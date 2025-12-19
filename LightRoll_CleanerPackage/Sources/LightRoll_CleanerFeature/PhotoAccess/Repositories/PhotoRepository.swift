//
//  PhotoRepository.swift
//  LightRoll_CleanerFeature
//
//  写真データへのアクセスを提供するリポジトリ
//  PHCachingImageManagerを使用したサムネイルキャッシュとフェッチ機能
//  Created by AI Assistant
//

import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

// MARK: - PhotoRepositoryError

/// PhotoRepository で発生するエラー
public enum PhotoRepositoryError: Error, Equatable, Sendable {
    /// 写真ライブラリへのアクセスが拒否された
    case photoAccessDenied

    /// アセットが見つからない
    case assetNotFound

    /// サムネイル生成に失敗
    case thumbnailGenerationFailed

    /// ストレージ情報の取得に失敗
    case storageInfoUnavailable

    /// フェッチがキャンセルされた
    case fetchCancelled

    /// 不明なエラー
    case unknown(String)

    // MARK: - Equatable

    public static func == (lhs: PhotoRepositoryError, rhs: PhotoRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.photoAccessDenied, .photoAccessDenied),
             (.assetNotFound, .assetNotFound),
             (.thumbnailGenerationFailed, .thumbnailGenerationFailed),
             (.storageInfoUnavailable, .storageInfoUnavailable),
             (.fetchCancelled, .fetchCancelled):
            return true
        case let (.unknown(lhsMessage), .unknown(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }

    // MARK: - LocalizedError

    /// ローカライズされたエラー説明
    public var localizedDescription: String {
        switch self {
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.photoRepository.accessDenied",
                value: "写真ライブラリへのアクセスが拒否されています",
                comment: "Photo access denied error"
            )
        case .assetNotFound:
            return NSLocalizedString(
                "error.photoRepository.assetNotFound",
                value: "指定された写真が見つかりませんでした",
                comment: "Asset not found error"
            )
        case .thumbnailGenerationFailed:
            return NSLocalizedString(
                "error.photoRepository.thumbnailFailed",
                value: "サムネイルの生成に失敗しました",
                comment: "Thumbnail generation failed error"
            )
        case .storageInfoUnavailable:
            return NSLocalizedString(
                "error.photoRepository.storageUnavailable",
                value: "ストレージ情報を取得できませんでした",
                comment: "Storage info unavailable error"
            )
        case .fetchCancelled:
            return NSLocalizedString(
                "error.photoRepository.fetchCancelled",
                value: "写真の取得がキャンセルされました",
                comment: "Fetch cancelled error"
            )
        case .unknown(let message):
            return String(format: NSLocalizedString(
                "error.photoRepository.unknown",
                value: "不明なエラーが発生しました: %@",
                comment: "Unknown error"
            ), message)
        }
    }
}

// MARK: - FetchOptions

/// 写真取得オプション
public struct PhotoFetchOptions: @unchecked Sendable {

    /// ソート順序
    public enum SortOrder: Sendable {
        case creationDateDescending
        case creationDateAscending
        case modificationDateDescending
        case modificationDateAscending
    }

    /// メディアタイプフィルター
    public enum MediaTypeFilter: Sendable {
        case all
        case images
        case videos
    }

    /// ソート順序
    public let sortOrder: SortOrder

    /// メディアタイプフィルター
    public let mediaTypeFilter: MediaTypeFilter

    /// ファイルサイズを含めるか（false の場合は高速だが fileSize = 0）
    public let includeFileSize: Bool

    /// 取得上限（nil の場合は全件）
    public let limit: Int?

    /// フィルター条件（NSPredicate）
    public let predicate: NSPredicate?

    /// デフォルトオプション
    public static let `default` = PhotoFetchOptions(
        sortOrder: .creationDateDescending,
        mediaTypeFilter: .all,
        includeFileSize: false,
        limit: nil,
        predicate: nil
    )

    public init(
        sortOrder: SortOrder = .creationDateDescending,
        mediaTypeFilter: MediaTypeFilter = .all,
        includeFileSize: Bool = false,
        limit: Int? = nil,
        predicate: NSPredicate? = nil
    ) {
        self.sortOrder = sortOrder
        self.mediaTypeFilter = mediaTypeFilter
        self.includeFileSize = includeFileSize
        self.limit = limit
        self.predicate = predicate
    }

    /// PHFetchOptions に変換
    internal func toPHFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()

        // ソート設定
        let sortKey: String
        let ascending: Bool
        switch sortOrder {
        case .creationDateDescending:
            sortKey = "creationDate"
            ascending = false
        case .creationDateAscending:
            sortKey = "creationDate"
            ascending = true
        case .modificationDateDescending:
            sortKey = "modificationDate"
            ascending = false
        case .modificationDateAscending:
            sortKey = "modificationDate"
            ascending = true
        }
        options.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]

        // 取得上限
        if let limit = limit {
            options.fetchLimit = limit
        }

        // フィルター条件
        if let predicate = predicate {
            options.predicate = predicate
        }

        return options
    }
}

// MARK: - PhotoRepository

/// 写真リポジトリの実装
/// PHCachingImageManager を使用してサムネイルをキャッシュ
@Observable
@MainActor
public final class PhotoRepository: PhotoRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// サムネイルキャッシュ用のイメージマネージャー
    private let imageManager: PHCachingImageManager

    /// 権限マネージャー
    private let permissionManager: PhotoPermissionManagerProtocol

    /// ストレージサービス
    private let storageService: StorageServiceProtocol

    /// フェッチオプション
    public var fetchOptions: PhotoFetchOptions

    /// 読み込み状態
    public private(set) var isLoading: Bool = false

    /// 最後のエラー
    public private(set) var lastError: PhotoRepositoryError?

    /// キャッシュされたアセット（プリフェッチ用）
    private var cachedAssets: [PHAsset] = []

    /// ストレージ情報のキャッシュ
    private var cachedStorageInfo: StorageInfo?

    /// ストレージ情報キャッシュの最終更新時刻
    private var storageInfoCacheTimestamp: Date?

    /// ストレージ情報キャッシュの有効期間（秒）
    private let storageInfoCacheValidity: TimeInterval = 30

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - permissionManager: 権限マネージャー
    ///   - fetchOptions: フェッチオプション
    ///   - storageService: ストレージサービス（nilの場合は内部で生成）
    public init(
        permissionManager: PhotoPermissionManagerProtocol,
        fetchOptions: PhotoFetchOptions = .default,
        storageService: StorageServiceProtocol? = nil
    ) {
        self.imageManager = PHCachingImageManager()
        self.permissionManager = permissionManager
        self.fetchOptions = fetchOptions
        self.storageService = storageService ?? StorageService()

        // キャッシュの最適化設定
        self.imageManager.allowsCachingHighQualityImages = false
    }

    // MARK: - PhotoRepositoryProtocol Implementation

    /// 全ての写真を取得（PhotoAsset版 - プロトコル準拠用）
    public func fetchAllPhotos() async throws -> [PhotoAsset] {
        let photos = try await fetchAllPhotoModels()
        return photos.map { photo in
            PhotoAsset(
                id: photo.id,
                creationDate: photo.creationDate,
                fileSize: photo.fileSize
            )
        }
    }

    /// 指定されたIDの写真を取得（PhotoAsset版）
    public func fetchPhoto(by id: String) async -> PhotoAsset? {
        guard let photo = await fetchPhotoModel(by: id) else {
            return nil
        }
        return PhotoAsset(
            id: photo.id,
            creationDate: photo.creationDate,
            fileSize: photo.fileSize
        )
    }

    /// 写真を削除（PHAsset完全削除）
    /// - Parameter photos: 削除する写真の配列
    /// - Throws: PhotoRepositoryError
    ///
    /// ## 注意事項
    /// - この操作は取り消し不可能です
    /// - PHPhotoLibrary.performChanges経由でシステム削除確認ダイアログが表示されます
    /// - ユーザーがキャンセルした場合はエラーがスローされます
    public func deletePhotos(_ photos: [PhotoAsset]) async throws {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        // 空の配列チェック
        guard !photos.isEmpty else {
            return
        }

        // PhotoAssetのIDからPHAssetを取得
        let ids = photos.map { $0.id }
        let assets = fetchPHAssets(by: ids)

        // アセットが見つからない場合
        guard !assets.isEmpty else {
            let error = PhotoRepositoryError.assetNotFound
            self.lastError = error
            throw error
        }

        // PHPhotoLibraryで削除を実行
        // システム削除確認ダイアログが表示される
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            }

            // キャッシュをクリア
            #if canImport(UIKit)
            self.clearThumbnailCache()
            #endif
            self.clearStorageInfoCache()

        } catch let error as NSError {
            // ユーザーキャンセルまたは削除失敗
            let repositoryError: PhotoRepositoryError
            if error.domain == PHPhotosErrorDomain {
                switch error.code {
                case PHPhotosError.userCancelled.rawValue:
                    repositoryError = .fetchCancelled
                case PHPhotosError.accessUserDenied.rawValue,
                     PHPhotosError.accessRestricted.rawValue:
                    repositoryError = .photoAccessDenied
                default:
                    repositoryError = .unknown("削除に失敗しました: \(error.localizedDescription)")
                }
            } else {
                repositoryError = .unknown(error.localizedDescription)
            }

            self.lastError = repositoryError
            throw repositoryError
        }
    }

    /// 写真をゴミ箱に移動（アプリ内管理）
    public func moveToTrash(_ photos: [PhotoAsset]) async throws {
        // アプリ内のゴミ箱管理は別途 TrashManager で実装
        // ここでは実際の削除は行わない（ソフトデリート）
    }

    /// ゴミ箱から復元
    public func restoreFromTrash(_ photos: [PhotoAsset]) async throws {
        // アプリ内のゴミ箱管理は別途 TrashManager で実装
    }

    #if canImport(UIKit)
    /// サムネイル画像を取得（PhotoAsset版）
    public func fetchThumbnail(for photo: PhotoAsset, size: CGSize) async throws -> UIImage {
        guard let asset = fetchPHAsset(by: photo.id) else {
            throw PhotoRepositoryError.assetNotFound
        }
        return try await fetchThumbnail(for: asset, size: size)
    }
    #endif

    // MARK: - Photo Model Methods

    /// 全ての写真を取得（Photo モデル版）
    public func fetchAllPhotoModels() async throws -> [Photo] {
        try await fetchAllPhotoModels(progress: { _ in })
    }

    /// 全ての写真を取得（進捗通知付き、Photo モデル版）
    public func fetchAllPhotoModels(progress: @escaping @Sendable (Double) -> Void) async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        // キャッシュを更新
        cachedAssets = result.toArray()

        // Photo 配列に変換
        let photos: [Photo]
        if fetchOptions.includeFileSize {
            photos = try await result.toPhotos(
                includeFileSize: true,
                progress: progress
            )
        } else {
            let photoArray = result.toArray().map { $0.toPhotoWithoutFileSize() }
            progress(1.0)
            photos = photoArray
        }

        return photos
    }

    /// 指定されたIDの写真を取得（Photo モデル版）
    public func fetchPhotoModel(by id: String) async -> Photo? {
        guard let asset = fetchPHAsset(by: id) else {
            return nil
        }

        if fetchOptions.includeFileSize {
            return try? await asset.toPhoto()
        } else {
            return asset.toPhotoWithoutFileSize()
        }
    }

    #if canImport(UIKit)
    /// サムネイル画像を取得（PHAsset版）
    public func fetchThumbnail(for asset: PHAsset, size: CGSize) async throws -> UIImage {
        try await fetchThumbnail(for: asset, options: .default.withSize(size))
    }

    /// サムネイル画像を取得（オプション指定版）
    /// - Parameters:
    ///   - asset: 対象のPHAsset
    ///   - options: 取得オプション
    /// - Returns: サムネイル画像
    /// - Throws: PhotoRepositoryError
    public func fetchThumbnail(
        for asset: PHAsset,
        options: ThumbnailRequestOptions
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let phOptions = options.toPHImageRequestOptions()
            var isResumed = false

            imageManager.requestImage(
                for: asset,
                targetSize: options.targetSize,
                contentMode: options.contentMode,
                options: phOptions
            ) { image, info in
                // 既にresumeされていたら何もしない
                guard !isResumed else { return }

                // エラーチェック
                if let error = info?[PHImageErrorKey] as? Error {
                    isResumed = true
                    continuation.resume(throwing: PhotoRepositoryError.unknown(error.localizedDescription))
                    return
                }

                // キャンセルチェック
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    isResumed = true
                    continuation.resume(throwing: PhotoRepositoryError.fetchCancelled)
                    return
                }

                // 高品質モードでない場合、degraded（低解像度）の画像も受け入れる
                // 高品質モードの場合、最終画像が来るまで待つ
                if options.quality != .fast {
                    if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded {
                        return
                    }
                }

                guard let image = image else {
                    isResumed = true
                    continuation.resume(throwing: PhotoRepositoryError.thumbnailGenerationFailed)
                    return
                }

                isResumed = true
                continuation.resume(returning: image)
            }
        }
    }

    /// サムネイル画像を取得（Photo版、オプション指定）
    /// - Parameters:
    ///   - photo: 対象の写真
    ///   - options: 取得オプション
    /// - Returns: サムネイル画像
    /// - Throws: PhotoRepositoryError
    public func fetchThumbnail(
        for photo: Photo,
        options: ThumbnailRequestOptions
    ) async throws -> UIImage {
        guard let asset = fetchPHAsset(by: photo.id) else {
            throw PhotoRepositoryError.assetNotFound
        }
        return try await fetchThumbnail(for: asset, options: options)
    }

    /// サムネイル画像と結果情報を取得
    /// - Parameters:
    ///   - asset: 対象のPHAsset
    ///   - options: 取得オプション
    /// - Returns: ThumbnailResult（画像と付加情報）
    /// - Throws: PhotoRepositoryError
    public func fetchThumbnailWithResult(
        for asset: PHAsset,
        options: ThumbnailRequestOptions
    ) async throws -> ThumbnailResult {
        try await withCheckedThrowingContinuation { continuation in
            let phOptions = options.toPHImageRequestOptions()
            var isResumed = false

            imageManager.requestImage(
                for: asset,
                targetSize: options.targetSize,
                contentMode: options.contentMode,
                options: phOptions
            ) { image, info in
                // 既にresumeされていたら何もしない
                guard !isResumed else { return }

                // エラーチェック
                if let error = info?[PHImageErrorKey] as? Error {
                    isResumed = true
                    continuation.resume(throwing: PhotoRepositoryError.unknown(error.localizedDescription))
                    return
                }

                // キャンセルチェック
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    isResumed = true
                    continuation.resume(throwing: PhotoRepositoryError.fetchCancelled)
                    return
                }

                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false

                // 高品質モードでない場合、degraded画像も受け入れる
                // 高品質モードの場合、最終画像が来るまで待つ
                if options.quality == .fast || !isDegraded {
                    guard let image = image else {
                        isResumed = true
                        continuation.resume(throwing: PhotoRepositoryError.thumbnailGenerationFailed)
                        return
                    }

                    let result = ThumbnailResult(
                        image: image,
                        isDegraded: isDegraded,
                        isLocallyAvailable: !isInCloud
                    )
                    isResumed = true
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// 複数のサムネイルをバッチで取得
    /// - Parameters:
    ///   - photos: 対象の写真配列
    ///   - options: 取得オプション
    ///   - progress: 進捗通知ハンドラ（完了数、総数）
    /// - Returns: PhotoIDをキーとした画像の辞書
    /// - Throws: PhotoRepositoryError
    public func fetchThumbnails(
        for photos: [Photo],
        options: ThumbnailRequestOptions,
        progress: @escaping @Sendable (Int, Int) -> Void
    ) async throws -> [String: UIImage] {
        guard !photos.isEmpty else { return [:] }

        let total = photos.count
        var results: [String: UIImage] = [:]
        results.reserveCapacity(total)

        var completed = 0

        // 並列でサムネイルを取得
        try await withThrowingTaskGroup(of: (String, UIImage)?.self) { group in
            for photo in photos {
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    // MainActor隔離されたメソッドを呼び出すため、MainActor.runを使用
                    guard let asset = await MainActor.run(body: { self.fetchPHAsset(by: photo.id) }) else {
                        return nil
                    }
                    do {
                        let image = try await self.fetchThumbnail(for: asset, options: options)
                        return (photo.id, image)
                    } catch {
                        // 個別の失敗は無視して続行
                        return nil
                    }
                }
            }

            for try await result in group {
                if let (id, image) = result {
                    results[id] = image
                }
                completed += 1
                progress(completed, total)
            }
        }

        return results
    }

    /// サムネイルのプリロード（キャッシュ準備）
    /// - Parameters:
    ///   - photos: プリロード対象の写真配列
    ///   - options: 取得オプション
    public func preloadThumbnails(
        for photos: [Photo],
        options: ThumbnailRequestOptions
    ) {
        let ids = photos.map { $0.id }
        let assets = fetchPHAssets(by: ids)
        guard !assets.isEmpty else { return }

        let phOptions = options.toPHImageRequestOptions()

        imageManager.startCachingImages(
            for: assets,
            targetSize: options.targetSize,
            contentMode: options.contentMode,
            options: phOptions
        )
    }

    /// プリロードを停止
    /// - Parameters:
    ///   - photos: 停止対象の写真配列
    ///   - options: 取得オプション
    public func stopPreloadingThumbnails(
        for photos: [Photo],
        options: ThumbnailRequestOptions
    ) {
        let ids = photos.map { $0.id }
        let assets = fetchPHAssets(by: ids)
        guard !assets.isEmpty else { return }

        let phOptions = options.toPHImageRequestOptions()

        imageManager.stopCachingImages(
            for: assets,
            targetSize: options.targetSize,
            contentMode: options.contentMode,
            options: phOptions
        )
    }

    /// 全てのサムネイルキャッシュをクリア
    public func clearThumbnailCache() {
        imageManager.stopCachingImagesForAllAssets()
    }

    /// スクロール方向に基づくキャッシュ戦略を更新
    /// - Parameters:
    ///   - addingPhotos: 新たにキャッシュに追加する写真
    ///   - removingPhotos: キャッシュから削除する写真
    ///   - options: 取得オプション
    public func updateCachingStrategy(
        addingPhotos: [Photo],
        removingPhotos: [Photo],
        options: ThumbnailRequestOptions
    ) {
        // 削除対象のキャッシュを停止
        if !removingPhotos.isEmpty {
            let removingIds = removingPhotos.map { $0.id }
            let removingAssets = fetchPHAssets(by: removingIds)
            if !removingAssets.isEmpty {
                let phOptions = options.toPHImageRequestOptions()
                imageManager.stopCachingImages(
                    for: removingAssets,
                    targetSize: options.targetSize,
                    contentMode: options.contentMode,
                    options: phOptions
                )
            }
        }

        // 追加対象のキャッシュを開始
        if !addingPhotos.isEmpty {
            let addingIds = addingPhotos.map { $0.id }
            let addingAssets = fetchPHAssets(by: addingIds)
            if !addingAssets.isEmpty {
                let phOptions = options.toPHImageRequestOptions()
                imageManager.startCachingImages(
                    for: addingAssets,
                    targetSize: options.targetSize,
                    contentMode: options.contentMode,
                    options: phOptions
                )
            }
        }
    }
    #endif

    /// ストレージ情報を取得
    /// StorageServiceを使用してデバイスのストレージ情報と写真使用量を取得
    /// - Returns: ストレージ情報
    /// - Throws: PhotoRepositoryError
    public func getStorageInfo() async throws -> StorageInfo {
        // キャッシュが有効かチェック
        if let cached = getCachedStorageInfo() {
            return cached
        }

        do {
            // StorageServiceを使用してデバイスストレージ情報を取得
            var storageInfo = try await storageService.getDeviceStorageInfo()

            // 空の情報が返ってきた場合はエラー
            guard storageInfo.totalCapacity > 0 else {
                let error = PhotoRepositoryError.storageInfoUnavailable
                self.lastError = error
                throw error
            }

            // 写真使用容量を計算（権限がある場合のみ）
            if permissionManager.currentStatus.isAuthorized {
                let photosSize = await calculateTotalPhotosSize()
                storageInfo = storageInfo.withPhotosUsedCapacity(photosSize)
            }

            // キャッシュを更新
            updateStorageInfoCache(storageInfo)

            return storageInfo

        } catch let error as StorageServiceError {
            let repositoryError: PhotoRepositoryError
            switch error {
            case .storageInfoUnavailable:
                repositoryError = .storageInfoUnavailable
            case .photoAccessDenied:
                repositoryError = .photoAccessDenied
            case .calculationFailed(let reason):
                repositoryError = .unknown(reason)
            }
            self.lastError = repositoryError
            throw repositoryError
        } catch {
            let repositoryError = PhotoRepositoryError.unknown(error.localizedDescription)
            self.lastError = repositoryError
            throw repositoryError
        }
    }

    /// 回収可能容量を含むストレージ情報を取得
    /// - Parameter groups: 削除候補のPhotoGroup配列
    /// - Returns: 完全なストレージ情報
    /// - Throws: PhotoRepositoryError
    public func getStorageInfo(withReclaimableFrom groups: [PhotoGroup]) async throws -> StorageInfo {
        var storageInfo = try await getStorageInfo()
        let reclaimable = await storageService.estimateReclaimableSpace(from: groups)
        storageInfo = storageInfo.withReclaimableCapacity(reclaimable)
        return storageInfo
    }

    /// ストレージ情報キャッシュを取得
    private func getCachedStorageInfo() -> StorageInfo? {
        guard let cached = cachedStorageInfo,
              let timestamp = storageInfoCacheTimestamp else {
            return nil
        }

        // キャッシュの有効期限をチェック
        if Date().timeIntervalSince(timestamp) < storageInfoCacheValidity {
            return cached
        }

        return nil
    }

    /// ストレージ情報キャッシュを更新
    private func updateStorageInfoCache(_ storageInfo: StorageInfo) {
        cachedStorageInfo = storageInfo
        storageInfoCacheTimestamp = Date()
    }

    /// ストレージ情報キャッシュをクリア
    public func clearStorageInfoCache() {
        cachedStorageInfo = nil
        storageInfoCacheTimestamp = nil
        storageService.clearCache()
    }

    /// PHAsset を取得
    public func fetchPHAsset(by id: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: [id],
            options: nil
        )
        return result.firstObject
    }

    /// 複数の PHAsset を取得
    public func fetchPHAssets(by ids: [String]) -> [PHAsset] {
        guard !ids.isEmpty else { return [] }

        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: ids,
            options: nil
        )
        return result.toArray()
    }

    // MARK: - Caching Methods

    /// サムネイルのプリフェッチを開始
    /// - Parameters:
    ///   - assets: プリフェッチ対象のアセット
    ///   - size: サムネイルサイズ
    public func startCachingThumbnails(for assets: [PHAsset], size: CGSize) {
        #if canImport(UIKit)
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
        #endif
    }

    /// サムネイルのプリフェッチを停止
    /// - Parameters:
    ///   - assets: 対象のアセット
    ///   - size: サムネイルサイズ
    public func stopCachingThumbnails(for assets: [PHAsset], size: CGSize) {
        #if canImport(UIKit)
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
        #endif
    }

    /// 全てのキャッシュをクリア
    public func stopCachingAllThumbnails() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Advanced Filtering Methods

    /// 日付範囲で写真を取得
    /// - Parameters:
    ///   - startDate: 開始日（この日以降の写真を取得）
    ///   - endDate: 終了日（この日以前の写真を取得）
    /// - Returns: 日付範囲内の写真の配列
    /// - Throws: PhotoRepositoryError
    public func fetchPhotos(from startDate: Date, to endDate: Date) async throws -> [Photo] {
        try await fetchPhotos(dateRange: PhotoDateRangeFilter(startDate: startDate, endDate: endDate))
    }

    /// 日付範囲フィルターで写真を取得
    /// - Parameter dateRange: 日付範囲フィルター
    /// - Returns: 日付範囲内の写真の配列
    /// - Throws: PhotoRepositoryError
    public func fetchPhotos(dateRange: PhotoDateRangeFilter) async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            dateRange.startDate as NSDate,
            dateRange.endDate as NSDate
        )

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        // Photo 配列に変換
        if fetchOptions.includeFileSize {
            return try await result.toPhotos(includeFileSize: true)
        } else {
            return result.toArray().map { $0.toPhotoWithoutFileSize() }
        }
    }

    /// メディアタイプで写真を取得
    /// - Parameter mediaType: メディアタイプ（image, video）
    /// - Returns: 指定タイプの写真の配列
    /// - Throws: PhotoRepositoryError
    public func fetchPhotos(mediaType: MediaType) async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()

        // メディアタイプに応じてフェッチ
        let result = PHAsset.fetchAssets(with: mediaType.toPHAssetMediaType, options: options)

        // Photo 配列に変換
        if fetchOptions.includeFileSize {
            return try await result.toPhotos(includeFileSize: true)
        } else {
            return result.toArray().map { $0.toPhotoWithoutFileSize() }
        }
    }

    /// お気に入りの写真のみを取得
    /// - Returns: お気に入りの写真の配列
    /// - Throws: PhotoRepositoryError
    public func fetchFavoritePhotos() async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()
        options.predicate = NSPredicate(format: "isFavorite == YES")

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        // Photo 配列に変換
        if fetchOptions.includeFileSize {
            return try await result.toPhotos(includeFileSize: true)
        } else {
            return result.toArray().map { $0.toPhotoWithoutFileSize() }
        }
    }

    /// スクリーンショットのみを取得
    /// - Returns: スクリーンショットの配列
    /// - Throws: PhotoRepositoryError
    public func fetchScreenshots() async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()

        // スクリーンショットは画像のみ
        let result = PHAsset.fetchAssets(with: .image, options: options)

        // スクリーンショットのみをフィルタリング
        let screenshotAssets = result.toArray().filter { $0.isScreenshot }

        // Photo 配列に変換
        if fetchOptions.includeFileSize {
            return try await screenshotAssets.toPhotos(includeFileSize: true)
        } else {
            return screenshotAssets.map { $0.toPhotoWithoutFileSize() }
        }
    }

    /// Live Photoのみを取得
    /// - Returns: Live Photoの配列
    /// - Throws: PhotoRepositoryError
    public func fetchLivePhotos() async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()

        // Live Photoは画像のみ
        let result = PHAsset.fetchAssets(with: .image, options: options)

        // Live Photoのみをフィルタリング
        let livePhotoAssets = result.toArray().filter { $0.isLivePhoto }

        // Photo 配列に変換
        if fetchOptions.includeFileSize {
            return try await livePhotoAssets.toPhotos(includeFileSize: true)
        } else {
            return livePhotoAssets.map { $0.toPhotoWithoutFileSize() }
        }
    }

    // MARK: - Pagination Methods

    /// ページネーション対応で写真を取得
    /// - Parameters:
    ///   - offset: 取得開始位置（0から開始）
    ///   - limit: 取得件数
    /// - Returns: PhotoPage（ページ情報と写真の配列）
    /// - Throws: PhotoRepositoryError
    public func fetchPhotos(offset: Int, limit: Int) async throws -> PhotoPage {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定（全件取得用）
        let options = fetchOptions.toPHFetchOptions()
        options.fetchLimit = 0  // 全件取得して手動でページング

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        let totalCount = result.count

        // 空の場合
        guard totalCount > 0 else {
            return PhotoPage.empty(pageSize: limit)
        }

        // オフセットが範囲外の場合
        guard offset < totalCount else {
            return PhotoPage(
                photos: [],
                totalCount: totalCount,
                hasMore: false,
                nextOffset: nil,
                currentOffset: offset,
                pageSize: limit
            )
        }

        // 指定範囲のアセットを取得
        let endIndex = min(offset + limit, totalCount)
        var pageAssets: [PHAsset] = []
        pageAssets.reserveCapacity(endIndex - offset)

        for i in offset..<endIndex {
            pageAssets.append(result.object(at: i))
        }

        // Photo 配列に変換
        let photos: [Photo]
        if fetchOptions.includeFileSize {
            photos = try await pageAssets.toPhotos(includeFileSize: true)
        } else {
            photos = pageAssets.map { $0.toPhotoWithoutFileSize() }
        }

        // 次のページがあるか判定
        let hasMore = endIndex < totalCount
        let nextOffset: Int? = hasMore ? endIndex : nil

        return PhotoPage(
            photos: photos,
            totalCount: totalCount,
            hasMore: hasMore,
            nextOffset: nextOffset,
            currentOffset: offset,
            pageSize: limit
        )
    }

    /// ページネーション対応で写真を取得（PhotoAsset版）
    /// - Parameters:
    ///   - offset: 取得開始位置（0から開始）
    ///   - limit: 取得件数
    /// - Returns: PhotoPageAsset
    /// - Throws: PhotoRepositoryError
    public func fetchPhotoAssets(offset: Int, limit: Int) async throws -> PhotoPageAsset {
        let page = try await fetchPhotos(offset: offset, limit: limit)
        return PhotoPageAsset.from(page)
    }

    // MARK: - Batch Fetch Methods

    /// 大量の写真をバッチで取得（進捗通知付き）
    /// - Parameters:
    ///   - batchSize: 1バッチあたりの取得件数
    ///   - progress: 進捗通知ハンドラ（0.0〜1.0）
    /// - Returns: 全ての写真の配列
    /// - Throws: PhotoRepositoryError
    public func fetchAllPhotosInBatches(
        batchSize: Int = 100,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // フェッチオプション設定
        let options = fetchOptions.toPHFetchOptions()
        options.fetchLimit = 0

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        let totalCount = result.count

        guard totalCount > 0 else {
            progress(1.0)
            return []
        }

        var allPhotos: [Photo] = []
        allPhotos.reserveCapacity(totalCount)

        var currentOffset = 0

        while currentOffset < totalCount {
            // 現在のバッチ範囲を計算
            let endIndex = min(currentOffset + batchSize, totalCount)
            var batchAssets: [PHAsset] = []
            batchAssets.reserveCapacity(endIndex - currentOffset)

            for i in currentOffset..<endIndex {
                batchAssets.append(result.object(at: i))
            }

            // バッチを変換
            let batchPhotos: [Photo]
            if fetchOptions.includeFileSize {
                batchPhotos = try await batchAssets.toPhotos(includeFileSize: true)
            } else {
                batchPhotos = batchAssets.map { $0.toPhotoWithoutFileSize() }
            }

            allPhotos.append(contentsOf: batchPhotos)

            // 進捗を通知
            let progressValue = Double(endIndex) / Double(totalCount)
            progress(progressValue)

            currentOffset = endIndex
        }

        return allPhotos
    }

    /// 大量の写真をバッチで取得（AsyncSequence版）
    /// - Parameter batchSize: 1バッチあたりの取得件数
    /// - Returns: PhotoBatchSequence（AsyncSequenceとして順次取得可能）
    /// - Throws: PhotoRepositoryError
    public func fetchAllPhotosAsStream(
        batchSize: Int = 100
    ) throws -> PhotoBatchSequence {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        return PhotoBatchSequence(
            repository: self,
            batchSize: batchSize
        )
    }

    // MARK: - Count Methods

    /// 写真の総数を取得（軽量な操作）
    /// - Returns: 写真の総数
    /// - Throws: PhotoRepositoryError
    public func fetchPhotoCount() throws -> Int {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        let options = PHFetchOptions()

        // メディアタイプに応じてフェッチ
        let result: PHFetchResult<PHAsset>
        switch fetchOptions.mediaTypeFilter {
        case .all:
            result = PHAsset.fetchAssets(with: options)
        case .images:
            result = PHAsset.fetchAssets(with: .image, options: options)
        case .videos:
            result = PHAsset.fetchAssets(with: .video, options: options)
        }

        return result.count
    }

    /// スクリーンショットの総数を取得
    /// - Returns: スクリーンショットの総数
    /// - Throws: PhotoRepositoryError
    public func fetchScreenshotCount() throws -> Int {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoRepositoryError.photoAccessDenied
            self.lastError = error
            throw error
        }

        let options = PHFetchOptions()
        let result = PHAsset.fetchAssets(with: .image, options: options)

        return result.toArray().filter { $0.isScreenshot }.count
    }

    // MARK: - Private Methods

    /// 写真ライブラリの総使用容量を計算
    private func calculateTotalPhotosSize() async -> Int64 {
        let options = PHFetchOptions()
        let result = PHAsset.fetchAssets(with: options)
        let assets = result.toArray()

        // 推定値を使用（高速）
        return assets.estimatedTotalFileSize
    }
}

// MARK: - PhotoProvider Protocol Conformance

/// PhotoProviderプロトコルへの準拠
extension PhotoRepository: PhotoProvider {
    /// 指定されたIDの写真を取得
    /// - Parameter ids: 写真ID配列
    /// - Returns: 写真配列
    public func photos(for ids: [String]) async -> [Photo] {
        // 空の配列チェック
        guard !ids.isEmpty else { return [] }

        // 各IDに対して写真を取得
        var photos: [Photo] = []
        photos.reserveCapacity(ids.count)

        for id in ids {
            if let photo = await fetchPhotoModel(by: id) {
                photos.append(photo)
            }
        }

        return photos
    }
}

// MARK: - PhotoBatchSequence

/// 写真をバッチで取得するためのAsyncSequence
public struct PhotoBatchSequence: AsyncSequence, Sendable {
    public typealias Element = [Photo]

    private let repository: PhotoRepository
    private let batchSize: Int

    init(repository: PhotoRepository, batchSize: Int) {
        self.repository = repository
        self.batchSize = batchSize
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(repository: repository, batchSize: batchSize)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        private let repository: PhotoRepository
        private let batchSize: Int
        private var currentOffset: Int = 0
        private var hasMore: Bool = true

        init(repository: PhotoRepository, batchSize: Int) {
            self.repository = repository
            self.batchSize = batchSize
        }

        public mutating func next() async throws -> [Photo]? {
            guard hasMore else { return nil }

            let page = try await repository.fetchPhotos(offset: currentOffset, limit: batchSize)

            guard !page.isEmpty else {
                hasMore = false
                return nil
            }

            hasMore = page.hasMore
            currentOffset = page.nextOffset ?? currentOffset

            return page.photos
        }
    }
}
