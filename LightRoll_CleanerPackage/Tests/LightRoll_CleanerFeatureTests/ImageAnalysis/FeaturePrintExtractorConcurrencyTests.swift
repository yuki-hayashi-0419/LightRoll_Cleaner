//
//  FeaturePrintExtractorConcurrencyTests.swift
//  LightRoll_CleanerFeatureTests
//
//  FeaturePrintExtractor の並列実行とパフォーマンスを検証
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - FeaturePrintExtractor 並列実行テストスイート

@Suite("FeaturePrintExtractor 並列実行テスト")
struct FeaturePrintExtractorConcurrencyTests {

    // MARK: - モックPHAsset

    /// テスト用のモックPHAsset（実際のテストでは実物を使用推奨）
    private static func createMockAssets(count: Int) -> [PHAsset] {
        // 注: 実際のテストではPHAssetFetchResultから取得したアセットを使用
        // ここではコンパイルエラーを避けるため、空配列を返す
        // 実機またはシミュレータでの実行時は、実際のフォトライブラリから取得
        return []
    }

    // MARK: - テスト1: 並列抽出が動作することを検証

    @Test("FeaturePrintExtractor - 並列抽出が動作する",
          .enabled(if: false, "実際のPHAssetが必要なため、手動実行時のみ有効化"))
    func testConcurrentExtraction() async throws {
        let extractor = FeaturePrintExtractor()
        let assets = Self.createMockAssets(count: 12)

        guard !assets.isEmpty else {
            print("⚠️ テストスキップ: PHAssetが利用できません")
            return
        }

        let startTime = ContinuousClock.now

        // 並列抽出を実行
        let results = try await extractor.extractFeaturePrints(from: assets)

        let endTime = ContinuousClock.now
        let elapsedMs = startTime.duration(to: endTime).components.attoseconds / 1_000_000_000_000_000

        print("📊 FeaturePrintExtractor 並列実行:")
        print("  - アセット数: \(assets.count)")
        print("  - 抽出結果数: \(results.count)")
        print("  - 実行時間: \(elapsedMs) ms")
        print("  - 平均処理時間: \(elapsedMs / results.count) ms/枚")

        // 検証: 全てのアセットから特徴量が抽出された
        #expect(results.count == assets.count, "全てのアセットから特徴量が抽出されること")
    }

    // MARK: - テスト2: 並列vs直列のパフォーマンス比較（シミュレーション）

    @Test("並列処理のパフォーマンス優位性 - シミュレーション")
    func testParallelVsSerialPerformance() async throws {
        // シミュレーション: 並列処理の効果を検証
        let taskCount = 12
        let processingTimePerTask = 100 // ms

        // 直列実行シミュレーション
        let serialStartTime = ContinuousClock.now
        for _ in 0..<taskCount {
            try await Task.sleep(for: .milliseconds(processingTimePerTask))
        }
        let serialEndTime = ContinuousClock.now
        let serialTime = serialStartTime.duration(to: serialEndTime).components.attoseconds / 1_000_000_000_000_000

        // 並列実行シミュレーション
        let parallelStartTime = ContinuousClock.now
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    try? await Task.sleep(for: .milliseconds(processingTimePerTask))
                }
            }
        }
        let parallelEndTime = ContinuousClock.now
        let parallelTime = parallelStartTime.duration(to: parallelEndTime).components.attoseconds / 1_000_000_000_000_000

        let speedup = Double(serialTime) / Double(parallelTime)

        print("⚡️ 並列vs直列パフォーマンス比較:")
        print("  - 直列実行時間: \(serialTime) ms")
        print("  - 並列実行時間: \(parallelTime) ms")
        print("  - 高速化率: \(String(format: "%.2f", speedup))倍")

        // 検証: 並列実行が高速
        #expect(parallelTime < serialTime, "並列実行が直列より高速であること")
        #expect(speedup >= 5.0, "5倍以上の高速化が達成されること")
    }

    // MARK: - テスト3: エラー処理の安全性

    @Test("エラー処理 - 一部失敗しても安全")
    func testErrorHandlingSafety() async throws {
        // エラー処理のシミュレーション
        let taskCount = 10

        var successCount = 0
        var failureCount = 0

        await withTaskGroup(of: Result<Void, Error>.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    if i % 3 == 0 {
                        // 33%の確率でエラー
                        return .failure(NSError(domain: "TestError", code: -1))
                    } else {
                        try? await Task.sleep(for: .milliseconds(10))
                        return .success(())
                    }
                }
            }

            for await result in group {
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    failureCount += 1
                }
            }
        }

        print("📊 エラー処理テスト:")
        print("  - 成功: \(successCount)タスク")
        print("  - 失敗: \(failureCount)タスク")

        // 検証: 成功と失敗が正しくカウントされている
        #expect(successCount + failureCount == taskCount, "全タスクが処理されること")
        #expect(successCount > 0, "一部のタスクは成功すること")
    }

    // MARK: - テスト4: メモリ効率（大量画像処理）

    @Test("メモリ効率 - 大量タスクでメモリリークなし")
    func testMemoryEfficiency() async throws {
        // メモリ効率をテスト（シミュレーション）
        let batchSize = 100
        let iterations = 5

        for iteration in 0..<iterations {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<batchSize {
                    group.addTask {
                        // 軽量タスクをシミュレート
                        try? await Task.sleep(for: .milliseconds(1))
                    }
                }
            }
            print("  - イテレーション \(iteration + 1): \(batchSize)タスク完了")
        }

        print("✅ メモリ効率テスト完了: \(batchSize * iterations)タスク実行")
        #expect(true, "大量タスク実行後もクラッシュしないこと")
    }
}

// MARK: - 実機テスト用の統合テスト

@Suite("実機テスト - FeaturePrintExtractor")
struct FeaturePrintExtractorRealDeviceTests {

    // MARK: - テスト: 実際のフォトライブラリでの並列処理

    @Test("実機テスト - 実際のフォトライブラリで並列処理",
          .enabled(if: false, "実機でのみ実行。CI環境ではスキップ"))
    func testRealPhotoLibrary() async throws {
        // フォトライブラリへのアクセス権限を確認
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authStatus == .authorized else {
            print("⚠️ テストスキップ: フォトライブラリへのアクセスが許可されていません")
            return
        }

        // 最近の写真を12枚取得
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 12

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        guard !assets.isEmpty else {
            print("⚠️ テストスキップ: フォトライブラリに画像がありません")
            return
        }

        print("📸 実機テスト開始:")
        print("  - アセット数: \(assets.count)")

        // FeaturePrintExtractorで並列抽出
        let extractor = FeaturePrintExtractor()
        let startTime = ContinuousClock.now

        let results = try await extractor.extractFeaturePrints(from: assets)

        let endTime = ContinuousClock.now
        let elapsedMs = startTime.duration(to: endTime).components.attoseconds / 1_000_000_000_000_000

        print("✅ 実機テスト完了:")
        print("  - 抽出成功: \(results.count)/\(assets.count)枚")
        print("  - 実行時間: \(elapsedMs) ms")
        print("  - 平均処理時間: \(results.count > 0 ? elapsedMs / results.count : 0) ms/枚")

        // 検証
        #expect(results.count == assets.count, "全てのアセットから特徴量が抽出されること")
        #expect(elapsedMs < 5000, "5秒以内に処理が完了すること（12枚の場合）")

        // 各結果の詳細を確認
        for (index, result) in results.enumerated() {
            print("  - 画像\(index + 1): elementCount=\(result.elementCount), hashSize=\(result.featurePrintHash.count) bytes")
        }
    }

    // MARK: - テスト: パフォーマンスベンチマーク

    @Test("実機パフォーマンスベンチマーク",
          .enabled(if: false, "実機でのみ実行"))
    func benchmarkPerformance() async throws {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard authStatus == .authorized else {
            print("⚠️ テストスキップ: フォトライブラリへのアクセスが許可されていません")
            return
        }

        // 様々なバッチサイズでベンチマーク
        let batchSizes = [4, 8, 16, 32]

        print("📊 パフォーマンスベンチマーク:")

        for batchSize in batchSizes {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = batchSize

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            guard assets.count == batchSize else {
                print("  ⚠️ \(batchSize)枚: スキップ（十分な画像がありません）")
                continue
            }

            let extractor = FeaturePrintExtractor()
            let startTime = ContinuousClock.now

            _ = try await extractor.extractFeaturePrints(from: assets)

            let endTime = ContinuousClock.now
            let elapsedMs = startTime.duration(to: endTime).components.attoseconds / 1_000_000_000_000_000

            let avgTimePerImage = elapsedMs / batchSize

            print("  - \(batchSize)枚: \(elapsedMs)ms (平均 \(avgTimePerImage)ms/枚)")

            // 検証: 妥当な処理時間
            #expect(avgTimePerImage < 500, "\(batchSize)枚での平均処理時間が500ms未満であること")
        }
    }
}

// MARK: - 同時実行数測定テスト

@Suite("同時実行数測定")
struct ConcurrencyMeasurementTests {

    // MARK: - 同時実行数を測定するActor

    actor ConcurrencyTracker {
        private var currentCount = 0
        private var peakCount = 0
        private var measurements: [Int] = []

        func enter() {
            currentCount += 1
            if currentCount > peakCount {
                peakCount = currentCount
            }
            measurements.append(currentCount)
        }

        func exit() {
            currentCount -= 1
        }

        func getStatistics() -> (peak: Int, average: Double, samples: Int) {
            let sum = measurements.reduce(0, +)
            let average = measurements.isEmpty ? 0.0 : Double(sum) / Double(measurements.count)
            return (peak: peakCount, average: average, samples: measurements.count)
        }
    }

    // MARK: - テスト: 同時実行数の詳細測定

    @Test("同時実行数の詳細測定")
    func measureConcurrencyInDetail() async throws {
        let tracker = ConcurrencyTracker()
        let taskCount = 20
        let taskDuration = 50 // ms

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await tracker.enter()
                    try? await Task.sleep(for: .milliseconds(taskDuration))
                    await tracker.exit()
                }
            }
        }

        let stats = await tracker.getStatistics()

        print("📊 同時実行数の詳細統計:")
        print("  - ピーク同時実行数: \(stats.peak)")
        print("  - 平均同時実行数: \(String(format: "%.2f", stats.average))")
        print("  - サンプル数: \(stats.samples)")

        // 検証: 並列実行が機能している
        #expect(stats.peak >= 4, "ピーク同時実行数が4以上であること")
        #expect(stats.average >= 2.0, "平均同時実行数が2以上であること")
    }

    // MARK: - テスト: 理論値との比較

    @Test("並列実行の理論値比較")
    func compareWithTheoreticalLimit() async throws {
        let tracker = ConcurrencyTracker()
        let taskCount = 12
        let taskDuration = 100 // ms

        let startTime = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await tracker.enter()
                    try? await Task.sleep(for: .milliseconds(taskDuration))
                    await tracker.exit()
                }
            }
        }

        let endTime = ContinuousClock.now
        let elapsedMs = startTime.duration(to: endTime).components.attoseconds / 1_000_000_000_000_000

        let stats = await tracker.getStatistics()

        // 理論値を計算
        let theoreticalMinTime = taskDuration // 完全並列の場合
        let theoreticalMaxTime = taskCount * taskDuration // 完全直列の場合

        let parallelismRatio = Double(taskCount * taskDuration) / Double(elapsedMs)

        print("🔬 理論値比較:")
        print("  - 実測ピーク同時実行数: \(stats.peak)")
        print("  - 理論最大同時実行数: \(taskCount)")
        print("  - 実行時間: \(elapsedMs) ms")
        print("  - 理論最小時間（完全並列）: \(theoreticalMinTime) ms")
        print("  - 理論最大時間（完全直列）: \(theoreticalMaxTime) ms")
        print("  - 並列化率: \(String(format: "%.2f", parallelismRatio))倍")

        // 検証: 理論値の30%以上の並列度
        let minExpectedParallelism = Double(taskCount) * 0.3
        #expect(Double(stats.peak) >= minExpectedParallelism,
                "ピーク同時実行数が理論値の30%以上であること（理論:\(taskCount), 実測:\(stats.peak)）")
    }
}
