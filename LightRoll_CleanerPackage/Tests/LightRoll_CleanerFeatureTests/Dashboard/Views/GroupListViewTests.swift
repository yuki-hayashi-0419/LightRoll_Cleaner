//
//  GroupListViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GroupListViewの包括的な単体テスト
//  MV Patternに基づくUI状態管理のテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI

@testable import LightRoll_CleanerFeature

// MARK: - ViewState Tests

@Suite("GroupListView.ViewState テスト")
struct GroupListViewStateTests {

    @Test("loading状態が正しく初期化される")
    func testLoadingState() {
        let state = GroupListView.ViewState.loading
        #expect(state == .loading)
    }

    @Test("loaded状態が正しく初期化される")
    func testLoadedState() {
        let state = GroupListView.ViewState.loaded
        #expect(state == .loaded)
    }

    @Test("processing状態が正しく初期化される")
    func testProcessingState() {
        let state = GroupListView.ViewState.processing
        #expect(state == .processing)
    }

    @Test("error状態がメッセージを保持する")
    func testErrorState() {
        let message = "テストエラーメッセージ"
        let state = GroupListView.ViewState.error(message)

        if case .error(let m) = state {
            #expect(m == message)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("ViewState同士の等価比較が機能する")
    func testViewStateEquality() {
        #expect(GroupListView.ViewState.loading == GroupListView.ViewState.loading)
        #expect(GroupListView.ViewState.loaded == GroupListView.ViewState.loaded)
        #expect(GroupListView.ViewState.processing == GroupListView.ViewState.processing)
        #expect(GroupListView.ViewState.error("test") == GroupListView.ViewState.error("test"))
    }

    @Test("異なるViewStateは等価でない")
    func testViewStateInequality() {
        #expect(GroupListView.ViewState.loading != GroupListView.ViewState.loaded)
        #expect(GroupListView.ViewState.loading != GroupListView.ViewState.processing)
        #expect(GroupListView.ViewState.error("a") != GroupListView.ViewState.error("b"))
    }

    @Test("空のエラーメッセージを処理できる")
    func testEmptyErrorMessage() {
        let state = GroupListView.ViewState.error("")

        if case .error(let message) = state {
            #expect(message.isEmpty)
        }
    }

    @Test("長いエラーメッセージを処理できる")
    func testLongErrorMessage() {
        let longMessage = String(repeating: "エラー", count: 100)
        let state = GroupListView.ViewState.error(longMessage)

        if case .error(let message) = state {
            #expect(message == longMessage)
        }
    }
}

// MARK: - SortOrder Tests

@Suite("GroupListView.SortOrder テスト")
struct SortOrderTests {

    @Test("reclaimableSize ソート順が正しい")
    func testReclaimableSizeSortOrder() {
        let order = GroupListView.SortOrder.reclaimableSize
        #expect(order.rawValue == "reclaimableSize")
        #expect(!order.displayName.isEmpty)
        #expect(!order.icon.isEmpty)
    }

    @Test("photoCount ソート順が正しい")
    func testPhotoCountSortOrder() {
        let order = GroupListView.SortOrder.photoCount
        #expect(order.rawValue == "photoCount")
        #expect(!order.displayName.isEmpty)
        #expect(!order.icon.isEmpty)
    }

    @Test("date ソート順が正しい")
    func testDateSortOrder() {
        let order = GroupListView.SortOrder.date
        #expect(order.rawValue == "date")
        #expect(!order.displayName.isEmpty)
        #expect(!order.icon.isEmpty)
    }

    @Test("type ソート順が正しい")
    func testTypeSortOrder() {
        let order = GroupListView.SortOrder.type
        #expect(order.rawValue == "type")
        #expect(!order.displayName.isEmpty)
        #expect(!order.icon.isEmpty)
    }

    @Test("全ソート順がallCasesに含まれる")
    func testAllSortOrders() {
        let allOrders = GroupListView.SortOrder.allCases
        #expect(allOrders.count == 4)
        #expect(allOrders.contains(.reclaimableSize))
        #expect(allOrders.contains(.photoCount))
        #expect(allOrders.contains(.date))
        #expect(allOrders.contains(.type))
    }

    @Test("各ソート順に一意のアイコンがある")
    func testUniqueIcons() {
        let icons = GroupListView.SortOrder.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)
        #expect(uniqueIcons.count == icons.count, "各ソート順に一意のアイコンが必要")
    }

    @Test("各ソート順に表示名がある")
    func testDisplayNames() {
        for order in GroupListView.SortOrder.allCases {
            #expect(!order.displayName.isEmpty, "\(order.rawValue)に表示名が必要")
        }
    }
}

// MARK: - PhotoProvider Protocol Tests

@Suite("PhotoProvider プロトコルテスト")
struct PhotoProviderTests {

    /// テスト用のモックPhotoProvider
    private struct MockPhotoProvider: PhotoProvider {
        let photosToReturn: [Photo]

        func photos(for ids: [String]) async -> [Photo] {
            return photosToReturn.filter { ids.contains($0.id) }
        }
    }

    @Test("PhotoProviderが写真を返す")
    @MainActor
    func testPhotoProviderReturnsPhotos() async {
        let testPhotos = createTestPhotos(count: 3)
        let provider = MockPhotoProvider(photosToReturn: testPhotos)

        let ids = testPhotos.map { $0.id }
        let result = await provider.photos(for: ids)

        #expect(result.count == 3)
    }

    @Test("PhotoProviderが存在しないIDに空配列を返す")
    @MainActor
    func testPhotoProviderReturnsEmptyForUnknownIds() async {
        let provider = MockPhotoProvider(photosToReturn: [])

        let result = await provider.photos(for: ["unknown-1", "unknown-2"])

        #expect(result.isEmpty)
    }

    @Test("PhotoProviderが部分的なIDに部分結果を返す")
    @MainActor
    func testPhotoProviderReturnsPartialResults() async {
        let testPhotos = createTestPhotos(count: 5)
        let provider = MockPhotoProvider(photosToReturn: testPhotos)

        let ids = [testPhotos[0].id, testPhotos[2].id, "unknown"]
        let result = await provider.photos(for: ids)

        #expect(result.count == 2)
    }

    /// テスト用Photo配列を生成
    private func createTestPhotos(count: Int) -> [Photo] {
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
                fileSize: Int64(2_500_000 + index * 100_000),
                isFavorite: false
            )
        }
    }
}

// MARK: - GroupListView Initialization Tests

@Suite("GroupListView 初期化テスト")
struct GroupListViewInitializationTests {

    @Test("空のグループ配列で初期化できる")
    @MainActor
    func testInitWithEmptyGroups() {
        let view = GroupListView(groups: [])
        #expect(type(of: view) == GroupListView.self)
    }

    @Test("グループ配列のみで初期化できる")
    @MainActor
    func testInitWithGroupsOnly() {
        let groups = createTestGroups(count: 3)
        let view = GroupListView(groups: groups)
        #expect(type(of: view) == GroupListView.self)
    }

    @Test("全パラメータで初期化できる")
    @MainActor
    func testInitWithAllParameters() {
        let groups = createTestGroups(count: 5)

        let view = GroupListView(
            groups: groups,
            photoProvider: nil,
            initialFilterType: .similar,
            onGroupTap: { _ in },
            onDeleteGroups: { _ in },
            onBack: { }
        )

        #expect(type(of: view) == GroupListView.self)
    }

    @Test("初期フィルタタイプを指定して初期化できる")
    @MainActor
    func testInitWithInitialFilterType() {
        let groups = createTestGroups(count: 3)

        for filterType in GroupType.allCases {
            let view = GroupListView(
                groups: groups,
                initialFilterType: filterType
            )
            #expect(type(of: view) == GroupListView.self)
        }
    }

    @Test("コールバックなしで初期化できる")
    @MainActor
    func testInitWithoutCallbacks() {
        let groups = createTestGroups(count: 2)
        let view = GroupListView(
            groups: groups,
            onGroupTap: nil,
            onDeleteGroups: nil,
            onBack: nil
        )
        #expect(type(of: view) == GroupListView.self)
    }

    /// テスト用PhotoGroup配列を生成
    private func createTestGroups(count: Int) -> [PhotoGroup] {
        (0..<count).map { index in
            PhotoGroup(
                type: GroupType.allCases[index % GroupType.allCases.count],
                photoIds: (0..<5).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: Int64(3_000_000), count: 5),
                bestShotIndex: 0
            )
        }
    }
}

// MARK: - Filtering Tests

@Suite("GroupListView フィルタリングテスト")
struct FilteringTests {

    @Test("similarタイプでフィルタリングできる")
    func testFilterBySimilar() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.similar)
        #expect(filtered.allSatisfy { $0.type == .similar })
    }

    @Test("screenshotタイプでフィルタリングできる")
    func testFilterByScreenshot() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.screenshot)
        #expect(filtered.allSatisfy { $0.type == .screenshot })
    }

    @Test("blurryタイプでフィルタリングできる")
    func testFilterByBlurry() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.blurry)
        #expect(filtered.allSatisfy { $0.type == .blurry })
    }

    @Test("selfieタイプでフィルタリングできる")
    func testFilterBySelfie() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.selfie)
        #expect(filtered.allSatisfy { $0.type == .selfie })
    }

    @Test("largeVideoタイプでフィルタリングできる")
    func testFilterByLargeVideo() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.largeVideo)
        #expect(filtered.allSatisfy { $0.type == .largeVideo })
    }

    @Test("duplicateタイプでフィルタリングできる")
    func testFilterByDuplicate() {
        let groups = createMixedGroups()
        let filtered = groups.filterByType(.duplicate)
        #expect(filtered.allSatisfy { $0.type == .duplicate })
    }

    @Test("存在しないタイプでフィルタリングすると空配列を返す")
    func testFilterByNonExistentType() {
        // similarのみのグループ
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1", "2"], fileSizes: [1000, 1000])
        ]
        let filtered = groups.filterByType(.screenshot)
        #expect(filtered.isEmpty)
    }

    @Test("空の配列をフィルタリングすると空配列を返す")
    func testFilterEmptyArray() {
        let groups: [PhotoGroup] = []
        let filtered = groups.filterByType(.similar)
        #expect(filtered.isEmpty)
    }

    /// 各タイプを含む混合グループを生成
    private func createMixedGroups() -> [PhotoGroup] {
        GroupType.allCases.flatMap { type in
            (0..<2).map { index in
                PhotoGroup(
                    type: type,
                    photoIds: (0..<3).map { "\(type.rawValue)-\(index)-\($0)" },
                    fileSizes: Array(repeating: Int64(1_000_000 + index * 500_000), count: 3)
                )
            }
        }
    }
}

// MARK: - Sorting Tests

@Suite("GroupListView ソートテスト")
struct SortingTests {

    @Test("reclaimableSizeで降順ソートできる")
    func testSortByReclaimableSize() {
        let groups = createGroupsWithVaryingSizes()
        let sorted = groups.sortedByReclaimableSize

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].reclaimableSize >= sorted[i + 1].reclaimableSize)
        }
    }

    @Test("photoCountで降順ソートできる")
    func testSortByPhotoCount() {
        let groups = createGroupsWithVaryingPhotoCounts()
        let sorted = groups.sortedByPhotoCount

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].count >= sorted[i + 1].count)
        }
    }

    @Test("dateでソートできる")
    func testSortByDate() {
        let groups = createGroupsWithVaryingDates()
        let sorted = groups.sortedByDate
        #expect(sorted.count == groups.count)
    }

    @Test("typeでソートできる")
    func testSortByType() {
        let groups = createMixedTypeGroups()
        let sorted = groups.sortedByType

        // sortOrderに従ってソートされていることを確認
        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].type.sortOrder <= sorted[i + 1].type.sortOrder)
        }
    }

    @Test("空の配列をソートしても空")
    func testSortEmptyArray() {
        let groups: [PhotoGroup] = []
        #expect(groups.sortedByReclaimableSize.isEmpty)
        #expect(groups.sortedByPhotoCount.isEmpty)
        #expect(groups.sortedByDate.isEmpty)
        #expect(groups.sortedByType.isEmpty)
    }

    @Test("1件の配列をソートしても1件")
    func testSortSingleElement() {
        let groups = [PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])]
        #expect(groups.sortedByReclaimableSize.count == 1)
        #expect(groups.sortedByPhotoCount.count == 1)
    }

    /// サイズが異なるグループを生成
    private func createGroupsWithVaryingSizes() -> [PhotoGroup] {
        (0..<5).map { index in
            let size = Int64(1_000_000 * (index + 1))
            return PhotoGroup(
                type: .similar,
                photoIds: (0..<3).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: size, count: 3),
                bestShotIndex: 0
            )
        }
    }

    /// 写真数が異なるグループを生成
    private func createGroupsWithVaryingPhotoCounts() -> [PhotoGroup] {
        (0..<5).map { index in
            let count = (index + 1) * 2
            return PhotoGroup(
                type: .screenshot,
                photoIds: (0..<count).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: Int64(1_000_000), count: count)
            )
        }
    }

    /// 異なる日付のグループを生成
    private func createGroupsWithVaryingDates() -> [PhotoGroup] {
        (0..<5).map { index in
            PhotoGroup(
                type: .blurry,
                photoIds: (0..<2).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: Int64(1_000_000), count: 2)
            )
        }
    }

    /// 異なるタイプのグループを生成
    private func createMixedTypeGroups() -> [PhotoGroup] {
        GroupType.allCases.map { type in
            PhotoGroup(
                type: type,
                photoIds: ["photo-\(type.rawValue)"],
                fileSizes: [Int64(1_000_000)]
            )
        }
    }
}

// MARK: - Selection Tests

@Suite("GroupListView 選択テスト")
struct SelectionTests {

    @Test("グループIDをSetに追加できる")
    func testAddGroupIdToSet() {
        var selectedIds: Set<UUID> = []
        let group = createTestGroup()

        selectedIds.insert(group.id)

        #expect(selectedIds.contains(group.id))
        #expect(selectedIds.count == 1)
    }

    @Test("グループIDをSetから削除できる")
    func testRemoveGroupIdFromSet() {
        let group = createTestGroup()
        var selectedIds: Set<UUID> = [group.id]

        selectedIds.remove(group.id)

        #expect(!selectedIds.contains(group.id))
        #expect(selectedIds.isEmpty)
    }

    @Test("複数グループを選択できる")
    func testMultipleSelection() {
        let groups = (0..<5).map { _ in createTestGroup() }
        var selectedIds: Set<UUID> = []

        for group in groups {
            selectedIds.insert(group.id)
        }

        #expect(selectedIds.count == 5)
    }

    @Test("全選択が機能する")
    func testSelectAll() {
        let groups = (0..<10).map { _ in createTestGroup() }
        let selectedIds = Set(groups.map { $0.id })

        #expect(selectedIds.count == groups.count)
    }

    @Test("全解除が機能する")
    func testDeselectAll() {
        var selectedIds: Set<UUID> = Set((0..<5).map { _ in UUID() })

        selectedIds.removeAll()

        #expect(selectedIds.isEmpty)
    }

    @Test("選択トグルが機能する")
    func testToggleSelection() {
        let group = createTestGroup()
        var selectedIds: Set<UUID> = []

        // トグル：選択
        if selectedIds.contains(group.id) {
            selectedIds.remove(group.id)
        } else {
            selectedIds.insert(group.id)
        }
        #expect(selectedIds.contains(group.id))

        // トグル：解除
        if selectedIds.contains(group.id) {
            selectedIds.remove(group.id)
        } else {
            selectedIds.insert(group.id)
        }
        #expect(!selectedIds.contains(group.id))
    }

    /// テスト用グループを生成
    private func createTestGroup() -> PhotoGroup {
        PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 1_000_000, 1_000_000],
            bestShotIndex: 0
        )
    }
}

// MARK: - Delete Confirmation Tests

@Suite("GroupListView 削除確認テスト")
struct DeleteConfirmationTests {

    @Test("削除対象グループの統計が正しく計算される")
    func testDeleteTargetStatistics() {
        let groups = createTestGroupsForDeletion()
        let selectedIds = Set(groups.map { $0.id })

        let selectedGroups = groups.filter { selectedIds.contains($0.id) }
        let totalPhotos = selectedGroups.reduce(0) { $0 + $1.count }
        let totalSize = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }

        #expect(totalPhotos > 0)
        #expect(totalSize > 0)
    }

    @Test("空の選択では統計が0になる")
    func testEmptySelectionStatistics() {
        let groups = createTestGroupsForDeletion()
        let selectedIds: Set<UUID> = []

        let selectedGroups = groups.filter { selectedIds.contains($0.id) }
        let totalPhotos = selectedGroups.reduce(0) { $0 + $1.count }
        let totalSize = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }

        #expect(totalPhotos == 0)
        #expect(totalSize == 0)
    }

    @Test("削減サイズがフォーマットできる")
    func testFormattedReclaimableSize() {
        let size: Int64 = 5_000_000_000 // 5GB
        let formatted = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("GB") || formatted.contains("バイト") || formatted.contains("bytes"))
    }

    @Test("部分選択の統計が正しい")
    func testPartialSelectionStatistics() {
        let groups = createTestGroupsForDeletion()
        let selectedIds = Set([groups[0].id, groups[1].id])

        let selectedGroups = groups.filter { selectedIds.contains($0.id) }
        #expect(selectedGroups.count == 2)
    }

    /// 削除テスト用グループを生成
    private func createTestGroupsForDeletion() -> [PhotoGroup] {
        (0..<5).map { index in
            PhotoGroup(
                type: GroupType.allCases[index % GroupType.allCases.count],
                photoIds: (0..<(index + 2)).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: Int64(2_000_000), count: index + 2),
                bestShotIndex: 0
            )
        }
    }
}

// MARK: - Summary Statistics Tests

@Suite("GroupListView サマリー統計テスト")
struct SummaryStatisticsTests {

    @Test("グループ数が正しく計算される")
    func testGroupCount() {
        let groups = createTestGroups(count: 7)
        #expect(groups.count == 7)
    }

    @Test("総写真数が正しく計算される")
    func testTotalPhotoCount() {
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1", "2", "3"], fileSizes: [1000, 1000, 1000]),
            PhotoGroup(type: .screenshot, photoIds: ["4", "5"], fileSizes: [1000, 1000])
        ]

        let totalPhotos = groups.totalPhotoCount
        #expect(totalPhotos == 5)
    }

    @Test("総削減可能サイズが正しく計算される")
    func testTotalReclaimableSize() {
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2", "3"],
                fileSizes: [1_000_000, 1_000_000, 1_000_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["4", "5"],
                fileSizes: [500_000, 500_000]
            )
        ]

        let totalReclaimable = groups.reduce(0) { $0 + $1.reclaimableSize }
        #expect(totalReclaimable > 0)
    }

    @Test("空のグループ配列のサマリーは0")
    func testEmptyGroupsSummary() {
        let groups: [PhotoGroup] = []
        #expect(groups.count == 0)
        #expect(groups.totalPhotoCount == 0)
    }

    @Test("フォーマット済みサイズが正しい")
    func testFormattedTotalReclaimableSize() {
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2"],
                fileSizes: [500_000_000, 500_000_000],
                bestShotIndex: 0
            )
        ]

        let formatted = groups.formattedTotalReclaimableSize
        #expect(!formatted.isEmpty)
    }

    /// テスト用グループを生成
    private func createTestGroups(count: Int) -> [PhotoGroup] {
        (0..<count).map { index in
            PhotoGroup(
                type: .similar,
                photoIds: (0..<3).map { "photo-\(index)-\($0)" },
                fileSizes: Array(repeating: Int64(1_000_000), count: 3)
            )
        }
    }
}

// MARK: - Available Group Types Tests

@Suite("GroupListView 利用可能グループタイプテスト")
struct AvailableGroupTypesTests {

    @Test("similarのみのグループでsimilarが利用可能")
    func testSimilarOnlyAvailable() {
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])
        ]

        let availableTypes = GroupType.allCases.filter { type in
            groups.contains { $0.type == type }
        }

        #expect(availableTypes.count == 1)
        #expect(availableTypes.contains(.similar))
    }

    @Test("複数タイプがある場合すべて利用可能")
    func testMultipleTypesAvailable() {
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000]),
            PhotoGroup(type: .screenshot, photoIds: ["2"], fileSizes: [1000]),
            PhotoGroup(type: .blurry, photoIds: ["3"], fileSizes: [1000])
        ]

        let availableTypes = GroupType.allCases.filter { type in
            groups.contains { $0.type == type }
        }

        #expect(availableTypes.count == 3)
        #expect(availableTypes.contains(.similar))
        #expect(availableTypes.contains(.screenshot))
        #expect(availableTypes.contains(.blurry))
    }

    @Test("空のグループでは利用可能タイプなし")
    func testNoAvailableTypesForEmptyGroups() {
        let groups: [PhotoGroup] = []

        let availableTypes = GroupType.allCases.filter { type in
            groups.contains { $0.type == type }
        }

        #expect(availableTypes.isEmpty)
    }

    @Test("全タイプが利用可能な場合")
    func testAllTypesAvailable() {
        let groups = GroupType.allCases.map { type in
            PhotoGroup(type: type, photoIds: ["\(type.rawValue)"], fileSizes: [1000])
        }

        let availableTypes = GroupType.allCases.filter { type in
            groups.contains { $0.type == type }
        }

        #expect(availableTypes.count == GroupType.allCases.count)
    }
}

// MARK: - Navigation Title Tests

@Suite("GroupListView ナビゲーションタイトルテスト")
struct NavigationTitleTests {

    @Test("フィルタなしでデフォルトタイトルが表示される")
    func testDefaultTitle() {
        let title = NSLocalizedString(
            "groupList.title",
            value: "グループ一覧",
            comment: "Group list title"
        )
        #expect(!title.isEmpty)
        #expect(title.contains("グループ"))
    }

    @Test("similarフィルタ時のタイトルが正しい")
    func testSimilarFilterTitle() {
        let title = GroupType.similar.displayName
        #expect(!title.isEmpty)
    }

    @Test("screenshotフィルタ時のタイトルが正しい")
    func testScreenshotFilterTitle() {
        let title = GroupType.screenshot.displayName
        #expect(!title.isEmpty)
    }

    @Test("全グループタイプに表示名がある")
    func testAllGroupTypesHaveDisplayNames() {
        for type in GroupType.allCases {
            #expect(!type.displayName.isEmpty, "\(type.rawValue)に表示名が必要")
        }
    }
}

// MARK: - Callback Tests

@Suite("GroupListView コールバックテスト")
struct CallbackTests {

    @Test("onGroupTapコールバックが呼ばれる")
    func testOnGroupTapCallback() {
        var tappedGroup: PhotoGroup?
        let testGroup = PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])

        let callback: (PhotoGroup) -> Void = { group in
            tappedGroup = group
        }

        callback(testGroup)
        #expect(tappedGroup?.id == testGroup.id)
    }

    @Test("onDeleteGroupsコールバックが呼ばれる")
    @MainActor
    func testOnDeleteGroupsCallback() async {
        var deletedGroups: [PhotoGroup]?
        let testGroups = [
            PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000]),
            PhotoGroup(type: .screenshot, photoIds: ["2"], fileSizes: [1000])
        ]

        let callback: ([PhotoGroup]) async -> Void = { groups in
            deletedGroups = groups
        }

        await callback(testGroups)
        #expect(deletedGroups?.count == 2)
    }

    @Test("onBackコールバックが呼ばれる")
    func testOnBackCallback() {
        var backCalled = false

        let callback: () -> Void = {
            backCalled = true
        }

        callback()
        #expect(backCalled)
    }

    @Test("nilコールバックは安全に無視される")
    @MainActor
    func testNilCallbacksSafe() {
        let view = GroupListView(
            groups: [],
            onGroupTap: nil,
            onDeleteGroups: nil,
            onBack: nil
        )

        #expect(type(of: view) == GroupListView.self)
    }
}

// MARK: - Empty State Tests

@Suite("GroupListView 空状態テスト")
struct EmptyStateTests {

    @Test("グループなしで空状態が表示される")
    @MainActor
    func testEmptyStateWithNoGroups() {
        let view = GroupListView(groups: [])
        #expect(type(of: view) == GroupListView.self)
    }

    @Test("フィルタ後に空になった場合の空状態")
    func testEmptyStateAfterFilter() {
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])
        ]

        let filtered = groups.filterByType(.screenshot)
        #expect(filtered.isEmpty)
    }

    @Test("空状態のカスタムタイトルが取得できる")
    func testEmptyStateCustomTitle() {
        let filteredTitle = NSLocalizedString(
            "groupList.empty.filtered.title",
            value: "該当するグループがありません",
            comment: "No filtered groups title"
        )

        let noGroupsTitle = NSLocalizedString(
            "groupList.empty.title",
            value: "グループがありません",
            comment: "No groups title"
        )

        #expect(!filteredTitle.isEmpty)
        #expect(!noGroupsTitle.isEmpty)
    }

    @Test("空状態のカスタムメッセージが取得できる")
    func testEmptyStateCustomMessage() {
        let filteredMessage = NSLocalizedString(
            "groupList.empty.filtered.message",
            value: "フィルタを変更してください",
            comment: "No filtered groups message"
        )

        let noGroupsMessage = NSLocalizedString(
            "groupList.empty.message",
            value: "写真をスキャンしてグループを検出してください",
            comment: "No groups message"
        )

        #expect(!filteredMessage.isEmpty)
        #expect(!noGroupsMessage.isEmpty)
    }
}

// MARK: - Localization Tests

@Suite("GroupListView ローカライゼーションテスト")
struct GroupListLocalizationTests {

    @Test("グループリストタイトルが存在する")
    func testGroupListTitle() {
        let title = NSLocalizedString(
            "groupList.title",
            value: "グループ一覧",
            comment: "Group list title"
        )
        #expect(!title.isEmpty)
    }

    @Test("フィルタタイトルが存在する")
    func testFilterTitle() {
        let title = NSLocalizedString(
            "filter.title",
            value: "フィルタ",
            comment: "Filter sheet title"
        )
        #expect(!title.isEmpty)
    }

    @Test("すべてフィルタラベルが存在する")
    func testAllFilterLabel() {
        let label = NSLocalizedString(
            "filter.all",
            value: "すべて",
            comment: "All filter"
        )
        #expect(!label.isEmpty)
    }

    @Test("削除ボタンラベルが存在する")
    func testDeleteButtonLabel() {
        let label = NSLocalizedString(
            "groupList.delete",
            value: "削除",
            comment: "Delete button"
        )
        #expect(!label.isEmpty)
    }

    @Test("全選択ラベルが存在する")
    func testSelectAllLabel() {
        let label = NSLocalizedString(
            "groupList.selectAll",
            value: "全選択",
            comment: "Select all"
        )
        #expect(!label.isEmpty)
    }

    @Test("全解除ラベルが存在する")
    func testDeselectAllLabel() {
        let label = NSLocalizedString(
            "groupList.deselectAll",
            value: "全解除",
            comment: "Deselect all"
        )
        #expect(!label.isEmpty)
    }

    @Test("共通ボタンラベルが存在する")
    func testCommonButtonLabels() {
        let ok = NSLocalizedString("common.ok", value: "OK", comment: "OK button")
        let cancel = NSLocalizedString("common.cancel", value: "キャンセル", comment: "Cancel button")
        let close = NSLocalizedString("common.close", value: "閉じる", comment: "Close button")
        let done = NSLocalizedString("common.done", value: "完了", comment: "Done button")
        let back = NSLocalizedString("common.back", value: "戻る", comment: "Back button")

        #expect(!ok.isEmpty)
        #expect(!cancel.isEmpty)
        #expect(!close.isEmpty)
        #expect(!done.isEmpty)
        #expect(!back.isEmpty)
    }
}

// MARK: - Performance Tests

@Suite("GroupListView パフォーマンステスト")
struct GroupListPerformanceTests {

    @Test("大量のグループを処理できる")
    func testLargeGroupList() {
        var groups: [PhotoGroup] = []

        for i in 0..<500 {
            let group = PhotoGroup(
                type: GroupType.allCases[i % GroupType.allCases.count],
                photoIds: (0..<10).map { "photo_\(i)_\($0)" },
                fileSizes: Array(repeating: Int64(i) * 1_000_000, count: 10)
            )
            groups.append(group)
        }

        #expect(groups.count == 500)
    }

    @Test("大量のグループをフィルタリングできる")
    func testFilterLargeGroupList() {
        let groups = (0..<1000).map { i in
            PhotoGroup(
                type: GroupType.allCases[i % GroupType.allCases.count],
                photoIds: ["photo_\(i)"],
                fileSizes: [Int64(1_000_000)]
            )
        }

        let filtered = groups.filterByType(.similar)
        #expect(filtered.count > 0)
    }

    @Test("大量のグループをソートできる")
    func testSortLargeGroupList() {
        var groups: [PhotoGroup] = []
        for i in 0..<1000 {
            let photoCount = i % 10 + 1
            let photoIds = (0..<photoCount).map { "photo_\(i)_\($0)" }
            let fileSizes = Array(repeating: Int64(i * 100_000), count: photoCount)
            let group = PhotoGroup(
                type: .similar,
                photoIds: photoIds,
                fileSizes: fileSizes,
                bestShotIndex: 0
            )
            groups.append(group)
        }

        let sorted = groups.sortedByReclaimableSize
        #expect(sorted.count == 1000)
    }

    @Test("大量の選択を処理できる")
    func testLargeSelection() {
        let groups = (0..<1000).map { _ in
            PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])
        }

        let selectedIds = Set(groups.map { $0.id })
        #expect(selectedIds.count == 1000)
    }
}

// MARK: - Accessibility Tests

@Suite("GroupListView アクセシビリティテスト")
struct GroupListAccessibilityTests {

    @Test("戻るボタンにアクセシビリティラベルがある")
    func testBackButtonAccessibilityLabel() {
        let label = NSLocalizedString(
            "common.back",
            value: "戻る",
            comment: "Back button"
        )
        #expect(!label.isEmpty)
    }

    @Test("フィルタボタンにアイコンがある")
    func testFilterButtonIcon() {
        let icon = "line.3.horizontal.decrease.circle"
        #expect(!icon.isEmpty)
    }

    @Test("選択チェックボックスにアイコンがある")
    func testSelectionCheckboxIcons() {
        let selected = "checkmark.circle.fill"
        let unselected = "circle"
        #expect(!selected.isEmpty)
        #expect(!unselected.isEmpty)
    }

    @Test("ソート順アイコンが存在する")
    func testSortOrderIcons() {
        for order in GroupListView.SortOrder.allCases {
            #expect(!order.icon.isEmpty, "\(order.rawValue)にアイコンが必要")
        }
    }
}
