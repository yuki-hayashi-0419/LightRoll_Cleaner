import Foundation

/// 最適化されたグループ化サービス
/// 時間ベース事前グルーピング + 並列処理を組み合わせて高速化
public actor OptimizedGroupingService {
    private let timeBasedGrouper: TimeBasedGrouper
    private let similarityCalculator: SimilarityCalculator
    private let similarityThreshold: Double

    /// 初期化
    /// - Parameters:
    ///   - timeWindow: 時間ベースグルーピングの時間範囲（秒）
    ///   - similarityThreshold: 類似判定の閾値（0.0〜1.0）
    public init(
        timeWindow: TimeInterval = 24 * 60 * 60,
        similarityThreshold: Double = 0.85
    ) {
        self.timeBasedGrouper = TimeBasedGrouper(timeWindow: timeWindow)
        self.similarityCalculator = SimilarityCalculator()
        self.similarityThreshold = similarityThreshold
    }

    /// 写真をグループ化（最適化版）
    /// - Parameter photos: グループ化する写真の配列
    /// - Returns: グループ化された結果とメトリクス
    public func groupPhotos(photos: [PhotoModel]) async throws -> GroupingResult {
        let startTime = Date()

        // ステップ1：時間ベース事前グルーピング
        let timeGroups = await timeBasedGrouper.groupByTime(photos: photos)
        let statistics = await timeBasedGrouper.getGroupStatistics(groups: timeGroups)

        // ステップ2：各時間グループ内で類似度ベースのグループ化（並列処理）
        let similarityGroups = try await withThrowingTaskGroup(
            of: [[PhotoModel]].self,
            returning: [[PhotoModel]].self
        ) { group in
            for timeGroup in timeGroups {
                group.addTask {
                    try await self.groupBySimilarity(photos: timeGroup)
                }
            }

            var allGroups: [[PhotoModel]] = []
            for try await groupResult in group {
                allGroups.append(contentsOf: groupResult)
            }
            return allGroups
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return GroupingResult(
            groups: similarityGroups,
            processingTime: processingTime,
            timeBasedGroups: timeGroups.count,
            comparisonReductionRate: statistics.comparisonReductionRate,
            totalPhotos: photos.count
        )
    }

    /// 1つの時間グループ内で類似度ベースのグループ化
    private func groupBySimilarity(photos: [PhotoModel]) async throws -> [[PhotoModel]] {
        guard photos.count > 1 else { return [photos] }

        var groups: [[PhotoModel]] = []
        var remaining = photos

        while !remaining.isEmpty {
            let representative = remaining.removeFirst()
            var currentGroup = [representative]

            // 並列で類似度計算
            let similarities = await withTaskGroup(
                of: (PhotoModel, Double).self,
                returning: [(PhotoModel, Double)].self
            ) { group in
                for photo in remaining {
                    group.addTask {
                        let similarity = await self.similarityCalculator.calculateSimilarity(
                            between: representative,
                            and: photo
                        )
                        return (photo, similarity)
                    }
                }

                var results: [(PhotoModel, Double)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            // 類似している写真をグループに追加
            var toRemove: [PhotoModel] = []
            for (photo, similarity) in similarities {
                if similarity >= similarityThreshold {
                    currentGroup.append(photo)
                    toRemove.append(photo)
                }
            }

            // 残りから削除
            remaining.removeAll { photo in
                toRemove.contains { $0.id == photo.id }
            }

            groups.append(currentGroup)
        }

        return groups
    }
}

/// グループ化結果
public struct GroupingResult: Sendable {
    public let groups: [[PhotoModel]]
    public let processingTime: TimeInterval
    public let timeBasedGroups: Int
    public let comparisonReductionRate: Double
    public let totalPhotos: Int

    public init(
        groups: [[PhotoModel]],
        processingTime: TimeInterval,
        timeBasedGroups: Int,
        comparisonReductionRate: Double,
        totalPhotos: Int
    ) {
        self.groups = groups
        self.processingTime = processingTime
        self.timeBasedGroups = timeBasedGroups
        self.comparisonReductionRate = comparisonReductionRate
        self.totalPhotos = totalPhotos
    }

    /// 統計サマリーを取得
    public var summary: String {
        """
        グループ化完了
        - 総写真数: \(totalPhotos)
        - 時間ベースグループ数: \(timeBasedGroups)
        - 最終グループ数: \(groups.count)
        - 比較回数削減率: \(String(format: "%.1f", comparisonReductionRate * 100))%
        - 処理時間: \(String(format: "%.2f", processingTime))秒
        """
    }
}
