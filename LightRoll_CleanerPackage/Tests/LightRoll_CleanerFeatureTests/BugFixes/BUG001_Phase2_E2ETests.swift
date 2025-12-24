//
//  BUG001_Phase2_E2ETests.swift
//  LightRoll_CleanerFeatureTests
//
//  BUG-001 Phase 2: 自動スキャン設定同期のE2Eテスト・バリデーション
//
//  テスト対象:
//  - 設定画面→BackgroundScanManagerへの完全同期フロー
//  - syncSettings()メソッドのE2E動作検証
//  - エラーケースとリトライのバリデーション
//
//  Created by AI Assistant on 2025-12-24.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - BUG001_Phase2_E2ETests

/// BUG-001 Phase 2: 自動スキャン設定同期E2Eテストスイート
@Suite("BUG-001 Phase 2: 自動スキャン設定同期 E2Eテスト")
@MainActor
struct BUG001_Phase2_E2ETests {

    // MARK: - Test 1: 正常系 - syncSettings完全フロー

    @Test("E2E: syncSettingsが設定を正しく同期する")
    func testSyncSettingsCompleteSynchronization() async throws {
        // Arrange: 独立したUserDefaultsでBackgroundScanManagerを作成
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.sync")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.sync")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // 初期状態を確認
        #expect(manager.isBackgroundScanEnabled == false)
        #expect(manager.scanInterval == BackgroundScanManager.defaultScanInterval)

        // Act: syncSettingsを呼び出し（有効化）
        manager.syncSettings(autoScanEnabled: true, scanInterval: 86400.0) // 毎日

        // Assert: 設定が正しく反映
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(manager.scanInterval == 86400.0)
        #expect(manager.nextScheduledScanDate != nil) // スケジュールが設定される
    }

    @Test("E2E: syncSettingsで無効化時にスケジュールがキャンセルされる")
    func testSyncSettingsDisablesCancelsSchedule() async throws {
        // Arrange: 有効な状態から開始
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.cancel")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.cancel")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // まず有効化
        manager.syncSettings(autoScanEnabled: true, scanInterval: 86400.0)
        #expect(manager.nextScheduledScanDate != nil)

        // Act: 無効化
        manager.syncSettings(autoScanEnabled: false, scanInterval: 86400.0)

        // Assert: スケジュールがキャンセルされる
        #expect(manager.isBackgroundScanEnabled == false)
        #expect(manager.nextScheduledScanDate == nil)
    }

    // MARK: - Test 2: 正常系 - 設定値変更の連続同期

    @Test("E2E: 連続したsyncSettings呼び出しが正しく反映される")
    func testConsecutiveSyncSettingsCalls() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.consecutive")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.consecutive")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act & Assert: 連続した設定変更

        // 変更1: 毎日
        manager.syncSettings(autoScanEnabled: true, scanInterval: AutoScanInterval.daily.timeInterval!)
        #expect(manager.scanInterval == 86400.0)

        // 変更2: 毎週
        manager.syncSettings(autoScanEnabled: true, scanInterval: AutoScanInterval.weekly.timeInterval!)
        #expect(manager.scanInterval == 604800.0)

        // 変更3: 毎月
        manager.syncSettings(autoScanEnabled: true, scanInterval: AutoScanInterval.monthly.timeInterval!)
        #expect(manager.scanInterval == 2592000.0)

        // 変更4: 無効化
        manager.syncSettings(autoScanEnabled: false, scanInterval: AutoScanInterval.weekly.timeInterval!)
        #expect(manager.isBackgroundScanEnabled == false)
    }

    @Test("E2E: AutoScanIntervalからTimeIntervalへの変換が正しい")
    func testAutoScanIntervalToTimeIntervalConversion() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.interval")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.interval")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act & Assert: 各間隔でsyncSettings
        let intervals: [(AutoScanInterval, TimeInterval)] = [
            (.daily, 86400.0),
            (.weekly, 604800.0),
            (.monthly, 2592000.0)
        ]

        for (interval, expectedTimeInterval) in intervals {
            guard let timeInterval = interval.timeInterval else {
                Issue.record("AutoScanInterval.\(interval)のtimeIntervalがnilです")
                continue
            }
            manager.syncSettings(autoScanEnabled: true, scanInterval: timeInterval)
            #expect(manager.scanInterval == expectedTimeInterval)
        }
    }

    // MARK: - Test 3: 異常系 - エラーケースのバリデーション

    @Test("E2E: 無効なscanIntervalがクランプされる（最小値）")
    func testSyncSettingsWithInvalidMinInterval() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.minclamp")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.minclamp")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最小値未満を設定（30分 = 1800秒）
        manager.syncSettings(autoScanEnabled: true, scanInterval: 1800.0)

        // Assert: 最小値（1時間）にクランプされる
        #expect(manager.scanInterval == BackgroundScanManager.minimumScanInterval)
        #expect(manager.scanInterval == 3600.0) // 1時間
    }

    @Test("E2E: 無効なscanIntervalがクランプされる（最大値）")
    func testSyncSettingsWithInvalidMaxInterval() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.maxclamp")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.maxclamp")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最大値超過を設定（14日 = 1209600秒）
        manager.syncSettings(autoScanEnabled: true, scanInterval: 1209600.0)

        // Assert: 最大値（7日）にクランプされる
        #expect(manager.scanInterval == BackgroundScanManager.maximumScanInterval)
        #expect(manager.scanInterval == 604800.0) // 7日
    }

    @Test("E2E: ゼロのscanIntervalが最小値にクランプされる")
    func testSyncSettingsWithZeroInterval() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.zero")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.zero")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: ゼロを設定
        manager.syncSettings(autoScanEnabled: true, scanInterval: 0.0)

        // Assert: 最小値にクランプされる
        #expect(manager.scanInterval == BackgroundScanManager.minimumScanInterval)
    }

    // MARK: - Test 4: 境界値テスト

    @Test("E2E: 境界値 - 最小scanIntervalでの同期")
    func testSyncSettingsAtMinimumBoundary() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.boundary.min")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.boundary.min")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最小値ちょうどを設定
        let minInterval = BackgroundScanManager.minimumScanInterval
        manager.syncSettings(autoScanEnabled: true, scanInterval: minInterval)

        // Assert: そのまま設定される
        #expect(manager.scanInterval == minInterval)
    }

    @Test("E2E: 境界値 - 最大scanIntervalでの同期")
    func testSyncSettingsAtMaximumBoundary() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.boundary.max")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.boundary.max")
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act: 最大値ちょうどを設定
        let maxInterval = BackgroundScanManager.maximumScanInterval
        manager.syncSettings(autoScanEnabled: true, scanInterval: maxInterval)

        // Assert: そのまま設定される
        #expect(manager.scanInterval == maxInterval)
    }

    // MARK: - Test 5: 統合フローテスト - SettingsService連携

    @Test("E2E: SettingsService→BackgroundScanManager完全同期フロー")
    func testSettingsServiceToBackgroundScanManagerFlow() async throws {
        // Arrange: 両方を初期化
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.fullflow")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.fullflow")

        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act 1: SettingsServiceで自動スキャンを有効化
        var updatedSettings = service.settings.scanSettings
        updatedSettings.autoScanEnabled = true
        updatedSettings.autoScanInterval = .daily
        try service.updateScanSettings(updatedSettings)

        // シミュレート: ContentViewの.onChange監視で同期
        if let timeInterval = service.settings.scanSettings.autoScanInterval.timeInterval {
            manager.syncSettings(
                autoScanEnabled: service.settings.scanSettings.autoScanEnabled,
                scanInterval: timeInterval
            )
        }

        // Assert: 両方に値が反映される
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(manager.scanInterval == 86400.0)
        #expect(manager.nextScheduledScanDate != nil)
    }

    @Test("E2E: 設定変更→無効化の完全サイクル")
    func testSettingsChangeDisableCycle() async throws {
        // Arrange
        let userDefaults = UserDefaults(suiteName: "test.bug001.e2e.cycle")!
        userDefaults.removePersistentDomain(forName: "test.bug001.e2e.cycle")

        let mockRepository = BUG001_MockSettingsRepository()
        let service = SettingsService(repository: mockRepository)
        let manager = BackgroundScanManager(userDefaults: userDefaults)

        // Act 1: 有効化
        var settings1 = service.settings.scanSettings
        settings1.autoScanEnabled = true
        settings1.autoScanInterval = .weekly
        try service.updateScanSettings(settings1)

        if let timeInterval = settings1.autoScanInterval.timeInterval {
            manager.syncSettings(autoScanEnabled: true, scanInterval: timeInterval)
        }

        // Assert 1: 有効状態
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(manager.nextScheduledScanDate != nil)

        // Act 2: 無効化
        var settings2 = service.settings.scanSettings
        settings2.autoScanEnabled = false
        try service.updateScanSettings(settings2)

        manager.syncSettings(autoScanEnabled: false, scanInterval: manager.scanInterval)

        // Assert 2: 無効状態
        #expect(manager.isBackgroundScanEnabled == false)
        #expect(manager.nextScheduledScanDate == nil)

        // Act 3: 再有効化
        var settings3 = service.settings.scanSettings
        settings3.autoScanEnabled = true
        settings3.autoScanInterval = .monthly
        try service.updateScanSettings(settings3)

        if let timeInterval = settings3.autoScanInterval.timeInterval {
            manager.syncSettings(autoScanEnabled: true, scanInterval: timeInterval)
        }

        // Assert 3: 再有効状態
        #expect(manager.isBackgroundScanEnabled == true)
        #expect(manager.scanInterval == 2592000.0)
        #expect(manager.nextScheduledScanDate != nil)
    }
}

// MARK: - BUG001_Phase2_ValidationTests

/// BUG-001 Phase 2: バリデーションテストスイート
@Suite("BUG-001 Phase 2: バリデーションテスト")
@MainActor
struct BUG001_Phase2_ValidationTests {

    // MARK: - Test 1: ScanSettings バリデーション

    @Test("バリデーション: 有効なScanSettingsが正常に通過する")
    func testValidScanSettingsPassesValidation() async throws {
        // Arrange
        let settings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .daily,
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: true
        )

        // Act & Assert: エラーが発生しない
        try settings.validate()
    }

    @Test("バリデーション: 少なくとも1つのコンテンツタイプが必須")
    func testValidationRequiresAtLeastOneContentType() async throws {
        // Arrange: すべてのコンテンツタイプを無効
        let settings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: false
        )

        // Act & Assert: バリデーションエラー
        #expect(throws: SettingsError.noContentTypeEnabled) {
            try settings.validate()
        }
    }

    @Test("バリデーション: 1つのコンテンツタイプのみ有効でもOK")
    func testValidationPassesWithSingleContentType() async throws {
        // 動画のみ
        let settings1 = ScanSettings(
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: false
        )
        try settings1.validate()

        // スクリーンショットのみ
        let settings2 = ScanSettings(
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: false
        )
        try settings2.validate()

        // セルフィーのみ
        let settings3 = ScanSettings(
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: true
        )
        try settings3.validate()
    }

    // MARK: - Test 2: AutoScanInterval バリデーション

    @Test("バリデーション: AutoScanInterval.neverのtimeIntervalがnil")
    func testAutoScanIntervalNeverReturnsNil() {
        // Arrange & Act
        let interval = AutoScanInterval.never

        // Assert
        #expect(interval.timeInterval == nil)
    }

    @Test("バリデーション: AutoScanInterval値の正確性")
    func testAutoScanIntervalValues() {
        // Assert: 各間隔の秒数が正しい
        #expect(AutoScanInterval.daily.timeInterval == 86400) // 1日 = 24 * 60 * 60
        #expect(AutoScanInterval.weekly.timeInterval == 604800) // 7日 = 7 * 24 * 60 * 60
        #expect(AutoScanInterval.monthly.timeInterval == 2592000) // 30日 = 30 * 24 * 60 * 60
        #expect(AutoScanInterval.never.timeInterval == nil)
    }

    // MARK: - Test 3: BackgroundScanManager プロパティバリデーション

    @Test("バリデーション: BackgroundScanManager定数の正確性")
    func testBackgroundScanManagerConstants() {
        // Assert: 定数値
        #expect(BackgroundScanManager.defaultScanInterval == 86400) // 24時間
        #expect(BackgroundScanManager.minimumScanInterval == 3600) // 1時間
        #expect(BackgroundScanManager.maximumScanInterval == 604800) // 7日
    }

    @Test("バリデーション: タスク識別子の形式")
    func testTaskIdentifiersFormat() {
        // Assert: 識別子の形式が正しい
        let refreshId = BackgroundScanManager.backgroundRefreshTaskIdentifier
        let processingId = BackgroundScanManager.backgroundProcessingTaskIdentifier

        #expect(refreshId.hasPrefix("com.lightroll"))
        #expect(processingId.hasPrefix("com.lightroll"))
        #expect(refreshId.contains("backgroundRefresh"))
        #expect(processingId.contains("backgroundProcessing"))
    }
}
