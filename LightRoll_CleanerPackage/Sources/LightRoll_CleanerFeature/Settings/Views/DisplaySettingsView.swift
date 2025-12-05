//
//  DisplaySettingsView.swift
//  LightRoll_CleanerFeature
//
//  表示設定画面
//  MV Pattern: @Observable + @Environment、ViewModelは不使用
//  Created by AI Assistant on 2025-12-06.
//

import SwiftUI

// MARK: - DisplaySettingsView

/// 表示設定画面
///
/// 画像表示に関する設定（グリッド列数、ファイルサイズ表示、撮影日表示、並び順）を管理する画面。
/// SettingsServiceと連携し、設定の更新と保存を行います。
///
/// ## 機能
/// - グリッド列数の調整（2〜6列）
/// - ファイルサイズ表示のオン/オフ
/// - 撮影日表示のオン/オフ
/// - 並び順の選択（新しい順/古い順/容量大きい順/容量小さい順）
/// - バリデーション（有効範囲内の値検証）
///
/// ## 使用例
/// ```swift
/// NavigationStack {
///     DisplaySettingsView()
///         .environment(settingsService)
/// }
/// ```
@MainActor
public struct DisplaySettingsView: View {

    // MARK: - Environment

    /// 設定サービス
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    /// グリッド列数（ローカルステート）
    @State private var gridColumns: Int

    /// ファイルサイズ表示フラグ（ローカルステート）
    @State private var showFileSize: Bool

    /// 撮影日表示フラグ（ローカルステート）
    @State private var showDate: Bool

    /// 並び順（ローカルステート）
    @State private var sortOrder: SortOrder

    /// エラーアラート表示フラグ
    @State private var showErrorAlert = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    // MARK: - Initialization

    /// イニシャライザ
    public init() {
        // 初期値は後でtaskで設定されるため、デフォルト値で初期化
        self._gridColumns = State(initialValue: 4)
        self._showFileSize = State(initialValue: true)
        self._showDate = State(initialValue: true)
        self._sortOrder = State(initialValue: .dateDescending)
    }

    // MARK: - Body

    public var body: some View {
        List {
            // グリッド表示セクション
            gridSection

            // 情報表示セクション
            infoSection

            // 並び順セクション
            sortSection
        }
        .navigationTitle("表示設定")
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
        .accessibilityLabel("表示設定画面")
    }

    // MARK: - Sections

    /// グリッド表示セクション
    @ViewBuilder
    private var gridSection: some View {
        Section {
            SettingsRow(
                icon: "square.grid.3x3",
                iconColor: .blue,
                title: "グリッド列数",
                subtitle: "写真一覧の1行あたりの列数"
            ) {
                Stepper(
                    "\(gridColumns)列",
                    value: $gridColumns,
                    in: 2...6
                )
                .onChange(of: gridColumns) { _, _ in
                    saveSettings()
                }
            }
            .accessibilityIdentifier("gridColumnsStepper")
            .accessibilityLabel("グリッド列数")
            .accessibilityValue("\(gridColumns)列")
        } header: {
            Text("グリッド表示")
        } footer: {
            Text("列数を減らすと写真が大きく表示され、増やすと一度に多くの写真を見ることができます（推奨: 4列）。")
        }
    }

    /// 情報表示セクション
    @ViewBuilder
    private var infoSection: some View {
        Section {
            // ファイルサイズ表示トグル
            SettingsToggle(
                icon: "doc.text",
                iconColor: .purple,
                title: "ファイルサイズ表示",
                subtitle: "各写真のファイルサイズを表示",
                isOn: $showFileSize,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("showFileSizeToggle")

            // 撮影日表示トグル
            SettingsToggle(
                icon: "calendar",
                iconColor: .orange,
                title: "撮影日表示",
                subtitle: "各写真の撮影日時を表示",
                isOn: $showDate,
                onChange: { _ in
                    saveSettings()
                }
            )
            .accessibilityIdentifier("showDateToggle")
        } header: {
            Text("情報表示")
        } footer: {
            Text("写真一覧に表示する情報を選択します。")
        }
    }

    /// 並び順セクション
    @ViewBuilder
    private var sortSection: some View {
        Section {
            SettingsRow(
                icon: "arrow.up.arrow.down",
                iconColor: .green,
                title: "並び順",
                subtitle: currentSortOrderDescription
            ) {
                Picker("", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .onChange(of: sortOrder) { _, _ in
                    saveSettings()
                }
            }
            .accessibilityIdentifier("sortOrderPicker")
            .accessibilityLabel("並び順")
            .accessibilityValue(sortOrder.displayName)
        } header: {
            Text("並び順")
        } footer: {
            Text("写真一覧の並び順を選択します。")
        }
    }

    // MARK: - Computed Properties

    /// 現在の並び順の説明
    private var currentSortOrderDescription: String {
        sortOrder.displayName
    }

    // MARK: - Methods

    /// 設定を読み込み
    private func loadSettings() {
        let displaySettings = settingsService.settings.displaySettings
        gridColumns = displaySettings.gridColumns
        showFileSize = displaySettings.showFileSize
        showDate = displaySettings.showDate
        sortOrder = displaySettings.sortOrder

        // バリデーション: 範囲外の値の場合はデフォルト値にフォールバック
        if gridColumns < 2 || gridColumns > 6 {
            gridColumns = 4
        }
    }

    /// 設定を保存
    private func saveSettings() {
        // バリデーション: グリッド列数が範囲外の場合はデフォルト値に修正
        let validatedColumns: Int
        if gridColumns < 2 || gridColumns > 6 {
            validatedColumns = 4
        } else {
            validatedColumns = gridColumns
        }

        let newSettings = DisplaySettings(
            gridColumns: validatedColumns,
            showFileSize: showFileSize,
            showDate: showDate,
            sortOrder: sortOrder
        )

        do {
            try settingsService.updateDisplaySettings(newSettings)

            // 範囲外の値が修正された場合、UIを更新
            if gridColumns != validatedColumns {
                gridColumns = validatedColumns
            }
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
        DisplaySettingsView()
            .environment(SettingsService())
    }
}

#Preview("Minimum Columns") {
    let service = SettingsService()
    var settings = service.settings
    settings.displaySettings = DisplaySettings(
        gridColumns: 2,
        showFileSize: true,
        showDate: true,
        sortOrder: .dateDescending
    )
    try? service.updateDisplaySettings(settings.displaySettings)

    return NavigationStack {
        DisplaySettingsView()
            .environment(service)
    }
}

#Preview("Maximum Columns") {
    let service = SettingsService()
    var settings = service.settings
    settings.displaySettings = DisplaySettings(
        gridColumns: 6,
        showFileSize: false,
        showDate: false,
        sortOrder: .sizeDescending
    )
    try? service.updateDisplaySettings(settings.displaySettings)

    return NavigationStack {
        DisplaySettingsView()
            .environment(service)
    }
}

#Preview("Dark Mode") {
    let service = SettingsService()
    var settings = service.settings
    settings.displaySettings = DisplaySettings(
        gridColumns: 5,
        showFileSize: true,
        showDate: false,
        sortOrder: .sizeAscending
    )
    try? service.updateDisplaySettings(settings.displaySettings)

    return NavigationStack {
        DisplaySettingsView()
            .environment(service)
    }
    .preferredColorScheme(.dark)
}
