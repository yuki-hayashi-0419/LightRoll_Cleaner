//
//  ConfirmationDialog.swift
//  LightRoll_CleanerFeature
//
//  確認ダイアログコンポーネント
//  削除確認、キャンセル確認などの重要なアクション前に表示するダイアログ
//  破壊的アクション（削除など）の視覚的な区別、アクセシビリティ完全対応
//  Created by AI Assistant
//

import SwiftUI

// MARK: - ConfirmationDialogStyle

/// 確認ダイアログのスタイル定義
public enum ConfirmationDialogStyle: Sendable {
    /// 通常のアクション（キャンセル、確認など）
    case normal
    /// 破壊的アクション（削除、永久削除など）
    case destructive
    /// 警告アクション（注意が必要な操作）
    case warning

    /// アクションボタンの背景色
    @MainActor
    var actionColor: Color {
        switch self {
        case .normal:
            return Color.LightRoll.primary
        case .destructive:
            return Color.LightRoll.error
        case .warning:
            return Color.LightRoll.warning
        }
    }

    /// アクションアイコン
    @MainActor
    var actionIcon: String {
        switch self {
        case .normal:
            return "checkmark.circle"
        case .destructive:
            return "trash.circle.fill"
        case .warning:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - ConfirmationDialog

/// 確認ダイアログコンポーネント
/// 重要なアクション実行前にユーザーに確認を求めるダイアログ
/// 破壊的アクション（削除など）の視覚的な区別、詳細情報の表示に対応
@MainActor
public struct ConfirmationDialog: View {
    // MARK: - Properties

    /// ダイアログのタイトル
    let title: String

    /// メインメッセージ
    let message: String

    /// 詳細情報（オプション、追加の説明やメタデータ）
    let details: [ConfirmationDetail]?

    /// ダイアログスタイル
    let style: ConfirmationDialogStyle

    /// 確認ボタンのタイトル
    let confirmTitle: String

    /// キャンセルボタンのタイトル
    let cancelTitle: String

    /// 確認アクション
    let onConfirm: @Sendable () async -> Void

    /// キャンセルアクション
    let onCancel: @Sendable () async -> Void

    // MARK: - State

    /// 確認処理中かどうか
    @State private var isConfirming: Bool = false

    /// キャンセル処理中かどうか
    @State private var isCancelling: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - title: ダイアログのタイトル
    ///   - message: メインメッセージ
    ///   - details: 詳細情報（デフォルト: nil）
    ///   - style: ダイアログスタイル（デフォルト: .normal）
    ///   - confirmTitle: 確認ボタンのタイトル（デフォルト: "確認"）
    ///   - cancelTitle: キャンセルボタンのタイトル（デフォルト: "キャンセル"）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    public init(
        title: String,
        message: String,
        details: [ConfirmationDetail]? = nil,
        style: ConfirmationDialogStyle = .normal,
        confirmTitle: String = "確認",
        cancelTitle: String = "キャンセル",
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) {
        self.title = title
        self.message = message
        self.details = details
        self.style = style
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // 半透明背景オーバーレイ
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // 背景タップでキャンセル（破壊的アクション以外）
                    if style != .destructive {
                        Task {
                            await handleCancel()
                        }
                    }
                }
                .accessibilityHidden(true)

            // ダイアログカード
            VStack(spacing: 0) {
                // ヘッダー: アイコン + タイトル
                headerSection
                    .padding(.top, LRSpacing.xl)
                    .padding(.horizontal, LRSpacing.xl)

                // メインコンテンツ
                contentSection
                    .padding(.vertical, LRSpacing.lg)
                    .padding(.horizontal, LRSpacing.xl)

                // ボタンセクション
                buttonSection
                    .padding(.bottom, LRSpacing.xl)
                    .padding(.horizontal, LRSpacing.xl)
            }
            .frame(maxWidth: 340)
            .glassCard(cornerRadius: LRLayout.cornerRadiusXL, style: .thick)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    /// ヘッダーセクション（アイコン + タイトル）
    private var headerSection: some View {
        VStack(spacing: LRSpacing.md) {
            // スタイル別アイコン
            ZStack {
                Circle()
                    .fill(style.actionColor.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: style.actionIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(style.actionColor)
            }

            // タイトル
            Text(title)
                .font(Font.LightRoll.title3)
                .foregroundColor(Color.LightRoll.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    /// コンテンツセクション（メッセージ + 詳細）
    private var contentSection: some View {
        VStack(spacing: LRSpacing.md) {
            // メインメッセージ
            Text(message)
                .font(Font.LightRoll.body)
                .foregroundColor(Color.LightRoll.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // 詳細情報（存在する場合）
            if let details = details, !details.isEmpty {
                VStack(spacing: LRSpacing.sm) {
                    ForEach(details) { detail in
                        detailRow(detail)
                    }
                }
                .padding(.top, LRSpacing.sm)
            }
        }
    }

    /// 詳細情報行
    /// - Parameter detail: 詳細情報
    /// - Returns: 詳細情報表示ビュー
    private func detailRow(_ detail: ConfirmationDetail) -> some View {
        HStack(spacing: LRSpacing.sm) {
            // アイコン
            if let icon = detail.icon {
                Image(systemName: icon)
                    .font(.system(size: LRLayout.iconSizeSM))
                    .foregroundColor(detail.color ?? Color.LightRoll.textTertiary)
                    .frame(width: LRLayout.iconSizeMD)
            }

            // ラベル
            Text(detail.label)
                .font(Font.LightRoll.callout)
                .foregroundColor(Color.LightRoll.textSecondary)

            Spacer()

            // 値
            Text(detail.value)
                .font(Font.LightRoll.callout)
                .foregroundColor(detail.color ?? Color.LightRoll.textPrimary)
        }
        .padding(.horizontal, LRSpacing.md)
        .padding(.vertical, LRSpacing.sm)
        .background(
            RoundedRectangle(
                cornerRadius: LRLayout.cornerRadiusSM,
                style: .continuous
            )
            .fill(Color.LightRoll.surfaceCard.opacity(0.5))
        )
    }

    /// ボタンセクション
    private var buttonSection: some View {
        HStack(spacing: LRSpacing.md) {
            // キャンセルボタン
            ActionButton(
                title: cancelTitle,
                icon: "xmark",
                style: .secondary,
                isDisabled: isConfirming || isCancelling,
                isLoading: isCancelling
            ) {
                await handleCancel()
            }

            // 確認ボタン
            confirmButton
        }
    }

    /// 確認ボタン（スタイル別に色分け）
    @ViewBuilder
    private var confirmButton: some View {
        Button {
            Task {
                await handleConfirm()
            }
        } label: {
            HStack(spacing: LRSpacing.sm) {
                if isConfirming {
                    ProgressView()
                        .tint(.white)
                        .frame(width: LRLayout.iconSizeMD, height: LRLayout.iconSizeMD)

                    Text(confirmTitle)
                        .font(Font.LightRoll.headline)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: style.actionIcon)
                        .font(.system(size: LRLayout.iconSizeMD))
                        .foregroundColor(.white)

                    Text(confirmTitle)
                        .font(Font.LightRoll.headline)
                        .foregroundColor(.white)
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
            .fill(style.actionColor)
        )
        .opacity(effectiveConfirmOpacity)
        .disabled(isConfirming || isCancelling)
        .accessibilityLabel("\(confirmTitle)ボタン")
        .accessibilityHint(isConfirming ? "処理中です" : "タップして\(confirmTitle)")
        .accessibilityAddTraits(isConfirming || isCancelling ? [.isButton, .isStaticText] : .isButton)
    }

    // MARK: - Methods

    /// 確認処理
    private func handleConfirm() async {
        guard !isConfirming, !isCancelling else { return }

        isConfirming = true
        await onConfirm()
        isConfirming = false
    }

    /// キャンセル処理
    private func handleCancel() async {
        guard !isConfirming, !isCancelling else { return }

        isCancelling = true
        await onCancel()
        isCancelling = false
    }

    // MARK: - Computed Properties

    /// 確認ボタンの有効な不透明度
    private var effectiveConfirmOpacity: Double {
        if isConfirming {
            return 0.7
        } else if isCancelling {
            return 0.5
        } else {
            return 1.0
        }
    }

    /// アクセシビリティ用の説明文
    private var accessibilityDescription: String {
        var parts: [String] = []

        // タイトル
        parts.append(title)

        // メッセージ
        parts.append(message)

        // スタイル情報
        switch style {
        case .normal:
            parts.append("通常の確認")
        case .destructive:
            parts.append("破壊的アクション、注意が必要です")
        case .warning:
            parts.append("警告、慎重に確認してください")
        }

        // 詳細情報
        if let details = details, !details.isEmpty {
            let detailText = details.map { "\($0.label): \($0.value)" }.joined(separator: ", ")
            parts.append(detailText)
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - ConfirmationDetail

/// 確認ダイアログの詳細情報項目
public struct ConfirmationDetail: Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public let value: String
    public let icon: String?
    public let color: Color?

    /// イニシャライザ
    /// - Parameters:
    ///   - label: ラベル
    ///   - value: 値
    ///   - icon: アイコン（SF Symbol名、デフォルト: nil）
    ///   - color: 色（デフォルト: nil）
    public init(
        label: String,
        value: String,
        icon: String? = nil,
        color: Color? = nil
    ) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
}

// MARK: - Convenience Initializers

public extension ConfirmationDialog {
    /// 削除確認ダイアログ
    /// - Parameters:
    ///   - itemCount: 削除する項目数
    ///   - itemName: 項目名（例: "写真"、"グループ"）
    ///   - reclaimableSize: 削減可能容量（バイト数、nilの場合は表示しない）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: ConfirmationDialog
    static func deleteConfirmation(
        itemCount: Int,
        itemName: String = "写真",
        reclaimableSize: Int64? = nil,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> ConfirmationDialog {
        var details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: "削除枚数",
                value: "\(itemCount)枚",
                icon: "photo.stack",
                color: Color.LightRoll.textPrimary
            )
        ]

        if let size = reclaimableSize {
            details.append(
                ConfirmationDetail(
                    label: "削減容量",
                    value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                    icon: "arrow.down.circle",
                    color: Color.LightRoll.success
                )
            )
        }

        return ConfirmationDialog(
            title: "\(itemName)を削除しますか？",
            message: "削除した\(itemName)はゴミ箱に移動されます。30日後に完全に削除されます。",
            details: details,
            style: .destructive,
            confirmTitle: "削除",
            cancelTitle: "キャンセル",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// 永久削除確認ダイアログ
    /// - Parameters:
    ///   - itemCount: 削除する項目数
    ///   - itemName: 項目名（例: "写真"、"グループ"）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: ConfirmationDialog
    static func permanentDeleteConfirmation(
        itemCount: Int,
        itemName: String = "写真",
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> ConfirmationDialog {
        let details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: "削除枚数",
                value: "\(itemCount)枚",
                icon: "photo.stack",
                color: Color.LightRoll.error
            )
        ]

        return ConfirmationDialog(
            title: "完全に削除しますか？",
            message: "この操作は取り消せません。\(itemName)は完全に削除されます。",
            details: details,
            style: .destructive,
            confirmTitle: "完全削除",
            cancelTitle: "キャンセル",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// キャンセル確認ダイアログ
    /// - Parameters:
    ///   - processName: 処理名（例: "スキャン"、"削除"）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: ConfirmationDialog
    static func cancelConfirmation(
        processName: String,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> ConfirmationDialog {
        ConfirmationDialog(
            title: "\(processName)を中止しますか？",
            message: "進行中の処理が停止されます。",
            details: nil,
            style: .warning,
            confirmTitle: "中止",
            cancelTitle: "続行",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - View Extension

public extension View {
    /// 確認ダイアログを表示
    /// - Parameters:
    ///   - isPresented: 表示フラグ
    ///   - dialog: 確認ダイアログ
    /// - Returns: ダイアログが適用されたビュー
    func confirmationDialog(
        isPresented: Bool,
        dialog: @escaping @MainActor () -> ConfirmationDialog
    ) -> some View {
        self.overlay {
            if isPresented {
                dialog()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Preview

#if DEBUG
struct ConfirmationDialog_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
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

            ScrollView {
                VStack(spacing: LRSpacing.xxxl) {
                    Text("Confirmation Dialogs")
                        .font(Font.LightRoll.title2)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    // 削除確認ダイアログ（基本）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("削除確認ダイアログ")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ConfirmationDialog.deleteConfirmation(
                            itemCount: 24,
                            itemName: "写真",
                            reclaimableSize: 48_500_000
                        ) {
                            print("削除確認")
                        } onCancel: {
                            print("キャンセル")
                        }
                    }

                    // 永久削除確認ダイアログ
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("永久削除確認ダイアログ")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ConfirmationDialog.permanentDeleteConfirmation(
                            itemCount: 15,
                            itemName: "写真"
                        ) {
                            print("永久削除確認")
                        } onCancel: {
                            print("キャンセル")
                        }
                    }

                    // キャンセル確認ダイアログ
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("キャンセル確認ダイアログ")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ConfirmationDialog.cancelConfirmation(
                            processName: "スキャン"
                        ) {
                            print("中止確認")
                        } onCancel: {
                            print("続行")
                        }
                    }

                    // カスタム確認ダイアログ（通常スタイル）
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("カスタム確認ダイアログ（通常）")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ConfirmationDialog(
                            title: "設定をリセットしますか？",
                            message: "すべての設定が初期値に戻ります。",
                            details: [
                                ConfirmationDetail(
                                    label: "対象",
                                    value: "アプリ設定",
                                    icon: "gear"
                                )
                            ],
                            style: .normal,
                            confirmTitle: "リセット",
                            cancelTitle: "キャンセル"
                        ) {
                            print("リセット確認")
                        } onCancel: {
                            print("キャンセル")
                        }
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
        .previewDisplayName("Confirmation Dialog (Dark)")

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
                ConfirmationDialog.deleteConfirmation(
                    itemCount: 10,
                    itemName: "写真",
                    reclaimableSize: 25_000_000
                ) {
                    print("削除")
                } onCancel: {
                    print("キャンセル")
                }

                ConfirmationDialog.permanentDeleteConfirmation(
                    itemCount: 5,
                    itemName: "写真"
                ) {
                    print("永久削除")
                } onCancel: {
                    print("キャンセル")
                }
            }
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Confirmation Dialog (Light)")
    }
}

// MARK: - Demo View

/// デモ用のインタラクティブビュー
private struct DemoView: View {
    @State private var showDeleteDialog = false
    @State private var showCancelDialog = false

    var body: some View {
        VStack(spacing: LRSpacing.md) {
            ActionButton(
                title: "削除確認ダイアログを表示",
                icon: "trash",
                style: .primary
            ) {
                showDeleteDialog = true
            }

            ActionButton(
                title: "キャンセル確認ダイアログを表示",
                icon: "xmark.circle",
                style: .secondary
            ) {
                showCancelDialog = true
            }
        }
        .padding()
        .glassCard(cornerRadius: LRLayout.cornerRadiusLG)
        .confirmationDialog(isPresented: showDeleteDialog) {
            ConfirmationDialog.deleteConfirmation(
                itemCount: 50,
                itemName: "写真",
                reclaimableSize: 120_000_000
            ) {
                showDeleteDialog = false
                print("削除実行")
            } onCancel: {
                showDeleteDialog = false
                print("削除キャンセル")
            }
        }
        .confirmationDialog(isPresented: showCancelDialog) {
            ConfirmationDialog.cancelConfirmation(
                processName: "スキャン処理"
            ) {
                showCancelDialog = false
                print("中止")
            } onCancel: {
                showCancelDialog = false
                print("続行")
            }
        }
    }
}
#endif
