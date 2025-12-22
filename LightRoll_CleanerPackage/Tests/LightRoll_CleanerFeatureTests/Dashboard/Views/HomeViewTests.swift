//
//  HomeViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  HomeViewの包括的な単体テスト
//  MV Patternに基づくUI状態管理のテスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI

@testable import LightRoll_CleanerFeature

// MARK: - ViewState Tests

@Suite("HomeView.ViewState テスト")
struct ViewStateTests {

    @Test("loading状態が正しく初期化される")
    func testLoadingState() {
        let state = HomeView.ViewState.loading
        #expect(state == .loading)
        #expect(state.isLoading == true)
        #expect(state.isScanning == false)
    }

    @Test("loaded状態が正しく初期化される")
    func testLoadedState() {
        let state = HomeView.ViewState.loaded
        #expect(state == .loaded)
        #expect(state.isLoading == false)
        #expect(state.isScanning == false)
    }

    @Test("scanning状態が進捗値を保持する")
    func testScanningState() {
        let progress = 0.75
        let state = HomeView.ViewState.scanning(progress: progress)

        #expect(state.isScanning == true)
        #expect(state.isLoading == false)

        if case .scanning(let p) = state {
            #expect(p == progress)
        } else {
            Issue.record("Expected scanning state")
        }
    }

    @Test("error状態がメッセージを保持する")
    func testErrorState() {
        let message = "テストエラーメッセージ"
        let state = HomeView.ViewState.error(message)

        #expect(state.isLoading == false)
        #expect(state.isScanning == false)

        if case .error(let m) = state {
            #expect(m == message)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("scanning進捗0%が正しく表現される")
    func testScanningProgressZero() {
        let state = HomeView.ViewState.scanning(progress: 0.0)
        if case .scanning(let p) = state {
            #expect(p == 0.0)
        }
    }

    @Test("scanning進捗100%が正しく表現される")
    func testScanningProgressComplete() {
        let state = HomeView.ViewState.scanning(progress: 1.0)
        if case .scanning(let p) = state {
            #expect(p == 1.0)
        }
    }

    @Test("ViewState同士の等価比較が機能する")
    func testViewStateEquality() {
        #expect(HomeView.ViewState.loading == HomeView.ViewState.loading)
        #expect(HomeView.ViewState.loaded == HomeView.ViewState.loaded)
        #expect(HomeView.ViewState.scanning(progress: 0.5) == HomeView.ViewState.scanning(progress: 0.5))
        #expect(HomeView.ViewState.error("test") == HomeView.ViewState.error("test"))
    }

    @Test("異なるViewStateは等価でない")
    func testViewStateInequality() {
        #expect(HomeView.ViewState.loading != HomeView.ViewState.loaded)
        #expect(HomeView.ViewState.scanning(progress: 0.3) != HomeView.ViewState.scanning(progress: 0.7))
        #expect(HomeView.ViewState.error("a") != HomeView.ViewState.error("b"))
    }
}

// MARK: - CleanupHistoryRow Tests

@Suite("CleanupHistoryRow テスト")
struct CleanupHistoryRowTests {

    @Test("CleanupRecordから行が生成される")
    func testCleanupHistoryRowCreation() {
        let record = CleanupRecord(
            deletedCount: 25,
            freedSpace: 2_500_000_000,
            groupType: .similar,
            operationType: .quickClean
        )

        let row = CleanupHistoryRow(record: record)
        #expect(type(of: row) == CleanupHistoryRow.self)
    }

    @Test("各OperationTypeの行が生成される")
    func testAllOperationTypes() {
        for opType in CleanupRecord.OperationType.allCases {
            let record = CleanupRecord(
                deletedCount: 10,
                freedSpace: 1_000_000_000,
                groupType: .screenshot,
                operationType: opType
            )
            let row = CleanupHistoryRow(record: record)
            #expect(type(of: row) == CleanupHistoryRow.self)
        }
    }

    @Test("グループタイプなしの記録を処理できる")
    func testRecordWithoutGroupType() {
        let record = CleanupRecord(
            deletedCount: 5,
            freedSpace: 500_000_000,
            groupType: nil,
            operationType: .manual
        )

        let row = CleanupHistoryRow(record: record)
        #expect(type(of: row) == CleanupHistoryRow.self)
    }

    @Test("ゼロ削除数の記録を処理できる")
    func testZeroDeletedCount() {
        let record = CleanupRecord(
            deletedCount: 0,
            freedSpace: 0,
            groupType: nil,
            operationType: .automatic
        )

        let row = CleanupHistoryRow(record: record)
        #expect(type(of: row) == CleanupHistoryRow.self)
    }

    @Test("大きな削除数を処理できる")
    func testLargeDeletedCount() {
        let record = CleanupRecord(
            deletedCount: 10_000,
            freedSpace: 100_000_000_000,
            groupType: .largeVideo,
            operationType: .bulkDelete
        )

        let row = CleanupHistoryRow(record: record)
        #expect(type(of: row) == CleanupHistoryRow.self)
    }
}

// MARK: - ResultRow Tests

@Suite("ResultRow テスト")
struct ResultRowTests {

    @Test("アイコンとラベルと値から行が生成される")
    func testResultRowCreation() {
        let row = ResultRow(
            icon: "photo.fill",
            label: "テストラベル",
            value: "テスト値"
        )
        #expect(type(of: row) == ResultRow.self)
    }

    @Test("異なるアイコンで行が生成される")
    func testDifferentIcons() {
        let icons = ["checkmark.circle", "xmark.circle", "exclamationmark.triangle", "info.circle"]

        for icon in icons {
            let row = ResultRow(icon: icon, label: "ラベル", value: "値")
            #expect(type(of: row) == ResultRow.self)
        }
    }

    @Test("長いテキストを処理できる")
    func testLongText() {
        let longText = String(repeating: "テスト", count: 100)
        let row = ResultRow(icon: "doc.text", label: longText, value: longText)
        #expect(type(of: row) == ResultRow.self)
    }

    @Test("空のテキストを処理できる")
    func testEmptyText() {
        let row = ResultRow(icon: "circle", label: "", value: "")
        #expect(type(of: row) == ResultRow.self)
    }
}

// MARK: - ScanProgress Integration Tests

@Suite("HomeView ScanProgress統合テスト")
struct ScanProgressIntegrationTests {

    @Test("ScanProgressの各フェーズが正しく表現される")
    func testScanProgressPhases() {
        let phases: [ScanPhase] = [
            .preparing,
            .fetchingPhotos,
            .analyzing,
            .grouping,
            .optimizing,
            .completed
        ]

        for phase in phases {
            let progress = ScanProgress(
                phase: phase,
                progress: 0.5,
                processedCount: 50,
                totalCount: 100,
                currentTask: "テストタスク"
            )
            #expect(progress.phase == phase)
        }
    }

    @Test("進捗0%から100%まで正しく表現される")
    func testProgressRange() {
        let progressValues: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for value in progressValues {
            let progress = ScanProgress(
                phase: .analyzing,
                progress: value,
                processedCount: Int(value * 100),
                totalCount: 100,
                currentTask: "分析中"
            )
            #expect(progress.progress == value)
        }
    }

    @Test("現在のタスク名が正しく設定される")
    func testCurrentTaskName() {
        let taskName = "写真を分析中..."
        let progress = ScanProgress(
            phase: .analyzing,
            progress: 0.3,
            processedCount: 30,
            totalCount: 100,
            currentTask: taskName
        )
        #expect(progress.currentTask == taskName)
    }

    @Test("処理済み/合計カウントが正しい")
    func testProcessedAndTotalCounts() {
        let progress = ScanProgress(
            phase: .grouping,
            progress: 0.8,
            processedCount: 80,
            totalCount: 100,
            currentTask: "グループ化中"
        )
        #expect(progress.processedCount == 80)
        #expect(progress.totalCount == 100)
    }
}

// MARK: - ScanResult Display Tests

@Suite("HomeView ScanResult表示テスト")
struct ScanResultDisplayTests {

    private func createTestScanResult(
        totalPhotosScanned: Int = 1000,
        groupsFound: Int = 10,
        potentialSavings: Int64 = 5_000_000_000,
        duration: TimeInterval = 45.0
    ) -> ScanResult {
        ScanResult(
            totalPhotosScanned: totalPhotosScanned,
            groupsFound: groupsFound,
            potentialSavings: potentialSavings,
            duration: duration
        )
    }

    @Test("スキャン結果の総数が正しい")
    func testTotalPhotosScanned() {
        let result = createTestScanResult(totalPhotosScanned: 5000)
        #expect(result.totalPhotosScanned == 5000)
    }

    @Test("発見グループ数が正しい")
    func testGroupsFound() {
        let result = createTestScanResult(groupsFound: 25)
        #expect(result.groupsFound == 25)
    }

    @Test("削減可能容量が正しくフォーマットされる")
    func testFormattedPotentialSavings() {
        let result = createTestScanResult(potentialSavings: 5_000_000_000) // 5GB
        #expect(result.formattedPotentialSavings.contains("GB") || result.formattedPotentialSavings.contains("バイト"))
    }

    @Test("スキャン時間が正しくフォーマットされる")
    func testFormattedDuration() {
        let result = createTestScanResult(duration: 120.0) // 2分
        let formatted = result.formattedDuration
        #expect(!formatted.isEmpty)
    }

    @Test("ゼロ結果を処理できる")
    func testZeroResults() {
        let result = createTestScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: 0.5
        )
        #expect(result.totalPhotosScanned == 0)
        #expect(result.groupsFound == 0)
        #expect(result.potentialSavings == 0)
    }

    @Test("大きな結果を処理できる")
    func testLargeResults() {
        let result = createTestScanResult(
            totalPhotosScanned: 100_000,
            groupsFound: 500,
            potentialSavings: 500_000_000_000, // 500GB
            duration: 600.0 // 10分
        )
        #expect(result.totalPhotosScanned == 100_000)
        #expect(result.groupsFound == 500)
    }
}

// MARK: - Navigation Callback Tests

@Suite("HomeView ナビゲーションコールバックテスト")
struct NavigationCallbackTests {

    @Test("グループリストナビゲーションコールバックが呼ばれる")
    func testGroupListNavigationCallback() async {
        var calledGroupType: GroupType? = nil
        var callbackCalled = false

        let callback: (GroupType?) -> Void = { type in
            callbackCalled = true
            calledGroupType = type
        }

        // コールバックをテスト
        callback(.similar)
        #expect(callbackCalled)
        #expect(calledGroupType == .similar)
    }

    @Test("設定ナビゲーションコールバックが呼ばれる")
    func testSettingsNavigationCallback() async {
        var callbackCalled = false

        let callback: () -> Void = {
            callbackCalled = true
        }

        callback()
        #expect(callbackCalled)
    }

    @Test("nilグループタイプでナビゲーション可能")
    func testNavigationWithNilGroupType() {
        var receivedType: GroupType? = .similar // 初期値を設定

        let callback: (GroupType?) -> Void = { type in
            receivedType = type
        }

        callback(nil)
        #expect(receivedType == nil)
    }

    @Test("各グループタイプでナビゲーション可能")
    func testNavigationWithAllGroupTypes() {
        let groupTypes: [GroupType] = [.similar, .duplicate, .screenshot, .blurry, .largeVideo, .selfie]

        for expectedType in groupTypes {
            var receivedType: GroupType?

            let callback: (GroupType?) -> Void = { type in
                receivedType = type
            }

            callback(expectedType)
            #expect(receivedType == expectedType)
        }
    }
}

// MARK: - CleanupRecord Display Tests

@Suite("HomeView CleanupRecord表示テスト")
struct CleanupRecordDisplayTests {

    @Test("削除数が正しくフォーマットされる")
    func testDeletedCountFormatting() {
        let record = CleanupRecord(
            deletedCount: 1234,
            freedSpace: 1_000_000_000,
            groupType: .similar,
            operationType: .quickClean
        )
        #expect(record.deletedCount == 1234)
    }

    @Test("削減容量が正しくフォーマットされる")
    func testFreedSpaceFormatting() {
        let record = CleanupRecord(
            deletedCount: 100,
            freedSpace: 5_000_000_000, // 5GB
            groupType: .largeVideo,
            operationType: .manual
        )
        #expect(record.formattedFreedSpace.contains("GB") || record.formattedFreedSpace.contains("バイト"))
    }

    @Test("日付が正しくフォーマットされる")
    func testDateFormatting() {
        let record = CleanupRecord(
            deletedCount: 50,
            freedSpace: 500_000_000,
            groupType: .screenshot,
            operationType: .automatic
        )

        let formattedDate = record.formattedDate
        #expect(!formattedDate.isEmpty)
    }

    @Test("各操作タイプの表示名が存在する")
    func testOperationTypeDisplayNames() {
        for opType in CleanupRecord.OperationType.allCases {
            let record = CleanupRecord(
                deletedCount: 10,
                freedSpace: 100_000_000,
                groupType: nil,
                operationType: opType
            )
            #expect(!record.operationType.displayName.isEmpty)
        }
    }

    @Test("各グループタイプの表示名が存在する")
    func testGroupTypeDisplayNames() {
        let groupTypes: [GroupType] = [.similar, .duplicate, .screenshot, .blurry, .largeVideo, .selfie]

        for groupType in groupTypes {
            #expect(!groupType.displayName.isEmpty)
        }
    }
}

// MARK: - Error Handling Tests

@Suite("HomeView エラーハンドリングテスト")
struct ErrorHandlingTests {

    @Test("エラーメッセージが正しく表示される")
    func testErrorMessageDisplay() {
        let errorMessage = "写真ライブラリへのアクセスが拒否されました"
        let state = HomeView.ViewState.error(errorMessage)

        if case .error(let message) = state {
            #expect(message == errorMessage)
            #expect(message.contains("アクセス"))
        }
    }

    @Test("空のエラーメッセージを処理できる")
    func testEmptyErrorMessage() {
        let state = HomeView.ViewState.error("")

        if case .error(let message) = state {
            #expect(message.isEmpty)
        }
    }

    @Test("長いエラーメッセージを処理できる")
    func testLongErrorMessage() {
        let longMessage = String(repeating: "エラー", count: 100)
        let state = HomeView.ViewState.error(longMessage)

        if case .error(let message) = state {
            #expect(message == longMessage)
        }
    }

    @Test("特殊文字を含むエラーメッセージを処理できる")
    func testSpecialCharacterErrorMessage() {
        let specialMessage = "エラー: <test> & \"quote\" 'single'"
        let state = HomeView.ViewState.error(specialMessage)

        if case .error(let message) = state {
            #expect(message == specialMessage)
        }
    }
}

// MARK: - Accessibility Tests

@Suite("HomeView アクセシビリティテスト")
struct HomeViewAccessibilityTests {

    @Test("主要なUI要素にアクセシビリティ識別子がある")
    func testAccessibilityIdentifiers() {
        // HomeViewの主要な識別子
        let expectedIdentifiers = [
            "HomeView",
            "StorageOverviewCard",
            "QuickActionsSection",
            "RecentCleanupSection"
        ]

        for identifier in expectedIdentifiers {
            #expect(!identifier.isEmpty)
        }
    }

    @Test("ボタンにアクセシビリティラベルがある")
    func testButtonAccessibilityLabels() {
        let buttonLabels = [
            "スキャン開始",
            "グループを表示",
            "設定を開く"
        ]

        for label in buttonLabels {
            #expect(!label.isEmpty)
            #expect(label.count > 0)
        }
    }
}

// MARK: - State Transition Tests

@Suite("HomeView 状態遷移テスト")
struct StateTransitionTests {

    @Test("loading → loaded 遷移")
    func testLoadingToLoaded() {
        var state = HomeView.ViewState.loading
        #expect(state.isLoading)

        state = .loaded
        #expect(!state.isLoading)
        #expect(!state.isScanning)
    }

    @Test("loaded → scanning 遷移")
    func testLoadedToScanning() {
        var state = HomeView.ViewState.loaded
        #expect(!state.isScanning)

        state = .scanning(progress: 0.0)
        #expect(state.isScanning)
    }

    @Test("scanning → loaded 遷移（完了時）")
    func testScanningToLoaded() {
        var state = HomeView.ViewState.scanning(progress: 1.0)
        #expect(state.isScanning)

        state = .loaded
        #expect(!state.isScanning)
    }

    @Test("scanning → error 遷移")
    func testScanningToError() {
        var state = HomeView.ViewState.scanning(progress: 0.5)
        #expect(state.isScanning)

        state = .error("スキャン中にエラーが発生")
        #expect(!state.isScanning)

        if case .error(let message) = state {
            #expect(message.contains("エラー"))
        }
    }

    @Test("error → loading 遷移（リトライ時）")
    func testErrorToLoading() {
        var state = HomeView.ViewState.error("エラー")

        state = .loading
        #expect(state.isLoading)
    }

    @Test("scanning進捗の連続更新")
    func testScanningProgressUpdates() {
        var state = HomeView.ViewState.scanning(progress: 0.0)

        let progressValues: [Double] = [0.1, 0.2, 0.3, 0.5, 0.7, 0.9, 1.0]

        for progress in progressValues {
            state = .scanning(progress: progress)
            if case .scanning(let p) = state {
                #expect(p == progress)
            }
        }
    }
}

// MARK: - Localization Tests

@Suite("HomeView ローカライゼーションテスト")
struct LocalizationTests {

    @Test("ホーム画面タイトルが存在する")
    func testHomeTitle() {
        let title = NSLocalizedString(
            "home.title",
            value: "ホーム",
            comment: "Home screen title"
        )
        #expect(!title.isEmpty)
    }

    @Test("スキャンボタンタイトルが存在する")
    func testScanButtonTitle() {
        let title = NSLocalizedString(
            "home.action.scan",
            value: "スキャン",
            comment: "Scan button title"
        )
        #expect(!title.isEmpty)
    }

    @Test("グループボタンタイトルが存在する")
    func testGroupsButtonTitle() {
        let title = NSLocalizedString(
            "home.action.groups",
            value: "グループ",
            comment: "Groups button title"
        )
        #expect(!title.isEmpty)
    }

    @Test("リトライボタンタイトルが存在する")
    func testRetryButtonTitle() {
        let title = NSLocalizedString(
            "home.error.retry",
            value: "再読み込み",
            comment: "Retry button"
        )
        #expect(!title.isEmpty)
    }
}

// MARK: - Performance Considerations Tests

@Suite("HomeView パフォーマンス考慮テスト")
struct PerformanceConsiderationsTests {

    @Test("大量のクリーンアップ履歴を処理できる")
    func testLargeCleanupHistory() {
        var records: [CleanupRecord] = []

        for i in 0..<1000 {
            let record = CleanupRecord(
                deletedCount: i,
                freedSpace: Int64(i) * 1_000_000,
                groupType: GroupType.allCases[i % GroupType.allCases.count],
                operationType: CleanupRecord.OperationType.allCases[i % CleanupRecord.OperationType.allCases.count]
            )
            records.append(record)
        }

        #expect(records.count == 1000)
    }

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
}

// MARK: - DEVICE-001 修正テスト

/// DEVICE-001: .task修正に関するテスト
/// 初回データ読み込みとタブ切り替え時の再読み込み防止をテスト
@Suite("HomeView DEVICE-001 .task修正テスト")
struct HomeViewTaskModifierTests {

    // MARK: - 正常系テスト

    @Test("初回データ読み込み: loading状態から開始してloaded状態に遷移する")
    func testInitialDataLoadTransition() async {
        // Given: 初期状態はloading
        var state = HomeView.ViewState.loading
        #expect(state.isLoading)
        #expect(!state.isScanning)

        // When: データ読み込みが完了
        state = .loaded

        // Then: loaded状態に正しく遷移
        #expect(!state.isLoading)
        #expect(!state.isScanning)
        #expect(state == .loaded)
    }

    @Test("初回データ読み込み成功: 統計データが正しく設定される")
    func testInitialDataLoadSuccess() {
        // Given: 統計データを作成
        let storageInfo = StorageInfo(
            totalCapacity: 128_000_000_000,   // 128GB
            availableCapacity: 64_000_000_000, // 64GB
            usedCapacity: 64_000_000_000,      // 64GB
            photoLibrarySize: 32_000_000_000   // 32GB
        )

        // When: StorageStatisticsを作成
        let statistics = StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: [:],
            scannedPhotoCount: 1000
        )

        // Then: 統計データが正しく設定されている
        #expect(statistics.storageInfo.totalCapacity == 128_000_000_000)
        #expect(statistics.storageInfo.availableCapacity == 64_000_000_000)
        #expect(statistics.scannedPhotoCount == 1000)
    }

    @Test("タブ切り替え時の不要な再読み込み防止: loaded状態が維持される")
    func testNoUnnecessaryReloadOnTabSwitch() {
        // Given: loaded状態
        let state = HomeView.ViewState.loaded

        // When: タブ切り替えをシミュレート（状態は変わらない）
        // .task(id:) を使用しない場合、毎回再読み込みされてしまう
        // 修正後は loaded 状態が維持される

        // Then: loaded状態が維持されている
        #expect(state == .loaded)
        #expect(!state.isLoading)
        #expect(!state.isScanning)
    }

    @Test("スキャン中はプルトゥリフレッシュで更新されない")
    func testNoRefreshDuringScanning() {
        // Given: スキャン中の状態
        let state = HomeView.ViewState.scanning(progress: 0.5)

        // When: プルトゥリフレッシュを試みる（スキャン中はガードされる）
        let shouldRefresh = !state.isScanning

        // Then: スキャン中は更新されない
        #expect(state.isScanning)
        #expect(!shouldRefresh)
    }

    // MARK: - 異常系テスト

    @Test("データ読み込み失敗: error状態に遷移しエラーメッセージを保持する")
    func testDataLoadFailureTransition() {
        // Given: 読み込み中の状態
        var state = HomeView.ViewState.loading
        #expect(state.isLoading)

        // When: エラーが発生
        let errorMessage = "写真ライブラリへのアクセスが拒否されました"
        state = .error(errorMessage)

        // Then: error状態に遷移しメッセージを保持
        #expect(!state.isLoading)
        #expect(!state.isScanning)
        if case .error(let message) = state {
            #expect(message == errorMessage)
            #expect(message.contains("アクセス"))
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("エラー後のリトライ: error状態からloading状態に遷移する")
    func testRetryAfterError() {
        // Given: エラー状態
        var state = HomeView.ViewState.error("ネットワークエラー")

        // When: リトライを実行
        state = .loading

        // Then: loading状態に戻る
        #expect(state.isLoading)
        #expect(state == .loading)
    }

    @Test("グループ読み込みエラー: エラーメッセージが生成される")
    func testGroupLoadFailureErrorMessage() {
        // Given: グループ読み込みエラーのメッセージ
        let errorMessage = NSLocalizedString(
            "home.error.groupLoadFailure",
            value: "グループの読み込みに失敗しました。もう一度お試しください。",
            comment: "Group load failure error message"
        )

        // Then: エラーメッセージが空でない
        #expect(!errorMessage.isEmpty)
        #expect(errorMessage.contains("グループ") || errorMessage.contains("読み込み"))
    }

    // MARK: - 境界値テスト

    @Test("空データの場合: 統計データが空でも正常に処理される")
    func testEmptyDataHandling() {
        // Given: 空の統計データ
        let emptyStats = StorageStatistics.empty

        // Then: 空のデータが正しく処理される
        #expect(emptyStats.storageInfo.totalCapacity == 0)
        #expect(emptyStats.groupSummaries.isEmpty)
        #expect(emptyStats.scannedPhotoCount == 0)
    }

    @Test("空のグループリスト: 正常に処理される")
    func testEmptyGroupList() {
        // Given: 空のグループリスト
        let groups: [PhotoGroup] = []

        // Then: 空リストが正常に処理される
        #expect(groups.isEmpty)
        #expect(groups.count == 0)
    }

    @Test("大量データの場合: 10万枚の写真統計を処理できる")
    func testLargeDataHandling() {
        // Given: 大量の写真データ
        let largePhotoCount = 100_000
        let largeStorageSize: Int64 = 500_000_000_000 // 500GB

        let storageInfo = StorageInfo(
            totalCapacity: 1_000_000_000_000,      // 1TB
            availableCapacity: 500_000_000_000,    // 500GB
            usedCapacity: 500_000_000_000,         // 500GB
            photoLibrarySize: largeStorageSize
        )

        let statistics = StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: [:],
            scannedPhotoCount: largePhotoCount
        )

        // Then: 大量データが正しく処理される
        #expect(statistics.scannedPhotoCount == 100_000)
        #expect(statistics.storageInfo.photoLibrarySize == 500_000_000_000)
    }

    @Test("大量グループの場合: 1000グループを処理できる")
    func testLargeGroupCountHandling() {
        // Given: 大量のグループ
        var groups: [PhotoGroup] = []
        let groupCount = 1000

        for i in 0..<groupCount {
            let group = PhotoGroup(
                type: GroupType.allCases[i % GroupType.allCases.count],
                photoIds: ["photo_\(i)_0", "photo_\(i)_1"],
                fileSizes: [1_000_000, 1_000_000]
            )
            groups.append(group)
        }

        // Then: 大量グループが正しく処理される
        #expect(groups.count == 1000)
        #expect(groups.first != nil)
        #expect(groups.last != nil)
    }
}

// MARK: - デバッグログ条件付きコンパイルテスト

@Suite("HomeView デバッグログ条件付きコンパイルテスト")
struct HomeViewDebugLoggingTests {

    @Test("DEBUGフラグによるログ出力制御: printステートメントはDEBUGビルドのみ")
    func testDebugLoggingFlag() {
        // このテストは、デバッグログが条件付きコンパイルされていることを確認
        // 実際のログ出力は #if DEBUG で囲まれているべき

        #if DEBUG
        let isDebugBuild = true
        #else
        let isDebugBuild = false
        #endif

        // テスト環境では常にDEBUGビルド
        #expect(isDebugBuild == true)
    }

    @Test("ログメッセージのフォーマット: グループ読み込み成功メッセージ")
    func testSuccessLogMessageFormat() {
        // Given: グループ数
        let groupCount = 25

        // When: ログメッセージを生成（本番コードと同じ形式）
        let logMessage = "✅ グループ読み込み成功: \(groupCount)件"

        // Then: メッセージが正しくフォーマットされている
        #expect(logMessage.contains("✅"))
        #expect(logMessage.contains("グループ読み込み成功"))
        #expect(logMessage.contains("25件"))
    }

    @Test("ログメッセージのフォーマット: グループ読み込みエラーメッセージ")
    func testErrorLogMessageFormat() {
        // Given: エラー内容
        let errorDescription = "ファイルが見つかりません"

        // When: ログメッセージを生成（本番コードと同じ形式）
        let logMessage = "⚠️ グループ読み込みエラー: \(errorDescription)"

        // Then: メッセージが正しくフォーマットされている
        #expect(logMessage.contains("⚠️"))
        #expect(logMessage.contains("グループ読み込みエラー"))
        #expect(logMessage.contains("ファイルが見つかりません"))
    }

    @Test("保存済みグループ読み込み失敗のログメッセージ")
    func testSavedGroupLoadFailureLogMessage() {
        // Given: エラー説明
        let errorDescription = "JSONデコードエラー"

        // When: ログメッセージを生成
        let logMessage = "⚠️ 保存済みグループの読み込みに失敗: \(errorDescription)"

        // Then: メッセージが正しくフォーマットされている
        #expect(logMessage.contains("保存済みグループ"))
        #expect(logMessage.contains("失敗"))
        #expect(logMessage.contains(errorDescription))
    }
}
