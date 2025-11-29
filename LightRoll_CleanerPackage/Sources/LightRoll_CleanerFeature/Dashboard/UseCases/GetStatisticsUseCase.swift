//
//  GetStatisticsUseCase.swift
//  LightRoll_CleanerFeature
//
//  ストレージ統計取得ユースケース
//  CleanupRecordとStorageStatisticsを使用して統計情報を計算・取得
//  Created by AI Assistant
//

import Foundation

// MARK: - GetStatisticsUseCase

/// ストレージ統計取得ユースケースの実装
/// デバイスのストレージ情報、グループ統計、クリーンアップ履歴を統合
///
/// ## 主な責務
/// - StorageInfoからデバイスストレージ情報を取得
/// - グループ統計を集計
/// - クリーンアップ履歴を参照
/// - 統計情報を統合して返却
///
/// ## 使用例
/// ```swift
/// let useCase = GetStatisticsUseCase(
///     photoRepository: repository,
///     cleanupRecordProvider: cleanupProvider
/// )
///
/// let stats = try await useCase.execute()
/// print("Total: \(stats.storageInfo.formattedTotalCapacity)")
/// ```
@MainActor
public final class GetStatisticsUseCase: GetStatisticsUseCaseProtocol {

    // MARK: - Properties

    /// PhotoRepository インスタンス
    private let photoRepository: PhotoRepository

    /// クリーンアップ履歴プロバイダー
    private let cleanupRecordProvider: CleanupRecordProviderProtocol?

    /// グループ情報プロバイダー（キャッシュされたスキャン結果）
    private let groupProvider: GroupProviderProtocol?

    /// 最終スキャン日時プロバイダー
    private let lastScanDateProvider: LastScanDateProviderProtocol?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photoRepository: PhotoRepository インスタンス
    ///   - cleanupRecordProvider: クリーンアップ履歴プロバイダー（オプション）
    ///   - groupProvider: グループ情報プロバイダー（オプション）
    ///   - lastScanDateProvider: 最終スキャン日時プロバイダー（オプション）
    public init(
        photoRepository: PhotoRepository,
        cleanupRecordProvider: CleanupRecordProviderProtocol? = nil,
        groupProvider: GroupProviderProtocol? = nil,
        lastScanDateProvider: LastScanDateProviderProtocol? = nil
    ) {
        self.photoRepository = photoRepository
        self.cleanupRecordProvider = cleanupRecordProvider
        self.groupProvider = groupProvider
        self.lastScanDateProvider = lastScanDateProvider
    }

    // MARK: - GetStatisticsUseCaseProtocol

    /// 統計情報を取得
    /// - Returns: StatisticsOutput
    /// - Throws: GetStatisticsUseCaseError
    public func execute() async throws -> StatisticsOutput {
        do {
            // ストレージ情報を取得
            let storageInfo = try await fetchStorageInfo()

            // 写真総数を取得
            let totalPhotos = try await fetchPhotoCount()

            // グループ統計を取得
            let groupStatistics = await fetchGroupStatistics()

            // 最終スキャン日時を取得
            let lastScanDate = await fetchLastScanDate()

            return StatisticsOutput(
                storageInfo: storageInfo,
                totalPhotos: totalPhotos,
                groupStatistics: groupStatistics,
                lastScanDate: lastScanDate
            )
        } catch let error as GetStatisticsUseCaseError {
            throw error
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Private Methods

    /// ストレージ情報を取得
    private func fetchStorageInfo() async throws -> StorageInfo {
        do {
            // グループ情報がある場合は削減可能容量も計算
            if let groupProvider = groupProvider {
                let groups = await groupProvider.getGroups()
                if !groups.isEmpty {
                    return try await photoRepository.getStorageInfo(withReclaimableFrom: groups)
                }
            }
            return try await photoRepository.getStorageInfo()
        } catch let error as PhotoRepositoryError {
            switch error {
            case .photoAccessDenied:
                throw GetStatisticsUseCaseError.photoAccessDenied
            case .storageInfoUnavailable:
                throw GetStatisticsUseCaseError.storageInfoUnavailable
            default:
                throw GetStatisticsUseCaseError.fetchFailed(reason: error.localizedDescription)
            }
        }
    }

    /// 写真総数を取得
    private func fetchPhotoCount() async throws -> Int {
        do {
            return try photoRepository.fetchPhotoCount()
        } catch let error as PhotoRepositoryError {
            switch error {
            case .photoAccessDenied:
                throw GetStatisticsUseCaseError.photoAccessDenied
            default:
                // 写真数取得に失敗しても0を返す（致命的ではない）
                return 0
            }
        }
    }

    /// グループ統計を取得
    private func fetchGroupStatistics() async -> GroupStatistics {
        guard let groupProvider = groupProvider else {
            return GroupStatistics()
        }

        let groups = await groupProvider.getGroups()

        // グループタイプ別に集計
        var similarGroupCount = 0
        var screenshotCount = 0
        var blurryCount = 0
        var largeVideoCount = 0

        for group in groups {
            switch group.type {
            case .similar, .duplicate, .selfie:
                similarGroupCount += 1
            case .screenshot:
                screenshotCount += group.count
            case .blurry:
                blurryCount += group.count
            case .largeVideo:
                largeVideoCount += group.count
            }
        }

        // ゴミ箱内の写真数を取得
        let trashCount = await fetchTrashCount()

        return GroupStatistics(
            similarGroupCount: similarGroupCount,
            screenshotCount: screenshotCount,
            blurryCount: blurryCount,
            largeVideoCount: largeVideoCount,
            trashCount: trashCount
        )
    }

    /// ゴミ箱内の写真数を取得
    private func fetchTrashCount() async -> Int {
        // TrashManagerが実装されたら連携
        // 現時点では0を返す
        return 0
    }

    /// 最終スキャン日時を取得
    private func fetchLastScanDate() async -> Date? {
        await lastScanDateProvider?.getLastScanDate()
    }

    /// エラーをマッピング
    private func mapError(_ error: Error) -> GetStatisticsUseCaseError {
        if let repositoryError = error as? PhotoRepositoryError {
            switch repositoryError {
            case .photoAccessDenied:
                return .photoAccessDenied
            case .storageInfoUnavailable:
                return .storageInfoUnavailable
            default:
                return .fetchFailed(reason: repositoryError.localizedDescription)
            }
        }

        return .fetchFailed(reason: error.localizedDescription)
    }
}

// MARK: - GetStatisticsUseCaseError

/// GetStatisticsUseCase で発生するエラー
public enum GetStatisticsUseCaseError: Error, LocalizedError, Equatable, Sendable {
    /// 写真ライブラリへのアクセスが拒否された
    case photoAccessDenied

    /// ストレージ情報が取得できない
    case storageInfoUnavailable

    /// データ取得に失敗した
    case fetchFailed(reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.statistics.photoAccessDenied",
                value: "写真ライブラリへのアクセスが許可されていません",
                comment: "Photo access denied error"
            )
        case .storageInfoUnavailable:
            return NSLocalizedString(
                "error.statistics.storageInfoUnavailable",
                value: "ストレージ情報を取得できませんでした",
                comment: "Storage info unavailable error"
            )
        case .fetchFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.statistics.fetchFailed",
                    value: "統計情報の取得に失敗しました: %@",
                    comment: "Fetch failed error"
                ),
                reason
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.statistics.photoAccessDenied.suggestion",
                value: "設定アプリから写真へのアクセスを許可してください",
                comment: "Photo access denied recovery suggestion"
            )
        case .storageInfoUnavailable:
            return NSLocalizedString(
                "error.statistics.storageInfoUnavailable.suggestion",
                value: "デバイスを再起動してから再度お試しください",
                comment: "Storage info unavailable recovery suggestion"
            )
        case .fetchFailed:
            return NSLocalizedString(
                "error.statistics.fetchFailed.suggestion",
                value: "しばらく待ってから再度お試しください",
                comment: "Fetch failed recovery suggestion"
            )
        }
    }
}

// MARK: - Provider Protocols

/// クリーンアップ履歴プロバイダープロトコル
/// クリーンアップ履歴を提供するためのインターフェース
public protocol CleanupRecordProviderProtocol: Sendable {
    /// クリーンアップ履歴を取得
    /// - Returns: クリーンアップ履歴の配列
    func getRecords() async -> [CleanupRecord]

    /// 指定期間内のクリーンアップ履歴を取得
    /// - Parameters:
    ///   - start: 開始日時
    ///   - end: 終了日時
    /// - Returns: フィルタされたクリーンアップ履歴の配列
    func getRecords(from start: Date, to end: Date) async -> [CleanupRecord]

    /// 統計情報を取得
    /// - Returns: クリーンアップ履歴の統計
    func getStatistics() async -> CleanupRecordStatistics
}

/// グループ情報プロバイダープロトコル
/// スキャン結果のグループ情報を提供するためのインターフェース
public protocol GroupProviderProtocol: Sendable {
    /// グループ情報を取得
    /// - Returns: PhotoGroupの配列
    func getGroups() async -> [PhotoGroup]

    /// 指定タイプのグループを取得
    /// - Parameter type: グループタイプ
    /// - Returns: フィルタされたPhotoGroupの配列
    func getGroups(ofType type: GroupType) async -> [PhotoGroup]
}

/// 最終スキャン日時プロバイダープロトコル
/// 最終スキャン日時を提供するためのインターフェース
public protocol LastScanDateProviderProtocol: Sendable {
    /// 最終スキャン日時を取得
    /// - Returns: 最終スキャン日時（スキャン未実行の場合はnil）
    func getLastScanDate() async -> Date?

    /// 最終スキャン日時を更新
    /// - Parameter date: 新しいスキャン日時
    func setLastScanDate(_ date: Date) async
}

// MARK: - GetStatisticsUseCase + Factory

extension GetStatisticsUseCase {
    /// コンビニエンスファクトリ
    /// - Parameter permissionManager: 権限マネージャー
    /// - Returns: GetStatisticsUseCase インスタンス
    @MainActor
    public static func create(
        permissionManager: PhotoPermissionManagerProtocol
    ) -> GetStatisticsUseCase {
        let repository = PhotoRepository(
            permissionManager: permissionManager
        )

        return GetStatisticsUseCase(
            photoRepository: repository
        )
    }
}

// MARK: - Extended Statistics

/// 拡張統計情報
/// StorageStatisticsとの統合や詳細な統計を提供
public struct ExtendedStatistics: Sendable, Equatable {

    /// 基本統計情報
    public let basicStats: StatisticsOutput

    /// ストレージ統計（StorageStatistics形式）
    public let storageStatistics: StorageStatistics?

    /// クリーンアップ履歴統計
    public let cleanupStatistics: CleanupRecordStatistics

    /// 前回スキャンからの経過時間
    public let timeSinceLastScan: TimeInterval?

    // MARK: - Initialization

    public init(
        basicStats: StatisticsOutput,
        storageStatistics: StorageStatistics? = nil,
        cleanupStatistics: CleanupRecordStatistics = .empty,
        timeSinceLastScan: TimeInterval? = nil
    ) {
        self.basicStats = basicStats
        self.storageStatistics = storageStatistics
        self.cleanupStatistics = cleanupStatistics
        self.timeSinceLastScan = timeSinceLastScan
    }

    // MARK: - Computed Properties

    /// スキャンが推奨されるかどうか
    /// 7日以上スキャンしていない場合はtrue
    public var shouldRecommendScan: Bool {
        guard let timeSince = timeSinceLastScan else {
            return true // 一度もスキャンしていない
        }
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        return timeSince > sevenDays
    }

    /// フォーマット済み経過時間
    public var formattedTimeSinceLastScan: String? {
        guard let timeSince = timeSinceLastScan else {
            return nil
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1

        return formatter.string(from: timeSince)
    }

    /// 累計削減容量
    public var totalFreedSpace: Int64 {
        cleanupStatistics.totalFreedSpace
    }

    /// フォーマット済み累計削減容量
    public var formattedTotalFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalFreedSpace, countStyle: .file)
    }

    /// 累計削除枚数
    public var totalDeletedCount: Int {
        cleanupStatistics.totalDeletedCount
    }
}

// MARK: - GetStatisticsUseCase + Extended

extension GetStatisticsUseCase {
    /// 拡張統計情報を取得
    /// 基本統計に加えてクリーンアップ履歴や経過時間を含む
    /// - Returns: ExtendedStatistics
    /// - Throws: GetStatisticsUseCaseError
    public func executeExtended() async throws -> ExtendedStatistics {
        // 基本統計を取得
        let basicStats = try await execute()

        // クリーンアップ履歴統計を取得
        let cleanupStatistics = await cleanupRecordProvider?.getStatistics() ?? .empty

        // 経過時間を計算
        let timeSinceLastScan: TimeInterval?
        if let lastScanDate = basicStats.lastScanDate {
            timeSinceLastScan = Date().timeIntervalSince(lastScanDate)
        } else {
            timeSinceLastScan = nil
        }

        // StorageStatisticsを生成（グループ情報がある場合）
        var storageStatistics: StorageStatistics?
        if let groupProvider = groupProvider {
            let groups = await groupProvider.getGroups()
            if !groups.isEmpty {
                storageStatistics = StorageStatistics(
                    storageInfo: basicStats.storageInfo,
                    groups: groups,
                    scannedPhotoCount: basicStats.totalPhotos
                )
            }
        }

        return ExtendedStatistics(
            basicStats: basicStats,
            storageStatistics: storageStatistics,
            cleanupStatistics: cleanupStatistics,
            timeSinceLastScan: timeSinceLastScan
        )
    }
}
