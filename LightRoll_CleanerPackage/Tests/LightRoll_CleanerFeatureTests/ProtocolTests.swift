//
//  ProtocolTests.swift
//  LightRoll_CleanerFeatureTests
//
//  Protocol定義のユニットテスト
//  プロトコルの型定義とモック実装の検証
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - UseCase Protocol Tests

@Suite("UseCase Protocols Tests")
struct UseCaseProtocolTests {

    // MARK: - DeletePhotosInput Tests

    @Test("DeletePhotosInputが正しく初期化される")
    func deletePhotosInputInitialization() {
        let photo1 = PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)
        let photo2 = PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 2000)

        let input = DeletePhotosInput(photos: [photo1, photo2], permanently: true)

        #expect(input.photos.count == 2)
        #expect(input.permanently == true)
    }

    @Test("DeletePhotosInputのデフォルト値が正しい")
    func deletePhotosInputDefaultValues() {
        let photo = PhotoAsset(id: "photo1")

        let input = DeletePhotosInput(photos: [photo])

        #expect(input.permanently == false)
    }

    // MARK: - DeletePhotosOutput Tests

    @Test("DeletePhotosOutputの成功判定が正しい")
    func deletePhotosOutputSuccess() {
        let output = DeletePhotosOutput(
            deletedCount: 5,
            freedBytes: 1024 * 1024 * 10,
            failedIds: []
        )

        #expect(output.isFullySuccessful == true)
        #expect(output.deletedCount == 5)
    }

    @Test("DeletePhotosOutputの失敗判定が正しい")
    func deletePhotosOutputPartialFailure() {
        let output = DeletePhotosOutput(
            deletedCount: 3,
            freedBytes: 1024 * 1024 * 5,
            failedIds: ["photo1", "photo2"]
        )

        #expect(output.isFullySuccessful == false)
        #expect(output.failedIds.count == 2)
    }

    @Test("DeletePhotosOutputのフォーマットが正しい")
    func deletePhotosOutputFormatting() {
        let output = DeletePhotosOutput(
            deletedCount: 10,
            freedBytes: 1024 * 1024 * 100, // 100MB
            failedIds: []
        )

        #expect(!output.formattedFreedBytes.isEmpty)
    }

    // MARK: - RestorePhotosOutput Tests

    @Test("RestorePhotosOutputが正しく機能する")
    func restorePhotosOutput() {
        let successOutput = RestorePhotosOutput(restoredCount: 5, failedIds: [])
        let partialOutput = RestorePhotosOutput(restoredCount: 3, failedIds: ["id1"])

        #expect(successOutput.isFullySuccessful == true)
        #expect(partialOutput.isFullySuccessful == false)
    }

    // MARK: - AnalysisOptions Tests

    @Test("AnalysisOptionsのデフォルト値が全て有効")
    func analysisOptionsDefault() {
        let options = AnalysisOptions.default

        #expect(options.detectFaces == true)
        #expect(options.detectBlur == true)
        #expect(options.detectScreenshot == true)
        #expect(options.calculateQuality == true)
    }

    @Test("AnalysisOptionsの高速モードが正しい")
    func analysisOptionsFast() {
        let options = AnalysisOptions.fast

        #expect(options.detectFaces == true)
        #expect(options.detectBlur == false)
        #expect(options.detectScreenshot == false)
        #expect(options.calculateQuality == false)
    }

    // MARK: - BestShotCriteria Tests

    @Test("BestShotCriteriaのデフォルト値が正しい")
    func bestShotCriteriaDefault() {
        let criteria = BestShotCriteria.default

        #expect(criteria.qualityWeight == 0.5)
        #expect(criteria.faceQualityWeight == 0.3)
        #expect(criteria.compositionWeight == 0.2)
    }

    // MARK: - DeletionLimitStatus Tests

    @Test("DeletionLimitStatusの残り数計算が正しい")
    func deletionLimitStatusRemaining() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 30,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.remainingCount == 20)
        #expect(status.canDelete == true)
    }

    @Test("DeletionLimitStatusの制限超過判定が正しい")
    func deletionLimitStatusExceeded() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 50,
            dailyLimit: 50,
            premiumStatus: .free
        )

        #expect(status.remainingCount == 0)
        #expect(status.canDelete == false)
        #expect(status.canDelete(count: 1) == false)
    }

    @Test("プレミアムユーザーは制限なし")
    func deletionLimitStatusPremium() {
        let status = DeletionLimitStatus(
            todayDeletedCount: 100,
            dailyLimit: 50,
            premiumStatus: .premium
        )

        #expect(status.canDelete == true)
        #expect(status.canDelete(count: 1000) == true)
    }

    // MARK: - StatisticsOutput Tests

    @Test("StatisticsOutputが正しく初期化される")
    func statisticsOutput() {
        let storageInfo = StorageInfo(
            totalCapacity: 128 * 1024 * 1024 * 1024,       // 128GB
            availableCapacity: 64 * 1024 * 1024 * 1024,    // 64GB 空き
            photosUsedCapacity: 30 * 1024 * 1024 * 1024,   // 30GB 写真
            reclaimableCapacity: 5 * 1024 * 1024 * 1024    // 5GB 削減可能
        )

        let stats = GroupStatistics(
            similarGroupCount: 10,
            screenshotCount: 50,
            blurryCount: 25,
            largeVideoCount: 5,
            trashCount: 15
        )

        let output = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: 1000,
            groupStatistics: stats
        )

        #expect(output.totalPhotos == 1000)
        #expect(output.groupStatistics.totalDeletionCandidates == 90) // 10+50+25+5
    }
}

// MARK: - ViewModel State Tests

@Suite("ViewModel State Tests")
struct ViewModelStateTests {

    // MARK: - HomeViewState Tests

    @Test("HomeViewStateの等価性が正しい")
    func homeViewStateEquality() {
        let state1 = HomeViewState.initial
        let state2 = HomeViewState.initial
        let state3 = HomeViewState.loading

        #expect(state1 == state2)
        #expect(state1 != state3)
    }

    @Test("HomeViewDataが正しく初期化される")
    func homeViewData() {
        let storageInfo = StorageInfo.empty
        let data = HomeViewData(storageInfo: storageInfo)

        #expect(data.groups.isEmpty)
        #expect(data.lastScanResult == nil)
    }

    // MARK: - GroupDetailViewState Tests

    @Test("GroupDetailViewStateの状態遷移")
    func groupDetailViewState() {
        let states: [GroupDetailViewState] = [
            .initial,
            .loadingThumbnails,
            .ready,
            .deleting,
            .error("test error")
        ]

        #expect(states.count == 5)
        #expect(states[0] == .initial)
    }

    // MARK: - TrashViewState Tests

    @Test("TrashPhotoItemの期限判定が正しい")
    func trashPhotoItemExpiry() {
        let photo = PhotoAsset(id: "test")

        // 2日後に削除される場合
        let nearExpiry = TrashPhotoItem(
            photo: photo,
            trashedDate: Date(),
            daysUntilDeletion: 2
        )

        // 10日後に削除される場合
        let notNearExpiry = TrashPhotoItem(
            photo: photo,
            trashedDate: Date(),
            daysUntilDeletion: 10
        )

        #expect(nearExpiry.isNearExpiry == true)
        #expect(notNearExpiry.isNearExpiry == false)
    }
}

// MARK: - Service Protocol Types Tests

@Suite("Service Protocol Types Tests")
struct ServiceProtocolTypesTests {

    // MARK: - TrashPhoto Tests

    @Test("TrashPhotoの削除日計算が正しい")
    func trashPhotoDeletionDate() {
        let photo = PhotoAsset(id: "test")
        let trashedDate = Date()
        let trashPhoto = TrashPhoto(photo: photo, trashedDate: trashedDate)

        let deletionDate = trashPhoto.deletionDate(retentionDays: 30)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 30, to: trashedDate)!

        #expect(Calendar.current.isDate(deletionDate, inSameDayAs: expectedDate))
    }

    @Test("TrashPhotoの残り日数計算が正しい")
    func trashPhotoDaysUntilDeletion() {
        let photo = PhotoAsset(id: "test")
        let trashedDate = Date()
        let trashPhoto = TrashPhoto(photo: photo, trashedDate: trashedDate)

        let daysRemaining = trashPhoto.daysUntilDeletion(retentionDays: 30)

        // 今日ゴミ箱に入れたので、約30日残っているはず
        #expect(daysRemaining >= 29 && daysRemaining <= 30)
    }

    // MARK: - NotificationContent Tests

    @Test("NotificationContentが正しく初期化される")
    func notificationContent() {
        let content = NotificationContent(
            title: "テスト通知",
            body: "これはテストです",
            badge: 5,
            userInfo: ["key": "value"]
        )

        #expect(content.title == "テスト通知")
        #expect(content.body == "これはテストです")
        #expect(content.badge == 5)
        #expect(content.userInfo["key"] == "value")
    }

    // MARK: - PermissionStatus Tests

    @Test("PermissionStatusの全ケースが存在する")
    func permissionStatusCases() {
        let statuses: [PermissionStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorized,
            .limited
        ]

        #expect(statuses.count == 5)
    }

    // MARK: - PremiumFeature Tests

    @Test("PremiumFeatureの全ケースが存在する")
    func premiumFeatureCases() {
        let features = PremiumFeature.allCases

        #expect(features.contains(.unlimitedDeletion))
        #expect(features.contains(.adFree))
        #expect(features.contains(.advancedAnalysis))
        #expect(features.contains(.cloudBackup))
    }
}

// MARK: - Mock Implementation Tests

@Suite("Mock Implementation Conformance Tests")
struct MockImplementationTests {

    // MARK: - Repository Protocol Conformance

    @Test("MockPhotoRepositoryがプロトコルに準拠している")
    func mockPhotoRepositoryConformance() async throws {
        let mock = MockPhotoRepository()
        mock.mockPhotos = [PhotoAsset(id: "test")]

        let photos = try await mock.fetchAllPhotos()

        #expect(mock.fetchAllPhotosCalled == true)
        #expect(photos.count == 1)
    }

    @Test("MockAnalysisRepositoryがプロトコルに準拠している")
    func mockAnalysisRepositoryConformance() async throws {
        let mock = MockAnalysisRepository()
        let photo = PhotoAsset(id: "test")

        let result = try await mock.analyzePhoto(photo)

        #expect(result.photoId == "test")
    }

    @Test("MockStorageRepositoryがプロトコルに準拠している")
    func mockStorageRepositoryConformance() async {
        let mock = MockStorageRepository()
        mock.mockStorageInfo = StorageInfo(
            totalCapacity: 100,
            availableCapacity: 50,
            photosUsedCapacity: 30,
            reclaimableCapacity: 10
        )

        let info = await mock.fetchStorageInfo()

        #expect(info.totalCapacity == 100)
        #expect(info.availableCapacity == 50)
    }

    @Test("MockSettingsRepositoryがプロトコルに準拠している")
    func mockSettingsRepositoryConformance() {
        let mock = MockSettingsRepository()
        let newSettings = UserSettings(similarityThreshold: 0.9)

        mock.save(newSettings)
        let loaded = mock.load()

        #expect(mock.saveCalled == true)
        #expect(loaded.similarityThreshold == 0.9)
    }

    @Test("MockPurchaseRepositoryがプロトコルに準拠している")
    func mockPurchaseRepositoryConformance() async throws {
        let mock = MockPurchaseRepository()
        mock.mockPremiumStatus = .premium

        let status = await mock.getPremiumStatus()
        let result = try await mock.purchase("test_product")

        #expect(status == .premium)
        #expect(mock.purchaseCalled == true)

        if case .success = result {
            // 成功
        } else {
            Issue.record("購入結果が成功ではありません")
        }
    }
}

// MARK: - Sendable Conformance Tests

@Suite("Sendable Conformance Tests")
struct SendableConformanceTests {

    @Test("DeletePhotosInputがSendable")
    func deletePhotosInputSendable() async {
        let input = DeletePhotosInput(photos: [], permanently: false)

        // Sendableの検証：別のTaskに渡せることを確認
        await Task {
            _ = input.photos
        }.value
    }

    @Test("DeletePhotosOutputがSendable")
    func deletePhotosOutputSendable() async {
        let output = DeletePhotosOutput(deletedCount: 1, freedBytes: 100, failedIds: [])

        await Task {
            _ = output.deletedCount
        }.value
    }

    @Test("StatisticsOutputがSendable")
    func statisticsOutputSendable() async {
        let output = StatisticsOutput(
            storageInfo: StorageInfo.empty,
            totalPhotos: 100
        )

        await Task {
            _ = output.totalPhotos
        }.value
    }

    @Test("HomeViewStateがSendable")
    func homeViewStateSendable() async {
        let state = HomeViewState.loading

        await Task {
            _ = state
        }.value
    }

    @Test("TrashPhotoがSendable")
    func trashPhotoSendable() async {
        let photo = PhotoAsset(id: "test")
        let trashPhoto = TrashPhoto(photo: photo)

        await Task {
            _ = trashPhoto.id
        }.value
    }
}
