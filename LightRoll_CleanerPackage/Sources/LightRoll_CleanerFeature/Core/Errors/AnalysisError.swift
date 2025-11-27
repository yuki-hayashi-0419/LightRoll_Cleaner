//
//  AnalysisError.swift
//  LightRoll_CleanerFeature
//
//  画像分析処理関連のエラー型を定義
//  Created by AI Assistant
//

import Foundation

// MARK: - 分析エラー

/// 画像分析処理に関連するエラー
/// Visionフレームワーク使用時や類似度計算時に発生するエラーをカテゴリ化
public enum AnalysisError: Error, LocalizedError, Equatable {

    // MARK: - Vision関連

    /// Visionフレームワークのエラー
    /// - Parameter reason: 詳細な理由
    case visionFrameworkError(String)

    /// 特徴量の抽出に失敗
    case featureExtractionFailed

    // MARK: - 計算関連

    /// 類似度計算に失敗
    case similarityCalculationFailed

    /// グルーピング処理に失敗
    case groupingFailed

    // MARK: - キャンセル

    /// 分析処理がキャンセルされた
    case cancelled

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .visionFrameworkError(let reason):
            return String(
                format: NSLocalizedString(
                    "error.analysis.visionError",
                    value: "画像解析エンジンでエラーが発生しました: %@",
                    comment: "Vision framework error"
                ),
                reason
            )
        case .featureExtractionFailed:
            return NSLocalizedString(
                "error.analysis.featureExtractionFailed",
                value: "画像の特徴抽出に失敗しました",
                comment: "Feature extraction failed error"
            )
        case .similarityCalculationFailed:
            return NSLocalizedString(
                "error.analysis.similarityFailed",
                value: "類似度の計算に失敗しました",
                comment: "Similarity calculation failed error"
            )
        case .groupingFailed:
            return NSLocalizedString(
                "error.analysis.groupingFailed",
                value: "写真のグループ化に失敗しました",
                comment: "Grouping failed error"
            )
        case .cancelled:
            return NSLocalizedString(
                "error.analysis.cancelled",
                value: "分析処理がキャンセルされました",
                comment: "Analysis cancelled error"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .visionFrameworkError:
            return NSLocalizedString(
                "error.analysis.visionError.reason",
                value: "システムの画像解析機能で問題が発生しました",
                comment: "Vision framework error reason"
            )
        case .featureExtractionFailed:
            return NSLocalizedString(
                "error.analysis.featureExtractionFailed.reason",
                value: "画像から特徴的なパターンを検出できませんでした",
                comment: "Feature extraction failed reason"
            )
        case .similarityCalculationFailed:
            return NSLocalizedString(
                "error.analysis.similarityFailed.reason",
                value: "画像間の比較処理中にエラーが発生しました",
                comment: "Similarity calculation failed reason"
            )
        case .groupingFailed:
            return NSLocalizedString(
                "error.analysis.groupingFailed.reason",
                value: "類似画像のグループ分け処理でエラーが発生しました",
                comment: "Grouping failed reason"
            )
        case .cancelled:
            return NSLocalizedString(
                "error.analysis.cancelled.reason",
                value: "ユーザーまたはシステムにより処理が中断されました",
                comment: "Analysis cancelled reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .visionFrameworkError:
            return NSLocalizedString(
                "error.analysis.visionError.recovery",
                value: "アプリを再起動してください。問題が続く場合はOSを更新してください",
                comment: "Vision framework error recovery"
            )
        case .featureExtractionFailed:
            return NSLocalizedString(
                "error.analysis.featureExtractionFailed.recovery",
                value: "対象の画像が破損している可能性があります。別の画像で試してください",
                comment: "Feature extraction failed recovery"
            )
        case .similarityCalculationFailed:
            return NSLocalizedString(
                "error.analysis.similarityFailed.recovery",
                value: "再度スキャンを実行してください",
                comment: "Similarity calculation failed recovery"
            )
        case .groupingFailed:
            return NSLocalizedString(
                "error.analysis.groupingFailed.recovery",
                value: "再度スキャンを実行してください。対象の写真数を減らすと解決する場合があります",
                comment: "Grouping failed recovery"
            )
        case .cancelled:
            return NSLocalizedString(
                "error.analysis.cancelled.recovery",
                value: "必要に応じて再度スキャンを開始してください",
                comment: "Analysis cancelled recovery"
            )
        }
    }
}
