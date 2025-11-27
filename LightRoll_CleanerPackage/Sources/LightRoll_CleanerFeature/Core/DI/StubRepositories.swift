//
//  StubRepositories.swift
//  LightRoll_CleanerFeature
//
//  Stub Repository実装
//  実際の実装が完了するまでの仮実装として使用
//  Created by AI Assistant
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Stub Photo Repository

/// PhotoRepositoryのスタブ実装
/// 開発中のプレースホルダーとして使用
public final class StubPhotoRepository: PhotoRepositoryProtocol, @unchecked Sendable {

    public init() {}

    public func fetchAllPhotos() async throws -> [PhotoAsset] {
        // スタブ: 空配列を返す
        return []
    }

    public func fetchPhoto(by id: String) async -> PhotoAsset? {
        return nil
    }

    public func deletePhotos(_ photos: [PhotoAsset]) async throws {
        // スタブ: 何もしない
    }

    public func moveToTrash(_ photos: [PhotoAsset]) async throws {
        // スタブ: 何もしない
    }

    public func restoreFromTrash(_ photos: [PhotoAsset]) async throws {
        // スタブ: 何もしない
    }

    #if canImport(UIKit)
    public func fetchThumbnail(for photo: PhotoAsset, size: CGSize) async throws -> UIImage {
        // スタブ: プレースホルダー画像を返す
        return UIImage(systemName: "photo") ?? UIImage()
    }
    #endif
}

// MARK: - Stub Analysis Repository

/// AnalysisRepositoryのスタブ実装
public final class StubAnalysisRepository: AnalysisRepositoryProtocol, @unchecked Sendable {

    public init() {}

    public func analyzePhoto(_ photo: PhotoAsset) async throws -> PhotoAnalysisResult {
        return PhotoAnalysisResult(photoId: photo.id)
    }

    public func findSimilarPhotos(_ photos: [PhotoAsset]) async throws -> [[PhotoAsset]] {
        return []
    }

    public func detectBlurryPhotos(_ photos: [PhotoAsset]) async throws -> [PhotoAsset] {
        return []
    }

    public func detectScreenshots(_ photos: [PhotoAsset]) async -> [PhotoAsset] {
        return []
    }

    public func selectBestShot(from photos: [PhotoAsset]) async -> Int? {
        return photos.isEmpty ? nil : 0
    }
}

// MARK: - Stub Storage Repository

/// StorageRepositoryのスタブ実装
public final class StubStorageRepository: StorageRepositoryProtocol, @unchecked Sendable {

    public init() {}

    public func fetchStorageInfo() async -> StorageInfo {
        // スタブ: ダミーデータを返す
        return StorageInfo(
            totalCapacity: 128 * 1024 * 1024 * 1024,  // 128GB
            usedCapacity: 64 * 1024 * 1024 * 1024,    // 64GB
            photosSize: 16 * 1024 * 1024 * 1024,      // 16GB
            reclaimableSize: 2 * 1024 * 1024 * 1024   // 2GB
        )
    }

    public func calculatePhotosSize(_ photos: [PhotoAsset]) async -> Int64 {
        return photos.reduce(0) { $0 + $1.fileSize }
    }

    public func calculateReclaimableSize(_ photos: [PhotoAsset]) async -> Int64 {
        return photos.reduce(0) { $0 + $1.fileSize }
    }
}

// MARK: - Stub Settings Repository

/// SettingsRepositoryのスタブ実装
public final class StubSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {

    private var settings: UserSettings = .default

    public init() {}

    public func load() -> UserSettings {
        return settings
    }

    public func save(_ settings: UserSettings) {
        self.settings = settings
    }

    public func reset() {
        settings = .default
    }
}

// MARK: - Stub Purchase Repository

/// PurchaseRepositoryのスタブ実装
public final class StubPurchaseRepository: PurchaseRepositoryProtocol, @unchecked Sendable {

    public init() {}

    public func fetchProducts() async throws -> [ProductInfo] {
        return [
            ProductInfo(
                id: "com.lightroll.premium",
                displayName: "プレミアム",
                displayPrice: "¥980"
            )
        ]
    }

    public func purchase(_ productId: String) async throws -> PurchaseResult {
        return .success
    }

    public func restorePurchases() async throws {
        // スタブ: 何もしない
    }

    public func getPremiumStatus() async -> PremiumStatus {
        return .free
    }
}

// MARK: - Mock Repositories (For Testing)

#if DEBUG

/// MockPhotoRepository（テスト用）
public final class MockPhotoRepository: PhotoRepositoryProtocol, @unchecked Sendable {

    public var mockPhotos: [PhotoAsset] = []
    public var fetchAllPhotosCalled = false
    public var deletePhotosCalled = false
    public var deletedPhotos: [PhotoAsset] = []

    public init() {}

    public func fetchAllPhotos() async throws -> [PhotoAsset] {
        fetchAllPhotosCalled = true
        return mockPhotos
    }

    public func fetchPhoto(by id: String) async -> PhotoAsset? {
        return mockPhotos.first { $0.id == id }
    }

    public func deletePhotos(_ photos: [PhotoAsset]) async throws {
        deletePhotosCalled = true
        deletedPhotos = photos
    }

    public func moveToTrash(_ photos: [PhotoAsset]) async throws {
        deletedPhotos = photos
    }

    public func restoreFromTrash(_ photos: [PhotoAsset]) async throws {
        // テスト用
    }

    #if canImport(UIKit)
    public func fetchThumbnail(for photo: PhotoAsset, size: CGSize) async throws -> UIImage {
        return UIImage(systemName: "photo") ?? UIImage()
    }
    #endif
}

/// MockAnalysisRepository（テスト用）
public final class MockAnalysisRepository: AnalysisRepositoryProtocol, @unchecked Sendable {

    public var mockResults: [String: PhotoAnalysisResult] = [:]
    public var mockSimilarGroups: [[PhotoAsset]] = []
    public var mockBlurryPhotos: [PhotoAsset] = []

    public init() {}

    public func analyzePhoto(_ photo: PhotoAsset) async throws -> PhotoAnalysisResult {
        return mockResults[photo.id] ?? PhotoAnalysisResult(photoId: photo.id)
    }

    public func findSimilarPhotos(_ photos: [PhotoAsset]) async throws -> [[PhotoAsset]] {
        return mockSimilarGroups
    }

    public func detectBlurryPhotos(_ photos: [PhotoAsset]) async throws -> [PhotoAsset] {
        return mockBlurryPhotos
    }

    public func detectScreenshots(_ photos: [PhotoAsset]) async -> [PhotoAsset] {
        return photos.filter { mockResults[$0.id]?.isScreenshot == true }
    }

    public func selectBestShot(from photos: [PhotoAsset]) async -> Int? {
        return photos.isEmpty ? nil : 0
    }
}

/// MockStorageRepository（テスト用）
public final class MockStorageRepository: StorageRepositoryProtocol, @unchecked Sendable {

    public var mockStorageInfo: StorageInfo = StorageInfo()

    public init() {}

    public func fetchStorageInfo() async -> StorageInfo {
        return mockStorageInfo
    }

    public func calculatePhotosSize(_ photos: [PhotoAsset]) async -> Int64 {
        return photos.reduce(0) { $0 + $1.fileSize }
    }

    public func calculateReclaimableSize(_ photos: [PhotoAsset]) async -> Int64 {
        return photos.reduce(0) { $0 + $1.fileSize }
    }
}

/// MockSettingsRepository（テスト用）
public final class MockSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {

    public var mockSettings: UserSettings = .default
    public var saveCalled = false
    public var resetCalled = false

    public init() {}

    public func load() -> UserSettings {
        return mockSettings
    }

    public func save(_ settings: UserSettings) {
        saveCalled = true
        mockSettings = settings
    }

    public func reset() {
        resetCalled = true
        mockSettings = .default
    }
}

/// MockPurchaseRepository（テスト用）
public final class MockPurchaseRepository: PurchaseRepositoryProtocol, @unchecked Sendable {

    public var mockProducts: [ProductInfo] = []
    public var mockPremiumStatus: PremiumStatus = .free
    public var purchaseCalled = false
    public var restoreCalled = false

    public init() {}

    public func fetchProducts() async throws -> [ProductInfo] {
        return mockProducts
    }

    public func purchase(_ productId: String) async throws -> PurchaseResult {
        purchaseCalled = true
        return .success
    }

    public func restorePurchases() async throws {
        restoreCalled = true
    }

    public func getPremiumStatus() async -> PremiumStatus {
        return mockPremiumStatus
    }
}

#endif
