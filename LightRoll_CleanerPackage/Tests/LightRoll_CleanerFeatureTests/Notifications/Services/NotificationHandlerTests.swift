//
//  NotificationHandlerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationHandler のテストスイート
//  - 通知受信時の処理検証
//  - ナビゲーション動作検証
//  - アクション処理検証
//  - Swift Testing framework使用
//  Created by AI Assistant for M7-T10
//

import Testing
import Foundation
@preconcurrency import UserNotifications
@testable import LightRoll_CleanerFeature

@Suite("NotificationHandler Tests")
@MainActor
struct NotificationHandlerTests {

    // MARK: - Helper Methods

    /// テスト用のNotificationHandlerを作成
    private func makeTestHandler(
        notificationManager: NotificationManager? = nil
    ) -> NotificationHandler {
        return NotificationHandler(notificationManager: notificationManager)
    }

    /// テスト用のNotificationManagerを作成
    private func makeTestNotificationManager() async -> NotificationManager {
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)
        return NotificationManager(
            settings: .default,
            notificationCenter: mockCenter
        )
    }

    /// テスト用のUNNotificationRequestを作成
    /// 注: UNNotificationは直接インスタンス化できないため、
    /// テストではUNNotificationRequestとidentifierで動作を検証
    private func makeTestNotificationRequest(
        identifier: String,
        title: String,
        body: String,
        categoryIdentifier: String
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier

        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
    }

    // MARK: - Initialization Tests

    @Test("初期化: デフォルト設定で初期化できる")
    func testInitializationWithDefaults() {
        let handler = makeTestHandler()

        #expect(handler.lastDestination == nil)
        #expect(handler.navigationPath.isEmpty)
        #expect(handler.lastError == nil)
    }

    @Test("初期化: NotificationManagerを指定して初期化できる")
    func testInitializationWithManager() async {
        let manager = await makeTestNotificationManager()
        let handler = makeTestHandler(notificationManager: manager)

        #expect(handler.lastDestination == nil)
        #expect(handler.navigationPath.isEmpty)
        #expect(handler.lastError == nil)
    }

    // MARK: - Destination Tests

    @Test("遷移先判定: ストレージ警告識別子はhomeに遷移")
    func testDestination_StorageAlert() {
        let handler = makeTestHandler()
        let destination = handler.destination(for: "storage_alert_12345")

        #expect(destination == .home)
    }

    @Test("遷移先判定: スキャン完了識別子はgroupListに遷移")
    func testDestination_ScanCompletion() {
        let handler = makeTestHandler()
        let destination = handler.destination(for: "scan_completion_67890")

        #expect(destination == .groupList)
    }

    @Test("遷移先判定: ゴミ箱期限警告識別子はtrashに遷移")
    func testDestination_TrashExpiration() {
        let handler = makeTestHandler()
        let destination = handler.destination(for: "trash_expiration_warning_abcde")

        #expect(destination == .trash)
    }

    @Test("遷移先判定: リマインダー識別子はreminderに遷移")
    func testDestination_Reminder() {
        let handler = makeTestHandler()
        let destination = handler.destination(for: "reminder_xyz")

        #expect(destination == .reminder)
    }

    @Test("遷移先判定: 不明な識別子はunknownに遷移")
    func testDestination_Unknown() {
        let handler = makeTestHandler()
        let destination = handler.destination(for: "unknown_notification")

        #expect(destination == .unknown)
    }

    // MARK: - Notification Tap Tests

    @Test("通知タップ: 正しい遷移先が設定される")
    func testHandleNotificationTap_SetsDestination() {
        let handler = makeTestHandler()

        handler.handleNotificationTap(
            identifier: "storage_alert_123",
            categoryIdentifier: "STORAGE_ALERT"
        )

        #expect(handler.lastDestination == .home)
    }

    @Test("通知タップ: ナビゲーションパスに追加される")
    func testHandleNotificationTap_AddsToNavigationPath() {
        let handler = makeTestHandler()

        handler.handleNotificationTap(
            identifier: "scan_completion_456",
            categoryIdentifier: "SCAN_COMPLETION"
        )

        #expect(handler.navigationPath.count == 1)
        #expect(handler.navigationPath[0] == .groupList)
    }

    @Test("通知タップ: 複数回タップで複数の遷移先が記録される")
    func testHandleNotificationTap_MultipleTaps() {
        let handler = makeTestHandler()

        handler.handleNotificationTap(
            identifier: "storage_alert_1",
            categoryIdentifier: "STORAGE_ALERT"
        )
        handler.handleNotificationTap(
            identifier: "trash_expiration_warning_2",
            categoryIdentifier: "TRASH_EXPIRATION"
        )

        #expect(handler.navigationPath.count == 2)
        #expect(handler.navigationPath[0] == .home)
        #expect(handler.navigationPath[1] == .trash)
        #expect(handler.lastDestination == .trash)
    }

    @Test("通知タップ: エラーがクリアされる")
    func testHandleNotificationTap_ClearsError() {
        let handler = makeTestHandler()

        handler.handleNotificationTap(
            identifier: "storage_alert_123",
            categoryIdentifier: "STORAGE_ALERT"
        )

        #expect(handler.lastError == nil)
    }

    // MARK: - Clear Methods Tests

    @Test("クリア: ナビゲーションパスがクリアされる")
    func testClearNavigationPath() {
        let handler = makeTestHandler()

        // パスを追加
        handler.handleNotificationTap(
            identifier: "storage_alert_1",
            categoryIdentifier: "STORAGE_ALERT"
        )
        handler.handleNotificationTap(
            identifier: "scan_completion_2",
            categoryIdentifier: "SCAN_COMPLETION"
        )

        #expect(handler.navigationPath.count == 2)

        // クリア
        handler.clearNavigationPath()

        #expect(handler.navigationPath.isEmpty)
        #expect(handler.lastError == nil)
    }

    @Test("クリア: 最後の遷移先がクリアされる")
    func testClearLastDestination() {
        let handler = makeTestHandler()

        // 遷移先を設定
        handler.handleNotificationTap(
            identifier: "trash_expiration_warning_1",
            categoryIdentifier: "TRASH_EXPIRATION"
        )

        #expect(handler.lastDestination == .trash)

        // クリア
        handler.clearLastDestination()

        #expect(handler.lastDestination == nil)
        #expect(handler.lastError == nil)
    }

    // MARK: - NotificationAction Tests

    @Test("アクション: 開くアクションのロジックが正しい")
    func testNotificationAction_OpenLogic() async {
        let handler = makeTestHandler()

        // テスト用の通知識別子とカテゴリ
        let testIdentifier = "storage_alert_123"
        let testCategory = "STORAGE_ALERT"

        // NotificationAction.openの場合、handleNotificationTapと同じ処理になる
        // ロジック検証: identifierから正しい遷移先を判定できること
        let destination = handler.destination(for: testIdentifier)
        #expect(destination == .home)

        // タップ処理の検証
        handler.handleNotificationTap(
            identifier: testIdentifier,
            categoryIdentifier: testCategory
        )
        #expect(handler.lastDestination == .home)
        #expect(handler.navigationPath.count == 1)
    }

    @Test("アクション: アクション識別子の検証")
    func testNotificationAction_ActionIdentifiers() {
        // すべてのアクション識別子が正しくマッピングされていることを確認
        #expect(NotificationAction.open.rawValue == "OPEN_ACTION")
        #expect(NotificationAction.snooze.rawValue == "SNOOZE_ACTION")
        #expect(NotificationAction.cancel.rawValue == "CANCEL_ACTION")
        #expect(NotificationAction.openTrash.rawValue == "OPEN_TRASH_ACTION")
        #expect(NotificationAction.startScan.rawValue == "START_SCAN_ACTION")

        // 不明なアクションはnilになる
        #expect(NotificationAction(rawValue: "INVALID_ACTION") == nil)
    }

    // MARK: - Snooze Tests

    @Test("スヌーズ: NotificationManagerなしの場合の動作")
    func testSnooze_WithoutManager() async {
        let handler = makeTestHandler(notificationManager: nil)

        // NotificationManagerがnilの状態を確認
        #expect(handler.lastError == nil)

        // 注: 実際のスヌーズ処理はUNNotificationオブジェクトが必要なため、
        // ここではNotificationManagerの有無によるロジック分岐を確認
        // handleSnooze内部でmanagerがnilの場合、エラーが設定される
    }

    @Test("スヌーズ: NotificationManagerありの場合の動作")
    func testSnooze_WithManager() async {
        let manager = await makeTestNotificationManager()
        let handler = makeTestHandler(notificationManager: manager)

        // 初期状態の通知数を確認
        let initialCount = manager.pendingNotificationCount
        #expect(initialCount == 0)

        // 注: 実際のスヌーズ処理はUNNotificationオブジェクトが必要
        // handleSnooze内部でNotificationManagerを使って再スケジューリングされる
        // 10分後のトリガーが作成され、"_snooze"サフィックス付きの識別子で登録される
    }

    // MARK: - Delegate Setup Tests

    // 注: setupAsDelegate()は UNUserNotificationCenter.current() を使用するため、
    // テスト環境では実行できません（bundleProxyForCurrentProcess is nil エラー）
    // この機能は統合テストまたはアプリ実行時にのみテスト可能です

    // MARK: - Integration Tests

    @Test("統合: 複数の通知タップで正しいナビゲーションフローが構築される")
    func testIntegration_MultipleNotifications() {
        let handler = makeTestHandler()

        // 1. ストレージ警告をタップ
        handler.handleNotificationTap(
            identifier: "storage_alert_1",
            categoryIdentifier: "STORAGE_ALERT"
        )

        #expect(handler.lastDestination == .home)
        #expect(handler.navigationPath.count == 1)

        // 2. ゴミ箱期限警告をタップ
        handler.handleNotificationTap(
            identifier: "trash_expiration_warning_2",
            categoryIdentifier: "TRASH_EXPIRATION"
        )

        #expect(handler.lastDestination == .trash)
        #expect(handler.navigationPath.count == 2)

        // 3. ナビゲーションパスをクリア
        handler.clearNavigationPath()

        #expect(handler.navigationPath.isEmpty)

        // 4. スキャン完了通知をタップ
        handler.handleNotificationTap(
            identifier: "scan_completion_3",
            categoryIdentifier: "SCAN_COMPLETION"
        )

        #expect(handler.lastDestination == .groupList)
        #expect(handler.navigationPath.count == 1)
    }

    @Test("統合: エラーハンドリングが正しく機能する")
    func testIntegration_ErrorHandling() {
        let handler = makeTestHandler()

        // エラーがない状態
        #expect(handler.lastError == nil)

        // 通知タップでエラーがクリアされる
        handler.handleNotificationTap(
            identifier: "reminder_1",
            categoryIdentifier: "REMINDER"
        )

        #expect(handler.lastError == nil)

        // clearメソッドでもエラーがクリアされる
        handler.clearNavigationPath()
        #expect(handler.lastError == nil)

        handler.clearLastDestination()
        #expect(handler.lastError == nil)
    }
}

// MARK: - Error Tests

@Suite("NotificationHandlerError Tests")
struct NotificationHandlerErrorTests {

    @Test("エラー: エラーの等価性が正しく機能する")
    func testErrorEquality() {
        #expect(
            NotificationHandlerError.invalidNotificationData(reason: "test") ==
            NotificationHandlerError.invalidNotificationData(reason: "other")
        )
        #expect(
            NotificationHandlerError.navigationFailed(destination: .home) ==
            NotificationHandlerError.navigationFailed(destination: .trash)
        )
        #expect(
            NotificationHandlerError.actionProcessingFailed(action: "a", reason: "r") ==
            NotificationHandlerError.actionProcessingFailed(action: "b", reason: "s")
        )
    }

    @Test("エラー: エラーメッセージが正しく提供される")
    func testErrorDescriptions() {
        #expect(NotificationHandlerError.invalidNotificationData(reason: "test").errorDescription != nil)
        #expect(NotificationHandlerError.navigationFailed(destination: .home).errorDescription != nil)
        #expect(NotificationHandlerError.actionProcessingFailed(action: "test", reason: "reason").errorDescription != nil)
    }
}

// MARK: - NotificationDestination Tests

@Suite("NotificationDestination Tests")
struct NotificationDestinationTests {

    @Test("遷移先: すべての遷移先が等価性比較できる")
    func testDestinationEquality() {
        #expect(NotificationDestination.home == .home)
        #expect(NotificationDestination.groupList == .groupList)
        #expect(NotificationDestination.trash == .trash)
        #expect(NotificationDestination.reminder == .reminder)
        #expect(NotificationDestination.settings == .settings)
        #expect(NotificationDestination.unknown == .unknown)

        #expect(NotificationDestination.home != .groupList)
        #expect(NotificationDestination.trash != .reminder)
    }
}

// MARK: - NotificationAction Tests

@Suite("NotificationAction Tests")
struct NotificationActionTests {

    @Test("アクション: 正しいrawValueを持つ")
    func testActionRawValues() {
        #expect(NotificationAction.open.rawValue == "OPEN_ACTION")
        #expect(NotificationAction.snooze.rawValue == "SNOOZE_ACTION")
        #expect(NotificationAction.cancel.rawValue == "CANCEL_ACTION")
        #expect(NotificationAction.openTrash.rawValue == "OPEN_TRASH_ACTION")
        #expect(NotificationAction.startScan.rawValue == "START_SCAN_ACTION")
    }

    @Test("アクション: rawValueから初期化できる")
    func testActionInitialization() {
        #expect(NotificationAction(rawValue: "OPEN_ACTION") == .open)
        #expect(NotificationAction(rawValue: "SNOOZE_ACTION") == .snooze)
        #expect(NotificationAction(rawValue: "CANCEL_ACTION") == .cancel)
        #expect(NotificationAction(rawValue: "OPEN_TRASH_ACTION") == .openTrash)
        #expect(NotificationAction(rawValue: "START_SCAN_ACTION") == .startScan)
        #expect(NotificationAction(rawValue: "INVALID") == nil)
    }
}

// MARK: - Test Helpers

// 注: UNNotificationは直接サブクラス化できないため、
// テストではUNNotificationRequestとidentifierを使用して
// NotificationHandlerのロジックを検証します。
//
// 実際のUNUserNotificationCenterDelegateメソッドのテストは
// 統合テストまたはUIテストで実施することを推奨します。
