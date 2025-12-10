//
//  NotificationHandler.swift
//  LightRoll_CleanerFeature
//
//  通知受信時の処理とナビゲーション
//  - UNUserNotificationCenterDelegateの実装
//  - 通知タップ時の画面遷移（DeepLink対応）
//  - 通知アクション処理（スヌーズ、開く等）
//  - フォアグラウンド通知表示
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T10
//

import Foundation
@preconcurrency import UserNotifications
import Observation
import SwiftUI

// MARK: - NotificationDestination

/// 通知タップ時のナビゲーション先
public enum NotificationDestination: Equatable, Sendable {
    /// ストレージ警告 → ホーム画面
    case home

    /// スキャン完了 → グループ一覧
    case groupList

    /// ゴミ箱期限警告 → ゴミ箱画面
    case trash

    /// リマインダー → ホーム画面
    case reminder

    /// 設定画面
    case settings

    /// 不明な通知（デフォルト動作）
    case unknown
}

// MARK: - NotificationAction

/// 通知アクション
public enum NotificationAction: String, Sendable {
    /// 通知を開く（デフォルト）
    case open = "OPEN_ACTION"

    /// スヌーズ（後で通知）
    case snooze = "SNOOZE_ACTION"

    /// キャンセル
    case cancel = "CANCEL_ACTION"

    /// ゴミ箱を開く
    case openTrash = "OPEN_TRASH_ACTION"

    /// スキャンを開始
    case startScan = "START_SCAN_ACTION"
}

// MARK: - NotificationHandlerError

/// NotificationHandlerのエラー
public enum NotificationHandlerError: Error, Equatable, LocalizedError {
    /// 無効な通知データ
    case invalidNotificationData(reason: String)

    /// ナビゲーション失敗
    case navigationFailed(destination: NotificationDestination)

    /// アクション処理失敗
    case actionProcessingFailed(action: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidNotificationData(let reason):
            return NSLocalizedString(
                "error.notificationHandler.invalidData",
                value: "通知データが無効です: \(reason)",
                comment: "Invalid notification data error"
            )
        case .navigationFailed(let destination):
            return NSLocalizedString(
                "error.notificationHandler.navigationFailed",
                value: "画面遷移に失敗しました: \(destination)",
                comment: "Navigation failed error"
            )
        case .actionProcessingFailed(let action, let reason):
            return NSLocalizedString(
                "error.notificationHandler.actionFailed",
                value: "アクション処理に失敗しました (\(action)): \(reason)",
                comment: "Action processing failed error"
            )
        }
    }

    public static func == (lhs: NotificationHandlerError, rhs: NotificationHandlerError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidNotificationData, .invalidNotificationData),
             (.navigationFailed, .navigationFailed),
             (.actionProcessingFailed, .actionProcessingFailed):
            return true
        default:
            return false
        }
    }
}

// MARK: - NotificationHandler

/// 通知受信時の処理を管理するサービス
///
/// MV Patternに従い、@Observableサービスとして実装
/// - 通知タップ時の画面遷移
/// - 通知アクションの処理
/// - フォアグラウンド通知表示
@MainActor
@Observable
public final class NotificationHandler: NSObject, Sendable {

    // MARK: - Properties

    /// 最後に受信した通知先
    public private(set) var lastDestination: NotificationDestination?

    /// ナビゲーションパス（Viewから監視）
    public private(set) var navigationPath: [NotificationDestination] = []

    /// 最後のエラー
    public private(set) var lastError: NotificationHandlerError?

    /// 通知マネージャー（オプショナル依存）
    private weak var notificationManager: NotificationManager?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter notificationManager: 通知マネージャー（オプショナル）
    public init(notificationManager: NotificationManager? = nil) {
        self.notificationManager = notificationManager
        super.init()
    }

    // MARK: - Public Methods

    /// UNUserNotificationCenterのデリゲートとして設定
    public func setupAsDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 通知識別子から遷移先を決定
    /// - Parameter identifier: 通知識別子
    /// - Returns: ナビゲーション先
    public func destination(for identifier: String) -> NotificationDestination {
        // 通知識別子のプレフィックスで判定
        if identifier.hasPrefix("storage_alert") {
            return .home
        } else if identifier.hasPrefix("scan_completion") {
            return .groupList
        } else if identifier.hasPrefix("trash_expiration") {
            return .trash
        } else if identifier.hasPrefix("reminder") {
            return .reminder
        } else {
            return .unknown
        }
    }

    /// 通知タップ時の処理
    /// - Parameters:
    ///   - identifier: 通知識別子
    ///   - categoryIdentifier: 通知カテゴリ
    public func handleNotificationTap(identifier: String, categoryIdentifier: String) {
        let destination = self.destination(for: identifier)
        lastDestination = destination

        // ナビゲーションパスに追加
        navigationPath.append(destination)

        // エラーをクリア
        lastError = nil
    }

    /// 通知アクションの処理
    /// - Parameters:
    ///   - action: アクション識別子
    ///   - notification: 通知オブジェクト
    public func handleNotificationAction(action: String, notification: UNNotification) async {
        guard let notificationAction = NotificationAction(rawValue: action) else {
            lastError = .actionProcessingFailed(action: action, reason: "Unknown action")
            return
        }

        switch notificationAction {
        case .open:
            // 通知を開く（通常のタップと同じ処理）
            let identifier = notification.request.identifier
            let category = notification.request.content.categoryIdentifier
            handleNotificationTap(identifier: identifier, categoryIdentifier: category)

        case .snooze:
            // スヌーズ処理（10分後に再通知）
            await handleSnooze(notification: notification)

        case .cancel:
            // キャンセル（何もしない）
            lastError = nil

        case .openTrash:
            // ゴミ箱を開く
            lastDestination = .trash
            navigationPath.append(.trash)
            lastError = nil

        case .startScan:
            // スキャン開始（ホーム画面へ）
            lastDestination = .home
            navigationPath.append(.home)
            lastError = nil
        }
    }

    /// ナビゲーションパスをクリア
    public func clearNavigationPath() {
        navigationPath.removeAll()
        lastError = nil
    }

    /// 最後の遷移先をクリア
    public func clearLastDestination() {
        lastDestination = nil
        lastError = nil
    }

    // MARK: - Private Methods

    /// スヌーズ処理（10分後に再通知）
    /// - Parameter notification: 元の通知
    private func handleSnooze(notification: UNNotification) async {
        guard let manager = notificationManager else {
            lastError = .actionProcessingFailed(
                action: "snooze",
                reason: "NotificationManager not available"
            )
            return
        }

        // 10分後のトリガーを作成
        let snoozeTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10 * 60, // 10分
            repeats: false
        )

        // 元の通知内容を使って再スケジュール
        let originalContent = notification.request.content
        let mutableContent = originalContent.mutableCopy() as! UNMutableNotificationContent
        mutableContent.title = "リマインダー: " + originalContent.title

        let snoozeIdentifier = "\(notification.request.identifier)_snooze"

        do {
            try await manager.scheduleNotification(
                identifier: snoozeIdentifier,
                content: mutableContent,
                trigger: snoozeTrigger
            )
            lastError = nil
        } catch {
            lastError = .actionProcessingFailed(
                action: "snooze",
                reason: error.localizedDescription
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationHandler: UNUserNotificationCenterDelegate {

    /// フォアグラウンドで通知を受信したときの処理
    /// - Parameters:
    ///   - center: 通知センター
    ///   - notification: 通知オブジェクト
    ///   - completionHandler: 表示オプションのコールバック
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])
    }

    /// ユーザーが通知をタップしたときの処理
    /// - Parameters:
    ///   - center: 通知センター
    ///   - response: ユーザーの応答
    ///   - completionHandler: 完了コールバック
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            if actionIdentifier == UNNotificationDefaultActionIdentifier {
                // 通知本体をタップ
                handleNotificationTap(
                    identifier: identifier,
                    categoryIdentifier: categoryIdentifier
                )
            } else {
                // 通知アクションをタップ
                await handleNotificationAction(
                    action: actionIdentifier,
                    notification: response.notification
                )
            }
        }

        completionHandler()
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックNotificationHandler
@MainActor
@Observable
public final class MockNotificationHandler: Sendable {

    // MARK: - Test Hooks

    public var setupAsDelegateCalled = false
    public var handleNotificationTapCalled = false
    public var handleNotificationActionCalled = false
    public var clearNavigationPathCalled = false
    public var clearLastDestinationCalled = false

    public var lastTappedIdentifier: String?
    public var lastTappedCategory: String?
    public var lastActionIdentifier: String?
    public var mockNavigationPath: [NotificationDestination] = []
    public var mockLastDestination: NotificationDestination?

    // MARK: - Initialization

    public init() {}

    // MARK: - Mock Methods

    public func setupAsDelegate() {
        setupAsDelegateCalled = true
    }

    public func destination(for identifier: String) -> NotificationDestination {
        if identifier.hasPrefix("storage_alert") {
            return .home
        } else if identifier.hasPrefix("scan_completion") {
            return .groupList
        } else if identifier.hasPrefix("trash_expiration") {
            return .trash
        } else if identifier.hasPrefix("reminder") {
            return .reminder
        } else {
            return .unknown
        }
    }

    public func handleNotificationTap(identifier: String, categoryIdentifier: String) {
        handleNotificationTapCalled = true
        lastTappedIdentifier = identifier
        lastTappedCategory = categoryIdentifier

        let destination = self.destination(for: identifier)
        mockLastDestination = destination
        mockNavigationPath.append(destination)
    }

    public func handleNotificationAction(action: String, notification: UNNotification) async {
        handleNotificationActionCalled = true
        lastActionIdentifier = action
    }

    public func clearNavigationPath() {
        clearNavigationPathCalled = true
        mockNavigationPath.removeAll()
    }

    public func clearLastDestination() {
        clearLastDestinationCalled = true
        mockLastDestination = nil
    }

    // MARK: - Test Helper Methods

    public func reset() {
        setupAsDelegateCalled = false
        handleNotificationTapCalled = false
        handleNotificationActionCalled = false
        clearNavigationPathCalled = false
        clearLastDestinationCalled = false
        lastTappedIdentifier = nil
        lastTappedCategory = nil
        lastActionIdentifier = nil
        mockNavigationPath.removeAll()
        mockLastDestination = nil
    }
}

#endif
