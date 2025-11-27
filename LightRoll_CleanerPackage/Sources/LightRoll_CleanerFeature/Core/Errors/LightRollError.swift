//
//  LightRollError.swift
//  LightRoll_CleanerFeature
//
//  アプリケーション全体のエラー型を定義
//  Created by AI Assistant
//

import Foundation

// MARK: - メインエラー型

/// LightRoll Cleanerアプリケーションのメインエラー型
/// 全てのエラーはこの型にラップされて扱われる
public enum LightRollError: Error, LocalizedError, Equatable {

    // MARK: - エラーカテゴリ

    /// 写真ライブラリ関連のエラー
    case photoLibrary(PhotoLibraryError)

    /// 分析処理関連のエラー
    case analysis(AnalysisError)

    /// ストレージ関連のエラー
    case storage(StorageError)

    /// 設定関連のエラー
    case configuration(ConfigurationError)

    /// 一般的なエラー（分類不能なエラー）
    case unknown(String?)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .photoLibrary(let error):
            return error.errorDescription
        case .analysis(let error):
            return error.errorDescription
        case .storage(let error):
            return error.errorDescription
        case .configuration(let error):
            return error.errorDescription
        case .unknown(let message):
            return message ?? NSLocalizedString(
                "error.unknown",
                value: "不明なエラーが発生しました",
                comment: "Unknown error message"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .photoLibrary(let error):
            return error.failureReason
        case .analysis(let error):
            return error.failureReason
        case .storage(let error):
            return error.failureReason
        case .configuration(let error):
            return error.failureReason
        case .unknown:
            return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .photoLibrary(let error):
            return error.recoverySuggestion
        case .analysis(let error):
            return error.recoverySuggestion
        case .storage(let error):
            return error.recoverySuggestion
        case .configuration(let error):
            return error.recoverySuggestion
        case .unknown:
            return NSLocalizedString(
                "error.unknown.recovery",
                value: "アプリを再起動してください",
                comment: "Unknown error recovery suggestion"
            )
        }
    }

    // MARK: - Equatable

    public static func == (lhs: LightRollError, rhs: LightRollError) -> Bool {
        switch (lhs, rhs) {
        case (.photoLibrary(let l), .photoLibrary(let r)):
            return l == r
        case (.analysis(let l), .analysis(let r)):
            return l == r
        case (.storage(let l), .storage(let r)):
            return l == r
        case (.configuration(let l), .configuration(let r)):
            return l == r
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - ファクトリメソッド

extension LightRollError {

    /// 汎用Errorからラップされたエラーを生成
    /// - Parameter error: 元のエラー
    /// - Returns: LightRollErrorにラップされたエラー
    public static func wrap(_ error: Error) -> LightRollError {
        if let lightRollError = error as? LightRollError {
            return lightRollError
        }
        return .unknown(error.localizedDescription)
    }
}
