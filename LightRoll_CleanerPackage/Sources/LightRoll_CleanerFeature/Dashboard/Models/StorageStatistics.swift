//
//  StorageStatistics.swift
//  LightRoll_CleanerFeature
//
//  ストレージ統計のドメインモデル
//  ダッシュボードでの容量情報とグループサマリーを統合表示するために使用
//  Created by AI Assistant
//

import Foundation

// MARK: - GroupSummary

/// グループタイプごとのサマリー情報
/// ダッシュボードのグループ一覧表示に使用
public struct GroupSummary: Sendable, Codable, Hashable, Identifiable {

    // MARK: - Properties

    /// グループタイプ
    public let type: GroupType

    /// グループ数
    public let groupCount: Int

    /// 写真/動画の合計枚数
    public let photoCount: Int

    /// 合計サイズ（バイト）
    public let totalSize: Int64

    /// 削減可能サイズ（バイト）
    public let reclaimableSize: Int64

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - type: グループタイプ
    ///   - groupCount: グループ数
    ///   - photoCount: 写真/動画の合計枚数
    ///   - totalSize: 合計サイズ
    ///   - reclaimableSize: 削減可能サイズ
    public init(
        type: GroupType,
        groupCount: Int,
        photoCount: Int,
        totalSize: Int64,
        reclaimableSize: Int64
    ) {
        self.type = type
        self.groupCount = Swift.max(0, groupCount)
        self.photoCount = Swift.max(0, photoCount)
        self.totalSize = Swift.max(0, totalSize)
        self.reclaimableSize = Swift.max(0, reclaimableSize)
    }

    /// PhotoGroup配列から生成
    /// - Parameters:
    ///   - type: グループタイプ
    ///   - groups: 対象グループ配列
    public init(type: GroupType, groups: [PhotoGroup]) {
        let filteredGroups = groups.filter { $0.type == type }
        self.init(
            type: type,
            groupCount: filteredGroups.count,
            photoCount: filteredGroups.reduce(0) { $0 + $1.count },
            totalSize: filteredGroups.reduce(0) { $0 + $1.totalSize },
            reclaimableSize: filteredGroups.reduce(0) { $0 + $1.reclaimableSize }
        )
    }

    // MARK: - Identifiable

    /// 識別子（グループタイプのrawValue）
    public var id: String {
        type.rawValue
    }

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

    /// サマリーが空かどうか（データなし）
    public var isEmpty: Bool {
        groupCount == 0
    }

    /// サマリーが有効かどうか（1グループ以上）
    public var isValid: Bool {
        groupCount > 0
    }

    /// グループタイプの表示名
    public var displayName: String {
        type.displayName
    }

    /// グループタイプのアイコン
    public var icon: String {
        type.icon
    }

    /// グループタイプの絵文字
    public var emoji: String {
        type.emoji
    }

    /// 空のサマリー
    public static func empty(for type: GroupType) -> GroupSummary {
        GroupSummary(
            type: type,
            groupCount: 0,
            photoCount: 0,
            totalSize: 0,
            reclaimableSize: 0
        )
    }
}

// MARK: - GroupSummary + Comparable

extension GroupSummary: Comparable {
    /// 削減可能サイズで比較（大きい順）
    public static func < (lhs: GroupSummary, rhs: GroupSummary) -> Bool {
        lhs.reclaimableSize > rhs.reclaimableSize
    }
}

// MARK: - GroupSummary + CustomStringConvertible

extension GroupSummary: CustomStringConvertible {
    public var description: String {
        "\(type.emoji) \(displayName): \(photoCount)枚, \(formattedReclaimableSize)削減可能"
    }
}

// MARK: - StorageStatistics

/// ストレージ統計情報（ダッシュボード用）
/// StorageInfo とグループサマリーを統合した統計モデル
public struct StorageStatistics: Sendable, Codable, Hashable {

    // MARK: - Properties

    /// デバイスのストレージ情報
    public let storageInfo: StorageInfo

    /// グループタイプ別のサマリー
    public let groupSummaries: [GroupType: GroupSummary]

    /// 統計取得日時
    public let timestamp: Date

    /// スキャン済み写真数
    public let scannedPhotoCount: Int

    /// スキャン済み動画数
    public let scannedVideoCount: Int

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - storageInfo: ストレージ情報
    ///   - groupSummaries: グループタイプ別サマリー
    ///   - timestamp: 統計取得日時
    ///   - scannedPhotoCount: スキャン済み写真数
    ///   - scannedVideoCount: スキャン済み動画数
    public init(
        storageInfo: StorageInfo,
        groupSummaries: [GroupType: GroupSummary] = [:],
        timestamp: Date = Date(),
        scannedPhotoCount: Int = 0,
        scannedVideoCount: Int = 0
    ) {
        self.storageInfo = storageInfo
        self.groupSummaries = groupSummaries
        self.timestamp = timestamp
        self.scannedPhotoCount = Swift.max(0, scannedPhotoCount)
        self.scannedVideoCount = Swift.max(0, scannedVideoCount)
    }

    /// PhotoGroup配列から生成
    /// - Parameters:
    ///   - storageInfo: ストレージ情報
    ///   - groups: グループ配列
    ///   - scannedPhotoCount: スキャン済み写真数
    ///   - scannedVideoCount: スキャン済み動画数
    public init(
        storageInfo: StorageInfo,
        groups: [PhotoGroup],
        scannedPhotoCount: Int = 0,
        scannedVideoCount: Int = 0
    ) {
        var summaries: [GroupType: GroupSummary] = [:]
        for type in GroupType.allCases {
            let summary = GroupSummary(type: type, groups: groups)
            if !summary.isEmpty {
                summaries[type] = summary
            }
        }

        self.init(
            storageInfo: storageInfo,
            groupSummaries: summaries,
            scannedPhotoCount: scannedPhotoCount,
            scannedVideoCount: scannedVideoCount
        )
    }

    // MARK: - Computed Properties

    /// 全グループの削減可能サイズ合計
    public var totalReclaimableSize: Int64 {
        groupSummaries.values.reduce(0) { $0 + $1.reclaimableSize }
    }

    /// フォーマット済み全削減可能サイズ
    public var formattedTotalReclaimableSize: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableSize, countStyle: .file)
    }

    /// 全グループの写真/動画数合計
    public var totalGroupedPhotoCount: Int {
        groupSummaries.values.reduce(0) { $0 + $1.photoCount }
    }

    /// 全グループ数
    public var totalGroupCount: Int {
        groupSummaries.values.reduce(0) { $0 + $1.groupCount }
    }

    /// スキャン済みアイテム合計
    public var totalScannedCount: Int {
        scannedPhotoCount + scannedVideoCount
    }

    /// 削減率（写真ライブラリ容量に対する割合、%）
    public var savingsPercentage: Double {
        guard storageInfo.photosUsedCapacity > 0 else { return 0 }
        return Double(totalReclaimableSize) / Double(storageInfo.photosUsedCapacity) * 100
    }

    /// 削減可能容量が大きいかどうか（1GB以上）
    public var hasSignificantSavings: Bool {
        let gigabyte: Int64 = 1_000_000_000
        return totalReclaimableSize >= gigabyte
    }

    /// データがあるかどうか
    public var hasData: Bool {
        !groupSummaries.isEmpty
    }

    /// ソート順でグループサマリーを取得
    public var sortedGroupSummaries: [GroupSummary] {
        GroupType.allCases
            .compactMap { groupSummaries[$0] }
            .filter { !$0.isEmpty }
            .sorted { $0.type.sortOrder < $1.type.sortOrder }
    }

    /// 削減可能サイズ順でグループサマリーを取得
    public var summariesByReclaimableSize: [GroupSummary] {
        groupSummaries.values
            .filter { !$0.isEmpty }
            .sorted { $0.reclaimableSize > $1.reclaimableSize }
    }

    /// タイムスタンプのフォーマット済み文字列
    public var formattedTimestamp: String {
        StorageStatistics.timestampFormatter.string(from: timestamp)
    }

    /// タイムスタンプの相対形式
    public var formattedRelativeTimestamp: String {
        StorageStatistics.relativeFormatter.localizedString(for: timestamp, relativeTo: Date())
    }

    // MARK: - Date Formatters (Static)

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Factory Methods

    /// 空の統計
    public static var empty: StorageStatistics {
        StorageStatistics(storageInfo: .empty)
    }

    /// デバイスのストレージ情報のみで生成
    public static func fromDevice() -> StorageStatistics {
        StorageStatistics(storageInfo: .fromDevice())
    }

    // MARK: - Lookup Methods

    /// 指定グループタイプのサマリーを取得
    /// - Parameter type: グループタイプ
    /// - Returns: サマリー（存在しない場合は空のサマリー）
    public func summary(for type: GroupType) -> GroupSummary {
        groupSummaries[type] ?? .empty(for: type)
    }

    /// 指定グループタイプが存在するかチェック
    /// - Parameter type: グループタイプ
    /// - Returns: 存在する場合true
    public func hasSummary(for type: GroupType) -> Bool {
        if let summary = groupSummaries[type] {
            return !summary.isEmpty
        }
        return false
    }

    // MARK: - Update Methods

    /// ストレージ情報を更新した新しいインスタンスを返す
    /// - Parameter newStorageInfo: 新しいストレージ情報
    /// - Returns: 更新されたStorageStatistics
    public func withStorageInfo(_ newStorageInfo: StorageInfo) -> StorageStatistics {
        StorageStatistics(
            storageInfo: newStorageInfo,
            groupSummaries: groupSummaries,
            timestamp: Date(),
            scannedPhotoCount: scannedPhotoCount,
            scannedVideoCount: scannedVideoCount
        )
    }

    /// グループサマリーを更新した新しいインスタンスを返す
    /// - Parameter newSummaries: 新しいグループサマリー
    /// - Returns: 更新されたStorageStatistics
    public func withGroupSummaries(_ newSummaries: [GroupType: GroupSummary]) -> StorageStatistics {
        StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: newSummaries,
            timestamp: Date(),
            scannedPhotoCount: scannedPhotoCount,
            scannedVideoCount: scannedVideoCount
        )
    }

    /// 特定のグループサマリーを追加/更新
    /// - Parameter summary: 追加/更新するサマリー
    /// - Returns: 更新されたStorageStatistics
    public func withSummary(_ summary: GroupSummary) -> StorageStatistics {
        var newSummaries = groupSummaries
        newSummaries[summary.type] = summary
        return withGroupSummaries(newSummaries)
    }

    /// スキャンカウントを更新
    /// - Parameters:
    ///   - photos: 写真数
    ///   - videos: 動画数
    /// - Returns: 更新されたStorageStatistics
    public func withScannedCounts(photos: Int, videos: Int) -> StorageStatistics {
        StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: groupSummaries,
            timestamp: Date(),
            scannedPhotoCount: photos,
            scannedVideoCount: videos
        )
    }
}

// MARK: - StorageStatistics + Identifiable

extension StorageStatistics: Identifiable {
    /// 識別子（タイムスタンプベース）
    public var id: Date {
        timestamp
    }
}

// MARK: - StorageStatistics + CustomStringConvertible

extension StorageStatistics: CustomStringConvertible {
    public var description: String {
        """
        StorageStatistics(\
        storage: \(storageInfo.formattedUsedCapacity)/\(storageInfo.formattedTotalCapacity), \
        reclaimable: \(formattedTotalReclaimableSize), \
        groups: \(totalGroupCount), \
        timestamp: \(formattedTimestamp))
        """
    }
}

// MARK: - Array Extension for GroupSummary

extension Array where Element == GroupSummary {

    /// 削減可能サイズの合計
    public var totalReclaimableSize: Int64 {
        reduce(0) { $0 + $1.reclaimableSize }
    }

    /// 写真/動画数の合計
    public var totalPhotoCount: Int {
        reduce(0) { $0 + $1.photoCount }
    }

    /// グループ数の合計
    public var totalGroupCount: Int {
        reduce(0) { $0 + $1.groupCount }
    }

    /// フォーマット済み削減可能サイズ
    public var formattedTotalReclaimableSize: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableSize, countStyle: .file)
    }

    /// 有効なサマリーのみ抽出
    public var validSummaries: [GroupSummary] {
        filter { $0.isValid }
    }

    /// グループタイプのソート順でソート
    public var sortedByType: [GroupSummary] {
        sorted { $0.type.sortOrder < $1.type.sortOrder }
    }

    /// 削減可能サイズ順でソート
    public var sortedByReclaimableSize: [GroupSummary] {
        sorted { $0.reclaimableSize > $1.reclaimableSize }
    }
}
