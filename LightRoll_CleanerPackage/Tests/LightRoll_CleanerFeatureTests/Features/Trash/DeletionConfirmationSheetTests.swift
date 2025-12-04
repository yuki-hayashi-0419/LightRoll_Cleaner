//
//  DeletionConfirmationSheetTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DeletionConfirmationSheetのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - DeletionConfirmationSheetTests

@MainActor
@Suite("DeletionConfirmationSheet Tests", .tags(.deletionSheet))
struct DeletionConfirmationSheetTests {

    // MARK: - Initialization Tests

    @Test("初期化 - メッセージあり")
    func testInitializationWithMessage() async throws {
        // Given
        let message = ConfirmationMessage(
            title: "テストタイトル",
            message: "テストメッセージ",
            details: [],
            style: .normal,
            confirmTitle: "確認",
            cancelTitle: "キャンセル"
        )

        // When
        let sut = DeletionConfirmationSheet(
            message: message,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title == "テストタイトル")
        #expect(sut.message?.message == "テストメッセージ")
    }

    @Test("初期化 - メッセージなし")
    func testInitializationWithoutMessage() async throws {
        // When
        let sut = DeletionConfirmationSheet(
            message: nil,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message == nil)
    }

    // MARK: - Convenience Initializers Tests

    @Test("削除確認シート生成 - from()メソッド")
    func testDeleteConfirmationFromService() async throws {
        // Given
        let service = DeletionConfirmationService()

        // When
        let sut = DeletionConfirmationSheet.from(
            service: service,
            photoCount: 10,
            totalSize: 5_000_000,
            actionType: .delete,
            itemName: "写真",
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("削除") == true)
        #expect(sut.message?.style == .destructive)
    }

    @Test("削除確認シート生成 - 簡易版")
    func testDeleteConfirmationConvenience() async throws {
        // When
        let sut = DeletionConfirmationSheet.deleteConfirmation(
            photoCount: 24,
            totalSize: 48_500_000,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("削除") == true)
        #expect(sut.message?.style == .destructive)
        #expect(sut.message?.details.count == 2) // 削除枚数 + 削減容量
    }

    @Test("復元確認シート生成 - 簡易版")
    func testRestoreConfirmationConvenience() async throws {
        // When
        let sut = DeletionConfirmationSheet.restoreConfirmation(
            photoCount: 15,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("復元") == true)
        #expect(sut.message?.style == .normal)
        #expect(sut.message?.details.count == 1) // 復元枚数のみ
    }

    @Test("永久削除確認シート生成 - 簡易版")
    func testPermanentDeleteConfirmationConvenience() async throws {
        // When
        let sut = DeletionConfirmationSheet.permanentDeleteConfirmation(
            photoCount: 8,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("完全") == true || sut.message?.title.contains("削除") == true)
        #expect(sut.message?.style == .destructive)
        #expect(sut.message?.details.count == 1) // 削除枚数のみ
    }

    @Test("ゴミ箱を空にする確認シート生成 - 簡易版")
    func testEmptyTrashConfirmationConvenience() async throws {
        // When
        let sut = DeletionConfirmationSheet.emptyTrashConfirmation(
            photoCount: 127,
            totalSize: 256_000_000,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("ゴミ箱") == true)
        #expect(sut.message?.style == .destructive)
        #expect(sut.message?.details.count == 2) // 削除枚数 + 削減容量
    }

    // MARK: - Message Content Tests

    @Test("削除確認メッセージ内容 - 詳細情報の検証")
    func testDeleteConfirmationMessageDetails() async throws {
        // Given
        let photoCount = 50
        let totalSize: Int64 = 100_000_000

        // When
        let sut = DeletionConfirmationSheet.deleteConfirmation(
            photoCount: photoCount,
            totalSize: totalSize,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        guard let message = sut.message else {
            Issue.record("メッセージがnil")
            return
        }

        #expect(message.details.count == 2)

        // 削除枚数の詳細
        let countDetail = message.details.first { $0.label.contains("削除枚数") }
        #expect(countDetail != nil)
        #expect(countDetail?.value.contains("\(photoCount)") == true)

        // 削減容量の詳細
        let sizeDetail = message.details.first { $0.label.contains("削減容量") }
        #expect(sizeDetail != nil)
    }

    @Test("復元確認メッセージ内容 - 詳細情報の検証")
    func testRestoreConfirmationMessageDetails() async throws {
        // Given
        let photoCount = 30

        // When
        let sut = DeletionConfirmationSheet.restoreConfirmation(
            photoCount: photoCount,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        guard let message = sut.message else {
            Issue.record("メッセージがnil")
            return
        }

        #expect(message.details.count == 1)

        // 復元枚数の詳細
        let countDetail = message.details.first
        #expect(countDetail != nil)
        #expect(countDetail?.label.contains("復元枚数") == true)
        #expect(countDetail?.value.contains("\(photoCount)") == true)
    }

    // MARK: - Edge Cases Tests

    @Test("エッジケース - 0枚の削除確認")
    func testDeleteConfirmationWithZeroPhotos() async throws {
        // Given
        let photoCount = 0

        // When
        let sut = DeletionConfirmationSheet.deleteConfirmation(
            photoCount: photoCount,
            totalSize: 0,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.details.count == 2) // 削除枚数 + 削減容量
    }

    @Test("エッジケース - 大量枚数の削除確認")
    func testDeleteConfirmationWithLargePhotoCount() async throws {
        // Given
        let photoCount = 10_000
        let totalSize: Int64 = 10_000_000_000 // 10GB

        // When
        let sut = DeletionConfirmationSheet.deleteConfirmation(
            photoCount: photoCount,
            totalSize: totalSize,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.contains("削除") == true)
        #expect(sut.message?.details.count == 2)
    }

    @Test("エッジケース - サイズなしの削除確認")
    func testDeleteConfirmationWithoutSize() async throws {
        // Given
        let photoCount = 10

        // When
        let sut = DeletionConfirmationSheet.deleteConfirmation(
            photoCount: photoCount,
            totalSize: nil,
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.details.count == 1) // 削除枚数のみ
    }

    // MARK: - Integration Tests

    @Test("統合テスト - DeletionConfirmationServiceとの連携")
    func testIntegrationWithDeletionConfirmationService() async throws {
        // Given
        let service = DeletionConfirmationService()
        let photoCount = 25
        let totalSize: Int64 = 50_000_000

        // When
        let sut = DeletionConfirmationSheet.from(
            service: service,
            photoCount: photoCount,
            totalSize: totalSize,
            actionType: .delete,
            itemName: "写真",
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title.isEmpty == false)
        #expect(sut.message?.message.isEmpty == false)
        #expect(sut.message?.style == .destructive)
    }

    @Test("統合テスト - 複数のアクションタイプ")
    func testIntegrationWithMultipleActionTypes() async throws {
        // Given
        let service = DeletionConfirmationService()
        let photoCount = 20
        let actionTypes: [ConfirmationActionType] = [.delete, .restore, .permanentDelete, .emptyTrash]

        // When & Then
        for actionType in actionTypes {
            let sut = DeletionConfirmationSheet.from(
                service: service,
                photoCount: photoCount,
                totalSize: nil,
                actionType: actionType,
                itemName: "写真",
                onConfirm: {},
                onCancel: {}
            )

            #expect(sut.message != nil)
            #expect(sut.message?.title.isEmpty == false)
            #expect(sut.message?.message.isEmpty == false)
        }
    }

    // MARK: - Mock Service Tests

    @Test("モックサービス - カスタムメッセージ")
    func testWithMockService() async throws {
        // Given
        let mockService = MockDeletionConfirmationService()
        mockService.mockMessage = ConfirmationMessage(
            title: "カスタムタイトル",
            message: "カスタムメッセージ",
            details: [
                ConfirmationDetail(
                    label: "カスタムラベル",
                    value: "カスタム値",
                    icon: "star.fill",
                    color: Color.yellow
                )
            ],
            style: .warning,
            confirmTitle: "カスタム確認",
            cancelTitle: "カスタムキャンセル"
        )

        // When
        let sut = DeletionConfirmationSheet.from(
            service: mockService,
            photoCount: 10,
            totalSize: nil,
            actionType: .delete,
            itemName: "写真",
            onConfirm: {},
            onCancel: {}
        )

        // Then
        #expect(sut.message != nil)
        #expect(sut.message?.title == "カスタムタイトル")
        #expect(sut.message?.message == "カスタムメッセージ")
        #expect(sut.message?.style == .warning)
        #expect(sut.message?.details.count == 1)
        #expect(mockService.formatConfirmationMessageCalled)
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var deletionSheet: Self
}
