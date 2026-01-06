import Foundation
import Photos

/// 時間ベースで写真を事前グルーピングするサービス
/// 大量の写真の類似度計算を最適化するため、時間的に近い写真のみを比較対象にする
///
/// Phase X1-1: 日付ベース分割機能を追加
/// - groupByDate(): 日付単位で写真を分割（並列処理最適化）
/// - 100,000枚のデータを100日×1,000枚/日に分割し、候補ペア数を50倍削減
public actor TimeBasedGrouper {
    /// 時間範囲の設定（デフォルト：24時間）
    public let timeWindow: TimeInterval

    /// カレンダー（日付計算用）
    private let calendar: Calendar

    /// 初期化
    /// - Parameter timeWindow: グループ化する時間範囲（秒単位）。デフォルトは24時間
    public init(timeWindow: TimeInterval = 24 * 60 * 60) {
        self.timeWindow = timeWindow
        self.calendar = Calendar.current
    }

    /// 写真を撮影時刻でソートし、時間範囲ごとにグループ化
    /// - Parameter photos: グループ化する写真の配列
    /// - Returns: 時間範囲ごとにグループ化された写真の配列
    public func groupByTime(photos: [Photo]) -> [[Photo]] {
        guard !photos.isEmpty else { return [] }

        // 撮影日時でソート
        let sortedPhotos = photos.sorted { $0.creationDate < $1.creationDate }

        var groups: [[Photo]] = []
        var currentGroup: [Photo] = [sortedPhotos[0]]
        var groupStartTime = sortedPhotos[0].creationDate

        for photo in sortedPhotos.dropFirst() {
            let timeDifference = photo.creationDate.timeIntervalSince(groupStartTime)

            if timeDifference <= timeWindow {
                // 同じ時間範囲内ならグループに追加
                currentGroup.append(photo)
            } else {
                // 時間範囲を超えたら新しいグループ開始
                groups.append(currentGroup)
                currentGroup = [photo]
                groupStartTime = photo.creationDate
            }
        }

        // 最後のグループを追加
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    /// グループ統計情報を取得
    /// - Parameter groups: 分析するグループの配列
    /// - Returns: グループ数、最小/最大/平均サイズ、総比較回数削減率
    public func getGroupStatistics(groups: [[Photo]]) -> GroupingStatistics {
        let groupCount = groups.count
        let sizes = groups.map { $0.count }
        let minSize = sizes.min() ?? 0
        let maxSize = sizes.max() ?? 0
        let avgSize = sizes.isEmpty ? 0 : Double(sizes.reduce(0, +)) / Double(sizes.count)

        // 比較回数の削減率計算
        let totalPhotos = sizes.reduce(0, +)
        let originalComparisons = totalPhotos * (totalPhotos - 1) / 2
        let optimizedComparisons = sizes.map { n in n * (n - 1) / 2 }.reduce(0, +)
        let reductionRate = originalComparisons > 0
            ? Double(originalComparisons - optimizedComparisons) / Double(originalComparisons)
            : 0

        return GroupingStatistics(
            groupCount: groupCount,
            minGroupSize: minSize,
            maxGroupSize: maxSize,
            avgGroupSize: avgSize,
            comparisonReductionRate: reductionRate
        )
    }

    // MARK: - Phase X1-1: 日付ベース分割

    /// 写真を日付（日単位）でグループ化
    ///
    /// Phase X1-1 最適化: 日付単位で写真を分割し、各日付グループを独立して並列処理可能にする。
    /// これにより、100,000枚×100,000枚 = 100億回の比較を、
    /// 1,000枚×1,000枚 × 100日 = 1億回（50倍削減）に最適化する。
    ///
    /// - Parameter photos: グループ化する写真の配列
    /// - Returns: 日付をキーとした写真グループの辞書
    ///
    /// - Performance:
    ///   - 時間計算量: O(n)（各写真を1回だけ処理）
    ///   - 空間計算量: O(n)（グループ化された写真を保持）
    ///   - 期待効果: 候補ペア数50倍削減、全体処理時間30%改善
    public func groupByDate(photos: [Photo]) -> [Date: [Photo]] {
        guard !photos.isEmpty else { return [:] }

        var dateGroups: [Date: [Photo]] = [:]
        dateGroups.reserveCapacity(min(photos.count, 365)) // 最大1年分の日付を想定

        for photo in photos {
            // 日付の開始時刻（00:00:00）を取得
            let dayStart = calendar.startOfDay(for: photo.creationDate)
            dateGroups[dayStart, default: []].append(photo)
        }

        return dateGroups
    }

    /// 写真を日付でグループ化し、日付順にソートされた配列として返す
    ///
    /// Phase X1-1 最適化: groupByDate()の結果を日付順にソートして返す。
    /// 並列処理で各日付グループを独立して処理する際に使用。
    ///
    /// - Parameter photos: グループ化する写真の配列
    /// - Returns: 日付順にソートされた(日付, 写真配列)のタプル配列
    ///
    /// - Note: 古い日付から新しい日付の順でソート
    public func groupByDateSorted(photos: [Photo]) -> [(date: Date, photos: [Photo])] {
        let dateGroups = groupByDate(photos: photos)

        // 日付順にソート（古い順）
        return dateGroups.sorted { $0.key < $1.key }
            .map { (date: $0.key, photos: $0.value) }
    }

    /// 日付グループの統計情報を取得
    ///
    /// - Parameter dateGroups: 日付別にグループ化された写真
    /// - Returns: グループ統計情報
    public func getDateGroupStatistics(dateGroups: [Date: [Photo]]) -> GroupingStatistics {
        let groups = Array(dateGroups.values)
        return getGroupStatistics(groups: groups)
    }

    /// PHAssetを日付（日単位）でグループ化
    ///
    /// Phase X1-1 最適化: PHAssetを直接日付単位で分割。
    /// PhotoGrouper等でPHAssetを直接扱う場合に使用。
    ///
    /// - Parameter assets: グループ化するPHAsset配列
    /// - Returns: 日付をキーとしたPHAssetグループの辞書
    public func groupAssetsByDate(_ assets: [PHAsset]) -> [Date: [PHAsset]] {
        guard !assets.isEmpty else { return [:] }

        var dateGroups: [Date: [PHAsset]] = [:]
        dateGroups.reserveCapacity(min(assets.count, 365))

        for asset in assets {
            // PHAssetのcreationDateがnilの場合は現在日を使用
            let creationDate = asset.creationDate ?? Date()
            let dayStart = calendar.startOfDay(for: creationDate)
            dateGroups[dayStart, default: []].append(asset)
        }

        return dateGroups
    }

    /// PHAssetを日付でグループ化し、日付順にソートされた配列として返す
    ///
    /// - Parameter assets: グループ化するPHAsset配列
    /// - Returns: 日付順にソートされた(日付, PHAsset配列)のタプル配列
    public func groupAssetsByDateSorted(_ assets: [PHAsset]) -> [(date: Date, assets: [PHAsset])] {
        let dateGroups = groupAssetsByDate(assets)

        // 日付順にソート（古い順）
        return dateGroups.sorted { $0.key < $1.key }
            .map { (date: $0.key, assets: $0.value) }
    }
}

/// グループ統計情報
public struct GroupingStatistics: Sendable {
    public let groupCount: Int
    public let minGroupSize: Int
    public let maxGroupSize: Int
    public let avgGroupSize: Double
    public let comparisonReductionRate: Double

    public init(
        groupCount: Int,
        minGroupSize: Int,
        maxGroupSize: Int,
        avgGroupSize: Double,
        comparisonReductionRate: Double
    ) {
        self.groupCount = groupCount
        self.minGroupSize = minGroupSize
        self.maxGroupSize = maxGroupSize
        self.avgGroupSize = avgGroupSize
        self.comparisonReductionRate = comparisonReductionRate
    }
}
