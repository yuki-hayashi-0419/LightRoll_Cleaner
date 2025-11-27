import SwiftUI

// MARK: - Spacing System
/// LightRoll アプリケーションのデザインシステム - スペーシング定義
/// 8pt グリッドシステムをベースにした一貫したスペーシング

public extension CGFloat {
    /// LightRoll アプリ専用のスペーシング・レイアウト定数
    struct LightRoll {
        private init() {}

        // MARK: - Spacing
        /// スペーシング定数（8pt グリッドベース）
        public struct Spacing {
            private init() {}

            // MARK: - Base Spacing Values
            /// 極小間隔 - 2pt（アイコンとラベルの間など）
            public static let xxs: CGFloat = 2

            /// 極小間隔 - 4pt（タイトな要素間）
            public static let xs: CGFloat = 4

            /// 小間隔 - 8pt（関連要素間）
            public static let sm: CGFloat = 8

            /// 中間隔 - 12pt（中程度の要素間）
            public static let md: CGFloat = 12

            /// 大間隔 - 16pt（セクション内要素間）
            public static let lg: CGFloat = 16

            /// 特大間隔 - 24pt（セクション間）
            public static let xl: CGFloat = 24

            /// 極大間隔 - 32pt（主要セクション間）
            public static let xxl: CGFloat = 32

            /// 最大間隔 - 40pt（画面上部マージン等）
            public static let xxxl: CGFloat = 40

            // MARK: - Semantic Spacing
            /// コンポーネント内部のパディング（デフォルト）
            public static let componentPadding: CGFloat = 16

            /// カード内部のパディング
            public static let cardPadding: CGFloat = 16

            /// セクション内の要素間スペース
            public static let sectionItemSpacing: CGFloat = 12

            /// セクション間のスペース
            public static let sectionSpacing: CGFloat = 24

            /// リスト項目間のスペース
            public static let listItemSpacing: CGFloat = 8

            /// グリッド項目間のスペース
            public static let gridSpacing: CGFloat = 2

            /// ボタン内のパディング（水平）
            public static let buttonPaddingH: CGFloat = 16

            /// ボタン内のパディング（垂直）
            public static let buttonPaddingV: CGFloat = 12

            /// ナビゲーションバーの高さ
            public static let navigationBarHeight: CGFloat = 44

            /// タブバーの高さ
            public static let tabBarHeight: CGFloat = 49

            /// セーフエリア追加マージン
            public static let safeAreaAdditional: CGFloat = 16
        }

        // MARK: - Layout Metrics
        /// レイアウトに関する定数
        public struct LayoutMetrics {
            private init() {}

            // MARK: - Corner Radius
            /// 極小角丸 - 4pt（小さなバッジ、タグ）
            public static let cornerRadiusXS: CGFloat = 4

            /// 小角丸 - 8pt（ボタン、入力フィールド）
            public static let cornerRadiusSM: CGFloat = 8

            /// 中角丸 - 12pt（小さめのカード）
            public static let cornerRadiusMD: CGFloat = 12

            /// 大角丸 - 16pt（カード、モーダル）
            public static let cornerRadiusLG: CGFloat = 16

            /// 特大角丸 - 20pt（大きなカード、シート）
            public static let cornerRadiusXL: CGFloat = 20

            /// 極大角丸 - 24pt（フルスクリーンモーダル）
            public static let cornerRadiusXXL: CGFloat = 24

            // MARK: - Icon Sizes
            /// 極小アイコン - 12pt
            public static let iconSizeXS: CGFloat = 12

            /// 小アイコン - 16pt
            public static let iconSizeSM: CGFloat = 16

            /// 中アイコン - 20pt
            public static let iconSizeMD: CGFloat = 20

            /// 大アイコン - 24pt（標準）
            public static let iconSizeLG: CGFloat = 24

            /// 特大アイコン - 32pt
            public static let iconSizeXL: CGFloat = 32

            /// 極大アイコン - 48pt（ヒーローアイコン）
            public static let iconSizeXXL: CGFloat = 48

            /// 巨大アイコン - 64pt（空状態アイコン等）
            public static let iconSizeHuge: CGFloat = 64

            // MARK: - Component Heights
            /// 小ボタンの高さ - 32pt
            public static let buttonHeightSM: CGFloat = 32

            /// 標準ボタンの高さ - 44pt（タッチターゲット最小サイズ）
            public static let buttonHeightMD: CGFloat = 44

            /// 大ボタンの高さ - 56pt
            public static let buttonHeightLG: CGFloat = 56

            /// 入力フィールドの高さ - 44pt
            public static let textFieldHeight: CGFloat = 44

            /// サムネイルサイズ（小）- 60pt
            public static let thumbnailSizeSM: CGFloat = 60

            /// サムネイルサイズ（中）- 80pt
            public static let thumbnailSizeMD: CGFloat = 80

            /// サムネイルサイズ（大）- 120pt
            public static let thumbnailSizeLG: CGFloat = 120

            // MARK: - Border & Stroke
            /// 極細ボーダー - 0.5pt
            public static let borderWidthHairline: CGFloat = 0.5

            /// 細ボーダー - 1pt
            public static let borderWidthThin: CGFloat = 1

            /// 標準ボーダー - 2pt
            public static let borderWidthMedium: CGFloat = 2

            /// 太ボーダー - 3pt
            public static let borderWidthThick: CGFloat = 3

            // MARK: - Grid
            /// 写真グリッドの列数（iPhone）
            public static let photoGridColumnsPhone: Int = 3

            /// 写真グリッドの列数（iPad）
            public static let photoGridColumnsPad: Int = 5

            // MARK: - Minimum Touch Target
            /// 最小タッチターゲットサイズ（Apple HIG準拠）
            public static let minTouchTarget: CGFloat = 44
        }
    }
}

// MARK: - EdgeInsets Convenience
/// エッジインセットの便利イニシャライザ
public extension EdgeInsets {
    /// LightRoll デザインシステムのスペーシングを使用したエッジインセット
    struct LightRoll {
        private init() {}

        /// 水平方向のみのパディング
        /// - Parameter value: パディング値
        /// - Returns: 左右にパディングを適用したEdgeInsets
        public static func horizontal(_ value: CGFloat) -> EdgeInsets {
            EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value)
        }

        /// 垂直方向のみのパディング
        /// - Parameter value: パディング値
        /// - Returns: 上下にパディングを適用したEdgeInsets
        public static func vertical(_ value: CGFloat) -> EdgeInsets {
            EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0)
        }

        /// 全方向に同じパディング
        /// - Parameter value: パディング値
        /// - Returns: 全方向にパディングを適用したEdgeInsets
        public static func all(_ value: CGFloat) -> EdgeInsets {
            EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
        }

        /// カスタムパディング
        /// - Parameters:
        ///   - horizontal: 水平方向のパディング
        ///   - vertical: 垂直方向のパディング
        /// - Returns: カスタムEdgeInsets
        public static func custom(horizontal: CGFloat, vertical: CGFloat) -> EdgeInsets {
            EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
        }

        // MARK: - Preset EdgeInsets
        /// コンポーネント標準パディング
        public static let component = EdgeInsets.all(CGFloat.LightRoll.Spacing.componentPadding)

        /// カード標準パディング
        public static let card = EdgeInsets.all(CGFloat.LightRoll.Spacing.cardPadding)

        /// セクション内パディング
        public static let section = EdgeInsets.all(CGFloat.LightRoll.Spacing.lg)

        /// リスト項目パディング
        public static let listItem = custom(
            horizontal: CGFloat.LightRoll.Spacing.lg,
            vertical: CGFloat.LightRoll.Spacing.sm
        )

        /// ボタン内パディング
        public static let button = custom(
            horizontal: CGFloat.LightRoll.Spacing.buttonPaddingH,
            vertical: CGFloat.LightRoll.Spacing.buttonPaddingV
        )
    }

    /// 全方向に同じパディングを適用
    static func all(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }
}

// MARK: - View Extension for Spacing
public extension View {
    /// LightRoll デザインシステムのスペーシングを適用
    /// - Parameter spacing: 適用するスペーシング値
    /// - Returns: パディングが適用されたビュー
    func lightRollPadding(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }

    /// LightRoll デザインシステムの水平パディングを適用
    /// - Parameter spacing: 適用するスペーシング値
    /// - Returns: 水平パディングが適用されたビュー
    func lightRollHorizontalPadding(_ spacing: CGFloat = CGFloat.LightRoll.Spacing.lg) -> some View {
        self.padding(.horizontal, spacing)
    }

    /// LightRoll デザインシステムの垂直パディングを適用
    /// - Parameter spacing: 適用するスペーシング値
    /// - Returns: 垂直パディングが適用されたビュー
    func lightRollVerticalPadding(_ spacing: CGFloat = CGFloat.LightRoll.Spacing.lg) -> some View {
        self.padding(.vertical, spacing)
    }

    /// コンポーネント標準パディングを適用
    /// - Returns: コンポーネントパディングが適用されたビュー
    func componentPadding() -> some View {
        self.padding(CGFloat.LightRoll.Spacing.componentPadding)
    }

    /// カード標準パディングを適用
    /// - Returns: カードパディングが適用されたビュー
    func cardPadding() -> some View {
        self.padding(CGFloat.LightRoll.Spacing.cardPadding)
    }

    /// セクション間スペーシングを上部に適用
    /// - Returns: セクションスペーシングが適用されたビュー
    func sectionSpacing() -> some View {
        self.padding(.top, CGFloat.LightRoll.Spacing.sectionSpacing)
    }

    /// LightRoll デザインシステムの角丸を適用
    /// - Parameter radius: 角丸の半径
    /// - Returns: 角丸が適用されたビュー
    func lightRollCornerRadius(_ radius: CGFloat = CGFloat.LightRoll.LayoutMetrics.cornerRadiusLG) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// 最小タッチターゲットサイズを保証
    /// - Returns: 最小タッチターゲットサイズが適用されたビュー
    func ensureMinTouchTarget() -> some View {
        self.frame(minWidth: CGFloat.LightRoll.LayoutMetrics.minTouchTarget,
                   minHeight: CGFloat.LightRoll.LayoutMetrics.minTouchTarget)
    }
}

// MARK: - Spacing Scale Type Alias
/// スペーシングスケールへのショートカット型エイリアス
public typealias LRSpacing = CGFloat.LightRoll.Spacing
/// レイアウトメトリクスへのショートカット型エイリアス
public typealias LRLayout = CGFloat.LightRoll.LayoutMetrics

// MARK: - Preview
#if DEBUG
struct Spacing_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // スペーシングスケール
                Group {
                    Text("Spacing Scale")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        SpacingRow(name: "xxs", value: LRSpacing.xxs)
                        SpacingRow(name: "xs", value: LRSpacing.xs)
                        SpacingRow(name: "sm", value: LRSpacing.sm)
                        SpacingRow(name: "md", value: LRSpacing.md)
                        SpacingRow(name: "lg", value: LRSpacing.lg)
                        SpacingRow(name: "xl", value: LRSpacing.xl)
                        SpacingRow(name: "xxl", value: LRSpacing.xxl)
                        SpacingRow(name: "xxxl", value: LRSpacing.xxxl)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // 角丸スケール
                Group {
                    Text("Corner Radius Scale")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: 12) {
                        CornerRadiusBox(name: "XS", radius: LRLayout.cornerRadiusXS)
                        CornerRadiusBox(name: "SM", radius: LRLayout.cornerRadiusSM)
                        CornerRadiusBox(name: "MD", radius: LRLayout.cornerRadiusMD)
                        CornerRadiusBox(name: "LG", radius: LRLayout.cornerRadiusLG)
                        CornerRadiusBox(name: "XL", radius: LRLayout.cornerRadiusXL)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // アイコンサイズスケール
                Group {
                    Text("Icon Size Scale")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: 16) {
                        IconSizeBox(name: "XS", size: LRLayout.iconSizeXS)
                        IconSizeBox(name: "SM", size: LRLayout.iconSizeSM)
                        IconSizeBox(name: "MD", size: LRLayout.iconSizeMD)
                        IconSizeBox(name: "LG", size: LRLayout.iconSizeLG)
                        IconSizeBox(name: "XL", size: LRLayout.iconSizeXL)
                        IconSizeBox(name: "XXL", size: LRLayout.iconSizeXXL)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // ボタンの高さスケール
                Group {
                    Text("Button Height Scale")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    VStack(spacing: 12) {
                        ButtonHeightRow(name: "SM (32pt)", height: LRLayout.buttonHeightSM)
                        ButtonHeightRow(name: "MD (44pt)", height: LRLayout.buttonHeightMD)
                        ButtonHeightRow(name: "LG (56pt)", height: LRLayout.buttonHeightLG)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // View Extension 使用例
                Group {
                    Text("View Extension Usage")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    Text("componentPadding()")
                        .componentPadding()
                        .background(Color.LightRoll.surfaceCard)
                        .lightRollCornerRadius(LRLayout.cornerRadiusMD)

                    Text("cardPadding()")
                        .cardPadding()
                        .background(Color.LightRoll.surfaceCard)
                        .lightRollCornerRadius(LRLayout.cornerRadiusLG)

                    Text("ensureMinTouchTarget()")
                        .font(Font.LightRoll.caption)
                        .ensureMinTouchTarget()
                        .background(Color.LightRoll.primary.opacity(0.3))
                        .lightRollCornerRadius(LRLayout.cornerRadiusSM)
                }
                .foregroundColor(Color.LightRoll.textPrimary)
            }
            .padding()
        }
        .background(Color.LightRoll.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Spacing & Layout (Dark)")
    }
}

// MARK: - Preview Helper Views
private struct SpacingRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(Font.LightRoll.callout)
                .frame(width: 50, alignment: .leading)

            Rectangle()
                .fill(Color.LightRoll.primary)
                .frame(width: value, height: 16)

            Text("\(Int(value))pt")
                .font(Font.LightRoll.caption)
                .foregroundColor(Color.LightRoll.textSecondary)
        }
        .foregroundColor(Color.LightRoll.textPrimary)
    }
}

private struct CornerRadiusBox: View {
    let name: String
    let radius: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.LightRoll.surfaceCard)
                .frame(width: 50, height: 50)

            Text(name)
                .font(Font.LightRoll.caption2)

            Text("\(Int(radius))pt")
                .font(Font.LightRoll.caption2)
                .foregroundColor(Color.LightRoll.textSecondary)
        }
        .foregroundColor(Color.LightRoll.textPrimary)
    }
}

private struct IconSizeBox: View {
    let name: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)

            Text(name)
                .font(Font.LightRoll.caption2)

            Text("\(Int(size))pt")
                .font(Font.LightRoll.caption2)
                .foregroundColor(Color.LightRoll.textSecondary)
        }
        .foregroundColor(Color.LightRoll.textPrimary)
    }
}

private struct ButtonHeightRow: View {
    let name: String
    let height: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(Font.LightRoll.callout)
                .frame(width: 100, alignment: .leading)

            RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM, style: .continuous)
                .fill(Color.LightRoll.primary)
                .frame(height: height)
                .overlay {
                    Text("Button")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(.white)
                }
        }
        .foregroundColor(Color.LightRoll.textPrimary)
    }
}
#endif
