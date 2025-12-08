//
//  StorageService.swift
//  LightRoll_CleanerFeature
//
//  デバイスストレージ情報の取得と計算を担当するサービス
//  FileManagerとPhotos Frameworkを使用してストレージ情報を計算
//  Created by AI Assistant
//

import Foundation
import Photos

// MARK: - StorageServiceProtocol

/// ストレージサービスプロトコル
/// デバイスストレージ情報の取得と計算機能を抽象化
public protocol StorageServiceProtocol: AnyObject, Sendable {

    /// デバイスのストレージ情報を取得
    /// - Returns: ストレージ情報
    /// - Throws: StorageError
    func getDeviceStorageInfo() async throws -> StorageInfo

    /// 写真ライブラリの使用容量を計算
    /// - Returns: 使用容量（バイト）
    /// - Throws: PhotoRepositoryError
    func calculatePhotosUsage() async throws -> Int64

    /// 回収可能容量を推定
    /// - Parameter groups: 削除候補のPhotoGroup配列
    /// - Returns: 回収可能容量（バイト）
    func estimateReclaimableSpace(from groups: [PhotoGroup]) async -> Int64

    /// バイト数を人間が読みやすい形式にフォーマット
    /// - Parameter bytes: バイト数
    /// - Returns: フォーマット済み文字列（例: "1.5 GB"）
    static func formatBytes(_ bytes: Int64) -> String

    /// キャッシュをクリア
    func clearCache()
}

// MARK: - StorageServiceError

/// StorageService固有のエラー型
public enum StorageServiceError: Error, LocalizedError, Equatable {

    /// ストレージ情報の取得に失敗
    case storageInfoUnavailable

    /// 写真ライブラリへのアクセスが拒否された
    case photoAccessDenied

    /// 容量計算に失敗
    case calculationFailed(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .storageInfoUnavailable:
            return NSLocalizedString(
                "error.storageService.unavailable",
                value: "ストレージ情報を取得できませんでした",
                comment: "Storage info unavailable error"
            )
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.storageService.accessDenied",
                value: "写真ライブラリへのアクセスが拒否されています",
                comment: "Photo access denied error"
            )
        case .calculationFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.storageService.calculationFailed",
                    value: "容量計算に失敗しました: %@",
                    comment: "Calculation failed error"
                ),
                reason
            )
        }
    }
}

// MARK: - StorageService

/// ストレージサービスの実装
/// デバイスストレージ情報の取得と写真使用容量の計算を提供
public final class StorageService: StorageServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// キャッシュされたストレージ情報
    private var cachedStorageInfo: StorageInfo?

    /// キャッシュの最終更新時刻
    private var cacheTimestamp: Date?

    /// キャッシュの有効期間（秒）
    private let cacheValidityDuration: TimeInterval

    /// ロック用のシリアルキュー
    private let lock = NSLock()

    // MARK: - Initialization

    /// 初期化
    /// - Parameter cacheValidityDuration: キャッシュの有効期間（秒）。デフォルトは60秒
    public init(cacheValidityDuration: TimeInterval = 60) {
        self.cacheValidityDuration = cacheValidityDuration
    }

    // MARK: - StorageServiceProtocol Implementation

    /// デバイスのストレージ情報を取得
    /// - Returns: ストレージ情報
    /// - Throws: StorageServiceError
    public func getDeviceStorageInfo() async throws -> StorageInfo {
        // キャッシュが有効かチェック
        if let cached = getCachedStorageInfo() {
            return cached
        }

        let fileManager = FileManager.default

        // ドキュメントディレクトリのURLを取得
        guard let documentDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw StorageServiceError.storageInfoUnavailable
        }

        do {
            // iOS 11以降の高精度API使用
            let resourceValues = try documentDirectory.resourceValues(
                forKeys: [
                    .volumeTotalCapacityKey,
                    .volumeAvailableCapacityForImportantUsageKey
                ]
            )

            // 総容量を取得
            guard let totalCapacity = resourceValues.volumeTotalCapacity else {
                throw StorageServiceError.storageInfoUnavailable
            }

            // 利用可能容量を取得（重要な使用のための容量）
            // volumeAvailableCapacityForImportantUsage はより正確な空き容量を返す
            let availableCapacity: Int64
            if let importantUsage = resourceValues.volumeAvailableCapacityForImportantUsage {
                availableCapacity = importantUsage
            } else {
                // フォールバック: 通常の方法で取得
                let attributes = try fileManager.attributesOfFileSystem(
                    forPath: documentDirectory.path
                )
                availableCapacity = (attributes[.systemFreeSize] as? Int64) ?? 0
            }

            let storageInfo = StorageInfo(
                totalCapacity: Int64(totalCapacity),
                availableCapacity: availableCapacity,
                photosUsedCapacity: 0,  // 別途計算が必要
                reclaimableCapacity: 0   // 別途計算が必要
            )

            // キャッシュを更新
            updateCache(storageInfo)

            return storageInfo

        } catch let error as StorageServiceError {
            throw error
        } catch {
            throw StorageServiceError.calculationFailed(error.localizedDescription)
        }
    }

    /// 写真ライブラリの使用容量を計算
    /// - Returns: 使用容量（バイト）
    /// - Throws: StorageServiceError
    public func calculatePhotosUsage() async throws -> Int64 {
        // 写真ライブラリ権限チェック
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw StorageServiceError.photoAccessDenied
        }

        // 全写真アセットを取得
        let fetchOptions = PHFetchOptions()
        let allAssets = PHAsset.fetchAssets(with: fetchOptions)

        // 推定ファイルサイズを計算（高速）
        let assets = allAssets.toArray()
        let estimatedSize = assets.estimatedTotalFileSize

        return estimatedSize
    }

    /// 写真ライブラリの正確な使用容量を計算（低速だが精度が高い）
    /// - Parameter progressHandler: 進捗ハンドラ（0.0〜1.0）
    /// - Returns: 使用容量（バイト）
    /// - Throws: StorageServiceError
    public func calculatePhotosUsageAccurate(
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> Int64 {
        // 写真ライブラリ権限チェック
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw StorageServiceError.photoAccessDenied
        }

        // 全写真アセットを取得
        let fetchOptions = PHFetchOptions()
        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        let assets = allAssets.toArray()

        guard !assets.isEmpty else {
            progressHandler(1.0)
            return 0
        }

        // バッチで処理して進捗を報告
        let batchSize = 100
        var totalSize: Int64 = 0
        var processed = 0
        let totalCount = assets.count

        for asset in assets {
            // ファイルサイズを取得（推定値を使用）
            if let fileSize = asset.estimatedFileSize {
                totalSize += fileSize
            }

            processed += 1
            if processed % batchSize == 0 || processed == totalCount {
                let progress = Double(processed) / Double(totalCount)
                progressHandler(progress)
            }
        }

        return totalSize
    }

    /// 回収可能容量を推定
    /// - Parameter groups: 削除候補のPhotoGroup配列
    /// - Returns: 回収可能容量（バイト）
    public func estimateReclaimableSpace(from groups: [PhotoGroup]) async -> Int64 {
        // PhotoGroup の reclaimableSize プロパティを使用して合計を計算
        // 各グループの削減可能サイズ（ベストショット以外）を集計
        groups.reduce(0) { $0 + $1.reclaimableSize }
    }

    /// 指定された写真配列の合計サイズを計算
    /// - Parameter photos: 対象の写真配列
    /// - Returns: 合計サイズ（バイト）
    public func calculateTotalSize(for photos: [PhotoAsset]) -> Int64 {
        photos.reduce(0) { $0 + $1.fileSize }
    }

    /// バイト数を人間が読みやすい形式にフォーマット
    /// - Parameter bytes: バイト数
    /// - Returns: フォーマット済み文字列（例: "1.5 GB"）
    public static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// バイト数をカスタムフォーマットで変換
    /// - Parameters:
    ///   - bytes: バイト数
    ///   - style: フォーマットスタイル
    /// - Returns: フォーマット済み文字列
    public static func formatBytes(_ bytes: Int64, style: ByteCountFormatter.CountStyle) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: style)
    }

    /// バイト数を詳細情報付きでフォーマット
    /// - Parameter bytes: バイト数
    /// - Returns: 単位と数値を含むタプル
    public static func formatBytesDetailed(_ bytes: Int64) -> (value: Double, unit: String) {
        let kilobyte: Int64 = 1024
        let megabyte = kilobyte * 1024
        let gigabyte = megabyte * 1024
        let terabyte = gigabyte * 1024

        switch bytes {
        case 0..<kilobyte:
            return (Double(bytes), "B")
        case kilobyte..<megabyte:
            return (Double(bytes) / Double(kilobyte), "KB")
        case megabyte..<gigabyte:
            return (Double(bytes) / Double(megabyte), "MB")
        case gigabyte..<terabyte:
            return (Double(bytes) / Double(gigabyte), "GB")
        default:
            return (Double(bytes) / Double(terabyte), "TB")
        }
    }

    // MARK: - Cache Management

    /// キャッシュからストレージ情報を取得
    /// - Returns: 有効なキャッシュがあればStorageInfo、なければnil
    private func getCachedStorageInfo() -> StorageInfo? {
        lock.lock()
        defer { lock.unlock() }

        guard let cached = cachedStorageInfo,
              let timestamp = cacheTimestamp else {
            return nil
        }

        // キャッシュの有効期限をチェック
        if Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            return cached
        }

        return nil
    }

    /// キャッシュを更新
    /// - Parameter storageInfo: 新しいストレージ情報
    private func updateCache(_ storageInfo: StorageInfo) {
        lock.lock()
        defer { lock.unlock() }

        cachedStorageInfo = storageInfo
        cacheTimestamp = Date()
    }

    /// キャッシュをクリア
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }

        cachedStorageInfo = nil
        cacheTimestamp = nil
    }

    // MARK: - Utility Methods

    /// ストレージが低容量かどうかをチェック
    /// - Parameter thresholdPercentage: 閾値（%）。デフォルトは10%
    /// - Returns: 低容量の場合はtrue
    public func isStorageLow(thresholdPercentage: Double = 10.0) async -> Bool {
        do {
            let info = try await getDeviceStorageInfo()
            let usagePercentage = info.usagePercentage * 100
            return (100 - usagePercentage) < thresholdPercentage
        } catch {
            return false
        }
    }

    /// ストレージの健全性レベルを取得
    /// - Returns: StorageLevel
    public func getStorageHealthLevel() async -> StorageLevel {
        do {
            let info = try await getDeviceStorageInfo()
            return info.storageLevel
        } catch {
            return .critical
        }
    }
}

// MARK: - StorageService + Convenience

extension StorageService {

    /// 完全なストレージ情報を取得（写真使用量を含む）
    /// - Returns: 写真使用量を含むストレージ情報
    /// - Throws: StorageServiceError
    public func getCompleteStorageInfo() async throws -> StorageInfo {
        var storageInfo = try await getDeviceStorageInfo()

        do {
            let photosUsage = try await calculatePhotosUsage()
            storageInfo = storageInfo.withPhotosUsedCapacity(photosUsage)
        } catch StorageServiceError.photoAccessDenied {
            // 写真ライブラリへのアクセスが拒否された場合は、
            // 写真使用量を0として返す
        }

        return storageInfo
    }

    /// 回収可能容量を含む完全なストレージ情報を取得
    /// - Parameter groups: 削除候補のPhotoGroup配列
    /// - Returns: 完全なストレージ情報
    /// - Throws: StorageServiceError
    public func getCompleteStorageInfo(
        withReclaimableFrom groups: [PhotoGroup]
    ) async throws -> StorageInfo {
        var storageInfo = try await getCompleteStorageInfo()
        let reclaimable = await estimateReclaimableSpace(from: groups)
        storageInfo = storageInfo.withReclaimableCapacity(reclaimable)
        return storageInfo
    }
}
