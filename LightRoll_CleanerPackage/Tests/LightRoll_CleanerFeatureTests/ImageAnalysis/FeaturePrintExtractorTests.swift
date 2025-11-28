//
//  FeaturePrintExtractorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  FeaturePrintExtractor のテスト
//  Created by AI Assistant
//

import Testing
import Vision
@testable import LightRoll_CleanerFeature

// MARK: - FeaturePrintExtractorTests

@Suite("FeaturePrintExtractor Tests")
struct FeaturePrintExtractorTests {

    // MARK: - Initialization Tests

    @Test("初期化: デフォルトオプションで正常に作成できる")
    func testInitialization() async {
        let extractor = FeaturePrintExtractor()
        #expect(extractor != nil)
    }

    @Test("初期化: カスタムオプションで正常に作成できる")
    func testInitializationWithCustomOptions() async {
        let options = ExtractionOptions.fast
        let extractor = FeaturePrintExtractor(options: options)
        #expect(extractor != nil)
    }

    @Test("初期化: カスタムハンドラーで正常に作成できる")
    func testInitializationWithCustomHandler() async {
        let handler = VisionRequestHandler()
        let extractor = FeaturePrintExtractor(visionHandler: handler)
        #expect(extractor != nil)
    }

    // MARK: - ExtractionOptions Tests

    @Test("ExtractionOptions: デフォルト値の検証")
    func testDefaultExtractionOptions() {
        let options = ExtractionOptions.default
        #expect(options.cropAndScaleOption == .centerCrop)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("ExtractionOptions: highAccuracy プリセットの検証")
    func testHighAccuracyOptions() {
        let options = ExtractionOptions.highAccuracy
        #expect(options.cropAndScaleOption == .scaleFit)
        #expect(options.maxConcurrentOperations == 2)
    }

    @Test("ExtractionOptions: fast プリセットの検証")
    func testFastOptions() {
        let options = ExtractionOptions.fast
        #expect(options.cropAndScaleOption == .centerCrop)
        #expect(options.maxConcurrentOperations == 8)
    }

    // MARK: - FeaturePrintResult Tests

    @Test("FeaturePrintResult: プロパティの検証")
    func testFeaturePrintResultProperties() {
        let photoId = "test-photo-123"

        // モック VNFeaturePrintObservation を作成
        // 注: 実際の VNFeaturePrintObservation は Vision Framework が生成するため、
        // ここではプロパティのみをテスト
        let result = createMockFeaturePrintResult(photoId: photoId)

        #expect(result.photoId == photoId)
        #expect(result.extractedAt <= Date())
        #expect(!result.featurePrintHash.isEmpty)
    }

    @Test("FeaturePrintResult: Hashable の検証")
    func testFeaturePrintResultHashable() {
        let result1 = createMockFeaturePrintResult(photoId: "photo1")
        let result2 = createMockFeaturePrintResult(photoId: "photo1")
        let result3 = createMockFeaturePrintResult(photoId: "photo2")

        // 同じ photoId でも id が異なるため等価ではない
        #expect(result1 != result2)

        // 異なる photoId は当然等価ではない
        #expect(result1 != result3)

        // Set に格納できることを確認
        let set: Set<FeaturePrintResult> = [result1, result2, result3]
        #expect(set.count == 3)
    }

    @Test("FeaturePrintResult: description の生成")
    func testFeaturePrintResultDescription() {
        let result = createMockFeaturePrintResult(photoId: "test-photo")
        let description = result.description

        #expect(description.contains("FeaturePrintResult"))
        #expect(description.contains("test-photo"))
        #expect(description.contains("elementCount"))
    }

    // MARK: - Array Extension Tests

    @Test("Array Extension: result(forPhotoId:) で写真IDから結果を取得")
    func testArrayResultForPhotoId() {
        let results = [
            createMockFeaturePrintResult(photoId: "photo1"),
            createMockFeaturePrintResult(photoId: "photo2"),
            createMockFeaturePrintResult(photoId: "photo3")
        ]

        let found = results.result(forPhotoId: "photo2")
        #expect(found?.photoId == "photo2")

        let notFound = results.result(forPhotoId: "photo99")
        #expect(notFound == nil)
    }

    @Test("Array Extension: results(forPhotoIds:) で複数の写真IDから結果を取得")
    func testArrayResultsForPhotoIds() {
        let results = [
            createMockFeaturePrintResult(photoId: "photo1"),
            createMockFeaturePrintResult(photoId: "photo2"),
            createMockFeaturePrintResult(photoId: "photo3"),
            createMockFeaturePrintResult(photoId: "photo4")
        ]

        let photoIds: Set<String> = ["photo1", "photo3", "photo99"]
        let filtered = results.results(forPhotoIds: photoIds)

        #expect(filtered.count == 2)
        #expect(filtered.contains { $0.photoId == "photo1" })
        #expect(filtered.contains { $0.photoId == "photo3" })
    }

    @Test("Array Extension: byPhotoId で辞書に変換")
    func testArrayByPhotoId() {
        let results = [
            createMockFeaturePrintResult(photoId: "photo1"),
            createMockFeaturePrintResult(photoId: "photo2"),
            createMockFeaturePrintResult(photoId: "photo3")
        ]

        let dict = results.byPhotoId
        #expect(dict.count == 3)
        #expect(dict["photo1"]?.photoId == "photo1")
        #expect(dict["photo2"]?.photoId == "photo2")
        #expect(dict["photo3"]?.photoId == "photo3")
    }

    @Test("Array Extension: averageElementCount の計算")
    func testArrayAverageElementCount() {
        let results = [
            createMockFeaturePrintResult(photoId: "photo1", elementCount: 100),
            createMockFeaturePrintResult(photoId: "photo2", elementCount: 200),
            createMockFeaturePrintResult(photoId: "photo3", elementCount: 300)
        ]

        let average = results.averageElementCount
        #expect(average == 200.0)
    }

    @Test("Array Extension: 空配列の averageElementCount は nil")
    func testArrayAverageElementCountEmpty() {
        let results: [FeaturePrintResult] = []
        #expect(results.averageElementCount == nil)
    }

    // MARK: - Integration Tests (require real images)

    // 注: 以下のテストは実際の画像や PHAsset が必要なため、
    // ユニットテストではなく統合テストとして別途実装することを推奨

    /*
    @Test("統合: PHAsset から特徴量を抽出")
    func testExtractFeaturePrintFromAsset() async throws {
        // 実際の PHAsset が必要
    }

    @Test("統合: 複数の PHAsset から一括抽出")
    func testExtractFeaturePrintsFromMultipleAssets() async throws {
        // 実際の PHAsset 配列が必要
    }

    @Test("統合: Photo モデルから特徴量を抽出")
    func testExtractFeaturePrintFromPhoto() async throws {
        // 実際の Photo オブジェクトが必要
    }
    */

    // MARK: - Helper Methods

    /// モック FeaturePrintResult を作成するヘルパーメソッド
    private func createMockFeaturePrintResult(
        photoId: String,
        elementCount: Int = 128
    ) -> FeaturePrintResult {
        // モックデータを作成
        let mockHash = Data(count: elementCount * MemoryLayout<Float>.size)

        // Swift 5モードでは静的ファクトリメソッドを使用
        return FeaturePrintResult.mock(
            photoId: photoId,
            featurePrintHash: mockHash,
            elementCount: elementCount
        )
    }
}

// MARK: - FeaturePrintResult + Mock Initializer

extension FeaturePrintResult {
    /// テスト用のイニシャライザ（モック用）
    /// - Note: Swift 5モードでは、通常のCodableデコーダー経由で生成するのが安全
    static func mock(
        id: UUID = UUID(),
        photoId: String = "test-photo-id",
        featurePrintHash: Data = Data(repeating: 0, count: 128),
        extractedAt: Date = Date(),
        elementCount: Int = 128,
        elementType: VNElementType = .float
    ) -> FeaturePrintResult {
        // JSONエンコード/デコードを使用して安全にインスタンスを作成
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let mockData: [String: Any] = [
            "id": id.uuidString,
            "photoId": photoId,
            "featurePrintHash": featurePrintHash.base64EncodedString(),
            "extractedAt": extractedAt.timeIntervalSince1970,
            "elementCount": elementCount,
            "elementType": elementType.rawValue
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mockData)
            return try decoder.decode(FeaturePrintResult.self, from: jsonData)
        } catch {
            fatalError("Failed to create mock FeaturePrintResult: \(error)")
        }
    }
}
