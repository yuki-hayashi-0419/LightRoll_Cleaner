import SwiftUI

// MARK: - SettingsRow
/// 設定画面用の再利用可能な行コンポーネント
///
/// 設定画面で使用する標準的な行レイアウトを提供します。
/// アイコン、タイトル、説明、右側のコンテンツ（アクション、トグル、ピッカーなど）を柔軟に配置できます。
///
/// ## 使用例
/// ```swift
/// // 基本的な使用
/// SettingsRow(
///     icon: "bell",
///     iconColor: .orange,
///     title: "通知",
///     subtitle: "通知設定を管理"
/// )
///
/// // トグル付き
/// SettingsRow(
///     icon: "moon",
///     iconColor: .purple,
///     title: "ダークモード"
/// ) {
///     Toggle("", isOn: $isDarkMode)
///         .labelsHidden()
/// }
///
/// // ナビゲーション付き
/// SettingsRow(
///     icon: "photo",
///     iconColor: .blue,
///     title: "写真ライブラリ",
///     showChevron: true
/// )
/// ```
@MainActor
public struct SettingsRow<AccessoryContent: View>: View {

    // MARK: - Properties

    /// アイコン名（SF Symbol）
    let icon: String

    /// アイコンカラー
    let iconColor: Color

    /// タイトル
    let title: String

    /// サブタイトル（オプション）
    let subtitle: String?

    /// シェブロン表示フラグ（ナビゲーション用）
    let showChevron: Bool

    /// 右側のアクセサリコンテンツ
    private let accessoryContent: AccessoryContent

    // MARK: - Initialization

    /// イニシャライザ（アクセサリコンテンツなし）
    /// - Parameters:
    ///   - icon: アイコン名（SF Symbol）
    ///   - iconColor: アイコンカラー
    ///   - title: タイトル
    ///   - subtitle: サブタイトル（オプション）
    ///   - showChevron: シェブロン表示フラグ（デフォルト: false）
    public init(
        icon: String,
        iconColor: Color = .gray,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false
    ) where AccessoryContent == EmptyView {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.accessoryContent = EmptyView()
    }

    /// イニシャライザ（アクセサリコンテンツ付き）
    /// - Parameters:
    ///   - icon: アイコン名（SF Symbol）
    ///   - iconColor: アイコンカラー
    ///   - title: タイトル
    ///   - subtitle: サブタイトル（オプション）
    ///   - showChevron: シェブロン表示フラグ（デフォルト: false）
    ///   - accessoryContent: 右側のアクセサリコンテンツ
    public init(
        icon: String,
        iconColor: Color = .gray,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = false,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.accessoryContent = accessoryContent()
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 12) {
            // アイコン
            iconView

            // タイトル＆サブタイトル
            textContent

            Spacer()

            // アクセサリコンテンツ
            accessoryContent

            // シェブロン
            if showChevron {
                chevronView
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Subviews

    /// アイコンビュー
    private var iconView: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(iconColor)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }

    /// テキストコンテンツ
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// シェブロンビュー
    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Basic Row") {
    List {
        SettingsRow(
            icon: "bell",
            iconColor: .orange,
            title: "通知",
            subtitle: "通知設定を管理"
        )

        SettingsRow(
            icon: "photo",
            iconColor: .blue,
            title: "写真ライブラリ",
            showChevron: true
        )

        SettingsRow(
            icon: "lock",
            iconColor: .red,
            title: "プライバシー",
            subtitle: "データ保護設定",
            showChevron: true
        )
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
}

#Preview("With Accessory") {
    @Previewable @State var isEnabled = true
    @Previewable @State var selectedValue = 2

    List {
        SettingsRow(
            icon: "moon",
            iconColor: .purple,
            title: "ダークモード"
        ) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }

        SettingsRow(
            icon: "grid",
            iconColor: .green,
            title: "グリッド列数"
        ) {
            Picker("", selection: $selectedValue) {
                Text("3").tag(3)
                Text("4").tag(4)
                Text("5").tag(5)
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        }

        SettingsRow(
            icon: "info.circle",
            iconColor: .blue,
            title: "バージョン"
        ) {
            Text("1.0.0")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
}

#Preview("Dark Mode") {
    List {
        SettingsRow(
            icon: "bell.badge",
            iconColor: .orange,
            title: "通知を許可",
            subtitle: "アプリからの通知を受け取る"
        ) {
            Toggle("", isOn: .constant(true))
                .labelsHidden()
        }

        SettingsRow(
            icon: "folder",
            iconColor: .yellow,
            title: "ゴミ箱",
            subtitle: "削除した写真を表示",
            showChevron: true
        )
    }
    #if os(iOS)
    .listStyle(.insetGrouped)
    #else
    .listStyle(.automatic)
    #endif
    .preferredColorScheme(.dark)
}
