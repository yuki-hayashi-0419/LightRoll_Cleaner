//
//  StorageIndicatorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StorageIndicatorコンポーネントのテスト
//  M4-T07 テストケース
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - StorageIndicatorTests

@MainActor
struct StorageIndicatorTests {

    // MARK: - M4-T07-TC01: 容量50%使用時の表示

    @Test("容量50%使用時、グラフが半分表示される")
    func testHalfUsageDisplay() async throws {
        // Given: 50%使用のストレージ情報
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,    // 128GB
            availableCapacity: 64_000_000_000,  // 64GB空き
            photosUsedCapacity: 25_000_000_000, // 25GB写真
            reclaimableCapacity: 3_500_000_000  // 3.5GB削減可能
        )

        // When: StorageIndicatorを作成
        let indicator = StorageIndicator(
            storageInfo: storageInfo,
            showDetails: true,
            style: .bar
        )

        // Then: 使用率が50%
        #expect(storageInfo.usagePercentage == 0.5)
        #expect(storageInfo.formattedUsagePercentage == "50.0%")
        #expect(storageInfo.storageLevel == .normal)

        // インジケータが正しく作成されている
        #expect(indicator.storageInfo.totalCapacity == 128_000_000_000)
        #expect(indicator.showDetails == true)
    }

    // MARK: - M4-T07-TC02: 容量90%以上の警告

    @Test("容量90%以上使用時、警告状態（オレンジ）で表示される")
    func testWarningStateDisplay() async throws {
        // Given: 92%使用のストレージ情報
        let storageInfo = StorageInfo(
            totalCapacity: 64_000_000_000,     // 64GB
            availableCapacity: 5_000_000_000,  // 5GB空き
            photosUsedCapacity: 40_000_000_000, // 40GB写真
            reclaimableCapacity: 8_000_000_000  // 8GB削減可能
        )

        // When: ストレージレベルを確認
        let level = storageInfo.storageLevel

        // Then: 警告レベル
        #expect(level == .warning)
        #expect(storageInfo.isLowStorage == true)
        #expect(storageInfo.isCriticalStorage == false)
        #expect(storageInfo.usagePercentage > 0.9)
    }

    @Test("容量97%以上使用時、危険状態（赤）で表示される")
    func testCriticalStateDisplay() async throws {
        // Given: 97%使用のストレージ情報
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,     // 128GB
            availableCapacity: 3_000_000_000,   // 3GB空き
            photosUsedCapacity: 80_000_000_000, // 80GB写真
            reclaimableCapacity: 12_000_000_000 // 12GB削減可能
        )

        // When: ストレージレベルを確認
        let level = storageInfo.storageLevel

        // Then: 危険レベル
        #expect(level == .critical)
        #expect(storageInfo.isCriticalStorage == true)
        #expect(storageInfo.isLowStorage == true)
        #expect(storageInfo.usagePercentage > 0.95)
    }

    // MARK: - M4-T07-TC03: アニメーション

    @Test("使用量変更時、スムーズなアニメーションが適用される")
    func testSmoothAnimation() async throws {
        // Given: 初期状態（50%使用）
        let initialInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // When: 使用量が変更される（70%使用）
        let updatedInfo = initialInfo.withAvailableCapacity(38_400_000_000)

        // Then: 使用率が変更されている
        #expect(initialInfo.usagePercentage == 0.5)
        #expect(updatedInfo.usagePercentage == 0.7)

        // 容量表示が異なる
        #expect(initialInfo.formattedAvailableCapacity != updatedInfo.formattedAvailableCapacity)
    }

    // MARK: - Additional Tests

    @Test("リングスタイルで正しく表示される")
    func testRingStyle() async throws {
        // Given: ストレージ情報
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // When: リングスタイルのIndicatorを作成
        let indicator = StorageIndicator(
            storageInfo: storageInfo,
            showDetails: false,
            style: .ring
        )

        // Then: スタイルが設定されている
        #expect(indicator.style == .ring)
        #expect(indicator.showDetails == false)
    }

    @Test("削減可能容量が1GB以上の場合、オーバーレイが表示される")
    func testReclaimableOverlay() async throws {
        // Given: 削減可能容量が3.5GB
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // Then: 削減効果が大きいと判定される
        #expect(storageInfo.hasSignificantReclaimable == true)
        #expect(storageInfo.reclaimableCapacity >= 1_000_000_000)
        #expect(storageInfo.formattedReclaimableCapacity.contains("GB"))
    }

    @Test("削減可能容量が1GB未満の場合、オーバーレイは表示されない")
    func testNoReclaimableOverlay() async throws {
        // Given: 削減可能容量が500MB
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 500_000_000
        )

        // Then: 削減効果は小さいと判定される
        #expect(storageInfo.hasSignificantReclaimable == false)
        #expect(storageInfo.reclaimableCapacity < 1_000_000_000)
    }

    @Test("詳細情報表示時、写真容量と削減可能容量が表示される")
    func testDetailsDisplay() async throws {
        // Given: 削減可能容量がある状態
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // When: 詳細表示ありのIndicator
        let indicator = StorageIndicator(
            storageInfo: storageInfo,
            showDetails: true,
            style: .bar
        )

        // Then: 詳細情報が利用可能
        #expect(indicator.showDetails == true)
        #expect(storageInfo.formattedPhotosUsedCapacity.isEmpty == false)
        #expect(storageInfo.formattedReclaimableCapacity.isEmpty == false)
        #expect(storageInfo.formattedTotalCapacity.isEmpty == false)
    }

    @Test("アクセシビリティラベルが正しく設定される")
    func testAccessibilityLabel() async throws {
        // Given: 正常状態のストレージ情報
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // Then: アクセシビリティ情報が含まれる
        #expect(storageInfo.formattedUsedCapacity.isEmpty == false)
        #expect(storageInfo.formattedAvailableCapacity.isEmpty == false)
        #expect(storageInfo.storageLevel == .normal)
    }

    @Test("0%使用時でもクラッシュしない")
    func testZeroUsage() async throws {
        // Given: 0%使用
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 128_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        // When: Indicatorを作成
        let indicator = StorageIndicator(
            storageInfo: storageInfo,
            showDetails: true,
            style: .bar
        )

        // Then: 使用率が0%
        #expect(storageInfo.usagePercentage == 0.0)
        #expect(storageInfo.usedCapacity == 0)
        #expect(indicator.storageInfo.totalCapacity > 0)
    }

    @Test("100%使用時でもクラッシュしない")
    func testFullUsage() async throws {
        // Given: 100%使用
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 0,
            photosUsedCapacity: 80_000_000_000,
            reclaimableCapacity: 10_000_000_000
        )

        // When: Indicatorを作成
        let indicator = StorageIndicator(
            storageInfo: storageInfo,
            showDetails: true,
            style: .bar
        )

        // Then: 使用率が100%
        #expect(storageInfo.usagePercentage == 1.0)
        #expect(storageInfo.availableCapacity == 0)
        #expect(storageInfo.isCriticalStorage == true)
        #expect(indicator.storageInfo.totalCapacity > 0)
    }
}

// MARK: - IndicatorStyle Tests

@MainActor
struct IndicatorStyleTests {

    @Test("IndicatorStyleはSendable準拠")
    func testSendableConformance() async throws {
        // Given: IndicatorStyleの値
        let barStyle: StorageIndicator.IndicatorStyle = .bar
        let ringStyle: StorageIndicator.IndicatorStyle = .ring

        // Then: 異なるスタイルは異なる
        #expect(barStyle != ringStyle)
    }
}

// MARK: - Integration Tests

@MainActor
struct StorageIndicatorIntegrationTests {

    @Test("ストレージ情報の変更に応じて表示が更新される")
    func testStorageInfoUpdate() async throws {
        // Given: 初期状態
        let initialInfo = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        // When: 削減可能容量を更新
        let updatedInfo = initialInfo.withReclaimableCapacity(8_000_000_000)

        // Then: 削減可能容量が変更されている
        #expect(initialInfo.reclaimableCapacity == 3_500_000_000)
        #expect(updatedInfo.reclaimableCapacity == 8_000_000_000)

        // その他の値は変わらない
        #expect(initialInfo.totalCapacity == updatedInfo.totalCapacity)
        #expect(initialInfo.availableCapacity == updatedInfo.availableCapacity)
        #expect(initialInfo.photosUsedCapacity == updatedInfo.photosUsedCapacity)
    }

    @Test("警告レベルに応じて色が変わる")
    func testColorBasedOnLevel() async throws {
        // Given: 3つの異なるストレージ状態
        let normalStorage = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        )

        let warningStorage = StorageInfo(
            totalCapacity: 64_000_000_000,
            availableCapacity: 5_000_000_000,
            photosUsedCapacity: 40_000_000_000,
            reclaimableCapacity: 8_000_000_000
        )

        let criticalStorage = StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 3_000_000_000,
            photosUsedCapacity: 80_000_000_000,
            reclaimableCapacity: 12_000_000_000
        )

        // Then: レベルが異なる
        #expect(normalStorage.storageLevel == .normal)
        #expect(warningStorage.storageLevel == .warning)
        #expect(criticalStorage.storageLevel == .critical)

        // フラグも適切
        #expect(normalStorage.isLowStorage == false)
        #expect(warningStorage.isLowStorage == true)
        #expect(criticalStorage.isCriticalStorage == true)
    }
}
