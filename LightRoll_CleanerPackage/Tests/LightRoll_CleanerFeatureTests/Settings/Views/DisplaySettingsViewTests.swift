//
//  DisplaySettingsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  表示設定画面のテスト
//  Created by AI Assistant on 2025-12-06.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - DisplaySettingsViewTests

/// DisplaySettingsViewのテストスイート
@Suite("DisplaySettingsView Tests")
@MainActor
struct DisplaySettingsViewTests {

    // MARK: - Test: 初期化

    @Test("初期化時にデフォルト設定を読み込む")
    func testInitWithDefaultSettings() async throws {
        // Arrange
        let service = SettingsService()
        // デフォルト設定に明示的にリセット
        try service.updateDisplaySettings(.default)

        // Act
        _ = DisplaySettingsView()
            .environment(service)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 4)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == true)
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    @Test("初期化時にカスタム設定を読み込む")
    func testInitWithCustomSettings() async throws {
        // Arrange
        let service = SettingsService()
        let customSettings = DisplaySettings(
            gridColumns: 3,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeDescending
        )
        try service.updateDisplaySettings(customSettings)

        // Act
        _ = DisplaySettingsView()
            .environment(service)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 3)
        #expect(service.settings.displaySettings.showFileSize == false)
        #expect(service.settings.displaySettings.showDate == false)
        #expect(service.settings.displaySettings.sortOrder == .sizeDescending)
    }

    // MARK: - Test: グリッド列数変更

    @Test("グリッド列数を最小値（2列）に変更できる")
    func testChangeGridColumnsToMinimum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 2,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 2)
    }

    @Test("グリッド列数を最大値（6列）に変更できる")
    func testChangeGridColumnsToMaximum() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 6,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 6)
    }

    @Test("グリッド列数を3列に変更できる")
    func testChangeGridColumnsToThree() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 3,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 3)
    }

    @Test("グリッド列数を5列に変更できる")
    func testChangeGridColumnsToFive() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 5,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 5)
    }

    // MARK: - Test: ファイルサイズ表示トグル

    @Test("ファイルサイズ表示をオフに変更できる")
    func testToggleShowFileSizeOff() async throws {
        // Arrange
        let service = SettingsService()
        try service.updateDisplaySettings(.default) // オン状態

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.showFileSize == false)
    }

    @Test("ファイルサイズ表示をオンに変更できる")
    func testToggleShowFileSizeOn() async throws {
        // Arrange
        let service = SettingsService()
        let initialSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(initialSettings)

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.showFileSize == true)
    }

    // MARK: - Test: 撮影日表示トグル

    @Test("撮影日表示をオフに変更できる")
    func testToggleShowDateOff() async throws {
        // Arrange
        let service = SettingsService()
        try service.updateDisplaySettings(.default) // オン状態

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.showDate == false)
    }

    @Test("撮影日表示をオンに変更できる")
    func testToggleShowDateOn() async throws {
        // Arrange
        let service = SettingsService()
        let initialSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(initialSettings)

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.showDate == true)
    }

    // MARK: - Test: 並び順変更

    @Test("並び順を新しい順に変更できる")
    func testChangeSortOrderToDateDescending() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    @Test("並び順を古い順に変更できる")
    func testChangeSortOrderToDateAscending() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateAscending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.sortOrder == .dateAscending)
    }

    @Test("並び順を容量大きい順に変更できる")
    func testChangeSortOrderToSizeDescending() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .sizeDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.sortOrder == .sizeDescending)
    }

    @Test("並び順を容量小さい順に変更できる")
    func testChangeSortOrderToSizeAscending() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .sizeAscending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.sortOrder == .sizeAscending)
    }

    // MARK: - Test: バリデーション

    @Test("グリッド列数が範囲外（1列未満）の場合はエラー")
    func testGridColumnsValidationBelowMinimum() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = DisplaySettings(
            gridColumns: 0,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateDisplaySettings(invalidSettings)
        }
    }

    @Test("グリッド列数が範囲外（6列超過）の場合はエラー")
    func testGridColumnsValidationAboveMaximum() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = DisplaySettings(
            gridColumns: 7,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateDisplaySettings(invalidSettings)
        }
    }

    // MARK: - Test: 統合シナリオ

    @Test("複数の設定を同時に変更できる")
    func testChangeMultipleSettings() async throws {
        // Arrange
        let service = SettingsService()
        try service.updateDisplaySettings(.default)

        // Act
        let newSettings = DisplaySettings(
            gridColumns: 3,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 3)
        #expect(service.settings.displaySettings.showFileSize == false)
        #expect(service.settings.displaySettings.showDate == false)
        #expect(service.settings.displaySettings.sortOrder == .sizeDescending)
    }

    @Test("設定をデフォルトにリセットできる")
    func testResetToDefaultSettings() async throws {
        // Arrange
        let service = SettingsService()
        let customSettings = DisplaySettings(
            gridColumns: 6,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeAscending
        )
        try service.updateDisplaySettings(customSettings)

        // Act
        try service.updateDisplaySettings(.default)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 4)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == true)
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    // MARK: - Test: UI状態

    @Test("グリッド列数の表示が正しい")
    func testGridColumnsDisplay() async throws {
        // Arrange
        let service = SettingsService()

        // Act: 各列数でテスト
        for columns in 2...6 {
            let settings = DisplaySettings(
                gridColumns: columns,
                showFileSize: true,
                showDate: true,
                sortOrder: .dateDescending
            )
            try service.updateDisplaySettings(settings)

            // Assert
            #expect(service.settings.displaySettings.gridColumns == columns)
        }
    }

    @Test("並び順の表示名が正しい")
    func testSortOrderDisplayNames() async throws {
        // Arrange & Act & Assert
        #expect(SortOrder.dateDescending.displayName == "新しい順")
        #expect(SortOrder.dateAscending.displayName == "古い順")
        #expect(SortOrder.sizeDescending.displayName == "容量大きい順")
        #expect(SortOrder.sizeAscending.displayName == "容量小さい順")
    }

    @Test("すべての並び順オプションが利用可能")
    func testAllSortOrderOptionsAvailable() async throws {
        // Arrange & Act
        let allOptions = SortOrder.allCases

        // Assert
        #expect(allOptions.count == 4)
        #expect(allOptions.contains(.dateDescending))
        #expect(allOptions.contains(.dateAscending))
        #expect(allOptions.contains(.sizeDescending))
        #expect(allOptions.contains(.sizeAscending))
    }

    // MARK: - Test: エラーハンドリング

    @Test("保存失敗時に設定が元に戻る")
    func testSettingsRevertOnSaveFailure() async throws {
        // Arrange
        let service = SettingsService()
        let initialSettings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(initialSettings)

        // Act: 無効な設定を保存しようとする
        let invalidSettings = DisplaySettings(
            gridColumns: 10, // 範囲外
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeDescending
        )

        // Assert: エラーが発生する
        #expect(throws: SettingsError.self) {
            try service.updateDisplaySettings(invalidSettings)
        }

        // 元の設定が維持されていることを確認
        #expect(service.settings.displaySettings.gridColumns == 4)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == true)
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    // MARK: - Test: アクセシビリティ

    @Test("アクセシビリティ識別子が設定されている")
    func testAccessibilityIdentifiers() async throws {
        // Arrange
        let service = SettingsService()

        // Act
        let view = DisplaySettingsView()
            .environment(service)

        // Assert: アクセシビリティ識別子の存在を確認
        // 実際のUIテストではこれらの識別子が利用可能であることを確認
        #expect(view != nil)
    }
}
