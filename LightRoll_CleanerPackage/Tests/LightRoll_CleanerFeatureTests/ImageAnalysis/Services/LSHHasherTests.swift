import Testing
import Foundation
@testable import LightRoll_CleanerFeature

/// LSHHasherのテストスイート
@Suite("LSHHasher Tests")
struct LSHHasherTests {

    // MARK: - Helper Methods

    /// テスト用の特徴量データを生成（512次元のFloat配列）
    private func createFeatureData(seed: Int = 0) -> Data {
        var generator = TestRandomGenerator(seed: UInt64(seed))
        let features: [Float] = (0..<512).map { _ in
            Float.random(in: -1...1, using: &generator)
        }
        return Data(bytes: features, count: features.count * MemoryLayout<Float>.stride)
    }

    /// 類似した特徴量データを生成（元データに小さなノイズを追加）
    private func createSimilarFeatureData(original: Data, noise: Float = 0.1) -> Data {
        let originalFeatures = original.withUnsafeBytes { buffer -> [Float] in
            guard let baseAddress = buffer.baseAddress else { return [] }
            return Array(
                UnsafeBufferPointer(
                    start: baseAddress.assumingMemoryBound(to: Float.self),
                    count: buffer.count / MemoryLayout<Float>.stride
                )
            )
        }

        var generator = TestRandomGenerator(seed: 12345)
        let noisyFeatures: [Float] = originalFeatures.map { value in
            value + Float.random(in: -noise...noise, using: &generator)
        }

        return Data(bytes: noisyFeatures, count: noisyFeatures.count * MemoryLayout<Float>.stride)
    }

    // MARK: - 正常系テスト: computeLSHHash

    @Test("同一データから同一ハッシュが生成されること")
    func testComputeLSHHash_SameDataProducesSameHash() async {
        let hasher = LSHHasher()
        let featureData = createFeatureData(seed: 100)

        let hash1 = await hasher.computeLSHHash(from: featureData)
        let hash2 = await hasher.computeLSHHash(from: featureData)

        #expect(hash1 == hash2)
        #expect(hash1 != 0) // 有効なハッシュ値が生成されていること
    }

    @Test("類似データから近いハッシュが生成されること")
    func testComputeLSHHash_SimilarDataProducesSimilarHash() async {
        let hasher = LSHHasher()
        let originalData = createFeatureData(seed: 200)
        let similarData = createSimilarFeatureData(original: originalData, noise: 0.05)

        let hash1 = await hasher.computeLSHHash(from: originalData)
        let hash2 = await hasher.computeLSHHash(from: similarData)

        // ハミング距離を計算（異なるビット数）
        let hammingDistance = (hash1 ^ hash2).nonzeroBitCount

        // 類似データはハミング距離が小さいはず（64ビット中、20ビット以下の差）
        #expect(hammingDistance < 20)
    }

    @Test("異なるシードで異なるハッシュが生成されること")
    func testComputeLSHHash_DifferentSeedsProduceDifferentHashes() async {
        let hasher1 = LSHHasher(seed: 42)
        let hasher2 = LSHHasher(seed: 1000)
        let featureData = createFeatureData(seed: 300)

        let hash1 = await hasher1.computeLSHHash(from: featureData)
        let hash2 = await hasher2.computeLSHHash(from: featureData)

        #expect(hash1 != hash2) // 異なるシードなら異なるハッシュ
    }

    @Test("同一シードで再現性があること")
    func testComputeLSHHash_SameSeedProducesReproducibleHash() async {
        let featureData = createFeatureData(seed: 400)

        let hasher1 = LSHHasher(seed: 42)
        let hash1 = await hasher1.computeLSHHash(from: featureData)

        let hasher2 = LSHHasher(seed: 42)
        let hash2 = await hasher2.computeLSHHash(from: featureData)

        #expect(hash1 == hash2) // 同一シードなら完全に同じハッシュ
    }

    // MARK: - 異常系テスト: computeLSHHash

    @Test("空データに対して0を返すこと")
    func testComputeLSHHash_EmptyDataReturnsZero() async {
        let hasher = LSHHasher()
        let emptyData = Data()

        let hash = await hasher.computeLSHHash(from: emptyData)

        #expect(hash == 0)
    }

    @Test("不正なサイズのデータに対して0を返すこと")
    func testComputeLSHHash_InvalidSizeReturnsZero() async {
        let hasher = LSHHasher()
        // 256次元のデータ（本来は512次元必要）
        let invalidData = createFeatureData(seed: 500).prefix(256 * MemoryLayout<Float>.stride)

        let hash = await hasher.computeLSHHash(from: Data(invalidData))

        #expect(hash == 0)
    }

    @Test("サイズ超過のデータに対して0を返すこと")
    func testComputeLSHHash_OversizedDataReturnsZero() async {
        let hasher = LSHHasher()
        // 1024次元のデータ（本来は512次元）
        let features: [Float] = (0..<1024).map { _ in Float.random(in: -1...1) }
        let oversizedData = Data(bytes: features, count: features.count * MemoryLayout<Float>.stride)

        let hash = await hasher.computeLSHHash(from: oversizedData)

        #expect(hash == 0)
    }

    // MARK: - 正常系テスト: groupByLSH

    @Test("類似特徴量が同一バケットにグルーピングされること")
    func testGroupByLSH_SimilarFeaturesGroupedTogether() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData(seed: 600)
        let data2 = createSimilarFeatureData(original: data1, noise: 0.05)
        let data3 = createFeatureData(seed: 700) // 全く異なるデータ

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2),
            (id: "id3", hash: data3)
        ]

        let groups = await hasher.groupByLSH(features: features)

        // id1とid2が同じグループに入る可能性が高い
        // （LSHの確率的性質により100%ではないが、高確率で同じグループ）
        #expect(groups.count >= 1)

        // 少なくとも1つのグループにid1とid2が含まれているか確認
        let containsBothSimilar = groups.contains { group in
            group.contains("id1") && group.contains("id2")
        }
        #expect(containsBothSimilar)
    }

    @Test("単独の特徴量はグループから除外されること")
    func testGroupByLSH_SingleItemsExcluded() async {
        let hasher = LSHHasher()

        // 全て異なるシードで生成（各バケットに1つずつ入る可能性が高い）
        let features = [
            (id: "id1", hash: createFeatureData(seed: 1000)),
            (id: "id2", hash: createFeatureData(seed: 2000)),
            (id: "id3", hash: createFeatureData(seed: 3000))
        ]

        let groups = await hasher.groupByLSH(features: features)

        // 単独バケットは除外されるため、グループ数は少ないはず
        // （偶然同じバケットに入る可能性もあるので、完全に0とは限らない）
        #expect(groups.allSatisfy { $0.count >= 2 })
    }

    @Test("空配列に対して空配列を返すこと")
    func testGroupByLSH_EmptyInputReturnsEmpty() async {
        let hasher = LSHHasher()
        let emptyFeatures: [(id: String, hash: Data)] = []

        let groups = await hasher.groupByLSH(features: emptyFeatures)

        #expect(groups.isEmpty)
    }

    // MARK: - 正常系テスト: findCandidatePairs

    @Test("候補ペアが正しく生成されること")
    func testFindCandidatePairs_GeneratesPairs() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData(seed: 800)
        let data2 = createSimilarFeatureData(original: data1, noise: 0.05)
        let data3 = createSimilarFeatureData(original: data1, noise: 0.05)

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2),
            (id: "id3", hash: data3)
        ]

        let pairs = await hasher.findCandidatePairs(features: features)

        // 少なくとも1つのペアが生成されること
        #expect(pairs.count >= 1)

        // ペアに重複がないこと
        let pairSet = Set(pairs.map { "\($0.0)|\($0.1)" })
        #expect(pairSet.count == pairs.count)
    }

    @Test("単一要素に対して空配列を返すこと")
    func testFindCandidatePairs_SingleItemReturnsEmpty() async {
        let hasher = LSHHasher()
        let features = [
            (id: "id1", hash: createFeatureData(seed: 900))
        ]

        let pairs = await hasher.findCandidatePairs(features: features)

        #expect(pairs.isEmpty)
    }

    @Test("ペアの順序が一貫していること")
    func testFindCandidatePairs_ConsistentOrdering() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData(seed: 1100)
        let data2 = createSimilarFeatureData(original: data1, noise: 0.05)

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2)
        ]

        let pairs = await hasher.findCandidatePairs(features: features)

        // ペアが生成された場合、順序をチェック
        if let pair = pairs.first {
            #expect(pair.0 == "id1" && pair.1 == "id2")
        }
    }

    // MARK: - 正常系テスト: findCandidatePairsMultiProbe

    @Test("マルチプローブで再現率が向上すること")
    func testFindCandidatePairsMultiProbe_ImprovedRecall() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData(seed: 1200)
        let data2 = createSimilarFeatureData(original: data1, noise: 0.1) // やや大きめのノイズ
        let data3 = createSimilarFeatureData(original: data1, noise: 0.1)

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2),
            (id: "id3", hash: data3)
        ]

        // シングルプローブ
        let singlePairs = await hasher.findCandidatePairs(features: features)

        // マルチプローブ（4テーブル）
        let multiPairs = await hasher.findCandidatePairsMultiProbe(
            features: features,
            numberOfHashTables: 4
        )

        // マルチプローブの方がペア数が多いか同等であること
        #expect(multiPairs.count >= singlePairs.count)
    }

    @Test("マルチプローブで重複が削除されること")
    func testFindCandidatePairsMultiProbe_RemovesDuplicates() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData(seed: 1300)
        let data2 = createSimilarFeatureData(original: data1, noise: 0.05)

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2)
        ]

        let pairs = await hasher.findCandidatePairsMultiProbe(
            features: features,
            numberOfHashTables: 4
        )

        // ペアに重複がないこと
        let pairSet = Set(pairs.map { min($0.0, $0.1) + "|" + max($0.0, $0.1) })
        #expect(pairSet.count == pairs.count)
    }

    @Test("マルチプローブのハッシュテーブル数が結果に影響すること")
    func testFindCandidatePairsMultiProbe_NumberOfTablesAffectsResults() async {
        let hasher = LSHHasher()

        let features = (0..<10).map { i in
            (id: "id\(i)", hash: createFeatureData(seed: 1400 + i))
        }

        let pairs2Tables = await hasher.findCandidatePairsMultiProbe(
            features: features,
            numberOfHashTables: 2
        )

        let pairs8Tables = await hasher.findCandidatePairsMultiProbe(
            features: features,
            numberOfHashTables: 8
        )

        // テーブル数が多いほど、候補ペア数が増える傾向
        // （確率的性質により必ずしも増えるとは限らないが、通常は増加）
        #expect(pairs8Tables.count >= pairs2Tables.count)
    }

    // MARK: - 境界値テスト

    @Test("大量データでもパフォーマンスが許容範囲内であること")
    func testGroupByLSH_LargeDatasetPerformance() async {
        let hasher = LSHHasher()

        // 1000件のデータ（実際のユースケースより少ないが、テストとしては十分）
        let features = (0..<1000).map { i in
            (id: "id\(i)", hash: createFeatureData(seed: 2000 + i))
        }

        let startTime = Date()
        let groups = await hasher.groupByLSH(features: features)
        let elapsedTime = Date().timeIntervalSince(startTime)

        // グルーピングが完了すること
        #expect(groups.count >= 0)

        // 処理時間が5秒以内であること（妥当な範囲）
        #expect(elapsedTime < 5.0)
    }

    @Test("異なるビット数のハッシャーが正常に動作すること")
    func testDifferentBitCounts_WorkCorrectly() async {
        let hasher32 = LSHHasher(numberOfBits: 32)
        let hasher128 = LSHHasher(numberOfBits: 128)

        let featureData = createFeatureData(seed: 1500)

        let hash32 = await hasher32.computeLSHHash(from: featureData)
        let hash128 = await hasher128.computeLSHHash(from: featureData)

        // どちらも有効なハッシュ値が生成されること
        #expect(hash32 != 0)
        #expect(hash128 != 0)

        // 異なるビット数なので異なる値になる可能性が高い
        #expect(hash32 != hash128)
    }

    @Test("最小ビット数（1ビット）でも動作すること")
    func testMinimumBitCount_WorksCorrectly() async {
        let hasher = LSHHasher(numberOfBits: 1)
        let featureData = createFeatureData(seed: 1600)

        let hash = await hasher.computeLSHHash(from: featureData)

        // 1ビットなので、値は0または1
        #expect(hash == 0 || hash == 1)
    }

    @Test("最大ビット数（64ビット）でも動作すること")
    func testMaximumBitCount_WorksCorrectly() async {
        let hasher = LSHHasher(numberOfBits: 64)
        let featureData = createFeatureData(seed: 1700)

        let hash = await hasher.computeLSHHash(from: featureData)

        // 64ビットの有効なハッシュ値が生成されること
        #expect(hash != 0)
    }

    // MARK: - 動的次元数対応テスト（VNFeaturePrint互換）

    @Test("2048次元（VNFeaturePrint標準）で動的検出が正常に動作すること")
    func testDynamicDimensionDetection_2048Dimensions() async {
        // featureDimensionを指定せずに初期化（動的検出モード）
        let hasher = LSHHasher()
        let featureData = createFeatureData2048(seed: 2000)

        let hash = await hasher.computeLSHHash(from: featureData)

        // 有効なハッシュ値が生成されること（0以外）
        #expect(hash != 0)
    }

    @Test("動的次元数検出で同一データから同一ハッシュが生成されること")
    func testDynamicDimension_SameDataProducesSameHash() async {
        let hasher = LSHHasher()
        let featureData = createFeatureData2048(seed: 2100)

        let hash1 = await hasher.computeLSHHash(from: featureData)
        let hash2 = await hasher.computeLSHHash(from: featureData)

        #expect(hash1 == hash2)
        #expect(hash1 != 0)
    }

    @Test("動的次元数検出で類似データから近いハッシュが生成されること")
    func testDynamicDimension_SimilarDataProducesSimilarHash() async {
        let hasher = LSHHasher()
        let originalData = createFeatureData2048(seed: 2200)
        let similarData = createSimilarFeatureData2048(original: originalData, noise: 0.05)

        let hash1 = await hasher.computeLSHHash(from: originalData)
        let hash2 = await hasher.computeLSHHash(from: similarData)

        // ハミング距離を計算（異なるビット数）
        let hammingDistance = (hash1 ^ hash2).nonzeroBitCount

        // 類似データはハミング距離が小さいはず（64ビット中、20ビット以下の差）
        #expect(hammingDistance < 20)
    }

    @Test("動的次元数でグルーピングが正常に動作すること")
    func testDynamicDimension_GroupByLSH() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData2048(seed: 2300)
        let data2 = createSimilarFeatureData2048(original: data1, noise: 0.05)
        let data3 = createFeatureData2048(seed: 2400) // 全く異なるデータ

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2),
            (id: "id3", hash: data3)
        ]

        let groups = await hasher.groupByLSH(features: features)

        // グループが生成されること
        #expect(groups.count >= 1)

        // id1とid2が同じグループに入る可能性が高い
        let containsBothSimilar = groups.contains { group in
            group.contains("id1") && group.contains("id2")
        }
        #expect(containsBothSimilar)
    }

    @Test("動的次元数で候補ペアが正しく生成されること")
    func testDynamicDimension_FindCandidatePairs() async {
        let hasher = LSHHasher()

        let data1 = createFeatureData2048(seed: 2500)
        let data2 = createSimilarFeatureData2048(original: data1, noise: 0.05)
        let data3 = createSimilarFeatureData2048(original: data1, noise: 0.05)

        let features = [
            (id: "id1", hash: data1),
            (id: "id2", hash: data2),
            (id: "id3", hash: data3)
        ]

        let pairs = await hasher.findCandidatePairs(features: features)

        // 少なくとも1つのペアが生成されること
        #expect(pairs.count >= 1)

        // ペアに重複がないこと
        let pairSet = Set(pairs.map { "\($0.0)|\($0.1)" })
        #expect(pairSet.count == pairs.count)
    }

    // MARK: - 2048次元用ヘルパーメソッド

    /// 2048次元のテスト用特徴量データを生成（VNFeaturePrint互換）
    private func createFeatureData2048(seed: Int = 0) -> Data {
        var generator = TestRandomGenerator(seed: UInt64(seed))
        let features: [Float] = (0..<2048).map { _ in
            Float.random(in: -1...1, using: &generator)
        }
        return Data(bytes: features, count: features.count * MemoryLayout<Float>.stride)
    }

    /// 2048次元の類似した特徴量データを生成
    private func createSimilarFeatureData2048(original: Data, noise: Float = 0.1) -> Data {
        let originalFeatures = original.withUnsafeBytes { buffer -> [Float] in
            guard let baseAddress = buffer.baseAddress else { return [] }
            return Array(
                UnsafeBufferPointer(
                    start: baseAddress.assumingMemoryBound(to: Float.self),
                    count: buffer.count / MemoryLayout<Float>.stride
                )
            )
        }

        var generator = TestRandomGenerator(seed: 12345)
        let noisyFeatures: [Float] = originalFeatures.map { value in
            value + Float.random(in: -noise...noise, using: &generator)
        }

        return Data(bytes: noisyFeatures, count: noisyFeatures.count * MemoryLayout<Float>.stride)
    }
}

// MARK: - Supporting Types

/// テスト用のシード固定ランダム数生成器
private struct TestRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
