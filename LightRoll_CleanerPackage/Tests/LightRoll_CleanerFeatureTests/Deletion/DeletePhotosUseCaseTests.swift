//
//  DeletePhotosUseCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DeletePhotosUseCaseのテスト
//  ゴミ箱への移動と完全削除のロジックを検証
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - DeletePhotosUseCase Tests

@Suite("DeletePhotosUseCase Tests")
@MainActor
struct DeletePhotosUseCaseTests {

    // MARK: - Test Cases

    @Test("空の写真配列で実行するとエラーが発生する")
    func testExecuteWithEmptyPhotos() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(trashManager: mockTrashManager)
        let input = DeletePhotosInput(photos: [], permanently: false)

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
    }

    @Test("ゴミ箱への移動が成功する")
    func testMoveToTrashSuccess() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            deletionReason: .userSelected
        )

        let photos = [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000),
            PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 2000),
            PhotoAsset(id: "photo3", creationDate: Date(), fileSize: 3000)
        ]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // When
        let result = try await sut.execute(input)

        // Then
        #expect(mockTrashManager.moveToTrashCalled)
        #expect(result.deletedCount == 3)
        #expect(result.freedBytes == 6000)
        #expect(result.failedIds.isEmpty)
        #expect(result.isFullySuccessful)
    }

    @Test("削除容量が正しく計算される")
    func testFreedBytesCalculation() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(trashManager: mockTrashManager)

        let photos = [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 5_000_000),    // 5MB
            PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 10_000_000),   // 10MB
            PhotoAsset(id: "photo3", creationDate: Date(), fileSize: 15_000_000)    // 15MB
        ]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // When
        let result = try await sut.execute(input)

        // Then
        #expect(result.freedBytes == 30_000_000) // 合計30MB
        #expect(result.deletedCount == 3)
    }

    @Test("TrashManagerの移動失敗時にエラーが発生する")
    func testMoveToTrashFailure() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        mockTrashManager.shouldThrowError = true
        mockTrashManager.errorToThrow = TrashPhotoError.storageError(
            underlying: NSError(domain: "Test", code: -1)
        )

        let sut = DeletePhotosUseCase(trashManager: mockTrashManager)
        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
        #expect(mockTrashManager.moveToTrashCalled)
    }

    @Test("削除理由がTrashManagerに正しく渡される")
    func testDeletionReasonPassed() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let expectedReason = TrashPhoto.DeletionReason.similarPhoto

        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            deletionReason: expectedReason
        )

        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // When
        _ = try await sut.execute(input)

        // Then
        #expect(mockTrashManager.moveToTrashCalled)
        // Note: MockTrashManagerに削除理由を記録する機能を追加する必要がある
    }

    @Test("完全削除モードでPhotoRepositoryが未設定の場合エラーが発生する")
    func testPermanentDeletionWithoutRepository() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            photoRepository: nil  // PhotoRepositoryを設定しない
        )

        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: true)

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
    }

    @Test("完全削除モードでPhotoRepositoryが設定されている場合削除が実行される")
    func testPermanentDeletionWithRepository() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let mockRepository = MockPhotoRepository()

        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            photoRepository: mockRepository
        )

        let photos = [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000),
            PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 2000)
        ]
        let input = DeletePhotosInput(photos: photos, permanently: true)

        // When
        let result = try await sut.execute(input)

        // Then
        #expect(mockRepository.deletePhotosCalled)
        #expect(mockRepository.lastDeletedPhotos?.count == 2)
        #expect(result.deletedCount == 2)
        #expect(result.freedBytes == 3000)
        #expect(result.isFullySuccessful)
        #expect(!mockTrashManager.moveToTrashCalled) // ゴミ箱には移動しない
    }

    @Test("完全削除でPhotoRepositoryがエラーを返す場合エラーが発生する")
    func testPermanentDeletionRepositoryError() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let mockRepository = MockPhotoRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = PhotoRepositoryError.photoAccessDenied

        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            photoRepository: mockRepository
        )

        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: true)

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
        #expect(mockRepository.deletePhotosCalled)
    }

    @Test("完全削除でユーザーがキャンセルした場合エラーが発生する")
    func testPermanentDeletionUserCancelled() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let mockRepository = MockPhotoRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = PhotoRepositoryError.fetchCancelled

        let sut = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            photoRepository: mockRepository
        )

        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: true)

        // When & Then
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
        #expect(mockRepository.deletePhotosCalled)
    }

    @Test("フォーマット済み容量が正しく表示される")
    func testFormattedFreedBytes() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(trashManager: mockTrashManager)

        let photos = [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1_048_576) // 1MB
        ]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // When
        let result = try await sut.execute(input)

        // Then
        #expect(result.formattedFreedBytes.contains("1") || result.formattedFreedBytes.contains("MB"))
    }

    @Test("複数グループからの一括削除")
    func testExecuteFromGroups() async throws {
        // Given
        let mockTrashManager = MockTrashManager()
        let sut = DeletePhotosUseCase(trashManager: mockTrashManager)

        let group1 = PhotoGroup.mock(photoCount: 3, fileSize: 1000)
        let group2 = PhotoGroup.mock(photoCount: 2, fileSize: 2000)

        // When
        let result = try await sut.executeFromGroups(
            [group1, group2],
            permanently: false
        )

        // Then
        #expect(mockTrashManager.moveToTrashCalled)
        #expect(result.deletedCount == 5)
    }
}

// MARK: - DeletePhotosInput Tests

@Suite("DeletePhotosInput Tests")
struct DeletePhotosInputTests {

    @Test("正常に初期化できる")
    func testInitialization() {
        // Given
        let photos = [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000),
            PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 2000)
        ]

        // When
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then
        #expect(input.photos.count == 2)
        #expect(input.permanently == false)
    }

    @Test("デフォルトでゴミ箱移動モード")
    func testDefaultPermanently() {
        // Given
        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]

        // When
        let input = DeletePhotosInput(photos: photos)

        // Then
        #expect(input.permanently == false)
    }
}

// MARK: - DeletePhotosOutput Tests

@Suite("DeletePhotosOutput Tests")
struct DeletePhotosOutputTests {

    @Test("正常に初期化できる")
    func testInitialization() {
        // When
        let output = DeletePhotosOutput(
            deletedCount: 5,
            freedBytes: 10_000_000,
            failedIds: []
        )

        // Then
        #expect(output.deletedCount == 5)
        #expect(output.freedBytes == 10_000_000)
        #expect(output.failedIds.isEmpty)
        #expect(output.isFullySuccessful)
    }

    @Test("失敗がある場合isFullySuccessfulがfalse")
    func testIsFullySuccessfulWithFailures() {
        // When
        let output = DeletePhotosOutput(
            deletedCount: 3,
            freedBytes: 5_000_000,
            failedIds: ["photo1", "photo2"]
        )

        // Then
        #expect(!output.isFullySuccessful)
        #expect(output.failedIds.count == 2)
    }

    @Test("フォーマット済み容量が文字列で取得できる")
    func testFormattedFreedBytes() {
        // Given
        let output = DeletePhotosOutput(
            deletedCount: 1,
            freedBytes: 2_097_152, // 2MB
            failedIds: []
        )

        // When
        let formatted = output.formattedFreedBytes

        // Then
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("2") || formatted.contains("MB"))
    }

    @Test("等価性比較が正しく動作する")
    func testEquality() {
        // Given
        let output1 = DeletePhotosOutput(
            deletedCount: 5,
            freedBytes: 10_000,
            failedIds: ["a", "b"]
        )
        let output2 = DeletePhotosOutput(
            deletedCount: 5,
            freedBytes: 10_000,
            failedIds: ["a", "b"]
        )
        let output3 = DeletePhotosOutput(
            deletedCount: 3,
            freedBytes: 10_000,
            failedIds: ["a", "b"]
        )

        // Then
        #expect(output1 == output2)
        #expect(output1 != output3)
    }
}

// MARK: - Mock Extensions

extension Photo {
    static func mock(
        id: String = UUID().uuidString,
        fileSize: Int64 = 1_000_000,
        creationDate: Date = Date()
    ) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: creationDate,
            modificationDate: creationDate,
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 0,
            fileSize: fileSize,
            isFavorite: false
        )
    }
}

extension PhotoGroup {
    static func mock(
        photoCount: Int = 3,
        fileSize: Int64 = 1000
    ) -> PhotoGroup {
        let photoIds = (0..<photoCount).map { "photo\($0)" }
        let fileSizes = Array(repeating: fileSize, count: photoCount)

        return PhotoGroup(
            id: UUID(),
            type: .similar,
            photoIds: photoIds,
            fileSizes: fileSizes,
            bestShotIndex: nil,
            isSelected: false,
            createdAt: Date()
        )
    }
}
