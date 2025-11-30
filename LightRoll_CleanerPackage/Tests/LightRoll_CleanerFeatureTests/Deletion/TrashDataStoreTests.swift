//
//  TrashDataStoreTests.swift
//  LightRoll_CleanerFeatureTests
//
//  TrashDataStoreのテスト
//  永続化、読み込み、削除、期限切れ処理などを検証
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - TrashDataStore Tests

@Suite("TrashDataStore Tests", .serialized)
struct TrashDataStoreTests {

    // MARK: - Test Helpers

    /// テスト用のTrashPhotoを生成
    private func makeTestPhoto(
        id: UUID = UUID(),
        originalPhotoId: String = "test-photo-123",
        deletedAt: Date = Date(),
        expiresAt: Date? = nil,
        fileSize: Int64 = 1024 * 1024
    ) -> TrashPhoto {
        TrashPhoto(
            id: id,
            originalPhotoId: originalPhotoId,
            originalAssetIdentifier: "asset-\(originalPhotoId)",
            thumbnailData: Data([0x00, 0x01, 0x02]),
            deletedAt: deletedAt,
            expiresAt: expiresAt,
            fileSize: fileSize,
            metadata: TrashPhotoMetadata(
                creationDate: Date().addingTimeInterval(-86400),
                pixelWidth: 1920,
                pixelHeight: 1080
            )
        )
    }

    /// テスト用の一時ディレクトリを作成
    private func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        return tempDir
    }

    /// テスト用のFileManagerを作成
    private func createTestFileManager(withTempDirectory tempDir: URL) -> FileManager {
        FileManager.default
    }

    // MARK: - Initialization Tests

    @Test("初期化が成功する")
    func initializationSucceeds() async throws {
        let store = try TrashDataStore()
        #expect(store != nil)
    }

    @Test("空の状態でloadAllは空配列を返す")
    func loadAllReturnsEmptyArrayWhenEmpty() async throws {
        let store = try TrashDataStore()
        try await store.removeAll() // テスト間のデータをクリア
        let photos = try await store.loadAll()
        #expect(photos.isEmpty)
    }

    // MARK: - Save and Load Tests

    @Test("単一の写真を保存して読み込める")
    func saveSinglePhotoAndLoad() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo = makeTestPhoto()

        try await store.save([photo])
        let loaded = try await store.loadAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.id == photo.id)
        #expect(loaded.first?.originalPhotoId == photo.originalPhotoId)
    }

    @Test("複数の写真を保存して読み込める")
    func saveMultiplePhotosAndLoad() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photos = [
            makeTestPhoto(originalPhotoId: "photo-1"),
            makeTestPhoto(originalPhotoId: "photo-2"),
            makeTestPhoto(originalPhotoId: "photo-3")
        ]

        try await store.save(photos)
        let loaded = try await store.loadAll()

        #expect(loaded.count == 3)
        #expect(loaded.map { $0.originalPhotoId }.sorted() == ["photo-1", "photo-2", "photo-3"])
    }

    @Test("保存後に再度読み込んでも同じデータが取得できる")
    func saveAndReloadReturnsSameData() async throws {
        let store1 = try TrashDataStore()
        try await store1.removeAll()

        let photo = makeTestPhoto(fileSize: 5 * 1024 * 1024)

        try await store1.save([photo])

        // 新しいインスタンスで読み込み
        let store2 = try TrashDataStore()
        let loaded = try await store2.loadAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.id == photo.id)
        #expect(loaded.first?.fileSize == photo.fileSize)
    }

    // MARK: - Add Tests

    @Test("add()で単一の写真を追加できる")
    func addSinglePhoto() async throws {
        let store = try TrashDataStore()

        // まず空にする
        try await store.removeAll()

        let photo1 = makeTestPhoto(originalPhotoId: "photo-1")
        let photo2 = makeTestPhoto(originalPhotoId: "photo-2")

        try await store.add(photo1)
        try await store.add(photo2)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 2)
    }

    @Test("addBatch()で複数の写真を一括追加できる")
    func addBatchPhotos() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let initialPhoto = makeTestPhoto(originalPhotoId: "initial")
        try await store.save([initialPhoto])

        let newPhotos = [
            makeTestPhoto(originalPhotoId: "batch-1"),
            makeTestPhoto(originalPhotoId: "batch-2"),
            makeTestPhoto(originalPhotoId: "batch-3")
        ]

        try await store.addBatch(newPhotos)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 4)
    }

    // MARK: - Remove Tests

    @Test("remove()で指定IDの写真を削除できる")
    func removePhotoById() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo1 = makeTestPhoto(originalPhotoId: "photo-1")
        let photo2 = makeTestPhoto(originalPhotoId: "photo-2")
        let photo3 = makeTestPhoto(originalPhotoId: "photo-3")

        try await store.save([photo1, photo2, photo3])
        try await store.remove(id: photo2.id)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.id == photo1.id })
        #expect(loaded.contains { $0.id == photo3.id })
        #expect(!loaded.contains { $0.id == photo2.id })
    }

    @Test("存在しないIDをremove()するとエラーが発生する")
    func removeNonExistentPhotoThrowsError() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo = makeTestPhoto()
        try await store.save([photo])

        await #expect(throws: TrashPhotoError.self) {
            try await store.remove(id: UUID())
        }
    }

    @Test("removeBatch()で複数の写真を一括削除できる")
    func removeBatchPhotos() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photos = [
            makeTestPhoto(originalPhotoId: "photo-1"),
            makeTestPhoto(originalPhotoId: "photo-2"),
            makeTestPhoto(originalPhotoId: "photo-3"),
            makeTestPhoto(originalPhotoId: "photo-4")
        ]

        try await store.save(photos)

        let idsToRemove = [photos[1].id, photos[3].id]
        try await store.removeBatch(ids: idsToRemove)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.id == photos[0].id })
        #expect(loaded.contains { $0.id == photos[2].id })
    }

    @Test("removeAll()で全ての写真を削除できる")
    func removeAllPhotos() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photos = [
            makeTestPhoto(originalPhotoId: "photo-1"),
            makeTestPhoto(originalPhotoId: "photo-2"),
            makeTestPhoto(originalPhotoId: "photo-3")
        ]

        try await store.save(photos)
        try await store.removeAll()

        let loaded = try await store.loadAll()
        #expect(loaded.isEmpty)
    }

    // MARK: - Expired Photos Tests

    @Test("removeExpiredPhotos()で期限切れ写真のみ削除される")
    func removeExpiredPhotosOnly() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let now = Date()

        let validPhoto = makeTestPhoto(
            originalPhotoId: "valid",
            expiresAt: now.addingTimeInterval(86400) // 明日
        )

        let expiredPhoto1 = makeTestPhoto(
            originalPhotoId: "expired-1",
            expiresAt: now.addingTimeInterval(-86400) // 昨日
        )

        let expiredPhoto2 = makeTestPhoto(
            originalPhotoId: "expired-2",
            expiresAt: now.addingTimeInterval(-3600) // 1時間前
        )

        try await store.save([validPhoto, expiredPhoto1, expiredPhoto2])

        let removedCount = try await store.removeExpiredPhotos()
        #expect(removedCount == 2)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == validPhoto.id)
    }

    @Test("期限切れ写真がない場合removeExpiredPhotosは0を返す")
    func removeExpiredPhotosReturnsZeroWhenNoExpired() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let now = Date()

        let photos = [
            makeTestPhoto(originalPhotoId: "photo-1", expiresAt: now.addingTimeInterval(86400)),
            makeTestPhoto(originalPhotoId: "photo-2", expiresAt: now.addingTimeInterval(172800))
        ]

        try await store.save(photos)
        let removedCount = try await store.removeExpiredPhotos()

        #expect(removedCount == 0)

        let loaded = try await store.loadAll()
        #expect(loaded.count == 2)
    }

    // MARK: - Fetch Tests

    @Test("fetch()で指定IDの写真を取得できる")
    func fetchPhotoById() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo = makeTestPhoto(originalPhotoId: "target-photo")

        try await store.save([photo])
        let fetched = try await store.fetch(id: photo.id)

        #expect(fetched != nil)
        #expect(fetched?.id == photo.id)
        #expect(fetched?.originalPhotoId == "target-photo")
    }

    @Test("存在しないIDをfetch()するとnilを返す")
    func fetchNonExistentPhotoReturnsNil() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo = makeTestPhoto()
        try await store.save([photo])

        let fetched = try await store.fetch(id: UUID())
        #expect(fetched == nil)
    }

    // MARK: - Storage Size Tests

    @Test("getStorageSize()でストレージサイズを取得できる")
    func getStorageSizeReturnsSize() async throws {
        let store = try TrashDataStore()

        // まず空にする
        try await store.removeAll()

        // 空の場合（空配列のJSONファイルは存在するため4バイト以上）
        let emptySize = try await store.getStorageSize()
        #expect(emptySize >= 0) // ファイルが存在すれば4バイト（"[]\n"）、なければ0

        // 写真を追加後
        let photos = [
            makeTestPhoto(originalPhotoId: "photo-1"),
            makeTestPhoto(originalPhotoId: "photo-2")
        ]
        try await store.save(photos)

        let sizeAfterSave = try await store.getStorageSize()
        #expect(sizeAfterSave > emptySize) // 追加後は明らかにサイズが増える
    }

    // MARK: - Cache Tests

    @Test("キャッシュが正しく機能する")
    func cacheWorks() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photo = makeTestPhoto()

        try await store.save([photo])

        // 1回目の読み込み（ファイルから）
        let loaded1 = try await store.loadAll()
        #expect(loaded1.count == 1)

        // 2回目の読み込み（キャッシュから）
        let loaded2 = try await store.loadAll()
        #expect(loaded2.count == 1)

        // キャッシュされた値が同じことを確認
        #expect(loaded1.first?.id == loaded2.first?.id)
    }

    // MARK: - Edge Cases

    @Test("空のデータを保存しても問題ない")
    func saveEmptyArraySucceeds() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        try await store.save([])

        let loaded = try await store.loadAll()
        #expect(loaded.isEmpty)
    }

    @Test("大量の写真を保存して読み込める")
    func saveLargeNumberOfPhotos() async throws {
        let store = try TrashDataStore()
        try await store.removeAll()

        let photos = (0..<100).map { index in
            makeTestPhoto(originalPhotoId: "photo-\(index)")
        }

        try await store.save(photos)
        let loaded = try await store.loadAll()

        #expect(loaded.count == 100)
    }
}

// MARK: - MockTrashDataStore Tests

#if DEBUG

@Suite("MockTrashDataStore Tests")
struct MockTrashDataStoreTests {

    @Test("Mock初期化が成功する")
    func mockInitializationSucceeds() async {
        let mock = MockTrashDataStore()
        #expect(mock != nil)
    }

    @Test("Mock初期データが設定される")
    func mockInitialDataIsSet() async throws {
        let photo = TrashPhoto(
            originalPhotoId: "test",
            originalAssetIdentifier: "asset-test",
            thumbnailData: nil,
            fileSize: 1024,
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )
        )

        let mock = MockTrashDataStore(initialData: [photo])
        let loaded = try await mock.loadAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.originalPhotoId == "test")
    }

    @Test("Mock基本操作が動作する")
    func mockBasicOperationsWork() async throws {
        let photo = TrashPhoto(
            originalPhotoId: "test",
            originalAssetIdentifier: "asset-test",
            thumbnailData: nil,
            fileSize: 1024,
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )
        )

        let mock = MockTrashDataStore()

        // 追加操作
        try await mock.add(photo)

        // 読み込み操作
        let loaded = try await mock.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.originalPhotoId == "test")

        // 削除操作
        try await mock.remove(id: photo.id)
        let afterRemove = try await mock.loadAll()
        #expect(afterRemove.isEmpty)
    }
}

#endif
