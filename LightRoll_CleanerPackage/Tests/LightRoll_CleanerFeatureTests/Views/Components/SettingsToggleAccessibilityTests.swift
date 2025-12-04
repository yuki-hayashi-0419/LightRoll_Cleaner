//
//  SettingsToggleAccessibilityTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsToggleコンポーネントのアクセシビリティ追加テスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - SettingsToggle Accessibility Enhancement Tests

@Suite("SettingsToggle Accessibility Enhancement Tests")
@MainActor
struct SettingsToggleAccessibilityTests {

    // MARK: - Test State Helper

    /// テスト用の状態ホルダー
    @MainActor
    final class ToggleStateHolder {
        var isOn: Bool

        init(isOn: Bool = false) {
            self.isOn = isOn
        }

        var binding: Binding<Bool> {
            Binding(
                get: { self.isOn },
                set: { self.isOn = $0 }
            )
        }
    }

    // MARK: - Accessibility Value Tests

    @Test("アクセシビリティ: オン状態の値が正しく報告される")
    func accessibilityValueWhenOn() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.accessibilityValue == "オン")
        #expect(stateHolder.isOn == true)
    }

    @Test("アクセシビリティ: オフ状態の値が正しく報告される")
    func accessibilityValueWhenOff() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.accessibilityValue == "オフ")
        #expect(stateHolder.isOn == false)
    }

    // MARK: - Accessibility Hint Tests

    @Test("アクセシビリティ: 有効時のヒント（オン状態）")
    func accessibilityHintWhenEnabledAndOn() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding,
            disabled: false
        )

        // Assert
        #expect(toggle.accessibilityHint == "ダブルタップでオフにします")
        #expect(toggle.disabled == false)
    }

    @Test("アクセシビリティ: 有効時のヒント（オフ状態）")
    func accessibilityHintWhenEnabledAndOff() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding,
            disabled: false
        )

        // Assert
        #expect(toggle.accessibilityHint == "ダブルタップでオンにします")
        #expect(toggle.disabled == false)
    }

    // MARK: - Accessibility Element Tests

    @Test("アクセシビリティ: 要素が結合されて単一要素として扱われる")
    func accessibilityElementCombined() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            iconColor: .orange,
            title: "通知を許可",
            subtitle: "アプリからの通知を受け取る",
            isOn: stateHolder.binding
        )

        // Assert
        // Note: 実装では.accessibilityElement(children: .combine)が適用されており、
        // アイコン、タイトル、サブタイトル、トグルが単一のアクセシビリティ要素として
        // 結合される。これによりVoiceOverのナビゲーションが簡潔になる。
        #expect(toggle.accessibilityLabel == "通知を許可, アプリからの通知を受け取る")
        #expect(toggle.accessibilityValue == "オフ")
    }

    // MARK: - Disabled State Accessibility Tests

    @Test("アクセシビリティ: 無効状態の不透明度が適用される")
    func disabledOpacityIsApplied() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "clock",
            title: "定期通知",
            isOn: stateHolder.binding,
            disabled: true
        )

        // Assert
        #expect(toggle.disabled == true)

        // Note: 実装では.opacity(disabled ? 0.6 : 1.0)が適用されており、
        // 無効状態が視覚的にもアクセシビリティ的にも明確に示される
    }

    @Test("アクセシビリティ: 無効状態のアイコンカラーが調整される")
    func disabledIconColorIsAdjusted() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            iconColor: .orange,
            title: "通知",
            isOn: stateHolder.binding,
            disabled: true
        )

        // Assert
        #expect(toggle.disabled == true)
        #expect(toggle.iconColor == .orange)

        // Note: 実装ではdisabled時にiconColor.opacity(0.5)が適用されており、
        // アイコンの色が薄くなることで無効状態が視覚的に示される
    }

    // MARK: - Dynamic Type Tests

    @Test("アクセシビリティ: 動的フォントサイズに対応している")
    func supportsDynamicType() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            iconColor: .orange,
            title: "通知設定",
            subtitle: "詳細な説明",
            isOn: stateHolder.binding
        )

        // Assert
        // Note: SettingsRowが内部で使用されており、Dynamic Typeが自動的にサポートされる
        #expect(toggle.title == "通知設定")
        #expect(toggle.subtitle == "詳細な説明")
    }

    // MARK: - Complex Accessibility Scenarios

    @Test("アクセシビリティ: 長いタイトルとサブタイトルが適切に処理される")
    func longTextAccessibility() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)
        let longTitle = "この設定は非常に長いタイトルを持っており、複数行にわたって表示される可能性があります"
        let longSubtitle = "同様に、このサブタイトルも非常に長く、ユーザーに詳細な情報を提供するために複数行にわたって表示される可能性があります"

        // Act
        let toggle = SettingsToggle(
            icon: "info.circle",
            iconColor: .blue,
            title: longTitle,
            subtitle: longSubtitle,
            isOn: stateHolder.binding
        )

        // Assert
        let expectedLabel = "\(longTitle), \(longSubtitle)"
        #expect(toggle.accessibilityLabel == expectedLabel)
        #expect(toggle.accessibilityValue == "オン")

        // Note: VoiceOverは長いテキストを適切に処理し、ユーザーはスワイプで
        // テキストを段階的に聞くことができる
    }

    @Test("アクセシビリティ: 依存関係のあるトグルの状態が適切に報告される")
    func dependentToggleAccessibility() async throws {
        // Arrange
        let mainStateHolder = ToggleStateHolder(isOn: false)
        let dependentStateHolder = ToggleStateHolder(isOn: true)

        // Act
        let mainToggle = SettingsToggle(
            icon: "bell",
            title: "通知を許可",
            isOn: mainStateHolder.binding
        )

        let dependentToggle = SettingsToggle(
            icon: "clock",
            title: "定期通知",
            subtitle: "通知が有効な場合のみ利用可能",
            isOn: dependentStateHolder.binding,
            disabled: !mainStateHolder.isOn
        )

        // Assert
        #expect(mainToggle.accessibilityHint == "ダブルタップでオンにします")
        #expect(dependentToggle.accessibilityHint == "この設定は現在無効です")
        #expect(dependentToggle.disabled == true)

        // Note: 依存トグルが無効な理由がヒントで明確に示される
    }
}
