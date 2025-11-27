//
//  SpacingTests.swift
//  LightRoll_CleanerFeatureTests
//
//  スペーシングシステムのテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - Spacing Scale Tests

@Suite("Spacing Scale Tests")
struct SpacingScaleTests {

    // MARK: - Base Spacing Value Tests

    @Test("xxsが2ptである")
    func testXXS() {
        #expect(LRSpacing.xxs == 2)
    }

    @Test("xsが4ptである")
    func testXS() {
        #expect(LRSpacing.xs == 4)
    }

    @Test("smが8ptである")
    func testSM() {
        #expect(LRSpacing.sm == 8)
    }

    @Test("mdが12ptである")
    func testMD() {
        #expect(LRSpacing.md == 12)
    }

    @Test("lgが16ptである")
    func testLG() {
        #expect(LRSpacing.lg == 16)
    }

    @Test("xlが24ptである")
    func testXL() {
        #expect(LRSpacing.xl == 24)
    }

    @Test("xxlが32ptである")
    func testXXL() {
        #expect(LRSpacing.xxl == 32)
    }

    @Test("xxxlが40ptである")
    func testXXXL() {
        #expect(LRSpacing.xxxl == 40)
    }

    // MARK: - Spacing Scale Progression Tests

    @Test("スペーシングスケールが昇順である")
    func testSpacingScaleProgression() {
        #expect(LRSpacing.xxs < LRSpacing.xs)
        #expect(LRSpacing.xs < LRSpacing.sm)
        #expect(LRSpacing.sm < LRSpacing.md)
        #expect(LRSpacing.md < LRSpacing.lg)
        #expect(LRSpacing.lg < LRSpacing.xl)
        #expect(LRSpacing.xl < LRSpacing.xxl)
        #expect(LRSpacing.xxl < LRSpacing.xxxl)
    }

    @Test("スペーシングが8ptグリッドに基づいている")
    func testSpacingGridAlignment() {
        // sm, lg, xxl は8の倍数
        #expect(LRSpacing.sm.truncatingRemainder(dividingBy: 8) == 0)
        #expect(LRSpacing.lg.truncatingRemainder(dividingBy: 8) == 0)
        #expect(LRSpacing.xxl.truncatingRemainder(dividingBy: 8) == 0)
        #expect(LRSpacing.xxxl.truncatingRemainder(dividingBy: 8) == 0)
    }
}

// MARK: - Semantic Spacing Tests

@Suite("Semantic Spacing Tests")
struct SemanticSpacingTests {

    @Test("componentPaddingが16ptである")
    func testComponentPadding() {
        #expect(LRSpacing.componentPadding == 16)
    }

    @Test("cardPaddingが16ptである")
    func testCardPadding() {
        #expect(LRSpacing.cardPadding == 16)
    }

    @Test("sectionItemSpacingが12ptである")
    func testSectionItemSpacing() {
        #expect(LRSpacing.sectionItemSpacing == 12)
    }

    @Test("sectionSpacingが24ptである")
    func testSectionSpacing() {
        #expect(LRSpacing.sectionSpacing == 24)
    }

    @Test("listItemSpacingが8ptである")
    func testListItemSpacing() {
        #expect(LRSpacing.listItemSpacing == 8)
    }

    @Test("gridSpacingが2ptである")
    func testGridSpacing() {
        #expect(LRSpacing.gridSpacing == 2)
    }

    @Test("buttonPaddingHが16ptである")
    func testButtonPaddingH() {
        #expect(LRSpacing.buttonPaddingH == 16)
    }

    @Test("buttonPaddingVが12ptである")
    func testButtonPaddingV() {
        #expect(LRSpacing.buttonPaddingV == 12)
    }

    @Test("navigationBarHeightが44ptである")
    func testNavigationBarHeight() {
        #expect(LRSpacing.navigationBarHeight == 44)
    }

    @Test("tabBarHeightが49ptである")
    func testTabBarHeight() {
        #expect(LRSpacing.tabBarHeight == 49)
    }
}

// MARK: - Layout Metrics Corner Radius Tests

@Suite("Corner Radius Tests")
struct CornerRadiusTests {

    @Test("cornerRadiusXSが4ptである")
    func testCornerRadiusXS() {
        #expect(LRLayout.cornerRadiusXS == 4)
    }

    @Test("cornerRadiusSMが8ptである")
    func testCornerRadiusSM() {
        #expect(LRLayout.cornerRadiusSM == 8)
    }

    @Test("cornerRadiusMDが12ptである")
    func testCornerRadiusMD() {
        #expect(LRLayout.cornerRadiusMD == 12)
    }

    @Test("cornerRadiusLGが16ptである")
    func testCornerRadiusLG() {
        #expect(LRLayout.cornerRadiusLG == 16)
    }

    @Test("cornerRadiusXLが20ptである")
    func testCornerRadiusXL() {
        #expect(LRLayout.cornerRadiusXL == 20)
    }

    @Test("cornerRadiusXXLが24ptである")
    func testCornerRadiusXXL() {
        #expect(LRLayout.cornerRadiusXXL == 24)
    }

    @Test("角丸スケールが昇順である")
    func testCornerRadiusProgression() {
        #expect(LRLayout.cornerRadiusXS < LRLayout.cornerRadiusSM)
        #expect(LRLayout.cornerRadiusSM < LRLayout.cornerRadiusMD)
        #expect(LRLayout.cornerRadiusMD < LRLayout.cornerRadiusLG)
        #expect(LRLayout.cornerRadiusLG < LRLayout.cornerRadiusXL)
        #expect(LRLayout.cornerRadiusXL < LRLayout.cornerRadiusXXL)
    }
}

// MARK: - Layout Metrics Icon Size Tests

@Suite("Icon Size Tests")
struct IconSizeTests {

    @Test("iconSizeXSが12ptである")
    func testIconSizeXS() {
        #expect(LRLayout.iconSizeXS == 12)
    }

    @Test("iconSizeSMが16ptである")
    func testIconSizeSM() {
        #expect(LRLayout.iconSizeSM == 16)
    }

    @Test("iconSizeMDが20ptである")
    func testIconSizeMD() {
        #expect(LRLayout.iconSizeMD == 20)
    }

    @Test("iconSizeLGが24ptである")
    func testIconSizeLG() {
        #expect(LRLayout.iconSizeLG == 24)
    }

    @Test("iconSizeXLが32ptである")
    func testIconSizeXL() {
        #expect(LRLayout.iconSizeXL == 32)
    }

    @Test("iconSizeXXLが48ptである")
    func testIconSizeXXL() {
        #expect(LRLayout.iconSizeXXL == 48)
    }

    @Test("iconSizeHugeが64ptである")
    func testIconSizeHuge() {
        #expect(LRLayout.iconSizeHuge == 64)
    }

    @Test("アイコンサイズスケールが昇順である")
    func testIconSizeProgression() {
        #expect(LRLayout.iconSizeXS < LRLayout.iconSizeSM)
        #expect(LRLayout.iconSizeSM < LRLayout.iconSizeMD)
        #expect(LRLayout.iconSizeMD < LRLayout.iconSizeLG)
        #expect(LRLayout.iconSizeLG < LRLayout.iconSizeXL)
        #expect(LRLayout.iconSizeXL < LRLayout.iconSizeXXL)
        #expect(LRLayout.iconSizeXXL < LRLayout.iconSizeHuge)
    }
}

// MARK: - Layout Metrics Button Height Tests

@Suite("Button Height Tests")
struct ButtonHeightTests {

    @Test("buttonHeightSMが32ptである")
    func testButtonHeightSM() {
        #expect(LRLayout.buttonHeightSM == 32)
    }

    @Test("buttonHeightMDが44ptである（タッチターゲット最小サイズ）")
    func testButtonHeightMD() {
        #expect(LRLayout.buttonHeightMD == 44)
        #expect(LRLayout.buttonHeightMD >= LRLayout.minTouchTarget)
    }

    @Test("buttonHeightLGが56ptである")
    func testButtonHeightLG() {
        #expect(LRLayout.buttonHeightLG == 56)
    }

    @Test("ボタン高さスケールが昇順である")
    func testButtonHeightProgression() {
        #expect(LRLayout.buttonHeightSM < LRLayout.buttonHeightMD)
        #expect(LRLayout.buttonHeightMD < LRLayout.buttonHeightLG)
    }
}

// MARK: - Layout Metrics Border Width Tests

@Suite("Border Width Tests")
struct BorderWidthTests {

    @Test("borderWidthHairlineが0.5ptである")
    func testBorderWidthHairline() {
        #expect(LRLayout.borderWidthHairline == 0.5)
    }

    @Test("borderWidthThinが1ptである")
    func testBorderWidthThin() {
        #expect(LRLayout.borderWidthThin == 1)
    }

    @Test("borderWidthMediumが2ptである")
    func testBorderWidthMedium() {
        #expect(LRLayout.borderWidthMedium == 2)
    }

    @Test("borderWidthThickが3ptである")
    func testBorderWidthThick() {
        #expect(LRLayout.borderWidthThick == 3)
    }
}

// MARK: - Layout Metrics Thumbnail Tests

@Suite("Thumbnail Size Tests")
struct ThumbnailSizeTests {

    @Test("thumbnailSizeSMが60ptである")
    func testThumbnailSizeSM() {
        #expect(LRLayout.thumbnailSizeSM == 60)
    }

    @Test("thumbnailSizeMDが80ptである")
    func testThumbnailSizeMD() {
        #expect(LRLayout.thumbnailSizeMD == 80)
    }

    @Test("thumbnailSizeLGが120ptである")
    func testThumbnailSizeLG() {
        #expect(LRLayout.thumbnailSizeLG == 120)
    }
}

// MARK: - Layout Metrics Grid Tests

@Suite("Grid Configuration Tests")
struct GridConfigurationTests {

    @Test("photoGridColumnsPhoneが3である")
    func testPhotoGridColumnsPhone() {
        #expect(LRLayout.photoGridColumnsPhone == 3)
    }

    @Test("photoGridColumnsPadが5である")
    func testPhotoGridColumnsPad() {
        #expect(LRLayout.photoGridColumnsPad == 5)
    }

    @Test("minTouchTargetが44ptである（Apple HIG準拠）")
    func testMinTouchTarget() {
        #expect(LRLayout.minTouchTarget == 44)
    }
}

// MARK: - EdgeInsets Tests

@Suite("EdgeInsets LightRoll Tests")
struct EdgeInsetsLightRollTests {

    @Test("horizontal EdgeInsetsが正しく生成される")
    func testHorizontalEdgeInsets() {
        let insets = EdgeInsets.LightRoll.horizontal(16)
        #expect(insets.leading == 16)
        #expect(insets.trailing == 16)
        #expect(insets.top == 0)
        #expect(insets.bottom == 0)
    }

    @Test("vertical EdgeInsetsが正しく生成される")
    func testVerticalEdgeInsets() {
        let insets = EdgeInsets.LightRoll.vertical(12)
        #expect(insets.top == 12)
        #expect(insets.bottom == 12)
        #expect(insets.leading == 0)
        #expect(insets.trailing == 0)
    }

    @Test("all EdgeInsetsが正しく生成される")
    func testAllEdgeInsets() {
        let insets = EdgeInsets.LightRoll.all(8)
        #expect(insets.top == 8)
        #expect(insets.bottom == 8)
        #expect(insets.leading == 8)
        #expect(insets.trailing == 8)
    }

    @Test("custom EdgeInsetsが正しく生成される")
    func testCustomEdgeInsets() {
        let insets = EdgeInsets.LightRoll.custom(horizontal: 16, vertical: 8)
        #expect(insets.leading == 16)
        #expect(insets.trailing == 16)
        #expect(insets.top == 8)
        #expect(insets.bottom == 8)
    }

    @Test("preset componentが正しい値を持つ")
    func testPresetComponent() {
        let insets = EdgeInsets.LightRoll.component
        #expect(insets.top == LRSpacing.componentPadding)
        #expect(insets.bottom == LRSpacing.componentPadding)
        #expect(insets.leading == LRSpacing.componentPadding)
        #expect(insets.trailing == LRSpacing.componentPadding)
    }

    @Test("preset cardが正しい値を持つ")
    func testPresetCard() {
        let insets = EdgeInsets.LightRoll.card
        #expect(insets.top == LRSpacing.cardPadding)
        #expect(insets.bottom == LRSpacing.cardPadding)
        #expect(insets.leading == LRSpacing.cardPadding)
        #expect(insets.trailing == LRSpacing.cardPadding)
    }

    @Test("preset buttonが正しい値を持つ")
    func testPresetButton() {
        let insets = EdgeInsets.LightRoll.button
        #expect(insets.leading == LRSpacing.buttonPaddingH)
        #expect(insets.trailing == LRSpacing.buttonPaddingH)
        #expect(insets.top == LRSpacing.buttonPaddingV)
        #expect(insets.bottom == LRSpacing.buttonPaddingV)
    }
}

// MARK: - View Extension Tests

@Suite("Spacing View Extension Tests")
@MainActor
struct SpacingViewExtensionTests {

    @Test("lightRollPaddingがViewに適用可能")
    func testLightRollPaddingApplicable() {
        let view = Text("Test").lightRollPadding(LRSpacing.md)
        #expect(view != nil)
    }

    @Test("lightRollHorizontalPaddingがViewに適用可能")
    func testLightRollHorizontalPaddingApplicable() {
        let view = Text("Test").lightRollHorizontalPadding()
        #expect(view != nil)
    }

    @Test("lightRollVerticalPaddingがViewに適用可能")
    func testLightRollVerticalPaddingApplicable() {
        let view = Text("Test").lightRollVerticalPadding()
        #expect(view != nil)
    }

    @Test("componentPaddingがViewに適用可能")
    func testComponentPaddingApplicable() {
        let view = Text("Test").componentPadding()
        #expect(view != nil)
    }

    @Test("cardPaddingがViewに適用可能")
    func testCardPaddingApplicable() {
        let view = Text("Test").cardPadding()
        #expect(view != nil)
    }

    @Test("sectionSpacingがViewに適用可能")
    func testSectionSpacingApplicable() {
        let view = Text("Test").sectionSpacing()
        #expect(view != nil)
    }

    @Test("lightRollCornerRadiusがViewに適用可能")
    func testLightRollCornerRadiusApplicable() {
        let view = Text("Test").lightRollCornerRadius()
        #expect(view != nil)
    }

    @Test("ensureMinTouchTargetがViewに適用可能")
    func testEnsureMinTouchTargetApplicable() {
        let view = Text("Test").ensureMinTouchTarget()
        #expect(view != nil)
    }
}

// MARK: - Type Alias Tests

@Suite("Type Alias Tests")
struct TypeAliasTests {

    @Test("LRSpacingがCGFloat.LightRoll.Spacingのエイリアスである")
    func testLRSpacingAlias() {
        #expect(LRSpacing.lg == CGFloat.LightRoll.Spacing.lg)
        #expect(LRSpacing.md == CGFloat.LightRoll.Spacing.md)
    }

    @Test("LRLayoutがCGFloat.LightRoll.LayoutMetricsのエイリアスである")
    func testLRLayoutAlias() {
        #expect(LRLayout.cornerRadiusLG == CGFloat.LightRoll.LayoutMetrics.cornerRadiusLG)
        #expect(LRLayout.iconSizeLG == CGFloat.LightRoll.LayoutMetrics.iconSizeLG)
    }
}

// MARK: - Integration Tests

@Suite("Spacing Integration Tests")
@MainActor
struct SpacingIntegrationTests {

    @Test("SpacingがTypographyシステムと連携する")
    func testSpacingWithTypography() {
        // スペーシングとタイポグラフィが同時に利用可能であることを確認
        let spacing = LRSpacing.lg
        let font = Font.LightRoll.body

        #expect(spacing > 0)
        #expect(font != nil)
    }

    @Test("SpacingがColorシステムと連携する")
    func testSpacingWithColors() {
        // スペーシングとカラーが同時に利用可能であることを確認
        let padding = LRSpacing.componentPadding
        let backgroundColor = Color.LightRoll.background

        #expect(padding == 16)
        #expect(backgroundColor != nil)
    }

    @Test("全てのView extensionがチェーン可能")
    func testViewExtensionChaining() {
        let view = Text("Test")
            .lightRollPadding(LRSpacing.sm)
            .lightRollHorizontalPadding(LRSpacing.md)
            .lightRollCornerRadius(LRLayout.cornerRadiusMD)
            .ensureMinTouchTarget()

        #expect(view != nil)
    }
}
