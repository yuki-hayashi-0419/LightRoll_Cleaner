//
//  ScanCompletionNotifier.swift
//  LightRoll_CleanerFeature
//
//  スキャン完了通知の送信
//  - スキャン完了イベントの通知
//  - 削除候補数・サイズの通知
//  - 通知タップでアプリを開く
//  - 静寂時間帯考慮
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T08
//

import Foundation
@preconcurrency import UserNotifications
import Observation

// MARK: - ScanCompletionNotifierError

/// ScanCompletionNotifierのエラー
public enum ScanCompletionNotifierError: Error, Equatable, LocalizedError {
    /// 通知のスケジューリングに失敗
    case schedulingFailed(reason: String)

    /// 通知設定が無効
    case notificationsDisabled

    /// 権限が拒否されている
    case permissionDenied

    /// 静寂時間帯中のため通知がスキップされた
    case quietHoursActive

    /// 無効なパラメータ
    case invalidParameters(reason: String)

    public var errorDescription: String? {
        switch self {
        case .schedulingFailed(let reason):
            return NSLocalizedString(
                "error.scanCompletionNotifier.schedulingFailed",
                value: "スキャン完了通知の送信に失敗しました: \(reason)",
                comment: "Scheduling failed error"
            )
        case .notificationsDisabled:
            return NSLocalizedString(
                "error.scanCompletionNotifier.notificationsDisabled",
                value: "スキャン完了通知が無効になっています",
                comment: "Notifications disabled error"
            )
        case .permissionDenied:
            return NSLocalizedString(
                "error.scanCompletionNotifier.permissionDenied",
                value: "通知権限が拒否されています",
                comment: "Permission denied error"
            )
        case .quietHoursActive:
            return NSLocalizedString(
                "error.scanCompletionNotifier.quietHoursActive",
                value: "静寂時間帯のため通知がスキップされました",
                comment: "Quiet hours active error"
            )
        case .invalidParameters(let reason):
            return NSLocalizedString(
                "error.scanCompletionNotifier.invalidParameters",
                value: "無効なパラメータ: \(reason)",
                comment: "Invalid parameters error"
            )
        }
    }

    public static func == (lhs: ScanCompletionNotifierError, rhs: ScanCompletionNotifierError) -> Bool {
        switch (lhs, rhs) {
        case (.schedulingFailed, .schedulingFailed),
             (.notificationsDisabled, .notificationsDisabled),
             (.permissionDenied, .permissionDenied),
             (.quietHoursActive, .quietHoursActive),
             (.invalidParameters, .invalidParameters):
            return true
        default:
            return false
        }
    }
}

// MARK: - ScanCompletionNotifier

/// スキャン完了通知を送信するサービス
///
/// MV Patternに従い、@Observableサービスとして実装
/// - スキャン完了時に通知を送信
/// - 削除候補数と合計サイズを通知に含める
/// - 静寂時間帯を考慮
/// - 通知タップでアプリを開く
@MainActor
@Observable
public final class ScanCompletionNotifier: Sendable {

    // MARK: - Properties

    /// 最後に通知した削除候補数
    public private(set) var lastNotifiedItemCount: Int = 0

    /// 最後に通知した合計サイズ（バイト）
    public private(set) var lastNotifiedTotalSize: Int64 = 0

    /// 最後に通知を送信した日時
    public private(set) var lastNotificationDate: Date?

    /// 通知が送信されたか
    public private(set) var wasNotificationSent: Bool = false

    /// 最後に発生したエラー
    public private(set) var lastError: ScanCompletionNotifierError?

    /// NotificationManagerの参照
    private let notificationManager: NotificationManager

    /// NotificationContentBuilderの参照
    private let contentBuilder: NotificationContentBuilder

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - notificationManager: NotificationManager
    ///   - contentBuilder: NotificationContentBuilder
    public init(
        notificationManager: NotificationManager,
        contentBuilder: NotificationContentBuilder = NotificationContentBuilder()
    ) {
        self.notificationManager = notificationManager
        self.contentBuilder = contentBuilder
    }

    // MARK: - Notification Sending

    /// スキャン完了通知を送信
    ///
    /// スキャンが完了したことをユーザーに通知します。
    /// 削除候補が見つかった場合と見つからなかった場合で異なるメッセージを表示します。
    ///
    /// - Parameters:
    ///   - itemCount: 検出された削除候補の数
    ///   - totalSize: 削除候補の合計サイズ（バイト）
    /// - Throws: ScanCompletionNotifierError
    public func notifyScanCompletion(
        itemCount: Int,
        totalSize: Int64
    ) async throws {
        // パラメータバリデーション
        guard itemCount >= 0 else {
            let error = ScanCompletionNotifierError.invalidParameters(
                reason: "アイテム数は0以上である必要があります"
            )
            lastError = error
            throw error
        }

        guard totalSize >= 0 else {
            let error = ScanCompletionNotifierError.invalidParameters(
                reason: "合計サイズは0以上である必要があります"
            )
            lastError = error
            throw error
        }

        // 通知設定を確認
        guard notificationManager.settings.isEnabled else {
            let error = ScanCompletionNotifierError.notificationsDisabled
            lastError = error
            throw error
        }

        // 権限確認
        await notificationManager.updateAuthorizationStatus()
        guard notificationManager.isAuthorized else {
            let error = ScanCompletionNotifierError.permissionDenied
            lastError = error
            throw error
        }

        // 静寂時間帯チェック
        if notificationManager.isInQuietHours {
            let error = ScanCompletionNotifierError.quietHoursActive
            lastError = error
            throw error
        }

        // 既存の通知をキャンセル
        await notificationManager.cancelNotification(.scanCompletion)

        // 通知コンテンツを生成
        let content = contentBuilder.buildScanCompletionContent(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // 即時通知（5秒後に配信）
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )

        // 通知をスケジュール
        do {
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.scanCompletion.identifier,
                content: content,
                trigger: trigger
            )

            // 状態を更新
            lastNotifiedItemCount = itemCount
            lastNotifiedTotalSize = totalSize
            lastNotificationDate = Date()
            wasNotificationSent = true
            lastError = nil

        } catch {
            let notifierError = ScanCompletionNotifierError.schedulingFailed(
                reason: error.localizedDescription
            )
            lastError = notifierError
            wasNotificationSent = false
            throw notifierError
        }
    }

    /// スキャン完了通知を送信（アイテムなし）
    ///
    /// 削除候補が見つからなかった場合の簡易メソッド
    ///
    /// - Throws: ScanCompletionNotifierError
    public func notifyNoItemsFound() async throws {
        try await notifyScanCompletion(itemCount: 0, totalSize: 0)
    }

    /// スキャン完了通知をキャンセル
    ///
    /// ペンディング中のスキャン完了通知をキャンセルします
    public func cancelScanCompletionNotification() async {
        await notificationManager.cancelNotification(.scanCompletion)
        wasNotificationSent = false
        lastError = nil
    }

    // MARK: - Utility Methods

    /// 通知送信状態をリセット
    ///
    /// 次回のスキャン開始時などに状態をクリアします
    public func resetNotificationState() {
        lastNotifiedItemCount = 0
        lastNotifiedTotalSize = 0
        lastNotificationDate = nil
        wasNotificationSent = false
        lastError = nil
    }

    /// エラーをクリア
    public func clearError() {
        lastError = nil
    }

    /// 最後の通知から経過した時間（秒）
    ///
    /// - Returns: 経過秒数。通知が送信されていない場合はnil
    public var timeSinceLastNotification: TimeInterval? {
        guard let lastNotificationDate else { return nil }
        return Date().timeIntervalSince(lastNotificationDate)
    }

    /// 通知が有効かを判定
    ///
    /// 通知設定が有効で、権限が許可されている場合にtrue
    /// - Returns: 通知が有効な場合true
    public var isNotificationEnabled: Bool {
        notificationManager.settings.isEnabled && notificationManager.isAuthorized
    }

    /// 静寂時間帯中かを判定
    ///
    /// - Returns: 静寂時間帯内の場合true
    public var isInQuietHours: Bool {
        notificationManager.isInQuietHours
    }
}
