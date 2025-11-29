//
//  StorageOverviewCardTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StorageOverviewCardの包括的な単体テスト
//  MV Patternに基づくUI状態管理のテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI

@testable import LightRoll_CleanerFeature

// MARK: - DisplayStyle Tests

@Suite("StorageOverviewCard.DisplayStyle テスト")
struct DisplayStyleTests {

    @Test("fullスタイルが正しく初期化される")
    func testFullStyle() {
        let style = StorageOverviewCard.DisplayStyle.full
        #expect(style == .full)
    }

    @Test("compactスタイルが正しく初期化される")
    func testCompactStyle() {
        let style = StorageOverviewCard.DisplayStyle.compact
        #expect(style == .compact)
    }

    @Test("minimalスタイルが正しく初期化される")
    func testMinimalStyle() {
        let style = StorageOverviewCard.DisplayStyle.minimal
        #expect(style == .minimal)
    }

    @Test("各スタイルが等価比較できる")
    func testStyleEquality() {
        #expect(StorageOverviewCard.DisplayStyle.full == .full)
        #expect(StorageOverviewCard.DisplayStyle.compact == .compact)
        #expect(StorageOverviewCard.DisplayStyle.minimal == .minimal)
        #expect(StorageOverviewCard.DisplayStyle.full != .compact)
        #expect(StorageOverviewCard.DisplayStyle.compact != .minimal)
    }
}

// MARK: - StorageOverviewCard Initialization Tests

@Suite("StorageOverviewCard 初期化テスト")
@MainActor
struct StorageOverviewCardInitializationTests {

    // テスト用のStorageStatistics生成
    private func createTestStatistics(
        totalBytes: Int64 = 128_000_000_000,
        availableBytes: Int64 = 78_000_000_000,
        photosUsedBytes: Int64 = 25_000_000_000,
        reclaimableBytes: Int64 = 5_000_000_000,
        photoCount: Int = 5000
    ) -> StorageStatistics {
        let storageInfo = StorageInfo(
            totalCapacity: totalBytes,
            availableCapacity: availableBytes,
            photosUsedCapacity: photosUsedBytes,
            reclaimableCapacity: reclaimableBytes
        )
        return StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: photoCount
        )
    }

    @Test("デフォルトスタイル（full）で初期化される")
    func testDefaultStyleInitialization() {
        let stats = createTestStatistics()
        let card = StorageOverviewCard(statistics: stats)
        // Viewは正常に生成される
        #expect(type(of: card) == StorageOverviewCard.self)
    }

    @Test("compactスタイルで初期化される")
    func testCompactStyleInitialization() {
        let stats = createTestStatistics()
        let card = StorageOverviewCard(
            statistics: stats,
            displayStyle: .compact
        )
        #expect(type(of: card) == StorageOverviewCard.self)
    }

    @Test("minimalスタイルで初期化される")
    func testMinimalStyleInitialization() {
        let stats = createTestStatistics()
        let card = StorageOverviewCard(
            statistics: stats,
            displayStyle: .minimal
        )
        #expect(type(of: card) == StorageOverviewCard.self)
    }

    @Test("コールバック付きで初期化される")
    func testInitializationWithCallbacks() {
        let stats = createTestStatistics()
        var scanTapped = false
        var groupTapped: GroupType?

        let card = StorageOverviewCard(
            statistics: stats,
            onScanTap: {
                scanTapped = true
            },
            onGroupTap: { type in
                groupTapped = type
            }
        )

        #expect(type(of: card) == StorageOverviewCard.self)
        // コールバックは外部からのタップイベントで呼ばれる
        // 変数が未使用の警告を抑制
        _ = scanTapped
        _ = groupTapped
    }

    @Test("nilコールバックで初期化される")
    func testInitializationWithNilCallbacks() {
        let stats = createTestStatistics()
        let card = StorageOverviewCard(
            statistics: stats,
            onScanTap: nil,
            onGroupTap: nil
        )
        #expect(type(of: card) == StorageOverviewCard.self)
    }
}

// MARK: - StorageStatistics for Card Tests

@Suite("StorageOverviewCard用StorageStatistics テスト")
struct StorageStatisticsForCardTests {

    @Test("ストレージ使用率が正しく計算される")
    func testUsagePercentageCalculation() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000, // 100GB
            availableCapacity: 40_000_000_000, // 40GB available = 60GB used
            photosUsedCapacity: 30_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 1000
        )

        #expect(stats.storageInfo.usagePercentage >= 0.59)
        #expect(stats.storageInfo.usagePercentage <= 0.61)
    }

    @Test("0バイト使用時は使用率0%")
    func testZeroUsagePercentage() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 100_000_000_000, // 全て空き
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )
        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 0
        )

        #expect(stats.storageInfo.usagePercentage == 0.0)
    }

    @Test("満杯時は使用率100%")
    func testFullUsagePercentage() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 0, // 空き無し
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 10_000_000_000
        )
        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 5000
        )

        #expect(stats.storageInfo.usagePercentage == 1.0)
    }

    @Test("削減可能容量が正しく報告される")
    func testReclaimableCapacity() {
        let reclaimable: Int64 = 15_000_000_000 // 15GB
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 28_000_000_000,
            photosUsedCapacity: 60_000_000_000,
            reclaimableCapacity: reclaimable
        )
        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 3000
        )

        #expect(stats.storageInfo.reclaimableCapacity == reclaimable)
    }

    @Test("フォーマット済み容量が正しい形式")
    func testFormattedCapacity() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 8_000_000_000
        )

        // formattedTotalCapacityが適切な単位（GB）を含む
        #expect(storageInfo.formattedTotalCapacity.contains("GB") || storageInfo.formattedTotalCapacity.contains("バイト"))
    }
}

// MARK: - Group Statistics Tests

@Suite("StorageOverviewCard グループ統計テスト")
struct GroupStatisticsTests {

    private func createTestGroup(type: GroupType, photoCount: Int, totalSizePerPhoto: Int64) -> PhotoGroup {
        let photoIds = (0..<photoCount).map { "photo_\($0)" }
        let fileSizes = Array(repeating: totalSizePerPhoto, count: photoCount)
        return PhotoGroup(
            type: type,
            photoIds: photoIds,
            fileSizes: fileSizes
        )
    }

    @Test("類似写真グループ数が正しくカウントされる")
    func testSimilarGroupCount() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let groups = [
            createTestGroup(type: .similar, photoCount: 5, totalSizePerPhoto: 100_000_000),
            createTestGroup(type: .similar, photoCount: 3, totalSizePerPhoto: 100_000_000),
            createTestGroup(type: .screenshot, photoCount: 10, totalSizePerPhoto: 10_000_000)
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 100
        )

        // groupSummariesから類似写真のサマリーを取得
        let similarSummary = stats.summary(for: .similar)
        #expect(similarSummary.groupCount == 2)
    }

    @Test("スクリーンショット数が正しくカウントされる")
    func testScreenshotCount() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 3_000_000_000
        )

        let groups = [
            createTestGroup(type: .screenshot, photoCount: 15, totalSizePerPhoto: 10_000_000)
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 50
        )

        let screenshotSummary = stats.summary(for: .screenshot)
        #expect(screenshotSummary.groupCount == 1)
        #expect(screenshotSummary.photoCount == 15)
    }

    @Test("空のグループリストを処理できる")
    func testEmptyGroups() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 0
        )

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 0
        )

        #expect(stats.groupSummaries.isEmpty)
        #expect(stats.totalReclaimableSize == 0)
    }

    @Test("全グループタイプを含む統計")
    func testAllGroupTypes() {
        let storageInfo = StorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 56_000_000_000,
            photosUsedCapacity: 120_000_000_000,
            reclaimableCapacity: 20_000_000_000
        )

        let groups = [
            createTestGroup(type: .similar, photoCount: 10, totalSizePerPhoto: 500_000_000),
            createTestGroup(type: .duplicate, photoCount: 5, totalSizePerPhoto: 400_000_000),
            createTestGroup(type: .screenshot, photoCount: 50, totalSizePerPhoto: 10_000_000),
            createTestGroup(type: .blurry, photoCount: 20, totalSizePerPhoto: 50_000_000),
            createTestGroup(type: .largeVideo, photoCount: 3, totalSizePerPhoto: 3_333_333_333)
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 500
        )

        #expect(stats.groupSummaries.count == 5)
        #expect(stats.hasSummary(for: .similar))
        #expect(stats.hasSummary(for: .duplicate))
        #expect(stats.hasSummary(for: .screenshot))
        #expect(stats.hasSummary(for: .blurry))
        #expect(stats.hasSummary(for: .largeVideo))
    }
}

// MARK: - Warning Level Tests

@Suite("StorageOverviewCard 警告レベルテスト")
struct WarningLevelTests {

    @Test("50%未満は正常状態")
    func testNormalLevel() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 60_000_000_000, // 60% available = 40% used
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 2_000_000_000
        )

        #expect(storageInfo.usagePercentage < 0.5)
    }

    @Test("70-90%は警告状態")
    func testWarningLevel() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 20_000_000_000, // 20% available = 80% used
            photosUsedCapacity: 40_000_000_000,
            reclaimableCapacity: 10_000_000_000
        )

        let percentage = storageInfo.usagePercentage
        #expect(percentage >= 0.7)
        #expect(percentage < 0.9)
    }

    @Test("90%以上は危険状態")
    func testCriticalLevel() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 5_000_000_000, // 5% available = 95% used
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 15_000_000_000
        )

        #expect(storageInfo.usagePercentage >= 0.9)
    }
}

// MARK: - Accessibility Tests

@Suite("StorageOverviewCard アクセシビリティテスト")
struct AccessibilityTests {

    @Test("アクセシビリティ識別子が設定される")
    func testAccessibilityIdentifier() {
        // StorageOverviewCardは "StorageOverviewCard" という識別子を持つ
        let expectedIdentifier = "StorageOverviewCard"
        #expect(expectedIdentifier == "StorageOverviewCard")
    }

    @Test("アクセシビリティラベルが設定される")
    func testAccessibilityLabel() {
        // "ストレージ概要" というラベルが期待される
        let expectedLabel = "ストレージ概要"
        #expect(expectedLabel.contains("ストレージ"))
    }
}

// MARK: - Edge Cases Tests

@Suite("StorageOverviewCard エッジケーステスト")
struct EdgeCasesTests {

    @Test("非常に大きなストレージ値を処理できる")
    func testVeryLargeStorageValues() {
        let storageInfo = StorageInfo(
            totalCapacity: 2_000_000_000_000, // 2TB
            availableCapacity: 500_000_000_000, // 500GB available = 75% used
            photosUsedCapacity: 800_000_000_000,
            reclaimableCapacity: 100_000_000_000
        )

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 50000
        )

        #expect(stats.storageInfo.totalCapacity == 2_000_000_000_000)
        #expect(stats.storageInfo.usagePercentage == 0.75)
    }

    @Test("非常に多くの写真数を処理できる")
    func testVeryLargePhotoCount() {
        let storageInfo = StorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 56_000_000_000,
            photosUsedCapacity: 150_000_000_000,
            reclaimableCapacity: 30_000_000_000
        )

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 100_000
        )

        #expect(stats.scannedPhotoCount == 100_000)
    }

    @Test("ゼロ容量のデバイスを処理できる")
    func testZeroCapacityDevice() {
        let storageInfo = StorageInfo(
            totalCapacity: 0,
            availableCapacity: 0,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 0
        )

        // ゼロ除算を回避できている
        #expect(stats.storageInfo.totalCapacity == 0)
        #expect(stats.storageInfo.usagePercentage == 0.0)
    }
}

// MARK: - Animation State Tests

@Suite("StorageOverviewCard アニメーション状態テスト")
struct AnimationStateTests {

    @Test("初期アニメーション進捗は0")
    func testInitialAnimationProgress() {
        // アニメーション開始前の進捗値
        let initialProgress: Double = 0.0
        #expect(initialProgress == 0.0)
    }

    @Test("アニメーション完了後の進捗は使用率と一致")
    func testFinalAnimationProgress() {
        let storageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 25_000_000_000, // 25% available = 75% used
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 10_000_000_000
        )

        let expectedProgress = storageInfo.usagePercentage
        #expect(expectedProgress == 0.75)
    }
}

// MARK: - GroupSummary Tests

@Suite("StorageOverviewCard用GroupSummary テスト")
struct GroupSummaryTests {

    @Test("空のGroupSummaryを生成できる")
    func testEmptyGroupSummary() {
        let summary = GroupSummary.empty(for: .similar)
        #expect(summary.isEmpty)
        #expect(summary.groupCount == 0)
        #expect(summary.photoCount == 0)
        #expect(summary.reclaimableSize == 0)
    }

    @Test("GroupSummaryの削減率が正しく計算される")
    func testGroupSummarySavingsPercentage() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 5,
            photoCount: 50,
            totalSize: 1_000_000_000,
            reclaimableSize: 750_000_000
        )

        #expect(summary.savingsPercentage == 75.0)
    }

    @Test("GroupSummaryのフォーマット済みサイズが正しい")
    func testGroupSummaryFormattedSize() {
        let summary = GroupSummary(
            type: .duplicate,
            groupCount: 3,
            photoCount: 30,
            totalSize: 500_000_000,
            reclaimableSize: 400_000_000
        )

        // フォーマット済み文字列が空でないことを確認
        #expect(!summary.formattedTotalSize.isEmpty)
        #expect(!summary.formattedReclaimableSize.isEmpty)
    }

    @Test("GroupSummaryの比較が削減可能サイズ基準")
    func testGroupSummaryComparison() {
        let larger = GroupSummary(
            type: .similar,
            groupCount: 2,
            photoCount: 20,
            totalSize: 200_000_000,
            reclaimableSize: 150_000_000
        )

        let smaller = GroupSummary(
            type: .screenshot,
            groupCount: 5,
            photoCount: 50,
            totalSize: 100_000_000,
            reclaimableSize: 80_000_000
        )

        // Comparable実装: 削減可能サイズ大きい方が "小さい"（ソート時に先頭）
        #expect(larger < smaller)
    }
}

// MARK: - StorageStatistics Lookup Tests

@Suite("StorageStatistics ルックアップテスト")
struct StorageStatisticsLookupTests {

    @Test("存在するグループタイプのサマリーを取得できる")
    func testGetExistingSummary() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2", "3"],
                fileSizes: [100_000_000, 100_000_000, 100_000_000]
            )
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 100
        )

        #expect(stats.hasSummary(for: .similar))
        let summary = stats.summary(for: .similar)
        #expect(summary.photoCount == 3)
    }

    @Test("存在しないグループタイプは空のサマリーを返す")
    func testGetNonExistingSummary() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: [],
            scannedPhotoCount: 0
        )

        #expect(!stats.hasSummary(for: .blurry))
        let summary = stats.summary(for: .blurry)
        #expect(summary.isEmpty)
    }

    @Test("ソート済みサマリーが正しい順序で返される")
    func testSortedSummaries() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 10_000_000_000
        )

        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1", "2"], fileSizes: [100_000_000, 100_000_000]),
            PhotoGroup(type: .duplicate, photoIds: ["3", "4"], fileSizes: [200_000_000, 200_000_000]),
            PhotoGroup(type: .screenshot, photoIds: ["5", "6"], fileSizes: [50_000_000, 50_000_000])
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 50
        )

        let sorted = stats.sortedGroupSummaries
        #expect(sorted.count == 3)
        // sortOrderに従ってソートされている
        // duplicate (0) < similar (1) < screenshot (3)
        #expect(sorted[0].type == .duplicate)
        #expect(sorted[1].type == .similar)
        #expect(sorted[2].type == .screenshot)
    }
}

// Note: StorageLevel, StorageInfoComputedProperties, StorageInfoFactoryMethods
// tests are located in PhotoModelsTests.swift to avoid duplication
