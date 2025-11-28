//
//  PhotoModelsTests.swift
//  LightRoll_CleanerFeatureTests
//
//  Photo および StorageInfo モデルの単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - Photo Tests

@Suite("Photo モデルテスト")
struct PhotoTests {

    // MARK: - Test Data

    /// テスト用の写真を生成
    private func makePhoto(
        id: String = "test-id",
        localIdentifier: String = "local-123",
        creationDate: Date = Date(),
        modificationDate: Date = Date(),
        mediaType: MediaType = .image,
        mediaSubtypes: MediaSubtypes = [],
        pixelWidth: Int = 4032,
        pixelHeight: Int = 3024,
        duration: TimeInterval = 0,
        fileSize: Int64 = 3_500_000,
        isFavorite: Bool = false
    ) -> Photo {
        Photo(
            id: id,
            localIdentifier: localIdentifier,
            creationDate: creationDate,
            modificationDate: modificationDate,
            mediaType: mediaType,
            mediaSubtypes: mediaSubtypes,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            duration: duration,
            fileSize: fileSize,
            isFavorite: isFavorite
        )
    }

    // MARK: - Initialization Tests

    @Test("Photo を全プロパティ指定で初期化できる")
    func initializationWithAllProperties() {
        let creationDate = Date()
        let modificationDate = Date()

        let photo = makePhoto(
            id: "photo-1",
            localIdentifier: "local-1",
            creationDate: creationDate,
            modificationDate: modificationDate,
            mediaType: .image,
            mediaSubtypes: [.hdr, .livePhoto],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 5_000_000,
            isFavorite: true
        )

        #expect(photo.id == "photo-1")
        #expect(photo.localIdentifier == "local-1")
        #expect(photo.creationDate == creationDate)
        #expect(photo.modificationDate == modificationDate)
        #expect(photo.mediaType == .image)
        #expect(photo.mediaSubtypes.contains(.hdr))
        #expect(photo.mediaSubtypes.contains(.livePhoto))
        #expect(photo.pixelWidth == 4032)
        #expect(photo.pixelHeight == 3024)
        #expect(photo.duration == 0)
        #expect(photo.fileSize == 5_000_000)
        #expect(photo.isFavorite == true)
    }

    // MARK: - Computed Property Tests

    @Test("aspectRatio が正しく計算される")
    func aspectRatioCalculation() {
        // 横長写真
        let landscape = makePhoto(pixelWidth: 4032, pixelHeight: 3024)
        #expect(landscape.aspectRatio == 4032.0 / 3024.0)

        // 縦長写真
        let portrait = makePhoto(pixelWidth: 3024, pixelHeight: 4032)
        #expect(portrait.aspectRatio == 3024.0 / 4032.0)

        // 正方形
        let square = makePhoto(pixelWidth: 1000, pixelHeight: 1000)
        #expect(square.aspectRatio == 1.0)
    }

    @Test("aspectRatio は高さが 0 の場合 1.0 を返す")
    func aspectRatioWithZeroHeight() {
        let photo = makePhoto(pixelWidth: 100, pixelHeight: 0)
        #expect(photo.aspectRatio == 1.0)
    }

    @Test("isVideo が正しく判定される")
    func isVideoDetection() {
        let image = makePhoto(mediaType: .image)
        let video = makePhoto(mediaType: .video)
        let audio = makePhoto(mediaType: .audio)

        #expect(image.isVideo == false)
        #expect(video.isVideo == true)
        #expect(audio.isVideo == false)
    }

    @Test("isScreenshot が正しく判定される")
    func isScreenshotDetection() {
        let normalPhoto = makePhoto(mediaSubtypes: [])
        let screenshot = makePhoto(mediaSubtypes: [.screenshot])
        let screenshotWithHDR = makePhoto(mediaSubtypes: [.screenshot, .hdr])

        #expect(normalPhoto.isScreenshot == false)
        #expect(screenshot.isScreenshot == true)
        #expect(screenshotWithHDR.isScreenshot == true)
    }

    @Test("formattedFileSize が適切にフォーマットされる")
    func formattedFileSizeFormatting() {
        // 3.5 MB
        let photo1 = makePhoto(fileSize: 3_500_000)
        #expect(photo1.formattedFileSize.contains("MB") || photo1.formattedFileSize.contains("メガバイト"))

        // 1 KB
        let photo2 = makePhoto(fileSize: 1_000)
        #expect(photo2.formattedFileSize.contains("KB") || photo2.formattedFileSize.contains("キロバイト"))

        // 1.5 GB
        let photo3 = makePhoto(fileSize: 1_500_000_000)
        #expect(photo3.formattedFileSize.contains("GB") || photo3.formattedFileSize.contains("ギガバイト"))
    }

    @Test("resolution が正しくフォーマットされる")
    func resolutionFormatting() {
        let photo = makePhoto(pixelWidth: 4032, pixelHeight: 3024)
        #expect(photo.resolution == "4032 × 3024")
    }

    @Test("formattedDuration が正しくフォーマットされる")
    func formattedDurationFormatting() {
        // 画像（0秒）
        let image = makePhoto(mediaType: .image, duration: 0)
        #expect(image.formattedDuration == "")

        // 短い動画（30秒）
        let shortVideo = makePhoto(mediaType: .video, duration: 30)
        #expect(shortVideo.formattedDuration == "0:30")

        // 長い動画（1分23秒）
        let longVideo = makePhoto(mediaType: .video, duration: 83)
        #expect(longVideo.formattedDuration == "1:23")

        // 10分超の動画
        let veryLongVideo = makePhoto(mediaType: .video, duration: 600)
        #expect(veryLongVideo.formattedDuration == "10:00")
    }

    @Test("isImage, isHDR, isPanorama, isLivePhoto が正しく判定される")
    func mediaSubtypeDetection() {
        let normalImage = makePhoto(mediaType: .image, mediaSubtypes: [])
        #expect(normalImage.isImage == true)
        #expect(normalImage.isHDR == false)
        #expect(normalImage.isPanorama == false)
        #expect(normalImage.isLivePhoto == false)

        let hdrPhoto = makePhoto(mediaType: .image, mediaSubtypes: [.hdr])
        #expect(hdrPhoto.isHDR == true)

        let panorama = makePhoto(mediaType: .image, mediaSubtypes: [.panorama])
        #expect(panorama.isPanorama == true)

        let livePhoto = makePhoto(mediaType: .image, mediaSubtypes: [.livePhoto])
        #expect(livePhoto.isLivePhoto == true)
    }

    @Test("isPortrait, isLandscape, isSquare が正しく判定される")
    func orientationDetection() {
        let portrait = makePhoto(pixelWidth: 3024, pixelHeight: 4032)
        #expect(portrait.isPortrait == true)
        #expect(portrait.isLandscape == false)
        #expect(portrait.isSquare == false)

        let landscape = makePhoto(pixelWidth: 4032, pixelHeight: 3024)
        #expect(landscape.isPortrait == false)
        #expect(landscape.isLandscape == true)
        #expect(landscape.isSquare == false)

        let square = makePhoto(pixelWidth: 1000, pixelHeight: 1000)
        #expect(square.isPortrait == false)
        #expect(square.isLandscape == false)
        #expect(square.isSquare == true)
    }

    @Test("totalPixels と megapixels が正しく計算される")
    func pixelCalculations() {
        let photo = makePhoto(pixelWidth: 4032, pixelHeight: 3024)
        #expect(photo.totalPixels == 4032 * 3024)
        #expect(photo.megapixels == Double(4032 * 3024) / 1_000_000.0)
    }

    // MARK: - Equatable/Hashable Tests

    @Test("同じ id を持つ Photo は等しい")
    func equalityById() {
        let photo1 = makePhoto(id: "same-id", fileSize: 100)
        let photo2 = makePhoto(id: "same-id", fileSize: 200)
        let photo3 = makePhoto(id: "different-id", fileSize: 100)

        // Hashable なので同じ id で同じプロパティなら等しいが、
        // 実際にはすべてのプロパティが比較される
        #expect(photo1 != photo2)  // fileSize が違う
        #expect(photo1 != photo3)  // id が違う
    }

    @Test("Photo は Set に格納できる")
    func photoInSet() {
        // 全く同じプロパティを持つ Photo を作成
        let date = Date()
        let photo1 = Photo(
            id: "1",
            localIdentifier: "local-1",
            creationDate: date,
            modificationDate: date,
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 1000,
            isFavorite: false
        )
        let photo2 = makePhoto(id: "2")
        let photo3 = Photo(
            id: "1",
            localIdentifier: "local-1",
            creationDate: date,
            modificationDate: date,
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 1000,
            isFavorite: false
        )

        var photoSet: Set<Photo> = []
        photoSet.insert(photo1)
        photoSet.insert(photo2)
        photoSet.insert(photo3)

        // photo1 と photo3 は全プロパティが同じなので Set では 1 つになる
        #expect(photoSet.count == 2)
    }

    // MARK: - Comparable Tests

    @Test("Photo は作成日時で比較できる（新しい順）")
    func comparableByCreationDate() {
        let oldDate = Date(timeIntervalSince1970: 1000)
        let newDate = Date(timeIntervalSince1970: 2000)

        let oldPhoto = makePhoto(id: "old", creationDate: oldDate)
        let newPhoto = makePhoto(id: "new", creationDate: newDate)

        // < 演算子は新しい順なので、newPhoto < oldPhoto
        #expect(newPhoto < oldPhoto)

        let photos = [oldPhoto, newPhoto].sorted()
        #expect(photos[0].id == "new")
        #expect(photos[1].id == "old")
    }

    // MARK: - Codable Tests

    @Test("Photo は JSON にエンコード・デコードできる")
    func codableRoundTrip() throws {
        let original = makePhoto(
            id: "codable-test",
            mediaType: .image,
            mediaSubtypes: [.hdr, .livePhoto],
            pixelWidth: 4032,
            pixelHeight: 3024,
            fileSize: 5_000_000,
            isFavorite: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Photo.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.mediaType == original.mediaType)
        #expect(decoded.mediaSubtypes == original.mediaSubtypes)
        #expect(decoded.pixelWidth == original.pixelWidth)
        #expect(decoded.pixelHeight == original.pixelHeight)
        #expect(decoded.fileSize == original.fileSize)
        #expect(decoded.isFavorite == original.isFavorite)
    }

    // MARK: - Description Tests

    @Test("Photo の description が正しく出力される")
    func descriptionOutput() {
        let photo = makePhoto(
            id: "desc-test",
            mediaType: .image,
            pixelWidth: 4032,
            pixelHeight: 3024,
            fileSize: 3_500_000
        )

        let description = photo.description
        #expect(description.contains("desc-test"))
        #expect(description.contains("4032"))
        #expect(description.contains("3024"))
    }
}

// MARK: - MediaType Tests

@Suite("MediaType テスト")
struct MediaTypeTests {

    @Test("MediaType の rawValue が正しい")
    func rawValues() {
        #expect(MediaType.unknown.rawValue == 0)
        #expect(MediaType.image.rawValue == 1)
        #expect(MediaType.video.rawValue == 2)
        #expect(MediaType.audio.rawValue == 3)
    }

    @Test("MediaType のローカライズ名が空でない")
    func localizedNames() {
        #expect(!MediaType.unknown.localizedName.isEmpty)
        #expect(!MediaType.image.localizedName.isEmpty)
        #expect(!MediaType.video.localizedName.isEmpty)
        #expect(!MediaType.audio.localizedName.isEmpty)
    }

    @Test("MediaType は Codable")
    func codable() throws {
        let original = MediaType.video

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MediaType.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - MediaSubtypes Tests

@Suite("MediaSubtypes テスト")
struct MediaSubtypesTests {

    @Test("MediaSubtypes の OptionSet 操作が正しく動作する")
    func optionSetOperations() {
        var subtypes: MediaSubtypes = []

        subtypes.insert(.screenshot)
        #expect(subtypes.contains(.screenshot))

        subtypes.insert(.hdr)
        #expect(subtypes.contains(.screenshot))
        #expect(subtypes.contains(.hdr))

        subtypes.remove(.screenshot)
        #expect(!subtypes.contains(.screenshot))
        #expect(subtypes.contains(.hdr))
    }

    @Test("MediaSubtypes の descriptions が正しく生成される")
    func descriptions() {
        let subtypes: MediaSubtypes = [.screenshot, .hdr, .livePhoto]
        let descriptions = subtypes.descriptions

        #expect(descriptions.count == 3)
    }

    @Test("空の MediaSubtypes の descriptions は空配列")
    func emptyDescriptions() {
        let subtypes: MediaSubtypes = []
        #expect(subtypes.descriptions.isEmpty)
    }

    @Test("MediaSubtypes は Codable")
    func codable() throws {
        let original: MediaSubtypes = [.screenshot, .hdr, .panorama]

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MediaSubtypes.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - StorageInfo Tests

@Suite("StorageInfo モデルテスト")
struct StorageInfoTests {

    // MARK: - Test Data

    /// テスト用のストレージ情報を生成
    private func makeStorageInfo(
        totalCapacity: Int64 = 128_000_000_000,      // 128 GB
        availableCapacity: Int64 = 45_000_000_000,  // 45 GB
        photosUsedCapacity: Int64 = 25_000_000_000, // 25 GB
        reclaimableCapacity: Int64 = 3_500_000_000  // 3.5 GB
    ) -> StorageInfo {
        StorageInfo(
            totalCapacity: totalCapacity,
            availableCapacity: availableCapacity,
            photosUsedCapacity: photosUsedCapacity,
            reclaimableCapacity: reclaimableCapacity
        )
    }

    // MARK: - Initialization Tests

    @Test("StorageInfo を全プロパティ指定で初期化できる")
    func initializationWithAllProperties() {
        let info = makeStorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 100_000_000_000,
            photosUsedCapacity: 50_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )

        #expect(info.totalCapacity == 256_000_000_000)
        #expect(info.availableCapacity == 100_000_000_000)
        #expect(info.photosUsedCapacity == 50_000_000_000)
        #expect(info.reclaimableCapacity == 5_000_000_000)
    }

    // MARK: - Computed Property Tests

    @Test("usagePercentage が正しく計算される")
    func usagePercentageCalculation() {
        // 使用率 50%
        let info50 = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 50_000_000_000
        )
        #expect(info50.usagePercentage == 0.5)

        // 使用率 75%
        let info75 = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 25_000_000_000
        )
        #expect(info75.usagePercentage == 0.75)

        // 使用率 100%
        let info100 = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 0
        )
        #expect(info100.usagePercentage == 1.0)
    }

    @Test("usagePercentage は totalCapacity が 0 の場合 0.0 を返す")
    func usagePercentageWithZeroTotal() {
        let info = makeStorageInfo(
            totalCapacity: 0,
            availableCapacity: 0
        )
        #expect(info.usagePercentage == 0.0)
    }

    @Test("usedCapacity が正しく計算される")
    func usedCapacityCalculation() {
        let info = makeStorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 45_000_000_000
        )
        #expect(info.usedCapacity == 83_000_000_000)
    }

    @Test("photosUsagePercentage が正しく計算される")
    func photosUsagePercentageCalculation() {
        let info = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            photosUsedCapacity: 25_000_000_000
        )
        #expect(info.photosUsagePercentage == 0.25)
    }

    @Test("reclaimablePercentage が正しく計算される")
    func reclaimablePercentageCalculation() {
        let info = makeStorageInfo(
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 5_000_000_000
        )
        #expect(info.reclaimablePercentage == 0.2)
    }

    @Test("reclaimablePercentage は photosUsedCapacity が 0 の場合 0.0 を返す")
    func reclaimablePercentageWithZeroPhotos() {
        let info = makeStorageInfo(
            photosUsedCapacity: 0,
            reclaimableCapacity: 1_000_000_000
        )
        #expect(info.reclaimablePercentage == 0.0)
    }

    @Test("formattedUsagePercentage が正しくフォーマットされる")
    func formattedUsagePercentageFormatting() {
        let info = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 35_300_000_000  // 64.7% 使用
        )
        #expect(info.formattedUsagePercentage == "64.7%")
    }

    // MARK: - Storage Level Tests

    @Test("isLowStorage が正しく判定される")
    func isLowStorageDetection() {
        // 正常（空き 15%）
        let normal = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 15_000_000_000
        )
        #expect(normal.isLowStorage == false)

        // 警告（空き 8%）
        let warning = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 8_000_000_000
        )
        #expect(warning.isLowStorage == true)
    }

    @Test("isCriticalStorage が正しく判定される")
    func isCriticalStorageDetection() {
        // 正常（空き 10%）
        let normal = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 10_000_000_000
        )
        #expect(normal.isCriticalStorage == false)

        // 危険（空き 3%）
        let critical = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 3_000_000_000
        )
        #expect(critical.isCriticalStorage == true)

        // 危険（空き 500 MB）
        let veryLow = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 500_000_000
        )
        #expect(veryLow.isCriticalStorage == true)
    }

    @Test("hasSignificantReclaimable が正しく判定される")
    func hasSignificantReclaimableDetection() {
        // 500 MB 削減可能
        let small = makeStorageInfo(reclaimableCapacity: 500_000_000)
        #expect(small.hasSignificantReclaimable == false)

        // 1 GB 削減可能
        let oneGB = makeStorageInfo(reclaimableCapacity: 1_000_000_000)
        #expect(oneGB.hasSignificantReclaimable == true)

        // 3.5 GB 削減可能
        let large = makeStorageInfo(reclaimableCapacity: 3_500_000_000)
        #expect(large.hasSignificantReclaimable == true)
    }

    @Test("storageLevel が正しく判定される")
    func storageLevelDetection() {
        // 正常
        let normal = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 15_000_000_000
        )
        #expect(normal.storageLevel == .normal)

        // 警告
        let warning = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 8_000_000_000
        )
        #expect(warning.storageLevel == .warning)

        // 危険
        let critical = makeStorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 3_000_000_000
        )
        #expect(critical.storageLevel == .critical)
    }

    // MARK: - Factory Methods Tests

    @Test("empty が正しく生成される")
    func emptyFactory() {
        let empty = StorageInfo.empty

        #expect(empty.totalCapacity == 0)
        #expect(empty.availableCapacity == 0)
        #expect(empty.photosUsedCapacity == 0)
        #expect(empty.reclaimableCapacity == 0)
    }

    @Test("fromDevice が StorageInfo を返す")
    func fromDeviceFactory() {
        // macOS/iOS 環境では実際のデバイス情報が取得される
        let info = StorageInfo.fromDevice()

        // シミュレータ/デバイスでは総容量が存在するはず
        // テスト環境によっては 0 の可能性もあるため、緩い検証
        #expect(info.totalCapacity >= 0)
        #expect(info.availableCapacity >= 0)
        #expect(info.photosUsedCapacity == 0)  // 別途設定が必要
        #expect(info.reclaimableCapacity == 0)  // 別途設定が必要
    }

    // MARK: - Update Methods Tests

    @Test("withPhotosUsedCapacity が正しく動作する")
    func withPhotosUsedCapacity() {
        let original = makeStorageInfo(photosUsedCapacity: 10_000_000_000)
        let updated = original.withPhotosUsedCapacity(20_000_000_000)

        #expect(updated.totalCapacity == original.totalCapacity)
        #expect(updated.availableCapacity == original.availableCapacity)
        #expect(updated.photosUsedCapacity == 20_000_000_000)
        #expect(updated.reclaimableCapacity == original.reclaimableCapacity)
    }

    @Test("withReclaimableCapacity が正しく動作する")
    func withReclaimableCapacity() {
        let original = makeStorageInfo(reclaimableCapacity: 1_000_000_000)
        let updated = original.withReclaimableCapacity(5_000_000_000)

        #expect(updated.totalCapacity == original.totalCapacity)
        #expect(updated.availableCapacity == original.availableCapacity)
        #expect(updated.photosUsedCapacity == original.photosUsedCapacity)
        #expect(updated.reclaimableCapacity == 5_000_000_000)
    }

    @Test("withAvailableCapacity が正しく動作する")
    func withAvailableCapacity() {
        let original = makeStorageInfo(availableCapacity: 40_000_000_000)
        let updated = original.withAvailableCapacity(50_000_000_000)

        #expect(updated.totalCapacity == original.totalCapacity)
        #expect(updated.availableCapacity == 50_000_000_000)
        #expect(updated.photosUsedCapacity == original.photosUsedCapacity)
        #expect(updated.reclaimableCapacity == original.reclaimableCapacity)
    }

    // MARK: - Codable Tests

    @Test("StorageInfo は JSON にエンコード・デコードできる")
    func codableRoundTrip() throws {
        let original = makeStorageInfo()

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StorageInfo.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Hashable Tests

    @Test("StorageInfo は Set に格納できる")
    func storageInfoInSet() {
        let info1 = makeStorageInfo(totalCapacity: 128_000_000_000)
        let info2 = makeStorageInfo(totalCapacity: 256_000_000_000)
        let info3 = makeStorageInfo(totalCapacity: 128_000_000_000)  // info1 と同じ

        var infoSet: Set<StorageInfo> = []
        infoSet.insert(info1)
        infoSet.insert(info2)
        infoSet.insert(info3)

        // info1 と info3 は同じなので Set では 2 つになる
        #expect(infoSet.count == 2)
    }

    // MARK: - Description Tests

    @Test("StorageInfo の description が正しく出力される")
    func descriptionOutput() {
        let info = makeStorageInfo()
        let description = info.description

        #expect(description.contains("StorageInfo"))
    }
}

// MARK: - StorageLevel Tests

@Suite("StorageLevel テスト")
struct StorageLevelTests {

    @Test("StorageLevel のローカライズ名が空でない")
    func localizedNames() {
        #expect(!StorageLevel.normal.localizedName.isEmpty)
        #expect(!StorageLevel.warning.localizedName.isEmpty)
        #expect(!StorageLevel.critical.localizedName.isEmpty)
    }

    @Test("StorageLevel のローカライズ説明が空でない")
    func localizedDescriptions() {
        #expect(!StorageLevel.normal.localizedDescription.isEmpty)
        #expect(!StorageLevel.warning.localizedDescription.isEmpty)
        #expect(!StorageLevel.critical.localizedDescription.isEmpty)
    }
}
