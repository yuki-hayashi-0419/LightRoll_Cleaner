//
//  RestorePhotosUseCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  RestorePhotosUseCase のテスト
//  Created by AI Assistant
//

import Testing
@testable import LightRoll_CleanerFeature
import Foundation

// MARK: - RestorePhotosUseCaseTests

@MainActor
@Suite("RestorePhotosUseCase Tests")
struct RestorePhotosUseCaseTests {

    // MARK: - Test Properties

    /// テスト用モックTrashManager
    private let mockTrashManager = MockTrashManager()

    /// テスト対象のUseCase
    private var sut: RestorePhotosUseCase {
        RestorePhotosUseCase(trashManager: mockTrashManager)
    }

    // MARK: - Initialization Tests

    @Test("初期化が正しく行われること")
    func testInitialization() async throws {
        let useCase = RestorePhotosUseCase(trashManager: mockTrashManager)
        #expect(useCase != nil)
    }

    @Test("autoSkipExpiredオプションを設定できること")
    func testInitializationWithAutoSkipExpired() async throws {
        let useCase = RestorePhotosUseCase(
            trashManager: mockTrashManager,
            autoSkipExpired: true
        )
        #expect(useCase != nil)
    }

    // MARK: - Execute Tests

    @Test("空の写真配列で実行するとemptyPhotosエラーがスローされること")
    func testExecuteWithEmptyPhotos() async throws {
        let input = RestorePhotosInput(photos: [])

        await #expect(throws: RestorePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
    }

    @Test("復元可能な写真を正しく復元できること")
    func testExecuteWithValidPhotos() async throws {
        // Given: ゴミ箱に復元可能な写真が存在
        let trashPhoto = TrashPhoto.mock(
            originalPhotoId: "photo1",
            deletedAt: Date().addingTimeInterval(-3600), // 1時間前
            expiresAt: Date().addingTimeInterval(86400 * 29) // 29日後
        )
        mockTrashManager.addMockPhoto(trashPhoto)

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1024)
        ])

        // When: 復元を実行
        let result = try await sut.execute(input)

        // Then: 復元成功
        #expect(result.restoredCount == 1)
        #expect(result.failedIds.isEmpty)
        #expect(result.isFullySuccessful)
        #expect(mockTrashManager.restoreCalled)
    }

    @Test("複数の写真を一括復元できること")
    func testExecuteWithMultiplePhotos() async throws {
        // Given: 複数の写真がゴミ箱に存在
        for i in 1...3 {
            let trashPhoto = TrashPhoto.mock(
                originalPhotoId: "photo\(i)",
                deletedAt: Date().addingTimeInterval(-3600),
                expiresAt: Date().addingTimeInterval(86400 * 29)
            )
            mockTrashManager.addMockPhoto(trashPhoto)
        }

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1024),
            PhotoAsset(id: "photo2", creationDate: Date(), fileSize: 2048),
            PhotoAsset(id: "photo3", creationDate: Date(), fileSize: 4096)
        ])

        // When: 復元を実行
        let result = try await sut.execute(input)

        // Then: 全て復元成功
        #expect(result.restoredCount == 3)
        #expect(result.failedIds.isEmpty)
        #expect(result.isFullySuccessful)
    }

    @Test("期限切れ写真が含まれている場合エラーがスローされること")
    func testExecuteWithExpiredPhotos() async throws {
        // Given: 期限切れの写真がゴミ箱に存在
        let expiredPhoto = TrashPhoto.mock(
            originalPhotoId: "expired1",
            deletedAt: Date().addingTimeInterval(-86400 * 31), // 31日前
            expiresAt: Date().addingTimeInterval(-86400) // 1日前に期限切れ
        )
        mockTrashManager.addMockPhoto(expiredPhoto)

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "expired1", creationDate: Date(), fileSize: 1024)
        ])

        // When/Then: containsExpiredPhotosエラーがスローされる
        await #expect(throws: RestorePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
    }

    @Test("autoSkipExpiredがtrueの場合、期限切れ写真をスキップして復元できること")
    func testExecuteWithAutoSkipExpired() async throws {
        // Given: 期限切れと有効な写真が混在
        let expiredPhoto = TrashPhoto.mock(
            originalPhotoId: "expired1",
            deletedAt: Date().addingTimeInterval(-86400 * 31),
            expiresAt: Date().addingTimeInterval(-86400)
        )
        let validPhoto = TrashPhoto.mock(
            originalPhotoId: "valid1",
            deletedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(86400 * 29)
        )
        mockTrashManager.addMockPhoto(expiredPhoto)
        mockTrashManager.addMockPhoto(validPhoto)

        let useCase = RestorePhotosUseCase(
            trashManager: mockTrashManager,
            autoSkipExpired: true
        )

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "expired1", creationDate: Date(), fileSize: 1024),
            PhotoAsset(id: "valid1", creationDate: Date(), fileSize: 2048)
        ])

        // When: 復元を実行
        let result = try await useCase.execute(input)

        // Then: 有効な写真のみ復元される
        #expect(result.restoredCount == 1)
        #expect(result.isFullySuccessful)
    }

    @Test("TrashManagerがエラーをスローした場合、restorationFailedエラーでラップされること")
    func testExecuteWithTrashManagerError() async throws {
        // Given: TrashManagerがエラーを返す設定
        let trashPhoto = TrashPhoto.mock(
            originalPhotoId: "photo1",
            deletedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(86400 * 29)
        )
        mockTrashManager.addMockPhoto(trashPhoto)
        mockTrashManager.shouldThrowError = true

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1024)
        ])

        // When/Then: restorationFailedエラーがスローされる
        await #expect(throws: RestorePhotosUseCaseError.self) {
            try await sut.execute(input)
        }
    }

    // MARK: - Batch Operations Tests

    @Test("TrashPhotoから直接復元できること")
    func testExecuteFromTrashPhotos() async throws {
        // Given: TrashPhotoを直接指定
        let trashPhotos = [
            TrashPhoto.mock(
                originalPhotoId: "photo1",
                deletedAt: Date().addingTimeInterval(-3600),
                expiresAt: Date().addingTimeInterval(86400 * 29)
            )
        ]
        mockTrashManager.addMockPhoto(trashPhotos[0])

        // When: 復元を実行
        let result = try await sut.executeFromTrashPhotos(trashPhotos)

        // Then: 復元成功
        #expect(result.restoredCount == 1)
        #expect(result.isFullySuccessful)
    }

    @Test("削除理由別に一括復元できること")
    func testExecuteBatchByReason() async throws {
        // Given: 削除理由別の写真を用意
        let blurryPhoto = TrashPhoto.mock(
            originalPhotoId: "blurry1",
            deletedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(86400 * 29),
            deletionReason: .blurryPhoto
        )
        let screenshotPhoto = TrashPhoto.mock(
            originalPhotoId: "screenshot1",
            deletedAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(86400 * 29),
            deletionReason: .screenshot
        )
        mockTrashManager.addMockPhoto(blurryPhoto)
        mockTrashManager.addMockPhoto(screenshotPhoto)

        let photosByReason: [TrashPhoto.DeletionReason: [TrashPhoto]] = [
            .blurryPhoto: [blurryPhoto],
            .screenshot: [screenshotPhoto]
        ]

        // When: 理由別復元を実行
        let results = try await sut.executeBatchByReason(photosByReason)

        // Then: それぞれの理由で復元成功
        #expect(results.count == 2)
        #expect(results[.blurryPhoto]?.restoredCount == 1)
        #expect(results[.screenshot]?.restoredCount == 1)
    }

    // MARK: - Mock Implementation Tests

    @Test("MockRestorePhotosUseCaseが正しく動作すること")
    func testMockRestorePhotosUseCase() async throws {
        // Given: モックUseCaseを設定
        let mockUseCase = MockRestorePhotosUseCase()
        mockUseCase.mockOutput = RestorePhotosOutput(
            restoredCount: 5,
            failedIds: []
        )

        let input = RestorePhotosInput(photos: [
            PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1024)
        ])

        // When: 実行
        let result = try await mockUseCase.execute(input)

        // Then: モック結果が返される
        #expect(result.restoredCount == 5)
        #expect(mockUseCase.executeCalled)
        #expect(mockUseCase.lastInput != nil)
    }

    @Test("MockRestorePhotosUseCaseでエラーをシミュレートできること")
    func testMockRestorePhotosUseCaseError() async throws {
        // Given: エラーを返すように設定
        let mockUseCase = MockRestorePhotosUseCase()
        mockUseCase.shouldThrowError = true
        mockUseCase.errorToThrow = .emptyPhotos

        let input = RestorePhotosInput(photos: [])

        // When/Then: エラーがスローされる
        await #expect(throws: RestorePhotosUseCaseError.self) {
            try await mockUseCase.execute(input)
        }
    }
}
