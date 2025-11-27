import Foundation
import SwiftUI

// MARK: - AppConfig

/// アプリケーション全体の設定を管理するシングルトンクラス
/// UserDefaultsとの連携により設定値を永続化
@MainActor
public final class AppConfig: ObservableObject {
    // MARK: - Singleton

    /// 共有インスタンス
    public static let shared = AppConfig()

    // MARK: - UserDefaults

    private let defaults: UserDefaults

    // MARK: - App Info (Read-only)

    /// アプリバージョン
    public var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// ビルド番号
    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// バンドル識別子
    public var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.example.LightRollCleaner"
    }

    /// 完全なバージョン文字列
    public var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }

    // MARK: - Feature Flags

    /// デバッグモードかどうか
    public var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// 分析機能の有効化
    @Published public var enableAnalytics: Bool {
        didSet {
            defaults.set(enableAnalytics, forKey: ConfigKey.enableAnalytics)
        }
    }

    /// クラッシュレポートの有効化
    @Published public var enableCrashReporting: Bool {
        didSet {
            defaults.set(enableCrashReporting, forKey: ConfigKey.enableCrashReporting)
        }
    }

    // MARK: - Photo Analysis Settings

    /// 類似度判定の閾値（デフォルト: 0.85）
    /// 範囲: 0.5〜1.0
    @Published public var similarityThreshold: Double {
        didSet {
            let validated = Self.validateSimilarityThreshold(similarityThreshold)
            if similarityThreshold != validated {
                similarityThreshold = validated
            }
            defaults.set(similarityThreshold, forKey: ConfigKey.similarityThreshold)
        }
    }

    /// 同時分析の最大数（デフォルト: 4）
    /// 範囲: 1〜8
    @Published public var maxConcurrentAnalysis: Int {
        didSet {
            let validated = Self.validateMaxConcurrentAnalysis(maxConcurrentAnalysis)
            if maxConcurrentAnalysis != validated {
                maxConcurrentAnalysis = validated
            }
            defaults.set(maxConcurrentAnalysis, forKey: ConfigKey.maxConcurrentAnalysis)
        }
    }

    /// サムネイルキャッシュサイズ（MB、デフォルト: 100）
    /// 範囲: 50〜500
    @Published public var thumbnailCacheSize: Int {
        didSet {
            let validated = Self.validateThumbnailCacheSize(thumbnailCacheSize)
            if thumbnailCacheSize != validated {
                thumbnailCacheSize = validated
            }
            defaults.set(thumbnailCacheSize, forKey: ConfigKey.thumbnailCacheSize)
        }
    }

    /// ブレ検出の感度（デフォルト: 0.5）
    /// 範囲: 0.0〜1.0
    @Published public var blurDetectionSensitivity: Double {
        didSet {
            let validated = Self.validateBlurDetectionSensitivity(blurDetectionSensitivity)
            if blurDetectionSensitivity != validated {
                blurDetectionSensitivity = validated
            }
            defaults.set(blurDetectionSensitivity, forKey: ConfigKey.blurDetectionSensitivity)
        }
    }

    // MARK: - Storage Settings

    /// 空き容量警告の閾値（バイト、デフォルト: 500MB）
    @Published public var minFreeSpaceWarning: Int64 {
        didSet {
            let validated = Self.validateMinFreeSpaceWarning(minFreeSpaceWarning)
            if minFreeSpaceWarning != validated {
                minFreeSpaceWarning = validated
            }
            defaults.set(minFreeSpaceWarning, forKey: ConfigKey.minFreeSpaceWarning)
        }
    }

    /// ゴミ箱の保持日数（デフォルト: 30日）
    /// 範囲: 1〜90
    @Published public var trashRetentionDays: Int {
        didSet {
            let validated = Self.validateTrashRetentionDays(trashRetentionDays)
            if trashRetentionDays != validated {
                trashRetentionDays = validated
            }
            defaults.set(trashRetentionDays, forKey: ConfigKey.trashRetentionDays)
        }
    }

    // MARK: - UI Settings

    /// グリッドの列数（デフォルト: 3）
    /// 範囲: 2〜5
    @Published public var gridColumns: Int {
        didSet {
            let validated = Self.validateGridColumns(gridColumns)
            if gridColumns != validated {
                gridColumns = validated
            }
            defaults.set(gridColumns, forKey: ConfigKey.gridColumns)
        }
    }

    /// アニメーション時間（秒、デフォルト: 0.3）
    /// 範囲: 0.1〜1.0
    @Published public var animationDuration: Double {
        didSet {
            let validated = Self.validateAnimationDuration(animationDuration)
            if animationDuration != validated {
                animationDuration = validated
            }
            defaults.set(animationDuration, forKey: ConfigKey.animationDuration)
        }
    }

    // MARK: - Premium Features

    /// プレミアムユーザーかどうか
    @Published public var isPremiumUser: Bool {
        didSet {
            defaults.set(isPremiumUser, forKey: ConfigKey.isPremiumUser)
        }
    }

    /// 無料ユーザーの1日あたり最大削除枚数（デフォルト: 50）
    public let maxFreePhotosPerDay: Int = 50

    // MARK: - Scan Settings

    /// スクリーンショット検出の有効化
    @Published public var enableScreenshotDetection: Bool {
        didSet {
            defaults.set(enableScreenshotDetection, forKey: ConfigKey.enableScreenshotDetection)
        }
    }

    /// 類似写真検出の有効化
    @Published public var enableSimilarPhotoDetection: Bool {
        didSet {
            defaults.set(enableSimilarPhotoDetection, forKey: ConfigKey.enableSimilarPhotoDetection)
        }
    }

    /// ブレ写真検出の有効化
    @Published public var enableBlurryPhotoDetection: Bool {
        didSet {
            defaults.set(enableBlurryPhotoDetection, forKey: ConfigKey.enableBlurryPhotoDetection)
        }
    }

    // MARK: - Notification Settings

    /// 通知の有効化
    @Published public var enableNotifications: Bool {
        didSet {
            defaults.set(enableNotifications, forKey: ConfigKey.enableNotifications)
        }
    }

    /// 空き容量警告通知の有効化
    @Published public var enableStorageWarningNotification: Bool {
        didSet {
            defaults.set(enableStorageWarningNotification, forKey: ConfigKey.enableStorageWarningNotification)
        }
    }

    // MARK: - App State

    /// 初回起動かどうか
    @Published public var isFirstLaunch: Bool {
        didSet {
            defaults.set(isFirstLaunch, forKey: ConfigKey.isFirstLaunch)
        }
    }

    /// 最終スキャン日時
    @Published public var lastScanDate: Date? {
        didSet {
            defaults.set(lastScanDate, forKey: ConfigKey.lastScanDate)
        }
    }

    /// オンボーディング完了フラグ
    @Published public var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: ConfigKey.hasCompletedOnboarding)
        }
    }

    // MARK: - Initialization

    private init() {
        self.defaults = ConfigKey.userDefaults

        // 初回起動時のデフォルト値を登録
        Self.registerDefaults(in: defaults)

        // UserDefaultsから値を読み込み
        self.enableAnalytics = defaults.bool(forKey: ConfigKey.enableAnalytics)
        self.enableCrashReporting = defaults.bool(forKey: ConfigKey.enableCrashReporting)
        self.similarityThreshold = defaults.double(forKey: ConfigKey.similarityThreshold)
        self.maxConcurrentAnalysis = defaults.integer(forKey: ConfigKey.maxConcurrentAnalysis)
        self.thumbnailCacheSize = defaults.integer(forKey: ConfigKey.thumbnailCacheSize)
        self.blurDetectionSensitivity = defaults.double(forKey: ConfigKey.blurDetectionSensitivity)
        self.minFreeSpaceWarning = Int64(defaults.integer(forKey: ConfigKey.minFreeSpaceWarning))
        self.trashRetentionDays = defaults.integer(forKey: ConfigKey.trashRetentionDays)
        self.gridColumns = defaults.integer(forKey: ConfigKey.gridColumns)
        self.animationDuration = defaults.double(forKey: ConfigKey.animationDuration)
        self.isPremiumUser = defaults.bool(forKey: ConfigKey.isPremiumUser)
        self.enableScreenshotDetection = defaults.bool(forKey: ConfigKey.enableScreenshotDetection)
        self.enableSimilarPhotoDetection = defaults.bool(forKey: ConfigKey.enableSimilarPhotoDetection)
        self.enableBlurryPhotoDetection = defaults.bool(forKey: ConfigKey.enableBlurryPhotoDetection)
        self.enableNotifications = defaults.bool(forKey: ConfigKey.enableNotifications)
        self.enableStorageWarningNotification = defaults.bool(forKey: ConfigKey.enableStorageWarningNotification)
        self.isFirstLaunch = defaults.object(forKey: ConfigKey.isFirstLaunch) == nil
        self.lastScanDate = defaults.object(forKey: ConfigKey.lastScanDate) as? Date
        self.hasCompletedOnboarding = defaults.bool(forKey: ConfigKey.hasCompletedOnboarding)

        // 初回起動フラグを更新
        if isFirstLaunch {
            defaults.set(false, forKey: ConfigKey.isFirstLaunch)
        }
    }

    // MARK: - Default Values Registration

    /// デフォルト値を登録
    private static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: [
            ConfigKey.enableAnalytics: true,
            ConfigKey.enableCrashReporting: true,
            ConfigKey.similarityThreshold: 0.85,
            ConfigKey.maxConcurrentAnalysis: 4,
            ConfigKey.thumbnailCacheSize: 100,
            ConfigKey.blurDetectionSensitivity: 0.5,
            ConfigKey.minFreeSpaceWarning: 500_000_000,  // 500MB
            ConfigKey.trashRetentionDays: 30,
            ConfigKey.gridColumns: 3,
            ConfigKey.animationDuration: 0.3,
            ConfigKey.isPremiumUser: false,
            ConfigKey.enableScreenshotDetection: true,
            ConfigKey.enableSimilarPhotoDetection: true,
            ConfigKey.enableBlurryPhotoDetection: true,
            ConfigKey.enableNotifications: true,
            ConfigKey.enableStorageWarningNotification: true,
            ConfigKey.hasCompletedOnboarding: false
        ])
    }

    // MARK: - Validation Methods

    /// 類似度閾値のバリデーション
    private static func validateSimilarityThreshold(_ value: Double) -> Double {
        min(max(value, 0.5), 1.0)
    }

    /// 同時分析数のバリデーション
    private static func validateMaxConcurrentAnalysis(_ value: Int) -> Int {
        min(max(value, 1), 8)
    }

    /// サムネイルキャッシュサイズのバリデーション
    private static func validateThumbnailCacheSize(_ value: Int) -> Int {
        min(max(value, 50), 500)
    }

    /// ブレ検出感度のバリデーション
    private static func validateBlurDetectionSensitivity(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }

    /// 空き容量警告閾値のバリデーション
    private static func validateMinFreeSpaceWarning(_ value: Int64) -> Int64 {
        min(max(value, 100_000_000), 5_000_000_000)  // 100MB〜5GB
    }

    /// ゴミ箱保持日数のバリデーション
    private static func validateTrashRetentionDays(_ value: Int) -> Int {
        min(max(value, 1), 90)
    }

    /// グリッド列数のバリデーション
    private static func validateGridColumns(_ value: Int) -> Int {
        min(max(value, 2), 5)
    }

    /// アニメーション時間のバリデーション
    private static func validateAnimationDuration(_ value: Double) -> Double {
        min(max(value, 0.1), 1.0)
    }

    // MARK: - Public Methods

    /// すべての設定をデフォルト値にリセット
    public func resetToDefaults() {
        enableAnalytics = true
        enableCrashReporting = true
        similarityThreshold = 0.85
        maxConcurrentAnalysis = 4
        thumbnailCacheSize = 100
        blurDetectionSensitivity = 0.5
        minFreeSpaceWarning = 500_000_000
        trashRetentionDays = 30
        gridColumns = 3
        animationDuration = 0.3
        isPremiumUser = false
        enableScreenshotDetection = true
        enableSimilarPhotoDetection = true
        enableBlurryPhotoDetection = true
        enableNotifications = true
        enableStorageWarningNotification = true
        hasCompletedOnboarding = false
    }

    /// 無料ユーザーの残り削除可能枚数を取得
    public func remainingFreeDeletes() -> Int {
        guard !isPremiumUser else { return Int.max }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDelete = defaults.object(forKey: ConfigKey.lastDeleteDate) as? Date
        let lastDeleteDay = lastDelete.map { Calendar.current.startOfDay(for: $0) }

        // 日付が変わっていたらカウントをリセット
        if lastDeleteDay != today {
            defaults.set(0, forKey: ConfigKey.todayDeletedCount)
            defaults.set(today, forKey: ConfigKey.lastDeleteDate)
            return maxFreePhotosPerDay
        }

        let todayCount = defaults.integer(forKey: ConfigKey.todayDeletedCount)
        return max(0, maxFreePhotosPerDay - todayCount)
    }

    /// 削除カウントを更新
    public func incrementDeleteCount(by count: Int) {
        guard !isPremiumUser else { return }

        let today = Calendar.current.startOfDay(for: Date())
        defaults.set(today, forKey: ConfigKey.lastDeleteDate)

        let currentCount = defaults.integer(forKey: ConfigKey.todayDeletedCount)
        defaults.set(currentCount + count, forKey: ConfigKey.todayDeletedCount)
    }
}

// MARK: - AppConfig + Description

extension AppConfig {
    /// 設定情報の文字列表現を取得
    public var configDescription: String {
        """
        AppConfig:
          Version: \(fullVersionString)
          Debug Mode: \(isDebugMode)
          Premium: \(isPremiumUser)
          Similarity Threshold: \(similarityThreshold)
          Max Concurrent Analysis: \(maxConcurrentAnalysis)
          Grid Columns: \(gridColumns)
        """
    }
}
