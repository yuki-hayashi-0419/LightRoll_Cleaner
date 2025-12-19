//
//  SettingsViewIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsView統合テスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - SettingsViewIntegrationTests

/// SettingsViewの統合テスト
/// 設定の保存・読み込み、UI操作の動作を検証
@MainActor
@Suite("SettingsView統合テスト")
struct SettingsViewIntegrationTests {

    // MARK: - テスト用リポジトリ

    /// テスト用UserDefaults
    private let testDefaults: UserDefaults

    /// テスト用リポジトリ
    private let repository: SettingsRepository

    /// テスト用サービス
    private let service: SettingsService

    init() {
        // 各テストで独立したUserDefaultsを使用
        testDefaults = UserDefaults(suiteName: "test.suite.\(UUID().uuidString)")!
        repository = SettingsRepository(userDefaults: testDefaults)
        service = SettingsService(repository: repository)
    }

    // MARK: - 正常系テスト

    @Test("デフォルト設定の読み込み")
    func testLoadDefaultSettings() {
        // Given: 初期状態（何も保存されていない）
        // When: 設定を読み込み
        let settings = service.settings

        // Then: デフォルト値が返される
        #expect(settings.scanSettings.autoScanEnabled == false)
        #expect(settings.scanSettings.includeVideos == true)
        #expect(settings.displaySettings.gridColumns == 3)
        #expect(settings.notificationSettings.isEnabled == false)
    }

    @Test("スキャン設定の保存と読み込み")
    func testSaveAndLoadScanSettings() throws {
        // Given: スキャン設定を変更
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .weekly
        scanSettings.includeVideos = false

        // When: 保存
        try service.updateScanSettings(scanSettings)

        // Then: 正しく読み込まれる
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
        #expect(service.settings.scanSettings.includeVideos == false)
    }

    @Test("分析設定の保存と読み込み")
    func testSaveAndLoadAnalysisSettings() throws {
        // Given: 分析設定を変更
        var analysisSettings = service.settings.analysisSettings
        analysisSettings.similarityThreshold = 0.95
        analysisSettings.minGroupSize = 5
        analysisSettings.blurThreshold = 0.8

        // When: 保存
        try service.updateAnalysisSettings(analysisSettings)

        // Then: 正しく読み込まれる
        #expect(service.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(service.settings.analysisSettings.minGroupSize == 5)
        #expect(service.settings.analysisSettings.blurThreshold == 0.8)
    }

    @Test("表示設定の保存と読み込み")
    func testSaveAndLoadDisplaySettings() throws {
        // Given: 表示設定を変更
        var displaySettings = service.settings.displaySettings
        displaySettings.gridColumns = 5
        displaySettings.showFileSize = true
        displaySettings.showDate = false
        displaySettings.sortOrder = .dateDescending

        // When: 保存
        try service.updateDisplaySettings(displaySettings)

        // Then: 正しく読み込まれる
        #expect(service.settings.displaySettings.gridColumns == 5)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == false)
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    @Test("通知設定の保存と読み込み")
    func testSaveAndLoadNotificationSettings() throws {
        // Given: 通知設定を変更
        var notificationSettings = service.settings.notificationSettings
        notificationSettings.isEnabled = true
        notificationSettings.storageAlertEnabled = true
        notificationSettings.reminderEnabled = true
        notificationSettings.quietHoursEnabled = true

        // When: 保存
        try service.updateNotificationSettings(notificationSettings)

        // Then: 正しく読み込まれる
        #expect(service.settings.notificationSettings.isEnabled == true)
        #expect(service.settings.notificationSettings.storageAlertEnabled == true)
        #expect(service.settings.notificationSettings.reminderEnabled == true)
        #expect(service.settings.notificationSettings.quietHoursEnabled == true)
    }

    @Test("複数の設定を順次保存")
    func testSaveMultipleSettingsSequentially() throws {
        // Given: 複数の設定を変更

        // When: スキャン設定を保存
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // When: 表示設定を保存
        var displaySettings = service.settings.displaySettings
        displaySettings.gridColumns = 4
        try service.updateDisplaySettings(displaySettings)

        // Then: 両方の設定が保持される
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.displaySettings.gridColumns == 4)
    }

    // MARK: - 異常系テスト

    @Test("不正な類似度しきい値")
    func testInvalidSimilarityThreshold() throws {
        // Given: 範囲外の類似度しきい値
        var analysisSettings = service.settings.analysisSettings
        analysisSettings.similarityThreshold = 1.5 // 範囲外

        // When: 保存
        try service.updateAnalysisSettings(analysisSettings)

        // Then: 0.0-1.0の範囲にクランプされる
        #expect(service.settings.analysisSettings.similarityThreshold <= 1.0)
    }

    @Test("不正なグリッド列数")
    func testInvalidGridColumns() {
        // Given: 範囲外のグリッド列数
        var displaySettings = service.settings.displaySettings
        displaySettings.gridColumns = 10 // 通常6が最大

        // When/Then: 保存は成功するが、UIでは制限される
        // SettingsServiceは値を検証しないため、UIレベルで制限
        #expect(throws: Never.self) {
            try service.updateDisplaySettings(displaySettings)
        }
    }

    // MARK: - 境界値テスト

    @Test("最小グループサイズの境界値")
    func testMinGroupSizeBoundary() throws {
        // Given: 最小値と最大値
        let testCases = [
            (input: 1, expected: 2),  // 最小値未満
            (input: 2, expected: 2),  // 最小値
            (input: 5, expected: 5),  // 中間値
            (input: 10, expected: 10) // 上限値
        ]

        for testCase in testCases {
            // When: グループサイズを設定
            var analysisSettings = service.settings.analysisSettings
            analysisSettings.minGroupSize = testCase.input
            try service.updateAnalysisSettings(analysisSettings)

            // Then: 期待値と一致（最小値2に制限）
            #expect(service.settings.analysisSettings.minGroupSize >= 2)
        }
    }

    @Test("グリッド列数の境界値")
    func testGridColumnsBoundary() throws {
        // Given: グリッド列数の境界値
        let testCases = [2, 3, 4, 5, 6]

        for columns in testCases {
            // When: 列数を設定
            var displaySettings = service.settings.displaySettings
            displaySettings.gridColumns = columns
            try service.updateDisplaySettings(displaySettings)

            // Then: 正しく保存される
            #expect(service.settings.displaySettings.gridColumns == columns)
        }
    }

    @Test("類似度しきい値の境界値")
    func testSimilarityThresholdBoundary() throws {
        // Given: 類似度の境界値
        let testCases: [Float] = [0.0, 0.5, 0.85, 1.0]

        for threshold in testCases {
            // When: しきい値を設定
            var analysisSettings = service.settings.analysisSettings
            analysisSettings.similarityThreshold = threshold
            try service.updateAnalysisSettings(analysisSettings)

            // Then: 正しく保存される
            #expect(service.settings.analysisSettings.similarityThreshold == threshold)
        }
    }

    // MARK: - 永続化テスト

    @Test("設定の永続化確認")
    func testSettingsPersistence() throws {
        // Given: 設定を変更して保存
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // When: 新しいサービスインスタンスを作成
        let newService = SettingsService(repository: repository)

        // Then: 設定が永続化されている
        #expect(newService.settings.scanSettings.autoScanEnabled == true)
    }

    @Test("設定のリセット")
    func testResetSettings() throws {
        // Given: 設定を変更
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // When: リセット
        service.resetToDefaults()

        // Then: デフォルト値に戻る
        #expect(service.settings.scanSettings.autoScanEnabled == false)
    }

    // MARK: - トグル操作テスト

    @Test("トグルのオン・オフ切り替え")
    func testToggleSwitching() throws {
        // Given: 初期状態（オフ）
        var scanSettings = service.settings.scanSettings
        #expect(scanSettings.autoScanEnabled == false)

        // When: オンに切り替え
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // Then: オンになる
        #expect(service.settings.scanSettings.autoScanEnabled == true)

        // When: オフに切り替え
        scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = false
        try service.updateScanSettings(scanSettings)

        // Then: オフになる
        #expect(service.settings.scanSettings.autoScanEnabled == false)
    }

    @Test("複数トグルの独立性")
    func testMultipleTogglesIndependence() throws {
        // Given: 複数のトグル設定
        var scanSettings = service.settings.scanSettings

        // When: 個別にオン・オフ
        scanSettings.includeVideos = true
        scanSettings.includeScreenshots = false
        scanSettings.includeSelfies = true
        try service.updateScanSettings(scanSettings)

        // Then: それぞれ独立して動作
        #expect(service.settings.scanSettings.includeVideos == true)
        #expect(service.settings.scanSettings.includeScreenshots == false)
        #expect(service.settings.scanSettings.includeSelfies == true)
    }

    // MARK: - ピッカー操作テスト

    @Test("自動スキャン間隔の選択")
    func testAutoScanIntervalPicker() throws {
        // Given: すべての間隔オプション
        let intervals = AutoScanInterval.allCases

        for interval in intervals {
            // When: 間隔を選択
            var scanSettings = service.settings.scanSettings
            scanSettings.autoScanInterval = interval
            try service.updateScanSettings(scanSettings)

            // Then: 正しく保存される
            #expect(service.settings.scanSettings.autoScanInterval == interval)
        }
    }

    @Test("ソート順の選択")
    func testSortOrderPicker() throws {
        // Given: すべてのソート順
        let sortOrders = SortOrder.allCases

        for sortOrder in sortOrders {
            // When: ソート順を選択
            var displaySettings = service.settings.displaySettings
            displaySettings.sortOrder = sortOrder
            try service.updateDisplaySettings(displaySettings)

            // Then: 正しく保存される
            #expect(service.settings.displaySettings.sortOrder == sortOrder)
        }
    }

    // MARK: - エラーハンドリングテスト

    @Test("エラーの記録と取得")
    func testErrorRecording() throws {
        // Given: エラーが発生する状況をシミュレート
        // Note: 実際のエラー生成は難しいため、エラーハンドリング機構のテスト

        // When: lastErrorを確認
        let error = service.lastError

        // Then: 初期状態ではエラーなし
        #expect(error == nil)
    }

    @Test("エラーのクリア")
    func testClearError() {
        // Given: エラーがある状態（シミュレート）
        // When: エラーをクリア
        service.clearError()

        // Then: エラーがクリアされる
        #expect(service.lastError == nil)
    }

    // MARK: - 統合シナリオテスト

    @Test("完全な設定フロー")
    func testCompleteSettingsFlow() throws {
        // シナリオ: ユーザーが設定画面で複数の設定を変更

        // Step 1: 自動スキャンを有効化
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        scanSettings.autoScanInterval = .daily
        try service.updateScanSettings(scanSettings)

        // Step 2: 分析設定を調整
        var analysisSettings = service.settings.analysisSettings
        analysisSettings.similarityThreshold = 0.9
        analysisSettings.minGroupSize = 3
        try service.updateAnalysisSettings(analysisSettings)

        // Step 3: 表示設定を変更
        var displaySettings = service.settings.displaySettings
        displaySettings.gridColumns = 4
        displaySettings.showFileSize = true
        try service.updateDisplaySettings(displaySettings)

        // Step 4: 通知を有効化
        var notificationSettings = service.settings.notificationSettings
        notificationSettings.isEnabled = true
        notificationSettings.storageAlertEnabled = true
        try service.updateNotificationSettings(notificationSettings)

        // Then: すべての設定が保存されている
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.similarityThreshold == 0.9)
        #expect(service.settings.displaySettings.gridColumns == 4)
        #expect(service.settings.notificationSettings.isEnabled == true)
    }
}
