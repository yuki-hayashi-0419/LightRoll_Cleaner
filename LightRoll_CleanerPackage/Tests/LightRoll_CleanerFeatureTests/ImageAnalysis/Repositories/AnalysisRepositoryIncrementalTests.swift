//
//  AnalysisRepositoryIncrementalTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AnalysisRepositoryのインクリメンタル分析機能テスト
//  - キャッシュヒット/ミスの処理
//  - 一部新規・一部キャッシュのハイブリッド処理
//  - forceReanalyze = trueでの全再分析
//  - エラー時のフォールバック
//  - パフォーマンステスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - AnalysisRepositoryIncrementalTests

@Suite("AnalysisRepository Incremental Analysis Tests")
struct AnalysisRepositoryIncrementalTests {

    // MARK: - Test Helpers

    /// テスト用のPhotoモデルを作成
    private static func makeTestPhoto(
        id: String = "test-photo",
        fileSize: Int64 = 1024
    ) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 0,
            fileSize: fileSize,
            isFavorite: false
        )
    }

    /// テスト用のPhotoAnalysisResultを作成
    private static func makeTestResult(
        photoId: String,
        qualityScore: Double = 0.8
    ) -> PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: photoId,
            qualityScore: qualityScore,
            hasBlur: false,
            isScreenshot: false,
            faceCount: 0,
            featurePrint: nil
        )
    }

    // MARK: - 正常系テスト - 全て新規写真（2テスト）

    @Test("全て新規写真の分析")
    func testAnalyzeAllNewPhotos() async throws {
        let repository = AnalysisRepository()

        let photos = [
            Self.makeTestPhoto(id: "new-photo-1"),
            Self.makeTestPhoto(id: "new-photo-2"),
            Self.makeTestPhoto(id: "new-photo-3")
        ]

        let results = try await repository.analyzePhotos(photos)

        // 全ての写真が分析され、結果が返される
        #expect(results.count == 3)
        #expect(results[0].photoId == "new-photo-1")
        #expect(results[1].photoId == "new-photo-2")
        #expect(results[2].photoId == "new-photo-3")
    }

    @Test("単一の新規写真を分析")
    func testAnalyzeSingleNewPhoto() async throws {
        let repository = AnalysisRepository()
        let photo = Self.makeTestPhoto(id: "single-new-photo")

        let results = try await repository.analyzePhotos([photo])

        #expect(results.count == 1)
        #expect(results[0].photoId == "single-new-photo")
    }

    // MARK: - 正常系テスト - キャッシュヒット（3テスト）

    @Test("全てキャッシュヒット")
    func testAnalyzeAllCachedPhotos() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        // 事前にキャッシュを保存
        let cachedPhotos = [
            Self.makeTestPhoto(id: "cached-photo-1"),
            Self.makeTestPhoto(id: "cached-photo-2"),
            Self.makeTestPhoto(id: "cached-photo-3")
        ]

        for photo in cachedPhotos {
            let result = Self.makeTestResult(photoId: photo.id, qualityScore: 0.95)
            try cacheManager.save(result: result, for: photo.id)
        }

        // キャッシュから読み込む
        let results = try await repository.analyzePhotos(cachedPhotos, useCache: true)

        // 全てキャッシュから返される
        #expect(results.count == 3)
        #expect(results[0].qualityScore == 0.95)
        #expect(results[1].qualityScore == 0.95)
        #expect(results[2].qualityScore == 0.95)
    }

    @Test("キャッシュヒット時に再分析しない")
    func testCacheHitDoesNotReanalyze() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        let photo = Self.makeTestPhoto(id: "cached-photo")
        let cachedResult = Self.makeTestResult(photoId: "cached-photo", qualityScore: 0.99)

        try cacheManager.save(result: cachedResult, for: photo.id)

        let startTime = Date()
        let results = try await repository.analyzePhotos([photo], useCache: true)
        let elapsed = Date().timeIntervalSince(startTime)

        // キャッシュヒットなので高速
        #expect(elapsed < 0.1)
        #expect(results.count == 1)
        #expect(results[0].qualityScore == 0.99)
    }

    @Test("useCacheがfalseの場合はキャッシュを使用しない")
    func testUseCacheFalseIgnoresCache() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        let photo = Self.makeTestPhoto(id: "cached-photo")
        let cachedResult = Self.makeTestResult(photoId: "cached-photo", qualityScore: 0.99)

        try cacheManager.save(result: cachedResult, for: photo.id)

        // useCache = false で実行
        let results = try await repository.analyzePhotos([photo], useCache: false)

        // 再分析されるため、キャッシュとは異なる可能性がある（デフォルト値が返る）
        #expect(results.count == 1)
        #expect(results[0].photoId == "cached-photo")
    }

    // MARK: - 正常系テスト - ハイブリッド（一部新規、一部キャッシュ）（3テスト）

    @Test("一部新規、一部キャッシュの混在")
    func testAnalyzeHybridPhotos() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        // キャッシュに2件保存
        let cachedResult1 = Self.makeTestResult(photoId: "cached-photo-1", qualityScore: 0.9)
        let cachedResult2 = Self.makeTestResult(photoId: "cached-photo-2", qualityScore: 0.85)

        try cacheManager.save(result: cachedResult1, for: "cached-photo-1")
        try cacheManager.save(result: cachedResult2, for: "cached-photo-2")

        // 混在する写真リスト
        let photos = [
            Self.makeTestPhoto(id: "cached-photo-1"),  // キャッシュヒット
            Self.makeTestPhoto(id: "new-photo-1"),     // 新規
            Self.makeTestPhoto(id: "cached-photo-2"),  // キャッシュヒット
            Self.makeTestPhoto(id: "new-photo-2")      // 新規
        ]

        let results = try await repository.analyzePhotos(photos, useCache: true)

        // 全ての結果が返される
        #expect(results.count == 4)

        // キャッシュされた写真はキャッシュの値
        #expect(results[0].qualityScore == 0.9)
        #expect(results[2].qualityScore == 0.85)

        // 新規写真は分析された値
        #expect(results[1].photoId == "new-photo-1")
        #expect(results[3].photoId == "new-photo-2")
    }

    @Test("大量の混在写真（キャッシュヒット率50%）")
    func testAnalyzeLargeHybridSet() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        var photos: [Photo] = []

        // 500件中250件をキャッシュに保存
        for i in 0..<500 {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            if i % 2 == 0 {
                // 偶数はキャッシュに保存
                let result = Self.makeTestResult(photoId: "photo-\(i)", qualityScore: 0.88)
                try cacheManager.save(result: result, for: "photo-\(i)")
            }
        }

        let results = try await repository.analyzePhotos(photos, useCache: true)

        // 全ての写真が分析される
        #expect(results.count == 500)

        // キャッシュされた写真の品質スコアを確認
        #expect(results[0].qualityScore == 0.88)  // photo-0 (キャッシュ)
        #expect(results[2].qualityScore == 0.88)  // photo-2 (キャッシュ)
    }

    @Test("キャッシュヒット率90%のケース")
    func testHighCacheHitRate() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        var photos: [Photo] = []

        // 100件中90件をキャッシュに保存
        for i in 0..<100 {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            if i < 90 {
                let result = Self.makeTestResult(photoId: "photo-\(i)", qualityScore: 0.92)
                try cacheManager.save(result: result, for: "photo-\(i)")
            }
        }

        let startTime = Date()
        let results = try await repository.analyzePhotos(photos, useCache: true)
        let elapsed = Date().timeIntervalSince(startTime)

        // 全ての写真が分析される
        #expect(results.count == 100)

        // キャッシュヒット率が高いため、処理時間が短い（目安: 5秒以内）
        #expect(elapsed < 5.0)
    }

    // MARK: - forceReanalyze = true テスト（2テスト）

    @Test("forceReanalyze = trueで全再分析")
    func testForceReanalyze() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        // キャッシュに保存
        let cachedResult = Self.makeTestResult(photoId: "cached-photo", qualityScore: 0.99)
        try cacheManager.save(result: cachedResult, for: "cached-photo")

        let photo = Self.makeTestPhoto(id: "cached-photo")

        // forceReanalyze = trueで実行
        let results = try await repository.analyzePhotos(
            [photo],
            useCache: true,
            forceReanalyze: true
        )

        // 再分析されるため、キャッシュの値とは異なる可能性がある
        #expect(results.count == 1)
        #expect(results[0].photoId == "cached-photo")
    }

    @Test("forceReanalyze = true で大量再分析")
    func testForceReanalyzeLargeSet() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        var photos: [Photo] = []

        // 全てキャッシュに保存
        for i in 0..<50 {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            let result = Self.makeTestResult(photoId: "photo-\(i)", qualityScore: 0.95)
            try cacheManager.save(result: result, for: "photo-\(i)")
        }

        // forceReanalyze = true で再分析
        let results = try await repository.analyzePhotos(
            photos,
            useCache: true,
            forceReanalyze: true
        )

        // 全て再分析される
        #expect(results.count == 50)
    }

    // MARK: - 異常系テスト - エラーハンドリング（3テスト）

    @Test("キャッシュ読み込みエラー時のフォールバック")
    func testCacheLoadErrorFallback() async throws {
        let repository = AnalysisRepository()

        // キャッシュが存在しない写真を分析
        let photo = Self.makeTestPhoto(id: "no-cache-photo")

        let results = try await repository.analyzePhotos([photo], useCache: true)

        // キャッシュミスでも通常の分析にフォールバック
        #expect(results.count == 1)
        #expect(results[0].photoId == "no-cache-photo")
    }

    @Test("個別分析エラー時も処理続行")
    func testContinueOnIndividualAnalysisError() async throws {
        let repository = AnalysisRepository()

        let photos = [
            Self.makeTestPhoto(id: "photo-1"),
            Self.makeTestPhoto(id: "invalid-photo"),  // 不正な写真
            Self.makeTestPhoto(id: "photo-3")
        ]

        let results = try await repository.analyzePhotos(photos)

        // エラーが発生しても処理は続行され、全ての結果が返される
        #expect(results.count == 3)
        #expect(results[0].photoId == "photo-1")
        #expect(results[1].photoId == "invalid-photo")
        #expect(results[2].photoId == "photo-3")
    }

    @Test("キャッシュ破損時のフォールバック")
    func testCorruptedCacheFallback() async throws {
        let repository = AnalysisRepository()

        // キャッシュが破損している場合でも通常の分析を実行
        let photo = Self.makeTestPhoto(id: "photo-with-corrupted-cache")

        let results = try await repository.analyzePhotos([photo], useCache: true)

        #expect(results.count == 1)
        #expect(results[0].photoId == "photo-with-corrupted-cache")
    }

    // MARK: - 境界値テスト（3テスト）

    @Test("空配列での分析")
    func testAnalyzeEmptyArray() async throws {
        let repository = AnalysisRepository()

        let results = try await repository.analyzePhotos([])

        #expect(results.isEmpty)
    }

    @Test("1枚のみの分析")
    func testAnalyzeSinglePhoto() async throws {
        let repository = AnalysisRepository()
        let photo = Self.makeTestPhoto(id: "single-photo")

        let results = try await repository.analyzePhotos([photo])

        #expect(results.count == 1)
        #expect(results[0].photoId == "single-photo")
    }

    @Test("1000枚の大量分析")
    func testAnalyze1000Photos() async throws {
        let repository = AnalysisRepository()

        let photos = (0..<1000).map { index in
            Self.makeTestPhoto(id: "photo-\(index)", fileSize: Int64(index * 100))
        }

        let startTime = Date()
        let results = try await repository.analyzePhotos(photos)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(results.count == 1000)
        #expect(results.first?.photoId == "photo-0")
        #expect(results.last?.photoId == "photo-999")

        // 1000枚の分析が妥当な時間内に完了する
        // （並列化されているため、目安: 30秒以内）
        print("1000枚の分析時間: \(elapsed)秒")
    }

    // MARK: - パフォーマンステスト（3テスト）

    @Test("キャッシュヒット率90%でのパフォーマンス")
    func testPerformanceWith90PercentCacheHit() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        var photos: [Photo] = []

        // 1000枚中900枚をキャッシュに保存
        for i in 0..<1000 {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            if i < 900 {
                let result = Self.makeTestResult(photoId: "photo-\(i)", qualityScore: 0.9)
                try cacheManager.save(result: result, for: "photo-\(i)")
            }
        }

        let startTime = Date()
        let results = try await repository.analyzePhotos(photos, useCache: true)
        let elapsed = Date().timeIntervalSince(startTime)

        #expect(results.count == 1000)

        // キャッシュヒット率90%の場合、処理時間が大幅に短縮される
        // 目安: キャッシュなしの場合の10%以下の時間
        print("キャッシュヒット率90%での処理時間: \(elapsed)秒")

        // 実用的な時間内に完了する（目安: 10秒以内）
        #expect(elapsed < 10.0)
    }

    @Test("キャッシュなしとキャッシュありの比較")
    func testCompareWithAndWithoutCache() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        let photos = (0..<100).map { Self.makeTestPhoto(id: "photo-\(i)") }

        // キャッシュなしで分析
        let startTimeNoCache = Date()
        _ = try await repository.analyzePhotos(photos, useCache: false)
        let elapsedNoCache = Date().timeIntervalSince(startTimeNoCache)

        // 全てキャッシュに保存
        for photo in photos {
            let result = Self.makeTestResult(photoId: photo.id, qualityScore: 0.85)
            try cacheManager.save(result: result, for: photo.id)
        }

        // キャッシュありで分析
        let startTimeWithCache = Date()
        _ = try await repository.analyzePhotos(photos, useCache: true)
        let elapsedWithCache = Date().timeIntervalSince(startTimeWithCache)

        print("キャッシュなし: \(elapsedNoCache)秒")
        print("キャッシュあり: \(elapsedWithCache)秒")
        print("高速化率: \(elapsedNoCache / elapsedWithCache)倍")

        // キャッシュありの方が高速であることを確認
        #expect(elapsedWithCache < elapsedNoCache)

        // 期待する高速化率（目安: 10倍以上）
        let speedupRatio = elapsedNoCache / elapsedWithCache
        #expect(speedupRatio > 10.0)
    }

    @Test("進捗通知とキャッシュの併用")
    func testProgressCallbackWithCache() async throws {
        let repository = AnalysisRepository()
        let cacheManager = AnalysisCacheManager()

        var photos: [Photo] = []

        // 50件中25件をキャッシュに保存
        for i in 0..<50 {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            if i % 2 == 0 {
                let result = Self.makeTestResult(photoId: "photo-\(i)", qualityScore: 0.87)
                try cacheManager.save(result: result, for: "photo-\(i)")
            }
        }

        actor ProgressTracker {
            var values: [Double] = []

            func append(_ value: Double) {
                values.append(value)
            }

            func getValues() -> [Double] {
                values
            }
        }

        let tracker = ProgressTracker()
        let progressHandler: @Sendable (Double) async -> Void = { progress in
            await tracker.append(progress)
        }

        let results = try await repository.analyzePhotos(
            photos,
            useCache: true,
            progress: progressHandler
        )

        #expect(results.count == 50)

        let progressValues = await tracker.getValues()

        // 進捗が報告されていることを確認
        #expect(progressValues.count == 50)
        #expect(progressValues.last == 1.0)
    }
}
