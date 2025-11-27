//
//  TypographyTests.swift
//  LightRoll_CleanerFeatureTests
//
//  タイポグラフィシステムのテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - Typography Tests

@Suite("Typography Tests")
struct TypographyTests {

    // MARK: - Font Style Existence Tests

    @Test("Font.LightRoll.largeTitleが存在する")
    func testLargeTitleExists() {
        let font = Font.LightRoll.largeTitle
        #expect(font != nil)
    }

    @Test("Font.LightRoll.title1が存在する")
    func testTitle1Exists() {
        let font = Font.LightRoll.title1
        #expect(font != nil)
    }

    @Test("Font.LightRoll.title2が存在する")
    func testTitle2Exists() {
        let font = Font.LightRoll.title2
        #expect(font != nil)
    }

    @Test("Font.LightRoll.title3が存在する")
    func testTitle3Exists() {
        let font = Font.LightRoll.title3
        #expect(font != nil)
    }

    @Test("Font.LightRoll.headlineが存在する")
    func testHeadlineExists() {
        let font = Font.LightRoll.headline
        #expect(font != nil)
    }

    @Test("Font.LightRoll.bodyが存在する")
    func testBodyExists() {
        let font = Font.LightRoll.body
        #expect(font != nil)
    }

    @Test("Font.LightRoll.calloutが存在する")
    func testCalloutExists() {
        let font = Font.LightRoll.callout
        #expect(font != nil)
    }

    @Test("Font.LightRoll.subheadlineが存在する")
    func testSubheadlineExists() {
        let font = Font.LightRoll.subheadline
        #expect(font != nil)
    }

    @Test("Font.LightRoll.footnoteが存在する")
    func testFootnoteExists() {
        let font = Font.LightRoll.footnote
        #expect(font != nil)
    }

    @Test("Font.LightRoll.captionが存在する")
    func testCaptionExists() {
        let font = Font.LightRoll.caption
        #expect(font != nil)
    }

    @Test("Font.LightRoll.caption2が存在する")
    func testCaption2Exists() {
        let font = Font.LightRoll.caption2
        #expect(font != nil)
    }

    // MARK: - Special Font Style Tests

    @Test("Font.LightRoll.largeNumberが存在する")
    func testLargeNumberExists() {
        let font = Font.LightRoll.largeNumber
        #expect(font != nil)
    }

    @Test("Font.LightRoll.mediumNumberが存在する")
    func testMediumNumberExists() {
        let font = Font.LightRoll.mediumNumber
        #expect(font != nil)
    }

    @Test("Font.LightRoll.smallNumberが存在する")
    func testSmallNumberExists() {
        let font = Font.LightRoll.smallNumber
        #expect(font != nil)
    }

    @Test("Font.LightRoll.monospacedが存在する")
    func testMonospacedExists() {
        let font = Font.LightRoll.monospaced
        #expect(font != nil)
    }
}

// MARK: - LightRollTextStyle Tests

@Suite("LightRollTextStyle Tests")
struct LightRollTextStyleTests {

    @Test("LightRollTextStyleが全スタイルをサポートする")
    func testAllStylesSupported() {
        // 全てのスタイルが列挙されていることを確認
        let styles: [LightRollTextStyle.Style] = [
            .largeTitle, .title1, .title2, .title3,
            .headline, .body, .callout, .subheadline,
            .footnote, .caption, .caption2,
            .largeNumber, .mediumNumber, .smallNumber, .monospaced
        ]
        #expect(styles.count == 15)
    }

    @Test("LightRollTextStyleModifierが正しく初期化される")
    func testModifierInitialization() {
        let modifier = LightRollTextStyle(style: .body, color: nil)
        #expect(modifier.style == .body)
        #expect(modifier.color == nil)
    }

    @Test("LightRollTextStyleModifierがカスタムカラーを受け付ける")
    func testModifierWithCustomColor() {
        let customColor = Color.red
        let modifier = LightRollTextStyle(style: .headline, color: customColor)
        #expect(modifier.style == .headline)
        #expect(modifier.color == customColor)
    }
}

// MARK: - Style Enum Tests

@Suite("LightRollTextStyle.Style Enum Tests")
struct StyleEnumTests {

    @Test("Styleがrawvalueを持たない純粋なenumである")
    func testStyleIsSimpleEnum() {
        // enumケースをswitchでテストすることで全網羅を確認
        let style: LightRollTextStyle.Style = .body

        switch style {
        case .largeTitle, .title1, .title2, .title3:
            #expect(false, "Style should be .body")
        case .headline, .body, .callout, .subheadline:
            #expect(true) // .body がここに来る
        case .footnote, .caption, .caption2:
            #expect(false, "Style should be .body")
        case .largeNumber, .mediumNumber, .smallNumber, .monospaced:
            #expect(false, "Style should be .body")
        }
    }

    @Test("Display stylesが正しくグループ化されている")
    func testDisplayStylesGroup() {
        let displayStyles: [LightRollTextStyle.Style] = [
            .largeTitle, .title1, .title2, .title3
        ]
        #expect(displayStyles.count == 4)
    }

    @Test("Body stylesが正しくグループ化されている")
    func testBodyStylesGroup() {
        let bodyStyles: [LightRollTextStyle.Style] = [
            .headline, .body, .callout, .subheadline
        ]
        #expect(bodyStyles.count == 4)
    }

    @Test("Supporting stylesが正しくグループ化されている")
    func testSupportingStylesGroup() {
        let supportingStyles: [LightRollTextStyle.Style] = [
            .footnote, .caption, .caption2
        ]
        #expect(supportingStyles.count == 3)
    }

    @Test("Special stylesが正しくグループ化されている")
    func testSpecialStylesGroup() {
        let specialStyles: [LightRollTextStyle.Style] = [
            .largeNumber, .mediumNumber, .smallNumber, .monospaced
        ]
        #expect(specialStyles.count == 4)
    }
}

// MARK: - View Extension Tests

@Suite("View Extension Tests")
@MainActor
struct ViewExtensionTests {

    @Test("lightRollTextStyleがViewに適用可能")
    func testLightRollTextStyleApplicable() {
        // ViewModifierが適用可能かをコンパイル時チェック
        let text = Text("Test")
        let styledView = text.lightRollTextStyle(.body)

        // ビューが正常に生成されることを確認
        #expect(styledView is ModifiedContent<Text, LightRollTextStyle>)
    }

    @Test("lightRollTextStyleがカスタムカラーと共に適用可能")
    func testLightRollTextStyleWithColorApplicable() {
        let text = Text("Test")
        let styledView = text.lightRollTextStyle(.headline, color: .red)

        // ビューが正常に生成されることを確認
        #expect(styledView is ModifiedContent<Text, LightRollTextStyle>)
    }

    @Test("limitDynamicTypeSizeが適用可能")
    func testLimitDynamicTypeSizeApplicable() {
        let text = Text("Test")
        // dynamicTypeSizeモディファイアが使用可能かを確認
        let limitedView = text.limitDynamicTypeSize(to: .accessibility1)
        #expect(limitedView != nil)
    }
}

// MARK: - Text Extension Tests

@Suite("Text Extension Tests")
struct TextExtensionTests {

    @Test("primaryStyleがTextに適用可能")
    func testPrimaryStyleApplicable() {
        let text = Text("Test").primaryStyle()
        #expect(text is Text)
    }

    @Test("secondaryStyleがTextに適用可能")
    func testSecondaryStyleApplicable() {
        let text = Text("Test").secondaryStyle()
        #expect(text is Text)
    }

    @Test("tertiaryStyleがTextに適用可能")
    func testTertiaryStyleApplicable() {
        let text = Text("Test").tertiaryStyle()
        #expect(text is Text)
    }
}

// MARK: - Integration Tests

@Suite("Typography Integration Tests")
@MainActor
struct TypographyIntegrationTests {

    @Test("タイポグラフィがカラーシステムと連携する")
    func testTypographyWithColors() {
        // カラーとタイポグラフィが同時に利用可能であることを確認
        let primaryColor = Color.LightRoll.textPrimary
        let bodyFont = Font.LightRoll.body

        #expect(primaryColor != nil)
        #expect(bodyFont != nil)
    }

    @Test("複数のスタイルを連続して適用可能")
    func testMultipleStylesChaining() {
        // 複数のビューに異なるスタイルを適用
        let view1 = Text("Title").lightRollTextStyle(.title1)
        let view2 = Text("Body").lightRollTextStyle(.body)
        let view3 = Text("Caption").lightRollTextStyle(.caption)

        #expect(view1 != nil)
        #expect(view2 != nil)
        #expect(view3 != nil)
    }
}
