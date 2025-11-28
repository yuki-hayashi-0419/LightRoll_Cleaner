//
//  ThumbnailCacheTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ThumbnailCacheのユニットテスト
//  キャッシュの基本動作、メモリ管理、統計機能をテスト
//  Created by AI Assistant
//

import Testing
import Foundation

#if canImport(UIKit)
import UIKit
#endif

@testable import LightRoll_CleanerFeature

// MARK: - ThumbnailCacheTests

@Suite("ThumbnailCache Tests")
struct ThumbnailCacheTests {

    // MARK: - Test Helpers

    #if canImport(UIKit)
    /// テスト用のダミー画像を生成
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// テスト用のアセットIDを生成
    private func createTestAssetId(index: Int = 0) -> String {
        "test-asset-\(index)"
    }
    #endif

    // MARK: - Initialization Tests

    @Test("デフォルト初期化が正しく動作する")
    func testDefaultInitialization() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()

        #expect(cache.cachedCount == 0)
        #expect(cache.estimatedMemoryUsage == 0)
        #expect(cache.countLimit == ThumbnailCachePolicy.default.maxCount)
        #expect(cache.totalCostLimit == ThumbnailCachePolicy.default.maxMemoryBytes)
        #endif
    }

    @Test("ポリシー指定初期化が正しく動作する")
    func testPolicyInitialization() {
        #if canImport(UIKit)
        let policy = ThumbnailCachePolicy.lowMemory
        let cache = ThumbnailCache(policy: policy)

        #expect(cache.countLimit == policy.maxCount)
        #expect(cache.totalCostLimit == policy.maxMemoryBytes)
        #expect(cache.policy == policy)
        #endif
    }

    // MARK: - Basic Cache Operations Tests

    @Test("サムネイルの保存と取得が正しく動作する")
    func testSetAndGetThumbnail() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let testImage = createTestImage()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)

        // 保存
        cache.setThumbnail(testImage, for: assetId, size: size)

        // 取得
        let retrieved = cache.thumbnail(for: assetId, size: size)

        #expect(retrieved != nil)
        #expect(cache.cachedCount >= 1)
        #endif
    }

    @Test("存在しないキーへのアクセスはnilを返す")
    func testGetNonExistentThumbnail() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        let result = cache.thumbnail(for: "non-existent-id", size: size)

        #expect(result == nil)
        #endif
    }

    @Test("同一アセットの異なるサイズは別々にキャッシュされる")
    func testDifferentSizesForSameAsset() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()

        let smallImage = createTestImage(size: CGSize(width: 50, height: 50))
        let largeImage = createTestImage(size: CGSize(width: 200, height: 200))

        let smallSize = CGSize(width: 50, height: 50)
        let largeSize = CGSize(width: 200, height: 200)

        // 異なるサイズで保存
        cache.setThumbnail(smallImage, for: assetId, size: smallSize)
        cache.setThumbnail(largeImage, for: assetId, size: largeSize)

        // それぞれ取得可能
        let retrievedSmall = cache.thumbnail(for: assetId, size: smallSize)
        let retrievedLarge = cache.thumbnail(for: assetId, size: largeSize)

        #expect(retrievedSmall != nil)
        #expect(retrievedLarge != nil)
        #expect(cache.cachedCount >= 2)
        #endif
    }

    // MARK: - Cache Key Tests

    @Test("キャッシュキー生成が正しく動作する")
    func testCacheKeyGeneration() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = "test-asset-123"
        let size = CGSize(width: 100, height: 150)

        let key = cache.cacheKey(for: assetId, size: size)

        #expect(key == "test-asset-123_100x150")
        #endif
    }

    @Test("異なるサイズは異なるキーを生成する")
    func testDifferentSizesProduceDifferentKeys() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = "test-asset"

        let key1 = cache.cacheKey(for: assetId, size: CGSize(width: 100, height: 100))
        let key2 = cache.cacheKey(for: assetId, size: CGSize(width: 200, height: 200))

        #expect(key1 != key2)
        #endif
    }

    // MARK: - Cache Removal Tests

    @Test("全キャッシュクリアが正しく動作する")
    func testRemoveAll() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        // 複数のサムネイルを追加
        for i in 0..<10 {
            let image = createTestImage()
            cache.setThumbnail(image, for: createTestAssetId(index: i), size: size)
        }

        #expect(cache.cachedCount >= 1)

        // クリア
        cache.removeAll()

        #expect(cache.cachedCount == 0)
        #expect(cache.estimatedMemoryUsage == 0)
        #endif
    }

    @Test("個別アセットの削除が正しく動作する")
    func testRemoveThumbnailForAsset() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId1 = createTestAssetId(index: 1)
        let assetId2 = createTestAssetId(index: 2)
        let size = ThumbnailRequestOptions.mediumSize

        // 2つのサムネイルを追加
        cache.setThumbnail(createTestImage(), for: assetId1, size: size)
        cache.setThumbnail(createTestImage(), for: assetId2, size: size)

        // 1つを削除
        cache.removeThumbnail(for: assetId1)

        // assetId1は取得できないが、assetId2は取得可能
        #expect(cache.thumbnail(for: assetId1, size: size) == nil)
        #expect(cache.thumbnail(for: assetId2, size: size) != nil)
        #endif
    }

    @Test("複数アセットの一括削除が正しく動作する")
    func testRemoveMultipleThumbnails() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = ThumbnailRequestOptions.mediumSize

        let assetIds = (0..<5).map { createTestAssetId(index: $0) }

        // 全て追加
        for assetId in assetIds {
            cache.setThumbnail(createTestImage(), for: assetId, size: size)
        }

        // 最初の3つを削除
        let idsToRemove = Array(assetIds.prefix(3))
        cache.removeThumbnails(for: idsToRemove)

        // 削除されたものは取得できない
        for assetId in idsToRemove {
            #expect(cache.thumbnail(for: assetId, size: size) == nil)
        }

        // 残りは取得可能
        for assetId in assetIds.suffix(2) {
            #expect(cache.thumbnail(for: assetId, size: size) != nil)
        }
        #endif
    }

    @Test("特定サイズのサムネイル削除が正しく動作する")
    func testRemoveThumbnailForSpecificSize() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let smallSize = ThumbnailRequestOptions.smallSize
        let largeSize = ThumbnailRequestOptions.largeSize

        // 異なるサイズで追加
        cache.setThumbnail(createTestImage(), for: assetId, size: smallSize)
        cache.setThumbnail(createTestImage(), for: assetId, size: largeSize)

        // 小さいサイズだけ削除
        cache.removeThumbnail(for: assetId, size: smallSize)

        #expect(cache.thumbnail(for: assetId, size: smallSize) == nil)
        #expect(cache.thumbnail(for: assetId, size: largeSize) != nil)
        #endif
    }

    // MARK: - Contains Tests

    @Test("contains メソッドが正しく動作する")
    func testContains() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)

        #expect(cache.contains(assetId: assetId, size: size) == false)

        cache.setThumbnail(createTestImage(), for: assetId, size: size)

        #expect(cache.contains(assetId: assetId, size: size) == true)
        #endif
    }

    // MARK: - Statistics Tests

    @Test("統計情報が正しく記録される")
    func testStatistics() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)

        // 初期状態
        var stats = cache.statistics()
        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)

        // ミス（キャッシュなし）
        _ = cache.thumbnail(for: assetId, size: size)
        stats = cache.statistics()
        #expect(stats.missCount == 1)

        // 保存
        cache.setThumbnail(createTestImage(), for: assetId, size: size)

        // ヒット
        _ = cache.thumbnail(for: assetId, size: size)
        stats = cache.statistics()
        #expect(stats.hitCount == 1)
        #expect(stats.missCount == 1)
        #endif
    }

    @Test("ヒット率が正しく計算される")
    func testHitRate() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)

        // 保存
        cache.setThumbnail(createTestImage(), for: assetId, size: size)

        // 3回ヒット
        _ = cache.thumbnail(for: assetId, size: size)
        _ = cache.thumbnail(for: assetId, size: size)
        _ = cache.thumbnail(for: assetId, size: size)

        // 1回ミス
        _ = cache.thumbnail(for: "non-existent", size: size)

        let stats = cache.statistics()
        // ヒット率 = 3 / (3 + 1) = 0.75
        #expect(stats.hitRate == 0.75)
        #endif
    }

    @Test("統計リセットが正しく動作する")
    func testResetStatistics() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)

        cache.setThumbnail(createTestImage(), for: assetId, size: size)
        _ = cache.thumbnail(for: assetId, size: size)
        _ = cache.thumbnail(for: "non-existent", size: size)

        var stats = cache.statistics()
        #expect(stats.hitCount > 0 || stats.missCount > 0)

        cache.resetStatistics()

        stats = cache.statistics()
        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)
        #endif
    }

    // MARK: - Policy Tests

    @Test("ポリシー更新が正しく動作する")
    func testUpdatePolicy() {
        #if canImport(UIKit)
        let cache = ThumbnailCache(policy: .default)

        #expect(cache.policy == .default)

        cache.updatePolicy(.lowMemory)

        #expect(cache.policy == .lowMemory)
        #expect(cache.countLimit == ThumbnailCachePolicy.lowMemory.maxCount)
        #expect(cache.totalCostLimit == ThumbnailCachePolicy.lowMemory.maxMemoryBytes)
        #endif
    }

    @Test("カウントリミットの変更が正しく反映される")
    func testCountLimitChange() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let newLimit = 50

        cache.countLimit = newLimit

        #expect(cache.countLimit == newLimit)
        #endif
    }

    @Test("コストリミットの変更が正しく反映される")
    func testTotalCostLimitChange() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let newLimit = 50 * 1024 * 1024  // 50MB

        cache.totalCostLimit = newLimit

        #expect(cache.totalCostLimit == newLimit)
        #endif
    }

    // MARK: - Memory Warning Tests

    @Test("メモリ警告処理が正しく動作する")
    func testHandleMemoryWarning() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        // 複数のサムネイルを追加
        for i in 0..<20 {
            cache.setThumbnail(createTestImage(), for: createTestAssetId(index: i), size: size)
        }

        let countBefore = cache.cachedCount

        // メモリ警告を処理
        cache.handleMemoryWarning()

        // 統計がリセットされる
        let stats = cache.statistics()
        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)

        // 注：NSCacheの自動削除動作は非同期なので、
        // カウントの即時減少は保証されない
        _ = countBefore  // 未使用警告を抑制
        #endif
    }

    // MARK: - Async Convenience Methods Tests

    @Test("ローダー付きサムネイル取得が正しく動作する")
    func testThumbnailWithLoader() async throws {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let assetId = createTestAssetId()
        let size = CGSize(width: 100, height: 100)
        var loaderCallCount = 0

        let image = try await cache.thumbnail(for: assetId, size: size) {
            loaderCallCount += 1
            return self.createTestImage()
        }

        #expect(image != nil)
        #expect(loaderCallCount == 1)

        // 2回目はキャッシュから取得（ローダーは呼ばれない）
        let cachedImage = try await cache.thumbnail(for: assetId, size: size) {
            loaderCallCount += 1
            return self.createTestImage()
        }

        #expect(cachedImage != nil)
        #expect(loaderCallCount == 1)  // 変化なし
        #endif
    }

    @Test("プリロードが正しく動作する")
    func testPreload() async {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)
        let assetIds = (0..<5).map { createTestAssetId(index: $0) }

        await cache.preload(assetIds: assetIds, size: size) { [self] _ in
            return self.createTestImage()
        }

        // 全てキャッシュされている
        for assetId in assetIds {
            #expect(cache.contains(assetId: assetId, size: size))
        }
        #endif
    }

    @Test("既存キャッシュはプリロードでスキップされる")
    func testPreloadSkipsExisting() async {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)
        let assetId = createTestAssetId()
        var loaderCallCount = 0

        // 事前にキャッシュ
        cache.setThumbnail(createTestImage(), for: assetId, size: size)

        await cache.preload(assetIds: [assetId], size: size) { _ in
            loaderCallCount += 1
            return self.createTestImage()
        }

        // ローダーは呼ばれない
        #expect(loaderCallCount == 0)
        #endif
    }

    // MARK: - ThumbnailCachePolicy Tests

    @Test("ThumbnailCachePolicy のデフォルト値が正しい")
    func testDefaultPolicy() {
        #if canImport(UIKit)
        let policy = ThumbnailCachePolicy.default

        #expect(policy.maxCount == 500)
        #expect(policy.maxMemoryMB == 100)
        #expect(policy.evictionPolicy == .leastRecentlyUsed)
        #expect(policy.maxMemoryBytes == 100 * 1024 * 1024)
        #endif
    }

    @Test("ThumbnailCachePolicy の低メモリ設定が正しい")
    func testLowMemoryPolicy() {
        #if canImport(UIKit)
        let policy = ThumbnailCachePolicy.lowMemory

        #expect(policy.maxCount == 100)
        #expect(policy.maxMemoryMB == 30)
        #expect(policy.evictionPolicy == .sizeFirst)
        #endif
    }

    @Test("ThumbnailCachePolicy の高パフォーマンス設定が正しい")
    func testHighPerformancePolicy() {
        #if canImport(UIKit)
        let policy = ThumbnailCachePolicy.highPerformance

        #expect(policy.maxCount == 1000)
        #expect(policy.maxMemoryMB == 200)
        #expect(policy.evictionPolicy == .leastRecentlyUsed)
        #endif
    }

    @Test("ThumbnailCachePolicy のカスタム初期化が正しい")
    func testCustomPolicyInitialization() {
        #if canImport(UIKit)
        let policy = ThumbnailCachePolicy(
            maxCount: 250,
            maxMemoryMB: 50,
            evictionPolicy: .leastFrequentlyUsed
        )

        #expect(policy.maxCount == 250)
        #expect(policy.maxMemoryMB == 50)
        #expect(policy.evictionPolicy == .leastFrequentlyUsed)
        #endif
    }

    // MARK: - ThumbnailCacheStatistics Tests

    @Test("ThumbnailCacheStatistics の空の状態が正しい")
    func testEmptyStatistics() {
        #if canImport(UIKit)
        let stats = ThumbnailCacheStatistics.empty

        #expect(stats.hitCount == 0)
        #expect(stats.missCount == 0)
        #expect(stats.currentCount == 0)
        #expect(stats.estimatedMemoryUsage == 0)
        #expect(stats.hitRate == 0.0)
        #expect(stats.estimatedMemoryUsageMB == 0.0)
        #endif
    }

    @Test("ThumbnailCacheStatistics のメモリ使用量計算が正しい")
    func testStatisticsMemoryUsage() {
        #if canImport(UIKit)
        let stats = ThumbnailCacheStatistics(
            hitCount: 10,
            missCount: 5,
            currentCount: 100,
            estimatedMemoryUsage: 10 * 1024 * 1024  // 10MB
        )

        #expect(stats.estimatedMemoryUsageMB == 10.0)
        #endif
    }

    // MARK: - Description Tests

    @Test("キャッシュの説明文字列が正しく生成される")
    func testCacheDescription() {
        #if canImport(UIKit)
        let cache = ThumbnailCache()

        let description = cache.description

        #expect(description.contains("ThumbnailCache"))
        #expect(description.contains("count:"))
        #expect(description.contains("memory:"))
        #expect(description.contains("hitRate:"))
        #endif
    }

    // MARK: - Thread Safety Tests

    @Test("並行アクセスが安全に動作する")
    func testConcurrentAccess() async {
        #if canImport(UIKit)
        let cache = ThumbnailCache()
        let size = CGSize(width: 100, height: 100)

        await withTaskGroup(of: Void.self) { group in
            // 同時に書き込み
            for i in 0..<100 {
                group.addTask {
                    let image = self.createTestImage()
                    cache.setThumbnail(image, for: self.createTestAssetId(index: i), size: size)
                }
            }

            // 同時に読み込み
            for i in 0..<100 {
                group.addTask {
                    _ = cache.thumbnail(for: self.createTestAssetId(index: i), size: size)
                }
            }
        }

        // クラッシュせずに完了すればOK
        #expect(cache.cachedCount >= 0)
        #endif
    }

    // MARK: - Shared Instance Tests

    @Test("共有インスタンスが正しく動作する")
    func testSharedInstance() {
        #if canImport(UIKit)
        let shared1 = ThumbnailCache.shared
        let shared2 = ThumbnailCache.shared

        // 同一インスタンス
        #expect(shared1 === shared2)
        #endif
    }
}
