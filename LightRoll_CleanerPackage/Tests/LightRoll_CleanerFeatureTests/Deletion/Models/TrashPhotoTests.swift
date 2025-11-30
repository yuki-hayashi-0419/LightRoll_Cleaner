//
//  TrashPhotoTests.swift
//  LightRoll_CleanerFeatureTests
//
//  TrashPhotoモデルの単体テスト
//  正常系・異常系・境界値テストを網羅
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - TrashPhoto Tests

@Suite("TrashPhoto Tests")
struct TrashPhotoTests {

    // MARK: - Test Helpers

    /// テスト用のサンプルメタデータを作成
    private func makeSampleMetadata(
        creationDate: Date = Date(),
        pixelWidth: Int = 4032,
        pixelHeight: Int = 3024,
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

    /// テスト用のサンプルTrashPhotoを作成
    private func makeSampleTrashPhoto(
        id: UUID = UUID(),
        originalPhotoId: String = "photo-123",
        originalAssetIdentifier: String = "asset-456",
        thumbnailData: Data? = Data([0x00, 0x01, 0x02]),
        deletedAt: Date = Date(),
        expiresAt: Date? = nil,
        fileSize: Int64 = 1024 * 1024,
        metadata: TrashPhotoMetadata? = nil,
        deletionReason: TrashPhoto.DeletionReason? = nil
    ) -> TrashPhoto {
        TrashPhoto(
            id: id,
            originalPhotoId: originalPhotoId,
            originalAssetIdentifier: originalAssetIdentifier,
            thumbnailData: thumbnailData,
            deletedAt: deletedAt,
            expiresAt: expiresAt,
            fileSize: fileSize,
            metadata: metadata ?? makeSampleMetadata(),
            deletionReason: deletionReason
        )
    }

    // MARK: - 正常系テスト (Normal Cases)

    @Suite("Initialization Tests")
    struct InitializationTests {

        @Test("全プロパティを指定して初期化")
        func fullInitialization() {
            let id = UUID()
            let deletedAt = Date()
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            )

            let trashPhoto = TrashPhoto(
                id: id,
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: Data([0x00]),
                deletedAt: deletedAt,
                expiresAt: nil,
                fileSize: 1024 * 1024,
                metadata: metadata,
                deletionReason: .userSelected
            )

            #expect(trashPhoto.id == id)
            #expect(trashPhoto.originalPhotoId == "photo-123")
            #expect(trashPhoto.originalAssetIdentifier == "asset-456")
            #expect(trashPhoto.thumbnailData != nil)
            #expect(trashPhoto.deletedAt == deletedAt)
            #expect(trashPhoto.fileSize == 1024 * 1024)
            #expect(trashPhoto.deletionReason == .userSelected)
        }

        @Test("expiresAtが未指定の場合、30日後に自動設定される")
        func defaultExpiresAt() {
            let deletedAt = Date()
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                deletedAt: deletedAt,
                expiresAt: nil,
                fileSize: 1024,
                metadata: metadata
            )

            let expectedExpires = Calendar.current.date(
                byAdding: .day,
                value: 30,
                to: deletedAt
            )!

            // 1秒以内の誤差を許容
            let difference = abs(trashPhoto.expiresAt.timeIntervalSince(expectedExpires))
            #expect(difference < 1.0)
        }

        @Test("デフォルト保持日数は30日")
        func defaultRetentionDays() {
            #expect(TrashPhoto.defaultRetentionDays == 30)
        }
    }

    @Suite("Computed Properties Tests")
    struct ComputedPropertiesTests {

        @Test("isExpired: 期限切れの判定")
        func isExpiredTrue() {
            let pastExpires = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                deletedAt: Date().addingTimeInterval(-86400 * 31),
                expiresAt: pastExpires,
                fileSize: 1024,
                metadata: metadata
            )

            #expect(trashPhoto.isExpired == true)
            #expect(trashPhoto.isRestorable == false)
        }

        @Test("isExpired: 期限内の判定")
        func isExpiredFalse() {
            let futureExpires = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                deletedAt: Date(),
                expiresAt: futureExpires,
                fileSize: 1024,
                metadata: metadata
            )

            #expect(trashPhoto.isExpired == false)
            #expect(trashPhoto.isRestorable == true)
        }

        @Test("daysUntilExpiration: 残り日数の計算")
        func daysUntilExpiration() {
            let daysRemaining = 15
            let futureExpires = Calendar.current.date(byAdding: .day, value: daysRemaining, to: Date())!
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                deletedAt: Date(),
                expiresAt: futureExpires,
                fileSize: 1024,
                metadata: metadata
            )

            // Calendar計算の誤差で±1日の許容
            let actual = trashPhoto.daysUntilExpiration
            #expect(actual >= daysRemaining - 1 && actual <= daysRemaining + 1)
        }

        @Test("formattedFileSize: ファイルサイズのフォーマット")
        func formattedFileSize() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 1024 * 1024,
                metadata: metadata
            )

            // "1 MB" または ロケールによる表記
            #expect(trashPhoto.formattedFileSize.contains("MB") || trashPhoto.formattedFileSize.contains("1"))
        }

        @Test("isVideo: 動画判定")
        func isVideo() {
            let videoMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1920,
                pixelHeight: 1080,
                mediaType: .video,
                mediaSubtypes: [],
                isFavorite: false
            )

            let imageMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1920,
                pixelHeight: 1080,
                mediaType: .image,
                mediaSubtypes: [],
                isFavorite: false
            )

            let videoPhoto = TrashPhoto(
                originalPhotoId: "video-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: videoMetadata
            )

            let imagePhoto = TrashPhoto(
                originalPhotoId: "image-123",
                originalAssetIdentifier: "asset-789",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: imageMetadata
            )

            #expect(videoPhoto.isVideo == true)
            #expect(imagePhoto.isVideo == false)
        }

        @Test("isScreenshot: スクリーンショット判定")
        func isScreenshot() {
            let screenshotMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1170,
                pixelHeight: 2532,
                mediaType: .image,
                mediaSubtypes: .screenshot,
                isFavorite: false
            )

            let normalMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024,
                mediaType: .image,
                mediaSubtypes: [],
                isFavorite: false
            )

            let screenshotPhoto = TrashPhoto(
                originalPhotoId: "screenshot-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: screenshotMetadata
            )

            let normalPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-789",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: normalMetadata
            )

            #expect(screenshotPhoto.isScreenshot == true)
            #expect(normalPhoto.isScreenshot == false)
        }

        @Test("hasThumbnail: サムネイル有無の判定")
        func hasThumbnail() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let withThumbnail = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: Data([0x00, 0x01, 0x02]),
                fileSize: 1024,
                metadata: metadata
            )

            let withoutThumbnail = TrashPhoto(
                originalPhotoId: "photo-456",
                originalAssetIdentifier: "asset-789",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: metadata
            )

            let withEmptyThumbnail = TrashPhoto(
                originalPhotoId: "photo-789",
                originalAssetIdentifier: "asset-012",
                thumbnailData: Data(),
                fileSize: 1024,
                metadata: metadata
            )

            #expect(withThumbnail.hasThumbnail == true)
            #expect(withoutThumbnail.hasThumbnail == false)
            #expect(withEmptyThumbnail.hasThumbnail == false)
        }

        @Test("resolution: 解像度文字列")
        func resolution() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: metadata
            )

            #expect(trashPhoto.resolution == "4032 × 3024")
        }
    }

    // MARK: - DeletionReason Tests

    @Suite("DeletionReason Tests")
    struct DeletionReasonTests {

        @Test("全ての削除理由にdisplayNameがある")
        func allReasonsHaveDisplayName() {
            for reason in TrashPhoto.DeletionReason.allCases {
                #expect(!reason.displayName.isEmpty)
            }
        }

        @Test("全ての削除理由にiconがある")
        func allReasonsHaveIcon() {
            for reason in TrashPhoto.DeletionReason.allCases {
                #expect(!reason.icon.isEmpty)
            }
        }

        @Test("削除理由のCodable準拠")
        func reasonIsCodable() throws {
            let reason = TrashPhoto.DeletionReason.similarPhoto

            let encoder = JSONEncoder()
            let data = try encoder.encode(reason)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TrashPhoto.DeletionReason.self, from: data)

            #expect(decoded == reason)
        }
    }

    // MARK: - TrashPhotoMetadata Tests

    @Suite("TrashPhotoMetadata Tests")
    struct MetadataTests {

        @Test("メタデータの初期化")
        func metadataInitialization() {
            let creationDate = Date()
            let metadata = TrashPhotoMetadata(
                creationDate: creationDate,
                pixelWidth: 4032,
                pixelHeight: 3024,
                mediaType: .image,
                mediaSubtypes: .screenshot,
                isFavorite: true
            )

            #expect(metadata.creationDate == creationDate)
            #expect(metadata.pixelWidth == 4032)
            #expect(metadata.pixelHeight == 3024)
            #expect(metadata.mediaType == .image)
            #expect(metadata.mediaSubtypes == .screenshot)
            #expect(metadata.isFavorite == true)
        }

        @Test("シンプルイニシャライザのデフォルト値")
        func simpleInitializerDefaults() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1920,
                pixelHeight: 1080
            )

            #expect(metadata.mediaType == .image)
            #expect(metadata.mediaSubtypes == [])
            #expect(metadata.isFavorite == false)
        }

        @Test("aspectRatio: アスペクト比の計算")
        func aspectRatio() {
            let landscape = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            )

            let portrait = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 3024,
                pixelHeight: 4032
            )

            #expect(landscape.aspectRatio > 1.0)
            #expect(portrait.aspectRatio < 1.0)
        }

        @Test("megapixels: メガピクセル計算")
        func megapixels() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            )

            // 4032 * 3024 = 12,192,768 = 約12.2MP
            #expect(metadata.megapixels > 12.0 && metadata.megapixels < 12.5)
        }

        @Test("totalPixels: 総ピクセル数")
        func totalPixels() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 200
            )

            #expect(metadata.totalPixels == 20000)
        }
    }

    // MARK: - 境界値テスト (Boundary Cases)

    @Suite("Boundary Value Tests")
    struct BoundaryValueTests {

        @Test("ファイルサイズが0以下の場合は0に正規化")
        func fileSizeZeroOrNegative() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let zeroSize = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 0,
                metadata: metadata
            )

            let negativeSize = TrashPhoto(
                originalPhotoId: "photo-456",
                originalAssetIdentifier: "asset-789",
                thumbnailData: nil,
                fileSize: -1000,
                metadata: metadata
            )

            #expect(zeroSize.fileSize == 0)
            #expect(negativeSize.fileSize == 0)
        }

        @Test("ピクセル寸法が0以下の場合は0に正規化")
        func pixelDimensionsZeroOrNegative() {
            let zeroMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 0,
                pixelHeight: 0
            )

            let negativeMetadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: -100,
                pixelHeight: -200
            )

            #expect(zeroMetadata.pixelWidth == 0)
            #expect(zeroMetadata.pixelHeight == 0)
            #expect(negativeMetadata.pixelWidth == 0)
            #expect(negativeMetadata.pixelHeight == 0)
        }

        @Test("期限切れ直前（残り1日）の判定")
        func expiresInOneDay() {
            let tomorrowExpires = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                expiresAt: tomorrowExpires,
                fileSize: 1024,
                metadata: metadata
            )

            #expect(trashPhoto.isExpired == false)
            #expect(trashPhoto.isRestorable == true)
            #expect(trashPhoto.daysUntilExpiration >= 0 && trashPhoto.daysUntilExpiration <= 1)
        }

        @Test("期限切れ直後（残り0日）の判定")
        func justExpired() {
            // 1秒前に期限切れ
            let justPastExpires = Date().addingTimeInterval(-1)
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                expiresAt: justPastExpires,
                fileSize: 1024,
                metadata: metadata
            )

            #expect(trashPhoto.isExpired == true)
            #expect(trashPhoto.isRestorable == false)
        }

        @Test("ちょうど30日後の期限")
        func exactlyThirtyDays() {
            let now = Date()
            let metadata = TrashPhotoMetadata(
                creationDate: now,
                pixelWidth: 100,
                pixelHeight: 100
            )

            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                deletedAt: now,
                expiresAt: nil,  // 自動で30日後に設定
                fileSize: 1024,
                metadata: metadata
            )

            let expected = Calendar.current.dateComponents([.day], from: now, to: trashPhoto.expiresAt).day ?? 0
            #expect(expected == 30 || expected == 29 || expected == 31) // タイムゾーンの境界を考慮
        }

        @Test("高さが0の場合のアスペクト比は1.0")
        func aspectRatioWithZeroHeight() {
            let metadata = TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 100,
                pixelHeight: 0
            )

            #expect(metadata.aspectRatio == 1.0)
        }
    }

    // MARK: - 異常系テスト (Error Cases)

    @Suite("TrashPhotoError Tests")
    struct ErrorTests {

        @Test("エラーのLocalizedError準拠")
        func errorHasLocalizedDescription() {
            let errors: [TrashPhotoError] = [
                .photoExpired(photoId: "123"),
                .photoNotFound(photoId: "456"),
                .restorationFailed(underlying: NSError(domain: "test", code: 0)),
                .storageError(underlying: NSError(domain: "test", code: 0)),
                .invalidData(reason: "invalid format"),
                .permissionDenied
            ]

            for error in errors {
                #expect(error.errorDescription != nil)
                #expect(!error.errorDescription!.isEmpty)
            }
        }

        @Test("エラーのfailureReason")
        func errorHasFailureReason() {
            let expiredError = TrashPhotoError.photoExpired(photoId: "123")
            let notFoundError = TrashPhotoError.photoNotFound(photoId: "456")
            let permissionError = TrashPhotoError.permissionDenied

            #expect(expiredError.failureReason != nil)
            #expect(notFoundError.failureReason != nil)
            #expect(permissionError.failureReason != nil)
        }

        @Test("エラーのrecoverySuggestion")
        func errorHasRecoverySuggestion() {
            let notFoundError = TrashPhotoError.photoNotFound(photoId: "123")
            let restorationError = TrashPhotoError.restorationFailed(underlying: NSError(domain: "test", code: 0))
            let storageError = TrashPhotoError.storageError(underlying: NSError(domain: "test", code: 0))
            let permissionError = TrashPhotoError.permissionDenied

            #expect(notFoundError.recoverySuggestion != nil)
            #expect(restorationError.recoverySuggestion != nil)
            #expect(storageError.recoverySuggestion != nil)
            #expect(permissionError.recoverySuggestion != nil)
        }
    }

    // MARK: - Codable Tests

    @Suite("Codable Tests")
    struct CodableTests {

        @Test("TrashPhotoのエンコード・デコード")
        func trashPhotoCodable() throws {
            let original = TrashPhoto(
                originalPhotoId: "photo-123",
                originalAssetIdentifier: "asset-456",
                thumbnailData: Data([0x00, 0x01]),
                fileSize: 1024 * 1024,
                metadata: TrashPhotoMetadata(
                    creationDate: Date(),
                    pixelWidth: 4032,
                    pixelHeight: 3024,
                    mediaType: .image,
                    mediaSubtypes: .screenshot,
                    isFavorite: true
                ),
                deletionReason: .similarPhoto
            )

            let encoder = JSONEncoder()
            let data = try encoder.encode(original)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TrashPhoto.self, from: data)

            #expect(decoded.id == original.id)
            #expect(decoded.originalPhotoId == original.originalPhotoId)
            #expect(decoded.fileSize == original.fileSize)
            #expect(decoded.deletionReason == original.deletionReason)
            #expect(decoded.metadata.pixelWidth == original.metadata.pixelWidth)
        }
    }

    // MARK: - Comparable & Hashable Tests

    @Suite("Protocol Conformance Tests")
    struct ProtocolTests {

        @Test("Comparable: 新しい削除日時が先")
        func comparableByDeletedAt() {
            let older = TrashPhoto(
                originalPhotoId: "photo-1",
                originalAssetIdentifier: "asset-1",
                thumbnailData: nil,
                deletedAt: Date().addingTimeInterval(-86400),
                fileSize: 1024,
                metadata: TrashPhotoMetadata(creationDate: Date(), pixelWidth: 100, pixelHeight: 100)
            )

            let newer = TrashPhoto(
                originalPhotoId: "photo-2",
                originalAssetIdentifier: "asset-2",
                thumbnailData: nil,
                deletedAt: Date(),
                fileSize: 1024,
                metadata: TrashPhotoMetadata(creationDate: Date(), pixelWidth: 100, pixelHeight: 100)
            )

            // newerの方が「小さい」（先にくる）
            #expect(newer < older)
        }

        @Test("Hashable: SetやDictionaryで使用可能")
        func hashable() {
            let photo1 = TrashPhoto(
                originalPhotoId: "photo-1",
                originalAssetIdentifier: "asset-1",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: TrashPhotoMetadata(creationDate: Date(), pixelWidth: 100, pixelHeight: 100)
            )

            let photo2 = TrashPhoto(
                originalPhotoId: "photo-2",
                originalAssetIdentifier: "asset-2",
                thumbnailData: nil,
                fileSize: 1024,
                metadata: TrashPhotoMetadata(creationDate: Date(), pixelWidth: 100, pixelHeight: 100)
            )

            let set: Set<TrashPhoto> = [photo1, photo2, photo1]
            #expect(set.count == 2)
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Suite("CustomStringConvertible Tests")
    struct DescriptionTests {

        @Test("description: 適切な文字列表現")
        func description() {
            let trashPhoto = TrashPhoto(
                originalPhotoId: "photo-123456789",
                originalAssetIdentifier: "asset-456",
                thumbnailData: nil,
                fileSize: 1024 * 1024,
                metadata: TrashPhotoMetadata(creationDate: Date(), pixelWidth: 100, pixelHeight: 100)
            )

            let desc = trashPhoto.description
            #expect(desc.contains("TrashPhoto"))
            #expect(desc.contains("photo-12"))
        }
    }
}

// MARK: - Array Extension Tests

@Suite("Array<TrashPhoto> Extension Tests")
struct TrashPhotoArrayTests {

    // MARK: - Test Helpers

    private func makeTestPhotos() -> [TrashPhoto] {
        let now = Date()
        let metadata = TrashPhotoMetadata(creationDate: now, pixelWidth: 100, pixelHeight: 100)

        return [
            // 期限切れ
            TrashPhoto(
                originalPhotoId: "expired-1",
                originalAssetIdentifier: "asset-1",
                thumbnailData: nil,
                deletedAt: now.addingTimeInterval(-86400 * 35),
                expiresAt: now.addingTimeInterval(-86400 * 5),
                fileSize: 1000,
                metadata: metadata,
                deletionReason: .userSelected
            ),
            // 7日以内に期限切れ
            TrashPhoto(
                originalPhotoId: "expiring-1",
                originalAssetIdentifier: "asset-2",
                thumbnailData: nil,
                deletedAt: now.addingTimeInterval(-86400 * 25),
                expiresAt: now.addingTimeInterval(86400 * 5),
                fileSize: 2000,
                metadata: metadata,
                deletionReason: .similarPhoto
            ),
            // 通常（復元可能）
            TrashPhoto(
                originalPhotoId: "normal-1",
                originalAssetIdentifier: "asset-3",
                thumbnailData: nil,
                deletedAt: now.addingTimeInterval(-86400 * 10),
                expiresAt: now.addingTimeInterval(86400 * 20),
                fileSize: 3000,
                metadata: metadata,
                deletionReason: .blurryPhoto
            ),
            // 通常（復元可能）
            TrashPhoto(
                originalPhotoId: "normal-2",
                originalAssetIdentifier: "asset-4",
                thumbnailData: nil,
                deletedAt: now.addingTimeInterval(-86400 * 5),
                expiresAt: now.addingTimeInterval(86400 * 25),
                fileSize: 4000,
                metadata: metadata,
                deletionReason: .similarPhoto
            )
        ]
    }

    // MARK: - Filtering Tests

    @Test("expiredPhotos: 期限切れ写真の抽出")
    func expiredPhotosFiltering() {
        let photos = makeTestPhotos()
        let expired = photos.expiredPhotos

        #expect(expired.count == 1)
        #expect(expired.first?.originalPhotoId == "expired-1")
    }

    @Test("restorablePhotos: 復元可能な写真の抽出")
    func restorablePhotosFiltering() {
        let photos = makeTestPhotos()
        let restorable = photos.restorablePhotos

        #expect(restorable.count == 3)
    }

    @Test("expiringWithin: 期限切れ間近の写真の抽出")
    func expiringWithinFiltering() {
        let photos = makeTestPhotos()
        let expiring = photos.expiringWithin(days: 7)

        #expect(expiring.count == 1)
        #expect(expiring.first?.originalPhotoId == "expiring-1")
    }

    @Test("filterByReason: 削除理由でフィルタ")
    func filterByReasonFiltering() {
        let photos = makeTestPhotos()
        let similarPhotos = photos.filterByReason(.similarPhoto)

        #expect(similarPhotos.count == 2)
    }

    // MARK: - Sorting Tests

    @Test("sortedByDeletedAtDescending: 新しい順にソート")
    func sortByDeletedAtDescending() {
        let photos = makeTestPhotos()
        let sorted = photos.sortedByDeletedAtDescending

        #expect(sorted.first?.originalPhotoId == "normal-2")
        #expect(sorted.last?.originalPhotoId == "expired-1")
    }

    @Test("sortedByFileSizeDescending: ファイルサイズ降順ソート")
    func sortByFileSizeDescending() {
        let photos = makeTestPhotos()
        let sorted = photos.sortedByFileSizeDescending

        #expect(sorted.first?.fileSize == 4000)
        #expect(sorted.last?.fileSize == 1000)
    }

    // MARK: - Statistics Tests

    @Test("statistics: 統計情報の計算")
    func statisticsCalculation() {
        let photos = makeTestPhotos()
        let stats = photos.statistics

        #expect(stats.totalCount == 4)
        #expect(stats.totalSize == 10000)
        #expect(stats.expiredCount == 1)
        #expect(stats.expiringCount == 1)
        #expect(stats.restorableCount == 3)
        #expect(stats.countByReason[.similarPhoto] == 2)
        #expect(stats.countByReason[.userSelected] == 1)
        #expect(stats.countByReason[.blurryPhoto] == 1)
    }

    @Test("totalSize: 合計ファイルサイズ")
    func totalSizeCalculation() {
        let photos = makeTestPhotos()
        #expect(photos.totalSize == 10000)
    }

    @Test("空配列の統計")
    func emptyStatistics() {
        let photos: [TrashPhoto] = []
        let stats = photos.statistics

        #expect(stats.totalCount == 0)
        #expect(stats.totalSize == 0)
        #expect(stats.isEmpty == true)
        #expect(stats.oldestDeletedAt == nil)
        #expect(stats.newestDeletedAt == nil)
    }

    // MARK: - Grouping Tests

    @Test("groupedByReason: 削除理由でグループ化")
    func groupByReason() {
        let photos = makeTestPhotos()
        let grouped = photos.groupedByReason

        #expect(grouped[.similarPhoto]?.count == 2)
        #expect(grouped[.userSelected]?.count == 1)
        #expect(grouped[.blurryPhoto]?.count == 1)
    }
}

// MARK: - TrashPhotoStatistics Tests

@Suite("TrashPhotoStatistics Tests")
struct TrashPhotoStatisticsTests {

    @Test("empty: 空の統計情報")
    func emptyStatistics() {
        let empty = TrashPhotoStatistics.empty

        #expect(empty.totalCount == 0)
        #expect(empty.totalSize == 0)
        #expect(empty.isEmpty == true)
        #expect(empty.restorableCount == 0)
    }

    @Test("formattedTotalSize: フォーマット済みサイズ")
    func formattedTotalSize() {
        let stats = TrashPhotoStatistics(
            totalCount: 10,
            totalSize: 1024 * 1024 * 100, // 100 MB
            expiringCount: 2,
            expiredCount: 1,
            countByReason: [:],
            oldestDeletedAt: Date(),
            newestDeletedAt: Date()
        )

        #expect(stats.formattedTotalSize.contains("MB") || stats.formattedTotalSize.contains("100"))
    }
}
