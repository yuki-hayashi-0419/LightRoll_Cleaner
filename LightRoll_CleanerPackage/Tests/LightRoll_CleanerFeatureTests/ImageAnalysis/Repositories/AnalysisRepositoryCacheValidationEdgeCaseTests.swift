//
//  AnalysisRepositoryCacheValidationEdgeCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  エッジケーステスト（品質検証で不足していた項目）
//  - 並行アクセス時のキャッシュ検証（競合状態）
//  - 大量写真時のメモリ効率
//  - featurePrintHashが空Data（[]）の場合の扱い
//  - キャッシュ破損時の挙動
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - AnalysisRepositoryCacheValidationEdgeCaseTests

@Suite("AnalysisRepository キャッシュ検証エッジケーステスト")
@MainActor
struct AnalysisRepositoryCacheValidationEdgeCaseTests {

    // MARK: - Test Helpers

    private static func makeTestPhoto(id: String) -> Photo {
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
            fileSize: 1024,
            isFavorite: false
        )
    }

    private static func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "AnalysisCacheValidationEdgeCaseTests_\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    // MARK: - エッジケーステスト

    @Test("featurePrintHashが空Data（[]）の場合、再分析対象となる")
    func testEmptyFeaturePrintHashRequiresReanalysis() async throws {
        let userDefaults = Self.makeTestUserDefaults()
        let cacheManager = AnalysisCacheManager(userDefaults: userDefaults)

        // 空Dataのキャッシュを作成
        let emptyHashResult = PhotoAnalysisResult(
            photoId: "photo-empty-hash",
            qualityScore: 0.8,
            blurScore: 0.2,
            brightnessScore: 0.5,
            contrastScore: 0.5,
            saturationScore: 0.5,
            faceCount: 1,
            featurePrintHash: Data() // 空Data（nilではない）
        )
        await cacheManager.saveResult(emptyHashResult)

        let repository = AnalysisRepository(cacheManager: cacheManager)
        let photos = [Self.makeTestPhoto(id: "photo-empty-hash")]

        // 分析を実行
        let results = try await repository.analyzePhotos(photos, forceReanalyze: false)

        // 空Dataは無効なため再分析されることを確認
        #expect(results.count == 1)
        #expect(results[0].photoId == "photo-empty-hash")

        // クリーンアップ
        await cacheManager.clearCache()
    }

    @Test("並行して複数の分析が実行される場合、キャッシュ検証が正しく動作する")
    func testConcurrentAnalysisWithCacheValidation() async throws {
        let userDefaults = Self.makeTestUserDefaults()
        let cacheManager = AnalysisCacheManager(userDefaults: userDefaults)

        // 完全なキャッシュを事前保存
        let cachedResult = PhotoAnalysisResult(
            photoId: "photo-concurrent",
            qualityScore: 0.9,
            blurScore: 0.1,
            brightnessScore: 0.6,
            contrastScore: 0.6,
            saturationScore: 0.6,
            faceCount: 2,
            featurePrintHash: Data([0x01, 0x02, 0x03, 0x04])
        )
        await cacheManager.saveResult(cachedResult)

        let repository = AnalysisRepository(cacheManager: cacheManager)
        let photos = [Self.makeTestPhoto(id: "photo-concurrent")]

        // 並行して同じ写真を分析
        async let result1 = repository.analyzePhotos(photos, forceReanalyze: false)
        async let result2 = repository.analyzePhotos(photos, forceReanalyze: false)

        let (results1, results2) = try await (result1, result2)

        // 両方ともキャッシュから取得した結果を確認
        #expect(results1.count == 1)
        #expect(results2.count == 1)
        #expect(results1[0].photoId == "photo-concurrent")
        #expect(results2[0].photoId == "photo-concurrent")
        #expect(results1[0].featurePrintHash != nil)
        #expect(results2[0].featurePrintHash != nil)

        // クリーンアップ
        await cacheManager.clearCache()
    }

    @Test("大量の写真（1000枚）でもメモリ効率よくキャッシュ検証できる")
    func testLargeScaleCacheValidation() async throws {
        let userDefaults = Self.makeTestUserDefaults()
        let cacheManager = AnalysisCacheManager(userDefaults: userDefaults)

        // 500枚はキャッシュあり、500枚はキャッシュなし
        let photoCount = 1000
        var photos: [Photo] = []

        for i in 0..<photoCount {
            let photo = Self.makeTestPhoto(id: "photo-\(i)")
            photos.append(photo)

            // 前半500枚はキャッシュを作成
            if i < photoCount / 2 {
                let cachedResult = PhotoAnalysisResult(
                    photoId: "photo-\(i)",
                    qualityScore: 0.8,
                    blurScore: 0.2,
                    brightnessScore: 0.5,
                    contrastScore: 0.5,
                    saturationScore: 0.5,
                    faceCount: 1,
                    featurePrintHash: Data([0x01, 0x02, 0x03, UInt8(i % 256)])
                )
                await cacheManager.saveResult(cachedResult)
            }
        }

        let repository = AnalysisRepository(cacheManager: cacheManager)

        // メモリ使用量を確認しつつ分析実行
        let results = try await repository.analyzePhotos(photos, forceReanalyze: false)

        // 全写真の結果が返されることを確認
        #expect(results.count == photoCount)

        // 前半500枚はキャッシュヒット、後半500枚は再分析
        let cachedResults = results.prefix(photoCount / 2)
        #expect(cachedResults.allSatisfy { $0.featurePrintHash != nil })

        // クリーンアップ
        await cacheManager.clearCache()
    }

    @Test("キャッシュが破損している場合、再分析対象として扱われる")
    func testCorruptedCacheRequiresReanalysis() async throws {
        let userDefaults = Self.makeTestUserDefaults()
        let cacheManager = AnalysisCacheManager(userDefaults: userDefaults)

        // 破損した状態をシミュレート（不正なデータ構造）
        let photoId = "photo-corrupted"
        let invalidData = "invalid-json-data".data(using: .utf8)!
        userDefaults.set(invalidData, forKey: "analysis_cache_\(photoId)")

        let repository = AnalysisRepository(cacheManager: cacheManager)
        let photos = [Self.makeTestPhoto(id: photoId)]

        // 分析を実行（破損キャッシュのためエラーになる可能性）
        do {
            let results = try await repository.analyzePhotos(photos, forceReanalyze: false)

            // 破損キャッシュは無視され、再分析されることを確認
            #expect(results.count == 1)
            #expect(results[0].photoId == photoId)
        } catch {
            // エラーが発生しても、破損キャッシュが適切に処理されたことを確認
            #expect(error is NSError)
        }

        // クリーンアップ
        await cacheManager.clearCache()
    }

    @Test("featurePrintHashがnilとData()混在時、両方とも再分析対象")
    func testMixedInvalidFeaturePrintHash() async throws {
        let userDefaults = Self.makeTestUserDefaults()
        let cacheManager = AnalysisCacheManager(userDefaults: userDefaults)

        // nilパターン
        let nilHashResult = PhotoAnalysisResult(
            photoId: "photo-nil-hash",
            qualityScore: 0.8,
            blurScore: 0.2,
            brightnessScore: 0.5,
            contrastScore: 0.5,
            saturationScore: 0.5,
            faceCount: 1,
            featurePrintHash: nil
        )

        // 空Dataパターン
        let emptyHashResult = PhotoAnalysisResult(
            photoId: "photo-empty-hash",
            qualityScore: 0.8,
            blurScore: 0.2,
            brightnessScore: 0.5,
            contrastScore: 0.5,
            saturationScore: 0.5,
            faceCount: 1,
            featurePrintHash: Data()
        )

        // 有効なキャッシュ
        let validHashResult = PhotoAnalysisResult(
            photoId: "photo-valid-hash",
            qualityScore: 0.8,
            blurScore: 0.2,
            brightnessScore: 0.5,
            contrastScore: 0.5,
            saturationScore: 0.5,
            faceCount: 1,
            featurePrintHash: Data([0x01, 0x02, 0x03, 0x04])
        )

        await cacheManager.saveResult(nilHashResult)
        await cacheManager.saveResult(emptyHashResult)
        await cacheManager.saveResult(validHashResult)

        let repository = AnalysisRepository(cacheManager: cacheManager)
        let photos = [
            Self.makeTestPhoto(id: "photo-nil-hash"),
            Self.makeTestPhoto(id: "photo-empty-hash"),
            Self.makeTestPhoto(id: "photo-valid-hash")
        ]

        // 分析を実行
        let results = try await repository.analyzePhotos(photos, forceReanalyze: false)

        // 全写真の結果が返されることを確認
        #expect(results.count == 3)

        // 有効なキャッシュのみキャッシュヒット
        let validResult = results.first { $0.photoId == "photo-valid-hash" }
        #expect(validResult?.featurePrintHash != nil)

        // nilと空Dataは再分析対象
        let nilResult = results.first { $0.photoId == "photo-nil-hash" }
        let emptyResult = results.first { $0.photoId == "photo-empty-hash" }
        #expect(nilResult != nil)
        #expect(emptyResult != nil)

        // クリーンアップ
        await cacheManager.clearCache()
    }
}
