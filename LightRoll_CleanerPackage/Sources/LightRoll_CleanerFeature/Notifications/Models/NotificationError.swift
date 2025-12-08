//
//  NotificationError.swift
//  LightRoll_CleanerFeature
//
//  通知機能のエラー型定義
//  - 権限エラー
//  - スケジューリングエラー
//  - キャンセルエラー
//  Created by AI Assistant for M7-T03
//

import Foundation

// MARK: - NotificationError

/// 通知機能で発生するエラーを表す型
///
/// LocalizedErrorに準拠し、ユーザーフレンドリーなエラーメッセージを提供
public enum NotificationError: LocalizedError, Equatable, Sendable {

    // MARK: - Permission Errors

    /// 通知権限が拒否されている
    case permissionDenied

    /// 通知権限がまだ決定されていない
    case permissionNotDetermined

    /// 権限リクエストに失敗
    case permissionRequestFailed(underlying: String)

    // MARK: - Scheduling Errors

    /// 通知のスケジューリングに失敗
    case schedulingFailed(identifier: String, reason: String)

    /// 無効な通知識別子
    case invalidIdentifier(String)

    /// 通知コンテンツの生成に失敗
    case contentGenerationFailed(reason: String)

    /// 通知トリガーの生成に失敗
    case triggerGenerationFailed(reason: String)

    // MARK: - Cancellation Errors

    /// 通知のキャンセルに失敗
    case cancellationFailed(identifier: String, reason: String)

    // MARK: - Settings Errors

    /// 通知設定が無効
    case invalidSettings(reason: String)

    /// 静寂時間帯のエラー
    case quietHoursConflict

    // MARK: - System Errors

    /// システムエラー（予期しないエラー）
    case systemError(underlying: Error)

    /// 通知センターが利用できない
    case notificationCenterUnavailable

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString(
                "notification.error.permissionDenied",
                value: "通知の権限が拒否されています",
                comment: "Notification permission denied error"
            )

        case .permissionNotDetermined:
            return NSLocalizedString(
                "notification.error.permissionNotDetermined",
                value: "通知の権限がまだ設定されていません",
                comment: "Notification permission not determined error"
            )

        case .permissionRequestFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "notification.error.permissionRequestFailed",
                    value: "通知権限のリクエストに失敗しました: %@",
                    comment: "Notification permission request failed"
                ),
                underlying
            )

        case .schedulingFailed(let identifier, let reason):
            return String(
                format: NSLocalizedString(
                    "notification.error.schedulingFailed",
                    value: "通知 '%@' のスケジューリングに失敗しました: %@",
                    comment: "Notification scheduling failed"
                ),
                identifier,
                reason
            )

        case .invalidIdentifier(let identifier):
            return String(
                format: NSLocalizedString(
                    "notification.error.invalidIdentifier",
                    value: "無効な通知識別子: %@",
                    comment: "Invalid notification identifier"
                ),
                identifier
            )

        case .contentGenerationFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "notification.error.contentGenerationFailed",
                    value: "通知コンテンツの生成に失敗しました: %@",
                    comment: "Notification content generation failed"
                ),
                reason
            )

        case .triggerGenerationFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "notification.error.triggerGenerationFailed",
                    value: "通知トリガーの生成に失敗しました: %@",
                    comment: "Notification trigger generation failed"
                ),
                reason
            )

        case .cancellationFailed(let identifier, let reason):
            return String(
                format: NSLocalizedString(
                    "notification.error.cancellationFailed",
                    value: "通知 '%@' のキャンセルに失敗しました: %@",
                    comment: "Notification cancellation failed"
                ),
                identifier,
                reason
            )

        case .invalidSettings(let reason):
            return String(
                format: NSLocalizedString(
                    "notification.error.invalidSettings",
                    value: "通知設定が無効です: %@",
                    comment: "Invalid notification settings"
                ),
                reason
            )

        case .quietHoursConflict:
            return NSLocalizedString(
                "notification.error.quietHoursConflict",
                value: "静寂時間帯の設定に矛盾があります",
                comment: "Quiet hours conflict error"
            )

        case .systemError(let underlying):
            return String(
                format: NSLocalizedString(
                    "notification.error.systemError",
                    value: "システムエラーが発生しました: %@",
                    comment: "System error"
                ),
                underlying.localizedDescription
            )

        case .notificationCenterUnavailable:
            return NSLocalizedString(
                "notification.error.notificationCenterUnavailable",
                value: "通知センターが利用できません",
                comment: "Notification center unavailable"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString(
                "notification.error.permissionDenied.reason",
                value: "ユーザーが通知の許可を拒否しました",
                comment: "Permission denied reason"
            )

        case .permissionNotDetermined:
            return NSLocalizedString(
                "notification.error.permissionNotDetermined.reason",
                value: "アプリが通知権限をリクエストしていません",
                comment: "Permission not determined reason"
            )

        case .schedulingFailed:
            return NSLocalizedString(
                "notification.error.schedulingFailed.reason",
                value: "システムが通知をスケジュールできませんでした",
                comment: "Scheduling failed reason"
            )

        case .invalidSettings:
            return NSLocalizedString(
                "notification.error.invalidSettings.reason",
                value: "通知設定に無効な値が含まれています",
                comment: "Invalid settings reason"
            )

        default:
            return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString(
                "notification.error.permissionDenied.recovery",
                value: "設定アプリから通知を許可してください",
                comment: "Permission denied recovery"
            )

        case .permissionNotDetermined:
            return NSLocalizedString(
                "notification.error.permissionNotDetermined.recovery",
                value: "通知権限をリクエストしてください",
                comment: "Permission not determined recovery"
            )

        case .invalidSettings:
            return NSLocalizedString(
                "notification.error.invalidSettings.recovery",
                value: "通知設定を見直してください",
                comment: "Invalid settings recovery"
            )

        case .quietHoursConflict:
            return NSLocalizedString(
                "notification.error.quietHoursConflict.recovery",
                value: "静寂時間帯の開始時刻と終了時刻を確認してください",
                comment: "Quiet hours conflict recovery"
            )

        default:
            return NSLocalizedString(
                "notification.error.default.recovery",
                value: "しばらくしてからもう一度お試しください",
                comment: "Default recovery suggestion"
            )
        }
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: NotificationError, rhs: NotificationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.permissionNotDetermined, .permissionNotDetermined),
             (.quietHoursConflict, .quietHoursConflict),
             (.notificationCenterUnavailable, .notificationCenterUnavailable):
            return true

        case let (.permissionRequestFailed(lhsUnderlying), .permissionRequestFailed(rhsUnderlying)):
            return lhsUnderlying == rhsUnderlying

        case let (.schedulingFailed(lhsId, lhsReason), .schedulingFailed(rhsId, rhsReason)):
            return lhsId == rhsId && lhsReason == rhsReason

        case let (.invalidIdentifier(lhsId), .invalidIdentifier(rhsId)):
            return lhsId == rhsId

        case let (.contentGenerationFailed(lhsReason), .contentGenerationFailed(rhsReason)):
            return lhsReason == rhsReason

        case let (.triggerGenerationFailed(lhsReason), .triggerGenerationFailed(rhsReason)):
            return lhsReason == rhsReason

        case let (.cancellationFailed(lhsId, lhsReason), .cancellationFailed(rhsId, rhsReason)):
            return lhsId == rhsId && lhsReason == rhsReason

        case let (.invalidSettings(lhsReason), .invalidSettings(rhsReason)):
            return lhsReason == rhsReason

        case let (.systemError(lhsError), .systemError(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription

        default:
            return false
        }
    }
}

// MARK: - Helper Extensions

extension NotificationError {
    /// エラーが権限関連かどうかを判定
    public var isPermissionError: Bool {
        switch self {
        case .permissionDenied, .permissionNotDetermined, .permissionRequestFailed:
            return true
        default:
            return false
        }
    }

    /// エラーがリカバリー可能かどうかを判定
    public var isRecoverable: Bool {
        switch self {
        case .permissionDenied, .permissionNotDetermined, .invalidSettings, .quietHoursConflict:
            return true
        case .systemError, .notificationCenterUnavailable:
            return false
        default:
            return true
        }
    }

    /// 設定画面への誘導が必要かどうか
    public var needsSettingsRedirect: Bool {
        switch self {
        case .permissionDenied:
            return true
        default:
            return false
        }
    }
}
