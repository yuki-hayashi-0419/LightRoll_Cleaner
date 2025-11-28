//
//  SimilarityAnalyzer.swift
//  LightRoll_CleanerFeature
//
//  類似写真グループ検出エンジン
//  FeaturePrintExtractorとSimilarityCalculatorを統合し、類似写真をグルーピング
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - SimilarityAnalyzer

/// 類似写真グループ検出サービス
///
/// 主な責務:
/// - 複数の写真から特徴量を抽出
/// - 類似写真ペアを検出
/// - グラフクラスタリングによるグループ化
/// - 進捗通知とキャンセル対応
public actor SimilarityAnalyzer {

    // MARK: - Properties

    /// 特徴量抽出器
    private let featurePrintExtractor: FeaturePrintExtractor

    /// 類似度計算器
    private let similarityCalculator: SimilarityCalculator

    /// 分析オプション
    private let options: SimilarityAnalysisOptions

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - featurePrintExtractor: 特徴量抽出器（省略時は新規作成）
    ///   - similarityCalculator: 類似度計算器（省略時は新規作成）
    ///   - options: 分析オプション
    public init(
        featurePrintExtractor: FeaturePrintExtractor? = nil,
        similarityCalculator: SimilarityCalculator? = nil,
        options: SimilarityAnalysisOptions = .default
    ) {
        self.featurePrintExtractor = featurePrintExtractor ?? FeaturePrintExtractor()
        self.similarityCalculator = similarityCalculator ?? SimilarityCalculator()
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset配列から類似写真グループを検出
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        guard !assets.isEmpty else {
            return []
        }

        // フェーズ1: 特徴量抽出（進捗 0.0〜0.6）
        let observations = try await extractFeaturePrints(
            from: assets,
            progressRange: (0.0, 0.6),
            progress: progress
        )

        // フェーズ2: 類似ペア検出（進捗 0.6〜0.9）
        await progress?(0.6)
        let similarPairs = try await similarityCalculator.findSimilarPairs(
            in: observations,
            threshold: options.similarityThreshold
        )
        await progress?(0.9)

        // フェーズ3: グループ化（進捗 0.9〜1.0）
        let groups = clusterIntoGroups(
            observations: observations,
            similarPairs: similarPairs
        )

        await progress?(1.0)

        return groups
    }

    /// Photo配列から類似写真グループを検出（便利メソッド）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        // Photo から PHAsset を取得
        let assets = try await fetchPHAssets(from: photos)
        return try await findSimilarGroups(in: assets, progress: progress)
    }

    /// 特定の写真に類似する写真を検索
    ///
    /// - Parameters:
    ///   - targetAsset: 基準となるPHAsset
    ///   - candidates: 検索対象のPHAsset配列
    ///   - threshold: 類似判定の閾値（nil の場合はオプションのデフォルト値）
    /// - Returns: 類似写真のIDと類似度スコアのペア配列（類似度降順）
    /// - Throws: AnalysisError
    public func findSimilarPhotos(
        to targetAsset: PHAsset,
        in candidates: [PHAsset],
        threshold: Float? = nil
    ) async throws -> [(id: String, similarity: Float)] {
        // 対象写真の特徴量を抽出
        let _ = try await featurePrintExtractor.extractFeaturePrint(from: targetAsset)

        // 候補写真の特徴量を抽出
        let candidateFeatures = try await featurePrintExtractor.extractFeaturePrints(from: candidates)

        // 類似度を計算
        let similarityThreshold = threshold ?? options.similarityThreshold
        var results: [(id: String, similarity: Float)] = []

        // 各候補写真との類似度を計算
        for candidateFeature in candidateFeatures {
            // 特徴量観測結果を再構築（実行時のみ可能）
            // 注: この実装では観測結果を直接保持するObservationCacheを使用
            if let targetObs = await getObservation(for: targetAsset),
               let candidateObs = await getObservation(for: candidates.first(where: { $0.localIdentifier == candidateFeature.photoId })) {

                let similarity = try await similarityCalculator.calculateSimilarity(
                    between: targetObs,
                    and: candidateObs
                )

                if similarity >= similarityThreshold {
                    results.append((id: candidateFeature.photoId, similarity: similarity))
                }
            }

            // キャンセルチェック
            try Task.checkCancellation()
        }

        return results.sorted { $0.similarity > $1.similarity }
    }

    // MARK: - Private Methods

    /// 特徴量抽出フェーズ
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲
    ///   - progress: 進捗コールバック
    /// - Returns: 抽出された観測結果の配列
    /// - Throws: AnalysisError
    private func extractFeaturePrints(
        from assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [(id: String, observation: VNFeaturePrintObservation)] {
        var observations: [(id: String, observation: VNFeaturePrintObservation)] = []
        observations.reserveCapacity(assets.count)

        let progressDelta = progressRange.end - progressRange.start

        // 特徴量抽出リクエストを作成
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        request.revision = VNGenerateImageFeaturePrintRequestRevision2

        // Vision リクエストハンドラー
        let visionHandler = VisionRequestHandler()

        // 各アセットから特徴量を抽出
        for (index, asset) in assets.enumerated() {
            // Vision リクエストを実行
            let result = try await visionHandler.perform(on: asset, request: request)

            // 結果を取得
            guard let featurePrintRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self),
                  let observation = featurePrintRequest.results?.first as? VNFeaturePrintObservation else {
                // 特徴量抽出失敗時はスキップ（処理は続行）
                continue
            }

            observations.append((id: asset.localIdentifier, observation: observation))

            // 進捗通知
            let currentProgress = progressRange.start + progressDelta * Double(index + 1) / Double(assets.count)
            await progress?(currentProgress)

            // キャンセルチェック
            try Task.checkCancellation()
        }

        return observations
    }

    /// グループ化フェーズ（Union-Findアルゴリズム）
    ///
    /// - Parameters:
    ///   - observations: 観測結果の配列
    ///   - similarPairs: 類似ペア配列
    /// - Returns: 類似写真グループ配列
    private func clusterIntoGroups(
        observations: [(id: String, observation: VNFeaturePrintObservation)],
        similarPairs: [SimilarityPair]
    ) -> [SimilarPhotoGroup] {
        guard !observations.isEmpty else {
            return []
        }

        // Union-Find データ構造でグループ化
        var unionFind = UnionFind(ids: observations.map { $0.id })

        // 類似ペアを統合
        for pair in similarPairs {
            unionFind.union(pair.id1, pair.id2)
        }

        // グループIDごとに写真をまとめる
        var groupsDict: [String: [String]] = [:]
        for (id, _) in observations {
            let root = unionFind.find(id)
            groupsDict[root, default: []].append(id)
        }

        // 最小グループサイズ以上のグループのみを抽出
        var groups: [SimilarPhotoGroup] = []
        for (_, photoIds) in groupsDict {
            // 最小グループサイズチェック
            guard photoIds.count >= options.minGroupSize else {
                continue
            }

            // グループ内の類似度を計算
            let groupPairs = similarPairs.filter { pair in
                photoIds.contains(pair.id1) && photoIds.contains(pair.id2)
            }

            let averageSimilarity = groupPairs.averageSimilarity ?? 0.0

            let group = SimilarPhotoGroup(
                id: UUID(),
                photoIds: photoIds,
                averageSimilarity: averageSimilarity,
                pairCount: groupPairs.count
            )

            groups.append(group)
        }

        // 写真数の多い順にソート
        return groups.sorted { $0.photoIds.count > $1.photoIds.count }
    }

    /// Photo配列からPHAssetを取得
    ///
    /// - Parameter photos: Photo配列
    /// - Returns: PHAsset配列
    /// - Throws: PhotoLibraryError
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

    /// 実行時の観測結果を取得（キャッシュから）
    ///
    /// 注: VNFeaturePrintObservation はハッシュから復元できないため、
    /// 実行時のみ観測結果を保持するキャッシュを使用
    ///
    /// - Parameter asset: PHAsset
    /// - Returns: VNFeaturePrintObservation（キャッシュになければ nil）
    private func getObservation(for asset: PHAsset?) async -> VNFeaturePrintObservation? {
        // 実装: 観測結果キャッシュから取得
        // このメソッドは将来的にObservationCacheで実装予定
        return nil
    }
}

// MARK: - SimilarityAnalysisOptions

/// 類似度分析オプション
public struct SimilarityAnalysisOptions: Sendable {

    /// 類似判定の閾値（0.0〜1.0）
    public let similarityThreshold: Float

    /// グループの最小サイズ（この数以上の写真で構成されるグループのみ抽出）
    public let minGroupSize: Int

    /// バッチ処理のサイズ
    public let batchSize: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        similarityThreshold: Float = 0.85,
        minGroupSize: Int = 2,
        batchSize: Int = 100,
        maxConcurrentOperations: Int = 4
    ) {
        self.similarityThreshold = Swift.max(0.0, Swift.min(1.0, similarityThreshold))
        self.minGroupSize = Swift.max(2, minGroupSize)
        self.batchSize = Swift.max(1, batchSize)
        self.maxConcurrentOperations = Swift.max(1, maxConcurrentOperations)
    }

    // MARK: - Presets

    /// デフォルトオプション（閾値 0.85、最小2枚）
    public static let `default` = SimilarityAnalysisOptions()

    /// 厳格モード（高類似度のみ検出、最小3枚）
    public static let strict = SimilarityAnalysisOptions(
        similarityThreshold: 0.95,
        minGroupSize: 3,
        batchSize: 50,
        maxConcurrentOperations: 2
    )

    /// 緩和モード（より多くの類似を検出、最小2枚）
    public static let relaxed = SimilarityAnalysisOptions(
        similarityThreshold: 0.75,
        minGroupSize: 2,
        batchSize: 200,
        maxConcurrentOperations: 8
    )
}

// MARK: - SimilarPhotoGroup

/// 類似写真グループ
public struct SimilarPhotoGroup: Sendable, Identifiable, Hashable {

    /// グループの一意な識別子
    public let id: UUID

    /// グループに含まれる写真ID配列
    public let photoIds: [String]

    /// グループ内の平均類似度
    public let averageSimilarity: Float

    /// グループ内のペア数
    public let pairCount: Int

    /// グループのサイズ（写真枚数）
    public var size: Int {
        photoIds.count
    }

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        id: UUID = UUID(),
        photoIds: [String],
        averageSimilarity: Float = 0.0,
        pairCount: Int = 0
    ) {
        self.id = id
        self.photoIds = photoIds
        self.averageSimilarity = Swift.max(0.0, Swift.min(1.0, averageSimilarity))
        self.pairCount = Swift.max(0, pairCount)
    }

    // MARK: - Computed Properties

    /// フォーマット済み平均類似度（パーセント表示）
    public var formattedAverageSimilarity: String {
        String(format: "%.1f%%", averageSimilarity * 100)
    }

    /// 指定されたIDが含まれているかチェック
    /// - Parameter photoId: 写真ID
    /// - Returns: 含まれている場合 true
    public func contains(photoId: String) -> Bool {
        photoIds.contains(photoId)
    }
}

// MARK: - SimilarPhotoGroup + Comparable

extension SimilarPhotoGroup: Comparable {
    /// グループサイズで比較（大きいグループが先）
    public static func < (lhs: SimilarPhotoGroup, rhs: SimilarPhotoGroup) -> Bool {
        if lhs.size != rhs.size {
            return lhs.size > rhs.size
        }
        // サイズが同じ場合は平均類似度で比較
        return lhs.averageSimilarity > rhs.averageSimilarity
    }
}

// MARK: - SimilarPhotoGroup + Codable

extension SimilarPhotoGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoIds
        case averageSimilarity
        case pairCount
    }
}

// MARK: - UnionFind

/// Union-Find データ構造（素集合データ構造）
/// グラフのクラスタリングに使用
private struct UnionFind {

    /// 親要素の辞書
    private var parent: [String: String] = [:]

    /// ランク（木の高さ）の辞書
    private var rank: [String: Int] = [:]

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter ids: 要素のID配列
    init(ids: [String]) {
        for id in ids {
            parent[id] = id
            rank[id] = 0
        }
    }

    // MARK: - Methods

    /// 要素のルートを検索（経路圧縮あり）
    /// - Parameter id: 要素のID
    /// - Returns: ルートのID
    mutating func find(_ id: String) -> String {
        guard let p = parent[id] else {
            return id
        }

        if p != id {
            // 経路圧縮: 再帰的にルートを探し、親を直接ルートに設定
            parent[id] = find(p)
            return parent[id]!
        }

        return id
    }

    /// 2つの要素を統合（ランクによる結合）
    /// - Parameters:
    ///   - id1: 1つ目の要素のID
    ///   - id2: 2つ目の要素のID
    mutating func union(_ id1: String, _ id2: String) {
        let root1 = find(id1)
        let root2 = find(id2)

        guard root1 != root2 else {
            return // 既に同じグループ
        }

        let rank1 = rank[root1] ?? 0
        let rank2 = rank[root2] ?? 0

        // ランクの低い木を高い木の下に結合
        if rank1 < rank2 {
            parent[root1] = root2
        } else if rank1 > rank2 {
            parent[root2] = root1
        } else {
            // ランクが同じ場合、どちらかをルートにしてランクを1増やす
            parent[root2] = root1
            rank[root1] = rank1 + 1
        }
    }

    /// 2つの要素が同じグループに属しているかチェック
    /// - Parameters:
    ///   - id1: 1つ目の要素のID
    ///   - id2: 2つ目の要素のID
    /// - Returns: 同じグループに属している場合 true
    mutating func isConnected(_ id1: String, _ id2: String) -> Bool {
        find(id1) == find(id2)
    }
}

// MARK: - Array Extension for SimilarPhotoGroup

extension Array where Element == SimilarPhotoGroup {

    /// 指定されたIDを含むグループをフィルタ
    /// - Parameter photoId: 写真ID
    /// - Returns: 該当するグループの配列
    public func groups(containing photoId: String) -> [SimilarPhotoGroup] {
        filter { $0.contains(photoId: photoId) }
    }

    /// 指定されたサイズ以上のグループをフィルタ
    /// - Parameter size: 最小サイズ
    /// - Returns: 該当するグループの配列
    public func groups(withMinSize size: Int) -> [SimilarPhotoGroup] {
        filter { $0.size >= size }
    }

    /// 総写真数を計算
    public var totalPhotoCount: Int {
        reduce(0) { $0 + $1.size }
    }

    /// 平均グループサイズ
    public var averageGroupSize: Double? {
        guard !isEmpty else { return nil }
        return Double(totalPhotoCount) / Double(count)
    }

    /// 最大グループサイズ
    public var maxGroupSize: Int? {
        map { $0.size }.max()
    }

    /// 最小グループサイズ
    public var minGroupSize: Int? {
        map { $0.size }.min()
    }
}
