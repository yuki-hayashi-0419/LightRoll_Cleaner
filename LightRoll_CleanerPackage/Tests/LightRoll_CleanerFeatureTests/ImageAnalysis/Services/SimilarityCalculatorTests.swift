//
//  SimilarityCalculatorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SimilarityCalculatorのテストスイート
//  - calculateSimilarityFromCacheSIMD() の包括的テスト
//  - SIMD版と通常版の精度一致検証
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

/// SimilarityCalculatorのテストスイート
@Suite("SimilarityCalculator Tests")
struct SimilarityCalculatorTests {

    // MARK: - Helper Methods

    /// テスト用の2048次元特徴量データを生成（実際のVNFeaturePrintObservationサイズ）
    private func createFeatureData(seed: Int = 0) -> Data {
        var generator = TestRandomGenerator(seed: UInt64(seed))
        let features: [Float] = (0..<2048).map { _ in
            Float.random(in: -1...1, using: &generator)
        }
        return Data(bytes: features, count: features.count * MemoryLayout<Float>.stride)
    }

    /// 同一のベクトルデータを生成（類似度 = 1.0をテスト）
    private func createIdenticalData() -> (Data, Data) {
        let data = createFeatureData(seed: 42)
        return (data, data)
    }

    /// 完全に異なるベクトルを生成（類似度 ≈ 0.0をテスト）
    private func createOppositeData() -> (Data, Data) {
        var generator = TestRandomGenerator(seed: 100)
        let features1: [Float] = (0..<2048).map { _ in
            Float.random(in: 0.5...1.0, using: &generator)
        }
        let features2: [Float] = (0..<2048).map { _ in
            Float.random(in: -1.0...(-0.5), using: &generator)
        }

        let data1 = Data(bytes: features1, count: features1.count * MemoryLayout<Float>.stride)
        let data2 = Data(bytes: features2, count: features2.count * MemoryLayout<Float>.stride)
        return (data1, data2)
    }

    /// 類似したベクトルを生成（指定された類似度付近になるようにノイズを調整）
    private func createSimilarData(targetSimilarity: Float) -> (Data, Data) {
        let noise: Float
        switch targetSimilarity {
        case 0.8..<1.0:
            noise = 0.05  // 高類似度
        case 0.5..<0.8:
            noise = 0.3   // 中程度の類似度
        case 0.1..<0.5:
            noise = 0.7   // 低類似度
        default:
            noise = 0.3
        }

        var generator = TestRandomGenerator(seed: 200)
        let features1: [Float] = (0..<2048).map { _ in
            Float.random(in: -1...1, using: &generator)
        }

        let features2: [Float] = features1.map { value in
            value + Float.random(in: -noise...noise, using: &generator)
        }

        let data1 = Data(bytes: features1, count: features1.count * MemoryLayout<Float>.stride)
        let data2 = Data(bytes: features2, count: features2.count * MemoryLayout<Float>.stride)
        return (data1, data2)
    }

    /// ゼロベクトルを生成
    private func createZeroVector() -> Data {
        let features: [Float] = Array(repeating: 0.0, count: 2048)
        return Data(bytes: features, count: features.count * MemoryLayout<Float>.stride)
    }

    // MARK: - 正常系テスト (6ケース)

    @Test("SIMD版：同一ベクトルで類似度1.0を返すこと")
    func testSIMD_IdenticalVectors_ReturnsSimilarityOne() async throws {
        let calculator = SimilarityCalculator()
        let (data1, data2) = createIdenticalData()

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity > 0.99)
        #expect(similarity <= 1.0)
    }

    @Test("SIMD版：完全に異なるベクトルで類似度が低いこと")
    func testSIMD_OppositeVectors_ReturnsLowSimilarity() async throws {
        let calculator = SimilarityCalculator()
        let (data1, data2) = createOppositeData()

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity < 0.2)
        #expect(similarity >= 0.0)
    }

    @Test("SIMD版：中程度の類似ベクトルで適切な類似度を返すこと")
    func testSIMD_ModeratelySimilarVectors_ReturnsModerateSimilarity() async throws {
        let calculator = SimilarityCalculator()
        let (data1, data2) = createSimilarData(targetSimilarity: 0.5)

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity > 0.3)
        #expect(similarity < 0.8)
    }

    @Test("SIMD版：高い類似度（0.8-0.9）を正しく計算できること")
    func testSIMD_HighlySimilarVectors_ReturnsHighSimilarity() async throws {
        let calculator = SimilarityCalculator()
        let (data1, data2) = createSimilarData(targetSimilarity: 0.85)

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity > 0.7)
        #expect(similarity < 1.0)
    }

    @Test("SIMD版：低い類似度（0.1-0.2）を正しく計算できること")
    func testSIMD_LowSimilarVectors_ReturnsLowSimilarity() async throws {
        let calculator = SimilarityCalculator()
        let (data1, data2) = createSimilarData(targetSimilarity: 0.15)

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity > 0.0)
        #expect(similarity < 0.4)
    }

    @Test("SIMD版：2048次元の実データサイズで正しく動作すること")
    func testSIMD_RealDataSize_WorksCorrectly() async throws {
        let calculator = SimilarityCalculator()
        let data1 = createFeatureData(seed: 300)
        let data2 = createFeatureData(seed: 301)

        // 8192バイト = 2048次元 × 4バイト(Float)
        #expect(data1.count == 8192)
        #expect(data2.count == 8192)

        let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        #expect(similarity >= 0.0)
        #expect(similarity <= 1.0)
    }

    // MARK: - エラーケース (3ケース)

    @Test("SIMD版：データサイズ不一致でエラーをスローすること")
    func testSIMD_MismatchedDataSize_ThrowsError() async {
        let calculator = SimilarityCalculator()
        let data1 = createFeatureData(seed: 400)

        // 異なるサイズのデータを作成
        let features2: [Float] = Array(repeating: 0.5, count: 1024) // 半分のサイズ
        let data2 = Data(bytes: features2, count: features2.count * MemoryLayout<Float>.stride)

        await #expect(throws: AnalysisError.self) {
            try await calculator.calculateSimilarityFromCacheSIMD(hash1: data1, hash2: data2)
        }
    }

    @Test("SIMD版：空データでエラーをスローすること")
    func testSIMD_EmptyData_ThrowsError() async {
        let calculator = SimilarityCalculator()
        let emptyData = Data()
        let validData = createFeatureData(seed: 500)

        await #expect(throws: AnalysisError.self) {
            try await calculator.calculateSimilarityFromCacheSIMD(hash1: emptyData, hash2: validData)
        }

        await #expect(throws: AnalysisError.self) {
            try await calculator.calculateSimilarityFromCacheSIMD(hash1: validData, hash2: emptyData)
        }
    }

    @Test("SIMD版：ゼロベクトルでエラーをスローすること")
    func testSIMD_ZeroVectors_ThrowsError() async {
        let calculator = SimilarityCalculator()
        let zeroData = createZeroVector()

        await #expect(throws: AnalysisError.self) {
            try await calculator.calculateSimilarityFromCacheSIMD(hash1: zeroData, hash2: zeroData)
        }
    }

    // MARK: - 精度検証 (2ケース)

    @Test("SIMD版と通常版の結果が一致すること")
    func testSIMD_MatchesNonSIMDVersion() async throws {
        let calculator = SimilarityCalculator()
        let data1 = createFeatureData(seed: 600)
        let data2 = createFeatureData(seed: 601)

        let simdSimilarity = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        let normalSimilarity = try await calculator.calculateSimilarityFromCache(
            hash1: data1,
            hash2: data2
        )

        // 浮動小数点の誤差を許容（0.0001以内）
        let difference = abs(simdSimilarity - normalSimilarity)
        #expect(difference < 0.0001)
    }

    @Test("複数のテストケースでSIMD版と通常版の精度が一致すること")
    func testSIMD_AccuracyConsistencyAcrossMultipleCases() async throws {
        let calculator = SimilarityCalculator()

        // 10ケースでテスト
        for seed in 700..<710 {
            let data1 = createFeatureData(seed: seed)
            let data2 = createFeatureData(seed: seed + 1000)

            let simdSimilarity = try await calculator.calculateSimilarityFromCacheSIMD(
                hash1: data1,
                hash2: data2
            )

            let normalSimilarity = try await calculator.calculateSimilarityFromCache(
                hash1: data1,
                hash2: data2
            )

            let difference = abs(simdSimilarity - normalSimilarity)
            #expect(
                difference < 0.0001,
                "精度不一致（シード: \(seed)）: SIMD=\(simdSimilarity), Normal=\(normalSimilarity)"
            )
        }
    }

    // MARK: - 境界値・追加テスト

    @Test("SIMD版：結果が常に0.0〜1.0の範囲内であること")
    func testSIMD_ResultAlwaysInValidRange() async throws {
        let calculator = SimilarityCalculator()

        // ランダムな10ペアでテスト
        for seed in 800..<810 {
            let data1 = createFeatureData(seed: seed)
            let data2 = createFeatureData(seed: seed + 500)

            let similarity = try await calculator.calculateSimilarityFromCacheSIMD(
                hash1: data1,
                hash2: data2
            )

            #expect(similarity >= 0.0)
            #expect(similarity <= 1.0)
        }
    }

    @Test("SIMD版：対称性が保証されること（A vs B == B vs A）")
    func testSIMD_Symmetry() async throws {
        let calculator = SimilarityCalculator()
        let data1 = createFeatureData(seed: 900)
        let data2 = createFeatureData(seed: 901)

        let similarity1 = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data1,
            hash2: data2
        )

        let similarity2 = try await calculator.calculateSimilarityFromCacheSIMD(
            hash1: data2,
            hash2: data1
        )

        #expect(similarity1 == similarity2)
    }
}

// MARK: - TestRandomGenerator

/// 再現可能なランダム値生成器（テスト用）
/// Note: LSHHasherTests.swiftと異なる実装（LCG vs XorShift）
fileprivate struct TestRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // LCG (Linear Congruential Generator)
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
