//
//  PhotoLibraryError.swift
//  LightRoll_CleanerFeature
//
//  写真ライブラリ関連のエラー型を定義
//  Created by AI Assistant
//

import Foundation

// MARK: - 写真ライブラリエラー

/// 写真ライブラリ操作に関連するエラー
/// PHPhotosライブラリとのやり取りで発生するエラーをカテゴリ化
public enum PhotoLibraryError: Error, LocalizedError, Equatable {

    // MARK: - 権限関連

    /// 写真ライブラリへのアクセスが拒否された
    case accessDenied

    /// 写真ライブラリへのアクセスが制限されている（ペアレンタルコントロール等）
    case accessRestricted

    // MARK: - 取得関連

    /// 写真の取得に失敗
    /// - Parameter reason: 失敗の理由
    case fetchFailed(String)

    /// 指定されたアセットが見つからない
    /// - Parameter identifier: アセットの識別子
    case assetNotFound(String)

    // MARK: - 削除関連

    /// 写真の削除に失敗
    /// - Parameter reason: 失敗の理由
    case deletionFailed(String)

    // MARK: - サムネイル関連

    /// サムネイルの生成に失敗
    case thumbnailGenerationFailed

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return NSLocalizedString(
                "error.photoLibrary.accessDenied",
                value: "写真ライブラリへのアクセスが許可されていません",
                comment: "Photo library access denied error"
            )
        case .accessRestricted:
            return NSLocalizedString(
                "error.photoLibrary.accessRestricted",
                value: "写真ライブラリへのアクセスが制限されています",
                comment: "Photo library access restricted error"
            )
        case .fetchFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.photoLibrary.fetchFailed",
                    value: "写真の取得に失敗しました: %@",
                    comment: "Photo fetch failed error"
                ),
                reason
            )
        case .assetNotFound(let identifier):
            return String(
                format: NSLocalizedString(
                    "error.photoLibrary.assetNotFound",
                    value: "写真が見つかりません (ID: %@)",
                    comment: "Photo asset not found error"
                ),
                identifier
            )
        case .deletionFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.photoLibrary.deletionFailed",
                    value: "写真の削除に失敗しました: %@",
                    comment: "Photo deletion failed error"
                ),
                reason
            )
        case .thumbnailGenerationFailed:
            return NSLocalizedString(
                "error.photoLibrary.thumbnailFailed",
                value: "サムネイルの生成に失敗しました",
                comment: "Thumbnail generation failed error"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .accessDenied:
            return NSLocalizedString(
                "error.photoLibrary.accessDenied.reason",
                value: "ユーザーがアクセスを許可していません",
                comment: "Photo library access denied reason"
            )
        case .accessRestricted:
            return NSLocalizedString(
                "error.photoLibrary.accessRestricted.reason",
                value: "システム設定によりアクセスが制限されています",
                comment: "Photo library access restricted reason"
            )
        case .fetchFailed:
            return NSLocalizedString(
                "error.photoLibrary.fetchFailed.reason",
                value: "写真ライブラリからのデータ取得に問題が発生しました",
                comment: "Photo fetch failed reason"
            )
        case .assetNotFound:
            return NSLocalizedString(
                "error.photoLibrary.assetNotFound.reason",
                value: "指定された写真がライブラリに存在しません",
                comment: "Photo asset not found reason"
            )
        case .deletionFailed:
            return NSLocalizedString(
                "error.photoLibrary.deletionFailed.reason",
                value: "写真の削除処理中にエラーが発生しました",
                comment: "Photo deletion failed reason"
            )
        case .thumbnailGenerationFailed:
            return NSLocalizedString(
                "error.photoLibrary.thumbnailFailed.reason",
                value: "画像の縮小版を作成できませんでした",
                comment: "Thumbnail generation failed reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return NSLocalizedString(
                "error.photoLibrary.accessDenied.recovery",
                value: "設定アプリから写真へのアクセスを許可してください",
                comment: "Photo library access denied recovery"
            )
        case .accessRestricted:
            return NSLocalizedString(
                "error.photoLibrary.accessRestricted.recovery",
                value: "デバイスの設定またはスクリーンタイムの設定を確認してください",
                comment: "Photo library access restricted recovery"
            )
        case .fetchFailed:
            return NSLocalizedString(
                "error.photoLibrary.fetchFailed.recovery",
                value: "アプリを再起動するか、しばらく待ってから再試行してください",
                comment: "Photo fetch failed recovery"
            )
        case .assetNotFound:
            return NSLocalizedString(
                "error.photoLibrary.assetNotFound.recovery",
                value: "写真が削除された可能性があります。画面を更新してください",
                comment: "Photo asset not found recovery"
            )
        case .deletionFailed:
            return NSLocalizedString(
                "error.photoLibrary.deletionFailed.recovery",
                value: "再度削除を試みるか、写真アプリから直接削除してください",
                comment: "Photo deletion failed recovery"
            )
        case .thumbnailGenerationFailed:
            return NSLocalizedString(
                "error.photoLibrary.thumbnailFailed.recovery",
                value: "元の画像に問題がある可能性があります。別の写真を選択してください",
                comment: "Thumbnail generation failed recovery"
            )
        }
    }
}
