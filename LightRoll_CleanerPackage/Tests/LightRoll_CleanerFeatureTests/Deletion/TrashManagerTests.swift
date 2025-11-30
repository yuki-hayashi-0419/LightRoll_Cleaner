//
//  TrashManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  TrashManagerのテスト
//  ゴミ箱管理機能の単体テスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - TrashManagerTests Suite

@Suite("TrashManager Tests", .tags(.deletion))
struct TrashManagerTests {

    // MARK: - Helper Properties

    /// モックデータストア
    private let mockDataStore = MockTrashDataStore()

    /// テスト対象のTrashManager
    private var sut: TrashManager {
        TrashManager(dataStore: mockDataStore, retentionDays: 30)
    }

    // MARK: - Initialization Tests

    @Test("TrashManager初期化")
    func testInitialization() async {
        // Given & When
        let manager = sut

        // Then
        let count = await manager.trashCount
        #expect(count == 0)

        let size = await manager.trashSize
        #expect(size == 0)
    }

    // MARK: - Fetch Tests

    @Test("空のゴミ箱から全写真取得")
    func testFetchAllTrashPhotos_WhenEmpty() async {
        // Given
        let manager = sut

        // When
        let photos = await manager.fetchAllTrashPhotos()

        // Then
        #expect(photos.isEmpty)
    }

    @Test("ゴミ箱から全写真取得")
    func testFetchAllTrashPhotos_WithData() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(id: UUID(), originalPhotoId: "photo1"),
            TrashPhoto.mock(id: UUID(), originalPhotoId: "photo2")
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let fetchedPhotos = await manager.fetchAllTrashPhotos()

        // Then
        #expect(fetchedPhotos.count == 2)
        #expect(fetchedPhotos.contains { $0.originalPhotoId == "photo1" })
        #expect(fetchedPhotos.contains { $0.originalPhotoId == "photo2" })
    }

    @Test("ゴミ箱写真取得時のキャッシュ動作")
    func testFetchAllTrashPhotos_CacheBehavior() async throws {
        // Given
        let manager = sut
        let trashPhotos = [TrashPhoto.mock()]
        try await mockDataStore.save(trashPhotos)

        // When - 1回目の取得
        let firstFetch = await manager.fetchAllTrashPhotos()
        let loadAllCalledFirst = await mockDataStore.loadAllCalled

        // Then - DataStoreが呼ばれる
        #expect(loadAllCalledFirst)
        #expect(firstFetch.count == 1)

        // When - 2回目の取得（キャッシュ有効期間内）
        await mockDataStore.reset()
        let secondFetch = await manager.fetchAllTrashPhotos()

        // Then - キャッシュが使われる（loadAllは呼ばれない可能性）
        #expect(secondFetch.count == 1)
    }

    // MARK: - Move to Trash Tests

    @Test("写真をゴミ箱に移動")
    func testMoveToTrash_SinglePhoto() async throws {
        // Given
        let manager = sut
        let photo = Photo.mock(localIdentifier: "photo1")

        // When
        try await manager.moveToTrash([photo], reason: .userSelected)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 1)
        #expect(trashPhotos[0].originalPhotoId == "photo1")
        #expect(trashPhotos[0].deletionReason == .userSelected)
    }

    @Test("複数写真をゴミ箱に移動")
    func testMoveToTrash_MultiplePhotos() async throws {
        // Given
        let manager = sut
        let photos = [
            Photo.mock(localIdentifier: "photo1"),
            Photo.mock(localIdentifier: "photo2"),
            Photo.mock(localIdentifier: "photo3")
        ]

        // When
        try await manager.moveToTrash(photos, reason: .similarPhoto)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 3)
        #expect(trashPhotos.allSatisfy { $0.deletionReason == .similarPhoto })
    }

    @Test("削除理由なしで写真をゴミ箱に移動")
    func testMoveToTrash_WithoutReason() async throws {
        // Given
        let manager = sut
        let photo = Photo.mock(localIdentifier: "photo1")

        // When
        try await manager.moveToTrash([photo], reason: nil)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 1)
        #expect(trashPhotos[0].deletionReason == nil)
    }

    @Test("空配列をゴミ箱に移動（何も起こらない）")
    func testMoveToTrash_EmptyArray() async throws {
        // Given
        let manager = sut

        // When
        try await manager.moveToTrash([], reason: .userSelected)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.isEmpty)
    }

    @Test("写真移動時の有効期限設定")
    func testMoveToTrash_ExpirationDate() async throws {
        // Given
        let manager = sut
        let photo = Photo.mock(localIdentifier: "photo1")
        let beforeMove = Date()

        // When
        try await manager.moveToTrash([photo], reason: .userSelected)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 1)

        let trashPhoto = trashPhotos[0]
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents(
            [.day],
            from: trashPhoto.deletedAt,
            to: trashPhoto.expiresAt
        ).day

        #expect(daysDifference == 30)
        #expect(trashPhoto.deletedAt >= beforeMove)
    }

    // MARK: - Restore Tests

    @Test("ゴミ箱から写真を復元")
    func testRestore_ValidPhoto() async throws {
        // Given
        let manager = sut
        let trashPhoto = TrashPhoto.mock()
        try await mockDataStore.save([trashPhoto])

        // When
        try await manager.restore([trashPhoto])

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.isEmpty)
    }

    @Test("複数の写真を復元")
    func testRestore_MultiplePhotos() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID())
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        try await manager.restore(Array(trashPhotos.prefix(2)))

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 1)
    }

    @Test("期限切れ写真の復元失敗")
    func testRestore_ExpiredPhoto() async throws {
        // Given
        let manager = sut
        let expiredPhoto = TrashPhoto.mock(
            expiresAt: Date().addingTimeInterval(-86400) // 1日前
        )
        try await mockDataStore.save([expiredPhoto])

        // When & Then
        await #expect(throws: TrashPhotoError.self) {
            try await manager.restore([expiredPhoto])
        }
    }

    @Test("空配列の復元（何も起こらない）")
    func testRestore_EmptyArray() async throws {
        // Given
        let manager = sut
        let trashPhoto = TrashPhoto.mock()
        try await mockDataStore.save([trashPhoto])

        // When
        try await manager.restore([])

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 1)
    }

    // MARK: - Permanent Delete Tests

    @Test("ゴミ箱から完全削除")
    func testPermanentlyDelete_ValidPhoto() async throws {
        // Given
        let manager = sut
        let trashPhoto = TrashPhoto.mock()
        try await mockDataStore.save([trashPhoto])

        // When
        try await manager.permanentlyDelete([trashPhoto])

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.isEmpty)
    }

    @Test("複数写真を完全削除")
    func testPermanentlyDelete_MultiplePhotos() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID())
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        try await manager.permanentlyDelete(Array(trashPhotos.prefix(2)))

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 1)
    }

    @Test("空配列の完全削除（何も起こらない）")
    func testPermanentlyDelete_EmptyArray() async throws {
        // Given
        let manager = sut
        let trashPhoto = TrashPhoto.mock()
        try await mockDataStore.save([trashPhoto])

        // When
        try await manager.permanentlyDelete([])

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 1)
    }

    // MARK: - Cleanup Expired Tests

    @Test("期限切れ写真の自動削除")
    func testCleanupExpired_RemovesExpiredPhotos() async throws {
        // Given
        let manager = sut
        let validPhoto = TrashPhoto.mock(
            id: UUID(),
            expiresAt: Date().addingTimeInterval(86400) // 1日後
        )
        let expiredPhoto = TrashPhoto.mock(
            id: UUID(),
            expiresAt: Date().addingTimeInterval(-86400) // 1日前
        )
        try await mockDataStore.save([validPhoto, expiredPhoto])

        // When
        let deletedCount = await manager.cleanupExpired()

        // Then
        #expect(deletedCount == 1)

        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 1)
        #expect(remainingPhotos[0].id == validPhoto.id)
    }

    @Test("期限切れ写真がない場合のクリーンアップ")
    func testCleanupExpired_NoExpiredPhotos() async throws {
        // Given
        let manager = sut
        let validPhotos = [
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID())
        ]
        try await mockDataStore.save(validPhotos)

        // When
        let deletedCount = await manager.cleanupExpired()

        // Then
        #expect(deletedCount == 0)

        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.count == 2)
    }

    @Test("全て期限切れの場合のクリーンアップ")
    func testCleanupExpired_AllExpired() async throws {
        // Given
        let manager = sut
        let expiredPhotos = [
            TrashPhoto.mock(id: UUID(), expiresAt: Date().addingTimeInterval(-86400)),
            TrashPhoto.mock(id: UUID(), expiresAt: Date().addingTimeInterval(-172800))
        ]
        try await mockDataStore.save(expiredPhotos)

        // When
        let deletedCount = await manager.cleanupExpired()

        // Then
        #expect(deletedCount == 2)

        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.isEmpty)
    }

    // MARK: - Empty Trash Tests

    @Test("ゴミ箱を空にする")
    func testEmptyTrash_RemovesAllPhotos() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID()),
            TrashPhoto.mock(id: UUID())
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        try await manager.emptyTrash()

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.isEmpty)

        let count = await manager.trashCount
        #expect(count == 0)
    }

    @Test("空のゴミ箱を空にする")
    func testEmptyTrash_WhenAlreadyEmpty() async throws {
        // Given
        let manager = sut

        // When
        try await manager.emptyTrash()

        // Then
        let remainingPhotos = try await mockDataStore.loadAll()
        #expect(remainingPhotos.isEmpty)
    }

    // MARK: - Computed Properties Tests

    @Test("ゴミ箱写真数の取得")
    func testTrashCount() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(),
            TrashPhoto.mock(),
            TrashPhoto.mock()
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let count = await manager.trashCount

        // Then
        #expect(count == 3)
    }

    @Test("ゴミ箱サイズの取得")
    func testTrashSize() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(fileSize: 1024),
            TrashPhoto.mock(fileSize: 2048),
            TrashPhoto.mock(fileSize: 4096)
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let size = await manager.trashSize

        // Then
        #expect(size == 7168) // 1024 + 2048 + 4096
    }

    // MARK: - Batch Operations Tests

    @Test("削除理由別のバッチ移動")
    func testMoveToTrashBatch() async throws {
        // Given
        let manager = sut
        let photosByReason: [TrashPhoto.DeletionReason: [Photo]] = [
            .similarPhoto: [Photo.mock(localIdentifier: "photo1")],
            .blurryPhoto: [Photo.mock(localIdentifier: "photo2")],
            .screenshot: [Photo.mock(localIdentifier: "photo3")]
        ]

        // When
        try await manager.moveToTrashBatch(photosByReason)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 3)

        let similarCount = trashPhotos.filter { $0.deletionReason == .similarPhoto }.count
        let blurryCount = trashPhotos.filter { $0.deletionReason == .blurryPhoto }.count
        let screenshotCount = trashPhotos.filter { $0.deletionReason == .screenshot }.count

        #expect(similarCount == 1)
        #expect(blurryCount == 1)
        #expect(screenshotCount == 1)
    }

    @Test("統計情報の取得")
    func testGetStatistics() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(fileSize: 1000, deletionReason: .similarPhoto),
            TrashPhoto.mock(fileSize: 2000, deletionReason: .similarPhoto),
            TrashPhoto.mock(fileSize: 3000, deletionReason: .blurryPhoto)
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let stats = await manager.getStatistics()

        // Then
        #expect(stats.totalCount == 3)
        #expect(stats.totalSize == 6000)
        #expect(stats.countByReason[.similarPhoto] == 2)
        #expect(stats.countByReason[.blurryPhoto] == 1)
    }

    // MARK: - Filter & Sort Tests

    @Test("削除理由でフィルタリング")
    func testFetchPhotosByReason() async throws {
        // Given
        let manager = sut
        let trashPhotos = [
            TrashPhoto.mock(deletionReason: .similarPhoto),
            TrashPhoto.mock(deletionReason: .blurryPhoto),
            TrashPhoto.mock(deletionReason: .similarPhoto)
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let similarPhotos = await manager.fetchPhotos(byReason: .similarPhoto)

        // Then
        #expect(similarPhotos.count == 2)
        #expect(similarPhotos.allSatisfy { $0.deletionReason == .similarPhoto })
    }

    @Test("期限切れ間近の写真取得")
    func testFetchExpiringPhotos() async throws {
        // Given
        let manager = sut
        let now = Date()
        let trashPhotos = [
            TrashPhoto.mock(expiresAt: now.addingTimeInterval(2 * 86400)), // 2日後
            TrashPhoto.mock(expiresAt: now.addingTimeInterval(5 * 86400)), // 5日後
            TrashPhoto.mock(expiresAt: now.addingTimeInterval(10 * 86400)) // 10日後
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let expiringPhotos = await manager.fetchExpiringPhotos(withinDays: 3)

        // Then
        #expect(expiringPhotos.count == 1)
    }

    @Test("削除日でソート（降順）")
    func testFetchPhotosSortedByDate_Descending() async throws {
        // Given
        let manager = sut
        let now = Date()
        let trashPhotos = [
            TrashPhoto.mock(id: UUID(), deletedAt: now.addingTimeInterval(-86400)), // 1日前
            TrashPhoto.mock(id: UUID(), deletedAt: now.addingTimeInterval(-172800)), // 2日前
            TrashPhoto.mock(id: UUID(), deletedAt: now) // 今
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let sortedPhotos = await manager.fetchPhotosSortedByDate(ascending: false)

        // Then
        #expect(sortedPhotos.count == 3)
        #expect(sortedPhotos[0].deletedAt >= sortedPhotos[1].deletedAt)
        #expect(sortedPhotos[1].deletedAt >= sortedPhotos[2].deletedAt)
    }

    @Test("削除日でソート（昇順）")
    func testFetchPhotosSortedByDate_Ascending() async throws {
        // Given
        let manager = sut
        let now = Date()
        let trashPhotos = [
            TrashPhoto.mock(id: UUID(), deletedAt: now),
            TrashPhoto.mock(id: UUID(), deletedAt: now.addingTimeInterval(-86400)),
            TrashPhoto.mock(id: UUID(), deletedAt: now.addingTimeInterval(-172800))
        ]
        try await mockDataStore.save(trashPhotos)

        // When
        let sortedPhotos = await manager.fetchPhotosSortedByDate(ascending: true)

        // Then
        #expect(sortedPhotos.count == 3)
        #expect(sortedPhotos[0].deletedAt <= sortedPhotos[1].deletedAt)
        #expect(sortedPhotos[1].deletedAt <= sortedPhotos[2].deletedAt)
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var deletion: Self
}

// MARK: - Mock Extensions

extension TrashPhoto {
    static func mock(
        id: UUID = UUID(),
        originalPhotoId: String = "mock-photo-id",
        deletedAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(30 * 86400),
        fileSize: Int64 = 1024,
        deletionReason: DeletionReason? = nil
    ) -> TrashPhoto {
        TrashPhoto(
            id: id,
            originalPhotoId: originalPhotoId,
            originalAssetIdentifier: originalPhotoId,
            thumbnailData: nil,
            deletedAt: deletedAt,
            expiresAt: expiresAt,
            fileSize: fileSize,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: deletionReason
        )
    }
}

extension TrashPhotoMetadata {
    static func mock() -> TrashPhotoMetadata {
        TrashPhotoMetadata(
            creationDate: Date(),
            pixelWidth: 1920,
            pixelHeight: 1080,
            mediaType: .image,
            mediaSubtypes: [],
            isFavorite: false
        )
    }
}

extension Photo {
    static func mock(localIdentifier: String = "mock-photo-id") -> Photo {
        Photo(
            id: localIdentifier,
            localIdentifier: localIdentifier,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 0,
            fileSize: 1024,
            isFavorite: false
        )
    }
}
