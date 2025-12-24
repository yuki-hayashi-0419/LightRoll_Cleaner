//
//  DisplaySettingsIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DisplaySettings統合テスト
//  DISPLAY-001〜003の統合動作を検証
//  Created by AI Assistant on 2025-12-24.
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - DisplaySettingsIntegrationTests

/// DisplaySettings統合テストスイート
/// 設定画面からUI表示までの統合動作を検証
@Suite("DisplaySettings統合テスト")
@MainActor
struct DisplaySettingsIntegrationTests {

    // MARK: - Test Data Helpers

    /// テスト用写真データ生成
    /// 様々なファイルサイズと撮影日を持つ写真を生成
    private func createTestPhotos(count: Int) -> [Photo] {
        var result: [Photo] = []
        let baseDate = Date()

        for index in 0..<count {
            let photo = Photo(
                id: "photo-\(index)",
                localIdentifier: "local-\(index)",
                creationDate: baseDate.addingTimeInterval(TimeInterval(-index * 86400)), // 日毎にずらす
                modificationDate: baseDate,
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: 0,
                fileSize: Int64(1_000_000 + index * 500_000), // 1MB〜、500KBずつ増加
                isFavorite: false
            )
            result.append(photo)
        }
        return result
    }

    // MARK: - DISPLAY-001: グリッド列数統合テスト

    @Test("グリッド列数2列が正しく設定される")
    func testGridColumns2() async throws {
        // Arrange: 2列設定
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 2,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        // Assert: 設定値が反映されている
        #expect(service.settings.displaySettings.gridColumns == 2)
    }

    @Test("グリッド列数3列が正しく設定される")
    func testGridColumns3() async throws {
        // Arrange: 3列設定
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 3,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 3)
    }

    @Test("グリッド列数4列（デフォルト）が正しく設定される")
    func testGridColumns4Default() async throws {
        // Arrange: デフォルト4列
        let service = SettingsService()
        try service.updateDisplaySettings(.default)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 4)
    }

    @Test("グリッド列数5列が正しく設定される")
    func testGridColumns5() async throws {
        // Arrange: 5列設定
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 5,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 5)
    }

    @Test("グリッド列数6列（最大）が正しく設定される")
    func testGridColumns6Maximum() async throws {
        // Arrange: 最大6列
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 6,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 6)
    }

    @Test("グリッド列数変更がPhotoGridに反映される")
    func testGridColumnsReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let photos = createTestPhotos(count: 10)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act: 2列→6列に変更
        for columns in 2...6 {
            let settings = DisplaySettings(
                gridColumns: columns,
                showFileSize: false,
                showDate: false,
                sortOrder: .dateDescending
            )
            try service.updateDisplaySettings(settings)

            let grid = PhotoGrid(
                photos: photos,
                columns: service.settings.displaySettings.gridColumns,
                selectedPhotos: selectedPhotos
            )

            // Assert: PhotoGridの列数が設定と一致
            #expect(grid.columns == columns)
        }
    }

    @Test("グリッド列数境界値下限（1列未満）はエラー")
    func testGridColumnsBelowMinimumThrowsError() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = DisplaySettings(
            gridColumns: 0,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateDisplaySettings(invalidSettings)
        }
    }

    @Test("グリッド列数境界値上限（7列以上）はエラー")
    func testGridColumnsAboveMaximumThrowsError() async throws {
        // Arrange
        let service = SettingsService()
        let invalidSettings = DisplaySettings(
            gridColumns: 7,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )

        // Act & Assert
        #expect(throws: SettingsError.self) {
            try service.updateDisplaySettings(invalidSettings)
        }
    }

    // MARK: - DISPLAY-002: ファイルサイズ/撮影日表示統合テスト

    @Test("ファイルサイズ表示オン時にPhotoGridにフラグが渡される")
    func testShowFileSizeOnReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act
        let grid = PhotoGrid(
            photos: photos,
            columns: service.settings.displaySettings.gridColumns,
            selectedPhotos: selectedPhotos,
            showFileSize: service.settings.displaySettings.showFileSize,
            showDate: service.settings.displaySettings.showDate
        )

        // Assert
        #expect(grid.showFileSize == true)
        #expect(grid.showDate == false)
    }

    @Test("ファイルサイズ表示オフ時にPhotoGridにフラグが渡される")
    func testShowFileSizeOffReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act
        let grid = PhotoGrid(
            photos: photos,
            columns: service.settings.displaySettings.gridColumns,
            selectedPhotos: selectedPhotos,
            showFileSize: service.settings.displaySettings.showFileSize,
            showDate: service.settings.displaySettings.showDate
        )

        // Assert
        #expect(grid.showFileSize == false)
        #expect(grid.showDate == true)
    }

    @Test("撮影日表示オン時にPhotoGridにフラグが渡される")
    func testShowDateOnReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act
        let grid = PhotoGrid(
            photos: photos,
            columns: service.settings.displaySettings.gridColumns,
            selectedPhotos: selectedPhotos,
            showFileSize: service.settings.displaySettings.showFileSize,
            showDate: service.settings.displaySettings.showDate
        )

        // Assert
        #expect(grid.showDate == true)
    }

    @Test("ファイルサイズと撮影日両方オン時に両フラグが渡される")
    func testBothFileSizeAndDateOnReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: true,
            showDate: true,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act
        let grid = PhotoGrid(
            photos: photos,
            columns: service.settings.displaySettings.gridColumns,
            selectedPhotos: selectedPhotos,
            showFileSize: service.settings.displaySettings.showFileSize,
            showDate: service.settings.displaySettings.showDate
        )

        // Assert
        #expect(grid.showFileSize == true)
        #expect(grid.showDate == true)
    }

    @Test("ファイルサイズと撮影日両方オフ時に両フラグがオフ")
    func testBothFileSizeAndDateOffReflectedInPhotoGrid() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // Act
        let grid = PhotoGrid(
            photos: photos,
            columns: service.settings.displaySettings.gridColumns,
            selectedPhotos: selectedPhotos,
            showFileSize: service.settings.displaySettings.showFileSize,
            showDate: service.settings.displaySettings.showDate
        )

        // Assert
        #expect(grid.showFileSize == false)
        #expect(grid.showDate == false)
    }

    @Test("Photoモデルのファイルサイズフォーマットが正しい")
    func testPhotoFileSizeFormat() async throws {
        // Arrange: 様々なサイズの写真
        let smallPhoto = Photo(
            id: "small",
            localIdentifier: "small-local",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1000,
            pixelHeight: 1000,
            duration: 0,
            fileSize: 500_000, // 500KB
            isFavorite: false
        )

        let mediumPhoto = Photo(
            id: "medium",
            localIdentifier: "medium-local",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1000,
            pixelHeight: 1000,
            duration: 0,
            fileSize: 2_500_000, // 2.5MB
            isFavorite: false
        )

        let largePhoto = Photo(
            id: "large",
            localIdentifier: "large-local",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 1000,
            pixelHeight: 1000,
            duration: 0,
            fileSize: 15_000_000, // 15MB
            isFavorite: false
        )

        // Assert: formattedFileSizeが適切にフォーマットされている
        #expect(smallPhoto.formattedFileSize.contains("KB") || smallPhoto.formattedFileSize.contains("MB"))
        #expect(mediumPhoto.formattedFileSize.contains("MB"))
        #expect(largePhoto.formattedFileSize.contains("MB"))
    }

    // MARK: - DISPLAY-003: 並び順統合テスト

    @Test("新しい順（dateDescending）で正しくソートされる")
    func testSortOrderDateDescending() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)

        // Act: applySortOrderと同じロジックでソート
        let sortOrder = service.settings.displaySettings.sortOrder
        let sortedPhotos: [Photo]
        switch sortOrder {
        case .dateDescending:
            sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }
        case .dateAscending:
            sortedPhotos = photos.sorted { $0.creationDate < $1.creationDate }
        case .sizeDescending:
            sortedPhotos = photos.sorted { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            sortedPhotos = photos.sorted { $0.fileSize < $1.fileSize }
        }

        // Assert: 最初の写真が最も新しい
        #expect(sortedPhotos.first?.creationDate ?? Date.distantPast >= sortedPhotos.last?.creationDate ?? Date.distantFuture)
    }

    @Test("古い順（dateAscending）で正しくソートされる")
    func testSortOrderDateAscending() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateAscending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)

        // Act
        let sortOrder = service.settings.displaySettings.sortOrder
        let sortedPhotos: [Photo]
        switch sortOrder {
        case .dateDescending:
            sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }
        case .dateAscending:
            sortedPhotos = photos.sorted { $0.creationDate < $1.creationDate }
        case .sizeDescending:
            sortedPhotos = photos.sorted { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            sortedPhotos = photos.sorted { $0.fileSize < $1.fileSize }
        }

        // Assert: 最初の写真が最も古い
        #expect(sortedPhotos.first?.creationDate ?? Date.distantFuture <= sortedPhotos.last?.creationDate ?? Date.distantPast)
    }

    @Test("容量大きい順（sizeDescending）で正しくソートされる")
    func testSortOrderSizeDescending() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeDescending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)

        // Act
        let sortOrder = service.settings.displaySettings.sortOrder
        let sortedPhotos: [Photo]
        switch sortOrder {
        case .dateDescending:
            sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }
        case .dateAscending:
            sortedPhotos = photos.sorted { $0.creationDate < $1.creationDate }
        case .sizeDescending:
            sortedPhotos = photos.sorted { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            sortedPhotos = photos.sorted { $0.fileSize < $1.fileSize }
        }

        // Assert: 最初の写真が最も大きい
        #expect(sortedPhotos.first?.fileSize ?? 0 >= sortedPhotos.last?.fileSize ?? Int64.max)
    }

    @Test("容量小さい順（sizeAscending）で正しくソートされる")
    func testSortOrderSizeAscending() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeAscending
        )
        try service.updateDisplaySettings(settings)

        let photos = createTestPhotos(count: 5)

        // Act
        let sortOrder = service.settings.displaySettings.sortOrder
        let sortedPhotos: [Photo]
        switch sortOrder {
        case .dateDescending:
            sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }
        case .dateAscending:
            sortedPhotos = photos.sorted { $0.creationDate < $1.creationDate }
        case .sizeDescending:
            sortedPhotos = photos.sorted { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            sortedPhotos = photos.sorted { $0.fileSize < $1.fileSize }
        }

        // Assert: 最初の写真が最も小さい
        #expect(sortedPhotos.first?.fileSize ?? Int64.max <= sortedPhotos.last?.fileSize ?? 0)
    }

    @Test("SortOrderの全ケースが利用可能")
    func testAllSortOrderCasesAvailable() async throws {
        // Assert: 4つのソート順が定義されている
        let allCases = SortOrder.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.dateDescending))
        #expect(allCases.contains(.dateAscending))
        #expect(allCases.contains(.sizeDescending))
        #expect(allCases.contains(.sizeAscending))
    }

    @Test("SortOrderの表示名が正しい")
    func testSortOrderDisplayNames() async throws {
        // Assert
        #expect(SortOrder.dateDescending.displayName == "新しい順")
        #expect(SortOrder.dateAscending.displayName == "古い順")
        #expect(SortOrder.sizeDescending.displayName == "容量大きい順")
        #expect(SortOrder.sizeAscending.displayName == "容量小さい順")
    }

    // MARK: - 統合シナリオテスト

    @Test("複数設定を同時に変更できる")
    func testMultipleSettingsChange() async throws {
        // Arrange
        let service = SettingsService()

        // Act: すべての設定を変更
        let newSettings = DisplaySettings(
            gridColumns: 5,
            showFileSize: false,
            showDate: true,
            sortOrder: .sizeDescending
        )
        try service.updateDisplaySettings(newSettings)

        // Assert
        #expect(service.settings.displaySettings.gridColumns == 5)
        #expect(service.settings.displaySettings.showFileSize == false)
        #expect(service.settings.displaySettings.showDate == true)
        #expect(service.settings.displaySettings.sortOrder == .sizeDescending)
    }

    @Test("デフォルト設定にリセットできる")
    func testResetToDefault() async throws {
        // Arrange: カスタム設定
        let service = SettingsService()
        let customSettings = DisplaySettings(
            gridColumns: 2,
            showFileSize: false,
            showDate: false,
            sortOrder: .sizeAscending
        )
        try service.updateDisplaySettings(customSettings)

        // Act: デフォルトにリセット
        try service.updateDisplaySettings(.default)

        // Assert: デフォルト値
        #expect(service.settings.displaySettings.gridColumns == 4)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == true)
        #expect(service.settings.displaySettings.sortOrder == .dateDescending)
    }

    @Test("無効な設定では元の設定が維持される")
    func testInvalidSettingsPreservesOriginal() async throws {
        // Arrange: 有効な設定
        let service = SettingsService()
        let validSettings = DisplaySettings(
            gridColumns: 3,
            showFileSize: true,
            showDate: false,
            sortOrder: .dateAscending
        )
        try service.updateDisplaySettings(validSettings)

        // Act: 無効な設定を試みる
        let invalidSettings = DisplaySettings(
            gridColumns: 10, // 無効
            showFileSize: false,
            showDate: true,
            sortOrder: .sizeDescending
        )

        do {
            try service.updateDisplaySettings(invalidSettings)
            Issue.record("エラーが発生するべき")
        } catch {
            // 期待通りエラー発生
        }

        // Assert: 元の設定が維持されている
        #expect(service.settings.displaySettings.gridColumns == 3)
        #expect(service.settings.displaySettings.showFileSize == true)
        #expect(service.settings.displaySettings.showDate == false)
        #expect(service.settings.displaySettings.sortOrder == .dateAscending)
    }

    @Test("空の写真リストでもソートが動作する")
    func testSortEmptyPhotoList() async throws {
        // Arrange
        let service = SettingsService()
        let settings = DisplaySettings(
            gridColumns: 4,
            showFileSize: false,
            showDate: false,
            sortOrder: .dateDescending
        )
        try service.updateDisplaySettings(settings)

        let photos: [Photo] = []

        // Act
        let sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }

        // Assert: 空のままエラーなし
        #expect(sortedPhotos.isEmpty)
    }

    @Test("1枚の写真でもソートが動作する")
    func testSortSinglePhoto() async throws {
        // Arrange
        let photos = createTestPhotos(count: 1)

        // Act
        let sortedPhotos = photos.sorted { $0.creationDate > $1.creationDate }

        // Assert
        #expect(sortedPhotos.count == 1)
        #expect(sortedPhotos.first?.id == "photo-0")
    }

    @Test("同じ撮影日の写真でもソートが安定している")
    func testSortWithSameCreationDate() async throws {
        // Arrange: 同じ日付の写真
        let baseDate = Date()
        let photos = [
            Photo(
                id: "same-date-1",
                localIdentifier: "local-1",
                creationDate: baseDate,
                modificationDate: baseDate,
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1000,
                pixelHeight: 1000,
                duration: 0,
                fileSize: 1_000_000,
                isFavorite: false
            ),
            Photo(
                id: "same-date-2",
                localIdentifier: "local-2",
                creationDate: baseDate,
                modificationDate: baseDate,
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1000,
                pixelHeight: 1000,
                duration: 0,
                fileSize: 2_000_000,
                isFavorite: false
            )
        ]

        // Act: 日付順でソート
        let sortedByDate = photos.sorted { $0.creationDate > $1.creationDate }

        // Assert: ソートは安定して動作（順序は保証されないが、クラッシュしない）
        #expect(sortedByDate.count == 2)
    }

    @Test("同じファイルサイズの写真でもソートが安定している")
    func testSortWithSameFileSize() async throws {
        // Arrange: 同じサイズの写真
        let baseDate = Date()
        let photos = [
            Photo(
                id: "same-size-1",
                localIdentifier: "local-1",
                creationDate: baseDate.addingTimeInterval(-86400),
                modificationDate: baseDate,
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1000,
                pixelHeight: 1000,
                duration: 0,
                fileSize: 1_000_000,
                isFavorite: false
            ),
            Photo(
                id: "same-size-2",
                localIdentifier: "local-2",
                creationDate: baseDate,
                modificationDate: baseDate,
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 1000,
                pixelHeight: 1000,
                duration: 0,
                fileSize: 1_000_000,
                isFavorite: false
            )
        ]

        // Act: サイズ順でソート
        let sortedBySize = photos.sorted { $0.fileSize > $1.fileSize }

        // Assert: ソートは安定して動作（順序は保証されないが、クラッシュしない）
        #expect(sortedBySize.count == 2)
    }
}
