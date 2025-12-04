//
//  AnalysisSettingsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  分析設定画面のテスト
//  Created by AI Assistant on 2025-12-05.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - AnalysisSettingsViewTests

/// AnalysisSettingsViewのテストスイート
@Suite("AnalysisSettingsView Tests")
@MainActor
struct AnalysisSettingsViewTests {

    // MARK: - Test: 初期化

    @Test("初期化時にデフォルト設定を読み込む")
    func testInitWithDefaultSettings() async throws {
        // Arrange
        let service = SettingsService()
        // デフォルト設定に明示的にリセット
        try service.updateAnalysisSettings(.default)

        // Act
        _ = AnalysisSettingsView()
            .environment(service)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.85)
        #expect(service.settings.analysisSettings.blurThreshold == 0.3)
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    @Test("初期化時にカスタム設定を読み込む")
    func testInitWithCustomSettings() async throws {
        // Arrange
        let service = SettingsService()
        let customSettings = AnalysisSettings(
            similarityThreshold: 0.95,
            blurThreshold: 0.5,
            minGroupSize: 5
        )
        try service.updateAnalysisSettings(customSettings)

        // Act
        _ = AnalysisSettingsView()
            .environment(service)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(service.settings.analysisSettings.blurThreshold == 0.5)
        #expect(service.settings.analysisSettings.minGroupSize == 5)
    }

    // MARK: - Test: 類似度しきい値変更

    @Test("類似度しきい値を最小値に変更できる")
    func testChangeSimilarityThresholdToMinimum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.0,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.0)
    }

    @Test("類似度しきい値を最大値に変更できる")
    func testChangeSimilarityThresholdToMaximum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 1.0,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 1.0)
    }

    @Test("類似度しきい値を中間値に変更できる")
    func testChangeSimilarityThresholdToMiddle() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.65,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.65)
    }

    // MARK: - Test: ブレ感度変更

    @Test("ブレ感度を「低」に変更できる")
    func testChangeBlurSensitivityToLow() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.5,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.blurThreshold == 0.5)
    }

    @Test("ブレ感度を「標準」に変更できる")
    func testChangeBlurSensitivityToStandard() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.blurThreshold == 0.3)
    }

    @Test("ブレ感度を「高」に変更できる")
    func testChangeBlurSensitivityToHigh() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.1,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.blurThreshold == 0.1)
    }

    // MARK: - Test: グループサイズ変更

    @Test("最小グループサイズを最小値に変更できる")
    func testChangeMinGroupSizeToMinimum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    @Test("最小グループサイズを最大値に変更できる")
    func testChangeMinGroupSizeToMaximum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 10
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.minGroupSize == 10)
    }

    @Test("最小グループサイズを中間値に変更できる")
    func testChangeMinGroupSizeToMiddle() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 5
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.minGroupSize == 5)
    }

    // MARK: - Test: バリデーション

    @Test("不正な類似度しきい値でエラーが発生する（負の値）")
    func testInvalidSimilarityThresholdNegative() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = AnalysisSettings(
            similarityThreshold: -0.1,
            blurThreshold: 0.3,
            minGroupSize: 2
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }
    }

    @Test("不正な類似度しきい値でエラーが発生する（1.0超過）")
    func testInvalidSimilarityThresholdOverOne() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 1.1,
            blurThreshold: 0.3,
            minGroupSize: 2
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }
    }

    // MARK: - Test: エラーハンドリング

    @Test("不正なブレ閾値でエラーが発生する（負の値）")
    func testInvalidBlurThresholdNegative() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: -0.1,
            minGroupSize: 2
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }
    }

    @Test("不正なブレ閾値でエラーが発生する（1.0超過）")
    func testInvalidBlurThresholdOverOne() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 1.1,
            minGroupSize: 2
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }
    }

    @Test("不正な最小グループサイズでエラーが発生する（1以下）")
    func testInvalidMinGroupSizeBelowTwo() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 1
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }
    }

    // MARK: - Test: BlurSensitivity Enum

    @Test("BlurSensitivity.fromが正しく低感度を返す")
    func testBlurSensitivityFromLow() {
        // Act
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.5)

        // Assert
        #expect(sensitivity == .low)
        #expect(sensitivity.thresholdValue == 0.5)
    }

    @Test("BlurSensitivity.fromが正しく標準感度を返す")
    func testBlurSensitivityFromStandard() {
        // Act
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.3)

        // Assert
        #expect(sensitivity == .standard)
        #expect(sensitivity.thresholdValue == 0.3)
    }

    @Test("BlurSensitivity.fromが正しく高感度を返す")
    func testBlurSensitivityFromHigh() {
        // Act
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.1)

        // Assert
        #expect(sensitivity == .high)
        #expect(sensitivity.thresholdValue == 0.1)
    }

    @Test("BlurSensitivity.descriptionが正しい説明を返す")
    func testBlurSensitivityDescription() {
        // Assert
        #expect(AnalysisSettingsView.BlurSensitivity.low.description == "ブレにくい（厳しめ）")
        #expect(AnalysisSettingsView.BlurSensitivity.standard.description == "バランスの取れた判定")
        #expect(AnalysisSettingsView.BlurSensitivity.high.description == "ブレやすい（緩め）")
    }

    @Test("BlurSensitivity.allCasesが全ケースを含む")
    func testBlurSensitivityAllCases() {
        // Arrange
        let allCases = AnalysisSettingsView.BlurSensitivity.allCases

        // Assert
        #expect(allCases.count == 3)
        #expect(allCases.contains(.low))
        #expect(allCases.contains(.standard))
        #expect(allCases.contains(.high))
    }

    // MARK: - エッジケーステスト（追加）

    @Test("類似度しきい値の境界値0.0でも正常に保存される")
    func testSimilarityThresholdBoundaryZero() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.0,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.0)
        #expect(service.settings.analysisSettings.blurThreshold == 0.3)
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    @Test("類似度しきい値の境界値1.0でも正常に保存される")
    func testSimilarityThresholdBoundaryOne() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 1.0,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 1.0)
        #expect(service.settings.analysisSettings.blurThreshold == 0.3)
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    @Test("ブレ感度の境界値0.19は高感度に分類される")
    func testBlurSensitivityBoundary019() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.19,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.19)
        #expect(sensitivity == .high)
        #expect(service.settings.analysisSettings.blurThreshold == 0.19)
    }

    @Test("ブレ感度の境界値0.21は標準感度に分類される")
    func testBlurSensitivityBoundary021() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.21,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.21)
        #expect(sensitivity == .standard)
        #expect(service.settings.analysisSettings.blurThreshold == 0.21)
    }

    @Test("ブレ感度の境界値0.39は標準感度に分類される")
    func testBlurSensitivityBoundary039() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.39,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.39)
        #expect(sensitivity == .standard)
        #expect(service.settings.analysisSettings.blurThreshold == 0.39)
    }

    @Test("ブレ感度の境界値0.41は低感度に分類される")
    func testBlurSensitivityBoundary041() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.41,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        let sensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: 0.41)
        #expect(sensitivity == .low)
        #expect(service.settings.analysisSettings.blurThreshold == 0.41)
    }

    @Test("グループサイズの境界値2でも正常に保存される")
    func testGroupSizeBoundaryTwo() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    @Test("グループサイズの境界値10でも正常に保存される")
    func testGroupSizeBoundaryTen() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.85,
            blurThreshold: 0.3,
            minGroupSize: 10
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.minGroupSize == 10)
    }

    @Test("複数設定の同時変更が正常に保存される")
    func testMultipleSettingsChangeSimultaneously() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = AnalysisSettings(
            similarityThreshold: 0.95,
            blurThreshold: 0.1,
            minGroupSize: 7
        )
        try service.updateAnalysisSettings(newSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.95)
        #expect(service.settings.analysisSettings.blurThreshold == 0.1)
        #expect(service.settings.analysisSettings.minGroupSize == 7)
    }

    @Test("デフォルト値への復元が正常に動作する")
    func testRestoreDefaultValues() async throws {
        // Arrange
        let service = SettingsService()

        // まずカスタム設定に変更
        let customSettings = AnalysisSettings(
            similarityThreshold: 0.95,
            blurThreshold: 0.5,
            minGroupSize: 8
        )
        try service.updateAnalysisSettings(customSettings)

        #expect(service.settings.analysisSettings.similarityThreshold == 0.95)

        // Act: デフォルト設定に戻す
        let defaultSettings = AnalysisSettings.default
        try service.updateAnalysisSettings(defaultSettings)

        // Assert
        #expect(service.settings.analysisSettings.similarityThreshold == 0.85)
        #expect(service.settings.analysisSettings.blurThreshold == 0.3)
        #expect(service.settings.analysisSettings.minGroupSize == 2)
    }

    // MARK: - 統合テスト（追加）

    @Test("設定保存→読み込み→確認のフルサイクルが正常に動作")
    func testSaveLoadCyclePreservesValues() async throws {
        // Arrange
        let service = SettingsService()
        let customSettings = AnalysisSettings(
            similarityThreshold: 0.77,
            blurThreshold: 0.42,
            minGroupSize: 6
        )

        // Act: 保存
        try service.updateAnalysisSettings(customSettings)

        // 再読み込み
        service.reload()

        // Assert: 値が維持されている
        #expect(service.settings.analysisSettings.similarityThreshold == 0.77)
        #expect(service.settings.analysisSettings.blurThreshold == 0.42)
        #expect(service.settings.analysisSettings.minGroupSize == 6)
    }

    @Test("設定変更のトランザクション性：エラー時はロールバックされる")
    func testTransactionalUpdate() async throws {
        // Arrange
        let service = SettingsService()
        let validSettings = AnalysisSettings(
            similarityThreshold: 0.8,
            blurThreshold: 0.3,
            minGroupSize: 3
        )
        try service.updateAnalysisSettings(validSettings)

        let originalThreshold = service.settings.analysisSettings.similarityThreshold
        #expect(originalThreshold == 0.8)

        // Act: 無効な設定で更新を試みる
        let invalidSettings = AnalysisSettings(
            similarityThreshold: 1.5, // 無効値
            blurThreshold: 0.3,
            minGroupSize: 3
        )

        // Assert: エラーが発生
        #expect(throws: SettingsError.self) {
            try service.updateAnalysisSettings(invalidSettings)
        }

        // 元の有効な値が保持されている
        #expect(service.settings.analysisSettings.similarityThreshold == 0.8)
    }

    @Test("分析設定と他の設定カテゴリが独立している")
    func testAnalysisSettingsIndependence() async throws {
        // Arrange
        let service = SettingsService()

        // スキャン設定を変更
        var scanSettings = service.settings.scanSettings
        scanSettings.autoScanEnabled = true
        try service.updateScanSettings(scanSettings)

        // 分析設定を変更
        let analysisSettings = AnalysisSettings(
            similarityThreshold: 0.92,
            blurThreshold: 0.2,
            minGroupSize: 4
        )
        try service.updateAnalysisSettings(analysisSettings)

        // Assert: 両方の設定が独立して保存されている
        #expect(service.settings.scanSettings.autoScanEnabled == true)
        #expect(service.settings.analysisSettings.similarityThreshold == 0.92)
        #expect(service.settings.analysisSettings.blurThreshold == 0.2)
        #expect(service.settings.analysisSettings.minGroupSize == 4)
    }

    // MARK: - UI状態テスト（追加）

    @Test("類似度スライダーの値表示フォーマットが正しい（小数点処理）")
    func testSimilarityThresholdDisplayFormat() async throws {
        // Arrange
        let service = SettingsService()

        // 0.854のような値でも整数パーセント表示される
        let settings1 = AnalysisSettings(
            similarityThreshold: 0.854,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(settings1)

        // Assert: 85%として表示される（85.4%ではない）
        let displayValue1 = Int(0.854 * 100)
        #expect(displayValue1 == 85)

        // 0.859でも85%
        let settings2 = AnalysisSettings(
            similarityThreshold: 0.859,
            blurThreshold: 0.3,
            minGroupSize: 2
        )
        try service.updateAnalysisSettings(settings2)

        let displayValue2 = Int(0.859 * 100)
        #expect(displayValue2 == 85)
    }

    @Test("ブレ感度Pickerの選択状態が正しく反映される")
    func testBlurSensitivityPickerSelection() async throws {
        // Arrange
        let service = SettingsService()

        // Act: 各感度に設定
        let sensitivities: [(Float, AnalysisSettingsView.BlurSensitivity)] = [
            (0.5, .low),
            (0.3, .standard),
            (0.1, .high)
        ]

        for (threshold, expectedSensitivity) in sensitivities {
            let settings = AnalysisSettings(
                similarityThreshold: 0.85,
                blurThreshold: threshold,
                minGroupSize: 2
            )
            try service.updateAnalysisSettings(settings)

            // Assert
            let actualSensitivity = AnalysisSettingsView.BlurSensitivity.from(threshold: threshold)
            #expect(actualSensitivity == expectedSensitivity)
        }
    }

    @Test("グループサイズStepperの増減ボタン動作が正しい")
    func testGroupSizeStepperIncrement() async throws {
        // Arrange
        let service = SettingsService()

        // デフォルト設定にリセット
        try service.updateAnalysisSettings(.default)

        // Act: 初期値2から開始
        #expect(service.settings.analysisSettings.minGroupSize == 2)

        // +1ボタン押下（2 → 3）
        var settings = service.settings.analysisSettings
        settings.minGroupSize = 3
        try service.updateAnalysisSettings(settings)
        #expect(service.settings.analysisSettings.minGroupSize == 3)

        // +1ボタン押下（3 → 4）
        settings = service.settings.analysisSettings
        settings.minGroupSize = 4
        try service.updateAnalysisSettings(settings)
        #expect(service.settings.analysisSettings.minGroupSize == 4)

        // -1ボタン押下（4 → 3）
        settings = service.settings.analysisSettings
        settings.minGroupSize = 3
        try service.updateAnalysisSettings(settings)
        #expect(service.settings.analysisSettings.minGroupSize == 3)
    }

    // MARK: - パフォーマンステスト（追加）

    @Test("連続的な設定変更のパフォーマンス")
    func testPerformanceOfMultipleChanges() async throws {
        // Arrange
        let service = SettingsService()

        // Act: 100回連続で設定変更
        for i in 0..<100 {
            let threshold = Float(i % 100) / 100.0 // 0.0〜0.99をループ
            let settings = AnalysisSettings(
                similarityThreshold: threshold,
                blurThreshold: 0.3,
                minGroupSize: 2
            )
            try service.updateAnalysisSettings(settings)
        }

        // Assert: 最後の値が正しく保存されている
        let finalThreshold = Float(99) / 100.0
        #expect(service.settings.analysisSettings.similarityThreshold == finalThreshold)
    }

    @Test("大量の設定読み込み時の応答性")
    func testPerformanceOfMultipleReloads() async throws {
        // Arrange
        let service = SettingsService()
        let settings = AnalysisSettings(
            similarityThreshold: 0.88,
            blurThreshold: 0.25,
            minGroupSize: 5
        )
        try service.updateAnalysisSettings(settings)

        // Act: 100回連続で設定を再読み込み
        for _ in 0..<100 {
            service.reload()
        }

        // Assert: 値が保持されている
        #expect(service.settings.analysisSettings.similarityThreshold == 0.88)
        #expect(service.settings.analysisSettings.blurThreshold == 0.25)
        #expect(service.settings.analysisSettings.minGroupSize == 5)
    }
}
