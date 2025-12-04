import SwiftUI

// MARK: - SettingsToggle
/// 設定画面用の再利用可能なトグルコンポーネント
///
/// SettingsRowを内部で使用し、トグルスイッチを統合したコンポーネント。
/// 設定画面でのオン/オフ設定を簡単に実装できます。
///
/// ## 使用例
/// ```swift
/// @State private var notificationsEnabled = true
/// @State private var autoScanEnabled = false
///
/// List {
///     SettingsToggle(
///         icon: "bell",
///         iconColor: .orange,
///         title: "通知を許可",
///         subtitle: "アプリからの通知を受け取る",
///         isOn: $notificationsEnabled
///     )
///
///     SettingsToggle(
///         icon: "arrow.clockwise",
///         iconColor: .blue,
///         title: "自動スキャン",
///         subtitle: "定期的に写真を自動スキャン",
///         isOn: $autoScanEnabled,
///         disabled: !notificationsEnabled
///     )
/// }
/// ```
@MainActor
public struct SettingsToggle: View {

    // MARK: - Properties

    /// アイコン名（SF Symbol）
    let icon: String

    /// アイコンカラー
    let iconColor: Color

    /// タイトル
    let title: String

    /// サブタイトル（オプション）
    let subtitle: String?

    /// トグルの状態（バインディング）
    @Binding private var isOn: Bool

    /// 無効化フラグ
    let disabled: Bool

    /// トグル変更時のコールバック（オプション）
    let onChange: ((Bool) -> Void)?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - icon: アイコン名（SF Symbol）
    ///   - iconColor: アイコンカラー（デフォルト: .gray）
    ///   - title: タイトル
    ///   - subtitle: サブタイトル（オプション）
    ///   - isOn: トグルの状態バインディング
    ///   - disabled: 無効化フラグ（デフォルト: false）
    ///   - onChange: トグル変更時のコールバック（オプション）
    public init(
        icon: String,
        iconColor: Color = .gray,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        disabled: Bool = false,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.disabled = disabled
        self.onChange = onChange
    }

    // MARK: - Body

    public var body: some View {
        SettingsRow(
            icon: icon,
            iconColor: disabled ? iconColor.opacity(0.5) : iconColor,
            title: title,
            subtitle: subtitle
        ) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(disabled)
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Accessibility

    /// アクセシビリティラベル
    var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        return label
    }

    /// アクセシビリティ値
    var accessibilityValue: String {
        isOn ? "オン" : "オフ"
    }

    /// アクセシビリティヒント
    var accessibilityHint: String {
        if disabled {
            return "この設定は現在無効です"
        }
        return isOn ? "ダブルタップでオフにします" : "ダブルタップでオンにします"
    }
}

// MARK: - Preview

#Preview("Basic Toggle") {
    @Previewable @State var isEnabled = true

    List {
        Section {
            SettingsToggle(
                icon: "bell",
                iconColor: .orange,
                title: "通知を許可",
                subtitle: "アプリからの通知を受け取る",
                isOn: $isEnabled
            )
        } header: {
            Text("通知設定")
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
}

#Preview("Multiple Toggles") {
    @Previewable @State var notificationsEnabled = true
    @Previewable @State var autoScanEnabled = false
    @Previewable @State var includeVideos = true
    @Previewable @State var includeScreenshots = true

    List {
        Section {
            SettingsToggle(
                icon: "bell.badge",
                iconColor: .orange,
                title: "通知を許可",
                subtitle: "アプリからの通知を受け取る",
                isOn: $notificationsEnabled
            )

            SettingsToggle(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "自動スキャン",
                subtitle: "定期的に写真を自動スキャン",
                isOn: $autoScanEnabled
            )
        } header: {
            Text("通知設定")
        }

        Section {
            SettingsToggle(
                icon: "video",
                iconColor: .purple,
                title: "動画を含める",
                subtitle: "動画ファイルもスキャン対象に含める",
                isOn: $includeVideos
            )

            SettingsToggle(
                icon: "camera.viewfinder",
                iconColor: .green,
                title: "スクリーンショット",
                subtitle: "スクリーンショットを検出",
                isOn: $includeScreenshots
            )
        } header: {
            Text("スキャン設定")
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
}

#Preview("Disabled Toggle") {
    @Previewable @State var mainEnabled = false
    @Previewable @State var dependentEnabled = true

    List {
        Section {
            SettingsToggle(
                icon: "bell.badge",
                iconColor: .orange,
                title: "通知を許可",
                subtitle: "メイン設定",
                isOn: $mainEnabled
            )

            SettingsToggle(
                icon: "clock",
                iconColor: .blue,
                title: "定期通知",
                subtitle: "通知が有効な場合のみ利用可能",
                isOn: $dependentEnabled,
                disabled: !mainEnabled
            )
        } header: {
            Text("依存関係のある設定")
        } footer: {
            Text("定期通知を使用するには、まず通知を許可してください。")
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
}

#Preview("With Callbacks") {
    @Previewable @State var isEnabled = true
    @Previewable @State var showAlert = false
    @Previewable @State var alertMessage = ""

    List {
        Section {
            SettingsToggle(
                icon: "moon",
                iconColor: .indigo,
                title: "ダークモード",
                subtitle: "変更時にアラートを表示",
                isOn: $isEnabled,
                onChange: { newValue in
                    alertMessage = newValue ? "ダークモードが有効になりました" : "ダークモードが無効になりました"
                    showAlert = true
                }
            )
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
    .alert("設定変更", isPresented: $showAlert) {
        Button("OK", role: .cancel) {}
    } message: {
        Text(alertMessage)
    }
}

#Preview("Dark Mode") {
    @Previewable @State var option1 = true
    @Previewable @State var option2 = false
    @Previewable @State var option3 = true

    List {
        Section {
            SettingsToggle(
                icon: "bell.badge",
                iconColor: .orange,
                title: "通知を許可",
                subtitle: "すべての通知を受け取る",
                isOn: $option1
            )

            SettingsToggle(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "自動スキャン",
                subtitle: "毎週自動的にスキャン",
                isOn: $option2
            )

            SettingsToggle(
                icon: "photo",
                iconColor: .green,
                title: "写真を含める",
                isOn: $option3
            )
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
    .preferredColorScheme(.dark)
}
