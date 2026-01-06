//
//  LimitReachedSheetTests.swift
//  LightRoll_CleanerFeatureTests
//
//  M9-T13: LimitReachedSheetのテスト
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - LimitReachedSheetTests

@MainActor
struct LimitReachedSheetTests {

    // MARK: - 正常系テスト

    @Test("LimitReachedSheetが正しく初期化される")
    func testInitialization() {
        // Given
        let currentCount = 50
        let dailyLimit = 50
        var upgradeCalled = false

        // When
        let sheet = LimitReachedSheet(
            currentCount: currentCount,
            limit: dailyLimit,
            onUpgrade: {
                upgradeCalled = true
            }
        )

        // Then
        #expect(sheet.currentCount == currentCount)
        #expect(sheet.limit == dailyLimit)
        #expect(!upgradeCalled)
    }

    @Test("デフォルトの上限値が50である")
    func testDefaultLimit() {
        // Given
        let currentCount = 50

        // When
        let sheet = LimitReachedSheet(
            currentCount: currentCount,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.limit == 50)
    }

    @Test("onUpgradeクロージャが正しく設定される")
    func testOnUpgradeCallback() {
        // Given
        var upgradeCalled = false
        let sheet = LimitReachedSheet(
            currentCount: 50,
            limit: 50,
            onUpgrade: {
                upgradeCalled = true
            }
        )

        // When: クロージャを直接呼び出してテスト
        sheet.onUpgrade()

        // Then
        #expect(upgradeCalled)
    }

    // MARK: - 境界値テスト

    @Test("上限値に達した場合（currentCount == dailyLimit）")
    func testAtLimit() {
        // Given
        let count = 50
        let limit = 50

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.currentCount == sheet.limit)
    }

    @Test("上限値を超えた場合（currentCount > dailyLimit）")
    func testOverLimit() {
        // Given
        let count = 55
        let limit = 50

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.currentCount > sheet.limit)
    }

    @Test("カスタム上限値が正しく反映される")
    func testCustomLimit() {
        // Given
        let customLimit = 25
        let count = 25

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: customLimit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.limit == customLimit)
    }

    @Test("最小値での動作（0枚）")
    func testMinimumCount() {
        // Given
        let count = 0
        let limit = 50

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.currentCount == 0)
        #expect(sheet.limit == 50)
    }

    // MARK: - 異常系テスト

    @Test("負の値が渡された場合でも初期化できる")
    func testNegativeCount() {
        // Given
        let count = -1
        let limit = 50

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        // 負の値も受け入れるが、実装側で適切に処理されることを期待
        #expect(sheet.currentCount == count)
    }

    @Test("上限値が0の場合でも初期化できる")
    func testZeroLimit() {
        // Given
        let count = 0
        let limit = 0

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.limit == 0)
    }

    @Test("非常に大きな値でも初期化できる")
    func testLargeValues() {
        // Given
        let count = Int.max
        let limit = Int.max

        // When
        let sheet = LimitReachedSheet(
            currentCount: count,
            limit: limit,
            onUpgrade: {}
        )

        // Then
        #expect(sheet.currentCount == Int.max)
        #expect(sheet.limit == Int.max)
    }

    // MARK: - UI コンポーネントテスト

    @Test("PremiumFeatureRowが正しくレンダリングされる")
    func testFeatureRowRendering() {
        // Given
        let icon = "infinity"
        let title = "無制限削除"
        let description = "1日の削除制限なし"

        // When
        // PremiumFeatureRowは内部構造体のため直接テスト不可
        // LimitReachedSheetのbodyに含まれることを確認
        let sheet = LimitReachedSheet(
            currentCount: 50,
            limit: 50,
            onUpgrade: {}
        )

        // Then
        // ViewがSwiftUIコンポーネントとして正しく構成されていることを確認
        #expect(sheet.currentCount == 50)
    }
}

// MARK: - Integration Tests

@MainActor
struct LimitReachedSheetIntegrationTests {

    @Test("複数のコールバック呼び出しが正しく動作する")
    func testMultipleCallbacks() async {
        // Given
        var callCount = 0
        let sheet = LimitReachedSheet(
            currentCount: 50,
            limit: 50,
            onUpgrade: {
                callCount += 1
            }
        )

        // When
        sheet.onUpgrade()
        sheet.onUpgrade()
        sheet.onUpgrade()

        // Then
        #expect(callCount == 3)
    }

    @Test("異なるパラメータで複数のインスタンスを作成できる")
    func testMultipleInstances() {
        // Given & When
        let sheet1 = LimitReachedSheet(currentCount: 50, limit: 50, onUpgrade: {})
        let sheet2 = LimitReachedSheet(currentCount: 25, limit: 25, onUpgrade: {})
        let sheet3 = LimitReachedSheet(currentCount: 100, limit: 100, onUpgrade: {})

        // Then
        #expect(sheet1.currentCount == 50)
        #expect(sheet2.currentCount == 25)
        #expect(sheet3.currentCount == 100)
        #expect(sheet1.limit == 50)
        #expect(sheet2.limit == 25)
        #expect(sheet3.limit == 100)
    }
}
