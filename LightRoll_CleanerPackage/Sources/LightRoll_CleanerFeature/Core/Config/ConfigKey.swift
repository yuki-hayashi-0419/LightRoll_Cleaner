import Foundation

// MARK: - ConfigKey

/// アプリケーション設定キーを定義する列挙型
/// UserDefaultsやAppStorageで使用するキーを一元管理
public enum ConfigKey {
    // MARK: - Feature Flags

    /// 分析機能の有効化
    public static let enableAnalytics = "enableAnalytics"

    /// クラッシュレポートの有効化
    public static let enableCrashReporting = "enableCrashReporting"

    // MARK: - Photo Analysis Settings

    /// 類似度判定の閾値（0.0〜1.0）
    public static let similarityThreshold = "similarityThreshold"

    /// 同時分析の最大数
    public static let maxConcurrentAnalysis = "maxConcurrentAnalysis"

    /// サムネイルキャッシュサイズ（MB）
    public static let thumbnailCacheSize = "thumbnailCacheSize"

    /// ブレ検出の感度（0.0〜1.0）
    public static let blurDetectionSensitivity = "blurDetectionSensitivity"

    // MARK: - Storage Settings

    /// 空き容量警告の閾値（バイト）
    public static let minFreeSpaceWarning = "minFreeSpaceWarning"

    /// ゴミ箱の保持日数
    public static let trashRetentionDays = "trashRetentionDays"

    // MARK: - UI Settings

    /// グリッドの列数
    public static let gridColumns = "gridColumns"

    /// アニメーション時間（秒）
    public static let animationDuration = "animationDuration"

    /// ダークモード設定
    public static let appearanceMode = "appearanceMode"

    // MARK: - Premium Features

    /// プレミアムユーザーかどうか
    public static let isPremiumUser = "isPremiumUser"

    /// 無料ユーザーの1日あたり最大削除枚数
    public static let maxFreePhotosPerDay = "maxFreePhotosPerDay"

    /// 今日の削除枚数
    public static let todayDeletedCount = "todayDeletedCount"

    /// 最終削除日
    public static let lastDeleteDate = "lastDeleteDate"

    // MARK: - Notification Settings

    /// 通知の有効化
    public static let enableNotifications = "enableNotifications"

    /// 空き容量警告通知の有効化
    public static let enableStorageWarningNotification = "enableStorageWarningNotification"

    /// 定期リマインダーの有効化
    public static let enablePeriodicReminder = "enablePeriodicReminder"

    /// リマインダー間隔（日数）
    public static let reminderIntervalDays = "reminderIntervalDays"

    // MARK: - Scan Settings

    /// 自動スキャンの有効化
    public static let enableAutoScan = "enableAutoScan"

    /// スクリーンショット検出の有効化
    public static let enableScreenshotDetection = "enableScreenshotDetection"

    /// 類似写真検出の有効化
    public static let enableSimilarPhotoDetection = "enableSimilarPhotoDetection"

    /// ブレ写真検出の有効化
    public static let enableBlurryPhotoDetection = "enableBlurryPhotoDetection"

    // MARK: - App State

    /// 初回起動フラグ
    public static let isFirstLaunch = "isFirstLaunch"

    /// 最終スキャン日時
    public static let lastScanDate = "lastScanDate"

    /// オンボーディング完了フラグ
    public static let hasCompletedOnboarding = "hasCompletedOnboarding"
}

// MARK: - ConfigKey + UserDefaults Extension

extension ConfigKey {
    /// UserDefaultsのスイート名（App Groups用）
    public static let suiteName: String? = nil  // 将来的にApp Groups対応時に設定

    /// 共有のUserDefaults
    public static var userDefaults: UserDefaults {
        if let suiteName = suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
