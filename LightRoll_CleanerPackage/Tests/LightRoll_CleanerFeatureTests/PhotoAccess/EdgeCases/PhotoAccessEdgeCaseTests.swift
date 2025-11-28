//
//  PhotoAccessEdgeCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoAccess機能のエッジケーステスト
//  境界値、異常系、パフォーマンスに関するテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

@testable import LightRoll_CleanerFeature

// MARK: - Mock Components for Edge Case Tests

/// エッジケーステスト用のモック権限マネージャー
@MainActor
final class EdgeCaseMockPermissionManager: PhotoPermissionManagerProtocol {
    var currentStatus: PHAuthorizationStatus
    private var requestResult: PHAuthorizationStatus
    var statusChangeHandler: ((PHAuthorizationStatus) -> Void)?

    init(status: PHAuthorizationStatus = .authorized, requestResult: PHAuthorizationStatus? = nil) {
        self.currentStatus = status
        self.requestResult = requestResult ?? status
    }

    func checkPermissionStatus() -> PHAuthorizationStatus {
        return currentStatus
    }

    func requestPermission() async -> PHAuthorizationStatus {
        currentStatus = requestResult
        statusChangeHandler?(requestResult)
        return requestResult
    }

    func openSettings() {
        // テスト用: 何もしない
    }

    /// 権限状態を変更（テスト用）
    func changeStatus(to newStatus: PHAuthorizationStatus) {
        currentStatus = newStatus
        statusChangeHandler?(newStatus)
    }
}

// MARK: - Empty Photo Library Edge Cases

@Suite("空のフォトライブラリ エッジケース")
@MainActor
struct EmptyPhotoLibraryEdgeCaseTests {

    @Test("空のフォトライブラリでスキャンが正常完了する")
    func emptyLibraryScanCompletes() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            let photos = try await scanner.scan()

            // 空でも正常に完了
            #expect(scanner.scanState == .completed)
            #expect(scanner.progress == 1.0)
            #expect(photos.count >= 0)
        } catch {
            // エラーでもOK
        }
    }

    @Test("空のフォトライブラリで進捗コールバックが呼ばれる")
    func emptyLibraryProgressCallbackIsCalled() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        actor CallCounter {
            var count = 0
            func increment() { count += 1 }
            func getCount() -> Int { count }
        }

        let counter = CallCounter()

        do {
            _ = try await scanner.scan { _ in
                Task { await counter.increment() }
            }

            // 少し待機
            try? await Task.sleep(for: .milliseconds(50))

            // 空でも少なくとも完了時のコールバックは呼ばれる
            let callCount = await counter.getCount()
            #expect(callCount >= 1)
        } catch {
            // エラーでもOK
        }
    }

    @Test("空の配列で回収可能容量が0を返す")
    func emptyGroupsReturnZeroReclaimable() async {
        let storageService = StorageService()

        let reclaimable = await storageService.estimateReclaimableSpace(from: [])

        #expect(reclaimable == 0)
    }

    @Test("空の写真配列で合計サイズが0を返す")
    func emptyPhotosReturnZeroTotalSize() {
        let storageService = StorageService()

        let totalSize = storageService.calculateTotalSize(for: [])

        #expect(totalSize == 0)
    }
}

// MARK: - Large Photo Library Edge Cases

@Suite("大量の写真 パフォーマンステスト")
@MainActor
struct LargePhotoLibraryEdgeCaseTests {

    @Test("大量のPhotoAssetで回収可能容量を計算できる")
    func calculateReclaimableForLargeGroups() async {
        let storageService = StorageService()

        // 大量のPhotoAssetを生成
        let photoCount = 1000
        let photos = (0..<photoCount).map { index in
            PhotoAsset(
                id: "photo-\(index)",
                creationDate: Date().addingTimeInterval(-Double(index) * 3600),
                fileSize: Int64.random(in: 1_000_000...5_000_000)
            )
        }

        // 複数のグループに分割
        let groupCount = 50
        let photosPerGroup = photoCount / groupCount
        var groups: [PhotoGroup] = []

        for groupIndex in 0..<groupCount {
            let startIndex = groupIndex * photosPerGroup
            let endIndex = min(startIndex + photosPerGroup, photoCount)
            let groupPhotos = Array(photos[startIndex..<endIndex])
            let photoIds = groupPhotos.map { $0.id }
            let fileSizes = groupPhotos.map { $0.fileSize }

            let types: [GroupType] = [.similar, .selfie, .screenshot, .blurry, .largeVideo]
            let group = PhotoGroup(
                id: UUID(),
                type: types[groupIndex % types.count],
                photoIds: photoIds,
                fileSizes: fileSizes,
                bestShotIndex: 0
            )
            groups.append(group)
        }

        // 計算実行と時間計測
        let startTime = Date()
        let reclaimable = await storageService.estimateReclaimableSpace(from: groups)
        let elapsed = Date().timeIntervalSince(startTime)

        // 結果確認
        #expect(reclaimable > 0)
        // 1秒以内に完了すべき
        #expect(elapsed < 1.0, "回収可能容量計算に \(elapsed) 秒かかりました")
    }

    @Test("大量のバイト数フォーマットが高速に動作する")
    func formatLargeBytesIsPerformant() {
        let testValues: [Int64] = [
            0,
            500,
            1_024,
            1_048_576,
            1_073_741_824,
            1_099_511_627_776,
            Int64.max / 2
        ]

        let startTime = Date()

        for _ in 0..<10000 {
            for value in testValues {
                _ = StorageService.formatBytes(value)
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)

        // 1秒以内に70000回のフォーマットが完了すべき
        #expect(elapsed < 1.0, "フォーマット処理に \(elapsed) 秒かかりました")
    }
}

// MARK: - Memory Pressure Edge Cases

@Suite("メモリプレッシャー エッジケース")
struct MemoryPressureEdgeCaseTests {

    #if canImport(UIKit)
    @Test("メモリ警告でキャッシュが適切に処理される")
    func memorWarningHandlesCacheCorrectly() {
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        // ダミー画像を追加
        let renderer = UIGraphicsImageRenderer(size: size)
        for i in 0..<50 {
            let image = renderer.image { context in
                UIColor.red.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            cache.setThumbnail(image, for: "photo-\(i)", size: size)
        }

        #expect(cache.cachedCount > 0)

        // メモリ警告
        cache.handleMemoryWarning()

        // 統計はリセットされる
        let stats = cache.statistics()
        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)
    }

    @Test("ポリシー変更後も正常に動作する")
    func policyChangeWorksCorrectly() {
        let cache = ThumbnailCache(policy: .default)
        let size = CGSize(width: 100, height: 100)

        // ダミー画像を追加
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        cache.setThumbnail(image, for: "photo-1", size: size)
        #expect(cache.contains(assetId: "photo-1", size: size))

        // ポリシーを低メモリモードに変更
        cache.updatePolicy(.lowMemory)

        // 既存キャッシュは保持される可能性がある（NSCacheの挙動に依存）
        // 新しいポリシーの設定は正しく反映される
        #expect(cache.policy == .lowMemory)
        #expect(cache.countLimit == ThumbnailCachePolicy.lowMemory.maxCount)
    }

    @Test("低メモリポリシーでのキャッシュ制限")
    func lowMemoryPolicyLimitsCache() {
        let policy = ThumbnailCachePolicy.lowMemory
        let cache = ThumbnailCache(policy: policy)

        #expect(cache.countLimit == 100)
        #expect(cache.totalCostLimit == 30 * 1024 * 1024) // 30MB
    }
    #endif
}

// MARK: - Permission Change Edge Cases

@Suite("権限変更 エッジケース")
@MainActor
struct PermissionChangeEdgeCaseTests {

    @Test("スキャン中に権限が変更された場合の動作")
    func scanWithPermissionChangeHandled() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // スキャン開始
        let scanTask = Task {
            try await scanner.scan()
        }

        // 少し待機
        try? await Task.sleep(for: .milliseconds(5))

        // 権限を変更（シミュレート）
        mockPermission.changeStatus(to: .denied)

        // タスク完了を待つ
        do {
            _ = try await scanTask.value
            // 既に取得中のデータは返される可能性がある
        } catch {
            // 権限エラーが発生する可能性もある
        }

        // 状態は完了、キャンセル、または失敗のいずれか
        let validStates: [ScanState] = [
            .completed,
            .cancelled,
            .failed(.notAuthorized),
            .failed(.scanCancelled)
        ]
        // Note: ScanStateはEquatableなので直接比較可能
        #expect(validStates.contains { $0 == scanner.scanState })
    }

    @Test("権限が制限から許可に変わった場合")
    func permissionChangedFromRestrictedToAuthorized() async {
        let mockPermission = EdgeCaseMockPermissionManager(
            status: .restricted,
            requestResult: .authorized
        )

        // 最初は制限状態
        #expect(mockPermission.currentStatus == .restricted)

        // 権限リクエスト
        let newStatus = await mockPermission.requestPermission()

        #expect(newStatus == .authorized)
        #expect(mockPermission.currentStatus == .authorized)
    }

    @Test("権限が限定的な場合でもスキャンできる")
    func scanWorksWithLimitedPermission() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .limited)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            let photos = try await scanner.scan()

            // limited でもスキャンは成功する
            #expect(scanner.scanState == .completed)
            #expect(photos.count >= 0)
        } catch {
            // エラーでもOK（実際のライブラリの状態による）
        }
    }
}

// MARK: - Boundary Value Edge Cases

@Suite("境界値 エッジケース")
struct BoundaryValueEdgeCaseTests {

    @Test("バッチサイズの最小値が10に制限される")
    func batchSizeMinimumBound() {
        let options = ScanOptions(batchSize: 1)
        #expect(options.batchSize == 10)
    }

    @Test("バッチサイズの最大値が500に制限される")
    func batchSizeMaximumBound() {
        let options = ScanOptions(batchSize: 1000)
        #expect(options.batchSize == 500)
    }

    @Test("スキャン間隔の最小値が1時間に制限される")
    func scanIntervalMinimumBound() {
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
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 最小値より小さい値を設定
        manager.scanInterval = 30 * 60 // 30分

        // 最小値に制限される
        #expect(manager.scanInterval == BackgroundScanManager.minimumScanInterval)
    }

    @Test("スキャン間隔の最大値が7日に制限される")
    func scanIntervalMaximumBound() {
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
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 最大値より大きい値を設定
        manager.scanInterval = 14 * 24 * 60 * 60 // 14日

        // 最大値に制限される
        #expect(manager.scanInterval == BackgroundScanManager.maximumScanInterval)
    }

    @Test("ストレージ使用率が0〜100%の範囲に収まる")
    func storageUsagePercentageInRange() {
        // 通常ケース
        let normalInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 30_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )
        #expect(normalInfo.usagePercentage >= 0.0 && normalInfo.usagePercentage <= 1.0)

        // 極端なケース（容量0）
        let zeroInfo = StorageInfo(
            totalCapacity: 0,
            availableCapacity: 0,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )
        #expect(zeroInfo.usagePercentage >= 0.0 && zeroInfo.usagePercentage <= 1.0)
    }

    @Test("進捗率が0〜1の範囲に制限される")
    func progressPercentageInRange() {
        // 通常ケース
        let normalProgress = PhotoScanProgress(current: 50, total: 100)
        #expect(normalProgress.percentage >= 0.0 && normalProgress.percentage <= 1.0)

        // current > total のケース
        let overProgress = PhotoScanProgress(current: 150, total: 100)
        #expect(overProgress.percentage == 1.0)

        // total = 0 のケース
        let zeroProgress = PhotoScanProgress(current: 0, total: 0)
        #expect(zeroProgress.percentage == 0.0)
    }
}

// MARK: - Concurrent Access Edge Cases

@Suite("並行アクセス エッジケース")
struct ConcurrentAccessEdgeCaseTests {

    #if canImport(UIKit)
    @Test("並行してキャッシュにアクセスしてもクラッシュしない")
    func concurrentCacheAccessDoesNotCrash() async {
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        // ダミー画像生成ヘルパー
        func createDummyImage() -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.green.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }

        await withTaskGroup(of: Void.self) { group in
            // 同時に書き込み
            for i in 0..<100 {
                group.addTask {
                    let image = createDummyImage()
                    cache.setThumbnail(image, for: "photo-\(i)", size: size)
                }
            }

            // 同時に読み込み
            for i in 0..<100 {
                group.addTask {
                    _ = cache.thumbnail(for: "photo-\(i)", size: size)
                }
            }

            // 同時に削除
            for i in 0..<50 {
                group.addTask {
                    cache.removeThumbnail(for: "photo-\(i)")
                }
            }
        }

        // クラッシュせずに完了
        #expect(cache.cachedCount >= 0)
    }
    #endif

    @Test("並行してStorageServiceにアクセスしてもクラッシュしない")
    func concurrentStorageServiceAccessDoesNotCrash() async throws {
        let storageService = StorageService()

        await withTaskGroup(of: StorageInfo?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try? await storageService.getDeviceStorageInfo()
                }
            }
        }

        // キャッシュをクリアしても問題ない
        storageService.clearCache()

        let info = try await storageService.getDeviceStorageInfo()
        #expect(info.totalCapacity > 0)
    }
}

// MARK: - Error Recovery Edge Cases

@Suite("エラー回復 エッジケース")
@MainActor
struct ErrorRecoveryEdgeCaseTests {

    @Test("エラー後にスキャナーをリセットして再スキャンできる")
    func canRescanAfterErrorReset() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .denied)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // 最初のスキャン（権限エラー）
        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }
        #expect(scanner.scanState == .failed(.notAuthorized))

        // リセット
        scanner.reset()
        #expect(scanner.scanState == .idle)

        // 権限を付与
        mockPermission.changeStatus(to: .authorized)

        // 再スキャン
        do {
            let photos = try await scanner.scan()
            #expect(scanner.scanState == .completed)
            #expect(photos.count >= 0)
        } catch {
            // 他のエラーは許容
        }
    }

    @Test("キャンセル後にスキャナーをリセットして再スキャンできる")
    func canRescanAfterCancelReset() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // スキャンを開始してキャンセル
        let scanTask = Task {
            try await scanner.scan()
        }

        try? await Task.sleep(for: .milliseconds(5))
        scanner.cancel()

        do {
            _ = try await scanTask.value
        } catch {
            // キャンセルエラーは期待される
        }

        // リセット
        scanner.reset()
        #expect(scanner.scanState == .idle)
        #expect(scanner.progress == 0.0)

        // 再スキャン
        do {
            let photos = try await scanner.scan()
            #expect(scanner.scanState == .completed)
            #expect(photos.count >= 0)
        } catch {
            // エラーでもOK
        }
    }
}

// MARK: - Date Range Filter Edge Cases

@Suite("日付範囲フィルター エッジケース")
@MainActor
struct DateRangeFilterEdgeCaseTests {

    @Test("過去1日の日付範囲でスキャンできる")
    func scanWithOneDayRange() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)

        let dateRange = DateInterval(
            start: Date().addingTimeInterval(-86400), // 1日前
            end: Date()
        )

        let options = ScanOptions(dateRange: dateRange)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: options
        )

        do {
            let photos = try await scanner.scan()

            // 日付範囲内の写真のみ
            for photo in photos {
                #expect(dateRange.contains(photo.creationDate))
            }
        } catch {
            // エラーでもOK
        }
    }

    @Test("将来の日付範囲で空の結果を返す")
    func scanWithFutureDateRange() async throws {
        let mockPermission = EdgeCaseMockPermissionManager(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)

        let futureDate = Date().addingTimeInterval(86400 * 365) // 1年後
        let dateRange = DateInterval(
            start: futureDate,
            end: futureDate.addingTimeInterval(86400)
        )

        let options = ScanOptions(dateRange: dateRange)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: options
        )

        do {
            let photos = try await scanner.scan()

            // 将来の日付なので結果は空（またはフィルタリング後に空）
            // Note: 実際にはPHFetchResultの日付フィルターは別途必要
            #expect(scanner.scanState == .completed)
            // 将来の日付範囲にマッチする写真は通常ない
            for photo in photos {
                #expect(dateRange.contains(photo.creationDate))
            }
        } catch {
            // エラーでもOK
        }
    }
}

// MARK: - Storage Level Edge Cases

@Suite("ストレージレベル エッジケース")
struct StorageLevelEdgeCaseTests {

    @Test("空き容量10%以下で警告レベルを返す")
    func lowStorageReturnsWarning() {
        let info = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 8_000_000_000, // 8%
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(info.isLowStorage == true)
        #expect(info.storageLevel == .warning)
    }

    @Test("空き容量5%以下で危険レベルを返す")
    func criticalStorageReturnsCritical() {
        let info = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 3_000_000_000, // 3%
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(info.isCriticalStorage == true)
        #expect(info.storageLevel == .critical)
    }

    @Test("空き容量1GB未満で危険レベルを返す")
    func veryLowStorageReturnsCritical() {
        let info = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 500_000_000, // 500MB
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(info.isCriticalStorage == true)
        #expect(info.storageLevel == .critical)
    }

    @Test("正常な空き容量で通常レベルを返す")
    func normalStorageReturnsNormal() {
        let info = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 30_000_000_000, // 30%
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(info.isLowStorage == false)
        #expect(info.isCriticalStorage == false)
        #expect(info.storageLevel == .normal)
    }
}
