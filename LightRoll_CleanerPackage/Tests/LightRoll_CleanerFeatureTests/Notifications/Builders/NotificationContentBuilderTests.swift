//
//  NotificationContentBuilderTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationContentBuilderのテスト
//  - 各通知タイプのコンテンツ生成テスト
//  - バリデーションテスト
//  - エッジケーステスト
//  Swift Testing framework使用
//

import Testing
@testable import LightRoll_CleanerFeature
import Foundation
@preconcurrency import UserNotifications

// MARK: - NotificationContentBuilder Tests

@MainActor
struct NotificationContentBuilderTests {

    // MARK: - Setup

    /// テスト対象のビルダー
    let builder = NotificationContentBuilder()

    // MARK: - Storage Alert Tests

    @Test("ストレージアラート通知コンテンツ生成 - 標準ケース")
    func buildStorageAlertContent_standard() {
        // Given: 使用率91%、空き容量10GB
        let usedPercentage = 0.91
        let availableSpace: Int64 = 10_000_000_000 // 10GB

        // When: コンテンツ生成
        let content = builder.buildStorageAlertContent(
            usedPercentage: usedPercentage,
            availableSpace: availableSpace
        )

        // Then: 通知コンテンツが正しく生成される
        #expect(content.title == "ストレージ容量が不足しています")
        #expect(content.body.contains("91%"))
        #expect(content.body.contains("残り容量"))
        #expect(content.sound == .default)
        #expect(content.badge == 1)
        #expect(content.categoryIdentifier == "STORAGE_ALERT")

        // ユーザー情報検証
        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["type"] as? String == "storage_alert")
        #expect(userInfo?["usedPercentage"] as? Double == usedPercentage)
        #expect(userInfo?["availableSpace"] as? Int64 == availableSpace)
    }

    @Test("ストレージアラート通知コンテンツ生成 - 使用率100%")
    func buildStorageAlertContent_fullCapacity() {
        // Given: 使用率100%、空き容量0GB
        let usedPercentage = 1.0
        let availableSpace: Int64 = 0

        // When: コンテンツ生成
        let content = builder.buildStorageAlertContent(
            usedPercentage: usedPercentage,
            availableSpace: availableSpace
        )

        // Then: 通知コンテンツが生成される
        #expect(content.body.contains("100%"))
        #expect(!content.title.isEmpty)
        #expect(!content.body.isEmpty)
    }

    @Test("ストレージアラート通知コンテンツ生成 - 小数点以下の使用率")
    func buildStorageAlertContent_decimalPercentage() {
        // Given: 使用率95.5%
        let usedPercentage = 0.955
        let availableSpace: Int64 = 5_000_000_000

        // When: コンテンツ生成
        let content = builder.buildStorageAlertContent(
            usedPercentage: usedPercentage,
            availableSpace: availableSpace
        )

        // Then: パーセンテージが整数で表示される
        #expect(content.body.contains("95%"))
    }

    // MARK: - Reminder Tests

    @Test("リマインダー通知コンテンツ生成 - 毎日")
    func buildReminderContent_daily() {
        // Given: 毎日リマインダー
        let interval = ReminderInterval.daily

        // When: コンテンツ生成
        let content = builder.buildReminderContent(interval: interval)

        // Then: 通知コンテンツが正しく生成される
        #expect(content.title == "クリーンアップのお知らせ")
        #expect(content.body.contains("クリーンアップの時間"))
        #expect(content.sound == .default)
        #expect(content.badge == 1)
        #expect(content.categoryIdentifier == "REMINDER")

        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["type"] as? String == "reminder")
        #expect(userInfo?["interval"] as? String == "daily")
    }

    @Test("リマインダー通知コンテンツ生成 - 毎週")
    func buildReminderContent_weekly() {
        // Given: 毎週リマインダー
        let interval = ReminderInterval.weekly

        // When: コンテンツ生成
        let content = builder.buildReminderContent(interval: interval)

        // Then: 通知コンテンツが生成される
        #expect(!content.title.isEmpty)
        #expect(!content.body.isEmpty)

        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["interval"] as? String == "weekly")
    }

    @Test("リマインダー通知コンテンツ生成 - 2週間ごと")
    func buildReminderContent_biweekly() {
        // Given: 2週間ごとリマインダー
        let interval = ReminderInterval.biweekly

        // When: コンテンツ生成
        let content = builder.buildReminderContent(interval: interval)

        // Then: 通知コンテンツが生成される
        #expect(!content.title.isEmpty)
        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["interval"] as? String == "biweekly")
    }

    @Test("リマインダー通知コンテンツ生成 - 毎月")
    func buildReminderContent_monthly() {
        // Given: 毎月リマインダー
        let interval = ReminderInterval.monthly

        // When: コンテンツ生成
        let content = builder.buildReminderContent(interval: interval)

        // Then: 通知コンテンツが生成される
        #expect(!content.title.isEmpty)
        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["interval"] as? String == "monthly")
    }

    // MARK: - Scan Completion Tests

    @Test("スキャン完了通知コンテンツ生成 - ファイル検出あり")
    func buildScanCompletionContent_withItems() {
        // Given: 25個のファイル、合計500MB
        let itemCount = 25
        let totalSize: Int64 = 500_000_000 // 500MB

        // When: コンテンツ生成
        let content = builder.buildScanCompletionContent(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then: 通知コンテンツが正しく生成される
        #expect(content.title == "スキャン完了")
        #expect(content.body.contains("25個"))
        #expect(content.body.contains("不要ファイル"))
        #expect(content.sound == .default)
        #expect(content.badge == 1)
        #expect(content.categoryIdentifier == "SCAN_COMPLETION")

        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["type"] as? String == "scan_completion")
        #expect(userInfo?["itemCount"] as? Int == itemCount)
        #expect(userInfo?["totalSize"] as? Int64 == totalSize)
    }

    @Test("スキャン完了通知コンテンツ生成 - ファイル検出なし")
    func buildScanCompletionContent_noItems() {
        // Given: 0個のファイル、合計0バイト
        let itemCount = 0
        let totalSize: Int64 = 0

        // When: コンテンツ生成
        let content = builder.buildScanCompletionContent(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then: 「見つかりませんでした」メッセージが含まれる
        #expect(content.title == "スキャン完了")
        #expect(content.body.contains("見つかりませんでした"))
        #expect(content.badge == 0) // バッジなし
    }

    @Test("スキャン完了通知コンテンツ生成 - 大量ファイル")
    func buildScanCompletionContent_largeCount() {
        // Given: 1000個のファイル、合計10GB
        let itemCount = 1000
        let totalSize: Int64 = 10_000_000_000 // 10GB

        // When: コンテンツ生成
        let content = builder.buildScanCompletionContent(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then: 通知コンテンツが生成される
        #expect(content.body.contains("1000個"))
        #expect(content.body.contains("GB"))
    }

    // MARK: - Trash Expiration Tests

    @Test("ゴミ箱期限警告通知コンテンツ生成 - 本日削除")
    func buildTrashExpirationContent_today() {
        // Given: 10個のアイテム、残り0日
        let itemCount = 10
        let expirationDays = 0

        // When: コンテンツ生成
        let content = builder.buildTrashExpirationContent(
            itemCount: itemCount,
            expirationDays: expirationDays
        )

        // Then: 「本日削除されます」メッセージが含まれる
        #expect(content.title == "ゴミ箱の期限警告")
        #expect(content.body.contains("10個"))
        #expect(content.body.contains("本日削除"))
        #expect(content.sound == .default)
        #expect(content.badge == 1)
        #expect(content.categoryIdentifier == "TRASH_EXPIRATION")

        let userInfo = content.userInfo as? [String: Any]
        #expect(userInfo?["type"] as? String == "trash_expiration")
        #expect(userInfo?["itemCount"] as? Int == itemCount)
        #expect(userInfo?["expirationDays"] as? Int == expirationDays)
    }

    @Test("ゴミ箱期限警告通知コンテンツ生成 - 明日削除")
    func buildTrashExpirationContent_tomorrow() {
        // Given: 5個のアイテム、残り1日
        let itemCount = 5
        let expirationDays = 1

        // When: コンテンツ生成
        let content = builder.buildTrashExpirationContent(
            itemCount: itemCount,
            expirationDays: expirationDays
        )

        // Then: 「明日削除されます」メッセージが含まれる
        #expect(content.body.contains("5個"))
        #expect(content.body.contains("明日削除"))
    }

    @Test("ゴミ箱期限警告通知コンテンツ生成 - N日後削除")
    func buildTrashExpirationContent_futureDays() {
        // Given: 15個のアイテム、残り7日
        let itemCount = 15
        let expirationDays = 7

        // When: コンテンツ生成
        let content = builder.buildTrashExpirationContent(
            itemCount: itemCount,
            expirationDays: expirationDays
        )

        // Then: 「N日後に削除されます」メッセージが含まれる
        #expect(content.body.contains("15個"))
        #expect(content.body.contains("7日後"))
    }

    // MARK: - Content Validation Tests

    @Test("通知コンテンツバリデーション - 有効なコンテンツ")
    func isValidContent_validContent() {
        // Given: 有効な通知コンテンツ
        let content = builder.buildStorageAlertContent(
            usedPercentage: 0.9,
            availableSpace: 10_000_000_000
        )

        // When: バリデーション実行
        let isValid = builder.isValidContent(content)

        // Then: 有効と判定される
        #expect(isValid == true)
    }

    @Test("通知コンテンツバリデーション - タイトル未設定")
    func isValidContent_emptyTitle() {
        // Given: タイトルが空のコンテンツ
        let content = UNMutableNotificationContent()
        content.title = ""
        content.body = "本文あり"
        content.categoryIdentifier = "TEST"
        content.userInfo = ["type": "test"]

        // When: バリデーション実行
        let isValid = builder.isValidContent(content)

        // Then: 無効と判定される
        #expect(isValid == false)
    }

    @Test("通知コンテンツバリデーション - 本文未設定")
    func isValidContent_emptyBody() {
        // Given: 本文が空のコンテンツ
        let content = UNMutableNotificationContent()
        content.title = "タイトルあり"
        content.body = ""
        content.categoryIdentifier = "TEST"
        content.userInfo = ["type": "test"]

        // When: バリデーション実行
        let isValid = builder.isValidContent(content)

        // Then: 無効と判定される
        #expect(isValid == false)
    }

    @Test("通知コンテンツバリデーション - カテゴリID未設定")
    func isValidContent_emptyCategoryIdentifier() {
        // Given: カテゴリIDが空のコンテンツ
        let content = UNMutableNotificationContent()
        content.title = "タイトルあり"
        content.body = "本文あり"
        content.categoryIdentifier = ""
        content.userInfo = ["type": "test"]

        // When: バリデーション実行
        let isValid = builder.isValidContent(content)

        // Then: 無効と判定される
        #expect(isValid == false)
    }

    @Test("通知コンテンツバリデーション - type情報未設定")
    func isValidContent_missingTypeInUserInfo() {
        // Given: userInfoにtype情報がないコンテンツ
        let content = UNMutableNotificationContent()
        content.title = "タイトルあり"
        content.body = "本文あり"
        content.categoryIdentifier = "TEST"
        content.userInfo = ["other": "data"]

        // When: バリデーション実行
        let isValid = builder.isValidContent(content)

        // Then: 無効と判定される
        #expect(isValid == false)
    }

    // MARK: - Edge Case Tests

    @Test("エッジケース - 負のストレージ容量")
    func edgeCase_negativeStorageSpace() {
        // Given: 負の空き容量
        let usedPercentage = 0.95
        let availableSpace: Int64 = -1000

        // When: コンテンツ生成
        let content = builder.buildStorageAlertContent(
            usedPercentage: usedPercentage,
            availableSpace: availableSpace
        )

        // Then: エラーなく生成される
        #expect(!content.title.isEmpty)
        #expect(!content.body.isEmpty)
    }

    @Test("エッジケース - 非常に大きなファイル数")
    func edgeCase_veryLargeItemCount() {
        // Given: 100万個のアイテム
        let itemCount = 1_000_000
        let totalSize: Int64 = 1_000_000_000_000 // 1TB

        // When: コンテンツ生成
        let content = builder.buildScanCompletionContent(
            itemCount: itemCount,
            totalSize: totalSize
        )

        // Then: エラーなく生成される
        #expect(content.body.contains("1000000個"))
    }

    @Test("エッジケース - 期限日数が大きい値")
    func edgeCase_largeExpirationDays() {
        // Given: 期限まで365日
        let itemCount = 10
        let expirationDays = 365

        // When: コンテンツ生成
        let content = builder.buildTrashExpirationContent(
            itemCount: itemCount,
            expirationDays: expirationDays
        )

        // Then: エラーなく生成される
        #expect(content.body.contains("365日後"))
    }

    @Test("すべての通知タイプでバリデーションが成功")
    func allNotificationTypes_passValidation() {
        // Given: 各通知タイプのコンテンツ
        let storageContent = builder.buildStorageAlertContent(
            usedPercentage: 0.9,
            availableSpace: 10_000_000_000
        )
        let reminderContent = builder.buildReminderContent(interval: .weekly)
        let scanContent = builder.buildScanCompletionContent(
            itemCount: 10,
            totalSize: 1_000_000
        )
        let trashContent = builder.buildTrashExpirationContent(
            itemCount: 5,
            expirationDays: 7
        )

        // When/Then: すべてバリデーションが成功
        #expect(builder.isValidContent(storageContent) == true)
        #expect(builder.isValidContent(reminderContent) == true)
        #expect(builder.isValidContent(scanContent) == true)
        #expect(builder.isValidContent(trashContent) == true)
    }
}
