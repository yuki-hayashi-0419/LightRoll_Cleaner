//
//  ToastViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ToastViewコンポーネントの包括的なテストスイート
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - Test Helpers

/// 解除呼び出しを追跡するためのクラス
final class DismissTracker: @unchecked Sendable {
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

@Suite("ToastView Tests")
@MainActor
struct ToastViewTests {

    // MARK: - ToastType テスト (4件)

    @Test("success タイプのデフォルト値")
    func successTypeDefaults() {
        let type = ToastType.success

        #expect(type.defaultIcon == "checkmark.circle.fill")
        #expect(type.iconColor == Color.LightRoll.success)
        #expect(type.accentColor == Color.LightRoll.success)
    }

    @Test("error タイプのデフォルト値")
    func errorTypeDefaults() {
        let type = ToastType.error

        #expect(type.defaultIcon == "xmark.circle.fill")
        #expect(type.iconColor == Color.LightRoll.error)
        #expect(type.accentColor == Color.LightRoll.error)
    }

    @Test("warning タイプのデフォルト値")
    func warningTypeDefaults() {
        let type = ToastType.warning

        #expect(type.defaultIcon == "exclamationmark.triangle.fill")
        #expect(type.iconColor == Color.LightRoll.warning)
        #expect(type.accentColor == Color.LightRoll.warning)
    }

    @Test("info タイプのデフォルト値")
    func infoTypeDefaults() {
        let type = ToastType.info

        #expect(type.defaultIcon == "info.circle.fill")
        #expect(type.iconColor == Color.LightRoll.primary)
        #expect(type.accentColor == Color.LightRoll.primary)
    }

    // MARK: - ToastItem 正常系テスト (7件)

    @Test("成功トーストアイテムの作成")
    func createSuccessToastItem() {
        let item = ToastItem(
            type: .success,
            title: "保存しました"
        )

        #expect(item.type == .success)
        #expect(item.title == "保存しました")
        #expect(item.message == nil)
        #expect(item.customIcon == nil)
        #expect(item.duration == 3.0)
    }

    @Test("エラートーストアイテムの作成")
    func createErrorToastItem() {
        let item = ToastItem(
            type: .error,
            title: "削除に失敗しました",
            message: "エラーが発生しました"
        )

        #expect(item.type == .error)
        #expect(item.title == "削除に失敗しました")
        #expect(item.message == "エラーが発生しました")
    }

    @Test("警告トーストアイテムの作成")
    func createWarningToastItem() {
        let item = ToastItem(
            type: .warning,
            title: "ストレージ容量が不足しています"
        )

        #expect(item.type == .warning)
        #expect(item.title == "ストレージ容量が不足しています")
    }

    @Test("情報トーストアイテムの作成")
    func createInfoToastItem() {
        let item = ToastItem(
            type: .info,
            title: "更新が利用可能です"
        )

        #expect(item.type == .info)
        #expect(item.title == "更新が利用可能です")
    }

    @Test("メッセージ付きトーストアイテム")
    func toastItemWithMessage() {
        let item = ToastItem(
            type: .success,
            title: "保存しました",
            message: "写真が正常に保存されました"
        )

        #expect(item.title == "保存しました")
        #expect(item.message == "写真が正常に保存されました")
    }

    @Test("カスタムアイコン付きトーストアイテム")
    func toastItemWithCustomIcon() {
        let item = ToastItem(
            type: .success,
            title: "お気に入りに追加",
            customIcon: "star.fill"
        )

        #expect(item.customIcon == "star.fill")
        #expect(item.displayIcon == "star.fill")
    }

    @Test("カスタムタイマー値のトーストアイテム")
    func toastItemWithCustomDuration() {
        let item = ToastItem(
            type: .success,
            title: "カスタムタイマー",
            duration: 5.0
        )

        #expect(item.duration == 5.0)
    }

    // MARK: - ToastItem Convenience Constructors テスト (4件)

    @Test("ToastItem.success() コンストラクタ")
    func successConvenienceConstructor() {
        let item = ToastItem.success(
            title: "削除完了",
            message: "24枚の写真を削除しました"
        )

        #expect(item.type == .success)
        #expect(item.title == "削除完了")
        #expect(item.message == "24枚の写真を削除しました")
        #expect(item.duration == 3.0)
    }

    @Test("ToastItem.error() コンストラクタ")
    func errorConvenienceConstructor() {
        let item = ToastItem.error(
            title: "削除失敗",
            message: "写真の削除中にエラーが発生しました"
        )

        #expect(item.type == .error)
        #expect(item.title == "削除失敗")
        #expect(item.duration == 4.0)
    }

    @Test("ToastItem.warning() コンストラクタ")
    func warningConvenienceConstructor() {
        let item = ToastItem.warning(
            title: "ストレージ容量不足",
            message: "残り容量が10%未満です"
        )

        #expect(item.type == .warning)
        #expect(item.title == "ストレージ容量不足")
        #expect(item.duration == 3.5)
    }

    @Test("ToastItem.info() コンストラクタ")
    func infoConvenienceConstructor() {
        let item = ToastItem.info(
            title: "スキャン完了",
            message: "120枚の写真を分析しました"
        )

        #expect(item.type == .info)
        #expect(item.title == "スキャン完了")
        #expect(item.duration == 3.0)
    }

    // MARK: - ToastView 正常系テスト (3件)

    @Test("ToastViewの作成とプロパティ確認")
    func createToastView() async {
        let tracker = DismissTracker()
        let item = ToastItem(
            type: .success,
            title: "保存しました"
        )

        let view = ToastView(toast: item) {
            tracker.markCalled()
        }

        #expect(view.toast.type == .success)
        #expect(view.toast.title == "保存しました")
    }

    @Test("ToastViewの解除コールバック")
    func toastViewDismissCallback() async {
        let tracker = DismissTracker()
        let item = ToastItem(
            type: .success,
            title: "テスト"
        )

        let view = ToastView(toast: item) {
            tracker.markCalled()
        }

        // onDismissを直接呼び出してテスト
        await view.onDismiss()
        #expect(tracker.wasCalled == true)
    }

    @Test("ToastView displayIcon プロパティ")
    func toastViewDisplayIcon() {
        let item = ToastItem(
            type: .success,
            title: "テスト",
            customIcon: "heart.fill"
        )

        let view = ToastView(toast: item) {}

        #expect(view.toast.displayIcon == "heart.fill")
    }

    // MARK: - ToastItem 異常系テスト (3件)

    @Test("空のタイトル")
    func emptyTitle() {
        let item = ToastItem(
            type: .success,
            title: ""
        )

        #expect(item.title == "")
    }

    @Test("非常に長いタイトル")
    func veryLongTitle() {
        let longTitle = String(repeating: "あ", count: 100)
        let item = ToastItem(
            type: .success,
            title: longTitle
        )

        #expect(item.title.count == 100)
    }

    @Test("非常に長いメッセージ")
    func veryLongMessage() {
        let longMessage = String(repeating: "い", count: 500)
        let item = ToastItem(
            type: .success,
            title: "タイトル",
            message: longMessage
        )

        #expect(item.message?.count == 500)
    }

    // MARK: - 境界値テスト (4件)

    @Test("duration = 0（自動消去なし）")
    func zeroDuration() {
        let item = ToastItem(
            type: .success,
            title: "永続表示",
            duration: 0
        )

        #expect(item.duration == 0)
    }

    @Test("duration = nil（自動消去なし）")
    func nilDuration() {
        let item = ToastItem(
            type: .warning,
            title: "重要なお知らせ",
            duration: nil
        )

        #expect(item.duration == nil)
    }

    @Test("最大タイマー値")
    func maximumDuration() {
        let item = ToastItem(
            type: .success,
            title: "長時間表示",
            duration: 15.0
        )

        #expect(item.duration == 15.0)
    }

    @Test("1文字のタイトル/メッセージ")
    func singleCharacterText() {
        let item = ToastItem(
            type: .success,
            title: "あ",
            message: "い"
        )

        #expect(item.title == "あ")
        #expect(item.message == "い")
    }

    // MARK: - ToastContainer テスト (3件)

    @Test("ToastContainerの初期化")
    func createToastContainer() {
        @State var toasts: [ToastItem] = []

        let container = ToastContainer(
            toasts: $toasts,
            maxToasts: 3
        )

        #expect(container.maxToasts == 3)
    }

    @Test("ToastContainerのカスタム最大数")
    func customMaxToasts() {
        @State var toasts: [ToastItem] = []

        let container = ToastContainer(
            toasts: $toasts,
            maxToasts: 5
        )

        #expect(container.maxToasts == 5)
    }

    @Test("View Extension toastContainer")
    func viewExtensionToastContainer() {
        @State var toasts: [ToastItem] = []

        let view = Text("Test")
            .toastContainer(toasts: $toasts, maxToasts: 3)

        // Viewが正常に作成されることを確認
        #expect(view != nil)
    }

    // MARK: - 統合テスト (3件)

    @Test("実用例：保存成功トースト")
    func realWorldSaveSuccessToast() {
        let item = ToastItem.success(
            title: "保存しました",
            message: "写真が正常に保存されました"
        )

        #expect(item.type == .success)
        #expect(item.title == "保存しました")
        #expect(item.message == "写真が正常に保存されました")
        #expect(item.duration == 3.0)
    }

    @Test("実用例：削除エラートースト")
    func realWorldDeleteErrorToast() {
        let item = ToastItem.error(
            title: "削除に失敗しました",
            message: "写真の削除中にエラーが発生しました。もう一度お試しください。",
            duration: 5.0
        )

        #expect(item.type == .error)
        #expect(item.title == "削除に失敗しました")
        #expect(item.duration == 5.0)
    }

    @Test("実用例：警告メッセージトースト")
    func realWorldWarningToast() {
        let item = ToastItem.warning(
            title: "ストレージ容量が不足しています",
            message: "写真を削除して空き容量を確保してください"
        )

        #expect(item.type == .warning)
        #expect(item.title == "ストレージ容量が不足しています")
        #expect(item.duration == 3.5)
    }

    // MARK: - ToastItem.displayIcon テスト (2件)

    @Test("displayIcon - デフォルトアイコン")
    func displayIconDefault() {
        let item = ToastItem(
            type: .success,
            title: "テスト"
        )

        #expect(item.displayIcon == "checkmark.circle.fill")
    }

    @Test("displayIcon - カスタムアイコン優先")
    func displayIconCustom() {
        let item = ToastItem(
            type: .success,
            title: "テスト",
            customIcon: "star.fill"
        )

        #expect(item.displayIcon == "star.fill")
    }

    // MARK: - ToastItem.id 一意性テスト (1件)

    @Test("ToastItem の一意なID")
    func uniqueToastItemIds() {
        let item1 = ToastItem(type: .success, title: "Test 1")
        let item2 = ToastItem(type: .success, title: "Test 2")
        let item3 = ToastItem(type: .success, title: "Test 1")

        #expect(item1.id != item2.id)
        #expect(item1.id != item3.id)
        #expect(item2.id != item3.id)
    }
}
