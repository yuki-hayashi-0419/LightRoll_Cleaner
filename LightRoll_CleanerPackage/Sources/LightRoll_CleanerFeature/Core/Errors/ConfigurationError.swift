//
//  ConfigurationError.swift
//  LightRoll_CleanerFeature
//
//  設定関連のエラー型を定義
//  Created by AI Assistant
//

import Foundation

// MARK: - 設定エラー

/// アプリ設定に関連するエラー
/// 設定の読み込み・保存・検証時に発生するエラーをカテゴリ化
public enum ConfigurationError: Error, LocalizedError, Equatable {

    // MARK: - 検証関連

    /// 無効な設定値
    /// - Parameter description: 問題の説明
    case invalidConfiguration(String)

    // MARK: - 入出力関連

    /// 設定の読み込みに失敗
    case loadFailed

    /// 設定の保存に失敗
    case saveFailed

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let description):
            return String(
                format: NSLocalizedString(
                    "error.configuration.invalid",
                    value: "設定が無効です: %@",
                    comment: "Invalid configuration error"
                ),
                description
            )
        case .loadFailed:
            return NSLocalizedString(
                "error.configuration.loadFailed",
                value: "設定の読み込みに失敗しました",
                comment: "Configuration load failed error"
            )
        case .saveFailed:
            return NSLocalizedString(
                "error.configuration.saveFailed",
                value: "設定の保存に失敗しました",
                comment: "Configuration save failed error"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidConfiguration:
            return NSLocalizedString(
                "error.configuration.invalid.reason",
                value: "設定値が許容範囲外または形式が不正です",
                comment: "Invalid configuration reason"
            )
        case .loadFailed:
            return NSLocalizedString(
                "error.configuration.loadFailed.reason",
                value: "設定ファイルが破損しているか、アクセスできません",
                comment: "Configuration load failed reason"
            )
        case .saveFailed:
            return NSLocalizedString(
                "error.configuration.saveFailed.reason",
                value: "設定の書き込み先にアクセスできません",
                comment: "Configuration save failed reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidConfiguration:
            return NSLocalizedString(
                "error.configuration.invalid.recovery",
                value: "設定をデフォルト値にリセットするか、有効な値を入力してください",
                comment: "Invalid configuration recovery"
            )
        case .loadFailed:
            return NSLocalizedString(
                "error.configuration.loadFailed.recovery",
                value: "アプリを再インストールすると設定がリセットされます",
                comment: "Configuration load failed recovery"
            )
        case .saveFailed:
            return NSLocalizedString(
                "error.configuration.saveFailed.recovery",
                value: "ストレージの空き容量を確認し、アプリを再起動してください",
                comment: "Configuration save failed recovery"
            )
        }
    }
}
