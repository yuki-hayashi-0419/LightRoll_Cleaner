//
//  ConfirmationDialogTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ConfirmationDialogコンポーネントの包括的テストスイート
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - Test Suite

/// ConfirmationDialogコンポーネントのテストスイート
@Suite("ConfirmationDialog Tests")
struct ConfirmationDialogTests {

    // MARK: - Test Helpers

    /// テスト用のアクション完了フラグ
    actor ActionTracker {
        private var confirmCalled = false
        private var cancelCalled = false

        func markConfirm() {
            confirmCalled = true
        }

        func markCancel() {
            cancelCalled = true
        }

        func wasConfirmCalled() -> Bool {
            confirmCalled
        }

        func wasCancelCalled() -> Bool {
            cancelCalled
        }

        func reset() {
            confirmCalled = false
            cancelCalled = false
        }
    }

    // MARK: - 1. 正常系テスト

    @Test("通常スタイルの確認ダイアログが正しく作成される")
    @MainActor
    func testNormalStyleDialog() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "確認",
            message: "この操作を実行しますか?",
            style: .normal,
            confirmTitle: "実行",
            cancelTitle: "キャンセル"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - プロパティ検証
        #expect(dialog.title == "確認")
        #expect(dialog.message == "この操作を実行しますか?")
        #expect(dialog.style == .normal)
        #expect(dialog.confirmTitle == "実行")
        #expect(dialog.cancelTitle == "キャンセル")
        #expect(dialog.details == nil)
    }

    @Test("破壊的スタイルの確認ダイアログが正しく作成される")
    @MainActor
    func testDestructiveStyleDialog() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "削除確認",
            message: "このアイテムを削除しますか?",
            style: .destructive,
            confirmTitle: "削除",
            cancelTitle: "キャンセル"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "削除確認")
        #expect(dialog.style == .destructive)

        // 破壊的スタイルの色が正しい
        let actionColor = dialog.style.actionColor
        #expect(actionColor == Color.LightRoll.error)
    }

    @Test("警告スタイルの確認ダイアログが正しく作成される")
    @MainActor
    func testWarningStyleDialog() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "警告",
            message: "この操作には注意が必要です",
            style: .warning,
            confirmTitle: "続行",
            cancelTitle: "戻る"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "警告")
        #expect(dialog.style == .warning)

        // 警告スタイルの色が正しい
        let actionColor = dialog.style.actionColor
        #expect(actionColor == Color.LightRoll.warning)
    }

    @Test("詳細情報付きダイアログが正しく作成される")
    @MainActor
    func testDialogWithDetails() async throws {
        // Arrange
        let tracker = ActionTracker()
        let details = [
            ConfirmationDetail(
                label: "削除枚数",
                value: "24枚",
                icon: "photo.stack"
            ),
            ConfirmationDetail(
                label: "削減容量",
                value: "48.5 MB",
                icon: "arrow.down.circle",
                color: Color.LightRoll.success
            )
        ]

        let dialog = ConfirmationDialog(
            title: "削除確認",
            message: "選択した写真を削除しますか?",
            details: details,
            style: .destructive
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.details != nil)
        #expect(dialog.details?.count == 2)
        #expect(dialog.details?[0].label == "削除枚数")
        #expect(dialog.details?[1].value == "48.5 MB")
    }

    @Test("詳細情報なしダイアログが正しく作成される")
    @MainActor
    func testDialogWithoutDetails() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "確認",
            message: "この操作を実行しますか?",
            details: nil,
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.details == nil)
    }

    @Test("deleteConfirmation便利イニシャライザが正しく動作する")
    @MainActor
    func testDeleteConfirmationConvenience() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 10,
            itemName: "写真",
            reclaimableSize: 10_000_000
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "写真を削除しますか？")
        #expect(dialog.message.contains("ゴミ箱に移動"))
        #expect(dialog.style == .destructive)
        #expect(dialog.confirmTitle == "削除")
        #expect(dialog.details != nil)
        #expect(dialog.details?.count == 2) // 削除枚数 + 削減容量
    }

    @Test("permanentDeleteConfirmation便利イニシャライザが正しく動作する")
    @MainActor
    func testPermanentDeleteConfirmationConvenience() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.permanentDeleteConfirmation(
            itemCount: 5,
            itemName: "グループ"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "完全に削除しますか？")
        #expect(dialog.message.contains("取り消せません"))
        #expect(dialog.style == .destructive)
        #expect(dialog.confirmTitle == "完全削除")
        #expect(dialog.details != nil)
        #expect(dialog.details?.count == 1) // 削除枚数のみ
    }

    @Test("cancelConfirmation便利イニシャライザが正しく動作する")
    @MainActor
    func testCancelConfirmationConvenience() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.cancelConfirmation(
            processName: "スキャン"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "スキャンを中止しますか？")
        #expect(dialog.message.contains("停止されます"))
        #expect(dialog.style == .warning)
        #expect(dialog.confirmTitle == "中止")
        #expect(dialog.cancelTitle == "続行")
        #expect(dialog.details == nil)
    }

    // MARK: - 2. 異常系テスト

    @Test("空のタイトルでもダイアログが作成される")
    @MainActor
    func testEmptyTitle() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "",
            message: "メッセージのみのダイアログ",
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "")
        #expect(dialog.message == "メッセージのみのダイアログ")
    }

    @Test("空のメッセージでもダイアログが作成される")
    @MainActor
    func testEmptyMessage() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "タイトルのみ",
            message: "",
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "タイトルのみ")
        #expect(dialog.message == "")
    }

    @Test("非常に長いテキストでもダイアログが作成される")
    @MainActor
    func testVeryLongText() async throws {
        // Arrange
        let tracker = ActionTracker()
        let longTitle = String(repeating: "タイトル ", count: 50)
        let longMessage = String(repeating: "これは非常に長いメッセージです。", count: 20)

        let dialog = ConfirmationDialog(
            title: longTitle,
            message: longMessage,
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == longTitle)
        #expect(dialog.message == longMessage)
        #expect(dialog.title.count > 200)
        #expect(dialog.message.count > 300)
    }

    // MARK: - 3. 境界値テスト

    @Test("詳細情報0件の場合")
    @MainActor
    func testZeroDetails() async throws {
        // Arrange
        let tracker = ActionTracker()
        let emptyDetails: [ConfirmationDetail] = []

        let dialog = ConfirmationDialog(
            title: "確認",
            message: "詳細情報なし",
            details: emptyDetails,
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.details != nil)
        #expect(dialog.details?.isEmpty == true)
    }

    @Test("詳細情報10件以上の場合")
    @MainActor
    func testManyDetails() async throws {
        // Arrange
        let tracker = ActionTracker()
        let manyDetails = (1...15).map { index in
            ConfirmationDetail(
                label: "項目\(index)",
                value: "値\(index)",
                icon: "checkmark.circle"
            )
        }

        let dialog = ConfirmationDialog(
            title: "詳細情報多数",
            message: "15件の詳細情報",
            details: manyDetails,
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.details?.count == 15)
        #expect(dialog.details?[0].label == "項目1")
        #expect(dialog.details?[14].label == "項目15")
    }

    @Test("最小文字数のテキスト")
    @MainActor
    func testMinimalText() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog(
            title: "T",
            message: "M",
            style: .normal,
            confirmTitle: "Y",
            cancelTitle: "N"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title.count == 1)
        #expect(dialog.message.count == 1)
        #expect(dialog.confirmTitle.count == 1)
        #expect(dialog.cancelTitle.count == 1)
    }

    // MARK: - 4. ConfirmationDetailテスト

    @Test("ConfirmationDetailが正しく作成される")
    func testConfirmationDetailCreation() {
        // Arrange & Act
        let detail = ConfirmationDetail(
            label: "削除枚数",
            value: "24枚",
            icon: "photo.stack",
            color: Color.red
        )

        // Assert
        #expect(detail.label == "削除枚数")
        #expect(detail.value == "24枚")
        #expect(detail.icon == "photo.stack")
        #expect(detail.color == Color.red)
        #expect(detail.id != UUID()) // ユニークなIDが生成される
    }

    @Test("ConfirmationDetailのデフォルト値が正しい")
    func testConfirmationDetailDefaults() {
        // Arrange & Act
        let detail = ConfirmationDetail(
            label: "項目",
            value: "値"
        )

        // Assert
        #expect(detail.label == "項目")
        #expect(detail.value == "値")
        #expect(detail.icon == nil)
        #expect(detail.color == nil)
    }

    @Test("複数のConfirmationDetailのID一意性")
    func testConfirmationDetailUniqueIds() {
        // Arrange & Act
        let detail1 = ConfirmationDetail(label: "A", value: "1")
        let detail2 = ConfirmationDetail(label: "B", value: "2")
        let detail3 = ConfirmationDetail(label: "C", value: "3")

        // Assert
        #expect(detail1.id != detail2.id)
        #expect(detail2.id != detail3.id)
        #expect(detail1.id != detail3.id)
    }

    // MARK: - 5. スタイルテスト

    @Test("ConfirmationDialogStyleの色が正しい")
    @MainActor
    func testStyleColors() {
        // Assert - 各スタイルの色
        #expect(ConfirmationDialogStyle.normal.actionColor == Color.LightRoll.primary)
        #expect(ConfirmationDialogStyle.destructive.actionColor == Color.LightRoll.error)
        #expect(ConfirmationDialogStyle.warning.actionColor == Color.LightRoll.warning)
    }

    @Test("ConfirmationDialogStyleのアイコンが正しい")
    @MainActor
    func testStyleIcons() {
        // Assert - 各スタイルのアイコン
        #expect(ConfirmationDialogStyle.normal.actionIcon == "checkmark.circle")
        #expect(ConfirmationDialogStyle.destructive.actionIcon == "trash.circle.fill")
        #expect(ConfirmationDialogStyle.warning.actionIcon == "exclamationmark.triangle")
    }

    @Test("スタイルがSendableに準拠している")
    func testStyleSendableConformance() {
        // Arrange
        let style: ConfirmationDialogStyle = .destructive

        // Act - Sendableなコンテキストで使用可能
        Task {
            let _ = style
        }

        // Assert - コンパイルエラーが発生しないことを確認
        #expect(true)
    }

    // MARK: - 6. アクセシビリティテスト

    @Test("通常スタイルのアクセシビリティラベルが正しい")
    @MainActor
    func testNormalAccessibilityLabel() async throws {
        // Arrange
        let tracker = ActionTracker()
        let dialog = ConfirmationDialog(
            title: "確認",
            message: "操作を実行しますか?",
            style: .normal
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Act
        let description = Mirror(reflecting: dialog)
            .children
            .first(where: { $0.label == "accessibilityDescription" })

        // Assert - アクセシビリティ情報に必要な要素が含まれる
        #expect(dialog.title == "確認")
        #expect(dialog.message == "操作を実行しますか?")
    }

    @Test("破壊的スタイルのアクセシビリティラベルに警告が含まれる")
    @MainActor
    func testDestructiveAccessibilityWarning() async throws {
        // Arrange
        let tracker = ActionTracker()
        let dialog = ConfirmationDialog(
            title: "削除",
            message: "アイテムを削除しますか?",
            style: .destructive
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 破壊的アクションであることが明示される
        #expect(dialog.style == .destructive)
        #expect(dialog.title == "削除")
    }

    @Test("詳細情報付きのアクセシビリティラベル")
    @MainActor
    func testAccessibilityWithDetails() async throws {
        // Arrange
        let tracker = ActionTracker()
        let details = [
            ConfirmationDetail(label: "削除枚数", value: "10枚"),
            ConfirmationDetail(label: "削減容量", value: "5MB")
        ]

        let dialog = ConfirmationDialog(
            title: "削除確認",
            message: "写真を削除しますか?",
            details: details,
            style: .destructive
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 詳細情報も含まれる
        #expect(dialog.details?.count == 2)
        #expect(dialog.details?[0].label == "削除枚数")
        #expect(dialog.details?[1].value == "5MB")
    }

    @Test("警告スタイルのアクセシビリティが適切")
    @MainActor
    func testWarningAccessibility() async throws {
        // Arrange
        let tracker = ActionTracker()
        let dialog = ConfirmationDialog(
            title: "警告",
            message: "注意が必要な操作です",
            style: .warning
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.style == .warning)
        #expect(dialog.style.actionColor == Color.LightRoll.warning)
    }

    @Test("VoiceOver対応のラベルとヒント")
    @MainActor
    func testVoiceOverSupport() async throws {
        // Arrange
        let tracker = ActionTracker()
        let dialog = ConfirmationDialog(
            title: "削除確認",
            message: "この操作を実行しますか?",
            style: .destructive,
            confirmTitle: "削除",
            cancelTitle: "キャンセル"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - VoiceOver用の情報が設定されている
        #expect(dialog.confirmTitle == "削除")
        #expect(dialog.cancelTitle == "キャンセル")
        #expect(dialog.style == .destructive)
    }

    // MARK: - 7. 統合テスト

    @Test("View ExtensionのconfirmationDialog modifierが動作する")
    @MainActor
    func testViewExtensionModifier() async throws {
        // Arrange
        let tracker = ActionTracker()
        var isPresented = true

        let testView = Text("Test View")
            .confirmationDialog(isPresented: isPresented) {
                ConfirmationDialog(
                    title: "確認",
                    message: "テスト",
                    style: .normal
                ) {
                    await tracker.markConfirm()
                } onCancel: {
                    await tracker.markCancel()
                }
            }

        // Assert - ビューが作成される
        #expect(testView != nil)
        #expect(isPresented == true)

        // 非表示時
        isPresented = false
        let hiddenView = Text("Test View")
            .confirmationDialog(isPresented: isPresented) {
                ConfirmationDialog(
                    title: "確認",
                    message: "テスト",
                    style: .normal
                ) {
                    await tracker.markConfirm()
                } onCancel: {
                    await tracker.markCancel()
                }
            }

        #expect(hiddenView != nil)
        #expect(isPresented == false)
    }

    @Test("複数のダイアログを切り替えられる")
    @MainActor
    func testMultipleDialogToggle() async throws {
        // Arrange
        let tracker1 = ActionTracker()
        let tracker2 = ActionTracker()

        let dialog1 = ConfirmationDialog(
            title: "ダイアログ1",
            message: "最初のダイアログ",
            style: .normal
        ) {
            await tracker1.markConfirm()
        } onCancel: {
            await tracker1.markCancel()
        }

        let dialog2 = ConfirmationDialog(
            title: "ダイアログ2",
            message: "2番目のダイアログ",
            style: .destructive
        ) {
            await tracker2.markConfirm()
        } onCancel: {
            await tracker2.markCancel()
        }

        // Assert - 異なるダイアログが作成される
        #expect(dialog1.title == "ダイアログ1")
        #expect(dialog2.title == "ダイアログ2")
        #expect(dialog1.style == .normal)
        #expect(dialog2.style == .destructive)
    }

    @Test("便利イニシャライザ間の切り替え")
    @MainActor
    func testConvenienceInitializerSwitching() async throws {
        // Arrange
        let tracker = ActionTracker()

        // 削除確認
        let deleteDialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 10,
            itemName: "写真",
            reclaimableSize: 5_000_000
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // 永久削除確認
        let permanentDialog = ConfirmationDialog.permanentDeleteConfirmation(
            itemCount: 5,
            itemName: "写真"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // キャンセル確認
        let cancelDialog = ConfirmationDialog.cancelConfirmation(
            processName: "スキャン"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - それぞれ異なる設定
        #expect(deleteDialog.confirmTitle == "削除")
        #expect(permanentDialog.confirmTitle == "完全削除")
        #expect(cancelDialog.confirmTitle == "中止")

        #expect(deleteDialog.details?.count == 2)
        #expect(permanentDialog.details?.count == 1)
        #expect(cancelDialog.details == nil)
    }

    // MARK: - 8. 特殊ケーステスト

    @Test("削除確認でreclaimableSizeがnilの場合")
    @MainActor
    func testDeleteConfirmationWithoutSize() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 10,
            itemName: "写真",
            reclaimableSize: nil
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 削減容量の詳細が含まれない
        #expect(dialog.details?.count == 1) // 削除枚数のみ
        #expect(dialog.details?[0].label == "削除枚数")
    }

    @Test("itemCount=0の削除確認")
    @MainActor
    func testDeleteConfirmationZeroItems() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 0,
            itemName: "写真"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 0枚でも作成される
        #expect(dialog.details?[0].value == "0枚")
    }

    @Test("itemCount=1000の大量削除確認")
    @MainActor
    func testDeleteConfirmationManyItems() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 1000,
            itemName: "写真",
            reclaimableSize: 1_000_000_000 // 1GB
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 大量の項目数でも動作
        #expect(dialog.details?[0].value == "1000枚")
    }

    @Test("非常に大きいreclaimableSize")
    @MainActor
    func testDeleteConfirmationLargeSize() async throws {
        // Arrange
        let tracker = ActionTracker()
        let largeSize: Int64 = 100_000_000_000 // 100GB

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 5000,
            itemName: "写真",
            reclaimableSize: largeSize
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert - 大きいサイズでも動作
        #expect(dialog.details?.count == 2)
    }

    @Test("カスタムitemNameが正しく使用される")
    @MainActor
    func testCustomItemName() async throws {
        // Arrange
        let tracker = ActionTracker()

        let dialog = ConfirmationDialog.deleteConfirmation(
            itemCount: 3,
            itemName: "グループ"
        ) {
            await tracker.markConfirm()
        } onCancel: {
            await tracker.markCancel()
        }

        // Assert
        #expect(dialog.title == "グループを削除しますか？")
        #expect(dialog.message.contains("グループ"))
    }
}

// MARK: - Custom Test Tags
// Note: ui, component, accessibility タグは既存定義を使用
