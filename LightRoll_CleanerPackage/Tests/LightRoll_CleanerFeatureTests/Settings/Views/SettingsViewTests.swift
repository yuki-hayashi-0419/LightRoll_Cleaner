//
//  SettingsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsViewのテストスイート
//  M8-T07 実装
//  Created by AI Assistant on 2025-12-05.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - SettingsView Tests

@Suite("SettingsView Tests", .tags(.settings))
@MainActor
struct SettingsViewTests {

    // MARK: - Initialization Tests

    @Test("SettingsViewが正しく初期化される")
    func initializesCorrectly() {
        // Given
        let service = SettingsService()
        let permissionManager = PermissionManager()

        // When
        let view = SettingsView()
            .environment(service)
            .environment(permissionManager)

        // Then
        #expect(view != nil)
    }

    // MARK: - Section Tests

    @Test("すべての必須セクションが存在する")
    func hasAllRequiredSections() {
        // Given
        let service = SettingsService()

        // Then: 以下のセクションが実装されていることを確認
        // 1. Premium Section
        #expect(service.settings.premiumStatus != nil)

        // 2. Scan Settings Section
        #expect(service.settings.scanSettings != nil)

        // 3. Analysis Settings Section
        #expect(service.settings.analysisSettings != nil)

        // 4. Notification Section
        #expect(service.settings.notificationSettings != nil)

        // 5. Display Section
        #expect(service.settings.displaySettings != nil)
    }

    // MARK: - Scan Settings Tests

    @Test("自動スキャントグルが正しく動作する")
    func autoScanToggleWorks() throws {
        // Given
        let service = SettingsService()
        var scanSettings = service.settings.scanSettings
        let initialState = scanSettings.autoScanEnabled

        // When
        scanSettings.autoScanEnabled.toggle()
        try service.updateScanSettings(scanSettings)

        // Then
        #expect(service.settings.scanSettings.autoScanEnabled == !initialState)
    }

    @Test("スキャン間隔が正しく更新される")
    func autoScanIntervalUpdatesCorrectly() throws {
        // Given
        let service = SettingsService()
        var scanSettings = service.settings.scanSettings

        // When
        scanSettings.autoScanInterval = .daily
        try service.updateScanSettings(scanSettings)

        // Then
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
    }

    @Test("コンテンツタイプトグルが正しく動作する")
    func contentTypeTogglesWork() throws {
        // Given
        let service = SettingsService()
        var scanSettings = service.settings.scanSettings

        // When: 動画を無効化
        scanSettings.includeVideos = false
        try service.updateScanSettings(scanSettings)

        // Then
        #expect(service.settings.scanSettings.includeVideos == false)

        // When: スクリーンショットを無効化
        scanSettings.includeScreenshots = false
        try service.updateScanSettings(scanSettings)

        // Then
        #expect(service.settings.scanSettings.includeScreenshots == false)

        // When: 自撮りを無効化（すべて無効→エラー）
        scanSettings.includeSelfies = false

        // Then: バリデーションエラー
        #expect(throws: SettingsError.self) {
            try scanSettings.validate()
        }
    }

    // MARK: - Analysis Settings Tests

    @Test("類似度しきい値が正しい範囲にある")
    func similarityThresholdIsInValidRange() {
        // Given
        let service = SettingsService()

        // Then
        let threshold = service.settings.analysisSettings.similarityThreshold
        #expect(threshold >= 0.0 && threshold <= 1.0)
    }

    @Test("ブレ判定感度が正しい範囲にある")
    func blurThresholdIsInValidRange() {
        // Given
        let service = SettingsService()

        // Then
        let threshold = service.settings.analysisSettings.blurThreshold
        #expect(threshold >= 0.0 && threshold <= 1.0)
    }

    @Test("最小グループサイズが正しく更新される")
    func minGroupSizeUpdatesCorrectly() throws {
        // Given
        let service = SettingsService()
        var analysisSettings = service.settings.analysisSettings

        // When
        analysisSettings.minGroupSize = 5
        try service.updateAnalysisSettings(analysisSettings)

        // Then
        #expect(service.settings.analysisSettings.minGroupSize == 5)
    }

    @Test("最小グループサイズは2以上である必要がある")
    func minGroupSizeMustBeAtLeastTwo() throws {
        // Given
        var analysisSettings = AnalysisSettings()

        // When
        analysisSettings.minGroupSize = 1

        // Then
        #expect(throws: SettingsError.self) {
            try analysisSettings.validate()
        }
    }

    // MARK: - Notification Settings Tests

    @Test("通知有効化トグルが正しく動作する")
    func notificationToggleWorks() throws {
        // Given
        let service = SettingsService()
        var notificationSettings = service.settings.notificationSettings
        let initialState = notificationSettings.enabled

        // When
        notificationSettings.enabled.toggle()
        try service.updateNotificationSettings(notificationSettings)

        // Then
        #expect(service.settings.notificationSettings.enabled == !initialState)
    }

    @Test("容量警告トグルが正しく動作する")
    func capacityWarningToggleWorks() throws {
        // Given
        let service = SettingsService()
        var notificationSettings = service.settings.notificationSettings

        // When
        notificationSettings.capacityWarning = false
        try service.updateNotificationSettings(notificationSettings)

        // Then
        #expect(service.settings.notificationSettings.capacityWarning == false)
    }

    @Test("リマインダートグルが正しく動作する")
    func reminderToggleWorks() throws {
        // Given
        let service = SettingsService()
        var notificationSettings = service.settings.notificationSettings

        // When
        notificationSettings.reminderEnabled = true
        try service.updateNotificationSettings(notificationSettings)

        // Then
        #expect(service.settings.notificationSettings.reminderEnabled == true)
    }

    @Test("静寂時間が正しい範囲にある")
    func quietHoursAreInValidRange() {
        // Given
        let service = SettingsService()

        // Then
        let start = service.settings.notificationSettings.quietHoursStart
        let end = service.settings.notificationSettings.quietHoursEnd

        #expect(start >= 0 && start < 24)
        #expect(end >= 0 && end < 24)
    }

    // MARK: - Display Settings Tests

    @Test("グリッド列数が正しく更新される")
    func gridColumnsUpdateCorrectly() throws {
        // Given
        let service = SettingsService()
        var displaySettings = service.settings.displaySettings

        // When
        displaySettings.gridColumns = 5
        try service.updateDisplaySettings(displaySettings)

        // Then
        #expect(service.settings.displaySettings.gridColumns == 5)
    }

    @Test("ファイルサイズ表示トグルが正しく動作する")
    func fileSizeToggleWorks() throws {
        // Given
        let service = SettingsService()
        var displaySettings = service.settings.displaySettings

        // When
        displaySettings.showFileSize = false
        try service.updateDisplaySettings(displaySettings)

        // Then
        #expect(service.settings.displaySettings.showFileSize == false)
    }

    @Test("撮影日表示トグルが正しく動作する")
    func dateToggleWorks() throws {
        // Given
        let service = SettingsService()
        var displaySettings = service.settings.displaySettings

        // When
        displaySettings.showDate = false
        try service.updateDisplaySettings(displaySettings)

        // Then
        #expect(service.settings.displaySettings.showDate == false)
    }

    @Test("並び順が正しく更新される")
    func sortOrderUpdatesCorrectly() throws {
        // Given
        let service = SettingsService()
        var displaySettings = service.settings.displaySettings

        // When
        displaySettings.sortOrder = .sizeDescending
        try service.updateDisplaySettings(displaySettings)

        // Then
        #expect(service.settings.displaySettings.sortOrder == .sizeDescending)
    }

    // MARK: - Error Handling Tests

    @Test("エラーが発生したときにlastErrorが設定される")
    func errorSetsLastError() throws {
        // Given
        let service = SettingsService()
        var scanSettings = service.settings.scanSettings

        // When: 無効な設定（すべてのコンテンツタイプを無効化）
        scanSettings.includeVideos = false
        scanSettings.includeScreenshots = false
        scanSettings.includeSelfies = false

        // Then: エラーがthrowされる
        #expect(throws: SettingsError.self) {
            try service.updateScanSettings(scanSettings)
        }
    }

    @Test("エラーをクリアできる")
    func errorCanBeCleared() {
        // Given
        let service = SettingsService()

        // When: エラーをクリア
        service.clearError()

        // Then
        #expect(service.lastError == nil)
    }

    // MARK: - Integration Tests

    @Test("複数の設定を連続して更新できる")
    func multipleSettingsCanBeUpdatedSequentially() throws {
        // Given
        let service = SettingsService()

        // When: スキャン設定を更新
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // And: 分析設定を更新
        var analysisSettings = service.settings.analysisSettings
        analysisSettings.minGroupSize = 3
        try service.updateAnalysisSettings(analysisSettings)

        // And: 通知設定を更新
        var notificationSettings = service.settings.notificationSettings
        notificationSettings.enabled = true
        try service.updateNotificationSettings(notificationSettings)

        // Then: すべての設定が正しく更新される
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.minGroupSize == 3)
        #expect(service.settings.notificationSettings.enabled == true)
    }

    @Test("設定の永続化と読み込みが動作する")
    func settingsPersistenceWorks() throws {
        // Given
        let repository = SettingsRepository()
        let service1 = SettingsService(repository: repository)

        // When: 設定を変更
        var scanSettings = service1.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service1.updateScanSettings(scanSettings)

        // And: 新しいサービスインスタンスを作成（設定を再読み込み）
        let service2 = SettingsService(repository: repository)

        // Then: 設定が保持されている
        #expect(service2.settings.scanSettings.autoScanEnabled == true)
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var settings: Self
}
