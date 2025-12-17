import Foundation

/// Locality-Sensitive Hashing (LSH) を使用した高速類似画像グルーピング
///
/// ## 概要
/// - 特徴量ハッシュ（Data型、Float配列）からLSHハッシュを生成
/// - ハイパープレーンを使用したランダム射影方式
/// - 同一バケット内のみを比較対象にすることでO(n²) → O(n)に近づける
///
/// ## 性能目標
/// - 7000枚: 350,000比較 → 約7,000回ハッシュ計算 + α比較（98%削減）
/// - ハッシュ計算: O(n×d) (d = 特徴量次元数)
/// - バケット内比較: O(n×k) (k = バケットサイズ平均、k << n)
///
/// ## 次元数対応
/// - featureDimension = nil の場合、最初の特徴量から自動検出
/// - VNFeaturePrintObservation は通常2048次元
public actor LSHHasher: Sendable {
    // MARK: - Properties

    /// ハッシュビット数（調整可能）
    private let numberOfBits: Int

    /// ランダム射影ベクトル（遅延生成）
    private var projectionVectors: [[Float]]?

    /// 特徴量の次元数（nil時は自動検出）
    private var featureDimension: Int?

    /// ランダムシード（再現性確保）
    private let seed: UInt64

    // MARK: - Initialization

    /// LSHHasherを初期化
    /// - Parameters:
    ///   - numberOfBits: ハッシュビット数（デフォルト: 64）
    ///   - featureDimension: 特徴量の次元数（nil時は自動検出、VNFeaturePrintは2048）
    ///   - seed: ランダム射影ベクトル生成のシード値（再現性確保）
    public init(
        numberOfBits: Int = 64,
        featureDimension: Int? = nil,
        seed: UInt64 = 42
    ) {
        self.numberOfBits = numberOfBits
        self.featureDimension = featureDimension
        self.seed = seed

        // featureDimensionが指定されている場合は即座にプロジェクションベクトルを生成
        if let dimension = featureDimension {
            self.projectionVectors = Self.generateProjectionVectors(
                numberOfBits: numberOfBits,
                featureDimension: dimension,
                seed: seed
            )
        } else {
            self.projectionVectors = nil
        }
    }

    // MARK: - Private Methods

    /// プロジェクションベクトルを生成（静的メソッド）
    private static func generateProjectionVectors(
        numberOfBits: Int,
        featureDimension: Int,
        seed: UInt64
    ) -> [[Float]] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return (0..<numberOfBits).map { _ in
            (0..<featureDimension).map { _ in
                Float.random(in: -1...1, using: &generator)
            }
        }
    }

    /// 必要に応じてプロジェクションベクトルを初期化（actor内で状態変更）
    private func ensureProjectionVectors(for dimension: Int) {
        guard projectionVectors == nil else { return }

        featureDimension = dimension
        projectionVectors = Self.generateProjectionVectors(
            numberOfBits: numberOfBits,
            featureDimension: dimension,
            seed: seed
        )
        logInfo("🔧 LSHHasher: 次元数\(dimension)を自動検出、プロジェクションベクトル生成完了", category: .analysis)
    }

    // MARK: - Public Methods

    /// 特徴量ハッシュからLSHハッシュを計算
    /// - Parameter featureHash: 特徴量ハッシュ（Data型、Float配列）
    /// - Returns: 64ビットLSHハッシュ
    public func computeLSHHash(from featureHash: Data) -> UInt64 {
        // DataをFloat配列に変換
        let features = featureHash.withUnsafeBytes { buffer -> [Float] in
            guard let baseAddress = buffer.baseAddress else {
                return []
            }
            return Array(
                UnsafeBufferPointer(
                    start: baseAddress.assumingMemoryBound(to: Float.self),
                    count: buffer.count / MemoryLayout<Float>.stride
                )
            )
        }

        // 空の特徴量は0を返す
        guard !features.isEmpty else {
            return 0
        }

        // 動的次元数検出: プロジェクションベクトルが未初期化なら生成
        if projectionVectors == nil {
            ensureProjectionVectors(for: features.count)
        }

        // 次元数チェック（初期化後）
        guard let currentDimension = featureDimension,
              features.count == currentDimension,
              let vectors = projectionVectors else {
            // 次元数が異なる場合は0を返す（エラーハンドリング）
            logWarning("⚠️ LSHHasher: 次元数不一致 (expected: \(featureDimension ?? -1), actual: \(features.count))", category: .analysis)
            return 0
        }

        // 各射影ベクトルとの内積を計算してビットを生成
        var hash: UInt64 = 0
        for (index, projectionVector) in vectors.enumerated() {
            // 内積計算: dot(features, projectionVector)
            let dotProduct = zip(features, projectionVector)
                .map { $0 * $1 }
                .reduce(0, +)

            // 内積が正なら1、負なら0をビットとして設定
            if dotProduct > 0 {
                hash |= (1 << index)
            }
        }

        return hash
    }

    /// 特徴量リストをLSHでグルーピング
    /// - Parameter features: 特徴量ハッシュのリスト（ID + Data）
    /// - Returns: 同一バケットのIDグループの配列
    public func groupByLSH(features: [(id: String, hash: Data)]) async -> [[String]] {
        // LSHハッシュごとにバケット化
        var buckets: [UInt64: [String]] = [:]

        for feature in features {
            let lshHash = computeLSHHash(from: feature.hash)
            buckets[lshHash, default: []].append(feature.id)
        }

        // バケットサイズが2以上のもののみ返す（単独は類似候補なし）
        return buckets.values
            .filter { $0.count > 1 }
            .map { Array($0) }
    }

    /// LSHを使用して類似候補ペアを高速検出
    /// - Parameter features: 特徴量ハッシュのリスト（ID + Data）
    /// - Returns: 類似候補ペアの配列
    public func findCandidatePairs(features: [(id: String, hash: Data)]) async -> [(String, String)] {
        // グルーピング実行
        let groups = await groupByLSH(features: features)

        // 各グループ内でペアを生成
        var pairs: [(String, String)] = []
        for group in groups {
            // グループ内の全ペアを生成（重複なし）
            for i in 0..<group.count {
                for j in (i + 1)..<group.count {
                    pairs.append((group[i], group[j]))
                }
            }
        }

        return pairs
    }

    /// 複数のLSHハッシュを使用したマルチプローブLSH（精度向上版）
    /// - Parameters:
    ///   - features: 特徴量ハッシュのリスト
    ///   - numberOfHashTables: ハッシュテーブル数（デフォルト: 4）
    /// - Returns: 類似候補ペアの配列（重複削除済み）
    public func findCandidatePairsMultiProbe(
        features: [(id: String, hash: Data)],
        numberOfHashTables: Int = 4
    ) async -> [(String, String)] {
        // 複数のシードで複数のLSHハッシュを計算
        var allPairs: Set<String> = []

        for tableIndex in 0..<numberOfHashTables {
            // 異なるシードでLSHHasherを作成
            let hasher = LSHHasher(
                numberOfBits: numberOfBits,
                featureDimension: featureDimension,
                seed: UInt64(42 + tableIndex * 1000)
            )

            // 候補ペアを取得
            let pairs = await hasher.findCandidatePairs(features: features)

            // ペアを正規化して追加（id1 < id2 の順序で）
            for (id1, id2) in pairs {
                let normalizedPair = id1 < id2 ? "\(id1)|\(id2)" : "\(id2)|\(id1)"
                allPairs.insert(normalizedPair)
            }
        }

        // Set<String> から [(String, String)] に変換
        return allPairs.map { pairString in
            let components = pairString.split(separator: "|").map(String.init)
            return (components[0], components[1])
        }
    }
}

// MARK: - Supporting Types

/// シード固定のランダム数生成器（再現性確保）
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // XORShift64アルゴリズム
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
