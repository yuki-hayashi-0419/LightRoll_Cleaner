//
//  GroupCardTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GroupCard コンポーネントのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - GroupCard Tests

@Suite("GroupCard Component Tests")
struct GroupCardTests {

    // MARK: - Test Data

    /// テスト用の写真を生成
    private func createTestPhoto(id: String, fileSize: Int64 = 2_500_000) -> Photo {
        Photo(
            id: id,
            localIdentifier: "local-\(id)",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: fileSize,
            isFavorite: false
        )
    }

    /// テスト用のグループを生成
    private func createTestGroup(
        type: GroupType = .similar,
        photoCount: Int = 5,
        bestShotIndex: Int? = 0
    ) -> PhotoGroup {
        let photoIds = (0..<photoCount).map { "photo-\($0)" }
        let fileSizes = Array(repeating: Int64(2_500_000), count: photoCount)

        return PhotoGroup(
            type: type,
            photoIds: photoIds,
            fileSizes: fileSizes,
            bestShotIndex: bestShotIndex
        )
    }

    // MARK: - Initialization Tests

    @Test("GroupCard は適切に初期化される")
    @MainActor
    func testGroupCardInitialization() {
        // Given
        let group = createTestGroup()
        let photos = [
            createTestPhoto(id: "photo-0"),
            createTestPhoto(id: "photo-1"),
            createTestPhoto(id: "photo-2")
        ]
        var tapCount = 0

        // When
        let card = GroupCard(
            group: group,
            representativePhotos: photos
        ) {
            tapCount += 1
        }

        // Then: コンパイルが通ること、ビューが生成されることを確認
        #expect(card.group.id == group.id)
    }

    @Test("GroupCard は3枚を超える写真を受け取った場合、最初の3枚のみ表示する")
    @MainActor
    func testGroupCardLimitsRepresentativePhotos() {
        // Given
        let group = createTestGroup()
        let photos = [
            createTestPhoto(id: "photo-0"),
            createTestPhoto(id: "photo-1"),
            createTestPhoto(id: "photo-2"),
            createTestPhoto(id: "photo-3"),
            createTestPhoto(id: "photo-4")
        ]

        // When
        let card = GroupCard(
            group: group,
            representativePhotos: photos
        ) {}

        // Then: 最初の3枚のみが保持される
        #expect(card.representativePhotos.count == 3)
        #expect(card.representativePhotos[0].id == "photo-0")
        #expect(card.representativePhotos[1].id == "photo-1")
        #expect(card.representativePhotos[2].id == "photo-2")
    }

    // MARK: - Group Type Tests

    @Test("GroupCard は類似写真グループを表示できる")
    @MainActor
    func testGroupCardDisplaysSimilarGroup() {
        // Given
        let group = createTestGroup(type: .similar, photoCount: 10)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.type == .similar)
        #expect(card.group.displayName == "類似写真")
    }

    @Test("GroupCard はスクリーンショットグループを表示できる")
    @MainActor
    func testGroupCardDisplaysScreenshotGroup() {
        // Given
        let group = createTestGroup(type: .screenshot, photoCount: 15)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.type == .screenshot)
        #expect(card.group.displayName == "スクリーンショット")
    }

    @Test("GroupCard はブレ写真グループを表示できる")
    @MainActor
    func testGroupCardDisplaysBlurryGroup() {
        // Given
        let group = createTestGroup(type: .blurry, photoCount: 8)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.type == .blurry)
        #expect(card.group.displayName == "ブレ写真")
    }

    @Test("GroupCard は大容量動画グループを表示できる")
    @MainActor
    func testGroupCardDisplaysLargeVideoGroup() {
        // Given
        let group = createTestGroup(type: .largeVideo, photoCount: 3)
        let photos = [createTestPhoto(id: "video-0", fileSize: 150_000_000)]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.type == .largeVideo)
        #expect(card.group.displayName == "大容量動画")
    }

    // MARK: - Data Display Tests

    @Test("GroupCard は正しい写真枚数を表示する")
    @MainActor
    func testGroupCardDisplaysCorrectPhotoCount() {
        // Given
        let group = createTestGroup(photoCount: 24)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.count == 24)
    }

    @Test("GroupCard は削減可能サイズを計算する")
    @MainActor
    func testGroupCardCalculatesReclaimableSize() {
        // Given: 5枚の写真、各2.5MB、ベストショット1枚
        let group = createTestGroup(photoCount: 5, bestShotIndex: 0)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then: 4枚分の容量が削減可能
        let expectedReclaimable = Int64(2_500_000 * 4) // 10MB
        #expect(card.group.reclaimableSize == expectedReclaimable)
    }

    // MARK: - Best Shot Tests

    @Test("GroupCard はベストショットインデックスを保持する")
    @MainActor
    func testGroupCardPreservesBestShotIndex() {
        // Given
        let group = createTestGroup(photoCount: 5, bestShotIndex: 2)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.bestShotIndex == 2)
    }

    @Test("GroupCard はベストショット未選定のグループを扱える")
    @MainActor
    func testGroupCardHandlesNoBestShot() {
        // Given
        let group = createTestGroup(photoCount: 5, bestShotIndex: nil)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.bestShotIndex == nil)
        // ベストショットがない場合、全写真が削減対象
        #expect(card.group.reclaimableSize == card.group.totalSize)
    }

    // MARK: - Edge Cases

    @Test("GroupCard は空の代表写真配列を扱える")
    @MainActor
    func testGroupCardHandlesEmptyRepresentativePhotos() {
        // Given
        let group = createTestGroup()
        let photos: [Photo] = []

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.representativePhotos.isEmpty)
    }

    @Test("GroupCard は1枚の代表写真を扱える")
    @MainActor
    func testGroupCardHandlesSingleRepresentativePhoto() {
        // Given
        let group = createTestGroup()
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.representativePhotos.count == 1)
    }

    @Test("GroupCard は2枚の代表写真を扱える")
    @MainActor
    func testGroupCardHandlesTwoRepresentativePhotos() {
        // Given
        let group = createTestGroup()
        let photos = [
            createTestPhoto(id: "photo-0"),
            createTestPhoto(id: "photo-1")
        ]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.representativePhotos.count == 2)
    }

    // MARK: - Accessibility Tests

    @Test("GroupCard はアクセシビリティ記述を生成する")
    @MainActor
    func testGroupCardAccessibilityDescription() {
        // Given
        let group = createTestGroup(type: .similar, photoCount: 10, bestShotIndex: 0)
        let photos = [createTestPhoto(id: "photo-0")]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}
        let description = card.accessibilityDescription

        // Then
        #expect(description.contains("類似写真"))
        #expect(description.contains("10枚"))
    }

    // MARK: - Performance Tests

    @Test("GroupCard は大量の写真を持つグループでも効率的に動作する")
    @MainActor
    func testGroupCardPerformanceWithLargeGroup() {
        // Given
        let group = createTestGroup(photoCount: 100)
        let photos = [
            createTestPhoto(id: "photo-0"),
            createTestPhoto(id: "photo-1"),
            createTestPhoto(id: "photo-2")
        ]

        // When
        let card = GroupCard(group: group, representativePhotos: photos) {}

        // Then
        #expect(card.group.count == 100)
        // 代表写真は3枚のみ
        #expect(card.representativePhotos.count == 3)
    }

    // MARK: - Integration Tests

    @Test("GroupCard は実際のグループデータで正しく動作する")
    @MainActor
    func testGroupCardWithRealisticData() {
        // Given: 類似写真グループ（連写24枚、2.5MB/枚）
        let photoIds = (0..<24).map { "burst-photo-\($0)" }
        let fileSizes = Array(repeating: Int64(2_500_000), count: 24)

        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: fileSizes,
            bestShotIndex: 5 // 6枚目がベストショット
        )

        let representativePhotos = [
            createTestPhoto(id: "burst-photo-0"),
            createTestPhoto(id: "burst-photo-5"),
            createTestPhoto(id: "burst-photo-23")
        ]

        // When
        let card = GroupCard(
            group: group,
            representativePhotos: representativePhotos
        ) {}

        // Then
        #expect(card.group.count == 24)
        #expect(card.group.type == .similar)
        #expect(card.group.bestShotIndex == 5)
        // 23枚分が削減可能（ベストショット以外）
        #expect(card.group.reclaimableSize == Int64(2_500_000 * 23))
        #expect(card.representativePhotos.count == 3)
    }
}
