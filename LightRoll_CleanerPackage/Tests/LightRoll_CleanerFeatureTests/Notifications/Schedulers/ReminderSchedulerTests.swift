//
//  ReminderSchedulerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ReminderSchedulerのテスト
//  - 初期化テスト
//  - リマインダースケジューリングテスト
//  - 日時計算テスト
//  - 静寂時間帯テスト
//  - ステート管理テスト
//  - エラーハンドリングテスト
//  Created by AI Assistant for M7-T07
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature
@preconcurrency import UserNotifications

// MARK: - Initialization Tests

@Suite("ReminderScheduler初期化テスト")
@MainActor
struct ReminderSchedulerInitializationTests {

    @Test("デフォルト初期化が正しく動作する")
    func defaultInitialization() async throws {
        // Arrange & Act
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Assert
        #expect(scheduler.nextReminderDate == nil)
        #expect(scheduler.lastScheduledInterval == nil)
        #expect(scheduler.isReminderScheduled == false)
        #expect(scheduler.lastError == nil)
        #expect(scheduler.hasScheduledReminder == false)
    }

    @Test("カスタム依存注入が正しく動作する")
    func customDependencyInjection() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let contentBuilder = NotificationContentBuilder()
        let calendar = Calendar.current

        // Act
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            contentBuilder: contentBuilder,
            calendar: calendar
        )

        // Assert
        #expect(scheduler.isReminderScheduled == false)
        #expect(scheduler.nextReminderDate == nil)
    }
}

// MARK: - Reminder Scheduling Tests

@Suite("ReminderSchedulerリマインダースケジューリングテスト")
@MainActor
struct ReminderSchedulerSchedulingTests {

    @Test("リマインダー設定有効時に通知がスケジュールされる")
    func scheduleReminderWhenEnabled() async throws {
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

        // Act
        let scheduledDate = try await scheduler.scheduleReminder()

        // Assert
        #expect(scheduler.isReminderScheduled == true)
        #expect(scheduler.nextReminderDate != nil)
        #expect(scheduler.lastScheduledInterval == .daily)
        #expect(scheduler.lastError == nil)
        #expect(scheduledDate > Date())
    }

    @Test("リマインダー無効時にエラーが発生する")
    func throwsErrorWhenReminderDisabled() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = false // リマインダー無効

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act & Assert
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError == .notificationsDisabled)
        #expect(scheduler.isReminderScheduled == false)
    }

    @Test("権限拒否時にエラーが発生する")
    func throwsErrorWhenPermissionDenied() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.denied)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act & Assert
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError == .permissionDenied)
    }

    @Test("既存通知がキャンセルされて新しい通知がスケジュールされる")
    func reschedulesReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true
        settings.reminderInterval = .daily

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act - 最初のスケジュール
        let firstDate = try await scheduler.scheduleReminder()

        // 設定変更
        var newSettings = notificationManager.settings
        newSettings.reminderInterval = .weekly
        try await notificationManager.updateSettings(newSettings)

        // 再スケジュール
        let secondDate = try await scheduler.rescheduleReminder()

        // Assert
        #expect(scheduler.isReminderScheduled == true)
        #expect(scheduler.lastScheduledInterval == .weekly)
        #expect(firstDate != secondDate)
    }
}

// MARK: - Date Calculation Tests

@Suite("ReminderScheduler日時計算テスト")
@MainActor
struct ReminderSchedulerDateCalculationTests {

    @Test("Daily間隔で翌日10時が計算される")
    func calculatesNextDailyReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let calendar = Calendar.current
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            calendar: calendar
        )

        let now = Date()

        // Act
        let nextDate = scheduler.calculateNextReminderDate(from: now, interval: .daily)

        // Assert
        let components = calendar.dateComponents([.hour, .minute], from: nextDate)
        #expect(components.hour == 10)
        #expect(components.minute == 0)
        #expect(nextDate > now)
    }

    @Test("Weekly間隔で1週間後が計算される")
    func calculatesNextWeeklyReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let calendar = Calendar.current
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            calendar: calendar
        )

        let now = Date()

        // Act
        let nextDate = scheduler.calculateNextReminderDate(from: now, interval: .weekly)

        // Assert
        let daysDifference = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
        #expect(daysDifference >= 7)
        #expect(daysDifference <= 8) // 最大8日（翌日10時 + 7日）

        let components = calendar.dateComponents([.hour], from: nextDate)
        #expect(components.hour == 10)
    }

    @Test("Biweekly間隔で2週間後が計算される")
    func calculatesNextBiweeklyReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let calendar = Calendar.current
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            calendar: calendar
        )

        let now = Date()

        // Act
        let nextDate = scheduler.calculateNextReminderDate(from: now, interval: .biweekly)

        // Assert
        let daysDifference = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
        #expect(daysDifference >= 14)
        #expect(daysDifference <= 15)

        let components = calendar.dateComponents([.hour], from: nextDate)
        #expect(components.hour == 10)
    }

    @Test("Monthly間隔で1ヶ月後が計算される")
    func calculatesNextMonthlyReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let calendar = Calendar.current
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            calendar: calendar
        )

        let now = Date()

        // Act
        let nextDate = scheduler.calculateNextReminderDate(from: now, interval: .monthly)

        // Assert
        // 月の日数によって変わるため、範囲チェック
        let daysDifference = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
        #expect(daysDifference >= 28)
        #expect(daysDifference <= 32)

        let components = calendar.dateComponents([.hour], from: nextDate)
        #expect(components.hour == 10)
    }

    @Test("過去の時刻でも未来の日時が計算される")
    func calculatesFutureDateFromPastTime() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)
        let calendar = Calendar.current
        let scheduler = ReminderScheduler(
            notificationManager: notificationManager,
            calendar: calendar
        )

        // 午後11時（23時）を基準にする
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        let lateTime = calendar.date(from: components) ?? Date()

        // Act
        let nextDate = scheduler.calculateNextReminderDate(from: lateTime, interval: .daily)

        // Assert
        #expect(nextDate > lateTime)
        let nextComponents = calendar.dateComponents([.hour], from: nextDate)
        #expect(nextComponents.hour == 10)
    }
}

// MARK: - Quiet Hours Tests

@Suite("ReminderScheduler静寂時間帯テスト")
@MainActor
struct ReminderSchedulerQuietHoursTests {

    @Test("静寂時間帯中の通知時刻が調整される")
    func adjustsTimeForQuietHours() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true
        settings.reminderInterval = .daily
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22  // 22時
        settings.quietHoursEnd = 8     // 8時（翌朝）

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

    @Test("静寂時間帯無効時は調整されない")
    func doesNotAdjustWhenQuietHoursDisabled() async throws {
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

        // Act
        let scheduledDate = try await scheduler.scheduleReminder()

        // Assert
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: scheduledDate)
        #expect(components.hour == 10) // デフォルトの10時
    }
}

// MARK: - Error Handling Tests

@Suite("ReminderSchedulerエラーハンドリングテスト")
@MainActor
struct ReminderSchedulerErrorHandlingTests {

    @Test("通知機能全体が無効な場合エラーになる")
    func throwsErrorWhenNotificationsDisabled() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        var settings = NotificationSettings.default
        settings.isEnabled = false // 通知全体が無効

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act & Assert
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError == .notificationsDisabled)
    }

    @Test("エラー後にclearError()で状態がクリアされる")
    func clearsErrorAfterClearError() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        var settings = NotificationSettings.default
        settings.isEnabled = false

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // エラーを発生させる
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }
        #expect(scheduler.lastError != nil)

        // Act
        scheduler.clearError()

        // Assert
        #expect(scheduler.lastError == nil)
    }

    @Test("スケジューリング失敗時にエラーが記録される")
    func recordsSchedulingError() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setShouldThrowOnAdd(true)
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act & Assert
        await #expect(throws: ReminderSchedulerError.self) {
            try await scheduler.scheduleReminder()
        }

        #expect(scheduler.lastError != nil)
        if case .schedulingFailed = scheduler.lastError {
            // 正しいエラー型
        } else {
            Issue.record("Expected schedulingFailed error")
        }
    }
}

// MARK: - State Management Tests

@Suite("ReminderSchedulerステート管理テスト")
@MainActor
struct ReminderSchedulerStateManagementTests {

    @Test("リマインダーキャンセル後に状態がリセットされる")
    func resetsStateAfterCancel() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // スケジュール
        _ = try await scheduler.scheduleReminder()
        #expect(scheduler.isReminderScheduled == true)

        // Act - キャンセル
        await scheduler.cancelReminder()

        // Assert
        #expect(scheduler.isReminderScheduled == false)
        #expect(scheduler.nextReminderDate == nil)
        #expect(scheduler.lastScheduledInterval == nil)
        #expect(scheduler.lastError == nil)
    }

    @Test("updateNotificationStatus()で状態が更新される")
    func updatesStatusCorrectly() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // スケジュール
        _ = try await scheduler.scheduleReminder()

        // Act
        await scheduler.updateNotificationStatus()

        // Assert
        #expect(scheduler.isReminderScheduled == true)
    }

    @Test("hasScheduledReminderが正しく動作する")
    func hasScheduledReminderWorksCorrectly() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // 初期状態
        #expect(scheduler.hasScheduledReminder == false)

        // スケジュール後
        _ = try await scheduler.scheduleReminder()
        #expect(scheduler.hasScheduledReminder == true)

        // キャンセル後
        await scheduler.cancelReminder()
        #expect(scheduler.hasScheduledReminder == false)
    }

    @Test("timeUntilNextReminderが正しく計算される")
    func calculatesTimeUntilNextReminder() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // スケジュール前
        #expect(scheduler.timeUntilNextReminder == nil)

        // Act
        _ = try await scheduler.scheduleReminder()

        // Assert
        let timeUntil = scheduler.timeUntilNextReminder
        #expect(timeUntil != nil)
        #expect(timeUntil! > 0) // 未来の日時なので正の値
    }

    @Test("lastScheduledIntervalが正しく記録される")
    func recordsLastScheduledInterval() async throws {
        // Arrange
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(.authorized)

        var settings = NotificationSettings.default
        settings.isEnabled = true
        settings.reminderEnabled = true
        settings.reminderInterval = .weekly

        let notificationManager = NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
        let scheduler = ReminderScheduler(notificationManager: notificationManager)

        // Act
        _ = try await scheduler.scheduleReminder()

        // Assert
        #expect(scheduler.lastScheduledInterval == ReminderInterval.weekly)
    }
}
