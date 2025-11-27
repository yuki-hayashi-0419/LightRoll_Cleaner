//
//  AppStateTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AppStateのユニットテスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - AppState Tests

@Suite("AppState Tests")
struct AppStateTests {

    // MARK: - Initialization Tests

    @MainActor
    @Test("AppStateが正しく初期化される")
    func testInitialization() {
        let appState = AppState(forTesting: true)

        #expect(appState.currentTab == .dashboard)
        #expect(appState.isScanning == false)
        #expect(appState.isLoading == false)
        #expect(appState.photoGroups.isEmpty)
        #expect(appState.selectedPhotos.isEmpty)
        #expect(appState.errorMessage == nil)
    }

    // MARK: - Navigation Tests

    @MainActor
    @Test("タブ切り替えが正しく動作する")
    func testSwitchTab() {
        let appState = AppState(forTesting: true)

        appState.switchTab(to: .groups)
        #expect(appState.currentTab == .groups)

        appState.switchTab(to: .settings)
        #expect(appState.currentTab == .settings)

        appState.switchTab(to: .dashboard)
        #expect(appState.currentTab == .dashboard)
    }

    @MainActor
    @Test("ナビゲーションパスが正しく動作する")
    func testNavigationPath() {
        let appState = AppState(forTesting: true)
        let group = PhotoGroup(type: .similar)

        appState.navigate(to: .groupDetail(group))
        #expect(appState.navigationPath.count == 1)

        appState.navigate(to: .settings)
        #expect(appState.navigationPath.count == 2)

        appState.navigateBack()
        #expect(appState.navigationPath.count == 1)

        appState.navigateToRoot()
        #expect(appState.navigationPath.isEmpty)
    }

    // MARK: - Scan Tests

    @MainActor
    @Test("スキャン開始が正しく動作する")
    func testStartScan() {
        let appState = AppState(forTesting: true)

        appState.startScan()
        #expect(appState.isScanning == true)
        #expect(appState.scanProgress.phase == .preparing)
        #expect(appState.errorMessage == nil)
    }

    @MainActor
    @Test("スキャン進捗更新が正しく動作する")
    func testUpdateScanProgress() {
        let appState = AppState(forTesting: true)
        let progress = ScanProgress(
            phase: .analyzing,
            progress: 0.5,
            processedCount: 500,
            totalCount: 1000,
            currentTask: "分析中..."
        )

        appState.updateScanProgress(progress)
        #expect(appState.scanProgress.phase == .analyzing)
        #expect(appState.scanProgress.progress == 0.5)
        #expect(appState.scanProgress.processedCount == 500)
    }

    @MainActor
    @Test("スキャン完了が正しく動作する")
    func testCompleteScan() {
        let appState = AppState(forTesting: true)
        let result = ScanResult(
            totalPhotosScanned: 1000,
            groupsFound: 50,
            potentialSavings: 1_000_000_000,
            duration: 30.0
        )

        appState.startScan()
        appState.completeScan(result: result)

        #expect(appState.isScanning == false)
        #expect(appState.scanProgress.phase == .completed)
        #expect(appState.scanResult?.totalPhotosScanned == 1000)
        #expect(appState.scanResult?.groupsFound == 50)
        #expect(appState.potentialSavings == 1_000_000_000)
        #expect(appState.lastScanDate != nil)
    }

    @MainActor
    @Test("スキャンキャンセルが正しく動作する")
    func testCancelScan() {
        let appState = AppState(forTesting: true)

        appState.startScan()
        appState.cancelScan()

        #expect(appState.isScanning == false)
        #expect(appState.scanProgress.phase == .preparing)
    }

    // MARK: - Photo Selection Tests

    @MainActor
    @Test("写真選択が正しく動作する")
    func testSelectPhoto() {
        let appState = AppState(forTesting: true)

        appState.selectPhoto("photo1")
        #expect(appState.selectedPhotos.contains("photo1"))
        #expect(appState.selectedPhotosCount == 1)

        appState.selectPhoto("photo2")
        #expect(appState.selectedPhotosCount == 2)
    }

    @MainActor
    @Test("写真選択解除が正しく動作する")
    func testDeselectPhoto() {
        let appState = AppState(forTesting: true)

        appState.selectPhoto("photo1")
        appState.selectPhoto("photo2")
        appState.deselectPhoto("photo1")

        #expect(!appState.selectedPhotos.contains("photo1"))
        #expect(appState.selectedPhotos.contains("photo2"))
        #expect(appState.selectedPhotosCount == 1)
    }

    @MainActor
    @Test("写真選択トグルが正しく動作する")
    func testTogglePhotoSelection() {
        let appState = AppState(forTesting: true)

        appState.togglePhotoSelection("photo1")
        #expect(appState.selectedPhotos.contains("photo1"))

        appState.togglePhotoSelection("photo1")
        #expect(!appState.selectedPhotos.contains("photo1"))
    }

    @MainActor
    @Test("全選択クリアが正しく動作する")
    func testClearSelection() {
        let appState = AppState(forTesting: true)

        appState.selectPhoto("photo1")
        appState.selectPhoto("photo2")
        appState.selectPhoto("photo3")
        appState.clearSelection()

        #expect(appState.selectedPhotos.isEmpty)
        #expect(appState.hasSelection == false)
    }

    @MainActor
    @Test("全写真選択が正しく動作する")
    func testSelectAllPhotos() {
        let appState = AppState(forTesting: true)
        let ids = ["photo1", "photo2", "photo3"]

        appState.selectAllPhotos(ids)

        #expect(appState.selectedPhotosCount == 3)
        #expect(appState.selectedPhotos.contains("photo1"))
        #expect(appState.selectedPhotos.contains("photo2"))
        #expect(appState.selectedPhotos.contains("photo3"))
    }

    // MARK: - Alert/Toast Tests

    @MainActor
    @Test("アラート表示が正しく動作する")
    func testShowAlert() {
        let appState = AppState(forTesting: true)

        appState.showAlert(title: "テスト", message: "テストメッセージ")

        #expect(appState.showingAlert == true)
        #expect(appState.alertTitle == "テスト")
        #expect(appState.alertMessage == "テストメッセージ")
    }

    @MainActor
    @Test("アラート非表示が正しく動作する")
    func testHideAlert() {
        let appState = AppState(forTesting: true)

        appState.showAlert(title: "テスト", message: "テストメッセージ")
        appState.hideAlert()

        #expect(appState.showingAlert == false)
        #expect(appState.alertTitle.isEmpty)
        #expect(appState.alertMessage.isEmpty)
    }

    @MainActor
    @Test("トースト表示が正しく動作する")
    func testShowToast() {
        let appState = AppState(forTesting: true)

        appState.showToast("保存しました")

        #expect(appState.toastMessage == "保存しました")
    }

    // MARK: - Premium Tests

    @MainActor
    @Test("プレミアムステータス更新が正しく動作する")
    func testUpdatePremiumStatus() {
        let appState = AppState(forTesting: true)

        #expect(appState.isPremium == false)

        appState.updatePremiumStatus(true)
        #expect(appState.isPremium == true)
    }

    @MainActor
    @Test("無料ユーザーの削除制限が正しく動作する")
    func testFreeUserDeleteLimit() {
        let appState = AppState(forTesting: true)
        appState.isPremium = false
        appState.todayDeleteCount = 0

        #expect(appState.remainingFreeDeletes == 20)
        #expect(appState.hasReachedFreeLimit == false)
        #expect(appState.canDelete(count: 10) == true)
        #expect(appState.canDelete(count: 25) == false)
    }

    @MainActor
    @Test("削除カウント加算が正しく動作する")
    func testIncrementDeleteCount() {
        let appState = AppState(forTesting: true)
        appState.todayDeleteCount = 0

        appState.incrementDeleteCount(by: 5)
        #expect(appState.todayDeleteCount == 5)
        #expect(appState.remainingFreeDeletes == 15)

        appState.incrementDeleteCount(by: 15)
        #expect(appState.todayDeleteCount == 20)
        #expect(appState.remainingFreeDeletes == 0)
        #expect(appState.hasReachedFreeLimit == true)
    }

    @MainActor
    @Test("プレミアムユーザーは削除制限がない")
    func testPremiumUserNoLimit() {
        let appState = AppState(forTesting: true)
        appState.isPremium = true
        appState.todayDeleteCount = 100

        #expect(appState.hasReachedFreeLimit == false)
        #expect(appState.canDelete(count: 1000) == true)
    }

    // MARK: - Reset Tests

    @MainActor
    @Test("リセットが正しく動作する")
    func testReset() {
        let appState = AppState(forTesting: true)

        // 状態を変更
        appState.currentTab = .settings
        appState.isScanning = true
        appState.selectPhoto("photo1")
        appState.errorMessage = "エラー"

        // リセット
        appState.reset()

        #expect(appState.currentTab == .dashboard)
        #expect(appState.isScanning == false)
        #expect(appState.selectedPhotos.isEmpty)
        #expect(appState.errorMessage == nil)
    }
}

// MARK: - Tab Tests

@Suite("Tab Tests")
struct TabTests {

    @Test("Tabの全ケースが存在する")
    func testAllCases() {
        #expect(Tab.allCases.count == 3)
        #expect(Tab.allCases.contains(.dashboard))
        #expect(Tab.allCases.contains(.groups))
        #expect(Tab.allCases.contains(.settings))
    }

    @Test("TabのIDがrawValueと一致する")
    func testTabId() {
        #expect(Tab.dashboard.id == "dashboard")
        #expect(Tab.groups.id == "groups")
        #expect(Tab.settings.id == "settings")
    }

    @Test("Tabのタイトルが設定されている")
    func testTabTitle() {
        #expect(!Tab.dashboard.title.isEmpty)
        #expect(!Tab.groups.title.isEmpty)
        #expect(!Tab.settings.title.isEmpty)
    }

    @Test("Tabのアイコンが設定されている")
    func testTabIcon() {
        #expect(!Tab.dashboard.icon.isEmpty)
        #expect(!Tab.groups.icon.isEmpty)
        #expect(!Tab.settings.icon.isEmpty)
    }
}

// MARK: - ScanResult Tests

@Suite("ScanResult Tests")
struct ScanResultTests {

    @Test("ScanResultが正しく初期化される")
    func testInitialization() {
        let result = ScanResult(
            totalPhotosScanned: 1000,
            groupsFound: 50,
            potentialSavings: 1_000_000_000,
            duration: 45.5
        )

        #expect(result.totalPhotosScanned == 1000)
        #expect(result.groupsFound == 50)
        #expect(result.potentialSavings == 1_000_000_000)
        #expect(result.duration == 45.5)
    }

    @Test("formattedPotentialSavingsが正しくフォーマットされる")
    func testFormattedPotentialSavings() {
        let result = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1_000_000_000, // 1GB
            duration: 10.0
        )

        // フォーマットはロケールに依存するが、空でないことを確認
        #expect(!result.formattedPotentialSavings.isEmpty)
    }

    @Test("ScanResult.emptyが正しく生成される")
    func testEmptyFactory() {
        let empty = ScanResult.empty

        #expect(empty.totalPhotosScanned == 0)
        #expect(empty.groupsFound == 0)
        #expect(empty.potentialSavings == 0)
        #expect(empty.duration == 0)
    }

    @Test("GroupBreakdownの合計が正しく計算される")
    func testGroupBreakdownTotal() {
        let breakdown = GroupBreakdown(
            similarGroups: 10,
            selfieGroups: 5,
            screenshotCount: 20,
            blurryCount: 15,
            largeVideoCount: 3
        )

        #expect(breakdown.totalItems == 53)
    }

    @Test("GroupBreakdownのタイプ別カウントが正しい")
    func testGroupBreakdownCountForType() {
        let breakdown = GroupBreakdown(
            similarGroups: 10,
            selfieGroups: 5,
            screenshotCount: 20,
            blurryCount: 15,
            largeVideoCount: 3
        )

        #expect(breakdown.count(for: .similar) == 10)
        #expect(breakdown.count(for: .selfie) == 5)
        #expect(breakdown.count(for: .screenshot) == 20)
        #expect(breakdown.count(for: .blurry) == 15)
        #expect(breakdown.count(for: .largeVideo) == 3)
    }
}

// MARK: - ScanProgress Tests

@Suite("ScanProgress Tests")
struct ScanProgressTests {

    @Test("ScanProgress.initialが正しく生成される")
    func testInitialFactory() {
        let progress = ScanProgress.initial

        #expect(progress.phase == .preparing)
        #expect(progress.progress == 0)
    }

    @Test("ScanProgress.completedが正しく生成される")
    func testCompletedFactory() {
        let progress = ScanProgress.completed

        #expect(progress.phase == .completed)
        #expect(progress.progress == 1.0)
    }

    @Test("進捗が0〜1にクランプされる")
    func testProgressClamping() {
        let negative = ScanProgress(phase: .analyzing, progress: -0.5)
        let overOne = ScanProgress(phase: .analyzing, progress: 1.5)

        #expect(negative.progress == 0)
        #expect(overOne.progress == 1.0)
    }
}

// MARK: - ScanPhase Tests

@Suite("ScanPhase Tests")
struct ScanPhaseTests {

    @Test("アクティブなフェーズが正しく判定される")
    func testIsActive() {
        #expect(ScanPhase.preparing.isActive == true)
        #expect(ScanPhase.fetchingPhotos.isActive == true)
        #expect(ScanPhase.analyzing.isActive == true)
        #expect(ScanPhase.grouping.isActive == true)
        #expect(ScanPhase.optimizing.isActive == true)
        #expect(ScanPhase.completed.isActive == false)
        #expect(ScanPhase.error.isActive == false)
    }

    @Test("フェーズの表示名が設定されている")
    func testDisplayName() {
        for phase in ScanPhase.allCases {
            #expect(!phase.displayName.isEmpty)
        }
    }
}

// MARK: - NavigationDestination Tests

@Suite("NavigationDestination Tests")
struct NavigationDestinationTests {

    @Test("NavigationDestinationのタイトルが設定されている")
    func testTitles() {
        let group = PhotoGroup(type: .similar)
        let photo = PhotoAsset(id: "1")
        let context = DeleteConfirmationContext(photoIds: ["1"])
        let result = ScanResult.empty

        #expect(!NavigationDestination.groupDetail(group).title.isEmpty)
        #expect(!NavigationDestination.photoDetail(photo).title.isEmpty)
        #expect(!NavigationDestination.deleteConfirmation(context).title.isEmpty)
        #expect(!NavigationDestination.settings.title.isEmpty)
        #expect(!NavigationDestination.premium.title.isEmpty)
        #expect(!NavigationDestination.trash.title.isEmpty)
        #expect(!NavigationDestination.permissions.title.isEmpty)
        #expect(!NavigationDestination.scanResult(result).title.isEmpty)
    }

    @Test("DeleteConfirmationContextが写真配列から正しく生成される")
    func testDeleteConfirmationContextFromPhotos() {
        let photos = [
            PhotoAsset(id: "1", fileSize: 1000),
            PhotoAsset(id: "2", fileSize: 2000),
            PhotoAsset(id: "3", fileSize: 3000)
        ]

        let context = DeleteConfirmationContext(photos: photos)

        #expect(context.count == 3)
        #expect(context.totalSize == 6000)
        #expect(context.photoIds == ["1", "2", "3"])
    }
}
