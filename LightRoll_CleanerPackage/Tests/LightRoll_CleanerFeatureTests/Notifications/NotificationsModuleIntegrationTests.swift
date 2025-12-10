//
//  NotificationsModuleIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  通知モジュール統合テスト（範囲縮小版）
//  - E2Eシナリオ: 5テストケース
//  - エラーハンドリング: 3テストケース
//  Created by AI Assistant for M7-T12
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature
@preconcurrency import UserNotifications

// MARK: - E2E Scenario Tests

@Suite("通知モジュールE2Eシナリオテスト")
@MainActor
struct NotificationsModuleE2ETests {

    // MARK: - Test 1: ストレージ警告フロー

    @Test("E2E: ストレージ警告フロー - 容量チェック → 通知スケジュール確認")
    func storageAlertFlow() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.9
        settings.quietHoursEnabled = false

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = TestMockStorageService()
        mockStorageService.mockStorageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 5_000_000_000,
            photosUsedCapacity: 95_000_000_000,
            reclaimableCapacity: 0
        )

        let photoRepository = PhotoRepository(
            permissionManager: mockPermission,
            storageService: mockStorageService
        )

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act
        let result = try await scheduler.checkAndScheduleIfNeeded()

        // Assert
        #expect(result == true)
        #expect(scheduler.isNotificationScheduled == true)
        #expect(scheduler.lastUsagePercentage >= 0.9)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "storage_alert")
    }

    // MARK: - Test 2: リマインダーフロー

    @Test("E2E: リマインダーフロー - リマインダースケジュール → 再スケジュール確認")
    func reminderFlow() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true
        settings.reminderInterval = .daily
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act - 初回スケジュール
        let firstDate = try await scheduler.scheduleReminder()

        #expect(scheduler.isReminderScheduled == true)
        #expect(scheduler.lastScheduledInterval == .daily)

        // 設定変更
        var newSettings = notificationManager.settings
        newSettings.reminderInterval = .weekly
        try notificationManager.updateSettings(newSettings)

        // 再スケジュール
        let secondDate = try await scheduler.rescheduleReminder()

        // Assert
        #expect(scheduler.isReminderScheduled == true)
        #expect(scheduler.lastScheduledInterval == .weekly)
        #expect(firstDate != secondDate)
    }

    // MARK: - Test 3: スキャン完了フロー

    @Test("E2E: スキャン完了フロー - スキャン完了通知 → 通知内容確認")
    func scanCompletionFlow() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let notifier = ScanCompletionNotifier(notificationManager: notificationManager)

        // Act
        let itemCount = 10
        let totalSize: Int64 = 1024 * 1024 * 100 // 100MB

        try await notifier.notifyScanCompletion(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Assert
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == itemCount)
        #expect(notifier.lastNotifiedTotalSize == totalSize)
        #expect(notifier.lastError == nil)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)
    }

    // MARK: - Test 4: ゴミ箱期限警告フロー

    @Test("E2E: ゴミ箱期限警告フロー - 期限警告スケジュール確認")
    func trashExpirationFlow() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let settings = NotificationSettings.default
        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let trashManager = IntegrationTestMockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: notificationManager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 明日期限切れのアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = TrashPhoto(
            originalPhotoId: UUID().uuidString,
            originalAssetIdentifier: UUID().uuidString,
            thumbnailData: nil,
            deletedAt: Date().addingTimeInterval(-86400),
            expiresAt: tomorrow,
            fileSize: 1024 * 1024,
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1920,
                pixelHeight: 1080,
                mediaType: .image,
                mediaSubtypes: [],
                isFavorite: false
            )
        )
        trashManager.addMockPhoto(photo)

        // Act
        try await notifier.scheduleExpirationWarning()

        // Assert
        let pendingCount = notificationManager.pendingNotificationCount
        #expect(pendingCount == 1)
    }

    // MARK: - Test 5: 静寂時間帯対応フロー

    @Test("E2E: 静寂時間帯対応フロー - 静寂時間帯での時間調整確認")
    func quietHoursFlow() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true
        settings.reminderInterval = .daily
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22
        settings.quietHoursEnd = 8

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act
        let scheduledDate = try await scheduler.scheduleReminder()

        // Assert
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: scheduledDate)
        let hour = components.hour ?? 0

        // 静寂時間帯（22時〜8時）を避けて9時以降にスケジュールされているか
        #expect(hour >= 9)
        #expect(scheduler.isReminderScheduled == true)
    }
}

// MARK: - Error Handling Tests

@Suite("通知モジュールエラーハンドリングテスト")
@MainActor
struct NotificationsModuleErrorHandlingTests {

    // MARK: - Test 6: 権限拒否時のエラー伝播

    @Test("エラー: 権限拒否時のエラー伝播 - 各コンポーネントが適切にエラーを返す")
    func permissionDeniedErrorPropagation() async throws {
        // Arrange - 権限拒否状態
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.denied)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        // Test 1: ReminderScheduler
        let scheduler = ReminderScheduler(notificationManager: notificationManager)
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError == .permissionDenied)

        // Test 2: ScanCompletionNotifier
        let notifier = ScanCompletionNotifier(notificationManager: notificationManager)
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .permissionDenied)
        }
    }

    // MARK: - Test 7: 通知設定無効時のエラー

    @Test("エラー: 通知設定無効時のエラー - 各コンポーネントが適切にエラーを返す")
    func notificationsDisabledError() async throws {
        // Arrange - 通知無効状態
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        // Test 1: ReminderScheduler
        let scheduler = ReminderScheduler(notificationManager: notificationManager)
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError == .notificationsDisabled)

        // Test 2: ScanCompletionNotifier
        let notifier = ScanCompletionNotifier(notificationManager: notificationManager)
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .notificationsDisabled)
        }
    }

    // MARK: - Test 8: 不正なパラメータでのエラー

    @Test("エラー: 不正なパラメータでのエラー - バリデーションが機能する")
    func invalidParametersError() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let notifier = ScanCompletionNotifier(notificationManager: notificationManager)

        // Test 1: 負のアイテム数
        do {
            try await notifier.notifyScanCompletion(itemCount: -1, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .invalidParameters(reason: ""))
        }

        // Test 2: 負の合計サイズ
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: -1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .invalidParameters(reason: ""))
        }
    }
}

// MARK: - Mock Objects

/// テスト用のモックTrashManager（統合テスト専用）
final class IntegrationTestMockTrashManager: TrashManagerProtocol, @unchecked Sendable {
    private var photos: [TrashPhoto] = []

    func addMockPhoto(_ photo: TrashPhoto) {
        photos.append(photo)
    }

    // MARK: - TrashManagerProtocol

    func fetchAllTrashPhotos() async -> [TrashPhoto] {
        return photos
    }

    func moveToTrash(_ photos: [Photo], reason: TrashPhoto.DeletionReason?) async throws {
        // テスト用：何もしない
    }

    func restore(_ photos: [TrashPhoto]) async throws {
        // テスト用：何もしない
    }

    func permanentlyDelete(_ photos: [TrashPhoto]) async throws {
        // テスト用：何もしない
    }

    @discardableResult
    func cleanupExpired() async -> Int {
        return 0
    }

    func emptyTrash() async throws {
        photos.removeAll()
    }

    var trashCount: Int {
        get async {
            return photos.count
        }
    }

    var trashSize: Int64 {
        get async {
            return photos.reduce(0) { $0 + $1.fileSize }
        }
    }
}

/// テスト用のモックストレージサービス（統合テスト専用）
final class TestMockStorageService: StorageServiceProtocol, @unchecked Sendable {
    var mockStorageInfo: StorageInfo?
    var shouldThrowError: Bool = false
    var errorToThrow: Error?

    func getDeviceStorageInfo() async throws -> StorageInfo {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: -1)
        }

        return mockStorageInfo ?? StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 50_000_000_000,
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 0
        )
    }

    func calculatePhotosUsage() async throws -> Int64 {
        return mockStorageInfo?.photosUsedCapacity ?? 0
    }

    func estimateReclaimableSpace(from groups: [PhotoGroup]) async -> Int64 {
        return mockStorageInfo?.reclaimableCapacity ?? 0
    }

    static func formatBytes(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func clearCache() {
        // テスト用：何もしない
    }
}
