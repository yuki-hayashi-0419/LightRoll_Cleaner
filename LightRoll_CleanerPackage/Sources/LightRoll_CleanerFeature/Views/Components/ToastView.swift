//
//  ToastView.swift
//  LightRoll_CleanerFeature
//
//  トースト通知コンポーネント
//  成功、エラー、警告、情報の4タイプのトースト表示に対応
//  自動消去、スワイプジェスチャー、アニメーション、アクセシビリティ完全対応
//  Created by AI Assistant
//

import SwiftUI

// MARK: - Toast Type

/// トーストの通知タイプ
public enum ToastType: Sendable {
    /// 成功（緑系アクセントカラー）
    case success
    /// エラー（赤系エラーカラー）
    case error
    /// 警告（オレンジ系警告カラー）
    case warning
    /// 情報（ブルー系プライマリカラー）
    case info

    /// デフォルトアイコン
    @MainActor
    var defaultIcon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    /// アイコンカラー
    @MainActor
    var iconColor: Color {
        switch self {
        case .success:
            return Color.LightRoll.success
        case .error:
            return Color.LightRoll.error
        case .warning:
            return Color.LightRoll.warning
        case .info:
            return Color.LightRoll.primary
        }
    }

    /// アクセントカラー
    @MainActor
    var accentColor: Color {
        switch self {
        case .success:
            return Color.LightRoll.success
        case .error:
            return Color.LightRoll.error
        case .warning:
            return Color.LightRoll.warning
        case .info:
            return Color.LightRoll.primary
        }
    }
}

// MARK: - Toast Item

/// トースト通知のデータモデル
public struct ToastItem: Sendable, Identifiable {
    // MARK: - Properties

    /// 一意の識別子
    public let id: UUID

    /// トーストのタイプ
    public let type: ToastType

    /// タイトル（必須、太字）
    public let title: String

    /// メッセージ（オプション、通常フォント）
    public let message: String?

    /// カスタムアイコン（オプション、未指定時はtypeのデフォルトを使用）
    public let customIcon: String?

    /// 自動消去までの秒数（nilの場合は自動消去しない）
    public let duration: TimeInterval?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - type: トーストのタイプ（デフォルト: .info）
    ///   - title: タイトル
    ///   - message: メッセージ（デフォルト: nil）
    ///   - customIcon: カスタムアイコン（デフォルト: nil）
    ///   - duration: 自動消去までの秒数（デフォルト: 3秒）
    public init(
        type: ToastType = .info,
        title: String,
        message: String? = nil,
        customIcon: String? = nil,
        duration: TimeInterval? = 3.0
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.customIcon = customIcon
        self.duration = duration
    }

    // MARK: - Computed Properties

    /// 表示するアイコン
    @MainActor
    var displayIcon: String {
        customIcon ?? type.defaultIcon
    }
}

// MARK: - Toast View

/// トースト通知コンポーネント
/// 成功、エラー、警告、情報の4タイプに対応
/// 自動消去、スワイプジェスチャー、アニメーション対応
@MainActor
public struct ToastView: View {
    // MARK: - Properties

    /// トースト通知データ
    let toast: ToastItem

    /// 消去時のコールバック
    let onDismiss: @Sendable () async -> Void

    // MARK: - State

    /// 表示オフセット（スワイプ用）
    @State private var offset: CGFloat = 0

    /// 消去中フラグ
    @State private var isDismissing: Bool = false

    // MARK: - Environment

    /// カラースキーム
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - toast: トースト通知データ
    ///   - onDismiss: 消去時のコールバック
    public init(
        toast: ToastItem,
        onDismiss: @escaping @Sendable () async -> Void
    ) {
        self.toast = toast
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: LRSpacing.md) {
            // アイコン
            Image(systemName: toast.displayIcon)
                .font(.system(size: LRLayout.iconSizeLG, weight: .semibold))
                .foregroundColor(toast.type.iconColor)
                .accessibilityHidden(true)

            // テキストコンテンツ
            VStack(alignment: .leading, spacing: LRSpacing.xs) {
                // タイトル
                Text(toast.title)
                    .font(Font.LightRoll.headline)
                    .foregroundColor(Color.LightRoll.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // メッセージ（オプション）
                if let message = toast.message {
                    Text(message)
                        .font(Font.LightRoll.callout)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 閉じるボタン
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: LRLayout.iconSizeSM, weight: .semibold))
                    .foregroundColor(Color.LightRoll.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.LightRoll.textTertiary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("閉じる")
            .accessibilityHint("トースト通知を閉じます")
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(toastBackground)
        .clipShape(RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG, style: .continuous))
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 12,
            x: 0,
            y: 4
        )
        .offset(y: offset)
        .opacity(isDismissing ? 0 : 1)
        .gesture(swipeGesture)
        .onTapGesture {
            dismiss()
        }
        .task {
            await startDismissTimer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("タップまたはスワイプで閉じることができます")
    }

    // MARK: - Subviews

    /// トースト背景
    @ViewBuilder
    private var toastBackground: some View {
        ZStack {
            // グラスモーフィズム背景
            RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG, style: .continuous)
                .fill(.regularMaterial)

            // アクセントカラーのグラデーション（左端）
            LinearGradient(
                colors: [
                    toast.type.accentColor.opacity(0.3),
                    toast.type.accentColor.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG, style: .continuous))

            // ボーダー
            RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Gestures

    /// スワイプジェスチャー
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // 上方向のスワイプのみ許可
                if value.translation.height < 0 {
                    offset = value.translation.height
                }
            }
            .onEnded { value in
                // しきい値を超えたら消去
                if value.translation.height < -50 || value.predictedEndTranslation.height < -100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = -200
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(200))
                        dismiss()
                    }
                } else {
                    // 元に戻す
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                    }
                }
            }
    }

    // MARK: - Methods

    /// 消去処理
    private func dismiss() {
        guard !isDismissing else { return }

        isDismissing = true
        withAnimation(.easeInOut(duration: 0.2)) {
            offset = -100
        }

        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await onDismiss()
        }
    }

    /// 自動消去タイマー開始
    private func startDismissTimer() async {
        guard let duration = toast.duration else { return }

        try? await Task.sleep(for: .seconds(duration))

        // キャンセルされていなければ消去
        if !Task.isCancelled && !isDismissing {
            dismiss()
        }
    }

    // MARK: - Accessibility

    /// アクセシビリティ用の説明文
    private var accessibilityDescription: String {
        var parts: [String] = []

        // タイプ
        switch toast.type {
        case .success:
            parts.append("成功")
        case .error:
            parts.append("エラー")
        case .warning:
            parts.append("警告")
        case .info:
            parts.append("情報")
        }

        // タイトル
        parts.append(toast.title)

        // メッセージ
        if let message = toast.message {
            parts.append(message)
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Toast Container

/// トースト通知を表示するコンテナ
/// 複数のトーストをスタック表示
@MainActor
public struct ToastContainer: View {
    // MARK: - Properties

    /// 表示中のトーストリスト
    @Binding var toasts: [ToastItem]

    /// 最大表示数
    let maxToasts: Int

    // MARK: - Constants

    /// トースト間のスペース
    private let toastSpacing: CGFloat = LRSpacing.sm

    /// 上部マージン（Safe Areaを考慮）
    private let topMargin: CGFloat = LRSpacing.md

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - toasts: 表示中のトーストリスト
    ///   - maxToasts: 最大表示数（デフォルト: 3）
    public init(
        toasts: Binding<[ToastItem]>,
        maxToasts: Int = 3
    ) {
        self._toasts = toasts
        self.maxToasts = maxToasts
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: toastSpacing) {
            ForEach(Array(toasts.prefix(maxToasts))) { toast in
                ToastView(toast: toast) {
                    await MainActor.run {
                        removeToast(toast)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.top, topMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toasts.map(\.id))
    }

    // MARK: - Methods

    /// トーストを削除
    /// - Parameter toast: 削除するトースト
    private func removeToast(_ toast: ToastItem) {
        toasts.removeAll { $0.id == toast.id }
    }
}

// MARK: - View Extension

public extension View {
    /// トーストコンテナを表示
    /// - Parameters:
    ///   - toasts: 表示するトーストリスト
    ///   - maxToasts: 最大表示数（デフォルト: 3）
    /// - Returns: トーストコンテナがオーバーレイされたビュー
    func toastContainer(
        toasts: Binding<[ToastItem]>,
        maxToasts: Int = 3
    ) -> some View {
        self.overlay(alignment: .top) {
            ToastContainer(toasts: toasts, maxToasts: maxToasts)
                .allowsHitTesting(!toasts.wrappedValue.isEmpty)
        }
    }
}

// MARK: - Convenience Constructors

public extension ToastItem {
    /// 成功トースト
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - duration: 自動消去までの秒数（デフォルト: 3秒）
    /// - Returns: 成功タイプのToastItem
    static func success(
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 3.0
    ) -> ToastItem {
        ToastItem(
            type: .success,
            title: title,
            message: message,
            duration: duration
        )
    }

    /// エラートースト
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - duration: 自動消去までの秒数（デフォルト: 4秒、エラーは少し長め）
    /// - Returns: エラータイプのToastItem
    static func error(
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 4.0
    ) -> ToastItem {
        ToastItem(
            type: .error,
            title: title,
            message: message,
            duration: duration
        )
    }

    /// 警告トースト
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - duration: 自動消去までの秒数（デフォルト: 3.5秒）
    /// - Returns: 警告タイプのToastItem
    static func warning(
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 3.5
    ) -> ToastItem {
        ToastItem(
            type: .warning,
            title: title,
            message: message,
            duration: duration
        )
    }

    /// 情報トースト
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - duration: 自動消去までの秒数（デフォルト: 3秒）
    /// - Returns: 情報タイプのToastItem
    static func info(
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 3.0
    ) -> ToastItem {
        ToastItem(
            type: .info,
            title: title,
            message: message,
            duration: duration
        )
    }
}

// MARK: - Sendable Conformance

extension ToastType: Equatable {}
extension ToastType: Hashable {}

// MARK: - Preview

#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        PreviewContainer()
            .preferredColorScheme(.dark)
            .previewDisplayName("Toast View (Dark)")

        // ライトモードプレビュー
        PreviewContainer()
            .preferredColorScheme(.light)
            .previewDisplayName("Toast View (Light)")
    }
}

// MARK: - Preview Container

/// プレビュー用コンテナ
private struct PreviewContainer: View {
    @State private var toasts: [ToastItem] = []

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // コントロールパネル
            ScrollView {
                VStack(spacing: LRSpacing.xxl) {
                    Text("Toast Notifications")
                        .font(Font.LightRoll.title1)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    // 成功トースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("成功トースト")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "成功通知を表示",
                            icon: "checkmark.circle",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showSuccessToast()
                            }
                        }
                    }

                    // エラートースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("エラートースト")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "エラー通知を表示",
                            icon: "xmark.circle",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showErrorToast()
                            }
                        }
                    }

                    // 警告トースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("警告トースト")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "警告通知を表示",
                            icon: "exclamationmark.triangle",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showWarningToast()
                            }
                        }
                    }

                    // 情報トースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("情報トースト")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "情報通知を表示",
                            icon: "info.circle",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showInfoToast()
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // 複数トースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("複数トースト同時表示")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "複数通知を表示",
                            icon: "square.stack.3d.up",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showMultipleToasts()
                            }
                        }
                    }

                    // メッセージ付きトースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("詳細メッセージ付き")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "詳細通知を表示",
                            icon: "text.bubble",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showDetailedToast()
                            }
                        }
                    }

                    // カスタムアイコン
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("カスタムアイコン")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "カスタム通知を表示",
                            icon: "star.fill",
                            style: .primary
                        ) {
                            await MainActor.run {
                                showCustomIconToast()
                            }
                        }
                    }

                    // 手動消去トースト
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("手動消去のみ")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "永続通知を表示",
                            icon: "pin.fill",
                            style: .secondary
                        ) {
                            await MainActor.run {
                                showPersistentToast()
                            }
                        }
                    }

                    // 全てクリア
                    VStack(alignment: .leading, spacing: LRSpacing.md) {
                        Text("管理")
                            .font(Font.LightRoll.headline)
                            .foregroundColor(Color.LightRoll.textPrimary)

                        ActionButton(
                            title: "全て消去",
                            icon: "trash",
                            style: .secondary
                        ) {
                            await MainActor.run {
                                clearAllToasts()
                            }
                        }
                    }

                    // 現在の表示数
                    if !toasts.isEmpty {
                        Text("表示中: \(toasts.count)件")
                            .font(Font.LightRoll.caption)
                            .foregroundColor(Color.LightRoll.textSecondary)
                    }
                }
                .padding()
            }
        }
        .toastContainer(toasts: $toasts)
    }

    // MARK: - Toast Actions

    private func showSuccessToast() {
        toasts.append(.success(
            title: "削除完了",
            message: "24枚の写真を削除しました"
        ))
    }

    private func showErrorToast() {
        toasts.append(.error(
            title: "削除失敗",
            message: "写真の削除中にエラーが発生しました"
        ))
    }

    private func showWarningToast() {
        toasts.append(.warning(
            title: "ストレージ容量不足",
            message: "残り容量が10%未満です"
        ))
    }

    private func showInfoToast() {
        toasts.append(.info(
            title: "スキャン完了",
            message: "120枚の写真を分析しました"
        ))
    }

    private func showMultipleToasts() {
        toasts.append(.success(title: "操作1完了"))
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            toasts.append(.info(title: "処理2開始"))
        }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            toasts.append(.warning(title: "注意事項"))
        }
    }

    private func showDetailedToast() {
        toasts.append(.success(
            title: "バックアップ完了",
            message: "iCloudに1,234枚の写真をバックアップしました。削除候補の写真は安全に削除できます。"
        ))
    }

    private func showCustomIconToast() {
        toasts.append(ToastItem(
            type: .info,
            title: "お気に入りに追加",
            message: "この写真をお気に入りに追加しました",
            customIcon: "star.fill"
        ))
    }

    private func showPersistentToast() {
        toasts.append(ToastItem(
            type: .warning,
            title: "重要なお知らせ",
            message: "タップまたはスワイプで閉じてください",
            duration: nil
        ))
    }

    private func clearAllToasts() {
        toasts.removeAll()
    }
}

// MARK: - Modern Previews (iOS 17+)

#Preview("成功トースト") {
    VStack {
        Spacer()
        ToastView(toast: ToastItem(
            type: .success,
            title: "削除完了",
            message: "24枚の写真を削除しました"
        ), onDismiss: {})
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

#Preview("エラートースト") {
    VStack {
        Spacer()
        ToastView(toast: ToastItem(
            type: .error,
            title: "削除失敗",
            message: "写真へのアクセス権限がありません"
        ), onDismiss: {})
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

#Preview("警告トースト") {
    VStack {
        Spacer()
        ToastView(toast: ToastItem(
            type: .warning,
            title: "ストレージ容量不足",
            message: "残り2GBです。写真を削除してください"
        ), onDismiss: {})
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

#Preview("情報トースト") {
    VStack {
        Spacer()
        ToastView(toast: ToastItem(
            type: .info,
            title: "スキャン開始",
            message: "重複写真を検出しています..."
        ), onDismiss: {})
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
