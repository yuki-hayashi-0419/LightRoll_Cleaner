//
//  UserSettingsTests.swift
//  LightRoll_CleanerFeatureTests
//
//  Created by AI Assistant on 2025-12-04.
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// 型の曖昧性を解消（GroupListView.SortOrderと区別）
typealias SettingsSortOrder = LightRoll_CleanerFeature.SortOrder

// MARK: - UserSettings Tests

@Test("UserSettings: デフォルト値が正しく設定されている")
func userSettingsDefaultValues() {
    let settings = UserSettings.default

    #expect(settings.premiumStatus == .free)
    #expect(settings.scanSettings.autoScanEnabled == false)
    #expect(settings.analysisSettings.similarityThreshold == 0.85)
    #expect(settings.notificationSettings.isEnabled == false)
    #expect(settings.displaySettings.gridColumns == 4)
}

@Test("UserSettings: Codableエンコード/デコードが機能する")
func userSettingsCodable() throws {
    let original = UserSettings.default
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)
    #expect(original == decoded)
}

@Test("UserSettings: カスタム値でのCodable")
func userSettingsCustomCodable() throws {
    var settings = UserSettings.default
    settings.scanSettings.autoScanEnabled = true
    settings.analysisSettings.similarityThreshold = 0.9
    settings.premiumStatus = .premium()

    let encoded = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)

    #expect(decoded.scanSettings.autoScanEnabled == true)
    #expect(decoded.analysisSettings.similarityThreshold == 0.9)
    #expect(decoded.premiumStatus == .premium())
}

@Test("UserSettings: Equatable準拠の検証")
func userSettingsEquatable() {
    let settings1 = UserSettings.default
    let settings2 = UserSettings.default

    #expect(settings1 == settings2)

    var settings3 = UserSettings.default
    settings3.premiumStatus = .premium()

    #expect(settings1 != settings3)
}

// MARK: - ScanSettings Tests

@Test("ScanSettings: デフォルト値が正しい")
func scanSettingsDefaults() {
    let settings = ScanSettings.default

    #expect(settings.autoScanEnabled == false)
    #expect(settings.autoScanInterval == .weekly)
    #expect(settings.includeVideos == true)
    #expect(settings.includeScreenshots == true)
    #expect(settings.includeSelfies == true)
}

@Test("ScanSettings: hasAnyContentTypeEnabled - すべて有効")
func scanSettingsAllEnabled() {
    let settings = ScanSettings.default
    #expect(settings.hasAnyContentTypeEnabled == true)
}

@Test("ScanSettings: hasAnyContentTypeEnabled - すべて無効")
func scanSettingsAllDisabled() {
    var settings = ScanSettings.default
    settings.includeVideos = false
    settings.includeScreenshots = false
    settings.includeSelfies = false

    #expect(settings.hasAnyContentTypeEnabled == false)
}

@Test("ScanSettings: バリデーション - 正常系")
func scanSettingsValidation() throws {
    let settings = ScanSettings.default
    try settings.validate()
    // エラーが発生しないことを確認
}

@Test("ScanSettings: バリデーション - コンテンツタイプすべて無効")
func scanSettingsValidationNoContent() {
    var settings = ScanSettings.default
    settings.includeVideos = false
    settings.includeScreenshots = false
    settings.includeSelfies = false

    #expect(throws: SettingsError.noContentTypeEnabled) {
        try settings.validate()
    }
}

@Test("ScanSettings: Codableが機能する")
func scanSettingsCodable() throws {
    let original = ScanSettings.default
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ScanSettings.self, from: encoded)
    #expect(original == decoded)
}

// MARK: - AnalysisSettings Tests

@Test("AnalysisSettings: デフォルト値が正しい")
func analysisSettingsDefaults() {
    let settings = AnalysisSettings.default

    #expect(settings.similarityThreshold == 0.85)
    #expect(settings.blurThreshold == 0.3)
    #expect(settings.minGroupSize == 2)
}

@Test("AnalysisSettings: バリデーション - 正常系")
func analysisSettingsValidation() throws {
    let settings = AnalysisSettings.default
    try settings.validate()
    // エラーが発生しないことを確認
}

@Test("AnalysisSettings: バリデーション - 類似度閾値が範囲外",
      arguments: [-0.1, 1.1, 2.0])
func analysisSettingsInvalidSimilarityThreshold(threshold: Float) {
    var settings = AnalysisSettings.default
    settings.similarityThreshold = threshold

    #expect(throws: SettingsError.invalidSimilarityThreshold) {
        try settings.validate()
    }
}

@Test("AnalysisSettings: バリデーション - ブレ閾値が範囲外",
      arguments: [-0.1, 1.1, 2.0])
func analysisSettingsInvalidBlurThreshold(threshold: Float) {
    var settings = AnalysisSettings.default
    settings.blurThreshold = threshold

    #expect(throws: SettingsError.invalidBlurThreshold) {
        try settings.validate()
    }
}

@Test("AnalysisSettings: バリデーション - 最小グループサイズが無効",
      arguments: [0, 1, -1])
func analysisSettingsInvalidMinGroupSize(size: Int) {
    var settings = AnalysisSettings.default
    settings.minGroupSize = size

    #expect(throws: SettingsError.invalidMinGroupSize) {
        try settings.validate()
    }
}

@Test("AnalysisSettings: バリデーション - 境界値テスト（有効）")
func analysisSettingsBoundaryValid() throws {
    var settings = AnalysisSettings.default

    // 類似度閾値の境界値（有効）
    settings.similarityThreshold = 0.0
    try settings.validate()

    settings.similarityThreshold = 1.0
    try settings.validate()

    // ブレ閾値の境界値（有効）
    settings.blurThreshold = 0.0
    try settings.validate()

    settings.blurThreshold = 1.0
    try settings.validate()

    // 最小グループサイズの境界値（有効）
    settings.minGroupSize = 2
    try settings.validate()
}

@Test("AnalysisSettings: Codableが機能する")
func analysisSettingsCodable() throws {
    let original = AnalysisSettings.default
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AnalysisSettings.self, from: encoded)
    #expect(original == decoded)
}

// MARK: - NotificationSettings Tests

// NotificationSettingsのテストはNotificationSettingsTests.swiftに移動しました

// MARK: - DisplaySettings Tests

@Test("DisplaySettings: デフォルト値が正しい")
func displaySettingsDefaults() {
    let settings = DisplaySettings.default

    #expect(settings.gridColumns == 4)
    #expect(settings.showFileSize == true)
    #expect(settings.showDate == true)
    #expect(settings.sortOrder == .dateDescending)
}

@Test("DisplaySettings: バリデーション - 正常系")
func displaySettingsValidation() throws {
    let settings = DisplaySettings.default
    try settings.validate()
}

@Test("DisplaySettings: バリデーション - グリッドカラムが範囲外",
      arguments: [0, 7, 10])
func displaySettingsInvalidGridColumns(columns: Int) {
    var settings = DisplaySettings.default
    settings.gridColumns = columns

    #expect(throws: SettingsError.invalidGridColumns) {
        try settings.validate()
    }
}

@Test("DisplaySettings: バリデーション - 境界値テスト（有効）")
func displaySettingsBoundaryValid() throws {
    var settings = DisplaySettings.default

    // グリッドカラムの境界値（有効）
    settings.gridColumns = 1
    try settings.validate()

    settings.gridColumns = 6
    try settings.validate()
}

@Test("DisplaySettings: Codableが機能する")
func displaySettingsCodable() throws {
    let original = DisplaySettings.default
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(DisplaySettings.self, from: encoded)
    #expect(original == decoded)
}

// MARK: - SortOrder Tests

@Test("SortOrder: すべてのケースがCodableである")
func sortOrderCodable() throws {
    for order in SettingsSortOrder.allCases {
        let encoded = try JSONEncoder().encode(order)
        let decoded = try JSONDecoder().decode(SettingsSortOrder.self, from: encoded)
        #expect(decoded == order)
    }
}

@Test("SortOrder: displayNameプロパティが正しい")
func sortOrderDisplayName() {
    #expect(SettingsSortOrder.dateDescending.displayName == "新しい順")
    #expect(SettingsSortOrder.dateAscending.displayName == "古い順")
    #expect(SettingsSortOrder.sizeDescending.displayName == "容量大きい順")
    #expect(SettingsSortOrder.sizeAscending.displayName == "容量小さい順")
}

@Test("SortOrder: allCasesに全ケースが含まれる")
func sortOrderAllCases() {
    #expect(SettingsSortOrder.allCases.count == 4)
    #expect(SettingsSortOrder.allCases.contains(.dateDescending))
    #expect(SettingsSortOrder.allCases.contains(.dateAscending))
    #expect(SettingsSortOrder.allCases.contains(.sizeDescending))
    #expect(SettingsSortOrder.allCases.contains(.sizeAscending))
}

// MARK: - AutoScanInterval Tests

@Test("AutoScanInterval: すべてのケースがCodableである")
func autoScanIntervalCodable() throws {
    for interval in AutoScanInterval.allCases {
        let encoded = try JSONEncoder().encode(interval)
        let decoded = try JSONDecoder().decode(AutoScanInterval.self, from: encoded)
        #expect(decoded == interval)
    }
}

@Test("AutoScanInterval: timeIntervalプロパティが正しい")
func autoScanIntervalTimeInterval() {
    #expect(AutoScanInterval.daily.timeInterval == 86400)
    #expect(AutoScanInterval.weekly.timeInterval == 604800)
    #expect(AutoScanInterval.monthly.timeInterval == 2592000)
    #expect(AutoScanInterval.never.timeInterval == nil)
}

@Test("AutoScanInterval: displayNameプロパティが正しい")
func autoScanIntervalDisplayName() {
    #expect(AutoScanInterval.daily.displayName == "毎日")
    #expect(AutoScanInterval.weekly.displayName == "毎週")
    #expect(AutoScanInterval.monthly.displayName == "毎月")
    #expect(AutoScanInterval.never.displayName == "しない")
}

// MARK: - PremiumStatus Tests

@Test("PremiumStatus: すべてのケースがCodableである")
func premiumStatusCodable() throws {
    for status in [PremiumStatus.free, PremiumStatus.premium()] {
        let encoded = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(PremiumStatus.self, from: encoded)
        #expect(decoded == status)
    }
}

@Test("PremiumStatus: isFreeプロパティが正しい")
func premiumStatusIsFree() {
    #expect(PremiumStatus.free.isFree == true)
    #expect(PremiumStatus.premium().isFree == false)
}

@Test("PremiumStatus: isPremiumプロパティが正しい")
func premiumStatusIsPremium() {
    #expect(PremiumStatus.free.isPremium == false)
    #expect(PremiumStatus.premium().isPremium == true)
}

@Test("PremiumStatus: displayNameプロパティが正しい")
func premiumStatusDisplayName() {
    #expect(PremiumStatus.free.statusText == "無料版")
    #expect(PremiumStatus.premium().statusText.contains("月額プラン"))
}

// MARK: - SettingsError Tests

@Test("SettingsError: LocalizedErrorが機能する")
func settingsErrorLocalized() {
    let errors: [SettingsError] = [
        .invalidSimilarityThreshold,
        .invalidBlurThreshold,
        .invalidMinGroupSize,
        .invalidGridColumns,
        .invalidQuietHours,
        .noContentTypeEnabled
    ]

    for error in errors {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }
}

@Test("SettingsError: エラーメッセージが日本語である")
func settingsErrorJapanese() {
    #expect(SettingsError.invalidSimilarityThreshold.errorDescription == "類似度閾値は0.0〜1.0の範囲で指定してください。")
    #expect(SettingsError.invalidBlurThreshold.errorDescription == "ブレ閾値は0.0〜1.0の範囲で指定してください。")
    #expect(SettingsError.invalidMinGroupSize.errorDescription == "最小グループサイズは2以上を指定してください。")
    #expect(SettingsError.invalidGridColumns.errorDescription == "グリッドカラム数は1〜6の範囲で指定してください。")
    #expect(SettingsError.invalidQuietHours.errorDescription == "静寂時間は0〜23の範囲で指定してください。")
    #expect(SettingsError.noContentTypeEnabled.errorDescription == "少なくとも1つのコンテンツタイプを有効にしてください。")
}

// MARK: - Integration Tests

@Test("統合: UserSettingsの完全なCodableサイクル")
func integrationUserSettingsFullCodable() throws {
    var settings = UserSettings.default

    // すべての設定をカスタマイズ
    settings.scanSettings.autoScanEnabled = true
    settings.scanSettings.autoScanInterval = .daily
    settings.analysisSettings.similarityThreshold = 0.9
    settings.notificationSettings.isEnabled = true
    settings.displaySettings.gridColumns = 3
    settings.displaySettings.sortOrder = .sizeDescending
    settings.premiumStatus = .premium()

    // エンコード/デコード
    let encoded = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)

    // すべてのフィールドが保持されていることを確認
    #expect(decoded.scanSettings.autoScanEnabled == true)
    #expect(decoded.scanSettings.autoScanInterval == .daily)
    #expect(decoded.analysisSettings.similarityThreshold == 0.9)
    #expect(decoded.notificationSettings.isEnabled == true)
    #expect(decoded.displaySettings.gridColumns == 3)
    #expect(decoded.displaySettings.sortOrder == .sizeDescending)
    #expect(decoded.premiumStatus == .premium())
}

@Test("統合: すべてのサブ設定のバリデーション")
func integrationAllValidations() throws {
    let settings = UserSettings.default

    // すべてのバリデーションが成功することを確認
    try settings.scanSettings.validate()
    try settings.analysisSettings.validate()
    // NotificationSettings.isValidを使用してバリデーション
    #expect(settings.notificationSettings.isValid == true)
    try settings.displaySettings.validate()
}
