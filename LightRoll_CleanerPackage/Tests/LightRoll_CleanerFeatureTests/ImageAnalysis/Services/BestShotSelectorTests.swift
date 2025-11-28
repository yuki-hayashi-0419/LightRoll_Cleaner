//
//  BestShotSelectorTests.swift
//  LightRoll_CleanerFeature
//
//  ベストショット選定サービスのテスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - BestShotSelectorTests

@Suite("BestShotSelector Tests")
struct BestShotSelectorTests {

    // MARK: - 初期化テスト

    @Test("デフォルト初期化")
    func testDefaultInitialization() async {
        let selector = BestShotSelector()
        #expect(selector != nil)
    }

    @Test("カスタムオプションで初期化")
    func testCustomOptionsInitialization() async {
        let options = BestShotSelectionOptions(
            sharpnessWeight: 0.5,
            faceQualityWeight: 0.3,
            faceCountWeight: 0.2
        )
        let selector = BestShotSelector(options: options)
        #expect(selector != nil)
    }

    // MARK: - ベストショット選定テスト

    @Test("空のグループでベストショット選定")
    func testSelectBestShotFromEmptyGroup() async throws {
        let selector = BestShotSelector()
        let emptyGroup = PhotoGroup(
            type: .similar,
            photoIds: []
        )

        let result = try await selector.selectBestShot(from: emptyGroup)
        #expect(result == nil)
    }

    @Test("単一写真のグループでベストショット選定")
    func testSelectBestShotFromSinglePhoto() async throws {
        let selector = BestShotSelector()
        let singlePhotoGroup = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1"]
        )

        let result = try await selector.selectBestShot(from: singlePhotoGroup)
        #expect(result == 0)
    }

    @Test("複数写真のグループでベストショット選定 - エラーハンドリング")
    func testSelectBestShotFromMultiplePhotos() async throws {
        let selector = BestShotSelector()
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3"]
        )

        // PHAssetが存在しない場合、AnalysisError.groupingFailedがスローされる
        await #expect(throws: AnalysisError.self) {
            try await selector.selectBestShot(from: group)
        }
    }

    // MARK: - オプションテスト

    @Test("デフォルトオプションの重み")
    func testDefaultOptionsWeights() {
        let options = BestShotSelectionOptions.default

        // 重みの合計が1.0になることを確認
        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)

        // デフォルト値の確認
        #expect(options.sharpnessWeight > 0)
        #expect(options.faceQualityWeight > 0)
        #expect(options.faceCountWeight > 0)
    }

    @Test("シャープネス重視オプション")
    func testSharpnessPriorityOption() {
        let options = BestShotSelectionOptions.sharpnessPriority

        // シャープネスの重みが最大であることを確認
        #expect(options.sharpnessWeight > options.faceQualityWeight)
        #expect(options.sharpnessWeight > options.faceCountWeight)

        // 重みの合計が1.0
        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)
    }

    @Test("顔品質重視オプション")
    func testFaceQualityPriorityOption() {
        let options = BestShotSelectionOptions.faceQualityPriority

        // 顔品質の重みが最大であることを確認
        #expect(options.faceQualityWeight > options.sharpnessWeight)
        #expect(options.faceQualityWeight > options.faceCountWeight)

        // 重みの合計が1.0
        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)
    }

    @Test("ポートレートモードオプション")
    func testPortraitModeOption() {
        let options = BestShotSelectionOptions.portraitMode

        // 顔に関する重みが高いことを確認
        let faceRelatedWeight = options.faceQualityWeight + options.faceCountWeight
        #expect(faceRelatedWeight > options.sharpnessWeight)

        // 重みの合計が1.0
        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)
    }

    @Test("カスタム重みの正規化")
    func testCustomWeightNormalization() {
        // 合計が1.0でない重みを設定
        let options = BestShotSelectionOptions(
            sharpnessWeight: 2.0,
            faceQualityWeight: 3.0,
            faceCountWeight: 5.0
        )

        // 自動的に正規化されることを確認
        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)

        // 比率が維持されることを確認
        #expect(options.faceCountWeight > options.faceQualityWeight)
        #expect(options.faceQualityWeight > options.sharpnessWeight)
    }

    @Test("ゼロ重みのハンドリング")
    func testZeroWeightsHandling() {
        // 全てゼロの場合はデフォルト値が使用される
        let options = BestShotSelectionOptions(
            sharpnessWeight: 0.0,
            faceQualityWeight: 0.0,
            faceCountWeight: 0.0
        )

        // デフォルト値で初期化される
        #expect(options.sharpnessWeight > 0)
        #expect(options.faceQualityWeight > 0)
        #expect(options.faceCountWeight > 0)

        let total = options.sharpnessWeight + options.faceQualityWeight + options.faceCountWeight
        #expect(abs(total - 1.0) < 0.001)
    }

    // MARK: - PhotoQualityScore テスト

    @Test("PhotoQualityScore 初期化")
    func testPhotoQualityScoreInitialization() {
        let score = PhotoQualityScore(
            photoId: "test-photo",
            sharpnessScore: 0.8,
            faceQualityScore: 0.6,
            faceCountScore: 1.0,
            totalScore: 0.75
        )

        #expect(score.photoId == "test-photo")
        #expect(score.sharpnessScore == 0.8)
        #expect(score.faceQualityScore == 0.6)
        #expect(score.faceCountScore == 1.0)
        #expect(score.totalScore == 0.75)
    }

    @Test("PhotoQualityScore スコアクランプ")
    func testPhotoQualityScoreClamping() {
        let score = PhotoQualityScore(
            photoId: "test-photo",
            sharpnessScore: 1.5,  // > 1.0
            faceQualityScore: -0.2, // < 0.0
            faceCountScore: 0.5,
            totalScore: 2.0 // > 1.0
        )

        // 0.0〜1.0 の範囲にクランプされる
        #expect(score.sharpnessScore == 1.0)
        #expect(score.faceQualityScore == 0.0)
        #expect(score.totalScore == 1.0)
    }

    @Test("PhotoQualityScore 品質レベル判定")
    func testPhotoQualityScoreQualityLevel() {
        let excellent = PhotoQualityScore(photoId: "1", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.9)
        #expect(excellent.qualityLevel == .excellent)

        let good = PhotoQualityScore(photoId: "2", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7)
        #expect(good.qualityLevel == .good)

        let fair = PhotoQualityScore(photoId: "3", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.5)
        #expect(fair.qualityLevel == .fair)

        let poor = PhotoQualityScore(photoId: "4", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.3)
        #expect(poor.qualityLevel == .poor)
    }

    @Test("PhotoQualityScore Comparable")
    func testPhotoQualityScoreComparable() {
        let score1 = PhotoQualityScore(photoId: "1", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7)
        let score2 = PhotoQualityScore(photoId: "2", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.9)

        #expect(score1 < score2)
        #expect(score2 > score1)
    }

    @Test("PhotoQualityScore Array Extension - ソート")
    func testPhotoQualityScoreArraySorting() {
        let scores = [
            PhotoQualityScore(photoId: "1", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.5),
            PhotoQualityScore(photoId: "2", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.9),
            PhotoQualityScore(photoId: "3", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7)
        ]

        let sorted = scores.sortedByTotalScore
        #expect(sorted[0].totalScore == 0.9)
        #expect(sorted[1].totalScore == 0.7)
        #expect(sorted[2].totalScore == 0.5)
    }

    @Test("PhotoQualityScore Array Extension - 最高スコア")
    func testPhotoQualityScoreArrayBest() {
        let scores = [
            PhotoQualityScore(photoId: "1", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.5),
            PhotoQualityScore(photoId: "2", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.9),
            PhotoQualityScore(photoId: "3", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7)
        ]

        let best = scores.best
        #expect(best?.photoId == "2")
        #expect(best?.totalScore == 0.9)
    }

    @Test("PhotoQualityScore Array Extension - 平均スコア")
    func testPhotoQualityScoreArrayAverage() {
        let scores = [
            PhotoQualityScore(photoId: "1", sharpnessScore: 0.6, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.5),
            PhotoQualityScore(photoId: "2", sharpnessScore: 0.8, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7),
            PhotoQualityScore(photoId: "3", sharpnessScore: 0.7, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.6)
        ]

        let avgTotal = scores.averageTotalScore
        #expect(avgTotal != nil)
        #expect(abs(avgTotal! - 0.6) < 0.01)

        let avgSharpness = scores.averageSharpnessScore
        #expect(avgSharpness != nil)
        #expect(abs(avgSharpness! - 0.7) < 0.01)
    }

    @Test("PhotoQualityScore Array Extension - 品質レベル別カウント")
    func testPhotoQualityScoreArrayCountByLevel() {
        let scores = [
            PhotoQualityScore(photoId: "1", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.9), // excellent
            PhotoQualityScore(photoId: "2", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.7), // good
            PhotoQualityScore(photoId: "3", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.5), // fair
            PhotoQualityScore(photoId: "4", sharpnessScore: 0, faceQualityScore: 0, faceCountScore: 0, totalScore: 0.85) // excellent
        ]

        let countByLevel = scores.countByQualityLevel
        #expect(countByLevel[.excellent] == 2)
        #expect(countByLevel[.good] == 1)
        #expect(countByLevel[.fair] == 1)
        #expect(countByLevel[.poor] == nil)
    }

    // MARK: - QualityLevel テスト

    @Test("QualityLevel 表示プロパティ")
    func testQualityLevelDisplayProperties() {
        #expect(QualityLevel.excellent.iconName == "star.fill")
        #expect(QualityLevel.good.iconName == "star.leadinghalf.filled")
        #expect(QualityLevel.fair.iconName == "star")
        #expect(QualityLevel.poor.iconName == "xmark.circle")

        #expect(!QualityLevel.excellent.displayName.isEmpty)
        #expect(!QualityLevel.good.displayName.isEmpty)
        #expect(!QualityLevel.fair.displayName.isEmpty)
        #expect(!QualityLevel.poor.displayName.isEmpty)
    }
}
