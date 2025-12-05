//
//  NotificationSettings.swift
//  LightRoll_CleanerFeature
//
//  通知設定モデル
//  - ストレージアラート設定
//  - リマインダー設定
//  - 静寂時間帯設定
//

import Foundation

// MARK: - ReminderInterval

/// リマインダー間隔を表す列挙型
public enum ReminderInterval: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    /// 日本語表示名
    public var displayName: String {
        switch self {
        case .daily:
            return "毎日"
        case .weekly:
            return "毎週"
        case .biweekly:
            return "2週間ごと"
        case .monthly:
            return "毎月"
        }
    }

    /// ローカライズされた説明文
    public var localizedDescription: String {
        switch self {
        case .daily:
            return "毎日通知を受け取ります"
        case .weekly:
            return "毎週通知を受け取ります"
        case .biweekly:
            return "2週間ごとに通知を受け取ります"
        case .monthly:
            return "毎月通知を受け取ります"
        }
    }

    /// TimeInterval変換（秒数）
    public var timeInterval: TimeInterval {
        switch self {
        case .daily:
            return 86400 // 24時間
        case .weekly:
            return 604800 // 7日間
        case .biweekly:
            return 1209600 // 14日間
        case .monthly:
            return 2592000 // 30日間（概算）
        }
    }
}

// MARK: - NotificationSettings

/// 通知設定を管理する構造体
public struct NotificationSettings: Codable, Equatable, Sendable {

    // MARK: - Properties

    /// 通知機能の有効/無効
    public var isEnabled: Bool

    /// ストレージアラートの有効/無効
    public var storageAlertEnabled: Bool

    /// ストレージアラートのしきい値（0.0〜1.0）
    public var storageAlertThreshold: Double

    /// リマインダーの有効/無効
    public var reminderEnabled: Bool

    /// リマインダー間隔
    public var reminderInterval: ReminderInterval

    /// 静寂時間帯の有効/無効
    public var quietHoursEnabled: Bool

    /// 静寂時間帯の開始時刻（0〜23）
    public var quietHoursStart: Int

    /// 静寂時間帯の終了時刻（0〜23）
    public var quietHoursEnd: Int

    // MARK: - Initialization

    /// デフォルトイニシャライザ
    public init(
        isEnabled: Bool = true,
        storageAlertEnabled: Bool = true,
        storageAlertThreshold: Double = 0.9,
        reminderEnabled: Bool = false,
        reminderInterval: ReminderInterval = .weekly,
        quietHoursEnabled: Bool = true,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 8
    ) {
        self.isEnabled = isEnabled
        self.storageAlertEnabled = storageAlertEnabled
        self.storageAlertThreshold = storageAlertThreshold
        self.reminderEnabled = reminderEnabled
        self.reminderInterval = reminderInterval
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }

    // MARK: - Validation

    /// 設定の妥当性を検証
    public var isValid: Bool {
        return isThresholdValid && areQuietHoursValid
    }

    /// しきい値の妥当性を検証（0.0〜1.0範囲）
    public var isThresholdValid: Bool {
        return storageAlertThreshold >= 0.0 && storageAlertThreshold <= 1.0
    }

    /// 静寂時間帯の妥当性を検証
    public var areQuietHoursValid: Bool {
        return isHourValid(quietHoursStart) && isHourValid(quietHoursEnd)
    }

    /// 時刻の妥当性を検証（0〜23範囲）
    private func isHourValid(_ hour: Int) -> Bool {
        return hour >= 0 && hour <= 23
    }

    // MARK: - Helper Methods

    /// 指定された時刻が静寂時間帯内かどうかを判定
    /// - Parameter hour: 判定する時刻（0〜23）
    /// - Returns: 静寂時間帯内の場合true
    public func isInQuietHours(hour: Int) -> Bool {
        guard quietHoursEnabled && isHourValid(hour) else {
            return false
        }

        // 開始時刻 < 終了時刻の場合（同日内）
        if quietHoursStart < quietHoursEnd {
            return hour >= quietHoursStart && hour < quietHoursEnd
        }
        // 開始時刻 > 終了時刻の場合（日跨ぎ）
        else if quietHoursStart > quietHoursEnd {
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
        // 開始時刻 == 終了時刻の場合（24時間静寂）
        else {
            return true
        }
    }

    /// 現在時刻が静寂時間帯内かどうかを判定
    /// - Returns: 静寂時間帯内の場合true
    public func isCurrentlyInQuietHours() -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return isInQuietHours(hour: currentHour)
    }

    /// デフォルト設定を取得
    public static var `default`: NotificationSettings {
        return NotificationSettings()
    }
}

// MARK: - CustomStringConvertible

extension NotificationSettings: CustomStringConvertible {
    public var description: String {
        return """
        NotificationSettings(
            isEnabled: \(isEnabled),
            storageAlertEnabled: \(storageAlertEnabled),
            storageAlertThreshold: \(storageAlertThreshold),
            reminderEnabled: \(reminderEnabled),
            reminderInterval: \(reminderInterval.displayName),
            quietHoursEnabled: \(quietHoursEnabled),
            quietHours: \(quietHoursStart):00-\(quietHoursEnd):00
        )
        """
    }
}
