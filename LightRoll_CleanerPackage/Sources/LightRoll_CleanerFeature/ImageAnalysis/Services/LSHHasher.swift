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
public actor LSHHasher: Sendable {
    // MARK: - Properties

    /// ハッシュビット数（調整可能）
    private let numberOfBits: Int

    /// ランダム射影ベクトル（再現性のためシード固定）
    private let projectionVectors: [[Float]]

    /// 特徴量の次元数（CLIP特徴量は512次元）
    private let featureDimension: Int

    // MARK: - Initialization

    /// LSHHasherを初期化
    /// - Parameters:
    ///   - numberOfBits: ハッシュビット数（デフォルト: 64）
    ///   - featureDimension: 特徴量の次元数（デフォルト: 512、CLIP特徴量）
    ///   - seed: ランダム射影ベクトル生成のシード値（再現性確保）
    public init(
        numberOfBits: Int = 64,
        featureDimension: Int = 512,
        seed: UInt64 = 42
    ) {
        self.numberOfBits = numberOfBits
        self.featureDimension = featureDimension

        // ランダム射影ベクトルを生成（シード固定で再現性確保）
        var generator = SeededRandomNumberGenerator(seed: seed)
        self.projectionVectors = (0..<numberOfBits).map { _ in
            (0..<featureDimension).map { _ in
                Float.random(in: -1...1, using: &generator)
            }
        }
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

        // 次元数チェック
        guard features.count == featureDimension else {
            // 次元数が異なる場合は0を返す（エラーハンドリング）
            return 0
        }

        // 各射影ベクトルとの内積を計算してビットを生成
        var hash: UInt64 = 0
        for (index, projectionVector) in projectionVectors.enumerated() {
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
