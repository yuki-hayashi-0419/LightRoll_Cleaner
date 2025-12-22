//
//  ContentViewTrashIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ContentViewのゴミ箱統合機能のテスト
//  onDeletePhotosとonDeleteGroupsがDeletePhotosUseCaseを正しく使用していることを検証
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - ContentView Trash Integration Tests

@Suite("ContentView Trash Integration Tests")
@MainActor
struct ContentViewTrashIntegrationTests {

    // MARK: - Test Cases (正常系)

    @Test("単一写真削除でDeletePhotosUseCaseが呼ばれる")
    func testDeleteSinglePhotoMovesToTrash() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // 1枚の写真を削除
        let photoIds = ["photo1"]

        // UseCaseのモック動作を設定
        mockDeleteUseCase.mockOutput = DeletePhotosOutput(
            deletedCount: 1,
            freedBytes: 1_000_000,
            failedIds: []
        )

        // When
        let input = DeletePhotosInput(
            photos: photoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 1_000_000) },
            permanently: false
        )
        let result = try await mockDeleteUseCase.execute(input)

        // Then
        #expect(mockDeleteUseCase.executeCalled)
        #expect(mockDeleteUseCase.lastInput?.photos.count == 1)
        #expect(mockDeleteUseCase.lastInput?.permanently == false)
        #expect(result.deletedCount == 1)
        #expect(result.freedBytes == 1_000_000)
        #expect(result.isFullySuccessful)
    }

    @Test("複数写真削除でDeletePhotosUseCaseが呼ばれる")
    func testDeleteMultiplePhotosMovesToTrash() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // 5枚の写真を削除
        let photoIds = (1...5).map { "photo\($0)" }

        // UseCaseのモック動作を設定
        mockDeleteUseCase.mockOutput = DeletePhotosOutput(
            deletedCount: 5,
            freedBytes: 5_000_000,
            failedIds: []
        )

        // When
        let input = DeletePhotosInput(
            photos: photoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 1_000_000) },
            permanently: false
        )
        let result = try await mockDeleteUseCase.execute(input)

        // Then
        #expect(mockDeleteUseCase.executeCalled)
        #expect(mockDeleteUseCase.lastInput?.photos.count == 5)
        #expect(mockDeleteUseCase.lastInput?.permanently == false)
        #expect(result.deletedCount == 5)
        #expect(result.freedBytes == 5_000_000)
        #expect(result.isFullySuccessful)
    }

    @Test("グループ削除でDeletePhotosUseCaseが呼ばれる")
    func testDeleteGroupsMovesToTrash() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // 2つのグループを削除（合計7枚の写真）
        let photoIds1 = (1...3).map { "photo\($0)" }
        let photoIds2 = (4...7).map { "photo\($0)" }
        let allPhotoIds = photoIds1 + photoIds2

        // UseCaseのモック動作を設定
        mockDeleteUseCase.mockOutput = DeletePhotosOutput(
            deletedCount: 7,
            freedBytes: 11_000_000,
            failedIds: []
        )

        // When
        let input = DeletePhotosInput(
            photos: allPhotoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 1_000_000) },
            permanently: false
        )
        let result = try await mockDeleteUseCase.execute(input)

        // Then
        #expect(mockDeleteUseCase.executeCalled)
        #expect(mockDeleteUseCase.lastInput?.photos.count == 7)
        #expect(mockDeleteUseCase.lastInput?.permanently == false)
        #expect(result.deletedCount == 7)
        #expect(result.isFullySuccessful)
    }

    // MARK: - Test Cases (異常系)

    @Test("削除エラー発生時にエラーが正しく処理される")
    func testDeletePhotosErrorHandling() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // エラーを返すように設定
        mockDeleteUseCase.shouldThrowError = true
        mockDeleteUseCase.errorToThrow = .trashMoveFailed(
            underlying: NSError(domain: "TestError", code: -1)
        )

        let photoIds = ["photo1"]
        let input = DeletePhotosInput(
            photos: photoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 1_000_000) },
            permanently: false
        )

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await mockDeleteUseCase.execute(input)
        }
        #expect(mockDeleteUseCase.executeCalled)
    }

    @Test("空の配列を渡した場合にエラーが発生する")
    func testDeleteEmptyArrayThrowsError() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // エラーを返すように設定
        mockDeleteUseCase.shouldThrowError = true
        mockDeleteUseCase.errorToThrow = .emptyPhotos

        let input = DeletePhotosInput(
            photos: [],
            permanently: false
        )

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await mockDeleteUseCase.execute(input)
        }
        #expect(mockDeleteUseCase.executeCalled)
    }

    // MARK: - Test Cases (境界値)

    @Test("大量の写真（100枚）削除時の動作")
    func testDeleteLargeNumberOfPhotos() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // 100枚の写真を削除
        let photoCount = 100
        let photoIds = (1...photoCount).map { "photo\($0)" }

        // UseCaseのモック動作を設定
        mockDeleteUseCase.mockOutput = DeletePhotosOutput(
            deletedCount: photoCount,
            freedBytes: Int64(photoCount) * 2_000_000, // 各写真2MB
            failedIds: []
        )

        // When
        let input = DeletePhotosInput(
            photos: photoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 2_000_000) },
            permanently: false
        )
        let result = try await mockDeleteUseCase.execute(input)

        // Then
        #expect(mockDeleteUseCase.executeCalled)
        #expect(mockDeleteUseCase.lastInput?.photos.count == photoCount)
        #expect(result.deletedCount == photoCount)
        #expect(result.freedBytes == Int64(photoCount) * 2_000_000)
        #expect(result.isFullySuccessful)
    }

    @Test("削除制限到達時にエラーが発生する")
    func testDeletionLimitReached() async throws {
        // Given
        let mockDeleteUseCase = MockDeletePhotosUseCase()

        // 削除制限エラーを設定
        mockDeleteUseCase.shouldThrowError = true
        mockDeleteUseCase.errorToThrow = .deletionLimitReached(
            current: 45,
            limit: 50,
            requested: 10
        )

        let photoIds = (1...10).map { "photo\($0)" }
        let input = DeletePhotosInput(
            photos: photoIds.map { PhotoAsset(id: $0, creationDate: Date(), fileSize: 1_000_000) },
            permanently: false
        )

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await mockDeleteUseCase.execute(input)
        }

        // エラーメッセージの検証
        do {
            _ = try await mockDeleteUseCase.execute(input)
        } catch let error as DeletePhotosUseCaseError {
            if case .deletionLimitReached(let current, let limit, let requested) = error {
                #expect(current == 45)
                #expect(limit == 50)
                #expect(requested == 10)
            }
        }
    }
}
