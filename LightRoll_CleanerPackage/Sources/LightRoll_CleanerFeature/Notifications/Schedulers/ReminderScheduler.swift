//
//  ReminderScheduler.swift
//  LightRoll_CleanerFeature
//
//  リマインダー通知のスケジューリング
//  - 定期的なリマインダー通知
//  - 次回通知日時の計算
//  - 通知スケジューリング
//  - 静寂時間帯考慮
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T07
//

import Foundation
@preconcurrency import UserNotifications
import Observation

// MARK: - ReminderSchedulerError

/// ReminderSchedulerのエラー
public enum ReminderSchedulerError: Error, Equatable, LocalizedError {
    /// 通知のスケジューリングに失敗
    case schedulingFailed(reason: String)

    /// 通知設定が無効
    case notificationsDisabled

    /// 権限が拒否されている
    case permissionDenied

    /// 静寂時間帯中のため通知がスキップされた
    case quietHoursActive

    /// 無効な間隔設定
    case invalidInterval

    public var errorDescription: String? {
        switch self {
        case .schedulingFailed(let reason):
            return NSLocalizedString(
                "error.reminderScheduler.schedulingFailed",
                value: "リマインダー通知のスケジューリングに失敗しました: \(reason)",
                comment: "Scheduling failed error"
            )
        case .notificationsDisabled:
            return NSLocalizedString(
                "error.reminderScheduler.notificationsDisabled",
                value: "リマインダー通知が無効になっています",
                comment: "Notifications disabled error"
            )
        case .permissionDenied:
            return NSLocalizedString(
                "error.reminderScheduler.permissionDenied",
                value: "通知権限が拒否されています",
                comment: "Permission denied error"
            )
        case .quietHoursActive:
            return NSLocalizedString(
                "error.reminderScheduler.quietHoursActive",
                value: "静寂時間帯のため通知がスキップされました",
                comment: "Quiet hours active error"
            )
        case .invalidInterval:
            return NSLocalizedString(
                "error.reminderScheduler.invalidInterval",
                value: "無効なリマインダー間隔が設定されています",
                comment: "Invalid interval error"
            )
        }
    }

    public static func == (lhs: ReminderSchedulerError, rhs: ReminderSchedulerError) -> Bool {
        switch (lhs, rhs) {
        case (.schedulingFailed, .schedulingFailed),
             (.notificationsDisabled, .notificationsDisabled),
             (.permissionDenied, .permissionDenied),
             (.quietHoursActive, .quietHoursActive),
             (.invalidInterval, .invalidInterval):
            return true
        default:
            return false
        }
    }
}

// MARK: - ReminderScheduler

/// リマインダー通知のスケジューラー
///
/// MV Patternに従い、@Observableサービスとして実装
/// - 定期的なリマインダー通知をスケジュール
/// - 次回通知日時を計算
/// - 静寂時間帯を考慮
/// - 通知の重複を防ぐ
@MainActor
@Observable
public final class ReminderScheduler: Sendable {

    // MARK: - Properties

    /// 次回リマインダー日時
    public private(set) var nextReminderDate: Date?

    /// 最後にスケジュールした間隔
    public private(set) var lastScheduledInterval: ReminderInterval?

    /// リマインダーが現在スケジュールされているか
    public private(set) var isReminderScheduled: Bool = false

    /// 最後に発生したエラー
    public private(set) var lastError: ReminderSchedulerError?

    /// NotificationManagerの参照
    private let notificationManager: NotificationManager

    /// NotificationContentBuilderの参照
    private let contentBuilder: NotificationContentBuilder

    /// Calendar（日時計算用）
    private let calendar: Calendar

    /// デフォルトの通知時刻（時）
    /// リマインダーは午前10時に送信される
    private let defaultReminderHour: Int = 10

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - notificationManager: NotificationManager
    ///   - contentBuilder: NotificationContentBuilder
    ///   - calendar: Calendar（デフォルトは.current）
    public init(
        notificationManager: NotificationManager,
        contentBuilder: NotificationContentBuilder = NotificationContentBuilder(),
        calendar: Calendar = .current
    ) {
        self.notificationManager = notificationManager
        self.contentBuilder = contentBuilder
        self.calendar = calendar
    }

    // MARK: - Reminder Scheduling

    /// リマインダー通知をスケジュール
    ///
    /// 現在の設定に基づいてリマインダー通知をスケジュールします。
    /// 既存の通知がある場合は再スケジュールされます。
    ///
    /// - Throws: ReminderSchedulerError
    @discardableResult
    public func scheduleReminder() async throws -> Date {
        // 通知設定を確認
        guard notificationManager.settings.isEnabled else {
            let error = ReminderSchedulerError.notificationsDisabled
            lastError = error
            throw error
        }

        guard notificationManager.settings.reminderEnabled else {
            let error = ReminderSchedulerError.notificationsDisabled
            lastError = error
            throw error
        }

        // 権限確認
        await notificationManager.updateAuthorizationStatus()
        guard notificationManager.isAuthorized else {
            let error = ReminderSchedulerError.permissionDenied
            lastError = error
            throw error
        }

        let interval = notificationManager.settings.reminderInterval

        // 次回通知日時を計算
        let nextDate = calculateNextReminderDate(from: Date(), interval: interval)

        // 静寂時間帯チェック（次回通知日時の時刻をチェック）
        let components = calendar.dateComponents([.hour], from: nextDate)
        if let hour = components.hour,
           notificationManager.settings.isInQuietHours(hour: hour) {
            // 静寂時間帯の場合は、終了時刻の1時間後に調整
            let adjustedDate = adjustDateForQuietHours(nextDate)
            return try await scheduleReminderInternal(for: adjustedDate, interval: interval)
        }

        return try await scheduleReminderInternal(for: nextDate, interval: interval)
    }

    /// リマインダーを再スケジュール
    ///
    /// 設定変更時などに既存の通知をキャンセルして再スケジュールします。
    ///
    /// - Throws: ReminderSchedulerError
    @discardableResult
    public func rescheduleReminder() async throws -> Date {
        // 既存の通知をキャンセル
        await cancelReminder()

        // 新しい通知をスケジュール
        return try await scheduleReminder()
    }

    /// リマインダー通知をキャンセル
    public func cancelReminder() async {
        await notificationManager.cancelNotification(.reminder)
        isReminderScheduled = false
        nextReminderDate = nil
        lastScheduledInterval = nil
        lastError = nil
    }

    // MARK: - Private Methods

    /// リマインダー通知を内部スケジュール
    ///
    /// - Parameters:
    ///   - date: スケジュール日時
    ///   - interval: リマインダー間隔
    /// - Returns: スケジュールされた日時
    /// - Throws: ReminderSchedulerError
    private func scheduleReminderInternal(for date: Date, interval: ReminderInterval) async throws -> Date {
        // 既存の通知をキャンセル
        await notificationManager.cancelNotification(.reminder)

        // 通知コンテンツを生成
        let content = contentBuilder.buildReminderContent(interval: interval)

        // カレンダーベースのトリガーを作成
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        // 通知をスケジュール
        do {
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.reminder.identifier,
                content: content,
                trigger: trigger
            )

            nextReminderDate = date
            lastScheduledInterval = interval
            isReminderScheduled = true
            lastError = nil

            return date
        } catch {
            let schedulerError = ReminderSchedulerError.schedulingFailed(
                reason: error.localizedDescription
            )
            lastError = schedulerError
            throw schedulerError
        }
    }

    /// 次回リマインダー日時を計算
    ///
    /// - Parameters:
    ///   - currentDate: 基準日時
    ///   - interval: リマインダー間隔
    /// - Returns: 次回リマインダー日時
    public func calculateNextReminderDate(from currentDate: Date, interval: ReminderInterval) -> Date {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)

        // 時刻を午前10時に設定
        components.hour = defaultReminderHour
        components.minute = 0
        components.second = 0

        // 基準日時を取得
        guard var baseDate = calendar.date(from: components) else {
            return currentDate
        }

        // 基準日時が過去の場合は翌日にする
        if baseDate <= currentDate {
            baseDate = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        }

        // 間隔に基づいて日付を調整
        let nextDate: Date
        switch interval {
        case .daily:
            // 翌日
            nextDate = baseDate
        case .weekly:
            // 1週間後
            nextDate = calendar.date(byAdding: .day, value: 7, to: baseDate) ?? baseDate
        case .biweekly:
            // 2週間後
            nextDate = calendar.date(byAdding: .day, value: 14, to: baseDate) ?? baseDate
        case .monthly:
            // 1ヶ月後
            nextDate = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
        }

        return nextDate
    }

    /// 静寂時間帯を考慮して日時を調整
    ///
    /// - Parameter date: 調整前の日時
    /// - Returns: 調整後の日時
    private func adjustDateForQuietHours(_ date: Date) -> Date {
        let settings = notificationManager.settings

        guard settings.quietHoursEnabled else {
            return date
        }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // 静寂時間帯終了時刻の1時間後に調整
        let endHour = settings.quietHoursEnd
        let adjustedHour = (endHour + 1) % 24

        components.hour = adjustedHour
        components.minute = 0
        components.second = 0

        return calendar.date(from: components) ?? date
    }

    // MARK: - Utility Methods

    /// 現在の通知スケジュール状態を更新
    ///
    /// ペンディング通知の存在を確認して状態を更新する
    public func updateNotificationStatus() async {
        isReminderScheduled = await notificationManager.hasNotification(.reminder)

        // 通知が存在しない場合は状態をリセット
        if !isReminderScheduled {
            nextReminderDate = nil
            lastScheduledInterval = nil
        }
    }

    /// エラーをクリア
    public func clearError() {
        lastError = nil
    }

    /// 次回通知までの残り時間（秒）
    ///
    /// - Returns: 残り秒数。スケジュールされていない場合はnil
    public var timeUntilNextReminder: TimeInterval? {
        guard let nextReminderDate else { return nil }
        return nextReminderDate.timeIntervalSince(Date())
    }

    /// 次回通知が予定されているか
    public var hasScheduledReminder: Bool {
        return nextReminderDate != nil && isReminderScheduled
    }
}
