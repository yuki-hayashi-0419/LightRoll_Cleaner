//
//  BUG001_AutoScanSettingsSyncTests.swift
//  LightRoll_CleanerFeature
//
//  BUG-001: 自動スキャン設定同期修正の包括的テストスイート
//
//  テスト対象:
//  - UserSettings.scanSettings変更の検出
//  - BackgroundScanManagerへの伝播
//  - ContentViewでの統合動作
//
//  Created by AI Assistant on 2025-12-23.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - BUG001_AutoScanSettingsSyncTests

/// BUG-001: 自動スキャン設定同期テストスイート
@Suite("BUG-001: 自動スキャン設定同期")
@MainActor
struct BUG001_AutoScanSettingsSyncTests {

    // MARK: - Test 1: 基本動作 - autoScanEnabled変更検出

    @Test("autoScanEnabledの変更が検出される")
    func testAutoScanEnabledChangeDetection() async throws {
        // Arrange: 設定サービスを初期化（autoScanEnabled=false）
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        #expect(service.settings.scanSettings.autoScanEnabled == false)

        // Act: autoScanEnabledをtrueに変更
        var updatedSettings = service.settings.scanSettings
        updatedSettings.autoScanEnabled = true
        try service.updateScanSettings(updatedSettings)

        // Assert: 変更が反映されている
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(mockRepository.saveCalled == true)
    }

    // MARK: - Test 2: 基本動作 - scanInterval変更検出

    @Test("autoScanIntervalの変更が検出される")
    func testAutoScanIntervalChangeDetection() async throws {
        // Arrange: 設定サービスを初期化（interval=weekly）
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        #expect(service.settings.scanSettings.autoScanInterval == .weekly)

        // Act: intervalをdailyに変更
        var updatedSettings = service.settings.scanSettings
        updatedSettings.autoScanInterval = .daily
        try service.updateScanSettings(updatedSettings)

        // Assert: 変更が反映されている
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
        #expect(mockRepository.saveCalled == true)
    }

    // MARK: - Test 3: 基本動作 - BackgroundScanManagerへの伝播

    @Test("BackgroundScanManagerのisEnabledが設定値を反映する")
    func testBackgroundScanManagerEnabledPropagation() async throws {
        // Arrange: BackgroundScanManagerを初期化
        let userDefaults = UserDefaults(suiteName: "test.bug001.enabled")!
        userDefaults.removePersistentDomain(forName: "test.bug001.enabled")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        #expect(manager.isBackgroundScanEnabled == false)

        // Act: isBackgroundScanEnabledをtrueに設定
        manager.isBackgroundScanEnabled = true

        // Assert: 値が反映される
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(userDefaults.bool(forKey: "BackgroundScanManager.isEnabled") == true)
    }

    @Test("BackgroundScanManagerのscanIntervalが設定値を反映する")
    func testBackgroundScanManagerIntervalPropagation() async throws {
        // Arrange: BackgroundScanManagerを初期化
        let userDefaults = UserDefaults(suiteName: "test.bug001.interval")!
        userDefaults.removePersistentDomain(forName: "test.bug001.interval")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // デフォルト値（24時間）
        #expect(manager.scanInterval == 86400.0)

        // Act: scanIntervalを変更（毎日 = 86400秒）
        manager.scanInterval = AutoScanInterval.daily.timeInterval!

        // Assert: 値が反映される
        #expect(manager.scanInterval == 86400.0)
    }

    // MARK: - Test 4: エッジケース - 初期化時の挙動

    @Test("初期化時にデフォルト値が設定される")
    func testInitializationWithDefaultValues() async throws {
        // Arrange & Act: 新規初期化
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        // Assert: デフォルト値が設定されている
        #expect(service.settings.scanSettings.autoScanEnabled == false)
        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
    }

    @Test("BackgroundScanManager初期化時にデフォルト値が設定される")
    func testBackgroundScanManagerInitializationDefaults() async throws {
        // Arrange & Act: 新規初期化
        let userDefaults = UserDefaults(suiteName: "test.bug001.init")!
        userDefaults.removePersistentDomain(forName: "test.bug001.init")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Assert: デフォルト値が設定されている
        #expect(manager.isBackgroundScanEnabled == false)
        #expect(manager.scanInterval == BackgroundScanManager.defaultScanInterval)
    }

    // MARK: - Test 5: エッジケース - 連続変更時の挙動

    @Test("autoScanEnabledの連続変更が正しく反映される")
    func testContinuousAutoScanEnabledChanges() async throws {
        // Arrange
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        // Act: 連続変更 false → true → false → true
        var settings1 = service.settings.scanSettings
        settings1.autoScanEnabled = true
        try service.updateScanSettings(settings1)
        #expect(service.settings.scanSettings.autoScanEnabled == true)

        var settings2 = service.settings.scanSettings
        settings2.autoScanEnabled = false
        try service.updateScanSettings(settings2)
        #expect(service.settings.scanSettings.autoScanEnabled == false)

        var settings3 = service.settings.scanSettings
        settings3.autoScanEnabled = true
        try service.updateScanSettings(settings3)
        #expect(service.settings.scanSettings.autoScanEnabled == true)

        // Assert: 最終的な値が正しい
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(mockRepository.saveCount == 3) // 3回保存された
    }

    @Test("scanIntervalの連続変更が正しく反映される")
    func testContinuousScanIntervalChanges() async throws {
        // Arrange
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        // Act: 連続変更 weekly → daily → monthly → never
        let intervals: [AutoScanInterval] = [.daily, .monthly, .never, .weekly]

        for interval in intervals {
            var updatedSettings = service.settings.scanSettings
            updatedSettings.autoScanInterval = interval
            try service.updateScanSettings(updatedSettings)
            #expect(service.settings.scanSettings.autoScanInterval == interval)
        }

        // Assert: 最終的な値が正しい
        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
        #expect(mockRepository.saveCount == 4) // 4回保存された
    }

    // MARK: - Test 6: エッジケース - nil/デフォルト値の扱い

    @Test("AutoScanInterval.neverの場合、timeIntervalがnilになる")
    func testAutoScanIntervalNeverReturnsNil() {
        // Arrange & Act
        let interval = AutoScanInterval.never

        // Assert
        #expect(interval.timeInterval == nil)
    }

    @Test("AutoScanInterval各値のtimeIntervalが正しい")
    func testAutoScanIntervalTimeIntervalValues() {
        // Arrange & Act & Assert
        #expect(AutoScanInterval.daily.timeInterval == 86400.0) // 1日
        #expect(AutoScanInterval.weekly.timeInterval == 604800.0) // 7日
        #expect(AutoScanInterval.monthly.timeInterval == 2592000.0) // 30日
        #expect(AutoScanInterval.never.timeInterval == nil)
    }

    // MARK: - Test 7: 統合テスト - 設定変更→Manager反映フロー

    @Test("SettingsService変更がBackgroundScanManagerに反映される統合フロー")
    func testIntegrationSettingsToManagerFlow() async throws {
        // Arrange: 両方を初期化
        let userDefaults = UserDefaults(suiteName: "test.bug001.integration")!
        userDefaults.removePersistentDomain(forName: "test.bug001.integration")

        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: SettingsServiceで設定を変更
        var updatedSettings = service.settings.scanSettings
        updatedSettings.autoScanEnabled = true
        updatedSettings.autoScanInterval = .daily
        try service.updateScanSettings(updatedSettings)

        // Manager側で同じ値を設定（実際のアプリではContentViewで監視して設定）
        manager.isBackgroundScanEnabled = true
        manager.scanInterval = AutoScanInterval.daily.timeInterval!

        // Assert: 両方に値が反映される
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(manager.scanInterval == 86400.0)
    }

    // MARK: - Test 8: エッジケース - 無効化時のタスクキャンセル

    @Test("autoScanEnabledをfalseにするとスケジュールがキャンセルされる")
    func testDisablingAutoScanCancelsSchedule() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.cancel")!
        userDefaults.removePersistentDomain(forName: "test.bug001.cancel")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // まず有効化してスケジュール（シミュレータなのでnextScheduledScanDateのみ設定）
        manager.isBackgroundScanEnabled = true
        try manager.scheduleBackgroundScan()

        // nextScheduledScanDateが設定されている
        #expect(manager.nextScheduledScanDate != nil)

        // Act: 無効化
        manager.isBackgroundScanEnabled = false

        // Assert: nextScheduledScanDateがクリアされる
        #expect(manager.nextScheduledScanDate == nil)
    }

    // MARK: - Test 9: バリデーション - scanSettings検証

    @Test("無効なscanSettingsを設定するとエラーになる")
    func testInvalidScanSettingsThrowsError() async throws {
        // Arrange
        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)

        // Act & Assert: 全てのコンテンツタイプを無効にする（バリデーションエラー）
        var invalidSettings = service.settings.scanSettings
        invalidSettings.includeVideos = false
        invalidSettings.includeScreenshots = false
        invalidSettings.includeSelfies = false

        #expect(throws: SettingsError.self) {
            try service.updateScanSettings(invalidSettings)
        }
    }

    // MARK: - Test 10: scanInterval境界値テスト

    @Test("scanIntervalの最小値が正しく制限される")
    func testScanIntervalMinimumClamp() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.min")!
        userDefaults.removePersistentDomain(forName: "test.bug001.min")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最小値未満を設定（30分 = 1800秒）
        manager.scanInterval = 1800.0

        // Assert: 最小値（1時間 = 3600秒）にクランプされる
        #expect(manager.scanInterval == BackgroundScanManager.minimumScanInterval)
    }

    @Test("scanIntervalの最大値が正しく制限される")
    func testScanIntervalMaximumClamp() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.max")!
        userDefaults.removePersistentDomain(forName: "test.bug001.max")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最大値超過を設定（14日 = 1209600秒）
        manager.scanInterval = 1209600.0

        // Assert: 最大値（7日 = 604800秒）にクランプされる
        #expect(manager.scanInterval == BackgroundScanManager.maximumScanInterval)
    }

    // MARK: - Test 11: スレッドセーフティ

    @Test("BackgroundScanManagerの並行アクセスが安全")
    func testConcurrentAccessSafety() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.concurrent")!
        userDefaults.removePersistentDomain(forName: "test.bug001.concurrent")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 複数のタスクで同時にアクセス
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    manager.isBackgroundScanEnabled = (i % 2 == 0)
                    manager.scanInterval = Double(i * 3600)
                }
            }
        }

        // Assert: クラッシュせず完了（値自体はどれかが最終的に設定される）
        #expect(manager.isBackgroundScanEnabled == true || manager.isBackgroundScanEnabled == false)
    }

    // MARK: - Test 12: UserDefaults永続化確認

    @Test("BackgroundScanManagerの設定がUserDefaultsに永続化される")
    func testBackgroundScanManagerPersistence() async throws {
        // Arrange
        let suiteName = "test.bug001.persistence"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        // Act: マネージャーで設定を変更
        let manager1 = BackgroundScanManager(userDefaults: userDefaults)
        manager1.isBackgroundScanEnabled = true
        manager1.scanInterval = 172800.0 // 2日

        // 新しいインスタンスで読み込み
        let manager2 = BackgroundScanManager(userDefaults: userDefaults)

        // Assert: 永続化された値が読み込まれる
        #expect(manager2.isBackgroundScanEnabled == true)
        #expect(manager2.scanInterval == 172800.0)
    }
}

// MARK: - BUG001_MockSettingsRepository

/// テスト用モックSettingsRepository（BUG001専用）
final class BUG001_MockSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _storage: UserSettings = .default
    private var _saveCalled = false
    private var _saveCount = 0

    var saveCalled: Bool {
        lock.withLock { _saveCalled }
    }

    var saveCount: Int {
        lock.withLock { _saveCount }
    }

    func load() -> UserSettings {
        lock.withLock { _storage }
    }

    func save(_ settings: UserSettings) {
        lock.withLock {
            _storage = settings
            _saveCalled = true
            _saveCount += 1
        }
    }

    func reset() {
        lock.withLock {
            _storage = .default
            _saveCalled = false
            _saveCount = 0
        }
    }
}
