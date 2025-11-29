//
//  EmptyStateView.swift
//  LightRoll_CleanerFeature
//
//  空状態表示コンポーネント
//  データなし、検索結果なし、エラー、権限なしなどの空状態を統一的に表示
//  アイコン、タイトル、メッセージ、オプションのアクションボタンに対応
//  Created by AI Assistant
//

import SwiftUI

// MARK: - EmptyStateType

/// 空状態のタイプ定義
public enum EmptyStateType: Sendable {
    /// 空リスト（データがまだない、初期状態）
    case empty
    /// 検索結果なし
    case noSearchResults
    /// エラー（ネットワークエラー、処理エラー等）
    case error
    /// 権限なし（写真ライブラリへのアクセス拒否等）
    case noPermission
    /// カスタム（独自のアイコンとメッセージ）
    case custom(icon: String, title: String, message: String)

    /// デフォルトのアイコン
    @MainActor
    var defaultIcon: String {
        switch self {
        case .empty:
            return "photo.on.rectangle.angled"
        case .noSearchResults:
            return "magnifyingglass"
        case .error:
            return "exclamationmark.triangle"
        case .noPermission:
            return "lock.shield"
        case .custom(let icon, _, _):
            return icon
        }
    }

    /// デフォルトのタイトル
    @MainActor
    var defaultTitle: String {
        switch self {
        case .empty:
            return "写真がありません"
        case .noSearchResults:
            return "検索結果がありません"
        case .error:
            return "エラーが発生しました"
        case .noPermission:
            return "権限がありません"
        case .custom(_, let title, _):
            return title
        }
    }

    /// デフォルトのメッセージ
    @MainActor
    var defaultMessage: String {
        switch self {
        case .empty:
            return "写真をスキャンして整理を開始しましょう"
        case .noSearchResults:
            return "検索条件を変更して再度お試しください"
        case .error:
            return "問題が発生しました。もう一度お試しください"
        case .noPermission:
            return "写真ライブラリへのアクセスを許可してください"
        case .custom(_, _, let message):
            return message
        }
    }

    /// アイコンの色
    @MainActor
    var iconColor: Color {
        switch self {
        case .empty, .noSearchResults:
            return Color.LightRoll.textSecondary
        case .error:
            return Color.LightRoll.error
        case .noPermission:
            return Color.LightRoll.warning
        case .custom:
            return Color.LightRoll.primary
        }
    }
}

// MARK: - EmptyStateView

/// 空状態表示コンポーネント
/// データがない、検索結果なし、エラー、権限なしなどの空状態を統一的に表示
/// アイコン、タイトル、メッセージ、オプションのアクションボタンに対応
@MainActor
public struct EmptyStateView: View {
    // MARK: - Properties

    /// 空状態のタイプ
    let type: EmptyStateType

    /// カスタムアイコン（オプション、未指定時はtypeのデフォルトを使用）
    let customIcon: String?

    /// カスタムタイトル（オプション、未指定時はtypeのデフォルトを使用）
    let customTitle: String?

    /// カスタムメッセージ（オプション、未指定時はtypeのデフォルトを使用）
    let customMessage: String?

    /// アクションボタンのタイトル
    let actionTitle: String?

    /// アクションボタンのアイコン（オプション）
    let actionIcon: String?

    /// アクションボタンのタップアクション
    let onAction: (@Sendable () async -> Void)?

    /// アクションボタンのローディング状態（外部から制御可能）
    let isActionLoading: Bool

    // MARK: - Computed Properties

    /// 表示するアイコン
    private var displayIcon: String {
        customIcon ?? type.defaultIcon
    }

    /// 表示するタイトル
    private var displayTitle: String {
        customTitle ?? type.defaultTitle
    }

    /// 表示するメッセージ
    private var displayMessage: String {
        customMessage ?? type.defaultMessage
    }

    /// アクションボタンが表示可能か
    private var hasAction: Bool {
        actionTitle != nil && onAction != nil
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - type: 空状態のタイプ（デフォルト: .empty）
    ///   - customIcon: カスタムアイコン（デフォルト: nil）
    ///   - customTitle: カスタムタイトル（デフォルト: nil）
    ///   - customMessage: カスタムメッセージ（デフォルト: nil）
    ///   - actionTitle: アクションボタンのタイトル（デフォルト: nil）
    ///   - actionIcon: アクションボタンのアイコン（デフォルト: nil）
    ///   - isActionLoading: アクションボタンのローディング状態（デフォルト: false）
    ///   - onAction: アクションボタンのタップアクション（デフォルト: nil）
    public init(
        type: EmptyStateType = .empty,
        customIcon: String? = nil,
        customTitle: String? = nil,
        customMessage: String? = nil,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        isActionLoading: Bool = false,
        onAction: (@Sendable () async -> Void)? = nil
    ) {
        self.type = type
        self.customIcon = customIcon
        self.customTitle = customTitle
        self.customMessage = customMessage
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.isActionLoading = isActionLoading
        self.onAction = onAction
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: LRSpacing.xl) {
            Spacer()

            // アイコン
            iconView

            // テキストコンテンツ
            textContent

            // アクションボタン（オプション）
            if hasAction, let actionTitle = actionTitle, let onAction = onAction {
                ActionButton(
                    title: actionTitle,
                    icon: actionIcon,
                    style: actionButtonStyle,
                    isLoading: isActionLoading,
                    action: onAction
                )
                .padding(.horizontal, LRSpacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, LRSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(hasAction ? "アクションボタンをタップして実行できます" : "")
    }

    // MARK: - Subviews

    /// アイコンビュー
    @ViewBuilder
    private var iconView: some View {
        Image(systemName: displayIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: LRLayout.iconSizeHuge, height: LRLayout.iconSizeHuge)
            .foregroundColor(type.iconColor)
            .accessibilityHidden(true)
    }

    /// テキストコンテンツ
    @ViewBuilder
    private var textContent: some View {
        VStack(spacing: LRSpacing.sm) {
            // タイトル
            Text(displayTitle)
                .font(Font.LightRoll.title2)
                .foregroundColor(Color.LightRoll.textPrimary)
                .multilineTextAlignment(.center)

            // メッセージ
            Text(displayMessage)
                .font(Font.LightRoll.body)
                .foregroundColor(Color.LightRoll.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helper Properties

    /// アクションボタンのスタイル
    private var actionButtonStyle: ActionButtonStyle {
        switch type {
        case .error, .noPermission:
            return .primary
        default:
            return .primary
        }
    }

    /// アクセシビリティ用の説明文
    private var accessibilityDescription: String {
        var parts: [String] = [displayTitle, displayMessage]

        if hasAction, let actionTitle = actionTitle {
            parts.append("アクション: \(actionTitle)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Sendable Conformance

extension EmptyStateType: Equatable {}
extension EmptyStateType: Hashable {}

// MARK: - Preview

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xxl) {
                Text("Empty State Views")
                    .font(Font.LightRoll.title1)
                    .foregroundColor(Color.LightRoll.textPrimary)

                // 空リスト状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("空リスト状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .empty,
                        actionTitle: "スキャンを開始",
                        actionIcon: "magnifyingglass"
                    ) {
                        print("スキャン開始")
                    }
                    .frame(height: 400)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // 検索結果なし
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("検索結果なし")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .noSearchResults
                    )
                    .frame(height: 350)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // エラー状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("エラー状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .error,
                        actionTitle: "再試行",
                        actionIcon: "arrow.clockwise"
                    ) {
                        print("再試行")
                    }
                    .frame(height: 400)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // 権限なし
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("権限なし")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .noPermission,
                        actionTitle: "設定を開く",
                        actionIcon: "gear"
                    ) {
                        print("設定を開く")
                    }
                    .frame(height: 400)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // カスタム状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("カスタム状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .custom(
                            icon: "star.fill",
                            title: "お気に入りがありません",
                            message: "お気に入りの写真を追加してみましょう"
                        ),
                        actionTitle: "写真を選択",
                        actionIcon: "photo.on.rectangle"
                    ) {
                        print("写真を選択")
                    }
                    .frame(height: 400)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // ローディング状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("ローディング状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .empty,
                        actionTitle: "スキャン中...",
                        actionIcon: "magnifyingglass",
                        isActionLoading: true
                    ) {
                        print("スキャン中")
                    }
                    .frame(height: 400)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // アクションなし
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("アクションなし")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    EmptyStateView(
                        type: .noSearchResults,
                        customMessage: "検索条件を変更してください"
                    )
                    .frame(height: 350)
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // 実用例: グループリストが空
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("実用例: グループリストが空")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    VStack(spacing: 0) {
                        // ヘッダー
                        HStack {
                            Text("整理候補")
                                .font(Font.LightRoll.title2)
                                .foregroundColor(Color.LightRoll.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, LRSpacing.lg)
                        .padding(.top, LRSpacing.lg)

                        // 空状態
                        EmptyStateView(
                            type: .empty,
                            customIcon: "photo.stack",
                            customTitle: "整理候補がありません",
                            customMessage: "写真をスキャンして、削除候補を見つけましょう",
                            actionTitle: "スキャンを開始",
                            actionIcon: "magnifyingglass"
                        ) {
                            print("スキャン開始")
                        }
                        .frame(height: 400)
                    }
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }

                // 実用例: 検索結果が空
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("実用例: 検索結果が空")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    VStack(spacing: 0) {
                        // 検索バー（モック）
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.LightRoll.textSecondary)
                            Text("検索中...")
                                .font(Font.LightRoll.body)
                                .foregroundColor(Color.LightRoll.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, LRSpacing.lg)
                        .padding(.vertical, LRSpacing.md)
                        .background(Color.LightRoll.surfaceCard)
                        .lightRollCornerRadius(LRLayout.cornerRadiusMD)
                        .padding(LRSpacing.lg)

                        // 空状態
                        EmptyStateView(
                            type: .noSearchResults,
                            customMessage: "「風景」に一致する写真が見つかりませんでした"
                        )
                        .frame(height: 350)
                    }
                    .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Empty State View (Dark)")

        // ライトモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xxl) {
                Text("Empty State Views")
                    .font(Font.LightRoll.title1)
                    .foregroundColor(Color.LightRoll.textPrimary)

                EmptyStateView(
                    type: .empty,
                    actionTitle: "スキャンを開始",
                    actionIcon: "magnifyingglass"
                ) {
                    print("スキャン開始")
                }
                .frame(height: 400)
                .glassCard(cornerRadius: LRLayout.cornerRadiusLG)

                EmptyStateView(
                    type: .error,
                    actionTitle: "再試行",
                    actionIcon: "arrow.clockwise"
                ) {
                    print("再試行")
                }
                .frame(height: 400)
                .glassCard(cornerRadius: LRLayout.cornerRadiusLG)

                EmptyStateView(
                    type: .noPermission,
                    actionTitle: "設定を開く",
                    actionIcon: "gear"
                ) {
                    print("設定を開く")
                }
                .frame(height: 400)
                .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Empty State View (Light)")
    }
}

// MARK: - Modern Previews (iOS 17+)

#Preview("空リスト") {
    EmptyStateView(
        type: .empty,
        actionTitle: "スキャン開始",
        onAction: { print("スキャン開始") }
    )
    .background(
        LinearGradient(
            colors: [
                Color.LightRoll.background,
                Color.LightRoll.primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("検索結果なし") {
    EmptyStateView(
        type: .noSearchResults,
        actionTitle: "検索条件をクリア",
        onAction: { print("検索条件をクリア") }
    )
    .background(
        LinearGradient(
            colors: [
                Color.LightRoll.background,
                Color.LightRoll.primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("エラー") {
    EmptyStateView(
        type: .error,
        actionTitle: "再試行",
        onAction: { print("再試行") }
    )
    .background(
        LinearGradient(
            colors: [
                Color.LightRoll.background,
                Color.LightRoll.primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("権限なし") {
    EmptyStateView(
        type: .noPermission,
        actionTitle: "設定を開く",
        onAction: { print("設定を開く") }
    )
    .background(
        LinearGradient(
            colors: [
                Color.LightRoll.background,
                Color.LightRoll.primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
#endif
