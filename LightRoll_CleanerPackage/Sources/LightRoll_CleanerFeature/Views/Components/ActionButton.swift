//
//  ActionButton.swift
//  LightRoll_CleanerFeature
//
//  アクションボタンコンポーネント
//  プライマリ/セカンダリスタイル、ローディング状態、無効化状態に対応
//  Created by AI Assistant
//

import SwiftUI

// MARK: - Button Style

/// ActionButtonのスタイル定義
public enum ActionButtonStyle: Sendable {
    /// プライマリスタイル（アクセントカラー背景、白文字）
    case primary
    /// セカンダリスタイル（グレー背景、黒文字）
    case secondary

    /// 背景色
    @MainActor
    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.LightRoll.accent
        case .secondary:
            return Color.LightRoll.surfaceCard
        }
    }

    /// テキストカラー
    @MainActor
    var textColor: Color {
        switch self {
        case .primary:
            return .white
        case .secondary:
            return Color.LightRoll.textPrimary
        }
    }
}

// MARK: - ActionButton

/// アクションボタンコンポーネント
/// プライマリ/セカンダリの2つのスタイル、ローディング状態、無効化状態に対応
@MainActor
public struct ActionButton: View {
    // MARK: - Properties

    /// ボタンのタイトル
    let title: String

    /// アイコン（SF Symbol名）
    let icon: String?

    /// ボタンスタイル
    let style: ActionButtonStyle

    /// 無効化状態
    let isDisabled: Bool

    /// ローディング状態
    let isLoading: Bool

    /// タップアクション（async対応）
    let action: @Sendable () async -> Void

    // MARK: - State

    /// タップ中の状態（スケールアニメーション用）
    @State private var isPressed: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - title: ボタンのタイトル
    ///   - icon: アイコン（SF Symbol名、デフォルト: nil）
    ///   - style: ボタンスタイル（デフォルト: .primary）
    ///   - isDisabled: 無効化状態（デフォルト: false）
    ///   - isLoading: ローディング状態（デフォルト: false）
    ///   - action: タップアクション
    public init(
        title: String,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping @Sendable () async -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: LRSpacing.sm) {
                // ローディング中はProgressView、それ以外はアイコンとタイトル
                if isLoading {
                    ProgressView()
                        .tint(style.textColor)
                        .frame(width: LRLayout.iconSizeMD, height: LRLayout.iconSizeMD)

                    Text(title)
                        .font(Font.LightRoll.headline)
                        .foregroundColor(style.textColor.opacity(0.7))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: LRLayout.iconSizeMD))
                            .foregroundColor(style.textColor)
                    }

                    Text(title)
                        .font(Font.LightRoll.headline)
                        .foregroundColor(style.textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LRSpacing.buttonPaddingH)
            .padding(.vertical, LRSpacing.buttonPaddingV)
        }
        .background(
            RoundedRectangle(
                cornerRadius: LRLayout.cornerRadiusMD,
                style: .continuous
            )
            .fill(style.backgroundColor)
        )
        .opacity(effectiveOpacity)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .disabled(isDisabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isDisabled || isLoading ? [.isButton, .isStaticText] : .isButton)
        .accessibilityHint(isLoading ? "処理中です" : "タップして実行")
    }

    // MARK: - Computed Properties

    /// 有効な不透明度（無効化またはローディング時は半透明）
    /// - Note: DEBUGビルドではテスト用にinternalアクセスが可能
    var effectiveOpacity: Double {
        if isDisabled {
            return 0.5
        } else if isLoading {
            return 0.7
        } else {
            return 1.0
        }
    }

    /// アクセシビリティ用の説明文
    /// - Note: DEBUGビルドではテスト用にinternalアクセスが可能
    var accessibilityDescription: String {
        var parts: [String] = []

        // タイトル
        parts.append(title)

        // 状態
        if isLoading {
            parts.append("処理中")
        } else if isDisabled {
            parts.append("無効")
        }

        // スタイル
        switch style {
        case .primary:
            parts.append("プライマリボタン")
        case .secondary:
            parts.append("セカンダリボタン")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Sendable Conformance

extension ActionButtonStyle: Equatable {}
extension ActionButtonStyle: Hashable {}

// MARK: - Preview

#if DEBUG
struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Action Buttons")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)

                // プライマリスタイル
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("プライマリスタイル")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    ActionButton(
                        title: "写真を削除",
                        style: .primary
                    ) {
                        print("削除アクション")
                    }

                    ActionButton(
                        title: "スキャン開始",
                        icon: "magnifyingglass",
                        style: .primary
                    ) {
                        print("スキャン開始")
                    }
                }

                // セカンダリスタイル
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("セカンダリスタイル")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    ActionButton(
                        title: "キャンセル",
                        style: .secondary
                    ) {
                        print("キャンセル")
                    }

                    ActionButton(
                        title: "設定を開く",
                        icon: "gear",
                        style: .secondary
                    ) {
                        print("設定を開く")
                    }
                }

                // ローディング状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("ローディング状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    ActionButton(
                        title: "処理中...",
                        style: .primary,
                        isLoading: true
                    ) {
                        print("処理中")
                    }

                    ActionButton(
                        title: "読み込み中...",
                        icon: "arrow.clockwise",
                        style: .secondary,
                        isLoading: true
                    ) {
                        print("読み込み中")
                    }
                }

                // 無効化状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("無効化状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    ActionButton(
                        title: "削除（無効）",
                        icon: "trash",
                        style: .primary,
                        isDisabled: true
                    ) {
                        print("削除（無効）")
                    }

                    ActionButton(
                        title: "実行（無効）",
                        style: .secondary,
                        isDisabled: true
                    ) {
                        print("実行（無効）")
                    }
                }

                // アイコンのみバリエーション
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("アイコン付きバリエーション")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: LRSpacing.md) {
                        ActionButton(
                            title: "保存",
                            icon: "checkmark",
                            style: .primary
                        ) {
                            print("保存")
                        }

                        ActionButton(
                            title: "共有",
                            icon: "square.and.arrow.up",
                            style: .secondary
                        ) {
                            print("共有")
                        }
                    }
                }

                // 実用例
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("実用例: 削除確認")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    VStack(spacing: LRSpacing.sm) {
                        Text("24枚の写真を削除しますか？")
                            .font(Font.LightRoll.body)
                            .foregroundColor(Color.LightRoll.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: LRSpacing.md) {
                            ActionButton(
                                title: "キャンセル",
                                style: .secondary
                            ) {
                                print("キャンセル")
                            }

                            ActionButton(
                                title: "削除",
                                icon: "trash",
                                style: .primary
                            ) {
                                print("削除実行")
                            }
                        }
                    }
                    .padding()
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
        .previewDisplayName("Action Button (Dark)")

        // ライトモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Action Buttons")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)

                ActionButton(
                    title: "スキャン開始",
                    icon: "magnifyingglass",
                    style: .primary
                ) {
                    print("スキャン開始")
                }

                ActionButton(
                    title: "キャンセル",
                    icon: "xmark",
                    style: .secondary
                ) {
                    print("キャンセル")
                }

                ActionButton(
                    title: "処理中...",
                    style: .primary,
                    isLoading: true
                ) {
                    print("処理中")
                }

                ActionButton(
                    title: "無効化",
                    icon: "exclamationmark.triangle",
                    style: .primary,
                    isDisabled: true
                ) {
                    print("無効化")
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
        .preferredColorScheme(.light)
        .previewDisplayName("Action Button (Light)")
    }
}

// MARK: - Modern Previews (iOS 17+)

#Preview("プライマリスタイル") {
    VStack(spacing: LRSpacing.md) {
        ActionButton(
            title: "写真を削除",
            icon: "trash",
            style: .primary
        ) {
            print("削除アクション")
        }
    }
    .padding()
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

#Preview("セカンダリスタイル") {
    VStack(spacing: LRSpacing.md) {
        ActionButton(
            title: "キャンセル",
            icon: "xmark",
            style: .secondary
        ) {
            print("キャンセル")
        }
    }
    .padding()
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

#Preview("ローディング＆無効化") {
    VStack(spacing: LRSpacing.md) {
        ActionButton(
            title: "処理中...",
            style: .primary,
            isLoading: true
        ) {
            print("処理中")
        }

        ActionButton(
            title: "無効化",
            icon: "exclamationmark.triangle",
            style: .primary,
            isDisabled: true
        ) {
            print("無効化")
        }
    }
    .padding()
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
