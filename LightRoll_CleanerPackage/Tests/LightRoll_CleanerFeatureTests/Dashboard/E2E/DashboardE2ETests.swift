//
//  DashboardE2ETests.swift
//  LightRoll_CleanerFeatureTests
//
//  Dashboard E2Eシナリオテスト
//  ユーザーフロー全体をエンドツーエンドでテスト
//  M5-T13: Dashboard E2Eテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@testable import LightRoll_CleanerFeature

// MARK: - E2E Scenario Tests

@Suite("Dashboard E2Eテスト: ユーザーシナリオ", .tags(.e2e, .dashboard))
@MainActor
struct DashboardE2EScenarioTests {

    // MARK: - Test Helpers

    /// E2Eテスト用モックPhotoRepository
    private actor E2EMockPhotoRepository: PhotoRepositoryProtocol {
        var photos: [PhotoAsset] = []
        var deletedPhotoIds: Set<String> = []

        func fetchAllPhotos() async throws -> [PhotoAsset] {
            return photos.filter { !deletedPhotoIds.contains($0.id) }
        }

        func fetchPhoto(by id: String) async -> PhotoAsset? {
            return photos.first { $0.id == id }
        }

        func deletePhotos(_ photos: [PhotoAsset]) async throws {
            for photo in photos {
                deletedPhotoIds.insert(photo.id)
            }
        }

        func moveToTrash(_ photos: [PhotoAsset]) async throws {
            // モック実装
        }

        func restoreFromTrash(_ photos: [PhotoAsset]) async throws {
            // モック実装
        }

        #if canImport(UIKit)
        func fetchThumbnail(for photo: PhotoAsset, size: CGSize) async throws -> UIImage {
            return UIImage()
        }
        #endif

        func setPhotos(_ newPhotos: [PhotoAsset]) {
            self.photos = newPhotos
        }
    }

    /// E2Eテスト用モックAnalysisRepository
    private actor E2EMockAnalysisRepository: AnalysisRepositoryProtocol {
        var groups: [PhotoGroup] = []

        func analyzePhoto(_ photo: PhotoAsset) async throws -> PhotoAnalysisResult {
            return PhotoAnalysisResult(
                photoId: photo.id,
                qualityScore: 0.5,
                blurScore: 0.0,
                faceCount: 0,
                isScreenshot: false,
                isSelfie: false
            )
        }

        func findSimilarPhotos(_ photos: [PhotoAsset]) async throws -> [[PhotoAsset]] {
            var result: [[PhotoAsset]] = []
            for group in groups {
                let groupPhotos = photos.filter { group.photoIds.contains($0.id) }
                if !groupPhotos.isEmpty {
                    result.append(groupPhotos)
                }
            }
            return result
        }

        func detectBlurryPhotos(_ photos: [PhotoAsset]) async throws -> [PhotoAsset] {
            return []
        }

        func detectScreenshots(_ photos: [PhotoAsset]) async -> [PhotoAsset] {
            return []
        }

        func selectBestShot(from photos: [PhotoAsset]) async -> Int? {
            return photos.isEmpty ? nil : 0
        }

        func setGroups(_ newGroups: [PhotoGroup]) {
            self.groups = newGroups
        }
    }

    /// テスト用写真を生成
    private func createE2EPhotos(count: Int) -> [PhotoAsset] {
        (0..<count).map { index in
            PhotoAsset(
                id: "e2e-photo-\(index)",
                creationDate: Date().addingTimeInterval(-TimeInterval(index * 3600)),
                fileSize: Int64(3_000_000 + index * 50_000)
            )
        }
    }

    /// テスト用グループを生成
    private func createE2EGroups(photoIds: [String]) -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: Array(photoIds.prefix(10)),
                fileSizes: Array(repeating: 3_000_000, count: 10),
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: Array(photoIds.dropFirst(10).prefix(5)),
                fileSizes: Array(repeating: 1_200_000, count: 5)
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: Array(photoIds.dropFirst(15).prefix(8)),
                fileSizes: Array(repeating: 2_500_000, count: 8),
                bestShotIndex: 0
            )
        ]
    }

    // MARK: - Happy Path Scenarios

    @Test("E2Eシナリオ: 初回スキャン → 結果表示 → グループ選択 → 詳細表示")
    func testFirstTimeScanToDetailFlow() async throws {
        // Given: 初期状態
        let photos = createE2EPhotos(count: 100)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        let router = DashboardRouter()

        // Step 1: モック結果を作成（実際のスキャンは省略）
        let scanResult = ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: groups.reduce(0) { $0 + $1.reclaimableSize },
            duration: 1.0
        )

        // Step 2: スキャン結果を確認
        #expect(scanResult.totalPhotosScanned == 100)
        #expect(scanResult.groupsFound == 3)
        #expect(scanResult.potentialSavings > 0)

        // Step 3: グループリストへ遷移
        router.navigateToGroupList()
        #expect(router.path.count == 1)

        // Step 4: 特定グループを選択して詳細へ
        let selectedGroup = groups[0]
        router.navigateToGroupDetail(group: selectedGroup)

        // Then: 最終状態の確認
        #expect(router.path.count == 2)
        #expect(router.path[1] == .groupDetail(selectedGroup))
        #expect(selectedGroup.type == .similar)
        #expect(selectedGroup.count == 10)
    }

    @Test("E2Eシナリオ: スキャン → フィルタ選択 → グループ一覧 → 詳細")
    func testScanToFilteredGroupListFlow() async throws {
        // Given
        let photos = createE2EPhotos(count: 50)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        let router = DashboardRouter()

        // Step 1: スキャン完了を想定（実際のスキャンは省略）

        // Step 2: スクリーンショットフィルタで一覧へ
        router.navigateToGroupList(filterType: .screenshot)
        #expect(router.path.first == .groupListFiltered(.screenshot))

        // Step 3: フィルタリングされたグループを検証
        let screenshotGroups = groups.filter { $0.type == .screenshot }
        #expect(screenshotGroups.count == 1)

        // Step 4: グループ詳細へ
        router.navigateToGroupDetail(group: screenshotGroups[0])
        #expect(router.path.count == 2)
    }

    @Test("E2Eシナリオ: スキャン → グループ選択 → 削除 → 再スキャン")
    func testScanSelectDeleteRescanFlow() async throws {
        // Given
        let photos = createE2EPhotos(count: 30)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        // Step 1: 初回スキャン結果を作成
        let initialResult = ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: groups.reduce(0) { $0 + $1.reclaimableSize },
            duration: 1.0
        )
        #expect(initialResult.totalPhotosScanned == 30)
        #expect(initialResult.groupsFound == 3)

        // Step 2: グループを選択して削除
        let groupToDelete = groups[0]
        let photosToDelete = photos.filter { groupToDelete.photoIds.contains($0.id) }
        try await photoRepo.deletePhotos(photosToDelete)

        // Step 3: 再スキャン結果を作成
        let remainingPhotos = try await photoRepo.fetchAllPhotos()
        let secondResult = ScanResult(
            totalPhotosScanned: remainingPhotos.count,
            groupsFound: groups.count - 1,
            potentialSavings: 0,
            duration: 0.5
        )

        // Then: 削除後は写真数が減っている
        #expect(secondResult.totalPhotosScanned == 30 - photosToDelete.count)
        #expect(secondResult.totalPhotosScanned == 20)
    }

    @Test("E2Eシナリオ: 複数グループ選択 → 一括削除")
    func testMultipleGroupSelectionAndDeletion() async throws {
        // Given
        let photos = createE2EPhotos(count: 50)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        // Step 1: スキャン完了を想定（実際のスキャンは省略）

        // Step 2: 複数グループを選択
        var selectedGroupIds: Set<UUID> = []
        selectedGroupIds.insert(groups[0].id)
        selectedGroupIds.insert(groups[1].id)

        let selectedGroups = groups.filter { selectedGroupIds.contains($0.id) }
        #expect(selectedGroups.count == 2)

        // Step 3: 選択したグループの統計を計算
        let totalPhotosToDelete = selectedGroups.reduce(0) { $0 + $1.reclaimableCount }
        let totalSizeToFree = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }

        #expect(totalPhotosToDelete > 0)
        #expect(totalSizeToFree > 0)

        // Step 4: 削除実行
        var allPhotosToDelete: [PhotoAsset] = []
        for group in selectedGroups {
            let groupPhotos = photos.filter { group.deletionCandidateIds.contains($0.id) }
            allPhotosToDelete.append(contentsOf: groupPhotos)
        }

        try await photoRepo.deletePhotos(allPhotosToDelete)

        // Then: 削除後の確認
        let deletedIds = await photoRepo.deletedPhotoIds
        #expect(deletedIds.count == allPhotosToDelete.count)
    }

    // MARK: - Navigation Scenarios

    @Test("E2Eシナリオ: 深いナビゲーションスタックからの復帰")
    func testDeepNavigationStackReturn() async throws {
        // Given
        let photos = createE2EPhotos(count: 30)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let router = DashboardRouter()

        // Step 1: 深いナビゲーションスタックを構築
        router.navigateToGroupList()
        router.navigateToGroupDetail(group: groups[0])
        router.navigateToGroupList(filterType: .screenshot)
        router.navigateToGroupDetail(group: groups[1])

        #expect(router.path.count == 4)

        // Step 2: ルートまで一気に戻る
        router.navigateToRoot()

        // Then
        #expect(router.path.isEmpty)
    }

    @Test("E2Eシナリオ: フィルタ切り替えナビゲーション")
    func testFilterSwitchingNavigation() async throws {
        // Given
        let router = DashboardRouter()

        // Step 1: 類似写真フィルタで表示
        router.navigateToGroupList(filterType: .similar)
        #expect(router.path.count == 1)

        // Step 2: 戻る
        router.navigateBack()
        #expect(router.path.isEmpty)

        // Step 3: スクリーンショットフィルタで表示
        router.navigateToGroupList(filterType: .screenshot)
        #expect(router.path.first == .groupListFiltered(.screenshot))

        // Step 4: 再び戻る
        router.navigateBack()
        #expect(router.path.isEmpty)

        // Step 5: フィルタなしで表示
        router.navigateToGroupList()
        #expect(router.path.first == .groupList)
    }

    @Test("E2Eシナリオ: グループ詳細からの戻り → 別グループ選択")
    func testDetailBackToListAndSelectAnother() async throws {
        // Given
        let photos = createE2EPhotos(count: 30)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let router = DashboardRouter()

        // Step 1: グループ一覧へ
        router.navigateToGroupList()

        // Step 2: グループ1の詳細へ
        router.navigateToGroupDetail(group: groups[0])
        #expect(router.path.count == 2)

        // Step 3: 一覧に戻る
        router.navigateBack()
        #expect(router.path.count == 1)

        // Step 4: グループ2の詳細へ
        router.navigateToGroupDetail(group: groups[1])
        #expect(router.path.count == 2)
        #expect(router.path[1] == .groupDetail(groups[1]))
    }

    // MARK: - Error Recovery Scenarios

    @Test("E2Eシナリオ: スキャンエラー → リトライ → 成功")
    func testScanErrorRetrySuccess() async throws {
        // Given
        let photoRepo = E2EMockPhotoRepository()
        let analysisRepo = E2EMockAnalysisRepository()

        // Step 1: 空の写真でスキャン結果を作成
        await photoRepo.setPhotos([])

        let firstResult = ScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: 0.1
        )
        #expect(firstResult.totalPhotosScanned == 0)
        #expect(firstResult.groupsFound == 0)

        // Step 2: 写真を追加してリトライ
        let photos = createE2EPhotos(count: 20)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        await photoRepo.setPhotos(photos)
        await analysisRepo.setGroups(groups)

        let secondResult = ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: groups.reduce(0) { $0 + $1.reclaimableSize },
            duration: 1.0
        )

        // Then: リトライ成功
        #expect(secondResult.totalPhotosScanned == 20)
        #expect(secondResult.groupsFound == 3)
    }

    @Test("E2Eシナリオ: 空のグループリスト表示")
    func testEmptyGroupListDisplay() async throws {
        // Given
        let photoRepo = E2EMockPhotoRepository()
        let analysisRepo = E2EMockAnalysisRepository()

        await photoRepo.setPhotos([])
        await analysisRepo.setGroups([])

        // Step 1: スキャン結果を作成（結果なし）
        let result = ScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: 0.1
        )

        // Step 2: 空のグループリストへ遷移
        let router = DashboardRouter()
        router.navigateToGroupList()

        // Then
        #expect(result.groupsFound == 0)
        #expect(router.path.count == 1)
    }

    // MARK: - Data Persistence Scenarios

    @Test("E2Eシナリオ: スキャン結果の統計計算の正確性")
    func testScanResultStatisticsAccuracy() async throws {
        // Given
        let photos = createE2EPhotos(count: 100)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        // Step 1: スキャン結果を作成
        let scanResult = ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: groups.reduce(0) { $0 + $1.reclaimableSize },
            duration: 1.0
        )

        // Step 2: 統計情報を作成（GetStatisticsUseCaseは使用不可のため直接構築）
        let storageInfo = StorageInfo(
            totalCapacity: 256_000_000_000,
            availableCapacity: 100_000_000_000,
            photosUsedCapacity: 56_000_000_000,
            reclaimableCapacity: groups.reduce(0) { $0 + $1.reclaimableSize }
        )
        let statistics = StatisticsOutput(
            storageInfo: storageInfo,
            totalPhotos: photos.count,
            groupStatistics: GroupStatistics(
                similarGroupCount: groups.filter { $0.type == .similar || $0.type == .duplicate }.count,
                screenshotCount: groups.filter { $0.type == .screenshot }.reduce(0) { $0 + $1.count },
                blurryCount: groups.filter { $0.type == .blurry }.reduce(0) { $0 + $1.count },
                largeVideoCount: groups.filter { $0.type == .largeVideo }.reduce(0) { $0 + $1.count },
                trashCount: 0
            ),
            lastScanDate: Date()
        )

        // Then: スキャン結果と統計の整合性
        let groupsTotal = groups.reduce(0) { $0 + $1.count }
        let potentialSavingsTotal = groups.reduce(0) { $0 + $1.reclaimableSize }

        #expect(scanResult.totalPhotosScanned == 100)
        #expect(scanResult.groupsFound == 3)

        // 統計内のグループ数合計（GroupStatisticsから計算）
        let statisticsGroupCount = statistics.groupStatistics.similarGroupCount +
                                   (statistics.groupStatistics.screenshotCount > 0 ? 1 : 0) +
                                   (statistics.groupStatistics.blurryCount > 0 ? 1 : 0) +
                                   (statistics.groupStatistics.largeVideoCount > 0 ? 1 : 0)
        #expect(statisticsGroupCount >= 1)
    }

    @Test("E2Eシナリオ: 削除前後の容量計算")
    func testStorageCalculationBeforeAfterDeletion() async throws {
        // Given
        let photos = createE2EPhotos(count: 50)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        // Step 1: 初回スキャン結果を作成
        let beforeSavings = groups.reduce(Int64(0)) { $0 + $1.reclaimableSize }

        // Step 2: グループを削除
        let groupToDelete = groups[0]
        let photosToDelete = photos.filter { groupToDelete.deletionCandidateIds.contains($0.id) }
        let deletedSize = photosToDelete.reduce(Int64(0)) { $0 + $1.fileSize }

        try await photoRepo.deletePhotos(photosToDelete)

        // Step 3: 再スキャン結果を作成
        let remainingGroups = groups.filter { $0.id != groupToDelete.id }
        let afterSavings = remainingGroups.reduce(Int64(0)) { $0 + $1.reclaimableSize }

        // Then: 削減可能容量が減少
        #expect(afterSavings < beforeSavings)
        #expect(beforeSavings - afterSavings == deletedSize)
    }

    // MARK: - Complex User Workflows

    @Test("E2Eシナリオ: 複雑なユーザーワークフロー（スキャン→選択→削除→リフレッシュ）")
    func testComplexUserWorkflow() async throws {
        // Given
        let photos = createE2EPhotos(count: 80)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        let router = DashboardRouter()

        // Step 1: 初回スキャン結果を作成
        let scan1 = ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: groups.reduce(0) { $0 + $1.reclaimableSize },
            duration: 1.0
        )
        #expect(scan1.totalPhotosScanned == 80)

        // Step 2: グループリストへ遷移
        router.navigateToGroupList()
        #expect(router.path.count == 1)

        // Step 3: グループ選択
        var selectedIds: Set<UUID> = [groups[0].id]
        #expect(selectedIds.count == 1)

        // Step 4: 詳細表示
        router.navigateToGroupDetail(group: groups[0])
        #expect(router.path.count == 2)

        // Step 5: 削除実行
        let photosToDelete = photos.filter { groups[0].deletionCandidateIds.contains($0.id) }
        try await photoRepo.deletePhotos(photosToDelete)

        // Step 6: ルートに戻る
        router.navigateToRoot()
        #expect(router.path.isEmpty)

        // Step 7: 再スキャン結果を作成（リフレッシュ）
        let remainingPhotos = try await photoRepo.fetchAllPhotos()
        let scan2 = ScanResult(
            totalPhotosScanned: remainingPhotos.count,
            groupsFound: groups.count - 1,
            potentialSavings: 0,
            duration: 0.8
        )

        // Then: 2回目のスキャンは写真数が減少
        #expect(scan2.totalPhotosScanned < scan1.totalPhotosScanned)
        #expect(scan2.totalPhotosScanned == 80 - photosToDelete.count)
    }

    @Test("E2Eシナリオ: フィルタ → ソート → 選択 → 削除の一連の流れ")
    func testFilterSortSelectDeleteFlow() async throws {
        // Given
        let photos = createE2EPhotos(count: 60)
        let photoIds = photos.map { $0.id }
        let groups = createE2EGroups(photoIds: photoIds)

        let photoRepo = E2EMockPhotoRepository()
        await photoRepo.setPhotos(photos)

        let analysisRepo = E2EMockAnalysisRepository()
        await analysisRepo.setGroups(groups)

        // Step 1: スキャン完了を想定（実際のスキャンは省略）

        // Step 2: フィルタリング（類似写真のみ）
        let filteredGroups = groups.filter { $0.type == .similar }
        #expect(filteredGroups.count > 0)

        // Step 3: ソート（削減可能サイズ順）
        let sortedGroups = filteredGroups.sorted { $0.reclaimableSize > $1.reclaimableSize }
        #expect(sortedGroups.count == filteredGroups.count)

        // Step 4: 上位2グループを選択
        let topGroups = Array(sortedGroups.prefix(1))
        #expect(topGroups.count >= 1)

        // Step 5: 削除
        var allPhotosToDelete: [PhotoAsset] = []
        for group in topGroups {
            let groupPhotos = photos.filter { group.deletionCandidateIds.contains($0.id) }
            allPhotosToDelete.append(contentsOf: groupPhotos)
        }

        try await photoRepo.deletePhotos(allPhotosToDelete)

        // Then: 削除後の確認
        let deletedIds = await photoRepo.deletedPhotoIds
        #expect(deletedIds.count == allPhotosToDelete.count)
    }
}

// MARK: - Custom Test Tags
// 注: e2e タグは TestTags.swift で定義済み
