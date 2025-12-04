//
//  SettingsToggleTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsToggleコンポーネントのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - SettingsToggle Tests

@Suite("SettingsToggle Component Tests")
@MainActor
struct SettingsToggleTests {
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

    // MARK: - Initialization Tests

    @Test("初期化: デフォルト値で正しく初期化される")
    func initializationWithDefaults() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.icon == "bell")
        #expect(toggle.title == "通知")
        #expect(toggle.subtitle == nil)
        #expect(toggle.disabled == false)
        #expect(stateHolder.isOn == false)
    }

    @Test("初期化: カスタム値で正しく初期化される")
    func initializationWithCustomValues() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)

        // Act
        let toggle = SettingsToggle(
            icon: "moon",
            iconColor: .purple,
            title: "ダークモード",
            subtitle: "ダークモードを有効化",
            isOn: stateHolder.binding,
            disabled: true
        )

        // Assert
        #expect(toggle.icon == "moon")
        #expect(toggle.iconColor == .purple)
        #expect(toggle.title == "ダークモード")
        #expect(toggle.subtitle == "ダークモードを有効化")
        #expect(toggle.disabled == true)
        #expect(stateHolder.isOn == true)
    }

    // MARK: - State Tests

    @Test("状態: トグルがオンの状態で初期化される")
    func stateIsOnInitially() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(stateHolder.isOn == true)
    }

    @Test("状態: トグルがオフの状態で初期化される")
    func stateIsOffInitially() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(stateHolder.isOn == false)
    }

    @Test("状態: バインディングで状態が変更される")
    func stateChangedThroughBinding() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Act
        stateHolder.isOn = true

        // Assert
        #expect(stateHolder.isOn == true)
    }

    // MARK: - Disabled State Tests

    @Test("無効化: 無効状態で正しく初期化される")
    func disabledStateIsSet() async throws {
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
    }

    @Test("無効化: 有効状態で正しく初期化される")
    func enabledStateIsSet() async throws {
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
        #expect(toggle.disabled == false)
    }

    // MARK: - OnChange Callback Tests

    @Test("コールバック: onChange が設定される")
    func onChangeCallbackIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        var callbackCalled = false
        var callbackValue: Bool?

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding,
            onChange: { newValue in
                callbackCalled = true
                callbackValue = newValue
            }
        )

        // バインディング経由で状態変更
        stateHolder.isOn = true

        // Assert
        // Note: onChangeコールバックは実際のView階層で発火するため、
        // ここではコールバックが設定されていることのみ検証
        #expect(toggle.onChange != nil)
    }

    // MARK: - Icon Tests

    @Test("アイコン: 正しいアイコン名が設定される")
    func iconNameIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let icons = ["bell", "moon", "photo", "clock", "lock"]

        for iconName in icons {
            // Act
            let toggle = SettingsToggle(
                icon: iconName,
                title: "テスト",
                isOn: stateHolder.binding
            )

            // Assert
            #expect(toggle.icon == iconName)
        }
    }

    @Test("アイコン: 正しいアイコンカラーが設定される")
    func iconColorIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let colors: [Color] = [.orange, .blue, .red, .purple, .green]

        for color in colors {
            // Act
            let toggle = SettingsToggle(
                icon: "bell",
                iconColor: color,
                title: "テスト",
                isOn: stateHolder.binding
            )

            // Assert
            #expect(toggle.iconColor == color)
        }
    }

    @Test("アイコン: デフォルトアイコンカラーが設定される")
    func defaultIconColorIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "テスト",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.iconColor == .gray)
    }

    // MARK: - Text Tests

    @Test("テキスト: タイトルが正しく設定される")
    func titleIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let titles = ["通知を許可", "自動スキャン", "動画を含める", "ダークモード"]

        for title in titles {
            // Act
            let toggle = SettingsToggle(
                icon: "gear",
                title: title,
                isOn: stateHolder.binding
            )

            // Assert
            #expect(toggle.title == title)
        }
    }

    @Test("テキスト: サブタイトルが正しく設定される")
    func subtitleIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let subtitle = "アプリからの通知を受け取る"

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            subtitle: subtitle,
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.subtitle == subtitle)
    }

    @Test("テキスト: サブタイトルなしで正しく初期化される")
    func noSubtitleIsSet() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.subtitle == nil)
    }

    // MARK: - Accessibility Tests

    @Test("アクセシビリティ: ラベルが正しく生成される（サブタイトルあり）")
    func accessibilityLabelWithSubtitle() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知を許可",
            subtitle: "アプリからの通知を受け取る",
            isOn: stateHolder.binding
        )

        // Act & Assert
        let expectedLabel = "通知を許可, アプリからの通知を受け取る"
        #expect(toggle.accessibilityLabel == expectedLabel)
    }

    @Test("アクセシビリティ: ラベルが正しく生成される（サブタイトルなし）")
    func accessibilityLabelWithoutSubtitle() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let toggle = SettingsToggle(
            icon: "bell",
            title: "通知を許可",
            isOn: stateHolder.binding
        )

        // Act & Assert
        #expect(toggle.accessibilityLabel == "通知を許可")
    }

    @Test("アクセシビリティ: 無効時のヒントが正しく生成される")
    func accessibilityHintWhenDisabled() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let toggle = SettingsToggle(
            icon: "clock",
            title: "定期通知",
            isOn: stateHolder.binding,
            disabled: true
        )

        // Act & Assert
        #expect(toggle.accessibilityHint == "この設定は現在無効です")
    }

    // MARK: - Edge Cases

    @Test("エッジケース: 長いタイトルでも正しく初期化される")
    func edgeCaseLongTitle() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let longTitle = String(repeating: "長いタイトル", count: 10)

        // Act
        let toggle = SettingsToggle(
            icon: "text.alignleft",
            title: longTitle,
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.title == longTitle)
    }

    @Test("エッジケース: 長いサブタイトルでも正しく初期化される")
    func edgeCaseLongSubtitle() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)
        let longSubtitle = String(repeating: "長いサブタイトル", count: 10)

        // Act
        let toggle = SettingsToggle(
            icon: "text.alignleft",
            title: "タイトル",
            subtitle: longSubtitle,
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.subtitle == longSubtitle)
    }

    @Test("エッジケース: 空のタイトルでも初期化できる")
    func edgeCaseEmptyTitle() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: false)

        // Act
        let toggle = SettingsToggle(
            icon: "questionmark",
            title: "",
            isOn: stateHolder.binding
        )

        // Assert
        #expect(toggle.title == "")
    }

    // MARK: - Complex Scenarios

    @Test("複雑なシナリオ: 完全な設定でトグルを作成")
    func complexScenarioFullConfiguration() async throws {
        // Arrange
        let stateHolder = ToggleStateHolder(isOn: true)
        var changeCount = 0

        // Act
        let toggle = SettingsToggle(
            icon: "bell.badge",
            iconColor: .orange,
            title: "重要な通知",
            subtitle: "緊急のお知らせを受け取る",
            isOn: stateHolder.binding,
            disabled: false,
            onChange: { _ in changeCount += 1 }
        )

        // Assert
        #expect(toggle.icon == "bell.badge")
        #expect(toggle.iconColor == .orange)
        #expect(toggle.title == "重要な通知")
        #expect(toggle.subtitle == "緊急のお知らせを受け取る")
        #expect(toggle.disabled == false)
        #expect(stateHolder.isOn == true)
    }

    @Test("複雑なシナリオ: 無効化された依存トグル")
    func complexScenarioDependentDisabledToggle() async throws {
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
        #expect(mainToggle.disabled == false)
        #expect(dependentToggle.disabled == true)
        #expect(dependentStateHolder.isOn == true)
    }
}
