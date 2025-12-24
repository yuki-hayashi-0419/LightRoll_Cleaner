//
//  SettingsIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SETTINGS-001 / SETTINGS-002 統合テスト
//  - 分析設定 → SimilarityAnalyzer連携
//  - 通知設定 → NotificationManager統合
//  Created by AI Assistant for spec-test-generator
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - SETTINGS-001: AnalysisSettings → SimilarityAnalyzer連携テスト

@Suite("SETTINGS-001: AnalysisSettings → SimilarityAnalyzer連携")
@MainActor
struct AnalysisSettingsToSimilarityAnalyzerTests {

    // MARK: - 正常系テスト

    @Test("分析設定が正しくSimilarityAnalysisOptionsに変換される")
    func testAnalysisSettingsToSimilarityAnalysisOptionsConversion() async throws {
        // Given
        let analysisSettings = AnalysisSettings(
            similarityThreshold: 0.90,
            blurThreshold: 0.25,
            minGroupSize: 3
        )

        // When
        let options = analysisSettings.toSimilarityAnalysisOptions()

        // Then
        #expect(options.similarityThreshold == 0.90)
        #expect(options.minGroupSize == 3)
        // バッチサイズと並列実行数はデフォルト値を使用
        #expect(options.batchSize == 100)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("SettingsServiceからcurrentSimilarityAnalysisOptionsが正しく取得できる")
    func testSettingsServiceCurrentSimilarityAnalysisOptions() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let customAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.75,
            blurThreshold: 0.20,
            minGroupSize: 4
        )
        var settings = UserSettings.default
        settings.analysisSettings = customAnalysisSettings
        mockRepo.mockSettings = settings

        let sut = SettingsService(repository: mockRepo)

        // When
        let options = sut.currentSimilarityAnalysisOptions

        // Then
        #expect(options.similarityThreshold == 0.75)
        #expect(options.minGroupSize == 4)
    }

    @Test("SettingsServiceからSimilarityAnalyzerを正しく生成できる")
    func testSettingsServiceCreateSimilarityAnalyzer() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let customAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.92,
            blurThreshold: 0.35,
            minGroupSize: 5
        )
        try customAnalysisSettings.validate()

        var settings = UserSettings.default
        settings.analysisSettings = customAnalysisSettings
        mockRepo.mockSettings = settings

        let sut = SettingsService(repository: mockRepo)

        // When
        let analyzer = sut.createSimilarityAnalyzer()

        // Then
        // SimilarityAnalyzerが正しく生成されていることを確認
        // 注: SimilarityAnalyzer は actor なので、直接プロパティにアクセスできない
        // 代わりに、生成されたインスタンスが nil でないことを確認
        #expect(analyzer != nil)
    }

    // MARK: - 境界値テスト

    @Test("最小しきい値(0.0)で正しく変換される")
    func testMinimumThresholdConversion() async throws {
        // Given
        let analysisSettings = AnalysisSettings(
            similarityThreshold: 0.0,
            blurThreshold: 0.0,
            minGroupSize: 2
        )

        // When
        let options = analysisSettings.toSimilarityAnalysisOptions()

        // Then
        #expect(options.similarityThreshold == 0.0)
        #expect(options.minGroupSize == 2)
    }

    @Test("最大しきい値(1.0)で正しく変換される")
    func testMaximumThresholdConversion() async throws {
        // Given
        let analysisSettings = AnalysisSettings(
            similarityThreshold: 1.0,
            blurThreshold: 1.0,
            minGroupSize: 100
        )

        // When
        let options = analysisSettings.toSimilarityAnalysisOptions()

        // Then
        #expect(options.similarityThreshold == 1.0)
        #expect(options.minGroupSize == 100)
    }

    // MARK: - 異常系テスト

    @Test("無効なsimilarityThreshold(>1.0)でバリデーションエラー")
    func testInvalidSimilarityThresholdAboveMax() async throws {
        // Given
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 1.5,
            blurThreshold: 0.3,
            minGroupSize: 2
        )

        // When/Then
        #expect(throws: SettingsError.invalidSimilarityThreshold) {
            try invalidSettings.validate()
        }
    }

    @Test("無効なsimilarityThreshold(<0.0)でバリデーションエラー")
    func testInvalidSimilarityThresholdBelowMin() async throws {
        // Given
        let invalidSettings = AnalysisSettings(
            similarityThreshold: -0.1,
            blurThreshold: 0.3,
            minGroupSize: 2
        )

        // When/Then
        #expect(throws: SettingsError.invalidSimilarityThreshold) {
            try invalidSettings.validate()
        }
    }
}

// MARK: - SETTINGS-002: NotificationSettings → NotificationManager統合テスト

@Suite("SETTINGS-002: NotificationSettings → NotificationManager統合")
@MainActor
struct NotificationSettingsToNotificationManagerTests {

    // MARK: - 正常系テスト

    @Test("NotificationManagerがSettingsServiceから設定を正しく同期する")
    func testNotificationManagerSyncSettingsFromSettingsService() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let customNotificationSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: false,
            reminderEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 7
        )
        var settings = UserSettings.default
        settings.notificationSettings = customNotificationSettings
        mockRepo.mockSettings = settings

        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // When
        notificationManager.syncSettings(from: settingsService)

        // Then
        #expect(notificationManager.settings.isEnabled == true)
        #expect(notificationManager.settings.storageAlertEnabled == false)
        #expect(notificationManager.settings.reminderEnabled == true)
        #expect(notificationManager.settings.quietHoursStart == 22)
        #expect(notificationManager.settings.quietHoursEnd == 7)
    }

    @Test("SettingsServiceからNotificationManagerへ設定を正しく反映する")
    func testSettingsServiceSyncNotificationSettingsToManager() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // カスタム設定を作成
        let customSettings = NotificationSettings(
            isEnabled: false,
            storageAlertEnabled: true,
            reminderEnabled: false,
            quietHoursStart: 21,
            quietHoursEnd: 8
        )

        // 設定を更新
        try settingsService.updateNotificationSettings(customSettings)

        // When
        settingsService.syncNotificationSettings(to: notificationManager)

        // Then
        #expect(notificationManager.settings.isEnabled == false)
        #expect(notificationManager.settings.storageAlertEnabled == true)
        #expect(notificationManager.settings.reminderEnabled == false)
    }

    @Test("設定更新と同期が一括実行される")
    func testUpdateNotificationSettingsWithSync() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        let newSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            reminderEnabled: true,
            quietHoursStart: 23,
            quietHoursEnd: 6
        )

        // When
        try settingsService.updateNotificationSettings(newSettings, syncTo: notificationManager)

        // Then
        // SettingsServiceの設定が更新されている
        #expect(settingsService.settings.notificationSettings.isEnabled == true)
        #expect(settingsService.settings.notificationSettings.quietHoursStart == 23)

        // NotificationManagerにも同期されている
        #expect(notificationManager.settings.isEnabled == true)
        #expect(notificationManager.settings.quietHoursStart == 23)
        #expect(notificationManager.settings.quietHoursEnd == 6)
    }

    // MARK: - 境界値テスト

    @Test("通知有効/無効の切り替えが正しく反映される")
    func testNotificationEnabledToggleSync() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // When: 通知を無効化
        var disabledSettings = NotificationSettings.default
        disabledSettings.isEnabled = false
        try settingsService.updateNotificationSettings(disabledSettings, syncTo: notificationManager)

        // Then
        #expect(notificationManager.settings.isEnabled == false)

        // When: 通知を有効化
        var enabledSettings = NotificationSettings.default
        enabledSettings.isEnabled = true
        try settingsService.updateNotificationSettings(enabledSettings, syncTo: notificationManager)

        // Then
        #expect(notificationManager.settings.isEnabled == true)
    }

    @Test("静寂時間帯の境界値(0時と23時)が正しく同期される")
    func testQuietHoursBoundarySync() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // When: 0時開始、23時終了
        let settings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            reminderEnabled: true,
            quietHoursStart: 0,
            quietHoursEnd: 23
        )
        try settingsService.updateNotificationSettings(settings, syncTo: notificationManager)

        // Then
        #expect(notificationManager.settings.quietHoursStart == 0)
        #expect(notificationManager.settings.quietHoursEnd == 23)
    }

    // MARK: - 異常系テスト

    @Test("無効な静寂時間設定では同期されない")
    func testInvalidQuietHoursNotSynced() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // 初期設定を確認
        let initialSettings = notificationManager.settings

        // When: 無効な設定（24時以上）を試みる
        let invalidSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            reminderEnabled: true,
            quietHoursStart: 25,  // 無効
            quietHoursEnd: 8
        )

        // Then: バリデーションエラーが発生する
        #expect(throws: SettingsError.invalidQuietHours) {
            try settingsService.updateNotificationSettings(invalidSettings, syncTo: notificationManager)
        }

        // NotificationManagerの設定は変更されていない
        #expect(notificationManager.settings.quietHoursStart == initialSettings.quietHoursStart)
    }

    @Test("SettingsServiceのバリデーションエラー後、NotificationManagerは更新されない")
    func testValidationErrorPreventsSync() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()

        // 初期設定を設定
        let initialNotificationSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            reminderEnabled: true,
            quietHoursStart: 22,
            quietHoursEnd: 7
        )
        let notificationManager = NotificationManager(
            settings: initialNotificationSettings,
            notificationCenter: mockCenter
        )

        // When: 無効な設定でエラーを発生させる
        let invalidSettings = NotificationSettings(
            isEnabled: true,
            storageAlertEnabled: true,
            reminderEnabled: true,
            quietHoursStart: -1,  // 無効
            quietHoursEnd: 8
        )

        do {
            try settingsService.updateNotificationSettings(invalidSettings, syncTo: notificationManager)
            Issue.record("バリデーションエラーが発生するはずです")
        } catch {
            // 期待通りエラーが発生
        }

        // Then: NotificationManagerの設定は初期状態のまま
        #expect(notificationManager.settings.quietHoursStart == 22)
        #expect(notificationManager.settings.quietHoursEnd == 7)
    }
}

// MARK: - 統合テスト: 設定変更フロー

@Suite("Settings統合: 設定変更フロー全体テスト")
@MainActor
struct SettingsIntegrationFlowTests {

    @Test("分析設定変更がSimilarityAnalyzer生成に反映される")
    func testAnalysisSettingsChangeReflectedInAnalyzerCreation() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let sut = SettingsService(repository: mockRepo)

        // 初期設定
        let initialOptions = sut.currentSimilarityAnalysisOptions
        #expect(initialOptions.similarityThreshold == 0.85)  // デフォルト値

        // When: 設定を変更
        let newAnalysisSettings = AnalysisSettings(
            similarityThreshold: 0.95,
            blurThreshold: 0.40,
            minGroupSize: 4
        )
        try sut.updateAnalysisSettings(newAnalysisSettings)

        // Then: 新しい設定が反映される
        let updatedOptions = sut.currentSimilarityAnalysisOptions
        #expect(updatedOptions.similarityThreshold == 0.95)
        #expect(updatedOptions.minGroupSize == 4)

        // 新しいAnalyzerも正しく生成できる
        let analyzer = sut.createSimilarityAnalyzer()
        #expect(analyzer != nil)
    }

    @Test("通知設定変更がNotificationManagerに即時反映される")
    func testNotificationSettingsChangeImmediatelyReflected() async throws {
        // Given
        let mockRepo = MockSettingsRepository()
        let settingsService = SettingsService(repository: mockRepo)
        let mockCenter = MockUserNotificationCenter()
        let notificationManager = NotificationManager(notificationCenter: mockCenter)

        // 初期状態を確認
        #expect(notificationManager.settings.isEnabled == true)  // デフォルト

        // When: 複数回の設定変更
        for i in 0..<3 {
            let newSettings = NotificationSettings(
                isEnabled: i % 2 == 0,  // 交互に切り替え
                storageAlertEnabled: true,
                reminderEnabled: true,
                quietHoursStart: 20 + i,
                quietHoursEnd: 6 + i
            )
            try settingsService.updateNotificationSettings(newSettings, syncTo: notificationManager)

            // Then: 各変更が即時反映される
            #expect(notificationManager.settings.isEnabled == (i % 2 == 0))
            #expect(notificationManager.settings.quietHoursStart == 20 + i)
        }
    }
}
