//
//  BUG002_Phase2_E2EIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BUG-002 Phase 2: スキャン設定→グルーピング E2E統合テスト・バリデーション
//
//  テスト対象:
//  - ScanSettings→PhotoFilteringService→グルーピングの完全フロー
//  - フィルタリング設定の動的変更と反映
//  - データ整合性の検証
//
//  Created by AI Assistant on 2025-12-24.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - BUG002_Phase2_E2EIntegrationTests

/// BUG-002 Phase 2: スキャン設定→グルーピング E2E統合テストスイート
@Suite("BUG-002 Phase 2: スキャン設定→グルーピング E2E統合テスト")
struct BUG002_Phase2_E2EIntegrationTests {

    // MARK: - Test Fixtures

    /// テスト用の写真を作成（通常の画像）
    private func createNormalPhoto(id: String, creationDate: Date = Date()) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: creationDate,
            modificationDate: creationDate,
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 2_000_000,
            isFavorite: false
        )
    }

    /// テスト用の写真を作成（動画）
    private func createVideoPhoto(id: String, creationDate: Date = Date()) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: creationDate,
            modificationDate: creationDate,
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 60.0,
            fileSize: 50_000_000,
            isFavorite: false
        )
    }

    /// テスト用の写真を作成（スクリーンショット）
    private func createScreenshotPhoto(id: String, creationDate: Date = Date()) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: creationDate,
            modificationDate: creationDate,
            mediaType: .image,
            mediaSubtypes: .screenshot,
            pixelWidth: 1170,
            pixelHeight: 2532,
            duration: 0,
            fileSize: 500_000,
            isFavorite: false
        )
    }

    /// テスト用PhotoAnalysisResultを生成
    private func createMockAnalysisResult(
        photoId: String,
        isSelfie: Bool = false,
        isScreenshot: Bool = false
    ) -> PhotoAnalysisResult {
        let builder = PhotoAnalysisResult.Builder(photoId: photoId)
        builder.setIsSelfie(isSelfie)
        builder.setIsScreenshot(isScreenshot)
        builder.setQualityScore(0.8)
        return builder.build()
    }

    // MARK: - Test 1: 正常系 - 完全E2Eフロー

    @Test("E2E: ScanSettings→PhotoFilteringService→フィルタリング完全フロー")
    func testCompleteE2EFlow() {
        // Arrange: 多様な写真のセット
        let photos = [
            createNormalPhoto(id: "photo1"),
            createNormalPhoto(id: "photo2"),
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createScreenshotPhoto(id: "screenshot1"),
            createScreenshotPhoto(id: "screenshot2")
        ]

        let filteringService = PhotoFilteringService()

        // Act 1: デフォルト設定（すべて含む）でフィルタリング
        let defaultSettings = ScanSettings.default
        let result1 = filteringService.filter(photos: photos, with: defaultSettings)

        // Assert 1: すべての写真が含まれる
        #expect(result1.count == 6)

        // Act 2: 動画を除外してフィルタリング
        var noVideoSettings = ScanSettings.default
        noVideoSettings.includeVideos = false
        let result2 = filteringService.filter(photos: photos, with: noVideoSettings)

        // Assert 2: 動画が除外される
        #expect(result2.count == 4)
        #expect(!result2.contains { $0.isVideo })

        // Act 3: スクリーンショットも除外
        var noVideoNoScreenshotSettings = noVideoSettings
        noVideoNoScreenshotSettings.includeScreenshots = false
        let result3 = filteringService.filter(photos: photos, with: noVideoNoScreenshotSettings)

        // Assert 3: 動画とスクリーンショットが除外
        #expect(result3.count == 2)
        #expect(result3.allSatisfy { !$0.isVideo && !$0.isScreenshot })
    }

    @Test("E2E: 分析結果付きフィルタリング（セルフィー判定含む）")
    func testE2EFlowWithAnalysisResults() {
        // Arrange
        let photos = [
            createNormalPhoto(id: "photo1"),
            createNormalPhoto(id: "selfie1"),
            createNormalPhoto(id: "selfie2"),
            createVideoPhoto(id: "video1"),
            createScreenshotPhoto(id: "screenshot1")
        ]

        let analysisResults: [PhotoAnalysisResult] = [
            createMockAnalysisResult(photoId: "photo1", isSelfie: false),
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true),
            createMockAnalysisResult(photoId: "selfie2", isSelfie: true),
            createMockAnalysisResult(photoId: "video1", isSelfie: false),
            createMockAnalysisResult(photoId: "screenshot1", isSelfie: false, isScreenshot: true)
        ]

        let photosWithResults = photos.map { photo -> (photo: Photo, result: PhotoAnalysisResult?) in
            let result = analysisResults.first { $0.photoId == photo.localIdentifier }
            return (photo, result)
        }

        let filteringService = PhotoFilteringService()

        // Act: セルフィーを除外してフィルタリング
        var noSelfieSettings = ScanSettings.default
        noSelfieSettings.includeSelfies = false

        let filtered = filteringService.filterWithAnalysisResults(
            photosWithResults: photosWithResults,
            with: noSelfieSettings
        )

        // Assert: セルフィーが除外される
        #expect(filtered.count == 3) // photo1, video1, screenshot1
        #expect(!filtered.contains { $0.result?.isSelfie == true })
    }

    // MARK: - Test 2: 正常系 - 統計情報付きフィルタリング

    @Test("E2E: filterWithStatsで正確な統計が返される")
    func testFilterWithStatsReturnsAccurateStats() {
        // Arrange
        let photos = [
            createNormalPhoto(id: "photo1"),
            createNormalPhoto(id: "photo2"),
            createNormalPhoto(id: "photo3"),
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createScreenshotPhoto(id: "screenshot1")
        ]

        let filteringService = PhotoFilteringService()

        // Act: 動画とスクリーンショットを除外
        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false

        let result = filteringService.filterWithStats(photos: photos, with: settings)

        // Assert: 統計情報が正確
        #expect(result.originalCount == 6)
        #expect(result.filteredCount == 3)
        #expect(result.excludedVideoCount == 2)
        #expect(result.excludedScreenshotCount == 1)
        #expect(result.totalExcludedCount == 3)
        #expect(result.filteringRate == 0.5) // 3/6 = 50%
    }

    @Test("E2E: filterWithStatsのフォーマット済みフィルタリング率")
    func testFilterWithStatsFormattedRate() {
        // Arrange
        let photos = [
            createNormalPhoto(id: "photo1"),
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createVideoPhoto(id: "video3")
        ]

        let filteringService = PhotoFilteringService()

        // Act
        var settings = ScanSettings.default
        settings.includeVideos = false

        let result = filteringService.filterWithStats(photos: photos, with: settings)

        // Assert
        #expect(result.formattedFilteringRate == "25.0%") // 1/4 = 25%
    }

    // MARK: - Test 3: 異常系 - エッジケース

    @Test("E2E: 空の写真配列でも正常動作")
    func testE2EWithEmptyPhotoArray() {
        // Arrange
        let photos: [Photo] = []
        let filteringService = PhotoFilteringService()
        let settings = ScanSettings.default

        // Act
        let result = filteringService.filter(photos: photos, with: settings)
        let statsResult = filteringService.filterWithStats(photos: photos, with: settings)

        // Assert
        #expect(result.isEmpty)
        #expect(statsResult.filteredPhotos.isEmpty)
        #expect(statsResult.originalCount == 0)
        #expect(statsResult.filteringRate == 0.0) // ゼロ除算回避
    }

    @Test("E2E: すべて除外された場合の統計")
    func testE2EWithAllPhotosExcluded() {
        // Arrange: 動画のみ
        let photos = [
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createVideoPhoto(id: "video3")
        ]

        let filteringService = PhotoFilteringService()

        // Act: 動画を除外
        var settings = ScanSettings.default
        settings.includeVideos = false

        let result = filteringService.filterWithStats(photos: photos, with: settings)

        // Assert
        #expect(result.filteredPhotos.isEmpty)
        #expect(result.originalCount == 3)
        #expect(result.excludedVideoCount == 3)
        #expect(result.filteringRate == 0.0)
    }

    @Test("E2E: 分析結果が一部欠落している場合")
    func testE2EWithPartialAnalysisResults() {
        // Arrange: 一部の写真のみ分析済み
        let photos = [
            createNormalPhoto(id: "photo1"),
            createNormalPhoto(id: "photo2"), // 分析結果なし
            createNormalPhoto(id: "selfie1")
        ]

        let analysisResults = [
            createMockAnalysisResult(photoId: "photo1", isSelfie: false),
            // photo2の分析結果なし
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true)
        ]

        let photosWithResults = photos.map { photo -> (photo: Photo, result: PhotoAnalysisResult?) in
            let result = analysisResults.first { $0.photoId == photo.localIdentifier }
            return (photo, result)
        }

        let filteringService = PhotoFilteringService()

        // Act: セルフィー除外
        var settings = ScanSettings.default
        settings.includeSelfies = false

        let filtered = filteringService.filterWithAnalysisResults(
            photosWithResults: photosWithResults,
            with: settings
        )

        // Assert: 分析結果のない写真は除外されない（セルフィーではないと判断）
        #expect(filtered.count == 2) // photo1, photo2
        #expect(filtered.contains { $0.photo.id == "photo2" })
    }

    // MARK: - Test 4: 境界値テスト

    @Test("E2E: 大量の写真でもパフォーマンス劣化なし")
    func testE2EWithLargePhotoSet() {
        // Arrange: 1000枚の写真
        var photos: [Photo] = []
        for i in 0..<1000 {
            if i % 3 == 0 {
                photos.append(createVideoPhoto(id: "video-\(i)"))
            } else if i % 3 == 1 {
                photos.append(createScreenshotPhoto(id: "screenshot-\(i)"))
            } else {
                photos.append(createNormalPhoto(id: "photo-\(i)"))
            }
        }

        let filteringService = PhotoFilteringService()

        // Act: フィルタリング（パフォーマンス計測）
        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false

        let startTime = Date()
        let result = filteringService.filter(photos: photos, with: settings)
        let elapsed = Date().timeIntervalSince(startTime)

        // Assert: 1秒以内に完了
        #expect(elapsed < 1.0, "フィルタリングに\(elapsed)秒かかりました（1秒以内であるべき）")

        // 通常の写真のみが残る（約334枚）
        #expect(result.count < photos.count)
        #expect(result.allSatisfy { !$0.isVideo && !$0.isScreenshot })
    }

    @Test("E2E: 同一タイプの写真のみの配列")
    func testE2EWithSingleTypePhotos() {
        // Arrange: スクリーンショットのみ
        let photos = (0..<10).map { createScreenshotPhoto(id: "screenshot-\($0)") }
        let filteringService = PhotoFilteringService()

        // Act 1: スクリーンショット含む
        let result1 = filteringService.filter(photos: photos, with: .default)

        // Assert 1: すべて含まれる
        #expect(result1.count == 10)

        // Act 2: スクリーンショット除外
        var noScreenshotSettings = ScanSettings.default
        noScreenshotSettings.includeScreenshots = false
        let result2 = filteringService.filter(photos: photos, with: noScreenshotSettings)

        // Assert 2: すべて除外
        #expect(result2.isEmpty)
    }
}

// MARK: - BUG002_Phase2_ValidationTests

/// BUG-002 Phase 2: バリデーションテストスイート
@Suite("BUG-002 Phase 2: バリデーションテスト")
struct BUG002_Phase2_ValidationTests {

    // MARK: - Test 1: PhotoFilteringResult バリデーション

    @Test("バリデーション: PhotoFilteringResultの計算プロパティ")
    func testPhotoFilteringResultComputedProperties() {
        // Arrange
        let photo = Photo(
            id: "test",
            localIdentifier: "test",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 1000,
            isFavorite: false
        )

        let result = PhotoFilteringResult(
            filteredPhotos: [photo],
            originalCount: 10,
            excludedVideoCount: 3,
            excludedScreenshotCount: 4,
            excludedSelfieCount: 2
        )

        // Assert
        #expect(result.filteredCount == 1)
        #expect(result.totalExcludedCount == 9)
        #expect(result.filteringRate == 0.1) // 1/10
        #expect(result.formattedFilteringRate == "10.0%")
    }

    @Test("バリデーション: PhotoFilteringResultのEquatable")
    func testPhotoFilteringResultEquatable() {
        // Arrange
        let photo1 = Photo(
            id: "test1",
            localIdentifier: "test1",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 1000,
            isFavorite: false
        )

        let result1 = PhotoFilteringResult(
            filteredPhotos: [photo1],
            originalCount: 5,
            excludedVideoCount: 2
        )

        let result2 = PhotoFilteringResult(
            filteredPhotos: [photo1],
            originalCount: 5,
            excludedVideoCount: 2
        )

        let result3 = PhotoFilteringResult(
            filteredPhotos: [photo1],
            originalCount: 5,
            excludedVideoCount: 3 // 異なる
        )

        // Assert
        #expect(result1 == result2)
        #expect(result1 != result3)
    }

    @Test("バリデーション: PhotoFilteringResultのdescription")
    func testPhotoFilteringResultDescription() {
        // Arrange
        let result = PhotoFilteringResult(
            filteredPhotos: [],
            originalCount: 100,
            excludedVideoCount: 20,
            excludedScreenshotCount: 15,
            excludedSelfieCount: 10
        )

        // Act
        let description = result.description

        // Assert
        #expect(description.contains("0/100"))
        #expect(description.contains("videos=20"))
        #expect(description.contains("screenshots=15"))
        #expect(description.contains("selfies=10"))
    }

    // MARK: - Test 2: ScanSettings データ整合性

    @Test("バリデーション: ScanSettings.defaultの値が正しい")
    func testScanSettingsDefaultValues() {
        // Arrange & Act
        let settings = ScanSettings.default

        // Assert
        #expect(settings.autoScanEnabled == false)
        #expect(settings.autoScanInterval == .weekly)
        #expect(settings.includeVideos == true)
        #expect(settings.includeScreenshots == true)
        #expect(settings.includeSelfies == true)
        #expect(settings.hasAnyContentTypeEnabled == true)
    }

    @Test("バリデーション: ScanSettingsのCodable")
    func testScanSettingsCodable() throws {
        // Arrange
        let original = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .daily,
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: false
        )

        // Act: エンコード→デコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScanSettings.self, from: data)

        // Assert
        #expect(decoded == original)
    }

    // MARK: - Test 3: PhotoFilteringService Sendable

    @Test("バリデーション: PhotoFilteringServiceがSendable")
    func testPhotoFilteringServiceIsSendable() async {
        // Arrange
        let filteringService = PhotoFilteringService()
        let photos = [
            Photo(
                id: "test",
                localIdentifier: "test",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 0,
                fileSize: 1000,
                isFavorite: false
            )
        ]
        let settings = ScanSettings.default

        // Act: 複数のタスクから同時にアクセス
        await withTaskGroup(of: [Photo].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    // Sendableなので複数タスクからアクセス可能
                    filteringService.filter(photos: photos, with: settings)
                }
            }

            var results: [[Photo]] = []
            for await result in group {
                results.append(result)
            }

            // Assert: すべての結果が同じ
            #expect(results.count == 10)
            #expect(results.allSatisfy { $0.count == 1 })
        }
    }
}

// MARK: - BUG002_Phase2_DataIntegrityTests

/// BUG-002 Phase 2: データ整合性テストスイート
@Suite("BUG-002 Phase 2: データ整合性テスト")
struct BUG002_Phase2_DataIntegrityTests {

    // MARK: - Test 1: フィルタリング後のデータ整合性

    @Test("データ整合性: フィルタリング後の写真データが破損しない")
    func testFilteredPhotosDataIntegrity() {
        // Arrange
        let originalPhoto = Photo(
            id: "original",
            localIdentifier: "local-id-123",
            creationDate: Date(timeIntervalSince1970: 1000000),
            modificationDate: Date(timeIntervalSince1970: 1000001),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 2_500_000,
            isFavorite: true
        )

        let photos = [originalPhoto]
        let filteringService = PhotoFilteringService()

        // Act
        let filtered = filteringService.filter(photos: photos, with: .default)

        // Assert: フィルタリング後もすべてのプロパティが保持される
        #expect(filtered.count == 1)
        let resultPhoto = filtered.first!

        #expect(resultPhoto.id == "original")
        #expect(resultPhoto.localIdentifier == "local-id-123")
        #expect(resultPhoto.creationDate == Date(timeIntervalSince1970: 1000000))
        #expect(resultPhoto.modificationDate == Date(timeIntervalSince1970: 1000001))
        #expect(resultPhoto.mediaType == .image)
        #expect(resultPhoto.pixelWidth == 4032)
        #expect(resultPhoto.pixelHeight == 3024)
        #expect(resultPhoto.fileSize == 2_500_000)
        #expect(resultPhoto.isFavorite == true)
    }

    @Test("データ整合性: 元の配列が変更されない")
    func testOriginalArrayUnmodified() {
        // Arrange
        let photos = [
            Photo(
                id: "photo1",
                localIdentifier: "photo1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 0,
                fileSize: 1000,
                isFavorite: false
            ),
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 60,
                fileSize: 50000,
                isFavorite: false
            )
        ]

        let originalCount = photos.count
        let filteringService = PhotoFilteringService()

        // Act
        var settings = ScanSettings.default
        settings.includeVideos = false
        _ = filteringService.filter(photos: photos, with: settings)

        // Assert: 元の配列は変更されない
        #expect(photos.count == originalCount)
        #expect(photos.count == 2)
    }

    // MARK: - Test 2: 設定変更の分離

    @Test("データ整合性: 設定変更が他のインスタンスに影響しない")
    func testSettingsChangeIsolation() {
        // Arrange
        var settings1 = ScanSettings.default
        var settings2 = ScanSettings.default

        // Act: settings1を変更
        settings1.includeVideos = false
        settings1.includeScreenshots = false

        // Assert: settings2は変更されない
        #expect(settings1.includeVideos == false)
        #expect(settings1.includeScreenshots == false)
        #expect(settings2.includeVideos == true) // デフォルト値のまま
        #expect(settings2.includeScreenshots == true)
    }

    @Test("データ整合性: PhotoFilteringServiceはステートレス")
    func testPhotoFilteringServiceStateless() {
        // Arrange
        let filteringService = PhotoFilteringService()
        let photos = [
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 60,
                fileSize: 50000,
                isFavorite: false
            )
        ]

        // Act 1: 動画除外でフィルタリング
        var settings1 = ScanSettings.default
        settings1.includeVideos = false
        let result1 = filteringService.filter(photos: photos, with: settings1)

        // Act 2: デフォルト設定で再フィルタリング（動画含む）
        let result2 = filteringService.filter(photos: photos, with: .default)

        // Assert: 前回の呼び出しの影響を受けない
        #expect(result1.isEmpty) // 動画除外
        #expect(result2.count == 1) // 動画含む
    }
}
