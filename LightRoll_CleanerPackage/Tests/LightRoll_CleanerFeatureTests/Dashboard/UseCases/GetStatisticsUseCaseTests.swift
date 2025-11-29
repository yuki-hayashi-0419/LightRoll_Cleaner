//
//  GetStatisticsUseCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GetStatisticsUseCaseの包括的な単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing

@testable import LightRoll_CleanerFeature

// MARK: - GetStatisticsUseCaseError Tests

@Suite("GetStatisticsUseCaseError テスト")
struct GetStatisticsUseCaseErrorTests {

    @Test("photoAccessDeniedエラーの説明文が正しい")
    func testPhotoAccessDeniedErrorDescription() {
        let error = GetStatisticsUseCaseError.photoAccessDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("許可"))
    }

    @Test("storageInfoUnavailableエラーの説明文が正しい")
    func testStorageInfoUnavailableErrorDescription() {
        let error = GetStatisticsUseCaseError.storageInfoUnavailable
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("ストレージ"))
    }

    @Test("fetchFailedエラーが理由を含む")
    func testFetchFailedErrorWithReason() {
        let reason = "データベースエラー"
        let error = GetStatisticsUseCaseError.fetchFailed(reason: reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("photoAccessDeniedのリカバリー提案がある")
    func testPhotoAccessDeniedRecoverySuggestion() {
        let error = GetStatisticsUseCaseError.photoAccessDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("設定"))
    }

    @Test("storageInfoUnavailableのリカバリー提案がある")
    func testStorageInfoUnavailableRecoverySuggestion() {
        let error = GetStatisticsUseCaseError.storageInfoUnavailable
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("再起動"))
    }

    @Test("fetchFailedのリカバリー提案がある")
    func testFetchFailedRecoverySuggestion() {
        let error = GetStatisticsUseCaseError.fetchFailed(reason: "エラー")
        #expect(error.recoverySuggestion != nil)
    }
}

// MARK: - GetStatisticsUseCaseError Equatable Tests

@Suite("GetStatisticsUseCaseError Equatable テスト")
struct GetStatisticsUseCaseErrorEquatableTests {

    @Test("同じphotoAccessDeniedエラーは等しい")
    func testPhotoAccessDeniedEquatable() {
        let error1 = GetStatisticsUseCaseError.photoAccessDenied
        let error2 = GetStatisticsUseCaseError.photoAccessDenied
        #expect(error1 == error2)
    }

    @Test("同じstorageInfoUnavailableエラーは等しい")
    func testStorageInfoUnavailableEquatable() {
        let error1 = GetStatisticsUseCaseError.storageInfoUnavailable
        let error2 = GetStatisticsUseCaseError.storageInfoUnavailable
        #expect(error1 == error2)
    }

    @Test("同じ理由のfetchFailedエラーは等しい")
    func testFetchFailedEquatable() {
        let error1 = GetStatisticsUseCaseError.fetchFailed(reason: "同じ理由")
        let error2 = GetStatisticsUseCaseError.fetchFailed(reason: "同じ理由")
        #expect(error1 == error2)
    }

    @Test("異なる理由のfetchFailedエラーは等しくない")
    func testFetchFailedNotEquatable() {
        let error1 = GetStatisticsUseCaseError.fetchFailed(reason: "理由1")
        let error2 = GetStatisticsUseCaseError.fetchFailed(reason: "理由2")
        #expect(error1 != error2)
    }

    @Test("異なるエラータイプは等しくない")
    func testDifferentErrorTypesNotEquatable() {
        let error1 = GetStatisticsUseCaseError.photoAccessDenied
        let error2 = GetStatisticsUseCaseError.storageInfoUnavailable
        #expect(error1 != error2)
    }
}

// MARK: - StatisticsOutput Tests

@Suite("StatisticsOutput テスト")
struct StatisticsOutputUseCaseTests {

    @Test("StatisticsOutputを正しく初期化できる")
    func testStatisticsOutputInitialization() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let output = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        #expect(output.totalPhotos == 1000)
        #expect(output.storageInfo.totalCapacity == 128_000_000_000)
        #expect(output.lastScanDate == nil)
    }

    @Test("StatisticsOutputにグループ統計を設定できる")
    func testStatisticsOutputWithGroupStatistics() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let groupStats = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 20,
            largeVideoCount: 5,
            trashCount: 15
        )

        let output = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000,
            groupStatistics: groupStats
        )

        #expect(output.groupStatistics.similarGroupCount == 10)
        #expect(output.groupStatistics.screenshotCount == 50)
        #expect(output.groupStatistics.blurryCount == 20)
        #expect(output.groupStatistics.largeVideoCount == 5)
        #expect(output.groupStatistics.trashCount == 15)
    }

    @Test("StatisticsOutputに最終スキャン日時を設定できる")
    func testStatisticsOutputWithLastScanDate() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let lastScan = Date()

        let output = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000,
            lastScanDate: lastScan
        )

        #expect(output.lastScanDate == lastScan)
    }
}

// MARK: - GroupStatistics Tests

@Suite("GroupStatistics UseCase テスト")
struct GroupStatisticsUseCaseTests {

    @Test("空のGroupStatisticsを作成できる")
    func testEmptyGroupStatistics() {
        let stats = GroupStatistics()
        #expect(stats.similarGroupCount == 0)
        #expect(stats.screenshotCount == 0)
        #expect(stats.blurryCount == 0)
        #expect(stats.largeVideoCount == 0)
        #expect(stats.trashCount == 0)
    }

    @Test("GroupStatisticsの全プロパティを設定できる")
    func testGroupStatisticsAllProperties() {
        let stats = GroupStatistics(
            similarGroupCount: 15,
            screenshotCount: 100,
            blurryCount: 30,
            largeVideoCount: 10,
            trashCount: 25
        )

        #expect(stats.similarGroupCount == 15)
        #expect(stats.screenshotCount == 100)
        #expect(stats.blurryCount == 30)
        #expect(stats.largeVideoCount == 10)
        #expect(stats.trashCount == 25)
    }

    @Test("totalDeletionCandidatesを正しく計算できる")
    func testTotalDeletionCandidates() {
        let stats = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 20,
            largeVideoCount: 5,
            trashCount: 15
        )

        // totalDeletionCandidates = similarGroupCount + screenshotCount + blurryCount + largeVideoCount
        #expect(stats.totalDeletionCandidates == 85)
    }

    @Test("trashCountはtotalDeletionCandidatesに含まれない")
    func testTrashCountNotInTotal() {
        let stats = GroupStatistics(
            similarGroupCount: 0,
            screenshotCount: 0,
            blurryCount: 0,
            largeVideoCount: 0,
            trashCount: 100
        )

        #expect(stats.totalDeletionCandidates == 0)
    }
}

// MARK: - GroupStatistics Equatable Tests

@Suite("GroupStatistics Equatable UseCase テスト")
struct GroupStatisticsEquatableUseCaseTests {

    @Test("同じ値のGroupStatisticsは等しい")
    func testGroupStatisticsEquatable() {
        let stats1 = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 20,
            largeVideoCount: 5,
            trashCount: 15
        )
        let stats2 = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 20,
            largeVideoCount: 5,
            trashCount: 15
        )

        #expect(stats1 == stats2)
    }

    @Test("異なる値のGroupStatisticsは等しくない")
    func testGroupStatisticsNotEquatable() {
        let stats1 = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 20,
            largeVideoCount: 5,
            trashCount: 15
        )
        let stats2 = GroupStatistics(
            similarGroupCount: 20,
            screenshotCount: 100,
            blurryCount: 40,
            largeVideoCount: 10,
            trashCount: 30
        )

        #expect(stats1 != stats2)
    }
}

// MARK: - StatisticsOutput Equatable Tests

@Suite("StatisticsOutput Equatable UseCase テスト")
struct StatisticsOutputEquatableUseCaseTests {

    @Test("同じ値のStatisticsOutputは等しい")
    func testStatisticsOutputEquatable() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let lastScan = Date(timeIntervalSince1970: 1700000000)

        let output1 = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000,
            lastScanDate: lastScan
        )
        let output2 = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000,
            lastScanDate: lastScan
        )

        #expect(output1 == output2)
    }

    @Test("異なる写真数のStatisticsOutputは等しくない")
    func testStatisticsOutputNotEquatableByPhotoCount() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        let output1 = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )
        let output2 = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 2000
        )

        #expect(output1 != output2)
    }
}

// MARK: - ExtendedStatistics Tests

@Suite("ExtendedStatistics UseCase テスト")
struct ExtendedStatisticsUseCaseTests {

    @Test("ExtendedStatisticsを正しく初期化できる")
    func testExtendedStatisticsInitialization() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let extended = ExtendedStatistics(basicStats: basicStats)

        #expect(extended.basicStats.totalPhotos == 1000)
        #expect(extended.storageStatistics == nil)
        #expect(extended.cleanupStatistics == .empty)
        #expect(extended.timeSinceLastScan == nil)
    }

    @Test("shouldRecommendScanは7日以上で推奨する")
    func testShouldRecommendScanAfterSevenDays() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        // 8日経過
        let eightDays: TimeInterval = 8 * 24 * 60 * 60
        let extended = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: eightDays
        )

        #expect(extended.shouldRecommendScan == true)
    }

    @Test("shouldRecommendScanは7日未満で推奨しない")
    func testShouldNotRecommendScanWithinSevenDays() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        // 3日経過
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        let extended = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: threeDays
        )

        #expect(extended.shouldRecommendScan == false)
    }

    @Test("shouldRecommendScanはスキャン未実行で推奨する")
    func testShouldRecommendScanWhenNeverScanned() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let extended = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: nil
        )

        #expect(extended.shouldRecommendScan == true)
    }

    @Test("formattedTimeSinceLastScanがnilを返す")
    func testFormattedTimeSinceLastScanNil() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let extended = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: nil
        )

        #expect(extended.formattedTimeSinceLastScan == nil)
    }

    @Test("formattedTimeSinceLastScanが値を返す")
    func testFormattedTimeSinceLastScanWithValue() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        let extended = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: twoDays
        )

        #expect(extended.formattedTimeSinceLastScan != nil)
    }
}

// MARK: - ExtendedStatistics Cleanup Statistics Tests

@Suite("ExtendedStatistics クリーンアップ統計 UseCase テスト")
struct ExtendedStatisticsCleanupUseCaseTests {

    @Test("totalFreedSpaceを正しく取得できる")
    func testTotalFreedSpace() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let cleanupStats = CleanupRecordStatistics(
            totalRecords: 10,
            totalDeletedCount: 100,
            totalFreedSpace: 1_073_741_824, // 1GB
            countByOperationType: [:],
            deletedCountByGroupType: [:],
            latestCleanupDate: nil,
            oldestCleanupDate: nil
        )

        let extended = ExtendedStatistics(
            basicStats: basicStats,
            cleanupStatistics: cleanupStats
        )

        #expect(extended.totalFreedSpace == 1_073_741_824)
    }

    @Test("totalDeletedCountを正しく取得できる")
    func testTotalDeletedCount() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let cleanupStats = CleanupRecordStatistics(
            totalRecords: 10,
            totalDeletedCount: 150,
            totalFreedSpace: 500_000_000,
            countByOperationType: [:],
            deletedCountByGroupType: [:],
            latestCleanupDate: nil,
            oldestCleanupDate: nil
        )

        let extended = ExtendedStatistics(
            basicStats: basicStats,
            cleanupStatistics: cleanupStats
        )

        #expect(extended.totalDeletedCount == 150)
    }

    @Test("formattedTotalFreedSpaceが正しくフォーマットされる")
    func testFormattedTotalFreedSpace() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let cleanupStats = CleanupRecordStatistics(
            totalRecords: 10,
            totalDeletedCount: 100,
            totalFreedSpace: 1_073_741_824, // 1GB
            countByOperationType: [:],
            deletedCountByGroupType: [:],
            latestCleanupDate: nil,
            oldestCleanupDate: nil
        )

        let extended = ExtendedStatistics(
            basicStats: basicStats,
            cleanupStatistics: cleanupStats
        )

        #expect(!extended.formattedTotalFreedSpace.isEmpty)
    }
}

// MARK: - ExtendedStatistics Equatable Tests

@Suite("ExtendedStatistics Equatable UseCase テスト")
struct ExtendedStatisticsEquatableUseCaseTests {

    @Test("同じ値のExtendedStatisticsは等しい")
    func testExtendedStatisticsEquatable() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let extended1 = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: 86400
        )
        let extended2 = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: 86400
        )

        #expect(extended1 == extended2)
    }

    @Test("異なる値のExtendedStatisticsは等しくない")
    func testExtendedStatisticsNotEquatable() {
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 32_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        let basicStats = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000
        )

        let extended1 = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: 86400
        )
        let extended2 = ExtendedStatistics(
            basicStats: basicStats,
            timeSinceLastScan: 172800
        )

        #expect(extended1 != extended2)
    }
}

// MARK: - DeletionLimitStatus Tests

@Suite("DeletionLimitStatus UseCase テスト")
struct DeletionLimitStatusUseCaseTests {

    @Test("DeletionLimitStatusを正しく初期化できる")
    func testDeletionLimitStatusInitialization() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 10,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.todayDeletedCount == 10)
        #expect(status.dailyLimit == 50)
        #expect(status.remainingCount == 40)
        #expect(status.premiumStatus == .free)
    }

    @Test("remainingCountが正しく計算される")
    func testRemainingCountCalculation() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 30,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.remainingCount == 20)
    }

    @Test("remainingCountが0未満にならない")
    func testRemainingCountNonNegative() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 100,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.remainingCount == 0)
    }

    @Test("canDeleteは残数があればtrue")
    func testCanDeleteWithRemaining() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 10,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.canDelete == true)
    }

    @Test("canDeleteは残数がなければfalse")
    func testCanDeleteWithoutRemaining() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 50,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.canDelete == false)
    }

    @Test("canDeleteはプレミアムなら常にtrue")
    func testCanDeleteAlwaysTrueForPremium() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 1000,
            dailyLimit: 50,
            premiumStatus: .premium
        )

        #expect(status.canDelete == true)
    }

    @Test("canDelete(count:)は指定数削除可能か判定")
    func testCanDeleteCount() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 40,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.canDelete(count: 5) == true)
        #expect(status.canDelete(count: 10) == true)
        #expect(status.canDelete(count: 15) == false)
    }

    @Test("canDelete(count:)はプレミアムなら常にtrue")
    func testCanDeleteCountAlwaysTrueForPremium() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 1000,
            dailyLimit: 50,
            premiumStatus: .premium
        )

        #expect(status.canDelete(count: 9999) == true)
    }
}

// MARK: - DeletionLimitStatus Equatable Tests

@Suite("DeletionLimitStatus Equatable UseCase テスト")
struct DeletionLimitStatusEquatableUseCaseTests {

    @Test("同じ値のDeletionLimitStatusは等しい")
    func testDeletionLimitStatusEquatable() {
        let status1 = DeletionLimitStatus(
            todayDeletedCount: 10,
            dailyLimit: 50,
            premiumStatus: .free
        )
        let status2 = DeletionLimitStatus(
            todayDeletedCount: 10,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status1 == status2)
    }

    @Test("異なる値のDeletionLimitStatusは等しくない")
    func testDeletionLimitStatusNotEquatable() {
        let status1 = DeletionLimitStatus(
            todayDeletedCount: 10,
            dailyLimit: 50,
            premiumStatus: .free
        )
        let status2 = DeletionLimitStatus(
            todayDeletedCount: 20,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status1 != status2)
    }
}

// MARK: - DeletePhotosOutput Tests

@Suite("DeletePhotosOutput UseCase テスト")
struct DeletePhotosOutputUseCaseTests {

    @Test("DeletePhotosOutputを正しく初期化できる")
    func testDeletePhotosOutputInitialization() {
        let output = DeletePhotosOutput(
            deletedCount: 10,
            freedBytes: 1_000_000
        )

        #expect(output.deletedCount == 10)
        #expect(output.freedBytes == 1_000_000)
        #expect(output.failedIds.isEmpty)
    }

    @Test("失敗IDを含むDeletePhotosOutputを初期化できる")
    func testDeletePhotosOutputWithFailedIds() {
        let output = DeletePhotosOutput(
            deletedCount: 8,
            freedBytes: 800_000,
            failedIds: ["id1", "id2"]
        )

        #expect(output.deletedCount == 8)
        #expect(output.failedIds.count == 2)
        #expect(output.failedIds.contains("id1"))
    }

    @Test("isFullySuccessfulは失敗がなければtrue")
    func testIsFullySuccessfulTrue() {
        let output = DeletePhotosOutput(
            deletedCount: 10,
            freedBytes: 1_000_000
        )

        #expect(output.isFullySuccessful == true)
    }

    @Test("isFullySuccessfulは失敗があればfalse")
    func testIsFullySuccessfulFalse() {
        let output = DeletePhotosOutput(
            deletedCount: 8,
            freedBytes: 800_000,
            failedIds: ["id1"]
        )

        #expect(output.isFullySuccessful == false)
    }

    @Test("formattedFreedBytesが正しくフォーマットされる")
    func testFormattedFreedBytes() {
        let output = DeletePhotosOutput(
            deletedCount: 10,
            freedBytes: 1_073_741_824 // 1GB
        )

        #expect(!output.formattedFreedBytes.isEmpty)
    }
}

// MARK: - RestorePhotosOutput Tests

@Suite("RestorePhotosOutput UseCase テスト")
struct RestorePhotosOutputUseCaseTests {

    @Test("RestorePhotosOutputを正しく初期化できる")
    func testRestorePhotosOutputInitialization() {
        let output = RestorePhotosOutput(restoredCount: 5)

        #expect(output.restoredCount == 5)
        #expect(output.failedIds.isEmpty)
    }

    @Test("失敗IDを含むRestorePhotosOutputを初期化できる")
    func testRestorePhotosOutputWithFailedIds() {
        let output = RestorePhotosOutput(
            restoredCount: 3,
            failedIds: ["id1", "id2"]
        )

        #expect(output.restoredCount == 3)
        #expect(output.failedIds.count == 2)
    }

    @Test("isFullySuccessfulは失敗がなければtrue")
    func testIsFullySuccessfulTrue() {
        let output = RestorePhotosOutput(restoredCount: 5)
        #expect(output.isFullySuccessful == true)
    }

    @Test("isFullySuccessfulは失敗があればfalse")
    func testIsFullySuccessfulFalse() {
        let output = RestorePhotosOutput(
            restoredCount: 3,
            failedIds: ["id1"]
        )
        #expect(output.isFullySuccessful == false)
    }
}

// MARK: - SelectBestShotOutput Tests

@Suite("SelectBestShotOutput UseCase テスト")
struct SelectBestShotOutputUseCaseTests {

    @Test("SelectBestShotOutputを正しく初期化できる")
    func testSelectBestShotOutputInitialization() {
        let output = SelectBestShotOutput(
            bestShotIndex: 2,
            bestShotId: "photo-123",
            scores: [0.7, 0.8, 0.95, 0.6]
        )

        #expect(output.bestShotIndex == 2)
        #expect(output.bestShotId == "photo-123")
        #expect(output.scores.count == 4)
        #expect(output.scores[2] == 0.95)
    }
}

// MARK: - AnalysisOptions Tests

@Suite("AnalysisOptions UseCase テスト")
struct AnalysisOptionsUseCaseTests {

    @Test("デフォルトオプションは全て有効")
    func testDefaultOptions() {
        let options = AnalysisOptions.default

        #expect(options.detectFaces == true)
        #expect(options.detectBlur == true)
        #expect(options.detectScreenshot == true)
        #expect(options.calculateQuality == true)
    }

    @Test("高速オプションは顔検出のみ有効")
    func testFastOptions() {
        let options = AnalysisOptions.fast

        #expect(options.detectFaces == true)
        #expect(options.detectBlur == false)
        #expect(options.detectScreenshot == false)
        #expect(options.calculateQuality == false)
    }

    @Test("カスタムオプションを設定できる")
    func testCustomOptions() {
        let options = AnalysisOptions(
            detectFaces: false,
            detectBlur: true,
            detectScreenshot: false,
            calculateQuality: true
        )

        #expect(options.detectFaces == false)
        #expect(options.detectBlur == true)
        #expect(options.detectScreenshot == false)
        #expect(options.calculateQuality == true)
    }
}

// MARK: - BestShotCriteria Tests

@Suite("BestShotCriteria UseCase テスト")
struct BestShotCriteriaUseCaseTests {

    @Test("デフォルト基準を取得できる")
    func testDefaultCriteria() {
        let criteria = BestShotCriteria.default

        #expect(criteria.qualityWeight == 0.5)
        #expect(criteria.faceQualityWeight == 0.3)
        #expect(criteria.compositionWeight == 0.2)
    }

    @Test("カスタム基準を設定できる")
    func testCustomCriteria() {
        let criteria = BestShotCriteria(
            qualityWeight: 0.4,
            faceQualityWeight: 0.4,
            compositionWeight: 0.2
        )

        #expect(criteria.qualityWeight == 0.4)
        #expect(criteria.faceQualityWeight == 0.4)
        #expect(criteria.compositionWeight == 0.2)
    }
}
