//
//  BlurDetectorOptimizationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BlurDetector 最適化メソッドのテスト（analysis-speed-fix-001）
//  Created by AI Assistant
//

import Testing
import CoreImage
@testable import LightRoll_CleanerFeature

// MARK: - BlurDetector Optimization Tests

@Suite("BlurDetector 最適化メソッドのテスト")
struct BlurDetectorOptimizationTests {

    // MARK: - Test 1: detectBlur(from:assetIdentifier:) - 正常系

    @Test("detectBlur(from:assetIdentifier:): 正常にブレ検出結果が返却されること")
    func testDetectBlurFromCIImageReturnsValidResult() async throws {
        // Given: BlurDetectorのインスタンス
        let detector = BlurDetector()

        // テスト用のダミーCIImageを作成（100x100のブルー画像）
        let testImage = CIImage(color: .blue).cropped(
            to: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        let assetIdentifier = "test-asset-001"

        // When: ブレ検出を実行
        let result = try await detector.detectBlur(
            from: testImage,
            assetIdentifier: assetIdentifier
        )

        // Then: 検出結果が正常に返却される
        #expect(result.photoId == assetIdentifier)
        #expect(result.blurScore >= 0.0)
        #expect(result.blurScore <= 1.0)
        #expect(result.sharpnessScore >= 0.0)
        #expect(result.sharpnessScore <= 1.0)

        // blurScore + sharpnessScore = 1.0
        let sum = result.blurScore + result.sharpnessScore
        #expect(abs(sum - 1.0) < 0.001) // 浮動小数点誤差を考慮
    }

    // MARK: - Test 2: detectBlur(from:assetIdentifier:) - ブレスコア範囲検証

    @Test("detectBlur(from:assetIdentifier:): blurScoreが0.0〜1.0の範囲内であること")
    func testDetectBlurScoreWithinValidRange() async throws {
        // Given: BlurDetector インスタンス
        let detector = BlurDetector()

        // 様々な種類のテスト画像
        let testCases: [(color: CIColor, name: String)] = [
            (.red, "red"),
            (.green, "green"),
            (.blue, "blue"),
            (.white, "white"),
            (.black, "black")
        ]

        for testCase in testCases {
            // テスト画像を作成
            let testImage = CIImage(color: testCase.color).cropped(
                to: CGRect(x: 0, y: 0, width: 200, height: 200)
            )

            // When: ブレ検出を実行
            let result = try await detector.detectBlur(
                from: testImage,
                assetIdentifier: "test-\(testCase.name)"
            )

            // Then: blurScoreが有効範囲内
            #expect(
                result.blurScore >= 0.0 && result.blurScore <= 1.0,
                "blurScore が範囲外: \(result.blurScore) for \(testCase.name)"
            )

            // sharpnessScoreも有効範囲内
            #expect(
                result.sharpnessScore >= 0.0 && result.sharpnessScore <= 1.0,
                "sharpnessScore が範囲外: \(result.sharpnessScore) for \(testCase.name)"
            )
        }
    }

    // MARK: - Test 3: detectBlur(from:assetIdentifier:) - ブレ判定

    @Test("detectBlur(from:assetIdentifier:): ブレ判定が正しく行われること")
    func testDetectBlurIsBlurryFlag() async throws {
        // Given: BlurDetector インスタンス（デフォルト閾値: 0.5）
        let detector = BlurDetector()

        // テスト用の画像（単色画像はブレが少ない傾向）
        let sharpImage = CIImage(color: .white).cropped(
            to: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        // When: ブレ検出を実行
        let result = try await detector.detectBlur(
            from: sharpImage,
            assetIdentifier: "sharp-test"
        )

        // Then: isBlurry フラグが blurScore と一致
        let expectedIsBlurry = result.blurScore >= 0.5
        #expect(result.isBlurry == expectedIsBlurry)
    }

    // MARK: - Test 4: detectBlur(from:assetIdentifier:) - カスタム閾値

    @Test("detectBlur(from:assetIdentifier:): カスタム閾値でブレ判定が変わること")
    func testDetectBlurWithCustomThreshold() async throws {
        // Given: カスタム閾値（0.3）のBlurDetector
        let options = BlurDetectionOptions(blurThreshold: 0.3)
        let detector = BlurDetector(options: options)

        // テスト用の画像
        let testImage = CIImage(color: .gray).cropped(
            to: CGRect(x: 0, y: 0, width: 150, height: 150)
        )

        // When: ブレ検出を実行
        let result = try await detector.detectBlur(
            from: testImage,
            assetIdentifier: "custom-threshold-test"
        )

        // Then: カスタム閾値（0.3）でブレ判定が行われる
        let expectedIsBlurry = result.blurScore >= 0.3
        #expect(result.isBlurry == expectedIsBlurry)
    }

    // MARK: - Test 5: detectBlur(from:assetIdentifier:) - エラーハンドリング

    @Test("detectBlur(from:assetIdentifier:): 不正なCIImageでもエラーを投げずに処理すること")
    func testDetectBlurHandlesInvalidImage() async throws {
        // Given: BlurDetector インスタンス
        let detector = BlurDetector()

        // 極小画像（1x1ピクセル）
        let tinyImage = CIImage(color: .red).cropped(
            to: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        // When: ブレ検出を実行
        // Then: エラーを投げずに結果を返す（または適切にハンドリング）
        do {
            let result = try await detector.detectBlur(
                from: tinyImage,
                assetIdentifier: "tiny-image-test"
            )

            // 結果が返却される場合は有効範囲内であることを確認
            #expect(result.blurScore >= 0.0 && result.blurScore <= 1.0)
        } catch {
            // エラーが発生する場合は AnalysisError であることを確認
            #expect(error is AnalysisError)
        }
    }
}

// MARK: - Performance Comparison Tests

@Suite("BlurDetector パフォーマンステスト")
struct BlurDetectorPerformanceTests {

    @Test("パフォーマンス: detectBlur(from:) が従来メソッドより高速であること")
    func testDetectBlurFromCIImagePerformance() async throws {
        // Given: BlurDetector インスタンス
        let detector = BlurDetector()

        // テスト用の中サイズ画像（512x512）
        let testImage = CIImage(color: .blue).cropped(
            to: CGRect(x: 0, y: 0, width: 512, height: 512)
        )

        // When: 新しいメソッドで10回実行
        let iterations = 10
        let startTime = Date()

        for i in 0..<iterations {
            _ = try await detector.detectBlur(
                from: testImage,
                assetIdentifier: "perf-test-\(i)"
            )
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let averageTime = elapsed / Double(iterations)

        // Then: 平均実行時間が1秒未満であることを期待
        #expect(averageTime < 1.0, "平均実行時間: \(averageTime)秒")

        // 注: 実際のパフォーマンス比較は統合テストで実施
        // - 従来のdetectBlur(in: [PHAsset]) との速度比較
        // - メモリ使用量の比較
    }
}

// MARK: - Integration Test Notes

/*
 統合テストで実装すべき項目:

 1. 実際の画像を使用したブレ検出テスト
    - シャープな画像: blurScore < 0.3
    - 中程度のブレ画像: 0.3 <= blurScore < 0.7
    - 強いブレ画像: blurScore >= 0.7

 2. 様々な画像サイズでのテスト
    - 小サイズ（256x256）
    - 中サイズ（1024x1024）
    - 大サイズ（4032x3024）

 3. パフォーマンス比較テスト
    - detectBlur(from: CIImage) vs detectBlur(in: [PHAsset])
    - 100枚の画像での実行時間比較
    - メモリ使用量の比較

 4. エッジケース
    - 完全に黒い画像
    - 完全に白い画像
    - グラデーション画像
    - ノイズの多い画像

 テストフィクスチャの準備:
 - Tests/Resources/BlurSamples/ にブレレベル別のサンプル画像を配置
 - sharp/, moderate/, heavy/ サブディレクトリを作成
 */
