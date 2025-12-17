import Testing
import Foundation
@testable import LightRoll_CleanerFeature

/// TimeBasedGrouper のテストスイート
@Suite("TimeBasedGrouper Tests")
struct TimeBasedGrouperTests {

    // MARK: - Helper

    /// テスト用の PhotoModel を作成
    private func makePhoto(id: String, capturedDate: Date, fileSize: Int64 = 1000) -> PhotoModel {
        PhotoModel(
            id: id,
            fileName: "\(id).jpg",
            filePath: "/test/\(id).jpg",
            fileSize: fileSize,
            capturedDate: capturedDate,
            modifiedDate: capturedDate,
            width: 1920,
            height: 1080,
            orientation: .up
        )
    }

    // MARK: - 正常系テスト

    @Test("空配列の処理")
    func testEmptyArray() async {
        let grouper = TimeBasedGrouper()
        let result = await grouper.groupByTime(photos: [])
        #expect(result.isEmpty)
    }

    @Test("単一写真の処理")
    func testSinglePhoto() async {
        let grouper = TimeBasedGrouper()
        let photo = makePhoto(id: "1", capturedDate: Date())
        let result = await grouper.groupByTime(photos: [photo])

        #expect(result.count == 1)
        #expect(result[0].count == 1)
        #expect(result[0][0].id == "1")
    }

    @Test("同じ日の写真を1グループにまとめる")
    func testSameDayGrouping() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60) // 24時間
        let baseDate = Date()

        // 同じ日の3枚の写真（1時間間隔）
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(3600)), // +1時間
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(7200))  // +2時間
        ]

        let result = await grouper.groupByTime(photos: photos)

        #expect(result.count == 1) // 1グループ
        #expect(result[0].count == 3) // 3枚すべて同じグループ
    }

    @Test("異なる日の写真を複数グループに分ける")
    func testMultipleDayGrouping() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60) // 24時間
        let baseDate = Date()

        // 3日間の写真（各日1枚）
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(25 * 3600)), // +25時間（翌日）
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(50 * 3600))  // +50時間（2日後）
        ]

        let result = await grouper.groupByTime(photos: photos)

        #expect(result.count == 3) // 3グループ
        #expect(result[0].count == 1)
        #expect(result[1].count == 1)
        #expect(result[2].count == 1)
    }

    @Test("時間範囲の境界テスト - 24時間ちょうど")
    func testTimeWindowBoundary() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60) // 24時間
        let baseDate = Date()

        // 24時間ちょうどの間隔
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(24 * 3600)) // ちょうど24時間後
        ]

        let result = await grouper.groupByTime(photos: photos)

        #expect(result.count == 1) // 境界値は同じグループに含まれる
        #expect(result[0].count == 2)
    }

    // MARK: - 統計情報テスト

    @Test("統計情報の正確性")
    func testGroupStatistics() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60)
        let baseDate = Date()

        // 2グループ（各グループ3枚と2枚）
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(3600)),
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(7200)),
            makePhoto(id: "4", capturedDate: baseDate.addingTimeInterval(30 * 3600)), // 翌日
            makePhoto(id: "5", capturedDate: baseDate.addingTimeInterval(31 * 3600))
        ]

        let groups = await grouper.groupByTime(photos: photos)
        let stats = await grouper.getGroupStatistics(groups: groups)

        #expect(stats.groupCount == 2)
        #expect(stats.minGroupSize == 2)
        #expect(stats.maxGroupSize == 3)
        #expect(stats.avgGroupSize == 2.5)

        // 比較回数削減率の検証
        // 全体: 5 * 4 / 2 = 10回
        // グループ1: 3 * 2 / 2 = 3回
        // グループ2: 2 * 1 / 2 = 1回
        // 削減率: (10 - 4) / 10 = 0.6
        #expect(abs(stats.comparisonReductionRate - 0.6) < 0.01)
    }

    @Test("大規模データセットの比較回数削減率")
    func testComparisonReductionRate() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60)
        let baseDate = Date()

        // 100枚の写真を10日間に分散（各日10枚）
        var photos: [PhotoModel] = []
        for day in 0..<10 {
            for hour in 0..<10 {
                let date = baseDate.addingTimeInterval(Double(day * 24 * 3600 + hour * 3600))
                photos.append(makePhoto(id: "\(day)-\(hour)", capturedDate: date))
            }
        }

        let groups = await grouper.groupByTime(photos: photos)
        let stats = await grouper.getGroupStatistics(groups: groups)

        // 10グループに分かれることを確認
        #expect(stats.groupCount == 10)

        // 各グループは10枚
        #expect(stats.avgGroupSize == 10.0)

        // 比較回数削減率の検証
        // 全体: 100 * 99 / 2 = 4,950回
        // グループ: 10 * (10 * 9 / 2) = 10 * 45 = 450回
        // 削減率: (4950 - 450) / 4950 ≈ 0.909
        #expect(stats.comparisonReductionRate > 0.9)
    }

    // MARK: - 異常系テスト

    @Test("ソート順が乱れた写真の処理")
    func testUnsortedPhotos() async {
        let grouper = TimeBasedGrouper(timeWindow: 24 * 60 * 60)
        let baseDate = Date()

        // 時系列順ではない配列
        let photos = [
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(7200)),
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(3600))
        ]

        let result = await grouper.groupByTime(photos: photos)

        // 内部でソートされて1グループになる
        #expect(result.count == 1)
        #expect(result[0].count == 3)

        // ソート順の確認
        #expect(result[0][0].id == "1")
        #expect(result[0][1].id == "2")
        #expect(result[0][2].id == "3")
    }

    @Test("カスタム時間範囲の設定")
    func testCustomTimeWindow() async {
        // 12時間の時間範囲
        let grouper = TimeBasedGrouper(timeWindow: 12 * 60 * 60)
        let baseDate = Date()

        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(10 * 3600)), // +10時間
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(13 * 3600))  // +13時間
        ]

        let result = await grouper.groupByTime(photos: photos)

        // 12時間範囲なので2グループに分かれる
        #expect(result.count == 2)
        #expect(result[0].count == 2)
        #expect(result[1].count == 1)
    }
}
