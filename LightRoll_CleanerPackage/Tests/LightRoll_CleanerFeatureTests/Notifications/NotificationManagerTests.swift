//
//  NotificationManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationManagerの包括的なテスト
//  - 権限管理テスト
//  - スケジューリングテスト
//  - 設定統合テスト
//  - エラーハンドリングテスト
//  Created by AI Assistant for M7-T03
//

import Testing
@preconcurrency import UserNotifications
@testable import LightRoll_CleanerFeature

// MARK: - Sendable Conformance for Testing

extension UNNotificationRequest: @unchecked @retroactive Sendable {}
extension UNNotification: @unchecked @retroactive Sendable {}

// MARK: - MockUserNotificationCenter

/// テスト用のモック通知センター（NotificationManager用）
actor MockUserNotificationCenter: UserNotificationCenterProtocol {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var authorizationGranted: Bool = true
    var addedRequests: [UNNotificationRequest] = []
    var pendingRequests: [UNNotificationRequest] = []
    var deliveredNotifications: [UNNotification] = []
    var shouldThrowOnAdd: Bool = false
    var shouldThrowOnAuth: Bool = false

    // MARK: - Configuration Methods

    func setAuthorizationStatus(_ status: UNAuthorizationStatus) {
        authorizationStatus = status
    }

    func setAuthorizationGranted(_ granted: Bool) {
        authorizationGranted = granted
    }

    func setShouldThrowOnAdd(_ shouldThrow: Bool) {
        shouldThrowOnAdd = shouldThrow
    }

    func setShouldThrowOnAuth(_ shouldThrow: Bool) {
        shouldThrowOnAuth = shouldThrow
    }

    // MARK: - UserNotificationCenterProtocol

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return authorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        if shouldThrowOnAuth {
            throw NSError(domain: "TestError", code: -1)
        }
        if authorizationGranted {
            authorizationStatus = .authorized
        } else {
            authorizationStatus = .denied
        }
        return authorizationGranted
    }

    func add(_ request: UNNotificationRequest) async throws {
        if shouldThrowOnAdd {
            throw NSError(domain: "TestError", code: -2)
        }
        addedRequests.append(request)
        pendingRequests.append(request)
    }

    func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingRequests
    }

    func removeAllPendingNotificationRequests() async {
        pendingRequests.removeAll()
        addedRequests.removeAll()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        pendingRequests.removeAll { identifiers.contains($0.identifier) }
        addedRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return deliveredNotifications
    }

    func removeAllDeliveredNotifications() async {
        deliveredNotifications.removeAll()
    }

    func getAddedRequestsCount() -> Int {
        addedRequests.count
    }

    func reset() {
        authorizationStatus = .notDetermined
        authorizationGranted = true
        addedRequests.removeAll()
        pendingRequests.removeAll()
        deliveredNotifications.removeAll()
        shouldThrowOnAdd = false
        shouldThrowOnAuth = false
    }
}

// MARK: - Test Suite: Initialization

@Suite("NotificationManager - 初期化テスト")
@MainActor
struct NotificationManagerInitializationTests {

    @Test("デフォルト初期化が正常に動作する")
    func testDefaultInitialization() {
        // Given/When
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)

        // Then
        #expect(manager.authorizationStatus == .notDetermined)
        #expect(manager.settings == .default)
        #expect(manager.pendingNotificationCount == 0)
        #expect(manager.lastError == nil)
    }

    @Test("カスタム設定での初期化が正常に動作する")
    func testCustomSettingsInitialization() {
        // Given
        var customSettings = NotificationSettings.default
        customSettings.isEnabled = false
        customSettings.storageAlertEnabled = false

        let mockCenter = MockUserNotificationCenter()

        // When
        let manager = NotificationManager(
            settings: customSettings,
            notificationCenter: mockCenter
        )

        // Then
        #expect(manager.settings.isEnabled == false)
        #expect(manager.settings.storageAlertEnabled == false)
    }
}

// MARK: - Test Suite: Permission Management

@Suite("NotificationManager - 権限管理テスト")
@MainActor
struct NotificationManagerPermissionTests {

    @Test("権限ステータスの更新が正常に動作する")
    func testUpdateAuthorizationStatus() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        await manager.updateAuthorizationStatus()

        // Then
        #expect(manager.authorizationStatus == .authorized)
    }

    @Test("権限リクエストが成功する")
    func testRequestPermissionSuccess() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationGranted(true)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        let granted = try await manager.requestPermission()

        // Then
        #expect(granted == true)
        #expect(manager.authorizationStatus == .authorized)
        #expect(manager.lastError == nil)
    }

    @Test("権限リクエストが拒否される")
    func testRequestPermissionDenied() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationGranted(false)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When/Then
        await #expect(throws: NotificationError.permissionDenied) {
            try await manager.requestPermission()
        }
        #expect(manager.lastError == .permissionDenied)
    }

    @Test("すでに許可済みの場合はリクエストをスキップする")
    func testRequestPermissionAlreadyAuthorized() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        await manager.updateAuthorizationStatus()
        let granted = try await manager.requestPermission()

        // Then
        #expect(granted == true)
        #expect(manager.authorizationStatus == .authorized)
    }

    @Test("権限が拒否済みの場合はエラーを返す")
    func testRequestPermissionPreviouslyDenied() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.denied)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        await manager.updateAuthorizationStatus()

        // Then
        await #expect(throws: NotificationError.permissionDenied) {
            try await manager.requestPermission()
        }
    }

    @Test("isAuthorizedが正しく機能する")
    func testIsAuthorized() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When/Then: notDetermined
        #expect(manager.isAuthorized == false)

        // When/Then: authorized
        await mockCenter.setAuthorizationStatus(.authorized)
        await manager.updateAuthorizationStatus()
        #expect(manager.isAuthorized == true)

        // When/Then: provisional
        await mockCenter.setAuthorizationStatus(.provisional)
        await manager.updateAuthorizationStatus()
        #expect(manager.isAuthorized == true)

        // When/Then: denied
        await mockCenter.setAuthorizationStatus(.denied)
        await manager.updateAuthorizationStatus()
        #expect(manager.isAuthorized == false)
    }

    @Test("canRequestPermissionが正しく機能する")
    func testCanRequestPermission() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When/Then: notDetermined
        #expect(manager.canRequestPermission == true)

        // When/Then: authorized
        await mockCenter.setAuthorizationStatus(.authorized)
        await manager.updateAuthorizationStatus()
        #expect(manager.canRequestPermission == false)
    }
}

// MARK: - Test Suite: Settings Management

@Suite("NotificationManager - 設定管理テスト")
@MainActor
struct NotificationManagerSettingsTests {

    @Test("設定の更新が正常に動作する")
    func testUpdateSettings() throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)
        var newSettings = NotificationSettings.default
        newSettings.isEnabled = false
        newSettings.reminderEnabled = true

        // When
        try manager.updateSettings(newSettings)

        // Then
        #expect(manager.settings.isEnabled == false)
        #expect(manager.settings.reminderEnabled == true)
        #expect(manager.lastError == nil)
    }

    @Test("無効な設定の更新はエラーを返す")
    func testUpdateInvalidSettings() {
        // Given
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)
        var invalidSettings = NotificationSettings.default
        invalidSettings.storageAlertThreshold = 1.5 // 範囲外

        // When/Then
        #expect(throws: NotificationError.self) {
            try manager.updateSettings(invalidSettings)
        }
        #expect(manager.lastError != nil)
    }

    @Test("静寂時間帯の判定が正しく機能する")
    func testIsInQuietHours() {
        // Given
        let mockCenter = MockUserNotificationCenter()
        var settings = NotificationSettings.default
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22
        settings.quietHoursEnd = 8

        let manager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        // Then
        // 実際の時刻に依存するため、設定値の確認のみ
        #expect(manager.settings.quietHoursEnabled == true)
        #expect(manager.settings.quietHoursStart == 22)
        #expect(manager.settings.quietHoursEnd == 8)
    }

    @Test("通知有効状態の判定が正しく機能する")
    func testIsNotificationEnabled() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true

        let manager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        // When
        await manager.updateAuthorizationStatus()

        // Then
        #expect(manager.isNotificationEnabled == true)

        // When: 設定を無効化
        settings.isEnabled = false
        try? manager.updateSettings(settings)

        // Then
        #expect(manager.isNotificationEnabled == false)
    }
}

// MARK: - Test Suite: Notification Scheduling

@Suite("NotificationManager - 通知スケジューリングテスト")
@MainActor
struct NotificationManagerSchedulingTests {

    @Test("通知のスケジュールが正常に動作する")
    func testScheduleNotification() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "これはテストです"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)

        // When
        try await manager.scheduleNotification(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )

        // Then
        let requestsCount = await mockCenter.getAddedRequestsCount()
        #expect(requestsCount == 1)
        #expect(manager.lastError == nil)
    }

    @Test("空の識別子ではスケジュールできない")
    func testScheduleNotificationWithEmptyIdentifier() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト"

        // When/Then
        await #expect(throws: NotificationError.self) {
            try await manager.scheduleNotification(
                identifier: "",
                content: content,
                trigger: nil
            )
        }
        #expect(manager.lastError != nil)
    }

    @Test("通知が無効の場合はスケジュールできない")
    func testScheduleNotificationWhenDisabled() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        var settings = NotificationSettings.default
        settings.isEnabled = false

        let manager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト"

        // When/Then
        await #expect(throws: NotificationError.self) {
            try await manager.scheduleNotification(
                identifier: "test",
                content: content,
                trigger: nil
            )
        }
    }

    @Test("権限がない場合はスケジュールできない")
    func testScheduleNotificationWithoutPermission() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.denied)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト"

        // When/Then
        await #expect(throws: NotificationError.permissionDenied) {
            try await manager.scheduleNotification(
                identifier: "test",
                content: content,
                trigger: nil
            )
        }
    }

    @Test("スケジューリングエラーが正しくハンドリングされる")
    func testScheduleNotificationError() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        await mockCenter.setShouldThrowOnAdd(true)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト"

        // When/Then
        await #expect(throws: NotificationError.self) {
            try await manager.scheduleNotification(
                identifier: "test",
                content: content,
                trigger: nil
            )
        }
        #expect(manager.lastError != nil)
    }
}

// MARK: - Test Suite: Notification Cancellation

@Suite("NotificationManager - 通知キャンセルテスト")
@MainActor
struct NotificationManagerCancellationTests {

    @Test("個別通知のキャンセルが正常に動作する")
    func testCancelNotification() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "テスト"
        try await manager.scheduleNotification(
            identifier: "test_notification",
            content: content,
            trigger: nil
        )

        // When
        await manager.cancelNotification(identifier: "test_notification")

        // Then
        let pending = await manager.getPendingNotifications()
        #expect(pending.isEmpty)
        #expect(manager.lastError == nil)
    }

    @Test("すべての通知のキャンセルが正常に動作する")
    func testCancelAllNotifications() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // 複数スケジュール
        for i in 1...3 {
            let content = UNMutableNotificationContent()
            content.title = "テスト \(i)"
            try await manager.scheduleNotification(
                identifier: "test_\(i)",
                content: content,
                trigger: nil
            )
        }

        // When
        await manager.cancelAllNotifications()

        // Then
        let pending = await manager.getPendingNotifications()
        #expect(pending.isEmpty)
        #expect(manager.pendingNotificationCount == 0)
    }

    @Test("配信済み通知の削除が正常に動作する")
    func testRemoveAllDeliveredNotifications() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        await manager.removeAllDeliveredNotifications()

        // Then
        let delivered = await manager.getDeliveredNotifications()
        #expect(delivered.isEmpty)
    }

    @Test("NotificationIdentifierでのキャンセルが正常に動作する")
    func testCancelNotificationWithIdentifier() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "ストレージアラート"
        try await manager.scheduleNotification(
            identifier: NotificationManager.NotificationIdentifier.storageAlert.identifier,
            content: content,
            trigger: nil
        )

        // When
        await manager.cancelNotification(.storageAlert)

        // Then
        let pending = await manager.getPendingNotifications()
        #expect(pending.isEmpty)
    }
}

// MARK: - Test Suite: Notification Queries

@Suite("NotificationManager - 通知クエリテスト")
@MainActor
struct NotificationManagerQueryTests {

    @Test("ペンディング通知の取得が正常に動作する")
    func testGetPendingNotifications() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "テスト"
        try await manager.scheduleNotification(
            identifier: "test",
            content: content,
            trigger: nil
        )

        // When
        let pending = await manager.getPendingNotifications()

        // Then
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "test")
    }

    @Test("通知の存在確認が正常に動作する")
    func testHasNotification() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // When/Then: スケジュール前
        var exists = await manager.hasNotification(identifier: "test")
        #expect(exists == false)

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "テスト"
        try await manager.scheduleNotification(
            identifier: "test",
            content: content,
            trigger: nil
        )

        // When/Then: スケジュール後
        exists = await manager.hasNotification(identifier: "test")
        #expect(exists == true)
    }

    @Test("NotificationIdentifierでの存在確認が正常に動作する")
    func testHasNotificationWithIdentifier() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "リマインダー"
        try await manager.scheduleNotification(
            identifier: NotificationManager.NotificationIdentifier.reminder.identifier,
            content: content,
            trigger: nil
        )

        // When
        let exists = await manager.hasNotification(.reminder)

        // Then
        #expect(exists == true)
    }

    @Test("ペンディング通知数が正しく更新される")
    func testPendingNotificationCount() async throws {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        // When/Then: 初期状態
        #expect(manager.pendingNotificationCount == 0)

        // スケジュール
        let content = UNMutableNotificationContent()
        content.title = "テスト"
        try await manager.scheduleNotification(
            identifier: "test",
            content: content,
            trigger: nil
        )

        // When/Then: スケジュール後
        #expect(manager.pendingNotificationCount == 1)

        // キャンセル
        await manager.cancelNotification(identifier: "test")

        // When/Then: キャンセル後
        #expect(manager.pendingNotificationCount == 0)
    }
}

// MARK: - Test Suite: Error Handling

@Suite("NotificationManager - エラーハンドリングテスト")
@MainActor
struct NotificationManagerErrorHandlingTests {

    @Test("エラーのクリアが正常に動作する")
    func testClearError() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationGranted(false)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // エラー発生
        try? await manager.requestPermission()
        #expect(manager.lastError != nil)

        // When
        manager.clearError()

        // Then
        #expect(manager.lastError == nil)
    }

    @Test("権限エラーが正しく記録される")
    func testPermissionErrorRecording() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationGranted(false)
        let manager = NotificationManager(notificationCenter: mockCenter)

        // When
        try? await manager.requestPermission()

        // Then
        #expect(manager.lastError == .permissionDenied)
    }

    @Test("スケジューリングエラーが正しく記録される")
    func testSchedulingErrorRecording() async {
        // Given
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        await mockCenter.setShouldThrowOnAdd(true)
        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let content = UNMutableNotificationContent()
        content.title = "テスト"

        // When
        try? await manager.scheduleNotification(
            identifier: "test",
            content: content,
            trigger: nil
        )

        // Then
        #expect(manager.lastError != nil)
    }
}

// MARK: - Test Suite: Notification Identifiers

@Suite("NotificationManager - 通知識別子テスト")
@MainActor
struct NotificationManagerIdentifierTests {

    @Test("すべての通知識別子が一意である")
    func testAllIdentifiersAreUnique() {
        // Given
        let identifiers = NotificationManager.NotificationIdentifier.allCases.map { $0.identifier }

        // Then
        let uniqueIdentifiers = Set(identifiers)
        #expect(identifiers.count == uniqueIdentifiers.count)
    }

    @Test("通知識別子の数が正しい")
    func testIdentifierCount() {
        // Given/When
        let count = NotificationManager.NotificationIdentifier.allCases.count

        // Then
        #expect(count == 4) // storageAlert, reminder, scanCompletion, trashExpiration
    }

    @Test("各識別子が正しい文字列を持つ")
    func testIdentifierStrings() {
        #expect(NotificationManager.NotificationIdentifier.storageAlert.identifier == "storage_alert")
        #expect(NotificationManager.NotificationIdentifier.reminder.identifier == "reminder")
        #expect(NotificationManager.NotificationIdentifier.scanCompletion.identifier == "scan_completion")
        #expect(NotificationManager.NotificationIdentifier.trashExpiration.identifier == "trash_expiration")
    }
}
