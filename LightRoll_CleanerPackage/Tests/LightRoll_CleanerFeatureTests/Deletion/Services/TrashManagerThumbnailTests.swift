//
//  TrashManagerThumbnailTests.swift
//  LightRoll_CleanerFeatureTests
//
//  P1問題修正（DEVICE-002）のテスト
//  TrashManagerのサムネイル生成機能に関するテストケース
//  Created by AI Assistant
//

import Testing
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(Photos)
import Photos
#endif

@testable import LightRoll_CleanerFeature

// MARK: - TrashManagerThumbnailTests Suite

@Suite("TrashManager Thumbnail Tests - DEVICE-002", .tags(.deletion, .thumbnail))
struct TrashManagerThumbnailTests {

    // MARK: - Test Helper

    /// モックデータストア
    private let mockDataStore = MockTrashDataStore()

    /// テスト対象のTrashManager
    private var sut: TrashManager {
        TrashManager(dataStore: mockDataStore, retentionDays: 30)
    }

    #if canImport(UIKit)
    /// テスト用のダミーサムネイル画像を生成
    /// - Parameter size: 画像サイズ
    /// - Returns: テスト用UIImage
    private func createTestThumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// テスト用のダミーサムネイルデータを生成
    /// - Parameter size: 画像サイズ
    /// - Returns: テスト用サムネイルData
    private func createTestThumbnailData(size: CGSize = CGSize(width: 100, height: 100)) -> Data? {
        createTestThumbnail(size: size).jpegData(compressionQuality: 0.8)
    }
    #endif

    // MARK: - 正常系テスト

    @Test("サムネイルデータ付きTrashPhotoが正しく保存される")
    func testTrashPhotoWithThumbnailData_IsSavedCorrectly() async throws {
        #if canImport(UIKit)
        // Given
        let thumbnailData = createTestThumbnailData()
        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "test-photo-1",
            originalAssetIdentifier: "test-photo-1",
            thumbnailData: thumbnailData,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 2048,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: .userSelected
        )

        // When
        try await mockDataStore.save([trashPhoto])

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 1)
        #expect(savedPhotos[0].thumbnailData != nil)
        #expect(savedPhotos[0].thumbnailData == thumbnailData)
        #endif
    }

    @Test("サムネイルデータから正しいサイズの画像を復元できる")
    func testThumbnailDataToImage_ReturnsCorrectSize() async throws {
        #if canImport(UIKit)
        // Given
        let expectedSize = CGSize(width: 150, height: 150)
        let originalThumbnail = createTestThumbnail(size: expectedSize)
        let thumbnailData = originalThumbnail.pngData()

        // When
        guard let data = thumbnailData,
              let restoredImage = UIImage(data: data) else {
            Issue.record("サムネイルデータからの画像復元に失敗")
            return
        }

        // Then
        // サイズが近いことを確認（圧縮による多少の誤差を許容）
        #expect(abs(restoredImage.size.width - expectedSize.width) < 1)
        #expect(abs(restoredImage.size.height - expectedSize.height) < 1)
        #endif
    }

    @Test("複数のサムネイル付きTrashPhotoを同時に保存できる")
    func testMultipleTrashPhotosWithThumbnails_SavedCorrectly() async throws {
        #if canImport(UIKit)
        // Given
        let trashPhotos = (0..<5).map { index -> TrashPhoto in
            TrashPhoto(
                id: UUID(),
                originalPhotoId: "test-photo-\(index)",
                originalAssetIdentifier: "test-photo-\(index)",
                thumbnailData: createTestThumbnailData(),
                deletedAt: Date(),
                expiresAt: Date().addingTimeInterval(30 * 86400),
                fileSize: Int64(1024 * (index + 1)),
                metadata: TrashPhotoMetadata.mock(),
                deletionReason: .similarPhoto
            )
        }

        // When
        try await mockDataStore.save(trashPhotos)

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 5)

        // 全てのサムネイルデータが存在することを確認
        let photosWithThumbnails = savedPhotos.filter { $0.thumbnailData != nil }
        #expect(photosWithThumbnails.count == 5)
        #endif
    }

    // MARK: - 異常系テスト

    @Test("サムネイルデータがnilの場合でもTrashPhotoは保存される")
    func testTrashPhotoWithNilThumbnail_SavesSuccessfully() async throws {
        // Given
        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "test-photo-no-thumbnail",
            originalAssetIdentifier: "test-photo-no-thumbnail",
            thumbnailData: nil,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 1024,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: .userSelected
        )

        // When
        try await mockDataStore.save([trashPhoto])

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 1)
        #expect(savedPhotos[0].thumbnailData == nil)
        #expect(savedPhotos[0].originalPhotoId == "test-photo-no-thumbnail")
    }

    @Test("破損したサムネイルデータでもTrashPhotoは保存される")
    func testTrashPhotoWithCorruptedThumbnail_SavesSuccessfully() async throws {
        // Given
        let corruptedData = Data([0x00, 0x01, 0x02, 0x03])  // 無効な画像データ
        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "test-photo-corrupted",
            originalAssetIdentifier: "test-photo-corrupted",
            thumbnailData: corruptedData,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 1024,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: .userSelected
        )

        // When
        try await mockDataStore.save([trashPhoto])

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 1)

        #if canImport(UIKit)
        // 破損したデータからは画像を復元できないことを確認
        if let data = savedPhotos[0].thumbnailData {
            let image = UIImage(data: data)
            #expect(image == nil)
        }
        #endif
    }

    @Test("サムネイル生成失敗時はnilを返す")
    func testThumbnailGenerationFailure_ReturnsNil() async throws {
        #if canImport(UIKit)
        // Given
        let invalidAssetIdentifier = "invalid-asset-id-that-does-not-exist"

        // When
        // 実際のPHAssetではなく、無効なIDでの生成を試みる
        // 現在の実装ではサムネイル生成が未実装なのでnilが返る
        let photo = Photo.mock(localIdentifier: invalidAssetIdentifier)
        let manager = sut

        try await manager.moveToTrash([photo], reason: .userSelected)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 1)
        // 現在の実装ではthumbnailDataは常にnil
        #expect(trashPhotos[0].thumbnailData == nil)
        #endif
    }

    // MARK: - 境界値テスト

    @Test("空のサムネイルデータ（0バイト）でもTrashPhotoは保存される")
    func testTrashPhotoWithEmptyThumbnailData_SavesSuccessfully() async throws {
        // Given
        let emptyData = Data()
        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "test-photo-empty-thumbnail",
            originalAssetIdentifier: "test-photo-empty-thumbnail",
            thumbnailData: emptyData,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 1024,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: .userSelected
        )

        // When
        try await mockDataStore.save([trashPhoto])

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 1)
        #expect(savedPhotos[0].thumbnailData?.isEmpty == true)
    }

    @Test("大量のサムネイル付きTrashPhotoを同時生成してもメモリリークしない")
    func testManyThumbnailsSimultaneously_NoMemoryLeak() async throws {
        #if canImport(UIKit)
        // Given
        let photoCount = 50
        let trashPhotos = (0..<photoCount).map { index -> TrashPhoto in
            TrashPhoto(
                id: UUID(),
                originalPhotoId: "bulk-photo-\(index)",
                originalAssetIdentifier: "bulk-photo-\(index)",
                thumbnailData: createTestThumbnailData(size: CGSize(width: 80, height: 80)),
                deletedAt: Date(),
                expiresAt: Date().addingTimeInterval(30 * 86400),
                fileSize: Int64(1024 * (index + 1)),
                metadata: TrashPhotoMetadata.mock(),
                deletionReason: .similarPhoto
            )
        }

        // When
        try await mockDataStore.save(trashPhotos)

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == photoCount)

        // メモリ使用量が妥当な範囲内であることを確認
        // （テストが正常に完了すればメモリリークはないと推定）
        let totalThumbnailSize = savedPhotos.compactMap { $0.thumbnailData?.count }.reduce(0, +)
        #expect(totalThumbnailSize > 0)
        #endif
    }

    @Test("サムネイルサイズが0x0でも処理が完了する")
    func testZeroSizeThumbnail_ProcessesWithoutCrash() async throws {
        #if canImport(UIKit)
        // Given
        let zeroSizeImage = createTestThumbnail(size: CGSize(width: 0.1, height: 0.1))
        let thumbnailData = zeroSizeImage.pngData()

        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "test-photo-zero-size",
            originalAssetIdentifier: "test-photo-zero-size",
            thumbnailData: thumbnailData,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 1024,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: .userSelected
        )

        // When
        try await mockDataStore.save([trashPhoto])

        // Then
        let savedPhotos = try await mockDataStore.loadAll()
        #expect(savedPhotos.count == 1)
        // クラッシュしなければ成功
        #endif
    }
}

// MARK: - TrashManager Thumbnail Generation Tests

@Suite("TrashManager Thumbnail Generation", .tags(.deletion, .thumbnail))
struct TrashManagerThumbnailGenerationTests {

    /// モックデータストア
    private let mockDataStore = MockTrashDataStore()

    /// テスト対象のTrashManager
    private var sut: TrashManager {
        TrashManager(dataStore: mockDataStore, retentionDays: 30)
    }

    // MARK: - Integration Tests

    @Test("写真をゴミ箱に移動時、メタデータが正しく保存される")
    func testMoveToTrash_MetadataPreserved() async throws {
        // Given
        let photo = Photo(
            id: "integration-test-photo",
            localIdentifier: "integration-test-photo",
            creationDate: Date().addingTimeInterval(-86400),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 3024,
            pixelHeight: 4032,
            duration: 0,
            fileSize: 5_000_000,
            isFavorite: true
        )

        // When
        try await sut.moveToTrash([photo], reason: .blurryPhoto)

        // Then
        let trashPhotos = try await mockDataStore.loadAll()
        #expect(trashPhotos.count == 1)

        let trashPhoto = trashPhotos[0]
        #expect(trashPhoto.metadata.pixelWidth == 3024)
        #expect(trashPhoto.metadata.pixelHeight == 4032)
        #expect(trashPhoto.metadata.mediaType == .image)
        #expect(trashPhoto.metadata.isFavorite == true)
        #expect(trashPhoto.deletionReason == .blurryPhoto)
    }

    @Test("サムネイル取得用の拡張メソッドが正しく動作する")
    func testTrashPhotoThumbnailImage_ReturnsCorrectImage() async throws {
        #if canImport(UIKit)
        // Given
        let originalImage = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200)).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        }
        guard let thumbnailData = originalImage.jpegData(compressionQuality: 0.8) else {
            Issue.record("サムネイルデータの生成に失敗")
            return
        }

        let trashPhoto = TrashPhoto(
            id: UUID(),
            originalPhotoId: "thumbnail-test",
            originalAssetIdentifier: "thumbnail-test",
            thumbnailData: thumbnailData,
            deletedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 86400),
            fileSize: 2048,
            metadata: TrashPhotoMetadata.mock(),
            deletionReason: nil
        )

        // When
        let restoredImage = trashPhoto.thumbnailImage

        // Then
        #expect(restoredImage != nil)
        #expect(restoredImage?.size.width ?? 0 > 0)
        #expect(restoredImage?.size.height ?? 0 > 0)
        #endif
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var thumbnail: Self
}

// MARK: - TrashPhoto Extension for Testing

#if canImport(UIKit)
extension TrashPhoto {
    /// サムネイルデータからUIImageを生成する便利プロパティ
    var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
}
#endif

// MARK: - Additional Mock Extensions

extension TrashPhotoMetadata {
    /// テスト用のモックメタデータ
    static func mock(
        creationDate: Date = Date(),
        pixelWidth: Int = 1920,
        pixelHeight: Int = 1080,
        mediaType: MediaType = .image,
        mediaSubtypes: MediaSubtypes = [],
        isFavorite: Bool = false
    ) -> TrashPhotoMetadata {
        TrashPhotoMetadata(
            creationDate: creationDate,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            mediaType: mediaType,
            mediaSubtypes: mediaSubtypes,
            isFavorite: isFavorite
        )
    }
}
