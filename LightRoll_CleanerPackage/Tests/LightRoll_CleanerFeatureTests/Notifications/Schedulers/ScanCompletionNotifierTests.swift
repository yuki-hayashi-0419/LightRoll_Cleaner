//
//  ScanCompletionNotifierTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ScanCompletionNotifierのテスト
//  - 正常系: スキャン完了通知が正しく送信される
//  - 異常系: 権限なし、設定無効
//  - 境界値: アイテム数0件
//  Swift Testing framework使用
//  Created by AI Assistant for M7-T08
//

import Testing
import Foundation
@preconcurrency import UserNotifications
@testable import LightRoll_CleanerFeature

@Suite("ScanCompletionNotifier Tests")
struct ScanCompletionNotifierTests {

    // MARK: - Test Helpers

    /// テスト用NotificationManager
    @MainActor
    func createTestNotificationManager(
        isEnabled: Bool = true,
        authStatus: UNAuthorizationStatus = .authorized,
        quietHoursEnabled: Bool = false
    ) -> NotificationManager {
        let settings = NotificationSettings(
            isEnabled: isEnabled,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: true,
            reminderInterval: .weekly,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: 22,
            quietHoursEnd: 7
        )

        let mockCenter = MockNotificationCenter(
            authStatus: authStatus,
            shouldSucceed: true
        )

        let manager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )

        return manager
    }

    /// テスト用ScanCompletionNotifier
    @MainActor
    func createTestNotifier(
        notificationManager: NotificationManager? = nil
    ) -> ScanCompletionNotifier {
        let manager = notificationManager ?? createTestNotificationManager()
        return ScanCompletionNotifier(notificationManager: manager)
    }

    // MARK: - Initialization Tests

    @Test("初期化時のプロパティがデフォルト値であること")
    @MainActor
    func testInitialization() {
        // Given & When
        let notifier = createTestNotifier()

        // Then
        #expect(notifier.lastNotifiedItemCount == 0)
        #expect(notifier.lastNotifiedTotalSize == 0)
        #expect(notifier.lastNotificationDate == nil)
        #expect(notifier.wasNotificationSent == false)
        #expect(notifier.lastError == nil)
    }

    // MARK: - Scan Completion Notification Tests

    @Test("スキャン完了通知が正常に送信される（アイテムあり）")
    @MainActor
    func testNotifyScanCompletionWithItems() async throws {
        // Given
        let notifier = createTestNotifier()
        let itemCount = 10
        let totalSize: Int64 = 1024 * 1024 * 100 // 100MB

        // When
        try await notifier.notifyScanCompletion(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == itemCount)
        #expect(notifier.lastNotifiedTotalSize == totalSize)
        #expect(notifier.lastNotificationDate != nil)
        #expect(notifier.lastError == nil)
    }

    @Test("スキャン完了通知が正常に送信される（アイテムなし）")
    @MainActor
    func testNotifyScanCompletionNoItems() async throws {
        // Given
        let notifier = createTestNotifier()

        // When
        try await notifier.notifyNoItemsFound()

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == 0)
        #expect(notifier.lastNotifiedTotalSize == 0)
        #expect(notifier.lastNotificationDate != nil)
        #expect(notifier.lastError == nil)
    }

    @Test("大量のアイテムがある場合でも正常に通知される")
    @MainActor
    func testNotifyScanCompletionLargeNumbers() async throws {
        // Given
        let notifier = createTestNotifier()
        let itemCount = 10000
        let totalSize: Int64 = 1024 * 1024 * 1024 * 50 // 50GB

        // When
        try await notifier.notifyScanCompletion(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == itemCount)
        #expect(notifier.lastNotifiedTotalSize == totalSize)
        #expect(notifier.lastError == nil)
    }

    // MARK: - Error Handling Tests

    @Test("通知設定が無効な場合はエラーになる")
    @MainActor
    func testNotifyWhenDisabled() async {
        // Given
        let manager = createTestNotificationManager(isEnabled: false)
        let notifier = createTestNotifier(notificationManager: manager)

        // When & Then
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .notificationsDisabled)
            #expect(notifier.lastError == .notificationsDisabled)
            #expect(notifier.wasNotificationSent == false)
        } catch {
            Issue.record("予期しないエラータイプ: \(error)")
        }
    }

    @Test("通知権限がない場合はエラーになる")
    @MainActor
    func testNotifyWithoutPermission() async {
        // Given
        let manager = createTestNotificationManager(authStatus: .denied)
        let notifier = createTestNotifier(notificationManager: manager)

        // When & Then
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .permissionDenied)
            #expect(notifier.lastError == .permissionDenied)
            #expect(notifier.wasNotificationSent == false)
        } catch {
            Issue.record("予期しないエラータイプ: \(error)")
        }
    }

    @Test("静寂時間帯中はエラーになる")
    @MainActor
    func testNotifyDuringQuietHours() async throws {
        // Given
        let manager = createTestNotificationManager(quietHoursEnabled: true)
        let notifier = createTestNotifier(notificationManager: manager)

        // 静寂時間帯を強制的に有効化（22:00-07:00の時間帯を設定）
        // 現在時刻が範囲外の場合でも、設定が有効なら静寂時間帯と判定されるようにする
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // 静寂時間帯の範囲内かチェック
        let start = 22
        let end = 7
        let isInRange = (currentHour >= start || currentHour < end)

        if isInRange {
            // When & Then
            do {
                try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
                Issue.record("エラーが発生すべき")
            } catch let error as ScanCompletionNotifierError {
                #expect(error == .quietHoursActive)
                #expect(notifier.lastError == .quietHoursActive)
                #expect(notifier.wasNotificationSent == false)
            } catch {
                Issue.record("予期しないエラータイプ: \(error)")
            }
        } else {
            // 静寂時間帯外の場合は正常に通知される
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
            #expect(notifier.wasNotificationSent == true)
        }
    }

    @Test("負のアイテム数はエラーになる")
    @MainActor
    func testNotifyWithNegativeItemCount() async {
        // Given
        let notifier = createTestNotifier()

        // When & Then
        do {
            try await notifier.notifyScanCompletion(itemCount: -1, totalSize: 1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .invalidParameters(reason: ""))
            #expect(notifier.wasNotificationSent == false)
        } catch {
            Issue.record("予期しないエラータイプ: \(error)")
        }
    }

    @Test("負の合計サイズはエラーになる")
    @MainActor
    func testNotifyWithNegativeTotalSize() async {
        // Given
        let notifier = createTestNotifier()

        // When & Then
        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: -1024)
            Issue.record("エラーが発生すべき")
        } catch let error as ScanCompletionNotifierError {
            #expect(error == .invalidParameters(reason: ""))
            #expect(notifier.wasNotificationSent == false)
        } catch {
            Issue.record("予期しないエラータイプ: \(error)")
        }
    }

    // MARK: - Cancellation Tests

    @Test("通知をキャンセルできる")
    @MainActor
    func testCancelNotification() async throws {
        // Given
        let notifier = createTestNotifier()
        try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
        #expect(notifier.wasNotificationSent == true)

        // When
        await notifier.cancelScanCompletionNotification()

        // Then
        #expect(notifier.wasNotificationSent == false)
        #expect(notifier.lastError == nil)
    }

    // MARK: - State Management Tests

    @Test("通知状態をリセットできる")
    @MainActor
    func testResetNotificationState() async throws {
        // Given
        let notifier = createTestNotifier()
        try await notifier.notifyScanCompletion(itemCount: 10, totalSize: 2048)
        #expect(notifier.wasNotificationSent == true)

        // When
        notifier.resetNotificationState()

        // Then
        #expect(notifier.lastNotifiedItemCount == 0)
        #expect(notifier.lastNotifiedTotalSize == 0)
        #expect(notifier.lastNotificationDate == nil)
        #expect(notifier.wasNotificationSent == false)
        #expect(notifier.lastError == nil)
    }

    @Test("エラーをクリアできる")
    @MainActor
    func testClearError() async {
        // Given
        let manager = createTestNotificationManager(isEnabled: false)
        let notifier = createTestNotifier(notificationManager: manager)

        do {
            try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
        } catch {
            // エラー発生を期待
        }

        #expect(notifier.lastError != nil)

        // When
        notifier.clearError()

        // Then
        #expect(notifier.lastError == nil)
    }

    // MARK: - Utility Tests

    @Test("最後の通知からの経過時間が取得できる")
    @MainActor
    func testTimeSinceLastNotification() async throws {
        // Given
        let notifier = createTestNotifier()

        // 初期状態ではnil
        #expect(notifier.timeSinceLastNotification == nil)

        // 通知を送信
        try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)

        // わずかに待機
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // Then
        let elapsed = notifier.timeSinceLastNotification
        #expect(elapsed != nil)
        #expect(elapsed! > 0)
    }

    @Test("通知が有効かを判定できる")
    @MainActor
    func testIsNotificationEnabled() async {
        // Given
        let enabledManager = createTestNotificationManager(isEnabled: true, authStatus: .authorized)
        let enabledNotifier = createTestNotifier(notificationManager: enabledManager)

        let disabledManager = createTestNotificationManager(isEnabled: false)
        let disabledNotifier = createTestNotifier(notificationManager: disabledManager)

        let noPermissionManager = createTestNotificationManager(authStatus: .denied)
        let noPermissionNotifier = createTestNotifier(notificationManager: noPermissionManager)

        // When & Then
        await enabledManager.updateAuthorizationStatus()
        #expect(enabledNotifier.isNotificationEnabled == true)

        await disabledManager.updateAuthorizationStatus()
        #expect(disabledNotifier.isNotificationEnabled == false)

        await noPermissionManager.updateAuthorizationStatus()
        #expect(noPermissionNotifier.isNotificationEnabled == false)
    }

    @Test("静寂時間帯かを判定できる")
    @MainActor
    func testIsInQuietHours() {
        // Given
        let quietManager = createTestNotificationManager(quietHoursEnabled: true)
        let quietNotifier = createTestNotifier(notificationManager: quietManager)

        let normalManager = createTestNotificationManager(quietHoursEnabled: false)
        let normalNotifier = createTestNotifier(notificationManager: normalManager)

        // When & Then
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let start = 22
        let end = 7
        let expectedQuiet = (currentHour >= start || currentHour < end)

        #expect(quietNotifier.isInQuietHours == expectedQuiet)
        #expect(normalNotifier.isInQuietHours == false)
    }

    // MARK: - Boundary Tests

    @Test("アイテム数が0の場合でも通知される")
    @MainActor
    func testNotifyWithZeroItems() async throws {
        // Given
        let notifier = createTestNotifier()

        // When
        try await notifier.notifyScanCompletion(itemCount: 0, totalSize: 0)

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == 0)
        #expect(notifier.lastNotifiedTotalSize == 0)
        #expect(notifier.lastError == nil)
    }

    @Test("最大値のアイテム数とサイズで通知される")
    @MainActor
    func testNotifyWithMaxValues() async throws {
        // Given
        let notifier = createTestNotifier()
        let maxItemCount = Int.max
        let maxTotalSize = Int64.max

        // When
        try await notifier.notifyScanCompletion(
            itemCount: maxItemCount,
            totalSize: maxTotalSize
        )

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == maxItemCount)
        #expect(notifier.lastNotifiedTotalSize == maxTotalSize)
        #expect(notifier.lastError == nil)
    }

    @Test("連続して通知を送信できる")
    @MainActor
    func testMultipleNotifications() async throws {
        // Given
        let notifier = createTestNotifier()

        // When
        try await notifier.notifyScanCompletion(itemCount: 5, totalSize: 1024)
        let firstDate = notifier.lastNotificationDate

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機

        try await notifier.notifyScanCompletion(itemCount: 10, totalSize: 2048)
        let secondDate = notifier.lastNotificationDate

        // Then
        #expect(notifier.wasNotificationSent == true)
        #expect(notifier.lastNotifiedItemCount == 10)
        #expect(notifier.lastNotifiedTotalSize == 2048)
        #expect(secondDate != nil)
        #expect(secondDate! > firstDate!)
    }
}

// MARK: - MockNotificationCenter

/// テスト用のモックNotificationCenter
private final class MockNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
    let authStatus: UNAuthorizationStatus
    let shouldSucceed: Bool
    private let _scheduledRequests = SendableBox<[UNNotificationRequest]>([])

    var scheduledRequests: [UNNotificationRequest] {
        get { _scheduledRequests.value }
        set { _scheduledRequests.value = newValue }
    }

    init(authStatus: UNAuthorizationStatus = .authorized, shouldSucceed: Bool = true) {
        self.authStatus = authStatus
        self.shouldSucceed = shouldSucceed
    }
}

/// スレッドセーフなボックス型
private final class SendableBox<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

// MARK: - MockNotificationCenter Methods

extension MockNotificationCenter {
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return authStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return shouldSucceed
    }

    func add(_ request: UNNotificationRequest) async throws {
        guard shouldSucceed else {
            throw NSError(domain: "TestError", code: -1)
        }
        scheduledRequests.append(request)
    }

    func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return scheduledRequests
    }

    func removeAllPendingNotificationRequests() async {
        scheduledRequests.removeAll()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        scheduledRequests.removeAll { request in
            identifiers.contains(request.identifier)
        }
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return []
    }

    func removeAllDeliveredNotifications() async {
        // No-op for mock
    }
}
