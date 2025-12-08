//
//  StorageAlertScheduler.swift
//  LightRoll_CleanerFeature
//
//  空き容量警告通知のスケジューリング
//  - ストレージ監視
//  - 閾値チェック
//  - 通知スケジューリング
//  - 静寂時間帯考慮
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T06
//

import Foundation
@preconcurrency import UserNotifications
import Observation

// MARK: - StorageAlertSchedulerError

/// StorageAlertSchedulerのエラー
public enum StorageAlertSchedulerError: Error, Equatable, LocalizedError {
    /// ストレージ情報の取得に失敗
    case storageInfoUnavailable(reason: String)

    /// 通知のスケジューリングに失敗
    case schedulingFailed(reason: String)

    /// 通知設定が無効
    case notificationsDisabled

    /// 権限が拒否されている
    case permissionDenied

    /// 静寂時間帯中のため通知がスキップされた
    case quietHoursActive

    public var errorDescription: String? {
        switch self {
        case .storageInfoUnavailable(let reason):
            return NSLocalizedString(
                "error.storageAlertScheduler.storageInfoUnavailable",
                value: "ストレージ情報の取得に失敗しました: \(reason)",
                comment: "Storage info unavailable error"
            )
        case .schedulingFailed(let reason):
            return NSLocalizedString(
                "error.storageAlertScheduler.schedulingFailed",
                value: "通知のスケジューリングに失敗しました: \(reason)",
                comment: "Scheduling failed error"
            )
        case .notificationsDisabled:
            return NSLocalizedString(
                "error.storageAlertScheduler.notificationsDisabled",
                value: "ストレージアラート通知が無効になっています",
                comment: "Notifications disabled error"
            )
        case .permissionDenied:
            return NSLocalizedString(
                "error.storageAlertScheduler.permissionDenied",
                value: "通知権限が拒否されています",
                comment: "Permission denied error"
            )
        case .quietHoursActive:
            return NSLocalizedString(
                "error.storageAlertScheduler.quietHoursActive",
                value: "静寂時間帯のため通知がスキップされました",
                comment: "Quiet hours active error"
            )
        }
    }

    public static func == (lhs: StorageAlertSchedulerError, rhs: StorageAlertSchedulerError) -> Bool {
        switch (lhs, rhs) {
        case (.storageInfoUnavailable, .storageInfoUnavailable),
             (.schedulingFailed, .schedulingFailed),
             (.notificationsDisabled, .notificationsDisabled),
             (.permissionDenied, .permissionDenied),
             (.quietHoursActive, .quietHoursActive):
            return true
        default:
            return false
        }
    }
}

// MARK: - StorageAlertScheduler

/// 空き容量警告通知のスケジューラー
///
/// MV Patternに従い、@Observableサービスとして実装
/// - ストレージ容量を監視
/// - 閾値を超えた場合に通知をスケジュール
/// - 静寂時間帯を考慮
/// - 通知の重複を防ぐ
@MainActor
@Observable
public final class StorageAlertScheduler: Sendable {

    // MARK: - Properties

    /// 最後にチェックしたストレージ使用率
    public private(set) var lastUsagePercentage: Double = 0.0

    /// 最後にチェックした空き容量（バイト）
    public private(set) var lastAvailableSpace: Int64 = 0

    /// 最後のチェック時刻
    public private(set) var lastCheckTime: Date?

    /// 通知が現在スケジュールされているか
    public private(set) var isNotificationScheduled: Bool = false

    /// 最後に発生したエラー
    public private(set) var lastError: StorageAlertSchedulerError?

    /// PhotoRepositoryの参照
    private let photoRepository: PhotoRepository

    /// NotificationManagerの参照
    private let notificationManager: NotificationManager

    /// NotificationContentBuilderの参照
    private let contentBuilder: NotificationContentBuilder

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photoRepository: PhotoRepository
    ///   - notificationManager: NotificationManager
    ///   - contentBuilder: NotificationContentBuilder
    public init(
        photoRepository: PhotoRepository,
        notificationManager: NotificationManager,
        contentBuilder: NotificationContentBuilder = NotificationContentBuilder()
    ) {
        self.photoRepository = photoRepository
        self.notificationManager = notificationManager
        self.contentBuilder = contentBuilder
    }

    // MARK: - Storage Monitoring

    /// ストレージ状態をチェックし、必要に応じて通知をスケジュール
    ///
    /// - Returns: 通知がスケジュールされた場合true
    /// - Throws: StorageAlertSchedulerError
    @discardableResult
    public func checkAndScheduleIfNeeded() async throws -> Bool {
        // 通知設定を確認
        guard notificationManager.settings.isEnabled else {
            let error = StorageAlertSchedulerError.notificationsDisabled
            lastError = error
            throw error
        }

        guard notificationManager.settings.storageAlertEnabled else {
            let error = StorageAlertSchedulerError.notificationsDisabled
            lastError = error
            throw error
        }

        // 権限確認
        await notificationManager.updateAuthorizationStatus()
        guard notificationManager.isAuthorized else {
            let error = StorageAlertSchedulerError.permissionDenied
            lastError = error
            throw error
        }

        // ストレージ情報を取得
        let storageInfo: StorageInfo
        do {
            storageInfo = try await photoRepository.getStorageInfo()
        } catch {
            let schedulerError = StorageAlertSchedulerError.storageInfoUnavailable(
                reason: error.localizedDescription
            )
            lastError = schedulerError
            throw schedulerError
        }

        // ストレージ状態を更新
        lastUsagePercentage = storageInfo.usagePercentage
        lastAvailableSpace = storageInfo.availableCapacity
        lastCheckTime = Date()

        // 閾値チェック
        let threshold = notificationManager.settings.storageAlertThreshold
        guard lastUsagePercentage >= threshold else {
            // 閾値未満の場合は既存の通知をキャンセル
            await cancelStorageAlertNotification()
            lastError = nil
            return false
        }

        // 静寂時間帯チェック
        if notificationManager.isInQuietHours {
            let error = StorageAlertSchedulerError.quietHoursActive
            lastError = error
            throw error
        }

        // 通知をスケジュール
        try await scheduleStorageAlert(
            usagePercentage: lastUsagePercentage,
            availableSpace: lastAvailableSpace
        )

        lastError = nil
        return true
    }

    /// ストレージアラート通知をスケジュール
    ///
    /// - Parameters:
    ///   - usagePercentage: ストレージ使用率（0.0〜1.0）
    ///   - availableSpace: 利用可能な空き容量（バイト）
    /// - Throws: StorageAlertSchedulerError
    public func scheduleStorageAlert(
        usagePercentage: Double,
        availableSpace: Int64
    ) async throws {
        // 既存の通知が存在する場合はスキップ
        let hasExisting = await notificationManager.hasNotification(.storageAlert)
        if hasExisting {
            isNotificationScheduled = true
            lastError = nil
            return
        }

        // 通知コンテンツを生成
        let content = contentBuilder.buildStorageAlertContent(
            usedPercentage: usagePercentage,
            availableSpace: availableSpace
        )

        // トリガーは即時（60秒後）
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60,
            repeats: false
        )

        // 通知をスケジュール
        do {
            try await notificationManager.scheduleNotification(
                identifier: NotificationManager.NotificationIdentifier.storageAlert.identifier,
                content: content,
                trigger: trigger
            )
            isNotificationScheduled = true
            lastError = nil
        } catch {
            let schedulerError = StorageAlertSchedulerError.schedulingFailed(
                reason: error.localizedDescription
            )
            lastError = schedulerError
            throw schedulerError
        }
    }

    /// ストレージアラート通知をキャンセル
    public func cancelStorageAlertNotification() async {
        await notificationManager.cancelNotification(.storageAlert)
        isNotificationScheduled = false
        lastError = nil
    }

    /// 現在の通知スケジュール状態を更新
    ///
    /// ペンディング通知の存在を確認して状態を更新する
    public func updateNotificationStatus() async {
        isNotificationScheduled = await notificationManager.hasNotification(.storageAlert)
    }

    // MARK: - Utility Methods

    /// 閾値を超えているかを確認
    ///
    /// - Returns: 閾値を超えている場合true
    public var isOverThreshold: Bool {
        let threshold = notificationManager.settings.storageAlertThreshold
        return lastUsagePercentage >= threshold
    }

    /// エラーをクリア
    public func clearError() {
        lastError = nil
    }

    /// 最後のチェックから経過した時間（秒）
    ///
    /// - Returns: 経過秒数。チェックされていない場合はnil
    public var timeSinceLastCheck: TimeInterval? {
        guard let lastCheckTime else { return nil }
        return Date().timeIntervalSince(lastCheckTime)
    }
}
