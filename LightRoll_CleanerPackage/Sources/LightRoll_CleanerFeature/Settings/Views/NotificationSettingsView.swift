//
//  NotificationSettingsView.swift
//  LightRoll_CleanerFeature
//
//  通知設定画面
//  MV Pattern: @Observable + @Environment、ViewModelは不使用
//  Created by AI Assistant on 2025-12-08.
//

import SwiftUI

// MARK: - NotificationSettingsView

/// 通知設定画面
///
/// 通知機能のすべての設定を管理する画面。
/// SettingsServiceと連携し、設定の更新と保存を行います。
///
/// ## 機能
/// - 通知のマスタースイッチ
/// - ストレージアラートの設定（オン/オフ、しきい値）
/// - リマインダーの設定（オン/オフ、間隔）
/// - 静寂時間帯の設定（オン/オフ、開始/終了時刻）
/// - バリデーション（しきい値0.0〜1.0、時刻0〜23）
///
/// ## 使用例
/// ```swift
/// NavigationStack {
///     NotificationSettingsView()
///         .environment(settingsService)
/// }
/// ```
@MainActor
public struct NotificationSettingsView: View {

    // MARK: - Environment

    /// 設定サービス
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    /// 通知有効フラグ（ローカルステート）
    @State private var isEnabled: Bool

    /// ストレージアラート有効フラグ（ローカルステート）
    @State private var storageAlertEnabled: Bool

    /// ストレージアラートしきい値（ローカルステート）
    @State private var storageAlertThreshold: Double

    /// リマインダー有効フラグ（ローカルステート）
    @State private var reminderEnabled: Bool

    /// リマインダー間隔（ローカルステート）
    @State private var reminderInterval: ReminderInterval

    /// 静寂時間帯有効フラグ（ローカルステート）
    @State private var quietHoursEnabled: Bool

    /// 静寂開始時刻（ローカルステート）
    @State private var quietHoursStart: Int

    /// 静寂終了時刻（ローカルステート）
    @State private var quietHoursEnd: Int

    /// エラーアラート表示フラグ
    @State private var showErrorAlert = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    // MARK: - Initialization

    /// イニシャライザ
    public init() {
        // 初期値は後でtaskで設定されるため、デフォルト値で初期化
        self._isEnabled = State(initialValue: true)
        self._storageAlertEnabled = State(initialValue: true)
        self._storageAlertThreshold = State(initialValue: 0.9)
        self._reminderEnabled = State(initialValue: false)
        self._reminderInterval = State(initialValue: .weekly)
        self._quietHoursEnabled = State(initialValue: true)
        self._quietHoursStart = State(initialValue: 22)
        self._quietHoursEnd = State(initialValue: 8)
    }

    // MARK: - Body

    public var body: some View {
        List {
            // 通知マスタースイッチセクション
            notificationMasterSection

            // ストレージアラート設定セクション
            if isEnabled {
                storageAlertSection
            }

            // リマインダー設定セクション
            if isEnabled {
                reminderSection
            }

            // 静寂時間帯設定セクション
            if isEnabled {
                quietHoursSection
            }
        }
        .navigationTitle("通知設定")
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
        .accessibilityLabel("通知設定画面")
    }

    // MARK: - Sections

    /// 通知マスタースイッチセクション
    @ViewBuilder
    private var notificationMasterSection: some View {
        Section {
            SettingsToggle(
                icon: "bell.badge",
                iconColor: .orange,
                title: "通知を許可",
                subtitle: "アプリからの通知を受け取る",
                isOn: $isEnabled,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("notificationMasterToggle")
        } footer: {
            if isEnabled {
                Text("通知を許可すると、ストレージアラートやリマインダーを受け取ることができます。")
            } else {
                Text("通知が無効の場合、すべての通知が停止されます。")
            }
        }
    }

    /// ストレージアラート設定セクション
    @ViewBuilder
    private var storageAlertSection: some View {
        Section {
            // ストレージアラート有効トグル
            SettingsToggle(
                icon: "externaldrive.badge.exclamationmark",
                iconColor: .red,
                title: "容量警告",
                subtitle: "ストレージ容量が不足した際に通知",
                isOn: $storageAlertEnabled,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("storageAlertToggle")

            // しきい値スライダー（ストレージアラートが有効な場合のみ）
            if storageAlertEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gauge")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("警告しきい値")
                                .font(.body)
                                .foregroundStyle(.primary)

                            Text("ストレージ使用率が\(Int(storageAlertThreshold * 100))%を超えると通知")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(storageAlertThreshold * 100))%")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(minWidth: 50, alignment: .trailing)
                    }

                    Slider(
                        value: $storageAlertThreshold,
                        in: 0.5...0.95,
                        step: 0.05
                    ) {
                        Text("警告しきい値")
                    }
                    .tint(.blue)
                    .onChange(of: storageAlertThreshold) { _, _ in
                        saveSettings()
                    }
                    .accessibilityIdentifier("storageThresholdSlider")
                    .accessibilityLabel("警告しきい値")
                    .accessibilityValue("\(Int(storageAlertThreshold * 100))パーセント")
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("ストレージアラート")
        } footer: {
            if storageAlertEnabled {
                Text("ストレージ使用率が設定したしきい値を超えると、削除可能なファイルがあることを通知します。")
            } else {
                Text("ストレージアラートを有効にすると、容量不足時に通知を受け取れます。")
            }
        }
    }

    /// リマインダー設定セクション
    @ViewBuilder
    private var reminderSection: some View {
        Section {
            // リマインダー有効トグル
            SettingsToggle(
                icon: "clock.badge",
                iconColor: .green,
                title: "リマインダー",
                subtitle: "定期的に写真整理をリマインド",
                isOn: $reminderEnabled,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("reminderToggle")

            // リマインダー間隔ピッカー（リマインダーが有効な場合のみ）
            if reminderEnabled {
                SettingsRow(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "リマインダー間隔",
                    subtitle: "通知を受け取る頻度"
                ) {
                    Picker("", selection: $reminderInterval) {
                        ForEach(ReminderInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: reminderInterval) { _, _ in
                        saveSettings()
                    }
                }
                .accessibilityIdentifier("reminderIntervalPicker")
                .accessibilityLabel("リマインダー間隔")
                .accessibilityValue(reminderInterval.displayName)
            }
        } header: {
            Text("リマインダー")
        } footer: {
            reminderFooterText
        }
    }

    /// 静寂時間帯設定セクション
    @ViewBuilder
    private var quietHoursSection: some View {
        Section {
            // 静寂時間帯有効トグル
            SettingsToggle(
                icon: "moon.zzz",
                iconColor: .indigo,
                title: "静寂時間帯",
                subtitle: "指定した時間帯は通知を送信しない",
                isOn: $quietHoursEnabled,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("quietHoursToggle")

            // 静寂時間帯設定（静寂時間帯が有効な場合のみ）
            if quietHoursEnabled {
                // 開始時刻ピッカー
                SettingsRow(
                    icon: "sunset",
                    iconColor: .orange,
                    title: "開始時刻",
                    subtitle: "静寂時間帯の開始時刻"
                ) {
                    Picker("", selection: $quietHoursStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: quietHoursStart) { _, _ in
                        saveSettings()
                    }
                }
                .accessibilityIdentifier("quietHoursStartPicker")
                .accessibilityLabel("静寂開始時刻")
                .accessibilityValue(formatHour(quietHoursStart))

                // 終了時刻ピッカー
                SettingsRow(
                    icon: "sunrise",
                    iconColor: .yellow,
                    title: "終了時刻",
                    subtitle: "静寂時間帯の終了時刻"
                ) {
                    Picker("", selection: $quietHoursEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: quietHoursEnd) { _, _ in
                        saveSettings()
                    }
                }
                .accessibilityIdentifier("quietHoursEndPicker")
                .accessibilityLabel("静寂終了時刻")
                .accessibilityValue(formatHour(quietHoursEnd))
            }
        } header: {
            Text("静寂時間帯")
        } footer: {
            quietHoursFooterText
        }
    }

    // MARK: - Footer Text

    /// リマインダーフッターテキスト
    @ViewBuilder
    private var reminderFooterText: some View {
        if reminderEnabled {
            Text("設定した間隔で写真整理のリマインダーを受け取ります。\(reminderInterval.localizedDescription)")
        } else {
            Text("リマインダーを有効にすると、定期的に写真整理を促す通知が届きます。")
        }
    }

    /// 静寂時間帯フッターテキスト
    @ViewBuilder
    private var quietHoursFooterText: some View {
        if quietHoursEnabled {
            Text("静寂時間帯中（\(formatHour(quietHoursStart)) - \(formatHour(quietHoursEnd))）は通知を送信しません。緊急の通知のみ例外的に送信されます。")
        } else {
            Text("静寂時間帯を有効にすると、指定した時間帯は通知を受け取りません。")
        }
    }

    // MARK: - Helper Methods

    /// 時刻をフォーマット（24時間表記）
    /// - Parameter hour: 時刻（0〜23）
    /// - Returns: フォーマットされた文字列（例：「22時」「8時」）
    private func formatHour(_ hour: Int) -> String {
        return "\(hour)時"
    }

    // MARK: - Settings Management

    /// 設定を読み込み
    private func loadSettings() {
        let settings = settingsService.settings.notificationSettings
        isEnabled = settings.isEnabled
        storageAlertEnabled = settings.storageAlertEnabled
        storageAlertThreshold = settings.storageAlertThreshold
        reminderEnabled = settings.reminderEnabled
        reminderInterval = settings.reminderInterval
        quietHoursEnabled = settings.quietHoursEnabled
        quietHoursStart = settings.quietHoursStart
        quietHoursEnd = settings.quietHoursEnd
    }

    /// 設定を保存
    private func saveSettings() {
        let newSettings = NotificationSettings(
            isEnabled: isEnabled,
            storageAlertEnabled: storageAlertEnabled,
            storageAlertThreshold: storageAlertThreshold,
            reminderEnabled: reminderEnabled,
            reminderInterval: reminderInterval,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )

        do {
            try settingsService.updateNotificationSettings(newSettings)
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
        NotificationSettingsView()
            .environment(SettingsService())
    }
}

#Preview("All Enabled") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: true,
        storageAlertEnabled: true,
        storageAlertThreshold: 0.85,
        reminderEnabled: true,
        reminderInterval: .daily,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
}

#Preview("Notifications Disabled") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: false,
        storageAlertEnabled: true,
        storageAlertThreshold: 0.9,
        reminderEnabled: false,
        reminderInterval: .weekly,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
}

#Preview("Storage Alert Only") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: true,
        storageAlertEnabled: true,
        storageAlertThreshold: 0.75,
        reminderEnabled: false,
        reminderInterval: .weekly,
        quietHoursEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
}

#Preview("Reminder Only") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: true,
        storageAlertEnabled: false,
        storageAlertThreshold: 0.9,
        reminderEnabled: true,
        reminderInterval: .monthly,
        quietHoursEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
}

#Preview("Dark Mode") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: true,
        storageAlertEnabled: true,
        storageAlertThreshold: 0.9,
        reminderEnabled: true,
        reminderInterval: .biweekly,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 7
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
    .preferredColorScheme(.dark)
}

#Preview("Custom Quiet Hours") {
    let service = SettingsService()
    var settings = service.settings
    settings.notificationSettings = NotificationSettings(
        isEnabled: true,
        storageAlertEnabled: true,
        storageAlertThreshold: 0.95,
        reminderEnabled: true,
        reminderInterval: .weekly,
        quietHoursEnabled: true,
        quietHoursStart: 20,
        quietHoursEnd: 10
    )
    try? service.updateNotificationSettings(settings.notificationSettings)

    return NavigationStack {
        NotificationSettingsView()
            .environment(service)
    }
}
