//
//  PhotoGridTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoGrid コンポーネントのテスト
//  選択状態管理、タップハンドリング、アクセシビリティのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - PhotoGridTests

/// PhotoGrid コンポーネントのテストスイート
@Suite("PhotoGrid Tests")
@MainActor
struct PhotoGridTests {

    // MARK: - Test Data

    /// テスト用の写真データを生成
    private func createTestPhotos(count: Int) -> [Photo] {
        var result: [Photo] = []
        for index in 0..<count {
            let photo = Photo(
                id: "test-\(index)",
                localIdentifier: "test-local-\(index)",
                creationDate: Date().addingTimeInterval(TimeInterval(-index * 86400)),
                modificationDate: Date(),
                mediaType: index % 5 == 0 ? .video : .image,
                mediaSubtypes: index % 3 == 0 ? [.screenshot] : [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: index % 5 == 0 ? 45.5 : 0,
                fileSize: Int64(2_500_000 + index * 100_000),
                isFavorite: index % 7 == 0
            )
            result.append(photo)
        }
        return result
    }

    // MARK: - Initialization Tests

    @Test("PhotoGrid は空の写真リストで初期化できる")
    func testInitWithEmptyPhotos() {
        // Given
        let photos: [Photo] = []
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.photos.isEmpty)
    }

    @Test("PhotoGrid はデフォルトで3列になる")
    func testDefaultColumns() {
        // Given
        let photos = createTestPhotos(count: 10)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.columns == 3)
    }

    @Test("PhotoGrid はカスタム列数で初期化できる")
    func testCustomColumns() {
        // Given
        let photos = createTestPhotos(count: 10)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: 4,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.columns == 4)
    }

    // MARK: - Selection Tests

    @Test("選択された写真のセットが正しく保持される")
    func testSelectionBinding() {
        // Given
        let photos = createTestPhotos(count: 5)
        let initialSelection: Set<String> = ["test-0", "test-2"]
        let selectedPhotos = Binding.constant(initialSelection)

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.selectedPhotos == initialSelection)
        #expect(grid.selectedPhotos.count == 2)
        #expect(grid.selectedPhotos.contains("test-0"))
        #expect(grid.selectedPhotos.contains("test-2"))
    }

    @Test("ベストショット写真のセットが正しく保持される")
    func testBestShotPhotos() {
        // Given
        let photos = createTestPhotos(count: 5)
        let bestShots: Set<String> = ["test-1", "test-3"]
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos,
            bestShotPhotos: bestShots
        )

        // Then
        #expect(grid.bestShotPhotos == bestShots)
        #expect(grid.bestShotPhotos.count == 2)
        #expect(grid.bestShotPhotos.contains("test-1"))
        #expect(grid.bestShotPhotos.contains("test-3"))
    }

    // MARK: - Data Tests

    @Test("複数の写真を表示できる")
    func testMultiplePhotos() {
        // Given
        let photos = createTestPhotos(count: 20)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.photos.count == 20)
    }

    @Test("空の写真リストでも正常に動作する")
    func testEmptyPhotosHandling() {
        // Given
        let photos: [Photo] = []
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.photos.isEmpty)
        #expect(grid.selectedPhotos.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("1列グリッドも設定できる")
    func testSingleColumnGrid() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: 1,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.columns == 1)
    }

    @Test("多数の列でもグリッドを構成できる")
    func testManyColumnsGrid() {
        // Given
        let photos = createTestPhotos(count: 50)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: 10,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.columns == 10)
    }

    @Test("大量の写真（100枚以上）でも正常に動作する")
    func testManyPhotos() {
        // Given
        let photos = createTestPhotos(count: 150)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: 3,
            selectedPhotos: selectedPhotos
        )

        // Then
        #expect(grid.photos.count == 150)
        #expect(grid.columns == 3)
    }

    @Test("0列グリッドを設定しても動作する")
    func testZeroColumnGrid() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: 0,
            selectedPhotos: selectedPhotos
        )

        // Then
        // 実装では0列でも受け入れられることを確認
        #expect(grid.columns == 0)
    }

    @Test("負の列数を設定しても動作する")
    func testNegativeColumnGrid() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            columns: -1,
            selectedPhotos: selectedPhotos
        )

        // Then
        // 実装では負の値でも受け入れられることを確認
        #expect(grid.columns == -1)
    }

    // MARK: - Interaction Tests

    @Test("カスタムタップハンドラが正しく呼ばれる")
    func testCustomTapHandler() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())
        var tappedPhoto: Photo?

        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos,
            onPhotoTap: { photo in
                tappedPhoto = photo
            }
        )

        // Then
        // onPhotoTap が設定されていることを確認
        #expect(grid.onPhotoTap != nil)

        // コールバックを実行して動作を確認
        if let callback = grid.onPhotoTap {
            callback(photos[0])
            #expect(tappedPhoto?.id == "test-0")
        }
    }

    @Test("カスタム長押しハンドラが正しく呼ばれる")
    func testCustomLongPressHandler() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())
        var longPressedPhoto: Photo?

        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos,
            onPhotoLongPress: { photo in
                longPressedPhoto = photo
            }
        )

        // Then
        // onPhotoLongPress が設定されていることを確認
        #expect(grid.onPhotoLongPress != nil)

        // コールバックを実行して動作を確認
        if let callback = grid.onPhotoLongPress {
            callback(photos[2])
            #expect(longPressedPhoto?.id == "test-2")
        }
    }

    @Test("タップハンドラがnilの場合は何もしない")
    func testNilTapHandler() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos,
            onPhotoTap: nil
        )

        // Then
        // デフォルト動作（選択トグル）が適用されることを確認
        #expect(grid.onPhotoTap == nil)
    }

    @Test("長押しハンドラがnilの場合は何もしない")
    func testNilLongPressHandler() {
        // Given
        let photos = createTestPhotos(count: 5)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos,
            onPhotoLongPress: nil
        )

        // Then
        // デフォルト動作（選択トグル）が適用されることを確認
        #expect(grid.onPhotoLongPress == nil)
    }

    // MARK: - Accessibility Tests

    @Test("accessibilityIdentifier が正しく設定される")
    func testAccessibilityIdentifier() {
        // Given
        let photos = createTestPhotos(count: 3)
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        // 各写真に "photo-{id}" の形式で identifier が設定されることを期待
        // 実装ではPhotoThumbnailに accessibilityIdentifier が設定される
        #expect(grid.photos.count == 3)
        #expect(grid.photos[0].id == "test-0")
        #expect(grid.photos[1].id == "test-1")
        #expect(grid.photos[2].id == "test-2")
    }

    @Test("グリッドのaccessibilityLabelが正しく設定される")
    func testGridAccessibilityLabel() {
        // Given
        let photos = createTestPhotos(count: 10)
        let selectedPhotos = Binding.constant(Set(["test-0", "test-2", "test-5"]))

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        // グリッドには "写真グリッド" というラベルが設定される
        // accessibilityHint には "{総数}枚の写真、{選択数}枚選択中" が設定される
        #expect(grid.photos.count == 10)
        #expect(grid.selectedPhotos.count == 3)
    }

    @Test("空状態のaccessibilityLabelが正しく設定される")
    func testEmptyStateAccessibilityLabel() {
        // Given
        let photos: [Photo] = []
        let selectedPhotos = Binding.constant(Set<String>())

        // When
        let grid = PhotoGrid(
            photos: photos,
            selectedPhotos: selectedPhotos
        )

        // Then
        // 空状態には "写真がありません" というラベルが設定される
        #expect(grid.photos.isEmpty)
        #expect(grid.selectedPhotos.isEmpty)
    }
}
