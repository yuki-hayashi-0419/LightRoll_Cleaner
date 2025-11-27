import SwiftUI

// MARK: - Typography System
/// LightRoll アプリケーションのデザインシステム - タイポグラフィ定義
/// Dynamic Type 完全対応のフォントスタイルシステム

public extension Font {
    /// LightRoll アプリ専用のタイポグラフィスタイル
    struct LightRoll {
        // MARK: - Display Styles
        /// 大見出し（ホーム画面のメインタイトル等）
        /// - Base: 34pt Bold
        /// - Dynamic Type: largeTitle
        public static let largeTitle: Font = .largeTitle.weight(.bold)

        /// タイトル1（セクションヘッダー等）
        /// - Base: 28pt Bold
        /// - Dynamic Type: title
        public static let title1: Font = .title.weight(.bold)

        /// タイトル2（サブセクションヘッダー等）
        /// - Base: 22pt Semibold
        /// - Dynamic Type: title2
        public static let title2: Font = .title2.weight(.semibold)

        /// タイトル3（カード内タイトル等）
        /// - Base: 20pt Semibold
        /// - Dynamic Type: title3
        public static let title3: Font = .title3.weight(.semibold)

        // MARK: - Body Styles
        /// ヘッドライン（強調テキスト、ボタンラベル等）
        /// - Base: 17pt Semibold
        /// - Dynamic Type: headline
        public static let headline: Font = .headline

        /// 本文（通常のテキスト）
        /// - Base: 17pt Regular
        /// - Dynamic Type: body
        public static let body: Font = .body

        /// コールアウト（やや小さい本文）
        /// - Base: 16pt Regular
        /// - Dynamic Type: callout
        public static let callout: Font = .callout

        /// サブヘッドライン（補助的なヘッダー）
        /// - Base: 15pt Regular
        /// - Dynamic Type: subheadline
        public static let subheadline: Font = .subheadline

        // MARK: - Supporting Styles
        /// 脚注（小さな補足テキスト）
        /// - Base: 13pt Regular
        /// - Dynamic Type: footnote
        public static let footnote: Font = .footnote

        /// キャプション1（メタデータ、タイムスタンプ等）
        /// - Base: 12pt Regular
        /// - Dynamic Type: caption
        public static let caption: Font = .caption

        /// キャプション2（最小サイズの補助テキスト）
        /// - Base: 11pt Regular
        /// - Dynamic Type: caption2
        public static let caption2: Font = .caption2

        // MARK: - Special Styles
        /// 数値表示用（ストレージ容量等の大きな数字）
        /// - Base: 48pt Bold
        /// - Monospaced for alignment
        public static let largeNumber: Font = .system(size: 48, weight: .bold, design: .rounded)

        /// 中程度の数値表示
        /// - Base: 28pt Semibold
        /// - Monospaced for alignment
        public static let mediumNumber: Font = .system(size: 28, weight: .semibold, design: .rounded)

        /// 小さい数値表示（バッジ等）
        /// - Base: 14pt Medium
        /// - Monospaced for alignment
        public static let smallNumber: Font = .system(size: 14, weight: .medium, design: .rounded)

        /// 等幅フォント（技術情報表示用）
        /// - Base: 14pt Regular
        /// - Monospaced
        public static let monospaced: Font = .system(size: 14, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Style Modifier
/// テキストスタイルを一括適用するためのビューモディファイア
public struct LightRollTextStyle: ViewModifier {
    public enum Style {
        case largeTitle
        case title1
        case title2
        case title3
        case headline
        case body
        case callout
        case subheadline
        case footnote
        case caption
        case caption2
        case largeNumber
        case mediumNumber
        case smallNumber
        case monospaced
    }

    let style: Style
    let color: Color?

    public init(style: Style, color: Color? = nil) {
        self.style = style
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .font(font(for: style))
            .foregroundColor(color ?? defaultColor(for: style))
    }

    private func font(for style: Style) -> Font {
        switch style {
        case .largeTitle: return Font.LightRoll.largeTitle
        case .title1: return Font.LightRoll.title1
        case .title2: return Font.LightRoll.title2
        case .title3: return Font.LightRoll.title3
        case .headline: return Font.LightRoll.headline
        case .body: return Font.LightRoll.body
        case .callout: return Font.LightRoll.callout
        case .subheadline: return Font.LightRoll.subheadline
        case .footnote: return Font.LightRoll.footnote
        case .caption: return Font.LightRoll.caption
        case .caption2: return Font.LightRoll.caption2
        case .largeNumber: return Font.LightRoll.largeNumber
        case .mediumNumber: return Font.LightRoll.mediumNumber
        case .smallNumber: return Font.LightRoll.smallNumber
        case .monospaced: return Font.LightRoll.monospaced
        }
    }

    private func defaultColor(for style: Style) -> Color {
        switch style {
        case .largeTitle, .title1, .title2, .title3, .headline, .body, .largeNumber, .mediumNumber:
            return Color.LightRoll.textPrimary
        case .callout, .subheadline:
            return Color.LightRoll.textSecondary
        case .footnote, .caption, .caption2, .smallNumber, .monospaced:
            return Color.LightRoll.textTertiary
        }
    }
}

// MARK: - View Extension
public extension View {
    /// LightRollのタイポグラフィスタイルを適用
    /// - Parameters:
    ///   - style: 適用するスタイル
    ///   - color: オプションのカスタムカラー（nilの場合はデフォルト色を使用）
    /// - Returns: スタイルが適用されたビュー
    func lightRollTextStyle(_ style: LightRollTextStyle.Style, color: Color? = nil) -> some View {
        modifier(LightRollTextStyle(style: style, color: color))
    }
}

// MARK: - Text Utilities
public extension Text {
    /// プライマリテキストスタイル（本文テキスト用）
    func primaryStyle() -> Text {
        self
            .font(Font.LightRoll.body)
            .foregroundColor(Color.LightRoll.textPrimary)
    }

    /// セカンダリテキストスタイル（補助テキスト用）
    func secondaryStyle() -> Text {
        self
            .font(Font.LightRoll.callout)
            .foregroundColor(Color.LightRoll.textSecondary)
    }

    /// ターシャリテキストスタイル（注釈テキスト用）
    func tertiaryStyle() -> Text {
        self
            .font(Font.LightRoll.caption)
            .foregroundColor(Color.LightRoll.textTertiary)
    }
}

// MARK: - Accessibility Support
/// アクセシビリティに関連するテキストユーティリティ
public extension View {
    /// ダイナミックタイプを考慮したテキストスケーリング制限
    /// アクセシビリティを維持しつつ、レイアウト崩れを防ぐ
    /// - Parameter range: 許容するスケール範囲
    /// - Returns: スケーリング制限が適用されたビュー
    @ViewBuilder
    func dynamicTypeSize(range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }

    /// 最大のダイナミックタイプサイズを設定
    /// UIが崩れやすい箇所で使用
    /// - Parameter size: 最大サイズ
    /// - Returns: サイズ制限が適用されたビュー
    func limitDynamicTypeSize(to size: DynamicTypeSize = .accessibility1) -> some View {
        self.dynamicTypeSize(...size)
    }
}

// MARK: - Preview
#if DEBUG
struct Typography_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Display Styles")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Large Title")
                        .font(Font.LightRoll.largeTitle)
                    Text("Title 1")
                        .font(Font.LightRoll.title1)
                    Text("Title 2")
                        .font(Font.LightRoll.title2)
                    Text("Title 3")
                        .font(Font.LightRoll.title3)
                }

                Divider()

                Group {
                    Text("Body Styles")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Headline - 強調テキスト")
                        .font(Font.LightRoll.headline)
                    Text("Body - 本文テキスト")
                        .font(Font.LightRoll.body)
                    Text("Callout - コールアウトテキスト")
                        .font(Font.LightRoll.callout)
                    Text("Subheadline - サブヘッドライン")
                        .font(Font.LightRoll.subheadline)
                }

                Divider()

                Group {
                    Text("Supporting Styles")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Footnote - 脚注テキスト")
                        .font(Font.LightRoll.footnote)
                    Text("Caption - キャプション")
                        .font(Font.LightRoll.caption)
                    Text("Caption 2 - 最小キャプション")
                        .font(Font.LightRoll.caption2)
                }

                Divider()

                Group {
                    Text("Special Styles")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("12.5 GB")
                        .font(Font.LightRoll.largeNumber)
                    Text("1,234")
                        .font(Font.LightRoll.mediumNumber)
                    Text("99+")
                        .font(Font.LightRoll.smallNumber)
                    Text("0x48656C6C6F")
                        .font(Font.LightRoll.monospaced)
                }

                Divider()

                Group {
                    Text("View Modifier Usage")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Using lightRollTextStyle(.headline)")
                        .lightRollTextStyle(.headline)
                    Text("Using lightRollTextStyle(.caption)")
                        .lightRollTextStyle(.caption)
                    Text("Custom Color")
                        .lightRollTextStyle(.body, color: .orange)
                }

                Divider()

                Group {
                    Text("Text Extension Usage")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Primary Style").primaryStyle()
                    Text("Secondary Style").secondaryStyle()
                    Text("Tertiary Style").tertiaryStyle()
                }
            }
            .padding()
        }
        .background(Color.LightRoll.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Typography (Dark)")

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Large Title")
                    .font(Font.LightRoll.largeTitle)
                Text("Title 1")
                    .font(Font.LightRoll.title1)
                Text("Body Text")
                    .font(Font.LightRoll.body)
                Text("12.5 GB")
                    .font(Font.LightRoll.largeNumber)
            }
            .padding()
        }
        .background(Color.LightRoll.background)
        .preferredColorScheme(.light)
        .previewDisplayName("Typography (Light)")
    }
}
#endif
