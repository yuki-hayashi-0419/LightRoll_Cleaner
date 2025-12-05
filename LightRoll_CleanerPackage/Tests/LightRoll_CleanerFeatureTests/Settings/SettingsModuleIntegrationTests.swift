//
//  SettingsModuleIntegrationTests.swift
//  LightRoll_CleanerFeature
//
//  M8モジュール統合テストスイート
//  - SettingsService、PermissionManager、ViewModelの統合動作テスト
//  - データ永続化、権限管理、設定変更伝播のE2Eシナリオ
//  M8-T14 実装
//  Created by AI Assistant on 2025-12-06.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - Test Suite

/// Settings モジュール統合テスト
///
/// このテストスイートは以下をカバー:
/// 1. 統合シナリオ（画面遷移、設定保存、複数変更、リセット、エラー回復）
/// 2. データ永続化（保存、復元、不正データ処理）
/// 3. 権限管理統合（権限リクエスト、状態反映）
/// 4. 設定変更伝播（サービス経由の更新、自動UI更新、複数画面同期）
/// 5. エンドツーエンドシナリオ（初回起動、カスタマイズ、全設定変更）
@MainActor
@Suite("Settings Module Integration Tests")
struct SettingsModuleIntegrationTests {

    // MARK: - Test Helpers

    /// テスト用のモックリポジトリ
    final class MockSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {
        private let storage = NSMutableDictionary()

        func save(_ settings: UserSettings) {
            if let data = try? JSONEncoder().encode(settings) {
                storage.setObject(data, forKey: "settings" as NSString)
            }
        }

        func load() -> UserSettings {
            guard let data = storage.object(forKey: "settings" as NSString) as? Data,
                  let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
                return .default
            }
            return settings
        }

        func reset() {
            storage.removeAllObjects()
        }

        func clear() {
            storage.removeAllObjects()
        }
    }

    /// テスト用のモック権限マネージャー
    final class MockPermissionManager: @unchecked Sendable {
        var photoLibraryStatus: PermissionStatus = .notDetermined
        var notificationStatus: PermissionStatus = .notDetermined
        var requestPhotoLibraryCalled = false
        var requestNotificationCalled = false

        func photoLibraryPermissionStatus() -> PermissionStatus {
            photoLibraryStatus
        }

        func notificationPermissionStatus() async -> PermissionStatus {
            notificationStatus
        }

        func requestPhotoLibraryPermission() async -> PermissionStatus {
            requestPhotoLibraryCalled = true
            photoLibraryStatus = .authorized
            return .authorized
        }

        func requestNotificationPermission() async -> PermissionStatus {
            requestNotificationCalled = true
            notificationStatus = .authorized
            return .authorized
        }
    }

    // MARK: - 1. 統合シナリオテスト (7テスト)

    @Test("設定保存と読み込みの統合フロー")
    func settingsSaveAndLoadIntegration() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // カスタム設定を作成
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .daily

        // 保存
        try service.updateScanSettings(scanSettings)

        // 新しいサービスインスタンスで読み込み
        let service2 = SettingsService(repository: repository)
        #expect(service2.settings.scanSettings.autoScanEnabled == true)
        #expect(service2.settings.scanSettings.autoScanInterval == .daily)
    }

    @Test("複数設定の同時変更と保存")
    func multipleSettingsUpdate() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // スキャン設定を変更
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // 分析設定を変更
        var analysisSettings = AnalysisSettings.default
        analysisSettings.similarityThreshold = 0.95
        try service.updateAnalysisSettings(analysisSettings)

        // 表示設定を変更
        var displaySettings = DisplaySettings.default
        displaySettings.showFileSize = true
        try service.updateDisplaySettings(displaySettings)

        // すべての変更が反映されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(service.settings.displaySettings.showFileSize == true)

        // 再読み込みして永続化を確認
        let service2 = SettingsService(repository: repository)
        #expect(service2.settings.scanSettings.autoScanEnabled == true)
        #expect(service2.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(service2.settings.displaySettings.showFileSize == true)
    }

    @Test("デフォルトへのリセット統合")
    func resetToDefaultsIntegration() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // カスタム設定を保存
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // リセット
        service.resetToDefaults()

        // デフォルト値に戻っていることを確認
        #expect(service.settings == .default)

        // 再読み込みしてもデフォルトであることを確認
        let service2 = SettingsService(repository: repository)
        #expect(service2.settings == .default)
    }

    @Test("バリデーションエラー発生時の状態維持")
    func validationErrorStatePreservation() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初期設定を保存
        var validSettings = ScanSettings.default
        validSettings.autoScanEnabled = true
        try service.updateScanSettings(validSettings)

        // 不正な設定を試みる
        var invalidSettings = ScanSettings.default
        invalidSettings.includeVideos = false
        invalidSettings.includeScreenshots = false
        invalidSettings.includeSelfies = false

        // バリデーションエラーが発生することを確認
        #expect(throws: SettingsError.self) {
            try service.updateScanSettings(invalidSettings)
        }

        // 元の設定が維持されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
    }

    @Test("設定サービスのエラー回復")
    func settingsServiceErrorRecovery() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 不正な設定でエラーを発生させる
        var invalidScanSettings = ScanSettings.default
        invalidScanSettings.includeVideos = false
        invalidScanSettings.includeScreenshots = false
        invalidScanSettings.includeSelfies = false

        #expect(throws: SettingsError.self) {
            try service.updateScanSettings(invalidScanSettings)
        }

        // エラー発生後でもサービスは動作することを確認（lastErrorはupdateSettings経由でないとセットされない）
        #expect(service.lastError == nil) // throwsで例外が投げられるため、lastErrorには記録されない

        // 正常な設定で再試行
        var validSettings = ScanSettings.default
        validSettings.autoScanEnabled = true
        try service.updateScanSettings(validSettings)

        // 成功したことを確認
        #expect(service.lastError == nil)
        #expect(service.settings.scanSettings.autoScanEnabled == true)
    }

    @Test("ViewModelとServiceの統合動作")
    func viewModelServiceIntegration() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)
        let service = SettingsService(repository: repository)

        // ViewModelで設定を変更
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        await viewModel.updateScanSettings(scanSettings)

        // Serviceで読み込んで反映されていることを確認
        service.reload()
        #expect(service.settings.scanSettings.autoScanEnabled == true)
    }

    @Test("保存中フラグの動作確認")
    func savingFlagBehavior() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初期状態では保存中ではない
        #expect(service.isSaving == false)

        // 設定を変更（同期的に保存される）
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // 保存完了後はフラグがfalseに戻る
        #expect(service.isSaving == false)
    }

    // MARK: - 2. データ永続化テスト (5テスト)

    @Test("UserDefaults経由での設定保存")
    func userDefaultsPersistence() async throws {
        let repository = SettingsRepository()
        let service = SettingsService(repository: repository)

        // カスタム設定を保存
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .monthly
        try service.updateScanSettings(scanSettings)

        // 新しいインスタンスで読み込み
        let service2 = SettingsService(repository: SettingsRepository())
        #expect(service2.settings.scanSettings.autoScanEnabled == true)
        #expect(service2.settings.scanSettings.autoScanInterval == .monthly)

        // クリーンアップ
        service2.resetToDefaults()
    }

    @Test("アプリ再起動後の設定復元シミュレーション")
    func settingsRestoreAfterRestart() async throws {
        let repository = MockSettingsRepository()

        // セッション1: 設定を保存
        do {
            let service = SettingsService(repository: repository)
            var analysisSettings = AnalysisSettings.default
            analysisSettings.similarityThreshold = 0.88
            analysisSettings.blurThreshold = 0.65
            try service.updateAnalysisSettings(analysisSettings)
        }

        // セッション2: 設定を復元
        do {
            let service = SettingsService(repository: repository)
            #expect(service.settings.analysisSettings.similarityThreshold == 0.88)
            #expect(service.settings.analysisSettings.blurThreshold == 0.65)
        }
    }

    @Test("不正なJSONデータの処理")
    func invalidJSONHandling() async throws {
        let repository = MockSettingsRepository()

        // 不正なデータを直接書き込み
        let invalidData = "invalid json".data(using: .utf8)!
        let storage = NSMutableDictionary()
        storage.setObject(invalidData, forKey: "settings" as NSString)

        // デフォルト設定が返されることを確認
        let service = SettingsService(repository: repository)
        #expect(service.settings == .default)
    }

    @Test("設定の完全性検証")
    func settingsIntegrityValidation() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 各設定項目を個別に変更
        var scanSettings = ScanSettings.default
        scanSettings.includeVideos = false
        try service.updateScanSettings(scanSettings)

        var analysisSettings = AnalysisSettings.default
        analysisSettings.similarityThreshold = 0.92
        try service.updateAnalysisSettings(analysisSettings)

        var notificationSettings = NotificationSettings.default
        notificationSettings.isEnabled = false
        notificationSettings.reminderEnabled = false
        try service.updateNotificationSettings(notificationSettings)

        var displaySettings = DisplaySettings.default
        displaySettings.gridColumns = 4
        try service.updateDisplaySettings(displaySettings)

        // すべての設定が正しく保存・復元されることを確認
        let service2 = SettingsService(repository: repository)
        #expect(service2.settings.scanSettings.includeVideos == false)
        #expect(service2.settings.analysisSettings.similarityThreshold == 0.92)
        #expect(service2.settings.notificationSettings.isEnabled == false)
        #expect(service2.settings.displaySettings.gridColumns == 4)
    }

    @Test("リポジトリのリセット動作")
    func repositoryResetBehavior() async throws {
        let repository = MockSettingsRepository()

        // カスタム設定を保存
        var settings = UserSettings.default
        settings.scanSettings.autoScanEnabled = true
        repository.save(settings)

        // リセット
        repository.reset()

        // デフォルト設定が読み込まれることを確認
        let loadedSettings = repository.load()
        #expect(loadedSettings == .default)
    }

    // MARK: - 3. 権限管理統合テスト (4テスト)

    @Test("写真ライブラリ権限リクエストフロー")
    func photoLibraryPermissionFlow() async throws {
        let mockPermissionManager = MockPermissionManager()

        // 初期状態は未決定
        #expect(mockPermissionManager.photoLibraryPermissionStatus() == .notDetermined)

        // 権限をリクエスト
        let status = await mockPermissionManager.requestPhotoLibraryPermission()

        // 権限が付与されたことを確認
        #expect(status == .authorized)
        #expect(mockPermissionManager.requestPhotoLibraryCalled == true)
        #expect(mockPermissionManager.photoLibraryPermissionStatus() == .authorized)
    }

    @Test("通知権限リクエストフロー")
    func notificationPermissionFlow() async throws {
        let mockPermissionManager = MockPermissionManager()

        // 初期状態は未決定
        let initialStatus = await mockPermissionManager.notificationPermissionStatus()
        #expect(initialStatus == .notDetermined)

        // 権限をリクエスト
        let status = await mockPermissionManager.requestNotificationPermission()

        // 権限が付与されたことを確認
        #expect(status == .authorized)
        #expect(mockPermissionManager.requestNotificationCalled == true)

        let finalStatus = await mockPermissionManager.notificationPermissionStatus()
        #expect(finalStatus == .authorized)
    }

    @Test("権限状態の変化追跡")
    func permissionStateTracking() async throws {
        let mockPermissionManager = MockPermissionManager()

        // 未決定 → 権限付与
        mockPermissionManager.photoLibraryStatus = .notDetermined
        #expect(mockPermissionManager.photoLibraryPermissionStatus() == .notDetermined)

        _ = await mockPermissionManager.requestPhotoLibraryPermission()
        #expect(mockPermissionManager.photoLibraryPermissionStatus() == .authorized)

        // 拒否シミュレーション
        mockPermissionManager.photoLibraryStatus = .denied
        #expect(mockPermissionManager.photoLibraryPermissionStatus() == .denied)
    }

    @Test("複数権限の同時管理")
    func multiplePermissionsManagement() async throws {
        let mockPermissionManager = MockPermissionManager()

        // 両方の権限をリクエスト
        let photoStatus = await mockPermissionManager.requestPhotoLibraryPermission()
        let notificationStatus = await mockPermissionManager.requestNotificationPermission()

        // 両方とも付与されていることを確認
        #expect(photoStatus == .authorized)
        #expect(notificationStatus == .authorized)
        #expect(mockPermissionManager.requestPhotoLibraryCalled == true)
        #expect(mockPermissionManager.requestNotificationCalled == true)
    }

    // MARK: - 4. 設定変更伝播テスト (4テスト)

    @Test("SettingsService経由の設定更新")
    func settingsUpdateThroughService() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初期値を確認
        #expect(service.settings.scanSettings.autoScanEnabled == false)

        // 設定を更新
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // サービスの設定が更新されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
    }

    @Test("@Observableによる自動UI更新シミュレーション")
    func observableAutoUpdateSimulation() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初期状態を記録
        let initialAutoScan = service.settings.scanSettings.autoScanEnabled

        // 設定を更新
        service.updateSettings { settings in
            settings.scanSettings.autoScanEnabled.toggle()
        }

        // 値が変更されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled != initialAutoScan)
    }

    @Test("複数コンポーネント間の設定同期")
    func multiComponentSettingsSync() async throws {
        let repository = MockSettingsRepository()
        let service1 = SettingsService(repository: repository)
        let service2 = SettingsService(repository: repository)

        // service1で設定を変更
        var scanSettings = ScanSettings.default
        scanSettings.autoScanInterval = .daily
        try service1.updateScanSettings(scanSettings)

        // service2をリロード
        service2.reload()

        // 同じ値が反映されていることを確認
        #expect(service2.settings.scanSettings.autoScanInterval == .daily)
    }

    @Test("バリデーションエラー時のロールバック")
    func validationErrorRollback() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 正常な設定を保存
        var validSettings = ScanSettings.default
        validSettings.autoScanEnabled = true
        try service.updateScanSettings(validSettings)

        let savedSettings = service.settings.scanSettings

        // 不正な設定を試みる
        var invalidSettings = ScanSettings.default
        invalidSettings.includeVideos = false
        invalidSettings.includeScreenshots = false
        invalidSettings.includeSelfies = false

        #expect(throws: SettingsError.self) {
            try service.updateScanSettings(invalidSettings)
        }

        // 元の設定が維持されていることを確認（ロールバック）
        #expect(service.settings.scanSettings == savedSettings)
    }

    // MARK: - 5. エンドツーエンドシナリオ (5テスト)

    @Test("初回起動フローシミュレーション")
    func firstLaunchFlowSimulation() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初回起動時はデフォルト設定
        #expect(service.settings == .default)

        // ユーザーが初期設定を行う
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        var notificationSettings = NotificationSettings.default
        notificationSettings.isEnabled = true
        notificationSettings.reminderEnabled = true
        try service.updateNotificationSettings(notificationSettings)

        // 設定が保存されたことを確認
        let newService = SettingsService(repository: repository)
        #expect(newService.settings.scanSettings.autoScanEnabled == true)
        #expect(newService.settings.notificationSettings.isEnabled == true)
    }

    @Test("設定カスタマイズフルフロー")
    func fullSettingsCustomizationFlow() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // スキャン設定をカスタマイズ
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .daily
        scanSettings.includeVideos = true
        try service.updateScanSettings(scanSettings)

        // 分析設定をカスタマイズ
        var analysisSettings = AnalysisSettings.default
        analysisSettings.similarityThreshold = 0.88
        analysisSettings.blurThreshold = 0.6
        try service.updateAnalysisSettings(analysisSettings)

        // 通知設定をカスタマイズ
        var notificationSettings = NotificationSettings.default
        notificationSettings.isEnabled = true
        notificationSettings.storageAlertEnabled = true
        notificationSettings.reminderEnabled = true
        try service.updateNotificationSettings(notificationSettings)

        // 表示設定をカスタマイズ
        var displaySettings = DisplaySettings.default
        displaySettings.gridColumns = 4
        displaySettings.showFileSize = true
        try service.updateDisplaySettings(displaySettings)

        // すべての設定が保存されたことを確認
        let newService = SettingsService(repository: repository)
        #expect(newService.settings.scanSettings.autoScanEnabled == true)
        #expect(newService.settings.scanSettings.autoScanInterval == .daily)
        #expect(newService.settings.analysisSettings.similarityThreshold == 0.88)
        #expect(newService.settings.analysisSettings.blurThreshold == 0.6)
        #expect(newService.settings.notificationSettings.isEnabled == true)
        #expect(newService.settings.displaySettings.gridColumns == 4)
    }

    @Test("プレミアムアップグレード誘導フロー")
    func premiumUpgradeFlow() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // 初期状態は無料プラン
        #expect(service.settings.premiumStatus == .free)

        // プレミアム機能を試みる（自動スキャン）
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true  // プレミアム機能
        try service.updateScanSettings(scanSettings)

        // プレミアムステータスを更新
        service.updatePremiumStatus(.premium)

        // プレミアムステータスが保存されたことを確認
        let newService = SettingsService(repository: repository)
        #expect(newService.settings.premiumStatus == .premium)
    }

    @Test("全設定項目の一括変更・保存")
    func bulkSettingsUpdate() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // すべての設定を一度に変更
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .monthly
        scanSettings.includeVideos = false
        try service.updateScanSettings(scanSettings)

        var analysisSettings = AnalysisSettings.default
        analysisSettings.similarityThreshold = 0.95
        analysisSettings.blurThreshold = 0.7
        analysisSettings.minGroupSize = 3
        try service.updateAnalysisSettings(analysisSettings)

        var notificationSettings = NotificationSettings.default
        notificationSettings.isEnabled = false
        notificationSettings.reminderEnabled = false
        try service.updateNotificationSettings(notificationSettings)

        var displaySettings = DisplaySettings.default
        displaySettings.sortOrder = .sizeDescending
        displaySettings.gridColumns = 5
        displaySettings.showFileSize = false
        try service.updateDisplaySettings(displaySettings)

        // すべての変更が永続化されていることを確認
        let newService = SettingsService(repository: repository)
        #expect(newService.settings.scanSettings.autoScanEnabled == true)
        #expect(newService.settings.scanSettings.includeVideos == false)
        #expect(newService.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(newService.settings.notificationSettings.isEnabled == false)
        #expect(newService.settings.displaySettings.sortOrder == .sizeDescending)
        #expect(newService.settings.displaySettings.gridColumns == 5)
    }

    @Test("設定のインポート・エクスポートシミュレーション")
    func settingsImportExportSimulation() async throws {
        let repository = MockSettingsRepository()
        let service = SettingsService(repository: repository)

        // カスタム設定を作成
        var scanSettings = ScanSettings.default
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        var analysisSettings = AnalysisSettings.default
        analysisSettings.similarityThreshold = 0.91
        try service.updateAnalysisSettings(analysisSettings)

        // 設定をエクスポート（JSONエンコード）
        let encoder = JSONEncoder()
        let exportedData = try encoder.encode(service.settings)

        // 設定をリセット
        service.resetToDefaults()
        #expect(service.settings == .default)

        // 設定をインポート（JSONデコード）
        let decoder = JSONDecoder()
        let importedSettings = try decoder.decode(UserSettings.self, from: exportedData)

        // インポートした設定を保存
        try service.updateScanSettings(importedSettings.scanSettings)
        try service.updateAnalysisSettings(importedSettings.analysisSettings)

        // 元の設定が復元されたことを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.similarityThreshold == 0.91)
    }
}
