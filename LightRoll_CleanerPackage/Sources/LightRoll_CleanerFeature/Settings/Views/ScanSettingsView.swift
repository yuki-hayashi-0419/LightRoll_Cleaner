//
//  ScanSettingsView.swift
//  LightRoll_CleanerFeature
//
//  スキャン設定画面
//  MV Pattern: @Observable + @Environment、ViewModelは不使用
//  Created by AI Assistant on 2025-12-05.
//

import SwiftUI

// MARK: - ScanSettingsView

/// スキャン設定画面
///
/// 自動スキャン設定とスキャン対象の選択を管理する画面。
/// SettingsServiceと連携し、設定の更新と保存を行います。
///
/// ## 機能
/// - 自動スキャンのオン/オフ切り替え
/// - スキャン間隔の選択（毎日、毎週、毎月、しない）
/// - スキャン対象の選択（動画、スクリーンショット、自撮り）
/// - バリデーション（少なくとも1つのコンテンツタイプが有効）
///
/// ## 使用例
/// ```swift
/// NavigationStack {
///     ScanSettingsView()
///         .environment(settingsService)
/// }
/// ```
@MainActor
public struct ScanSettingsView: View {

    // MARK: - Environment

    /// 設定サービス
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    /// 自動スキャン有効フラグ（ローカルステート）
    @State private var autoScanEnabled: Bool

    /// スキャン間隔（ローカルステート）
    @State private var autoScanInterval: AutoScanInterval

    /// 動画を含める（ローカルステート）
    @State private var includeVideos: Bool

    /// スクリーンショットを含める（ローカルステート）
    @State private var includeScreenshots: Bool

    /// 自撮りを含める（ローカルステート）
    @State private var includeSelfies: Bool

    /// エラーアラート表示フラグ
    @State private var showErrorAlert = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    // MARK: - Initialization

    /// イニシャライザ
    public init() {
        // 初期値は後でonAppear/taskで設定されるため、デフォルト値で初期化
        self._autoScanEnabled = State(initialValue: false)
        self._autoScanInterval = State(initialValue: .weekly)
        self._includeVideos = State(initialValue: true)
        self._includeScreenshots = State(initialValue: true)
        self._includeSelfies = State(initialValue: true)
    }

    // MARK: - Body

    public var body: some View {
        List {
            // 自動スキャン設定セクション
            autoScanSection

            // スキャン対象セクション
            scanTargetSection
        }
        .navigationTitle("スキャン設定")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            // 初回ロード時に現在の設定を反映
            loadSettings()
        }
        .alert("設定エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                showErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("スキャン設定画面")
    }

    // MARK: - Sections

    /// 自動スキャン設定セクション
    @ViewBuilder
    private var autoScanSection: some View {
        Section {
            // 自動スキャントグル
            SettingsToggle(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "自動スキャン",
                subtitle: "定期的に写真ライブラリをスキャン",
                isOn: $autoScanEnabled,
                onChange: { newValue in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("autoScanToggle")

            // スキャン間隔ピッカー（自動スキャンが有効な場合のみ）
            if autoScanEnabled {
                SettingsRow(
                    icon: "calendar",
                    iconColor: .orange,
                    title: "スキャン間隔",
                    subtitle: "自動スキャンの実行頻度"
                ) {
                    Picker("", selection: $autoScanInterval) {
                        ForEach(AutoScanInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: autoScanInterval) { _, _ in
                        saveSettings()
                    }
                }
                .accessibilityIdentifier("autoScanIntervalPicker")
                .accessibilityLabel("スキャン間隔")
                .accessibilityValue(autoScanInterval.displayName)
            }
        } header: {
            Text("自動スキャン")
        } footer: {
            footerText
        }
    }

    /// スキャン対象セクション
    @ViewBuilder
    private var scanTargetSection: some View {
        Section {
            // 動画を含める
            SettingsToggle(
                icon: "video",
                iconColor: .purple,
                title: "動画を含める",
                subtitle: "動画ファイルもスキャン対象に含める",
                isOn: $includeVideos,
                disabled: isOnlyContentTypeEnabled && includeVideos,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("includeVideosToggle")

            // スクリーンショットを含める
            SettingsToggle(
                icon: "camera.viewfinder",
                iconColor: .green,
                title: "スクリーンショットを含める",
                subtitle: "スクリーンショットを検出",
                isOn: $includeScreenshots,
                disabled: isOnlyContentTypeEnabled && includeScreenshots,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("includeScreenshotsToggle")

            // 自撮りを含める
            SettingsToggle(
                icon: "person.crop.circle",
                iconColor: .pink,
                title: "自撮りを含める",
                subtitle: "前面カメラで撮影した写真を検出",
                isOn: $includeSelfies,
                disabled: isOnlyContentTypeEnabled && includeSelfies,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("includeSelfiesToggle")
        } header: {
            Text("スキャン対象")
        } footer: {
            Text("少なくとも1つのコンテンツタイプを有効にしてください。")
        }
    }

    /// フッターテキスト
    @ViewBuilder
    private var footerText: some View {
        if autoScanEnabled {
            if autoScanInterval == .never {
                Text("自動スキャンが有効ですが、間隔が「しない」に設定されています。")
            } else {
                Text("バックグラウンドで\(autoScanInterval.displayName)スキャンを実行します。")
            }
        } else {
            Text("自動スキャンを有効にすると、定期的に写真ライブラリをスキャンします。")
        }
    }

    // MARK: - Computed Properties

    /// 有効なコンテンツタイプが1つのみか
    private var isOnlyContentTypeEnabled: Bool {
        let enabledCount = [includeVideos, includeScreenshots, includeSelfies].filter { $0 }.count
        return enabledCount == 1
    }

    // MARK: - Methods

    /// 設定を読み込み
    private func loadSettings() {
        let scanSettings = settingsService.settings.scanSettings
        autoScanEnabled = scanSettings.autoScanEnabled
        autoScanInterval = scanSettings.autoScanInterval
        includeVideos = scanSettings.includeVideos
        includeScreenshots = scanSettings.includeScreenshots
        includeSelfies = scanSettings.includeSelfies
    }

    /// 設定を保存
    private func saveSettings() {
        let newSettings = ScanSettings(
            autoScanEnabled: autoScanEnabled,
            autoScanInterval: autoScanInterval,
            includeVideos: includeVideos,
            includeScreenshots: includeScreenshots,
            includeSelfies: includeSelfies
        )

        do {
            try settingsService.updateScanSettings(newSettings)
        } catch let error as SettingsError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            // エラーの場合は元の値に戻す
            loadSettings()
        } catch {
            errorMessage = "設定の保存に失敗しました: \(error.localizedDescription)"
            showErrorAlert = true
            loadSettings()
        }
    }
}

// MARK: - Preview

#Preview("Default Settings") {
    NavigationStack {
        ScanSettingsView()
            .environment(SettingsService())
    }
}

#Preview("Auto Scan Enabled") {
    let service = SettingsService()
    var settings = service.settings
    settings.scanSettings = ScanSettings(
        autoScanEnabled: true,
        autoScanInterval: .weekly,
        includeVideos: true,
        includeScreenshots: true,
        includeSelfies: true
    )
    try? service.updateScanSettings(settings.scanSettings)

    return NavigationStack {
        ScanSettingsView()
            .environment(service)
    }
}

#Preview("Daily Scan") {
    let service = SettingsService()
    var settings = service.settings
    settings.scanSettings = ScanSettings(
        autoScanEnabled: true,
        autoScanInterval: .daily,
        includeVideos: true,
        includeScreenshots: false,
        includeSelfies: true
    )
    try? service.updateScanSettings(settings.scanSettings)

    return NavigationStack {
        ScanSettingsView()
            .environment(service)
    }
}

#Preview("Dark Mode") {
    let service = SettingsService()
    var settings = service.settings
    settings.scanSettings = ScanSettings(
        autoScanEnabled: true,
        autoScanInterval: .monthly,
        includeVideos: true,
        includeScreenshots: true,
        includeSelfies: false
    )
    try? service.updateScanSettings(settings.scanSettings)

    return NavigationStack {
        ScanSettingsView()
            .environment(service)
    }
    .preferredColorScheme(.dark)
}

#Preview("Videos Only") {
    let service = SettingsService()
    var settings = service.settings
    settings.scanSettings = ScanSettings(
        autoScanEnabled: false,
        autoScanInterval: .weekly,
        includeVideos: true,
        includeScreenshots: false,
        includeSelfies: false
    )
    try? service.updateScanSettings(settings.scanSettings)

    return NavigationStack {
        ScanSettingsView()
            .environment(service)
    }
}
