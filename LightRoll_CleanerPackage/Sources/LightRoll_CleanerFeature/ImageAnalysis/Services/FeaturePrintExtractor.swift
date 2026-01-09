//
//  FeaturePrintExtractor.swift
//  LightRoll_CleanerFeature
//
//  画像特徴量（Feature Print）の抽出を担当するサービス
//  VNGenerateImageFeaturePrintRequest を使用して類似度比較用の特徴ベクトルを生成
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - FeaturePrintExtractor

/// 画像特徴量抽出サービス
///
/// 主な責務:
/// - VNGenerateImageFeaturePrintRequest を使用した特徴量抽出
/// - 特徴量のハッシュ化（永続化用）
/// - バッチ処理による効率的な抽出
public actor FeaturePrintExtractor {

    // MARK: - Properties

    /// Vision リクエストハンドラー
    private let visionHandler: VisionRequestHandler

    /// 抽出オプション
    private let options: ExtractionOptions

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - visionHandler: Vision リクエストハンドラー（省略時は新規作成）
    ///   - options: 抽出オプション
    public init(
        visionHandler: VisionRequestHandler? = nil,
        options: ExtractionOptions = .default
    ) {
        self.visionHandler = visionHandler ?? VisionRequestHandler()
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset から特徴量を抽出
    ///
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: 抽出された特徴量
    /// - Throws: AnalysisError
    public func extractFeaturePrint(from asset: PHAsset) async throws -> FeaturePrintResult {
        // 特徴量抽出リクエストを作成
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = options.cropAndScaleOption
        request.revision = options.revision

        // Vision リクエストを実行
        let result = try await visionHandler.perform(on: asset, request: request)

        // 結果を取得
        guard let featurePrintRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self),
              let observation = featurePrintRequest.results?.first as? VNFeaturePrintObservation else {
            throw AnalysisError.featureExtractionFailed
        }

        // FeaturePrintResult を作成
        return try FeaturePrintResult(
            photoId: asset.localIdentifier,
            observation: observation,
            extractedAt: Date()
        )
    }

    /// 複数の PHAsset から特徴量を一括抽出
    ///
    /// - Parameters:
    ///   - assets: 対象の PHAsset 配列
    ///   - progressHandler: 進捗報告コールバック（0.0〜1.0）
    ///   - memoryMonitor: メモリ監視（省略時は新規作成）
    /// - Returns: 抽出された特徴量の配列
    /// - Throws: AnalysisError
    public func extractFeaturePrints(
        from assets: [PHAsset],
        progressHandler: (@Sendable (Double) async -> Void)? = nil,
        memoryMonitor: MemoryPressureMonitor? = nil
    ) async throws -> [FeaturePrintResult] {
        guard !assets.isEmpty else { return [] }

        let totalCount = assets.count
        let completedCount = LockIsolated(0)
        let monitor = memoryMonitor ?? MemoryPressureMonitor()

        // 動的に調整可能な並列数
        let currentParallelism = LockIsolated(options.maxConcurrentOperations)

        // 並列制限用のセマフォ
        let semaphore = AsyncSemaphore(limit: options.maxConcurrentOperations)

        // メモリ監視を開始
        await monitor.startMonitoring { [currentParallelism] level in
            let newParallelism: Int
            switch level {
            case .normal:
                newParallelism = 8
            case .warning:
                newParallelism = 4
            case .critical:
                newParallelism = 2
            }
            currentParallelism.setValue(newParallelism)
        }

        defer {
            Task {
                await monitor.stopMonitoring()
            }
        }

        // TaskGroup を使用して並列処理（セマフォで制限）
        return try await withThrowingTaskGroup(
            of: FeaturePrintResult.self,
            returning: [FeaturePrintResult].self
        ) { group in
            // 各 Asset に対してタスクを追加
            for asset in assets {
                group.addTask {
                    // セマフォで並列数を制限
                    await semaphore.wait()
                    defer {
                        Task { await semaphore.signal() }
                    }

                    // メモリプレッシャーが危険レベルの場合、少し待機
                    let pressureLevel = await monitor.currentPressureLevel()
                    if pressureLevel == .critical {
                        try await Task.sleep(for: .milliseconds(100))
                    }

                    let result = try await self.extractFeaturePrint(from: asset)

                    // 進捗を更新
                    let newCount = completedCount.withLock { count in
                        count += 1
                        return count
                    }

                    // 進捗を報告（10件ごと、または完了時）
                    if let progressHandler = progressHandler,
                       newCount % 10 == 0 || newCount == totalCount {
                        let progress = Double(newCount) / Double(totalCount)
                        await progressHandler(progress)
                    }

                    return result
                }
            }

            // 結果を収集
            var results: [FeaturePrintResult] = []
            results.reserveCapacity(assets.count)

            for try await result in group {
                results.append(result)
            }

            return results
        }
    }

    /// Photo モデルから特徴量を抽出（便利メソッド）
    ///
    /// - Parameter photo: 対象の Photo
    /// - Returns: 抽出された特徴量
    /// - Throws: AnalysisError
    public func extractFeaturePrint(from photo: Photo) async throws -> FeaturePrintResult {
        // PHAsset を取得
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            throw AnalysisError.visionFrameworkError("PHAsset の取得に失敗しました")
        }

        return try await extractFeaturePrint(from: asset)
    }
}

// MARK: - ExtractionOptions

/// 特徴量抽出オプション
public struct ExtractionOptions: Sendable {

    /// 画像のクロップとスケールオプション
    public let cropAndScaleOption: VNImageCropAndScaleOption

    /// Vision API のリビジョン番号
    public let revision: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - cropAndScaleOption: 画像のクロップ・スケール方法
    ///   - revision: Vision APIリビジョン番号
    ///   - maxConcurrentOperations: 最大同時実行数（デフォルト8）
    public init(
        cropAndScaleOption: VNImageCropAndScaleOption = .centerCrop,
        revision: Int = VNGenerateImageFeaturePrintRequestRevision2,
        maxConcurrentOperations: Int = 8
    ) {
        self.cropAndScaleOption = cropAndScaleOption
        self.revision = revision
        self.maxConcurrentOperations = maxConcurrentOperations
    }

    // MARK: - Presets

    /// デフォルトオプション
    public static let `default` = ExtractionOptions()

    /// 高精度オプション（スケールダウンなし）
    /// メモリ使用量が多いため、並列数を4に制限
    public static let highAccuracy = ExtractionOptions(
        cropAndScaleOption: .scaleFit,
        revision: VNGenerateImageFeaturePrintRequestRevision2,
        maxConcurrentOperations: 4
    )

    /// 高速オプション（クロップして処理）
    public static let fast = ExtractionOptions(
        cropAndScaleOption: .centerCrop,
        revision: VNGenerateImageFeaturePrintRequestRevision1,
        maxConcurrentOperations: 8
    )
}

// MARK: - FeaturePrintResult

/// 特徴量抽出結果
public struct FeaturePrintResult: Sendable, Identifiable {

    /// 結果の一意な識別子
    public let id: UUID

    /// 対象の写真ID
    public let photoId: String

    /// 特徴量のハッシュ（永続化用）
    public let featurePrintHash: Data

    /// 抽出日時
    public let extractedAt: Date

    /// 特徴量の次元数
    public let elementCount: Int

    /// 特徴量の型
    public let elementType: VNElementType

    // MARK: - Initialization

    /// VNFeaturePrintObservation から初期化
    ///
    /// - Parameters:
    ///   - photoId: 写真ID
    ///   - observation: Vision の特徴量観測結果
    ///   - extractedAt: 抽出日時
    /// - Throws: AnalysisError（ハッシュ化失敗時）
    public init(
        photoId: String,
        observation: VNFeaturePrintObservation,
        extractedAt: Date = Date()
    ) throws {
        self.id = UUID()
        self.photoId = photoId
        self.extractedAt = extractedAt
        self.elementCount = observation.elementCount
        self.elementType = observation.elementType

        // 特徴量をハッシュ化
        self.featurePrintHash = try Self.hashFeaturePrint(observation)
    }

    // MARK: - Helper Methods

    /// 特徴量をハッシュ化（Data として保存可能な形式に変換）
    ///
    /// - Parameter observation: VNFeaturePrintObservation
    /// - Returns: ハッシュ化された Data
    /// - Throws: AnalysisError
    private static func hashFeaturePrint(
        _ observation: VNFeaturePrintObservation
    ) throws -> Data {
        // VNFeaturePrintObservation は直接 Codable ではないため、
        // データポインタから Data を作成
        let elementCount = observation.elementCount
        let elementType = observation.elementType

        // Float 配列として取得
        guard elementType == .float else {
            throw AnalysisError.featureExtractionFailed
        }

        // データポインタから Data を作成
        var data = Data(count: elementCount * MemoryLayout<Float>.size)
        try data.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress else {
                throw AnalysisError.featureExtractionFailed
            }

            let floatPointer = baseAddress.assumingMemoryBound(to: Float.self)
            try observation.data.withUnsafeBytes { observationBytes in
                guard let observationAddress = observationBytes.baseAddress else {
                    throw AnalysisError.featureExtractionFailed
                }

                floatPointer.initialize(
                    from: observationAddress.assumingMemoryBound(to: Float.self),
                    count: elementCount
                )
            }
        }

        return data
    }

    /// ハッシュ化されたデータから VNFeaturePrintObservation を復元
    /// (注: Vision Framework の内部実装に依存するため、参考実装)
    ///
    /// - Parameter data: ハッシュ化されたデータ
    /// - Returns: VNFeaturePrintObservation（復元可能な場合）
    public static func reconstructObservation(from data: Data) -> VNFeaturePrintObservation? {
        // VNFeaturePrintObservation の復元は Vision Framework の制約により困難
        // そのため、類似度計算時は観測結果を直接保持・使用することを推奨
        return nil
    }
}

// MARK: - FeaturePrintResult + Hashable

extension FeaturePrintResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(photoId)
        hasher.combine(featurePrintHash)
    }

    public static func == (lhs: FeaturePrintResult, rhs: FeaturePrintResult) -> Bool {
        lhs.id == rhs.id && lhs.photoId == rhs.photoId
    }
}

// MARK: - FeaturePrintResult + Codable

extension FeaturePrintResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoId
        case featurePrintHash
        case extractedAt
        case elementCount
        case elementType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        photoId = try container.decode(String.self, forKey: .photoId)
        featurePrintHash = try container.decode(Data.self, forKey: .featurePrintHash)
        extractedAt = try container.decode(Date.self, forKey: .extractedAt)
        elementCount = try container.decode(Int.self, forKey: .elementCount)

        // VNElementType を Int から復元
        let elementTypeRaw = try container.decode(UInt.self, forKey: .elementType)
        elementType = VNElementType(rawValue: elementTypeRaw) ?? .float
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(photoId, forKey: .photoId)
        try container.encode(featurePrintHash, forKey: .featurePrintHash)
        try container.encode(extractedAt, forKey: .extractedAt)
        try container.encode(elementCount, forKey: .elementCount)
        try container.encode(elementType.rawValue, forKey: .elementType)
    }
}

// MARK: - FeaturePrintResult + CustomStringConvertible

extension FeaturePrintResult: CustomStringConvertible {
    public var description: String {
        """
        FeaturePrintResult(
            photoId: \(photoId),
            elementCount: \(elementCount),
            hashSize: \(featurePrintHash.count) bytes,
            extractedAt: \(extractedAt)
        )
        """
    }
}

// MARK: - Array Extension for FeaturePrintResult

extension Array where Element == FeaturePrintResult {

    /// 写真IDでフィルタ
    /// - Parameter photoId: 写真ID
    /// - Returns: 該当する結果（見つからない場合は nil）
    public func result(forPhotoId photoId: String) -> FeaturePrintResult? {
        first { $0.photoId == photoId }
    }

    /// 複数の写真IDでフィルタ
    /// - Parameter photoIds: 写真IDのセット
    /// - Returns: 該当する結果の配列
    public func results(forPhotoIds photoIds: Set<String>) -> [FeaturePrintResult] {
        filter { photoIds.contains($0.photoId) }
    }

    /// 写真IDをキーとした辞書に変換
    public var byPhotoId: [String: FeaturePrintResult] {
        Dictionary(uniqueKeysWithValues: map { ($0.photoId, $0) })
    }

    /// 平均特徴量次元数
    public var averageElementCount: Double? {
        guard !isEmpty else { return nil }
        let sum = reduce(0) { $0 + $1.elementCount }
        return Double(sum) / Double(count)
    }
}
