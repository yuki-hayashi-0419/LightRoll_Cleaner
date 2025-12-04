//
//  UserSettings.swift
//  LightRoll_CleanerFeature
//
//  Created by AI Assistant on 2025-12-04.
//

import Foundation

// MARK: - UserSettings

/// アプリ全体のユーザー設定を管理するモデル
public struct UserSettings: Codable, Sendable, Equatable {
    public var scanSettings: ScanSettings
    public var analysisSettings: AnalysisSettings
    public var notificationSettings: NotificationSettings
    public var displaySettings: DisplaySettings
    public var premiumStatus: PremiumStatus

    public init(
        scanSettings: ScanSettings = .default,
        analysisSettings: AnalysisSettings = .default,
        notificationSettings: NotificationSettings = .default,
        displaySettings: DisplaySettings = .default,
        premiumStatus: PremiumStatus = .free
    ) {
        self.scanSettings = scanSettings
        self.analysisSettings = analysisSettings
        self.notificationSettings = notificationSettings
        self.displaySettings = displaySettings
        self.premiumStatus = premiumStatus
    }
}

extension UserSettings {
    /// デフォルト設定
    public static let `default` = UserSettings(
        scanSettings: .default,
        analysisSettings: .default,
        notificationSettings: .default,
        displaySettings: .default,
        premiumStatus: .free
    )
}

// MARK: - ScanSettings

/// スキャン動作に関する設定
public struct ScanSettings: Codable, Sendable, Equatable {
    public var autoScanEnabled: Bool
    public var autoScanInterval: AutoScanInterval
    public var includeVideos: Bool
    public var includeScreenshots: Bool
    public var includeSelfies: Bool

    public init(
        autoScanEnabled: Bool = false,
        autoScanInterval: AutoScanInterval = .weekly,
        includeVideos: Bool = true,
        includeScreenshots: Bool = true,
        includeSelfies: Bool = true
    ) {
        self.autoScanEnabled = autoScanEnabled
        self.autoScanInterval = autoScanInterval
        self.includeVideos = includeVideos
        self.includeScreenshots = includeScreenshots
        self.includeSelfies = includeSelfies
    }
}

extension ScanSettings {
    /// デフォルト設定
    public static let `default` = ScanSettings(
        autoScanEnabled: false,
        autoScanInterval: .weekly,
        includeVideos: true,
        includeScreenshots: true,
        includeSelfies: true
    )

    /// 少なくとも1つのコンテンツタイプが有効か
    public var hasAnyContentTypeEnabled: Bool {
        includeVideos || includeScreenshots || includeSelfies
    }

    /// バリデーション
    public func validate() throws {
        // 少なくとも1つのコンテンツタイプが有効であることを確認
        guard hasAnyContentTypeEnabled else {
            throw SettingsError.noContentTypeEnabled
        }
    }
}

// MARK: - AnalysisSettings

/// 画像分析に関する設定
public struct AnalysisSettings: Codable, Sendable, Equatable {
    public var similarityThreshold: Float
    public var blurThreshold: Float
    public var minGroupSize: Int

    public init(
        similarityThreshold: Float = 0.85,
        blurThreshold: Float = 0.3,
        minGroupSize: Int = 2
    ) {
        self.similarityThreshold = similarityThreshold
        self.blurThreshold = blurThreshold
        self.minGroupSize = minGroupSize
    }
}

extension AnalysisSettings {
    /// デフォルト設定
    public static let `default` = AnalysisSettings(
        similarityThreshold: 0.85,
        blurThreshold: 0.3,
        minGroupSize: 2
    )

    /// バリデーション
    public func validate() throws {
        // 類似度閾値の検証（0.0〜1.0）
        guard similarityThreshold >= 0.0 && similarityThreshold <= 1.0 else {
            throw SettingsError.invalidSimilarityThreshold
        }

        // ブレ閾値の検証（0.0〜1.0）
        guard blurThreshold >= 0.0 && blurThreshold <= 1.0 else {
            throw SettingsError.invalidBlurThreshold
        }

        // 最小グループサイズの検証（2以上）
        guard minGroupSize >= 2 else {
            throw SettingsError.invalidMinGroupSize
        }
    }
}

// MARK: - NotificationSettings

/// 通知に関する設定
public struct NotificationSettings: Codable, Sendable, Equatable {
    public var enabled: Bool
    public var capacityWarning: Bool
    public var reminderEnabled: Bool
    public var quietHoursStart: Int
    public var quietHoursEnd: Int

    public init(
        enabled: Bool = false,
        capacityWarning: Bool = true,
        reminderEnabled: Bool = false,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 8
    ) {
        self.enabled = enabled
        self.capacityWarning = capacityWarning
        self.reminderEnabled = reminderEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}

extension NotificationSettings {
    /// デフォルト設定
    public static let `default` = NotificationSettings(
        enabled: false,
        capacityWarning: true,
        reminderEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )

    /// 現在時刻が静寂時間内かどうか
    public var isQuietHours: Bool {
        let now = Calendar.current.component(.hour, from: Date())

        if quietHoursStart < quietHoursEnd {
            // 通常のケース（例: 22時〜8時 → 22-23, 0-7）
            return now >= quietHoursStart || now < quietHoursEnd
        } else {
            // 日をまたがないケース（例: 8時〜22時）
            return now >= quietHoursStart && now < quietHoursEnd
        }
    }

    /// バリデーション
    public func validate() throws {
        // 静寂時間の開始時刻検証（0〜23）
        guard quietHoursStart >= 0 && quietHoursStart < 24 else {
            throw SettingsError.invalidQuietHours
        }

        // 静寂時間の終了時刻検証（0〜23）
        guard quietHoursEnd >= 0 && quietHoursEnd < 24 else {
            throw SettingsError.invalidQuietHours
        }
    }
}

// MARK: - DisplaySettings

/// 表示に関する設定
public struct DisplaySettings: Codable, Sendable, Equatable {
    public var gridColumns: Int
    public var showFileSize: Bool
    public var showDate: Bool
    public var sortOrder: SortOrder

    public init(
        gridColumns: Int = 4,
        showFileSize: Bool = true,
        showDate: Bool = true,
        sortOrder: SortOrder = .dateDescending
    ) {
        self.gridColumns = gridColumns
        self.showFileSize = showFileSize
        self.showDate = showDate
        self.sortOrder = sortOrder
    }
}

extension DisplaySettings {
    /// デフォルト設定
    public static let `default` = DisplaySettings(
        gridColumns: 4,
        showFileSize: true,
        showDate: true,
        sortOrder: .dateDescending
    )

    /// バリデーション
    public func validate() throws {
        // グリッドカラム数の検証（1〜6）
        guard gridColumns >= 1 && gridColumns <= 6 else {
            throw SettingsError.invalidGridColumns
        }
    }
}

// MARK: - SortOrder

/// ソート順序
public enum SortOrder: String, Codable, CaseIterable, Sendable {
    case dateDescending = "新しい順"
    case dateAscending = "古い順"
    case sizeDescending = "容量大きい順"
    case sizeAscending = "容量小さい順"
}

extension SortOrder {
    /// 表示用のラベル
    public var displayName: String {
        rawValue
    }
}

// MARK: - AutoScanInterval

/// 自動スキャン間隔
public enum AutoScanInterval: String, Codable, CaseIterable, Sendable {
    case daily = "毎日"
    case weekly = "毎週"
    case monthly = "毎月"
    case never = "しない"
}

extension AutoScanInterval {
    /// 表示用のラベル
    public var displayName: String {
        rawValue
    }

    /// 秒数に変換（neverの場合はnil）
    public var timeInterval: TimeInterval? {
        switch self {
        case .daily:
            return 86400 // 1日
        case .weekly:
            return 604800 // 7日
        case .monthly:
            return 2592000 // 30日
        case .never:
            return nil
        }
    }
}

// MARK: - PremiumStatus

/// プレミアムステータス
public enum PremiumStatus: String, Codable, Sendable {
    case free
    case premium
}

extension PremiumStatus {
    /// 無料版かどうか
    public var isFree: Bool {
        self == .free
    }

    /// プレミアム版かどうか
    public var isPremium: Bool {
        self == .premium
    }

    /// 表示用ラベル
    public var displayName: String {
        switch self {
        case .free:
            return "無料版"
        case .premium:
            return "プレミアム版"
        }
    }
}

// MARK: - SettingsError

/// 設定関連のエラー
public enum SettingsError: LocalizedError, Sendable {
    case invalidSimilarityThreshold
    case invalidBlurThreshold
    case invalidMinGroupSize
    case invalidGridColumns
    case invalidQuietHours
    case noContentTypeEnabled

    public var errorDescription: String? {
        switch self {
        case .invalidSimilarityThreshold:
            return "類似度閾値は0.0〜1.0の範囲で指定してください。"
        case .invalidBlurThreshold:
            return "ブレ閾値は0.0〜1.0の範囲で指定してください。"
        case .invalidMinGroupSize:
            return "最小グループサイズは2以上を指定してください。"
        case .invalidGridColumns:
            return "グリッドカラム数は1〜6の範囲で指定してください。"
        case .invalidQuietHours:
            return "静寂時間は0〜23の範囲で指定してください。"
        case .noContentTypeEnabled:
            return "少なくとも1つのコンテンツタイプを有効にしてください。"
        }
    }
}
