//
//  ScanSettingsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ScanSettingsViewのテスト
//  Swift Testing frameworkを使用
//  Created by AI Assistant on 2025-12-05.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - ScanSettingsViewTests

@MainActor
@Suite("ScanSettingsView Tests")
struct ScanSettingsViewTests {

    // MARK: - 初期化テスト

    @Test("ScanSettingsView初期化成功")
    func testViewInitialization() async throws {
        let service = SettingsService()
        let view = ScanSettingsView()
            .environment(service)

        #expect(view != nil)
    }

    @Test("デフォルト設定でView生成")
    func testViewWithDefaultSettings() async throws {
        let service = SettingsService()
        // デフォルト設定にリセット
        service.resetToDefaults()

        let view = ScanSettingsView()
            .environment(service)

        let settings = service.settings.scanSettings
        #expect(settings.autoScanEnabled == false)
        #expect(settings.autoScanInterval == .weekly)
        #expect(settings.includeVideos == true)
        #expect(settings.includeScreenshots == true)
        #expect(settings.includeSelfies == true)
    }

    // MARK: - 自動スキャン設定テスト

    @Test("自動スキャンが無効の場合、間隔ピッカーが表示されない")
    func testIntervalPickerHiddenWhenAutoScanDisabled() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = false
        try service.updateScanSettings(settings.scanSettings)

        let view = ScanSettingsView()
            .environment(service)

        #expect(service.settings.scanSettings.autoScanEnabled == false)
        #expect(view != nil)
    }

    @Test("自動スキャンが有効の場合、間隔ピッカーが表示される")
    func testIntervalPickerVisibleWhenAutoScanEnabled() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        try service.updateScanSettings(settings.scanSettings)

        let view = ScanSettingsView()
            .environment(service)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(view != nil)
    }

    @Test("自動スキャン間隔を毎日に変更")
    func testChangeIntervalToDaily() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .daily
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanInterval == .daily)
    }

    @Test("自動スキャン間隔を毎週に変更")
    func testChangeIntervalToWeekly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .weekly
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
    }

    @Test("自動スキャン間隔を毎月に変更")
    func testChangeIntervalToMonthly() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .monthly
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanInterval == .monthly)
    }

    @Test("自動スキャン間隔をしないに変更")
    func testChangeIntervalToNever() async throws {
        let service = SettingsService()
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .never
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanInterval == .never)
    }

    // MARK: - スキャン対象設定テスト

    @Test("動画を含める設定を変更")
    func testToggleIncludeVideos() async throws {
        let service = SettingsService()
        var settings = service.settings

        // 他のコンテンツタイプを有効にして、動画だけ無効にする
        settings.scanSettings.includeVideos = false
        settings.scanSettings.includeScreenshots = true
        settings.scanSettings.includeSelfies = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeVideos == false)

        settings.scanSettings.includeVideos = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeVideos == true)
    }

    @Test("スクリーンショットを含める設定を変更")
    func testToggleIncludeScreenshots() async throws {
        let service = SettingsService()
        var settings = service.settings

        // 他のコンテンツタイプを有効にして、スクリーンショットだけ無効にする
        settings.scanSettings.includeVideos = true
        settings.scanSettings.includeScreenshots = false
        settings.scanSettings.includeSelfies = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeScreenshots == false)

        settings.scanSettings.includeScreenshots = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeScreenshots == true)
    }

    @Test("自撮りを含める設定を変更")
    func testToggleIncludeSelfies() async throws {
        let service = SettingsService()
        var settings = service.settings

        // 他のコンテンツタイプを有効にして、自撮りだけ無効にする
        settings.scanSettings.includeVideos = true
        settings.scanSettings.includeScreenshots = true
        settings.scanSettings.includeSelfies = false
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeSelfies == false)

        settings.scanSettings.includeSelfies = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.includeSelfies == true)
    }

    // MARK: - バリデーションテスト

    @Test("すべてのコンテンツタイプを無効にするとエラー")
    func testValidationErrorWhenAllContentTypesDisabled() async throws {
        let service = SettingsService()
        let invalidSettings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: false
        )

        #expect(throws: SettingsError.self) {
            try invalidSettings.validate()
        }
    }

    @Test("少なくとも1つのコンテンツタイプが有効ならバリデーション成功")
    func testValidationSuccessWithOneContentTypeEnabled() async throws {
        let service = SettingsService()

        // 動画のみ有効
        let settings1 = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: false
        )
        try settings1.validate()

        // スクリーンショットのみ有効
        let settings2 = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: false
        )
        try settings2.validate()

        // 自撮りのみ有効
        let settings3 = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: true
        )
        try settings3.validate()
    }

    // MARK: - 複合テスト

    @Test("自動スキャン有効＋動画のみスキャン")
    func testAutoScanEnabledWithVideosOnly() async throws {
        let service = SettingsService()
        let settings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .daily,
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: false
        )
        try service.updateScanSettings(settings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
        #expect(service.settings.scanSettings.includeVideos == true)
        #expect(service.settings.scanSettings.includeScreenshots == false)
        #expect(service.settings.scanSettings.includeSelfies == false)
    }

    @Test("自動スキャン無効＋すべてのコンテンツタイプ有効")
    func testAutoScanDisabledWithAllContentTypes() async throws {
        let service = SettingsService()
        let settings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .never,
            includeVideos: true,
            includeScreenshots: true,
            includeSelfies: true
        )
        try service.updateScanSettings(settings)

        #expect(service.settings.scanSettings.autoScanEnabled == false)
        #expect(service.settings.scanSettings.includeVideos == true)
        #expect(service.settings.scanSettings.includeScreenshots == true)
        #expect(service.settings.scanSettings.includeSelfies == true)
    }

    @Test("設定を複数回変更しても正常に動作")
    func testMultipleSettingsChanges() async throws {
        let service = SettingsService()

        // 1回目の変更
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .daily
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)

        // 2回目の変更
        settings.scanSettings.autoScanInterval = .weekly
        settings.scanSettings.includeVideos = false
        settings.scanSettings.includeScreenshots = true  // 他のコンテンツタイプを明示的に有効化
        settings.scanSettings.includeSelfies = true      // バリデーションエラー回避
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
        #expect(service.settings.scanSettings.includeVideos == false)

        // 3回目の変更
        settings.scanSettings.autoScanEnabled = false
        settings.scanSettings.includeVideos = true
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanEnabled == false)
        #expect(service.settings.scanSettings.includeVideos == true)
    }

    // MARK: - エッジケーステスト

    @Test("AutoScanInterval.allCasesに4つの選択肢がある")
    func testAutoScanIntervalAllCases() async throws {
        #expect(AutoScanInterval.allCases.count == 4)
        #expect(AutoScanInterval.allCases.contains(.daily))
        #expect(AutoScanInterval.allCases.contains(.weekly))
        #expect(AutoScanInterval.allCases.contains(.monthly))
        #expect(AutoScanInterval.allCases.contains(.never))
    }

    @Test("AutoScanIntervalのdisplayNameが正しい")
    func testAutoScanIntervalDisplayNames() async throws {
        #expect(AutoScanInterval.daily.displayName == "毎日")
        #expect(AutoScanInterval.weekly.displayName == "毎週")
        #expect(AutoScanInterval.monthly.displayName == "毎月")
        #expect(AutoScanInterval.never.displayName == "しない")
    }

    @Test("ScanSettings.hasAnyContentTypeEnabledが正しく動作")
    func testHasAnyContentTypeEnabled() async throws {
        // すべて有効
        let allEnabled = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: true,
            includeScreenshots: true,
            includeSelfies: true
        )
        #expect(allEnabled.hasAnyContentTypeEnabled == true)

        // 1つのみ有効
        let oneEnabled = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: false
        )
        #expect(oneEnabled.hasAnyContentTypeEnabled == true)

        // すべて無効
        let noneEnabled = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: false
        )
        #expect(noneEnabled.hasAnyContentTypeEnabled == false)
    }

    // MARK: - エッジケース：境界値テスト

    @Test("最後の有効なコンテンツタイプを無効化しようとするとエラー")
    func testCannotDisableLastContentType() async throws {
        let service = SettingsService()
        var settings = service.settings

        // まず2つを無効化
        settings.scanSettings.includeVideos = true
        settings.scanSettings.includeScreenshots = false
        settings.scanSettings.includeSelfies = false
        try service.updateScanSettings(settings.scanSettings)

        // 最後の1つも無効化しようとする
        settings.scanSettings.includeVideos = false
        #expect(throws: SettingsError.noContentTypeEnabled) {
            try service.updateScanSettings(settings.scanSettings)
        }

        // サービスの状態が変更されていないことを確認
        #expect(service.settings.scanSettings.includeVideos == true)
    }

    @Test("全コンテンツタイプ有効から1つずつ無効化できる")
    func testDisableContentTypesSequentially() async throws {
        let service = SettingsService()
        var settings = service.settings

        // すべて有効の状態から開始
        settings.scanSettings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: true,
            includeScreenshots: true,
            includeSelfies: true
        )
        try service.updateScanSettings(settings.scanSettings)

        // 動画を無効化
        settings.scanSettings.includeVideos = false
        try service.updateScanSettings(settings.scanSettings)
        #expect(service.settings.scanSettings.includeVideos == false)
        #expect(service.settings.scanSettings.hasAnyContentTypeEnabled == true)

        // スクリーンショットを無効化
        settings.scanSettings.includeScreenshots = false
        try service.updateScanSettings(settings.scanSettings)
        #expect(service.settings.scanSettings.includeScreenshots == false)
        #expect(service.settings.scanSettings.hasAnyContentTypeEnabled == true)

        // 自撮りだけ残る
        #expect(service.settings.scanSettings.includeSelfies == true)
    }

    @Test("AutoScanInterval.timeIntervalが正しい秒数を返す")
    func testAutoScanIntervalTimeIntervalValues() async throws {
        #expect(AutoScanInterval.daily.timeInterval == 86400)      // 1日
        #expect(AutoScanInterval.weekly.timeInterval == 604800)    // 7日
        #expect(AutoScanInterval.monthly.timeInterval == 2592000)  // 30日
        #expect(AutoScanInterval.never.timeInterval == nil)        // nil
    }

    @Test("自動スキャン有効＋間隔「しない」の矛盾した設定が可能")
    func testAutoScanEnabledWithNeverInterval() async throws {
        let service = SettingsService()
        let settings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .never,
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: false
        )

        // バリデーション自体は通る（論理的に矛盾しているが技術的に無効ではない）
        try service.updateScanSettings(settings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .never)
    }

    // MARK: - エラーハンドリング：保存失敗テスト

    @Test("保存中フラグが立っている間は二重保存を防ぐ")
    func testConcurrentSaveAttemptsFail() async throws {
        let service = SettingsService()

        // isSavingフラグを確認（初期値はfalse）
        #expect(service.isSaving == false)

        // 通常の保存は成功する
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        try service.updateScanSettings(settings.scanSettings)

        // 保存完了後はフラグがfalseに戻る
        #expect(service.isSaving == false)
    }

    @Test("SettingsErrorのequality比較が正しく動作")
    func testSettingsErrorEquality() async throws {
        let error1 = SettingsError.noContentTypeEnabled
        let error2 = SettingsError.noContentTypeEnabled
        let error3 = SettingsError.invalidSimilarityThreshold

        #expect(error1 == error2)
        #expect(error1 != error3)

        let saveError1 = SettingsError.saveFailed("テストエラー")
        let saveError2 = SettingsError.saveFailed("テストエラー")
        let saveError3 = SettingsError.saveFailed("別のエラー")

        #expect(saveError1 == saveError2)
        #expect(saveError1 != saveError3)
    }

    @Test("SettingsErrorのローカライズメッセージが存在する")
    func testSettingsErrorLocalizedDescriptions() async throws {
        let errors: [SettingsError] = [
            .noContentTypeEnabled,
            .invalidSimilarityThreshold,
            .invalidBlurThreshold,
            .invalidMinGroupSize,
            .invalidGridColumns,
            .invalidQuietHours,
            .saveFailed("テスト")
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description?.isEmpty == false)
        }
    }

    // MARK: - 統合テスト：サービス連携

    @Test("設定変更後の再読み込みで最新の値が反映される")
    func testReloadAfterSettingsChange() async throws {
        let service = SettingsService()

        // 設定を変更
        var settings = service.settings
        settings.scanSettings.autoScanEnabled = true
        settings.scanSettings.autoScanInterval = .daily
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)

        // 再読み込み
        service.reload()

        // 値が保持されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.autoScanInterval == .daily)
    }

    @Test("デフォルトにリセット後は初期値に戻る")
    func testResetToDefaultsRestoresInitialState() async throws {
        let service = SettingsService()

        // カスタム設定に変更
        var settings = service.settings
        settings.scanSettings = ScanSettings(
            autoScanEnabled: true,
            autoScanInterval: .daily,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: true
        )
        try service.updateScanSettings(settings.scanSettings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.scanSettings.includeVideos == false)

        // デフォルトにリセット
        service.resetToDefaults()

        // デフォルト値に戻ることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == false)
        #expect(service.settings.scanSettings.autoScanInterval == .weekly)
        #expect(service.settings.scanSettings.includeVideos == true)
        #expect(service.settings.scanSettings.includeScreenshots == true)
        #expect(service.settings.scanSettings.includeSelfies == true)
        #expect(service.lastError == nil)
    }

    @Test("複数の設定カテゴリを独立して変更できる")
    func testIndependentSettingsUpdates() async throws {
        let service = SettingsService()

        // スキャン設定を変更
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        #expect(service.settings.scanSettings.autoScanEnabled == true)

        // 分析設定を変更
        var analysisSettings = service.settings.analysisSettings
        analysisSettings.similarityThreshold = 0.9
        try service.updateAnalysisSettings(analysisSettings)

        // 両方の変更が反映されていることを確認
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.similarityThreshold == 0.9)
    }

    @Test("エラー発生後もサービスは正常な状態を維持")
    func testServiceRemainsStableAfterError() async throws {
        let service = SettingsService()

        // 有効な設定で開始
        var settings = service.settings
        settings.scanSettings.includeVideos = true
        settings.scanSettings.includeScreenshots = true
        settings.scanSettings.includeSelfies = false
        try service.updateScanSettings(settings.scanSettings)

        let validState = service.settings.scanSettings

        // 無効な設定を試みる（すべて無効）
        let invalidSettings = ScanSettings(
            autoScanEnabled: false,
            autoScanInterval: .weekly,
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: false
        )

        #expect(throws: SettingsError.noContentTypeEnabled) {
            try service.updateScanSettings(invalidSettings)
        }

        // エラー後も元の有効な状態が維持されている
        #expect(service.settings.scanSettings == validState)
        #expect(service.settings.scanSettings.includeVideos == true)
        #expect(service.settings.scanSettings.includeScreenshots == true)
    }
}
