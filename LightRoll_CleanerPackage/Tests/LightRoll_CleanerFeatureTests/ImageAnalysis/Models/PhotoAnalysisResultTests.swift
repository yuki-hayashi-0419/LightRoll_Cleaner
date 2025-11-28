//
//  PhotoAnalysisResultTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoAnalysisResult モデルの単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - PhotoAnalysisResult Tests

@Suite("PhotoAnalysisResult モデルテスト")
struct PhotoAnalysisResultTests {

    // MARK: - Test Data

    /// テスト用の分析結果を生成
    private func makeResult(
        id: String = "result-id",
        photoId: String = "photo-123",
        analyzedAt: Date = Date(),
        qualityScore: Float = 0.7,
        blurScore: Float = 0.2,
        brightnessScore: Float = 0.5,
        contrastScore: Float = 0.5,
        saturationScore: Float = 0.5,
        faceCount: Int = 0,
        faceQualityScores: [Float] = [],
        faceAngles: [FaceAngle] = [],
        isScreenshot: Bool = false,
        isSelfie: Bool = false,
        featurePrintHash: Data? = nil
    ) -> PhotoAnalysisResult {
        PhotoAnalysisResult(
            id: id,
            photoId: photoId,
            analyzedAt: analyzedAt,
            qualityScore: qualityScore,
            blurScore: blurScore,
            brightnessScore: brightnessScore,
            contrastScore: contrastScore,
            saturationScore: saturationScore,
            faceCount: faceCount,
            faceQualityScores: faceQualityScores,
            faceAngles: faceAngles,
            isScreenshot: isScreenshot,
            isSelfie: isSelfie,
            featurePrintHash: featurePrintHash
        )
    }

    // MARK: - Initialization Tests

    @Test("全プロパティを指定して初期化できる")
    func initializationWithAllProperties() {
        let date = Date()
        let hash = Data([0x01, 0x02, 0x03])
        let faceAngles = [FaceAngle(yaw: 0, pitch: 0, roll: 0)]

        let result = makeResult(
            id: "test-1",
            photoId: "photo-1",
            analyzedAt: date,
            qualityScore: 0.85,
            blurScore: 0.1,
            brightnessScore: 0.55,
            contrastScore: 0.6,
            saturationScore: 0.7,
            faceCount: 2,
            faceQualityScores: [0.9, 0.8],
            faceAngles: faceAngles,
            isScreenshot: false,
            isSelfie: true,
            featurePrintHash: hash
        )

        #expect(result.id == "test-1")
        #expect(result.photoId == "photo-1")
        #expect(result.analyzedAt == date)
        #expect(result.qualityScore == 0.85)
        #expect(result.blurScore == 0.1)
        #expect(result.brightnessScore == 0.55)
        #expect(result.contrastScore == 0.6)
        #expect(result.saturationScore == 0.7)
        #expect(result.faceCount == 2)
        #expect(result.faceQualityScores == [0.9, 0.8])
        #expect(result.faceAngles == faceAngles)
        #expect(result.isScreenshot == false)
        #expect(result.isSelfie == true)
        #expect(result.featurePrintHash == hash)
    }

    @Test("スコアは 0.0〜1.0 の範囲にクランプされる")
    func scoresClamped() {
        let result = makeResult(
            qualityScore: 1.5,
            blurScore: -0.5,
            brightnessScore: 2.0,
            contrastScore: -1.0,
            saturationScore: 100.0
        )

        #expect(result.qualityScore == 1.0)
        #expect(result.blurScore == 0.0)
        #expect(result.brightnessScore == 1.0)
        #expect(result.contrastScore == 0.0)
        #expect(result.saturationScore == 1.0)
    }

    @Test("faceCount は負の値を 0 にクランプする")
    func faceCountClamped() {
        let result = makeResult(faceCount: -5)
        #expect(result.faceCount == 0)
    }

    @Test("faceQualityScores の各値がクランプされる")
    func faceQualityScoresClamped() {
        let result = makeResult(faceQualityScores: [1.5, -0.5, 0.8])
        #expect(result.faceQualityScores == [1.0, 0.0, 0.8])
    }

    // MARK: - Computed Property Tests

    @Test("sharpnessScore が正しく計算される")
    func sharpnessScoreCalculation() {
        let result1 = makeResult(blurScore: 0.0)
        #expect(result1.sharpnessScore == 1.0)

        let result2 = makeResult(blurScore: 0.3)
        #expect(result2.sharpnessScore == 0.7)

        let result3 = makeResult(blurScore: 1.0)
        #expect(result3.sharpnessScore == 0.0)
    }

    @Test("isBlurry が閾値に基づいて判定される")
    func isBlurryDetection() {
        // デフォルト閾値: 0.4
        let sharp = makeResult(blurScore: 0.3)
        #expect(sharp.isBlurry == false)

        let borderline = makeResult(blurScore: 0.4)
        #expect(borderline.isBlurry == true)

        let blurry = makeResult(blurScore: 0.7)
        #expect(blurry.isBlurry == true)
    }

    @Test("isHighQuality が閾値に基づいて判定される")
    func isHighQualityDetection() {
        // デフォルト閾値: 0.7
        let lowQuality = makeResult(qualityScore: 0.5)
        #expect(lowQuality.isHighQuality == false)

        let borderline = makeResult(qualityScore: 0.7)
        #expect(borderline.isHighQuality == true)

        let highQuality = makeResult(qualityScore: 0.9)
        #expect(highQuality.isHighQuality == true)
    }

    @Test("isLowQuality が閾値に基づいて判定される")
    func isLowQualityDetection() {
        // デフォルト閾値: 0.4
        let good = makeResult(qualityScore: 0.6)
        #expect(good.isLowQuality == false)

        let borderline = makeResult(qualityScore: 0.4)
        #expect(borderline.isLowQuality == false)

        let poor = makeResult(qualityScore: 0.3)
        #expect(poor.isLowQuality == true)
    }

    @Test("isOverexposed が閾値に基づいて判定される")
    func isOverexposedDetection() {
        // デフォルト閾値: 0.8
        let normal = makeResult(brightnessScore: 0.5)
        #expect(normal.isOverexposed == false)

        let borderline = makeResult(brightnessScore: 0.8)
        #expect(borderline.isOverexposed == true)

        let bright = makeResult(brightnessScore: 0.95)
        #expect(bright.isOverexposed == true)
    }

    @Test("isUnderexposed が閾値に基づいて判定される")
    func isUnderexposedDetection() {
        // デフォルト閾値: 0.2
        let normal = makeResult(brightnessScore: 0.5)
        #expect(normal.isUnderexposed == false)

        let borderline = makeResult(brightnessScore: 0.2)
        #expect(borderline.isUnderexposed == true)

        let dark = makeResult(brightnessScore: 0.1)
        #expect(dark.isUnderexposed == true)
    }

    @Test("hasProperExposure が正しく判定される")
    func hasProperExposureDetection() {
        let proper = makeResult(brightnessScore: 0.5)
        #expect(proper.hasProperExposure == true)

        let overexposed = makeResult(brightnessScore: 0.9)
        #expect(overexposed.hasProperExposure == false)

        let underexposed = makeResult(brightnessScore: 0.1)
        #expect(underexposed.hasProperExposure == false)
    }

    @Test("hasFaces と hasMultipleFaces が正しく判定される")
    func faceDetection() {
        let noFaces = makeResult(faceCount: 0)
        #expect(noFaces.hasFaces == false)
        #expect(noFaces.hasMultipleFaces == false)

        let oneFace = makeResult(faceCount: 1)
        #expect(oneFace.hasFaces == true)
        #expect(oneFace.hasMultipleFaces == false)

        let multipleFaces = makeResult(faceCount: 3)
        #expect(multipleFaces.hasFaces == true)
        #expect(multipleFaces.hasMultipleFaces == true)
    }

    @Test("averageFaceQuality が正しく計算される")
    func averageFaceQualityCalculation() {
        let noFaces = makeResult(faceQualityScores: [])
        #expect(noFaces.averageFaceQuality == nil)

        let oneFace = makeResult(faceQualityScores: [0.8])
        #expect(oneFace.averageFaceQuality == 0.8)

        let multipleFaces = makeResult(faceQualityScores: [0.6, 0.8, 1.0])
        #expect(multipleFaces.averageFaceQuality == 0.8)
    }

    @Test("bestFaceQuality が正しく計算される")
    func bestFaceQualityCalculation() {
        let noFaces = makeResult(faceQualityScores: [])
        #expect(noFaces.bestFaceQuality == nil)

        let faces = makeResult(faceQualityScores: [0.6, 0.9, 0.7])
        #expect(faces.bestFaceQuality == 0.9)
    }

    @Test("frontalFaceCount が正しく計算される")
    func frontalFaceCountCalculation() {
        let frontal = FaceAngle(yaw: 0, pitch: 0, roll: 0)
        let side = FaceAngle(yaw: 60, pitch: 0, roll: 0)
        let slightlyAngled = FaceAngle(yaw: 20, pitch: 15, roll: 0)

        let result = makeResult(faceAngles: [frontal, side, slightlyAngled])
        #expect(result.frontalFaceCount == 2) // frontal と slightlyAngled
    }

    @Test("hasFeaturePrint が正しく判定される")
    func hasFeaturePrintDetection() {
        let withHash = makeResult(featurePrintHash: Data([0x01]))
        #expect(withHash.hasFeaturePrint == true)

        let withoutHash = makeResult(featurePrintHash: nil)
        #expect(withoutHash.hasFeaturePrint == false)
    }

    @Test("isDeletionCandidate が正しく判定される")
    func isDeletionCandidateDetection() {
        // 問題なし
        let good = makeResult(qualityScore: 0.8, blurScore: 0.1, brightnessScore: 0.5)
        #expect(good.isDeletionCandidate == false)

        // ブレ
        let blurry = makeResult(qualityScore: 0.8, blurScore: 0.5, brightnessScore: 0.5)
        #expect(blurry.isDeletionCandidate == true)

        // 低品質
        let lowQuality = makeResult(qualityScore: 0.3, blurScore: 0.1, brightnessScore: 0.5)
        #expect(lowQuality.isDeletionCandidate == true)

        // 露出異常
        let overexposed = makeResult(qualityScore: 0.8, blurScore: 0.1, brightnessScore: 0.9)
        #expect(overexposed.isDeletionCandidate == true)
    }

    @Test("issues が正しく検出される")
    func issuesDetection() {
        // 問題なし
        let good = makeResult(qualityScore: 0.8, blurScore: 0.1, brightnessScore: 0.5)
        #expect(good.issues.isEmpty)

        // 複数の問題
        let problematic = makeResult(qualityScore: 0.2, blurScore: 0.6, brightnessScore: 0.1)
        #expect(problematic.issues.count == 3) // blurry, lowQuality, underexposed
    }

    // MARK: - Codable Tests

    @Test("JSON エンコード・デコードが正しく動作する")
    func codableRoundTrip() throws {
        let original = makeResult(
            id: "codable-test",
            photoId: "photo-codable",
            qualityScore: 0.85,
            blurScore: 0.15,
            brightnessScore: 0.55,
            faceCount: 2,
            faceQualityScores: [0.9, 0.8],
            faceAngles: [FaceAngle(yaw: 10, pitch: 5, roll: 0)],
            isScreenshot: true,
            isSelfie: true,
            featurePrintHash: Data([0x01, 0x02, 0x03])
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PhotoAnalysisResult.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.photoId == original.photoId)
        #expect(decoded.qualityScore == original.qualityScore)
        #expect(decoded.blurScore == original.blurScore)
        #expect(decoded.brightnessScore == original.brightnessScore)
        #expect(decoded.faceCount == original.faceCount)
        #expect(decoded.faceQualityScores == original.faceQualityScores)
        #expect(decoded.isScreenshot == original.isScreenshot)
        #expect(decoded.isSelfie == original.isSelfie)
        #expect(decoded.featurePrintHash == original.featurePrintHash)
    }

    // MARK: - Hashable & Equatable Tests

    @Test("同一 id, photoId の結果は等しいと判定される")
    func equalityByIdAndPhotoId() {
        let result1 = makeResult(id: "same", photoId: "same-photo", qualityScore: 0.5)
        let result2 = makeResult(id: "same", photoId: "same-photo", qualityScore: 0.9)

        #expect(result1 == result2)
    }

    @Test("異なる id の結果は等しくないと判定される")
    func inequalityByDifferentId() {
        let result1 = makeResult(id: "id-1", photoId: "photo")
        let result2 = makeResult(id: "id-2", photoId: "photo")

        #expect(result1 != result2)
    }

    @Test("Set で重複が排除される")
    func setDeduplication() {
        let result1 = makeResult(id: "dup", photoId: "photo")
        let result2 = makeResult(id: "dup", photoId: "photo")
        let result3 = makeResult(id: "unique", photoId: "photo2")

        let set: Set<PhotoAnalysisResult> = [result1, result2, result3]
        #expect(set.count == 2)
    }

    // MARK: - Comparable Tests

    @Test("品質スコア順でソートされる（高品質が先）")
    func sortingByQuality() {
        let low = makeResult(id: "low", qualityScore: 0.3)
        let medium = makeResult(id: "medium", qualityScore: 0.5)
        let high = makeResult(id: "high", qualityScore: 0.9)

        let sorted = [low, high, medium].sorted()
        #expect(sorted[0].id == "high")
        #expect(sorted[1].id == "medium")
        #expect(sorted[2].id == "low")
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description が正しくフォーマットされる")
    func descriptionFormatting() {
        let result = makeResult(
            photoId: "photo-desc",
            qualityScore: 0.75,
            blurScore: 0.25,
            faceCount: 2
        )

        let description = result.description
        #expect(description.contains("photo-desc"))
        #expect(description.contains("0.75"))
        #expect(description.contains("0.25"))
        #expect(description.contains("2"))
    }
}

// MARK: - FaceAngle Tests

@Suite("FaceAngle テスト")
struct FaceAngleTests {

    @Test("初期化が正しく動作する")
    func initialization() {
        let angle = FaceAngle(yaw: 15.5, pitch: -10.0, roll: 5.0)

        #expect(angle.yaw == 15.5)
        #expect(angle.pitch == -10.0)
        #expect(angle.roll == 5.0)
    }

    @Test("isFrontal が正面向きを正しく判定する")
    func frontalDetection() {
        // 正面
        let frontal = FaceAngle(yaw: 0, pitch: 0, roll: 0)
        #expect(frontal.isFrontal == true)

        // 許容範囲内
        let slightlyAngled = FaceAngle(yaw: 25, pitch: -25, roll: 0)
        #expect(slightlyAngled.isFrontal == true)

        // yaw が範囲外
        let turnedLeft = FaceAngle(yaw: 45, pitch: 0, roll: 0)
        #expect(turnedLeft.isFrontal == false)

        // pitch が範囲外
        let lookingUp = FaceAngle(yaw: 0, pitch: 45, roll: 0)
        #expect(lookingUp.isFrontal == false)
    }

    @Test("isSideProfile が横顔を正しく判定する")
    func sideProfileDetection() {
        let frontal = FaceAngle(yaw: 0, pitch: 0, roll: 0)
        #expect(frontal.isSideProfile == false)

        let slightlyTurned = FaceAngle(yaw: 40, pitch: 0, roll: 0)
        #expect(slightlyTurned.isSideProfile == false)

        let sideLeft = FaceAngle(yaw: 60, pitch: 0, roll: 0)
        #expect(sideLeft.isSideProfile == true)

        let sideRight = FaceAngle(yaw: -60, pitch: 0, roll: 0)
        #expect(sideRight.isSideProfile == true)
    }

    @Test("description が適切な説明を返す")
    func descriptionText() {
        let frontal = FaceAngle(yaw: 0, pitch: 0, roll: 0)
        #expect(frontal.description.contains("正面"))

        let left = FaceAngle(yaw: 45, pitch: 0, roll: 0)
        #expect(left.description.contains("左"))

        let right = FaceAngle(yaw: -45, pitch: 0, roll: 0)
        #expect(right.description.contains("右"))

        let up = FaceAngle(yaw: 0, pitch: 45, roll: 0)
        #expect(up.description.contains("上"))

        let down = FaceAngle(yaw: 0, pitch: -45, roll: 0)
        #expect(down.description.contains("下"))
    }

    @Test("Codable が正しく動作する")
    func codableRoundTrip() throws {
        let original = FaceAngle(yaw: 15.5, pitch: -10.0, roll: 5.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FaceAngle.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - AnalysisIssue Tests

@Suite("AnalysisIssue テスト")
struct AnalysisIssueTests {

    @Test("description が各問題タイプに対して適切な値を返す")
    func descriptionForEachType() {
        let blurry = AnalysisIssue.blurry(score: 0.6)
        #expect(!blurry.description.isEmpty)

        let lowQuality = AnalysisIssue.lowQuality(score: 0.3)
        #expect(!lowQuality.description.isEmpty)

        let overexposed = AnalysisIssue.overexposed(score: 0.9)
        #expect(!overexposed.description.isEmpty)

        let underexposed = AnalysisIssue.underexposed(score: 0.1)
        #expect(!underexposed.description.isEmpty)
    }

    @Test("iconName が各問題タイプに対して有効な SF Symbol 名を返す")
    func iconNameForEachType() {
        let blurry = AnalysisIssue.blurry(score: 0.6)
        #expect(!blurry.iconName.isEmpty)

        let lowQuality = AnalysisIssue.lowQuality(score: 0.3)
        #expect(!lowQuality.iconName.isEmpty)

        let overexposed = AnalysisIssue.overexposed(score: 0.9)
        #expect(!overexposed.iconName.isEmpty)

        let underexposed = AnalysisIssue.underexposed(score: 0.1)
        #expect(!underexposed.iconName.isEmpty)
    }

    @Test("severity が正しく計算される")
    func severityCalculation() {
        let epsilon: Float = 0.0001

        // blurry: スコアがそのまま深刻度
        let blurry = AnalysisIssue.blurry(score: 0.7)
        #expect(abs(blurry.severity - 0.7) < epsilon)

        // lowQuality: 1 - スコア
        let lowQuality = AnalysisIssue.lowQuality(score: 0.3)
        #expect(abs(lowQuality.severity - 0.7) < epsilon)

        // overexposed: (スコア - 0.5) * 2
        let overexposed = AnalysisIssue.overexposed(score: 0.9)
        #expect(abs(overexposed.severity - 0.8) < epsilon)

        // underexposed: (0.5 - スコア) * 2
        let underexposed = AnalysisIssue.underexposed(score: 0.1)
        #expect(abs(underexposed.severity - 0.8) < epsilon)
    }

    @Test("Hashable が正しく動作する")
    func hashable() {
        let issue1 = AnalysisIssue.blurry(score: 0.6)
        let issue2 = AnalysisIssue.blurry(score: 0.6)
        let issue3 = AnalysisIssue.blurry(score: 0.7)

        #expect(issue1 == issue2)
        #expect(issue1 != issue3)

        let set: Set<AnalysisIssue> = [issue1, issue2, issue3]
        #expect(set.count == 2)
    }
}

// MARK: - AnalysisThresholds Tests

@Suite("AnalysisThresholds テスト")
struct AnalysisThresholdsTests {

    @Test("デフォルト閾値が設定されている")
    func defaultThresholds() {
        #expect(AnalysisThresholds.blurThreshold == 0.4)
        #expect(AnalysisThresholds.highQualityThreshold == 0.7)
        #expect(AnalysisThresholds.lowQualityThreshold == 0.4)
        #expect(AnalysisThresholds.overexposedThreshold == 0.8)
        #expect(AnalysisThresholds.underexposedThreshold == 0.2)
        #expect(AnalysisThresholds.similarityThreshold == 0.85)
        #expect(AnalysisThresholds.selfieMinFaceRatio == 0.15)
    }

    @Test("閾値は適切な範囲内にある")
    func thresholdsAreInValidRange() {
        // すべての閾値が0.0〜1.0の範囲内にあることを確認
        #expect(AnalysisThresholds.blurThreshold >= 0.0 && AnalysisThresholds.blurThreshold <= 1.0)
        #expect(AnalysisThresholds.highQualityThreshold >= 0.0 && AnalysisThresholds.highQualityThreshold <= 1.0)
        #expect(AnalysisThresholds.lowQualityThreshold >= 0.0 && AnalysisThresholds.lowQualityThreshold <= 1.0)
        #expect(AnalysisThresholds.overexposedThreshold >= 0.0 && AnalysisThresholds.overexposedThreshold <= 1.0)
        #expect(AnalysisThresholds.underexposedThreshold >= 0.0 && AnalysisThresholds.underexposedThreshold <= 1.0)
        #expect(AnalysisThresholds.similarityThreshold >= 0.0 && AnalysisThresholds.similarityThreshold <= 1.0)
        #expect(AnalysisThresholds.selfieMinFaceRatio >= 0.0 && AnalysisThresholds.selfieMinFaceRatio <= 1.0)
    }

    @Test("閾値の論理的整合性")
    func thresholdsLogicalConsistency() {
        // 高品質閾値は低品質閾値より大きい
        #expect(AnalysisThresholds.highQualityThreshold > AnalysisThresholds.lowQualityThreshold)
        // 明るすぎ閾値は暗すぎ閾値より大きい
        #expect(AnalysisThresholds.overexposedThreshold > AnalysisThresholds.underexposedThreshold)
    }
}

// MARK: - PhotoAnalysisResult.Builder Tests

@Suite("PhotoAnalysisResult.Builder テスト")
struct PhotoAnalysisResultBuilderTests {

    @Test("ビルダーでデフォルト値を持つ結果を構築できる")
    func buildWithDefaults() {
        let builder = PhotoAnalysisResult.Builder(photoId: "builder-test")
        let result = builder.build()

        #expect(result.photoId == "builder-test")
        #expect(result.qualityScore == 0.5)
        #expect(result.blurScore == 0.0)
        #expect(result.brightnessScore == 0.5)
        #expect(result.faceCount == 0)
        #expect(result.isScreenshot == false)
    }

    @Test("ビルダーで各プロパティを設定できる")
    func buildWithCustomValues() {
        let builder = PhotoAnalysisResult.Builder(photoId: "custom")
            .setQualityScore(0.9)
            .setBlurScore(0.1)
            .setBrightnessScore(0.6)
            .setContrastScore(0.7)
            .setSaturationScore(0.8)
            .setFaceResults(count: 2, qualityScores: [0.9, 0.8], angles: [FaceAngle(yaw: 0, pitch: 0, roll: 0)])
            .setIsScreenshot(true)
            .setIsSelfie(true)
            .setFeaturePrintHash(Data([0x01]))

        let result = builder.build()

        #expect(result.qualityScore == 0.9)
        #expect(result.blurScore == 0.1)
        #expect(result.brightnessScore == 0.6)
        #expect(result.contrastScore == 0.7)
        #expect(result.saturationScore == 0.8)
        #expect(result.faceCount == 2)
        #expect(result.faceQualityScores == [0.9, 0.8])
        #expect(result.faceAngles.count == 1)
        #expect(result.isScreenshot == true)
        #expect(result.isSelfie == true)
        #expect(result.featurePrintHash != nil)
    }

    @Test("ビルダーはメソッドチェーンをサポートする")
    func builderMethodChaining() {
        let result = PhotoAnalysisResult.Builder(photoId: "chain")
            .setQualityScore(0.8)
            .setBlurScore(0.2)
            .setBrightnessScore(0.5)
            .build()

        #expect(result.qualityScore == 0.8)
        #expect(result.blurScore == 0.2)
        #expect(result.brightnessScore == 0.5)
    }

    @Test("ビルダーは複数回 build を呼び出せる")
    func builderCanBuildMultipleTimes() {
        let builder = PhotoAnalysisResult.Builder(photoId: "multi")
            .setQualityScore(0.7)

        let result1 = builder.build()
        builder.setQualityScore(0.9)
        let result2 = builder.build()

        #expect(result1.qualityScore == 0.7)
        #expect(result2.qualityScore == 0.9)
    }
}

// MARK: - Array Extension Tests

@Suite("PhotoAnalysisResult 配列拡張テスト")
struct PhotoAnalysisResultArrayExtensionTests {

    private func makeResults() -> [PhotoAnalysisResult] {
        [
            PhotoAnalysisResult(
                id: "1", photoId: "p1", qualityScore: 0.9, blurScore: 0.1,
                brightnessScore: 0.5, faceCount: 1, faceQualityScores: [0.8],
                isScreenshot: false, featurePrintHash: nil
            ),
            PhotoAnalysisResult(
                id: "2", photoId: "p2", qualityScore: 0.3, blurScore: 0.6,
                brightnessScore: 0.5, faceCount: 0, faceQualityScores: [],
                isScreenshot: true, featurePrintHash: nil
            ),
            PhotoAnalysisResult(
                id: "3", photoId: "p3", qualityScore: 0.7, blurScore: 0.2,
                brightnessScore: 0.5, faceCount: 2, faceQualityScores: [0.9, 0.7],
                isScreenshot: false, isSelfie: true, featurePrintHash: nil
            )
        ]
    }

    @Test("sortedByQuality で品質順にソートされる")
    func sortedByQuality() {
        let results = makeResults()
        let sorted = results.sortedByQuality()

        #expect(sorted[0].id == "1") // 0.9
        #expect(sorted[1].id == "3") // 0.7
        #expect(sorted[2].id == "2") // 0.3
    }

    @Test("sortedBySharpness でシャープ順にソートされる")
    func sortedBySharpness() {
        let results = makeResults()
        let sorted = results.sortedBySharpness()

        #expect(sorted[0].id == "1") // blur 0.1
        #expect(sorted[1].id == "3") // blur 0.2
        #expect(sorted[2].id == "2") // blur 0.6
    }

    @Test("filterDeletionCandidates で削除候補をフィルタ")
    func filterDeletionCandidates() {
        let results = makeResults()
        let candidates = results.filterDeletionCandidates()

        // id: 2 のみが削除候補（isBlurry: 0.6 >= 0.4, isLowQuality: 0.3 < 0.4）
        #expect(candidates.count == 1)
        #expect(candidates[0].id == "2")
    }

    @Test("filterHighQuality で高品質をフィルタ")
    func filterHighQuality() {
        let results = makeResults()
        let highQuality = results.filterHighQuality()

        #expect(highQuality.count == 2) // id: 1 (0.9), id: 3 (0.7)
    }

    @Test("filterWithFaces で顔ありをフィルタ")
    func filterWithFaces() {
        let results = makeResults()
        let withFaces = results.filterWithFaces()

        #expect(withFaces.count == 2) // id: 1, 3
    }

    @Test("filterSelfies で自撮りをフィルタ")
    func filterSelfies() {
        let results = makeResults()
        let selfies = results.filterSelfies()

        #expect(selfies.count == 1) // id: 3
    }

    @Test("filterScreenshots でスクリーンショットをフィルタ")
    func filterScreenshots() {
        let results = makeResults()
        let screenshots = results.filterScreenshots()

        #expect(screenshots.count == 1) // id: 2
    }

    @Test("filterBlurry でブレ写真をフィルタ")
    func filterBlurry() {
        let results = makeResults()
        let blurry = results.filterBlurry()

        #expect(blurry.count == 1) // id: 2 (blur 0.6)
    }

    @Test("averageQualityScore が正しく計算される")
    func averageQualityScore() {
        let results = makeResults()
        let average = results.averageQualityScore

        // (0.9 + 0.3 + 0.7) / 3 ≈ 0.633
        #expect(average != nil)
        #expect(abs(average! - 0.633) < 0.01)
    }

    @Test("空配列の averageQualityScore は nil")
    func averageQualityScoreEmpty() {
        let results: [PhotoAnalysisResult] = []
        #expect(results.averageQualityScore == nil)
    }

    @Test("bestQuality が最高品質を返す")
    func bestQuality() {
        let results = makeResults()
        let best = results.bestQuality

        #expect(best?.id == "1") // 0.9
    }

    @Test("worstQuality が最低品質を返す")
    func worstQuality() {
        let results = makeResults()
        let worst = results.worstQuality

        #expect(worst?.id == "2") // 0.3
    }
}
