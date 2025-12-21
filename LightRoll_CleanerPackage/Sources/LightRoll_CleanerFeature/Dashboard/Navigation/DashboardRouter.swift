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

    /// グループ詳細画面（グループIDで指定）
    case groupDetail(UUID)

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
        print("🔵 [DEBUG] navigateToGroupList called with filterType: \(String(describing: filterType))")
        print("🔵 [DEBUG] Current path count: \(path.count)")
        print("🔵 [DEBUG] Current path: \(path)")

        let destination: DashboardDestination = filterType.map { .groupListFiltered($0) } ?? .groupList
        print("🔵 [DEBUG] Destination determined: \(destination)")

        // 既に同じDestinationがpathの最後にある場合は追加しない
        guard path.last != destination else {
            print("⚠️ 既に \(destination) に遷移済みのため、重複pushをスキップ")
            return
        }

        print("📍 ナビゲーション: \(destination) へ遷移")
        print("🔵 [DEBUG] About to append destination to path")
        path.append(destination)
        print("🔵 [DEBUG] Path after append: \(path)")
        print("🔵 [DEBUG] Path count after append: \(path.count)")
    }

    /// グループ詳細画面へ遷移
    /// - Parameter groupId: 表示するグループのID
    public func navigateToGroupDetail(groupId: UUID) {
        path.append(.groupDetail(groupId))
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
