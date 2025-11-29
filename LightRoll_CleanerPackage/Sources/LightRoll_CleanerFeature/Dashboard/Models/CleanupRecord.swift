//
//  CleanupRecord.swift
//  LightRoll_CleanerFeature
//
//  クリーンアップ履歴のドメインモデル
//  削除操作の履歴を管理し、統計表示に使用
//  Created by AI Assistant
//

import Foundation

// MARK: - CleanupRecord

/// クリーンアップ履歴を表すドメインモデル
/// 各削除操作の日時、削除枚数、解放容量を記録
/// SwiftData/永続化層での保存に対応（Codable）
public struct CleanupRecord: Identifiable, Sendable, Codable, Hashable {

    // MARK: - Properties

    /// レコードの一意な識別子
    public let id: UUID

    /// クリーンアップ実行日時
    public let date: Date

    /// 削除した写真/動画の枚数
    public let deletedCount: Int

    /// 解放したストレージ容量（バイト）
    public let freedSpace: Int64

    /// 削除したグループタイプ（nilの場合は混合または不明）
    public let groupType: GroupType?

    /// 削除操作の種類
    public let operationType: OperationType

    // MARK: - Nested Types

    /// 削除操作の種類
    public enum OperationType: String, Sendable, Codable, CaseIterable {
        /// 手動選択削除
        case manual

        /// クイッククリーンアップ（推奨削除）
        case quickClean

        /// 一括削除（グループ全体）
        case bulkDelete

        /// 自動クリーンアップ（バックグラウンド）
        case automatic

        /// 表示名
        public var displayName: String {
            switch self {
            case .manual:
                return NSLocalizedString("operationType.manual", value: "手動削除", comment: "Manual deletion")
            case .quickClean:
                return NSLocalizedString("operationType.quickClean", value: "クイッククリーン", comment: "Quick clean")
            case .bulkDelete:
                return NSLocalizedString("operationType.bulkDelete", value: "一括削除", comment: "Bulk delete")
            case .automatic:
                return NSLocalizedString("operationType.automatic", value: "自動クリーンアップ", comment: "Automatic cleanup")
            }
        }

        /// アイコン（SF Symbol名）
        public var icon: String {
            switch self {
            case .manual:
                return "hand.tap"
            case .quickClean:
                return "sparkles"
            case .bulkDelete:
                return "trash.fill"
            case .automatic:
                return "clock.arrow.circlepath"
            }
        }
    }

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - id: レコードID（デフォルトは新規UUID）
    ///   - date: クリーンアップ実行日時（デフォルトは現在時刻）
    ///   - deletedCount: 削除した写真/動画の枚数
    ///   - freedSpace: 解放したストレージ容量（バイト）
    ///   - groupType: 削除したグループタイプ（オプション）
    ///   - operationType: 削除操作の種類（デフォルトは手動）
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        deletedCount: Int,
        freedSpace: Int64,
        groupType: GroupType? = nil,
        operationType: OperationType = .manual
    ) {
        self.id = id
        self.date = date
        self.deletedCount = Swift.max(0, deletedCount)
        self.freedSpace = Swift.max(0, freedSpace)
        self.groupType = groupType
        self.operationType = operationType
    }

    /// 簡易イニシャライザ（必須項目のみ）
    /// - Parameters:
    ///   - deletedCount: 削除した写真/動画の枚数
    ///   - freedSpace: 解放したストレージ容量（バイト）
    public init(deletedCount: Int, freedSpace: Int64) {
        self.init(
            deletedCount: deletedCount,
            freedSpace: freedSpace,
            groupType: nil,
            operationType: .manual
        )
    }

    // MARK: - Computed Properties

    /// フォーマット済み解放容量（例: 「1.2 GB」）
    public var formattedFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: freedSpace, countStyle: .file)
    }

    /// フォーマット済み日付（例: 「11/25」）
    public var formattedDate: String {
        CleanupRecord.shortDateFormatter.string(from: date)
    }

    /// フォーマット済み日時（例: 「11/25 14:32」）
    public var formattedDateTime: String {
        CleanupRecord.dateTimeFormatter.string(from: date)
    }

    /// フォーマット済み日付（相対形式、例: 「今日」「昨日」「3日前」）
    public var formattedRelativeDate: String {
        CleanupRecord.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// 履歴表示用のサマリー文字列
    /// 例: 「156枚削除 - 1.2 GB解放」
    public var summary: String {
        String(
            format: NSLocalizedString(
                "cleanupRecord.summary",
                value: "%d枚削除 - %@解放",
                comment: "Cleanup record summary"
            ),
            deletedCount,
            formattedFreedSpace
        )
    }

    /// 履歴表示用の詳細サマリー文字列（日付付き）
    /// 例: 「11/25 - 156枚削除 - 1.2 GB解放」
    public var detailedSummary: String {
        "\(formattedDate) - \(summary)"
    }

    /// グループタイプの表示名（nilの場合は「混合」）
    public var groupTypeDisplayName: String {
        groupType?.displayName ?? NSLocalizedString("groupType.mixed", value: "混合", comment: "Mixed group type")
    }

    /// このレコードが有効かどうか
    public var isValid: Bool {
        deletedCount > 0 && freedSpace > 0
    }

    // MARK: - Date Formatters (Static)

    /// 短い日付フォーマッタ（例: 「11/25」）
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale.current
        return formatter
    }()

    /// 日時フォーマッタ（例: 「11/25 14:32」）
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()

    /// 相対日付フォーマッタ
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - CleanupRecord + CustomStringConvertible

extension CleanupRecord: CustomStringConvertible {
    public var description: String {
        """
        CleanupRecord(\
        id: \(id.uuidString.prefix(8))..., \
        date: \(formattedDateTime), \
        deleted: \(deletedCount), \
        freed: \(formattedFreedSpace))
        """
    }
}

// MARK: - CleanupRecord + Comparable

extension CleanupRecord: Comparable {
    /// 日付で比較（新しい順）
    public static func < (lhs: CleanupRecord, rhs: CleanupRecord) -> Bool {
        lhs.date > rhs.date
    }
}

// MARK: - CleanupRecordStatistics

/// クリーンアップ履歴の統計情報
public struct CleanupRecordStatistics: Sendable, Equatable {

    /// 履歴レコード総数
    public let totalRecords: Int

    /// 削除した写真/動画の合計枚数
    public let totalDeletedCount: Int

    /// 解放したストレージ容量の合計（バイト）
    public let totalFreedSpace: Int64

    /// 操作タイプ別のレコード数
    public let countByOperationType: [CleanupRecord.OperationType: Int]

    /// グループタイプ別の削除枚数
    public let deletedCountByGroupType: [GroupType: Int]

    /// 最新のクリーンアップ日時
    public let latestCleanupDate: Date?

    /// 最古のクリーンアップ日時
    public let oldestCleanupDate: Date?

    // MARK: - Computed Properties

    /// フォーマット済み合計解放容量
    public var formattedTotalFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalFreedSpace, countStyle: .file)
    }

    /// 平均削除枚数（レコードあたり）
    public var averageDeletedCount: Double {
        guard totalRecords > 0 else { return 0 }
        return Double(totalDeletedCount) / Double(totalRecords)
    }

    /// 平均解放容量（レコードあたり）
    public var averageFreedSpace: Int64 {
        guard totalRecords > 0 else { return 0 }
        return totalFreedSpace / Int64(totalRecords)
    }

    /// フォーマット済み平均解放容量
    public var formattedAverageFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: averageFreedSpace, countStyle: .file)
    }

    /// 空の統計
    public static let empty = CleanupRecordStatistics(
        totalRecords: 0,
        totalDeletedCount: 0,
        totalFreedSpace: 0,
        countByOperationType: [:],
        deletedCountByGroupType: [:],
        latestCleanupDate: nil,
        oldestCleanupDate: nil
    )
}

// MARK: - Array Extension for CleanupRecord

extension Array where Element == CleanupRecord {

    // MARK: - Filtering

    /// 指定期間内のレコードのみ抽出
    /// - Parameters:
    ///   - start: 開始日時
    ///   - end: 終了日時
    /// - Returns: フィルタされたレコード配列
    public func filterByDateRange(from start: Date, to end: Date) -> [CleanupRecord] {
        filter { $0.date >= start && $0.date <= end }
    }

    /// 過去N日間のレコードのみ抽出
    /// - Parameter days: 日数
    /// - Returns: フィルタされたレコード配列
    public func filterLastDays(_ days: Int) -> [CleanupRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return filter { $0.date >= cutoffDate }
    }

    /// 指定グループタイプのレコードのみ抽出
    /// - Parameter type: グループタイプ
    /// - Returns: フィルタされたレコード配列
    public func filterByGroupType(_ type: GroupType) -> [CleanupRecord] {
        filter { $0.groupType == type }
    }

    /// 指定操作タイプのレコードのみ抽出
    /// - Parameter type: 操作タイプ
    /// - Returns: フィルタされたレコード配列
    public func filterByOperationType(_ type: CleanupRecord.OperationType) -> [CleanupRecord] {
        filter { $0.operationType == type }
    }

    /// 有効なレコードのみ抽出
    public var validRecords: [CleanupRecord] {
        filter { $0.isValid }
    }

    // MARK: - Sorting

    /// 日付で降順ソート（新しい順）
    public var sortedByDateDescending: [CleanupRecord] {
        sorted { $0.date > $1.date }
    }

    /// 日付で昇順ソート（古い順）
    public var sortedByDateAscending: [CleanupRecord] {
        sorted { $0.date < $1.date }
    }

    /// 解放容量で降順ソート
    public var sortedByFreedSpace: [CleanupRecord] {
        sorted { $0.freedSpace > $1.freedSpace }
    }

    /// 削除枚数で降順ソート
    public var sortedByDeletedCount: [CleanupRecord] {
        sorted { $0.deletedCount > $1.deletedCount }
    }

    // MARK: - Statistics

    /// 統計情報を計算
    public var statistics: CleanupRecordStatistics {
        var countByOperationType: [CleanupRecord.OperationType: Int] = [:]
        var deletedCountByGroupType: [GroupType: Int] = [:]

        for record in self {
            countByOperationType[record.operationType, default: 0] += 1
            if let groupType = record.groupType {
                deletedCountByGroupType[groupType, default: 0] += record.deletedCount
            }
        }

        let sortedByDate = self.sortedByDateDescending

        return CleanupRecordStatistics(
            totalRecords: count,
            totalDeletedCount: reduce(0) { $0 + $1.deletedCount },
            totalFreedSpace: reduce(0) { $0 + $1.freedSpace },
            countByOperationType: countByOperationType,
            deletedCountByGroupType: deletedCountByGroupType,
            latestCleanupDate: sortedByDate.first?.date,
            oldestCleanupDate: sortedByDate.last?.date
        )
    }

    /// 合計削除枚数
    public var totalDeletedCount: Int {
        reduce(0) { $0 + $1.deletedCount }
    }

    /// 合計解放容量
    public var totalFreedSpace: Int64 {
        reduce(0) { $0 + $1.freedSpace }
    }

    /// フォーマット済み合計解放容量
    public var formattedTotalFreedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalFreedSpace, countStyle: .file)
    }

    /// 最新のクリーンアップ日時
    public var latestCleanupDate: Date? {
        self.max(by: { $0.date < $1.date })?.date
    }

    // MARK: - Grouping

    /// 日付でグルーピング（日ごと）
    public var groupedByDay: [Date: [CleanupRecord]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { record in
            calendar.startOfDay(for: record.date)
        }
    }

    /// 月でグルーピング
    public var groupedByMonth: [Date: [CleanupRecord]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { record in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
    }

    /// 操作タイプでグルーピング
    public var groupedByOperationType: [CleanupRecord.OperationType: [CleanupRecord]] {
        Dictionary(grouping: self) { $0.operationType }
    }
}
