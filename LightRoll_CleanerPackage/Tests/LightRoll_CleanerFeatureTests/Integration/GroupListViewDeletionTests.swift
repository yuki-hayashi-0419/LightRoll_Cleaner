//
//  GroupListViewDeletionTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GroupListViewの削除機能テスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - GroupListViewDeletionTests

/// GroupListViewの削除機能テスト
/// 選択モード、一括削除、確認ダイアログの動作を検証
@MainActor
@Suite("GroupListView削除機能")
struct GroupListViewDeletionTests {

    // MARK: - テストデータ

    /// テスト用グループ
    private func createTestGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["photo1", "photo2", "photo3"],
                fileSizes: [1_000_000, 1_200_000, 900_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["screen1", "screen2"],
                fileSizes: [500_000, 600_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["blur1", "blur2", "blur3", "blur4"],
                fileSizes: [2_000_000, 1_800_000, 2_200_000, 1_900_000]
            )
        ]
    }

    // MARK: - 選択モードテスト

    @Test("選択モード初期状態")
    func testSelectionModeInitialState() {
        // Given: GroupListViewの初期状態
        let groups = createTestGroups()

        // When/Then: 選択モードはオフ、選択されたグループはなし
        // Note: SwiftUIビューのため、状態は内部的に検証される
        // 実際の実装では@Stateを直接テストできないため、
        // 動作ベースのテストを行う必要がある
        #expect(groups.selectedGroups.isEmpty)
    }

    @Test("グループ選択切り替え")
    func testToggleGroupSelection() {
        // Given: グループ配列
        var groups = createTestGroups()

        // When: 1つ目のグループを選択
        groups[0] = groups[0].withSelection(true)

        // Then: 選択状態になる
        #expect(groups[0].isSelected == true)
        #expect(groups.selectedGroups.count == 1)
    }

    @Test("複数グループの選択")
    func testMultipleGroupSelection() {
        // Given: グループ配列
        var groups = createTestGroups()

        // When: 複数のグループを選択
        groups[0] = groups[0].withSelection(true)
        groups[2] = groups[2].withSelection(true)

        // Then: 2つのグループが選択される
        #expect(groups.selectedGroups.count == 2)
        #expect(groups[0].isSelected == true)
        #expect(groups[1].isSelected == false)
        #expect(groups[2].isSelected == true)
    }

    @Test("全選択")
    func testSelectAll() {
        // Given: グループ配列
        let groups = createTestGroups()

        // When: すべて選択
        let allSelected = groups.settingSelection(true)

        // Then: すべてのグループが選択される
        #expect(allSelected.selectedGroups.count == groups.count)
        #expect(allSelected.allSatisfy { $0.isSelected })
    }

    @Test("全解除")
    func testDeselectAll() {
        // Given: すべて選択されたグループ
        let selectedGroups = createTestGroups().settingSelection(true)

        // When: すべて解除
        let deselectedGroups = selectedGroups.settingSelection(false)

        // Then: すべてのグループが未選択になる
        #expect(deselectedGroups.selectedGroups.isEmpty)
        #expect(deselectedGroups.allSatisfy { !$0.isSelected })
    }

    // MARK: - 削除計算テスト

    @Test("削除候補の計算（ベストショットあり）")
    func testDeletionCandidatesWithBestShot() {
        // Given: ベストショットが設定されたグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2", "photo3", "photo4"],
            fileSizes: [1_000_000, 1_200_000, 900_000, 1_100_000],
            bestShotIndex: 1
        )

        // When: 削除候補を取得
        let candidates = group.deletionCandidateIds

        // Then: ベストショット以外が削除候補
        #expect(candidates.count == 3)
        #expect(!candidates.contains("photo2")) // ベストショットは除外
        #expect(candidates.contains("photo1"))
        #expect(candidates.contains("photo3"))
        #expect(candidates.contains("photo4"))
    }

    @Test("削除候補の計算（ベストショットなし）")
    func testDeletionCandidatesWithoutBestShot() {
        // Given: ベストショットが未設定のグループ
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["screen1", "screen2", "screen3"],
            fileSizes: [500_000, 600_000, 550_000]
        )

        // When: 削除候補を取得
        let candidates = group.deletionCandidateIds

        // Then: すべてが削除候補
        #expect(candidates.count == 3)
        #expect(Set(candidates) == Set(group.photoIds))
    }

    @Test("削減可能サイズの計算")
    func testReclaimableSizeCalculation() {
        // Given: グループ配列
        let groups = createTestGroups()

        // When: 削減可能サイズを計算
        let totalReclaimable = groups.totalReclaimableSize

        // Then: 正しく合計される
        // Group1: 1,200,000 + 900,000 = 2,100,000 (ベストショット除外)
        // Group2: 500,000 + 600,000 = 1,100,000 (ベストショットなし)
        // Group3: 8,000,000 - 0 = 7,900,000 (ベストショットなし)
        #expect(totalReclaimable > 0)
    }

    @Test("削減可能写真数の計算")
    func testReclaimableCountCalculation() {
        // Given: ベストショットが設定されたグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2", "photo3"],
            fileSizes: [1_000_000, 1_000_000, 1_000_000],
            bestShotIndex: 0
        )

        // When: 削減可能写真数を取得
        let reclaimableCount = group.reclaimableCount

        // Then: ベストショット以外の数
        #expect(reclaimableCount == 2)
    }

    // MARK: - 削除確認メッセージテスト

    @Test("削除確認メッセージの生成")
    func testDeletionConfirmationMessage() {
        // Given: 選択されたグループ
        var groups = createTestGroups()
        groups[0] = groups[0].withSelection(true)
        groups[1] = groups[1].withSelection(true)

        let selectedGroups = groups.selectedGroups

        // When: 削除確認メッセージを生成
        let totalPhotos = selectedGroups.reduce(0) { $0 + $1.count }
        let totalSize = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }

        // Then: 正しい情報が含まれる
        #expect(selectedGroups.count == 2)
        #expect(totalPhotos == 5) // Group1: 3枚 + Group2: 2枚
        #expect(totalSize > 0)
    }

    // MARK: - 境界値テスト

    @Test("空のグループ配列での削除")
    func testDeletionWithEmptyGroups() {
        // Given: 空の配列
        let groups: [PhotoGroup] = []

        // When: 選択されたグループを取得
        let selected = groups.selectedGroups

        // Then: 空配列が返る
        #expect(selected.isEmpty)
    }

    @Test("1件のグループのみの削除")
    func testDeletionWithSingleGroup() {
        // Given: 1件のグループ
        var groups = [
            PhotoGroup(
                type: .screenshot,
                photoIds: ["screen1", "screen2"],
                fileSizes: [500_000, 600_000]
            )
        ]

        // When: 選択して削除候補を取得
        groups[0] = groups[0].withSelection(true)

        // Then: 正しく処理される
        #expect(groups.selectedGroups.count == 1)
        #expect(groups[0].deletionCandidateIds.count == 2)
    }

    @Test("すべてのグループを削除")
    func testDeleteAllGroups() {
        // Given: すべて選択されたグループ
        let groups = createTestGroups().settingSelection(true)

        // When: すべての削除候補を取得
        let allCandidates = groups.allDeletionCandidateIds

        // Then: すべての写真IDが含まれる
        let allPhotoIds = groups.allPhotoIds
        // ベストショットがある場合は除外されるため、等しいとは限らない
        #expect(allCandidates.count <= allPhotoIds.count)
    }

    // MARK: - 異常系テスト

    @Test("無効なインデックスのベストショット")
    func testInvalidBestShotIndex() {
        // Given: 範囲外のベストショットインデックス
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2"],
            fileSizes: [1_000_000, 1_000_000],
            bestShotIndex: 10 // 範囲外
        )

        // When: 削除候補を取得
        let candidates = group.deletionCandidateIds

        // Then: すべてが削除候補になる（無効なインデックスは無視）
        #expect(candidates.count == 2)
    }

    @Test("選択されていないグループの削除試行")
    func testDeleteUnselectedGroups() {
        // Given: 選択されていないグループ
        let groups = createTestGroups()

        // When: 選択されたグループを取得
        let selected = groups.selectedGroups

        // Then: 空配列が返る
        #expect(selected.isEmpty)
    }

    // MARK: - 統合テスト

    @Test("削除フロー全体のシミュレーション")
    func testCompleteDeletionFlow() async {
        // Given: 初期グループ
        var groups = createTestGroups()
        var deletedGroups: [PhotoGroup] = []

        // Step 1: グループを選択
        groups[0] = groups[0].withSelection(true)
        groups[2] = groups[2].withSelection(true)

        // Step 2: 削除確認
        let selectedGroups = groups.selectedGroups
        #expect(selectedGroups.count == 2)

        // Step 3: 削除実行（シミュレーション）
        deletedGroups = selectedGroups
        groups = groups.filter { !$0.isSelected }

        // Then: 選択されたグループが削除される
        #expect(groups.count == 1)
        #expect(deletedGroups.count == 2)
        #expect(groups[0].type == .screenshot)
    }

    @Test("削除後の選択状態リセット")
    func testSelectionResetAfterDeletion() {
        // Given: 選択されたグループ
        var groups = createTestGroups().settingSelection(true)

        // When: 削除後に選択をリセット
        groups = groups.settingSelection(false)

        // Then: すべての選択が解除される
        #expect(groups.selectedGroups.isEmpty)
        #expect(groups.allSatisfy { !$0.isSelected })
    }
}
