//
//  GlassMorphismTests.swift
//  LightRoll_CleanerFeatureTests
//
//  グラスモーフィズムシステムのテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - GlassStyle Tests

@Suite("GlassStyle Tests")
struct GlassStyleTests {

    @Test("GlassStyleが全5種類のスタイルを持つ")
    func testAllStylesExist() {
        let styles = GlassStyle.allCases
        #expect(styles.count == 5)
    }

    @Test("GlassStyle.ultraThinが存在する")
    func testUltraThinExists() {
        let style = GlassStyle.ultraThin
        #expect(style == .ultraThin)
    }

    @Test("GlassStyle.thinが存在する")
    func testThinExists() {
        let style = GlassStyle.thin
        #expect(style == .thin)
    }

    @Test("GlassStyle.regularが存在する")
    func testRegularExists() {
        let style = GlassStyle.regular
        #expect(style == .regular)
    }

    @Test("GlassStyle.thickが存在する")
    func testThickExists() {
        let style = GlassStyle.thick
        #expect(style == .thick)
    }

    @Test("GlassStyle.chromeが存在する")
    func testChromeExists() {
        let style = GlassStyle.chrome
        #expect(style == .chrome)
    }

    // MARK: - Border Opacity Tests

    @Test("borderOpacityがスタイルごとに異なる値を持つ")
    func testBorderOpacityValues() {
        #expect(GlassStyle.ultraThin.borderOpacity == 0.15)
        #expect(GlassStyle.thin.borderOpacity == 0.2)
        #expect(GlassStyle.regular.borderOpacity == 0.25)
        #expect(GlassStyle.thick.borderOpacity == 0.3)
        #expect(GlassStyle.chrome.borderOpacity == 0.35)
    }

    @Test("borderOpacityがultraThinからchromeへ増加する")
    func testBorderOpacityIncreases() {
        let ultraThin = GlassStyle.ultraThin.borderOpacity
        let thin = GlassStyle.thin.borderOpacity
        let regular = GlassStyle.regular.borderOpacity
        let thick = GlassStyle.thick.borderOpacity
        let chrome = GlassStyle.chrome.borderOpacity

        #expect(ultraThin < thin)
        #expect(thin < regular)
        #expect(regular < thick)
        #expect(thick < chrome)
    }

    // MARK: - Inner Glow Opacity Tests

    @Test("innerGlowOpacityがスタイルごとに異なる値を持つ")
    func testInnerGlowOpacityValues() {
        #expect(GlassStyle.ultraThin.innerGlowOpacity == 0.05)
        #expect(GlassStyle.thin.innerGlowOpacity == 0.08)
        #expect(GlassStyle.regular.innerGlowOpacity == 0.1)
        #expect(GlassStyle.thick.innerGlowOpacity == 0.12)
        #expect(GlassStyle.chrome.innerGlowOpacity == 0.15)
    }

    @Test("innerGlowOpacityがultraThinからchromeへ増加する")
    func testInnerGlowOpacityIncreases() {
        let ultraThin = GlassStyle.ultraThin.innerGlowOpacity
        let thin = GlassStyle.thin.innerGlowOpacity
        let regular = GlassStyle.regular.innerGlowOpacity
        let thick = GlassStyle.thick.innerGlowOpacity
        let chrome = GlassStyle.chrome.innerGlowOpacity

        #expect(ultraThin < thin)
        #expect(thin < regular)
        #expect(regular < thick)
        #expect(thick < chrome)
    }

    // MARK: - Shadow Radius Tests

    @Test("shadowRadiusがスタイルごとに異なる値を持つ")
    func testShadowRadiusValues() {
        #expect(GlassStyle.ultraThin.shadowRadius == 8)
        #expect(GlassStyle.thin.shadowRadius == 10)
        #expect(GlassStyle.regular.shadowRadius == 12)
        #expect(GlassStyle.thick.shadowRadius == 15)
        #expect(GlassStyle.chrome.shadowRadius == 20)
    }

    @Test("shadowRadiusがultraThinからchromeへ増加する")
    func testShadowRadiusIncreases() {
        let ultraThin = GlassStyle.ultraThin.shadowRadius
        let thin = GlassStyle.thin.shadowRadius
        let regular = GlassStyle.regular.shadowRadius
        let thick = GlassStyle.thick.shadowRadius
        let chrome = GlassStyle.chrome.shadowRadius

        #expect(ultraThin < thin)
        #expect(thin < regular)
        #expect(regular < thick)
        #expect(thick < chrome)
    }

    // MARK: - Shadow Opacity Tests

    @Test("shadowOpacityがスタイルごとに異なる値を持つ")
    func testShadowOpacityValues() {
        #expect(GlassStyle.ultraThin.shadowOpacity == 0.1)
        #expect(GlassStyle.thin.shadowOpacity == 0.15)
        #expect(GlassStyle.regular.shadowOpacity == 0.2)
        #expect(GlassStyle.thick.shadowOpacity == 0.25)
        #expect(GlassStyle.chrome.shadowOpacity == 0.3)
    }

    @Test("shadowOpacityがultraThinからchromeへ増加する")
    func testShadowOpacityIncreases() {
        let ultraThin = GlassStyle.ultraThin.shadowOpacity
        let thin = GlassStyle.thin.shadowOpacity
        let regular = GlassStyle.regular.shadowOpacity
        let thick = GlassStyle.thick.shadowOpacity
        let chrome = GlassStyle.chrome.shadowOpacity

        #expect(ultraThin < thin)
        #expect(thin < regular)
        #expect(regular < thick)
        #expect(thick < chrome)
    }

    // MARK: - Sendable Conformance

    @Test("GlassStyleがSendableに準拠している")
    func testSendableConformance() {
        let style: GlassStyle = .regular
        // Sendable準拠の確認（コンパイル時チェック）
        Task {
            let _ = style
        }
        #expect(true)
    }
}

// MARK: - GlassShape Tests

@Suite("GlassShape Tests")
struct GlassShapeTests {

    @Test("GlassShape.roundedRectangleが角丸パラメータを持つ")
    func testRoundedRectangleWithCornerRadius() {
        let shape = GlassShape.roundedRectangle(cornerRadius: 16)
        #expect(shape.cornerRadius == 16)
    }

    @Test("GlassShape.capsuleが存在する")
    func testCapsuleExists() {
        let shape = GlassShape.capsule
        #expect(shape.cornerRadius == nil)
    }

    @Test("GlassShape.circleが存在する")
    func testCircleExists() {
        let shape = GlassShape.circle
        #expect(shape.cornerRadius == nil)
    }

    @Test("GlassShape.continuousRoundedRectangleが角丸パラメータを持つ")
    func testContinuousRoundedRectangleWithCornerRadius() {
        let shape = GlassShape.continuousRoundedRectangle(cornerRadius: 20)
        #expect(shape.cornerRadius == 20)
    }

    @Test("GlassShapeがSendableに準拠している")
    func testSendableConformance() {
        let shape: GlassShape = .roundedRectangle(cornerRadius: 12)
        Task {
            let _ = shape
        }
        #expect(Bool(true))
    }
}

// MARK: - GlassModifier Tests

@Suite("GlassModifier Tests")
@MainActor
struct GlassModifierTests {

    @Test("GlassModifierがデフォルト値で初期化される")
    func testDefaultInitialization() {
        let modifier = GlassModifier()
        #expect(modifier.style == .regular)
        #expect(modifier.showBorder == true)
        #expect(modifier.showShadow == true)
        #expect(modifier.showInnerGlow == true)
    }

    @Test("GlassModifierがカスタム値で初期化される")
    func testCustomInitialization() {
        let modifier = GlassModifier(
            style: .thick,
            shape: .capsule,
            showBorder: false,
            showShadow: false,
            showInnerGlow: false
        )
        #expect(modifier.style == .thick)
        #expect(modifier.showBorder == false)
        #expect(modifier.showShadow == false)
        #expect(modifier.showInnerGlow == false)
    }

    @Test("GlassModifierが全てのスタイルで初期化可能")
    func testAllStylesInitializable() {
        for style in GlassStyle.allCases {
            let modifier = GlassModifier(style: style)
            #expect(modifier.style == style)
        }
    }
}

// MARK: - GlassCardView Tests

@Suite("GlassCardView Tests")
@MainActor
struct GlassCardViewTests {

    @Test("GlassCardViewがデフォルト値で初期化される")
    func testDefaultInitialization() {
        let card = GlassCardView {
            Text("Test")
        }
        #expect(card.style == .regular)
        #expect(card.cornerRadius == 20)
        #expect(card.padding == 16)
        #expect(card.showBorder == true)
        #expect(card.showShadow == true)
    }

    @Test("GlassCardViewがカスタム値で初期化される")
    func testCustomInitialization() {
        let card = GlassCardView(
            style: .chrome,
            cornerRadius: 12,
            padding: 24,
            showBorder: false,
            showShadow: false
        ) {
            Text("Test")
        }
        #expect(card.style == .chrome)
        #expect(card.cornerRadius == 12)
        #expect(card.padding == 24)
        #expect(card.showBorder == false)
        #expect(card.showShadow == false)
    }

    @Test("GlassCardViewが任意のコンテンツを受け付ける")
    func testAcceptsAnyContent() {
        // Textコンテンツ
        let textCard = GlassCardView { Text("Text") }
        _ = textCard

        // Imageコンテンツ
        let imageCard = GlassCardView {
            Image(systemName: "star")
        }
        _ = imageCard

        // 複合コンテンツ
        let complexCard = GlassCardView {
            VStack {
                Text("Title")
                Image(systemName: "photo")
                Text("Description")
            }
        }
        _ = complexCard

        // コンパイル時チェック - 全てのビューが正常に生成されることを確認
        #expect(Bool(true))
    }
}

// MARK: - GlassButtonStyle Tests

@Suite("GlassButtonStyle Tests")
@MainActor
struct GlassButtonStyleTests {

    @Test("GlassButtonStyleがデフォルト値で初期化される")
    func testDefaultInitialization() {
        let style = GlassButtonStyle()
        #expect(style.style == .thin)
        #expect(style.cornerRadius == 12)
    }

    @Test("GlassButtonStyleがカスタム値で初期化される")
    func testCustomInitialization() {
        let style = GlassButtonStyle(style: .chrome, cornerRadius: 20)
        #expect(style.style == .chrome)
        #expect(style.cornerRadius == 20)
    }

    @Test("ButtonStyle.glassが利用可能")
    func testStaticGlassMethod() {
        // ButtonStyle.glassはButtonに適用する形式で使用
        // Button().buttonStyle(.glass()) の形式でテスト
        let button = Button("Test") {}
            .buttonStyle(.glass(style: .regular, cornerRadius: 16))
        _ = button
        #expect(Bool(true))
    }
}

// MARK: - View Extension Tests

@Suite("Glass View Extension Tests")
@MainActor
struct GlassViewExtensionTests {

    @Test("glassBackgroundがViewに適用可能")
    func testGlassBackgroundApplicable() {
        let view = Text("Test")
            .glassBackground()
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("glassBackgroundがカスタムパラメータを受け付ける")
    func testGlassBackgroundWithParams() {
        let view = Text("Test")
            .glassBackground(
                style: .thick,
                shape: .capsule,
                showBorder: false,
                showShadow: true,
                showInnerGlow: false
            )
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("glassCardがViewに適用可能")
    func testGlassCardApplicable() {
        let view = Text("Test")
            .glassCard(cornerRadius: 16, style: .regular)
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("glassCapsuleがViewに適用可能")
    func testGlassCapsuleApplicable() {
        let view = Text("Test")
            .glassCapsule(style: .thin)
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("glassCircleがViewに適用可能")
    func testGlassCircleApplicable() {
        let view = Rectangle()
            .frame(width: 50, height: 50)
            .glassCircle(style: .regular)
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("adaptiveGlassがViewに適用可能")
    func testAdaptiveGlassApplicable() {
        let view = Text("Test")
            .adaptiveGlass(cornerRadius: 20, fallbackStyle: .regular)
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("glassButtonがViewに適用可能")
    func testGlassButtonApplicable() {
        let view = Text("Button")
            .padding()
            .glassButton(style: .thin, cornerRadius: 12)
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }
}

// MARK: - Integration Tests

@Suite("GlassMorphism Integration Tests")
@MainActor
struct GlassMorphismIntegrationTests {

    @Test("グラスモーフィズムのスタイルが正しく設定される")
    func testGlassStyleSetup() {
        // グラススタイルが正しく機能することを確認
        let glassStyle = GlassStyle.regular
        #expect(glassStyle == .regular)
        #expect(glassStyle.borderOpacity == 0.25)
    }

    @Test("グラスモーフィズムがタイポグラフィと連携する")
    func testIntegrationWithTypography() {
        // タイポグラフィとグラスカードが連携可能であることを確認
        let card = GlassCardView {
            Text("Title")
                .font(Font.LightRoll.headline)
        }
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = card
        #expect(Bool(true))
    }

    @Test("複数のグラス要素を組み合わせて使用可能")
    func testMultipleGlassElements() {
        let view = VStack {
            GlassCardView(style: .ultraThin) {
                Text("Card 1")
            }

            Text("Button")
                .padding()
                .glassCapsule(style: .thin)

            Circle()
                .frame(width: 50, height: 50)
                .glassCircle(style: .chrome)
        }
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }

    @Test("GlassButtonStyleがButtonに適用可能")
    func testButtonStyleApplicable() {
        let button = Button("Test") {}
            .buttonStyle(.glass(style: .regular))
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = button
        #expect(Bool(true))
    }

    @Test("ネストされたグラス要素が作成可能")
    func testNestedGlassElements() {
        let view = GlassCardView(style: .regular) {
            VStack {
                Text("Title")

                Button("Action") {}
                    .buttonStyle(.glass(style: .thin))
            }
        }
        // コンパイル時チェック - ビューが正常に生成されることを確認
        _ = view
        #expect(Bool(true))
    }
}

// MARK: - Style Consistency Tests

@Suite("Glass Style Consistency Tests")
@MainActor
struct GlassStyleConsistencyTests {

    @Test("全てのスタイルプロパティが0より大きい値を持つ")
    func testAllPropertiesPositive() {
        for style in GlassStyle.allCases {
            #expect(style.borderOpacity > 0)
            #expect(style.innerGlowOpacity > 0)
            #expect(style.shadowRadius > 0)
            #expect(style.shadowOpacity > 0)
        }
    }

    @Test("全てのスタイルプロパティが1以下の値を持つ（opacity）")
    func testOpacityWithinRange() {
        for style in GlassStyle.allCases {
            #expect(style.borderOpacity <= 1.0)
            #expect(style.innerGlowOpacity <= 1.0)
            #expect(style.shadowOpacity <= 1.0)
        }
    }

    @Test("スタイル間でプロパティ値の一貫性がある")
    func testStylePropertyConsistency() {
        // より強いスタイルはより大きな値を持つ
        let styles = GlassStyle.allCases

        // 各スタイルペアで値が増加していることを確認
        for i in 0..<(styles.count - 1) {
            let current = styles[i]
            let next = styles[i + 1]

            #expect(
                current.borderOpacity <= next.borderOpacity,
                "borderOpacity should increase from \(current) to \(next)"
            )
            #expect(
                current.innerGlowOpacity <= next.innerGlowOpacity,
                "innerGlowOpacity should increase from \(current) to \(next)"
            )
            #expect(
                current.shadowRadius <= next.shadowRadius,
                "shadowRadius should increase from \(current) to \(next)"
            )
            #expect(
                current.shadowOpacity <= next.shadowOpacity,
                "shadowOpacity should increase from \(current) to \(next)"
            )
        }
    }
}

// MARK: - Edge Case Tests

@Suite("Glass Edge Case Tests")
@MainActor
struct GlassEdgeCaseTests {

    @Test("角丸0のグラス背景が作成可能")
    func testZeroCornerRadius() {
        let view = Text("Test")
            .glassCard(cornerRadius: 0, style: .regular)
        _ = view
        #expect(Bool(true))
    }

    @Test("非常に大きな角丸のグラス背景が作成可能")
    func testLargeCornerRadius() {
        let view = Text("Test")
            .glassCard(cornerRadius: 1000, style: .regular)
        _ = view
        #expect(Bool(true))
    }

    @Test("全てのオプションを無効にしたグラス背景が作成可能")
    func testAllOptionsDisabled() {
        let view = Text("Test")
            .glassBackground(
                style: .regular,
                showBorder: false,
                showShadow: false,
                showInnerGlow: false
            )
        _ = view
        #expect(Bool(true))
    }

    @Test("GlassCardViewのpaddingが0でも作成可能")
    func testZeroPadding() {
        let card = GlassCardView(padding: 0) {
            Text("Test")
        }
        #expect(card.padding == 0)
    }

    @Test("空のコンテンツでもGlassCardViewが作成可能")
    func testEmptyContent() {
        let card = GlassCardView {
            EmptyView()
        }
        _ = card
        #expect(Bool(true))
    }
}
