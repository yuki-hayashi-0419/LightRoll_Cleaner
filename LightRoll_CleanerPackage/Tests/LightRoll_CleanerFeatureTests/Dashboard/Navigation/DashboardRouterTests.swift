//
//  DashboardRouterTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DashboardRouterのテスト
//  ナビゲーションパスの管理をテスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - DashboardRouterTests

@Suite("DashboardRouter Tests", .serialized)
@MainActor
struct DashboardRouterTests {

    // MARK: - Initialization Tests

    @Test("初期化時にパスが空であること")
    func testInitialState() async {
        // Given & When
        let router = DashboardRouter()

        // Then
        #expect(router.path.isEmpty)
        #expect(router.onNavigateToSettings == nil)
    }

    @Test("設定コールバック付きで初期化できること")
    func testInitializationWithCallback() async {
        // Given
        var settingsCalled = false

        // When
        let router = DashboardRouter(onNavigateToSettings: {
            settingsCalled = true
        })

        router.navigateToSettings()

        // Then
        #expect(router.onNavigateToSettings != nil)
        #expect(settingsCalled)
    }

    // MARK: - Navigation Tests

    @Test("グループリスト画面へ遷移できること（全タイプ）")
    func testNavigateToGroupList() async {
        // Given
        let router = DashboardRouter()

        // When
        router.navigateToGroupList()

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupList)
    }

    @Test("グループリスト画面へ遷移できること（フィルタ付き）")
    func testNavigateToGroupListWithFilter() async {
        // Given
        let router = DashboardRouter()

        // When
        router.navigateToGroupList(filterType: .similar)

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupListFiltered(.similar))
    }

    @Test("グループ詳細画面へ遷移できること")
    func testNavigateToGroupDetail() async {
        // Given
        let router = DashboardRouter()
        let groupId = UUID()

        // When
        router.navigateToGroupDetail(groupId: groupId)

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupDetail(groupId))
    }

    @Test("複数の画面に連続して遷移できること")
    func testNavigateMultipleScreens() async {
        // Given
        let router = DashboardRouter()
        let groupId = UUID()

        // When
        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: groupId)

        // Then
        #expect(router.path.count == 2)
        #expect(router.path[0] == .groupList)
        #expect(router.path[1] == .groupDetail(groupId))
    }

    // MARK: - Back Navigation Tests

    @Test("前の画面に戻れること")
    func testNavigateBack() async {
        // Given
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupList(filterType: .blurry)

        // When
        router.navigateBack()

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupList)
    }

    @Test("パスが空の状態で戻る操作をしても何も起きないこと")
    func testNavigateBackWhenEmpty() async {
        // Given
        let router = DashboardRouter()

        // When
        router.navigateBack()

        // Then
        #expect(router.path.isEmpty)
    }

    @Test("ルート画面に戻れること")
    func testNavigateToRoot() async {
        // Given
        let router = DashboardRouter()
        let groupId = UUID()

        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: groupId)

        // When
        router.navigateToRoot()

        // Then
        #expect(router.path.isEmpty)
    }

    @Test("指定した画面まで戻れること")
    func testNavigateBackToDestination() async {
        // Given
        let router = DashboardRouter()
        let groupId1 = UUID()
        let groupId2 = UUID()

        router.navigateToGroupList()
        router.navigateToGroupDetail(groupId: groupId1)
        router.navigateToGroupDetail(groupId: groupId2)

        // When
        router.navigateBackTo(.groupList)

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupList)
    }

    @Test("存在しない画面への戻り操作では何も起きないこと")
    func testNavigateBackToNonExistentDestination() async {
        // Given
        let router = DashboardRouter()
        let groupId = UUID()

        router.navigateToGroupList()

        // When
        router.navigateBackTo(.groupDetail(groupId))

        // Then
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupList)
    }

    // MARK: - Settings Navigation Tests

    @Test("設定画面への遷移コールバックが呼ばれること")
    func testNavigateToSettings() async {
        // Given
        var settingsCalled = false
        let router = DashboardRouter(onNavigateToSettings: {
            settingsCalled = true
        })

        // When
        router.navigateToSettings()

        // Then
        #expect(settingsCalled)
    }

    @Test("設定コールバックが未設定の場合でもクラッシュしないこと")
    func testNavigateToSettingsWithoutCallback() async {
        // Given
        let router = DashboardRouter()

        // When & Then (クラッシュしないことを確認)
        router.navigateToSettings()
        #expect(true)
    }

    // MARK: - Path Manipulation Tests

    @Test("パスを直接操作できること")
    func testDirectPathManipulation() async {
        // Given
        let router = DashboardRouter()

        // When
        router.path = [.groupList, .groupListFiltered(.similar)]

        // Then
        #expect(router.path.count == 2)
    }

    @Test("パスをクリアできること")
    func testClearPath() async {
        // Given
        let router = DashboardRouter()
        router.navigateToGroupList()
        router.navigateToGroupList(filterType: .blurry)

        // When
        router.path.removeAll()

        // Then
        #expect(router.path.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("同じ画面に連続して遷移できること")
    func testNavigateToSameScreenMultipleTimes() async {
        // Given
        let router = DashboardRouter()

        // When
        router.navigateToGroupList()
        router.navigateToGroupList()

        // Then
        #expect(router.path.count == 2)
        #expect(router.path.allSatisfy { $0 == .groupList })
    }

    @Test("異なるフィルタタイプで連続遷移できること")
    func testNavigateWithDifferentFilters() async {
        // Given
        let router = DashboardRouter()

        // When
        router.navigateToGroupList(filterType: .similar)
        router.navigateToGroupList(filterType: .screenshot)
        router.navigateToGroupList(filterType: .blurry)

        // Then
        #expect(router.path.count == 3)
        #expect(router.path[0] == .groupListFiltered(.similar))
        #expect(router.path[1] == .groupListFiltered(.screenshot))
        #expect(router.path[2] == .groupListFiltered(.blurry))
    }
}

// MARK: - DashboardDestination Tests

@Suite("DashboardDestination Tests", .serialized)
struct DashboardDestinationTests {

    @Test("グループリスト遷移先の等価性判定")
    func testGroupListEquality() async {
        // Given
        let dest1 = DashboardDestination.groupList
        let dest2 = DashboardDestination.groupList

        // Then
        #expect(dest1 == dest2)
    }

    @Test("フィルタ付きグループリスト遷移先の等価性判定")
    func testGroupListFilteredEquality() async {
        // Given
        let dest1 = DashboardDestination.groupListFiltered(.similar)
        let dest2 = DashboardDestination.groupListFiltered(.similar)
        let dest3 = DashboardDestination.groupListFiltered(.screenshot)

        // Then
        #expect(dest1 == dest2)
        #expect(dest1 != dest3)
    }

    @Test("グループ詳細遷移先の等価性判定")
    func testGroupDetailEquality() async {
        // Given
        let groupId = UUID()

        let dest1 = DashboardDestination.groupDetail(groupId)
        let dest2 = DashboardDestination.groupDetail(groupId)
        let dest3 = DashboardDestination.groupDetail(UUID())

        // Then
        // 同じグループIDを使用しているため等価
        #expect(dest1 == dest2)
        // 異なるグループIDは非等価
        #expect(dest1 != dest3)
    }

    @Test("異なる遷移先の非等価性判定")
    func testDifferentDestinationsNotEqual() async {
        // Given
        let dest1 = DashboardDestination.groupList
        let dest2 = DashboardDestination.groupListFiltered(.similar)
        let dest3 = DashboardDestination.settings

        // Then
        #expect(dest1 != dest2)
        #expect(dest1 != dest3)
        #expect(dest2 != dest3)
    }

    @Test("設定遷移先の等価性判定")
    func testSettingsEquality() async {
        // Given
        let dest1 = DashboardDestination.settings
        let dest2 = DashboardDestination.settings

        // Then
        #expect(dest1 == dest2)
    }

    @Test("Hashableプロトコル準拠")
    func testHashable() async {
        // Given
        let dest1 = DashboardDestination.groupList
        let dest2 = DashboardDestination.groupListFiltered(.similar)
        let dest3 = DashboardDestination.settings

        // When
        var set: Set<DashboardDestination> = []
        set.insert(dest1)
        set.insert(dest2)
        set.insert(dest3)

        // Then
        #expect(set.count == 3)
        #expect(set.contains(dest1))
        #expect(set.contains(dest2))
        #expect(set.contains(dest3))
    }
}
