//
//  SettingsRepositoryTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsRepositoryの包括的なテスト
//  Created by AI Assistant on 2025-12-04.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - SettingsRepository Tests

/// SettingsRepositoryのテストスイート
@Suite("SettingsRepository Tests")
@MainActor
struct SettingsRepositoryTests {

    // MARK: - Helper Methods

    /// テスト用のUserDefaultsインスタンスを生成
    /// 各テストで独立したUserDefaultsを使用することで、テストの独立性を保証
    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!

        // テスト開始前に確実にクリーンな状態にする
        userDefaults.removePersistentDomain(forName: suiteName)

        return userDefaults
    }

    /// テスト用のカスタム設定を生成
    private func makeCustomSettings() -> UserSettings {
        return UserSettings(
            scanSettings: ScanSettings(
                autoScanEnabled: true,
                autoScanInterval: .daily,
                includeVideos: false,
                includeScreenshots: false,
                includeSelfies: false
            ),
            analysisSettings: AnalysisSettings(
                similarityThreshold: 0.95,
                blurThreshold: 0.5,
                minGroupSize: 5
            ),
            notificationSettings: NotificationSettings(
                enabled: true,
                capacityWarning: false,
                reminderEnabled: true,
                quietHoursStart: 20,
                quietHoursEnd: 6
            ),
            displaySettings: DisplaySettings(
                gridColumns: 6,
                showFileSize: false,
                showDate: false,
                sortOrder: .sizeAscending
            ),
            premiumStatus: .premium
        )
    }

    // MARK: - 正常系テスト

    /// M8-T02-TC01: 初回起動時のデフォルト値
    /// 期待結果: データが存在しない場合、デフォルト設定が返される
    @Test("初回起動時にデフォルト設定を返す")
    func testLoadReturnsDefaultOnFirstLaunch() {
        // Given: 新規のUserDefaultsインスタンス（データなし）
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When: 設定を読み込む
        let settings = repository.load()

        // Then: デフォルト設定が返される
        #expect(settings == .default)
        #expect(settings.scanSettings.autoScanEnabled == false)
        #expect(settings.scanSettings.autoScanInterval == .weekly)
        #expect(settings.analysisSettings.similarityThreshold == 0.85)
        #expect(settings.displaySettings.gridColumns == 4)
        #expect(settings.premiumStatus == .free)
    }

    /// M8-T02-TC02: 設定の保存と読み込み
    /// 期待結果: 保存した設定が正しく復元される
    @Test("設定を保存して正しく復元できる")
    func testSaveAndLoad() {
        // Given: リポジトリとカスタム設定
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let customSettings = makeCustomSettings()

        // When: 設定を保存して読み込む
        repository.save(customSettings)
        let loadedSettings = repository.load()

        // Then: 保存した設定が復元される
        #expect(loadedSettings == customSettings)

        // すべてのフィールドを個別に検証
        #expect(loadedSettings.scanSettings.autoScanEnabled == true)
        #expect(loadedSettings.scanSettings.autoScanInterval == .daily)
        #expect(loadedSettings.scanSettings.includeVideos == false)
        #expect(loadedSettings.scanSettings.includeScreenshots == false)
        #expect(loadedSettings.scanSettings.includeSelfies == false)

        #expect(loadedSettings.analysisSettings.similarityThreshold == 0.95)
        #expect(loadedSettings.analysisSettings.blurThreshold == 0.5)
        #expect(loadedSettings.analysisSettings.minGroupSize == 5)

        #expect(loadedSettings.notificationSettings.enabled == true)
        #expect(loadedSettings.notificationSettings.capacityWarning == false)
        #expect(loadedSettings.notificationSettings.reminderEnabled == true)
        #expect(loadedSettings.notificationSettings.quietHoursStart == 20)
        #expect(loadedSettings.notificationSettings.quietHoursEnd == 6)

        #expect(loadedSettings.displaySettings.gridColumns == 6)
        #expect(loadedSettings.displaySettings.showFileSize == false)
        #expect(loadedSettings.displaySettings.showDate == false)
        #expect(loadedSettings.displaySettings.sortOrder == .sizeAscending)

        #expect(loadedSettings.premiumStatus == .premium)
    }

    /// M8-T02-TC03: リセット機能
    /// 期待結果: リセット後、次回読み込みでデフォルト値が返される
    @Test("リセット後にデフォルト設定に戻る")
    func testResetSettings() {
        // Given: カスタム設定を保存したリポジトリ
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let customSettings = makeCustomSettings()
        repository.save(customSettings)

        // When: 設定をリセット
        repository.reset()

        // Then: 次回読み込みでデフォルト設定が返される
        let loadedSettings = repository.load()
        #expect(loadedSettings == .default)
    }

    // MARK: - 異常系テスト

    /// デコード失敗時のフォールバック
    /// 期待結果: 壊れたJSONデータが保存されている場合、デフォルト値を返す
    @Test("デコード失敗時にデフォルト設定を返す")
    func testLoadReturnsDefaultOnDecodeFailure() {
        // Given: 不正なJSONデータを保存
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let corruptedData = "{ invalid json }".data(using: .utf8)!
        userDefaults.set(corruptedData, forKey: "user_settings")

        // When: 設定を読み込む
        let settings = repository.load()

        // Then: デコード失敗してもクラッシュせず、デフォルト設定が返される
        #expect(settings == .default)
    }

    /// 空データの処理
    /// 期待結果: 空のDataオブジェクトが保存されている場合、デフォルト値を返す
    @Test("空データの場合にデフォルト設定を返す")
    func testLoadReturnsDefaultOnEmptyData() {
        // Given: 空のDataを保存
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        userDefaults.set(Data(), forKey: "user_settings")

        // When: 設定を読み込む
        let settings = repository.load()

        // Then: デフォルト設定が返される
        #expect(settings == .default)
    }

    // MARK: - 境界値テスト

    /// 複数回の保存・読み込み
    /// 期待結果: 設定を変更→保存→読み込みを複数回繰り返しても正しく動作
    @Test("複数回の保存と読み込みが正しく動作する")
    func testMultipleSaveAndLoad() {
        // Given: リポジトリ
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When/Then: 複数回の保存と読み込みを実行
        for iteration in 1...5 {
            let settings = UserSettings(
                scanSettings: ScanSettings(
                    autoScanEnabled: iteration % 2 == 0,
                    autoScanInterval: .daily,
                    includeVideos: true,
                    includeScreenshots: true,
                    includeSelfies: true
                ),
                analysisSettings: AnalysisSettings(
                    similarityThreshold: 0.8 + Float(iteration) * 0.01,
                    blurThreshold: 0.3,
                    minGroupSize: 2 + iteration
                ),
                notificationSettings: .default,
                displaySettings: DisplaySettings(
                    gridColumns: iteration,
                    showFileSize: true,
                    showDate: true,
                    sortOrder: .dateDescending
                ),
                premiumStatus: iteration > 3 ? .premium : .free
            )

            repository.save(settings)
            let loaded = repository.load()

            #expect(loaded == settings)
            #expect(loaded.scanSettings.autoScanEnabled == (iteration % 2 == 0))
            #expect(loaded.analysisSettings.minGroupSize == 2 + iteration)
            #expect(loaded.displaySettings.gridColumns == iteration)
        }
    }

    /// UserSettings全フィールドの保存確認
    /// 期待結果: すべての設定項目が正しく保存・復元される
    @Test("全フィールドが正しく保存される")
    func testAllFieldsArePersisted() {
        // Given: すべてのフィールドを設定したUserSettings
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        let settings = UserSettings(
            scanSettings: ScanSettings(
                autoScanEnabled: true,
                autoScanInterval: .monthly,
                includeVideos: true,
                includeScreenshots: false,
                includeSelfies: true
            ),
            analysisSettings: AnalysisSettings(
                similarityThreshold: 0.75,
                blurThreshold: 0.25,
                minGroupSize: 10
            ),
            notificationSettings: NotificationSettings(
                enabled: true,
                capacityWarning: true,
                reminderEnabled: true,
                quietHoursStart: 23,
                quietHoursEnd: 7
            ),
            displaySettings: DisplaySettings(
                gridColumns: 5,
                showFileSize: true,
                showDate: false,
                sortOrder: .dateAscending
            ),
            premiumStatus: .premium
        )

        // When: 保存して読み込み
        repository.save(settings)
        let loaded = repository.load()

        // Then: すべてのフィールドが一致
        #expect(loaded.scanSettings == settings.scanSettings)
        #expect(loaded.analysisSettings == settings.analysisSettings)
        #expect(loaded.notificationSettings == settings.notificationSettings)
        #expect(loaded.displaySettings == settings.displaySettings)
        #expect(loaded.premiumStatus == settings.premiumStatus)
    }

    /// 最小値・最大値の境界値テスト
    /// 期待結果: 境界値が正しく保存・復元される
    @Test("境界値が正しく処理される")
    func testBoundaryValues() {
        // Given: 境界値を持つ設定
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        let settings = UserSettings(
            scanSettings: .default,
            analysisSettings: AnalysisSettings(
                similarityThreshold: 1.0, // 最大値
                blurThreshold: 0.0,       // 最小値
                minGroupSize: 2           // 最小値
            ),
            notificationSettings: NotificationSettings(
                enabled: true,
                capacityWarning: true,
                reminderEnabled: true,
                quietHoursStart: 0,  // 最小値
                quietHoursEnd: 23    // 最大値
            ),
            displaySettings: DisplaySettings(
                gridColumns: 1,     // 最小値
                showFileSize: true,
                showDate: true,
                sortOrder: .dateDescending
            ),
            premiumStatus: .free
        )

        // When: 保存して読み込み
        repository.save(settings)
        let loaded = repository.load()

        // Then: 境界値が正しく保存される
        #expect(loaded.analysisSettings.similarityThreshold == 1.0)
        #expect(loaded.analysisSettings.blurThreshold == 0.0)
        #expect(loaded.analysisSettings.minGroupSize == 2)
        #expect(loaded.notificationSettings.quietHoursStart == 0)
        #expect(loaded.notificationSettings.quietHoursEnd == 23)
        #expect(loaded.displaySettings.gridColumns == 1)
    }

    // MARK: - テストの独立性

    /// テストの独立性確認
    /// 期待結果: 各テストが独立したUserDefaultsを使用し、互いに影響しない
    @Test("各テストが独立している")
    func testTestsAreIndependent() {
        // Given: 2つの独立したリポジトリ
        let userDefaults1 = makeTestUserDefaults()
        let repository1 = SettingsRepository(userDefaults: userDefaults1)

        let userDefaults2 = makeTestUserDefaults()
        let repository2 = SettingsRepository(userDefaults: userDefaults2)

        let settings1 = makeCustomSettings()
        var settings2 = UserSettings.default
        settings2.premiumStatus = .premium

        // When: 異なる設定を保存
        repository1.save(settings1)
        repository2.save(settings2)

        // Then: それぞれが独立した設定を保持
        let loaded1 = repository1.load()
        let loaded2 = repository2.load()

        #expect(loaded1 == settings1)
        #expect(loaded2 == settings2)
        #expect(loaded1 != loaded2)
    }

    // MARK: - 追加テスト

    /// リセット後の再保存
    /// 期待結果: リセット後に新しい設定を保存できる
    @Test("リセット後に新しい設定を保存できる")
    func testSaveAfterReset() {
        // Given: リポジトリ
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When: 保存→リセット→再保存
        let settings1 = makeCustomSettings()
        repository.save(settings1)
        repository.reset()

        var settings2 = UserSettings.default
        settings2.premiumStatus = .premium
        repository.save(settings2)

        // Then: 最後に保存した設定が読み込まれる
        let loaded = repository.load()
        #expect(loaded == settings2)
        #expect(loaded != settings1)
    }

    /// デフォルト設定の保存と読み込み
    /// 期待結果: デフォルト設定を明示的に保存した場合も正しく動作
    @Test("デフォルト設定を明示的に保存できる")
    func testSaveDefaultSettings() {
        // Given: リポジトリ
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When: デフォルト設定を明示的に保存
        repository.save(.default)

        // Then: 正しく復元される
        let loaded = repository.load()
        #expect(loaded == .default)
    }
}
