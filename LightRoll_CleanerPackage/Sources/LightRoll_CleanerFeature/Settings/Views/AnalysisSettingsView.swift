//
//  AnalysisSettingsView.swift
//  LightRoll_CleanerFeature
//
//  分析設定画面
//  MV Pattern: @Observable + @Environment、ViewModelは不使用
//  Created by AI Assistant on 2025-12-05.
//

import SwiftUI

// MARK: - AnalysisSettingsView

/// 分析設定画面
///
/// 画像分析に関する設定（類似度判定、ブレ判定、グループ化設定）を管理する画面。
/// SettingsServiceと連携し、設定の更新と保存を行います。
///
/// ## 機能
/// - 類似度しきい値の調整（0%〜100%）
/// - ブレ判定感度の選択（低/標準/高）
/// - 最小グループサイズの設定（2〜10枚）
/// - バリデーション（有効範囲内の値検証）
///
/// ## 使用例
/// ```swift
/// NavigationStack {
///     AnalysisSettingsView()
///         .environment(settingsService)
/// }
/// ```
@MainActor
public struct AnalysisSettingsView: View {

    // MARK: - Environment

    /// 設定サービス
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    /// 類似度しきい値（ローカルステート）
    @State private var similarityThreshold: Float

    /// ブレ閾値（ローカルステート）
    @State private var blurThreshold: Float

    /// 最小グループサイズ（ローカルステート）
    @State private var minGroupSize: Int

    /// エラーアラート表示フラグ
    @State private var showErrorAlert = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    // MARK: - Nested Types

    /// ブレ判定感度の列挙型
    enum BlurSensitivity: String, CaseIterable {
        case low = "低"
        case standard = "標準"
        case high = "高"

        /// 閾値に対応する数値
        var thresholdValue: Float {
            switch self {
            case .low: return 0.5
            case .standard: return 0.3
            case .high: return 0.1
            }
        }

        /// 閾値から感度を取得
        static func from(threshold: Float) -> BlurSensitivity {
            if threshold >= 0.4 {
                return .low
            } else if threshold >= 0.2 {
                return .standard
            } else {
                return .high
            }
        }

        /// 説明テキスト
        var description: String {
            switch self {
            case .low:
                return "ブレにくい（厳しめ）"
            case .standard:
                return "バランスの取れた判定"
            case .high:
                return "ブレやすい（緩め）"
            }
        }
    }

    // MARK: - Initialization

    /// イニシャライザ
    public init() {
        // 初期値は後でtaskで設定されるため、デフォルト値で初期化
        self._similarityThreshold = State(initialValue: 0.85)
        self._blurThreshold = State(initialValue: 0.3)
        self._minGroupSize = State(initialValue: 2)
    }

    // MARK: - Body

    public var body: some View {
        List {
            // 類似度判定セクション
            similaritySection

            // ブレ判定セクション
            blurSection

            // グループ化設定セクション
            groupSection
        }
        .navigationTitle("分析設定")
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
        .accessibilityLabel("分析設定画面")
    }

    // MARK: - Sections

    /// 類似度判定セクション
    @ViewBuilder
    private var similaritySection: some View {
        Section {
            SettingsRow(
                icon: "chart.bar",
                iconColor: .blue,
                title: "類似度しきい値",
                subtitle: "写真の類似度を判定する基準"
            ) {
                Text("\(Int(similarityThreshold * 100))%")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("similarityThresholdRow")

            VStack(spacing: 8) {
                Slider(value: $similarityThreshold, in: 0.0...1.0, step: 0.01)
                    .onChange(of: similarityThreshold) { _, _ in
                        saveSettings()
                    }
                    .accessibilityIdentifier("similarityThresholdSlider")
                    .accessibilityLabel("類似度しきい値")
                    .accessibilityValue("\(Int(similarityThreshold * 100))パーセント")

                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("50%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("類似度判定")
        } footer: {
            Text("値が大きいほど厳密に判定されます（推奨: 85%）。")
        }
    }

    /// ブレ判定セクション
    @ViewBuilder
    private var blurSection: some View {
        Section {
            SettingsRow(
                icon: "camera.metering.center.weighted",
                iconColor: .purple,
                title: "ブレ判定感度",
                subtitle: currentBlurSensitivity.description
            ) {
                Picker("", selection: Binding(
                    get: { currentBlurSensitivity },
                    set: { newSensitivity in
                        blurThreshold = newSensitivity.thresholdValue
                        saveSettings()
                    }
                )) {
                    ForEach(BlurSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.rawValue).tag(sensitivity)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .accessibilityIdentifier("blurSensitivityPicker")
            .accessibilityLabel("ブレ判定感度")
            .accessibilityValue(currentBlurSensitivity.rawValue)
        } header: {
            Text("ブレ判定")
        } footer: {
            Text("感度が高いほど多くの写真がブレていると判定されます。")
        }
    }

    /// グループ化設定セクション
    @ViewBuilder
    private var groupSection: some View {
        Section {
            SettingsRow(
                icon: "square.grid.2x2",
                iconColor: .green,
                title: "最小グループサイズ",
                subtitle: "類似写真をグループ化する最小枚数"
            ) {
                Stepper(
                    "\(minGroupSize)枚",
                    value: $minGroupSize,
                    in: 2...10
                )
                .onChange(of: minGroupSize) { _, _ in
                    saveSettings()
                }
            }
            .accessibilityIdentifier("minGroupSizeStepper")
            .accessibilityLabel("最小グループサイズ")
            .accessibilityValue("\(minGroupSize)枚")
        } header: {
            Text("グループ化設定")
        } footer: {
            Text("この枚数以上の類似写真が見つかった場合にグループ化されます（推奨: 2枚）。")
        }
    }

    // MARK: - Computed Properties

    /// 現在のブレ感度
    private var currentBlurSensitivity: BlurSensitivity {
        BlurSensitivity.from(threshold: blurThreshold)
    }

    // MARK: - Methods

    /// 設定を読み込み
    private func loadSettings() {
        let analysisSettings = settingsService.settings.analysisSettings
        similarityThreshold = analysisSettings.similarityThreshold
        blurThreshold = analysisSettings.blurThreshold
        minGroupSize = analysisSettings.minGroupSize
    }

    /// 設定を保存
    private func saveSettings() {
        let newSettings = AnalysisSettings(
            similarityThreshold: similarityThreshold,
            blurThreshold: blurThreshold,
            minGroupSize: minGroupSize
        )

        do {
            try settingsService.updateAnalysisSettings(newSettings)
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
        AnalysisSettingsView()
            .environment(SettingsService())
    }
}

#Preview("High Similarity") {
    let service = SettingsService()
    var settings = service.settings
    settings.analysisSettings = AnalysisSettings(
        similarityThreshold: 0.95,
        blurThreshold: 0.3,
        minGroupSize: 3
    )
    try? service.updateAnalysisSettings(settings.analysisSettings)

    return NavigationStack {
        AnalysisSettingsView()
            .environment(service)
    }
}

#Preview("Low Blur Sensitivity") {
    let service = SettingsService()
    var settings = service.settings
    settings.analysisSettings = AnalysisSettings(
        similarityThreshold: 0.85,
        blurThreshold: 0.5,
        minGroupSize: 2
    )
    try? service.updateAnalysisSettings(settings.analysisSettings)

    return NavigationStack {
        AnalysisSettingsView()
            .environment(service)
    }
}

#Preview("Large Groups") {
    let service = SettingsService()
    var settings = service.settings
    settings.analysisSettings = AnalysisSettings(
        similarityThreshold: 0.75,
        blurThreshold: 0.1,
        minGroupSize: 5
    )
    try? service.updateAnalysisSettings(settings.analysisSettings)

    return NavigationStack {
        AnalysisSettingsView()
            .environment(service)
    }
}

#Preview("Dark Mode") {
    let service = SettingsService()
    var settings = service.settings
    settings.analysisSettings = AnalysisSettings(
        similarityThreshold: 0.80,
        blurThreshold: 0.3,
        minGroupSize: 4
    )
    try? service.updateAnalysisSettings(settings.analysisSettings)

    return NavigationStack {
        AnalysisSettingsView()
            .environment(service)
    }
    .preferredColorScheme(.dark)
}
