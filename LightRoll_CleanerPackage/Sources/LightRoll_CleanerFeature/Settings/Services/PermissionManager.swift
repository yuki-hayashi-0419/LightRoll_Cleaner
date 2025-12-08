//
//  PermissionManager.swift
//  LightRoll_CleanerFeature
//
//  アプリ全体の権限管理を統合するマネージャー
//  写真ライブラリと通知の権限チェック・リクエストを担当
//  Created by AI Assistant for M8-T03
//

import Foundation
import Photos
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

// MARK: - PermissionManager

/// アプリ全体の権限を管理するマネージャー
/// PHPhotoLibrary と UNUserNotificationCenter を統合管理
/// ServiceProtocols の PermissionManagerProtocol に準拠
@Observable
@MainActor
public final class PermissionManager: PermissionManagerProtocol {

    // MARK: - Properties

    /// 現在の写真権限ステータス
    /// @Observable により自動的に SwiftUI と連携
    public private(set) var currentPhotoStatus: PHAuthorizationStatus

    /// 設定アプリを開くための抽象化（テスト用）
    private let settingsOpener: SettingsOpenerProtocol

    /// 通知センターの抽象化（テスト用）
    private let notificationCenter: PermissionNotificationCenterProtocol

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - settingsOpener: 設定アプリを開くためのオブジェクト（デフォルトは実際の実装）
    ///   - notificationCenter: 通知センター（デフォルトは実際の実装）
    public init(
        settingsOpener: SettingsOpenerProtocol = DefaultSettingsOpener(),
        notificationCenter: PermissionNotificationCenterProtocol = DefaultPermissionNotificationCenter()
    ) {
        self.currentPhotoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.settingsOpener = settingsOpener
        self.notificationCenter = notificationCenter
    }

    // MARK: - PermissionManagerProtocol (汎用インターフェース)

    /// 指定された権限の状態を取得
    /// - Parameter type: 権限種別
    /// - Returns: 権限状態
    public func getStatus(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .photoLibrary:
            return getPhotoPermissionStatus().toPermissionStatus
        case .notifications:
            let unStatus = await getNotificationPermissionStatus()
            return unStatus.toPermissionStatus
        }
    }

    /// 指定された権限をリクエスト
    /// - Parameter type: 権限種別
    /// - Returns: リクエスト後の権限状態
    public func requestPermission(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .photoLibrary:
            let phStatus = await requestPhotoPermission()
            return phStatus.toPermissionStatus
        case .notifications:
            let granted = await requestNotificationPermission()
            return granted ? .authorized : .denied
        }
    }

    /// 設定アプリを開く
    /// 権限が拒否された場合にユーザーを設定画面へ誘導
    public func openSettings() async {
        openAppSettings()
    }

    /// 全権限の状態を取得
    /// - Returns: 権限種別と状態のマップ
    public func getAllStatuses() async -> [PermissionType: PermissionStatus] {
        var statuses: [PermissionType: PermissionStatus] = [:]

        for type in PermissionType.allCases {
            statuses[type] = await getStatus(for: type)
        }

        return statuses
    }

    // MARK: - 具体的な型を返すメソッド (M8-T03 要求仕様)

    /// 写真権限ステータスを取得
    /// システムの最新の権限状態を取得し、内部状態も更新する
    /// - Returns: 現在の写真権限ステータス
    public func getPhotoPermissionStatus() -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        currentPhotoStatus = status
        return status
    }

    /// 通知権限ステータスを取得
    /// UNUserNotificationCenter から最新の権限状態を取得
    /// - Returns: 現在の通知権限ステータス
    public func getNotificationPermissionStatus() async -> UNAuthorizationStatus {
        return await notificationCenter.getAuthorizationStatus()
    }

    /// 写真権限をリクエスト
    /// ユーザーに写真権限ダイアログを表示し、結果を返す
    /// - Returns: リクエスト後の権限ステータス
    public func requestPhotoPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        currentPhotoStatus = status
        return status
    }

    /// 通知権限をリクエスト
    /// ユーザーに通知権限ダイアログを表示し、結果を返す
    /// - Returns: リクエストが成功したかどうか（authorized または provisional の場合に true）
    public func requestNotificationPermission() async -> Bool {
        return await notificationCenter.requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    /// システム設定アプリを開く
    /// 権限が拒否された場合にユーザーを設定画面へ誘導する
    public func openAppSettings() {
        settingsOpener.openSettings()
    }
}

// MARK: - UNAuthorizationStatus to PermissionStatus Extension

extension UNAuthorizationStatus {
    /// PermissionStatus への変換
    /// UserNotifications の権限状態を汎用的な PermissionStatus に変換
    var toPermissionStatus: PermissionStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .provisional, .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }
}

// MARK: - PermissionNotificationCenterProtocol

/// 通知センターのプロトコル（権限管理用）
/// テスト時にモックできるように抽象化
public protocol PermissionNotificationCenterProtocol: Sendable {
    /// 通知権限のステータスを取得
    /// - Returns: 現在の通知権限ステータス
    func getAuthorizationStatus() async -> UNAuthorizationStatus

    /// 通知権限をリクエスト
    /// - Parameter options: リクエストする通知オプション
    /// - Returns: リクエストが成功したかどうか
    func requestAuthorization(options: UNAuthorizationOptions) async -> Bool
}

// MARK: - DefaultPermissionNotificationCenter

/// 通知センターのデフォルト実装（権限管理用）
/// UNUserNotificationCenter の実際の実装を使用
public struct DefaultPermissionNotificationCenter: PermissionNotificationCenterProtocol {
    public init() {}

    /// 通知権限のステータスを取得
    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// 通知権限をリクエスト
    public func requestAuthorization(options: UNAuthorizationOptions) async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: options)
            return granted
        } catch {
            return false
        }
    }
}

// MARK: - UNAuthorizationStatus Extension

extension UNAuthorizationStatus {
    /// 権限が許可されているかどうか
    /// .authorized または .provisional の場合に true
    public var isAuthorized: Bool {
        switch self {
        case .authorized, .provisional:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// 権限リクエストが可能かどうか
    /// .notDetermined の場合のみ true
    public var canRequestPermission: Bool {
        self == .notDetermined
    }

    /// 設定画面への誘導が必要かどうか
    /// .denied の場合に true
    public var needsSettingsRedirect: Bool {
        self == .denied
    }

    /// ローカライズされた説明文
    public var localizedDescription: String {
        switch self {
        case .notDetermined:
            return NSLocalizedString(
                "permission.notification.notDetermined",
                value: "通知の許可が未設定です",
                comment: "Notification permission not determined"
            )
        case .denied:
            return NSLocalizedString(
                "permission.notification.denied",
                value: "通知が拒否されています",
                comment: "Notification permission denied"
            )
        case .authorized:
            return NSLocalizedString(
                "permission.notification.authorized",
                value: "通知が許可されています",
                comment: "Notification permission authorized"
            )
        case .provisional:
            return NSLocalizedString(
                "permission.notification.provisional",
                value: "静かな通知が許可されています",
                comment: "Notification permission provisional"
            )
        case .ephemeral:
            return NSLocalizedString(
                "permission.notification.ephemeral",
                value: "一時的な通知が許可されています",
                comment: "Notification permission ephemeral"
            )
        @unknown default:
            return NSLocalizedString(
                "permission.notification.unknown",
                value: "不明な権限状態です",
                comment: "Notification permission unknown"
            )
        }
    }
}
