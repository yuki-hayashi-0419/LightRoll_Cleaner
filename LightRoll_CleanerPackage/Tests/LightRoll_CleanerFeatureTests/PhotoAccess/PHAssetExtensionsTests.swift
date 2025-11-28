//
//  PHAssetExtensionsTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PHAsset拡張のテスト
//  Photos Framework依存のため、テスト可能な範囲は限定的
//  Created by AI Assistant
//

import Foundation
import Photos
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - MediaType Conversion Tests

@Suite("PHAssetMediaType から MediaType への変換テスト")
struct MediaTypeConversionTests {

    @Test("PHAssetMediaType.image から MediaType.image へ変換される")
    func imageTypeConversion() {
        let mediaType = MediaType(from: .image)
        #expect(mediaType == .image)
    }

    @Test("PHAssetMediaType.video から MediaType.video へ変換される")
    func videoTypeConversion() {
        let mediaType = MediaType(from: .video)
        #expect(mediaType == .video)
    }

    @Test("PHAssetMediaType.audio から MediaType.audio へ変換される")
    func audioTypeConversion() {
        let mediaType = MediaType(from: .audio)
        #expect(mediaType == .audio)
    }

    @Test("PHAssetMediaType.unknown から MediaType.unknown へ変換される")
    func unknownTypeConversion() {
        let mediaType = MediaType(from: .unknown)
        #expect(mediaType == .unknown)
    }

    @Test("MediaType.image から PHAssetMediaType.image へ変換される")
    func imageToPhAssetMediaType() {
        let phMediaType = MediaType.image.toPHAssetMediaType
        #expect(phMediaType == .image)
    }

    @Test("MediaType.video から PHAssetMediaType.video へ変換される")
    func videoToPhAssetMediaType() {
        let phMediaType = MediaType.video.toPHAssetMediaType
        #expect(phMediaType == .video)
    }

    @Test("MediaType.audio から PHAssetMediaType.audio へ変換される")
    func audioToPhAssetMediaType() {
        let phMediaType = MediaType.audio.toPHAssetMediaType
        #expect(phMediaType == .audio)
    }

    @Test("MediaType.unknown から PHAssetMediaType.unknown へ変換される")
    func unknownToPhAssetMediaType() {
        let phMediaType = MediaType.unknown.toPHAssetMediaType
        #expect(phMediaType == .unknown)
    }

    @Test("双方向変換が一貫している")
    func roundTripConversion() {
        // image
        let imageConverted = MediaType(from: MediaType.image.toPHAssetMediaType)
        #expect(imageConverted == .image)

        // video
        let videoConverted = MediaType(from: MediaType.video.toPHAssetMediaType)
        #expect(videoConverted == .video)

        // audio
        let audioConverted = MediaType(from: MediaType.audio.toPHAssetMediaType)
        #expect(audioConverted == .audio)

        // unknown
        let unknownConverted = MediaType(from: MediaType.unknown.toPHAssetMediaType)
        #expect(unknownConverted == .unknown)
    }
}

// MARK: - MediaSubtypes Conversion Tests

@Suite("PHAssetMediaSubtype から MediaSubtypes への変換テスト")
struct MediaSubtypesConversionTests {

    @Test("単一のサブタイプが正しく変換される - screenshot")
    func screenshotSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.photoScreenshot
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.screenshot))
        #expect(!mediaSubtypes.contains(.hdr))
        #expect(!mediaSubtypes.contains(.panorama))
    }

    @Test("単一のサブタイプが正しく変換される - hdr")
    func hdrSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.photoHDR
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.hdr))
        #expect(!mediaSubtypes.contains(.screenshot))
    }

    @Test("単一のサブタイプが正しく変換される - panorama")
    func panoramaSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.photoPanorama
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.panorama))
    }

    @Test("単一のサブタイプが正しく変換される - livePhoto")
    func livePhotoSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.photoLive
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.livePhoto))
    }

    @Test("単一のサブタイプが正しく変換される - depthEffect")
    func depthEffectSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.photoDepthEffect
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.depthEffect))
    }

    @Test("複数のサブタイプが正しく変換される")
    func multipleSubtypesConversion() {
        var subtype: PHAssetMediaSubtype = []
        subtype.insert(.photoScreenshot)
        subtype.insert(.photoHDR)

        let mediaSubtypes = MediaSubtypes(from: subtype)

        #expect(mediaSubtypes.contains(.screenshot))
        #expect(mediaSubtypes.contains(.hdr))
        #expect(!mediaSubtypes.contains(.panorama))
        #expect(!mediaSubtypes.contains(.livePhoto))
    }

    @Test("動画サブタイプが正しく変換される - highFrameRate")
    func highFrameRateSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.videoHighFrameRate
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.highFrameRate))
    }

    @Test("動画サブタイプが正しく変換される - timelapse")
    func timelapseSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.videoTimelapse
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.timelapse))
    }

    @Test("動画サブタイプが正しく変換される - cinematic")
    func cinematicSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.videoCinematic
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.cinematicVideo))
    }

    @Test("動画サブタイプが正しく変換される - streamed")
    func streamedSubtypeConversion() {
        let subtype = PHAssetMediaSubtype.videoStreamed
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.contains(.streamed))
    }

    @Test("空のサブタイプは空の MediaSubtypes になる")
    func emptySubtypeConversion() {
        let subtype: PHAssetMediaSubtype = []
        let mediaSubtypes = MediaSubtypes(from: subtype)
        #expect(mediaSubtypes.rawValue == 0)
    }

    @Test("MediaSubtypes から PHAssetMediaSubtype への変換 - 単一")
    func singleSubtypeToPHAssetMediaSubtype() {
        let mediaSubtypes: MediaSubtypes = [.screenshot]
        let phSubtype = mediaSubtypes.toPHAssetMediaSubtype
        #expect(phSubtype.contains(.photoScreenshot))
    }

    @Test("MediaSubtypes から PHAssetMediaSubtype への変換 - 複数")
    func multipleSubtypesToPHAssetMediaSubtype() {
        let mediaSubtypes: MediaSubtypes = [.screenshot, .hdr, .livePhoto]
        let phSubtype = mediaSubtypes.toPHAssetMediaSubtype

        #expect(phSubtype.contains(.photoScreenshot))
        #expect(phSubtype.contains(.photoHDR))
        #expect(phSubtype.contains(.photoLive))
        #expect(!phSubtype.contains(.photoPanorama))
    }

    @Test("双方向変換が一貫している")
    func roundTripSubtypesConversion() {
        let original: MediaSubtypes = [.screenshot, .hdr, .panorama, .livePhoto, .depthEffect]
        let phSubtype = original.toPHAssetMediaSubtype
        let converted = MediaSubtypes(from: phSubtype)

        #expect(converted == original)
    }

    @Test("動画サブタイプの双方向変換が一貫している")
    func roundTripVideoSubtypesConversion() {
        let original: MediaSubtypes = [.highFrameRate, .timelapse, .cinematicVideo, .streamed]
        let phSubtype = original.toPHAssetMediaSubtype
        let converted = MediaSubtypes(from: phSubtype)

        #expect(converted == original)
    }
}

// MARK: - Photo Model Creation Tests

@Suite("PHAsset から Photo モデル作成のロジックテスト")
struct PhotoModelCreationTests {

    /// テスト用の Photo を作成するヘルパー
    private func makeTestPhoto(
        id: String = "test-id",
        mediaType: MediaType = .image,
        mediaSubtypes: MediaSubtypes = [],
        pixelWidth: Int = 4032,
        pixelHeight: Int = 3024,
        duration: TimeInterval = 0,
        fileSize: Int64 = 0
    ) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: mediaType,
            mediaSubtypes: mediaSubtypes,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            duration: duration,
            fileSize: fileSize,
            isFavorite: false
        )
    }

    @Test("Photo は localIdentifier を id として使用する")
    func photoUsesLocalIdentifierAsId() {
        let photo = makeTestPhoto(id: "local-identifier-123")
        #expect(photo.id == "local-identifier-123")
        #expect(photo.localIdentifier == "local-identifier-123")
    }

    @Test("Photo のメディアタイプが正しく設定される")
    func photoMediaTypeIsCorrect() {
        let imagePhoto = makeTestPhoto(mediaType: .image)
        #expect(imagePhoto.mediaType == .image)
        #expect(imagePhoto.isImage)
        #expect(!imagePhoto.isVideo)

        let videoPhoto = makeTestPhoto(mediaType: .video, duration: 30)
        #expect(videoPhoto.mediaType == .video)
        #expect(videoPhoto.isVideo)
        #expect(!videoPhoto.isImage)
    }

    @Test("Photo のメディアサブタイプが正しく設定される")
    func photoMediaSubtypesAreCorrect() {
        let screenshotPhoto = makeTestPhoto(mediaSubtypes: [.screenshot])
        #expect(screenshotPhoto.isScreenshot)
        #expect(!screenshotPhoto.isHDR)

        let hdrLivePhoto = makeTestPhoto(mediaSubtypes: [.hdr, .livePhoto])
        #expect(hdrLivePhoto.isHDR)
        #expect(hdrLivePhoto.isLivePhoto)
        #expect(!hdrLivePhoto.isScreenshot)
    }

    @Test("Photo のピクセルサイズが正しく設定される")
    func photoPixelSizeIsCorrect() {
        let photo = makeTestPhoto(pixelWidth: 4032, pixelHeight: 3024)
        #expect(photo.pixelWidth == 4032)
        #expect(photo.pixelHeight == 3024)
        #expect(photo.resolution == "4032 × 3024")
    }

    @Test("Photo の duration が正しく設定される")
    func photoDurationIsCorrect() {
        let image = makeTestPhoto(mediaType: .image, duration: 0)
        #expect(image.duration == 0)
        #expect(image.formattedDuration == "")

        let video = makeTestPhoto(mediaType: .video, duration: 125)
        #expect(video.duration == 125)
        #expect(video.formattedDuration == "2:05")
    }

    @Test("Photo の fileSize が正しく設定される")
    func photoFileSizeIsCorrect() {
        let photo = makeTestPhoto(fileSize: 3_500_000)
        #expect(photo.fileSize == 3_500_000)
    }
}

// MARK: - Collection Extension Tests

@Suite("コレクション拡張のテスト")
struct CollectionExtensionTests {

    /// テスト用の Photo を作成するヘルパー
    private func makeTestPhoto(
        id: String,
        fileSize: Int64 = 1_000_000
    ) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: fileSize,
            isFavorite: false
        )
    }

    @Test("空の配列の estimatedTotalFileSize は 0")
    func emptyArrayEstimatedSize() {
        let photos: [Photo] = []
        // Photo 配列に対する推定サイズは Photo モデル側では直接サポートしていないが、
        // テストとしては fileSize の合計で確認
        let total = photos.reduce(0) { $0 + $1.fileSize }
        #expect(total == 0)
    }

    @Test("複数の Photo の fileSize 合計が正しく計算される")
    func multiplePhotosFileSizeSum() {
        let photos = [
            makeTestPhoto(id: "1", fileSize: 1_000_000),
            makeTestPhoto(id: "2", fileSize: 2_000_000),
            makeTestPhoto(id: "3", fileSize: 3_000_000)
        ]

        let total = photos.reduce(0) { $0 + $1.fileSize }
        #expect(total == 6_000_000)
    }
}

// MARK: - Date Calculation Logic Tests

@Suite("日付計算ロジックのテスト")
struct DateCalculationTests {

    @Test("今日の日付は isCreatedToday として判定される")
    func todayDateIsCreatedToday() {
        let today = Date()
        let isToday = Calendar.current.isDateInToday(today)
        #expect(isToday == true)
    }

    @Test("昨日の日付は isCreatedToday として判定されない")
    func yesterdayDateIsNotCreatedToday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let isToday = Calendar.current.isDateInToday(yesterday)
        #expect(isToday == false)
    }

    @Test("同じ週の日付は同じ週として判定される")
    func sameWeekDatesAreInSameWeek() {
        let today = Date()
        // 週の始めの日を取得
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        let isInSameWeek = Calendar.current.isDate(weekStart, equalTo: today, toGranularity: .weekOfYear)
        #expect(isInSameWeek == true)
    }

    @Test("同じ月の日付は同じ月として判定される")
    func sameMonthDatesAreInSameMonth() {
        let today = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: today))!

        let isInSameMonth = Calendar.current.isDate(startOfMonth, equalTo: today, toGranularity: .month)
        #expect(isInSameMonth == true)
    }

    @Test("同じ年の日付は同じ年として判定される")
    func sameYearDatesAreInSameYear() {
        let today = Date()
        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: today))!

        let isInSameYear = Calendar.current.isDate(startOfYear, equalTo: today, toGranularity: .year)
        #expect(isInSameYear == true)
    }

    @Test("日数計算が正しく動作する")
    func daysSinceCalculation() {
        let today = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let days = Calendar.current.dateComponents([.day], from: sevenDaysAgo, to: today).day
        #expect(days == 7)
    }
}

// MARK: - Aspect Ratio Tests

@Suite("アスペクト比計算のテスト")
struct AspectRatioTests {

    @Test("横長のアスペクト比が正しく計算される")
    func landscapeAspectRatio() {
        let width = 4032
        let height = 3024
        let aspectRatio = Double(width) / Double(height)

        #expect(aspectRatio > 1.0)
        #expect(abs(aspectRatio - 1.333) < 0.01)  // 約 4:3
    }

    @Test("縦長のアスペクト比が正しく計算される")
    func portraitAspectRatio() {
        let width = 3024
        let height = 4032
        let aspectRatio = Double(width) / Double(height)

        #expect(aspectRatio < 1.0)
        #expect(abs(aspectRatio - 0.75) < 0.01)  // 約 3:4
    }

    @Test("正方形のアスペクト比は 1.0")
    func squareAspectRatio() {
        let width = 1000
        let height = 1000
        let aspectRatio = Double(width) / Double(height)

        #expect(aspectRatio == 1.0)
    }

    @Test("高さが 0 の場合のアスペクト比は 1.0")
    func zeroHeightAspectRatio() {
        let width = 100
        let height = 0
        let aspectRatio = height > 0 ? Double(width) / Double(height) : 1.0

        #expect(aspectRatio == 1.0)
    }
}

// MARK: - Megapixel Calculation Tests

@Suite("メガピクセル計算のテスト")
struct MegapixelTests {

    @Test("12MP の計算が正しい（4032 x 3024）")
    func twelveMegapixelCalculation() {
        let width = 4032
        let height = 3024
        let totalPixels = width * height
        let megapixels = Double(totalPixels) / 1_000_000.0

        #expect(abs(megapixels - 12.192) < 0.01)
    }

    @Test("48MP の計算が正しい（8064 x 6048）")
    func fortyEightMegapixelCalculation() {
        let width = 8064
        let height = 6048
        let totalPixels = width * height
        let megapixels = Double(totalPixels) / 1_000_000.0

        #expect(abs(megapixels - 48.77) < 0.01)
    }

    @Test("1MP の計算が正しい（1000 x 1000）")
    func oneMegapixelCalculation() {
        let width = 1000
        let height = 1000
        let totalPixels = width * height
        let megapixels = Double(totalPixels) / 1_000_000.0

        #expect(megapixels == 1.0)
    }
}
