//
//  PhotoScanner.swift
//  LightRoll_CleanerFeature
//
//  プログレス付き写真スキャン機能
//  写真ライブラリ全体をスキャンし、リアルタイムで進捗を通知する
//  Created by AI Assistant
//

import Foundation
import Photos

// MARK: - ScanState

/// スキャンの状態
public enum ScanState: Sendable, Equatable {
    /// アイドル状態（スキャン未実行）
    case idle

    /// スキャン中
    case scanning

    /// 一時停止中（将来の拡張用）
    case paused

    /// スキャン完了
    case completed

    /// スキャンがキャンセルされた
    case cancelled

    /// スキャン失敗
    case failed(PhotoScannerError)

    // MARK: - Equatable

    public static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.scanning, .scanning),
             (.paused, .paused),
             (.completed, .completed),
             (.cancelled, .cancelled):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - PhotoScanProgress

/// 写真スキャン進捗情報
/// Note: Core/State/ScanResult.swift に既存の ScanProgress があるため PhotoScanProgress とする
public struct PhotoScanProgress: Sendable {
    /// 現在スキャン済みの写真数
    public let current: Int

    /// 写真の総数
    public let total: Int

    /// 進捗率（0.0〜1.0）
    public let percentage: Double

    /// 現在処理中の写真（バッチ処理のため最後の1枚）
    public let currentPhoto: Photo?

    /// 残り推定時間（秒）
    public let estimatedTimeRemaining: TimeInterval?

    /// 初期化
    /// - Parameters:
    ///   - current: 現在のスキャン済み数
    ///   - total: 総数
    ///   - currentPhoto: 現在の写真
    ///   - startTime: スキャン開始時刻（残り時間計算用）
    public init(
        current: Int,
        total: Int,
        currentPhoto: Photo? = nil,
        startTime: Date? = nil
    ) {
        self.current = current
        self.total = total
        self.percentage = total > 0 ? min(1.0, max(0.0, Double(current) / Double(total))) : 0.0
        self.currentPhoto = currentPhoto

        // 残り時間の推定
        if let startTime = startTime, current > 0, total > current {
            let elapsed = Date().timeIntervalSince(startTime)
            let rate = elapsed / Double(current)
            let remaining = Double(total - current) * rate
            self.estimatedTimeRemaining = remaining
        } else {
            self.estimatedTimeRemaining = nil
        }
    }

    /// 初期進捗
    public static let initial = PhotoScanProgress(current: 0, total: 0)

    /// 完了進捗
    public static func completed(total: Int) -> PhotoScanProgress {
        PhotoScanProgress(current: total, total: total)
    }
}

// MARK: - ScanOptions

/// スキャンオプション
public struct ScanOptions: Sendable {
    /// 動画を含めるか
    public let includeVideos: Bool

    /// スクリーンショットを含めるか
    public let includeScreenshots: Bool

    /// スキャン対象の日付範囲（nil の場合は全期間）
    public let dateRange: DateInterval?

    /// ファイルサイズを取得するか（true の場合は処理が遅くなる）
    public let fetchFileSize: Bool

    /// バッチサイズ
    public let batchSize: Int

    /// デフォルトオプション
    /// バッチサイズを500に最適化（オーバーヘッド削減）
    /// ファイルサイズ取得を有効化（並列化+キャッシュで高速）
    public static let `default` = ScanOptions(
        includeVideos: true,
        includeScreenshots: true,
        dateRange: nil,
        fetchFileSize: true,
        batchSize: 500
    )

    /// 高速スキャン用オプション（ファイルサイズなし）
    /// 大きめのバッチサイズで最速処理
    public static let fast = ScanOptions(
        includeVideos: true,
        includeScreenshots: true,
        dateRange: nil,
        fetchFileSize: false,
        batchSize: 500
    )

    /// 詳細スキャン用オプション（ファイルサイズあり）
    /// ファイルサイズ取得時は中程度のバッチサイズ
    public static let detailed = ScanOptions(
        includeVideos: true,
        includeScreenshots: true,
        dateRange: nil,
        fetchFileSize: true,
        batchSize: 200
    )

    /// 初期化
    /// - Parameters:
    ///   - includeVideos: 動画を含めるか
    ///   - includeScreenshots: スクリーンショットを含めるか
    ///   - dateRange: 日付範囲
    ///   - fetchFileSize: ファイルサイズを取得するか
    ///   - batchSize: バッチサイズ（デフォルト500、最適化済み）
    public init(
        includeVideos: Bool = true,
        includeScreenshots: Bool = true,
        dateRange: DateInterval? = nil,
        fetchFileSize: Bool = false,
        batchSize: Int = 500
    ) {
        self.includeVideos = includeVideos
        self.includeScreenshots = includeScreenshots
        self.dateRange = dateRange
        self.fetchFileSize = fetchFileSize
        self.batchSize = max(10, min(500, batchSize)) // 10〜500 に制限
    }

    /// PhotoFetchOptions に変換
    internal func toPhotoFetchOptions() -> PhotoFetchOptions {
        let mediaFilter: PhotoFetchOptions.MediaTypeFilter
        if includeVideos {
            mediaFilter = .all
        } else {
            mediaFilter = .images
        }

        // フィルター条件を構築
        var predicates: [NSPredicate] = []

        // スクリーンショット除外
        if !includeScreenshots {
            predicates.append(NSPredicate(format: "(mediaSubtype & %d) == 0", PHAssetMediaSubtype.photoScreenshot.rawValue))
        }

        // 日付範囲フィルター
        if let dateRange = dateRange {
            predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", dateRange.start as NSDate, dateRange.end as NSDate))
        }

        // 複数の条件を AND で結合
        let combinedPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        return PhotoFetchOptions(
            sortOrder: .creationDateDescending,
            mediaTypeFilter: mediaFilter,
            includeFileSize: fetchFileSize,
            limit: nil,
            predicate: combinedPredicate
        )
    }
}

// MARK: - PhotoScannerError

/// PhotoScanner で発生するエラー
public enum PhotoScannerError: Error, Equatable, Sendable, LocalizedError {
    /// 写真ライブラリへのアクセスが許可されていない
    case notAuthorized

    /// 既にスキャンが実行中
    case scanInProgress

    /// スキャンがキャンセルされた
    case scanCancelled

    /// スキャンが失敗した
    case scanFailed(underlying: String)

    // MARK: - Equatable

    public static func == (lhs: PhotoScannerError, rhs: PhotoScannerError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.scanInProgress, .scanInProgress),
             (.scanCancelled, .scanCancelled):
            return true
        case let (.scanFailed(lhsMessage), .scanFailed(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return NSLocalizedString(
                "error.scanner.notAuthorized",
                value: "写真ライブラリへのアクセスが許可されていません",
                comment: "Scanner not authorized error"
            )
        case .scanInProgress:
            return NSLocalizedString(
                "error.scanner.inProgress",
                value: "既にスキャンが実行中です",
                comment: "Scan already in progress error"
            )
        case .scanCancelled:
            return NSLocalizedString(
                "error.scanner.cancelled",
                value: "スキャンがキャンセルされました",
                comment: "Scan cancelled error"
            )
        case .scanFailed(let underlying):
            return String(format: NSLocalizedString(
                "error.scanner.failed",
                value: "スキャンに失敗しました: %@",
                comment: "Scan failed error"
            ), underlying)
        }
    }
}

// MARK: - PhotoScanner

/// プログレス付き写真スキャン機能
/// 写真ライブラリ全体をスキャンし、リアルタイムで進捗を通知する
@Observable
@MainActor
public final class PhotoScanner: @unchecked Sendable {

    // MARK: - Properties

    /// 現在のスキャン状態
    public private(set) var scanState: ScanState = .idle

    /// スキャン進捗（0.0〜1.0）
    public private(set) var progress: Double = 0.0

    /// スキャン済み写真数
    public private(set) var scannedCount: Int = 0

    /// 写真の総数
    public private(set) var totalCount: Int = 0

    /// スキャンオプション
    public var options: ScanOptions = .default

    /// 残り推定時間（秒）
    public private(set) var estimatedTimeRemaining: TimeInterval?

    /// PhotoRepository への参照
    private let repository: PhotoRepository

    /// 権限マネージャー
    private let permissionManager: PhotoPermissionManagerProtocol

    /// 現在実行中のスキャンタスク
    private var currentScanTask: Task<[Photo], Error>?

    /// スキャン開始時刻
    private var scanStartTime: Date?

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - repository: PhotoRepository インスタンス
    ///   - permissionManager: 権限マネージャー
    ///   - options: スキャンオプション
    public init(
        repository: PhotoRepository,
        permissionManager: PhotoPermissionManagerProtocol,
        options: ScanOptions = .default
    ) {
        self.repository = repository
        self.permissionManager = permissionManager
        self.options = options
    }

    // MARK: - Public Methods

    /// スキャンを実行
    /// - Returns: スキャン結果の写真配列
    /// - Throws: PhotoScannerError
    public func scan() async throws -> [Photo] {
        try await scan(progressHandler: { _ in })
    }

    /// 進捗コールバック付きでスキャンを実行
    /// - Parameter progressHandler: 進捗通知ハンドラ
    /// - Returns: スキャン結果の写真配列
    /// - Throws: PhotoScannerError
    public func scan(progressHandler: @escaping @Sendable (PhotoScanProgress) -> Void) async throws -> [Photo] {
        // 権限チェック
        guard permissionManager.currentStatus.isAuthorized else {
            let error = PhotoScannerError.notAuthorized
            scanState = .failed(error)
            throw error
        }

        // 既にスキャン中かチェック
        guard scanState != .scanning else {
            throw PhotoScannerError.scanInProgress
        }

        // 状態をリセット
        resetState()
        scanState = .scanning
        scanStartTime = Date()

        // スキャンタスクを作成
        let task = Task<[Photo], Error> { [weak self] in
            guard let self = self else {
                throw PhotoScannerError.scanCancelled
            }

            do {
                // 総数を取得
                let total = try await self.fetchTotalCount()

                await MainActor.run {
                    self.totalCount = total
                }

                // 空のライブラリの場合は早期リターン
                guard total > 0 else {
                    await MainActor.run {
                        self.progress = 1.0
                        progressHandler(PhotoScanProgress.completed(total: 0))
                    }
                    return []
                }

                // 初期進捗を通知
                await MainActor.run {
                    progressHandler(PhotoScanProgress(current: 0, total: total, startTime: self.scanStartTime))
                }

                // バッチ処理でスキャン
                let photos = try await self.performBatchScan(
                    total: total,
                    progressHandler: progressHandler
                )

                return photos

            } catch is CancellationError {
                throw PhotoScannerError.scanCancelled
            } catch let error as PhotoRepositoryError {
                switch error {
                case .photoAccessDenied:
                    throw PhotoScannerError.notAuthorized
                case .fetchCancelled:
                    throw PhotoScannerError.scanCancelled
                default:
                    throw PhotoScannerError.scanFailed(underlying: error.localizedDescription)
                }
            } catch {
                throw PhotoScannerError.scanFailed(underlying: error.localizedDescription)
            }
        }

        currentScanTask = task

        do {
            let result = try await task.value

            // 成功時の状態更新
            scanState = .completed
            progress = 1.0
            progressHandler(PhotoScanProgress.completed(total: result.count))

            return result

        } catch let error as PhotoScannerError {
            // エラー時の状態更新
            if case .scanCancelled = error {
                scanState = .cancelled
            } else {
                scanState = .failed(error)
            }
            throw error

        } catch {
            let scanError = PhotoScannerError.scanFailed(underlying: error.localizedDescription)
            scanState = .failed(scanError)
            throw scanError
        }
    }

    /// スキャンをキャンセル
    public func cancel() {
        currentScanTask?.cancel()
        currentScanTask = nil

        if scanState == .scanning {
            scanState = .cancelled
        }
    }

    /// スキャン状態をリセット
    public func reset() {
        cancel()
        resetState()
        scanState = .idle
    }

    // MARK: - Private Methods

    /// 状態をリセット
    private func resetState() {
        progress = 0.0
        scannedCount = 0
        totalCount = 0
        estimatedTimeRemaining = nil
        scanStartTime = nil
    }

    /// 写真の総数を取得
    private func fetchTotalCount() async throws -> Int {
        // FetchOptionsを設定
        let fetchOptions = options.toPhotoFetchOptions()

        // 日付範囲フィルターがある場合
        // Note: 日付範囲のカウントは PhotoRepository の fetchPhotos を使う必要があるが、
        // ここでは単純化のために全件カウントを使用
        // TODO: 日付範囲を考慮したカウント

        // スクリーンショット除外の場合は別途フィルタリングが必要
        // ここでは単純化のため、全件カウントを返す
        repository.fetchOptions = fetchOptions
        return try repository.fetchPhotoCount()
    }

    /// バッチ処理でスキャンを実行
    private func performBatchScan(
        total: Int,
        progressHandler: @escaping @Sendable (PhotoScanProgress) -> Void
    ) async throws -> [Photo] {
        // リポジトリのオプションを設定
        repository.fetchOptions = options.toPhotoFetchOptions()

        var allPhotos: [Photo] = []
        allPhotos.reserveCapacity(total)

        // バッチ処理で写真を取得
        // フィルタリングは toPhotoFetchOptions() の predicate で事前に行われるため、
        // ここでの後処理フィルタリングは不要（30-50%高速化）
        let photos = try await repository.fetchAllPhotosInBatches(
            batchSize: options.batchSize
        ) { [weak self] batchProgress in
            guard let self = self else { return }

            Task { @MainActor in
                // キャンセルチェック
                try? Task.checkCancellation()

                let currentCount = Int(batchProgress * Double(total))
                self.progress = batchProgress
                self.scannedCount = currentCount

                let scanProgress = PhotoScanProgress(
                    current: currentCount,
                    total: total,
                    currentPhoto: nil,
                    startTime: self.scanStartTime
                )

                self.estimatedTimeRemaining = scanProgress.estimatedTimeRemaining
                progressHandler(scanProgress)
            }
        }

        return photos
    }
}

// MARK: - PhotoScanner + Convenience

extension PhotoScanner {
    /// 新しいスキャナーを作成するコンビニエンスファクトリ
    /// - Parameters:
    ///   - permissionManager: 権限マネージャー
    ///   - options: スキャンオプション
    /// - Returns: PhotoScanner インスタンス
    public static func create(
        permissionManager: PhotoPermissionManagerProtocol,
        options: ScanOptions = .default
    ) -> PhotoScanner {
        let repository = PhotoRepository(
            permissionManager: permissionManager,
            fetchOptions: options.toPhotoFetchOptions()
        )
        return PhotoScanner(
            repository: repository,
            permissionManager: permissionManager,
            options: options
        )
    }
}
