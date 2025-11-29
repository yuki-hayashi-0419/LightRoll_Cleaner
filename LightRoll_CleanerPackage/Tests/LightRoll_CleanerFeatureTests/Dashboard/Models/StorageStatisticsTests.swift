//
//  StorageStatisticsTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StorageStatistics & GroupSummary モデルの包括的な単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing

@testable import LightRoll_CleanerFeature

// MARK: - GroupSummary Initialization Tests

@Suite("GroupSummary 初期化テスト")
struct GroupSummaryInitializationTests {

    @Test("全プロパティを指定して初期化できる")
    func testFullInitialization() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 5,
            photoCount: 50,
            totalSize: 1_000_000_000,
            reclaimableSize: 800_000_000
        )

        #expect(summary.type == .similar)
        #expect(summary.groupCount == 5)
        #expect(summary.photoCount == 50)
        #expect(summary.totalSize == 1_000_000_000)
        #expect(summary.reclaimableSize == 800_000_000)
    }

    @Test("負のグループ数は0にクランプされる")
    func testNegativeGroupCountClamping() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: -5,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(summary.groupCount == 0)
    }

    @Test("負の写真数は0にクランプされる")
    func testNegativePhotoCountClamping() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 5,
            photoCount: -10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(summary.photoCount == 0)
    }

    @Test("負のサイズは0にクランプされる")
    func testNegativeSizesClamping() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 5,
            photoCount: 10,
            totalSize: -1000,
            reclaimableSize: -500
        )
        #expect(summary.totalSize == 0)
        #expect(summary.reclaimableSize == 0)
    }

    @Test("PhotoGroup配列から生成できる")
    func testInitFromPhotoGroups() {
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2", "3"],
                fileSizes: [1000, 2000, 3000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .similar,
                photoIds: ["4", "5"],
                fileSizes: [1500, 1500],
                bestShotIndex: 1
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["6", "7"],
                fileSizes: [500, 500]
            )
        ]

        let summary = GroupSummary(type: .similar, groups: groups)

        #expect(summary.type == .similar)
        #expect(summary.groupCount == 2) // similar タイプのみ
        #expect(summary.photoCount == 5) // 3 + 2
        #expect(summary.totalSize == 9000) // (1000+2000+3000) + (1500+1500)
    }

    @Test("空のサマリーを生成できる")
    func testEmptySummary() {
        let empty = GroupSummary.empty(for: .blurry)

        #expect(empty.type == .blurry)
        #expect(empty.groupCount == 0)
        #expect(empty.photoCount == 0)
        #expect(empty.totalSize == 0)
        #expect(empty.reclaimableSize == 0)
        #expect(empty.isEmpty == true)
    }
}

// MARK: - GroupSummary Computed Properties Tests

@Suite("GroupSummary 算出プロパティテスト")
struct GroupSummaryComputedPropertiesTests {

    @Test("idがGroupTypeのrawValueを返す")
    func testId() {
        let summary = GroupSummary(
            type: .screenshot,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 1000
        )
        #expect(summary.id == GroupType.screenshot.rawValue)
    }

    @Test("formattedTotalSizeが人間可読形式を返す")
    func testFormattedTotalSize() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1_500_000_000, // 1.5GB
            reclaimableSize: 1000
        )
        #expect(!summary.formattedTotalSize.isEmpty)
    }

    @Test("formattedReclaimableSizeが人間可読形式を返す")
    func testFormattedReclaimableSize() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 800_000_000 // 800MB
        )
        #expect(!summary.formattedReclaimableSize.isEmpty)
    }

    @Test("savingsPercentageが正しく計算される")
    func testSavingsPercentage() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 750
        )
        #expect(summary.savingsPercentage == 75.0)
    }

    @Test("savingsPercentageがtotalSize=0で0を返す")
    func testSavingsPercentageZeroTotal() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 0,
            photoCount: 0,
            totalSize: 0,
            reclaimableSize: 0
        )
        #expect(summary.savingsPercentage == 0)
    }

    @Test("isEmptyが正しく判定される")
    func testIsEmpty() {
        let emptySummary = GroupSummary.empty(for: .similar)
        #expect(emptySummary.isEmpty == true)

        let nonEmptySummary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(nonEmptySummary.isEmpty == false)
    }

    @Test("isValidが正しく判定される")
    func testIsValid() {
        let invalidSummary = GroupSummary.empty(for: .similar)
        #expect(invalidSummary.isValid == false)

        let validSummary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(validSummary.isValid == true)
    }

    @Test("displayNameがGroupTypeの表示名を返す")
    func testDisplayName() {
        let summary = GroupSummary(
            type: .selfie,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(summary.displayName == GroupType.selfie.displayName)
    }

    @Test("iconがGroupTypeのアイコンを返す")
    func testIcon() {
        let summary = GroupSummary(
            type: .blurry,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(summary.icon == GroupType.blurry.icon)
    }

    @Test("emojiがGroupTypeの絵文字を返す")
    func testEmoji() {
        let summary = GroupSummary(
            type: .largeVideo,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        #expect(summary.emoji == GroupType.largeVideo.emoji)
    }
}

// MARK: - GroupSummary Comparable Tests

@Suite("GroupSummary Comparable テスト")
struct GroupSummaryComparableTests {

    @Test("削減可能サイズで降順にソートされる")
    func testComparable() {
        let small = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 100
        )
        let large = GroupSummary(
            type: .screenshot,
            groupCount: 1,
            photoCount: 10,
            totalSize: 2000,
            reclaimableSize: 1000
        )

        // < 演算子は reclaimableSize が大きい方が「小さい」と判定（降順ソート用）
        #expect(large < small)
    }
}

// MARK: - GroupSummary Codable Tests

@Suite("GroupSummary Codable テスト")
struct GroupSummaryCodableTests {

    @Test("GroupSummaryがエンコード・デコードできる")
    func testCodable() throws {
        let original = GroupSummary(
            type: .duplicate,
            groupCount: 5,
            photoCount: 50,
            totalSize: 1_000_000,
            reclaimableSize: 800_000
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GroupSummary.self, from: encoded)

        #expect(decoded.type == original.type)
        #expect(decoded.groupCount == original.groupCount)
        #expect(decoded.photoCount == original.photoCount)
        #expect(decoded.totalSize == original.totalSize)
        #expect(decoded.reclaimableSize == original.reclaimableSize)
    }
}

// MARK: - GroupSummary Protocol Conformance Tests

@Suite("GroupSummary プロトコル準拠テスト")
struct GroupSummaryProtocolConformanceTests {

    @Test("GroupSummaryがIdentifiable準拠している")
    func testIdentifiable() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        let _ = summary.id // Identifiable要件
    }

    @Test("GroupSummaryがHashable準拠している")
    func testHashable() {
        let summary1 = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )
        let summary2 = GroupSummary(
            type: .screenshot,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )

        var set = Set<GroupSummary>()
        set.insert(summary1)
        set.insert(summary2)
        #expect(set.count == 2)
    }

    @Test("GroupSummaryがSendable準拠している")
    func testSendable() async {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 10,
            totalSize: 1000,
            reclaimableSize: 500
        )

        let result = await Task.detached {
            summary.type
        }.value

        #expect(result == .similar)
    }

    @Test("GroupSummaryのdescriptionが期待通りの形式")
    func testCustomStringConvertible() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 3,
            photoCount: 30,
            totalSize: 1_000_000,
            reclaimableSize: 800_000
        )

        let description = summary.description
        #expect(description.contains(GroupType.similar.emoji))
        #expect(description.contains("30枚"))
    }
}

// MARK: - StorageStatistics Initialization Tests

@Suite("StorageStatistics 初期化テスト")
struct StorageStatisticsInitializationTests {

    @Test("全プロパティを指定して初期化できる")
    func testFullInitialization() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 0
        )
        let summaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 5,
                photoCount: 50,
                totalSize: 1_000_000_000,
                reclaimableSize: 800_000_000
            )
        ]
        let timestamp = Date()

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: summaries,
            timestamp: timestamp,
            scannedPhotoCount: 1000,
            scannedVideoCount: 100
        )

        #expect(stats.storageInfo == storageInfo)
        #expect(stats.groupSummaries.count == 1)
        #expect(stats.timestamp == timestamp)
        #expect(stats.scannedPhotoCount == 1000)
        #expect(stats.scannedVideoCount == 100)
    }

    @Test("負のスキャンカウントは0にクランプされる")
    func testNegativeScannedCountsClamping() {
        let storageInfo = StorageInfo.empty

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            scannedPhotoCount: -100,
            scannedVideoCount: -50
        )

        #expect(stats.scannedPhotoCount == 0)
        #expect(stats.scannedVideoCount == 0)
    }

    @Test("PhotoGroup配列から生成できる")
    func testInitFromPhotoGroups() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 0
        )
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2", "3"],
                fileSizes: [1000, 2000, 3000]
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["4", "5"],
                fileSizes: [500, 500]
            )
        ]

        let stats = StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 500,
            scannedVideoCount: 50
        )

        #expect(stats.groupSummaries[GroupType.similar] != nil)
        #expect(stats.groupSummaries[GroupType.screenshot] != nil)
        #expect(stats.groupSummaries[GroupType.blurry] == nil) // 空のサマリーは含まれない
    }

    @Test("空の統計を生成できる")
    func testEmptyStatistics() {
        let empty = StorageStatistics.empty

        #expect(empty.storageInfo == StorageInfo.empty)
        #expect(empty.groupSummaries.isEmpty)
        #expect(empty.scannedPhotoCount == 0)
        #expect(empty.scannedVideoCount == 0)
    }

    @Test("デバイスから生成できる")
    func testFromDevice() {
        let stats = StorageStatistics.fromDevice()

        // デバイスのストレージ情報が取得されていることを確認
        #expect(stats.storageInfo.totalCapacity > 0)
    }
}

// MARK: - StorageStatistics Computed Properties Tests

@Suite("StorageStatistics 算出プロパティテスト")
struct StorageStatisticsComputedPropertiesTests {

    private func createSampleStats() -> StorageStatistics {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 0
        )
        let summaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 5,
                photoCount: 50,
                totalSize: 1_000_000_000,
                reclaimableSize: 800_000_000
            ),
            .screenshot: GroupSummary(
                type: .screenshot,
                groupCount: 3,
                photoCount: 30,
                totalSize: 500_000_000,
                reclaimableSize: 500_000_000
            )
        ]

        return StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: summaries,
            scannedPhotoCount: 1000,
            scannedVideoCount: 100
        )
    }

    @Test("totalReclaimableSizeが正しく計算される")
    func testTotalReclaimableSize() {
        let stats = createSampleStats()
        #expect(stats.totalReclaimableSize == 1_300_000_000) // 800M + 500M
    }

    @Test("formattedTotalReclaimableSizeが人間可読形式を返す")
    func testFormattedTotalReclaimableSize() {
        let stats = createSampleStats()
        #expect(!stats.formattedTotalReclaimableSize.isEmpty)
    }

    @Test("totalGroupedPhotoCountが正しく計算される")
    func testTotalGroupedPhotoCount() {
        let stats = createSampleStats()
        #expect(stats.totalGroupedPhotoCount == 80) // 50 + 30
    }

    @Test("totalGroupCountが正しく計算される")
    func testTotalGroupCount() {
        let stats = createSampleStats()
        #expect(stats.totalGroupCount == 8) // 5 + 3
    }

    @Test("totalScannedCountが正しく計算される")
    func testTotalScannedCount() {
        let stats = createSampleStats()
        #expect(stats.totalScannedCount == 1100) // 1000 + 100
    }

    @Test("savingsPercentageが正しく計算される")
    func testSavingsPercentage() {
        let stats = createSampleStats()
        // 1.3GB / 20GB * 100 = 6.5%
        #expect(stats.savingsPercentage > 0)
    }

    @Test("savingsPercentageがphotosUsedCapacity=0で0を返す")
    func testSavingsPercentageZeroPhotosUsed() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )
        let stats = StorageStatistics(storageInfo: storageInfo)
        #expect(stats.savingsPercentage == 0)
    }

    @Test("hasSignificantSavingsが1GB以上でtrueを返す")
    func testHasSignificantSavings() {
        let stats = createSampleStats() // 1.3GB
        #expect(stats.hasSignificantSavings == true)

        let smallStats = StorageStatistics(
            storageInfo: StorageInfo.empty,
            groupSummaries: [
                .similar: GroupSummary(
                    type: .similar,
                    groupCount: 1,
                    photoCount: 10,
                    totalSize: 100_000_000, // 100MB
                    reclaimableSize: 50_000_000 // 50MB
                )
            ]
        )
        #expect(smallStats.hasSignificantSavings == false)
    }

    @Test("hasDataが正しく判定される")
    func testHasData() {
        let stats = createSampleStats()
        #expect(stats.hasData == true)

        let emptyStats = StorageStatistics.empty
        #expect(emptyStats.hasData == false)
    }

    @Test("sortedGroupSummariesがsortOrder順でソートされる")
    func testSortedGroupSummaries() {
        let stats = createSampleStats()
        let sorted = stats.sortedGroupSummaries

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].type.sortOrder < sorted[i + 1].type.sortOrder)
        }
    }

    @Test("summariesByReclaimableSizeが削減可能サイズ順でソートされる")
    func testSummariesByReclaimableSize() {
        let stats = createSampleStats()
        let sorted = stats.summariesByReclaimableSize

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].reclaimableSize >= sorted[i + 1].reclaimableSize)
        }
    }

    @Test("formattedTimestampが文字列を返す")
    func testFormattedTimestamp() {
        let stats = createSampleStats()
        #expect(!stats.formattedTimestamp.isEmpty)
    }

    @Test("formattedRelativeTimestampが相対形式を返す")
    func testFormattedRelativeTimestamp() {
        let stats = createSampleStats()
        #expect(!stats.formattedRelativeTimestamp.isEmpty)
    }
}

// MARK: - StorageStatistics Lookup Methods Tests

@Suite("StorageStatistics 検索メソッドテスト")
struct StorageStatisticsLookupMethodsTests {

    private func createSampleStats() -> StorageStatistics {
        let storageInfo = StorageInfo.empty
        let summaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 5,
                photoCount: 50,
                totalSize: 1_000_000_000,
                reclaimableSize: 800_000_000
            )
        ]

        return StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: summaries
        )
    }

    @Test("summaryForが存在するタイプのサマリーを返す")
    func testSummaryForExistingType() {
        let stats = createSampleStats()
        let summary = stats.summary(for: .similar)

        #expect(summary.groupCount == 5)
        #expect(summary.photoCount == 50)
    }

    @Test("summaryForが存在しないタイプで空のサマリーを返す")
    func testSummaryForNonExistingType() {
        let stats = createSampleStats()
        let summary = stats.summary(for: .blurry)

        #expect(summary.isEmpty == true)
        #expect(summary.type == .blurry)
    }

    @Test("hasSummaryForが正しく判定される")
    func testHasSummaryFor() {
        let stats = createSampleStats()

        #expect(stats.hasSummary(for: .similar) == true)
        #expect(stats.hasSummary(for: .blurry) == false)
    }
}

// MARK: - StorageStatistics Update Methods Tests

@Suite("StorageStatistics 更新メソッドテスト")
struct StorageStatisticsUpdateMethodsTests {

    @Test("withStorageInfoが新しいインスタンスを返す")
    func testWithStorageInfo() {
        let stats = StorageStatistics.empty
        let newStorageInfo = StorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 128_000_000_000,
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 0
        )

        let updated = stats.withStorageInfo(newStorageInfo)

        #expect(stats.storageInfo == StorageInfo.empty)
        #expect(updated.storageInfo == newStorageInfo)
    }

    @Test("withGroupSummariesが新しいインスタンスを返す")
    func testWithGroupSummaries() {
        let stats = StorageStatistics.empty
        let newSummaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 3,
                photoCount: 30,
                totalSize: 500_000_000,
                reclaimableSize: 400_000_000
            )
        ]

        let updated = stats.withGroupSummaries(newSummaries)

        #expect(stats.groupSummaries.isEmpty)
        #expect(updated.groupSummaries.count == 1)
    }

    @Test("withSummaryが特定のサマリーを追加/更新する")
    func testWithSummary() {
        let stats = StorageStatistics.empty
        let summary = GroupSummary(
            type: .screenshot,
            groupCount: 2,
            photoCount: 20,
            totalSize: 200_000_000,
            reclaimableSize: 200_000_000
        )

        let updated = stats.withSummary(summary)

        #expect(updated.groupSummaries[.screenshot] != nil)
        #expect(updated.groupSummaries[.screenshot]?.groupCount == 2)
    }

    @Test("withScannedCountsがカウントを更新する")
    func testWithScannedCounts() {
        let stats = StorageStatistics.empty
        let updated = stats.withScannedCounts(photos: 500, videos: 50)

        #expect(stats.scannedPhotoCount == 0)
        #expect(stats.scannedVideoCount == 0)
        #expect(updated.scannedPhotoCount == 500)
        #expect(updated.scannedVideoCount == 50)
    }
}

// MARK: - StorageStatistics Codable Tests

@Suite("StorageStatistics Codable テスト")
struct StorageStatisticsCodableTests {

    @Test("StorageStatisticsがエンコード・デコードできる")
    func testCodable() throws {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 0
        )
        let summaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 5,
                photoCount: 50,
                totalSize: 1_000_000_000,
                reclaimableSize: 800_000_000
            )
        ]
        let original = StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: summaries,
            scannedPhotoCount: 1000,
            scannedVideoCount: 100
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StorageStatistics.self, from: encoded)

        #expect(decoded.storageInfo == original.storageInfo)
        #expect(decoded.groupSummaries.count == original.groupSummaries.count)
        #expect(decoded.scannedPhotoCount == original.scannedPhotoCount)
        #expect(decoded.scannedVideoCount == original.scannedVideoCount)
    }
}

// MARK: - StorageStatistics Protocol Conformance Tests

@Suite("StorageStatistics プロトコル準拠テスト")
struct StorageStatisticsProtocolConformanceTests {

    @Test("StorageStatisticsがIdentifiable準拠している")
    func testIdentifiable() {
        let stats = StorageStatistics.empty
        let _ = stats.id // Identifiable要件（timestamp）
    }

    @Test("StorageStatisticsがHashable準拠している")
    func testHashable() {
        let stats1 = StorageStatistics.empty
        let stats2 = StorageStatistics.empty

        var set = Set<StorageStatistics>()
        set.insert(stats1)
        set.insert(stats2)
        // timestampが異なるので2つになる可能性あり
    }

    @Test("StorageStatisticsがSendable準拠している")
    func testSendable() async {
        let stats = StorageStatistics.empty

        let result = await Task.detached {
            stats.scannedPhotoCount
        }.value

        #expect(result == 0)
    }

    @Test("StorageStatisticsのdescriptionが期待通りの形式")
    func testCustomStringConvertible() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 20_000_000_000,
            reclaimableCapacity: 0
        )
        let stats = StorageStatistics(storageInfo: storageInfo)

        let description = stats.description
        #expect(description.contains("StorageStatistics"))
    }
}

// MARK: - Array+GroupSummary Extension Tests

@Suite("Array+GroupSummary 拡張テスト")
struct ArrayGroupSummaryExtensionTests {

    private func createSampleSummaries() -> [GroupSummary] {
        [
            GroupSummary(
                type: .similar,
                groupCount: 5,
                photoCount: 50,
                totalSize: 1_000_000_000,
                reclaimableSize: 800_000_000
            ),
            GroupSummary(
                type: .screenshot,
                groupCount: 3,
                photoCount: 30,
                totalSize: 500_000_000,
                reclaimableSize: 500_000_000
            ),
            GroupSummary(
                type: .blurry,
                groupCount: 2,
                photoCount: 20,
                totalSize: 200_000_000,
                reclaimableSize: 200_000_000
            )
        ]
    }

    @Test("totalReclaimableSizeが正しく計算される")
    func testTotalReclaimableSize() {
        let summaries = createSampleSummaries()
        #expect(summaries.totalReclaimableSize == 1_500_000_000)
    }

    @Test("totalPhotoCountが正しく計算される")
    func testTotalPhotoCount() {
        let summaries = createSampleSummaries()
        #expect(summaries.totalPhotoCount == 100)
    }

    @Test("totalGroupCountが正しく計算される")
    func testTotalGroupCount() {
        let summaries = createSampleSummaries()
        #expect(summaries.totalGroupCount == 10)
    }

    @Test("formattedTotalReclaimableSizeが文字列を返す")
    func testFormattedTotalReclaimableSize() {
        let summaries = createSampleSummaries()
        #expect(!summaries.formattedTotalReclaimableSize.isEmpty)
    }

    @Test("validSummariesが有効なサマリーのみを返す")
    func testValidSummaries() {
        var summaries = createSampleSummaries()
        summaries.append(GroupSummary.empty(for: .selfie))

        let valid = summaries.validSummaries
        #expect(valid.count == 3)
    }

    @Test("sortedByTypeがsortOrder順でソートする")
    func testSortedByType() {
        let summaries = createSampleSummaries()
        let sorted = summaries.sortedByType

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].type.sortOrder < sorted[i + 1].type.sortOrder)
        }
    }

    @Test("sortedByReclaimableSizeが削減可能サイズ順でソートする")
    func testSortedByReclaimableSize() {
        let summaries = createSampleSummaries()
        let sorted = summaries.sortedByReclaimableSize

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].reclaimableSize >= sorted[i + 1].reclaimableSize)
        }
    }
}

// MARK: - Edge Case Tests

@Suite("StorageStatistics エッジケーステスト")
struct StorageStatisticsEdgeCaseTests {

    @Test("最大値のInt64を処理できる")
    func testMaxInt64() {
        let summary = GroupSummary(
            type: .similar,
            groupCount: 1,
            photoCount: 1,
            totalSize: Int64.max,
            reclaimableSize: Int64.max
        )
        #expect(summary.totalSize == Int64.max)
    }

    @Test("全てのGroupTypeでサマリーを持つStorageStatistics")
    func testAllGroupTypes() {
        var summaries: [GroupType: GroupSummary] = [:]
        for type in GroupType.allCases {
            summaries[type] = GroupSummary(
                type: type,
                groupCount: 1,
                photoCount: 10,
                totalSize: 100_000_000,
                reclaimableSize: 50_000_000
            )
        }

        let stats = StorageStatistics(
            storageInfo: StorageInfo.empty,
            groupSummaries: summaries
        )

        #expect(stats.groupSummaries.count == GroupType.allCases.count)
        #expect(stats.sortedGroupSummaries.count == GroupType.allCases.count)
    }

    @Test("空のPhotoGroup配列からStorageStatisticsを生成")
    func testEmptyPhotoGroupsArray() {
        let stats = StorageStatistics(
            storageInfo: StorageInfo.empty,
            groups: []
        )

        #expect(stats.groupSummaries.isEmpty)
        #expect(stats.totalReclaimableSize == 0)
    }
}
