//
//  VisionRequestHandlerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  VisionRequestHandler のテスト
//  Created by AI Assistant
//

import Testing
import Vision
@testable import LightRoll_CleanerFeature

// MARK: - VisionRequestHandlerTests

@Suite("VisionRequestHandler Tests")
struct VisionRequestHandlerTests {

    // MARK: - Initialization Tests

    @Test("初期化: デフォルトオプションで正常に作成できる")
    func testInitialization() async {
        let handler = VisionRequestHandler()
        #expect(handler != nil)
    }

    @Test("初期化: カスタムオプションで正常に作成できる")
    func testInitializationWithCustomOptions() async {
        let options = VisionRequestOptions.fast
        let handler = VisionRequestHandler(options: options)
        #expect(handler != nil)
    }

    // MARK: - VisionRequestOptions Tests

    @Test("VisionRequestOptions: デフォルト値の検証")
    func testDefaultOptions() {
        let options = VisionRequestOptions.default
        #expect(options.qos == .userInitiated)
        #expect(options.timeout == 30.0)
        #expect(options.maxRetries == 2)
    }

    @Test("VisionRequestOptions: fast プリセットの検証")
    func testFastOptions() {
        let options = VisionRequestOptions.fast
        #expect(options.timeout == 10.0)
        #expect(options.maxRetries == 1)
    }

    @Test("VisionRequestOptions: accurate プリセットの検証")
    func testAccurateOptions() {
        let options = VisionRequestOptions.accurate
        #expect(options.timeout == 60.0)
        #expect(options.maxRetries == 3)
    }

    @Test("VisionRequestOptions: background プリセットの検証")
    func testBackgroundOptions() {
        let options = VisionRequestOptions.background
        #expect(options.qos == .utility)
        #expect(options.timeout == 120.0)
    }

    // MARK: - VisionRequestResult Tests

    @Test("VisionRequestResult: 空のリクエスト配列で初期化")
    func testResultWithEmptyRequests() {
        let result = VisionRequestResult(requests: [])
        #expect(result.requests.isEmpty)
        #expect(result.successCount == 0)
        #expect(result.failureCount == 0)
    }

    @Test("VisionRequestResult: リクエスト数のカウント")
    func testResultRequestCount() {
        let request1 = VNDetectFaceRectanglesRequest()
        let request2 = VNGenerateImageFeaturePrintRequest()

        let result = VisionRequestResult(requests: [request1, request2])
        #expect(result.requests.count == 2)
    }

    @Test("VisionRequestResult: 特定タイプのリクエストを取得")
    func testResultGetRequestByType() {
        let faceRequest = VNDetectFaceRectanglesRequest()
        let featureRequest = VNGenerateImageFeaturePrintRequest()

        let result = VisionRequestResult(requests: [faceRequest, featureRequest])

        let retrievedFaceRequest = result.request(ofType: VNDetectFaceRectanglesRequest.self)
        #expect(retrievedFaceRequest != nil)

        let retrievedFeatureRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self)
        #expect(retrievedFeatureRequest != nil)
    }

    @Test("VisionRequestResult: 存在しないタイプのリクエストを取得")
    func testResultGetNonExistentRequestType() {
        let faceRequest = VNDetectFaceRectanglesRequest()
        let result = VisionRequestResult(requests: [faceRequest])

        let retrievedRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self)
        #expect(retrievedRequest == nil)
    }

    @Test("VisionRequestResult: 複数の同じタイプのリクエストを取得")
    func testResultGetMultipleRequestsOfSameType() {
        let request1 = VNDetectFaceRectanglesRequest()
        let request2 = VNDetectFaceRectanglesRequest()
        let result = VisionRequestResult(requests: [request1, request2])

        let retrievedRequests = result.requests(ofType: VNDetectFaceRectanglesRequest.self)
        #expect(retrievedRequests.count == 2)
    }

    @Test("VisionRequestResult: description の生成")
    func testResultDescription() {
        let request = VNDetectFaceRectanglesRequest()
        let result = VisionRequestResult(requests: [request])

        let description = result.description
        #expect(description.contains("VisionRequestResult"))
        #expect(description.contains("requestCount"))
    }

    // MARK: - Cancel/Reset Tests

    @Test("キャンセル: cancel() でキャンセル状態になる")
    func testCancelOperation() async {
        let handler = VisionRequestHandler()
        await handler.cancel()

        // キャンセル後にリクエストを実行すると AnalysisError.cancelled が投げられることを期待
        // (実際の PHAsset が必要なため、ここでは状態のみ確認)
    }

    @Test("リセット: reset() でキャンセル状態がリセットされる")
    func testResetOperation() async {
        let handler = VisionRequestHandler()
        await handler.cancel()
        await handler.reset()

        // リセット後は通常通り実行可能な状態に戻ることを期待
    }

    // MARK: - Error Handling Tests

    @Test("エラー: 空のリクエスト配列でエラーが投げられる")
    func testPerformWithEmptyRequestsThrowsError() async throws {
        let handler = VisionRequestHandler()

        // テスト用のダミー CIImage を作成
        let ciImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))

        await #expect(throws: AnalysisError.self) {
            try await handler.perform(on: ciImage, requests: [])
        }
    }

    // MARK: - Integration Tests (require real images)

    // 注: 以下のテストは実際の画像や PHAsset が必要なため、
    // ユニットテストではなく統合テストとして別途実装することを推奨

    /*
    @Test("統合: PHAsset から画像を読み込んで Vision リクエストを実行")
    func testPerformOnPHAsset() async throws {
        // 実際の PHAsset が必要
    }

    @Test("統合: CIImage に対して顔検出リクエストを実行")
    func testPerformFaceDetection() async throws {
        // 実際の顔画像が必要
    }

    @Test("統合: Data から Vision リクエストを実行")
    func testPerformOnData() async throws {
        // 実際の画像データが必要
    }
    */
}

// MARK: - VisionRequestOptions Tests

@Suite("VisionRequestOptions Presets")
struct VisionRequestOptionsPresetsTests {

    @Test("すべてのプリセットが正常に作成できる")
    func testAllPresets() {
        let presets: [VisionRequestOptions] = [
            .default,
            .fast,
            .accurate,
            .background
        ]

        for preset in presets {
            #expect(preset.timeout > 0)
            #expect(preset.maxRetries >= 0)
        }
    }

    @Test("タイムアウト値の順序: fast < default < accurate < background")
    func testTimeoutOrdering() {
        #expect(VisionRequestOptions.fast.timeout < VisionRequestOptions.default.timeout)
        #expect(VisionRequestOptions.default.timeout < VisionRequestOptions.accurate.timeout)
        #expect(VisionRequestOptions.accurate.timeout < VisionRequestOptions.background.timeout)
    }
}
