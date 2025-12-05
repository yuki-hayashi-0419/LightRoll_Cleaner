//
//  NotificationSettingsTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationSettingsモデルのテスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

@Suite("NotificationSettings Tests")
struct NotificationSettingsTests {

    // MARK: - Initialization Tests

    @Test("デフォルト値の確認")
    func testDefaultInitialization() {
        let settings = NotificationSettings()

        #expect(settings.isEnabled == true)
        #expect(settings.storageAlertEnabled == true)
        #expect(settings.storageAlertThreshold == 0.9)
        #expect(settings.reminderEnabled == false)
        #expect(settings.reminderInterval == .weekly)
        #expect(settings.quietHoursEnabled == true)
        #expect(settings.quietHoursStart == 22)
        #expect(settings.quietHoursEnd == 8)
    }

    @Test("カスタムイニシャライザの動作確認")
    func testCustomInitialization() {
        let settings = NotificationSettings(
            isEnabled: false,
            storageAlertEnabled: false,
            storageAlertThreshold: 0.5,
            reminderEnabled: true,
            reminderInterval: .daily,
            quietHoursEnabled: false,
            quietHoursStart: 20,
            quietHoursEnd: 7
        )

        #expect(settings.isEnabled == false)
        #expect(settings.storageAlertEnabled == false)
        #expect(settings.storageAlertThreshold == 0.5)
        #expect(settings.reminderEnabled == true)
        #expect(settings.reminderInterval == .daily)
        #expect(settings.quietHoursEnabled == false)
        #expect(settings.quietHoursStart == 20)
        #expect(settings.quietHoursEnd == 7)
    }

    @Test("デフォルト設定の取得")
    func testDefaultStaticProperty() {
        let defaultSettings = NotificationSettings.default

        #expect(defaultSettings.isEnabled == true)
        #expect(defaultSettings.storageAlertThreshold == 0.9)
        #expect(defaultSettings.quietHoursStart == 22)
    }

    // MARK: - Validation Tests

    @Test("有効なしきい値の検証 - 0.0")
    func testValidThresholdMinimum() {
        let settings = NotificationSettings(storageAlertThreshold: 0.0)
        #expect(settings.isThresholdValid == true)
        #expect(settings.isValid == true)
    }

    @Test("有効なしきい値の検証 - 0.5")
    func testValidThresholdMiddle() {
        let settings = NotificationSettings(storageAlertThreshold: 0.5)
        #expect(settings.isThresholdValid == true)
        #expect(settings.isValid == true)
    }

    @Test("有効なしきい値の検証 - 1.0")
    func testValidThresholdMaximum() {
        let settings = NotificationSettings(storageAlertThreshold: 1.0)
        #expect(settings.isThresholdValid == true)
        #expect(settings.isValid == true)
    }

    @Test("無効なしきい値の検証 - 負の値")
    func testInvalidThresholdNegative() {
        let settings = NotificationSettings(storageAlertThreshold: -0.1)
        #expect(settings.isThresholdValid == false)
        #expect(settings.isValid == false)
    }

    @Test("無効なしきい値の検証 - 1.0超過")
    func testInvalidThresholdExceedsOne() {
        let settings = NotificationSettings(storageAlertThreshold: 1.1)
        #expect(settings.isThresholdValid == false)
        #expect(settings.isValid == false)
    }

    @Test("有効な静寂時間帯の検証 - 同日内")
    func testValidQuietHoursSameDay() {
        let settings = NotificationSettings(quietHoursStart: 10, quietHoursEnd: 18)
        #expect(settings.areQuietHoursValid == true)
        #expect(settings.isValid == true)
    }

    @Test("有効な静寂時間帯の検証 - 日跨ぎ")
    func testValidQuietHoursAcrossMidnight() {
        let settings = NotificationSettings(quietHoursStart: 22, quietHoursEnd: 8)
        #expect(settings.areQuietHoursValid == true)
        #expect(settings.isValid == true)
    }

    @Test("無効な静寂時間帯の検証 - 開始時刻が範囲外")
    func testInvalidQuietHoursStartOutOfRange() {
        let settings = NotificationSettings(quietHoursStart: 24, quietHoursEnd: 8)
        #expect(settings.areQuietHoursValid == false)
        #expect(settings.isValid == false)
    }

    @Test("無効な静寂時間帯の検証 - 終了時刻が範囲外")
    func testInvalidQuietHoursEndOutOfRange() {
        let settings = NotificationSettings(quietHoursStart: 22, quietHoursEnd: -1)
        #expect(settings.areQuietHoursValid == false)
        #expect(settings.isValid == false)
    }

    // MARK: - ReminderInterval Tests

    @Test("ReminderInterval - displayName正確性")
    func testReminderIntervalDisplayNames() {
        #expect(ReminderInterval.daily.displayName == "毎日")
        #expect(ReminderInterval.weekly.displayName == "毎週")
        #expect(ReminderInterval.biweekly.displayName == "2週間ごと")
        #expect(ReminderInterval.monthly.displayName == "毎月")
    }

    @Test("ReminderInterval - localizedDescription")
    func testReminderIntervalLocalizedDescription() {
        #expect(ReminderInterval.daily.localizedDescription == "毎日通知を受け取ります")
        #expect(ReminderInterval.weekly.localizedDescription == "毎週通知を受け取ります")
        #expect(ReminderInterval.biweekly.localizedDescription == "2週間ごとに通知を受け取ります")
        #expect(ReminderInterval.monthly.localizedDescription == "毎月通知を受け取ります")
    }

    @Test("ReminderInterval - timeInterval変換")
    func testReminderIntervalTimeIntervals() {
        #expect(ReminderInterval.daily.timeInterval == 86400)
        #expect(ReminderInterval.weekly.timeInterval == 604800)
        #expect(ReminderInterval.biweekly.timeInterval == 1209600)
        #expect(ReminderInterval.monthly.timeInterval == 2592000)
    }

    @Test("ReminderInterval - CaseIterable網羅性")
    func testReminderIntervalAllCases() {
        let allCases = ReminderInterval.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.daily))
        #expect(allCases.contains(.weekly))
        #expect(allCases.contains(.biweekly))
        #expect(allCases.contains(.monthly))
    }

    @Test("ReminderInterval - Codableエンコード/デコード")
    func testReminderIntervalCodable() throws {
        let original = ReminderInterval.biweekly
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReminderInterval.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.rawValue == "biweekly")
    }

    // MARK: - Integration Tests

    @Test("Codableエンコード/デコード - 完全な設定")
    func testNotificationSettingsCodable() throws {
        let original = NotificationSettings(
            isEnabled: false,
            storageAlertEnabled: true,
            storageAlertThreshold: 0.75,
            reminderEnabled: true,
            reminderInterval: .daily,
            quietHoursEnabled: true,
            quietHoursStart: 23,
            quietHoursEnd: 7
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationSettings.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.storageAlertThreshold == 0.75)
        #expect(decoded.reminderInterval == .daily)
    }

    @Test("Equatable動作確認 - 同一設定")
    func testEquatableSameSettings() {
        let settings1 = NotificationSettings()
        let settings2 = NotificationSettings()

        #expect(settings1 == settings2)
    }

    @Test("Equatable動作確認 - 異なる設定")
    func testEquatableDifferentSettings() {
        let settings1 = NotificationSettings(isEnabled: true)
        let settings2 = NotificationSettings(isEnabled: false)

        #expect(settings1 != settings2)
    }

    // MARK: - Edge Case Tests

    @Test("境界値 - しきい値0.0と1.0")
    func testThresholdBoundaryValues() {
        let settings0 = NotificationSettings(storageAlertThreshold: 0.0)
        let settings1 = NotificationSettings(storageAlertThreshold: 1.0)

        #expect(settings0.isValid == true)
        #expect(settings1.isValid == true)
    }

    @Test("境界値 - 時刻0と23")
    func testHourBoundaryValues() {
        let settings = NotificationSettings(quietHoursStart: 0, quietHoursEnd: 23)

        #expect(settings.areQuietHoursValid == true)
        #expect(settings.isValid == true)
    }

    @Test("複数の不正値が存在する場合")
    func testMultipleInvalidValues() {
        let settings = NotificationSettings(
            storageAlertThreshold: -0.5,
            quietHoursStart: 25,
            quietHoursEnd: -2
        )

        #expect(settings.isThresholdValid == false)
        #expect(settings.areQuietHoursValid == false)
        #expect(settings.isValid == false)
    }

    // MARK: - Quiet Hours Logic Tests

    @Test("静寂時間帯判定 - 同日内（10時〜18時）")
    func testQuietHoursSameDayLogic() {
        let settings = NotificationSettings(
            quietHoursEnabled: true,
            quietHoursStart: 10,
            quietHoursEnd: 18
        )

        #expect(settings.isInQuietHours(hour: 9) == false)
        #expect(settings.isInQuietHours(hour: 10) == true)
        #expect(settings.isInQuietHours(hour: 14) == true)
        #expect(settings.isInQuietHours(hour: 17) == true)
        #expect(settings.isInQuietHours(hour: 18) == false)
    }

    @Test("静寂時間帯判定 - 日跨ぎ（22時〜8時）")
    func testQuietHoursAcrossMidnightLogic() {
        let settings = NotificationSettings(
            quietHoursEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isInQuietHours(hour: 21) == false)
        #expect(settings.isInQuietHours(hour: 22) == true)
        #expect(settings.isInQuietHours(hour: 23) == true)
        #expect(settings.isInQuietHours(hour: 0) == true)
        #expect(settings.isInQuietHours(hour: 7) == true)
        #expect(settings.isInQuietHours(hour: 8) == false)
    }

    @Test("静寂時間帯判定 - 無効時は常にfalse")
    func testQuietHoursDisabled() {
        let settings = NotificationSettings(
            quietHoursEnabled: false,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        #expect(settings.isInQuietHours(hour: 22) == false)
        #expect(settings.isInQuietHours(hour: 0) == false)
    }

    @Test("静寂時間帯判定 - 開始と終了が同じ時刻（24時間静寂）")
    func testQuietHours24Hours() {
        let settings = NotificationSettings(
            quietHoursEnabled: true,
            quietHoursStart: 10,
            quietHoursEnd: 10
        )

        #expect(settings.isInQuietHours(hour: 0) == true)
        #expect(settings.isInQuietHours(hour: 10) == true)
        #expect(settings.isInQuietHours(hour: 23) == true)
    }

    @Test("CustomStringConvertible - description")
    func testCustomStringConvertible() {
        let settings = NotificationSettings()
        let description = settings.description

        #expect(description.contains("NotificationSettings"))
        #expect(description.contains("isEnabled: true"))
        #expect(description.contains("storageAlertThreshold: 0.9"))
    }
}
