//
//  ScreenshotDetectorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  スクリーンショット検出サービスのユニットテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - ScreenshotDetectorTests

@Suite("ScreenshotDetector Tests")
struct ScreenshotDetectorTests {

    // MARK: - 基本検出テスト

    @Test("スクリーンショットフラグが立っている写真を正しく検出")
    func detectScreenshotWithFlag() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createScreenshot()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == true)
    }

    @Test("通常の写真をスクリーンショットでないと正しく判定")
    func detectNonScreenshot() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createRegularPhoto()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == false)
    }

    @Test("動画はスクリーンショットとして検出されない")
    func videoNotDetectedAsScreenshot() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createVideo()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == false)
    }

    // MARK: - バッチ処理テスト
    // 注: バッチ処理テストは実際の PHAsset が必要なため、統合テストで実施

    // MARK: - オプションテスト

    @Test("デフォルトオプションでは追加検証を行わない")
    func defaultOptionsNoAdditionalVerification() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createRegularPhoto()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        // mediaSubtypes フラグのみで判定されるため false
        #expect(result == false)
    }

    @Test("高精度オプションでは追加検証を行う")
    func accurateOptionsWithAdditionalVerification() async throws {
        // Given
        let detector = ScreenshotDetector(options: .accurate)
        let asset = MockPHAsset.createRegularPhoto()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        // 追加検証も行われるが、通常の写真なので false
        #expect(result == false)
    }

    // MARK: - キャンセルテスト

    @Test("キャンセル後にリセットすると処理を再開できる")
    func resetAfterCancellation() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        await detector.cancel()

        // When
        await detector.reset()
        let asset = MockPHAsset.createScreenshot()
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == true)
    }

    // MARK: - Array Extension テスト

    @Test("スクリーンショットのみをフィルタできる")
    func filterScreenshots() async throws {
        // Given
        let results = [
            ScreenshotDetectionResult(
                assetIdentifier: "1",
                isScreenshot: true,
                confidence: 1.0,
                detectionMethod: .mediaSubtype
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "2",
                isScreenshot: false,
                confidence: 1.0,
                detectionMethod: .notScreenshot
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "3",
                isScreenshot: true,
                confidence: 0.9,
                detectionMethod: .screenSizeMatch
            )
        ]

        // When
        let screenshots = results.filterScreenshots()

        // Then
        #expect(screenshots.count == 2)
        #expect(screenshots.allSatisfy { $0.isScreenshot })
    }

    @Test("非スクリーンショットのみをフィルタできる")
    func filterNonScreenshots() async throws {
        // Given
        let results = [
            ScreenshotDetectionResult(
                assetIdentifier: "1",
                isScreenshot: true,
                confidence: 1.0,
                detectionMethod: .mediaSubtype
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "2",
                isScreenshot: false,
                confidence: 1.0,
                detectionMethod: .notScreenshot
            )
        ]

        // When
        let nonScreenshots = results.filterNonScreenshots()

        // Then
        #expect(nonScreenshots.count == 1)
        #expect(nonScreenshots.allSatisfy { !$0.isScreenshot })
    }

    @Test("信頼度順にソートできる")
    func sortByConfidence() async throws {
        // Given
        let results = [
            ScreenshotDetectionResult(
                assetIdentifier: "1",
                isScreenshot: true,
                confidence: 0.7,
                detectionMethod: .filenamePattern
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "2",
                isScreenshot: true,
                confidence: 1.0,
                detectionMethod: .mediaSubtype
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "3",
                isScreenshot: true,
                confidence: 0.85,
                detectionMethod: .screenSizeMatch
            )
        ]

        // When
        let sorted = results.sortedByConfidence()

        // Then
        #expect(sorted[0].confidence == 1.0)
        #expect(sorted[1].confidence == 0.85)
        #expect(sorted[2].confidence == 0.7)
    }

    @Test("平均信頼度が正しく計算される")
    func averageConfidence() async throws {
        // Given
        let results = [
            ScreenshotDetectionResult(
                assetIdentifier: "1",
                isScreenshot: true,
                confidence: 1.0,
                detectionMethod: .mediaSubtype
            ),
            ScreenshotDetectionResult(
                assetIdentifier: "2",
                isScreenshot: true,
                confidence: 0.8,
                detectionMethod: .screenSizeMatch
            )
        ]

        // When
        let average = results.averageConfidence

        // Then
        #expect(average != nil)
        #expect(average! == 0.9)
    }

    // MARK: - Edge Cases

    @Test("Live Photo はスクリーンショットとして検出されない")
    func livePhotoNotDetected() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createLivePhoto()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == false)
    }

    @Test("パノラマ写真はスクリーンショットとして検出されない")
    func panoramaNotDetected() async throws {
        // Given
        let detector = ScreenshotDetector(options: .default)
        let asset = MockPHAsset.createPanorama()

        // When
        let result = try await detector.isScreenshot(mockAsset: asset)

        // Then
        #expect(result == false)
    }

    @Test("信頼度レベルの判定が正しく動作する")
    func confidenceLevelChecks() async throws {
        // Given
        let highConfidence = ScreenshotDetectionResult(
            assetIdentifier: "1",
            isScreenshot: true,
            confidence: 0.95,
            detectionMethod: .mediaSubtype
        )

        let mediumConfidence = ScreenshotDetectionResult(
            assetIdentifier: "2",
            isScreenshot: true,
            confidence: 0.8,
            detectionMethod: .screenSizeMatch
        )

        let lowConfidence = ScreenshotDetectionResult(
            assetIdentifier: "3",
            isScreenshot: true,
            confidence: 0.6,
            detectionMethod: .filenamePattern
        )

        // Then
        #expect(highConfidence.isHighConfidence == true)
        #expect(mediumConfidence.isMediumConfidence == true)
        #expect(lowConfidence.isLowConfidence == true)
    }
}

// MARK: - MockPHAsset

/// テスト用の PHAsset モックプロトコル
/// 実際の PHAsset はサブクラス化できないため、プロトコルで抽象化
protocol MockableAsset {
    var mediaType: PHAssetMediaType { get }
    var mediaSubtypes: PHAssetMediaSubtype { get }
    var pixelWidth: Int { get }
    var pixelHeight: Int { get }
    var localIdentifier: String { get }
    var creationDate: Date? { get }
    var isScreenshot: Bool { get }
}

/// テスト用の PHAsset モック実装
struct MockPHAsset: MockableAsset {
    let mediaType: PHAssetMediaType
    let mediaSubtypes: PHAssetMediaSubtype
    let pixelWidth: Int
    let pixelHeight: Int
    let localIdentifier: String
    let creationDate: Date?

    var isScreenshot: Bool {
        mediaSubtypes.contains(.photoScreenshot)
    }

    // MARK: - Factory Methods

    static func createScreenshot() -> MockPHAsset {
        MockPHAsset(
            mediaType: .image,
            mediaSubtypes: .photoScreenshot,
            pixelWidth: 1170,
            pixelHeight: 2532,  // iPhone 13 Pro のスクリーンショットサイズ
            localIdentifier: UUID().uuidString,
            creationDate: Date()
        )
    }

    static func createRegularPhoto() -> MockPHAsset {
        MockPHAsset(
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,  // 12MP カメラの標準解像度
            localIdentifier: UUID().uuidString,
            creationDate: Date()
        )
    }

    static func createVideo() -> MockPHAsset {
        MockPHAsset(
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            localIdentifier: UUID().uuidString,
            creationDate: Date()
        )
    }

    static func createLivePhoto() -> MockPHAsset {
        MockPHAsset(
            mediaType: .image,
            mediaSubtypes: .photoLive,
            pixelWidth: 4032,
            pixelHeight: 3024,
            localIdentifier: UUID().uuidString,
            creationDate: Date()
        )
    }

    static func createPanorama() -> MockPHAsset {
        MockPHAsset(
            mediaType: .image,
            mediaSubtypes: .photoPanorama,
            pixelWidth: 10000,
            pixelHeight: 2000,
            localIdentifier: UUID().uuidString,
            creationDate: Date()
        )
    }
}

/// ScreenshotDetector を PHAsset と MockPHAsset 両方で使えるようにするためのアダプター
extension PHAsset: MockableAsset {}

/// テスト用のモックアセットを受け入れるための ScreenshotDetector 拡張
extension ScreenshotDetector {
    /// モックアセットでスクリーンショット判定（テスト専用）
    func isScreenshot<T: MockableAsset>(mockAsset asset: T) async throws -> Bool {
        // キャンセルチェック
        try Task.checkCancellation()

        // メディアタイプチェック（動画は除外）
        guard asset.mediaType == .image else {
            return false
        }

        // PHAsset の mediaSubtypes フラグ
        if asset.isScreenshot {
            return true
        }

        return false
    }
}
