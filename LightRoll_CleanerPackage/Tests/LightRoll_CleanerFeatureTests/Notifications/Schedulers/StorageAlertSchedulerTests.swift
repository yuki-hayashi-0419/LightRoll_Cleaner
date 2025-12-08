//
//  StorageAlertSchedulerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StorageAlertSchedulerのテスト
//  - 初期化テスト
//  - ストレージチェック機能テスト
//  - 通知スケジューリングテスト
//  - 静寂時間帯テスト
//  - ステート管理テスト
//  - エラーハンドリングテスト
//  Created by AI Assistant for M7-T06
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature
@preconcurrency import UserNotifications
@preconcurrency import Photos

// MARK: - Initialization Tests

@Suite("StorageAlertScheduler初期化テスト")
@MainActor
struct StorageAlertSchedulerInitializationTests {

    @Test("デフォルト初期化が正しく動作する")
    func defaultInitialization() async throws {
        // Arrange & Act
        let mockCenter = MockUserNotificationCenter()
        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Assert
        #expect(scheduler.lastUsagePercentage == 0.0)
        #expect(scheduler.lastAvailableSpace == 0)
        #expect(scheduler.lastCheckTime == nil)
        #expect(scheduler.isNotificationScheduled == false)
        #expect(scheduler.lastError == nil)
    }

    @Test("カスタム依存注入が正しく動作する")
    func customDependencyInjection() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let contentBuilder = NotificationContentBuilder()

        // Act
        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager,
            contentBuilder: contentBuilder
        )

        // Assert
        #expect(scheduler.lastUsagePercentage == 0.0)
        #expect(scheduler.isNotificationScheduled == false)
    }
}

// MARK: - Storage Check Tests

@Suite("StorageAlertSchedulerストレージチェックテスト")
@MainActor
struct StorageAlertSchedulerStorageCheckTests {

    @Test("閾値超過時に通知がスケジュールされる")
    func scheduleNotificationWhenOverThreshold() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = MockStorageService()
        mockStorageService.mockStorageInfo = StorageInfo(
            totalCapacity: 100_000_000_000,    // 100GB
            availableCapacity: 5_000_000_000,   // 5GB空き
            photosUsedCapacity: 95_000_000_000,       // 95GB使用
            reclaimableCapacity: 0
        )
        let photoRepository = PhotoRepository(
            permissionManager: mockPermission,
            storageService: mockStorageService
        )

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.9
        settings.quietHoursEnabled = false

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
        #expect(scheduler.lastUsagePercentage >= 0.9)
        #expect(scheduler.isNotificationScheduled == true)
        #expect(scheduler.lastError == nil)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "storage_alert")
    }

    @Test("閾値未満時は通知されない")
    func noNotificationWhenBelowThreshold() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.99  // 非常に高い閾値
        settings.quietHoursEnabled = false

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
        #expect(result == false)
        #expect(scheduler.isNotificationScheduled == false)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 0)
    }

    @Test("ストレージ情報取得失敗時にエラーが発生する")
    func throwsErrorWhenStorageInfoUnavailable() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = MockStorageService()
        mockStorageService.shouldThrowError = true
        let photoRepository = PhotoRepository(
            permissionManager: mockPermission,
            storageService: mockStorageService
        )

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act & Assert
        await #expect(throws: StorageAlertSchedulerError.self) {
            try await scheduler.checkAndScheduleIfNeeded()
        }

        #expect(scheduler.lastError != nil)
        if case .storageInfoUnavailable = scheduler.lastError {
            // エラーが正しい
        } else {
            Issue.record("予期しないエラータイプ")
        }
    }

    @Test("通知無効時にエラーが発生する")
    func throwsErrorWhenNotificationsDisabled() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = false  // 通知無効

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act & Assert
        await #expect(throws: StorageAlertSchedulerError.notificationsDisabled) {
            try await scheduler.checkAndScheduleIfNeeded()
        }

        #expect(scheduler.lastError == .notificationsDisabled)
    }

    @Test("権限拒否時にエラーが発生する")
    func throwsErrorWhenPermissionDenied() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.denied)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act & Assert
        await #expect(throws: StorageAlertSchedulerError.permissionDenied) {
            try await scheduler.checkAndScheduleIfNeeded()
        }

        #expect(scheduler.lastError == .permissionDenied)
    }
}

// MARK: - Notification Scheduling Tests

@Suite("StorageAlertScheduler通知スケジューリングテスト")
@MainActor
struct StorageAlertSchedulerNotificationTests {

    @Test("通知コンテンツが正しく生成される")
    func notificationContentIsCorrect() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

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
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.91,
            availableSpace: 15_000_000_000
        )

        // Assert
        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)

        if let request = pending.first {
            #expect(request.identifier == "storage_alert")
            #expect(request.content.title.contains("ストレージ"))
            #expect(request.content.body.contains("91%"))
            #expect(request.content.categoryIdentifier == "STORAGE_ALERT")

            // userInfoに必要な情報が含まれている
            #expect(request.content.userInfo["type"] as? String == "storage_alert")
        } else {
            Issue.record("通知リクエストが見つかりません")
        }
    }

    @Test("通知スケジュールが成功する")
    func scheduleNotificationSuccessfully() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

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
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.95,
            availableSpace: 5_000_000_000
        )

        // Assert
        #expect(scheduler.isNotificationScheduled == true)
        #expect(scheduler.lastError == nil)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)
    }

    @Test("重複通知が防止される")
    func preventsDuplicateNotifications() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act - 1回目
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.95,
            availableSpace: 5_000_000_000
        )

        let pendingBefore = await mockCenter.getPendingNotificationRequests()
        #expect(pendingBefore.count == 1)

        // Act - 2回目（重複）
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.96,
            availableSpace: 4_000_000_000
        )

        // Assert - 通知数は増えない
        let pendingAfter = await mockCenter.getPendingNotificationRequests()
        #expect(pendingAfter.count == 1)
    }

    @Test("通知キャンセルが正しく動作する")
    func cancelNotificationSuccessfully() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // まず通知をスケジュール
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.95,
            availableSpace: 5_000_000_000
        )

        let pendingBefore = await mockCenter.getPendingNotificationRequests()
        #expect(pendingBefore.count == 1)

        // Act - キャンセル
        await scheduler.cancelStorageAlertNotification()

        // Assert
        #expect(scheduler.isNotificationScheduled == false)

        let pendingAfter = await mockCenter.getPendingNotificationRequests()
        #expect(pendingAfter.count == 0)
    }
}

// MARK: - Quiet Hours Tests

@Suite("StorageAlertScheduler静寂時間帯テスト")
@MainActor
struct StorageAlertSchedulerQuietHoursTests {

    @Test("静寂時間帯中はエラーが発生する")
    func throwsErrorDuringQuietHours() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = MockStorageService()
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

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = true

        // 現在時刻を静寂時間帯に設定
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // 現在時刻が静寂時間帯になるように設定
        settings.quietHoursStart = currentHour
        settings.quietHoursEnd = (currentHour + 1) % 24

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act & Assert
        await #expect(throws: StorageAlertSchedulerError.quietHoursActive) {
            try await scheduler.checkAndScheduleIfNeeded()
        }

        #expect(scheduler.lastError == .quietHoursActive)
    }

    @Test("静寂時間帯外は正常に動作する")
    func worksNormallyOutsideQuietHours() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = MockStorageService()
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

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.9
        settings.quietHoursEnabled = true

        // 現在時刻が静寂時間帯外になるように設定
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        settings.quietHoursStart = (currentHour + 2) % 24
        settings.quietHoursEnd = (currentHour + 3) % 24

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
        #expect(scheduler.lastError == nil)

        let pending = await mockCenter.getPendingNotificationRequests()
        #expect(pending.count == 1)
    }
}

// MARK: - State Management Tests

@Suite("StorageAlertSchedulerステート管理テスト")
@MainActor
struct StorageAlertSchedulerStateTests {

    @Test("使用率と空き容量が正しく更新される")
    func updatesUsageAndAvailableSpace() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.9
        settings.quietHoursEnabled = false

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
        try await scheduler.checkAndScheduleIfNeeded()

        // Assert
        #expect(scheduler.lastUsagePercentage > 0.0)
        #expect(scheduler.lastAvailableSpace > 0)
    }

    @Test("チェック時刻が記録される")
    func recordsCheckTime() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        #expect(scheduler.lastCheckTime == nil)

        // Act
        try await scheduler.checkAndScheduleIfNeeded()

        // Assert
        #expect(scheduler.lastCheckTime != nil)

        if let timeSince = scheduler.timeSinceLastCheck {
            #expect(timeSince >= 0.0)
            #expect(timeSince < 5.0)  // 5秒以内
        } else {
            Issue.record("timeSinceLastCheckがnilです")
        }
    }

    @Test("通知スケジュール状態が更新される")
    func updatesNotificationScheduledState() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        #expect(scheduler.isNotificationScheduled == false)

        // Act - 通知をスケジュール
        try await scheduler.scheduleStorageAlert(
            usagePercentage: 0.95,
            availableSpace: 5_000_000_000
        )

        // Assert
        #expect(scheduler.isNotificationScheduled == true)

        // 状態を更新して確認
        await scheduler.updateNotificationStatus()
        #expect(scheduler.isNotificationScheduled == true)
    }
}

// MARK: - Error Handling Tests

@Suite("StorageAlertSchedulerエラーハンドリングテスト")
@MainActor
struct StorageAlertSchedulerErrorTests {

    @Test("エラーが記録され、クリアできる")
    func recordsAndClearsErrors() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let mockPermission = MockPhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: mockPermission)

        var settings = NotificationSettings.default
        settings.isEnabled = false  // 通知無効でエラーを発生させる

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // Act - エラー発生
        await #expect(throws: StorageAlertSchedulerError.self) {
            try await scheduler.checkAndScheduleIfNeeded()
        }

        #expect(scheduler.lastError != nil)

        // エラーをクリア
        scheduler.clearError()

        // Assert
        #expect(scheduler.lastError == nil)
    }

    @Test("各種エラーケースが正しく処理される")
    func handlesVariousErrorCases() async throws {
        // Test 1: 通知無効エラー
        let error1 = StorageAlertSchedulerError.notificationsDisabled
        #expect(error1.errorDescription != nil)

        // Test 2: 権限拒否エラー
        let error2 = StorageAlertSchedulerError.permissionDenied
        #expect(error2.errorDescription != nil)

        // Test 3: 静寂時間帯エラー
        let error3 = StorageAlertSchedulerError.quietHoursActive
        #expect(error3.errorDescription != nil)

        // Test 4: ストレージ情報エラー
        let error4 = StorageAlertSchedulerError.storageInfoUnavailable(reason: "テスト")
        #expect(error4.errorDescription != nil)

        // Test 5: スケジューリング失敗エラー
        let error5 = StorageAlertSchedulerError.schedulingFailed(reason: "テスト")
        #expect(error5.errorDescription != nil)

        // Test エラーの等価性
        #expect(error1 == StorageAlertSchedulerError.notificationsDisabled)
        #expect(error2 == StorageAlertSchedulerError.permissionDenied)
    }

    @Test("閾値チェックユーティリティが正しく動作する")
    func thresholdCheckUtilityWorks() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        let mockPermission = MockPhotoPermissionManager()
        let mockStorageService = MockStorageService()
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

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.storageAlertEnabled = true
        settings.storageAlertThreshold = 0.9
        settings.quietHoursEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await notificationManager.updateAuthorizationStatus()

        let scheduler = StorageAlertScheduler(
            photoRepository: photoRepository,
            notificationManager: notificationManager
        )

        // 初期状態では閾値未満
        #expect(scheduler.isOverThreshold == false)

        // Act - チェック実行
        try await scheduler.checkAndScheduleIfNeeded()

        // Assert - チェック後は閾値を超えている
        #expect(scheduler.isOverThreshold == true)
    }
}

// MARK: - Mock Objects

/// テスト用のモックストレージサービス
final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    var mockStorageInfo: StorageInfo?
    var shouldThrowError: Bool = false
    var errorToThrow: Error?

    func getDeviceStorageInfo() async throws -> StorageInfo {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "TestError", code: -1)
        }

        return mockStorageInfo ?? StorageInfo(
            totalCapacity: 100_000_000_000,  // 100GB
            availableCapacity: 50_000_000_000, // 50GB
            photosUsedCapacity: 50_000_000_000,      // 50GB
            reclaimableCapacity: 0
        )
    }

    func calculatePhotosUsage() async throws -> Int64 {
        // テスト用：mockStorageInfoから写真使用容量を返す
        return mockStorageInfo?.photosUsedCapacity ?? 0
    }

    func estimateReclaimableSpace(from groups: [PhotoGroup]) async -> Int64 {
        // テスト用：mockStorageInfoから回収可能容量を返す
        return mockStorageInfo?.reclaimableCapacity ?? 0
    }

    static func formatBytes(_ bytes: Int64) -> String {
        // テスト用：簡易実装
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func clearCache() {
        // テスト用：何もしない
    }
}
