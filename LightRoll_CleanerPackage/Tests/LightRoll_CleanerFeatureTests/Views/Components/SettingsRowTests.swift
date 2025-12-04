//
//  SettingsRowTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SettingsRowコンポーネントのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - SettingsRow Tests

@Suite("SettingsRow Component Tests")
@MainActor
struct SettingsRowTests {
    // MARK: - Initialization Tests

    @Test("初期化: アクセサリコンテンツなしで正しく初期化される")
    func initializationWithoutAccessory() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "bell",
            iconColor: .orange,
            title: "通知",
            subtitle: "通知設定を管理",
            showChevron: false
        )

        // Assert
        #expect(row.icon == "bell")
        #expect(row.iconColor == .orange)
        #expect(row.title == "通知")
        #expect(row.subtitle == "通知設定を管理")
        #expect(row.showChevron == false)
    }

    @Test("初期化: アクセサリコンテンツ付きで正しく初期化される")
    func initializationWithAccessory() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "moon",
            iconColor: .purple,
            title: "ダークモード"
        ) {
            Text("アクセサリ")
        }

        // Assert
        #expect(row.icon == "moon")
        #expect(row.iconColor == .purple)
        #expect(row.title == "ダークモード")
        #expect(row.subtitle == nil)
    }

    @Test("初期化: デフォルトアイコンカラーで正しく初期化される")
    func initializationWithDefaultIconColor() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "gear",
            title: "設定"
        )

        // Assert
        #expect(row.icon == "gear")
        #expect(row.iconColor == .gray)
    }

    // MARK: - Display Tests

    @Test("表示: シェブロンありで正しく表示される")
    func displayWithChevron() async throws {
        // Arrange
        let row = SettingsRow(
            icon: "photo",
            iconColor: .blue,
            title: "写真ライブラリ",
            showChevron: true
        )

        // Act & Assert
        #expect(row.showChevron == true)
    }

    @Test("表示: シェブロンなしで正しく表示される")
    func displayWithoutChevron() async throws {
        // Arrange
        let row = SettingsRow(
            icon: "bell",
            iconColor: .orange,
            title: "通知",
            showChevron: false
        )

        // Act & Assert
        #expect(row.showChevron == false)
    }

    @Test("表示: サブタイトルありで正しく表示される")
    func displayWithSubtitle() async throws {
        // Arrange
        let row = SettingsRow(
            icon: "lock",
            iconColor: .red,
            title: "プライバシー",
            subtitle: "データ保護設定"
        )

        // Act & Assert
        #expect(row.subtitle == "データ保護設定")
    }

    @Test("表示: サブタイトルなしで正しく表示される")
    func displayWithoutSubtitle() async throws {
        // Arrange
        let row = SettingsRow(
            icon: "gear",
            iconColor: .gray,
            title: "設定"
        )

        // Act & Assert
        #expect(row.subtitle == nil)
    }

    // MARK: - Icon Tests

    @Test("アイコン: 正しいアイコン名が設定される")
    func iconNameIsSet() async throws {
        // Arrange
        let icons = ["bell", "moon", "photo", "gear", "lock"]

        for iconName in icons {
            // Act
            let row = SettingsRow(
                icon: iconName,
                title: "テスト"
            )

            // Assert
            #expect(row.icon == iconName)
        }
    }

    @Test("アイコン: 正しいアイコンカラーが設定される")
    func iconColorIsSet() async throws {
        // Arrange
        let colors: [Color] = [.orange, .blue, .red, .purple, .green]

        for color in colors {
            // Act
            let row = SettingsRow(
                icon: "bell",
                iconColor: color,
                title: "テスト"
            )

            // Assert
            #expect(row.iconColor == color)
        }
    }

    // MARK: - Text Tests

    @Test("テキスト: タイトルが正しく設定される")
    func titleIsSet() async throws {
        // Arrange
        let titles = ["通知", "設定", "プライバシー", "写真ライブラリ"]

        for title in titles {
            // Act
            let row = SettingsRow(
                icon: "gear",
                title: title
            )

            // Assert
            #expect(row.title == title)
        }
    }

    @Test("テキスト: サブタイトルが正しく設定される")
    func subtitleIsSet() async throws {
        // Arrange
        let subtitle = "これはサブタイトルです"

        // Act
        let row = SettingsRow(
            icon: "bell",
            title: "通知",
            subtitle: subtitle
        )

        // Assert
        #expect(row.subtitle == subtitle)
    }

    // MARK: - Complex Initialization Tests

    @Test("複雑な初期化: すべてのパラメータを指定した場合")
    func complexInitializationWithAllParameters() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "bell.badge",
            iconColor: .orange,
            title: "重要な通知",
            subtitle: "緊急のお知らせを受け取る",
            showChevron: true
        ) {
            Image(systemName: "checkmark")
        }

        // Assert
        #expect(row.icon == "bell.badge")
        #expect(row.iconColor == .orange)
        #expect(row.title == "重要な通知")
        #expect(row.subtitle == "緊急のお知らせを受け取る")
        #expect(row.showChevron == true)
    }

    @Test("複雑な初期化: 最小限のパラメータで初期化")
    func complexInitializationWithMinimalParameters() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "gear",
            title: "設定"
        )

        // Assert
        #expect(row.icon == "gear")
        #expect(row.iconColor == .gray)
        #expect(row.title == "設定")
        #expect(row.subtitle == nil)
        #expect(row.showChevron == false)
    }

    // MARK: - Edge Cases

    @Test("エッジケース: 長いタイトルでも正しく初期化される")
    func edgeCaseLongTitle() async throws {
        // Arrange
        let longTitle = String(repeating: "長いタイトル", count: 10)

        // Act
        let row = SettingsRow(
            icon: "text.alignleft",
            title: longTitle
        )

        // Assert
        #expect(row.title == longTitle)
    }

    @Test("エッジケース: 長いサブタイトルでも正しく初期化される")
    func edgeCaseLongSubtitle() async throws {
        // Arrange
        let longSubtitle = String(repeating: "長いサブタイトル", count: 10)

        // Act
        let row = SettingsRow(
            icon: "text.alignleft",
            title: "タイトル",
            subtitle: longSubtitle
        )

        // Assert
        #expect(row.subtitle == longSubtitle)
    }

    @Test("エッジケース: 空のタイトルでも初期化できる")
    func edgeCaseEmptyTitle() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "questionmark",
            title: ""
        )

        // Assert
        #expect(row.title == "")
    }

    @Test("エッジケース: 空のサブタイトルでも初期化できる")
    func edgeCaseEmptySubtitle() async throws {
        // Arrange & Act
        let row = SettingsRow(
            icon: "questionmark",
            title: "タイトル",
            subtitle: ""
        )

        // Assert
        #expect(row.subtitle == "")
    }

    // MARK: - Accessibility Tests

    @Test("アクセシビリティ: アイコンが存在することを確認")
    func accessibilityIconExists() async throws {
        // Arrange
        let row = SettingsRow(
            icon: "bell",
            iconColor: .orange,
            title: "通知"
        )

        // Act & Assert
        #expect(row.icon == "bell")
        // アイコンはaccessibilityHidden(true)であることを期待
    }
}
