//
//  SettingsService.swift
//  LightRoll_CleanerFeature
//
//  ユーザー設定管理・バリデーション・永続化を統合するサービス
//  MV Pattern: @Observableでビューと自動連携
//  Created by AI Assistant on 2025-12-04.
//

import Foundation
import Observation

// MARK: - SettingsService

/// ユーザー設定を管理するサービス
///
/// MV Patternに従い、ViewModelではなく@Observableサービスとして実装
/// - 設定の読み込み・保存・更新を管理
/// - バリデーションとエラーハンドリング
/// - SwiftUI Viewと自動連携（@Observable）
@MainActor
@Observable
public final class SettingsService: Sendable {

    // MARK: - Properties

    /// 現在のユーザー設定
    public private(set) var settings: UserSettings

    /// 設定リポジトリ
    private let repository: SettingsRepositoryProtocol

    /// 最後に発生したエラー（View側でアラート表示などに使用）
    public private(set) var lastError: SettingsError?

    /// 保存中フラグ
    public private(set) var isSaving: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter repository: 設定リポジトリ（デフォルトはSettingsRepository）
    public init(repository: SettingsRepositoryProtocol = SettingsRepository()) {
        self.repository = repository
        self.settings = repository.load()
    }

    // MARK: - Public Methods

    /// 設定を再読み込み
    ///
    /// UserDefaultsから最新の設定を読み込む
    public func reload() {
        settings = repository.load()
        lastError = nil
    }

    /// スキャン設定を更新
    /// - Parameter scanSettings: 新しいスキャン設定
    /// - Throws: SettingsError（バリデーション失敗時）
    public func updateScanSettings(_ scanSettings: ScanSettings) throws {
        // バリデーション
        try scanSettings.validate()

        // 設定を更新
        var newSettings = settings
        newSettings.scanSettings = scanSettings
        settings = newSettings

        // 保存
        try saveSettings()
    }

    /// 分析設定を更新
    /// - Parameter analysisSettings: 新しい分析設定
    /// - Throws: SettingsError（バリデーション失敗時）
    public func updateAnalysisSettings(_ analysisSettings: AnalysisSettings) throws {
        // バリデーション
        try analysisSettings.validate()

        // 設定を更新
        var newSettings = settings
        newSettings.analysisSettings = analysisSettings
        settings = newSettings

        // 保存
        try saveSettings()
    }

    /// 通知設定を更新
    /// - Parameter notificationSettings: 新しい通知設定
    /// - Throws: SettingsError（バリデーション失敗時）
    public func updateNotificationSettings(_ notificationSettings: NotificationSettings) throws {
        // バリデーション
        guard notificationSettings.isValid else {
            throw SettingsError.invalidQuietHours
        }

        // 設定を更新
        var newSettings = settings
        newSettings.notificationSettings = notificationSettings
        settings = newSettings

        // 保存
        try saveSettings()
    }

    /// 表示設定を更新
    /// - Parameter displaySettings: 新しい表示設定
    /// - Throws: SettingsError（バリデーション失敗時）
    public func updateDisplaySettings(_ displaySettings: DisplaySettings) throws {
        // バリデーション
        try displaySettings.validate()

        // 設定を更新
        var newSettings = settings
        newSettings.displaySettings = displaySettings
        settings = newSettings

        // 保存
        try saveSettings()
    }

    /// プレミアムステータスを更新
    /// - Parameter premiumStatus: 新しいプレミアムステータス
    public func updatePremiumStatus(_ premiumStatus: PremiumStatus) {
        var newSettings = settings
        newSettings.premiumStatus = premiumStatus
        settings = newSettings

        // 保存（エラーは無視）
        try? saveSettings()
    }

    /// 設定をデフォルトにリセット
    public func resetToDefaults() {
        settings = .default
        repository.reset()
        lastError = nil
    }

    /// 個別設定項目の更新（トグル・スライダー用）
    ///
    /// バリデーションが必要な項目は個別のupdate*Settings()を使用してください
    /// - Parameter update: 設定更新クロージャ
    public func updateSettings(_ update: (inout UserSettings) -> Void) {
        var newSettings = settings
        update(&newSettings)
        settings = newSettings

        // 保存（エラーは記録するが例外は投げない）
        do {
            try saveSettings()
        } catch let error as SettingsError {
            lastError = error
        } catch {
            lastError = .saveFailed(error)
        }
    }

    /// エラーをクリア
    public func clearError() {
        lastError = nil
    }

    // MARK: - Analysis Integration (SETTINGS-001)

    /// 現在の分析設定からSimilarityAnalysisOptionsを生成
    ///
    /// SimilarityAnalyzerを初期化する際に使用します。
    /// ユーザーが設定画面で変更した分析設定が反映されます。
    ///
    /// - Returns: 現在の分析設定に基づくSimilarityAnalysisOptions
    public var currentSimilarityAnalysisOptions: SimilarityAnalysisOptions {
        settings.analysisSettings.toSimilarityAnalysisOptions()
    }

    /// 現在の設定でSimilarityAnalyzerを生成
    ///
    /// 新しいSimilarityAnalyzerインスタンスを現在のユーザー設定で生成します。
    /// 分析処理を開始する前に呼び出してください。
    ///
    /// - Returns: 現在の設定で初期化されたSimilarityAnalyzer
    public func createSimilarityAnalyzer() -> SimilarityAnalyzer {
        return SimilarityAnalyzer(options: currentSimilarityAnalysisOptions)
    }

    // MARK: - Notification Integration (SETTINGS-002)

    /// 通知設定をNotificationManagerに同期
    ///
    /// SettingsServiceで管理される通知設定をNotificationManagerに反映します。
    /// 設定画面での変更がNotificationManagerに正しく反映されるように、
    /// この関数を通知設定変更後に呼び出してください。
    ///
    /// - Parameter notificationManager: 同期先のNotificationManager
    public func syncNotificationSettings(to notificationManager: NotificationManager) {
        notificationManager.syncSettings(from: self)
    }

    /// 通知設定を更新し、NotificationManagerにも同期
    ///
    /// 通知設定を更新すると同時に、指定されたNotificationManagerにも反映します。
    /// これにより、設定の二重管理を防ぎ、一貫性を保ちます。
    ///
    /// - Parameters:
    ///   - notificationSettings: 新しい通知設定
    ///   - notificationManager: 同期先のNotificationManager
    /// - Throws: SettingsError（バリデーション失敗時）
    public func updateNotificationSettings(
        _ notificationSettings: NotificationSettings,
        syncTo notificationManager: NotificationManager
    ) throws {
        // 通常の更新処理
        try updateNotificationSettings(notificationSettings)

        // NotificationManagerに同期
        notificationManager.syncSettings(from: self)
    }

    // MARK: - Private Methods

    /// 設定を保存
    /// - Throws: SettingsError
    private func saveSettings() throws {
        guard !isSaving else {
            throw SettingsError.saveFailed(NSError(
                domain: "SettingsService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "保存処理が既に実行中です"]
            ))
        }

        isSaving = true
        defer { isSaving = false }

        // リポジトリに保存
        repository.save(settings)

        // 成功したらエラーをクリア
        lastError = nil
    }
}

