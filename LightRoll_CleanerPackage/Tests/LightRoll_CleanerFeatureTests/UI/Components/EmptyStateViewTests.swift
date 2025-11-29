//
//  EmptyStateViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  EmptyStateViewコンポーネントのテストスイート
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - Test Helpers

/// アクション呼び出しを追跡するためのクラス
final class ActionTracker: @unchecked Sendable {
    private var _wasCalled = false
    private let lock = NSLock()

    var wasCalled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _wasCalled
    }

    func markCalled() {
        lock.lock()
        defer { lock.unlock() }
        _wasCalled = true
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _wasCalled = false
    }
}

// MARK: - Test Suite

@Suite("EmptyStateView Tests")
@MainActor
struct EmptyStateViewTests {

    // MARK: - 正常系テスト (7件)

    @Test("空リスト状態のデフォルト表示")
    func emptyStateDefaultDisplay() {
        let view = EmptyStateView(type: .empty)

        #expect(view.type.defaultIcon == "photo.on.rectangle.angled")
        #expect(view.type.defaultTitle == "写真がありません")
        #expect(view.type.defaultMessage == "写真をスキャンして整理を開始しましょう")
    }

    @Test("検索結果なし状態のデフォルト表示")
    func noSearchResultsDefaultDisplay() {
        let view = EmptyStateView(type: .noSearchResults)

        #expect(view.type.defaultIcon == "magnifyingglass")
        #expect(view.type.defaultTitle == "検索結果がありません")
        #expect(view.type.defaultMessage == "検索条件を変更して再度お試しください")
    }

    @Test("エラー状態のデフォルト表示")
    func errorStateDefaultDisplay() {
        let view = EmptyStateView(type: .error)

        #expect(view.type.defaultIcon == "exclamationmark.triangle")
        #expect(view.type.defaultTitle == "エラーが発生しました")
        #expect(view.type.defaultMessage == "問題が発生しました。もう一度お試しください")
        #expect(view.type.iconColor == Color.LightRoll.error)
    }

    @Test("権限なし状態のデフォルト表示")
    func noPermissionStateDefaultDisplay() {
        let view = EmptyStateView(type: .noPermission)

        #expect(view.type.defaultIcon == "lock.shield")
        #expect(view.type.defaultTitle == "権限がありません")
        #expect(view.type.defaultMessage == "写真ライブラリへのアクセスを許可してください")
        #expect(view.type.iconColor == Color.LightRoll.warning)
    }

    @Test("カスタム状態の表示")
    func customStateDisplay() {
        let view = EmptyStateView(
            type: .custom(
                icon: "star.fill",
                title: "お気に入りがありません",
                message: "お気に入りの写真を追加してみましょう"
            )
        )

        #expect(view.type.defaultIcon == "star.fill")
        #expect(view.type.defaultTitle == "お気に入りがありません")
        #expect(view.type.defaultMessage == "お気に入りの写真を追加してみましょう")
    }

    @Test("アクションボタン付きの表示")
    func viewWithActionButton() async {
        let tracker = ActionTracker()

        let view = EmptyStateView(
            type: .empty,
            actionTitle: "スキャンを開始",
            actionIcon: "magnifyingglass"
        ) {
            tracker.markCalled()
        }

        #expect(view.actionTitle == "スキャンを開始")
        #expect(view.actionIcon == "magnifyingglass")
        #expect(view.onAction != nil)

        // アクション実行
        if let action = view.onAction {
            await action()
            #expect(tracker.wasCalled == true)
        }
    }

    @Test("アクションなしの表示")
    func viewWithoutAction() {
        let view = EmptyStateView(type: .noSearchResults)

        #expect(view.onAction == nil)
        #expect(view.actionTitle == nil)
    }

    // MARK: - 異常系テスト (3件)

    @Test("空のカスタムタイトル")
    func emptyCustomTitle() {
        let view = EmptyStateView(
            type: .empty,
            customTitle: ""
        )

        // 空文字列が設定されることを確認
        #expect(view.customTitle == "")
    }

    @Test("空のカスタムメッセージ")
    func emptyCustomMessage() {
        let view = EmptyStateView(
            type: .empty,
            customMessage: ""
        )

        // 空文字列が設定されることを確認
        #expect(view.customMessage == "")
    }

    @Test("非常に長いテキスト")
    func veryLongText() {
        let longTitle = String(repeating: "あ", count: 100)
        let longMessage = String(repeating: "い", count: 500)

        let view = EmptyStateView(
            type: .empty,
            customTitle: longTitle,
            customMessage: longMessage
        )

        #expect(view.customTitle?.count == 100)
        #expect(view.customMessage?.count == 500)
    }

    // MARK: - 境界値テスト (3件)

    @Test("最小文字数のテキスト（1文字）")
    func minimumTextLength() {
        let view = EmptyStateView(
            type: .empty,
            customTitle: "あ",
            customMessage: "い"
        )

        #expect(view.customTitle == "あ")
        #expect(view.customMessage == "い")
    }

    @Test("長いアイコン名")
    func longIconName() {
        let view = EmptyStateView(
            type: .empty,
            customIcon: "exclamationmark.triangle.fill.circle.fill"
        )

        #expect(view.customIcon == "exclamationmark.triangle.fill.circle.fill")
    }

    @Test("長いアクションタイトル")
    func longActionTitle() {
        let view = EmptyStateView(
            type: .empty,
            actionTitle: "写真ライブラリへのアクセスを許可する",
            actionIcon: "lock.shield"
        ) {}

        #expect(view.actionTitle == "写真ライブラリへのアクセスを許可する")
    }

    // MARK: - EmptyStateTypeテスト (5件)

    @Test("empty状態のデフォルト値")
    func emptyTypeDefaults() {
        let type = EmptyStateType.empty

        #expect(type.defaultIcon == "photo.on.rectangle.angled")
        #expect(type.defaultTitle == "写真がありません")
        #expect(type.defaultMessage == "写真をスキャンして整理を開始しましょう")
        #expect(type.iconColor == Color.LightRoll.textSecondary)
    }

    @Test("noSearchResults状態のデフォルト値")
    func noSearchResultsTypeDefaults() {
        let type = EmptyStateType.noSearchResults

        #expect(type.defaultIcon == "magnifyingglass")
        #expect(type.defaultTitle == "検索結果がありません")
        #expect(type.defaultMessage == "検索条件を変更して再度お試しください")
        #expect(type.iconColor == Color.LightRoll.textSecondary)
    }

    @Test("error状態のデフォルト値とアイコン色")
    func errorTypeDefaults() {
        let type = EmptyStateType.error

        #expect(type.defaultIcon == "exclamationmark.triangle")
        #expect(type.defaultTitle == "エラーが発生しました")
        #expect(type.iconColor == Color.LightRoll.error)
    }

    @Test("noPermission状態のデフォルト値とアイコン色")
    func noPermissionTypeDefaults() {
        let type = EmptyStateType.noPermission

        #expect(type.defaultIcon == "lock.shield")
        #expect(type.defaultTitle == "権限がありません")
        #expect(type.iconColor == Color.LightRoll.warning)
    }

    @Test("custom状態のカスタム値")
    func customTypeValues() {
        let type = EmptyStateType.custom(
            icon: "heart.fill",
            title: "カスタムタイトル",
            message: "カスタムメッセージ"
        )

        #expect(type.defaultIcon == "heart.fill")
        #expect(type.defaultTitle == "カスタムタイトル")
        #expect(type.defaultMessage == "カスタムメッセージ")
        #expect(type.iconColor == Color.LightRoll.primary)
    }

    // MARK: - アクセシビリティテスト (5件)

    @Test("empty状態のタイプ確認")
    func emptyStateTypeVerification() {
        let view = EmptyStateView(type: .empty)

        // typeプロパティが正しく設定されていることを確認
        switch view.type {
        case .empty:
            // 正しいタイプが設定されている
            #expect(Bool(true))
        default:
            #expect(Bool(false), "Expected .empty type")
        }
    }

    @Test("error状態のタイプ確認")
    func errorStateTypeVerification() {
        let view = EmptyStateView(type: .error)

        // typeプロパティが正しく設定されていることを確認
        switch view.type {
        case .error:
            // 正しいタイプが設定されている
            #expect(Bool(true))
        default:
            #expect(Bool(false), "Expected .error type")
        }
    }

    @Test("アクションボタンありのプロパティ確認")
    func actionButtonPropertyVerification() {
        let view = EmptyStateView(
            type: .empty,
            actionTitle: "スキャンを開始"
        ) {}

        #expect(view.actionTitle == "スキャンを開始")
        #expect(view.onAction != nil)
    }

    @Test("カスタムメッセージのプロパティ確認")
    func customMessagePropertyVerification() {
        let view = EmptyStateView(
            type: .empty,
            customTitle: "カスタムタイトル",
            customMessage: "カスタムメッセージ"
        )

        #expect(view.customTitle == "カスタムタイトル")
        #expect(view.customMessage == "カスタムメッセージ")
    }

    @Test("アイコンのカスタマイズ確認")
    func iconCustomizationVerification() {
        let view = EmptyStateView(
            type: .empty,
            customIcon: "star.fill"
        )

        #expect(view.customIcon == "star.fill")
    }

    // MARK: - 統合テスト (3件)

    @Test("実用例：空のグループリスト")
    func realWorldEmptyGroupList() {
        let view = EmptyStateView(
            type: .empty,
            customMessage: "類似写真のグループがまだありません",
            actionTitle: "スキャンを開始",
            actionIcon: "magnifyingglass"
        ) {}

        #expect(view.actionTitle == "スキャンを開始")
        #expect(view.customMessage == "類似写真のグループがまだありません")
        #expect(view.onAction != nil)
    }

    @Test("実用例：検索結果が空")
    func realWorldEmptySearchResults() {
        let view = EmptyStateView(
            type: .noSearchResults,
            customMessage: "「風景」に一致する写真が見つかりませんでした"
        )

        #expect(view.type.defaultIcon == "magnifyingglass")
        #expect(view.customMessage == "「風景」に一致する写真が見つかりませんでした")
    }

    @Test("ローディング状態の統合")
    func loadingStateIntegration() {
        let view = EmptyStateView(
            type: .empty,
            actionTitle: "スキャンを開始",
            isActionLoading: true
        ) {}

        #expect(view.isActionLoading == true)
        #expect(view.actionTitle == "スキャンを開始")
        #expect(view.onAction != nil)
    }
}
