//
//  DeletionConfirmationServiceTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DeletionConfirmationServiceのテスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - DeletionConfirmationServiceTests

@Suite("DeletionConfirmationService Tests")
struct DeletionConfirmationServiceTests {

    // MARK: - shouldShowConfirmation Tests

    @Test("削除アクションは常に確認が必要")
    func shouldShowConfirmation_Delete_AlwaysTrue() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result1 = service.shouldShowConfirmation(photoCount: 1, actionType: .delete)
        let result2 = service.shouldShowConfirmation(photoCount: 10, actionType: .delete)
        let result3 = service.shouldShowConfirmation(photoCount: 100, actionType: .delete)

        // Then
        #expect(result1 == true, "1枚でも確認が必要")
        #expect(result2 == true, "10枚でも確認が必要")
        #expect(result3 == true, "100枚でも確認が必要")
    }

    @Test("0枚の場合は確認不要")
    func shouldShowConfirmation_ZeroPhotos_ReturnsFalse() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result = service.shouldShowConfirmation(photoCount: 0, actionType: .delete)

        // Then
        #expect(result == false, "0枚の場合は確認不要")
    }

    @Test("復元は10枚以上で確認が必要")
    func shouldShowConfirmation_Restore_ThresholdIs10() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result1 = service.shouldShowConfirmation(photoCount: 5, actionType: .restore)
        let result2 = service.shouldShowConfirmation(photoCount: 10, actionType: .restore)
        let result3 = service.shouldShowConfirmation(photoCount: 20, actionType: .restore)

        // Then
        #expect(result1 == false, "5枚は確認不要")
        #expect(result2 == true, "10枚は確認が必要")
        #expect(result3 == true, "20枚は確認が必要")
    }

    @Test("永久削除は常に確認が必要")
    func shouldShowConfirmation_PermanentDelete_AlwaysTrue() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result1 = service.shouldShowConfirmation(photoCount: 1, actionType: .permanentDelete)
        let result2 = service.shouldShowConfirmation(photoCount: 50, actionType: .permanentDelete)

        // Then
        #expect(result1 == true, "1枚でも確認が必要")
        #expect(result2 == true, "50枚でも確認が必要")
    }

    @Test("ゴミ箱を空にするは常に確認が必要")
    func shouldShowConfirmation_EmptyTrash_AlwaysTrue() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result = service.shouldShowConfirmation(photoCount: 5, actionType: .emptyTrash)

        // Then
        #expect(result == true, "ゴミ箱を空にするは常に確認が必要")
    }

    @Test("キャンセルアクションは常に確認が必要")
    func shouldShowConfirmation_Cancel_AlwaysTrue() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let result = service.shouldShowConfirmation(photoCount: 0, actionType: .cancel)

        // Then
        #expect(result == true, "キャンセルは常に確認が必要")
    }

    // MARK: - formatConfirmationMessage Tests

    @Test("削除メッセージが正しく生成される")
    func formatConfirmationMessage_Delete_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 10,
            totalSize: 5_000_000,
            actionType: .delete,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("削除"), "タイトルに「削除」が含まれる")
        #expect(message.message.contains("ゴミ箱"), "メッセージに「ゴミ箱」が含まれる")
        #expect(message.message.contains("30日"), "メッセージに「30日」が含まれる")
        #expect(message.style == .destructive, "スタイルはdestructive")
        #expect(message.confirmTitle == "削除", "確認ボタンは「削除」")
        #expect(message.cancelTitle == "キャンセル", "キャンセルボタンは「キャンセル」")
        #expect(message.details.count == 2, "詳細情報は2つ（枚数とサイズ）")
    }

    @Test("削除メッセージ（サイズなし）が正しく生成される")
    func formatConfirmationMessage_Delete_WithoutSize_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 5,
            totalSize: nil,
            actionType: .delete,
            itemName: "写真"
        )

        // Then
        #expect(message.details.count == 1, "詳細情報は1つ（枚数のみ）")
    }

    @Test("大量削除メッセージが正しく生成される")
    func formatConfirmationMessage_Delete_LargeCount_CreatesWarningMessage() {
        // Given
        let service = DeletionConfirmationService(largeCountThreshold: 50)

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 100,
            totalSize: 50_000_000,
            actionType: .delete,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("大量"), "タイトルに「大量」が含まれる")
        #expect(message.style == .destructive, "スタイルはdestructive")
    }

    @Test("復元メッセージが正しく生成される")
    func formatConfirmationMessage_Restore_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 15,
            totalSize: nil,
            actionType: .restore,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("復元"), "タイトルに「復元」が含まれる")
        #expect(message.message.contains("ゴミ箱"), "メッセージに「ゴミ箱」が含まれる")
        #expect(message.style == .normal, "スタイルはnormal")
        #expect(message.confirmTitle == "復元", "確認ボタンは「復元」")
        #expect(message.details.count == 1, "詳細情報は1つ（枚数）")
    }

    @Test("永久削除メッセージが正しく生成される")
    func formatConfirmationMessage_PermanentDelete_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 5,
            totalSize: nil,
            actionType: .permanentDelete,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("完全"), "タイトルに「完全」が含まれる")
        #expect(message.message.contains("取り消せません"), "メッセージに「取り消せません」が含まれる")
        #expect(message.style == .destructive, "スタイルはdestructive")
        #expect(message.confirmTitle == "完全削除", "確認ボタンは「完全削除」")
        #expect(message.details.count == 1, "詳細情報は1つ（枚数）")
    }

    @Test("ゴミ箱を空にするメッセージが正しく生成される")
    func formatConfirmationMessage_EmptyTrash_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 30,
            totalSize: 15_000_000,
            actionType: .emptyTrash,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("ゴミ箱"), "タイトルに「ゴミ箱」が含まれる")
        #expect(message.message.contains("完全に削除"), "メッセージに「完全に削除」が含まれる")
        #expect(message.message.contains("取り消せません"), "メッセージに「取り消せません」が含まれる")
        #expect(message.style == .destructive, "スタイルはdestructive")
        #expect(message.confirmTitle == "空にする", "確認ボタンは「空にする」")
        #expect(message.details.count == 2, "詳細情報は2つ（枚数とサイズ）")
    }

    @Test("キャンセルメッセージが正しく生成される")
    func formatConfirmationMessage_Cancel_CreatesCorrectMessage() {
        // Given
        let service = DeletionConfirmationService()

        // When
        let message = service.formatConfirmationMessage(
            photoCount: 0,
            totalSize: nil,
            actionType: .cancel,
            itemName: "写真"
        )

        // Then
        #expect(message.title.contains("中止"), "タイトルに「中止」が含まれる")
        #expect(message.message.contains("停止"), "メッセージに「停止」が含まれる")
        #expect(message.style == .warning, "スタイルはwarning")
        #expect(message.confirmTitle == "中止", "確認ボタンは「中止」")
        #expect(message.cancelTitle == "続行", "キャンセルボタンは「続行」")
        #expect(message.details.isEmpty, "詳細情報はなし")
    }

    @Test("カスタム閾値で確認判定が変わる")
    func shouldShowConfirmation_CustomThreshold_WorksCorrectly() {
        // Given
        let service = DeletionConfirmationService(
            minCountForConfirmation: 5,
            largeCountThreshold: 100
        )

        // When
        let result1 = service.shouldShowConfirmation(photoCount: 3, actionType: .delete)
        let result2 = service.shouldShowConfirmation(photoCount: 5, actionType: .delete)
        let result3 = service.shouldShowConfirmation(photoCount: 10, actionType: .delete)

        // Then
        #expect(result1 == false, "閾値未満は確認不要")
        #expect(result2 == true, "閾値以上は確認が必要")
        #expect(result3 == true, "閾値以上は確認が必要")
    }

    // MARK: - ConfirmationMessage Extension Tests

    @Test("ConfirmationMessageをConfirmationDialogに変換できる")
    @MainActor
    func confirmationMessage_ToDialog_CreatesDialog() async {
        // Given
        let message = ConfirmationMessage(
            title: "テストタイトル",
            message: "テストメッセージ",
            details: [
                ConfirmationDetail(
                    label: "枚数",
                    value: "10枚",
                    icon: "photo.stack"
                )
            ],
            style: .normal,
            confirmTitle: "確認",
            cancelTitle: "キャンセル"
        )

        var confirmCalled = false
        var cancelCalled = false

        // When
        let dialog = message.toDialog {
            confirmCalled = true
        } onCancel: {
            cancelCalled = true
        }

        // Then
        #expect(dialog.title == "テストタイトル", "タイトルが正しく変換される")
        // 変換が正常に完了することを確認
        #expect(!confirmCalled, "まだ確認アクションは実行されていない")
        #expect(!cancelCalled, "まだキャンセルアクションは実行されていない")
    }

    // MARK: - Integration Tests

    @Test("削除フロー統合テスト")
    func integrationTest_DeleteFlow() {
        // Given
        let service = DeletionConfirmationService()
        let photoCount = 25
        let totalSize: Int64 = 12_500_000

        // When: 確認が必要かチェック
        let shouldShow = service.shouldShowConfirmation(
            photoCount: photoCount,
            actionType: .delete
        )

        // Then: 確認が必要
        #expect(shouldShow == true, "削除は確認が必要")

        // When: 確認メッセージを生成
        let message = service.formatConfirmationMessage(
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: .delete,
            itemName: "写真"
        )

        // Then: メッセージが正しく生成される
        #expect(message.title.contains("削除"), "削除タイトル")
        #expect(message.details.count == 2, "枚数とサイズ")
        #expect(message.style == .destructive, "破壊的スタイル")
    }

    @Test("復元フロー統合テスト")
    func integrationTest_RestoreFlow() {
        // Given
        let service = DeletionConfirmationService()
        let smallCount = 5
        let largeCount = 15

        // When: 少数の復元
        let shouldShowSmall = service.shouldShowConfirmation(
            photoCount: smallCount,
            actionType: .restore
        )

        // Then: 確認不要
        #expect(shouldShowSmall == false, "少数の復元は確認不要")

        // When: 大量の復元
        let shouldShowLarge = service.shouldShowConfirmation(
            photoCount: largeCount,
            actionType: .restore
        )

        // Then: 確認が必要
        #expect(shouldShowLarge == true, "大量の復元は確認が必要")

        // When: 確認メッセージを生成
        let message = service.formatConfirmationMessage(
            photoCount: largeCount,
            totalSize: nil,
            actionType: .restore,
            itemName: "写真"
        )

        // Then: メッセージが正しく生成される
        #expect(message.title.contains("復元"), "復元タイトル")
        #expect(message.style == .normal, "通常スタイル")
    }

    @Test("ゴミ箱を空にするフロー統合テスト")
    func integrationTest_EmptyTrashFlow() {
        // Given
        let service = DeletionConfirmationService()
        let photoCount = 45
        let totalSize: Int64 = 22_500_000

        // When: 確認が必要かチェック
        let shouldShow = service.shouldShowConfirmation(
            photoCount: photoCount,
            actionType: .emptyTrash
        )

        // Then: 確認が必要
        #expect(shouldShow == true, "ゴミ箱を空にするは確認が必要")

        // When: 確認メッセージを生成
        let message = service.formatConfirmationMessage(
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: .emptyTrash,
            itemName: "写真"
        )

        // Then: メッセージが正しく生成される
        #expect(message.title.contains("ゴミ箱"), "ゴミ箱タイトル")
        #expect(message.message.contains("取り消せません"), "警告メッセージ")
        #expect(message.details.count == 2, "枚数とサイズ")
        #expect(message.style == .destructive, "破壊的スタイル")
    }
}

// MARK: - MockDeletionConfirmationServiceTests

@Suite("MockDeletionConfirmationService Tests")
struct MockDeletionConfirmationServiceTests {

    @Test("モックが呼び出しを記録する")
    func mock_RecordsMethodCalls() {
        // Given
        let mock = MockDeletionConfirmationService()
        mock.shouldShowConfirmationResult = true

        // When
        let shouldShow = mock.shouldShowConfirmation(
            photoCount: 10,
            actionType: .delete
        )

        // Then
        #expect(mock.shouldShowConfirmationCalled == true, "メソッドが呼ばれた")
        #expect(mock.lastPhotoCount == 10, "写真枚数が記録された")
        #expect(mock.lastActionType == .delete, "アクションタイプが記録された")
        #expect(shouldShow == true, "設定した結果が返る")
    }

    @Test("モックがカスタムメッセージを返す")
    func mock_ReturnsCustomMessage() {
        // Given
        let mock = MockDeletionConfirmationService()
        let customMessage = ConfirmationMessage(
            title: "カスタムタイトル",
            message: "カスタムメッセージ",
            details: [],
            style: .warning,
            confirmTitle: "OK",
            cancelTitle: "NG"
        )
        mock.mockMessage = customMessage

        // When
        let message = mock.formatConfirmationMessage(
            photoCount: 5,
            totalSize: nil,
            actionType: .delete,
            itemName: "写真"
        )

        // Then
        #expect(mock.formatConfirmationMessageCalled == true, "メソッドが呼ばれた")
        #expect(message.title == "カスタムタイトル", "カスタムメッセージが返る")
        #expect(message.style == .warning, "カスタムスタイル")
    }

    @Test("モックがリセットできる")
    func mock_CanReset() {
        // Given
        let mock = MockDeletionConfirmationService()
        _ = mock.shouldShowConfirmation(photoCount: 10, actionType: .delete)

        // When
        mock.reset()

        // Then
        #expect(mock.shouldShowConfirmationCalled == false, "フラグがリセットされた")
        #expect(mock.formatConfirmationMessageCalled == false, "フラグがリセットされた")
        #expect(mock.lastPhotoCount == nil, "記録がクリアされた")
        #expect(mock.lastActionType == nil, "記録がクリアされた")
    }
}
