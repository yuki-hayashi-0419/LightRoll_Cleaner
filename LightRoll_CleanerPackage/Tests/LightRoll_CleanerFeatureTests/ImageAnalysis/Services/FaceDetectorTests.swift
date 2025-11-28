//
//  FaceDetectorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  FaceDetectorのテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import Vision
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - FaceDetector Tests

@Suite("FaceDetector Tests", .serialized)
struct FaceDetectorTests {

    // MARK: - Initialization Tests

    @Test("初期化 - デフォルトオプション")
    func testInitialization_defaultOptions() async throws {
        // When
        let sut = FaceDetector()

        // Then: インスタンス生成成功を確認
        #expect(sut != nil)
    }

    @Test("初期化 - カスタムオプション")
    func testInitialization_customOptions() async throws {
        // Given
        let options = FaceDetectionOptions(
            selfieMinFaceRatio: 0.20,
            batchSize: 200
        )

        // When
        let sut = FaceDetector(options: options)

        // Then: インスタンス生成成功を確認
        #expect(sut != nil)
    }

    // MARK: - FaceDetectionOptions Tests

    @Test("FaceDetectionOptions - デフォルト値")
    func testFaceDetectionOptions_defaultValues() {
        // When
        let options = FaceDetectionOptions.default

        // Then
        #expect(options.selfieMinFaceRatio == 0.15)
        #expect(options.batchSize == 500)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("FaceDetectionOptions - 厳格モード")
    func testFaceDetectionOptions_strictMode() {
        // When
        let options = FaceDetectionOptions.strict

        // Then
        #expect(options.selfieMinFaceRatio == 0.20)
        #expect(options.batchSize == 200)
        #expect(options.maxConcurrentOperations == 2)
    }

    @Test("FaceDetectionOptions - 緩和モード")
    func testFaceDetectionOptions_relaxedMode() {
        // When
        let options = FaceDetectionOptions.relaxed

        // Then
        #expect(options.selfieMinFaceRatio == 0.10)
        #expect(options.batchSize == 1000)
        #expect(options.maxConcurrentOperations == 8)
    }

    @Test("FaceDetectionOptions - 閾値の範囲制限")
    func testFaceDetectionOptions_thresholdClamping() {
        // Given & When
        let tooLow = FaceDetectionOptions(selfieMinFaceRatio: -0.5)
        let tooHigh = FaceDetectionOptions(selfieMinFaceRatio: 1.5)
        let valid = FaceDetectionOptions(selfieMinFaceRatio: 0.2)

        // Then
        #expect(tooLow.selfieMinFaceRatio == 0.0)
        #expect(tooHigh.selfieMinFaceRatio == 1.0)
        #expect(valid.selfieMinFaceRatio == 0.2)
    }

    @Test("FaceDetectionOptions - バッチサイズの制限")
    func testFaceDetectionOptions_batchSizeClamping() {
        // Given & When
        let zero = FaceDetectionOptions(batchSize: 0)
        let negative = FaceDetectionOptions(batchSize: -100)
        let valid = FaceDetectionOptions(batchSize: 200)

        // Then
        #expect(zero.batchSize == 1) // 最小値は1
        #expect(negative.batchSize == 1)
        #expect(valid.batchSize == 200)
    }

    // MARK: - FaceDetectionResult Tests

    @Test("FaceDetectionResult - 初期化")
    func testFaceDetectionResult_initialization() {
        // Given
        let faces = [
            FaceInfo(
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
                confidence: 0.95
            )
        ]

        // When
        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: faces,
            isSelfie: true
        )

        // Then
        #expect(result.photoId == "photo1")
        #expect(result.faceCount == 1)
        #expect(result.isSelfie == true)
        #expect(result.hasFaces == true)
    }

    @Test("FaceDetectionResult - 顔なし")
    func testFaceDetectionResult_noFaces() {
        // When
        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: []
        )

        // Then
        #expect(result.faceCount == 0)
        #expect(result.hasFaces == false)
        #expect(result.hasMultipleFaces == false)
    }

    @Test("FaceDetectionResult - 複数の顔")
    func testFaceDetectionResult_multipleFaces() {
        // Given
        let faces = [
            FaceInfo(boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.4), confidence: 0.9),
            FaceInfo(boundingBox: CGRect(x: 0.5, y: 0.2, width: 0.3, height: 0.4), confidence: 0.85)
        ]

        // When
        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: faces
        )

        // Then
        #expect(result.faceCount == 2)
        #expect(result.hasFaces == true)
        #expect(result.hasMultipleFaces == true)
    }

    @Test("FaceDetectionResult - 平均信頼度")
    func testFaceDetectionResult_averageConfidence() {
        // Given
        let faces = [
            FaceInfo(boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.4), confidence: 0.9),
            FaceInfo(boundingBox: CGRect(x: 0.5, y: 0.2, width: 0.3, height: 0.4), confidence: 0.8)
        ]

        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: faces
        )

        // When
        let avgConfidence = result.averageConfidence

        // Then
        #expect(avgConfidence != nil)
        #expect(abs(avgConfidence! - 0.85) < 0.01) // 0.85 ± 0.01
    }

    @Test("FaceDetectionResult - 平均信頼度（顔なし）")
    func testFaceDetectionResult_averageConfidence_noFaces() {
        // Given
        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: []
        )

        // When
        let avgConfidence = result.averageConfidence

        // Then
        #expect(avgConfidence == nil)
    }

    @Test("FaceDetectionResult - 正面顔カウント")
    func testFaceDetectionResult_frontalFaceCount() {
        // Given
        let faces = [
            FaceInfo(
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.4),
                confidence: 0.9,
                yaw: 10.0,
                pitch: 5.0
            ),
            FaceInfo(
                boundingBox: CGRect(x: 0.5, y: 0.2, width: 0.3, height: 0.4),
                confidence: 0.85,
                yaw: 50.0, // 横向き
                pitch: 10.0
            )
        ]

        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: faces
        )

        // When
        let frontalCount = result.frontalFaceCount

        // Then
        #expect(frontalCount == 1) // 1つ目だけ正面
    }

    @Test("FaceDetectionResult - 最大顔サイズ")
    func testFaceDetectionResult_maxFaceSize() {
        // Given
        let faces = [
            FaceInfo(boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.4), confidence: 0.9), // area = 0.12
            FaceInfo(boundingBox: CGRect(x: 0.5, y: 0.2, width: 0.4, height: 0.5), confidence: 0.85)  // area = 0.20
        ]

        let result = FaceDetectionResult(
            photoId: "photo1",
            faces: faces
        )

        // When
        let maxSize = result.maxFaceSize

        // Then
        #expect(maxSize != nil)
        #expect(abs(maxSize! - 0.20) < 0.01)
    }

    // MARK: - FaceInfo Tests

    @Test("FaceInfo - 初期化")
    func testFaceInfo_initialization() {
        // When
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95,
            roll: 10.0,
            yaw: 5.0,
            pitch: -3.0
        )

        // Then
        #expect(face.boundingBox.origin.x == 0.2)
        #expect(face.confidence == 0.95)
        #expect(face.roll == 10.0)
        #expect(face.yaw == 5.0)
        #expect(face.pitch == -3.0)
    }

    @Test("FaceInfo - 信頼度のクランプ")
    func testFaceInfo_confidenceClamping() {
        // Given & When
        let tooLow = FaceInfo(
            boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
            confidence: -0.5
        )
        let tooHigh = FaceInfo(
            boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
            confidence: 1.5
        )

        // Then
        #expect(tooLow.confidence == 0.0)
        #expect(tooHigh.confidence == 1.0)
    }

    @Test("FaceInfo - 面積計算")
    func testFaceInfo_areaCalculation() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95
        )

        // When
        let area = face.area

        // Then
        #expect(abs(area - 0.20) < 0.001) // 0.4 * 0.5 = 0.20
    }

    @Test("FaceInfo - 正面判定（正面）")
    func testFaceInfo_isFrontal_frontal() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95,
            yaw: 10.0,
            pitch: 5.0
        )

        // When & Then
        #expect(face.isFrontal == true)
    }

    @Test("FaceInfo - 正面判定（横向き）")
    func testFaceInfo_isFrontal_sideProfile() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95,
            yaw: 50.0,
            pitch: 5.0
        )

        // When & Then
        #expect(face.isFrontal == false)
        #expect(face.isSideProfile == true)
    }

    @Test("FaceInfo - 正面判定（角度情報なし）")
    func testFaceInfo_isFrontal_noAngles() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95
        )

        // When & Then
        #expect(face.isFrontal == false)
    }

    @Test("FaceInfo - 中心座標")
    func testFaceInfo_center() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95
        )

        // When
        let center = face.center

        // Then
        #expect(abs(center.x - 0.4) < 0.01) // 0.2 + 0.4/2 = 0.4
        #expect(abs(center.y - 0.55) < 0.01) // 0.3 + 0.5/2 = 0.55
    }

    @Test("FaceInfo - FaceAngle変換（成功）")
    func testFaceInfo_toFaceAngle_success() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95,
            roll: 10.0,
            yaw: 5.0,
            pitch: -3.0
        )

        // When
        let faceAngle = face.toFaceAngle()

        // Then
        #expect(faceAngle != nil)
        #expect(faceAngle!.yaw == 5.0)
        #expect(faceAngle!.pitch == -3.0)
        #expect(faceAngle!.roll == 10.0)
    }

    @Test("FaceInfo - FaceAngle変換（角度情報なし）")
    func testFaceInfo_toFaceAngle_noAngles() {
        // Given
        let face = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95
        )

        // When
        let faceAngle = face.toFaceAngle()

        // Then
        #expect(faceAngle == nil)
    }

    // MARK: - Codable Tests

    @Test("FaceDetectionResult - Codable")
    func testFaceDetectionResult_codable() throws {
        // Given
        let faces = [
            FaceInfo(
                boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
                confidence: 0.95,
                roll: 10.0,
                yaw: 5.0,
                pitch: -3.0
            )
        ]

        let original = FaceDetectionResult(
            photoId: "photo1",
            faces: faces,
            isSelfie: true
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FaceDetectionResult.self, from: data)

        // Then
        #expect(decoded.photoId == original.photoId)
        #expect(decoded.faceCount == original.faceCount)
        #expect(decoded.isSelfie == original.isSelfie)
        #expect(decoded.faces[0].confidence == original.faces[0].confidence)
    }

    @Test("FaceInfo - Codable")
    func testFaceInfo_codable() throws {
        // Given
        let original = FaceInfo(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            confidence: 0.95,
            roll: 10.0,
            yaw: 5.0,
            pitch: -3.0
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FaceInfo.self, from: data)

        // Then
        #expect(decoded.boundingBox == original.boundingBox)
        #expect(decoded.confidence == original.confidence)
        #expect(decoded.roll == original.roll)
        #expect(decoded.yaw == original.yaw)
        #expect(decoded.pitch == original.pitch)
    }

    // MARK: - Array Extension Tests

    @Test("Array<FaceDetectionResult> - filterSelfies")
    func testArrayExtension_filterSelfies() {
        // Given
        let selfie = FaceDetectionResult(photoId: "photo1", faces: [], isSelfie: true)
        let nonSelfie = FaceDetectionResult(photoId: "photo2", faces: [], isSelfie: false)
        let results = [selfie, nonSelfie]

        // When
        let filtered = results.filterSelfies()

        // Then
        #expect(filtered.count == 1)
        #expect(filtered.contains(selfie))
    }

    @Test("Array<FaceDetectionResult> - filterWithFaces")
    func testArrayExtension_filterWithFaces() {
        // Given
        let withFace = FaceDetectionResult(
            photoId: "photo1",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), confidence: 0.9)
            ]
        )
        let withoutFace = FaceDetectionResult(photoId: "photo2", faces: [])
        let results = [withFace, withoutFace]

        // When
        let filtered = results.filterWithFaces()

        // Then
        #expect(filtered.count == 1)
        #expect(filtered.contains(withFace))
    }

    @Test("Array<FaceDetectionResult> - filterWithMultipleFaces")
    func testArrayExtension_filterWithMultipleFaces() {
        // Given
        let oneFace = FaceDetectionResult(
            photoId: "photo1",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), confidence: 0.9)
            ]
        )
        let twoFaces = FaceDetectionResult(
            photoId: "photo2",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.3, height: 0.3), confidence: 0.9),
                FaceInfo(boundingBox: CGRect(x: 0.5, y: 0, width: 0.3, height: 0.3), confidence: 0.85)
            ]
        )
        let results = [oneFace, twoFaces]

        // When
        let filtered = results.filterWithMultipleFaces()

        // Then
        #expect(filtered.count == 1)
        #expect(filtered.contains(twoFaces))
    }

    @Test("Array<FaceDetectionResult> - filterWithoutFaces")
    func testArrayExtension_filterWithoutFaces() {
        // Given
        let withFace = FaceDetectionResult(
            photoId: "photo1",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), confidence: 0.9)
            ]
        )
        let withoutFace = FaceDetectionResult(photoId: "photo2", faces: [])
        let results = [withFace, withoutFace]

        // When
        let filtered = results.filterWithoutFaces()

        // Then
        #expect(filtered.count == 1)
        #expect(filtered.contains(withoutFace))
    }

    @Test("Array<FaceDetectionResult> - totalFaceCount")
    func testArrayExtension_totalFaceCount() {
        // Given
        let result1 = FaceDetectionResult(
            photoId: "photo1",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), confidence: 0.9)
            ]
        )
        let result2 = FaceDetectionResult(
            photoId: "photo2",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.3, height: 0.3), confidence: 0.9),
                FaceInfo(boundingBox: CGRect(x: 0.5, y: 0, width: 0.3, height: 0.3), confidence: 0.85)
            ]
        )
        let result3 = FaceDetectionResult(photoId: "photo3", faces: [])
        let results = [result1, result2, result3]

        // When
        let total = results.totalFaceCount

        // Then
        #expect(total == 3) // 1 + 2 + 0 = 3
    }

    @Test("Array<FaceDetectionResult> - averageFaceCount")
    func testArrayExtension_averageFaceCount() {
        // Given
        let result1 = FaceDetectionResult(
            photoId: "photo1",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), confidence: 0.9)
            ]
        )
        let result2 = FaceDetectionResult(
            photoId: "photo2",
            faces: [
                FaceInfo(boundingBox: CGRect(x: 0, y: 0, width: 0.3, height: 0.3), confidence: 0.9),
                FaceInfo(boundingBox: CGRect(x: 0.5, y: 0, width: 0.3, height: 0.3), confidence: 0.85)
            ]
        )
        let results = [result1, result2]

        // When
        let average = results.averageFaceCount

        // Then
        #expect(average != nil)
        #expect(abs(average! - 1.5) < 0.01) // (1 + 2) / 2 = 1.5
    }

    @Test("Array<FaceDetectionResult> - averageFaceCount（空配列）")
    func testArrayExtension_averageFaceCount_empty() {
        // Given
        let results: [FaceDetectionResult] = []

        // When
        let average = results.averageFaceCount

        // Then
        #expect(average == nil)
    }

    @Test("Array<FaceDetectionResult> - selfieCount")
    func testArrayExtension_selfieCount() {
        // Given
        let selfie1 = FaceDetectionResult(photoId: "photo1", faces: [], isSelfie: true)
        let selfie2 = FaceDetectionResult(photoId: "photo2", faces: [], isSelfie: true)
        let nonSelfie = FaceDetectionResult(photoId: "photo3", faces: [], isSelfie: false)
        let results = [selfie1, selfie2, nonSelfie]

        // When
        let count = results.selfieCount

        // Then
        #expect(count == 2)
    }

    @Test("Array<FaceDetectionResult> - selfieRatio")
    func testArrayExtension_selfieRatio() {
        // Given
        let selfie = FaceDetectionResult(photoId: "photo1", faces: [], isSelfie: true)
        let nonSelfie1 = FaceDetectionResult(photoId: "photo2", faces: [], isSelfie: false)
        let nonSelfie2 = FaceDetectionResult(photoId: "photo3", faces: [], isSelfie: false)
        let results = [selfie, nonSelfie1, nonSelfie2]

        // When
        let ratio = results.selfieRatio

        // Then
        #expect(ratio != nil)
        #expect(abs(ratio! - 0.333) < 0.01) // 1/3 ≈ 0.333
    }

    @Test("Array<FaceDetectionResult> - selfieRatio（空配列）")
    func testArrayExtension_selfieRatio_empty() {
        // Given
        let results: [FaceDetectionResult] = []

        // When
        let ratio = results.selfieRatio

        // Then
        #expect(ratio == nil)
    }

    // MARK: - Collection Chunking Tests

    @Test("Collection.chunked - 均等分割")
    func testCollectionChunked_evenDivision() {
        // Given
        let array = [1, 2, 3, 4, 5, 6]

        // When
        let chunks = array.chunked(into: 2)

        // Then
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2])
        #expect(chunks[1] == [3, 4])
        #expect(chunks[2] == [5, 6])
    }

    @Test("Collection.chunked - 不均等分割")
    func testCollectionChunked_unevenDivision() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let chunks = array.chunked(into: 2)

        // Then
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2])
        #expect(chunks[1] == [3, 4])
        #expect(chunks[2] == [5])
    }

    @Test("Collection.chunked - 空配列")
    func testCollectionChunked_emptyArray() {
        // Given
        let array: [Int] = []

        // When
        let chunks = array.chunked(into: 2)

        // Then
        #expect(chunks.isEmpty)
    }

    @Test("Collection.chunked - サイズより小さい配列")
    func testCollectionChunked_smallerThanChunkSize() {
        // Given
        let array = [1, 2]

        // When
        let chunks = array.chunked(into: 5)

        // Then
        #expect(chunks.count == 1)
        #expect(chunks[0] == [1, 2])
    }
}

// MARK: - Integration Tests

@Suite("FaceDetector Integration Tests", .serialized)
struct FaceDetectorIntegrationTests {

    @Test("空の配列を渡した場合は空の結果を返す")
    func testDetectFaces_emptyArray() async throws {
        // Given
        let sut = FaceDetector()
        let emptyAssets: [PHAsset] = []

        // When
        let result = try await sut.detectFaces(in: emptyAssets)

        // Then
        #expect(result.isEmpty)
    }

    // 注: 実際のPHAssetを使用した統合テストは、
    // テスト環境でのフォトライブラリアクセスが必要なため、
    // UIテストまたはモックを使用した単体テストで実施
}
