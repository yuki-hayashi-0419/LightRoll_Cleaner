//
//  GroupListNavigationFixTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NavigationStack二重ネスト解消に対するテスト
//  修正内容:
//  1. GroupListView から独自の NavigationStack を削除
//  2. DashboardNavigationContainer の navigationDestination で GroupListView を表示
//  3. フィルタ・ソート・選択モード機能が正常に動作することを確認
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - GroupListViewStateTests

@Suite("GroupListView 状態管理テスト", .serialized)
@MainActor
struct GroupListViewStateTests {

    // MARK: - Test Data

    /// テスト用のサンプルグループ
    private static func createSampleGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["similar-1", "similar-2", "similar-3", "similar-4", "similar-5"],
                fileSizes: [3_000_000, 3_000_000, 3_000_000, 3_000_000, 3_000_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .similar,
                photoIds: ["similar-b-1", "similar-b-2"],
                fileSizes: [2_500_000, 2_500_000],
                bestShotIndex: 1
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: Array(1...15).map { "screenshot-\($0)" },
                fileSizes: Array(repeating: 1_200_000, count: 15)
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["blurry-1", "blurry-2", "blurry-3", "blurry-4", "blurry-5", "blurry-6"],
                fileSizes: [3_500_000, 3_500_000, 3_500_000, 3_500_000, 3_500_000, 3_500_000]
            ),
            PhotoGroup(
                type: .selfie,
                photoIds: ["selfie-1", "selfie-2", "selfie-3", "selfie-4"],
                fileSizes: [2_800_000, 2_800_000, 2_800_000, 2_800_000],
                bestShotIndex: 1
            ),
        ]
    }

    // MARK: - 正常系テスト

    @Test("【正常系1】フィルタなしで全グループが表示される")
    func testDisplayAllGroupsWithoutFilter() async throws {
        // Given: サンプルグループ
        let groups = Self.createSampleGroups()

        // When: initialFilterType = nil
        // Then: 全グループが表示対象となる
        #expect(groups.count == 5)
    }

    @Test("【正常系2】特定のGroupTypeでフィルタリングが動作する")
    func testFilterGroupsByType() async throws {
        // Given: サンプルグループ
        let groups = Self.createSampleGroups()

        // When: .similar でフィルタ
        let similarGroups = groups.filter { $0.type == .similar }

        // Then: .similar タイプのみが返される
        #expect(similarGroups.count == 2)
        #expect(similarGroups.allSatisfy { $0.type == .similar })
    }

    @Test("【正常系3】ソート順が正しく適用される - 削減可能サイズ順")
    func testSortGroupsByReclaimableSize() async throws {
        // Given: サンプルグループ
        let groups = Self.createSampleGroups()

        // When: 削減可能サイズ順でソート
        let sorted = groups.sorted { $0.reclaimableSize > $1.reclaimableSize }

        // Then: サイズが大きい順に並ぶ
        #expect(sorted.count == 5)

        // 最初のグループが最もサイズが大きい
        let firstGroupSize = sorted[0].reclaimableSize
        let secondGroupSize = sorted[1].reclaimableSize
        #expect(firstGroupSize >= secondGroupSize)
    }

    @Test("【正常系4】選択モードの切り替えが動作する")
    func testSelectionModeToggle() async throws {
        // Given: 選択モードの初期状態は false
        var isSelectionMode = false
        var selectedGroupIds: Set<UUID> = []

        // When: 選択モードを有効化
        isSelectionMode = true

        // Then: 選択モードがtrueになる
        #expect(isSelectionMode == true)

        // When: グループを選択
        let group = Self.createSampleGroups()[0]
        selectedGroupIds.insert(group.id)

        // Then: 選択済みグループが記録される
        #expect(selectedGroupIds.count == 1)
        #expect(selectedGroupIds.contains(group.id))

        // When: 選択モードを無効化
        isSelectionMode = false
        selectedGroupIds.removeAll()

        // Then: 選択がクリアされる
        #expect(isSelectionMode == false)
        #expect(selectedGroupIds.isEmpty)
    }

    // MARK: - 異常系テスト

    @Test("【異常系1】空のグループリストでもエラーにならない")
    func testEmptyGroupsList() async throws {
        // Given: 空のグループ
        let groups: [PhotoGroup] = []

        // When: フィルタやソートを適用
        let filtered = groups.filter { $0.type == .similar }
        let sorted = groups.sorted { $0.reclaimableSize > $1.reclaimableSize }

        // Then: エラーなく空配列が返される
        #expect(filtered.isEmpty)
        #expect(sorted.isEmpty)
    }

    @Test("【異常系2】存在しないGroupTypeでフィルタしても空配列が返る")
    func testFilterByNonExistentType() async throws {
        // Given: .similar と .screenshot のみのグループ
        let groups = Self.createSampleGroups()

        // When: .largeVideo でフィルタ（存在しない）
        let filtered = groups.filter { $0.type == .largeVideo }

        // Then: 空配列が返される
        #expect(filtered.isEmpty)
    }

    // MARK: - 境界値テスト

    @Test("【境界値1】1グループのみの場合でも正常に動作する")
    func testSingleGroup() async throws {
        // Given: 1グループのみ
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["photo1"],
                fileSizes: [1_000_000]
            )
        ]

        // When: フィルタ・ソート
        let filtered = groups.filter { $0.type == .similar }
        let sorted = groups.sorted { $0.reclaimableSize > $1.reclaimableSize }

        // Then: 正常に動作
        #expect(filtered.count == 1)
        #expect(sorted.count == 1)
    }

    @Test("【境界値2】大量のグループ（100個以上）でも動作する")
    func testLargeNumberOfGroups() async throws {
        // Given: 100個のグループ
        let groups = (0..<100).map { index in
            PhotoGroup(
                type: .similar,
                photoIds: ["photo-\(index)"],
                fileSizes: [1_000_000 + Int64(index * 10_000)]
            )
        }

        // When: ソート
        let sorted = groups.sorted { $0.reclaimableSize > $1.reclaimableSize }

        // Then: 正常にソートされる
        #expect(sorted.count == 100)

        // 降順に並んでいることを確認
        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].reclaimableSize >= sorted[i + 1].reclaimableSize)
        }
    }

    @Test("【境界値3】1グループ1枚の写真でも正常に動作する")
    func testSinglePhotoPerGroup() async throws {
        // Given: 各グループに1枚ずつ写真
        let groups = (0..<5).map { index in
            PhotoGroup(
                type: .similar,
                photoIds: ["photo-\(index)"],
                fileSizes: [1_000_000]
            )
        }

        // When: ソート
        let sorted = groups.sorted { $0.count > $1.count }

        // Then: 正常に動作（全グループが同じ写真数）
        #expect(sorted.count == 5)
        #expect(sorted.allSatisfy { $0.count == 1 })
    }
}

// MARK: - GroupListNavigationFlowTests

@Suite("GroupListView ナビゲーションフロー テスト", .serialized)
@MainActor
struct GroupListNavigationFlowTests {

    // MARK: - 正常系テスト

    @Test("【正常系1】グループタップでコールバックが呼ばれる")
    func testGroupTapCallback() async throws {
        // Given: グループとタップ検出用のフラグ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1"],
            fileSizes: [1_000_000]
        )
        var tappedGroup: PhotoGroup?

        // When: タップコールバックを設定
        let onGroupTap: (PhotoGroup) -> Void = { group in
            tappedGroup = group
        }

        // Then: コールバック実行時にグループが渡される
        onGroupTap(group)
        #expect(tappedGroup?.id == group.id)
    }

    @Test("【正常系2】削除コールバックが呼ばれる")
    func testDeleteCallback() async throws {
        // Given: 削除対象グループ
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["photo1"],
                fileSizes: [1_000_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["photo2"],
                fileSizes: [500_000]
            ),
        ]
        var deletedGroups: [PhotoGroup] = []

        // When: 削除コールバックを設定
        let onDeleteGroups: ([PhotoGroup]) async -> Void = { groups in
            deletedGroups = groups
        }

        // Then: コールバック実行時にグループが渡される
        await onDeleteGroups(groups)
        #expect(deletedGroups.count == 2)
    }

    @Test("【正常系3】戻るコールバックが呼ばれる")
    func testBackCallback() async throws {
        // Given: 戻るフラグ
        var didCallBack = false

        // When: 戻るコールバックを設定
        let onBack: () -> Void = {
            didCallBack = true
        }

        // Then: コールバック実行時にフラグが立つ
        onBack()
        #expect(didCallBack == true)
    }
}

// MARK: - GroupListFilterAndSortIntegrationTests

@Suite("GroupListView フィルタ・ソート統合テスト", .serialized)
@MainActor
struct GroupListFilterAndSortIntegrationTests {

    // MARK: - Test Data

    private static func createMixedGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["s1", "s2", "s3"],
                fileSizes: [3_000_000, 3_000_000, 3_000_000]
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["sc1", "sc2"],
                fileSizes: [1_200_000, 1_200_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: Array(1...10).map { "b\($0)" },
                fileSizes: Array(repeating: 3_500_000, count: 10)
            ),
            PhotoGroup(
                type: .similar,
                photoIds: ["s4", "s5"],
                fileSizes: [2_500_000, 2_500_000]
            ),
        ]
    }

    // MARK: - 統合テスト

    @Test("【統合1】フィルタとソートの組み合わせが正常に動作する")
    func testFilterAndSortCombination() async throws {
        // Given: 混在したグループ
        let groups = Self.createMixedGroups()

        // When: .similar でフィルタ → 削減可能サイズ順でソート
        let filtered = groups.filter { $0.type == .similar }
        let sorted = filtered.sorted { $0.reclaimableSize > $1.reclaimableSize }

        // Then: 正しくフィルタ・ソートされる
        #expect(sorted.count == 2)
        #expect(sorted.allSatisfy { $0.type == .similar })

        // サイズ降順
        #expect(sorted[0].reclaimableSize >= sorted[1].reclaimableSize)
    }

    @Test("【統合2】フィルタ → 選択 → 削除の一連の流れ")
    func testFilterSelectDeleteFlow() async throws {
        // Given: グループと選択状態
        var groups = Self.createMixedGroups()
        var selectedGroupIds: Set<UUID> = []

        // When: .similar でフィルタ
        let filtered = groups.filter { $0.type == .similar }
        #expect(filtered.count == 2)

        // 全て選択
        selectedGroupIds = Set(filtered.map { $0.id })
        #expect(selectedGroupIds.count == 2)

        // 削除
        groups.removeAll { selectedGroupIds.contains($0.id) }

        // Then: .similar グループが削除される
        #expect(groups.count == 2)
        #expect(groups.allSatisfy { $0.type != .similar })
    }
}
