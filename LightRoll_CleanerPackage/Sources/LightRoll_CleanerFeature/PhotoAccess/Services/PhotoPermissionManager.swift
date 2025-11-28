//
//  PhotoPermissionManager.swift
//  LightRoll_CleanerFeature
//
//  写真ライブラリへのアクセス権限を管理するマネージャー
//  PHPhotoLibrary を使用した権限チェックとリクエストを担当
//  Created by AI Assistant
//

import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

// MARK: - PhotoPermissionManagerProtocol

/// 写真権限マネージャープロトコル
/// テスト可能にするためのプロトコル定義
/// MainActor 上で動作することを前提とする
@MainActor
public protocol PhotoPermissionManagerProtocol: AnyObject {
    /// 現在の権限ステータス
    var currentStatus: PHAuthorizationStatus { get }

    /// 権限ステータスをチェックして返す
    /// - Returns: 現在の権限ステータス
    func checkPermissionStatus() -> PHAuthorizationStatus

    /// 権限をリクエストする
    /// - Returns: リクエスト後の権限ステータス
    func requestPermission() async -> PHAuthorizationStatus

    /// 設定アプリを開く
    func openSettings()
}

// MARK: - PhotoPermissionManager

/// 写真ライブラリへのアクセス権限を管理するマネージャー
/// PHPhotoLibrary のラッパーとして機能し、権限の状態管理とリクエストを担当
@Observable
@MainActor
public final class PhotoPermissionManager: PhotoPermissionManagerProtocol {

    // MARK: - Properties

    /// 現在の権限ステータス
    /// @Observable により自動的に SwiftUI と連携
    public private(set) var currentStatus: PHAuthorizationStatus

    /// 設定アプリを開くための抽象化（テスト用）
    private let settingsOpener: SettingsOpenerProtocol

    // MARK: - Initialization

    /// 初期化
    /// - Parameter settingsOpener: 設定アプリを開くためのオブジェクト（デフォルトは実際の実装）
    public init(settingsOpener: SettingsOpenerProtocol = DefaultSettingsOpener()) {
        self.currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.settingsOpener = settingsOpener
    }

    // MARK: - PhotoPermissionManagerProtocol

    /// 権限ステータスをチェックして返す
    /// システムの最新の権限状態を取得し、内部状態も更新する
    /// - Returns: 現在の権限ステータス
    public func checkPermissionStatus() -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        currentStatus = status
        return status
    }

    /// 権限をリクエストする
    /// ユーザーに権限ダイアログを表示し、結果を返す
    /// - Returns: リクエスト後の権限ステータス
    public func requestPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        currentStatus = status
        return status
    }

    /// 設定アプリを開く
    /// 権限が拒否された場合にユーザーを設定画面へ誘導する
    public func openSettings() {
        settingsOpener.openSettings()
    }
}

// MARK: - SettingsOpenerProtocol

/// 設定アプリを開くためのプロトコル
/// テスト時にモックできるように抽象化
public protocol SettingsOpenerProtocol: Sendable {
    /// 設定アプリを開く
    func openSettings()
}

// MARK: - DefaultSettingsOpener

/// 設定アプリを開くデフォルト実装
public struct DefaultSettingsOpener: SettingsOpenerProtocol {
    public init() {}

    /// 設定アプリを開く
    /// iOS の設定アプリへのディープリンクを使用
    public func openSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        // MainActor で実行
        Task { @MainActor in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        #endif
    }
}

// MARK: - PHAuthorizationStatus Extension

extension PHAuthorizationStatus {
    /// 権限が許可されているかどうか
    /// .authorized または .limited の場合に true
    public var isAuthorized: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .notDetermined, .denied, .restricted:
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

    /// PermissionStatus への変換
    /// ServiceProtocols で定義された汎用的な権限状態に変換
    public var toPermissionStatus: PermissionStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .denied
        }
    }

    /// ローカライズされた説明文
    public var localizedDescription: String {
        switch self {
        case .notDetermined:
            return NSLocalizedString(
                "permission.photo.notDetermined",
                value: "写真へのアクセス権限が未設定です",
                comment: "Photo permission not determined"
            )
        case .restricted:
            return NSLocalizedString(
                "permission.photo.restricted",
                value: "写真へのアクセスが制限されています",
                comment: "Photo permission restricted"
            )
        case .denied:
            return NSLocalizedString(
                "permission.photo.denied",
                value: "写真へのアクセスが拒否されています",
                comment: "Photo permission denied"
            )
        case .authorized:
            return NSLocalizedString(
                "permission.photo.authorized",
                value: "すべての写真にアクセスできます",
                comment: "Photo permission authorized"
            )
        case .limited:
            return NSLocalizedString(
                "permission.photo.limited",
                value: "選択した写真のみアクセスできます",
                comment: "Photo permission limited"
            )
        @unknown default:
            return NSLocalizedString(
                "permission.photo.unknown",
                value: "不明な権限状態です",
                comment: "Photo permission unknown"
            )
        }
    }
}
