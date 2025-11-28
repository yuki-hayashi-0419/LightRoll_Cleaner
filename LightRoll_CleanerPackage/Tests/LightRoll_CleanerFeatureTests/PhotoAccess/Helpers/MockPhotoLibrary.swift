//
//  MockPhotoLibrary.swift
//  LightRoll_CleanerFeatureTests
//
//  テスト用のモックフォトライブラリとファクトリメソッド
//  様々なテストシナリオをシミュレートするためのヘルパー
//  Created by AI Assistant
//

import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

@testable import LightRoll_CleanerFeature

// MARK: - MockPhotoLibrary

/// テスト用のモックフォトライブラリ
/// 様々なシナリオをシミュレートするためのモッククラス
@MainActor
public final class MockPhotoLibrary: Sendable {

    // MARK: - Properties

    /// モック写真データ
    public var mockPhotos: [Photo]

    /// エラーをシミュレートする場合に設定
    public var shouldFailWithError: Error?

    /// 遅延レスポンスをシミュレート（秒）
    public var simulateSlowResponse: TimeInterval

    /// フェッチ呼び出し回数
    public private(set) var fetchCallCount: Int = 0

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - photos: モック写真データ
    ///   - shouldFailWithError: エラーをシミュレートする場合のエラー
    ///   - simulateSlowResponse: 遅延レスポンス時間（秒）
    public init(
        photos: [Photo] = [],
        shouldFailWithError: Error? = nil,
        simulateSlowResponse: TimeInterval = 0
    ) {
        self.mockPhotos = photos
        self.shouldFailWithError = shouldFailWithError
        self.simulateSlowResponse = simulateSlowResponse
    }

    // MARK: - Factory Methods

    /// 空のフォトライブラリを生成
    public static func empty() -> MockPhotoLibrary {
        MockPhotoLibrary(photos: [])
    }

    /// 指定数の写真を持つフォトライブラリを生成
    /// - Parameter count: 写真の数
    /// - Returns: モックフォトライブラリ
    public static func withPhotos(_ count: Int) -> MockPhotoLibrary {
        let photos = generatePhotos(count: count)
        return MockPhotoLibrary(photos: photos)
    }

    /// エラーを返すフォトライブラリを生成
    /// - Parameter error: 返すエラー
    /// - Returns: モックフォトライブラリ
    public static func withError(_ error: Error) -> MockPhotoLibrary {
        MockPhotoLibrary(shouldFailWithError: error)
    }

    /// 遅延レスポンスをシミュレートするフォトライブラリを生成
    /// - Parameters:
    ///   - count: 写真の数
    ///   - delay: 遅延時間（秒）
    /// - Returns: モックフォトライブラリ
    public static func withSlowResponse(count: Int, delay: TimeInterval) -> MockPhotoLibrary {
        let photos = generatePhotos(count: count)
        return MockPhotoLibrary(photos: photos, simulateSlowResponse: delay)
    }

    /// 様々なメディアタイプを含むフォトライブラリを生成
    /// - Parameter count: 写真の数
    /// - Returns: モックフォトライブラリ
    public static func withMixedMediaTypes(count: Int) -> MockPhotoLibrary {
        let photos = generateMixedPhotos(count: count)
        return MockPhotoLibrary(photos: photos)
    }

    /// 大量の写真を持つフォトライブラリを生成
    /// - Returns: モックフォトライブラリ
    public static func large() -> MockPhotoLibrary {
        let photos = generatePhotos(count: 10000)
        return MockPhotoLibrary(photos: photos)
    }

    // MARK: - Photo Generation Helpers

    /// 写真データを生成
    /// - Parameter count: 生成数
    /// - Returns: 写真配列
    private static func generatePhotos(count: Int) -> [Photo] {
        let baseDate = Date()
        return (0..<count).map { index in
            let id = "mock-photo-\(UUID().uuidString)"
            return Photo(
                id: id,
                localIdentifier: id,
                creationDate: baseDate.addingTimeInterval(-Double(index) * 86400),
                modificationDate: baseDate.addingTimeInterval(-Double(index) * 86400),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 3024,
                pixelHeight: 4032,
                duration: 0,
                fileSize: Int64.random(in: 1_000_000...10_000_000),
                isFavorite: index % 10 == 0
            )
        }
    }

    /// 様々なメディアタイプを含む写真データを生成
    /// - Parameter count: 生成数
    /// - Returns: 写真配列
    private static func generateMixedPhotos(count: Int) -> [Photo] {
        let baseDate = Date()
        return (0..<count).map { index in
            let mediaType: MediaType
            let mediaSubtypes: MediaSubtypes
            let duration: TimeInterval
            let pixelWidth: Int
            let pixelHeight: Int

            switch index % 10 {
            case 0, 1:
                // 動画
                mediaType = .video
                mediaSubtypes = []
                duration = Double.random(in: 5...300)
                pixelWidth = 1920
                pixelHeight = 1080
            case 2:
                // スクリーンショット
                mediaType = .image
                mediaSubtypes = [.screenshot]
                duration = 0
                pixelWidth = 1170
                pixelHeight = 2532
            case 3:
                // HDR写真
                mediaType = .image
                mediaSubtypes = [.hdr]
                duration = 0
                pixelWidth = 3024
                pixelHeight = 4032
            case 4:
                // Live Photo
                mediaType = .image
                mediaSubtypes = [.livePhoto]
                duration = 0
                pixelWidth = 3024
                pixelHeight = 4032
            default:
                // 通常の写真
                mediaType = .image
                mediaSubtypes = []
                duration = 0
                pixelWidth = 3024
                pixelHeight = 4032
            }

            let id = "mock-photo-\(UUID().uuidString)"
            return Photo(
                id: id,
                localIdentifier: id,
                creationDate: baseDate.addingTimeInterval(-Double(index) * 3600),
                modificationDate: baseDate.addingTimeInterval(-Double(index) * 3600),
                mediaType: mediaType,
                mediaSubtypes: mediaSubtypes,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                duration: duration,
                fileSize: Int64.random(in: 500_000...20_000_000),
                isFavorite: index % 15 == 0
            )
        }
    }

    // MARK: - Fetch Simulation

    /// 写真をフェッチ（シミュレート）
    /// - Returns: 写真配列
    /// - Throws: 設定されたエラー
    public func fetchPhotos() async throws -> [Photo] {
        fetchCallCount += 1

        // 遅延をシミュレート
        if simulateSlowResponse > 0 {
            try await Task.sleep(for: .seconds(simulateSlowResponse))
        }

        // エラーをシミュレート
        if let error = shouldFailWithError {
            throw error
        }

        return mockPhotos
    }

    /// リセット
    public func reset() {
        fetchCallCount = 0
    }
}

// MARK: - MockPhotoAssetFactory

/// テスト用のPhotoAssetファクトリ
public enum MockPhotoAssetFactory {

    /// 単一のPhotoAssetを生成
    /// - Parameters:
    ///   - id: アセットID
    ///   - fileSize: ファイルサイズ（バイト）
    /// - Returns: PhotoAsset
    public static func create(
        id: String = UUID().uuidString,
        fileSize: Int64 = 3_500_000
    ) -> PhotoAsset {
        PhotoAsset(
            id: id,
            creationDate: Date(),
            fileSize: fileSize
        )
    }

    /// 複数のPhotoAssetを生成
    /// - Parameters:
    ///   - count: 生成数
    ///   - baseSizeBytes: 基本ファイルサイズ
    /// - Returns: PhotoAsset配列
    public static func createBatch(
        count: Int,
        baseSizeBytes: Int64 = 2_000_000
    ) -> [PhotoAsset] {
        (0..<count).map { index in
            PhotoAsset(
                id: "asset-\(index)-\(UUID().uuidString)",
                creationDate: Date().addingTimeInterval(-Double(index) * 3600),
                fileSize: baseSizeBytes + Int64.random(in: 0...1_000_000)
            )
        }
    }

    /// 特定のファイルサイズパターンでPhotoAssetを生成
    /// - Parameter sizes: ファイルサイズの配列
    /// - Returns: PhotoAsset配列
    public static func createWithSizes(_ sizes: [Int64]) -> [PhotoAsset] {
        sizes.enumerated().map { index, size in
            PhotoAsset(
                id: "asset-\(index)",
                creationDate: Date(),
                fileSize: size
            )
        }
    }
}

// MARK: - MockPhotoGroupFactory

/// テスト用のPhotoGroupファクトリ
public enum MockPhotoGroupFactory {

    /// 単一のPhotoGroupを生成
    /// - Parameters:
    ///   - type: グループタイプ
    ///   - photoCount: 写真数
    ///   - bestShotIndex: ベストショットのインデックス
    /// - Returns: PhotoGroup
    public static func create(
        type: GroupType = .similar,
        photoCount: Int = 3,
        bestShotIndex: Int? = 0
    ) -> PhotoGroup {
        let photos = MockPhotoAssetFactory.createBatch(count: photoCount)
        let totalSize = photos.reduce(0) { $0 + $1.fileSize }

        return PhotoGroup(
            id: UUID(),
            type: type,
            photos: photos,
            bestShotIndex: bestShotIndex,
            totalSize: totalSize
        )
    }

    /// 複数のPhotoGroupを生成
    /// - Parameters:
    ///   - count: グループ数
    ///   - photosPerGroup: グループあたりの写真数
    /// - Returns: PhotoGroup配列
    public static func createBatch(
        count: Int,
        photosPerGroup: Int = 3
    ) -> [PhotoGroup] {
        let types: [GroupType] = [.similar, .selfie, .screenshot, .blurry, .largeVideo]
        return (0..<count).map { index in
            create(
                type: types[index % types.count],
                photoCount: photosPerGroup,
                bestShotIndex: 0
            )
        }
    }

    /// 特定の写真を持つPhotoGroupを生成
    /// - Parameters:
    ///   - photos: 写真配列
    ///   - type: グループタイプ
    ///   - bestShotIndex: ベストショットのインデックス
    /// - Returns: PhotoGroup
    public static func createWithPhotos(
        _ photos: [PhotoAsset],
        type: GroupType = .similar,
        bestShotIndex: Int? = 0
    ) -> PhotoGroup {
        let totalSize = photos.reduce(0) { $0 + $1.fileSize }

        return PhotoGroup(
            id: UUID(),
            type: type,
            photos: photos,
            bestShotIndex: bestShotIndex,
            totalSize: totalSize
        )
    }
}

// MARK: - MockStorageInfo

/// テスト用のStorageInfo拡張
extension StorageInfo {

    /// テスト用の低容量StorageInfoを生成
    public static func mockLowStorage() -> StorageInfo {
        StorageInfo(
            totalCapacity: 100_000_000_000, // 100GB
            availableCapacity: 5_000_000_000, // 5GB (5%)
            photosUsedCapacity: 50_000_000_000, // 50GB
            reclaimableCapacity: 10_000_000_000 // 10GB
        )
    }

    /// テスト用の危険な容量状態のStorageInfoを生成
    public static func mockCriticalStorage() -> StorageInfo {
        StorageInfo(
            totalCapacity: 100_000_000_000, // 100GB
            availableCapacity: 2_000_000_000, // 2GB (2%)
            photosUsedCapacity: 60_000_000_000, // 60GB
            reclaimableCapacity: 15_000_000_000 // 15GB
        )
    }

    /// テスト用の正常な容量状態のStorageInfoを生成
    public static func mockNormalStorage() -> StorageInfo {
        StorageInfo(
            totalCapacity: 256_000_000_000, // 256GB
            availableCapacity: 100_000_000_000, // 100GB (~39%)
            photosUsedCapacity: 80_000_000_000, // 80GB
            reclaimableCapacity: 5_000_000_000 // 5GB
        )
    }
}

// MARK: - MockPhotoFactory

/// テスト用のPhotoファクトリ
public enum MockPhotoFactory {

    /// 単一のPhotoを生成
    /// - Parameters:
    ///   - id: ID（nilの場合はUUID生成）
    ///   - mediaType: メディアタイプ
    ///   - isScreenshot: スクリーンショットかどうか
    ///   - fileSize: ファイルサイズ
    ///   - isFavorite: お気に入りかどうか
    /// - Returns: Photo
    public static func create(
        id: String? = nil,
        mediaType: MediaType = .image,
        isScreenshot: Bool = false,
        fileSize: Int64 = 3_500_000,
        isFavorite: Bool = false
    ) -> Photo {
        let photoId = id ?? UUID().uuidString
        let baseDate = Date()
        var mediaSubtypes: MediaSubtypes = []
        if isScreenshot {
            mediaSubtypes.insert(.screenshot)
        }

        return Photo(
            id: photoId,
            localIdentifier: photoId,
            creationDate: baseDate,
            modificationDate: baseDate,
            mediaType: mediaType,
            mediaSubtypes: mediaSubtypes,
            pixelWidth: mediaType == .video ? 1920 : 3024,
            pixelHeight: mediaType == .video ? 1080 : 4032,
            duration: mediaType == .video ? 30.0 : 0,
            fileSize: fileSize,
            isFavorite: isFavorite
        )
    }

    /// 複数のPhotoを生成
    /// - Parameter count: 生成数
    /// - Returns: Photo配列
    public static func createBatch(count: Int) -> [Photo] {
        let baseDate = Date()
        return (0..<count).map { index in
            let id = "photo-\(index)-\(UUID().uuidString)"
            return Photo(
                id: id,
                localIdentifier: id,
                creationDate: baseDate.addingTimeInterval(-Double(index) * 3600),
                modificationDate: baseDate.addingTimeInterval(-Double(index) * 3600),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 3024,
                pixelHeight: 4032,
                duration: 0,
                fileSize: Int64.random(in: 1_000_000...5_000_000),
                isFavorite: false
            )
        }
    }
}

// MARK: - Test Assertion Helpers

/// テスト用のアサーションヘルパー
public enum TestAssertionHelpers {

    /// 写真配列が日付降順でソートされているか確認
    /// - Parameter photos: 写真配列
    /// - Returns: ソートされているかどうか
    public static func isSortedByDateDescending(_ photos: [Photo]) -> Bool {
        guard photos.count > 1 else { return true }

        for i in 0..<(photos.count - 1) {
            if photos[i].creationDate < photos[i + 1].creationDate {
                return false
            }
        }
        return true
    }

    /// 写真配列に動画が含まれていないか確認
    /// - Parameter photos: 写真配列
    /// - Returns: 動画が含まれていないかどうか
    public static func hasNoVideos(_ photos: [Photo]) -> Bool {
        !photos.contains { $0.mediaType == .video }
    }

    /// 写真配列にスクリーンショットが含まれていないか確認
    /// - Parameter photos: 写真配列
    /// - Returns: スクリーンショットが含まれていないかどうか
    public static func hasNoScreenshots(_ photos: [Photo]) -> Bool {
        !photos.contains { $0.isScreenshot }
    }

    /// 進捗値が単調増加しているか確認
    /// - Parameter values: 進捗値配列
    /// - Returns: 単調増加しているかどうか
    public static func isMonotonicallyIncreasing(_ values: [Double]) -> Bool {
        guard values.count > 1 else { return true }

        for i in 0..<(values.count - 1) {
            if values[i] > values[i + 1] {
                return false
            }
        }
        return true
    }
}
