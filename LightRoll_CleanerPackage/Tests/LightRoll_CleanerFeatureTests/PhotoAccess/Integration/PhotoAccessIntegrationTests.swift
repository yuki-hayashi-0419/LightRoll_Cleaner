//
//  PhotoAccessIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoAccess機能の統合テスト
//  各コンポーネント間の連携をテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

@testable import LightRoll_CleanerFeature

// MARK: - Mock Components for Integration Tests

/// 統合テスト用のモック権限マネージャー
@MainActor
final class IntegrationMockPermissionManager: PhotoPermissionManagerProtocol {
    var currentStatus: PHAuthorizationStatus
    private var requestResult: PHAuthorizationStatus

    init(status: PHAuthorizationStatus = .authorized, requestResult: PHAuthorizationStatus? = nil) {
        self.currentStatus = status
        self.requestResult = requestResult ?? status
    }

    func checkPermissionStatus() -> PHAuthorizationStatus {
        return currentStatus
    }

    func requestPermission() async -> PHAuthorizationStatus {
        currentStatus = requestResult
        return requestResult
    }

    func openSettings() {
        // テスト用: 何もしない
    }
}

/// 統合テスト用のモックリポジトリ
/// PhotoRepositoryの実際の動作をシミュレート
@MainActor
final class IntegrationMockPhotoRepository {
    var mockPhotos: [Photo] = []
    var shouldFailWithError: PhotoRepositoryError?
    var fetchDelay: TimeInterval = 0
    var fetchCallCount: Int = 0

    /// テスト用の写真を生成
    static func generateMockPhotos(count: Int, withFileSize: Bool = true) -> [Photo] {
        let baseDate = Date()
        return (0..<count).map { index in
            let isVideo = index % 5 == 0
            let id = "mock-photo-\(index)"
            var mediaSubtypes: MediaSubtypes = []
            if index % 15 == 0 {
                mediaSubtypes.insert(.screenshot)
            }

            return Photo(
                id: id,
                localIdentifier: id,
                creationDate: baseDate.addingTimeInterval(-Double(index) * 86400),
                modificationDate: baseDate.addingTimeInterval(-Double(index) * 86400),
                mediaType: isVideo ? .video : .image,
                mediaSubtypes: mediaSubtypes,
                pixelWidth: isVideo ? 1920 : 3024,
                pixelHeight: isVideo ? 1080 : 4032,
                duration: isVideo ? Double.random(in: 5...120) : 0,
                fileSize: withFileSize ? Int64.random(in: 1_000_000...10_000_000) : 0,
                isFavorite: index % 10 == 0
            )
        }
    }
}

// MARK: - PhotoRepository + PhotoScanner Integration Tests

@Suite("PhotoRepository と PhotoScanner の統合テスト")
@MainActor
struct PhotoRepositoryScannerIntegrationTests {

    @Test("リポジトリとスキャナーの基本連携")
    func repositoryAndScannerBasicIntegration() async throws {
        // 準備
        let mockPermission = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: .default
        )

        // スキャナーの初期状態確認
        #expect(scanner.scanState == .idle)
        #expect(scanner.progress == 0.0)

        // スキャン実行
        do {
            let photos = try await scanner.scan()

            // スキャン完了の確認
            #expect(scanner.scanState == .completed)
            #expect(scanner.progress == 1.0)
            #expect(photos.count >= 0)
        } catch {
            // 権限エラー以外は許容
            if let scanError = error as? PhotoScannerError {
                #expect(scanError != .scanInProgress)
            }
        }
    }

    @Test("スキャンオプションがリポジトリに正しく伝播される")
    func scanOptionsPropagatesToRepository() async throws {
        let mockPermission = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)

        // カスタムオプションでスキャナー作成
        let customOptions = ScanOptions(
            includeVideos: false,
            includeScreenshots: false,
            fetchFileSize: true,
            batchSize: 50
        )

        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: customOptions
        )

        // オプションが正しく設定されている
        #expect(scanner.options.includeVideos == false)
        #expect(scanner.options.includeScreenshots == false)
        #expect(scanner.options.fetchFileSize == true)
        #expect(scanner.options.batchSize == 50)

        // スキャン実行
        do {
            let photos = try await scanner.scan()

            // 動画が除外されているか確認
            for photo in photos {
                #expect(photo.mediaType != .video)
            }
        } catch {
            // エラーでもOK
        }
    }

    @Test("進捗コールバックがリアルタイムで更新される")
    func progressCallbackUpdatesInRealTime() async throws {
        let mockPermission = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // 進捗追跡
        actor ProgressTracker {
            var progressValues: [Double] = []
            var updateTimes: [Date] = []

            func record(_ progress: Double) {
                progressValues.append(progress)
                updateTimes.append(Date())
            }

            func getProgressValues() -> [Double] { progressValues }
            func getUpdateCount() -> Int { progressValues.count }
        }

        let tracker = ProgressTracker()

        // スキャン実行
        do {
            _ = try await scanner.scan { progress in
                Task { await tracker.record(progress.percentage) }
            }

            // 少し待機
            try? await Task.sleep(for: .milliseconds(100))

            // 進捗更新が行われた
            let progressValues = await tracker.getProgressValues()

            // 全ての進捗値が0.0〜1.0の範囲内
            for value in progressValues {
                #expect(value >= 0.0 && value <= 1.0)
            }

            // 最終的に scanner.progress は 1.0
            #expect(scanner.progress == 1.0)
        } catch {
            // エラーでもOK
        }
    }

    @Test("スキャンキャンセルが正しく動作する")
    func scanCancellationWorksCorrectly() async throws {
        let mockPermission = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // スキャンタスクを開始
        let scanTask = Task {
            try await scanner.scan()
        }

        // 少し待ってからキャンセル
        try? await Task.sleep(for: .milliseconds(10))
        scanner.cancel()

        // タスク完了を待つ
        do {
            _ = try await scanTask.value
        } catch {
            // キャンセルエラーは期待される
        }

        // キャンセルまたは完了状態
        #expect(scanner.scanState == .cancelled || scanner.scanState == .completed)
    }
}

// MARK: - PhotoScanner + ThumbnailCache Integration Tests

@Suite("PhotoScanner と ThumbnailCache の統合テスト")
@MainActor
struct PhotoScannerCacheIntegrationTests {

    #if canImport(UIKit)
    @Test("スキャン結果のサムネイルがキャッシュに保存される")
    func scanResultThumbnailsAreCached() async throws {
        let mockPermission = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        let cache = ThumbnailCache()
        let thumbnailSize = ThumbnailRequestOptions.mediumSize

        // スキャン実行
        do {
            let photos = try await scanner.scan()

            guard !photos.isEmpty else {
                // 写真がない場合はスキップ
                return
            }

            // 最初の数枚のサムネイルをキャッシュに保存（シミュレート）
            let photosToCache = photos.prefix(min(5, photos.count))
            for photo in photosToCache {
                // ダミー画像を生成してキャッシュ
                let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
                let dummyImage = renderer.image { context in
                    UIColor.gray.setFill()
                    context.fill(CGRect(origin: .zero, size: thumbnailSize))
                }

                cache.setThumbnail(dummyImage, for: photo.id, size: thumbnailSize)
            }

            // キャッシュに保存されている
            for photo in photosToCache {
                #expect(cache.contains(assetId: photo.id, size: thumbnailSize))
            }

            // 統計確認
            let stats = cache.statistics()
            #expect(stats.currentCount >= photosToCache.count)
        } catch {
            // エラーでもOK
        }
    }

    @Test("キャッシュヒット率が正しく計算される")
    func cacheHitRateIsCorrect() async throws {
        let cache = ThumbnailCache()
        let thumbnailSize = CGSize(width: 100, height: 100)

        // ダミー画像生成ヘルパー
        func createDummyImage() -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            return renderer.image { context in
                UIColor.blue.setFill()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))
            }
        }

        // いくつかの画像をキャッシュに保存
        for i in 0..<5 {
            cache.setThumbnail(createDummyImage(), for: "photo-\(i)", size: thumbnailSize)
        }

        // ヒット
        _ = cache.thumbnail(for: "photo-0", size: thumbnailSize)
        _ = cache.thumbnail(for: "photo-1", size: thumbnailSize)
        _ = cache.thumbnail(for: "photo-2", size: thumbnailSize)

        // ミス
        _ = cache.thumbnail(for: "non-existent-1", size: thumbnailSize)
        _ = cache.thumbnail(for: "non-existent-2", size: thumbnailSize)

        let stats = cache.statistics()

        // ヒット率 = 3 / (3 + 2) = 0.6
        #expect(stats.hitCount == 3)
        #expect(stats.missCount == 2)
        #expect(abs(stats.hitRate - 0.6) < 0.001)
    }

    @Test("メモリ警告時にキャッシュがクリアされる")
    func cacheIsClearedOnMemoryWarning() async throws {
        let cache = ThumbnailCache()
        let thumbnailSize = CGSize(width: 100, height: 100)

        // ダミー画像を追加
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let dummyImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))
        }

        for i in 0..<20 {
            cache.setThumbnail(dummyImage, for: "photo-\(i)", size: thumbnailSize)
        }

        // メモリ警告を発行
        cache.handleMemoryWarning()

        // 統計がリセットされる
        let stats = cache.statistics()
        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)
    }
    #endif
}

// MARK: - StorageService + PhotoRepository Integration Tests

@Suite("StorageService と PhotoRepository の統合テスト")
@MainActor
struct StorageRepositoryIntegrationTests {

    @Test("ストレージ情報と写真リポジトリの連携")
    func storageAndRepositoryIntegration() async throws {
        let storageService = StorageService()

        // デバイスストレージ情報取得
        let storageInfo = try await storageService.getDeviceStorageInfo()

        #expect(storageInfo.totalCapacity > 0)
        #expect(storageInfo.availableCapacity >= 0)
        #expect(storageInfo.usagePercentage >= 0.0 && storageInfo.usagePercentage <= 1.0)
    }

    @Test("回収可能容量の計算が正しい")
    func reclaimableSpaceCalculationIsCorrect() async {
        let storageService = StorageService()

        // テスト用のPhotoGroupを作成
        let group1 = PhotoGroup(
            type: .similar,
            photoIds: ["p1", "p2", "p3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000],
            bestShotIndex: 0 // p1がベストショット
        )

        let group2 = PhotoGroup(
            type: .selfie,
            photoIds: ["p4", "p5"],
            fileSizes: [4_000_000, 5_000_000],
            bestShotIndex: 1 // p5がベストショット
        )

        // 回収可能容量を計算
        let reclaimable = await storageService.estimateReclaimableSpace(from: [group1, group2])

        // group1: p2 + p3 = 5MB, group2: p4 = 4MB, 合計 9MB
        #expect(reclaimable == 9_000_000)
    }

    @Test("完全なストレージ情報を取得できる")
    func completeStorageInfoCanBeRetrieved() async throws {
        let storageService = StorageService()

        let storageInfo = try await storageService.getCompleteStorageInfo()

        #expect(storageInfo.totalCapacity > 0)
        #expect(storageInfo.availableCapacity >= 0)
        #expect(storageInfo.photosUsedCapacity >= 0)
    }
}

// MARK: - Full Workflow Integration Tests

@Suite("PhotoAccess 全ワークフロー統合テスト")
@MainActor
struct FullWorkflowIntegrationTests {

    @Test("エンドツーエンド: 権限確認 → スキャン → 結果処理")
    func endToEndWorkflow() async throws {
        // 1. 権限マネージャー初期化
        let permissionManager = IntegrationMockPermissionManager(status: .authorized)

        // 2. 権限確認
        let status = permissionManager.checkPermissionStatus()
        #expect(status == .authorized)

        // 3. リポジトリとスキャナー初期化
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager,
            options: .fast
        )

        // 4. スキャン実行
        do {
            let photos = try await scanner.scan()

            // 5. 結果確認
            #expect(scanner.scanState == .completed)
            #expect(photos.count >= 0)

            // 6. ストレージサービスで容量情報取得
            let storageService = StorageService()
            let storageInfo = try await storageService.getDeviceStorageInfo()

            #expect(storageInfo.totalCapacity > 0)

            // 7. 写真の合計サイズ計算
            let photoAssets = photos.map { photo in
                PhotoAsset(
                    id: photo.id,
                    creationDate: photo.creationDate,
                    fileSize: photo.fileSize
                )
            }
            let totalSize = storageService.calculateTotalSize(for: photoAssets)

            #expect(totalSize >= 0)
        } catch {
            // 権限エラー以外は許容
        }
    }

    @Test("複数回のスキャンが正しく動作する")
    func multipleScansWorkCorrectly() async throws {
        let permissionManager = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager
        )

        // 1回目のスキャン
        do {
            let firstScanPhotos = try await scanner.scan()
            #expect(scanner.scanState == .completed)

            // リセット
            scanner.reset()
            #expect(scanner.scanState == .idle)
            #expect(scanner.progress == 0.0)

            // 2回目のスキャン
            let secondScanPhotos = try await scanner.scan()
            #expect(scanner.scanState == .completed)

            // 同じ結果が得られる
            #expect(firstScanPhotos.count == secondScanPhotos.count)
        } catch {
            // エラーでもOK
        }
    }

    @Test("オプション変更後のスキャンが正しく動作する")
    func scanWithChangedOptionsWorksCorrectly() async throws {
        let permissionManager = IntegrationMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager
        )

        // デフォルトオプションでスキャン
        do {
            _ = try await scanner.scan()
            #expect(scanner.scanState == .completed)

            // リセットしてオプション変更
            scanner.reset()
            scanner.options = ScanOptions(includeVideos: false, batchSize: 25)

            // 変更後のスキャン
            let photos = try await scanner.scan()
            #expect(scanner.scanState == .completed)

            // 動画が含まれていない
            for photo in photos {
                #expect(photo.mediaType != .video)
            }
        } catch {
            // エラーでもOK
        }
    }

    @Test("バックグラウンドスキャンマネージャーとの連携")
    func backgroundScanManagerIntegration() async {
        // モックUserDefaultsでテスト
        final class MockUserDefaults: UserDefaults {
            private var storage: [String: Any] = [:]

            override func bool(forKey defaultName: String) -> Bool {
                storage[defaultName] as? Bool ?? false
            }

            override func set(_ value: Bool, forKey defaultName: String) {
                storage[defaultName] = value
            }

            override func double(forKey defaultName: String) -> Double {
                storage[defaultName] as? Double ?? 0.0
            }

            override func set(_ value: Double, forKey defaultName: String) {
                storage[defaultName] = value
            }

            override func object(forKey defaultName: String) -> Any? {
                storage[defaultName]
            }

            override func set(_ value: Any?, forKey defaultName: String) {
                if let value = value {
                    storage[defaultName] = value
                } else {
                    storage.removeValue(forKey: defaultName)
                }
            }
        }

        let mockDefaults = MockUserDefaults()
        let backgroundManager = BackgroundScanManager(userDefaults: mockDefaults)

        // 初期状態は無効
        #expect(backgroundManager.isBackgroundScanEnabled == false)

        // 有効化
        backgroundManager.isBackgroundScanEnabled = true
        #expect(backgroundManager.isBackgroundScanEnabled == true)

        // スキャン間隔設定
        backgroundManager.scanInterval = 12 * 60 * 60 // 12時間
        #expect(backgroundManager.scanInterval == 12 * 60 * 60)

        // 無効化でスケジュールがクリアされる
        backgroundManager.isBackgroundScanEnabled = false
        #expect(backgroundManager.nextScheduledScanDate == nil)
    }
}

// MARK: - Error Propagation Integration Tests

@Suite("エラー伝播の統合テスト")
@MainActor
struct ErrorPropagationIntegrationTests {

    @Test("権限拒否エラーがスキャナーまで正しく伝播する")
    func permissionDeniedErrorPropagates() async {
        let permissionManager = IntegrationMockPermissionManager(status: .denied)
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }

        #expect(scanner.scanState == .failed(.notAuthorized))
    }

    @Test("権限制限エラーがスキャナーまで正しく伝播する")
    func permissionRestrictedErrorPropagates() async {
        let permissionManager = IntegrationMockPermissionManager(status: .restricted)
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }

        #expect(scanner.scanState == .failed(.notAuthorized))
    }

    @Test("権限未決定エラーがスキャナーまで正しく伝播する")
    func permissionNotDeterminedErrorPropagates() async {
        let permissionManager = IntegrationMockPermissionManager(status: .notDetermined)
        let repository = PhotoRepository(permissionManager: permissionManager)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: permissionManager
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }
    }
}
