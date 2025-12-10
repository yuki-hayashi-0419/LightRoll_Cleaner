//
//  TrashExpirationNotifier.swift
//  LightRoll_CleanerFeature
//
//  ゴミ箱期限警告通知のスケジューリング
//  - ゴミ箱内アイテムの期限チェック
//  - 期限切れ前の警告通知（デフォルト1日前）
//  - 通知内容にアイテム数と残り日数を含める
//  - 通知タップ時にゴミ箱画面を開く
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T09
//

import Foundation
@preconcurrency import UserNotifications
import Observation

// MARK: - TrashExpirationNotifierError

/// TrashExpirationNotifierのエラー
public enum TrashExpirationNotifierError: Error, Equatable, LocalizedError {
    /// 通知のスケジューリングに失敗
    case schedulingFailed(reason: String)

    /// 通知設定が無効
    case notificationsDisabled

    /// 権限が拒否されている
    case permissionDenied

    /// ゴミ箱が空のため通知不要
    case trashEmpty

    /// 期限切れ前のアイテムがない
    case noExpiringItems

    public var errorDescription: String? {
        switch self {
        case .schedulingFailed(let reason):
            return NSLocalizedString(
                "error.trashExpirationNotifier.schedulingFailed",
                value: "ゴミ箱期限警告通知のスケジューリングに失敗しました: \(reason)",
                comment: "Scheduling failed error"
            )
        case .notificationsDisabled:
            return NSLocalizedString(
                "error.trashExpirationNotifier.notificationsDisabled",
                value: "通知が無効になっています",
                comment: "Notifications disabled error"
            )
        case .permissionDenied:
            return NSLocalizedString(
                "error.trashExpirationNotifier.permissionDenied",
                value: "通知権限が拒否されています",
                comment: "Permission denied error"
            )
        case .trashEmpty:
            return NSLocalizedString(
                "error.trashExpirationNotifier.trashEmpty",
                value: "ゴミ箱は空です",
                comment: "Trash empty error"
            )
        case .noExpiringItems:
            return NSLocalizedString(
                "error.trashExpirationNotifier.noExpiringItems",
                value: "期限切れ前のアイテムがありません",
                comment: "No expiring items error"
            )
        }
    }

    public static func == (lhs: TrashExpirationNotifierError, rhs: TrashExpirationNotifierError) -> Bool {
        switch (lhs, rhs) {
        case (.schedulingFailed, .schedulingFailed),
             (.notificationsDisabled, .notificationsDisabled),
             (.permissionDenied, .permissionDenied),
             (.trashEmpty, .trashEmpty),
             (.noExpiringItems, .noExpiringItems):
            return true
        default:
            return false
        }
    }
}

// MARK: - TrashExpirationNotifier

/// ゴミ箱期限警告通知のスケジューラー
///
/// MV Patternに従い、@Observableサービスとして実装
/// - ゴミ箱内のアイテムの期限をチェック
/// - 期限切れ前（デフォルト1日前）に警告通知を送信
/// - 通知内容にアイテム数と残り日数を含める
/// - 通知タップ時にゴミ箱画面を開く
@MainActor
@Observable
public final class TrashExpirationNotifier: Sendable {

    // MARK: - Properties

    /// 通知マネージャー
    private let notificationManager: NotificationManager

    /// ゴミ箱マネージャー
    private let trashManager: any TrashManagerProtocol

    /// 通知コンテンツビルダー
    private let contentBuilder: NotificationContentBuilder

    /// 警告する日数前（デフォルト1日前）
    private let warningDaysBefore: Int

    /// 通知識別子プレフィックス
    private static let notificationIdentifierPrefix = "trash_expiration_warning"

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - notificationManager: 通知マネージャー
    ///   - trashManager: ゴミ箱マネージャー
    ///   - contentBuilder: 通知コンテンツビルダー（デフォルトは新規インスタンス）
    ///   - warningDaysBefore: 警告する日数前（デフォルト1日前）
    public init(
        notificationManager: NotificationManager,
        trashManager: any TrashManagerProtocol,
        contentBuilder: NotificationContentBuilder = NotificationContentBuilder(),
        warningDaysBefore: Int = 1
    ) {
        self.notificationManager = notificationManager
        self.trashManager = trashManager
        self.contentBuilder = contentBuilder
        self.warningDaysBefore = max(0, warningDaysBefore)
    }

    // MARK: - Public Methods

    /// ゴミ箱期限警告通知をスケジュール
    ///
    /// ゴミ箱内のアイテムをチェックし、期限切れ前のアイテムがあれば通知をスケジュールします
    /// - Throws: TrashExpirationNotifierError
    public func scheduleExpirationWarning() async throws {
        // 1. 通知設定の確認
        guard notificationManager.settings.isEnabled else {
            throw TrashExpirationNotifierError.notificationsDisabled
        }

        // 2. 権限確認
        await notificationManager.updateAuthorizationStatus()
        guard notificationManager.authorizationStatus == .authorized else {
            throw TrashExpirationNotifierError.permissionDenied
        }

        // 3. ゴミ箱内のアイテムを取得
        let trashPhotos = await trashManager.fetchAllTrashPhotos()
        guard !trashPhotos.isEmpty else {
            throw TrashExpirationNotifierError.trashEmpty
        }

        // 4. 期限切れ前のアイテムを抽出
        // warningDaysBefore日前に警告を送るため、期限切れがwarningDaysBefore日以内のアイテムを対象とする
        let expiringPhotos = trashPhotos.expiringWithin(days: warningDaysBefore)
        guard !expiringPhotos.isEmpty else {
            throw TrashExpirationNotifierError.noExpiringItems
        }

        // 5. 最も早く期限切れになるアイテムを取得
        guard let nearestExpiring = expiringPhotos.first else {
            throw TrashExpirationNotifierError.noExpiringItems
        }

        // 6. 残り日数を計算
        let calendar = Calendar.current
        let now = Date()
        let daysRemaining = calendar.dateComponents([.day], from: now, to: nearestExpiring.expiresAt).day ?? 0

        // 7. 通知コンテンツを生成
        let content = contentBuilder.buildTrashExpirationContent(
            itemCount: expiringPhotos.count,
            expirationDays: max(0, daysRemaining)
        )

        // 8. 通知トリガーを計算
        let trigger = calculateTrigger(for: nearestExpiring, warningDaysBefore: warningDaysBefore)

        // 9. 既存の通知をキャンセル
        await cancelAllExpirationWarnings()

        // 10. 通知をスケジュール
        let identifier = "\(Self.notificationIdentifierPrefix)_\(nearestExpiring.id.uuidString)"

        do {
            try await notificationManager.scheduleNotification(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
        } catch {
            throw TrashExpirationNotifierError.schedulingFailed(reason: error.localizedDescription)
        }
    }

    /// すべてのゴミ箱期限警告通知をキャンセル
    public func cancelAllExpirationWarnings() async {
        // ペンディング中の通知を取得
        let pendingRequests = await notificationManager.getPendingNotifications()

        // プレフィックスでフィルタリング
        let expirationNotificationIds = pendingRequests
            .map { $0.identifier }
            .filter { $0.hasPrefix(Self.notificationIdentifierPrefix) }

        // 該当する通知をキャンセル
        for identifier in expirationNotificationIds {
            await notificationManager.cancelNotification(identifier: identifier)
        }
    }

    /// 期限切れ前のアイテム数を取得
    /// - Returns: 期限切れ前のアイテム数
    public func getExpiringItemCount() async -> Int {
        let trashPhotos = await trashManager.fetchAllTrashPhotos()
        return trashPhotos.expiringWithin(days: warningDaysBefore).count
    }

    // MARK: - Private Methods

    /// 通知トリガーを計算
    /// - Parameters:
    ///   - photo: ゴミ箱写真
    ///   - warningDaysBefore: 警告する日数前
    /// - Returns: 通知トリガー
    private func calculateTrigger(
        for photo: TrashPhoto,
        warningDaysBefore: Int
    ) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let now = Date()

        // 期限切れの警告日時を計算
        guard let warningDate = calendar.date(
            byAdding: .day,
            value: -warningDaysBefore,
            to: photo.expiresAt
        ) else {
            // 計算失敗時は即座に通知（5秒後）
            return UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }

        // 警告日時が過去の場合は即座に通知
        if warningDate <= now {
            return UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }

        // 静寂時間帯を考慮して調整
        let adjustedDate = adjustForQuietHours(warningDate)

        // 通知時刻までの秒数を計算
        let timeInterval = adjustedDate.timeIntervalSince(now)

        // 時間間隔トリガーを使用（繰り返しなし）
        return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    }

    /// 静寂時間帯を考慮して通知日時を調整
    /// - Parameter date: 元の通知日時
    /// - Returns: 調整された通知日時
    private func adjustForQuietHours(_ date: Date) -> Date {
        guard notificationManager.settings.quietHoursEnabled else {
            return date
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour else {
            return date
        }

        let startHour = notificationManager.settings.quietHoursStart
        let endHour = notificationManager.settings.quietHoursEnd

        // 静寂時間帯中かチェック
        let isInQuietHours: Bool
        if startHour < endHour {
            // 例: 22時〜8時（翌日）
            isInQuietHours = hour >= startHour || hour < endHour
        } else {
            // 例: 8時〜22時（同日）
            isInQuietHours = hour >= startHour && hour < endHour
        }

        guard isInQuietHours else {
            return date
        }

        // 静寂時間帯終了時刻に調整
        var adjustedComponents = components
        adjustedComponents.hour = endHour
        adjustedComponents.minute = 0

        return calendar.date(from: adjustedComponents) ?? date
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックTrashExpirationNotifier
@MainActor
@Observable
public final class MockTrashExpirationNotifier: Sendable {

    // MARK: - Test Hooks

    public var scheduleExpirationWarningCalled = false
    public var cancelAllExpirationWarningsCalled = false
    public var getExpiringItemCountCalled = false
    public var shouldThrowError = false
    public var errorToThrow: TrashExpirationNotifierError?
    public var mockExpiringItemCount: Int = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - Mock Methods

    public func scheduleExpirationWarning() async throws {
        scheduleExpirationWarningCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashExpirationNotifierError.schedulingFailed(reason: "Mock error")
        }
    }

    public func cancelAllExpirationWarnings() async {
        cancelAllExpirationWarningsCalled = true
    }

    public func getExpiringItemCount() async -> Int {
        getExpiringItemCountCalled = true
        return mockExpiringItemCount
    }

    // MARK: - Test Helper Methods

    public func reset() {
        scheduleExpirationWarningCalled = false
        cancelAllExpirationWarningsCalled = false
        getExpiringItemCountCalled = false
        shouldThrowError = false
        errorToThrow = nil
        mockExpiringItemCount = 0
    }
}

#endif
