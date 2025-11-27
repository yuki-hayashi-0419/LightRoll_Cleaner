//
//  StorageError.swift
//  LightRoll_CleanerFeature
//
//  ストレージ関連のエラー型を定義
//  Created by AI Assistant
//

import Foundation

// MARK: - ストレージエラー

/// ストレージ操作に関連するエラー
/// 空き容量チェックやデータ永続化時に発生するエラーをカテゴリ化
public enum StorageError: Error, LocalizedError, Equatable {

    // MARK: - 容量関連

    /// ストレージの空き容量が不足
    case insufficientSpace

    /// ストレージ容量の計算に失敗
    case calculationFailed

    // MARK: - 永続化関連

    /// データの永続化に失敗
    /// - Parameter reason: 失敗の理由
    case persistenceFailed(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .insufficientSpace:
            return NSLocalizedString(
                "error.storage.insufficientSpace",
                value: "ストレージの空き容量が不足しています",
                comment: "Insufficient storage space error"
            )
        case .calculationFailed:
            return NSLocalizedString(
                "error.storage.calculationFailed",
                value: "ストレージ容量の計算に失敗しました",
                comment: "Storage calculation failed error"
            )
        case .persistenceFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.storage.persistenceFailed",
                    value: "データの保存に失敗しました: %@",
                    comment: "Data persistence failed error"
                ),
                reason
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .insufficientSpace:
            return NSLocalizedString(
                "error.storage.insufficientSpace.reason",
                value: "デバイスのストレージがほぼ満杯です",
                comment: "Insufficient storage space reason"
            )
        case .calculationFailed:
            return NSLocalizedString(
                "error.storage.calculationFailed.reason",
                value: "システムからストレージ情報を取得できませんでした",
                comment: "Storage calculation failed reason"
            )
        case .persistenceFailed:
            return NSLocalizedString(
                "error.storage.persistenceFailed.reason",
                value: "アプリのデータ保存領域への書き込みに失敗しました",
                comment: "Data persistence failed reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .insufficientSpace:
            return NSLocalizedString(
                "error.storage.insufficientSpace.recovery",
                value: "不要なアプリやデータを削除して空き容量を確保してください",
                comment: "Insufficient storage space recovery"
            )
        case .calculationFailed:
            return NSLocalizedString(
                "error.storage.calculationFailed.recovery",
                value: "アプリを再起動してください。問題が続く場合はデバイスを再起動してください",
                comment: "Storage calculation failed recovery"
            )
        case .persistenceFailed:
            return NSLocalizedString(
                "error.storage.persistenceFailed.recovery",
                value: "アプリを再起動してください。ストレージの空き容量も確認してください",
                comment: "Data persistence failed recovery"
            )
        }
    }
}
