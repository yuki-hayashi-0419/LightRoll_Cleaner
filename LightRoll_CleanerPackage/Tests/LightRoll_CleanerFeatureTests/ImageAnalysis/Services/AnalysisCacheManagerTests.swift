//
//  AnalysisCacheManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AnalysisCacheManager のテスト
//  キャッシュの保存・読み込み・削除・クリア機能を検証
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - AnalysisCacheManager Tests

@Suite("AnalysisCacheManager Tests")
struct AnalysisCacheManagerTests {

    // MARK: - 基本機能テスト

    @Test("保存と読み込みが正しく動作すること")
    func testSaveAndLoad() async throws {
        // Given: テスト用のUserDefaultsとマネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.saveLoad")!
        userDefaults.removePersistentDomain(forName: "test.cache.saveLoad")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        let result = PhotoAnalysisResult(
            photoId: "test-photo-1",
            qualityScore: 0.85,
            blurScore: 0.2,
            faceCount: 2
        )

        // When: 結果を保存
        await manager.saveResult(result)

        // Then: 読み込みが成功すること
        let loaded = await manager.loadResult(for: "test-photo-1")
        #expect(loaded != nil)
        #expect(loaded?.photoId == "test-photo-1")
        #expect(loaded?.qualityScore == 0.85)
        #expect(loaded?.blurScore == 0.2)
        #expect(loaded?.faceCount == 2)
    }

    @Test("存在しないIDの読み込みはnilを返すこと")
    func testLoadNonExistent() async throws {
        // Given: 空のマネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.nonExistent")!
        userDefaults.removePersistentDomain(forName: "test.cache.nonExistent")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 存在しないIDを読み込み
        let loaded = await manager.loadResult(for: "non-existent")

        // Then: nilが返ること
        #expect(loaded == nil)
    }

    @Test("削除が正しく動作すること")
    func testRemoveResult() async throws {
        // Given: 保存済みの結果
        let userDefaults = UserDefaults(suiteName: "test.cache.remove")!
        userDefaults.removePersistentDomain(forName: "test.cache.remove")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        let result = PhotoAnalysisResult(photoId: "test-photo-2", qualityScore: 0.75)
        await manager.saveResult(result)

        // When: 削除を実行
        await manager.removeResult(for: "test-photo-2")

        // Then: 読み込みがnilを返すこと
        let loaded = await manager.loadResult(for: "test-photo-2")
        #expect(loaded == nil)
    }

    @Test("全クリアが正しく動作すること")
    func testClearCache() async throws {
        // Given: 複数の結果を保存
        let userDefaults = UserDefaults(suiteName: "test.cache.clear")!
        userDefaults.removePersistentDomain(forName: "test.cache.clear")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-1", qualityScore: 0.8))
        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-2", qualityScore: 0.7))
        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-3", qualityScore: 0.6))

        // When: 全クリアを実行
        await manager.clearCache()

        // Then: すべての読み込みがnilを返すこと
        let loaded1 = await manager.loadResult(for: "photo-1")
        let loaded2 = await manager.loadResult(for: "photo-2")
        let loaded3 = await manager.loadResult(for: "photo-3")

        #expect(loaded1 == nil)
        #expect(loaded2 == nil)
        #expect(loaded3 == nil)

        // キャッシュサイズが0になること
        let size = await manager.getCacheSize()
        #expect(size == 0)
    }

    // MARK: - キャッシュサイズテスト

    @Test("キャッシュサイズが正しく計算されること")
    func testCacheSize() async throws {
        // Given: 空のマネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.size")!
        userDefaults.removePersistentDomain(forName: "test.cache.size")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 結果を段階的に追加
        var size = await manager.getCacheSize()
        #expect(size == 0)

        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-1", qualityScore: 0.8))
        size = await manager.getCacheSize()
        #expect(size == 1)

        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-2", qualityScore: 0.7))
        size = await manager.getCacheSize()
        #expect(size == 2)

        await manager.saveResult(PhotoAnalysisResult(photoId: "photo-3", qualityScore: 0.6))
        size = await manager.getCacheSize()
        #expect(size == 3)
    }

    // MARK: - 古いキャッシュ削除テスト

    @Test("古いキャッシュが削除されること")
    func testRemoveOldCache() async throws {
        // Given: 古い結果と新しい結果を保存
        let userDefaults = UserDefaults(suiteName: "test.cache.old")!
        userDefaults.removePersistentDomain(forName: "test.cache.old")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // 8日前の結果
        let oldResult = PhotoAnalysisResult(
            photoId: "old-photo",
            analyzedAt: Date().addingTimeInterval(-8 * 24 * 60 * 60),
            qualityScore: 0.8
        )

        // 1日前の結果
        let recentResult = PhotoAnalysisResult(
            photoId: "recent-photo",
            analyzedAt: Date().addingTimeInterval(-1 * 24 * 60 * 60),
            qualityScore: 0.9
        )

        await manager.saveResult(oldResult)
        await manager.saveResult(recentResult)

        // When: 7日より古いキャッシュを削除
        await manager.removeOldCache(olderThan: 7)

        // Then: 古い結果は削除され、新しい結果は残ること
        let loadedOld = await manager.loadResult(for: "old-photo")
        let loadedRecent = await manager.loadResult(for: "recent-photo")

        #expect(loadedOld == nil)
        #expect(loadedRecent != nil)
    }

    // MARK: - 複数結果の保存と読み込みテスト

    @Test("複数結果の保存と読み込みが正しく動作すること")
    func testMultipleResults() async throws {
        // Given: マネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.multiple")!
        userDefaults.removePersistentDomain(forName: "test.cache.multiple")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 複数の結果を保存
        let results = [
            PhotoAnalysisResult(photoId: "photo-1", qualityScore: 0.9, blurScore: 0.1),
            PhotoAnalysisResult(photoId: "photo-2", qualityScore: 0.8, blurScore: 0.2),
            PhotoAnalysisResult(photoId: "photo-3", qualityScore: 0.7, blurScore: 0.3),
            PhotoAnalysisResult(photoId: "photo-4", qualityScore: 0.6, blurScore: 0.4),
            PhotoAnalysisResult(photoId: "photo-5", qualityScore: 0.5, blurScore: 0.5)
        ]

        for result in results {
            await manager.saveResult(result)
        }

        // Then: すべての結果が正しく読み込めること
        for result in results {
            let loaded = await manager.loadResult(for: result.photoId)
            #expect(loaded != nil)
            #expect(loaded?.photoId == result.photoId)
            #expect(loaded?.qualityScore == result.qualityScore)
            #expect(loaded?.blurScore == result.blurScore)
        }
    }

    // MARK: - バッチ保存テスト（緊急パッチ）

    @Test("バッチ保存が正しく動作すること")
    func testBatchSave() async throws {
        // Given: マネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.batch")!
        userDefaults.removePersistentDomain(forName: "test.cache.batch")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 100件の結果をバッチ保存
        let results = (1...100).map { index in
            PhotoAnalysisResult(
                photoId: "batch-photo-\(index)",
                qualityScore: Float(index) / 100.0
            )
        }

        await manager.saveResults(results)

        // Then: すべての結果が正しく読み込めること
        for result in results {
            let loaded = await manager.loadResult(for: result.photoId)
            #expect(loaded != nil)
            #expect(loaded?.photoId == result.photoId)
            #expect(loaded?.qualityScore == result.qualityScore)
        }

        // キャッシュサイズが100であること
        let size = await manager.getCacheSize()
        #expect(size == 100)
    }

    @Test("バッチ保存と個別保存の結果が同じであること")
    func testBatchVsIndividualSave() async throws {
        // Given: 2つのマネージャー
        let userDefaultsBatch = UserDefaults(suiteName: "test.cache.batchCompare1")!
        userDefaultsBatch.removePersistentDomain(forName: "test.cache.batchCompare1")
        let managerBatch = AnalysisCacheManager(userDefaults: userDefaultsBatch)

        let userDefaultsIndividual = UserDefaults(suiteName: "test.cache.batchCompare2")!
        userDefaultsIndividual.removePersistentDomain(forName: "test.cache.batchCompare2")
        let managerIndividual = AnalysisCacheManager(userDefaults: userDefaultsIndividual)

        // When: 同じデータをバッチ保存と個別保存
        let results = (1...50).map { index in
            PhotoAnalysisResult(
                photoId: "compare-photo-\(index)",
                qualityScore: Float(index) / 50.0,
                blurScore: Float(index % 10) / 10.0
            )
        }

        // バッチ保存
        await managerBatch.saveResults(results)

        // 個別保存
        for result in results {
            await managerIndividual.saveResult(result)
        }

        // Then: 両方のキャッシュが同じ内容であること
        for result in results {
            let loadedBatch = await managerBatch.loadResult(for: result.photoId)
            let loadedIndividual = await managerIndividual.loadResult(for: result.photoId)

            #expect(loadedBatch?.photoId == loadedIndividual?.photoId)
            #expect(loadedBatch?.qualityScore == loadedIndividual?.qualityScore)
            #expect(loadedBatch?.blurScore == loadedIndividual?.blurScore)
        }

        let sizeBatch = await managerBatch.getCacheSize()
        let sizeIndividual = await managerIndividual.getCacheSize()
        #expect(sizeBatch == sizeIndividual)
        #expect(sizeBatch == 50)
    }

    @Test("空配列のバッチ保存が問題なく動作すること")
    func testEmptyBatchSave() async throws {
        // Given: マネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.emptyBatch")!
        userDefaults.removePersistentDomain(forName: "test.cache.emptyBatch")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 空配列をバッチ保存
        await manager.saveResults([])

        // Then: キャッシュサイズが0であること
        let size = await manager.getCacheSize()
        #expect(size == 0)
    }

    // MARK: - 上書き保存テスト

    @Test("同じIDで再保存すると上書きされること")
    func testOverwriteSave() async throws {
        // Given: 保存済みの結果
        let userDefaults = UserDefaults(suiteName: "test.cache.overwrite")!
        userDefaults.removePersistentDomain(forName: "test.cache.overwrite")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        let originalResult = PhotoAnalysisResult(photoId: "photo-1", qualityScore: 0.5)
        await manager.saveResult(originalResult)

        // When: 同じIDで異なる結果を保存
        let newResult = PhotoAnalysisResult(photoId: "photo-1", qualityScore: 0.9)
        await manager.saveResult(newResult)

        // Then: 新しい結果が読み込まれること
        let loaded = await manager.loadResult(for: "photo-1")
        #expect(loaded?.qualityScore == 0.9)

        // キャッシュサイズは1のままであること
        let size = await manager.getCacheSize()
        #expect(size == 1)
    }

    // MARK: - エッジケーステスト

    @Test("空のphotoIdでも動作すること")
    func testEmptyPhotoId() async throws {
        // Given: マネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.empty")!
        userDefaults.removePersistentDomain(forName: "test.cache.empty")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 空のIDで保存
        let result = PhotoAnalysisResult(photoId: "", qualityScore: 0.5)
        await manager.saveResult(result)

        // Then: 読み込みが成功すること
        let loaded = await manager.loadResult(for: "")
        #expect(loaded != nil)
        #expect(loaded?.photoId == "")
    }

    @Test("特殊文字を含むphotoIdでも動作すること")
    func testSpecialCharacters() async throws {
        // Given: マネージャー
        let userDefaults = UserDefaults(suiteName: "test.cache.special")!
        userDefaults.removePersistentDomain(forName: "test.cache.special")
        let manager = AnalysisCacheManager(userDefaults: userDefaults)

        // When: 特殊文字を含むIDで保存
        let specialId = "photo/test:123?query=value&foo=bar"
        let result = PhotoAnalysisResult(photoId: specialId, qualityScore: 0.8)
        await manager.saveResult(result)

        // Then: 読み込みが成功すること
        let loaded = await manager.loadResult(for: specialId)
        #expect(loaded != nil)
        #expect(loaded?.photoId == specialId)
    }
}
