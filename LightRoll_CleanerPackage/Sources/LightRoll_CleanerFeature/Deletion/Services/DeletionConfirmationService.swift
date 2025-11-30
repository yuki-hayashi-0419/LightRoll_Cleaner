//
//  DeletionConfirmationService.swift
//  LightRoll_CleanerFeature
//
//  削除確認サービス
//  ConfirmationDialogと統合し、削除・復元・永久削除の確認メッセージを生成
//  Created by AI Assistant
//

import SwiftUI

// MARK: - ConfirmationActionType

/// 確認アクションのタイプ
public enum ConfirmationActionType: Sendable {
    /// 削除（ゴミ箱へ移動）
    case delete
    /// 復元
    case restore
    /// 永久削除
    case permanentDelete
    /// ゴミ箱を空にする
    case emptyTrash
    /// キャンセル（処理中断）
    case cancel
}

// MARK: - ConfirmationMessage

/// 確認メッセージ
public struct ConfirmationMessage: Sendable {
    /// タイトル
    public let title: String
    /// メッセージ本文
    public let message: String
    /// 詳細情報
    public let details: [ConfirmationDetail]
    /// ダイアログスタイル
    public let style: ConfirmationDialogStyle
    /// 確認ボタンのタイトル
    public let confirmTitle: String
    /// キャンセルボタンのタイトル
    public let cancelTitle: String

    /// イニシャライザ
    public init(
        title: String,
        message: String,
        details: [ConfirmationDetail] = [],
        style: ConfirmationDialogStyle = .normal,
        confirmTitle: String = "確認",
        cancelTitle: String = "キャンセル"
    ) {
        self.title = title
        self.message = message
        self.details = details
        self.style = style
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
    }
}

// MARK: - DeletionConfirmationServiceProtocol

/// 削除確認サービスのプロトコル
public protocol DeletionConfirmationServiceProtocol: Sendable {
    /// 確認ダイアログを表示すべきかどうか
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - actionType: アクションのタイプ
    /// - Returns: 確認ダイアログを表示すべき場合はtrue
    func shouldShowConfirmation(photoCount: Int, actionType: ConfirmationActionType) -> Bool

    /// 確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - actionType: アクションのタイプ
    ///   - itemName: 項目名（デフォルト: "写真"）
    /// - Returns: 確認メッセージ
    func formatConfirmationMessage(
        photoCount: Int,
        totalSize: Int64?,
        actionType: ConfirmationActionType,
        itemName: String
    ) -> ConfirmationMessage
}

// MARK: - DeletionConfirmationService

/// 削除確認サービスの実装
/// ConfirmationDialogと統合し、削除・復元・永久削除の確認メッセージを生成
///
/// ## 主な責務
/// - 削除確認の閾値判定
/// - 確認メッセージの生成
/// - ConfirmationDialogとの統合
///
/// ## 使用例
/// ```swift
/// let service = DeletionConfirmationService()
///
/// // 確認が必要かチェック
/// if service.shouldShowConfirmation(photoCount: 10, actionType: .delete) {
///     // 確認メッセージを生成
///     let message = service.formatConfirmationMessage(
///         photoCount: 10,
///         totalSize: 5_000_000,
///         actionType: .delete,
///         itemName: "写真"
///     )
///
///     // ConfirmationDialogに渡す
///     // ...
/// }
/// ```
public final class DeletionConfirmationService: DeletionConfirmationServiceProtocol {

    // MARK: - Properties

    /// 確認ダイアログを表示する最小枚数
    private let minCountForConfirmation: Int

    /// 大量削除警告の閾値
    private let largeCountThreshold: Int

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - minCountForConfirmation: 確認ダイアログを表示する最小枚数（デフォルト: 1）
    ///   - largeCountThreshold: 大量削除警告の閾値（デフォルト: 50）
    public init(
        minCountForConfirmation: Int = 1,
        largeCountThreshold: Int = 50
    ) {
        self.minCountForConfirmation = minCountForConfirmation
        self.largeCountThreshold = largeCountThreshold
    }

    // MARK: - Public Methods

    /// 確認ダイアログを表示すべきかどうか
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - actionType: アクションのタイプ
    /// - Returns: 確認ダイアログを表示すべき場合はtrue
    public func shouldShowConfirmation(
        photoCount: Int,
        actionType: ConfirmationActionType
    ) -> Bool {
        // 写真が0枚の場合は確認不要
        guard photoCount > 0 else { return false }

        // アクションタイプ別の判定
        switch actionType {
        case .delete, .permanentDelete, .emptyTrash:
            // 削除系は常に確認
            return photoCount >= minCountForConfirmation
        case .restore:
            // 復元は10枚以上で確認
            return photoCount >= 10
        case .cancel:
            // キャンセルは常に確認
            return true
        }
    }

    /// 確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - actionType: アクションのタイプ
    ///   - itemName: 項目名（デフォルト: "写真"）
    /// - Returns: 確認メッセージ
    public func formatConfirmationMessage(
        photoCount: Int,
        totalSize: Int64? = nil,
        actionType: ConfirmationActionType,
        itemName: String = "写真"
    ) -> ConfirmationMessage {
        switch actionType {
        case .delete:
            return createDeleteMessage(
                photoCount: photoCount,
                totalSize: totalSize,
                itemName: itemName
            )
        case .restore:
            return createRestoreMessage(
                photoCount: photoCount,
                itemName: itemName
            )
        case .permanentDelete:
            return createPermanentDeleteMessage(
                photoCount: photoCount,
                itemName: itemName
            )
        case .emptyTrash:
            return createEmptyTrashMessage(
                photoCount: photoCount,
                totalSize: totalSize
            )
        case .cancel:
            return createCancelMessage()
        }
    }

    // MARK: - Private Methods

    /// 削除確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    ///   - itemName: 項目名
    /// - Returns: 確認メッセージ
    private func createDeleteMessage(
        photoCount: Int,
        totalSize: Int64?,
        itemName: String
    ) -> ConfirmationMessage {
        // 大量削除の警告
        let isLargeCount = photoCount >= largeCountThreshold

        // タイトル
        let title: String
        if isLargeCount {
            title = NSLocalizedString(
                "deletionConfirmation.delete.title.large",
                value: "大量の\(itemName)を削除しますか？",
                comment: "Large delete title"
            )
        } else {
            title = NSLocalizedString(
                "deletionConfirmation.delete.title",
                value: "\(itemName)を削除しますか？",
                comment: "Delete title"
            )
        }

        // メッセージ
        let message = NSLocalizedString(
            "deletionConfirmation.delete.message",
            value: "削除した\(itemName)はゴミ箱に移動されます。30日後に完全に削除されます。",
            comment: "Delete message"
        )

        // 詳細情報
        var details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: NSLocalizedString(
                    "deletionConfirmation.delete.detail.count",
                    value: "削除枚数",
                    comment: "Delete count label"
                ),
                value: "\(photoCount)枚",
                icon: "photo.stack",
                color: Color.LightRoll.textPrimary
            )
        ]

        // サイズ情報を追加
        if let size = totalSize {
            details.append(
                ConfirmationDetail(
                    label: NSLocalizedString(
                        "deletionConfirmation.delete.detail.size",
                        value: "削減容量",
                        comment: "Freed size label"
                    ),
                    value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                    icon: "arrow.down.circle",
                    color: Color.LightRoll.success
                )
            )
        }

        return ConfirmationMessage(
            title: title,
            message: message,
            details: details,
            style: .destructive,
            confirmTitle: NSLocalizedString(
                "deletionConfirmation.delete.confirm",
                value: "削除",
                comment: "Delete confirm button"
            ),
            cancelTitle: NSLocalizedString(
                "deletionConfirmation.cancel",
                value: "キャンセル",
                comment: "Cancel button"
            )
        )
    }

    /// 復元確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - itemName: 項目名
    /// - Returns: 確認メッセージ
    private func createRestoreMessage(
        photoCount: Int,
        itemName: String
    ) -> ConfirmationMessage {
        let title = NSLocalizedString(
            "deletionConfirmation.restore.title",
            value: "\(itemName)を復元しますか？",
            comment: "Restore title"
        )

        let message = NSLocalizedString(
            "deletionConfirmation.restore.message",
            value: "選択した\(itemName)をゴミ箱から復元します。",
            comment: "Restore message"
        )

        let details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: NSLocalizedString(
                    "deletionConfirmation.restore.detail.count",
                    value: "復元枚数",
                    comment: "Restore count label"
                ),
                value: "\(photoCount)枚",
                icon: "arrow.uturn.backward.circle",
                color: Color.LightRoll.primary
            )
        ]

        return ConfirmationMessage(
            title: title,
            message: message,
            details: details,
            style: .normal,
            confirmTitle: NSLocalizedString(
                "deletionConfirmation.restore.confirm",
                value: "復元",
                comment: "Restore confirm button"
            ),
            cancelTitle: NSLocalizedString(
                "deletionConfirmation.cancel",
                value: "キャンセル",
                comment: "Cancel button"
            )
        )
    }

    /// 永久削除確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - itemName: 項目名
    /// - Returns: 確認メッセージ
    private func createPermanentDeleteMessage(
        photoCount: Int,
        itemName: String
    ) -> ConfirmationMessage {
        let title = NSLocalizedString(
            "deletionConfirmation.permanentDelete.title",
            value: "完全に削除しますか？",
            comment: "Permanent delete title"
        )

        let message = NSLocalizedString(
            "deletionConfirmation.permanentDelete.message",
            value: "この操作は取り消せません。\(itemName)は完全に削除されます。",
            comment: "Permanent delete message"
        )

        let details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: NSLocalizedString(
                    "deletionConfirmation.permanentDelete.detail.count",
                    value: "削除枚数",
                    comment: "Permanent delete count label"
                ),
                value: "\(photoCount)枚",
                icon: "exclamationmark.triangle.fill",
                color: Color.LightRoll.error
            )
        ]

        return ConfirmationMessage(
            title: title,
            message: message,
            details: details,
            style: .destructive,
            confirmTitle: NSLocalizedString(
                "deletionConfirmation.permanentDelete.confirm",
                value: "完全削除",
                comment: "Permanent delete confirm button"
            ),
            cancelTitle: NSLocalizedString(
                "deletionConfirmation.cancel",
                value: "キャンセル",
                comment: "Cancel button"
            )
        )
    }

    /// ゴミ箱を空にする確認メッセージを生成
    /// - Parameters:
    ///   - photoCount: 写真の枚数
    ///   - totalSize: 合計サイズ（バイト）
    /// - Returns: 確認メッセージ
    private func createEmptyTrashMessage(
        photoCount: Int,
        totalSize: Int64?
    ) -> ConfirmationMessage {
        let title = NSLocalizedString(
            "deletionConfirmation.emptyTrash.title",
            value: "ゴミ箱を空にしますか？",
            comment: "Empty trash title"
        )

        let message = NSLocalizedString(
            "deletionConfirmation.emptyTrash.message",
            value: "ゴミ箱内のすべての写真が完全に削除されます。この操作は取り消せません。",
            comment: "Empty trash message"
        )

        var details: [ConfirmationDetail] = [
            ConfirmationDetail(
                label: NSLocalizedString(
                    "deletionConfirmation.emptyTrash.detail.count",
                    value: "削除枚数",
                    comment: "Empty trash count label"
                ),
                value: "\(photoCount)枚",
                icon: "trash.circle.fill",
                color: Color.LightRoll.error
            )
        ]

        if let size = totalSize {
            details.append(
                ConfirmationDetail(
                    label: NSLocalizedString(
                        "deletionConfirmation.emptyTrash.detail.size",
                        value: "削減容量",
                        comment: "Freed size label"
                    ),
                    value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                    icon: "arrow.down.circle.fill",
                    color: Color.LightRoll.success
                )
            )
        }

        return ConfirmationMessage(
            title: title,
            message: message,
            details: details,
            style: .destructive,
            confirmTitle: NSLocalizedString(
                "deletionConfirmation.emptyTrash.confirm",
                value: "空にする",
                comment: "Empty trash confirm button"
            ),
            cancelTitle: NSLocalizedString(
                "deletionConfirmation.cancel",
                value: "キャンセル",
                comment: "Cancel button"
            )
        )
    }

    /// キャンセル確認メッセージを生成
    /// - Returns: 確認メッセージ
    private func createCancelMessage() -> ConfirmationMessage {
        let title = NSLocalizedString(
            "deletionConfirmation.cancel.title",
            value: "処理を中止しますか？",
            comment: "Cancel title"
        )

        let message = NSLocalizedString(
            "deletionConfirmation.cancel.message",
            value: "進行中の処理が停止されます。",
            comment: "Cancel message"
        )

        return ConfirmationMessage(
            title: title,
            message: message,
            details: [],
            style: .warning,
            confirmTitle: NSLocalizedString(
                "deletionConfirmation.cancel.confirm",
                value: "中止",
                comment: "Cancel confirm button"
            ),
            cancelTitle: NSLocalizedString(
                "deletionConfirmation.cancel.continue",
                value: "続行",
                comment: "Continue button"
            )
        )
    }
}

// MARK: - ConfirmationMessage to ConfirmationDialog Extension

extension ConfirmationMessage {
    /// ConfirmationDialogに変換
    /// - Parameters:
    ///   - onConfirm: 確認アクション
    ///   - onCancel: キャンセルアクション
    /// - Returns: ConfirmationDialog
    @MainActor
    public func toDialog(
        onConfirm: @escaping @Sendable () async -> Void,
        onCancel: @escaping @Sendable () async -> Void
    ) -> ConfirmationDialog {
        ConfirmationDialog(
            title: title,
            message: message,
            details: details.isEmpty ? nil : details,
            style: style,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックDeletionConfirmationService
@MainActor
public final class MockDeletionConfirmationService: DeletionConfirmationServiceProtocol {

    // MARK: - Mock Storage

    public var shouldShowConfirmationResult = true
    public var mockMessage: ConfirmationMessage?
    public var shouldShowConfirmationCalled = false
    public var formatConfirmationMessageCalled = false
    public var lastPhotoCount: Int?
    public var lastActionType: ConfirmationActionType?

    // MARK: - Initialization

    public init() {}

    // MARK: - Protocol Implementation

    public func shouldShowConfirmation(
        photoCount: Int,
        actionType: ConfirmationActionType
    ) -> Bool {
        shouldShowConfirmationCalled = true
        lastPhotoCount = photoCount
        lastActionType = actionType
        return shouldShowConfirmationResult
    }

    public func formatConfirmationMessage(
        photoCount: Int,
        totalSize: Int64?,
        actionType: ConfirmationActionType,
        itemName: String
    ) -> ConfirmationMessage {
        formatConfirmationMessageCalled = true
        lastPhotoCount = photoCount
        lastActionType = actionType

        return mockMessage ?? ConfirmationMessage(
            title: "テスト確認",
            message: "テストメッセージ",
            details: [],
            style: .normal,
            confirmTitle: "確認",
            cancelTitle: "キャンセル"
        )
    }

    // MARK: - Test Helper Methods

    public func reset() {
        shouldShowConfirmationResult = true
        mockMessage = nil
        shouldShowConfirmationCalled = false
        formatConfirmationMessageCalled = false
        lastPhotoCount = nil
        lastActionType = nil
    }
}

#endif
