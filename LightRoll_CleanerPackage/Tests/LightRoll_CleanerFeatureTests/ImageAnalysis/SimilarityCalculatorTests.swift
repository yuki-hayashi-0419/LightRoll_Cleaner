//
//  SimilarityCalculatorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SimilarityCalculator のテスト
//  Created by AI Assistant
//

import Testing
import Vision
@testable import LightRoll_CleanerFeature

// MARK: - SimilarityCalculatorTests

@Suite("SimilarityCalculator Tests")
struct SimilarityCalculatorTests {

    // MARK: - Initialization Tests

    @Test("初期化: デフォルトオプションで正常に作成できる")
    func testInitialization() async {
        let calculator = SimilarityCalculator()
        #expect(calculator != nil)
    }

    @Test("初期化: カスタムオプションで正常に作成できる")
    func testInitializationWithCustomOptions() async {
        let options = CalculationOptions.strict
        let calculator = SimilarityCalculator(options: options)
        #expect(calculator != nil)
    }

    // MARK: - CalculationOptions Tests

    @Test("CalculationOptions: デフォルト値の検証")
    func testDefaultCalculationOptions() {
        let options = CalculationOptions.default
        #expect(options.similarityThreshold == AnalysisThresholds.similarityThreshold)
        #expect(options.batchSize == 100)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("CalculationOptions: strict プリセットの検証")
    func testStrictOptions() {
        let options = CalculationOptions.strict
        #expect(options.similarityThreshold == 0.95)
        #expect(options.batchSize == 50)
        #expect(options.maxConcurrentOperations == 2)
    }

    @Test("CalculationOptions: relaxed プリセットの検証")
    func testRelaxedOptions() {
        let options = CalculationOptions.relaxed
        #expect(options.similarityThreshold == 0.75)
        #expect(options.batchSize == 200)
        #expect(options.maxConcurrentOperations == 8)
    }

    @Test("CalculationOptions: 閾値が 0.0〜1.0 にクランプされる")
    func testOptionsThresholdClamping() {
        let optionsHigh = CalculationOptions(similarityThreshold: 1.5)
        #expect(optionsHigh.similarityThreshold == 1.0)

        let optionsLow = CalculationOptions(similarityThreshold: -0.5)
        #expect(optionsLow.similarityThreshold == 0.0)
    }

    // MARK: - SimilarityPair Tests

    @Test("SimilarityPair: 初期化とプロパティ")
    func testSimilarityPairInitialization() {
        let pair = SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.87)

        #expect(pair.id1 == "photo1")
        #expect(pair.id2 == "photo2")
        #expect(pair.similarity == 0.87)
    }

    @Test("SimilarityPair: 類似度が 0.0〜1.0 にクランプされる")
    func testSimilarityPairClamping() {
        let pairHigh = SimilarityPair(id1: "p1", id2: "p2", similarity: 1.5)
        #expect(pairHigh.similarity == 1.0)

        let pairLow = SimilarityPair(id1: "p1", id2: "p2", similarity: -0.5)
        #expect(pairLow.similarity == 0.0)
    }

    @Test("SimilarityPair: formattedSimilarity の検証")
    func testSimilarityPairFormattedSimilarity() {
        let pair = SimilarityPair(id1: "p1", id2: "p2", similarity: 0.875)
        #expect(pair.formattedSimilarity == "87.5%")
    }

    @Test("SimilarityPair: photoIds プロパティ")
    func testSimilarityPairPhotoIds() {
        let pair = SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9)
        #expect(pair.photoIds == ["photo1", "photo2"])
    }

    @Test("SimilarityPair: contains(photoId:) の検証")
    func testSimilarityPairContains() {
        let pair = SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9)

        #expect(pair.contains(photoId: "photo1"))
        #expect(pair.contains(photoId: "photo2"))
        #expect(!pair.contains(photoId: "photo3"))
    }

    @Test("SimilarityPair: otherPhotoId(given:) の検証")
    func testSimilarityPairOtherPhotoId() {
        let pair = SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9)

        #expect(pair.otherPhotoId(given: "photo1") == "photo2")
        #expect(pair.otherPhotoId(given: "photo2") == "photo1")
        #expect(pair.otherPhotoId(given: "photo3") == nil)
    }

    @Test("SimilarityPair: Hashable の検証（順序非依存）")
    func testSimilarityPairHashable() {
        let pair1 = SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9)
        let pair2 = SimilarityPair(id1: "photo2", id2: "photo1", similarity: 0.9)

        // 順序が異なっても同じペアとみなされる
        #expect(pair1 == pair2)

        let set: Set<SimilarityPair> = [pair1, pair2]
        #expect(set.count == 1)
    }

    @Test("SimilarityPair: Comparable の検証")
    func testSimilarityPairComparable() {
        let pair1 = SimilarityPair(id1: "p1", id2: "p2", similarity: 0.9)
        let pair2 = SimilarityPair(id1: "p3", id2: "p4", similarity: 0.7)

        // 高類似度が先（< 演算子は逆順）
        #expect(pair1 < pair2)

        let sorted = [pair2, pair1].sorted()
        #expect(sorted[0].similarity == 0.9)
        #expect(sorted[1].similarity == 0.7)
    }

    // MARK: - SimilarityMatrix Tests

    @Test("SimilarityMatrix: 初期化とプロパティ")
    func testSimilarityMatrixInitialization() {
        let ids = ["photo1", "photo2", "photo3"]
        let matrix: [[Float]] = [
            [1.0, 0.8, 0.6],
            [0.8, 1.0, 0.7],
            [0.6, 0.7, 1.0]
        ]

        let simMatrix = SimilarityMatrix(ids: ids, matrix: matrix)

        #expect(simMatrix.size == 3)
        #expect(simMatrix.isSquare)
    }

    @Test("SimilarityMatrix: similarity(between:and:) の検証")
    func testSimilarityMatrixLookup() {
        let ids = ["photo1", "photo2", "photo3"]
        let matrix: [[Float]] = [
            [1.0, 0.8, 0.6],
            [0.8, 1.0, 0.7],
            [0.6, 0.7, 1.0]
        ]

        let simMatrix = SimilarityMatrix(ids: ids, matrix: matrix)

        #expect(simMatrix.similarity(between: "photo1", and: "photo2") == 0.8)
        #expect(simMatrix.similarity(between: "photo2", and: "photo3") == 0.7)
        #expect(simMatrix.similarity(between: "photo1", and: "photo3") == 0.6)

        // 存在しないID
        #expect(simMatrix.similarity(between: "photo1", and: "photo99") == nil)
    }

    @Test("SimilarityMatrix: similarIds(to:threshold:) の検証")
    func testSimilarityMatrixSimilarIds() {
        let ids = ["photo1", "photo2", "photo3"]
        let matrix: [[Float]] = [
            [1.0, 0.9, 0.6],
            [0.9, 1.0, 0.7],
            [0.6, 0.7, 1.0]
        ]

        let simMatrix = SimilarityMatrix(ids: ids, matrix: matrix)

        let similar = simMatrix.similarIds(to: "photo1", threshold: 0.8)
        #expect(similar.count == 1)
        #expect(similar[0].id == "photo2")
        #expect(similar[0].similarity == 0.9)
    }

    @Test("SimilarityMatrix: mostSimilarId(to:) の検証")
    func testSimilarityMatrixMostSimilar() {
        let ids = ["photo1", "photo2", "photo3"]
        let matrix: [[Float]] = [
            [1.0, 0.9, 0.6],
            [0.9, 1.0, 0.7],
            [0.6, 0.7, 1.0]
        ]

        let simMatrix = SimilarityMatrix(ids: ids, matrix: matrix)

        let mostSimilar = simMatrix.mostSimilarId(to: "photo1")
        #expect(mostSimilar?.id == "photo2")
        #expect(mostSimilar?.similarity == 0.9)
    }

    // MARK: - Array Extension Tests (SimilarityPair)

    @Test("Array Extension: pairs(containing:) で写真を含むペアをフィルタ")
    func testArrayPairsContaining() {
        let pairs = [
            SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9),
            SimilarityPair(id1: "photo2", id2: "photo3", similarity: 0.8),
            SimilarityPair(id1: "photo3", id2: "photo4", similarity: 0.7)
        ]

        let filtered = pairs.pairs(containing: "photo2")
        #expect(filtered.count == 2)
    }

    @Test("Array Extension: pairs(aboveThreshold:) で閾値以上のペアをフィルタ")
    func testArrayPairsAboveThreshold() {
        let pairs = [
            SimilarityPair(id1: "p1", id2: "p2", similarity: 0.95),
            SimilarityPair(id1: "p3", id2: "p4", similarity: 0.85),
            SimilarityPair(id1: "p5", id2: "p6", similarity: 0.75)
        ]

        let filtered = pairs.pairs(aboveThreshold: 0.8)
        #expect(filtered.count == 2)
    }

    @Test("Array Extension: averageSimilarity の計算")
    func testArrayAverageSimilarity() {
        let pairs = [
            SimilarityPair(id1: "p1", id2: "p2", similarity: 0.9),
            SimilarityPair(id1: "p3", id2: "p4", similarity: 0.8),
            SimilarityPair(id1: "p5", id2: "p6", similarity: 0.7)
        ]

        let average = pairs.averageSimilarity
        #expect(average == 0.8)
    }

    @Test("Array Extension: maxSimilarity の取得")
    func testArrayMaxSimilarity() {
        let pairs = [
            SimilarityPair(id1: "p1", id2: "p2", similarity: 0.95),
            SimilarityPair(id1: "p3", id2: "p4", similarity: 0.85),
            SimilarityPair(id1: "p5", id2: "p6", similarity: 0.75)
        ]

        #expect(pairs.maxSimilarity == 0.95)
    }

    @Test("Array Extension: minSimilarity の取得")
    func testArrayMinSimilarity() {
        let pairs = [
            SimilarityPair(id1: "p1", id2: "p2", similarity: 0.95),
            SimilarityPair(id1: "p3", id2: "p4", similarity: 0.85),
            SimilarityPair(id1: "p5", id2: "p6", similarity: 0.75)
        ]

        #expect(pairs.minSimilarity == 0.75)
    }

    @Test("Array Extension: allPhotoIds で重複なしの全写真IDを取得")
    func testArrayAllPhotoIds() {
        let pairs = [
            SimilarityPair(id1: "photo1", id2: "photo2", similarity: 0.9),
            SimilarityPair(id1: "photo2", id2: "photo3", similarity: 0.8),
            SimilarityPair(id1: "photo3", id2: "photo4", similarity: 0.7)
        ]

        let allIds = pairs.allPhotoIds
        #expect(allIds.count == 4)
        #expect(allIds.contains("photo1"))
        #expect(allIds.contains("photo2"))
        #expect(allIds.contains("photo3"))
        #expect(allIds.contains("photo4"))
    }

    // MARK: - Collection Extension Tests

    @Test("Collection Extension: chunked(into:) でコレクションを分割")
    func testCollectionChunked() {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let chunks = array.chunked(into: 3)

        #expect(chunks.count == 4)
        #expect(chunks[0] == [1, 2, 3])
        #expect(chunks[1] == [4, 5, 6])
        #expect(chunks[2] == [7, 8, 9])
        #expect(chunks[3] == [10])
    }

    @Test("Collection Extension: 空配列の chunked は空配列")
    func testCollectionChunkedEmpty() {
        let array: [Int] = []
        let chunks = array.chunked(into: 3)
        #expect(chunks.isEmpty)
    }

    // MARK: - Integration Tests (require real observations)

    // 注: 以下のテストは実際の VNFeaturePrintObservation が必要なため、
    // ユニットテストではなく統合テストとして別途実装することを推奨

    /*
    @Test("統合: 2つの観測結果から類似度を計算")
    func testCalculateSimilarity() async throws {
        // 実際の VNFeaturePrintObservation が必要
    }

    @Test("統合: 類似ペアの検出")
    func testFindSimilarPairs() async throws {
        // 実際の VNFeaturePrintObservation 配列が必要
    }

    @Test("統合: 類似度マトリクスの生成")
    func testCreateSimilarityMatrix() async throws {
        // 実際の VNFeaturePrintObservation 配列が必要
    }
    */
}
