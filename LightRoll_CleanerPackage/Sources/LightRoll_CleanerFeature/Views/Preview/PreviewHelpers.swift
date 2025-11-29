//
//  PreviewHelpers.swift
//  LightRoll_CleanerFeature
//
//  SwiftUI Preview用のモックデータとヘルパー関数
//  全UIコンポーネントのプレビュー環境を整備
//  Created by AI Assistant (M4-T14)
//

import Foundation

// MARK: - MockPhoto

/// Photo型のサンプルデータ生成
public enum MockPhoto: Sendable {

    /// 標準的な写真（4032×3024、2.5MB）
    public static var standard: Photo {
        Photo(
            id: "mock-photo-standard",
            localIdentifier: "mock-local-standard",
            creationDate: Date().addingTimeInterval(-86400), // 1日前
            modificationDate: Date().addingTimeInterval(-86400),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 2_500_000,
            isFavorite: false
        )
    }

    /// 高解像度写真（8000×6000、15MB）
    public static var highResolution: Photo {
        Photo(
            id: "mock-photo-high-res",
            localIdentifier: "mock-local-high-res",
            creationDate: Date().addingTimeInterval(-172800), // 2日前
            modificationDate: Date().addingTimeInterval(-172800),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 8000,
            pixelHeight: 6000,
            duration: 0,
            fileSize: 15_000_000,
            isFavorite: true
        )
    }

    /// スクリーンショット
    public static var screenshot: Photo {
        Photo(
            id: "mock-photo-screenshot",
            localIdentifier: "mock-local-screenshot",
            creationDate: Date().addingTimeInterval(-7200), // 2時間前
            modificationDate: Date().addingTimeInterval(-7200),
            mediaType: .image,
            mediaSubtypes: MediaSubtypes(rawValue: MediaSubtypes.screenshot.rawValue),
            pixelWidth: 1170,
            pixelHeight: 2532,
            duration: 0,
            fileSize: 850_000,
            isFavorite: false
        )
    }

    /// HDR写真
    public static var hdr: Photo {
        Photo(
            id: "mock-photo-hdr",
            localIdentifier: "mock-local-hdr",
            creationDate: Date().addingTimeInterval(-259200), // 3日前
            modificationDate: Date().addingTimeInterval(-259200),
            mediaType: .image,
            mediaSubtypes: MediaSubtypes(rawValue: MediaSubtypes.hdr.rawValue),
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 3_200_000,
            isFavorite: false
        )
    }

    /// パノラマ写真
    public static var panorama: Photo {
        Photo(
            id: "mock-photo-panorama",
            localIdentifier: "mock-local-panorama",
            creationDate: Date().addingTimeInterval(-345600), // 4日前
            modificationDate: Date().addingTimeInterval(-345600),
            mediaType: .image,
            mediaSubtypes: MediaSubtypes(rawValue: MediaSubtypes.panorama.rawValue),
            pixelWidth: 12000,
            pixelHeight: 3000,
            duration: 0,
            fileSize: 8_500_000,
            isFavorite: true
        )
    }

    /// Live Photo
    public static var livePhoto: Photo {
        Photo(
            id: "mock-photo-live",
            localIdentifier: "mock-local-live",
            creationDate: Date().addingTimeInterval(-432000), // 5日前
            modificationDate: Date().addingTimeInterval(-432000),
            mediaType: .image,
            mediaSubtypes: MediaSubtypes(rawValue: MediaSubtypes.livePhoto.rawValue),
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 3_800_000,
            isFavorite: false
        )
    }

    /// 動画（45秒、15MB）
    public static var video: Photo {
        Photo(
            id: "mock-photo-video",
            localIdentifier: "mock-local-video",
            creationDate: Date().addingTimeInterval(-518400), // 6日前
            modificationDate: Date().addingTimeInterval(-518400),
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 45.5,
            fileSize: 15_000_000,
            isFavorite: false
        )
    }

    /// 短い動画（10秒、3MB）
    public static var shortVideo: Photo {
        Photo(
            id: "mock-photo-short-video",
            localIdentifier: "mock-local-short-video",
            creationDate: Date().addingTimeInterval(-604800), // 7日前
            modificationDate: Date().addingTimeInterval(-604800),
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 10.2,
            fileSize: 3_200_000,
            isFavorite: false
        )
    }

    /// タイムラプス動画
    public static var timelapse: Photo {
        Photo(
            id: "mock-photo-timelapse",
            localIdentifier: "mock-local-timelapse",
            creationDate: Date().addingTimeInterval(-691200), // 8日前
            modificationDate: Date().addingTimeInterval(-691200),
            mediaType: .video,
            mediaSubtypes: MediaSubtypes(rawValue: MediaSubtypes.timelapse.rawValue),
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 30.0,
            fileSize: 12_500_000,
            isFavorite: true
        )
    }

    /// 複数のサンプル写真を生成（グリッド表示用）
    /// - Parameter count: 生成する写真の数
    /// - Returns: Photo配列
    public static func multiple(count: Int) -> [Photo] {
        var photos: [Photo] = []
        let baseDate = Date()

        for i in 0..<count {
            let photo = Photo(
                id: "mock-photo-\(i)",
                localIdentifier: "mock-local-\(i)",
                creationDate: baseDate.addingTimeInterval(TimeInterval(-i * 3600)),
                modificationDate: baseDate.addingTimeInterval(TimeInterval(-i * 3600)),
                mediaType: i % 5 == 0 ? .video : .image,
                mediaSubtypes: i % 3 == 0 ? MediaSubtypes(rawValue: MediaSubtypes.screenshot.rawValue) : [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: i % 5 == 0 ? 30.0 : 0,
                fileSize: Int64(1_000_000 + (i * 100_000)),
                isFavorite: i % 7 == 0
            )
            photos.append(photo)
        }

        return photos
    }
}

// MARK: - MockPhotoGroup

/// PhotoGroup型のサンプルデータ生成
public enum MockPhotoGroup: Sendable {

    /// 類似写真グループ（5枚）
    public static var similarPhotos: PhotoGroup {
        let photos = MockPhoto.multiple(count: 5)
        return PhotoGroup(
            type: .similar,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize },
            bestShotIndex: 2,
            isSelected: false,
            similarityScore: 0.92
        )
    }

    /// 自撮りグループ（3枚）
    public static var selfies: PhotoGroup {
        let photos = [MockPhoto.standard, MockPhoto.highResolution, MockPhoto.hdr]
        return PhotoGroup(
            type: .selfie,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize },
            bestShotIndex: 1,
            isSelected: false
        )
    }

    /// スクリーンショットグループ（8枚）
    public static var screenshots: PhotoGroup {
        let photos: [Photo] = (0..<8).map { i -> Photo in
            let offset = TimeInterval(-i * 7200)
            let timestamp = Date().addingTimeInterval(offset)
            let subtypes = MediaSubtypes(rawValue: MediaSubtypes.screenshot.rawValue)
            let size = Int64(850_000 + (i * 50_000))

            return Photo(
                id: "mock-screenshot-\(i)",
                localIdentifier: "mock-local-screenshot-\(i)",
                creationDate: timestamp,
                modificationDate: timestamp,
                mediaType: .image,
                mediaSubtypes: subtypes,
                pixelWidth: 1170,
                pixelHeight: 2532,
                duration: 0,
                fileSize: size,
                isFavorite: false
            )
        }
        return PhotoGroup(
            type: .screenshot,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize },
            isSelected: false
        )
    }

    /// ブレ写真グループ（4枚）
    public static var blurryPhotos: PhotoGroup {
        let photos = MockPhoto.multiple(count: 4)
        return PhotoGroup(
            type: .blurry,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize },
            isSelected: true
        )
    }

    /// 大容量動画グループ（3本）
    public static var largeVideos: PhotoGroup {
        let photos = [MockPhoto.video, MockPhoto.timelapse]
        return PhotoGroup(
            type: .largeVideo,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize },
            isSelected: false
        )
    }

    /// 重複写真グループ（2枚）
    public static var duplicates: PhotoGroup {
        let photo1 = MockPhoto.standard
        let photo2 = Photo(
            id: "mock-photo-duplicate",
            localIdentifier: "mock-local-duplicate",
            creationDate: photo1.creationDate,
            modificationDate: photo1.modificationDate,
            mediaType: photo1.mediaType,
            mediaSubtypes: photo1.mediaSubtypes,
            pixelWidth: photo1.pixelWidth,
            pixelHeight: photo1.pixelHeight,
            duration: photo1.duration,
            fileSize: photo1.fileSize,
            isFavorite: false
        )
        return PhotoGroup(
            type: .duplicate,
            photoIds: [photo1.id, photo2.id],
            fileSizes: [photo1.fileSize, photo2.fileSize],
            bestShotIndex: 0,
            isSelected: false,
            similarityScore: 1.0
        )
    }

    /// 複数のグループを生成（ダッシュボード表示用）
    /// - Returns: PhotoGroup配列
    public static func multipleGroups() -> [PhotoGroup] {
        [
            duplicates,
            similarPhotos,
            blurryPhotos,
            screenshots,
            selfies,
            largeVideos
        ]
    }
}

// MARK: - MockStorageInfo

/// StorageInfo型のサンプルデータ生成
public enum MockStorageInfo: Sendable {

    /// 標準的なストレージ情報（128GB、空き45GB）
    public static var standard: StorageInfo {
        StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 45_000_000_000,
            photosUsedCapacity: 25_300_000_000,
            reclaimableCapacity: 3_500_000_000
        )
    }

    /// 空き容量が少ない状態（128GB、空き8GB）
    public static var lowStorage: StorageInfo {
        StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 8_000_000_000,
            photosUsedCapacity: 35_000_000_000,
            reclaimableCapacity: 5_200_000_000
        )
    }

    /// 空き容量が非常に少ない状態（128GB、空き2GB）
    public static var criticalStorage: StorageInfo {
        StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 2_000_000_000,
            photosUsedCapacity: 42_000_000_000,
            reclaimableCapacity: 8_500_000_000
        )
    }

    /// 大容量デバイス（512GB、空き200GB）
    public static var largeCapacity: StorageInfo {
        StorageInfo(
            totalCapacity: 512_000_000_000,
            availableCapacity: 200_000_000_000,
            photosUsedCapacity: 80_000_000_000,
            reclaimableCapacity: 12_000_000_000
        )
    }

    /// ほぼ空の状態（256GB、空き240GB）
    public static var mostlyEmpty: StorageInfo {
        StorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 240_000_000_000,
            photosUsedCapacity: 5_000_000_000,
            reclaimableCapacity: 500_000_000
        )
    }
}

// MARK: - MockAnalysisResult

/// PhotoAnalysisResult型のサンプルデータ生成
public enum MockAnalysisResult: Sendable {

    /// 高品質な写真の分析結果
    public static var highQuality: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: MockPhoto.standard.id,
            qualityScore: 0.85,
            blurScore: 0.15,
            brightnessScore: 0.55,
            contrastScore: 0.70,
            saturationScore: 0.65,
            faceCount: 2,
            faceQualityScores: [0.80, 0.75],
            faceAngles: [
                FaceAngle(yaw: 5, pitch: -2, roll: 1),
                FaceAngle(yaw: -8, pitch: 3, roll: -1)
            ],
            isScreenshot: false,
            isSelfie: false,
            featurePrintHash: Data([1, 2, 3, 4, 5])
        )
    }

    /// ブレている写真の分析結果
    public static var blurry: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: "mock-blurry-photo",
            qualityScore: 0.35,
            blurScore: 0.65,
            brightnessScore: 0.50,
            contrastScore: 0.40,
            saturationScore: 0.50,
            faceCount: 1,
            faceQualityScores: [0.30],
            faceAngles: [FaceAngle(yaw: 15, pitch: -10, roll: 5)],
            isScreenshot: false,
            isSelfie: false,
            featurePrintHash: Data([6, 7, 8, 9, 10])
        )
    }

    /// 自撮り写真の分析結果
    public static var selfie: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: "mock-selfie-photo",
            qualityScore: 0.75,
            blurScore: 0.20,
            brightnessScore: 0.60,
            contrastScore: 0.65,
            saturationScore: 0.70,
            faceCount: 1,
            faceQualityScores: [0.85],
            faceAngles: [FaceAngle(yaw: 0, pitch: 5, roll: 0)],
            isScreenshot: false,
            isSelfie: true,
            featurePrintHash: Data([11, 12, 13, 14, 15])
        )
    }

    /// スクリーンショットの分析結果
    public static var screenshot: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: MockPhoto.screenshot.id,
            qualityScore: 0.90,
            blurScore: 0.05,
            brightnessScore: 0.75,
            contrastScore: 0.80,
            saturationScore: 0.60,
            faceCount: 0,
            faceQualityScores: [],
            faceAngles: [],
            isScreenshot: true,
            isSelfie: false,
            featurePrintHash: Data([16, 17, 18, 19, 20])
        )
    }

    /// 露出オーバーの写真の分析結果
    public static var overexposed: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: "mock-overexposed-photo",
            qualityScore: 0.45,
            blurScore: 0.10,
            brightnessScore: 0.92,
            contrastScore: 0.30,
            saturationScore: 0.40,
            faceCount: 0,
            faceQualityScores: [],
            faceAngles: [],
            isScreenshot: false,
            isSelfie: false,
            featurePrintHash: Data([21, 22, 23, 24, 25])
        )
    }

    /// 露出アンダーの写真の分析結果
    public static var underexposed: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: "mock-underexposed-photo",
            qualityScore: 0.40,
            blurScore: 0.15,
            brightnessScore: 0.15,
            contrastScore: 0.25,
            saturationScore: 0.35,
            faceCount: 0,
            faceQualityScores: [],
            faceAngles: [],
            isScreenshot: false,
            isSelfie: false,
            featurePrintHash: Data([26, 27, 28, 29, 30])
        )
    }

    /// 複数人の顔がある写真の分析結果
    public static var multipleFaces: PhotoAnalysisResult {
        PhotoAnalysisResult(
            photoId: "mock-multi-face-photo",
            qualityScore: 0.80,
            blurScore: 0.12,
            brightnessScore: 0.58,
            contrastScore: 0.68,
            saturationScore: 0.72,
            faceCount: 4,
            faceQualityScores: [0.85, 0.78, 0.82, 0.70],
            faceAngles: [
                FaceAngle(yaw: 2, pitch: 0, roll: 0),
                FaceAngle(yaw: -5, pitch: 3, roll: 1),
                FaceAngle(yaw: 8, pitch: -2, roll: -1),
                FaceAngle(yaw: 25, pitch: 10, roll: 5)
            ],
            isScreenshot: false,
            isSelfie: false,
            featurePrintHash: Data([31, 32, 33, 34, 35])
        )
    }
}
