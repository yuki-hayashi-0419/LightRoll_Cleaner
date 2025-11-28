//
//  BlurDetector.swift
//  LightRoll_CleanerFeature
//
//  ブレ検出サービス - CoreImageを使用したブレ・シャープネス検出
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import CoreImage
import Photos

// MARK: - BlurDetector

/// ブレ検出サービス
///
/// 主な責務:
/// - CoreImage フィルタを使用したブレ検出
/// - ラプラシアン分散法によるシャープネス評価
/// - 品質スコア算出（0.0〜1.0）
/// - バッチ処理対応（最大500枚/バッチ）
/// - 進捗通知とキャンセル対応
public actor BlurDetector {

    // MARK: - Properties

    /// Vision リクエストハンドラー
    private let visionHandler: VisionRequestHandler

    /// ブレ検出オプション
    private let options: BlurDetectionOptions

    /// CoreImage コンテキスト（画像処理用）
    private let ciContext: CIContext

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - visionHandler: Vision リクエストハンドラー（省略時は新規作成）
    ///   - options: ブレ検出オプション
    public init(
        visionHandler: VisionRequestHandler? = nil,
        options: BlurDetectionOptions = .default
    ) {
        self.visionHandler = visionHandler ?? VisionRequestHandler()
        self.options = options
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .priorityRequestLow: false
        ])
    }

    // MARK: - Public Methods

    /// PHAsset配列からブレ検出を実行
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出されたブレ情報の配列
    /// - Throws: AnalysisError
    public func detectBlur(
        in assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [BlurDetectionResult] {
        guard !assets.isEmpty else {
            return []
        }

        var results: [BlurDetectionResult] = []
        results.reserveCapacity(assets.count)

        // バッチ処理でメモリ効率化
        let batches = assets.chunked(into: options.batchSize)

        for (batchIndex, batch) in batches.enumerated() {
            // バッチ内の各写真を処理
            for (index, asset) in batch.enumerated() {
                let result = try await detectBlur(in: asset)
                results.append(result)

                // 進捗通知
                let totalProcessed = batchIndex * options.batchSize + index + 1
                let currentProgress = Double(totalProcessed) / Double(assets.count)
                await progress?(currentProgress)

                // キャンセルチェック
                try Task.checkCancellation()
            }
        }

        return results
    }

    /// 単一のPHAssetからブレ検出を実行
    ///
    /// - Parameter asset: 対象のPHAsset
    /// - Returns: 検出されたブレ情報
    /// - Throws: AnalysisError
    public func detectBlur(in asset: PHAsset) async throws -> BlurDetectionResult {
        // PHAsset から CIImage を取得
        let ciImage = try await loadCIImage(from: asset)

        // ラプラシアン分散法でブレスコアを計算
        let blurScore = try calculateBlurScore(from: ciImage)

        // シャープネススコア（1.0 - blurScore）
        let sharpnessScore = 1.0 - blurScore

        // ブレ判定
        let isBlurry = blurScore >= options.blurThreshold

        return BlurDetectionResult(
            photoId: asset.localIdentifier,
            blurScore: blurScore,
            sharpnessScore: sharpnessScore,
            isBlurry: isBlurry
        )
    }

    /// Photo配列からブレ検出を実行（便利メソッド）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出されたブレ情報の配列
    /// - Throws: AnalysisError
    public func detectBlur(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [BlurDetectionResult] {
        let assets = try await fetchPHAssets(from: photos)
        return try await detectBlur(in: assets, progress: progress)
    }

    // MARK: - Private Methods

    /// ラプラシアン分散法によるブレスコア計算
    ///
    /// - Parameter ciImage: 対象のCIImage
    /// - Returns: ブレスコア（0.0〜1.0、高いほどブレている）
    /// - Throws: AnalysisError
    private func calculateBlurScore(from ciImage: CIImage) throws -> Float {
        // ラプラシアンフィルタを適用してエッジを検出
        guard let laplacianFilter = CIFilter(name: "CIConvolution3X3") else {
            throw AnalysisError.visionFrameworkError("ラプラシアンフィルタの作成に失敗しました")
        }

        // ラプラシアンカーネル（エッジ検出）
        let kernel = CIVector(values: [
            0,  1,  0,
            1, -4,  1,
            0,  1,  0
        ], count: 9)

        laplacianFilter.setValue(ciImage, forKey: kCIInputImageKey)
        laplacianFilter.setValue(kernel, forKey: "inputWeights")

        guard let outputImage = laplacianFilter.outputImage else {
            throw AnalysisError.visionFrameworkError("ラプラシアンフィルタの適用に失敗しました")
        }

        // エッジ強度の分散を計算
        let variance = try calculateVariance(from: outputImage)

        // 分散を0〜1のスコアに正規化（逆転: 低分散 = 高ブレ）
        // 経験的な閾値: 分散100以上でシャープ、10以下でブレ
        let normalizedScore: Float
        if variance >= 100.0 {
            normalizedScore = 0.0 // シャープ
        } else if variance <= 10.0 {
            normalizedScore = 1.0 // ブレ
        } else {
            // 対数スケールで正規化
            normalizedScore = 1.0 - Float(log10(variance / 10.0) / log10(10.0))
        }

        return max(0.0, min(1.0, normalizedScore))
    }

    /// 画像の分散を計算
    ///
    /// - Parameter ciImage: 対象のCIImage
    /// - Returns: 分散値
    /// - Throws: AnalysisError
    private func calculateVariance(from ciImage: CIImage) throws -> Double {
        // 画像をグレースケールに変換
        guard let grayscaleFilter = CIFilter(name: "CIColorControls") else {
            throw AnalysisError.visionFrameworkError("グレースケールフィルタの作成に失敗しました")
        }

        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)

        guard let grayscaleImage = grayscaleFilter.outputImage else {
            throw AnalysisError.visionFrameworkError("グレースケール変換に失敗しました")
        }

        // 画像のサンプリング領域を設定（パフォーマンス向上のため中央部分のみ）
        let extent = grayscaleImage.extent
        let centerRect = CGRect(
            x: extent.midX - extent.width * 0.25,
            y: extent.midY - extent.height * 0.25,
            width: extent.width * 0.5,
            height: extent.height * 0.5
        )

        // CGImage に変換してピクセルデータを取得
        guard let cgImage = ciContext.createCGImage(grayscaleImage, from: centerRect) else {
            throw AnalysisError.visionFrameworkError("CGImageの作成に失敗しました")
        }

        // ピクセルデータから分散を計算
        return try calculatePixelVariance(from: cgImage)
    }

    /// CGImageのピクセルデータから分散を計算
    ///
    /// - Parameter cgImage: 対象のCGImage
    /// - Returns: 分散値
    /// - Throws: AnalysisError
    private func calculatePixelVariance(from cgImage: CGImage) throws -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw AnalysisError.visionFrameworkError("CGContextの作成に失敗しました")
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 平均値を計算
        let sum = pixelData.reduce(0.0) { $0 + Double($1) }
        let mean = sum / Double(pixelData.count)

        // 分散を計算
        let variance = pixelData.reduce(0.0) { partialResult, pixel in
            let diff = Double(pixel) - mean
            return partialResult + (diff * diff)
        } / Double(pixelData.count)

        return variance
    }

    /// PHAsset から CIImage を読み込む
    ///
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: CIImage
    /// - Throws: AnalysisError
    private func loadCIImage(from asset: PHAsset) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            options.resizeMode = .none

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: options
            ) { image, info in
                // エラーチェック
                if let error = info?[PHImageErrorKey] as? Error {
                    let analysisError = AnalysisError.visionFrameworkError(
                        "画像読み込みエラー: \(error.localizedDescription)"
                    )
                    continuation.resume(throwing: analysisError)
                    return
                }

                // キャンセルチェック
                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    continuation.resume(throwing: AnalysisError.cancelled)
                    return
                }

                // UIImage から CIImage を作成
                guard let uiImage = image else {
                    let error = AnalysisError.visionFrameworkError(
                        "画像の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }

                // UIImage/NSImage -> CIImage への変換
                #if os(iOS)
                // iOS環境: UIImage.cgImage を使用
                guard let cgImage = uiImage.cgImage else {
                    let error = AnalysisError.visionFrameworkError(
                        "CGImage の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }
                let ciImage = CIImage(cgImage: cgImage)
                #else
                // macOS環境: NSImage から CGImage を取得
                guard let cgImage = uiImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    let error = AnalysisError.visionFrameworkError(
                        "CGImage の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }
                let ciImage = CIImage(cgImage: cgImage)
                #endif

                continuation.resume(returning: ciImage)
            }
        }
    }

    /// Photo配列からPHAssetを取得
    ///
    /// - Parameter photos: Photo配列
    /// - Returns: PHAsset配列
    /// - Throws: AnalysisError
    private func fetchPHAssets(from photos: [Photo]) async throws -> [PHAsset] {
        let identifiers = photos.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets: [PHAsset] = []
        assets.reserveCapacity(identifiers.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }
}

// MARK: - BlurDetectionOptions

/// ブレ検出オプション
public struct BlurDetectionOptions: Sendable {

    /// ブレ判定の閾値（0.0〜1.0、この値以上でブレと判定）
    public let blurThreshold: Float

    /// バッチ処理のサイズ
    public let batchSize: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        blurThreshold: Float = 0.4,
        batchSize: Int = 500,
        maxConcurrentOperations: Int = 4
    ) {
        self.blurThreshold = Swift.max(0.0, Swift.min(1.0, blurThreshold))
        self.batchSize = Swift.max(1, batchSize)
        self.maxConcurrentOperations = Swift.max(1, maxConcurrentOperations)
    }

    // MARK: - Presets

    /// デフォルトオプション（閾値 0.4、バッチ500枚）
    public static let `default` = BlurDetectionOptions()

    /// 厳格モード（高精度、ブレの閾値を厳しく）
    public static let strict = BlurDetectionOptions(
        blurThreshold: 0.3,
        batchSize: 200,
        maxConcurrentOperations: 2
    )

    /// 緩和モード（より多くの写真をブレとして検出）
    public static let relaxed = BlurDetectionOptions(
        blurThreshold: 0.5,
        batchSize: 1000,
        maxConcurrentOperations: 8
    )
}

// MARK: - BlurDetectionResult

/// ブレ検出結果
public struct BlurDetectionResult: Sendable, Identifiable {

    /// 一意な識別子（写真IDと同一）
    public let id: String

    /// 検出対象の写真ID
    public let photoId: String

    /// ブレスコア（0.0〜1.0、高いほどブレている）
    public let blurScore: Float

    /// シャープネススコア（0.0〜1.0、高いほどシャープ）
    public let sharpnessScore: Float

    /// ブレ判定
    public let isBlurry: Bool

    /// 検出日時
    public let detectedAt: Date

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        id: String? = nil,
        photoId: String,
        blurScore: Float,
        sharpnessScore: Float,
        isBlurry: Bool = false,
        detectedAt: Date = Date()
    ) {
        self.id = id ?? photoId
        self.photoId = photoId
        self.blurScore = Swift.max(0.0, Swift.min(1.0, blurScore))
        self.sharpnessScore = Swift.max(0.0, Swift.min(1.0, sharpnessScore))
        self.isBlurry = isBlurry
        self.detectedAt = detectedAt
    }

    // MARK: - Computed Properties

    /// 品質評価（3段階）
    public var qualityLevel: BlurQualityLevel {
        if blurScore < 0.3 {
            return .sharp
        } else if blurScore < 0.5 {
            return .acceptable
        } else {
            return .blurry
        }
    }

    /// ブレの説明テキスト
    public var blurDescription: String {
        switch qualityLevel {
        case .sharp:
            return NSLocalizedString("blur.sharp", value: "シャープ", comment: "Sharp image")
        case .acceptable:
            return NSLocalizedString("blur.acceptable", value: "やや不鮮明", comment: "Acceptable blur")
        case .blurry:
            return NSLocalizedString("blur.blurry", value: "ブレあり", comment: "Blurry image")
        }
    }

    /// フォーマット済みブレスコア（パーセント表示）
    public var formattedBlurScore: String {
        String(format: "%.1f%%", blurScore * 100)
    }

    /// フォーマット済みシャープネススコア（パーセント表示）
    public var formattedSharpnessScore: String {
        String(format: "%.1f%%", sharpnessScore * 100)
    }
}

// MARK: - BlurQualityLevel

/// ブレ品質レベル
public enum BlurQualityLevel: String, Sendable, Codable {
    /// シャープ（ブレなし）
    case sharp
    /// 許容範囲（やや不鮮明）
    case acceptable
    /// ブレあり
    case blurry

    /// SF Symbol アイコン名
    public var iconName: String {
        switch self {
        case .sharp:
            return "sparkles"
        case .acceptable:
            return "camera.metering.partial"
        case .blurry:
            return "camera.metering.unknown"
        }
    }
}

// MARK: - BlurDetectionResult + Hashable

extension BlurDetectionResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: BlurDetectionResult, rhs: BlurDetectionResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - BlurDetectionResult + Codable

extension BlurDetectionResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoId
        case blurScore
        case sharpnessScore
        case isBlurry
        case detectedAt
    }
}

// MARK: - BlurDetectionResult + CustomStringConvertible

extension BlurDetectionResult: CustomStringConvertible {
    public var description: String {
        """
        BlurDetectionResult(
            photoId: \(photoId),
            blurScore: \(String(format: "%.2f", blurScore)),
            sharpnessScore: \(String(format: "%.2f", sharpnessScore)),
            isBlurry: \(isBlurry),
            quality: \(qualityLevel.rawValue)
        )
        """
    }
}

// MARK: - BlurDetectionResult + Comparable

extension BlurDetectionResult: Comparable {
    /// シャープネススコアで比較（シャープが先）
    public static func < (lhs: BlurDetectionResult, rhs: BlurDetectionResult) -> Bool {
        lhs.sharpnessScore > rhs.sharpnessScore
    }
}

// MARK: - Array Extension for BlurDetectionResult

extension Array where Element == BlurDetectionResult {

    /// ブレ写真のみをフィルタ
    public func filterBlurry() -> [BlurDetectionResult] {
        filter { $0.isBlurry }
    }

    /// シャープな写真のみをフィルタ
    public func filterSharp() -> [BlurDetectionResult] {
        filter { !$0.isBlurry }
    }

    /// 品質レベルでフィルタ
    public func filter(by level: BlurQualityLevel) -> [BlurDetectionResult] {
        filter { $0.qualityLevel == level }
    }

    /// シャープネス順でソート（シャープが先）
    public func sortedBySharpness() -> [BlurDetectionResult] {
        sorted { $0.sharpnessScore > $1.sharpnessScore }
    }

    /// ブレスコア順でソート（ブレが多い順）
    public func sortedByBlur() -> [BlurDetectionResult] {
        sorted { $0.blurScore > $1.blurScore }
    }

    /// 総ブレ写真数
    public var blurryCount: Int {
        filter { $0.isBlurry }.count
    }

    /// シャープな写真数
    public var sharpCount: Int {
        filter { !$0.isBlurry }.count
    }

    /// ブレ率
    public var blurryRatio: Double? {
        guard !isEmpty else { return nil }
        return Double(blurryCount) / Double(count)
    }

    /// 平均ブレスコア
    public var averageBlurScore: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.blurScore }
        return sum / Float(count)
    }

    /// 平均シャープネススコア
    public var averageSharpnessScore: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.sharpnessScore }
        return sum / Float(count)
    }

    /// 最もシャープな写真
    public var sharpest: BlurDetectionResult? {
        self.max { $0.sharpnessScore < $1.sharpnessScore }
    }

    /// 最もブレている写真
    public var blurriest: BlurDetectionResult? {
        self.max { $0.blurScore < $1.blurScore }
    }
}
