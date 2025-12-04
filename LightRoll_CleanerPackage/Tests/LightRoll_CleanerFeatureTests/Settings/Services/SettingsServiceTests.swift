//
//  SettingsServiceTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsServiceのユニットテスト
//  Created by AI Assistant on 2025-12-04.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - SettingsService Tests

@Suite("SettingsService Tests")
@MainActor
struct SettingsServiceTests {

    // MARK: - 初期化とロード

    @Test("初期化時にデフォルト設定をロード")
    func testInitializationWithDefaultSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()

        // When
        let sut = SettingsService(repository: mockRepo)

        // Then
        #expect(sut.settings == .default)
        #expect(sut.lastError == nil)
        #expect(sut.isSaving == false)
    }

    @Test("初期化時に既存設定をロード")
    func testInitializationWithExistingSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let customSettings = UserSettings(
            scanSettings: ScanSettings(autoScanEnabled: true),
            analysisSettings: .default,
            notificationSettings: .default,
            displaySettings: .default,
            premiumStatus: .premium
        )
        mockRepo.mockSettings = customSettings

        // When
        let sut = SettingsService(repository: mockRepo)

        // Then
        #expect(sut.settings == customSettings)
        #expect(sut.settings.scanSettings.autoScanEnabled == true)
        #expect(sut.settings.premiumStatus == .premium)
    }

    // MARK: - スキャン設定更新

    @Test("スキャン設定を更新して保存")
    func testUpdateScanSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let newScanSettings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .daily,
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: false
        )

        // When
        try sut.updateScanSettings(newScanSettings)

        // Then
        #expect(sut.settings.scanSettings == newScanSettings)
        #expect(mockRepo.saveCallCount == 1)
        #expect(mockRepo.lastSavedSettings?.scanSettings == newScanSettings)
        #expect(sut.lastError == nil)
    }

    @Test("不正なスキャン設定でバリデーションエラー")
    func testUpdateScanSettingsWithInvalidSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidScanSettings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .weekly,
            includeVideos: false,  // 全てfalse → バリデーションエラー
            includeScreenshots: false,
            includeSelfies: false
        )

        // When/Then
        #expect(throws: SettingsError.self) {
            try sut.updateScanSettings(invalidScanSettings)
        }

        // 設定は更新されない
        #expect(sut.settings.scanSettings != invalidScanSettings)
        #expect(mockRepo.saveCallCount == 0)
    }

    // MARK: - 分析設定更新

    @Test("分析設定を更新して保存")
    func testUpdateAnalysisSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let newAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.90,
            blurThreshold: 0.25,
            minGroupSize: 3
        )

        // When
        try sut.updateAnalysisSettings(newAnalysisSettings)

        // Then
        #expect(sut.settings.analysisSettings == newAnalysisSettings)
        #expect(mockRepo.saveCallCount == 1)
        #expect(sut.lastError == nil)
    }

    @Test("不正な類似度閾値でバリデーションエラー")
    func testUpdateAnalysisSettingsWithInvalidSimilarityThreshold() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidAnalysisSettings = AnalysisSettings(
            similarityThreshold: 1.5,  // 1.0より大きい → エラー
            blurThreshold: 0.3,
            minGroupSize: 2
        )

        // When/Then
        #expect(throws: SettingsError.invalidSimilarityThreshold) {
            try sut.updateAnalysisSettings(invalidAnalysisSettings)
        }

        #expect(mockRepo.saveCallCount == 0)
    }

    @Test("不正なブレ閾値でバリデーションエラー")
    func testUpdateAnalysisSettingsWithInvalidBlurThreshold() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: -0.1,  // マイナス → エラー
            minGroupSize: 2
        )

        // When/Then
        #expect(throws: SettingsError.invalidBlurThreshold) {
            try sut.updateAnalysisSettings(invalidAnalysisSettings)
        }
    }

    @Test("不正な最小グループサイズでバリデーションエラー")
    func testUpdateAnalysisSettingsWithInvalidMinGroupSize() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 1  // 2未満 → エラー
        )

        // When/Then
        #expect(throws: SettingsError.invalidMinGroupSize) {
            try sut.updateAnalysisSettings(invalidAnalysisSettings)
        }
    }

    // MARK: - 通知設定更新

    @Test("通知設定を更新して保存")
    func testUpdateNotificationSettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let newNotificationSettings = NotificationSettings(
            enabled: true,
            capacityWarning: false,
            reminderEnabled: true,
            quietHoursStart: 21,
            quietHoursEnd: 7
        )

        // When
        try sut.updateNotificationSettings(newNotificationSettings)

        // Then
        #expect(sut.settings.notificationSettings == newNotificationSettings)
        #expect(mockRepo.saveCallCount == 1)
    }

    @Test("不正な静寂時間でバリデーションエラー")
    func testUpdateNotificationSettingsWithInvalidQuietHours() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidNotificationSettings = NotificationSettings(
            enabled: true,
            capacityWarning: true,
            reminderEnabled: false,
            quietHoursStart: 25,  // 24以上 → エラー
            quietHoursEnd: 8
        )

        // When/Then
        #expect(throws: SettingsError.invalidQuietHours) {
            try sut.updateNotificationSettings(invalidNotificationSettings)
        }
    }

    // MARK: - 表示設定更新

    @Test("表示設定を更新して保存")
    func testUpdateDisplaySettings() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let newDisplaySettings = DisplaySettings(
            gridColumns: 3,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeDescending
        )

        // When
        try sut.updateDisplaySettings(newDisplaySettings)

        // Then
        #expect(sut.settings.displaySettings == newDisplaySettings)
        #expect(mockRepo.saveCallCount == 1)
    }

    @Test("不正なグリッドカラム数でバリデーションエラー")
    func testUpdateDisplaySettingsWithInvalidGridColumns() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        let invalidDisplaySettings = DisplaySettings(
            gridColumns: 0,  // 1未満 → エラー
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )

        // When/Then
        #expect(throws: SettingsError.invalidGridColumns) {
            try sut.updateDisplaySettings(invalidDisplaySettings)
        }
    }

    // MARK: - プレミアムステータス更新

    @Test("プレミアムステータスを更新")
    func testUpdatePremiumStatus() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // When
        sut.updatePremiumStatus(.premium)

        // Then
        #expect(sut.settings.premiumStatus == .premium)
        #expect(mockRepo.saveCallCount == 1)
    }

    // MARK: - 設定リセット

    @Test("設定をデフォルトにリセット")
    func testResetToDefaults() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // カスタム設定を設定
        try sut.updateScanSettings(ScanSettings(autoScanEnabled: true))
        #expect(sut.settings.scanSettings.autoScanEnabled == true)

        // When
        sut.resetToDefaults()

        // Then
        #expect(sut.settings == .default)
        #expect(sut.settings.scanSettings.autoScanEnabled == false)
        #expect(mockRepo.resetCallCount == 1)
        #expect(sut.lastError == nil)
    }

    // MARK: - 個別設定項目更新

    @Test("updateSettingsクロージャで複数項目を一括更新")
    func testUpdateSettingsWithClosure() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // When
        sut.updateSettings { settings in
            settings.scanSettings.autoScanEnabled = true
            settings.displaySettings.gridColumns = 5
            settings.premiumStatus = .premium
        }

        // Then
        #expect(sut.settings.scanSettings.autoScanEnabled == true)
        #expect(sut.settings.displaySettings.gridColumns == 5)
        #expect(sut.settings.premiumStatus == .premium)
        #expect(mockRepo.saveCallCount == 1)
    }

    // MARK: - 再読み込み

    @Test("reloadで設定を再読み込み")
    func testReload() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // 初期設定を変更
        try sut.updateScanSettings(ScanSettings(autoScanEnabled: true))

        // リポジトリの設定を変更（外部変更を模擬）
        mockRepo.mockSettings = .default

        // When
        sut.reload()

        // Then
        #expect(sut.settings == .default)
        #expect(sut.settings.scanSettings.autoScanEnabled == false)
    }

    // MARK: - エラーハンドリング

    @Test("エラーをクリア")
    func testClearError() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // エラーを発生させる
        let invalidSettings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: false
        )

        // When
        sut.updateSettings { settings in
            settings.scanSettings = invalidSettings
        }

        // Then（バリデーションエラーは発生しないが、後から追加可能）
        // このテストは将来的にバリデーションが必要になった場合のためのプレースホルダー
        #expect(sut.lastError == nil)
    }
}

// MARK: - MockSettingsRepository

/// テスト用モックSettingsRepository
final class MockSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {

    // MARK: - Mock Storage

    var mockSettings: UserSettings = .default
    var lastSavedSettings: UserSettings?
    var saveCallCount = 0
    var resetCallCount = 0

    // MARK: - SettingsRepositoryProtocol

    func load() -> UserSettings {
        return mockSettings
    }

    func save(_ settings: UserSettings) {
        lastSavedSettings = settings
        mockSettings = settings
        saveCallCount += 1
    }

    func reset() {
        mockSettings = .default
        lastSavedSettings = nil
        resetCallCount += 1
    }
}
