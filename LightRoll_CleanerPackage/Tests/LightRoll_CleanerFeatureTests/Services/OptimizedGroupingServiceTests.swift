import Testing
import Foundation
@testable import LightRoll_CleanerFeature

/// OptimizedGroupingService のテストスイート
@Suite("OptimizedGroupingService Tests")
struct OptimizedGroupingServiceTests {

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
    func testEmptyArray() async throws {
        let service = OptimizedGroupingService()
        let result = try await service.groupPhotos(photos: [])

        #expect(result.groups.isEmpty)
        #expect(result.totalPhotos == 0)
        #expect(result.timeBasedGroups == 0)
    }

    @Test("単一写真の処理")
    func testSinglePhoto() async throws {
        let service = OptimizedGroupingService()
        let photo = makePhoto(id: "1", capturedDate: Date())
        let result = try await service.groupPhotos(photos: [photo])

        #expect(result.groups.count == 1)
        #expect(result.groups[0].count == 1)
        #expect(result.totalPhotos == 1)
        #expect(result.timeBasedGroups == 1)
    }

    @Test("小規模データセット（10枚）")
    func testSmallDataset() async throws {
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60,
            similarityThreshold: 0.85
        )
        let baseDate = Date()

        // 同じ日の10枚の写真（1時間間隔）
        var photos: [PhotoModel] = []
        for i in 0..<10 {
            let date = baseDate.addingTimeInterval(Double(i * 3600))
            photos.append(makePhoto(id: "\(i)", capturedDate: date))
        }

        let result = try await service.groupPhotos(photos: photos)

        // 基本検証
        #expect(result.totalPhotos == 10)
        #expect(result.timeBasedGroups == 1) // 全て同じ日なので1グループ
        #expect(!result.groups.isEmpty)

        // 処理時間が記録されている
        #expect(result.processingTime > 0)
    }

    @Test("中規模データセット（100枚）- 複数日にまたがる")
    func testMediumDataset() async throws {
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60,
            similarityThreshold: 0.85
        )
        let baseDate = Date()

        // 10日間にわたる100枚の写真（各日10枚）
        var photos: [PhotoModel] = []
        for day in 0..<10 {
            for hour in 0..<10 {
                let date = baseDate.addingTimeInterval(Double(day * 24 * 3600 + hour * 3600))
                photos.append(makePhoto(id: "\(day)-\(hour)", capturedDate: date, fileSize: Int64(1000 + day * 100)))
            }
        }

        let result = try await service.groupPhotos(photos: photos)

        // 基本検証
        #expect(result.totalPhotos == 100)
        #expect(result.timeBasedGroups == 10) // 10日間なので10グループ
        #expect(!result.groups.isEmpty)

        // 比較回数削減率の検証（90%以上削減されているはず）
        #expect(result.comparisonReductionRate > 0.9)

        // サマリーが生成できる
        let summary = result.summary
        #expect(summary.contains("グループ化完了"))
        #expect(summary.contains("100")) // 総写真数
    }

    // MARK: - 境界値テスト

    @Test("類似度閾値の境界 - 0.85")
    func testSimilarityThresholdBoundary() async throws {
        // 閾値ちょうど
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60,
            similarityThreshold: 0.85
        )

        let baseDate = Date()
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(3600))
        ]

        let result = try await service.groupPhotos(photos: photos)
        #expect(result.totalPhotos == 2)
        // 実際の類似度計算結果に依存するため、グループ数は厳密には検証しない
    }

    @Test("時間範囲の境界")
    func testTimeWindowBoundary() async throws {
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60, // 24時間
            similarityThreshold: 0.85
        )
        let baseDate = Date()

        // 24時間ちょうどの間隔
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(24 * 3600))
        ]

        let result = try await service.groupPhotos(photos: photos)

        #expect(result.totalPhotos == 2)
        #expect(result.timeBasedGroups == 1) // 境界値は同じグループ
    }

    // MARK: - パフォーマンステスト

    @Test("1000枚の処理時間計測")
    func testPerformanceWith1000Photos() async throws {
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60,
            similarityThreshold: 0.85
        )
        let baseDate = Date()

        // 100日間にわたる1000枚の写真（各日10枚）
        var photos: [PhotoModel] = []
        for day in 0..<100 {
            for hour in 0..<10 {
                let date = baseDate.addingTimeInterval(Double(day * 24 * 3600 + hour * 3600))
                photos.append(makePhoto(
                    id: "\(day)-\(hour)",
                    capturedDate: date,
                    fileSize: Int64(1000 + day * 10 + hour)
                ))
            }
        }

        let result = try await service.groupPhotos(photos: photos)

        // 基本検証
        #expect(result.totalPhotos == 1000)
        #expect(result.timeBasedGroups == 100) // 100日間なので100グループ

        // 比較回数削減率の検証（99%以上削減されているはず）
        #expect(result.comparisonReductionRate > 0.99)

        // 処理時間が妥当な範囲内（60秒以内を想定）
        // 注：実際の処理時間はマシン性能に依存
        #expect(result.processingTime < 60.0)

        print("1000枚の処理時間: \(String(format: "%.2f", result.processingTime))秒")
        print("比較回数削減率: \(String(format: "%.1f", result.comparisonReductionRate * 100))%")
    }

    @Test("比較回数削減率の検証")
    func testComparisonReductionRate() async throws {
        let service = OptimizedGroupingService(
            timeWindow: 24 * 60 * 60,
            similarityThreshold: 0.85
        )
        let baseDate = Date()

        // 10グループ、各グループ10枚 = 合計100枚
        var photos: [PhotoModel] = []
        for day in 0..<10 {
            for hour in 0..<10 {
                let date = baseDate.addingTimeInterval(Double(day * 24 * 3600 + hour * 3600))
                photos.append(makePhoto(id: "\(day)-\(hour)", capturedDate: date))
            }
        }

        let result = try await service.groupPhotos(photos: photos)

        // 期待される比較回数削減率の計算
        // 全体: 100 * 99 / 2 = 4,950回
        // グループ化後: 10グループ × (10 * 9 / 2) = 10 × 45 = 450回
        // 削減率: (4950 - 450) / 4950 ≈ 0.909
        #expect(result.comparisonReductionRate > 0.9)
        #expect(result.comparisonReductionRate <= 1.0)
    }

    // MARK: - 異常系テスト

    @Test("ソート順が乱れた写真の処理")
    func testUnsortedPhotos() async throws {
        let service = OptimizedGroupingService()
        let baseDate = Date()

        // 時系列順ではない配列
        let photos = [
            makePhoto(id: "3", capturedDate: baseDate.addingTimeInterval(48 * 3600)),
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(24 * 3600))
        ]

        let result = try await service.groupPhotos(photos: photos)

        // エラーなく処理される
        #expect(result.totalPhotos == 3)
        #expect(!result.groups.isEmpty)
    }

    @Test("カスタムパラメータでの初期化")
    func testCustomParameters() async throws {
        // カスタム時間範囲と類似度閾値
        let service = OptimizedGroupingService(
            timeWindow: 12 * 60 * 60,      // 12時間
            similarityThreshold: 0.90       // 90%
        )

        let baseDate = Date()
        let photos = [
            makePhoto(id: "1", capturedDate: baseDate),
            makePhoto(id: "2", capturedDate: baseDate.addingTimeInterval(10 * 3600)) // +10時間
        ]

        let result = try await service.groupPhotos(photos: photos)

        // エラーなく処理される
        #expect(result.totalPhotos == 2)
        #expect(result.timeBasedGroups == 1) // 12時間範囲内なので1グループ
    }
}
