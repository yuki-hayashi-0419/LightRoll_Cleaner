import SwiftUI

// MARK: - Glass Style
/// グラスモーフィズムのスタイル定義
/// アプリ全体で一貫したグラス効果を提供
public enum GlassStyle: Sendable, CaseIterable {
    /// 極薄の半透明効果（最も透明）
    case ultraThin
    /// 薄い半透明効果
    case thin
    /// 標準の半透明効果（デフォルト）
    case regular
    /// 厚めの半透明効果
    case thick
    /// 強調されたクロム効果（最も不透明）
    case chrome

    /// SwiftUI Materialへのマッピング
    @MainActor
    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .chrome: return .ultraThickMaterial
        }
    }

    /// ボーダーの不透明度
    var borderOpacity: Double {
        switch self {
        case .ultraThin: return 0.15
        case .thin: return 0.2
        case .regular: return 0.25
        case .thick: return 0.3
        case .chrome: return 0.35
        }
    }

    /// 内側のグロー効果の不透明度
    var innerGlowOpacity: Double {
        switch self {
        case .ultraThin: return 0.05
        case .thin: return 0.08
        case .regular: return 0.1
        case .thick: return 0.12
        case .chrome: return 0.15
        }
    }

    /// シャドウの半径
    var shadowRadius: CGFloat {
        switch self {
        case .ultraThin: return 8
        case .thin: return 10
        case .regular: return 12
        case .thick: return 15
        case .chrome: return 20
        }
    }

    /// シャドウの不透明度
    var shadowOpacity: Double {
        switch self {
        case .ultraThin: return 0.1
        case .thin: return 0.15
        case .regular: return 0.2
        case .thick: return 0.25
        case .chrome: return 0.3
        }
    }
}

// MARK: - Glass Shape
/// グラスモーフィズムに適用可能な形状
public enum GlassShape: Sendable {
    /// 角丸矩形
    case roundedRectangle(cornerRadius: CGFloat)
    /// カプセル形状
    case capsule
    /// 円形
    case circle
    /// 連続角丸（iOS 13+の滑らかな角丸）
    case continuousRoundedRectangle(cornerRadius: CGFloat)

    /// 角丸の値を取得（角丸系の形状の場合）
    var cornerRadius: CGFloat? {
        switch self {
        case .roundedRectangle(let radius), .continuousRoundedRectangle(let radius):
            return radius
        case .capsule, .circle:
            return nil
        }
    }
}

// MARK: - Glass Modifier
/// グラスモーフィズム効果を適用するViewModifier
public struct GlassModifier: ViewModifier {
    /// グラスのスタイル
    let style: GlassStyle
    /// 適用する形状
    let glassShape: GlassShape
    /// ボーダーを表示するか
    let showBorder: Bool
    /// シャドウを表示するか
    let showShadow: Bool
    /// 内側のグロー効果を表示するか
    let showInnerGlow: Bool

    /// イニシャライザ
    /// - Parameters:
    ///   - style: グラススタイル（デフォルト: .regular）
    ///   - shape: 形状（デフォルト: 角丸20pt）
    ///   - showBorder: ボーダー表示（デフォルト: true）
    ///   - showShadow: シャドウ表示（デフォルト: true）
    ///   - showInnerGlow: 内側グロー表示（デフォルト: true）
    public init(
        style: GlassStyle = .regular,
        shape: GlassShape = .roundedRectangle(cornerRadius: 20),
        showBorder: Bool = true,
        showShadow: Bool = true,
        showInnerGlow: Bool = true
    ) {
        self.style = style
        self.glassShape = shape
        self.showBorder = showBorder
        self.showShadow = showShadow
        self.showInnerGlow = showInnerGlow
    }

    public func body(content: Content) -> some View {
        content
            .background {
                glassBackground
            }
            .if(showShadow) { view in
                view.shadow(
                    color: Color.black.opacity(style.shadowOpacity),
                    radius: style.shadowRadius,
                    x: 0,
                    y: 4
                )
            }
    }

    @MainActor
    @ViewBuilder
    private var glassBackground: some View {
        switch glassShape {
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                .fill(style.material)
                .overlay {
                    if showInnerGlow {
                        innerGlowOverlay(cornerRadius: cornerRadius)
                    }
                }
                .overlay {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.borderOpacity),
                                        Color.white.opacity(style.borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }

        case .continuousRoundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(style.material)
                .overlay {
                    if showInnerGlow {
                        innerGlowOverlayContinuous(cornerRadius: cornerRadius)
                    }
                }
                .overlay {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.borderOpacity),
                                        Color.white.opacity(style.borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }

        case .capsule:
            Capsule()
                .fill(style.material)
                .overlay {
                    if showInnerGlow {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.innerGlowOpacity),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay {
                    if showBorder {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.borderOpacity),
                                        Color.white.opacity(style.borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }

        case .circle:
            Circle()
                .fill(style.material)
                .overlay {
                    if showInnerGlow {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.innerGlowOpacity),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay {
                    if showBorder {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(style.borderOpacity),
                                        Color.white.opacity(style.borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
        }
    }

    @MainActor
    @ViewBuilder
    private func innerGlowOverlay(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(style.innerGlowOpacity),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )
    }

    @MainActor
    @ViewBuilder
    private func innerGlowOverlayContinuous(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(style.innerGlowOpacity),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )
    }
}

// MARK: - Glass Card View
/// グラスモーフィズム効果が適用されたカードコンポーネント
public struct GlassCardView<Content: View>: View {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let padding: CGFloat
    let showBorder: Bool
    let showShadow: Bool
    let content: () -> Content

    /// イニシャライザ
    /// - Parameters:
    ///   - style: グラススタイル（デフォルト: .regular）
    ///   - cornerRadius: 角丸の半径（デフォルト: 20）
    ///   - padding: 内側の余白（デフォルト: 16）
    ///   - showBorder: ボーダー表示（デフォルト: true）
    ///   - showShadow: シャドウ表示（デフォルト: true）
    ///   - content: カード内のコンテンツ
    public init(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        showBorder: Bool = true,
        showShadow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showBorder = showBorder
        self.showShadow = showShadow
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .glassBackground(
                style: style,
                shape: .continuousRoundedRectangle(cornerRadius: cornerRadius),
                showBorder: showBorder,
                showShadow: showShadow
            )
    }
}

// MARK: - Glass Button Style
/// グラスモーフィズム効果が適用されたボタンスタイル
public struct GlassButtonStyle: ButtonStyle {
    let style: GlassStyle
    let cornerRadius: CGFloat

    public init(style: GlassStyle = .thin, cornerRadius: CGFloat = 12) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassBackground(
                style: style,
                shape: .continuousRoundedRectangle(cornerRadius: cornerRadius),
                showBorder: true,
                showShadow: !configuration.isPressed
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - iOS 26+ Liquid Glass Support
/// iOS 26以降のLiquid Glass効果をサポート
/// 注: iOS 26の正式リリース後に glassEffect API が利用可能になります
/// 現在はフォールバックとして通常のグラス効果を使用
@available(iOS 26.0, *)
public struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let style: GlassStyle

    public init(cornerRadius: CGFloat = 20, style: GlassStyle = .regular) {
        self.cornerRadius = cornerRadius
        self.style = style
    }

    public func body(content: Content) -> some View {
        // iOS 26 の glassEffect(_:in:isEnabled:) が利用可能になったら以下に置き換え:
        // content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        // 現在は標準のグラス効果を使用（iOS 26ではLiquid Glass相当の効果が期待される）
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View Extension
public extension View {
    /// グラスモーフィズム背景を適用
    /// - Parameters:
    ///   - style: グラススタイル（デフォルト: .regular）
    ///   - shape: 形状（デフォルト: 角丸20pt）
    ///   - showBorder: ボーダー表示（デフォルト: true）
    ///   - showShadow: シャドウ表示（デフォルト: true）
    ///   - showInnerGlow: 内側グロー表示（デフォルト: true）
    /// - Returns: グラス効果が適用されたビュー
    func glassBackground(
        style: GlassStyle = .regular,
        shape: GlassShape = .roundedRectangle(cornerRadius: 20),
        showBorder: Bool = true,
        showShadow: Bool = true,
        showInnerGlow: Bool = true
    ) -> some View {
        modifier(GlassModifier(
            style: style,
            shape: shape,
            showBorder: showBorder,
            showShadow: showShadow,
            showInnerGlow: showInnerGlow
        ))
    }

    /// 角丸のグラス背景を簡易適用
    /// - Parameters:
    ///   - cornerRadius: 角丸の半径
    ///   - style: グラススタイル
    /// - Returns: グラス効果が適用されたビュー
    func glassCard(
        cornerRadius: CGFloat = 20,
        style: GlassStyle = .regular
    ) -> some View {
        glassBackground(
            style: style,
            shape: .continuousRoundedRectangle(cornerRadius: cornerRadius)
        )
    }

    /// カプセル形状のグラス背景を適用
    /// - Parameter style: グラススタイル
    /// - Returns: グラス効果が適用されたビュー
    func glassCapsule(style: GlassStyle = .thin) -> some View {
        glassBackground(style: style, shape: .capsule)
    }

    /// 円形のグラス背景を適用
    /// - Parameter style: グラススタイル
    /// - Returns: グラス効果が適用されたビュー
    func glassCircle(style: GlassStyle = .regular) -> some View {
        glassBackground(style: style, shape: .circle)
    }

    /// iOS 26以降ではLiquid Glass、それ以前では通常のグラス効果を適用
    /// - Parameters:
    ///   - cornerRadius: 角丸の半径
    ///   - style: フォールバック用のグラススタイル
    /// - Returns: 適切なグラス効果が適用されたビュー
    @ViewBuilder
    func adaptiveGlass(
        cornerRadius: CGFloat = 20,
        fallbackStyle: GlassStyle = .regular
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
        } else {
            self.glassCard(cornerRadius: cornerRadius, style: fallbackStyle)
        }
    }

    /// グラスボタンスタイルを適用（ButtonStyleとして使用する場合はGlassButtonStyleを直接使用）
    /// - Parameters:
    ///   - style: グラススタイル
    ///   - cornerRadius: 角丸の半径
    /// - Returns: グラス効果が適用されたビュー
    func glassButton(
        style: GlassStyle = .thin,
        cornerRadius: CGFloat = 12
    ) -> some View {
        glassBackground(
            style: style,
            shape: .continuousRoundedRectangle(cornerRadius: cornerRadius)
        )
    }
}

// MARK: - ButtonStyle Extension
public extension ButtonStyle where Self == GlassButtonStyle {
    /// グラスボタンスタイル
    /// - Parameters:
    ///   - style: グラススタイル
    ///   - cornerRadius: 角丸の半径
    /// - Returns: GlassButtonStyle
    static func glass(
        style: GlassStyle = .thin,
        cornerRadius: CGFloat = 12
    ) -> GlassButtonStyle {
        GlassButtonStyle(style: style, cornerRadius: cornerRadius)
    }
}

// MARK: - Conditional Modifier Helper
private extension View {
    /// 条件付きモディファイア適用
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
#if DEBUG
struct GlassMorphism_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.3),
                    Color.LightRoll.secondary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // スタイルバリエーション
                    Text("Glass Styles")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    ForEach(GlassStyle.allCases, id: \.self) { style in
                        Text(styleName(style))
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .glassBackground(style: style)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // 形状バリエーション
                    Text("Glass Shapes")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: 16) {
                        Text("Card")
                            .padding()
                            .glassCard(cornerRadius: 16)

                        Text("Capsule")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassCapsule()

                        Circle()
                            .glassCircle()
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white)
                            }
                    }
                    .foregroundColor(Color.LightRoll.textPrimary)
                    .font(Font.LightRoll.callout)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // GlassCardView
                    Text("Glass Card Component")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    GlassCardView(style: .regular) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "photo.stack")
                                    .font(.title2)
                                Text("写真グループ")
                                    .font(Font.LightRoll.headline)
                            }
                            Text("類似した写真が 24枚 見つかりました")
                                .font(Font.LightRoll.callout)
                            HStack {
                                Text("削減可能容量:")
                                    .font(Font.LightRoll.caption)
                                Text("128 MB")
                                    .font(Font.LightRoll.smallNumber)
                                    .foregroundColor(Color.LightRoll.success)
                            }
                        }
                        .foregroundColor(Color.LightRoll.textPrimary)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // ボタンスタイル
                    Text("Glass Button Style")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: 16) {
                        Button("Thin") {}
                            .buttonStyle(.glass(style: .thin))

                        Button("Regular") {}
                            .buttonStyle(.glass(style: .regular))

                        Button("Chrome") {}
                            .buttonStyle(.glass(style: .chrome))
                    }
                    .foregroundColor(Color.LightRoll.textPrimary)

                    Button {
                        // アクション
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("選択した写真を削除")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass(style: .regular, cornerRadius: 16))
                    .foregroundColor(Color.LightRoll.error)
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Glass Morphism (Dark)")

        // ライトモードプレビュー
        ZStack {
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                GlassCardView(style: .thin) {
                    VStack(spacing: 8) {
                        Text("ストレージ使用量")
                            .font(Font.LightRoll.headline)
                        Text("64.5 GB")
                            .font(Font.LightRoll.largeNumber)
                    }
                    .foregroundColor(Color.LightRoll.textPrimary)
                }

                HStack(spacing: 12) {
                    Button("キャンセル") {}
                        .buttonStyle(.glass(style: .ultraThin))

                    Button("確定") {}
                        .buttonStyle(.glass(style: .regular))
                }
                .foregroundColor(Color.LightRoll.textPrimary)
            }
            .padding()
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Glass Morphism (Light)")
    }

    static func styleName(_ style: GlassStyle) -> String {
        switch style {
        case .ultraThin: return "Ultra Thin"
        case .thin: return "Thin"
        case .regular: return "Regular"
        case .thick: return "Thick"
        case .chrome: return "Chrome"
        }
    }
}
#endif
