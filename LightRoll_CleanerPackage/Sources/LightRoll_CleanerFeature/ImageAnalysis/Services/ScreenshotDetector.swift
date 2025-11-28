//
//  ScreenshotDetector.swift
//  LightRoll_CleanerFeature
//
//  スクリーンショット検出サービス
//  PHAsset のメタデータを使用してスクリーンショットを判定する
//  Created by AI Assistant
//

import Foundation
import Photos
import CoreGraphics

// MARK: - ScreenshotDetectorProtocol

/// スクリーンショット検出プロトコル
/// テスタビリティのために Protocol で抽象化
public protocol ScreenshotDetectorProtocol: Actor {
    /// 単一の写真がスクリーンショットかどうかを判定
    /// - Parameter asset: 判定対象の PHAsset
    /// - Returns: スクリーンショット判定結果
    /// - Throws: AnalysisError
    func isScreenshot(asset: PHAsset) async throws -> Bool

    /// 複数の写真をバッチ処理してスクリーンショットを検出
    /// - Parameters:
    ///   - assets: 判定対象の PHAsset 配列
    ///   - progress: 進捗通知クロージャ（0.0〜1.0）
    /// - Returns: スクリーンショット判定結果の配列
    /// - Throws: AnalysisError
    func detectScreenshots(
        in assets: [PHAsset],
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> [ScreenshotDetectionResult]

    /// 処理をキャンセル
    func cancel()
}

// MARK: - ScreenshotDetector

/// スクリーンショット検出サービスの実装
///
/// 主な検出方法:
/// 1. PHAsset.mediaSubtypes の .photoScreenshot フラグ（最も正確）
/// 2. 画面サイズとの一致判定（補助的な検証）
/// 3. ファイル名パターンマッチング（フォールバック）
///
/// iOS の写真ライブラリは、スクリーンショットを撮影時に自動的にタグ付けするため、
/// mediaSubtypes を使用するのが最も確実な方法です。
public actor ScreenshotDetector: ScreenshotDetectorProtocol {

    // MARK: - Properties

    /// キャンセルフラグ
    private var isCancelled = false

    /// 検出オプション
    private let options: ScreenshotDetectionOptions

    /// 既知のiOSデバイスの画面サイズキャッシュ
    private let knownDeviceScreenSizes: [CGSize]

    // MARK: - Initialization

    /// 標準イニシャライザ
    /// - Parameter options: 検出オプション
    public init(options: ScreenshotDetectionOptions = .default) {
        self.options = options
        self.knownDeviceScreenSizes = Self.buildDeviceScreenSizes()
    }

    // MARK: - Public Methods

    /// 単一の写真がスクリーンショットかどうかを判定
    public func isScreenshot(asset: PHAsset) async throws -> Bool {
        // キャンセルチェック
        try Task.checkCancellation()
        guard !isCancelled else {
            throw AnalysisError.cancelled
        }

        // メディアタイプチェック（動画は除外）
        guard asset.mediaType == .image else {
            return false
        }

        // 1. 最優先: PHAsset の mediaSubtypes フラグ
        // iOS がスクリーンショットとして認識している場合
        if asset.isScreenshot {
            return true
        }

        // 追加検証が無効な場合はここで終了
        guard options.useAdditionalVerification else {
            return false
        }

        // 2. 補助的検証: 画面サイズチェック
        if options.verifyScreenSize {
            let matchesScreenSize = checkScreenSizeMismatch(asset: asset)
            if matchesScreenSize {
                return true
            }
        }

        // 3. フォールバック: ファイル名パターン
        if options.checkFilenamePattern {
            let matchesPattern = await checkFilenamePattern(asset: asset)
            if matchesPattern {
                return true
            }
        }

        return false
    }

    /// 複数の写真をバッチ処理してスクリーンショットを検出
    public func detectScreenshots(
        in assets: [PHAsset],
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> [ScreenshotDetectionResult] {
        // キャンセルチェック
        try Task.checkCancellation()
        guard !isCancelled else {
            throw AnalysisError.cancelled
        }

        let totalCount = assets.count
        guard totalCount > 0 else {
            return []
        }

        var results: [ScreenshotDetectionResult] = []
        results.reserveCapacity(totalCount)

        // 進捗通知を最初に送信
        progress?(0.0)

        // バッチサイズに分割して処理
        let batchSize = options.batchSize
        let batches = stride(from: 0, to: totalCount, by: batchSize).map {
            Array(assets[$0..<min($0 + batchSize, totalCount)])
        }

        var completedCount = 0

        for batch in batches {
            // キャンセルチェック
            try Task.checkCancellation()
            guard !isCancelled else {
                throw AnalysisError.cancelled
            }

            // バッチ内で並列処理
            let batchResults = try await withThrowingTaskGroup(
                of: ScreenshotDetectionResult.self
            ) { group in
                for asset in batch {
                    group.addTask {
                        // キャンセルチェック
                        try Task.checkCancellation()

                        let isScreenshot = try await self.isScreenshot(asset: asset)
                        let method = isScreenshot ?
                            await self.determineDetectionMethod(asset: asset) :
                            .notScreenshot

                        return ScreenshotDetectionResult(
                            assetIdentifier: asset.localIdentifier,
                            isScreenshot: isScreenshot,
                            confidence: await self.calculateConfidence(
                                asset: asset,
                                isScreenshot: isScreenshot
                            ),
                            detectionMethod: method,
                            detectedAt: Date()
                        )
                    }
                }

                var batchResults: [ScreenshotDetectionResult] = []
                for try await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }

            results.append(contentsOf: batchResults)
            completedCount += batch.count

            // 進捗通知
            let currentProgress = Double(completedCount) / Double(totalCount)
            progress?(currentProgress)
        }

        return results
    }

    /// 処理をキャンセル
    public func cancel() {
        isCancelled = true
    }

    /// キャンセル状態をリセット
    public func reset() {
        isCancelled = false
    }

    // MARK: - Private Methods

    /// 画面サイズとの一致をチェック
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: 既知のデバイス画面サイズと一致する場合は true
    private func checkScreenSizeMismatch(asset: PHAsset) -> Bool {
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        // 既知のデバイス画面サイズと完全一致
        if knownDeviceScreenSizes.contains(size) {
            return true
        }

        // 回転を考慮（幅と高さを入れ替え）
        let rotatedSize = CGSize(width: asset.pixelHeight, height: asset.pixelWidth)
        if knownDeviceScreenSizes.contains(rotatedSize) {
            return true
        }

        // @2x, @3x のスケールファクターを考慮
        for scale in [2.0, 3.0] {
            let scaledSize = CGSize(
                width: Double(asset.pixelWidth) / scale,
                height: Double(asset.pixelHeight) / scale
            )

            if knownDeviceScreenSizes.contains(scaledSize) {
                return true
            }

            let scaledRotatedSize = CGSize(
                width: Double(asset.pixelHeight) / scale,
                height: Double(asset.pixelWidth) / scale
            )

            if knownDeviceScreenSizes.contains(scaledRotatedSize) {
                return true
            }
        }

        return false
    }

    /// ファイル名パターンのチェック
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: スクリーンショットのファイル名パターンに一致する場合は true
    private func checkFilenamePattern(asset: PHAsset) async -> Bool {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else {
            return false
        }

        let filename = resource.originalFilename.lowercased()

        // iOS スクリーンショットの標準パターン
        // 例: "IMG_0001.PNG", "Screenshot 2024-01-01 at 10.00.00.png"
        let patterns = [
            "screenshot",
            "スクリーンショット",
            "screen shot"
        ]

        return patterns.contains { pattern in
            filename.contains(pattern)
        }
    }

    /// 検出方法を判定
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: 検出方法
    private func determineDetectionMethod(asset: PHAsset) -> ScreenshotDetectionMethod {
        // mediaSubtypes フラグが最優先
        if asset.isScreenshot {
            return .mediaSubtype
        }

        // 画面サイズマッチング
        if checkScreenSizeMismatch(asset: asset) {
            return .screenSizeMatch
        }

        // ファイル名パターン（非同期なので同期的にチェックできない）
        return .filenamePattern
    }

    /// 信頼度を計算
    /// - Parameters:
    ///   - asset: 対象の PHAsset
    ///   - isScreenshot: スクリーンショット判定結果
    /// - Returns: 信頼度（0.0〜1.0）
    private func calculateConfidence(asset: PHAsset, isScreenshot: Bool) -> Float {
        guard isScreenshot else {
            return 1.0  // スクリーンショットでない場合は高信頼度
        }

        var confidence: Float = 0.0

        // mediaSubtypes フラグ: 最も信頼性が高い
        if asset.isScreenshot {
            confidence = 1.0
        }
        // 画面サイズマッチング: 高信頼度
        else if checkScreenSizeMismatch(asset: asset) {
            confidence = 0.85
        }
        // ファイル名パターン: 中程度の信頼度
        else {
            confidence = 0.7
        }

        return confidence
    }

    /// 既知のiOSデバイス画面サイズを構築
    /// - Returns: デバイス画面サイズの配列
    private static func buildDeviceScreenSizes() -> [CGSize] {
        var sizes: [CGSize] = []

        // iPhone (論理ピクセル)
        // @2x, @3x のスケールで実ピクセルに変換される
        sizes.append(CGSize(width: 320, height: 568))   // iPhone SE (1st gen)
        sizes.append(CGSize(width: 375, height: 667))   // iPhone 6/7/8
        sizes.append(CGSize(width: 414, height: 736))   // iPhone 6+/7+/8+
        sizes.append(CGSize(width: 375, height: 812))   // iPhone X/XS/11 Pro
        sizes.append(CGSize(width: 414, height: 896))   // iPhone XR/XS Max/11/11 Pro Max
        sizes.append(CGSize(width: 390, height: 844))   // iPhone 12/12 Pro/13/13 Pro
        sizes.append(CGSize(width: 428, height: 926))   // iPhone 12 Pro Max/13 Pro Max
        sizes.append(CGSize(width: 360, height: 780))   // iPhone 12 mini/13 mini
        sizes.append(CGSize(width: 393, height: 852))   // iPhone 14/14 Pro
        sizes.append(CGSize(width: 430, height: 932))   // iPhone 14 Plus/14 Pro Max
        sizes.append(CGSize(width: 393, height: 852))   // iPhone 15/15 Pro
        sizes.append(CGSize(width: 430, height: 932))   // iPhone 15 Plus/15 Pro Max

        // iPad (論理ピクセル)
        sizes.append(CGSize(width: 768, height: 1024))  // iPad/iPad 2/iPad mini
        sizes.append(CGSize(width: 810, height: 1080))  // iPad 10.2"
        sizes.append(CGSize(width: 820, height: 1180))  // iPad 10.9" (Air, 10th gen)
        sizes.append(CGSize(width: 834, height: 1112))  // iPad Pro 10.5"
        sizes.append(CGSize(width: 834, height: 1194))  // iPad Pro 11"
        sizes.append(CGSize(width: 1024, height: 1366)) // iPad Pro 12.9"

        return sizes
    }
}

// MARK: - ScreenshotDetectionOptions

/// スクリーンショット検出オプション
public struct ScreenshotDetectionOptions: Sendable {

    /// 追加検証を使用するかどうか
    /// false の場合、mediaSubtypes フラグのみで判定（最速）
    public let useAdditionalVerification: Bool

    /// 画面サイズ検証を行うかどうか
    public let verifyScreenSize: Bool

    /// ファイル名パターンチェックを行うかどうか
    public let checkFilenamePattern: Bool

    /// バッチサイズ（並列処理数）
    public let batchSize: Int

    // MARK: - Initialization

    /// カスタムイニシャライザ
    public init(
        useAdditionalVerification: Bool = false,
        verifyScreenSize: Bool = true,
        checkFilenamePattern: Bool = false,
        batchSize: Int = 50
    ) {
        self.useAdditionalVerification = useAdditionalVerification
        self.verifyScreenSize = verifyScreenSize
        self.checkFilenamePattern = checkFilenamePattern
        self.batchSize = batchSize
    }

    // MARK: - Presets

    /// デフォルトオプション（mediaSubtypes のみ、最速）
    public static let `default` = ScreenshotDetectionOptions(
        useAdditionalVerification: false
    )

    /// 高精度オプション（すべての検証を使用）
    public static let accurate = ScreenshotDetectionOptions(
        useAdditionalVerification: true,
        verifyScreenSize: true,
        checkFilenamePattern: true
    )

    /// 高速オプション（mediaSubtypes のみ）
    public static let fast = ScreenshotDetectionOptions(
        useAdditionalVerification: false,
        batchSize: 100
    )
}

// MARK: - ScreenshotDetectionResult

/// スクリーンショット検出結果
public struct ScreenshotDetectionResult: Identifiable, Hashable, Sendable {

    /// 一意な識別子
    public let id: String

    /// 対象アセットの識別子
    public let assetIdentifier: String

    /// スクリーンショットかどうか
    public let isScreenshot: Bool

    /// 信頼度（0.0〜1.0、高いほど確実）
    public let confidence: Float

    /// 検出方法
    public let detectionMethod: ScreenshotDetectionMethod

    /// 検出日時
    public let detectedAt: Date

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        assetIdentifier: String,
        isScreenshot: Bool,
        confidence: Float,
        detectionMethod: ScreenshotDetectionMethod,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.isScreenshot = isScreenshot
        self.confidence = confidence
        self.detectionMethod = detectionMethod
        self.detectedAt = detectedAt
    }

    // MARK: - Computed Properties

    /// 高信頼度かどうか（0.9以上）
    public var isHighConfidence: Bool {
        confidence >= 0.9
    }

    /// 中信頼度かどうか（0.7〜0.9）
    public var isMediumConfidence: Bool {
        confidence >= 0.7 && confidence < 0.9
    }

    /// 低信頼度かどうか（0.7未満）
    public var isLowConfidence: Bool {
        confidence < 0.7
    }
}

// MARK: - ScreenshotDetectionMethod

/// スクリーンショット検出方法
public enum ScreenshotDetectionMethod: String, Sendable, Codable {
    /// PHAsset.mediaSubtypes の .photoScreenshot フラグ
    case mediaSubtype = "media_subtype"

    /// 画面サイズとの一致
    case screenSizeMatch = "screen_size_match"

    /// ファイル名パターンマッチング
    case filenamePattern = "filename_pattern"

    /// スクリーンショットではない
    case notScreenshot = "not_screenshot"

    /// 検出方法の説明
    public var description: String {
        switch self {
        case .mediaSubtype:
            return "システムメタデータ"
        case .screenSizeMatch:
            return "画面サイズ一致"
        case .filenamePattern:
            return "ファイル名パターン"
        case .notScreenshot:
            return "スクリーンショットではない"
        }
    }

    /// 信頼性レベル（1が最も高い）
    public var reliabilityLevel: Int {
        switch self {
        case .mediaSubtype:
            return 1
        case .screenSizeMatch:
            return 2
        case .filenamePattern:
            return 3
        case .notScreenshot:
            return 0
        }
    }
}

// MARK: - Array Extension

extension Array where Element == ScreenshotDetectionResult {

    /// スクリーンショットのみをフィルタ
    public func filterScreenshots() -> [ScreenshotDetectionResult] {
        filter { $0.isScreenshot }
    }

    /// 非スクリーンショットのみをフィルタ
    public func filterNonScreenshots() -> [ScreenshotDetectionResult] {
        filter { !$0.isScreenshot }
    }

    /// 高信頼度のみをフィルタ
    public func filterHighConfidence() -> [ScreenshotDetectionResult] {
        filter { $0.isHighConfidence }
    }

    /// 信頼度順にソート（高信頼度が先）
    public func sortedByConfidence() -> [ScreenshotDetectionResult] {
        sorted { $0.confidence > $1.confidence }
    }

    /// 平均信頼度を計算
    public var averageConfidence: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.confidence }
        return sum / Float(count)
    }
}
