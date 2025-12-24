//
//  NotificationManager.swift
//  LightRoll_CleanerFeature
//
//  通知管理サービス
//  - UNUserNotificationCenterの統合
//  - 権限状態の管理
//  - 通知スケジューリング基盤
//  - NotificationSettingsとの統合
//  MV Pattern: @Observable + Sendable準拠
//  Created by AI Assistant for M7-T03
//

import Foundation
@preconcurrency import UserNotifications
import Observation

// MARK: - UserNotificationCenterProtocol

/// UNUserNotificationCenterの抽象化プロトコル
/// テスト時にモック実装を注入できるようにする
public protocol UserNotificationCenterProtocol: Sendable {
    /// 通知権限のステータスを取得
    func getAuthorizationStatus() async -> UNAuthorizationStatus

    /// 通知権限をリクエスト
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// 通知をスケジュール
    func add(_ request: UNNotificationRequest) async throws

    /// ペンディング中の通知リクエストを取得
    func getPendingNotificationRequests() async -> [UNNotificationRequest]

    /// すべてのペンディング通知をキャンセル
    func removeAllPendingNotificationRequests() async

    /// 特定の通知をキャンセル
    func removePendingNotificationRequests(withIdentifiers: [String]) async

    /// 配信済み通知を取得
    func getDeliveredNotifications() async -> [UNNotification]

    /// すべての配信済み通知を削除
    func removeAllDeliveredNotifications() async
}

// MARK: - DefaultNotificationCenter

/// UNUserNotificationCenterの実装ラッパー
public struct DefaultNotificationCenter: UserNotificationCenterProtocol {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return try await center.requestAuthorization(options: options)
    }

    public func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    public func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    public func removeAllPendingNotificationRequests() async {
        center.removeAllPendingNotificationRequests()
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }

    public func removeAllDeliveredNotifications() async {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - NotificationManager

/// 通知を管理するサービス
///
/// MV Patternに従い、@Observableサービスとして実装
/// - UNUserNotificationCenterの統合
/// - 権限管理
/// - 通知スケジューリング
/// - NotificationSettingsとの統合
@MainActor
@Observable
public final class NotificationManager: Sendable {

    // MARK: - Properties

    /// 現在の通知権限ステータス
    /// @Observableにより自動的にSwiftUIと連携
    public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// 現在の通知設定
    public private(set) var settings: NotificationSettings

    /// ペンディング中の通知数
    public private(set) var pendingNotificationCount: Int = 0

    /// 最後に発生したエラー
    public private(set) var lastError: NotificationError?

    /// 通知センターの抽象化（テスト用）
    private let notificationCenter: UserNotificationCenterProtocol

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - settings: 通知設定（デフォルトは標準設定）
    ///   - notificationCenter: 通知センター（デフォルトは実装）
    public init(
        settings: NotificationSettings = .default,
        notificationCenter: UserNotificationCenterProtocol = DefaultNotificationCenter()
    ) {
        self.settings = settings
        self.notificationCenter = notificationCenter
    }

    // MARK: - Permission Management

    /// 通知権限のステータスを更新
    ///
    /// システムから最新の権限状態を取得し、内部状態を更新する
    public func updateAuthorizationStatus() async {
        authorizationStatus = await notificationCenter.getAuthorizationStatus()
    }

    /// 通知権限をリクエスト
    ///
    /// ユーザーに通知権限ダイアログを表示し、結果を返す
    /// - Returns: 権限が許可された場合true
    /// - Throws: NotificationError（リクエスト失敗時）
    @discardableResult
    public func requestPermission() async throws -> Bool {
        // 現在のステータスを確認
        await updateAuthorizationStatus()

        // すでに決定済みの場合は現在の状態を返す
        if authorizationStatus == .authorized || authorizationStatus == .provisional {
            lastError = nil
            return true
        }

        if authorizationStatus == .denied {
            lastError = .permissionDenied
            throw NotificationError.permissionDenied
        }

        // 権限リクエスト実行
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            // ステータスを再取得
            await updateAuthorizationStatus()

            if granted {
                lastError = nil
                return true
            } else {
                lastError = .permissionDenied
                throw NotificationError.permissionDenied
            }
        } catch let error as NotificationError {
            lastError = error
            throw error
        } catch {
            let notificationError = NotificationError.permissionRequestFailed(
                underlying: error.localizedDescription
            )
            lastError = notificationError
            throw notificationError
        }
    }

    /// 権限が許可されているかを確認
    ///
    /// - Returns: 権限が許可されている場合true
    public var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    /// 権限リクエストが可能かを確認
    ///
    /// - Returns: 権限リクエストが可能な場合true
    public var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - Settings Management

    /// 通知設定を更新
    ///
    /// - Parameter newSettings: 新しい通知設定
    /// - Throws: NotificationError（設定が無効な場合）
    public func updateSettings(_ newSettings: NotificationSettings) throws {
        // バリデーション
        guard newSettings.isValid else {
            let error = NotificationError.invalidSettings(reason: "設定値が範囲外です")
            lastError = error
            throw error
        }

        settings = newSettings
        lastError = nil
    }

    /// SettingsServiceから通知設定を同期（SETTINGS-002対応）
    ///
    /// SettingsServiceで管理されるNotificationSettingsを
    /// NotificationManagerに反映します。
    /// これによりSettingsViewでの設定変更がNotificationManagerに正しく反映されます。
    ///
    /// - Parameter settingsService: 設定サービス
    public func syncSettings(from settingsService: SettingsService) {
        let newSettings = settingsService.settings.notificationSettings
        if newSettings.isValid {
            settings = newSettings
            lastError = nil
        }
    }

    // MARK: - Notification Scheduling

    /// 通知をスケジュール
    ///
    /// 通知設定と静寂時間帯を考慮して通知を登録する
    /// - Parameters:
    ///   - identifier: 通知識別子
    ///   - content: 通知コンテンツ
    ///   - trigger: 通知トリガー
    /// - Throws: NotificationError（スケジューリング失敗時）
    public func scheduleNotification(
        identifier: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger?
    ) async throws {
        // バリデーション
        guard !identifier.isEmpty else {
            let error = NotificationError.invalidIdentifier(identifier)
            lastError = error
            throw error
        }

        // 通知が無効化されている場合はエラー
        guard settings.isEnabled else {
            let error = NotificationError.invalidSettings(reason: "通知が無効化されています")
            lastError = error
            throw error
        }

        // 権限確認
        await updateAuthorizationStatus()
        guard isAuthorized else {
            let error = NotificationError.permissionDenied
            lastError = error
            throw error
        }

        // 通知リクエスト作成
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // スケジュール実行
        do {
            try await notificationCenter.add(request)
            await updatePendingNotificationCount()
            lastError = nil
        } catch {
            let notificationError = NotificationError.schedulingFailed(
                identifier: identifier,
                reason: error.localizedDescription
            )
            lastError = notificationError
            throw notificationError
        }
    }

    /// 通知をキャンセル
    ///
    /// - Parameter identifier: キャンセルする通知の識別子
    public func cancelNotification(identifier: String) async {
        guard !identifier.isEmpty else {
            lastError = .invalidIdentifier(identifier)
            return
        }

        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        await updatePendingNotificationCount()
        lastError = nil
    }

    /// すべての通知をキャンセル
    public func cancelAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
        await updatePendingNotificationCount()
        lastError = nil
    }

    /// すべての配信済み通知を削除
    public func removeAllDeliveredNotifications() async {
        await notificationCenter.removeAllDeliveredNotifications()
        lastError = nil
    }

    // MARK: - Notification Queries

    /// ペンディング中の通知を取得
    ///
    /// - Returns: ペンディング通知リクエストの配列
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.getPendingNotificationRequests()
    }

    /// 配信済み通知を取得
    ///
    /// - Returns: 配信済み通知の配列
    public func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.getDeliveredNotifications()
    }

    /// 特定の識別子の通知が存在するか確認
    ///
    /// - Parameter identifier: 通知識別子
    /// - Returns: 通知が存在する場合true
    public func hasNotification(identifier: String) async -> Bool {
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier == identifier }
    }

    // MARK: - Helper Methods

    /// ペンディング通知数を更新
    private func updatePendingNotificationCount() async {
        let pending = await getPendingNotifications()
        pendingNotificationCount = pending.count
    }

    /// エラーをクリア
    public func clearError() {
        lastError = nil
    }

    /// 現在時刻が静寂時間帯内かを判定
    ///
    /// - Returns: 静寂時間帯内の場合true
    public var isInQuietHours: Bool {
        settings.isCurrentlyInQuietHours()
    }

    /// 通知が有効かを判定
    ///
    /// 通知設定が有効で、権限が許可されている場合にtrue
    /// - Returns: 通知が有効な場合true
    public var isNotificationEnabled: Bool {
        settings.isEnabled && isAuthorized
    }
}

// MARK: - Notification Identifiers

/// 通知識別子の定義
///
/// アプリ内で使用する通知の識別子を定義
public extension NotificationManager {
    /// 通知識別子の列挙型
    enum NotificationIdentifier: String, CaseIterable {
        /// ストレージアラート通知
        case storageAlert = "storage_alert"

        /// 定期リマインダー通知
        case reminder = "reminder"

        /// スキャン完了通知
        case scanCompletion = "scan_completion"

        /// ゴミ箱期限警告通知
        case trashExpiration = "trash_expiration"

        /// 識別子文字列
        public var identifier: String {
            rawValue
        }
    }

    /// 通知識別子で通知をキャンセル
    /// - Parameter identifier: キャンセルする通知識別子
    func cancelNotification(_ identifier: NotificationIdentifier) async {
        await cancelNotification(identifier: identifier.identifier)
    }

    /// 通知識別子で通知の存在確認
    /// - Parameter identifier: 確認する通知識別子
    /// - Returns: 通知が存在する場合true
    func hasNotification(_ identifier: NotificationIdentifier) async -> Bool {
        await hasNotification(identifier: identifier.identifier)
    }
}
