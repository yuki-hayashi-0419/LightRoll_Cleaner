import Testing
import Foundation
@testable import LightRoll_CleanerFeature

/// TimeBasedGrouper のテストスイート
@Suite("TimeBasedGrouper Tests")
struct TimeBasedGrouperTests {

    // MARK: - Helper

    /// テスト用の Photo を作成
    private func makePhoto(id: String, capturedDate: Date, fileSize: Int64 = 1000) -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: capturedDate,
            modificationDate: capturedDate,
            mediaType: .image,
            mediaSubtypes: MediaSubtypes(),
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 0,
            fileSize: fileSize,
            isFavorite: false
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
        var photos: [Photo] = []
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

    // MARK: - Phase X1-1: 日付ベース分割テスト

    @Test("日付ベース分割 - 空配列")
    func testGroupByDateEmpty() async {
        let grouper = TimeBasedGrouper()
        let result = await grouper.groupByDate(photos: [])
        #expect(result.isEmpty)
    }

    @Test("日付ベース分割 - 単一写真")
    func testGroupByDateSinglePhoto() async {
        let grouper = TimeBasedGrouper()
        let photo = makePhoto(id: "1", capturedDate: Date())
        let result = await grouper.groupByDate(photos: [photo])

        #expect(result.count == 1)
        #expect(result.values.first?.count == 1)
    }

    @Test("日付ベース分割 - 同じ日の複数写真")
    func testGroupByDateSameDay() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // 同じ日の3枚の写真（異なる時間）
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate.addingTimeInterval(3600)),     // 01:00
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(7200)),     // 02:00
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(12 * 3600)) // 12:00
        ]

        let result = await grouper.groupByDate(photos: photos)

        #expect(result.count == 1) // 1日分のグループ
        #expect(result.values.first?.count == 3) // 3枚すべて同じ日
    }

    @Test("日付ベース分割 - 複数日の写真")
    func testGroupByDateMultipleDays() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // 3日間の写真
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),                                    // 0日目
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(3600)),          // 0日目
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(24 * 3600)),     // 1日目
            makePhoto(id: "4", capturedDate: baseDate.addingTimeInterval(24 * 3600 + 3600)), // 1日目
            makePhoto(id: "5", capturedDate: baseDate.addingTimeInterval(24 * 3600 + 7200)), // 1日目
            makePhoto(id: "6", capturedDate: baseDate.addingTimeInterval(48 * 3600))      // 2日目
        ]

        let result = await grouper.groupByDate(photos: photos)

        #expect(result.count == 3) // 3日分のグループ

        // 各日のカウントを確認
        let sortedGroups = result.sorted { $0.key < $1.key }
        #expect(sortedGroups[0].value.count == 2) // 0日目: 2枚
        #expect(sortedGroups[1].value.count == 3) // 1日目: 3枚
        #expect(sortedGroups[2].value.count == 1) // 2日目: 1枚
    }

    @Test("日付ベース分割 - ソート済み配列の返却")
    func testGroupByDateSorted() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // 順不同で写真を作成
        let photos = [
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(48 * 3600)),
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(24 * 3600))
        ]

        let result = await grouper.groupByDateSorted(photos: photos)

        #expect(result.count == 3)

        // 日付順にソートされていることを確認
        #expect(result[0].date < result[1].date)
        #expect(result[1].date < result[2].date)

        // 各日の写真IDを確認
        #expect(result[0].photos[0].id == "1")
        #expect(result[1].photos[0].id == "2")
        #expect(result[2].photos[0].id == "3")
    }

    @Test("日付ベース分割 - 統計情報")
    func testGroupByDateStatistics() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // 3日間、各日異なる枚数の写真
        var photos: [Photo] = []

        // 0日目: 10枚
        for i in 0..<10 {
            photos.append(makePhoto(id: "day0-\(i)", capturedDate: baseDate.addingTimeInterval(Double(i * 3600))))
        }

        // 1日目: 5枚
        for i in 0..<5 {
            photos.append(makePhoto(id: "day1-\(i)", capturedDate: baseDate.addingTimeInterval(24 * 3600 + Double(i * 3600))))
        }

        // 2日目: 3枚
        for i in 0..<3 {
            photos.append(makePhoto(id: "day2-\(i)", capturedDate: baseDate.addingTimeInterval(48 * 3600 + Double(i * 3600))))
        }

        let dateGroups = await grouper.groupByDate(photos: photos)
        let stats = await grouper.getDateGroupStatistics(dateGroups: dateGroups)

        #expect(stats.groupCount == 3)
        #expect(stats.minGroupSize == 3)
        #expect(stats.maxGroupSize == 10)
        #expect(abs(stats.avgGroupSize - 6.0) < 0.1)

        // 比較回数削減率の検証
        // 全体: 18 * 17 / 2 = 153回
        // グループ: (10 * 9 / 2) + (5 * 4 / 2) + (3 * 2 / 2) = 45 + 10 + 3 = 58回
        // 削減率: (153 - 58) / 153 ≈ 0.621
        #expect(stats.comparisonReductionRate > 0.6)
    }

    @Test("日付ベース分割 - 大規模データセットの削減率")
    func testGroupByDateLargeScaleReduction() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())

        // 100日間、各日100枚の写真（合計10,000枚）
        var photos: [Photo] = []

        for day in 0..<100 {
            for photoIndex in 0..<100 {
                let date = baseDate.addingTimeInterval(Double(day * 24 * 3600 + photoIndex * 60))
                photos.append(makePhoto(id: "d\(day)-p\(photoIndex)", capturedDate: date))
            }
        }

        let dateGroups = await grouper.groupByDate(photos: photos)
        let stats = await grouper.getDateGroupStatistics(dateGroups: dateGroups)

        #expect(stats.groupCount == 100)
        #expect(stats.avgGroupSize == 100.0)

        // 比較回数削減率の検証
        // 全体: 10,000 * 9,999 / 2 ≈ 50,000,000回
        // グループ: 100 * (100 * 99 / 2) = 100 * 4,950 = 495,000回
        // 削減率: (50,000,000 - 495,000) / 50,000,000 ≈ 0.99
        #expect(stats.comparisonReductionRate > 0.98)
    }

    @Test("日付ベース分割 - 深夜0時境界のテスト")
    func testGroupByDateMidnightBoundary() async {
        let grouper = TimeBasedGrouper()
        let calendar = Calendar.current

        // 基準日の23:59:59
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.second = 59
        let beforeMidnight = calendar.date(from: components)!

        // 翌日の00:00:01
        let afterMidnight = beforeMidnight.addingTimeInterval(2)

        let photos = [
            makePhoto(id: "1", capturedDate: beforeMidnight),
            makePhoto(id: "2", capturedDate: afterMidnight)
        ]

        let result = await grouper.groupByDate(photos: photos)

        // 深夜0時を境に別の日として扱われる
        #expect(result.count == 2)
    }
}
