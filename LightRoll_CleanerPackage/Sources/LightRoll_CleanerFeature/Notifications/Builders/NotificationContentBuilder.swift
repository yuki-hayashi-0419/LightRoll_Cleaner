//
//  NotificationContentBuilder.swift
//  LightRoll_CleanerFeature
//
//  通知コンテンツビルダー
//  - UNNotificationContent生成
//  - 各通知タイプのメッセージテンプレート
//  - 日本語通知文言
//  - Swift 6 Concurrency対応（Sendable準拠）
//  Created by AI Assistant for M7-T05
//

import Foundation
@preconcurrency import UserNotifications

// MARK: - NotificationContentBuilder

/// 通知コンテンツを生成するビルダー
///
/// 各種通知タイプ（ストレージアラート、リマインダー、スキャン完了、ゴミ箱期限警告）に対応した
/// UNNotificationContentを生成します。すべての通知文言は日本語で提供されます。
public struct NotificationContentBuilder: Sendable {

    // MARK: - Initialization

    /// デフォルトイニシャライザ
    public init() {}

    // MARK: - Storage Alert Notification

    /// ストレージアラート通知コンテンツを生成
    ///
    /// 空き容量が少なくなったときの警告通知を作成します。
    ///
    /// - Parameters:
    ///   - usedPercentage: 使用率（0.0〜1.0）
    ///   - availableSpace: 利用可能な空き容量（バイト）
    /// - Returns: ストレージアラート用の通知コンテンツ
    public func buildStorageAlertContent(
        usedPercentage: Double,
        availableSpace: Int64
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // パーセンテージを整数で表示（例: 0.91 -> 91%）
        let usedPercent = Int(usedPercentage * 100)

        // 空き容量をGB単位で表示
        let availableGB = ByteFormatter.format(bytes: availableSpace, unit: .gigabytes)

        content.title = "ストレージ容量が不足しています"
        content.body = "使用率: \(usedPercent)% - 残り容量: \(availableGB)GB\n不要なファイルをクリーンアップしましょう。"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "STORAGE_ALERT"

        // ユーザー情報に使用率と空き容量を格納
        content.userInfo = [
            "type": "storage_alert",
            "usedPercentage": usedPercentage,
            "availableSpace": availableSpace
        ]

        return content
    }

    // MARK: - Reminder Notification

    /// リマインダー通知コンテンツを生成
    ///
    /// 定期的なクリーンアップを促すリマインダー通知を作成します。
    ///
    /// - Parameter interval: リマインダー間隔
    /// - Returns: リマインダー用の通知コンテンツ
    public func buildReminderContent(
        interval: ReminderInterval
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        content.title = "クリーンアップのお知らせ"
        content.body = "定期的なクリーンアップの時間です。\nストレージを整理してデバイスを快適に保ちましょう。"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "REMINDER"

        content.userInfo = [
            "type": "reminder",
            "interval": interval.rawValue
        ]

        return content
    }

    // MARK: - Scan Completion Notification

    /// スキャン完了通知コンテンツを生成
    ///
    /// スキャンが完了したことをユーザーに通知します。
    ///
    /// - Parameters:
    ///   - itemCount: 検出された不要ファイル数
    ///   - totalSize: 不要ファイルの合計サイズ（バイト）
    /// - Returns: スキャン完了用の通知コンテンツ
    public func buildScanCompletionContent(
        itemCount: Int,
        totalSize: Int64
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // サイズをMB/GB単位で表示
        let sizeText = ByteFormatter.formatAuto(bytes: totalSize)

        content.title = "スキャン完了"

        if itemCount > 0 {
            content.body = "\(itemCount)個の不要ファイルが見つかりました。\n合計サイズ: \(sizeText)\nタップして確認しましょう。"
        } else {
            content.body = "不要なファイルは見つかりませんでした。\nストレージは良好な状態です。"
        }

        content.sound = .default
        content.badge = itemCount > 0 ? 1 : 0
        content.categoryIdentifier = "SCAN_COMPLETION"

        content.userInfo = [
            "type": "scan_completion",
            "itemCount": itemCount,
            "totalSize": totalSize
        ]

        return content
    }

    // MARK: - Trash Expiration Warning Notification

    /// ゴミ箱期限警告通知コンテンツを生成
    ///
    /// ゴミ箱に入っているファイルの保持期限が近づいたことを警告します。
    ///
    /// - Parameters:
    ///   - itemCount: ゴミ箱内のアイテム数
    ///   - expirationDays: 期限までの残り日数
    /// - Returns: ゴミ箱期限警告用の通知コンテンツ
    public func buildTrashExpirationContent(
        itemCount: Int,
        expirationDays: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        content.title = "ゴミ箱の期限警告"

        if expirationDays == 0 {
            content.body = "ゴミ箱内の\(itemCount)個のアイテムが本日削除されます。\n復元したいファイルがないか確認しましょう。"
        } else if expirationDays == 1 {
            content.body = "ゴミ箱内の\(itemCount)個のアイテムが明日削除されます。\n復元したいファイルがないか確認しましょう。"
        } else {
            content.body = "ゴミ箱内の\(itemCount)個のアイテムが\(expirationDays)日後に削除されます。\n復元したいファイルがないか確認しましょう。"
        }

        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRASH_EXPIRATION"

        content.userInfo = [
            "type": "trash_expiration",
            "itemCount": itemCount,
            "expirationDays": expirationDays
        ]

        return content
    }

    // MARK: - Content Validation

    /// 通知コンテンツが有効かどうかを検証
    ///
    /// - Parameter content: 検証する通知コンテンツ
    /// - Returns: コンテンツが有効な場合true
    public func isValidContent(_ content: UNNotificationContent) -> Bool {
        // タイトルと本文が空でないことを確認
        guard !content.title.isEmpty else { return false }
        guard !content.body.isEmpty else { return false }

        // カテゴリIDが設定されていることを確認
        guard !content.categoryIdentifier.isEmpty else { return false }

        // ユーザー情報にtype情報が含まれていることを確認
        guard let userInfo = content.userInfo as? [String: Any],
              let _ = userInfo["type"] as? String else {
            return false
        }

        return true
    }
}

// MARK: - ByteFormatter

/// バイトサイズをフォーマットするユーティリティ
private struct ByteFormatter {

    /// バイト単位
    enum Unit {
        case bytes
        case kilobytes
        case megabytes
        case gigabytes
    }

    /// バイトを指定された単位でフォーマット
    ///
    /// - Parameters:
    ///   - bytes: バイト数
    ///   - unit: 変換先の単位
    ///   - decimalPlaces: 小数点以下の桁数（デフォルト: 2）
    /// - Returns: フォーマットされた文字列
    static func format(
        bytes: Int64,
        unit: Unit,
        decimalPlaces: Int = 2
    ) -> String {
        let divisor: Double

        switch unit {
        case .bytes:
            return "\(bytes)"
        case .kilobytes:
            divisor = 1024.0
        case .megabytes:
            divisor = 1024.0 * 1024.0
        case .gigabytes:
            divisor = 1024.0 * 1024.0 * 1024.0
        }

        let converted = Double(bytes) / divisor
        return String(format: "%.\(decimalPlaces)f", converted)
    }

    /// バイトを最適な単位で自動フォーマット
    ///
    /// - Parameter bytes: バイト数
    /// - Returns: フォーマットされた文字列（単位付き）
    static func formatAuto(bytes: Int64) -> String {
        let kb: Double = 1024.0
        let mb: Double = kb * 1024.0
        let gb: Double = mb * 1024.0

        let absoluteBytes = abs(bytes)

        if absoluteBytes >= Int64(gb) {
            let value = Double(bytes) / gb
            return String(format: "%.2f GB", value)
        } else if absoluteBytes >= Int64(mb) {
            let value = Double(bytes) / mb
            return String(format: "%.2f MB", value)
        } else if absoluteBytes >= Int64(kb) {
            let value = Double(bytes) / kb
            return String(format: "%.2f KB", value)
        } else {
            return "\(bytes) bytes"
        }
    }
}
