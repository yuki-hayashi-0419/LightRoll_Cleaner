//
//  PhotoRepositoryTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoRepository のユニットテスト
//  モックを使用したテストで Photos Framework に依存しない
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature
import Photos

// MARK: - PhotoRepositoryTests

@Suite("PhotoRepository Tests")
struct PhotoRepositoryTests {

    // MARK: - Error Tests

    @Suite("PhotoRepositoryError Tests")
    struct ErrorTests {

        @Test("エラーの等価性が正しく判定される")
        func testErrorEquality() {
            // 同じエラーは等しい
            #expect(PhotoRepositoryError.photoAccessDenied == PhotoRepositoryError.photoAccessDenied)
            #expect(PhotoRepositoryError.assetNotFound == PhotoRepositoryError.assetNotFound)
            #expect(PhotoRepositoryError.thumbnailGenerationFailed == PhotoRepositoryError.thumbnailGenerationFailed)
            #expect(PhotoRepositoryError.storageInfoUnavailable == PhotoRepositoryError.storageInfoUnavailable)
            #expect(PhotoRepositoryError.fetchCancelled == PhotoRepositoryError.fetchCancelled)

            // 異なるエラーは等しくない
            #expect(PhotoRepositoryError.photoAccessDenied != PhotoRepositoryError.assetNotFound)
            #expect(PhotoRepositoryError.thumbnailGenerationFailed != PhotoRepositoryError.storageInfoUnavailable)

            // unknown エラーの比較
            #expect(PhotoRepositoryError.unknown("test") == PhotoRepositoryError.unknown("test"))
            #expect(PhotoRepositoryError.unknown("test1") != PhotoRepositoryError.unknown("test2"))
        }

        @Test("エラーのローカライズされた説明が存在する")
        func testErrorLocalizedDescription() {
            // 各エラーにローカライズされた説明がある
            #expect(!PhotoRepositoryError.photoAccessDenied.localizedDescription.isEmpty)
            #expect(!PhotoRepositoryError.assetNotFound.localizedDescription.isEmpty)
            #expect(!PhotoRepositoryError.thumbnailGenerationFailed.localizedDescription.isEmpty)
            #expect(!PhotoRepositoryError.storageInfoUnavailable.localizedDescription.isEmpty)
            #expect(!PhotoRepositoryError.fetchCancelled.localizedDescription.isEmpty)
            #expect(!PhotoRepositoryError.unknown("test").localizedDescription.isEmpty)

            // unknown エラーにはメッセージが含まれる
            let unknownError = PhotoRepositoryError.unknown("custom message")
            #expect(unknownError.localizedDescription.contains("custom message"))
        }
    }

    // MARK: - FetchOptions Tests

    @Suite("PhotoFetchOptions Tests")
    struct FetchOptionsTests {

        @Test("デフォルトオプションが正しく設定される")
        func testDefaultOptions() {
            let options = PhotoFetchOptions.default

            #expect(options.sortOrder == .creationDateDescending)
            #expect(options.mediaTypeFilter == .all)
            #expect(options.includeFileSize == false)
            #expect(options.limit == nil)
        }

        @Test("カスタムオプションが正しく設定される")
        func testCustomOptions() {
            let options = PhotoFetchOptions(
                sortOrder: .modificationDateAscending,
                mediaTypeFilter: .images,
                includeFileSize: true,
                limit: 100
            )

            #expect(options.sortOrder == .modificationDateAscending)
            #expect(options.mediaTypeFilter == .images)
            #expect(options.includeFileSize == true)
            #expect(options.limit == 100)
        }

        @Test("PHFetchOptionsへの変換が正しく行われる")
        func testToPHFetchOptions() {
            // creationDate descending
            let options1 = PhotoFetchOptions(sortOrder: .creationDateDescending, limit: 50)
            let phOptions1 = options1.toPHFetchOptions()
            #expect(phOptions1.sortDescriptors?.first?.key == "creationDate")
            #expect(phOptions1.sortDescriptors?.first?.ascending == false)
            #expect(phOptions1.fetchLimit == 50)

            // creationDate ascending
            let options2 = PhotoFetchOptions(sortOrder: .creationDateAscending)
            let phOptions2 = options2.toPHFetchOptions()
            #expect(phOptions2.sortDescriptors?.first?.ascending == true)

            // modificationDate descending
            let options3 = PhotoFetchOptions(sortOrder: .modificationDateDescending)
            let phOptions3 = options3.toPHFetchOptions()
            #expect(phOptions3.sortDescriptors?.first?.key == "modificationDate")
            #expect(phOptions3.sortDescriptors?.first?.ascending == false)

            // modificationDate ascending
            let options4 = PhotoFetchOptions(sortOrder: .modificationDateAscending)
            let phOptions4 = options4.toPHFetchOptions()
            #expect(phOptions4.sortDescriptors?.first?.key == "modificationDate")
            #expect(phOptions4.sortDescriptors?.first?.ascending == true)

            // 制限なし
            let options5 = PhotoFetchOptions(limit: nil)
            let phOptions5 = options5.toPHFetchOptions()
            #expect(phOptions5.fetchLimit == 0)
        }
    }

    // MARK: - PhotoRepository Integration Tests

    @Suite("PhotoRepository Integration Tests")
    @MainActor
    struct IntegrationTests {

        @Test("PhotoRepositoryの初期化")
        func testInitialization() async {
            // モック権限マネージャーを使用
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            #expect(repository.isLoading == false)
            #expect(repository.lastError == nil)
        }

        @Test("権限拒否時のエラー")
        func testAccessDeniedError() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchAllPhotoModels()
            }
        }

        @Test("権限未決定時のエラー")
        func testNotDeterminedError() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .notDetermined
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchAllPhotoModels()
            }
        }

        @Test("権限制限時のエラー")
        func testRestrictedError() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .restricted
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchAllPhotoModels()
            }
        }

        @Test("フェッチオプションの変更")
        func testFetchOptionsChange() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(
                permissionManager: mockPermission,
                fetchOptions: .default
            )

            // オプションを変更
            repository.fetchOptions = PhotoFetchOptions(
                sortOrder: .modificationDateAscending,
                mediaTypeFilter: .videos,
                includeFileSize: true,
                limit: 10
            )

            #expect(repository.fetchOptions.sortOrder == .modificationDateAscending)
            #expect(repository.fetchOptions.mediaTypeFilter == .videos)
            #expect(repository.fetchOptions.includeFileSize == true)
            #expect(repository.fetchOptions.limit == 10)
        }

        @Test("PHAsset取得メソッドが空IDで空配列を返す")
        func testFetchPHAssetsWithEmptyIds() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            let assets = repository.fetchPHAssets(by: [])

            #expect(assets.isEmpty)
        }

        @Test("存在しないIDでPHAssetがnilを返す")
        func testFetchPHAssetWithInvalidId() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            let asset = repository.fetchPHAsset(by: "non-existent-id")

            #expect(asset == nil)
        }

        @Test("存在しないIDでPhotoModelがnilを返す")
        func testFetchPhotoModelWithInvalidId() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            let photo = await repository.fetchPhotoModel(by: "non-existent-id")

            #expect(photo == nil)
        }

        @Test("存在しないIDでPhotoAssetがnilを返す")
        func testFetchPhotoWithInvalidId() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            let photo = await repository.fetchPhoto(by: "non-existent-id")

            #expect(photo == nil)
        }

        @Test("キャッシュ操作がエラーなく実行される")
        func testCachingOperations() async {
            let mockPermission = MockPhotoPermissionManager()
            let repository = PhotoRepository(permissionManager: mockPermission)

            // 空のアセット配列でキャッシュ操作を行ってもエラーにならない
            let size = CGSize(width: 100, height: 100)
            repository.startCachingThumbnails(for: [], size: size)
            repository.stopCachingThumbnails(for: [], size: size)
            repository.stopCachingAllThumbnails()

            // エラーなく完了することを確認
            #expect(true)
        }
    }

    // MARK: - Existing Mock Tests (使用既存のMockPhotoRepository)

    #if DEBUG
    @Suite("Existing MockPhotoRepository Tests")
    struct ExistingMockTests {

        @Test("既存のMockPhotoRepositoryが空配列を返す")
        func testExistingMockEmptyPhotos() async throws {
            let mock = MockPhotoRepository()

            let photos = try await mock.fetchAllPhotos()

            #expect(photos.isEmpty)
            #expect(mock.fetchAllPhotosCalled == true)
        }

        @Test("既存のMockPhotoRepositoryがモックデータを返す")
        func testExistingMockWithData() async throws {
            let mock = MockPhotoRepository()
            mock.mockPhotos = [
                PhotoAsset(id: "test-1", creationDate: Date(), fileSize: 1024),
                PhotoAsset(id: "test-2", creationDate: Date(), fileSize: 2048)
            ]

            let photos = try await mock.fetchAllPhotos()

            #expect(photos.count == 2)
            #expect(photos[0].id == "test-1")
            #expect(photos[1].id == "test-2")
        }

        @Test("既存のMockPhotoRepositoryのfetchPhotoがIDで検索")
        func testExistingMockFetchById() async {
            let mock = MockPhotoRepository()
            mock.mockPhotos = [
                PhotoAsset(id: "target-id", creationDate: Date(), fileSize: 1024)
            ]

            let found = await mock.fetchPhoto(by: "target-id")
            let notFound = await mock.fetchPhoto(by: "non-existent")

            #expect(found?.id == "target-id")
            #expect(notFound == nil)
        }

        @Test("既存のMockPhotoRepositoryの削除操作が記録される")
        func testExistingMockDeletePhotos() async throws {
            let mock = MockPhotoRepository()
            let photosToDelete = [
                PhotoAsset(id: "delete-1", creationDate: Date(), fileSize: 1024),
                PhotoAsset(id: "delete-2", creationDate: Date(), fileSize: 2048)
            ]

            try await mock.deletePhotos(photosToDelete)

            #expect(mock.deletePhotosCalled == true)
            #expect(mock.deletedPhotos.count == 2)
        }
    }
    #endif

    // MARK: - PhotoPage Tests (M2-T06)

    @Suite("PhotoPage Tests")
    struct PhotoPageTests {

        @Test("空のPhotoPageが正しく作成される")
        func testEmptyPhotoPage() {
            let page = PhotoPage.empty(pageSize: 50)

            #expect(page.photos.isEmpty)
            #expect(page.totalCount == 0)
            #expect(page.hasMore == false)
            #expect(page.nextOffset == nil)
            #expect(page.currentOffset == 0)
            #expect(page.pageSize == 50)
            #expect(page.isFirstPage == true)
            #expect(page.isLastPage == true)
            #expect(page.isEmpty == true)
            #expect(page.currentPage == 1)
            #expect(page.totalPages == 1)
        }

        @Test("PhotoPage.allファクトリメソッドが正しく動作する")
        func testPhotoPageAll() {
            // テスト用のPhotoを作成
            let photos = createTestPhotos(count: 5)
            let page = PhotoPage.all(photos)

            #expect(page.photos.count == 5)
            #expect(page.totalCount == 5)
            #expect(page.hasMore == false)
            #expect(page.nextOffset == nil)
            #expect(page.currentOffset == 0)
            #expect(page.pageSize == 5)
            #expect(page.isFirstPage == true)
            #expect(page.isLastPage == true)
        }

        @Test("PhotoPageのページ計算が正しい")
        func testPhotoPageCalculations() {
            // 100件中、offset=20、limit=20のケース
            let page = PhotoPage(
                photos: createTestPhotos(count: 20),
                totalCount: 100,
                hasMore: true,
                nextOffset: 40,
                currentOffset: 20,
                pageSize: 20
            )

            #expect(page.currentPage == 2)  // 0-19が1ページ目、20-39が2ページ目
            #expect(page.totalPages == 5)   // 100件 / 20件 = 5ページ
            #expect(page.isFirstPage == false)
            #expect(page.isLastPage == false)
            #expect(page.previousOffset == 0)
            #expect(page.fetchedCount == 20)
        }

        @Test("PhotoPageの最後のページが正しく判定される")
        func testPhotoPageLastPage() {
            // 100件中、offset=80、limit=20のケース（最後のページ）
            let page = PhotoPage(
                photos: createTestPhotos(count: 20),
                totalCount: 100,
                hasMore: false,
                nextOffset: nil,
                currentOffset: 80,
                pageSize: 20
            )

            #expect(page.currentPage == 5)
            #expect(page.isLastPage == true)
            #expect(page.previousOffset == 60)
        }

        @Test("PhotoPageの説明が正しいフォーマット")
        func testPhotoPageDescription() {
            let page = PhotoPage(
                photos: createTestPhotos(count: 10),
                totalCount: 50,
                hasMore: true,
                nextOffset: 10,
                currentOffset: 0,
                pageSize: 10
            )

            let description = page.description
            #expect(description.contains("page: 1/5"))
            #expect(description.contains("count: 10/50"))
            #expect(description.contains("hasMore: true"))
        }
    }

    // MARK: - PhotoPageAsset Tests

    @Suite("PhotoPageAsset Tests")
    struct PhotoPageAssetTests {

        @Test("空のPhotoPageAssetが正しく作成される")
        func testEmptyPhotoPageAsset() {
            let page = PhotoPageAsset.empty(pageSize: 25)

            #expect(page.photos.isEmpty)
            #expect(page.totalCount == 0)
            #expect(page.hasMore == false)
            #expect(page.pageSize == 25)
            #expect(page.isEmpty == true)
        }

        @Test("PhotoPageからPhotoPageAssetへの変換が正しい")
        func testFromPhotoPage() {
            let photoPage = PhotoPage(
                photos: createTestPhotos(count: 5),
                totalCount: 100,
                hasMore: true,
                nextOffset: 5,
                currentOffset: 0,
                pageSize: 5
            )

            let assetPage = PhotoPageAsset.from(photoPage)

            #expect(assetPage.photos.count == 5)
            #expect(assetPage.totalCount == 100)
            #expect(assetPage.hasMore == true)
            #expect(assetPage.nextOffset == 5)
            #expect(assetPage.currentOffset == 0)
            #expect(assetPage.pageSize == 5)
        }
    }

    // MARK: - PhotoDateRangeFilter Tests

    @Suite("PhotoDateRangeFilter Tests")
    struct DateRangeFilterTests {

        @Test("lastDaysフィルターが正しく作成される")
        func testLastDaysFilter() {
            let filter = PhotoDateRangeFilter.lastDays(7)
            let now = Date()
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

            // 開始日が7日前付近であること
            let startDiff = abs(filter.startDate.timeIntervalSince(sevenDaysAgo))
            #expect(startDiff < 1.0)  // 1秒以内の誤差

            // 終了日が現在付近であること
            let endDiff = abs(filter.endDate.timeIntervalSince(now))
            #expect(endDiff < 1.0)
        }

        @Test("lastWeeksフィルターが正しく作成される")
        func testLastWeeksFilter() {
            let filter = PhotoDateRangeFilter.lastWeeks(2)
            let now = Date()
            let twoWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: now)!

            let startDiff = abs(filter.startDate.timeIntervalSince(twoWeeksAgo))
            #expect(startDiff < 1.0)
        }

        @Test("lastMonthsフィルターが正しく作成される")
        func testLastMonthsFilter() {
            let filter = PhotoDateRangeFilter.lastMonths(3)
            let now = Date()
            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now)!

            let startDiff = abs(filter.startDate.timeIntervalSince(threeMonthsAgo))
            #expect(startDiff < 1.0)
        }

        @Test("todayフィルターが今日の日付範囲を返す")
        func testTodayFilter() {
            let filter = PhotoDateRangeFilter.today()
            let now = Date()
            let startOfToday = Calendar.current.startOfDay(for: now)

            #expect(filter.startDate == startOfToday)
            #expect(filter.endDate > startOfToday)
        }

        @Test("カスタム日付範囲フィルターが正しく作成される")
        func testCustomDateRangeFilter() {
            let startDate = Date(timeIntervalSince1970: 1000000)
            let endDate = Date(timeIntervalSince1970: 2000000)

            let filter = PhotoDateRangeFilter(startDate: startDate, endDate: endDate)

            #expect(filter.startDate == startDate)
            #expect(filter.endDate == endDate)
        }
    }

    // MARK: - Advanced Filtering Tests (M2-T06)

    @Suite("Advanced Filtering Tests")
    @MainActor
    struct AdvancedFilteringTests {

        @Test("権限なしで日付範囲フィルタ取得時にエラー - M2-T06-TC03")
        func testDateRangeFetchWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchPhotos(
                    from: Date().addingTimeInterval(-86400),
                    to: Date()
                )
            }
        }

        @Test("権限なしでお気に入り取得時にエラー")
        func testFetchFavoritesWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchFavoritePhotos()
            }
        }

        @Test("権限なしでスクリーンショット取得時にエラー")
        func testFetchScreenshotsWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchScreenshots()
            }
        }

        @Test("権限なしでLive Photo取得時にエラー")
        func testFetchLivePhotosWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchLivePhotos()
            }
        }

        @Test("権限なしでメディアタイプフィルタ取得時にエラー")
        func testMediaTypeFetchWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchPhotos(mediaType: .image)
            }
        }
    }

    // MARK: - Pagination Tests (M2-T06)

    @Suite("Pagination Tests")
    @MainActor
    struct PaginationTests {

        @Test("権限なしでページネーション取得時にエラー - M2-T06-TC03")
        func testPaginationWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchPhotos(offset: 0, limit: 50)
            }
        }

        @Test("権限なしでPhotoAssetページネーション取得時にエラー")
        func testPhotoAssetPaginationWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchPhotoAssets(offset: 0, limit: 50)
            }
        }
    }

    // MARK: - Batch Fetch Tests (M2-T06)

    @Suite("Batch Fetch Tests")
    @MainActor
    struct BatchFetchTests {

        @Test("権限なしでバッチ取得時にエラー - M2-T06-TC03")
        func testBatchFetchWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            await #expect(throws: PhotoRepositoryError.self) {
                _ = try await repository.fetchAllPhotosInBatches(
                    batchSize: 100,
                    progress: { _ in }
                )
            }
        }

        @Test("権限なしでストリーム取得時にエラー")
        func testStreamFetchWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            #expect(throws: PhotoRepositoryError.self) {
                _ = try repository.fetchAllPhotosAsStream(batchSize: 100)
            }
        }
    }

    // MARK: - Count Methods Tests (M2-T06)

    @Suite("Count Methods Tests")
    @MainActor
    struct CountMethodsTests {

        @Test("権限なしで写真数取得時にエラー - M2-T06-TC03")
        func testPhotoCountWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            #expect(throws: PhotoRepositoryError.self) {
                _ = try repository.fetchPhotoCount()
            }
        }

        @Test("権限なしでスクリーンショット数取得時にエラー")
        func testScreenshotCountWithDeniedPermission() async {
            let mockPermission = MockPhotoPermissionManager()
            mockPermission.mockStatus = .denied
            let repository = PhotoRepository(permissionManager: mockPermission)

            #expect(throws: PhotoRepositoryError.self) {
                _ = try repository.fetchScreenshotCount()
            }
        }
    }
}

// MARK: - ThumbnailRequestOptions Tests (M2-T07)

@Suite("ThumbnailRequestOptions Tests")
struct ThumbnailRequestOptionsTests {

    @Test("デフォルトオプションが正しく設定される")
    func testDefaultOptions() {
        let options = ThumbnailRequestOptions.default

        #expect(options.size == CGSize(width: 100, height: 100))
        #expect(options.contentMode == .aspectFill)
        #expect(options.quality == .balanced)
        #expect(options.isNetworkAccessAllowed == true)
        #expect(options.isSynchronous == false)
    }

    @Test("グリッドオプションが正しく設定される")
    func testGridOptions() {
        let size = CGSize(width: 80, height: 80)
        let options = ThumbnailRequestOptions.grid(size: size)

        #expect(options.size == size)
        #expect(options.contentMode == .aspectFill)
        #expect(options.quality == .fast)
        #expect(options.isNetworkAccessAllowed == false)
    }

    @Test("詳細表示オプションが正しく設定される")
    func testDetailOptions() {
        let size = CGSize(width: 300, height: 300)
        let options = ThumbnailRequestOptions.detail(size: size)

        #expect(options.size == size)
        #expect(options.contentMode == .aspectFit)
        #expect(options.quality == .highQuality)
        #expect(options.isNetworkAccessAllowed == true)
    }

    @Test("プレビューオプションが正しく設定される")
    func testPreviewOptions() {
        let size = CGSize(width: 200, height: 200)
        let options = ThumbnailRequestOptions.preview(size: size)

        #expect(options.size == size)
        #expect(options.quality == .balanced)
    }

    @Test("高速スクロールオプションが正しく設定される")
    func testFastScrollOptions() {
        let size = CGSize(width: 60, height: 60)
        let options = ThumbnailRequestOptions.fastScroll(size: size)

        #expect(options.size == size)
        #expect(options.quality == .fast)
        #expect(options.isNetworkAccessAllowed == false)
    }

    @Test("プリキャッシュオプションが正しく設定される")
    func testPreCacheOptions() {
        let size = CGSize(width: 100, height: 100)
        let options = ThumbnailRequestOptions.preCache(size: size)

        #expect(options.size == size)
        #expect(options.quality == .fast)
        #expect(options.isNetworkAccessAllowed == false)
    }

    @Test("withSizeで新しいオプションが作成される")
    func testWithSize() {
        let original = ThumbnailRequestOptions.default
        let newSize = CGSize(width: 200, height: 200)
        let modified = original.withSize(newSize)

        #expect(modified.size == newSize)
        #expect(modified.quality == original.quality)
        #expect(modified.contentMode == original.contentMode)
        #expect(modified.isNetworkAccessAllowed == original.isNetworkAccessAllowed)
    }

    @Test("withQualityで新しいオプションが作成される")
    func testWithQuality() {
        let original = ThumbnailRequestOptions.default
        let modified = original.withQuality(.highQuality)

        #expect(modified.quality == .highQuality)
        #expect(modified.size == original.size)
    }

    @Test("withNetworkAccessで新しいオプションが作成される")
    func testWithNetworkAccess() {
        let original = ThumbnailRequestOptions.default
        let modified = original.withNetworkAccess(false)

        #expect(modified.isNetworkAccessAllowed == false)
        #expect(modified.size == original.size)
    }

    @Test("withContentModeで新しいオプションが作成される")
    func testWithContentMode() {
        let original = ThumbnailRequestOptions.default
        let modified = original.withContentMode(.aspectFit)

        #expect(modified.contentMode == .aspectFit)
        #expect(modified.size == original.size)
    }

    @Test("PHImageRequestOptionsへの変換が正しく行われる")
    func testToPHImageRequestOptions() {
        let options = ThumbnailRequestOptions(
            size: CGSize(width: 100, height: 100),
            quality: .highQuality,
            isNetworkAccessAllowed: true,
            isSynchronous: false
        )

        let phOptions = options.toPHImageRequestOptions()

        #expect(phOptions.deliveryMode == .highQualityFormat)
        #expect(phOptions.isNetworkAccessAllowed == true)
        #expect(phOptions.isSynchronous == false)
    }

    @Test("サイズプリセットが正しく定義されている")
    func testSizePresets() {
        #expect(ThumbnailRequestOptions.smallSize == CGSize(width: 80, height: 80))
        #expect(ThumbnailRequestOptions.mediumSize == CGSize(width: 150, height: 150))
        #expect(ThumbnailRequestOptions.largeSize == CGSize(width: 300, height: 300))
        #expect(ThumbnailRequestOptions.extraLargeSize == CGSize(width: 600, height: 600))
    }

    @Test("descriptionが正しいフォーマット")
    func testDescription() {
        let options = ThumbnailRequestOptions(
            size: CGSize(width: 100, height: 100),
            quality: .balanced,
            isNetworkAccessAllowed: true
        )

        let description = options.description
        #expect(description.contains("100x100"))
        #expect(description.contains("バランス"))
        #expect(description.contains("network: true"))
    }

    @Test("Equatableが正しく動作する")
    func testEquatable() {
        let options1 = ThumbnailRequestOptions.default
        let options2 = ThumbnailRequestOptions.default
        let options3 = ThumbnailRequestOptions.grid(size: CGSize(width: 80, height: 80))

        #expect(options1 == options2)
        #expect(options1 != options3)
    }

    @Test("Hashableが正しく動作する")
    func testHashable() {
        let options1 = ThumbnailRequestOptions.default
        let options2 = ThumbnailRequestOptions.default

        var set: Set<ThumbnailRequestOptions> = []
        set.insert(options1)
        set.insert(options2)

        #expect(set.count == 1)
    }
}

// MARK: - ThumbnailQuality Tests (M2-T07)

@Suite("ThumbnailQuality Tests")
struct ThumbnailQualityTests {

    @Test("品質のdeliveryModeが正しくマッピングされる")
    func testDeliveryMode() {
        #expect(ThumbnailQuality.fast.deliveryMode == .fastFormat)
        #expect(ThumbnailQuality.balanced.deliveryMode == .opportunistic)
        #expect(ThumbnailQuality.highQuality.deliveryMode == .highQualityFormat)
    }

    @Test("品質のresizeModeが正しくマッピングされる")
    func testResizeMode() {
        #expect(ThumbnailQuality.fast.resizeMode == .fast)
        #expect(ThumbnailQuality.balanced.resizeMode == .fast)
        #expect(ThumbnailQuality.highQuality.resizeMode == .exact)
    }

    @Test("品質のローカライズ名が存在する")
    func testLocalizedName() {
        #expect(!ThumbnailQuality.fast.localizedName.isEmpty)
        #expect(!ThumbnailQuality.balanced.localizedName.isEmpty)
        #expect(!ThumbnailQuality.highQuality.localizedName.isEmpty)
    }

    @Test("品質のrawValueが正しい")
    func testRawValue() {
        #expect(ThumbnailQuality.fast.rawValue == 0)
        #expect(ThumbnailQuality.balanced.rawValue == 1)
        #expect(ThumbnailQuality.highQuality.rawValue == 2)
    }
}

// MARK: - ThumbnailBatchProgress Tests (M2-T07)

@Suite("ThumbnailBatchProgress Tests")
struct ThumbnailBatchProgressTests {

    @Test("進捗率が正しく計算される")
    func testProgress() {
        let progress1 = ThumbnailBatchProgress(completed: 5, total: 10)
        #expect(progress1.progress == 0.5)

        let progress2 = ThumbnailBatchProgress(completed: 0, total: 10)
        #expect(progress2.progress == 0.0)

        let progress3 = ThumbnailBatchProgress(completed: 10, total: 10)
        #expect(progress3.progress == 1.0)
    }

    @Test("totalが0の場合に進捗率が0になる")
    func testZeroTotal() {
        let progress = ThumbnailBatchProgress(completed: 0, total: 0)
        #expect(progress.progress == 0.0)
    }

    @Test("完了判定が正しく動作する")
    func testIsCompleted() {
        let progress1 = ThumbnailBatchProgress(completed: 5, total: 10)
        #expect(progress1.isCompleted == false)

        let progress2 = ThumbnailBatchProgress(completed: 10, total: 10)
        #expect(progress2.isCompleted == true)

        let progress3 = ThumbnailBatchProgress(completed: 15, total: 10)
        #expect(progress3.isCompleted == true)
    }
}

// MARK: - Thumbnail Fetch Tests (M2-T07)

#if canImport(UIKit)
@Suite("Thumbnail Fetch Tests")
@MainActor
struct ThumbnailFetchTests {

    @Test("プリロードがエラーなく実行される")
    func testPreloadThumbnails() async {
        let mockPermission = MockPhotoPermissionManager()
        let repository = PhotoRepository(permissionManager: mockPermission)

        let options = ThumbnailRequestOptions.grid(size: CGSize(width: 100, height: 100))
        let photos: [Photo] = []

        // 空の配列でもエラーにならない
        repository.preloadThumbnails(for: photos, options: options)
        #expect(Bool(true))
    }

    @Test("プリロード停止がエラーなく実行される")
    func testStopPreloadingThumbnails() async {
        let mockPermission = MockPhotoPermissionManager()
        let repository = PhotoRepository(permissionManager: mockPermission)

        let options = ThumbnailRequestOptions.grid(size: CGSize(width: 100, height: 100))
        let photos: [Photo] = []

        // 空の配列でもエラーにならない
        repository.stopPreloadingThumbnails(for: photos, options: options)
        #expect(Bool(true))
    }

    @Test("キャッシュクリアがエラーなく実行される")
    func testClearThumbnailCache() async {
        let mockPermission = MockPhotoPermissionManager()
        let repository = PhotoRepository(permissionManager: mockPermission)

        // エラーなく完了することを確認
        repository.clearThumbnailCache()
        #expect(Bool(true))
    }

    @Test("キャッシュ戦略更新がエラーなく実行される")
    func testUpdateCachingStrategy() async {
        let mockPermission = MockPhotoPermissionManager()
        let repository = PhotoRepository(permissionManager: mockPermission)

        let options = ThumbnailRequestOptions.grid(size: CGSize(width: 100, height: 100))
        let addingPhotos: [Photo] = []
        let removingPhotos: [Photo] = []

        // 空の配列でもエラーにならない
        repository.updateCachingStrategy(
            addingPhotos: addingPhotos,
            removingPhotos: removingPhotos,
            options: options
        )
        #expect(Bool(true))
    }

    @Test("バッチ取得が空配列で空辞書を返す")
    func testFetchThumbnailsWithEmptyArray() async throws {
        let mockPermission = MockPhotoPermissionManager()
        mockPermission.mockStatus = .authorized
        let repository = PhotoRepository(permissionManager: mockPermission)

        let options = ThumbnailRequestOptions.default
        // Swift 6ではクロージャ内でvar変数を変更できないため、
        // 空のプログレスクロージャを渡す

        let results = try await repository.fetchThumbnails(
            for: [],
            options: options,
            progress: { _, _ in }
        )

        #expect(results.isEmpty)
    }

    @Test("存在しないIDでサムネイル取得時にエラー")
    func testFetchThumbnailWithInvalidId() async {
        let mockPermission = MockPhotoPermissionManager()
        mockPermission.mockStatus = .authorized
        let repository = PhotoRepository(permissionManager: mockPermission)

        let photo = Photo(
            id: "non-existent-id",
            localIdentifier: "non-existent-id",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 0,
            isFavorite: false
        )

        let options = ThumbnailRequestOptions.default

        await #expect(throws: PhotoRepositoryError.self) {
            _ = try await repository.fetchThumbnail(for: photo, options: options)
        }
    }
}
#endif

// MARK: - Test Helpers

/// テスト用のPhotoを作成するヘルパー関数
private func createTestPhotos(count: Int) -> [Photo] {
    var photos: [Photo] = []
    photos.reserveCapacity(count)

    let now = Date()

    for index in 0..<count {
        let photo = Photo(
            id: "test-photo-\(index)",
            localIdentifier: "test-photo-\(index)",
            creationDate: now.addingTimeInterval(Double(-index * 3600)),
            modificationDate: now,
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: Int64(1024 * (index + 1)),
            isFavorite: index % 3 == 0
        )
        photos.append(photo)
    }

    return photos
}

// MARK: - MockPhotoPermissionManager

/// テスト用のモック権限マネージャー
@MainActor
final class MockPhotoPermissionManager: PhotoPermissionManagerProtocol {

    var mockStatus: PHAuthorizationStatus = .authorized

    var currentStatus: PHAuthorizationStatus {
        mockStatus
    }

    func checkPermissionStatus() -> PHAuthorizationStatus {
        mockStatus
    }

    func requestPermission() async -> PHAuthorizationStatus {
        mockStatus
    }

    func openSettings() {
        // テスト用：何もしない
    }
}
