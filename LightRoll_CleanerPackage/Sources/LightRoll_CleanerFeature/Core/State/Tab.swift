//
//  Tab.swift
//  LightRoll_CleanerFeature
//
//  アプリケーションのタブ定義
//  メインナビゲーションのタブを管理
//  Created by AI Assistant
//

import Foundation

// MARK: - Tab

/// アプリケーションのメインタブ
/// TabViewで使用されるナビゲーションタブを定義
public enum Tab: String, CaseIterable, Identifiable, Sendable {

    /// ダッシュボード（ホーム画面）
    case dashboard

    /// グループ一覧
    case groups

    /// 設定
    case settings

    // MARK: - Identifiable

    public var id: String { rawValue }

    // MARK: - Display Properties

    /// タブのタイトル
    public var title: String {
        switch self {
        case .dashboard:
            return NSLocalizedString(
                "tab.dashboard.title",
                value: "ホーム",
                comment: "Dashboard tab title"
            )
        case .groups:
            return NSLocalizedString(
                "tab.groups.title",
                value: "グループ",
                comment: "Groups tab title"
            )
        case .settings:
            return NSLocalizedString(
                "tab.settings.title",
                value: "設定",
                comment: "Settings tab title"
            )
        }
    }

    /// タブのアイコン名（SF Symbols）
    public var icon: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .groups:
            return "square.stack.3d.up.fill"
        case .settings:
            return "gearshape.fill"
        }
    }

    /// タブの未選択時アイコン名
    public var inactiveIcon: String {
        switch self {
        case .dashboard:
            return "house"
        case .groups:
            return "square.stack.3d.up"
        case .settings:
            return "gearshape"
        }
    }

    /// タブの説明（アクセシビリティ用）
    public var accessibilityLabel: String {
        switch self {
        case .dashboard:
            return NSLocalizedString(
                "tab.dashboard.accessibility",
                value: "ホーム画面を表示",
                comment: "Dashboard tab accessibility label"
            )
        case .groups:
            return NSLocalizedString(
                "tab.groups.accessibility",
                value: "写真グループ一覧を表示",
                comment: "Groups tab accessibility label"
            )
        case .settings:
            return NSLocalizedString(
                "tab.settings.accessibility",
                value: "設定画面を表示",
                comment: "Settings tab accessibility label"
            )
        }
    }
}

// MARK: - Tab + Hashable

extension Tab: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
