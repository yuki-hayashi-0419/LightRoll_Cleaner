//
//  FaceDetector.swift
//  LightRoll_CleanerFeature
//
//  顔検出サービス - VNDetectFaceRectanglesRequestを使用した顔検出・セルフィー判定
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - FaceDetector

/// 顔検出サービス
///
/// 主な責務:
/// - VNDetectFaceRectanglesRequestを使用した顔検出
/// - セルフィー写真の自動識別
/// - 顔の角度・位置情報取得
/// - バッチ処理対応（最大500枚/バッチ）
/// - 進捗通知とキャンセル対応
public actor FaceDetector {

    // MARK: - Properties

    /// Vision リクエストハンドラー
    private let visionHandler: VisionRequestHandler

    /// 顔検出オプション
    private let options: FaceDetectionOptions

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - visionHandler: Vision リクエストハンドラー（省略時は新規作成）
    ///   - options: 顔検出オプション
    public init(
        visionHandler: VisionRequestHandler? = nil,
        options: FaceDetectionOptions = .default
    ) {
        self.visionHandler = visionHandler ?? VisionRequestHandler()
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset配列から顔検出を実行
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出された顔情報の配列
    /// - Throws: AnalysisError
    public func detectFaces(
        in assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [FaceDetectionResult] {
        guard !assets.isEmpty else {
            return []
        }

        var results: [FaceDetectionResult] = []
        results.reserveCapacity(assets.count)

        // バッチ処理でメモリ効率化
        let batches = assets.chunked(into: options.batchSize)

        for (batchIndex, batch) in batches.enumerated() {
            // バッチ内の各写真を処理
            for (index, asset) in batch.enumerated() {
                let result = try await detectFaces(in: asset)
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

    /// 単一のPHAssetから顔検出を実行
    ///
    /// - Parameter asset: 対象のPHAsset
    /// - Returns: 検出された顔情報
    /// - Throws: AnalysisError
    public func detectFaces(in asset: PHAsset) async throws -> FaceDetectionResult {
        // 顔検出リクエストを作成
        let request = VNDetectFaceRectanglesRequest()

        // Vision リクエストを実行
        let result = try await visionHandler.perform(on: asset, requests: [request])

        // 結果を取得
        guard let faceRequest = result.request(ofType: VNDetectFaceRectanglesRequest.self),
              let observations = faceRequest.results else {
            // 顔が検出されなかった場合は空の結果を返す
            return FaceDetectionResult(
                photoId: asset.localIdentifier,
                faces: []
            )
        }

        // 顔情報を構築
        let faces = observations.map { observation in
            FaceInfo(
                boundingBox: observation.boundingBox,
                confidence: observation.confidence,
                roll: observation.roll?.doubleValue,
                yaw: observation.yaw?.doubleValue,
                pitch: observation.pitch?.doubleValue
            )
        }

        // セルフィー判定
        let isSelfie = determineSelfie(
            from: faces,
            imageSize: CGSize(
                width: CGFloat(asset.pixelWidth),
                height: CGFloat(asset.pixelHeight)
            )
        )

        return FaceDetectionResult(
            photoId: asset.localIdentifier,
            faces: faces,
            isSelfie: isSelfie
        )
    }

    /// Photo配列から顔検出を実行（便利メソッド）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された顔情報の配列
    /// - Throws: AnalysisError
    public func detectFaces(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [FaceDetectionResult] {
        let assets = try await fetchPHAssets(from: photos)
        return try await detectFaces(in: assets, progress: progress)
    }

    // MARK: - Private Methods

    /// セルフィー判定ロジック
    ///
    /// - Parameters:
    ///   - faces: 検出された顔情報の配列
    ///   - imageSize: 画像サイズ
    /// - Returns: セルフィーかどうか
    private func determineSelfie(
        from faces: [FaceInfo],
        imageSize: CGSize
    ) -> Bool {
        // 顔が検出されていない場合はセルフィーではない
        guard !faces.isEmpty else {
            return false
        }

        // 顔が1つだけ検出され、画像に占める割合が大きい場合
        if faces.count == 1 {
            let face = faces[0]
            let faceArea = face.boundingBox.width * face.boundingBox.height
            let imageArea = imageSize.width * imageSize.height

            // 画像に対する顔の占める割合を計算
            let faceRatio = Float(faceArea) / Float(imageArea)

            // 閾値以上の場合はセルフィーと判定
            return faceRatio >= options.selfieMinFaceRatio
        }

        // 顔が2〜3人の場合も、集合セルフィーとして判定可能
        if faces.count >= 2 && faces.count <= 3 {
            // すべての顔の面積を合計
            let totalFaceArea = faces.reduce(0.0) { sum, face in
                sum + (face.boundingBox.width * face.boundingBox.height)
            }
            let imageArea = imageSize.width * imageSize.height

            // 画像に対する顔の占める割合を計算
            let faceRatio = Float(totalFaceArea) / Float(imageArea)

            // 集合セルフィーの閾値（少し緩和）
            return faceRatio >= options.selfieMinFaceRatio * 0.8
        }

        // それ以外の場合はセルフィーではない
        return false
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

// MARK: - FaceDetectionOptions

/// 顔検出オプション
public struct FaceDetectionOptions: Sendable {

    /// セルフィー判定の最小顔サイズ比率（画像に対する顔の占める割合）
    public let selfieMinFaceRatio: Float

    /// バッチ処理のサイズ
    public let batchSize: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        selfieMinFaceRatio: Float = 0.15,
        batchSize: Int = 500,
        maxConcurrentOperations: Int = 4
    ) {
        self.selfieMinFaceRatio = Swift.max(0.0, Swift.min(1.0, selfieMinFaceRatio))
        self.batchSize = Swift.max(1, batchSize)
        self.maxConcurrentOperations = Swift.max(1, maxConcurrentOperations)
    }

    // MARK: - Presets

    /// デフォルトオプション（閾値 0.15、バッチ500枚）
    public static let `default` = FaceDetectionOptions()

    /// 厳格モード（高精度、処理速度は遅い）
    public static let strict = FaceDetectionOptions(
        selfieMinFaceRatio: 0.20,
        batchSize: 200,
        maxConcurrentOperations: 2
    )

    /// 緩和モード（より多くの写真をセルフィーとして検出）
    public static let relaxed = FaceDetectionOptions(
        selfieMinFaceRatio: 0.10,
        batchSize: 1000,
        maxConcurrentOperations: 8
    )
}

// MARK: - FaceDetectionResult

/// 顔検出結果
public struct FaceDetectionResult: Sendable, Identifiable, Hashable {

    /// 一意な識別子（写真IDと同一）
    public let id: String

    /// 検出対象の写真ID
    public let photoId: String

    /// 検出された顔の配列
    public let faces: [FaceInfo]

    /// セルフィー判定
    public let isSelfie: Bool

    /// 検出日時
    public let detectedAt: Date

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        id: String? = nil,
        photoId: String,
        faces: [FaceInfo],
        isSelfie: Bool = false,
        detectedAt: Date = Date()
    ) {
        self.id = id ?? photoId
        self.photoId = photoId
        self.faces = faces
        self.isSelfie = isSelfie
        self.detectedAt = detectedAt
    }

    // MARK: - Computed Properties

    /// 検出された顔の数
    public var faceCount: Int {
        faces.count
    }

    /// 顔が含まれているかどうか
    public var hasFaces: Bool {
        faceCount > 0
    }

    /// 複数の顔が含まれているかどうか
    public var hasMultipleFaces: Bool {
        faceCount > 1
    }

    /// 正面を向いている顔の数
    public var frontalFaceCount: Int {
        faces.filter { $0.isFrontal }.count
    }

    /// 平均信頼度
    public var averageConfidence: Float? {
        guard !faces.isEmpty else { return nil }
        let sum = faces.reduce(Float(0)) { $0 + $1.confidence }
        return sum / Float(faceCount)
    }

    /// 最大顔サイズ（面積）
    public var maxFaceSize: CGFloat? {
        faces.map { $0.area }.max()
    }
}

// MARK: - FaceInfo

/// 個別の顔情報
public struct FaceInfo: Sendable, Hashable {

    /// バウンディングボックス（正規化座標: 0.0〜1.0）
    public let boundingBox: CGRect

    /// 検出信頼度（0.0〜1.0）
    public let confidence: Float

    /// 首の傾き角度（-180〜180度、nil の場合は検出不可）
    public let roll: Double?

    /// 左右の回転角度（-90〜90度、nil の場合は検出不可）
    public let yaw: Double?

    /// 上下の傾き角度（-90〜90度、nil の場合は検出不可）
    public let pitch: Double?

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        boundingBox: CGRect,
        confidence: Float,
        roll: Double? = nil,
        yaw: Double? = nil,
        pitch: Double? = nil
    ) {
        self.boundingBox = boundingBox
        self.confidence = Swift.max(0.0, Swift.min(1.0, confidence))
        self.roll = roll
        self.yaw = yaw
        self.pitch = pitch
    }

    // MARK: - Computed Properties

    /// バウンディングボックスの面積
    public var area: CGFloat {
        boundingBox.width * boundingBox.height
    }

    /// 正面を向いているかどうか（yaw, pitch が閾値内）
    public var isFrontal: Bool {
        guard let yaw = yaw, let pitch = pitch else {
            return false
        }
        return abs(yaw) <= 30 && abs(pitch) <= 30
    }

    /// 横を向いているかどうか
    public var isSideProfile: Bool {
        guard let yaw = yaw else {
            return false
        }
        return abs(yaw) > 45
    }

    /// 顔の中心座標
    public var center: CGPoint {
        CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }

    /// FaceAngle型への変換
    public func toFaceAngle() -> FaceAngle? {
        guard let yaw = yaw, let pitch = pitch, let roll = roll else {
            return nil
        }
        return FaceAngle(
            yaw: Float(yaw),
            pitch: Float(pitch),
            roll: Float(roll)
        )
    }
}

// MARK: - FaceDetectionResult + Codable

extension FaceDetectionResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoId
        case faces
        case isSelfie
        case detectedAt
    }
}

extension FaceInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case boundingBox
        case confidence
        case roll
        case yaw
        case pitch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(CGRect.self, forKey: .boundingBox)
        self.confidence = try container.decode(Float.self, forKey: .confidence)
        self.roll = try container.decodeIfPresent(Double.self, forKey: .roll)
        self.yaw = try container.decodeIfPresent(Double.self, forKey: .yaw)
        self.pitch = try container.decodeIfPresent(Double.self, forKey: .pitch)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(roll, forKey: .roll)
        try container.encodeIfPresent(yaw, forKey: .yaw)
        try container.encodeIfPresent(pitch, forKey: .pitch)
    }
}

// MARK: - FaceDetectionResult + CustomStringConvertible

extension FaceDetectionResult: CustomStringConvertible {
    public var description: String {
        """
        FaceDetectionResult(
            photoId: \(photoId),
            faceCount: \(faceCount),
            isSelfie: \(isSelfie),
            frontalFaces: \(frontalFaceCount),
            avgConfidence: \(averageConfidence.map { String(format: "%.2f", $0) } ?? "N/A")
        )
        """
    }
}

// MARK: - Array Extension for FaceDetectionResult

extension Array where Element == FaceDetectionResult {

    /// セルフィーのみをフィルタ
    public func filterSelfies() -> [FaceDetectionResult] {
        filter { $0.isSelfie }
    }

    /// 顔が含まれるもののみをフィルタ
    public func filterWithFaces() -> [FaceDetectionResult] {
        filter { $0.hasFaces }
    }

    /// 複数の顔が含まれるもののみをフィルタ
    public func filterWithMultipleFaces() -> [FaceDetectionResult] {
        filter { $0.hasMultipleFaces }
    }

    /// 顔が含まれないもののみをフィルタ
    public func filterWithoutFaces() -> [FaceDetectionResult] {
        filter { !$0.hasFaces }
    }

    /// 総顔検出数
    public var totalFaceCount: Int {
        reduce(0) { $0 + $1.faceCount }
    }

    /// 平均顔検出数
    public var averageFaceCount: Double? {
        guard !isEmpty else { return nil }
        return Double(totalFaceCount) / Double(count)
    }

    /// セルフィー数
    public var selfieCount: Int {
        filter { $0.isSelfie }.count
    }

    /// セルフィー比率
    public var selfieRatio: Double? {
        guard !isEmpty else { return nil }
        return Double(selfieCount) / Double(count)
    }
}

