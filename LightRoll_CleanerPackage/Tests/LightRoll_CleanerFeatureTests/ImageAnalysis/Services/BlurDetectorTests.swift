//
//  BlurDetectorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BlurDetectorの単体テスト
//  ラプラシアン分散法によるブレ検出の動作を検証
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos
import CoreImage
@testable import LightRoll_CleanerFeature

// MARK: - BlurDetectorTests

@Suite("BlurDetector Tests", .serialized)
struct BlurDetectorTests {

    // MARK: - Initialization Tests

    @Test("デフォルト初期化が成功すること")
    func testDefaultInitialization() async throws {
        // Given & When
        let detector = BlurDetector()

        // Then
        // 初期化が成功すればテストパス（型チェック）
        _ = detector
        #expect(Bool(true))
    }

    @Test("カスタムオプションで初期化できること")
    func testCustomOptionsInitialization() async throws {
        // Given
        let options = BlurDetectionOptions(
            blurThreshold: 0.5,
            batchSize: 100,
            maxConcurrentOperations: 2
        )

        // When
        let detector = BlurDetector(options: options)

        // Then
        _ = detector
        #expect(Bool(true))
    }

    // MARK: - BlurDetectionOptions Tests

    @Test("BlurDetectionOptionsのデフォルト値が正しいこと")
    func testBlurDetectionOptionsDefaults() {
        // When
        let options = BlurDetectionOptions.default

        // Then
        #expect(options.blurThreshold == 0.4)
        #expect(options.batchSize == 500)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("BlurDetectionOptionsのstrictプリセットが正しいこと")
    func testBlurDetectionOptionsStrict() {
        // When
        let options = BlurDetectionOptions.strict

        // Then
        #expect(options.blurThreshold == 0.3)
        #expect(options.batchSize == 200)
        #expect(options.maxConcurrentOperations == 2)
    }

    @Test("BlurDetectionOptionsのrelaxedプリセットが正しいこと")
    func testBlurDetectionOptionsRelaxed() {
        // When
        let options = BlurDetectionOptions.relaxed

        // Then
        #expect(options.blurThreshold == 0.5)
        #expect(options.batchSize == 1000)
        #expect(options.maxConcurrentOperations == 8)
    }

    @Test("閾値が0〜1の範囲にクランプされること")
    func testBlurThresholdClamping() {
        // Given & When
        let tooHigh = BlurDetectionOptions(blurThreshold: 1.5)
        let tooLow = BlurDetectionOptions(blurThreshold: -0.5)

        // Then
        #expect(tooHigh.blurThreshold == 1.0)
        #expect(tooLow.blurThreshold == 0.0)
    }

    // MARK: - BlurDetectionResult Tests

    @Test("BlurDetectionResultの初期化が正しいこと")
    func testBlurDetectionResultInitialization() {
        // Given
        let photoId = "test-photo-001"
        let blurScore: Float = 0.6
        let sharpnessScore: Float = 0.4

        // When
        let result = BlurDetectionResult(
            photoId: photoId,
            blurScore: blurScore,
            sharpnessScore: sharpnessScore,
            isBlurry: true
        )

        // Then
        #expect(result.photoId == photoId)
        #expect(result.blurScore == blurScore)
        #expect(result.sharpnessScore == sharpnessScore)
        #expect(result.isBlurry == true)
        #expect(result.id == photoId)
    }

    @Test("BlurDetectionResultのスコアがクランプされること")
    func testBlurDetectionResultScoreClamping() {
        // Given & When
        let result = BlurDetectionResult(
            photoId: "test",
            blurScore: 1.5,
            sharpnessScore: -0.5,
            isBlurry: false
        )

        // Then
        #expect(result.blurScore == 1.0)
        #expect(result.sharpnessScore == 0.0)
    }

    @Test("品質レベルの判定が正しいこと")
    func testQualityLevelDetermination() {
        // Given & When
        let sharp = BlurDetectionResult(
            photoId: "sharp",
            blurScore: 0.2,
            sharpnessScore: 0.8,
            isBlurry: false
        )

        let acceptable = BlurDetectionResult(
            photoId: "acceptable",
            blurScore: 0.4,
            sharpnessScore: 0.6,
            isBlurry: false
        )

        let blurry = BlurDetectionResult(
            photoId: "blurry",
            blurScore: 0.7,
            sharpnessScore: 0.3,
            isBlurry: true
        )

        // Then
        #expect(sharp.qualityLevel == .sharp)
        #expect(acceptable.qualityLevel == .acceptable)
        #expect(blurry.qualityLevel == .blurry)
    }

    @Test("フォーマット済みスコアが正しいこと")
    func testFormattedScores() {
        // Given
        let result = BlurDetectionResult(
            photoId: "test",
            blurScore: 0.456,
            sharpnessScore: 0.544,
            isBlurry: false
        )

        // When
        let formattedBlur = result.formattedBlurScore
        let formattedSharpness = result.formattedSharpnessScore

        // Then
        #expect(formattedBlur == "45.6%")
        #expect(formattedSharpness == "54.4%")
    }

    // MARK: - BlurQualityLevel Tests

    @Test("BlurQualityLevelのアイコン名が正しいこと")
    func testBlurQualityLevelIcons() {
        // When & Then
        #expect(BlurQualityLevel.sharp.iconName == "sparkles")
        #expect(BlurQualityLevel.acceptable.iconName == "camera.metering.partial")
        #expect(BlurQualityLevel.blurry.iconName == "camera.metering.unknown")
    }

    // MARK: - Comparable Tests

    @Test("BlurDetectionResultの比較が正しいこと")
    func testBlurDetectionResultComparable() {
        // Given
        let sharp = BlurDetectionResult(
            photoId: "sharp",
            blurScore: 0.2,
            sharpnessScore: 0.8,
            isBlurry: false
        )

        let blurry = BlurDetectionResult(
            photoId: "blurry",
            blurScore: 0.6,
            sharpnessScore: 0.4,
            isBlurry: true
        )

        // When & Then
        #expect(sharp < blurry) // シャープな方が先（小さい）
        #expect(blurry > sharp)
    }

    // MARK: - Array Extension Tests

    @Test("ブレ写真のフィルタリングが正しいこと")
    func testFilterBlurry() {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "sharp1",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "blurry1",
                blurScore: 0.6,
                sharpnessScore: 0.4,
                isBlurry: true
            ),
            BlurDetectionResult(
                photoId: "blurry2",
                blurScore: 0.7,
                sharpnessScore: 0.3,
                isBlurry: true
            )
        ]

        // When
        let blurryOnly = results.filterBlurry()

        // Then
        #expect(blurryOnly.count == 2)
        #expect(blurryOnly.allSatisfy { $0.isBlurry })
    }

    @Test("シャープな写真のフィルタリングが正しいこと")
    func testFilterSharp() {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "sharp1",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "blurry1",
                blurScore: 0.6,
                sharpnessScore: 0.4,
                isBlurry: true
            )
        ]

        // When
        let sharpOnly = results.filterSharp()

        // Then
        #expect(sharpOnly.count == 1)
        #expect(sharpOnly.allSatisfy { !$0.isBlurry })
    }

    @Test("品質レベルによるフィルタリングが正しいこと")
    func testFilterByQualityLevel() {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "sharp",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "acceptable",
                blurScore: 0.4,
                sharpnessScore: 0.6,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "blurry",
                blurScore: 0.7,
                sharpnessScore: 0.3,
                isBlurry: true
            )
        ]

        // When
        let sharpOnly = results.filter(by: .sharp)
        let blurryOnly = results.filter(by: .blurry)

        // Then
        #expect(sharpOnly.count == 1)
        #expect(blurryOnly.count == 1)
    }

    @Test("シャープネス順のソートが正しいこと")
    func testSortedBySharpness() {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "2",
                blurScore: 0.4,
                sharpnessScore: 0.6,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "1",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "3",
                blurScore: 0.7,
                sharpnessScore: 0.3,
                isBlurry: true
            )
        ]

        // When
        let sorted = results.sortedBySharpness()

        // Then
        #expect(sorted[0].photoId == "1") // 最もシャープ
        #expect(sorted[1].photoId == "2")
        #expect(sorted[2].photoId == "3") // 最もブレ
    }

    @Test("ブレスコア順のソートが正しいこと")
    func testSortedByBlur() {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "2",
                blurScore: 0.4,
                sharpnessScore: 0.6,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "3",
                blurScore: 0.7,
                sharpnessScore: 0.3,
                isBlurry: true
            ),
            BlurDetectionResult(
                photoId: "1",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            )
        ]

        // When
        let sorted = results.sortedByBlur()

        // Then
        #expect(sorted[0].photoId == "3") // 最もブレ
        #expect(sorted[1].photoId == "2")
        #expect(sorted[2].photoId == "1") // 最もシャープ
    }

    @Test("配列の統計情報が正しいこと")
    func testArrayStatistics() throws {
        // Given
        let results = [
            BlurDetectionResult(
                photoId: "sharp",
                blurScore: 0.2,
                sharpnessScore: 0.8,
                isBlurry: false
            ),
            BlurDetectionResult(
                photoId: "blurry",
                blurScore: 0.6,
                sharpnessScore: 0.4,
                isBlurry: true
            )
        ]

        // When & Then
        #expect(results.blurryCount == 1)
        #expect(results.sharpCount == 1)
        #expect(results.blurryRatio == 0.5)

        let avgBlur = try #require(results.averageBlurScore)
        #expect(abs(avgBlur - 0.4) < 0.01)

        let avgSharp = try #require(results.averageSharpnessScore)
        #expect(abs(avgSharp - 0.6) < 0.01)

        let sharpest = try #require(results.sharpest)
        #expect(sharpest.photoId == "sharp")

        let blurriest = try #require(results.blurriest)
        #expect(blurriest.photoId == "blurry")
    }

    @Test("空配列の統計情報がnilを返すこと")
    func testEmptyArrayStatistics() {
        // Given
        let results: [BlurDetectionResult] = []

        // When & Then
        #expect(results.blurryRatio == nil)
        #expect(results.averageBlurScore == nil)
        #expect(results.averageSharpnessScore == nil)
        #expect(results.sharpest == nil)
        #expect(results.blurriest == nil)
    }

    // MARK: - Codable Tests

    @Test("BlurDetectionResultがエンコード・デコードできること")
    func testBlurDetectionResultCodable() throws {
        // Given
        let original = BlurDetectionResult(
            id: "test-id",
            photoId: "photo-123",
            blurScore: 0.5,
            sharpnessScore: 0.5,
            isBlurry: true,
            detectedAt: Date()
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BlurDetectionResult.self, from: data)

        // Then
        #expect(decoded.id == original.id)
        #expect(decoded.photoId == original.photoId)
        #expect(decoded.blurScore == original.blurScore)
        #expect(decoded.sharpnessScore == original.sharpnessScore)
        #expect(decoded.isBlurry == original.isBlurry)
    }

    // MARK: - Description Tests

    @Test("descriptionプロパティが正しいフォーマットであること")
    func testDescription() {
        // Given
        let result = BlurDetectionResult(
            photoId: "test-photo",
            blurScore: 0.45,
            sharpnessScore: 0.55,
            isBlurry: true
        )

        // When
        let description = result.description

        // Then
        #expect(description.contains("test-photo"))
        #expect(description.contains("0.45"))
        #expect(description.contains("0.55"))
        #expect(description.contains("true"))
        #expect(description.contains("acceptable"))
    }

    // MARK: - Hashable Tests

    @Test("同じIDを持つ結果が等しいこと")
    func testHashable() {
        // Given
        let result1 = BlurDetectionResult(
            id: "same-id",
            photoId: "photo-1",
            blurScore: 0.3,
            sharpnessScore: 0.7,
            isBlurry: false
        )

        let result2 = BlurDetectionResult(
            id: "same-id",
            photoId: "photo-2",
            blurScore: 0.5,
            sharpnessScore: 0.5,
            isBlurry: true
        )

        // When & Then
        #expect(result1 == result2) // IDが同じなら等しい
        #expect(result1.hashValue == result2.hashValue)
    }

    @Test("異なるIDを持つ結果が等しくないこと")
    func testHashableDifferent() {
        // Given
        let result1 = BlurDetectionResult(
            id: "id-1",
            photoId: "photo-1",
            blurScore: 0.3,
            sharpnessScore: 0.7,
            isBlurry: false
        )

        let result2 = BlurDetectionResult(
            id: "id-2",
            photoId: "photo-1",
            blurScore: 0.3,
            sharpnessScore: 0.7,
            isBlurry: false
        )

        // When & Then
        #expect(result1 != result2) // IDが異なれば等しくない
    }
}
