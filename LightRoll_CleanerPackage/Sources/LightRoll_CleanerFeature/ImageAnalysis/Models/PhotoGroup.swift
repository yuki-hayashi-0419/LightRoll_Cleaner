//
//  PhotoGroup.swift
//  LightRoll_CleanerFeature
//
//  写真グループのドメインモデル
//  類似写真、スクリーンショット、自撮り等のグルーピング結果を表現
//  Created by AI Assistant
//

import Foundation

// MARK: - GroupType

/// 写真グループの種類
/// 各グループタイプには異なる検出ロジックと表示特性がある
public enum GroupType: String, CaseIterable, Sendable, Codable, Hashable {
    /// 類似写真（連写含む）
    case similar

    /// 自撮り写真
    case selfie

    /// スクリーンショット
    case screenshot

    /// ブレ・ピンボケ写真
    case blurry

    /// 大容量動画
    case largeVideo

    /// 重複写真（完全一致）
    case duplicate

    // MARK: - Display Properties

    /// 表示名（日本語）
    public var displayName: String {
        switch self {
        case .similar:
            return NSLocalizedString("groupType.similar", value: "類似写真", comment: "Similar photos group")
        case .selfie:
            return NSLocalizedString("groupType.selfie", value: "自撮り", comment: "Selfie photos group")
        case .screenshot:
            return NSLocalizedString("groupType.screenshot", value: "スクリーンショット", comment: "Screenshot group")
        case .blurry:
            return NSLocalizedString("groupType.blurry", value: "ブレ写真", comment: "Blurry photos group")
        case .largeVideo:
            return NSLocalizedString("groupType.largeVideo", value: "大容量動画", comment: "Large video group")
        case .duplicate:
            return NSLocalizedString("groupType.duplicate", value: "重複写真", comment: "Duplicate photos group")
        }
    }

    /// SF Symbol アイコン名
    public var icon: String {
        switch self {
        case .similar:
            return "square.on.square"
        case .selfie:
            return "person.crop.circle"
        case .screenshot:
            return "rectangle.dashed"
        case .blurry:
            return "camera.metering.unknown"
        case .largeVideo:
            return "video.fill"
        case .duplicate:
            return "doc.on.doc"
        }
    }

    /// グループタイプの説明
    public var description: String {
        switch self {
        case .similar:
            return NSLocalizedString(
                "groupType.similar.description",
                value: "連写や似たような構図の写真をグルーピング",
                comment: "Similar photos description"
            )
        case .selfie:
            return NSLocalizedString(
                "groupType.selfie.description",
                value: "自撮りで撮影された写真",
                comment: "Selfie description"
            )
        case .screenshot:
            return NSLocalizedString(
                "groupType.screenshot.description",
                value: "画面キャプチャした画像",
                comment: "Screenshot description"
            )
        case .blurry:
            return NSLocalizedString(
                "groupType.blurry.description",
                value: "ピンボケや手ブレのある写真",
                comment: "Blurry photos description"
            )
        case .largeVideo:
            return NSLocalizedString(
                "groupType.largeVideo.description",
                value: "ストレージを多く消費する動画",
                comment: "Large video description"
            )
        case .duplicate:
            return NSLocalizedString(
                "groupType.duplicate.description",
                value: "完全に同一の写真",
                comment: "Duplicate photos description"
            )
        }
    }

    /// 絵文字表現
    public var emoji: String {
        switch self {
        case .similar:
            return "📸"
        case .selfie:
            return "🤳"
        case .screenshot:
            return "📱"
        case .blurry:
            return "🌫️"
        case .largeVideo:
            return "🎬"
        case .duplicate:
            return "👯"
        }
    }

    /// ソート順（ダッシュボード表示用）
    public var sortOrder: Int {
        switch self {
        case .duplicate:
            return 0
        case .similar:
            return 1
        case .blurry:
            return 2
        case .screenshot:
            return 3
        case .selfie:
            return 4
        case .largeVideo:
            return 5
        }
    }

    /// 自動削除が推奨されるかどうか
    public var isAutoDeleteRecommended: Bool {
        switch self {
        case .duplicate, .blurry:
            return true
        case .similar, .screenshot, .selfie, .largeVideo:
            return false
        }
    }

    /// ベストショット選定が必要かどうか
    public var needsBestShotSelection: Bool {
        switch self {
        case .similar, .selfie:
            return true
        case .screenshot, .blurry, .largeVideo, .duplicate:
            return false
        }
    }
}

// MARK: - PhotoGroup

/// 写真グループを表すドメインモデル
/// 類似写真や同種の写真をグルーピングし、ベストショット選定と削除候補の管理を行う
/// Sendable 準拠により Swift Concurrency で安全に使用可能
public struct PhotoGroup: Identifiable, Hashable, Sendable {

    // MARK: - Properties

    /// グループの一意な識別子
    public let id: UUID

    /// グループの種類
    public let type: GroupType

    /// グループに含まれる写真ID一覧
    /// 実際の Photo オブジェクトは必要に応じてリポジトリから取得
    public var photoIds: [String]

    /// 各写真のファイルサイズ（photoIds と同じ順序）
    public var fileSizes: [Int64]

    /// ベストショットのインデックス（nil の場合は未選定）
    public var bestShotIndex: Int?

    /// 選択状態（削除対象として選択されているか）
    public var isSelected: Bool

    /// グループ作成日時
    public let createdAt: Date

    /// 類似度スコア（similar/duplicate タイプの場合のみ有効）
    public let similarityScore: Float?

    /// グループ名（カスタム名、nil の場合は type.displayName を使用）
    public var customName: String?

    // MARK: - Initialization

    /// 標準イニシャライザ
    /// - Parameters:
    ///   - id: グループID（デフォルトは新規UUID）
    ///   - type: グループタイプ
    ///   - photoIds: 写真ID配列
    ///   - fileSizes: 各写真のファイルサイズ配列
    ///   - bestShotIndex: ベストショットインデックス
    ///   - isSelected: 選択状態
    ///   - createdAt: 作成日時
    ///   - similarityScore: 類似度スコア
    ///   - customName: カスタム名
    public init(
        id: UUID = UUID(),
        type: GroupType,
        photoIds: [String],
        fileSizes: [Int64] = [],
        bestShotIndex: Int? = nil,
        isSelected: Bool = false,
        createdAt: Date = Date(),
        similarityScore: Float? = nil,
        customName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.photoIds = photoIds
        // fileSizes が空の場合は photoIds と同じ数の 0 を設定
        self.fileSizes = fileSizes.isEmpty
            ? Array(repeating: 0, count: photoIds.count)
            : fileSizes
        self.bestShotIndex = bestShotIndex
        self.isSelected = isSelected
        self.createdAt = createdAt
        self.similarityScore = similarityScore.map { PhotoGroup.clampScore($0) }
        self.customName = customName
    }

    /// 簡易イニシャライザ（写真IDとサイズのタプル配列から作成）
    /// - Parameters:
    ///   - type: グループタイプ
    ///   - photos: (id, fileSize) のタプル配列
    public init(type: GroupType, photos: [(id: String, fileSize: Int64)]) {
        self.init(
            type: type,
            photoIds: photos.map { $0.id },
            fileSizes: photos.map { $0.fileSize }
        )
    }

    // MARK: - Computed Properties

    /// グループ表示名
    public var displayName: String {
        customName ?? type.displayName
    }

    /// グループ内の写真数
    public var count: Int {
        photoIds.count
    }

    /// グループが空かどうか
    public var isEmpty: Bool {
        photoIds.isEmpty
    }

    /// グループが有効かどうか（2枚以上の写真が必要）
    public var isValid: Bool {
        photoIds.count >= 2
    }

    /// 合計ファイルサイズ（バイト）
    public var totalSize: Int64 {
        fileSizes.reduce(0, +)
    }

    /// 削減可能なファイルサイズ（バイト）
    /// ベストショット以外の写真のサイズ合計
    public var reclaimableSize: Int64 {
        guard let bestIndex = bestShotIndex,
              bestIndex >= 0,
              bestIndex < fileSizes.count else {
            return totalSize
        }

        return fileSizes.enumerated()
            .filter { $0.offset != bestIndex }
            .reduce(0) { $0 + $1.element }
    }

    /// 削減可能な写真数
    public var reclaimableCount: Int {
        guard bestShotIndex != nil else {
            return count
        }
        return max(0, count - 1)
    }

    /// フォーマット済み合計サイズ
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// フォーマット済み削減可能サイズ
    public var formattedReclaimableSize: String {
        ByteCountFormatter.string(fromByteCount: reclaimableSize, countStyle: .file)
    }

    /// ベストショットの写真ID
    public var bestShotId: String? {
        guard let index = bestShotIndex,
              index >= 0,
              index < photoIds.count else {
            return nil
        }
        return photoIds[index]
    }

    /// 削除候補の写真ID一覧（ベストショット以外）
    public var deletionCandidateIds: [String] {
        guard let bestIndex = bestShotIndex else {
            return photoIds
        }
        return photoIds.enumerated()
            .filter { $0.offset != bestIndex }
            .map { $0.element }
    }

    /// 削減率（%）
    public var savingsPercentage: Double {
        guard totalSize > 0 else { return 0 }
        return Double(reclaimableSize) / Double(totalSize) * 100
    }

    // MARK: - Mutation Methods

    /// ベストショットを設定
    /// - Parameter index: ベストショットのインデックス
    /// - Returns: 新しい PhotoGroup インスタンス
    public func withBestShot(at index: Int?) -> PhotoGroup {
        var copy = self
        copy.bestShotIndex = index
        return copy
    }

    /// 選択状態を設定
    /// - Parameter selected: 新しい選択状態
    /// - Returns: 新しい PhotoGroup インスタンス
    public func withSelection(_ selected: Bool) -> PhotoGroup {
        var copy = self
        copy.isSelected = selected
        return copy
    }

    /// 写真を追加
    /// - Parameters:
    ///   - photoId: 追加する写真ID
    ///   - fileSize: ファイルサイズ
    /// - Returns: 新しい PhotoGroup インスタンス
    public func adding(photoId: String, fileSize: Int64 = 0) -> PhotoGroup {
        var copy = self
        copy.photoIds.append(photoId)
        copy.fileSizes.append(fileSize)
        return copy
    }

    /// 写真を削除
    /// - Parameter photoId: 削除する写真ID
    /// - Returns: 新しい PhotoGroup インスタンス
    public func removing(photoId: String) -> PhotoGroup {
        guard let index = photoIds.firstIndex(of: photoId) else {
            return self
        }

        var copy = self
        copy.photoIds.remove(at: index)
        if index < copy.fileSizes.count {
            copy.fileSizes.remove(at: index)
        }

        // ベストショットインデックスの調整
        if let bestIndex = copy.bestShotIndex {
            if bestIndex == index {
                copy.bestShotIndex = nil
            } else if bestIndex > index {
                copy.bestShotIndex = bestIndex - 1
            }
        }

        return copy
    }

    /// カスタム名を設定
    /// - Parameter name: カスタム名（nil でリセット）
    /// - Returns: 新しい PhotoGroup インスタンス
    public func withCustomName(_ name: String?) -> PhotoGroup {
        var copy = self
        copy.customName = name
        return copy
    }

    // MARK: - Helper Methods

    /// スコアを 0.0〜1.0 の範囲にクランプ
    private static func clampScore(_ value: Float) -> Float {
        Swift.min(1.0, Swift.max(0.0, value))
    }

    /// 写真IDが含まれているかチェック
    /// - Parameter photoId: チェックする写真ID
    /// - Returns: 含まれている場合 true
    public func contains(photoId: String) -> Bool {
        photoIds.contains(photoId)
    }

    /// 写真IDのインデックスを取得
    /// - Parameter photoId: 検索する写真ID
    /// - Returns: インデックス（見つからない場合は nil）
    public func index(of photoId: String) -> Int? {
        photoIds.firstIndex(of: photoId)
    }
}

// MARK: - PhotoGroup + Codable

extension PhotoGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case photoIds
        case fileSizes
        case bestShotIndex
        case isSelected
        case createdAt
        case similarityScore
        case customName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(GroupType.self, forKey: .type)
        photoIds = try container.decode([String].self, forKey: .photoIds)
        fileSizes = try container.decodeIfPresent([Int64].self, forKey: .fileSizes) ?? []
        bestShotIndex = try container.decodeIfPresent(Int.self, forKey: .bestShotIndex)
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        similarityScore = try container.decodeIfPresent(Float.self, forKey: .similarityScore)
        customName = try container.decodeIfPresent(String.self, forKey: .customName)

        // fileSizes が空の場合は photoIds と同じ数の 0 を設定
        if fileSizes.isEmpty {
            fileSizes = Array(repeating: 0, count: photoIds.count)
        }
    }
}

// MARK: - PhotoGroup + CustomStringConvertible

extension PhotoGroup: CustomStringConvertible {
    public var description: String {
        """
        PhotoGroup(\
        id: \(id.uuidString.prefix(8))..., \
        type: \(type.displayName), \
        count: \(count), \
        totalSize: \(formattedTotalSize), \
        reclaimable: \(formattedReclaimableSize))
        """
    }
}

// MARK: - PhotoGroup + Comparable

extension PhotoGroup: Comparable {
    /// 削減可能サイズで比較（大きい順）
    public static func < (lhs: PhotoGroup, rhs: PhotoGroup) -> Bool {
        lhs.reclaimableSize > rhs.reclaimableSize
    }
}

// MARK: - PhotoGroupStatistics

/// 写真グループ統計情報（PhotoGroup 配列用）
public struct PhotoGroupStatistics: Sendable, Equatable {
    /// グループ総数
    public let totalGroups: Int

    /// 写真総数
    public let totalPhotos: Int

    /// 合計サイズ（バイト）
    public let totalSize: Int64

    /// 削減可能サイズ（バイト）
    public let reclaimableSize: Int64

    /// タイプ別グループ数
    public let countByType: [GroupType: Int]

    /// タイプ別削減可能サイズ
    public let reclaimableSizeByType: [GroupType: Int64]

    // MARK: - Computed Properties

    /// フォーマット済み合計サイズ
    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// フォーマット済み削減可能サイズ
    public var formattedReclaimableSize: String {
        ByteCountFormatter.string(fromByteCount: reclaimableSize, countStyle: .file)
    }

    /// 削減率（%）
    public var savingsPercentage: Double {
        guard totalSize > 0 else { return 0 }
        return Double(reclaimableSize) / Double(totalSize) * 100
    }

    /// 空の統計
    public static let empty = PhotoGroupStatistics(
        totalGroups: 0,
        totalPhotos: 0,
        totalSize: 0,
        reclaimableSize: 0,
        countByType: [:],
        reclaimableSizeByType: [:]
    )
}

// MARK: - GroupingOptions

/// グルーピングオプション
public struct GroupingOptions: Sendable, Equatable {
    /// 類似度閾値（0.0〜1.0）
    public var similarityThreshold: Float

    /// 最小グループサイズ（この数以上の写真でグループ形成）
    public var minimumGroupSize: Int

    /// スクリーンショットを含めるか
    public var includeScreenshots: Bool

    /// 自撮りを含めるか
    public var includeSelfies: Bool

    /// ブレ写真を含めるか
    public var includeBlurry: Bool

    /// 大容量動画を含めるか
    public var includeLargeVideos: Bool

    /// 大容量動画の閾値（バイト）
    public var largeVideoThreshold: Int64

    /// ベストショット自動選定
    public var autoSelectBestShot: Bool

    /// 日付範囲でフィルタ（nil の場合は制限なし）
    public var dateRange: DateRange?

    // MARK: - Nested Types

    /// 日付範囲
    public struct DateRange: Sendable, Equatable, Codable {
        public let start: Date
        public let end: Date

        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }

        /// 過去N日間
        public static func lastDays(_ days: Int) -> DateRange {
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
            return DateRange(start: start, end: end)
        }
    }

    // MARK: - Initialization

    /// デフォルト値で初期化
    public init(
        similarityThreshold: Float = 0.85,
        minimumGroupSize: Int = 2,
        includeScreenshots: Bool = true,
        includeSelfies: Bool = true,
        includeBlurry: Bool = true,
        includeLargeVideos: Bool = true,
        largeVideoThreshold: Int64 = 100 * 1024 * 1024, // 100MB
        autoSelectBestShot: Bool = true,
        dateRange: DateRange? = nil
    ) {
        self.similarityThreshold = Swift.min(1.0, Swift.max(0.0, similarityThreshold))
        self.minimumGroupSize = Swift.max(2, minimumGroupSize)
        self.includeScreenshots = includeScreenshots
        self.includeSelfies = includeSelfies
        self.includeBlurry = includeBlurry
        self.includeLargeVideos = includeLargeVideos
        self.largeVideoThreshold = largeVideoThreshold
        self.autoSelectBestShot = autoSelectBestShot
        self.dateRange = dateRange
    }

    /// デフォルトオプション
    public static let `default` = GroupingOptions()

    /// 厳格なオプション（高類似度のみ）
    public static let strict = GroupingOptions(
        similarityThreshold: 0.95,
        minimumGroupSize: 2
    )

    /// 緩いオプション（より多くの類似検出）
    public static let relaxed = GroupingOptions(
        similarityThreshold: 0.75,
        minimumGroupSize: 2
    )
}

// MARK: - GroupingOptions + Codable

extension GroupingOptions: Codable {
    enum CodingKeys: String, CodingKey {
        case similarityThreshold
        case minimumGroupSize
        case includeScreenshots
        case includeSelfies
        case includeBlurry
        case includeLargeVideos
        case largeVideoThreshold
        case autoSelectBestShot
        case dateRange
    }
}

// MARK: - Array Extension for PhotoGroup

extension Array where Element == PhotoGroup {

    // MARK: - Filtering

    /// 指定タイプのグループのみ抽出
    /// - Parameter type: グループタイプ
    /// - Returns: フィルタされたグループ配列
    public func filterByType(_ type: GroupType) -> [PhotoGroup] {
        filter { $0.type == type }
    }

    /// 複数タイプでフィルタ
    /// - Parameter types: グループタイプのセット
    /// - Returns: フィルタされたグループ配列
    public func filterByTypes(_ types: Set<GroupType>) -> [PhotoGroup] {
        filter { types.contains($0.type) }
    }

    /// 有効なグループのみ抽出（2枚以上）
    public var validGroups: [PhotoGroup] {
        filter { $0.isValid }
    }

    /// 選択されたグループのみ抽出
    public var selectedGroups: [PhotoGroup] {
        filter { $0.isSelected }
    }

    /// 選択されていないグループのみ抽出
    public var unselectedGroups: [PhotoGroup] {
        filter { !$0.isSelected }
    }

    /// ベストショットが設定されているグループのみ抽出
    public var withBestShot: [PhotoGroup] {
        filter { $0.bestShotIndex != nil }
    }

    /// ベストショットが未設定のグループのみ抽出
    public var withoutBestShot: [PhotoGroup] {
        filter { $0.bestShotIndex == nil }
    }

    // MARK: - Sorting

    /// 削減可能サイズで降順ソート
    public var sortedByReclaimableSize: [PhotoGroup] {
        sorted { $0.reclaimableSize > $1.reclaimableSize }
    }

    /// 写真数で降順ソート
    public var sortedByPhotoCount: [PhotoGroup] {
        sorted { $0.count > $1.count }
    }

    /// 作成日時で降順ソート
    public var sortedByDate: [PhotoGroup] {
        sorted { $0.createdAt > $1.createdAt }
    }

    /// タイプのソート順でソート
    public var sortedByType: [PhotoGroup] {
        sorted { $0.type.sortOrder < $1.type.sortOrder }
    }

    /// 類似度スコアで降順ソート
    public var sortedBySimilarity: [PhotoGroup] {
        sorted { ($0.similarityScore ?? 0) > ($1.similarityScore ?? 0) }
    }

    // MARK: - Statistics

    /// 統計情報を計算
    public var statistics: PhotoGroupStatistics {
        var countByType: [GroupType: Int] = [:]
        var reclaimableSizeByType: [GroupType: Int64] = [:]

        for group in self {
            countByType[group.type, default: 0] += 1
            reclaimableSizeByType[group.type, default: 0] += group.reclaimableSize
        }

        return PhotoGroupStatistics(
            totalGroups: count,
            totalPhotos: reduce(0) { $0 + $1.count },
            totalSize: reduce(0) { $0 + $1.totalSize },
            reclaimableSize: reduce(0) { $0 + $1.reclaimableSize },
            countByType: countByType,
            reclaimableSizeByType: reclaimableSizeByType
        )
    }

    /// 合計削減可能サイズ
    public var totalReclaimableSize: Int64 {
        reduce(0) { $0 + $1.reclaimableSize }
    }

    /// 合計サイズ
    public var totalSize: Int64 {
        reduce(0) { $0 + $1.totalSize }
    }

    /// 合計写真数
    public var totalPhotoCount: Int {
        reduce(0) { $0 + $1.count }
    }

    /// 合計削減可能写真数
    public var totalReclaimableCount: Int {
        reduce(0) { $0 + $1.reclaimableCount }
    }

    /// フォーマット済み合計削減可能サイズ
    public var formattedTotalReclaimableSize: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableSize, countStyle: .file)
    }

    // MARK: - Lookup

    /// IDでグループを検索
    /// - Parameter id: グループID
    /// - Returns: 見つかったグループ（見つからない場合は nil）
    public func group(withId id: UUID) -> PhotoGroup? {
        first { $0.id == id }
    }

    /// 写真IDを含むグループを検索
    /// - Parameter photoId: 写真ID
    /// - Returns: 写真を含むグループ一覧
    public func groups(containing photoId: String) -> [PhotoGroup] {
        filter { $0.contains(photoId: photoId) }
    }

    // MARK: - Batch Operations

    /// すべてのグループを選択状態に設定
    /// - Parameter selected: 選択状態
    /// - Returns: 更新されたグループ配列
    public func settingSelection(_ selected: Bool) -> [PhotoGroup] {
        map { $0.withSelection(selected) }
    }

    /// タイプでグルーピング
    /// - Returns: タイプをキーとした辞書
    public var groupedByType: [GroupType: [PhotoGroup]] {
        Dictionary(grouping: self) { $0.type }
    }

    /// すべての削除候補写真IDを取得
    public var allDeletionCandidateIds: [String] {
        flatMap { $0.deletionCandidateIds }
    }

    /// すべての写真IDを取得
    public var allPhotoIds: [String] {
        flatMap { $0.photoIds }
    }

    /// 一意な写真IDを取得
    public var uniquePhotoIds: Set<String> {
        Set(allPhotoIds)
    }
}

// MARK: - GroupType + Comparable

extension GroupType: Comparable {
    public static func < (lhs: GroupType, rhs: GroupType) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
