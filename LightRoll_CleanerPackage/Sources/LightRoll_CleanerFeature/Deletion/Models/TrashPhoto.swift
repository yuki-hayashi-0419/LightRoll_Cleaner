//
//  TrashPhoto.swift
//  LightRoll_CleanerFeature
//
//  ゴミ箱写真のドメインモデル
//  削除された写真を30日間保持し、復元または自動削除を管理
//  Created by AI Assistant
//

import Foundation

// MARK: - TrashPhoto

/// ゴミ箱に移動された写真を表すドメインモデル
/// 元の写真情報を保持し、30日後に自動削除される
/// Sendable 準拠により Swift Concurrency で安全に使用可能
public struct TrashPhoto: Identifiable, Sendable, Codable, Hashable {

    // MARK: - Constants

    /// デフォルトの保持日数
    public static let defaultRetentionDays: Int = 30

    // MARK: - Properties

    /// ゴミ箱アイテムの一意な識別子
    public let id: UUID

    /// 元の写真の識別子（Photo.localIdentifier に対応）
    public let originalPhotoId: String

    /// 元の写真のアセットパス（復元時の参照用）
    public let originalAssetIdentifier: String

    /// サムネイル画像データ（JPEG圧縮、表示用）
    public let thumbnailData: Data?

    /// ゴミ箱への移動日時
    public let deletedAt: Date

    /// 自動削除予定日時
    public let expiresAt: Date

    /// ファイルサイズ（バイト）
    public let fileSize: Int64

    /// 元の写真のメタデータ
    public let metadata: TrashPhotoMetadata

    /// 削除理由（オプション）
    public let deletionReason: DeletionReason?

    // MARK: - Nested Types

    /// 削除理由
    public enum DeletionReason: String, Sendable, Codable, CaseIterable {
        /// ユーザーによる手動削除
        case userSelected

        /// 類似写真としてグループから削除
        case similarPhoto

        /// ブレ・ピンボケ写真として削除
        case blurryPhoto

        /// スクリーンショットとして削除
        case screenshot

        /// 一括クリーンアップによる削除
        case bulkCleanup

        /// 表示名
        public var displayName: String {
            switch self {
            case .userSelected:
                return NSLocalizedString("deletionReason.userSelected", value: "手動選択", comment: "User selected")
            case .similarPhoto:
                return NSLocalizedString("deletionReason.similarPhoto", value: "類似写真", comment: "Similar photo")
            case .blurryPhoto:
                return NSLocalizedString("deletionReason.blurryPhoto", value: "ブレ写真", comment: "Blurry photo")
            case .screenshot:
                return NSLocalizedString("deletionReason.screenshot", value: "スクリーンショット", comment: "Screenshot")
            case .bulkCleanup:
                return NSLocalizedString("deletionReason.bulkCleanup", value: "一括削除", comment: "Bulk cleanup")
            }
        }

        /// アイコン（SF Symbol名）
        public var icon: String {
            switch self {
            case .userSelected:
                return "hand.tap"
            case .similarPhoto:
                return "square.on.square"
            case .blurryPhoto:
                return "camera.metering.unknown"
            case .screenshot:
                return "rectangle.dashed"
            case .bulkCleanup:
                return "sparkles"
            }
        }
    }

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - id: ゴミ箱アイテムID（デフォルトは新規UUID）
    ///   - originalPhotoId: 元の写真ID
    ///   - originalAssetIdentifier: 元のアセット識別子
    ///   - thumbnailData: サムネイルデータ
    ///   - deletedAt: 削除日時（デフォルトは現在時刻）
    ///   - expiresAt: 有効期限日時（指定がない場合は30日後）
    ///   - fileSize: ファイルサイズ
    ///   - metadata: メタデータ
    ///   - deletionReason: 削除理由
    public init(
        id: UUID = UUID(),
        originalPhotoId: String,
        originalAssetIdentifier: String,
        thumbnailData: Data?,
        deletedAt: Date = Date(),
        expiresAt: Date? = nil,
        fileSize: Int64,
        metadata: TrashPhotoMetadata,
        deletionReason: DeletionReason? = nil
    ) {
        self.id = id
        self.originalPhotoId = originalPhotoId
        self.originalAssetIdentifier = originalAssetIdentifier
        self.thumbnailData = thumbnailData
        self.deletedAt = deletedAt
        self.expiresAt = expiresAt ?? Calendar.current.date(
            byAdding: .day,
            value: Self.defaultRetentionDays,
            to: deletedAt
        ) ?? deletedAt.addingTimeInterval(TimeInterval(Self.defaultRetentionDays * 24 * 60 * 60))
        self.fileSize = Swift.max(0, fileSize)
        self.metadata = metadata
        self.deletionReason = deletionReason
    }

    /// Photo モデルから TrashPhoto を作成
    /// - Parameters:
    ///   - photo: 元の Photo オブジェクト
    ///   - thumbnailData: サムネイルデータ
    ///   - deletionReason: 削除理由
    /// - Returns: TrashPhoto インスタンス
    public static func from(
        photo: Photo,
        thumbnailData: Data?,
        deletionReason: DeletionReason? = nil
    ) -> TrashPhoto {
        TrashPhoto(
            originalPhotoId: photo.id,
            originalAssetIdentifier: photo.localIdentifier,
            thumbnailData: thumbnailData,
            fileSize: photo.fileSize,
            metadata: TrashPhotoMetadata(
                creationDate: photo.creationDate,
                pixelWidth: photo.pixelWidth,
                pixelHeight: photo.pixelHeight,
                mediaType: photo.mediaType,
                mediaSubtypes: photo.mediaSubtypes,
                isFavorite: photo.isFavorite
            ),
            deletionReason: deletionReason
        )
    }

    // MARK: - Computed Properties

    /// 期限切れかどうか
    public var isExpired: Bool {
        Date() > expiresAt
    }

    /// 復元可能かどうか（期限切れでない）
    public var isRestorable: Bool {
        !isExpired
    }

    /// 残り日数（期限切れの場合は負の値）
    public var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }

    /// 残り時間（秒）
    public var secondsUntilExpiration: TimeInterval {
        expiresAt.timeIntervalSince(Date())
    }

    /// フォーマット済み残り期間
    public var formattedTimeRemaining: String {
        let days = daysUntilExpiration
        if days <= 0 {
            return NSLocalizedString("trashPhoto.expired", value: "期限切れ", comment: "Expired")
        } else if days == 1 {
            return NSLocalizedString("trashPhoto.1dayRemaining", value: "残り1日", comment: "1 day remaining")
        } else {
            return String(
                format: NSLocalizedString("trashPhoto.daysRemaining", value: "残り%d日", comment: "Days remaining"),
                days
            )
        }
    }

    /// フォーマット済みファイルサイズ
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// フォーマット済み削除日時
    public var formattedDeletedAt: String {
        Self.dateFormatter.string(from: deletedAt)
    }

    /// フォーマット済み有効期限日時
    public var formattedExpiresAt: String {
        Self.dateFormatter.string(from: expiresAt)
    }

    /// 相対的な削除日時（「今日」「昨日」など）
    public var formattedRelativeDeletedAt: String {
        Self.relativeDateFormatter.localizedString(for: deletedAt, relativeTo: Date())
    }

    /// 解像度文字列（例: 「4032 × 3024」）
    public var resolution: String {
        "\(metadata.pixelWidth) × \(metadata.pixelHeight)"
    }

    /// 動画かどうか
    public var isVideo: Bool {
        metadata.mediaType == .video
    }

    /// スクリーンショットかどうか
    public var isScreenshot: Bool {
        metadata.mediaSubtypes.contains(.screenshot)
    }

    /// サムネイルを持っているかどうか
    public var hasThumbnail: Bool {
        thumbnailData != nil && !thumbnailData!.isEmpty
    }

    // MARK: - Date Formatters (Static)

    /// 日付フォーマッタ
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    /// 相対日付フォーマッタ
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - TrashPhotoMetadata

/// ゴミ箱写真の元のメタデータ
public struct TrashPhotoMetadata: Sendable, Codable, Hashable {

    /// 元の写真の作成日時
    public let creationDate: Date

    /// 横幅（ピクセル）
    public let pixelWidth: Int

    /// 高さ（ピクセル）
    public let pixelHeight: Int

    /// メディアタイプ
    public let mediaType: MediaType

    /// メディアサブタイプ
    public let mediaSubtypes: MediaSubtypes

    /// お気に入りだったかどうか
    public let isFavorite: Bool

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    public init(
        creationDate: Date,
        pixelWidth: Int,
        pixelHeight: Int,
        mediaType: MediaType,
        mediaSubtypes: MediaSubtypes,
        isFavorite: Bool
    ) {
        self.creationDate = creationDate
        self.pixelWidth = Swift.max(0, pixelWidth)
        self.pixelHeight = Swift.max(0, pixelHeight)
        self.mediaType = mediaType
        self.mediaSubtypes = mediaSubtypes
        self.isFavorite = isFavorite
    }

    /// シンプルイニシャライザ（必須項目のみ）
    public init(
        creationDate: Date,
        pixelWidth: Int,
        pixelHeight: Int
    ) {
        self.init(
            creationDate: creationDate,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            mediaType: .image,
            mediaSubtypes: [],
            isFavorite: false
        )
    }

    // MARK: - Computed Properties

    /// アスペクト比
    public var aspectRatio: Double {
        guard pixelHeight > 0 else { return 1.0 }
        return Double(pixelWidth) / Double(pixelHeight)
    }

    /// 総ピクセル数
    public var totalPixels: Int {
        pixelWidth * pixelHeight
    }

    /// メガピクセル数
    public var megapixels: Double {
        Double(totalPixels) / 1_000_000.0
    }

    /// フォーマット済み作成日時
    public var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

// MARK: - TrashPhotoError

/// ゴミ箱操作のエラー型
public enum TrashPhotoError: LocalizedError, Sendable {
    /// 写真が期限切れで復元不可
    case photoExpired(photoId: String)

    /// ゴミ箱に写真が見つからない
    case photoNotFound(photoId: String)

    /// 復元処理の失敗
    case restorationFailed(underlying: Error)

    /// ストレージエラー
    case storageError(underlying: Error)

    /// 無効なデータ
    case invalidData(reason: String)

    /// 権限エラー
    case permissionDenied

    public var errorDescription: String? {
        switch self {
        case .photoExpired(let photoId):
            return String(
                format: NSLocalizedString(
                    "trashPhotoError.expired",
                    value: "写真が期限切れです: %@",
                    comment: "Photo expired error"
                ),
                photoId
            )
        case .photoNotFound(let photoId):
            return String(
                format: NSLocalizedString(
                    "trashPhotoError.notFound",
                    value: "写真が見つかりません: %@",
                    comment: "Photo not found error"
                ),
                photoId
            )
        case .restorationFailed:
            return NSLocalizedString(
                "trashPhotoError.restorationFailed",
                value: "写真の復元に失敗しました",
                comment: "Restoration failed error"
            )
        case .storageError:
            return NSLocalizedString(
                "trashPhotoError.storageError",
                value: "ストレージエラーが発生しました",
                comment: "Storage error"
            )
        case .invalidData(let reason):
            return String(
                format: NSLocalizedString(
                    "trashPhotoError.invalidData",
                    value: "無効なデータ: %@",
                    comment: "Invalid data error"
                ),
                reason
            )
        case .permissionDenied:
            return NSLocalizedString(
                "trashPhotoError.permissionDenied",
                value: "写真へのアクセス権限がありません",
                comment: "Permission denied error"
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .photoExpired:
            return NSLocalizedString(
                "trashPhotoError.expired.reason",
                value: "30日の保持期間を過ぎたため、この写真は復元できません",
                comment: "Photo expired reason"
            )
        case .photoNotFound:
            return NSLocalizedString(
                "trashPhotoError.notFound.reason",
                value: "指定された写真がゴミ箱に存在しません",
                comment: "Photo not found reason"
            )
        case .restorationFailed(let underlying):
            return underlying.localizedDescription
        case .storageError(let underlying):
            return underlying.localizedDescription
        case .invalidData:
            return nil
        case .permissionDenied:
            return NSLocalizedString(
                "trashPhotoError.permissionDenied.reason",
                value: "設定アプリから写真へのアクセスを許可してください",
                comment: "Permission denied reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .photoExpired:
            return nil
        case .photoNotFound:
            return NSLocalizedString(
                "trashPhotoError.notFound.suggestion",
                value: "ゴミ箱を更新してください",
                comment: "Photo not found suggestion"
            )
        case .restorationFailed:
            return NSLocalizedString(
                "trashPhotoError.restorationFailed.suggestion",
                value: "もう一度お試しください",
                comment: "Restoration failed suggestion"
            )
        case .storageError:
            return NSLocalizedString(
                "trashPhotoError.storageError.suggestion",
                value: "ストレージの空き容量を確認してください",
                comment: "Storage error suggestion"
            )
        case .invalidData:
            return nil
        case .permissionDenied:
            return NSLocalizedString(
                "trashPhotoError.permissionDenied.suggestion",
                value: "設定アプリを開いて権限を付与してください",
                comment: "Permission denied suggestion"
            )
        }
    }
}

// MARK: - TrashPhoto + CustomStringConvertible

extension TrashPhoto: CustomStringConvertible {
    public var description: String {
        """
        TrashPhoto(\
        id: \(id.uuidString.prefix(8))..., \
        original: \(originalPhotoId.prefix(8))..., \
        size: \(formattedFileSize), \
        expires: \(formattedTimeRemaining))
        """
    }
}

// MARK: - TrashPhoto + Comparable

extension TrashPhoto: Comparable {
    /// 削除日時で比較（新しい順）
    public static func < (lhs: TrashPhoto, rhs: TrashPhoto) -> Bool {
        lhs.deletedAt > rhs.deletedAt
    }
}

// MARK: - TrashPhotoStatistics

/// ゴミ箱の統計情報
public struct TrashPhotoStatistics: Sendable, Equatable {

    /// ゴミ箱内の写真総数
    public let totalCount: Int

    /// 合計ファイルサイズ（バイト）
    public let totalSize: Int64

    /// 期限切れ間近（7日以内）の写真数
    public let expiringCount: Int

    /// 既に期限切れの写真数
    public let expiredCount: Int

    /// 削除理由別の写真数
    public let countByReason: [TrashPhoto.DeletionReason: Int]

    /// 最も古い削除日時
    public let oldestDeletedAt: Date?

    /// 最も新しい削除日時
    public let newestDeletedAt: Date?

    // MARK: - Computed Properties

    /// フォーマット済み合計サイズ
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// 復元可能な写真数
    public var restorableCount: Int {
        totalCount - expiredCount
    }

    /// 空のゴミ箱かどうか
    public var isEmpty: Bool {
        totalCount == 0
    }

    /// 空の統計
    public static let empty = TrashPhotoStatistics(
        totalCount: 0,
        totalSize: 0,
        expiringCount: 0,
        expiredCount: 0,
        countByReason: [:],
        oldestDeletedAt: nil,
        newestDeletedAt: nil
    )
}

// MARK: - Array Extension for TrashPhoto

extension Array where Element == TrashPhoto {

    // MARK: - Filtering

    /// 期限切れの写真のみ抽出
    public var expiredPhotos: [TrashPhoto] {
        filter { $0.isExpired }
    }

    /// 復元可能な写真のみ抽出
    public var restorablePhotos: [TrashPhoto] {
        filter { $0.isRestorable }
    }

    /// 指定日数以内に期限切れとなる写真を抽出
    /// - Parameter days: 日数（デフォルトは7日）
    /// - Returns: フィルタされた写真配列
    public func expiringWithin(days: Int = 7) -> [TrashPhoto] {
        filter { photo in
            let remaining = photo.daysUntilExpiration
            return remaining > 0 && remaining <= days
        }
    }

    /// 指定した削除理由の写真のみ抽出
    /// - Parameter reason: 削除理由
    /// - Returns: フィルタされた写真配列
    public func filterByReason(_ reason: TrashPhoto.DeletionReason) -> [TrashPhoto] {
        filter { $0.deletionReason == reason }
    }

    // MARK: - Sorting

    /// 削除日時で降順ソート（新しい順）
    public var sortedByDeletedAtDescending: [TrashPhoto] {
        sorted { $0.deletedAt > $1.deletedAt }
    }

    /// 削除日時で昇順ソート（古い順）
    public var sortedByDeletedAtAscending: [TrashPhoto] {
        sorted { $0.deletedAt < $1.deletedAt }
    }

    /// 有効期限で昇順ソート（期限が近い順）
    public var sortedByExpiresAtAscending: [TrashPhoto] {
        sorted { $0.expiresAt < $1.expiresAt }
    }

    /// ファイルサイズで降順ソート
    public var sortedByFileSizeDescending: [TrashPhoto] {
        sorted { $0.fileSize > $1.fileSize }
    }

    // MARK: - Statistics

    /// 統計情報を計算
    public var statistics: TrashPhotoStatistics {
        var countByReason: [TrashPhoto.DeletionReason: Int] = [:]

        for photo in self {
            if let reason = photo.deletionReason {
                countByReason[reason, default: 0] += 1
            }
        }

        let sortedByDeleted = sortedByDeletedAtDescending

        return TrashPhotoStatistics(
            totalCount: count,
            totalSize: reduce(0) { $0 + $1.fileSize },
            expiringCount: expiringWithin(days: 7).count,
            expiredCount: expiredPhotos.count,
            countByReason: countByReason,
            oldestDeletedAt: sortedByDeleted.last?.deletedAt,
            newestDeletedAt: sortedByDeleted.first?.deletedAt
        )
    }

    /// 合計ファイルサイズ
    public var totalSize: Int64 {
        reduce(0) { $0 + $1.fileSize }
    }

    /// フォーマット済み合計サイズ
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    // MARK: - Grouping

    /// 削除日でグルーピング
    public var groupedByDeletedDay: [Date: [TrashPhoto]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { photo in
            calendar.startOfDay(for: photo.deletedAt)
        }
    }

    /// 削除理由でグルーピング
    public var groupedByReason: [TrashPhoto.DeletionReason?: [TrashPhoto]] {
        Dictionary(grouping: self) { $0.deletionReason }
    }
}
