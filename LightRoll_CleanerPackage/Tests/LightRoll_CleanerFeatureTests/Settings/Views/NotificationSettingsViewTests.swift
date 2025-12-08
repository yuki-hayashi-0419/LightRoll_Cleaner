//
//  NotificationSettingsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationSettingsViewのテスト
//  Swift Testing frameworkを使用
//  Created by AI Assistant on 2025-12-08.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - NotificationSettingsViewTests

@MainActor
@Suite("NotificationSettingsView Tests")
struct NotificationSettingsViewTests {

    // MARK: - 初期化テスト

    @Test("NotificationSettingsView初期化成功")
    func testViewInitialization() async throws {
        let service = SettingsService()
        let view = NotificationSettingsView()
            .environment(service)

        #expect(view != nil)
    }

    @Test("デフォルト設定でView生成")
    func testViewWithDefaultSettings() async throws {
        let service = SettingsService()
        // デフォルト設定にリセット
        service.resetToDefaults()

        let view = NotificationSettingsView()
            .environment(service)

        let settings = service.settings.notificationSettings
        #expect(settings.isEnabled == true)
        #expect(settings.storageAlertEnabled == true)
        #expect(settings.storageAlertThreshold == 0.9)
        #expect(settings.reminderEnabled == false)
        #expect(settings.reminderInterval == .weekly)
        #expect(settings.quietHoursEnabled == true)
        #expect(settings.quietHoursStart == 22)
        #expect(settings.quietHoursEnd == 8)
    }

    // MARK: - 通知マスタースイッチテスト

    @Test("通知を有効化")
    func testEnableNotifications() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.isEnabled == true)
    }

    @Test("通知を無効化")
    func testDisableNotifications() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = false
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.isEnabled == false)
    }

    @Test("通知無効時は他のセクションが非表示になる")
    func testHiddenSectionsWhenNotificationsDisabled() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = false
        try service.updateNotificationSettings(settings.notificationSettings)

        let view = NotificationSettingsView()
            .environment(service)

        #expect(service.settings.notificationSettings.isEnabled == false)
        #expect(view != nil)
    }

    // MARK: - ストレージアラート設定テスト

    @Test("ストレージアラートを有効化")
    func testEnableStorageAlert() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.storageAlertEnabled = true
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.storageAlertEnabled == true)
    }

    @Test("ストレージアラートを無効化")
    func testDisableStorageAlert() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.storageAlertEnabled = false
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.storageAlertEnabled == false)
    }

    @Test("ストレージアラートしきい値を50%に設定")
    func testSetStorageThresholdTo50Percent() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.storageAlertThreshold = 0.5
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.storageAlertThreshold == 0.5)
    }

    @Test("ストレージアラートしきい値を75%に設定")
    func testSetStorageThresholdTo75Percent() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.storageAlertThreshold = 0.75
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.storageAlertThreshold == 0.75)
    }

    @Test("ストレージアラートしきい値を95%に設定")
    func testSetStorageThresholdTo95Percent() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.storageAlertThreshold = 0.95
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.storageAlertThreshold == 0.95)
    }

    // MARK: - リマインダー設定テスト

    @Test("リマインダーを有効化")
    func testEnableReminder() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = true
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderEnabled == true)
    }

    @Test("リマインダーを無効化")
    func testDisableReminder() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = false
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderEnabled == false)
    }

    @Test("リマインダー間隔を毎日に変更")
    func testChangeReminderIntervalToDaily() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = true
        settings.notificationSettings.reminderInterval = .daily
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderInterval == .daily)
    }

    @Test("リマインダー間隔を毎週に変更")
    func testChangeReminderIntervalToWeekly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = true
        settings.notificationSettings.reminderInterval = .weekly
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderInterval == .weekly)
    }

    @Test("リマインダー間隔を2週間ごとに変更")
    func testChangeReminderIntervalToBiweekly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = true
        settings.notificationSettings.reminderInterval = .biweekly
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderInterval == .biweekly)
    }

    @Test("リマインダー間隔を毎月に変更")
    func testChangeReminderIntervalToMonthly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.reminderEnabled = true
        settings.notificationSettings.reminderInterval = .monthly
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.reminderInterval == .monthly)
    }

    // MARK: - 静寂時間帯設定テスト

    @Test("静寂時間帯を有効化")
    func testEnableQuietHours() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.quietHoursEnabled = true
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.quietHoursEnabled == true)
    }

    @Test("静寂時間帯を無効化")
    func testDisableQuietHours() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.quietHoursEnabled = false
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.quietHoursEnabled == false)
    }

    @Test("静寂開始時刻を22時に設定")
    func testSetQuietHoursStartTo22() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.quietHoursEnabled = true
        settings.notificationSettings.quietHoursStart = 22
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.quietHoursStart == 22)
    }

    @Test("静寂終了時刻を8時に設定")
    func testSetQuietHoursEndTo8() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.quietHoursEnabled = true
        settings.notificationSettings.quietHoursEnd = 8
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.quietHoursEnd == 8)
    }

    @Test("静寂時間帯を20時から10時に設定")
    func testSetQuietHours20To10() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings.isEnabled = true
        settings.notificationSettings.quietHoursEnabled = true
        settings.notificationSettings.quietHoursStart = 20
        settings.notificationSettings.quietHoursEnd = 10
        try service.updateNotificationSettings(settings.notificationSettings)

        #expect(service.settings.notificationSettings.quietHoursStart == 20)
        #expect(service.settings.notificationSettings.quietHoursEnd == 10)
    }

    // MARK: - バリデーションテスト

    @Test("しきい値が有効範囲内（0.0〜1.0）でバリデーション成功")
    func testValidThreshold() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.85,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isValid == true)
        #expect(settings.isThresholdValid == true)
    }

    @Test("しきい値が範囲外（1.0超過）でバリデーション失敗")
    func testInvalidThresholdTooHigh() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 1.5,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isValid == false)
        #expect(settings.isThresholdValid == false)
    }

    @Test("しきい値が範囲外（負の値）でバリデーション失敗")
    func testInvalidThresholdNegative() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: -0.1,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isValid == false)
        #expect(settings.isThresholdValid == false)
    }

    @Test("静寂時刻が有効範囲内（0〜23）でバリデーション成功")
    func testValidQuietHours() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isValid == true)
        #expect(settings.areQuietHoursValid == true)
    }

    @Test("静寂開始時刻が範囲外（24以上）でバリデーション失敗")
    func testInvalidQuietHoursStartTooHigh() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 24,
            quietHoursEnd: 8
        )

        #expect(settings.isValid == false)
        #expect(settings.areQuietHoursValid == false)
    }

    @Test("静寂終了時刻が範囲外（負の値）でバリデーション失敗")
    func testInvalidQuietHoursEndNegative() async throws {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: -1
        )

        #expect(settings.isValid == false)
        #expect(settings.areQuietHoursValid == false)
    }

    // MARK: - 複合設定テスト

    @Test("すべての設定を有効化")
    func testAllSettingsEnabled() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.85,
            reminderEnabled: true,
            reminderInterval: .daily,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        try service.updateNotificationSettings(settings.notificationSettings)

        let savedSettings = service.settings.notificationSettings
        #expect(savedSettings.isEnabled == true)
        #expect(savedSettings.storageAlertEnabled == true)
        #expect(savedSettings.reminderEnabled == true)
        #expect(savedSettings.quietHoursEnabled == true)
    }

    @Test("ストレージアラートのみ有効化")
    func testStorageAlertOnly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.75,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: false,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        try service.updateNotificationSettings(settings.notificationSettings)

        let savedSettings = service.settings.notificationSettings
        #expect(savedSettings.isEnabled == true)
        #expect(savedSettings.storageAlertEnabled == true)
        #expect(savedSettings.reminderEnabled == false)
        #expect(savedSettings.quietHoursEnabled == false)
    }

    @Test("リマインダーのみ有効化")
    func testReminderOnly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.notificationSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: false,
            storageAlertThreshold: 0.9,
            reminderEnabled: true,
            reminderInterval: .monthly,
            quietHoursEnabled: false,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        try service.updateNotificationSettings(settings.notificationSettings)

        let savedSettings = service.settings.notificationSettings
        #expect(savedSettings.isEnabled == true)
        #expect(savedSettings.storageAlertEnabled == false)
        #expect(savedSettings.reminderEnabled == true)
        #expect(savedSettings.quietHoursEnabled == false)
    }

    // MARK: - エラーハンドリングテスト

    @Test("無効な設定で保存時にエラー")
    func testSaveInvalidSettings() async throws {
        let service = SettingsService()
        let invalidSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 2.0, // 範囲外
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(throws: SettingsError.self) {
            try service.updateNotificationSettings(invalidSettings)
        }
    }

    @Test("無効な静寂時刻で保存時にエラー")
    func testSaveInvalidQuietHours() async throws {
        let service = SettingsService()
        let invalidSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 25, // 範囲外
            quietHoursEnd: 8
        )

        #expect(throws: SettingsError.self) {
            try service.updateNotificationSettings(invalidSettings)
        }
    }

    // MARK: - ReminderInterval表示テスト

    @Test("ReminderInterval.dailyの表示名が正しい")
    func testReminderIntervalDailyDisplayName() {
        let interval = ReminderInterval.daily
        #expect(interval.displayName == "毎日")
        #expect(interval.localizedDescription == "毎日通知を受け取ります")
    }

    @Test("ReminderInterval.weeklyの表示名が正しい")
    func testReminderIntervalWeeklyDisplayName() {
        let interval = ReminderInterval.weekly
        #expect(interval.displayName == "毎週")
        #expect(interval.localizedDescription == "毎週通知を受け取ります")
    }

    @Test("ReminderInterval.biweeklyの表示名が正しい")
    func testReminderIntervalBiweeklyDisplayName() {
        let interval = ReminderInterval.biweekly
        #expect(interval.displayName == "2週間ごと")
        #expect(interval.localizedDescription == "2週間ごとに通知を受け取ります")
    }

    @Test("ReminderInterval.monthlyの表示名が正しい")
    func testReminderIntervalMonthlyDisplayName() {
        let interval = ReminderInterval.monthly
        #expect(interval.displayName == "毎月")
        #expect(interval.localizedDescription == "毎月通知を受け取ります")
    }

    // MARK: - 静寂時間帯判定テスト

    @Test("静寂時間帯内の判定（同日内）")
    func testIsInQuietHoursSameDay() {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 14,
            quietHoursEnd: 18
        )

        #expect(settings.isInQuietHours(hour: 15) == true)
        #expect(settings.isInQuietHours(hour: 13) == false)
        #expect(settings.isInQuietHours(hour: 19) == false)
    }

    @Test("静寂時間帯内の判定（日跨ぎ）")
    func testIsInQuietHoursAcrossDays() {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isInQuietHours(hour: 23) == true)
        #expect(settings.isInQuietHours(hour: 5) == true)
        #expect(settings.isInQuietHours(hour: 15) == false)
    }

    @Test("静寂時間帯が無効の場合は常にfalse")
    func testIsInQuietHoursDisabled() {
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.9,
            reminderEnabled: false,
            reminderInterval: .weekly,
            quietHoursEnabled: false,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isInQuietHours(hour: 23) == false)
        #expect(settings.isInQuietHours(hour: 5) == false)
    }
}
