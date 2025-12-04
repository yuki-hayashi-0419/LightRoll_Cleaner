//
//  SettingsViewModel.swift
//  LightRoll_CleanerFeature
//
//  Settings画面のViewModel
//  ユーザー設定の管理と永続化を担当
//  M8-T04 実装
//  Created by AI Assistant on 2025-12-04.
//

import Foundation
import Observation

// MARK: - SettingsViewModel

/// Settings画面のViewModel
/// @Observable により SwiftUI での自動追跡が可能
@Observable
@MainActor
public final class SettingsViewModel {

    // MARK: - Properties

    /// 現在の設定
    /// @Observable により変更が自動的に SwiftUI に通知される
    public private(set) var settings: UserSettings

    /// 設定リポジトリ
    private let repository: SettingsRepositoryProtocol

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter repository: 設定リポジトリ（デフォルトは実装クラス、テスト時はモック注入可能）
    public init(repository: SettingsRepositoryProtocol = SettingsRepository()) {
        self.repository = repository
        self.settings = repository.load()
    }

    // MARK: - Public Methods

    /// 設定を読み込み
    ///
    /// リポジトリから最新の設定を取得して反映
    /// 通常は初期化時に自動的に読み込まれるため、明示的な呼び出しは不要
    public func loadSettings() async {
        settings = repository.load()
    }

    /// スキャン設定を更新
    ///
    /// スキャン動作に関する設定を更新して永続化
    /// - Parameter scanSettings: 新しいスキャン設定
    public func updateScanSettings(_ scanSettings: ScanSettings) async {
        settings.scanSettings = scanSettings
        repository.save(settings)
    }

    /// 分析設定を更新
    ///
    /// 画像分析のパラメータを更新して永続化
    /// - Parameter analysisSettings: 新しい分析設定
    public func updateAnalysisSettings(_ analysisSettings: AnalysisSettings) async {
        settings.analysisSettings = analysisSettings
        repository.save(settings)
    }

    /// 通知設定を更新
    ///
    /// 通知の動作設定を更新して永続化
    /// - Parameter notificationSettings: 新しい通知設定
    public func updateNotificationSettings(_ notificationSettings: NotificationSettings) async {
        settings.notificationSettings = notificationSettings
        repository.save(settings)
    }

    /// 表示設定を更新
    ///
    /// UI表示に関する設定を更新して永続化
    /// - Parameter displaySettings: 新しい表示設定
    public func updateDisplaySettings(_ displaySettings: DisplaySettings) async {
        settings.displaySettings = displaySettings
        repository.save(settings)
    }

    /// 設定をデフォルトにリセット
    ///
    /// すべての設定をデフォルト値に戻す
    /// リポジトリからも設定を削除し、次回起動時もデフォルト状態になる
    public func resetToDefaults() async {
        repository.reset()
        settings = .default
    }
}
