//
//  E2EPhotoGroupWorkflowTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoGroup機能のE2Eテスト
//  ホーム → グループ一覧 → 削除までの全体フロー
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - E2EPhotoGroupWorkflowTests

/// PhotoGroup機能のエンドツーエンドテスト
/// ユーザーの実際の操作フローをシミュレート
@MainActor
@Suite("E2E: PhotoGroupワークフロー")
struct E2EPhotoGroupWorkflowTests {

    // MARK: - テストデータ

    /// テスト用UserDefaults
    private let testDefaults: UserDefaults

    /// テスト用キー
    private let groupsKey = "photo_groups"

    init() {
        testDefaults = UserDefaults(suiteName: "test.suite.\(UUID().uuidString)")!
    }

    // MARK: - ヘルパー関数

    /// テスト用グループを作成
    private func createTestGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["photo1", "photo2", "photo3", "photo4", "photo5"],
                fileSizes: [1_000_000, 1_200_000, 900_000, 1_100_000, 950_000],
                bestShotIndex: 1
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["screen1", "screen2", "screen3"],
                fileSizes: [500_000, 600_000, 550_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["blur1", "blur2"],
                fileSizes: [2_000_000, 1_800_000]
            ),
            PhotoGroup(
                type: .selfie,
                photoIds: ["selfie1", "selfie2", "selfie3"],
                fileSizes: [1_500_000, 1_600_000, 1_400_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .largeVideo,
                photoIds: ["video1", "video2"],
                fileSizes: [150_000_000, 200_000_000]
            )
        ]
    }

    /// グループを保存
    private func saveGroups(_ groups: [PhotoGroup]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(groups)
        testDefaults.set(data, forKey: groupsKey)
    }

    /// グループを読み込み
    private func loadGroups() throws -> [PhotoGroup] {
        guard let data = testDefaults.data(forKey: groupsKey) else {
            return []
        }
        let decoder = JSONDecoder()
        return try decoder.decode([PhotoGroup].self, from: data)
    }

    /// グループをクリア
    private func clearGroups() {
        testDefaults.removeObject(forKey: groupsKey)
    }

    /// グループが存在するか確認
    private func hasGroups() -> Bool {
        testDefaults.data(forKey: groupsKey) != nil
    }

    // MARK: - E2Eシナリオ1: 初回スキャン → 保存 → 表示

    @Test("シナリオ1: 初回スキャンからグループ表示まで")
    func testScenario1_FirstScanToDisplay() async throws {
        // Given: 初期状態（グループなし）
        clearGroups()
        #expect(hasGroups() == false)

        // Step 1: スキャン実行（モックデータ生成）
        let scannedGroups = createTestGroups()
        #expect(scannedGroups.count == 5)

        // Step 2: グループを保存
        try saveGroups(scannedGroups)
        #expect(hasGroups() == true)

        // Step 3: 保存されたグループを読み込み
        let loadedGroups = try loadGroups()
        #expect(loadedGroups.count == 5)

        // Step 4: グループ統計を確認
        let stats = loadedGroups.statistics
        #expect(stats.totalGroups == 5)
        #expect(stats.totalPhotos == 15)
        #expect(stats.reclaimableSize > 0)

        // Step 5: タイプ別フィルタ
        let similarGroups = loadedGroups.filterByType(.similar)
        #expect(similarGroups.count == 1)
        #expect(similarGroups[0].count == 5)
    }

    // MARK: - E2Eシナリオ2: グループ選択 → 削除 → 永続化

    @Test("シナリオ2: グループ選択から削除まで")
    func testScenario2_SelectAndDelete() async throws {
        // Given: 保存済みのグループ
        var groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: グループを読み込み
        groups = try loadGroups()
        #expect(groups.count == 5)

        // Step 2: 削除するグループを選択（similarとscreenshot）
        groups[0] = groups[0].withSelection(true)
        groups[1] = groups[1].withSelection(true)

        let selectedGroups = groups.selectedGroups
        #expect(selectedGroups.count == 2)

        // Step 3: 削除確認情報を計算
        let totalPhotos = selectedGroups.reduce(0) { $0 + $1.count }
        let totalSize = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }

        #expect(totalPhotos == 8) // similar: 5枚 + screenshot: 3枚
        #expect(totalSize > 0)

        // Step 4: 削除実行
        let remainingGroups = groups.filter { !$0.isSelected }
        #expect(remainingGroups.count == 3)

        // Step 5: 削除後のグループを保存
        try saveGroups(remainingGroups)

        // Step 6: 削除が永続化されたか確認
        let savedGroups = try loadGroups()
        #expect(savedGroups.count == 3)
        #expect(savedGroups.contains { $0.type == .blurry })
        #expect(savedGroups.contains { $0.type == .selfie })
        #expect(savedGroups.contains { $0.type == .largeVideo })
    }

    // MARK: - E2Eシナリオ3: フィルタ → ソート → 選択

    @Test("シナリオ3: フィルタとソートの組み合わせ")
    func testScenario3_FilterAndSort() async throws {
        // Given: 保存済みのグループ
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: グループを読み込み
        var loadedGroups = try loadGroups()

        // Step 2: タイプでフィルタ
        let similarAndSelfie = loadedGroups.filterByTypes([.similar, .selfie])
        #expect(similarAndSelfie.count == 2)

        // Step 3: 削減可能サイズでソート
        let sorted = similarAndSelfie.sortedByReclaimableSize
        #expect(sorted[0].reclaimableSize >= sorted[1].reclaimableSize)

        // Step 4: 最も削減効果の高いグループを選択
        let topGroup = sorted[0]
        if let index = loadedGroups.firstIndex(where: { $0.id == topGroup.id }) {
            loadedGroups[index] = loadedGroups[index].withSelection(true)
        }

        // Step 5: 選択状態を保存
        try saveGroups(loadedGroups)

        // Step 6: 選択状態が永続化されたか確認
        let reloaded = try loadGroups()
        #expect(reloaded.selectedGroups.count == 1)
    }

    // MARK: - E2Eシナリオ4: 全選択 → 全削除 → クリア

    @Test("シナリオ4: 全削除フロー")
    func testScenario4_DeleteAll() async throws {
        // Given: 保存済みのグループ
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: すべて選択
        var loadedGroups = try loadGroups()
        loadedGroups = loadedGroups.settingSelection(true)
        #expect(loadedGroups.selectedGroups.count == loadedGroups.count)

        // Step 2: すべて削除
        let remainingGroups = loadedGroups.filter { !$0.isSelected }
        #expect(remainingGroups.isEmpty)

        // Step 3: 空配列を保存
        try saveGroups(remainingGroups)

        // Step 4: 削除完了を確認
        let finalGroups = try loadGroups()
        #expect(finalGroups.isEmpty)

        // Step 5: クリア処理（オプション）
        clearGroups()
        #expect(hasGroups() == false)
    }

    // MARK: - E2Eシナリオ5: ベストショット変更 → 削除候補再計算

    @Test("シナリオ5: ベストショット変更フロー")
    func testScenario5_ChangeBestShot() async throws {
        // Given: ベストショットが設定されたグループ
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: similar グループを取得
        var loadedGroups = try loadGroups()
        guard let similarIndex = loadedGroups.firstIndex(where: { $0.type == .similar }) else {
            Issue.record("Similar group not found")
            return
        }

        var similarGroup = loadedGroups[similarIndex]
        let originalBestShot = similarGroup.bestShotIndex
        #expect(originalBestShot == 1)

        // Step 2: ベストショットを変更
        similarGroup = similarGroup.withBestShot(at: 3)
        loadedGroups[similarIndex] = similarGroup

        // Step 3: 削除候補が変わったか確認
        let newCandidates = similarGroup.deletionCandidateIds
        #expect(newCandidates.count == 4) // 5枚中4枚が削除候補
        #expect(!newCandidates.contains("photo4")) // 新しいベストショット

        // Step 4: 変更を保存
        try saveGroups(loadedGroups)

        // Step 5: 変更が永続化されたか確認
        let reloaded = try loadGroups()
        let reloadedSimilar = reloaded.first { $0.type == .similar }
        #expect(reloadedSimilar?.bestShotIndex == 3)
    }

    // MARK: - E2Eシナリオ6: 設定連携テスト

    @Test("シナリオ6: 設定とグループの連携")
    func testScenario6_SettingsIntegration() async throws {
        // Given: 設定とグループの両方を扱う
        let settingsDefaults = UserDefaults(suiteName: "test.settings.\(UUID().uuidString)")!
        let settingsRepo = SettingsRepository(userDefaults: settingsDefaults)
        let settingsService = SettingsService(repository: settingsRepo)

        // Step 1: グループを保存
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 2: 最小グループサイズを設定
        var analysisSettings = settingsService.settings.analysisSettings
        analysisSettings.minGroupSize = 3
        try settingsService.updateAnalysisSettings(analysisSettings)

        // Step 3: 設定に基づいてグループをフィルタ
        let loadedGroups = try loadGroups()
        let validGroups = loadedGroups.filter {
            $0.count >= settingsService.settings.analysisSettings.minGroupSize
        }

        // Then: 最小サイズ未満のグループは除外される
        #expect(validGroups.allSatisfy { $0.count >= 3 })
    }

    // MARK: - E2Eシナリオ7: エラーリカバリー

    @Test("シナリオ7: データ破損からのリカバリー")
    func testScenario7_ErrorRecovery() async throws {
        // Given: 正常なグループを保存
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: データを破損させる
        let corruptedData = "invalid json".data(using: .utf8)!
        testDefaults.set(corruptedData, forKey: groupsKey)

        // Step 2: 読み込み試行
        #expect(throws: (any Error).self) {
            _ = try loadGroups()
        }

        // Step 3: リカバリー処理（クリアして再スキャン）
        clearGroups()
        #expect(hasGroups() == false)

        // Step 4: 新しいスキャン結果を保存
        let newGroups = createTestGroups()
        try saveGroups(newGroups)

        // Step 5: 正常に読み込めることを確認
        let recovered = try loadGroups()
        #expect(recovered.count == 5)
    }

    // MARK: - E2Eシナリオ8: 増分更新

    @Test("シナリオ8: グループの増分更新")
    func testScenario8_IncrementalUpdate() async throws {
        // Given: 初期グループを保存
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: 新しいグループを追加
        let newGroup = PhotoGroup(
            type: .duplicate,
            photoIds: ["dup1", "dup2"],
            fileSizes: [1_000_000, 1_000_000]
        )

        var loadedGroups = try loadGroups()
        loadedGroups.append(newGroup)

        // Step 2: 更新を保存
        try saveGroups(loadedGroups)

        // Step 3: 追加されたか確認
        let updated = try loadGroups()
        #expect(updated.count == 6)
        #expect(updated.contains { $0.type == .duplicate })

        // Step 4: 既存のグループが保持されているか確認
        #expect(updated.contains { $0.type == .similar })
        #expect(updated.contains { $0.type == .screenshot })
    }

    // MARK: - E2Eシナリオ9: 統計情報の追跡

    @Test("シナリオ9: 削除前後の統計情報")
    func testScenario9_StatisticsTracking() async throws {
        // Given: 初期グループ
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: 削除前の統計
        let beforeStats = groups.statistics
        let beforeReclaimable = beforeStats.reclaimableSize
        #expect(beforeReclaimable > 0)

        // Step 2: 削減効果の高いグループを削除
        let sortedBySize = groups.sortedByReclaimableSize
        let toDelete = Array(sortedBySize.prefix(2)) // 上位2つ

        let remainingGroups = groups.filter { group in
            !toDelete.contains { $0.id == group.id }
        }

        // Step 3: 削除後の統計
        let afterStats = remainingGroups.statistics
        let afterReclaimable = afterStats.reclaimableSize

        // Step 4: 削減量を計算
        let deleted = beforeReclaimable - afterReclaimable
        #expect(deleted > 0)

        // Step 5: 統計を保存
        try saveGroups(remainingGroups)

        // Step 6: 最終確認
        let finalGroups = try loadGroups()
        let finalStats = finalGroups.statistics
        #expect(finalStats.reclaimableSize == afterReclaimable)
    }

    // MARK: - E2Eシナリオ10: タイプ別削除

    @Test("シナリオ10: 特定タイプのみ削除")
    func testScenario10_DeleteSpecificType() async throws {
        // Given: 複数タイプのグループ
        let groups = createTestGroups()
        try saveGroups(groups)

        // Step 1: スクリーンショットのみ削除
        let loadedGroups = try loadGroups()
        let screenshotGroups = loadedGroups.filterByType(.screenshot)
        #expect(screenshotGroups.count == 1)

        // Step 2: スクリーンショット以外を保持
        let nonScreenshot = loadedGroups.filter { $0.type != .screenshot }
        #expect(nonScreenshot.count == 4)

        // Step 3: 保存
        try saveGroups(nonScreenshot)

        // Step 4: 確認
        let final = try loadGroups()
        #expect(final.filterByType(.screenshot).isEmpty)
        #expect(final.count == 4)
    }
}
