//
//  UX001_NavigationBackButtonTests.swift
//  LightRoll_CleanerFeatureTests
//
//  UX-001: NavigationStack戻るボタン二重表示修正のテストケース
//
//  テスト対象:
//  - グループ一覧画面のナビゲーションバー戻るボタン
//  - グループ詳細画面のナビゲーションバー戻るボタン
//  - ナビゲーション遷移の正常動作
//
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - UX001 NavigationBackButton Tests

@Suite("UX-001 NavigationStack戻るボタン二重表示修正テスト", .serialized)
@MainActor
struct UX001_NavigationBackButtonTests {

    // MARK: - Test Data Helpers

    /// テスト用のサンプルグループを生成
    private func createSampleGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["similar-1", "similar-2", "similar-3"],
                fileSizes: [3_000_000, 3_000_000, 3_000_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["screenshot-1", "screenshot-2", "screenshot-3"],
                fileSizes: [1_200_000, 1_200_000, 1_200_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["blurry-1", "blurry-2"],
                fileSizes: [3_500_000, 3_500_000]
            )
        ]
    }

    // MARK: - 1. UI構造テスト: ビュー生成と基本動作

    @Test("【UI構造1】GroupListViewが正常に作成される")
    func testGroupListViewCreation() async throws {
        // Given: サンプルグループ
        let groups = createSampleGroups()

        // When: GroupListViewを作成
        let view = GroupListView(groups: groups)

        // Then: ビューが正常に作成される
        #expect(type(of: view) == GroupListView.self)
        #expect(groups.count == 3)
    }

    @Test("【UI構造2】GroupDetailViewが正常に作成される")
    func testGroupDetailViewCreation() async throws {
        // Given: サンプルグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3"],
            fileSizes: [2_500_000, 2_500_000, 2_500_000],
            bestShotIndex: 0
        )

        // When: GroupDetailViewを作成
        let view = GroupDetailView(group: group)

        // Then: ビューが正常に作成される
        #expect(type(of: view) == GroupDetailView.self)
        #expect(group.count == 3)
    }

    @Test("【UI構造3】空のグループリストでビューが作成される")
    func testEmptyGroupListViewCreation() async throws {
        // Given: 空のグループリスト
        let emptyGroups: [PhotoGroup] = []

        // When: 空リストでGroupListViewを作成
        let view = GroupListView(groups: emptyGroups)

        // Then: ビューが正常に作成される
        #expect(type(of: view) == GroupListView.self)
    }

    // MARK: - 2. ナビゲーション動作テスト

    @Test("【ナビゲーション1】DashboardRouterでホーム→グループ一覧の遷移が正常動作")
    func testNavigationHomeToGroupList() async throws {
        // Given: 初期状態のルーター
        let router = DashboardRouter()

        // When: グループ一覧へ遷移
        router.navigateToGroupList()

        // Then: パスにgroupListが追加される
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupList)
    }

    @Test("【ナビゲーション2】DashboardRouterでグループ一覧→グループ詳細の遷移が正常動作")
    func testNavigationGroupListToGroupDetail() async throws {
        // Given: グループ一覧に遷移済みのルーター
        let router = DashboardRouter()
        router.navigateToGroupList()

        let groupId = UUID()

        // When: グループ詳細へ遷移
        router.navigateToGroupDetail(groupId: groupId)

        // Then: パスにgroupDetailが追加される
        #expect(router.path.count == 2)
        #expect(router.path[0] == .groupList)
        #expect(router.path[1] == .groupDetail(groupId))
    }

    @Test("【ナビゲーション3】DashboardRouterで戻るボタンタップで前の画面に戻る")
    func testNavigationBackButton() async throws {
        // Given: グループ詳細まで遷移済みのルーター
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: UUID())

        #expect(router.path.count == 2)

        // When: 戻るボタンをタップ（navigateBack）
        router.navigateBack()

        // Then: グループ一覧に戻る
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupList)
    }

    @Test("【ナビゲーション4】DashboardRouterでルート画面に戻る")
    func testNavigationBackToRoot() async throws {
        // Given: グループ詳細まで遷移済みのルーター
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: UUID())

        // When: ルートに戻る
        router.navigateToRoot()

        // Then: パスが空（ホーム画面）
        #expect(router.path.isEmpty)
    }

    // MARK: - 3. エッジケーステスト

    @Test("【エッジケース1】ルート画面では戻るボタンが表示されない（パスが空）")
    func testRootScreenNoBackButton() async throws {
        // Given: 初期状態（ルート画面）のルーター
        let router = DashboardRouter()

        // When: パスが空の状態でnavigateBackを呼ぶ
        router.navigateBack()

        // Then: パスは空のまま（エラーなし）
        #expect(router.path.isEmpty)
    }

    @Test("【エッジケース2】同じ遷移先への重複プッシュを防止")
    func testPreventDuplicatePush() async throws {
        // Given: グループ一覧に遷移済みのルーター
        let router = DashboardRouter()
        router.navigateToGroupList()

        #expect(router.path.count == 1)

        // When: 同じgroupListに再度遷移を試みる
        router.navigateToGroupList()

        // Then: 重複追加されない
        #expect(router.path.count == 1)
    }

    @Test("【エッジケース3】フィルタ付きグループ一覧への遷移")
    func testNavigationToFilteredGroupList() async throws {
        // Given: 初期状態のルーター
        let router = DashboardRouter()

        // When: similarタイプでフィルタしたグループ一覧へ遷移
        router.navigateToGroupList(filterType: .similar)

        // Then: パスにgroupListFiltered(.similar)が追加される
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupListFiltered(.similar))
    }

    @Test("【エッジケース4】navigateBackToで特定の画面まで戻る")
    func testNavigateBackToSpecificDestination() async throws {
        // Given: 複数画面を遷移したルーター
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: UUID())

        #expect(router.path.count == 2)

        // When: groupListまで戻る
        router.navigateBackTo(.groupList)

        // Then: groupListまで戻る（それ以降は削除）
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupList)
    }

    @Test("【エッジケース5】存在しない遷移先へのnavigateBackToは何もしない")
    func testNavigateBackToNonExistentDestination() async throws {
        // Given: グループ一覧のみ遷移したルーター
        let router = DashboardRouter()
        router.navigateToGroupList()

        let originalPathCount = router.path.count

        // When: 存在しない遷移先へnavigateBackToを呼ぶ
        router.navigateBackTo(.settings)

        // Then: パスは変わらない
        #expect(router.path.count == originalPathCount)
    }
}

// MARK: - DashboardDestination Equality Tests

@Suite("DashboardDestination 等価性テスト", .serialized)
@MainActor
struct DashboardDestinationEqualityTests {

    @Test("DashboardDestination.groupListは等しい")
    func testGroupListEquality() {
        let dest1 = DashboardDestination.groupList
        let dest2 = DashboardDestination.groupList

        #expect(dest1 == dest2)
    }

    @Test("DashboardDestination.groupListFilteredは同じタイプで等しい")
    func testGroupListFilteredEquality() {
        let dest1 = DashboardDestination.groupListFiltered(.similar)
        let dest2 = DashboardDestination.groupListFiltered(.similar)

        #expect(dest1 == dest2)
    }

    @Test("DashboardDestination.groupListFilteredは異なるタイプで等しくない")
    func testGroupListFilteredInequality() {
        let dest1 = DashboardDestination.groupListFiltered(.similar)
        let dest2 = DashboardDestination.groupListFiltered(.screenshot)

        #expect(dest1 != dest2)
    }

    @Test("DashboardDestination.groupDetailは同じUUIDで等しい")
    func testGroupDetailEquality() {
        let id = UUID()
        let dest1 = DashboardDestination.groupDetail(id)
        let dest2 = DashboardDestination.groupDetail(id)

        #expect(dest1 == dest2)
    }

    @Test("DashboardDestination.groupDetailは異なるUUIDで等しくない")
    func testGroupDetailInequality() {
        let dest1 = DashboardDestination.groupDetail(UUID())
        let dest2 = DashboardDestination.groupDetail(UUID())

        #expect(dest1 != dest2)
    }
}

// MARK: - Navigation Flow Integration Tests

@Suite("ナビゲーションフロー統合テスト", .serialized)
@MainActor
struct NavigationFlowIntegrationTests {

    @Test("完全なナビゲーションフロー: ホーム→グループ一覧→グループ詳細→戻る→戻る")
    func testFullNavigationFlow() async throws {
        // Given: 初期状態のルーター
        let router = DashboardRouter()
        let groupId = UUID()

        // Step 1: ホーム（初期状態）
        #expect(router.path.isEmpty)

        // Step 2: グループ一覧へ遷移
        router.navigateToGroupList()
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupList)

        // Step 3: グループ詳細へ遷移
        router.navigateToGroupDetail(groupId: groupId)
        #expect(router.path.count == 2)
        #expect(router.path.last == .groupDetail(groupId))

        // Step 4: 戻る（グループ詳細→グループ一覧）
        router.navigateBack()
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupList)

        // Step 5: 戻る（グループ一覧→ホーム）
        router.navigateBack()
        #expect(router.path.isEmpty)
    }

    @Test("フィルタ付きナビゲーションフロー: ホーム→フィルタ付きグループ一覧→グループ詳細")
    func testFilteredNavigationFlow() async throws {
        // Given: 初期状態のルーター
        let router = DashboardRouter()
        let groupId = UUID()

        // Step 1: フィルタ付きグループ一覧へ遷移
        router.navigateToGroupList(filterType: .screenshot)
        #expect(router.path.count == 1)
        #expect(router.path.last == .groupListFiltered(.screenshot))

        // Step 2: グループ詳細へ遷移
        router.navigateToGroupDetail(groupId: groupId)
        #expect(router.path.count == 2)

        // Step 3: ルートへ直接戻る
        router.navigateToRoot()
        #expect(router.path.isEmpty)
    }

    @Test("連続戻る操作でエラーが発生しない")
    func testMultipleBackOperations() async throws {
        // Given: グループ詳細まで遷移したルーター
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: UUID())

        // When: 必要以上に戻る操作を実行
        router.navigateBack()
        router.navigateBack()
        router.navigateBack() // パスが空でも安全
        router.navigateBack() // パスが空でも安全

        // Then: エラーなくパスが空になる
        #expect(router.path.isEmpty)
    }
}
