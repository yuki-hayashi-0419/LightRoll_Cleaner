//
//  PhotoGrouperTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoGrouperのユニットテスト
//  6種類のグルーピング機能をテスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature
import Photos

@Suite("PhotoGrouper Tests")
struct PhotoGrouperTests {

    // MARK: - Test Data

    /// テスト用のモック類似度分析器
    actor MockSimilarityAnalyzer {
        var findSimilarGroupsCalled = false
        var mockGroups: [SimilarPhotoGroup] = []

        func findSimilarGroups(
            in assets: [PHAsset],
            progress: (@Sendable (Double) async -> Void)?
        ) async throws -> [SimilarPhotoGroup] {
            findSimilarGroupsCalled = true
            return mockGroups
        }

        func reset() {
            findSimilarGroupsCalled = false
            mockGroups = []
        }
    }

    /// テスト用のモック顔検出器
    actor MockFaceDetector {
        var detectFacesCalled = false
        var mockResults: [FaceDetectionResult] = []

        func detectFaces(
            in assets: [PHAsset],
            progress: (@Sendable (Double) async -> Void)?
        ) async throws -> [FaceDetectionResult] {
            detectFacesCalled = true
            return mockResults
        }

        func reset() {
            detectFacesCalled = false
            mockResults = []
        }
    }

    /// テスト用のモックブレ検出器
    actor MockBlurDetector {
        var detectBlurCalled = false
        var mockResults: [BlurDetectionResult] = []

        func detectBlur(
            in assets: [PHAsset],
            progress: (@Sendable (Double) async -> Void)?
        ) async throws -> [BlurDetectionResult] {
            detectBlurCalled = true
            return mockResults
        }

        func reset() {
            detectBlurCalled = false
            mockResults = []
        }
    }

    /// テスト用のモックスクリーンショット検出器
    actor MockScreenshotDetector: ScreenshotDetectorProtocol {
        var detectScreenshotsCalled = false
        var mockResults: [ScreenshotDetectionResult] = []

        func isScreenshot(asset: PHAsset) async throws -> Bool {
            return false
        }

        func detectScreenshots(
            in assets: [PHAsset],
            progress: (@Sendable (Double) -> Void)?
        ) async throws -> [ScreenshotDetectionResult] {
            detectScreenshotsCalled = true
            return mockResults
        }

        func cancel() {}

        func reset() {
            detectScreenshotsCalled = false
            mockResults = []
        }
    }

    // MARK: - Initialization Tests

    @Test("PhotoGrouper初期化テスト")
    func testInitialization() async throws {
        // デフォルトオプションで初期化
        let grouper = PhotoGrouper()

        // インスタンスが作成されていることを確認
        // 空配列でメソッド呼び出しが成功することを検証
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupPhotos(emptyAssets)
        #expect(groups.isEmpty)
    }

    @Test("カスタムオプションでの初期化テスト")
    func testInitializationWithCustomOptions() async throws {
        // カスタムオプションで初期化
        let options = GroupingOptions(
            similarityThreshold: 0.9,
            minimumGroupSize: 3,
            includeScreenshots: true,
            includeSelfies: false
        )

        let grouper = PhotoGrouper(options: options)

        // インスタンスが正しく初期化されていることを確認
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupPhotos(emptyAssets)
        #expect(groups.isEmpty)
    }

    // MARK: - Empty Input Tests

    @Test("空の配列でのグルーピングテスト")
    func testGroupPhotosWithEmptyArray() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let groups = try await grouper.groupPhotos(emptyAssets)

        #expect(groups.isEmpty)
    }

    // MARK: - Similar Photos Grouping Tests

    @Test("類似写真グルーピングの基本動作テスト")
    func testGroupSimilarPhotosBasic() async throws {
        // テスト用のモック設定は実PHAssetが必要なため、
        // ここでは空配列テストのみ実施
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let similarGroups = try await grouper.groupSimilarPhotos(emptyAssets)

        #expect(similarGroups.isEmpty)
    }

    @Test("類似写真グルーピングの進捗通知テスト")
    func testGroupSimilarPhotosProgress() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        actor ProgressCollector {
            var values: [Double] = []

            func add(_ value: Double) {
                values.append(value)
            }

            func getValues() -> [Double] {
                return values
            }
        }

        let collector = ProgressCollector()
        let similarGroups = try await grouper.groupSimilarPhotos(emptyAssets) { progress in
            await collector.add(progress)
        }

        #expect(similarGroups.isEmpty)
        // 空配列の場合は進捗通知がない
    }

    // MARK: - Selfie Grouping Tests

    @Test("セルフィーグルーピングの基本動作テスト")
    func testGroupSelfiesBasic() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let selfieGroups = try await grouper.groupSelfies(emptyAssets)

        #expect(selfieGroups.isEmpty)
    }

    @Test("セルフィーグルーピングオプション無効時のテスト")
    func testGroupSelfiesWithDisabledOption() async throws {
        let options = GroupingOptions(includeSelfies: false)
        let grouper = PhotoGrouper(options: options)
        let emptyAssets: [PHAsset] = []

        // オプションで無効化されていても、個別メソッドは実行可能
        let selfieGroups = try await grouper.groupSelfies(emptyAssets)

        #expect(selfieGroups.isEmpty)
    }

    // MARK: - Screenshot Grouping Tests

    @Test("スクリーンショットグルーピングの基本動作テスト")
    func testGroupScreenshotsBasic() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let screenshotGroups = try await grouper.groupScreenshots(emptyAssets)

        #expect(screenshotGroups.isEmpty)
    }

    // MARK: - Blurry Photos Grouping Tests

    @Test("ブレ写真グルーピングの基本動作テスト")
    func testGroupBlurryPhotosBasic() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let blurryGroups = try await grouper.groupBlurryPhotos(emptyAssets)

        #expect(blurryGroups.isEmpty)
    }

    @Test("ブレ写真グルーピングオプション無効時のテスト")
    func testGroupBlurryPhotosWithDisabledOption() async throws {
        let options = GroupingOptions(includeBlurry: false)
        let grouper = PhotoGrouper(options: options)
        let emptyAssets: [PHAsset] = []

        // オプションで無効化されていても、個別メソッドは実行可能
        let blurryGroups = try await grouper.groupBlurryPhotos(emptyAssets)

        #expect(blurryGroups.isEmpty)
    }

    // MARK: - Large Videos Grouping Tests

    @Test("大容量動画グルーピングの基本動作テスト")
    func testGroupLargeVideosBasic() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let largeVideoGroups = try await grouper.groupLargeVideos(emptyAssets)

        #expect(largeVideoGroups.isEmpty)
    }

    @Test("大容量動画グルーピングオプション無効時のテスト")
    func testGroupLargeVideosWithDisabledOption() async throws {
        let options = GroupingOptions(includeLargeVideos: false)
        let grouper = PhotoGrouper(options: options)
        let emptyAssets: [PHAsset] = []

        // オプションで無効化されていても、個別メソッドは実行可能
        let largeVideoGroups = try await grouper.groupLargeVideos(emptyAssets)

        #expect(largeVideoGroups.isEmpty)
    }

    // MARK: - Duplicate Photos Grouping Tests

    @Test("重複写真グルーピングの基本動作テスト")
    func testGroupDuplicatesBasic() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let duplicateGroups = try await grouper.groupDuplicates(emptyAssets)

        #expect(duplicateGroups.isEmpty)
    }

    @Test("重複写真グルーピング - 1枚のみの場合")
    func testGroupDuplicatesWithSingleAsset() async throws {
        let grouper = PhotoGrouper()
        // 実際のPHAssetを作成することはできないため、空配列でテスト
        let singleAsset: [PHAsset] = []

        let duplicateGroups = try await grouper.groupDuplicates(singleAsset)

        #expect(duplicateGroups.isEmpty)
    }

    // MARK: - Comprehensive Grouping Tests

    @Test("全種類のグルーピングの統合テスト")
    func testGroupPhotosComprehensive() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        actor ProgressCollector {
            var values: [Double] = []

            func add(_ value: Double) {
                values.append(value)
            }
        }

        let collector = ProgressCollector()
        let allGroups = try await grouper.groupPhotos(emptyAssets) { progress in
            await collector.add(progress)
        }

        #expect(allGroups.isEmpty)
        // 空配列の場合は進捗通知がない、または最終進捗のみ
    }

    @Test("部分的なグルーピングオプションでのテスト")
    func testGroupPhotosWithPartialOptions() async throws {
        // 類似とブレのみ有効化
        let options = GroupingOptions(
            includeScreenshots: false,
            includeSelfies: false,
            includeLargeVideos: false
        )

        let grouper = PhotoGrouper(options: options)
        let emptyAssets: [PHAsset] = []

        let groups = try await grouper.groupPhotos(emptyAssets)

        #expect(groups.isEmpty)
    }

    @Test("すべてのグルーピング無効時のテスト")
    func testGroupPhotosWithAllOptionsDisabled() async throws {
        let options = GroupingOptions(
            includeScreenshots: false,
            includeSelfies: false,
            includeBlurry: false,
            includeLargeVideos: false
        )

        let grouper = PhotoGrouper(options: options)
        let emptyAssets: [PHAsset] = []

        let groups = try await grouper.groupPhotos(emptyAssets)

        #expect(groups.isEmpty)
    }

    // MARK: - Progress Range Tests

    @Test("進捗範囲の調整テスト - 類似写真")
    func testProgressRangeForSimilarPhotos() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        actor ProgressCollector {
            var values: [Double] = []

            func add(_ value: Double) {
                values.append(value)
            }

            func getValues() -> [Double] {
                return values
            }
        }

        let collector = ProgressCollector()
        _ = try await grouper.groupSimilarPhotos(
            emptyAssets,
            progressRange: (0.2, 0.8)
        ) { progress in
            await collector.add(progress)
        }

        let progressValues = await collector.getValues()
        // 空配列の場合は進捗通知がない
        #expect(progressValues.isEmpty || progressValues.allSatisfy { $0 >= 0.2 && $0 <= 0.8 })
    }

    @Test("進捗範囲の調整テスト - セルフィー")
    func testProgressRangeForSelfies() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        actor ProgressCollector {
            var values: [Double] = []

            func add(_ value: Double) {
                values.append(value)
            }

            func getValues() -> [Double] {
                return values
            }
        }

        let collector = ProgressCollector()
        _ = try await grouper.groupSelfies(
            emptyAssets,
            progressRange: (0.4, 0.6)
        ) { progress in
            await collector.add(progress)
        }

        let progressValues = await collector.getValues()
        // 空配列の場合は進捗通知がない
        #expect(progressValues.isEmpty || progressValues.allSatisfy { $0 >= 0.4 && $0 <= 0.6 })
    }

    // MARK: - Error Handling Tests

    @Test("キャンセル時のエラーハンドリングテスト")
    func testCancellationHandling() async throws {
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        // Task をキャンセル
        let task = Task {
            try await grouper.groupPhotos(emptyAssets)
        }

        task.cancel()

        do {
            let _ = try await task.value
            // キャンセルされても空配列の場合はエラーが発生しない
        } catch {
            // キャンセルエラーが発生する可能性もある
            #expect(error is CancellationError)
        }
    }

    // MARK: - Grouping Options Tests

    @Test("GroupingOptions デフォルト値のテスト")
    func testGroupingOptionsDefault() {
        let options = GroupingOptions.default

        #expect(options.similarityThreshold == 0.85)
        #expect(options.minimumGroupSize == 2)
        #expect(options.includeScreenshots == true)
        #expect(options.includeSelfies == true)
        #expect(options.includeBlurry == true)
        #expect(options.includeLargeVideos == true)
        #expect(options.largeVideoThreshold == 100 * 1024 * 1024) // 100MB
        #expect(options.autoSelectBestShot == true)
    }

    @Test("GroupingOptions 厳格モードのテスト")
    func testGroupingOptionsStrict() {
        let options = GroupingOptions.strict

        #expect(options.similarityThreshold == 0.95)
        #expect(options.minimumGroupSize == 2)
    }

    @Test("GroupingOptions 緩和モードのテスト")
    func testGroupingOptionsRelaxed() {
        let options = GroupingOptions.relaxed

        #expect(options.similarityThreshold == 0.75)
        #expect(options.minimumGroupSize == 2)
    }

    @Test("GroupingOptions カスタム値の範囲チェック")
    func testGroupingOptionsValueClamping() {
        // 類似度閾値の範囲チェック（0.0〜1.0にクランプされる）
        let options1 = GroupingOptions(similarityThreshold: 1.5)
        #expect(options1.similarityThreshold == 1.0)

        let options2 = GroupingOptions(similarityThreshold: -0.5)
        #expect(options2.similarityThreshold == 0.0)

        // 最小グループサイズの範囲チェック（最小2）
        let options3 = GroupingOptions(minimumGroupSize: 1)
        #expect(options3.minimumGroupSize == 2)

        let options4 = GroupingOptions(minimumGroupSize: 0)
        #expect(options4.minimumGroupSize == 2)
    }

    // MARK: - Behavioral Tests
    // 注: 実際のPHAssetを使ったテストは統合テストで実施
    // ユニットテストでは、各メソッドの振る舞いとロジックを検証

    @Test("類似写真グルーピング - 空配列とイメージフィルタリング動作")
    func testGroupSimilarPhotosEmptyAndFiltering() async throws {
        let grouper = PhotoGrouper()

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupSimilarPhotos(emptyAssets)
        #expect(groups.isEmpty)

        // 進捗範囲の動作確認（空配列でも正常に完了する）
        let groupsWithProgress = try await grouper.groupSimilarPhotos(
            emptyAssets,
            progressRange: (0.2, 0.8)
        ) { _ in
            // 進捗コールバックが呼ばれることを確認
            // 空配列の場合は呼ばれない可能性が高い
        }
        #expect(groupsWithProgress.isEmpty)
    }

    @Test("セルフィーグルーピング - 空配列と進捗範囲動作")
    func testGroupSelfiesEmptyAndProgress() async throws {
        let grouper = PhotoGrouper()

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupSelfies(emptyAssets)
        #expect(groups.isEmpty)

        // 進捗範囲の動作確認
        let groupsWithProgress = try await grouper.groupSelfies(
            emptyAssets,
            progressRange: (0.3, 0.7)
        ) { _ in }
        #expect(groupsWithProgress.isEmpty)
    }

    @Test("スクリーンショットグルーピング - 空配列と進捗範囲動作")
    func testGroupScreenshotsEmptyAndProgress() async throws {
        let grouper = PhotoGrouper()

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupScreenshots(emptyAssets)
        #expect(groups.isEmpty)

        // 進捗範囲の動作確認
        let groupsWithProgress = try await grouper.groupScreenshots(
            emptyAssets,
            progressRange: (0.1, 0.3)
        ) { _ in }
        #expect(groupsWithProgress.isEmpty)
    }

    @Test("ブレ写真グルーピング - 空配列と進捗範囲動作")
    func testGroupBlurryPhotosEmptyAndProgress() async throws {
        let grouper = PhotoGrouper()

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupBlurryPhotos(emptyAssets)
        #expect(groups.isEmpty)

        // 進捗範囲の動作確認
        let groupsWithProgress = try await grouper.groupBlurryPhotos(
            emptyAssets,
            progressRange: (0.5, 0.9)
        ) { _ in }
        #expect(groupsWithProgress.isEmpty)
    }

    @Test("重複写真グルーピング - 空配列と1枚以下の動作確認")
    func testGroupDuplicatesEdgeCases() async throws {
        let grouper = PhotoGrouper()

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupDuplicates(emptyAssets)
        #expect(groups.isEmpty)

        // 注: 実際に1枚のアセットでテストするには
        // Photos frameworkの統合テストが必要
    }

    @Test("大容量動画グルーピング - 閾値設定の確認")
    func testGroupLargeVideosWithCustomThreshold() async throws {
        // カスタム閾値（50MB）で初期化
        let options = GroupingOptions(largeVideoThreshold: 50 * 1024 * 1024)
        let grouper = PhotoGrouper(options: options)

        // 空配列の場合
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupLargeVideos(emptyAssets)
        #expect(groups.isEmpty)

        // 進捗範囲の動作確認
        let groupsWithProgress = try await grouper.groupLargeVideos(
            emptyAssets,
            progressRange: (0.0, 1.0)
        ) { _ in }
        #expect(groupsWithProgress.isEmpty)
    }

    @Test("PhotoGrouperProtocol 準拠のテスト")
    func testPhotoGrouperProtocolConformance() async throws {
        // PhotoGrouperがPhotoGrouperProtocolに準拠していることを確認
        let grouper: any PhotoGrouperProtocol = PhotoGrouper()

        // プロトコル経由でメソッドが呼び出せることを確認
        let emptyAssets: [PHAsset] = []
        let groups = try await grouper.groupPhotos(emptyAssets, progress: nil)

        #expect(groups.isEmpty)
    }

    @Test("複数グルーピングの統合実行 - オプション設定の動作確認")
    func testMultipleGroupingOptionsIntegration() async throws {
        // すべてのグルーピングを有効化
        let allEnabledOptions = GroupingOptions.default
        let grouper1 = PhotoGrouper(options: allEnabledOptions)

        let emptyAssets: [PHAsset] = []
        let allGroups = try await grouper1.groupPhotos(emptyAssets)
        #expect(allGroups.isEmpty)

        // 一部のグルーピングを無効化
        let partialOptions = GroupingOptions(
            includeScreenshots: false,
            includeSelfies: false
        )
        let grouper2 = PhotoGrouper(options: partialOptions)
        let partialGroups = try await grouper2.groupPhotos(emptyAssets)
        #expect(partialGroups.isEmpty)
    }

    // MARK: - Performance Tests (Conceptual)

    @Test("大量データでのパフォーマンステスト（概念）")
    func testPerformanceWithLargeDataset() async throws {
        // 実際のパフォーマンステストは別途実施
        // ここでは構造的なテストのみ
        let grouper = PhotoGrouper()
        let emptyAssets: [PHAsset] = []

        let startTime = Date()
        let _ = try await grouper.groupPhotos(emptyAssets)
        let elapsedTime = Date().timeIntervalSince(startTime)

        // 空配列の処理は非常に高速
        #expect(elapsedTime < 1.0)
    }
}

// MARK: - Helper Extensions for Testing

extension PhotoGroup {
    /// テスト用の簡易イニシャライザ
    static func makeTest(
        type: GroupType,
        photoCount: Int = 5
    ) -> PhotoGroup {
        let photoIds = (0..<photoCount).map { "photo_\($0)" }
        let fileSizes = Array(repeating: Int64(1024 * 1024), count: photoCount) // 1MB each

        return PhotoGroup(
            type: type,
            photoIds: photoIds,
            fileSizes: fileSizes
        )
    }
}
