//
//  SimilarityCalculator.swift
//  LightRoll_CleanerFeature
//
//  画像間の類似度計算エンジン
//  VNFeaturePrintObservation を使用してコサイン類似度を算出
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision

// MARK: - SimilarityCalculator

/// 画像類似度計算サービス
///
/// 主な責務:
/// - VNFeaturePrintObservation 間のコサイン類似度計算
/// - 類似写真ペアの検出
/// - 類似度マトリクスの生成
public actor SimilarityCalculator {

    // MARK: - Properties

    /// 計算オプション
    private let options: CalculationOptions

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter options: 計算オプション
    public init(options: CalculationOptions = .default) {
        self.options = options
    }

    // MARK: - Public Methods

    /// 2つの VNFeaturePrintObservation 間の類似度を計算
    ///
    /// - Parameters:
    ///   - observation1: 1つ目の特徴量
    ///   - observation2: 2つ目の特徴量
    /// - Returns: 類似度スコア（0.0〜1.0、高いほど類似）
    /// - Throws: AnalysisError
    public func calculateSimilarity(
        between observation1: VNFeaturePrintObservation,
        and observation2: VNFeaturePrintObservation
    ) throws -> Float {
        // Vision Framework の computeDistance を使用
        var distance: Float = 0
        try observation1.computeDistance(&distance, to: observation2)

        // 距離を類似度に変換（0 = 完全一致、1 = 完全不一致）
        // 類似度 = 1.0 - 距離
        let similarity = 1.0 - distance

        // 0.0〜1.0 の範囲にクランプ
        return Swift.max(0.0, Swift.min(1.0, similarity))
    }

    /// 2つの特徴量ハッシュ（Data）間のコサイン類似度を計算
    ///
    /// キャッシュされた featurePrintHash を使用して高速に類似度を計算
    /// VNFeaturePrintObservation の再抽出が不要
    ///
    /// - Parameters:
    ///   - hash1: 1つ目の特徴量ハッシュ（Float配列のData）
    ///   - hash2: 2つ目の特徴量ハッシュ（Float配列のData）
    /// - Returns: コサイン類似度スコア（0.0〜1.0）
    /// - Throws: AnalysisError（データが不正な場合）
    public func calculateSimilarityFromCache(
        hash1: Data,
        hash2: Data
    ) throws -> Float {
        // データサイズが一致することを確認
        guard hash1.count == hash2.count, hash1.count > 0 else {
            throw AnalysisError.similarityCalculationFailed
        }

        let elementCount = hash1.count / MemoryLayout<Float>.size
        guard elementCount > 0 else {
            throw AnalysisError.similarityCalculationFailed
        }

        // Float配列として読み取り、コサイン類似度を計算
        var dotProduct: Float = 0
        var magnitude1: Float = 0
        var magnitude2: Float = 0

        hash1.withUnsafeBytes { ptr1 in
            hash2.withUnsafeBytes { ptr2 in
                let floats1 = ptr1.bindMemory(to: Float.self)
                let floats2 = ptr2.bindMemory(to: Float.self)

                for i in 0..<elementCount {
                    let v1 = floats1[i]
                    let v2 = floats2[i]
                    dotProduct += v1 * v2
                    magnitude1 += v1 * v1
                    magnitude2 += v2 * v2
                }
            }
        }

        // ゼロ除算を防止
        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        guard denominator > 0 else {
            return 0.0
        }

        // コサイン類似度（-1〜1を0〜1にスケール）
        let cosineSimilarity = dotProduct / denominator
        let normalizedSimilarity = (cosineSimilarity + 1.0) / 2.0

        return Swift.max(0.0, Swift.min(1.0, normalizedSimilarity))
    }

    /// キャッシュされた特徴量ハッシュから類似ペアを検出
    ///
    /// 分析フェーズで保存された featurePrintHash を使用して高速にペアを検出
    /// VNFeaturePrintObservation の再抽出が不要なため大幅に高速化
    ///
    /// - Parameters:
    ///   - cachedFeatures: 写真IDと特徴量ハッシュのペア配列
    ///   - threshold: 類似判定の閾値
    /// - Returns: 類似ペアの配列
    /// - Throws: AnalysisError
    public func findSimilarPairsFromCache(
        cachedFeatures: [(id: String, hash: Data)],
        threshold: Float? = nil
    ) async throws -> [SimilarityPair] {
        let similarityThreshold = threshold ?? options.similarityThreshold
        var pairs: [SimilarityPair] = []

        let count = cachedFeatures.count

        // すべての組み合わせについて類似度を計算
        for i in 0..<count {
            for j in (i + 1)..<count {
                let item1 = cachedFeatures[i]
                let item2 = cachedFeatures[j]

                // キャッシュから類似度を計算
                let similarity = try calculateSimilarityFromCache(
                    hash1: item1.hash,
                    hash2: item2.hash
                )

                // 閾値以上の場合、ペアとして追加
                if similarity >= similarityThreshold {
                    let pair = SimilarityPair(
                        id1: item1.id,
                        id2: item2.id,
                        similarity: similarity
                    )
                    pairs.append(pair)
                }

                // キャンセルチェック（100ペアごと）
                if (i * count + j) % 100 == 0 {
                    try Task.checkCancellation()
                }
            }
        }

        return pairs.sorted { $0.similarity > $1.similarity }
    }

    /// LSHで絞り込まれた候補ペアのみから類似ペアを検出（高速化版）
    ///
    /// LSHハッシュで事前に絞り込まれた候補ペアに対してのみ類似度計算を実行。
    /// これによりO(n²)の全ペア比較をO(k)（k = 候補ペア数）に削減。
    ///
    /// - Parameters:
    ///   - cachedFeatures: 写真IDと特徴量ハッシュのペア配列
    ///   - candidatePairs: LSHで絞り込まれた候補ペア（ID1, ID2）のリスト
    ///   - threshold: 類似判定の閾値
    /// - Returns: 類似ペアの配列
    /// - Throws: AnalysisError
    public func findSimilarPairsFromCandidates(
        cachedFeatures: [(id: String, hash: Data)],
        candidatePairs: [(String, String)],
        threshold: Float? = nil
    ) async throws -> [SimilarityPair] {
        let similarityThreshold = threshold ?? options.similarityThreshold
        var pairs: [SimilarityPair] = []

        // IDからハッシュへの高速参照マップを作成
        var hashMap: [String: Data] = [:]
        for feature in cachedFeatures {
            hashMap[feature.id] = feature.hash
        }

        // 候補ペアに対してのみ類似度を計算
        for (index, (id1, id2)) in candidatePairs.enumerated() {
            // ハッシュが存在するかチェック
            guard let hash1 = hashMap[id1],
                  let hash2 = hashMap[id2] else {
                continue
            }

            // 類似度を計算
            let similarity = try calculateSimilarityFromCache(
                hash1: hash1,
                hash2: hash2
            )

            // 閾値以上の場合、ペアとして追加
            if similarity >= similarityThreshold {
                let pair = SimilarityPair(
                    id1: id1,
                    id2: id2,
                    similarity: similarity
                )
                pairs.append(pair)
            }

            // キャンセルチェック（100ペアごと）
            if index % 100 == 0 {
                try Task.checkCancellation()
            }
        }

        return pairs.sorted { $0.similarity > $1.similarity }
    }

    /// 複数の観測結果から類似度ペアを検出
    ///
    /// - Parameters:
    ///   - observations: 観測結果とIDのペア配列
    ///   - threshold: 類似判定の閾値（この値以上を類似とみなす）
    /// - Returns: 類似ペアの配列
    /// - Throws: AnalysisError
    public func findSimilarPairs(
        in observations: [(id: String, observation: VNFeaturePrintObservation)],
        threshold: Float? = nil
    ) async throws -> [SimilarityPair] {
        let similarityThreshold = threshold ?? options.similarityThreshold

        // 類似ペアを格納する配列
        var pairs: [SimilarityPair] = []

        // すべての組み合わせについて類似度を計算
        for i in 0..<observations.count {
            for j in (i + 1)..<observations.count {
                let item1 = observations[i]
                let item2 = observations[j]

                // 類似度を計算
                let similarity = try calculateSimilarity(
                    between: item1.observation,
                    and: item2.observation
                )

                // 閾値以上の場合、ペアとして追加
                if similarity >= similarityThreshold {
                    let pair = SimilarityPair(
                        id1: item1.id,
                        id2: item2.id,
                        similarity: similarity
                    )
                    pairs.append(pair)
                }

                // キャンセルチェック
                try Task.checkCancellation()
            }
        }

        // 類似度の降順でソート
        return pairs.sorted { $0.similarity > $1.similarity }
    }

    /// 類似度マトリクスを生成
    ///
    /// - Parameter observations: 観測結果とIDのペア配列
    /// - Returns: 類似度マトリクス
    /// - Throws: AnalysisError
    public func createSimilarityMatrix(
        for observations: [(id: String, observation: VNFeaturePrintObservation)]
    ) async throws -> SimilarityMatrix {
        let count = observations.count

        // N x N のマトリクスを作成
        var matrix = Array(
            repeating: Array(repeating: Float(0.0), count: count),
            count: count
        )

        // 対角線は 1.0（自分自身との類似度）
        for i in 0..<count {
            matrix[i][i] = 1.0
        }

        // 上三角行列を計算（対称行列なので下三角は省略）
        for i in 0..<count {
            for j in (i + 1)..<count {
                let similarity = try calculateSimilarity(
                    between: observations[i].observation,
                    and: observations[j].observation
                )

                matrix[i][j] = similarity
                matrix[j][i] = similarity // 対称性を保つ

                // キャンセルチェック
                try Task.checkCancellation()
            }
        }

        return SimilarityMatrix(
            ids: observations.map { $0.id },
            matrix: matrix
        )
    }

    /// バッチ処理で類似度を計算（メモリ効率重視）
    ///
    /// - Parameters:
    ///   - observations: 観測結果とIDのペア配列
    ///   - batchSize: バッチサイズ
    ///   - threshold: 類似判定の閾値
    /// - Returns: 類似ペアの配列
    /// - Throws: AnalysisError
    public func findSimilarPairsInBatches(
        in observations: [(id: String, observation: VNFeaturePrintObservation)],
        batchSize: Int = 100,
        threshold: Float? = nil
    ) async throws -> [SimilarityPair] {
        let similarityThreshold = threshold ?? options.similarityThreshold
        var allPairs: [SimilarityPair] = []

        // バッチごとに処理
        let batches = observations.chunked(into: batchSize)

        for (_, batch) in batches.enumerated() {
            // バッチ内のペアを検出
            let batchPairs = try await findSimilarPairs(
                in: Array(batch),
                threshold: similarityThreshold
            )

            allPairs.append(contentsOf: batchPairs)

            // キャンセルチェック
            try Task.checkCancellation()
        }

        // 重複を除去して類似度順にソート
        let uniquePairs = Set(allPairs)
        return uniquePairs.sorted { $0.similarity > $1.similarity }
    }
}

// MARK: - CalculationOptions

/// 類似度計算オプション
public struct CalculationOptions: Sendable {

    /// 類似判定の閾値（この値以上を類似とみなす）
    public let similarityThreshold: Float

    /// バッチ処理のサイズ
    public let batchSize: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        similarityThreshold: Float = AnalysisThresholds.similarityThreshold,
        batchSize: Int = 100,
        maxConcurrentOperations: Int = 4
    ) {
        self.similarityThreshold = Swift.max(0.0, Swift.min(1.0, similarityThreshold))
        self.batchSize = Swift.max(1, batchSize)
        self.maxConcurrentOperations = Swift.max(1, maxConcurrentOperations)
    }

    // MARK: - Presets

    /// デフォルトオプション（閾値 0.85）
    public static let `default` = CalculationOptions()

    /// 厳格モード（高類似度のみ検出）
    public static let strict = CalculationOptions(
        similarityThreshold: 0.95,
        batchSize: 50,
        maxConcurrentOperations: 2
    )

    /// 緩和モード（より多くの類似を検出）
    public static let relaxed = CalculationOptions(
        similarityThreshold: 0.75,
        batchSize: 200,
        maxConcurrentOperations: 8
    )
}

// MARK: - SimilarityPair

/// 類似する2つの画像のペア
public struct SimilarityPair: Sendable, Hashable, Identifiable {

    /// ペアの一意な識別子
    public let id: UUID

    /// 1つ目の写真ID
    public let id1: String

    /// 2つ目の写真ID
    public let id2: String

    /// 類似度スコア（0.0〜1.0）
    public let similarity: Float

    // MARK: - Initialization

    /// イニシャライザ
    public init(id1: String, id2: String, similarity: Float) {
        self.id = UUID()
        self.id1 = id1
        self.id2 = id2
        self.similarity = Swift.max(0.0, Swift.min(1.0, similarity))
    }

    // MARK: - Computed Properties

    /// フォーマット済み類似度（パーセント表示）
    public var formattedSimilarity: String {
        String(format: "%.1f%%", similarity * 100)
    }

    /// 両方のIDを含む配列
    public var photoIds: [String] {
        [id1, id2]
    }

    /// 指定されたIDが含まれているかチェック
    /// - Parameter photoId: 写真ID
    /// - Returns: 含まれている場合 true
    public func contains(photoId: String) -> Bool {
        id1 == photoId || id2 == photoId
    }

    /// もう一方のIDを取得
    /// - Parameter photoId: 一方の写真ID
    /// - Returns: もう一方のID（見つからない場合は nil）
    public func otherPhotoId(given photoId: String) -> String? {
        if id1 == photoId {
            return id2
        } else if id2 == photoId {
            return id1
        }
        return nil
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        // ペアの順序に依存しないハッシュ
        let sortedIds = [id1, id2].sorted()
        hasher.combine(sortedIds[0])
        hasher.combine(sortedIds[1])
    }

    public static func == (lhs: SimilarityPair, rhs: SimilarityPair) -> Bool {
        // ペアの順序に依存しない等価判定
        let lhsIds = Set([lhs.id1, lhs.id2])
        let rhsIds = Set([rhs.id1, rhs.id2])
        return lhsIds == rhsIds
    }
}

// MARK: - SimilarityPair + Comparable

extension SimilarityPair: Comparable {
    /// 類似度で比較（高類似度が先）
    public static func < (lhs: SimilarityPair, rhs: SimilarityPair) -> Bool {
        lhs.similarity > rhs.similarity
    }
}

// MARK: - SimilarityPair + Codable

extension SimilarityPair: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case id1
        case id2
        case similarity
    }
}

// MARK: - SimilarityMatrix

/// 類似度マトリクス（N x N の行列）
public struct SimilarityMatrix: Sendable {

    /// 写真IDの配列（マトリクスのインデックスに対応）
    public let ids: [String]

    /// 類似度マトリクス（N x N）
    public let matrix: [[Float]]

    // MARK: - Initialization

    /// イニシャライザ
    public init(ids: [String], matrix: [[Float]]) {
        self.ids = ids
        self.matrix = matrix
    }

    // MARK: - Computed Properties

    /// マトリクスのサイズ
    public var size: Int {
        ids.count
    }

    /// マトリクスが正方行列かチェック
    public var isSquare: Bool {
        matrix.count == size && matrix.allSatisfy { $0.count == size }
    }

    // MARK: - Access Methods

    /// 2つのIDの類似度を取得
    ///
    /// - Parameters:
    ///   - id1: 1つ目のID
    ///   - id2: 2つ目のID
    /// - Returns: 類似度（見つからない場合は nil）
    public func similarity(between id1: String, and id2: String) -> Float? {
        guard let index1 = ids.firstIndex(of: id1),
              let index2 = ids.firstIndex(of: id2) else {
            return nil
        }

        return matrix[index1][index2]
    }

    /// 指定されたIDに類似するIDの一覧を取得
    ///
    /// - Parameters:
    ///   - id: 基準となるID
    ///   - threshold: 類似判定の閾値
    /// - Returns: 類似するIDと類似度のペア配列（類似度降順）
    public func similarIds(
        to id: String,
        threshold: Float = AnalysisThresholds.similarityThreshold
    ) -> [(id: String, similarity: Float)] {
        guard let index = ids.firstIndex(of: id) else {
            return []
        }

        return ids.enumerated()
            .filter { $0.offset != index } // 自分自身を除外
            .compactMap { offset, otherId in
                let similarity = matrix[index][offset]
                return similarity >= threshold ? (otherId, similarity) : nil
            }
            .sorted { $0.similarity > $1.similarity }
    }

    /// 最も類似するIDを取得
    ///
    /// - Parameter id: 基準となるID
    /// - Returns: 最も類似するIDと類似度（見つからない場合は nil）
    public func mostSimilarId(to id: String) -> (id: String, similarity: Float)? {
        similarIds(to: id, threshold: 0.0).first
    }
}

// MARK: - Array Extension for SimilarityPair

extension Array where Element == SimilarityPair {

    /// 指定されたIDを含むペアをフィルタ
    /// - Parameter photoId: 写真ID
    /// - Returns: 該当するペアの配列
    public func pairs(containing photoId: String) -> [SimilarityPair] {
        filter { $0.contains(photoId: photoId) }
    }

    /// 指定された閾値以上のペアをフィルタ
    /// - Parameter threshold: 類似度閾値
    /// - Returns: 該当するペアの配列
    public func pairs(aboveThreshold threshold: Float) -> [SimilarityPair] {
        filter { $0.similarity >= threshold }
    }

    /// 平均類似度を計算
    public var averageSimilarity: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.similarity }
        return sum / Float(count)
    }

    /// 最高類似度を取得
    public var maxSimilarity: Float? {
        map { $0.similarity }.max()
    }

    /// 最低類似度を取得
    public var minSimilarity: Float? {
        map { $0.similarity }.min()
    }

    /// すべての写真IDを取得（重複なし）
    public var allPhotoIds: Set<String> {
        var ids = Set<String>()
        for pair in self {
            ids.insert(pair.id1)
            ids.insert(pair.id2)
        }
        return ids
    }
}

// MARK: - Collection Extension (Chunked)

extension Collection {
    /// コレクションを指定されたサイズのチャンクに分割
    /// - Parameter size: チャンクサイズ
    /// - Returns: チャンクの配列
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(dropFirst($0).prefix(size))
        }
    }
}
