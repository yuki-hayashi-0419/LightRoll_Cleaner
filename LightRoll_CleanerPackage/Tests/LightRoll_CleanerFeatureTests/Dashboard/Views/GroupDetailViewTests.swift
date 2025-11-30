//
//  GroupDetailViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GroupDetailViewのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - GroupDetailViewTests

@MainActor
@Suite("GroupDetailView Tests", .tags(.dashboard, .view))
struct GroupDetailViewTests {

    // MARK: - Test Data

    /// テスト用の写真プロバイダー
    private struct MockPhotoProvider: PhotoProvider {
        let photos: [Photo]

        func photos(for ids: [String]) async -> [Photo] {
            photos.filter { ids.contains($0.id) }
        }
    }

    /// テスト用のサンプル写真
    private func createMockPhotos(count: Int) -> [Photo] {
        (0..<count).map { index in
            Photo(
                id: "photo-\(index)",
                localIdentifier: "photo-\(index)",
                creationDate: Date().addingTimeInterval(TimeInterval(-3600 * index)),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: 0,
                fileSize: 2_500_000,
                isFavorite: false
            )
        }
    }

    // MARK: - Initialization Tests

    @Test("初期化 - 基本プロパティ")
    func testInitialization() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000],
            bestShotIndex: 0
        )

        // When
        let view = GroupDetailView(group: group)

        // Then
        // ビューが正常に作成されることを確認
        #expect(group.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        #expect(group.type == .similar)
        #expect(group.count == 3)
    }

    @Test("初期化 - PhotoProvider付き")
    func testInitializationWithProvider() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )
        let photos = createMockPhotos(count: 2)
        let provider = MockPhotoProvider(photos: photos)

        // When
        let view = GroupDetailView(
            group: group,
            photoProvider: provider
        )

        // Then
        #expect(group.count == 2)
        #expect(group.type == .screenshot)
    }

    // MARK: - ViewState Tests

    @Test("ViewState - 全状態の存在確認")
    func testViewStateValues() {
        // Given & When
        let loading = GroupDetailView.ViewState.loading
        let loaded = GroupDetailView.ViewState.loaded
        let processing = GroupDetailView.ViewState.processing
        let error = GroupDetailView.ViewState.error("Test error")

        // Then
        #expect(loading == .loading)
        #expect(loaded == .loaded)
        #expect(processing == .processing)
        if case .error(let message) = error {
            #expect(message == "Test error")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("ViewState - Equatable")
    func testViewStateEquatable() {
        // Given
        let state1 = GroupDetailView.ViewState.loading
        let state2 = GroupDetailView.ViewState.loading
        let state3 = GroupDetailView.ViewState.loaded

        // Then
        #expect(state1 == state2)
        #expect(state1 != state3)
    }

    // MARK: - Group Data Tests

    @Test("グループデータ - 類似写真グループ")
    func testSimilarPhotosGroup() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: (0..<5).map { "photo-\($0)" },
            fileSizes: Array(repeating: 3_000_000, count: 5),
            bestShotIndex: 0
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.type == .similar)
        #expect(group.count == 5)
        #expect(group.bestShotIndex == 0)
    }

    @Test("グループデータ - スクリーンショットグループ")
    func testScreenshotGroup() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: (0..<10).map { "screenshot-\($0)" },
            fileSizes: Array(repeating: 1_200_000, count: 10)
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.type == .screenshot)
        #expect(group.count == 10)
        #expect(group.bestShotIndex == nil)
    }

    @Test("グループデータ - ブレ写真グループ")
    func testBlurryPhotosGroup() {
        // Given
        let group = PhotoGroup(
            type: .blurry,
            photoIds: (0..<6).map { "blurry-\($0)" },
            fileSizes: Array(repeating: 3_500_000, count: 6)
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.type == .blurry)
        #expect(group.count == 6)
    }

    @Test("グループデータ - 自撮りグループ")
    func testSelfieGroup() {
        // Given
        let group = PhotoGroup(
            type: .selfie,
            photoIds: (0..<4).map { "selfie-\($0)" },
            fileSizes: Array(repeating: 2_800_000, count: 4),
            bestShotIndex: 1
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.type == .selfie)
        #expect(group.count == 4)
        #expect(group.bestShotIndex == 1)
    }

    // MARK: - Empty State Tests

    @Test("空状態 - 空のグループ")
    func testEmptyGroup() {
        // Given
        let group = PhotoGroup(
            type: .duplicate,
            photoIds: [],
            fileSizes: []
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.isEmpty)
        #expect(group.count == 0)
    }

    // MARK: - Best Shot Tests

    @Test("ベストショット - 設定あり")
    func testGroupWithBestShot() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3", "4"],
            fileSizes: [1000, 2000, 3000, 4000],
            bestShotIndex: 2
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.bestShotIndex == 2)
        #expect(group.bestShotId == "3")
    }

    @Test("ベストショット - 設定なし")
    func testGroupWithoutBestShot() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.bestShotIndex == nil)
        #expect(group.bestShotId == nil)
    }

    // MARK: - Size Calculation Tests

    @Test("サイズ計算 - 合計サイズ")
    func testTotalSize() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000]
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.totalSize == 6_000_000)
    }

    @Test("サイズ計算 - 削減可能サイズ（ベストショットあり）")
    func testReclaimableSizeWithBestShot() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000],
            bestShotIndex: 2 // 3,000,000バイトを保持
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        // ベストショット以外: 1,000,000 + 2,000,000 = 3,000,000
        #expect(group.reclaimableSize == 3_000_000)
    }

    @Test("サイズ計算 - 削減可能サイズ（ベストショットなし）")
    func testReclaimableSizeWithoutBestShot() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000]
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        // 全て削除可能: 6,000,000
        #expect(group.reclaimableSize == 6_000_000)
    }

    // MARK: - Photo Count Tests

    @Test("写真数 - 削減可能写真数（ベストショットあり）")
    func testReclaimableCountWithBestShot() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3", "4", "5"],
            fileSizes: Array(repeating: 1_000_000, count: 5),
            bestShotIndex: 0
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.reclaimableCount == 4)
    }

    @Test("写真数 - 削減可能写真数（ベストショットなし）")
    func testReclaimableCountWithoutBestShot() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2", "3"],
            fileSizes: Array(repeating: 1_000_000, count: 3)
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.reclaimableCount == 3)
    }

    // MARK: - Display Name Tests

    @Test("表示名 - デフォルト表示名")
    func testDefaultDisplayName() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.displayName == group.type.displayName)
    }

    @Test("表示名 - カスタム表示名")
    func testCustomDisplayName() {
        // Given
        let customName = "旅行の写真"
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000],
            customName: customName
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.displayName == customName)
    }

    // MARK: - Deletion Candidate Tests

    @Test("削除候補 - ベストショット以外の写真ID")
    func testDeletionCandidateIds() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3", "photo-4"],
            fileSizes: Array(repeating: 1_000_000, count: 4),
            bestShotIndex: 1
        )

        // When
        let _ = GroupDetailView(group: group)
        let candidateIds = group.deletionCandidateIds

        // Then
        #expect(candidateIds.count == 3)
        #expect(candidateIds.contains("photo-1"))
        #expect(candidateIds.contains("photo-3"))
        #expect(candidateIds.contains("photo-4"))
        #expect(!candidateIds.contains("photo-2"))
    }

    // MARK: - Large Group Tests

    @Test("大規模グループ - 20枚の写真")
    func testLargeGroup() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: (0..<20).map { "screenshot-\($0)" },
            fileSizes: Array(repeating: 1_200_000, count: 20)
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.count == 20)
        #expect(group.totalSize == 24_000_000)
    }

    @Test("大規模グループ - 50枚の写真")
    func testVeryLargeGroup() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: (0..<50).map { "photo-\($0)" },
            fileSizes: Array(repeating: 2_500_000, count: 50),
            bestShotIndex: 0
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then
        #expect(group.count == 50)
        #expect(group.reclaimableCount == 49)
        #expect(group.reclaimableSize == 122_500_000)
    }

    // MARK: - Different Group Types Tests

    @Test("グループタイプ - 全タイプでの初期化")
    func testAllGroupTypes() {
        for type in GroupType.allCases {
            // Given
            let group = PhotoGroup(
                type: type,
                photoIds: ["1", "2", "3"],
                fileSizes: [1000, 2000, 3000]
            )

            // When
            let _ = GroupDetailView(group: group)

            // Then
            #expect(group.type == type)
            #expect(group.count == 3)
        }
    }
}

// MARK: - Custom Test Tags

extension Tag {
    @Tag static var dashboard: Self
    @Tag static var view: Self
}
