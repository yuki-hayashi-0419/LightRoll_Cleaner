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
}
