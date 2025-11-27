//
//  NavigationDestination.swift
//  LightRoll_CleanerFeature
//
//  ナビゲーション遷移先の定義
//  NavigationStackで使用される遷移先を管理
//  Created by AI Assistant
//

import Foundation

// MARK: - NavigationDestination

/// ナビゲーション遷移先
/// NavigationStackの.navigationDestinationで使用
public enum NavigationDestination: Hashable, Sendable {

    /// グループ詳細画面
    case groupDetail(PhotoGroup)

    /// 写真詳細画面
    case photoDetail(PhotoAsset)

    /// 削除確認画面
    case deleteConfirmation(DeleteConfirmationContext)

    /// 設定画面
    case settings

    /// プレミアムアップグレード画面
    case premium

    /// ゴミ箱画面
    case trash

    /// 権限設定画面
    case permissions

    /// スキャン結果画面
    case scanResult(ScanResult)

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .groupDetail(let group):
            hasher.combine("groupDetail")
            hasher.combine(group.id)
        case .photoDetail(let photo):
            hasher.combine("photoDetail")
            hasher.combine(photo.id)
        case .deleteConfirmation(let context):
            hasher.combine("deleteConfirmation")
            hasher.combine(context)
        case .settings:
            hasher.combine("settings")
        case .premium:
            hasher.combine("premium")
        case .trash:
            hasher.combine("trash")
        case .permissions:
            hasher.combine("permissions")
        case .scanResult(let result):
            hasher.combine("scanResult")
            hasher.combine(result)
        }
    }

    public static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.groupDetail(let lGroup), .groupDetail(let rGroup)):
            return lGroup.id == rGroup.id
        case (.photoDetail(let lPhoto), .photoDetail(let rPhoto)):
            return lPhoto.id == rPhoto.id
        case (.deleteConfirmation(let lContext), .deleteConfirmation(let rContext)):
            return lContext == rContext
        case (.settings, .settings):
            return true
        case (.premium, .premium):
            return true
        case (.trash, .trash):
            return true
        case (.permissions, .permissions):
            return true
        case (.scanResult(let lResult), .scanResult(let rResult)):
            return lResult == rResult
        default:
            return false
        }
    }
}

// MARK: - DeleteConfirmationContext

/// 削除確認のコンテキスト
/// 削除確認ダイアログに必要な情報を保持
public struct DeleteConfirmationContext: Hashable, Sendable {

    /// 削除対象の写真ID一覧
    public let photoIds: [String]

    /// 削除される総容量（バイト）
    public let totalSize: Int64

    /// 削除元のグループID（オプション）
    public let sourceGroupId: UUID?

    // MARK: - Initialization

    public init(
        photoIds: [String],
        totalSize: Int64 = 0,
        sourceGroupId: UUID? = nil
    ) {
        self.photoIds = photoIds
        self.totalSize = totalSize
        self.sourceGroupId = sourceGroupId
    }

    /// 写真配列から生成
    public init(photos: [PhotoAsset], sourceGroupId: UUID? = nil) {
        self.photoIds = photos.map { $0.id }
        self.totalSize = photos.reduce(0) { $0 + $1.fileSize }
        self.sourceGroupId = sourceGroupId
    }

    // MARK: - Computed Properties

    /// 削除対象の件数
    public var count: Int {
        photoIds.count
    }

    /// 人間が読みやすい容量文字列
    public var formattedSize: String {
        ByteCountFormatter.string(
            fromByteCount: totalSize,
            countStyle: .file
        )
    }
}

// MARK: - Navigation Title

extension NavigationDestination {

    /// 画面タイトル
    public var title: String {
        switch self {
        case .groupDetail(let group):
            return group.type.displayName
        case .photoDetail:
            return NSLocalizedString(
                "navigation.photoDetail.title",
                value: "写真詳細",
                comment: "Photo detail screen title"
            )
        case .deleteConfirmation:
            return NSLocalizedString(
                "navigation.deleteConfirmation.title",
                value: "削除の確認",
                comment: "Delete confirmation screen title"
            )
        case .settings:
            return NSLocalizedString(
                "navigation.settings.title",
                value: "設定",
                comment: "Settings screen title"
            )
        case .premium:
            return NSLocalizedString(
                "navigation.premium.title",
                value: "プレミアム",
                comment: "Premium screen title"
            )
        case .trash:
            return NSLocalizedString(
                "navigation.trash.title",
                value: "ゴミ箱",
                comment: "Trash screen title"
            )
        case .permissions:
            return NSLocalizedString(
                "navigation.permissions.title",
                value: "権限設定",
                comment: "Permissions screen title"
            )
        case .scanResult:
            return NSLocalizedString(
                "navigation.scanResult.title",
                value: "スキャン結果",
                comment: "Scan result screen title"
            )
        }
    }
}
