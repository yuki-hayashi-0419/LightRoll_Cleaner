//
//  ConfigTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AppConfigとConfigKeyの単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - ConfigKey Tests

@Suite("ConfigKey Tests")
struct ConfigKeyTests {

    // MARK: - Feature Flags Keys

    @Test("ConfigKeyのFeature Flagsキーが正しい値を持つ")
    func testFeatureFlagsKeys() {
        #expect(ConfigKey.enableAnalytics == "enableAnalytics")
        #expect(ConfigKey.enableCrashReporting == "enableCrashReporting")
    }

    // MARK: - Photo Analysis Settings Keys

    @Test("ConfigKeyのPhoto Analysis Settingsキーが正しい値を持つ")
    func testPhotoAnalysisSettingsKeys() {
        #expect(ConfigKey.similarityThreshold == "similarityThreshold")
        #expect(ConfigKey.maxConcurrentAnalysis == "maxConcurrentAnalysis")
        #expect(ConfigKey.thumbnailCacheSize == "thumbnailCacheSize")
        #expect(ConfigKey.blurDetectionSensitivity == "blurDetectionSensitivity")
    }

    // MARK: - Storage Settings Keys

    @Test("ConfigKeyのStorage Settingsキーが正しい値を持つ")
    func testStorageSettingsKeys() {
        #expect(ConfigKey.minFreeSpaceWarning == "minFreeSpaceWarning")
        #expect(ConfigKey.trashRetentionDays == "trashRetentionDays")
    }

    // MARK: - UI Settings Keys

    @Test("ConfigKeyのUI Settingsキーが正しい値を持つ")
    func testUISettingsKeys() {
        #expect(ConfigKey.gridColumns == "gridColumns")
        #expect(ConfigKey.animationDuration == "animationDuration")
        #expect(ConfigKey.appearanceMode == "appearanceMode")
    }

    // MARK: - Premium Features Keys

    @Test("ConfigKeyのPremium Featuresキーが正しい値を持つ")
    func testPremiumFeaturesKeys() {
        #expect(ConfigKey.isPremiumUser == "isPremiumUser")
        #expect(ConfigKey.maxFreePhotosPerDay == "maxFreePhotosPerDay")
        #expect(ConfigKey.todayDeletedCount == "todayDeletedCount")
        #expect(ConfigKey.lastDeleteDate == "lastDeleteDate")
    }

    // MARK: - Notification Settings Keys

    @Test("ConfigKeyのNotification Settingsキーが正しい値を持つ")
    func testNotificationSettingsKeys() {
        #expect(ConfigKey.enableNotifications == "enableNotifications")
        #expect(ConfigKey.enableStorageWarningNotification == "enableStorageWarningNotification")
        #expect(ConfigKey.enablePeriodicReminder == "enablePeriodicReminder")
        #expect(ConfigKey.reminderIntervalDays == "reminderIntervalDays")
    }

    // MARK: - Scan Settings Keys

    @Test("ConfigKeyのScan Settingsキーが正しい値を持つ")
    func testScanSettingsKeys() {
        #expect(ConfigKey.enableAutoScan == "enableAutoScan")
        #expect(ConfigKey.enableScreenshotDetection == "enableScreenshotDetection")
        #expect(ConfigKey.enableSimilarPhotoDetection == "enableSimilarPhotoDetection")
        #expect(ConfigKey.enableBlurryPhotoDetection == "enableBlurryPhotoDetection")
    }

    // MARK: - App State Keys

    @Test("ConfigKeyのApp Stateキーが正しい値を持つ")
    func testAppStateKeys() {
        #expect(ConfigKey.isFirstLaunch == "isFirstLaunch")
        #expect(ConfigKey.lastScanDate == "lastScanDate")
        #expect(ConfigKey.hasCompletedOnboarding == "hasCompletedOnboarding")
    }

    // MARK: - UserDefaults Extension

    @Test("ConfigKey.suiteNameがnil（標準UserDefaults）")
    func testSuiteNameIsNil() {
        #expect(ConfigKey.suiteName == nil)
    }

    @Test("ConfigKey.userDefaultsが標準UserDefaultsを返す")
    func testUserDefaultsReturnsStandard() {
        // suiteNameがnilの場合、.standardが返される
        let defaults = ConfigKey.userDefaults
        #expect(defaults === UserDefaults.standard)
    }

    // MARK: - Key Uniqueness

    @Test("ConfigKeyの全キーがユニーク")
    func testAllKeysAreUnique() {
        let allKeys = [
            ConfigKey.enableAnalytics,
            ConfigKey.enableCrashReporting,
            ConfigKey.similarityThreshold,
            ConfigKey.maxConcurrentAnalysis,
            ConfigKey.thumbnailCacheSize,
            ConfigKey.blurDetectionSensitivity,
            ConfigKey.minFreeSpaceWarning,
            ConfigKey.trashRetentionDays,
            ConfigKey.gridColumns,
            ConfigKey.animationDuration,
            ConfigKey.appearanceMode,
            ConfigKey.isPremiumUser,
            ConfigKey.maxFreePhotosPerDay,
            ConfigKey.todayDeletedCount,
            ConfigKey.lastDeleteDate,
            ConfigKey.enableNotifications,
            ConfigKey.enableStorageWarningNotification,
            ConfigKey.enablePeriodicReminder,
            ConfigKey.reminderIntervalDays,
            ConfigKey.enableAutoScan,
            ConfigKey.enableScreenshotDetection,
            ConfigKey.enableSimilarPhotoDetection,
            ConfigKey.enableBlurryPhotoDetection,
            ConfigKey.isFirstLaunch,
            ConfigKey.lastScanDate,
            ConfigKey.hasCompletedOnboarding
        ]

        let uniqueKeys = Set(allKeys)
        #expect(uniqueKeys.count == allKeys.count, "重複したConfigKeyが存在します")
    }
}

// MARK: - AppConfig Tests

@Suite("AppConfig Tests")
@MainActor
struct AppConfigTests {

    // MARK: - Singleton

    @Test("AppConfig.sharedがシングルトンとして動作する")
    func testSharedInstance() {
        let config1 = AppConfig.shared
        let config2 = AppConfig.shared
        // シングルトンなので同一インスタンス
        #expect(config1 === config2)
    }

    // MARK: - App Info Properties

    @Test("appVersionが文字列を返す")
    func testAppVersion() {
        let config = AppConfig.shared
        #expect(!config.appVersion.isEmpty)
    }

    @Test("buildNumberが文字列を返す")
    func testBuildNumber() {
        let config = AppConfig.shared
        #expect(!config.buildNumber.isEmpty)
    }

    @Test("bundleIdentifierが文字列を返す")
    func testBundleIdentifier() {
        let config = AppConfig.shared
        #expect(!config.bundleIdentifier.isEmpty)
    }

    @Test("fullVersionStringがバージョンとビルド番号を含む")
    func testFullVersionString() {
        let config = AppConfig.shared
        let fullVersion = config.fullVersionString
        #expect(fullVersion.contains(config.appVersion))
        #expect(fullVersion.contains(config.buildNumber))
        #expect(fullVersion.contains("("))
        #expect(fullVersion.contains(")"))
    }

    // MARK: - Feature Flags

    @Test("isDebugModeがブール値を返す")
    func testIsDebugMode() {
        let config = AppConfig.shared
        // テスト環境ではDEBUGビルドのはず
        #if DEBUG
        #expect(config.isDebugMode == true)
        #else
        #expect(config.isDebugMode == false)
        #endif
    }

    // MARK: - Premium Features

    @Test("maxFreePhotosPerDayがデフォルト値50を持つ")
    func testMaxFreePhotosPerDay() {
        let config = AppConfig.shared
        #expect(config.maxFreePhotosPerDay == 50)
    }

    // MARK: - configDescription

    @Test("configDescriptionが設定情報を含む文字列を返す")
    func testConfigDescription() {
        let config = AppConfig.shared
        let description = config.configDescription

        #expect(description.contains("AppConfig:"))
        #expect(description.contains("Version:"))
        #expect(description.contains("Debug Mode:"))
        #expect(description.contains("Premium:"))
        #expect(description.contains("Similarity Threshold:"))
        #expect(description.contains("Max Concurrent Analysis:"))
        #expect(description.contains("Grid Columns:"))
    }
}

// MARK: - AppConfig Validation Tests

@Suite("AppConfig Validation Tests")
@MainActor
struct AppConfigValidationTests {

    // MARK: - Similarity Threshold Validation

    @Test("similarityThresholdの下限バリデーション（0.5未満は0.5にクランプ）")
    func testSimilarityThresholdLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.similarityThreshold

        config.similarityThreshold = 0.3
        #expect(config.similarityThreshold == 0.5)

        config.similarityThreshold = 0.0
        #expect(config.similarityThreshold == 0.5)

        config.similarityThreshold = -1.0
        #expect(config.similarityThreshold == 0.5)

        // 元の値に復元
        config.similarityThreshold = originalValue
    }

    @Test("similarityThresholdの上限バリデーション（1.0超は1.0にクランプ）")
    func testSimilarityThresholdUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.similarityThreshold

        config.similarityThreshold = 1.5
        #expect(config.similarityThreshold == 1.0)

        config.similarityThreshold = 10.0
        #expect(config.similarityThreshold == 1.0)

        // 元の値に復元
        config.similarityThreshold = originalValue
    }

    @Test("similarityThresholdの有効範囲内の値は保持される")
    func testSimilarityThresholdValidRange() {
        let config = AppConfig.shared
        let originalValue = config.similarityThreshold

        config.similarityThreshold = 0.5
        #expect(config.similarityThreshold == 0.5)

        config.similarityThreshold = 0.75
        #expect(config.similarityThreshold == 0.75)

        config.similarityThreshold = 1.0
        #expect(config.similarityThreshold == 1.0)

        // 元の値に復元
        config.similarityThreshold = originalValue
    }

    // MARK: - Max Concurrent Analysis Validation

    @Test("maxConcurrentAnalysisの下限バリデーション（1未満は1にクランプ）")
    func testMaxConcurrentAnalysisLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.maxConcurrentAnalysis

        config.maxConcurrentAnalysis = 0
        #expect(config.maxConcurrentAnalysis == 1)

        config.maxConcurrentAnalysis = -5
        #expect(config.maxConcurrentAnalysis == 1)

        // 元の値に復元
        config.maxConcurrentAnalysis = originalValue
    }

    @Test("maxConcurrentAnalysisの上限バリデーション（8超は8にクランプ）")
    func testMaxConcurrentAnalysisUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.maxConcurrentAnalysis

        config.maxConcurrentAnalysis = 10
        #expect(config.maxConcurrentAnalysis == 8)

        config.maxConcurrentAnalysis = 100
        #expect(config.maxConcurrentAnalysis == 8)

        // 元の値に復元
        config.maxConcurrentAnalysis = originalValue
    }

    @Test("maxConcurrentAnalysisの有効範囲内の値は保持される")
    func testMaxConcurrentAnalysisValidRange() {
        let config = AppConfig.shared
        let originalValue = config.maxConcurrentAnalysis

        config.maxConcurrentAnalysis = 1
        #expect(config.maxConcurrentAnalysis == 1)

        config.maxConcurrentAnalysis = 4
        #expect(config.maxConcurrentAnalysis == 4)

        config.maxConcurrentAnalysis = 8
        #expect(config.maxConcurrentAnalysis == 8)

        // 元の値に復元
        config.maxConcurrentAnalysis = originalValue
    }

    // MARK: - Thumbnail Cache Size Validation

    @Test("thumbnailCacheSizeの下限バリデーション（50未満は50にクランプ）")
    func testThumbnailCacheSizeLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.thumbnailCacheSize

        config.thumbnailCacheSize = 30
        #expect(config.thumbnailCacheSize == 50)

        config.thumbnailCacheSize = 0
        #expect(config.thumbnailCacheSize == 50)

        // 元の値に復元
        config.thumbnailCacheSize = originalValue
    }

    @Test("thumbnailCacheSizeの上限バリデーション（500超は500にクランプ）")
    func testThumbnailCacheSizeUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.thumbnailCacheSize

        config.thumbnailCacheSize = 600
        #expect(config.thumbnailCacheSize == 500)

        config.thumbnailCacheSize = 1000
        #expect(config.thumbnailCacheSize == 500)

        // 元の値に復元
        config.thumbnailCacheSize = originalValue
    }

    // MARK: - Blur Detection Sensitivity Validation

    @Test("blurDetectionSensitivityの下限バリデーション（0.0未満は0.0にクランプ）")
    func testBlurDetectionSensitivityLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.blurDetectionSensitivity

        config.blurDetectionSensitivity = -0.5
        #expect(config.blurDetectionSensitivity == 0.0)

        // 元の値に復元
        config.blurDetectionSensitivity = originalValue
    }

    @Test("blurDetectionSensitivityの上限バリデーション（1.0超は1.0にクランプ）")
    func testBlurDetectionSensitivityUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.blurDetectionSensitivity

        config.blurDetectionSensitivity = 1.5
        #expect(config.blurDetectionSensitivity == 1.0)

        // 元の値に復元
        config.blurDetectionSensitivity = originalValue
    }

    // MARK: - Min Free Space Warning Validation

    @Test("minFreeSpaceWarningの下限バリデーション（100MB未満は100MBにクランプ）")
    func testMinFreeSpaceWarningLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.minFreeSpaceWarning

        config.minFreeSpaceWarning = 50_000_000  // 50MB
        #expect(config.minFreeSpaceWarning == 100_000_000)  // 100MB

        // 元の値に復元
        config.minFreeSpaceWarning = originalValue
    }

    @Test("minFreeSpaceWarningの上限バリデーション（5GB超は5GBにクランプ）")
    func testMinFreeSpaceWarningUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.minFreeSpaceWarning

        config.minFreeSpaceWarning = 10_000_000_000  // 10GB
        #expect(config.minFreeSpaceWarning == 5_000_000_000)  // 5GB

        // 元の値に復元
        config.minFreeSpaceWarning = originalValue
    }

    // MARK: - Trash Retention Days Validation

    @Test("trashRetentionDaysの下限バリデーション（1未満は1にクランプ）")
    func testTrashRetentionDaysLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.trashRetentionDays

        config.trashRetentionDays = 0
        #expect(config.trashRetentionDays == 1)

        config.trashRetentionDays = -10
        #expect(config.trashRetentionDays == 1)

        // 元の値に復元
        config.trashRetentionDays = originalValue
    }

    @Test("trashRetentionDaysの上限バリデーション（90超は90にクランプ）")
    func testTrashRetentionDaysUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.trashRetentionDays

        config.trashRetentionDays = 100
        #expect(config.trashRetentionDays == 90)

        config.trashRetentionDays = 365
        #expect(config.trashRetentionDays == 90)

        // 元の値に復元
        config.trashRetentionDays = originalValue
    }

    // MARK: - Grid Columns Validation

    @Test("gridColumnsの下限バリデーション（2未満は2にクランプ）")
    func testGridColumnsLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.gridColumns

        config.gridColumns = 1
        #expect(config.gridColumns == 2)

        config.gridColumns = 0
        #expect(config.gridColumns == 2)

        // 元の値に復元
        config.gridColumns = originalValue
    }

    @Test("gridColumnsの上限バリデーション（5超は5にクランプ）")
    func testGridColumnsUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.gridColumns

        config.gridColumns = 6
        #expect(config.gridColumns == 5)

        config.gridColumns = 10
        #expect(config.gridColumns == 5)

        // 元の値に復元
        config.gridColumns = originalValue
    }

    // MARK: - Animation Duration Validation

    @Test("animationDurationの下限バリデーション（0.1未満は0.1にクランプ）")
    func testAnimationDurationLowerBound() {
        let config = AppConfig.shared
        let originalValue = config.animationDuration

        config.animationDuration = 0.05
        #expect(config.animationDuration == 0.1)

        config.animationDuration = 0.0
        #expect(config.animationDuration == 0.1)

        // 元の値に復元
        config.animationDuration = originalValue
    }

    @Test("animationDurationの上限バリデーション（1.0超は1.0にクランプ）")
    func testAnimationDurationUpperBound() {
        let config = AppConfig.shared
        let originalValue = config.animationDuration

        config.animationDuration = 1.5
        #expect(config.animationDuration == 1.0)

        config.animationDuration = 5.0
        #expect(config.animationDuration == 1.0)

        // 元の値に復元
        config.animationDuration = originalValue
    }
}

// MARK: - AppConfig Reset Tests

@Suite("AppConfig Reset Tests")
@MainActor
struct AppConfigResetTests {

    @Test("resetToDefaultsがすべての設定をデフォルト値にリセットする")
    func testResetToDefaults() {
        let config = AppConfig.shared

        // 設定を変更
        config.enableAnalytics = false
        config.similarityThreshold = 0.9
        config.maxConcurrentAnalysis = 8
        config.thumbnailCacheSize = 200
        config.gridColumns = 5

        // リセット実行
        config.resetToDefaults()

        // デフォルト値に戻っているか確認
        #expect(config.enableAnalytics == true)
        #expect(config.enableCrashReporting == true)
        #expect(config.similarityThreshold == 0.85)
        #expect(config.maxConcurrentAnalysis == 4)
        #expect(config.thumbnailCacheSize == 100)
        #expect(config.blurDetectionSensitivity == 0.5)
        #expect(config.minFreeSpaceWarning == 500_000_000)
        #expect(config.trashRetentionDays == 30)
        #expect(config.gridColumns == 3)
        #expect(config.animationDuration == 0.3)
        #expect(config.isPremiumUser == false)
        #expect(config.enableScreenshotDetection == true)
        #expect(config.enableSimilarPhotoDetection == true)
        #expect(config.enableBlurryPhotoDetection == true)
        #expect(config.enableNotifications == true)
        #expect(config.enableStorageWarningNotification == true)
        #expect(config.hasCompletedOnboarding == false)
    }
}

// MARK: - AppConfig Premium Features Tests

@Suite("AppConfig Premium Features Tests")
@MainActor
struct AppConfigPremiumFeaturesTests {

    @Test("プレミアムユーザーのremainingFreeDeletesはInt.maxを返す")
    func testPremiumUserRemainingDeletes() {
        let config = AppConfig.shared
        let originalValue = config.isPremiumUser

        config.isPremiumUser = true
        #expect(config.remainingFreeDeletes() == Int.max)

        // 元の値に復元
        config.isPremiumUser = originalValue
    }

    @Test("無料ユーザーのremainingFreeDeletesは正の値を返す")
    func testFreeUserRemainingDeletes() {
        let config = AppConfig.shared
        let originalValue = config.isPremiumUser

        config.isPremiumUser = false
        let remaining = config.remainingFreeDeletes()
        #expect(remaining >= 0)
        #expect(remaining <= config.maxFreePhotosPerDay)

        // 元の値に復元
        config.isPremiumUser = originalValue
    }

    @Test("プレミアムユーザーのincrementDeleteCountは何もしない")
    func testPremiumUserIncrementDeleteCount() {
        let config = AppConfig.shared
        let originalValue = config.isPremiumUser

        config.isPremiumUser = true
        let beforeRemaining = config.remainingFreeDeletes()

        config.incrementDeleteCount(by: 10)

        let afterRemaining = config.remainingFreeDeletes()
        #expect(beforeRemaining == afterRemaining)
        #expect(afterRemaining == Int.max)

        // 元の値に復元
        config.isPremiumUser = originalValue
    }
}
