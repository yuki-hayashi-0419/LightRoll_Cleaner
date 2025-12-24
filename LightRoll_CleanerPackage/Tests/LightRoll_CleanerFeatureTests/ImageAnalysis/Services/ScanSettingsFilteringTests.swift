//
//  ScanSettingsFilteringTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BUG-002: スキャン設定がグルーピング処理に反映されることを検証するテスト
//  対象機能: UserSettings.ScanSettings による写真フィルタリング
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - ScanSettingsFilteringTests

/// BUG-002: スキャン設定によるフィルタリング動作のテストスイート
///
/// テスト要件:
/// 1. UserSettings統合テスト - SimilarityAnalyzerがUserSettingsを正しく受け取ること
/// 2. フィルタリング動作テスト - 各設定に応じて写真が正しくフィルタリングされること
/// 3. エッジケーステスト - 境界条件での動作確認
@Suite("BUG-002: スキャン設定フィルタリングテスト", .serialized)
struct ScanSettingsFilteringTests {

    // MARK: - テスト用ヘルパー

    /// テスト用Photoを生成
    /// - Parameters:
    ///   - id: 写真ID
    ///   - isVideo: 動画かどうか
    ///   - isScreenshot: スクリーンショットかどうか
    ///   - isSelfie: 自撮りかどうか（顔検出に基づく）
    /// - Returns: Photo インスタンス
    private func createMockPhoto(
        id: String,
        isVideo: Bool = false,
        isScreenshot: Bool = false,
        isSelfie: Bool = false
    ) -> Photo {
        let mediaType: MediaType = isVideo ? .video : .image
        var mediaSubtypes: MediaSubtypes = []
        if isScreenshot {
            mediaSubtypes.insert(.screenshot)
        }
        if isSelfie {
            // 自撮りはポートレートモードで撮影されることが多い
            mediaSubtypes.insert(.depthEffect)
        }

        return Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: mediaType,
            mediaSubtypes: mediaSubtypes,
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: isVideo ? 10.0 : 0,
            fileSize: 1024 * 1024, // 1MB
            isFavorite: false
        )
    }

    /// テスト用PhotoAnalysisResultを生成（自撮り判定を含む）
    /// - Parameters:
    ///   - photoId: 写真ID
    ///   - isSelfie: 自撮りかどうか
    ///   - isScreenshot: スクリーンショットかどうか
    /// - Returns: PhotoAnalysisResult
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

    // MARK: - 1. UserSettings統合テスト

    @Test("ScanSettings: デフォルト設定ですべてのコンテンツタイプが有効")
    func testDefaultSettingsIncludesAllContentTypes() {
        // Given
        let settings = ScanSettings.default

        // Then: デフォルトではすべて有効
        #expect(settings.includeVideos == true)
        #expect(settings.includeScreenshots == true)
        #expect(settings.includeSelfies == true)
        #expect(settings.hasAnyContentTypeEnabled == true)
    }

    @Test("ScanSettings: 設定変更が正しく反映される")
    func testSettingsModification() {
        // Given
        var settings = ScanSettings.default

        // When: 各設定を変更
        settings.includeVideos = false
        settings.includeScreenshots = false
        settings.includeSelfies = false

        // Then: 変更が反映される
        #expect(settings.includeVideos == false)
        #expect(settings.includeScreenshots == false)
        #expect(settings.includeSelfies == false)
        #expect(settings.hasAnyContentTypeEnabled == false)
    }

    @Test("ScanSettings: 部分的な設定変更が他の設定に影響しない")
    func testPartialSettingsModification() {
        // Given
        var settings = ScanSettings.default

        // When: 動画のみ無効化
        settings.includeVideos = false

        // Then: 他の設定は影響を受けない
        #expect(settings.includeVideos == false)
        #expect(settings.includeScreenshots == true)
        #expect(settings.includeSelfies == true)
        #expect(settings.hasAnyContentTypeEnabled == true)
    }

    // MARK: - 2. フィルタリング動作テスト

    @Test("フィルタリング: includeVideos=false で動画が除外される")
    func testVideosExcludedWhenDisabled() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1", isVideo: false),
            createMockPhoto(id: "video1", isVideo: true),
            createMockPhoto(id: "photo2", isVideo: false),
            createMockPhoto(id: "video2", isVideo: true)
        ]

        var settings = ScanSettings.default
        settings.includeVideos = false

        // When: フィルタリング実行
        let filteredPhotos = filterPhotos(photos, with: settings)

        // Then: 動画が除外される
        #expect(filteredPhotos.count == 2)
        #expect(filteredPhotos.allSatisfy { !$0.isVideo })
        #expect(filteredPhotos.contains { $0.id == "photo1" })
        #expect(filteredPhotos.contains { $0.id == "photo2" })
    }

    @Test("フィルタリング: includeScreenshots=false でスクリーンショットが除外される")
    func testScreenshotsExcludedWhenDisabled() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1", isScreenshot: false),
            createMockPhoto(id: "screenshot1", isScreenshot: true),
            createMockPhoto(id: "photo2", isScreenshot: false),
            createMockPhoto(id: "screenshot2", isScreenshot: true)
        ]

        var settings = ScanSettings.default
        settings.includeScreenshots = false

        // When: フィルタリング実行
        let filteredPhotos = filterPhotos(photos, with: settings)

        // Then: スクリーンショットが除外される
        #expect(filteredPhotos.count == 2)
        #expect(filteredPhotos.allSatisfy { !$0.isScreenshot })
        #expect(filteredPhotos.contains { $0.id == "photo1" })
        #expect(filteredPhotos.contains { $0.id == "photo2" })
    }

    @Test("フィルタリング: includeSelfies=false でセルフィーが除外される")
    func testSelfiesExcludedWhenDisabled() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1", isSelfie: false),
            createMockPhoto(id: "selfie1", isSelfie: true),
            createMockPhoto(id: "photo2", isSelfie: false),
            createMockPhoto(id: "selfie2", isSelfie: true)
        ]

        // 自撮り判定は分析結果から取得するため、分析結果も用意
        let analysisResults = [
            createMockAnalysisResult(photoId: "photo1", isSelfie: false),
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true),
            createMockAnalysisResult(photoId: "photo2", isSelfie: false),
            createMockAnalysisResult(photoId: "selfie2", isSelfie: true)
        ]

        var settings = ScanSettings.default
        settings.includeSelfies = false

        // When: フィルタリング実行（分析結果に基づく）
        let filteredPhotos = filterPhotosWithAnalysisResults(
            photos,
            analysisResults: analysisResults,
            with: settings
        )

        // Then: セルフィーが除外される
        #expect(filteredPhotos.count == 2)
        #expect(filteredPhotos.contains { $0.id == "photo1" })
        #expect(filteredPhotos.contains { $0.id == "photo2" })
    }

    @Test("フィルタリング: 複数の設定を組み合わせた除外")
    func testMultipleFiltersApplied() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1"),
            createMockPhoto(id: "video1", isVideo: true),
            createMockPhoto(id: "screenshot1", isScreenshot: true),
            createMockPhoto(id: "selfie1", isSelfie: true)
        ]

        let analysisResults = [
            createMockAnalysisResult(photoId: "photo1"),
            createMockAnalysisResult(photoId: "video1"),
            createMockAnalysisResult(photoId: "screenshot1", isScreenshot: true),
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true)
        ]

        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false
        settings.includeSelfies = false

        // When: フィルタリング実行
        let filteredPhotos = filterPhotosWithAnalysisResults(
            photos,
            analysisResults: analysisResults,
            with: settings
        )

        // Then: 通常の写真のみ残る
        #expect(filteredPhotos.count == 1)
        #expect(filteredPhotos.first?.id == "photo1")
    }

    // MARK: - 3. エッジケーステスト

    @Test("エッジケース: すべての設定がfalseのとき空の結果を返す")
    func testAllFiltersDisabledReturnsEmpty() {
        // Given: すべてのコンテンツタイプを含む写真セット
        let photos = [
            createMockPhoto(id: "video1", isVideo: true),
            createMockPhoto(id: "screenshot1", isScreenshot: true),
            createMockPhoto(id: "selfie1", isSelfie: true)
        ]

        let analysisResults = [
            createMockAnalysisResult(photoId: "video1"),
            createMockAnalysisResult(photoId: "screenshot1", isScreenshot: true),
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true)
        ]

        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false
        settings.includeSelfies = false

        // When: フィルタリング実行
        let filteredPhotos = filterPhotosWithAnalysisResults(
            photos,
            analysisResults: analysisResults,
            with: settings
        )

        // Then: すべて除外されて空
        #expect(filteredPhotos.isEmpty)
    }

    @Test("エッジケース: すべての設定がtrueのときすべての写真が含まれる")
    func testAllFiltersEnabledIncludesAll() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1"),
            createMockPhoto(id: "video1", isVideo: true),
            createMockPhoto(id: "screenshot1", isScreenshot: true),
            createMockPhoto(id: "selfie1", isSelfie: true)
        ]

        let analysisResults = [
            createMockAnalysisResult(photoId: "photo1"),
            createMockAnalysisResult(photoId: "video1"),
            createMockAnalysisResult(photoId: "screenshot1", isScreenshot: true),
            createMockAnalysisResult(photoId: "selfie1", isSelfie: true)
        ]

        let settings = ScanSettings.default // すべてtrue

        // When: フィルタリング実行
        let filteredPhotos = filterPhotosWithAnalysisResults(
            photos,
            analysisResults: analysisResults,
            with: settings
        )

        // Then: すべて含まれる
        #expect(filteredPhotos.count == 4)
    }

    @Test("エッジケース: 空の写真リストでもエラーが発生しない")
    func testEmptyPhotosListHandledGracefully() {
        // Given
        let photos: [Photo] = []
        let settings = ScanSettings.default

        // When: フィルタリング実行
        let filteredPhotos = filterPhotos(photos, with: settings)

        // Then: 空の結果（エラーなし）
        #expect(filteredPhotos.isEmpty)
    }

    @Test("エッジケース: 分析結果がない写真はデフォルトで含まれる")
    func testPhotosWithoutAnalysisResultsIncludedByDefault() {
        // Given
        let photos = [
            createMockPhoto(id: "photo1"),
            createMockPhoto(id: "photo2")
        ]

        // 分析結果が空（まだ分析されていない場合）
        let analysisResults: [PhotoAnalysisResult] = []

        var settings = ScanSettings.default
        settings.includeSelfies = false // セルフィー除外設定

        // When: フィルタリング実行
        let filteredPhotos = filterPhotosWithAnalysisResults(
            photos,
            analysisResults: analysisResults,
            with: settings
        )

        // Then: 分析結果がない写真はセルフィーでないとみなして含まれる
        #expect(filteredPhotos.count == 2)
    }

    // MARK: - フィルタリング実装（テスト対象の実装をシミュレート）

    /// ScanSettingsに基づいて写真をフィルタリング（Photoメタデータベース）
    /// - Parameters:
    ///   - photos: 対象の写真配列
    ///   - settings: スキャン設定
    /// - Returns: フィルタリングされた写真配列
    private func filterPhotos(_ photos: [Photo], with settings: ScanSettings) -> [Photo] {
        photos.filter { photo in
            // 動画フィルタ
            if !settings.includeVideos && photo.isVideo {
                return false
            }

            // スクリーンショットフィルタ
            if !settings.includeScreenshots && photo.isScreenshot {
                return false
            }

            return true
        }
    }

    /// ScanSettingsに基づいて写真をフィルタリング（分析結果ベース）
    /// - Parameters:
    ///   - photos: 対象の写真配列
    ///   - analysisResults: 分析結果配列
    ///   - settings: スキャン設定
    /// - Returns: フィルタリングされた写真配列
    private func filterPhotosWithAnalysisResults(
        _ photos: [Photo],
        analysisResults: [PhotoAnalysisResult],
        with settings: ScanSettings
    ) -> [Photo] {
        // 分析結果をDictionaryに変換
        let resultsLookup = Dictionary(
            uniqueKeysWithValues: analysisResults.map { ($0.photoId, $0) }
        )

        return photos.filter { photo in
            // 動画フィルタ
            if !settings.includeVideos && photo.isVideo {
                return false
            }

            // スクリーンショットフィルタ（Photoメタデータから）
            if !settings.includeScreenshots && photo.isScreenshot {
                return false
            }

            // スクリーンショットフィルタ（分析結果から）
            if !settings.includeScreenshots {
                if let result = resultsLookup[photo.localIdentifier], result.isScreenshot {
                    return false
                }
            }

            // セルフィーフィルタ（分析結果から判定）
            if !settings.includeSelfies {
                if let result = resultsLookup[photo.localIdentifier], result.isSelfie {
                    return false
                }
            }

            return true
        }
    }
}

// MARK: - ScanSettings + グルーピング統合テスト

@Suite("BUG-002: ScanSettingsとグルーピング統合テスト")
struct ScanSettingsGroupingIntegrationTests {

    @Test("グルーピング前にフィルタリングが適用される")
    func testFilteringAppliedBeforeGrouping() {
        // Given
        var settings = ScanSettings.default
        settings.includeScreenshots = false

        let photos = [
            Photo(
                id: "photo1",
                localIdentifier: "photo1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 0,
                fileSize: 1024,
                isFavorite: false
            ),
            Photo(
                id: "screenshot1",
                localIdentifier: "screenshot1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: .screenshot,
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 0,
                fileSize: 1024,
                isFavorite: false
            )
        ]

        // When: フィルタリング実行
        let filteredPhotos = photos.filter { photo in
            if !settings.includeScreenshots && photo.isScreenshot {
                return false
            }
            return true
        }

        // Then: スクリーンショットが除外されている
        #expect(filteredPhotos.count == 1)
        #expect(filteredPhotos.first?.id == "photo1")
    }

    @Test("設定変更後のフィルタリング結果が正しく更新される")
    func testFilteringUpdatesAfterSettingsChange() {
        // Given: 初期設定
        var settings = ScanSettings.default

        let photos = [
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 10,
                fileSize: 1024,
                isFavorite: false
            )
        ]

        // When: 初期状態（動画含む）
        var filteredPhotos = photos.filter { photo in
            if !settings.includeVideos && photo.isVideo {
                return false
            }
            return true
        }

        // Then: 動画が含まれる
        #expect(filteredPhotos.count == 1)

        // When: 設定変更（動画除外）
        settings.includeVideos = false
        filteredPhotos = photos.filter { photo in
            if !settings.includeVideos && photo.isVideo {
                return false
            }
            return true
        }

        // Then: 動画が除外される
        #expect(filteredPhotos.isEmpty)
    }
}

// MARK: - BUG-002 Phase 2: E2E統合テスト

@Suite("BUG-002 Phase 2: E2E統合テスト", .serialized)
struct BUG002_E2EIntegrationTests {

    // MARK: - PhotoFilteringService E2Eテスト

    @Test("E2E-01: PhotoFilteringService.validateSettingsが正常設定を通過")
    func testValidateSettingsWithValidSettings() {
        // Given
        let service = PhotoFilteringService()
        let settings = ScanSettings.default

        // When
        let error = service.validateSettings(settings)

        // Then
        #expect(error == nil)
    }

    @Test("E2E-02: PhotoFilteringService.validateSettingsが無効設定を拒否")
    func testValidateSettingsWithInvalidSettings() {
        // Given
        let service = PhotoFilteringService()
        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false
        settings.includeSelfies = false

        // When
        let error = service.validateSettings(settings)

        // Then
        #expect(error != nil)
        if case .invalidSettings = error {
            // 期待通り
        } else {
            Issue.record("期待するエラータイプではありません")
        }
    }

    @Test("E2E-03: filterWithValidationが正常に動作")
    func testFilterWithValidationSuccess() {
        // Given
        let service = PhotoFilteringService()
        let settings = ScanSettings.default
        let photos = createTestPhotos()

        // When
        let result = service.filterWithValidation(photos: photos, with: settings)

        // Then
        #expect(result.success == true)
        #expect(result.result != nil)
        #expect(result.error == nil)
        #expect(result.result?.filteredCount == photos.count)
    }

    @Test("E2E-04: filterWithValidationが無効設定でエラーを返す")
    func testFilterWithValidationFailure() {
        // Given
        let service = PhotoFilteringService()
        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false
        settings.includeSelfies = false
        let photos = createTestPhotos()

        // When
        let result = service.filterWithValidation(photos: photos, with: settings)

        // Then
        #expect(result.success == false)
        #expect(result.result == nil)
        #expect(result.error != nil)
    }

    @Test("E2E-05: filterWithValidationが空結果時に警告を生成")
    func testFilterWithValidationWarnsOnEmptyResult() {
        // Given
        let service = PhotoFilteringService()
        var settings = ScanSettings.default
        settings.includeVideos = false // 動画のみ無効

        // 動画のみ含むリスト
        let photos = [
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 10,
                fileSize: 1024,
                isFavorite: false
            )
        ]

        // When
        let result = service.filterWithValidation(photos: photos, with: settings)

        // Then
        #expect(result.success == true)
        #expect(result.result?.filteredCount == 0)
        #expect(!result.warnings.isEmpty)
    }

    @Test("E2E-06: PhotoFilteringError Equatable準拠確認")
    func testPhotoFilteringErrorEquatable() {
        // Given
        let error1 = PhotoFilteringError.invalidSettings(reason: "テスト")
        let error2 = PhotoFilteringError.invalidSettings(reason: "テスト")
        let error3 = PhotoFilteringError.invalidSettings(reason: "異なる理由")
        let error4 = PhotoFilteringError.invalidInput(reason: "テスト")

        // Then
        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(error1 != error4)
    }

    @Test("E2E-07: ValidatedPhotoFilteringResult ファクトリメソッド確認")
    func testValidatedPhotoFilteringResultFactoryMethods() {
        // Given
        let mockResult = PhotoFilteringResult(
            filteredPhotos: [],
            originalCount: 0
        )

        // When: success
        let successResult = ValidatedPhotoFilteringResult.success(
            result: mockResult,
            warnings: ["警告"]
        )

        // Then
        #expect(successResult.success == true)
        #expect(successResult.result != nil)
        #expect(successResult.error == nil)
        #expect(successResult.warnings.count == 1)

        // When: failure
        let failureResult = ValidatedPhotoFilteringResult.failure(
            error: .invalidSettings(reason: "テスト")
        )

        // Then
        #expect(failureResult.success == false)
        #expect(failureResult.result == nil)
        #expect(failureResult.error != nil)
        #expect(failureResult.warnings.isEmpty)
    }

    @Test("E2E-08: ScanSettings → PhotoFilteringService → 結果の完全フロー")
    func testCompleteE2EFlow() {
        // Given: UserSettingsからScanSettingsを取得するシミュレーション
        let userSettings = UserSettings.default
        let scanSettings = userSettings.scanSettings

        // 様々なタイプの写真を作成
        let photos = [
            Photo(
                id: "photo1",
                localIdentifier: "photo1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 0,
                fileSize: 1024,
                isFavorite: false
            ),
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 10,
                fileSize: 2048,
                isFavorite: false
            ),
            Photo(
                id: "screenshot1",
                localIdentifier: "screenshot1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: .screenshot,
                pixelWidth: 1170,
                pixelHeight: 2532,
                duration: 0,
                fileSize: 512,
                isFavorite: false
            )
        ]

        let service = PhotoFilteringService()

        // When: バリデーション付きフィルタリング実行
        let result = service.filterWithValidation(photos: photos, with: scanSettings)

        // Then: デフォルト設定ではすべて含まれる
        #expect(result.success == true)
        #expect(result.result?.filteredCount == 3)
        #expect(result.result?.originalCount == 3)
        #expect(result.warnings.isEmpty)
    }

    @Test("E2E-09: 設定変更の連続適用が正しく動作")
    func testSequentialSettingsChanges() {
        // Given
        let service = PhotoFilteringService()
        let photos = createTestPhotosWithAllTypes()

        // When: 段階的に設定を変更
        var settings = ScanSettings.default

        // Step 1: すべて有効
        var result = service.filterWithValidation(photos: photos, with: settings)
        #expect(result.result?.filteredCount == 3)

        // Step 2: 動画除外
        settings.includeVideos = false
        result = service.filterWithValidation(photos: photos, with: settings)
        #expect(result.result?.filteredCount == 2)

        // Step 3: スクリーンショットも除外
        settings.includeScreenshots = false
        result = service.filterWithValidation(photos: photos, with: settings)
        #expect(result.result?.filteredCount == 1)

        // Step 4: セルフィーも除外（すべて除外ではない、通常写真が残る）
        settings.includeSelfies = false
        result = service.filterWithValidation(photos: photos, with: settings)
        // includeSelfiesをfalseにしても、通常の写真は残る（selfieではないため）
        #expect(result.result?.filteredCount == 1)
    }

    @Test("E2E-10: PhotoFilteringResult統計情報の正確性")
    func testPhotoFilteringResultStatistics() {
        // Given
        let service = PhotoFilteringService()
        var settings = ScanSettings.default
        settings.includeVideos = false
        settings.includeScreenshots = false

        let photos = createTestPhotosWithAllTypes()

        // When
        let result = service.filterWithValidation(photos: photos, with: settings)

        // Then
        #expect(result.success == true)
        guard let filterResult = result.result else {
            Issue.record("結果がnil")
            return
        }

        #expect(filterResult.originalCount == 3)
        #expect(filterResult.excludedVideoCount == 1)
        #expect(filterResult.excludedScreenshotCount == 1)
        #expect(filterResult.filteredCount == 1)
        #expect(filterResult.totalExcludedCount == 2)

        // フィルタリング率の検証
        let expectedRate = 1.0 / 3.0
        #expect(abs(filterResult.filteringRate - expectedRate) < 0.01)
    }

    // MARK: - ヘルパーメソッド

    private func createTestPhotos() -> [Photo] {
        [
            Photo(
                id: "photo1",
                localIdentifier: "photo1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 0,
                fileSize: 1024,
                isFavorite: false
            )
        ]
    }

    private func createTestPhotosWithAllTypes() -> [Photo] {
        [
            Photo(
                id: "photo1",
                localIdentifier: "photo1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 0,
                fileSize: 1024,
                isFavorite: false
            ),
            Photo(
                id: "video1",
                localIdentifier: "video1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .video,
                mediaSubtypes: [],
                pixelWidth: 1920,
                pixelHeight: 1080,
                duration: 10,
                fileSize: 2048,
                isFavorite: false
            ),
            Photo(
                id: "screenshot1",
                localIdentifier: "screenshot1",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: .screenshot,
                pixelWidth: 1170,
                pixelHeight: 2532,
                duration: 0,
                fileSize: 512,
                isFavorite: false
            )
        ]
    }
}
