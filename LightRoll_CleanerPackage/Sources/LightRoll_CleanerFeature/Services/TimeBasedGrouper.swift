import Foundation

/// 時間ベースで写真を事前グルーピングするサービス
/// 大量の写真の類似度計算を最適化するため、時間的に近い写真のみを比較対象にする
public actor TimeBasedGrouper {
    /// 時間範囲の設定（デフォルト：24時間）
    public let timeWindow: TimeInterval

    /// 初期化
    /// - Parameter timeWindow: グループ化する時間範囲（秒単位）。デフォルトは24時間
    public init(timeWindow: TimeInterval = 24 * 60 * 60) {
        self.timeWindow = timeWindow
    }

    /// 写真を撮影時刻でソートし、時間範囲ごとにグループ化
    /// - Parameter photos: グループ化する写真の配列
    /// - Returns: 時間範囲ごとにグループ化された写真の配列
    public func groupByTime(photos: [PhotoModel]) -> [[PhotoModel]] {
        guard !photos.isEmpty else { return [] }

        // 撮影日時でソート
        let sortedPhotos = photos.sorted { $0.capturedDate < $1.capturedDate }

        var groups: [[PhotoModel]] = []
        var currentGroup: [PhotoModel] = [sortedPhotos[0]]
        var groupStartTime = sortedPhotos[0].capturedDate

        for photo in sortedPhotos.dropFirst() {
            let timeDifference = photo.capturedDate.timeIntervalSince(groupStartTime)

            if timeDifference <= timeWindow {
                // 同じ時間範囲内ならグループに追加
                currentGroup.append(photo)
            } else {
                // 時間範囲を超えたら新しいグループ開始
                groups.append(currentGroup)
                currentGroup = [photo]
                groupStartTime = photo.capturedDate
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
    public func getGroupStatistics(groups: [[PhotoModel]]) -> GroupStatistics {
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

        return GroupStatistics(
            groupCount: groupCount,
            minGroupSize: minSize,
            maxGroupSize: maxSize,
            avgGroupSize: avgSize,
            comparisonReductionRate: reductionRate
        )
    }
}

/// グループ統計情報
public struct GroupStatistics: Sendable {
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
