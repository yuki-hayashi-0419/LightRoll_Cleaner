//
//  TrashManager.swift
//  LightRoll_CleanerFeature
//
//  ゴミ箱管理の高レベルAPI
//  TrashDataStoreを使用してゴミ箱の操作を提供
//  Created by AI Assistant
//

import Foundation
import Observation
import Photos
#if canImport(UIKit)
import UIKit
/// プラットフォーム共通の画像型
typealias PlatformImage = UIImage
#else
import AppKit
/// プラットフォーム共通の画像型
typealias PlatformImage = NSImage
#endif

// MARK: - TrashManager

/// ゴミ箱マネージャーの実装
/// TrashDataStoreを使用してゴミ箱機能を管理
/// @Observable により状態変更を自動追跡
@Observable
public final class TrashManager: TrashManagerProtocol {

    // MARK: - Properties

    /// データストア（actor分離）
    private let dataStore: any TrashDataStoreProtocol

    /// キャッシュされたゴミ箱写真（パフォーマンス最適化）
    private var cachedPhotos: [TrashPhoto] = []

    /// キャッシュの有効期限
    private var cacheExpiration: Date?

    /// キャッシュの有効期間（秒）
    private let cacheLifetime: TimeInterval = 30.0

    /// 保持日数（デフォルト30日）
    private let retentionDays: Int

    /// サムネイルサイズ（ポイント）
    private static let thumbnailSizePoints: CGFloat = 200.0

    // MARK: - Computed Properties

    /// ゴミ箱内の写真数
    public var trashCount: Int {
        get async {
            do {
                let photos = try await dataStore.loadAll()
                return photos.count
            } catch {
                return 0
            }
        }
    }

    /// ゴミ箱内の写真が使用している容量
    public var trashSize: Int64 {
        get async {
            do {
                let photos = try await dataStore.loadAll()
                return photos.reduce(0) { $0 + $1.fileSize }
            } catch {
                return 0
            }
        }
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - dataStore: データストア（デフォルトは実装インスタンス）
    ///   - retentionDays: 保持日数（デフォルト30日）
    public init(
        dataStore: any TrashDataStoreProtocol = try! TrashDataStore(),
        retentionDays: Int = TrashPhoto.defaultRetentionDays
    ) {
        self.dataStore = dataStore
        self.retentionDays = retentionDays
    }

    // MARK: - Public Methods

    /// ゴミ箱内の全写真を取得
    /// - Returns: ゴミ箱内の写真配列
    public func fetchAllTrashPhotos() async -> [TrashPhoto] {
        // キャッシュが有効な場合はそれを返す
        if let expiration = cacheExpiration,
           Date() < expiration {
            return cachedPhotos
        }

        do {
            let photos = try await dataStore.loadAll()
            updateCache(photos)
            return photos
        } catch {
            // エラー時は空配列を返す（UIは影響を受けない）
            return []
        }
    }

    /// 写真をゴミ箱に移動
    /// サムネイル生成を含む非同期処理
    /// - Parameters:
    ///   - photos: 移動する写真
    ///   - reason: 削除理由（オプション）
    public func moveToTrash(
        _ photos: [Photo],
        reason: TrashPhoto.DeletionReason? = nil
    ) async throws {
        guard !photos.isEmpty else { return }

        let now = Date()
        let expirationDate = Calendar.current.date(
            byAdding: .day,
            value: retentionDays,
            to: now
        ) ?? now.addingTimeInterval(TimeInterval(retentionDays * 86400))

        // PhotoからTrashPhotoへ変換（非同期でサムネイル生成）
        var trashPhotos: [TrashPhoto] = []
        trashPhotos.reserveCapacity(photos.count)

        for photo in photos {
            if let trashPhoto = await createTrashPhoto(
                from: photo,
                deletedAt: now,
                expiresAt: expirationDate,
                reason: reason
            ) {
                trashPhotos.append(trashPhoto)
            }
        }

        // バッチ追加
        try await dataStore.addBatch(trashPhotos)

        // キャッシュを無効化
        invalidateCache()
    }

    /// ゴミ箱から復元
    /// - Parameter photos: 復元する写真
    public func restore(_ photos: [TrashPhoto]) async throws {
        guard !photos.isEmpty else { return }

        // 期限切れチェック
        let expiredPhotos = photos.filter { $0.isExpired }
        if !expiredPhotos.isEmpty {
            throw TrashPhotoError.photoExpired(
                photoId: expiredPhotos.first!.originalPhotoId
            )
        }

        // ゴミ箱から削除
        let ids = photos.map { $0.id }
        try await dataStore.removeBatch(ids: ids)

        // キャッシュを無効化
        invalidateCache()
    }

    /// ゴミ箱から完全削除
    /// - Parameter photos: 削除する写真
    public func permanentlyDelete(_ photos: [TrashPhoto]) async throws {
        guard !photos.isEmpty else { return }

        // ゴミ箱から削除
        let ids = photos.map { $0.id }
        try await dataStore.removeBatch(ids: ids)

        // キャッシュを無効化
        invalidateCache()
    }

    /// 期限切れの写真を自動削除
    /// - Returns: 削除された写真数
    @discardableResult
    public func cleanupExpired() async -> Int {
        do {
            let deletedCount = try await dataStore.removeExpiredPhotos()

            if deletedCount > 0 {
                // キャッシュを無効化
                invalidateCache()
            }

            return deletedCount
        } catch {
            // エラー時は0を返す
            return 0
        }
    }

    /// ゴミ箱を空にする
    public func emptyTrash() async throws {
        try await dataStore.removeAll()

        // キャッシュをクリア
        cachedPhotos.removeAll()
        cacheExpiration = nil
    }

    // MARK: - Private Methods

    /// PhotoからTrashPhotoを作成（非同期版）
    /// サムネイルをPHImageManagerから取得
    /// - Parameters:
    ///   - photo: 元の写真
    ///   - deletedAt: 削除日時
    ///   - expiresAt: 有効期限
    ///   - reason: 削除理由
    /// - Returns: TrashPhoto（作成失敗時はnil）
    private func createTrashPhoto(
        from photo: Photo,
        deletedAt: Date,
        expiresAt: Date,
        reason: TrashPhoto.DeletionReason?
    ) async -> TrashPhoto? {
        // サムネイルデータの取得（非同期）
        let thumbnailData = await generateThumbnailData(for: photo.localIdentifier)

        // メタデータの構築
        let metadata = TrashPhotoMetadata(
            creationDate: photo.creationDate,
            pixelWidth: photo.pixelWidth,
            pixelHeight: photo.pixelHeight,
            mediaType: photo.mediaType,
            mediaSubtypes: photo.mediaSubtypes,
            isFavorite: photo.isFavorite
        )

        return TrashPhoto(
            id: UUID(),
            originalPhotoId: photo.localIdentifier,
            originalAssetIdentifier: photo.localIdentifier,
            thumbnailData: thumbnailData,
            deletedAt: deletedAt,
            expiresAt: expiresAt,
            fileSize: photo.fileSize,
            metadata: metadata,
            deletionReason: reason
        )
    }

    /// PHImageManagerを使用してサムネイルDataを生成
    /// - Parameter localIdentifier: PHAssetのlocalIdentifier
    /// - Returns: JPEG形式のサムネイルData（失敗時はnil）
    private func generateThumbnailData(for localIdentifier: String) async -> Data? {
        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            return nil
        }

        // サムネイルサイズを計算（Retina対応: 2x）
        let scale: CGFloat = 2.0
        let thumbnailSize = CGSize(
            width: Self.thumbnailSizePoints * scale,
            height: Self.thumbnailSizePoints * scale
        )

        // 画像リクエストオプションの設定
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // withCheckedContinuationを使用して非同期処理をラップ
        let image: PlatformImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // キャンセルされた場合
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    continuation.resume(returning: nil)
                    return
                }

                // エラーチェック
                if info?[PHImageErrorKey] as? Error != nil {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: image)
            }
        }

        // 画像をJPEGデータに変換
        guard let image = image else {
            return nil
        }

        #if canImport(UIKit)
        return image.jpegData(compressionQuality: 0.8)
        #else
        // macOS対応（必要に応じて）
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        #endif
    }

    /// キャッシュを更新
    /// - Parameter photos: 新しい写真配列
    private func updateCache(_ photos: [TrashPhoto]) {
        cachedPhotos = photos
        cacheExpiration = Date().addingTimeInterval(cacheLifetime)
    }

    /// キャッシュを無効化
    private func invalidateCache() {
        cacheExpiration = nil
    }
}

// MARK: - Batch Operations Extension

extension TrashManager {

    /// 複数の写真を削除理由別に移動
    /// - Parameter photosByReason: 削除理由ごとの写真辞書
    public func moveToTrashBatch(
        _ photosByReason: [TrashPhoto.DeletionReason: [Photo]]
    ) async throws {
        for (reason, photos) in photosByReason {
            try await moveToTrash(photos, reason: reason)
        }
    }

    /// ゴミ箱内の統計情報を取得
    /// - Returns: 統計情報
    public func getStatistics() async -> TrashPhotoStatistics {
        let photos = await fetchAllTrashPhotos()
        return photos.statistics
    }
}

// MARK: - Filter & Sort Extension

extension TrashManager {

    /// 削除理由でフィルタリング
    /// - Parameter reason: 削除理由
    /// - Returns: フィルタされた写真配列
    public func fetchPhotos(byReason reason: TrashPhoto.DeletionReason) async -> [TrashPhoto] {
        let allPhotos = await fetchAllTrashPhotos()
        return allPhotos.filterByReason(reason)
    }

    /// 期限切れ間近の写真を取得
    /// - Parameter days: 日数（デフォルト3日以内）
    /// - Returns: 期限切れ間近の写真配列
    public func fetchExpiringPhotos(withinDays days: Int = 3) async -> [TrashPhoto] {
        let allPhotos = await fetchAllTrashPhotos()
        return allPhotos.expiringWithin(days: days)
    }

    /// 削除日でソートされた写真を取得
    /// - Parameter ascending: 昇順の場合はtrue（デフォルトはfalse）
    /// - Returns: ソートされた写真配列
    public func fetchPhotosSortedByDate(ascending: Bool = false) async -> [TrashPhoto] {
        let allPhotos = await fetchAllTrashPhotos()
        return ascending ? allPhotos.sortedByDeletedAtAscending : allPhotos.sortedByDeletedAtDescending
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックTrashManager
@Observable
public final class MockTrashManager: TrashManagerProtocol {

    // MARK: - Mock Storage

    private var storage: [TrashPhoto] = []

    // MARK: - Test Hooks

    public var fetchAllCalled = false
    public var moveToTrashCalled = false
    public var restoreCalled = false
    public var permanentlyDeleteCalled = false
    public var cleanupExpiredCalled = false
    public var emptyTrashCalled = false
    public var shouldThrowError = false
    public var errorToThrow: TrashPhotoError?

    // MARK: - Initialization

    public init(initialData: [TrashPhoto] = []) {
        self.storage = initialData
    }

    // MARK: - Protocol Implementation

    public var trashCount: Int {
        get async { storage.count }
    }

    public var trashSize: Int64 {
        get async {
            storage.reduce(0) { $0 + $1.fileSize }
        }
    }

    public func fetchAllTrashPhotos() async -> [TrashPhoto] {
        fetchAllCalled = true
        return storage
    }

    public func moveToTrash(
        _ photos: [Photo],
        reason: TrashPhoto.DeletionReason? = nil
    ) async throws {
        moveToTrashCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        // 実際の変換は省略（テスト用）
    }

    public func restore(_ photos: [TrashPhoto]) async throws {
        restoreCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        let ids = Set(photos.map { $0.id })
        storage.removeAll { ids.contains($0.id) }
    }

    public func permanentlyDelete(_ photos: [TrashPhoto]) async throws {
        permanentlyDeleteCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        let ids = Set(photos.map { $0.id })
        storage.removeAll { ids.contains($0.id) }
    }

    public func cleanupExpired() async -> Int {
        cleanupExpiredCalled = true
        let expiredCount = storage.filter { $0.isExpired }.count
        storage.removeAll { $0.isExpired }
        return expiredCount
    }

    public func emptyTrash() async throws {
        emptyTrashCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        storage.removeAll()
    }

    // MARK: - Test Helper Methods

    public func reset() {
        storage.removeAll()
        fetchAllCalled = false
        moveToTrashCalled = false
        restoreCalled = false
        permanentlyDeleteCalled = false
        cleanupExpiredCalled = false
        emptyTrashCalled = false
        shouldThrowError = false
        errorToThrow = nil
    }

    public func addMockPhoto(_ photo: TrashPhoto) {
        storage.append(photo)
    }
}

#endif
