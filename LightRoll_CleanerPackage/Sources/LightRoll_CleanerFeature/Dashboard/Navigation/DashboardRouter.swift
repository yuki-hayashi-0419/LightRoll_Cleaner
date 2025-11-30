//
//  DashboardRouter.swift
//  LightRoll_CleanerFeature
//
//  ダッシュボードモジュールのナビゲーションルーター
//  HomeView → GroupListView → GroupDetailView の画面遷移を管理
//  MV Pattern: @Observable + @Environment で実装
//  Created by AI Assistant
//

import SwiftUI

// MARK: - DashboardDestination

/// ダッシュボードモジュール内の遷移先を表す列挙型
public enum DashboardDestination: Hashable, Sendable {
    /// グループリスト画面（全タイプ表示）
    case groupList

    /// グループリスト画面（特定タイプでフィルタ）
    case groupListFiltered(GroupType)

    /// グループ詳細画面
    case groupDetail(PhotoGroup)

    /// 設定画面（外部モジュール）
    case settings
}

// MARK: - DashboardRouter

/// ダッシュボードモジュールのルーター
/// NavigationStackのパスを管理し、画面遷移を制御
@Observable
@MainActor
public final class DashboardRouter: Sendable {

    // MARK: - Properties

    /// ナビゲーションパス
    public var path: [DashboardDestination] = []

    /// ルートレベルのナビゲーションコールバック（設定等）
    /// 外部モジュールへの遷移時に使用
    public var onNavigateToSettings: (() -> Void)?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter onNavigateToSettings: 設定画面への遷移コールバック
    public init(onNavigateToSettings: (() -> Void)? = nil) {
        self.onNavigateToSettings = onNavigateToSettings
    }

    // MARK: - Navigation Methods

    /// グループリスト画面へ遷移
    /// - Parameter filterType: フィルタタイプ（nil の場合は全タイプ表示）
    public func navigateToGroupList(filterType: GroupType? = nil) {
        if let filterType = filterType {
            path.append(.groupListFiltered(filterType))
        } else {
            path.append(.groupList)
        }
    }

    /// グループ詳細画面へ遷移
    /// - Parameter group: 表示するグループ
    public func navigateToGroupDetail(group: PhotoGroup) {
        path.append(.groupDetail(group))
    }

    /// 設定画面へ遷移（外部モジュール）
    public func navigateToSettings() {
        onNavigateToSettings?()
    }

    /// 一つ前の画面に戻る
    public func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// ルート画面（ホーム）に戻る
    public func navigateToRoot() {
        path.removeAll()
    }

    /// 指定した遷移先まで戻る
    /// - Parameter destination: 遷移先
    public func navigateBackTo(_ destination: DashboardDestination) {
        if let index = path.firstIndex(of: destination) {
            path = Array(path.prefix(upTo: index + 1))
        }
    }
}

// MARK: - Environment Key

/// DashboardRouterの環境キー
private struct DashboardRouterKey: EnvironmentKey {
    @MainActor
    static let defaultValue = DashboardRouter()
}

extension EnvironmentValues {
    /// DashboardRouterへのアクセス
    public var dashboardRouter: DashboardRouter {
        get { self[DashboardRouterKey.self] }
        set { self[DashboardRouterKey.self] = newValue }
    }
}
