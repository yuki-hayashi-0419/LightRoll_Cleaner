//
//  ProgressOverlay.swift
//  LightRoll_CleanerFeature
//
//  プログレスオーバーレイコンポーネント
//  処理進行中の表示を提供（プログレスインジケーター + メッセージ表示）
//  キャンセル機能、アクセシビリティ完全対応、グラスモーフィズムデザイン
//  Created by AI Assistant
//

import SwiftUI

// MARK: - ProgressOverlay

/// プログレスオーバーレイコンポーネント
/// 処理進行中の全画面オーバーレイを表示
/// 進捗率表示、メッセージ、キャンセル機能に対応
@MainActor
public struct ProgressOverlay: View {
    // MARK: - Properties

    /// 進捗率（0.0〜1.0、nilの場合は不定のプログレス）
    let progress: Double?

    /// メインメッセージ
    let message: String

    /// サブメッセージ（詳細情報）
    let detail: String?

    /// キャンセルボタンを表示するか
    let showCancelButton: Bool

    /// キャンセルアクション（async対応）
    let onCancel: (@Sendable () async -> Void)?

    // MARK: - State

    /// キャンセル処理中かどうか
    @State private var isCancelling: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - progress: 進捗率（0.0〜1.0、nilの場合は不定のプログレス、デフォルト: nil）
    ///   - message: メインメッセージ
    ///   - detail: サブメッセージ（詳細情報、デフォルト: nil）
    ///   - showCancelButton: キャンセルボタンを表示するか（デフォルト: false）
    ///   - onCancel: キャンセルアクション（デフォルト: nil）
    public init(
        progress: Double? = nil,
        message: String,
        detail: String? = nil,
        showCancelButton: Bool = false,
        onCancel: (@Sendable () async -> Void)? = nil
    ) {
        self.progress = progress
        self.message = message
        self.detail = detail
        self.showCancelButton = showCancelButton
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // 半透明背景オーバーレイ
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // プログレスカード
            VStack(spacing: LRSpacing.lg) {
                // プログレスインジケーター
                progressIndicatorView

                // テキスト情報
                VStack(spacing: LRSpacing.sm) {
                    Text(message)
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)
                        .multilineTextAlignment(.center)

                    if let detail = detail {
                        Text(detail)
                            .font(Font.LightRoll.callout)
                            .foregroundColor(Color.LightRoll.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // 進捗率テキスト（進捗率が指定されている場合）
                    if let progress = progress {
                        Text(progressPercentageText(progress))
                            .font(Font.LightRoll.mediumNumber)
                            .foregroundColor(Color.LightRoll.primary)
                    }
                }

                // キャンセルボタン
                if showCancelButton, let onCancel = onCancel {
                    ActionButton(
                        title: isCancelling ? "キャンセル中..." : "キャンセル",
                        icon: "xmark.circle",
                        style: .secondary,
                        isDisabled: isCancelling,
                        isLoading: isCancelling
                    ) {
                        await handleCancel(onCancel)
                    }
                }
            }
            .padding(LRSpacing.xl)
            .frame(maxWidth: 320)
            .glassCard(cornerRadius: LRLayout.cornerRadiusXL, style: .thick)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Subviews

    /// プログレスインジケーター
    @ViewBuilder
    private var progressIndicatorView: some View {
        if let progress = progress {
            // 進捗率が指定されている場合：円形プログレスバー
            ZStack {
                // 背景サークル
                Circle()
                    .stroke(
                        Color.LightRoll.textTertiary.opacity(0.2),
                        lineWidth: 8
                    )

                // 進捗サークル
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.LightRoll.primary,
                                Color.LightRoll.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // 中央のチェックマークアイコン（完了時）
                if progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.LightRoll.success)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 80, height: 80)

        } else {
            // 進捗率が不定の場合：回転するプログレスビュー
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.LightRoll.primary)
                .scaleEffect(1.5)
                .frame(width: 80, height: 80)
        }
    }

    // MARK: - Methods

    /// キャンセル処理
    /// - Parameter action: キャンセルアクション
    private func handleCancel(_ action: @Sendable @escaping () async -> Void) async {
        guard !isCancelling else { return }

        isCancelling = true
        await action()
        // キャンセル完了後は親ビューが閉じる責任を持つため、ここではフラグを立てたまま
    }

    /// 進捗率のパーセンテージテキスト
    /// - Parameter progress: 進捗率（0.0〜1.0）
    /// - Returns: パーセンテージ文字列（例: "75%"）
    private func progressPercentageText(_ progress: Double) -> String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    // MARK: - Accessibility

    /// アクセシビリティ用の説明文
    private var accessibilityDescription: String {
        var parts: [String] = []

        // メインメッセージ
        parts.append(message)

        // 詳細メッセージ
        if let detail = detail {
            parts.append(detail)
        }

        // キャンセル状態
        if isCancelling {
            parts.append("キャンセル処理中")
        }

        return parts.joined(separator: ", ")
    }

    /// アクセシビリティ用の進捗値
    private var accessibilityValue: String {
        if let progress = progress {
            return progressPercentageText(progress)
        } else {
            return "処理中"
        }
    }
}

// MARK: - Convenience Initializers

public extension ProgressOverlay {
    /// 不定進捗のオーバーレイ（シンプルなローディング）
    /// - Parameters:
    ///   - message: メインメッセージ（デフォルト: "処理中..."）
    ///   - detail: サブメッセージ（デフォルト: nil）
    ///   - showCancelButton: キャンセルボタンを表示するか（デフォルト: false）
    ///   - onCancel: キャンセルアクション（デフォルト: nil）
    /// - Returns: ProgressOverlay
    static func indeterminate(
        message: String = "処理中...",
        detail: String? = nil,
        showCancelButton: Bool = false,
        onCancel: (@Sendable () async -> Void)? = nil
    ) -> ProgressOverlay {
        ProgressOverlay(
            progress: nil,
            message: message,
            detail: detail,
            showCancelButton: showCancelButton,
            onCancel: onCancel
        )
    }

    /// 確定進捗のオーバーレイ
    /// - Parameters:
    ///   - progress: 進捗率（0.0〜1.0）
    ///   - message: メインメッセージ
    ///   - detail: サブメッセージ（デフォルト: nil）
    ///   - showCancelButton: キャンセルボタンを表示するか（デフォルト: false）
    ///   - onCancel: キャンセルアクション（デフォルト: nil）
    /// - Returns: ProgressOverlay
    static func determinate(
        progress: Double,
        message: String,
        detail: String? = nil,
        showCancelButton: Bool = false,
        onCancel: (@Sendable () async -> Void)? = nil
    ) -> ProgressOverlay {
        ProgressOverlay(
            progress: progress,
            message: message,
            detail: detail,
            showCancelButton: showCancelButton,
            onCancel: onCancel
        )
    }
}

// MARK: - View Extension

public extension View {
    /// プログレスオーバーレイを表示
    /// - Parameters:
    ///   - isPresented: 表示フラグ
    ///   - progress: 進捗率（0.0〜1.0、nilの場合は不定のプログレス）
    ///   - message: メインメッセージ
    ///   - detail: サブメッセージ（デフォルト: nil）
    ///   - showCancelButton: キャンセルボタンを表示するか（デフォルト: false）
    ///   - onCancel: キャンセルアクション（デフォルト: nil）
    /// - Returns: オーバーレイが適用されたビュー
    func progressOverlay(
        isPresented: Bool,
        progress: Double? = nil,
        message: String,
        detail: String? = nil,
        showCancelButton: Bool = false,
        onCancel: (@Sendable () async -> Void)? = nil
    ) -> some View {
        self.overlay {
            if isPresented {
                ProgressOverlay(
                    progress: progress,
                    message: message,
                    detail: detail,
                    showCancelButton: showCancelButton,
                    onCancel: onCancel
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - Preview

#if DEBUG
struct ProgressOverlay_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        ZStack {
            // 背景（オーバーレイが見えるように）
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LRSpacing.xxxl) {
                    Text("Progress Overlays")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    // 不定進捗（シンプル）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("不定進捗（シンプル）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.indeterminate(
                            message: "写真をスキャン中..."
                        )
                    }

                    // 不定進捗（詳細付き）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("不定進捗（詳細付き）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.indeterminate(
                            message: "写真を削除中...",
                            detail: "この処理には数分かかる場合があります"
                        )
                    }

                    // 不定進捗（キャンセルボタン付き）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("不定進捗（キャンセル可能）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.indeterminate(
                            message: "分析中...",
                            detail: "類似写真を検出しています",
                            showCancelButton: true
                        ) {
                            print("キャンセル")
                        }
                    }

                    // 確定進捗（25%）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("確定進捗（25%）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.determinate(
                            progress: 0.25,
                            message: "写真を処理中...",
                            detail: "120枚中30枚完了"
                        )
                    }

                    // 確定進捗（75%、キャンセル可能）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("確定進捗（75%、キャンセル可能）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.determinate(
                            progress: 0.75,
                            message: "削除中...",
                            detail: "100枚中75枚削除済み",
                            showCancelButton: true
                        ) {
                            print("キャンセル")
                        }
                    }

                    // 確定進捗（100%、完了）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("確定進捗（100%、完了）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ProgressOverlay.determinate(
                            progress: 1.0,
                            message: "完了しました",
                            detail: "50枚の写真を削除しました"
                        )
                    }

                    // 実用例: overlay modifier使用
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("実用例: overlay modifier")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        DemoView()
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Progress Overlay (Dark)")

        // ライトモードプレビュー
        ZStack {
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: LRSpacing.xl) {
                ProgressOverlay.indeterminate(
                    message: "読み込み中..."
                )

                ProgressOverlay.determinate(
                    progress: 0.6,
                    message: "アップロード中...",
                    detail: "残り約2分",
                    showCancelButton: true
                ) {
                    print("キャンセル")
                }
            }
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Progress Overlay (Light)")
    }
}

// MARK: - Demo View

/// デモ用のインタラクティブビュー
private struct DemoView: View {
    @State private var isProcessing = false
    @State private var progress: Double = 0.0

    var body: some View {
        VStack(spacing: LRSpacing.md) {
            ActionButton(
                title: "処理開始",
                icon: "play.fill",
                style: .primary,
                isDisabled: isProcessing
            ) {
                await startProcess()
            }

            if isProcessing {
                Text("プログレス: \(Int(progress * 100))%")
                    .font(Font.LightRoll.callout)
                    .foregroundColor(Color.LightRoll.textSecondary)
            }
        }
        .padding()
        .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
        .progressOverlay(
            isPresented: isProcessing,
            progress: progress,
            message: "処理中...",
            detail: "しばらくお待ちください",
            showCancelButton: true
        ) {
            await cancelProcess()
        }
    }

    private func startProcess() async {
        isProcessing = true
        progress = 0.0

        for i in 1...100 {
            try? await Task.sleep(for: .milliseconds(50))
            progress = Double(i) / 100.0

            if !isProcessing {
                break
            }
        }

        isProcessing = false
    }

    private func cancelProcess() async {
        isProcessing = false
        progress = 0.0
    }
}
#endif
