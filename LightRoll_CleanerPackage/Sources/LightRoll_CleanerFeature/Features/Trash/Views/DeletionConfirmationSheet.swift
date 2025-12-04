//
//  DeletionConfirmationSheet.swift
//  LightRoll_CleanerFeature
//
//  削除確認シート
//  DeletionConfirmationServiceと連携し、削除・復元・永久削除の確認ダイアログを表示
//  再利用可能なSheetコンポーネント
//  Created by AI Assistant
//

import SwiftUI

// MARK: - DeletionConfirmationSheet

/// 削除確認シート
/// DeletionConfirmationServiceと連携し、削除・復元・永久削除の確認ダイアログを表示
///
/// ## 主な機能
/// - DeletionConfirmationServiceからのメッセージを表示
/// - ConfirmationDialogコンポーネントをラップ
/// - 確認/キャンセルアクションの処理
/// - アニメーション付きプレゼンテーション
///
/// ## 使用例
/// ```swift
/// @State private var showConfirmation = false
/// @State private var confirmationMessage: ConfirmationMessage?
///
/// // シート表示
/// .sheet(isPresented: $showConfirmation) {
///     DeletionConfirmationSheet(
///         message: confirmationMessage,
///         onConfirm: {
///             await performDeletion()
///         },
///         onCancel: {
///             showConfirmation = false
///         }
///     )
/// }
/// ```
@MainActor
public struct DeletionConfirmationSheet: View {

    // MARK: - Properties

    /// 確認メッセージ
    let message: ConfirmationMessage?

    /// 確認アクション
    let onConfirm: @Sendable () async -> Void

    /// キャンセルアクション
    let onCancel: @Sendable () async -> Void

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - message: 確認メッセージ（nilの場合はデフォルトメッセージを表示）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    public init(
        message: ConfirmationMessage?,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) {
        self.message = message
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        if let message = message {
            // メッセージが存在する場合: ConfirmationDialogを表示
            ConfirmationDialog(
                title: message.title,
                message: message.message,
                details: message.details.isEmpty ? nil : message.details,
                style: message.style,
                confirmTitle: message.confirmTitle,
                cancelTitle: message.cancelTitle,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(LRLayout.cornerRadiusXL)
        } else {
            // メッセージがない場合: デフォルトのエラー表示
            defaultErrorView
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(LRLayout.cornerRadiusXL)
        }
    }

    // MARK: - Default Error View

    /// デフォルトのエラービュー（メッセージがない場合）
    private var defaultErrorView: some View {
        VStack(spacing: LRSpacing.lg) {
            // エラーアイコン
            ZStack {
                Circle()
                    .fill(Color.LightRoll.error.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color.LightRoll.error)
            }

            // エラーメッセージ
            VStack(spacing: LRSpacing.sm) {
                Text("エラーが発生しました")
                    .font(.LightRoll.title3)
                    .foregroundColor(Color.LightRoll.textPrimary)

                Text("確認メッセージの読み込みに失敗しました")
                    .font(.LightRoll.body)
                    .foregroundColor(Color.LightRoll.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // 閉じるボタン
            ActionButton(
                title: "閉じる",
                icon: "xmark",
                style: .secondary
            ) {
                await onCancel()
            }
            .padding(.horizontal, LRSpacing.xl)
        }
        .padding(LRSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.LightRoll.background)
    }
}

// MARK: - View Extension

public extension View {
    /// 削除確認シートを表示
    /// - Parameters:
    ///   - isPresented: 表示フラグ
    ///   - message: 確認メッセージ（nilの場合はデフォルトメッセージを表示）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: シートが適用されたビュー
    func deletionConfirmationSheet(
        isPresented: Binding<Bool>,
        message: ConfirmationMessage?,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            DeletionConfirmationSheet(
                message: message,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        }
    }
}

// MARK: - Convenience Initializers

public extension DeletionConfirmationSheet {
    /// 削除確認シート（DeletionConfirmationServiceから生成）
    /// - Parameters:
    ///   - service: DeletionConfirmationService
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - actionType: アクションのタイプ
    ///   - itemName: 項目名（デフォルト: "写真"）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: DeletionConfirmationSheet
    static func from(
        service: DeletionConfirmationServiceProtocol,
        photoCount: Int,
        totalSize: Int64? = nil,
        actionType: ConfirmationActionType,
        itemName: String = "写真",
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> DeletionConfirmationSheet {
        let message = service.formatConfirmationMessage(
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: actionType,
            itemName: itemName
        )

        return DeletionConfirmationSheet(
            message: message,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// 削除確認シート（簡易版）
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: DeletionConfirmationSheet
    static func deleteConfirmation(
        photoCount: Int,
        totalSize: Int64? = nil,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> DeletionConfirmationSheet {
        let service = DeletionConfirmationService()
        return from(
            service: service,
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: .delete,
            itemName: "写真",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// 復元確認シート（簡易版）
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: DeletionConfirmationSheet
    static func restoreConfirmation(
        photoCount: Int,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> DeletionConfirmationSheet {
        let service = DeletionConfirmationService()
        return from(
            service: service,
            photoCount: photoCount,
            totalSize: nil,
            actionType: .restore,
            itemName: "写真",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// 永久削除確認シート（簡易版）
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: DeletionConfirmationSheet
    static func permanentDeleteConfirmation(
        photoCount: Int,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> DeletionConfirmationSheet {
        let service = DeletionConfirmationService()
        return from(
            service: service,
            photoCount: photoCount,
            totalSize: nil,
            actionType: .permanentDelete,
            itemName: "写真",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    /// ゴミ箱を空にする確認シート（簡易版）
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: DeletionConfirmationSheet
    static func emptyTrashConfirmation(
        photoCount: Int,
        totalSize: Int64? = nil,
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> DeletionConfirmationSheet {
        let service = DeletionConfirmationService()
        return from(
            service: service,
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: .emptyTrash,
            itemName: "写真",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - Preview

#if DEBUG
struct DeletionConfirmationSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 削除確認シート
            VStack {
                Text("削除確認シート")
                    .font(.LightRoll.title2)
            }
            .sheet(isPresented: .constant(true)) {
                DeletionConfirmationSheet.deleteConfirmation(
                    photoCount: 24,
                    totalSize: 48_500_000
                ) {
                    print("削除実行")
                } onCancel: {
                    print("キャンセル")
                }
            }
            .previewDisplayName("削除確認")

            // 復元確認シート
            VStack {
                Text("復元確認シート")
                    .font(.LightRoll.title2)
            }
            .sheet(isPresented: .constant(true)) {
                DeletionConfirmationSheet.restoreConfirmation(
                    photoCount: 15
                ) {
                    print("復元実行")
                } onCancel: {
                    print("キャンセル")
                }
            }
            .previewDisplayName("復元確認")

            // 永久削除確認シート
            VStack {
                Text("永久削除確認シート")
                    .font(.LightRoll.title2)
            }
            .sheet(isPresented: .constant(true)) {
                DeletionConfirmationSheet.permanentDeleteConfirmation(
                    photoCount: 8
                ) {
                    print("永久削除実行")
                } onCancel: {
                    print("キャンセル")
                }
            }
            .previewDisplayName("永久削除確認")

            // ゴミ箱を空にする確認シート
            VStack {
                Text("ゴミ箱を空にする確認シート")
                    .font(.LightRoll.title2)
            }
            .sheet(isPresented: .constant(true)) {
                DeletionConfirmationSheet.emptyTrashConfirmation(
                    photoCount: 127,
                    totalSize: 256_000_000
                ) {
                    print("ゴミ箱を空にする実行")
                } onCancel: {
                    print("キャンセル")
                }
            }
            .previewDisplayName("ゴミ箱を空にする確認")

            // エラーケース（メッセージなし）
            VStack {
                Text("エラーケース")
                    .font(.LightRoll.title2)
            }
            .sheet(isPresented: .constant(true)) {
                DeletionConfirmationSheet(
                    message: nil,
                    onConfirm: {
                        print("確認")
                    },
                    onCancel: {
                        print("キャンセル")
                    }
                )
            }
            .previewDisplayName("エラーケース")
        }
        .preferredColorScheme(.dark)
    }
}

/// デモ用のインタラクティブビュー
struct DeletionConfirmationSheetDemo: View {
    @State private var showDeleteSheet = false
    @State private var showRestoreSheet = false
    @State private var showPermanentDeleteSheet = false
    @State private var showEmptyTrashSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LRSpacing.lg) {
                    // 削除確認
                    ActionButton(
                        title: "削除確認シートを表示",
                        icon: "trash",
                        style: .primary
                    ) {
                        showDeleteSheet = true
                    }

                    // 復元確認
                    ActionButton(
                        title: "復元確認シートを表示",
                        icon: "arrow.uturn.backward",
                        style: .primary
                    ) {
                        showRestoreSheet = true
                    }

                    // 永久削除確認
                    ActionButton(
                        title: "永久削除確認シートを表示",
                        icon: "trash.slash",
                        style: .primary
                    ) {
                        showPermanentDeleteSheet = true
                    }

                    // ゴミ箱を空にする確認
                    ActionButton(
                        title: "ゴミ箱を空にする確認シートを表示",
                        icon: "trash.circle",
                        style: .primary
                    ) {
                        showEmptyTrashSheet = true
                    }
                }
                .padding(LRSpacing.lg)
            }
            .navigationTitle("DeletionConfirmationSheet Demo")
            .background(Color.LightRoll.background)
            .sheet(isPresented: $showDeleteSheet) {
                DeletionConfirmationSheet.deleteConfirmation(
                    photoCount: 24,
                    totalSize: 48_500_000
                ) {
                    showDeleteSheet = false
                    print("削除実行")
                } onCancel: {
                    showDeleteSheet = false
                    print("削除キャンセル")
                }
            }
            .sheet(isPresented: $showRestoreSheet) {
                DeletionConfirmationSheet.restoreConfirmation(
                    photoCount: 15
                ) {
                    showRestoreSheet = false
                    print("復元実行")
                } onCancel: {
                    showRestoreSheet = false
                    print("復元キャンセル")
                }
            }
            .sheet(isPresented: $showPermanentDeleteSheet) {
                DeletionConfirmationSheet.permanentDeleteConfirmation(
                    photoCount: 8
                ) {
                    showPermanentDeleteSheet = false
                    print("永久削除実行")
                } onCancel: {
                    showPermanentDeleteSheet = false
                    print("永久削除キャンセル")
                }
            }
            .sheet(isPresented: $showEmptyTrashSheet) {
                DeletionConfirmationSheet.emptyTrashConfirmation(
                    photoCount: 127,
                    totalSize: 256_000_000
                ) {
                    showEmptyTrashSheet = false
                    print("ゴミ箱を空にする実行")
                } onCancel: {
                    showEmptyTrashSheet = false
                    print("ゴミ箱を空にするキャンセル")
                }
            }
        }
    }
}

#Preview("Demo") {
    DeletionConfirmationSheetDemo()
        .preferredColorScheme(.dark)
}
#endif
