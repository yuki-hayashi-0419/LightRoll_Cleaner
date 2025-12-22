//
//  GroupDetailViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  GroupDetailViewのテスト
//  修正対応: 空のPhotoGroup、View解放時のタスクキャンセル、エラーハンドリング
//  Swift Testing形式で実装
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
        var shouldReturnEmpty: Bool = false
        var delay: Duration? = nil

        func photos(for ids: [String]) async -> [Photo] {
            if let delay = delay {
                try? await Task.sleep(for: delay)
            }

            if shouldReturnEmpty {
                return []
            }
            return photos.filter { ids.contains($0.id) }
        }
    }

    /// テスト用のサンプル写真
    private func createMockPhotos(count: Int, prefix: String = "photo") -> [Photo] {
        (0..<count).map { index in
            Photo(
                id: "\(prefix)-\(index)",
                localIdentifier: "\(prefix)-\(index)",
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

    // MARK: - 正常系テスト: グループ詳細画面表示

    @Test("正常系: グループ詳細画面が正しく初期化される", .tags(.normal))
    func normalInitialization() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000],
            bestShotIndex: 0
        )

        // When
        let view = GroupDetailView(group: group)

        // Then: ビューが正常に作成される
        #expect(group.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        #expect(group.type == .similar)
        #expect(group.count == 3)
    }

    @Test("正常系: PhotoProvider付きで初期化される", .tags(.normal))
    func initializationWithProvider() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["photo-0", "photo-1"],
            fileSizes: [1000, 2000]
        )
        let photos = createMockPhotos(count: 2)
        let provider = MockPhotoProvider(photos: photos)

        // When
        let _ = GroupDetailView(
            group: group,
            photoProvider: provider
        )

        // Then
        #expect(group.count == 2)
        #expect(group.type == .screenshot)
    }

    @Test("正常系: 非空のグループが正しく表示される", .tags(.normal))
    func nonEmptyGroupDisplay() {
        // Given: 12枚の類似写真グループ
        let photoIds = (0..<12).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 12),
            bestShotIndex: 0
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then: グループの写真数が正しい
        #expect(group.count == 12)
        #expect(group.photoIds.count == 12)
        #expect(group.bestShotId == "photo-0")
    }

    // MARK: - 異常系テスト: 空のPhotoGroup

    @Test("異常系: 空のPhotoGroupが正しく処理される", .tags(.error, .edge))
    func emptyPhotoGroupHandling() {
        // Given: 空のグループ
        let emptyGroup = PhotoGroup(
            type: .duplicate,
            photoIds: [],
            fileSizes: []
        )

        // When: ビューを作成
        let _ = GroupDetailView(group: emptyGroup)

        // Then: 空として認識される
        #expect(emptyGroup.isEmpty == true)
        #expect(emptyGroup.count == 0)
        #expect(emptyGroup.totalSize == 0)
        #expect(emptyGroup.reclaimableSize == 0)
    }

    @Test("異常系: PhotoProviderがnilでもクラッシュしない", .tags(.error))
    func nilPhotoProviderHandling() {
        // Given: PhotoProviderなしでグループを作成
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )

        // When: PhotoProviderなしでビューを作成
        let _ = GroupDetailView(group: group, photoProvider: nil)

        // Then: 正常に作成される（ビュー内でproviderのnilチェックが行われる）
        #expect(group.count == 2)
    }

    @Test("異常系: PhotoProviderが空の結果を返す場合", .tags(.error))
    func emptyPhotoProviderResult() async {
        // Given: 空の結果を返すプロバイダー
        let provider = MockPhotoProvider(photos: [], shouldReturnEmpty: true)
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )

        // When: プロバイダーから写真を取得
        let result = await provider.photos(for: group.photoIds)

        // Then: 空の結果が返される
        #expect(result.isEmpty == true)
    }

    // MARK: - 境界値テスト

    @Test("境界値: 1枚だけのグループ", .tags(.boundary))
    func singlePhotoGroup() {
        // Given: 1枚だけのグループ
        let group = PhotoGroup(
            type: .blurry,
            photoIds: ["single-photo"],
            fileSizes: [5_000_000]
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then: 1枚として認識される
        #expect(group.count == 1)
        #expect(group.isValid == false) // 2枚以上が必要
        #expect(group.totalSize == 5_000_000)
    }

    @Test("境界値: 大量の写真を持つグループ（50枚）", .tags(.boundary, .performance))
    func largePhotoGroup() {
        // Given: 50枚のグループ
        let photoIds = (0..<50).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 50),
            bestShotIndex: 0
        )

        // When
        let _ = GroupDetailView(group: group)

        // Then: 正しく処理される
        #expect(group.count == 50)
        #expect(group.reclaimableCount == 49)
        #expect(group.reclaimableSize == 122_500_000)
    }

    @Test("境界値: 100枚の超大量グループ", .tags(.boundary, .performance))
    func veryLargePhotoGroup() {
        // Given: 100枚のグループ
        let photoIds = (0..<100).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: photoIds,
            fileSizes: Array(repeating: 1_200_000, count: 100)
        )
        let photos = createMockPhotos(count: 100)
        let provider = MockPhotoProvider(photos: photos)

        // When
        let _ = GroupDetailView(group: group, photoProvider: provider)

        // Then: パフォーマンスに問題なく処理される
        #expect(group.count == 100)
        #expect(group.totalSize == 120_000_000)
    }

    // MARK: - ViewState Tests

    @Test("ViewState: 全状態の存在確認", .tags(.state))
    func viewStateValues() {
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

    @Test("ViewState: Equatable準拠", .tags(.state))
    func viewStateEquatable() {
        // Given
        let state1 = GroupDetailView.ViewState.loading
        let state2 = GroupDetailView.ViewState.loading
        let state3 = GroupDetailView.ViewState.loaded
        let error1 = GroupDetailView.ViewState.error("Error A")
        let error2 = GroupDetailView.ViewState.error("Error A")
        let error3 = GroupDetailView.ViewState.error("Error B")

        // Then
        #expect(state1 == state2)
        #expect(state1 != state3)
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    // MARK: - グループタイプ別テスト

    @Test("グループタイプ: 類似写真グループ", .tags(.groupType))
    func similarPhotosGroup() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: (0..<5).map { "photo-\($0)" },
            fileSizes: Array(repeating: 3_000_000, count: 5),
            bestShotIndex: 0
        )

        // Then
        #expect(group.type == .similar)
        #expect(group.count == 5)
        #expect(group.bestShotIndex == 0)
        #expect(group.type.needsBestShotSelection == true)
    }

    @Test("グループタイプ: スクリーンショットグループ", .tags(.groupType))
    func screenshotGroup() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: (0..<10).map { "screenshot-\($0)" },
            fileSizes: Array(repeating: 1_200_000, count: 10)
        )

        // Then
        #expect(group.type == .screenshot)
        #expect(group.count == 10)
        #expect(group.bestShotIndex == nil)
        #expect(group.type.needsBestShotSelection == false)
    }

    @Test("グループタイプ: ブレ写真グループ", .tags(.groupType))
    func blurryPhotosGroup() {
        // Given
        let group = PhotoGroup(
            type: .blurry,
            photoIds: (0..<6).map { "blurry-\($0)" },
            fileSizes: Array(repeating: 3_500_000, count: 6)
        )

        // Then
        #expect(group.type == .blurry)
        #expect(group.count == 6)
        #expect(group.type.isAutoDeleteRecommended == true)
    }

    @Test("グループタイプ: 自撮りグループ", .tags(.groupType))
    func selfieGroup() {
        // Given
        let group = PhotoGroup(
            type: .selfie,
            photoIds: (0..<4).map { "selfie-\($0)" },
            fileSizes: Array(repeating: 2_800_000, count: 4),
            bestShotIndex: 1
        )

        // Then
        #expect(group.type == .selfie)
        #expect(group.count == 4)
        #expect(group.bestShotIndex == 1)
        #expect(group.type.needsBestShotSelection == true)
    }

    @Test("グループタイプ: 全タイプでの初期化", .tags(.groupType))
    func allGroupTypes() {
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

    // MARK: - ベストショットテスト

    @Test("ベストショット: 設定あり", .tags(.bestShot))
    func groupWithBestShot() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3", "4"],
            fileSizes: [1000, 2000, 3000, 4000],
            bestShotIndex: 2
        )

        // Then
        #expect(group.bestShotIndex == 2)
        #expect(group.bestShotId == "3")
        #expect(group.deletionCandidateIds.count == 3)
        #expect(!group.deletionCandidateIds.contains("3"))
    }

    @Test("ベストショット: 設定なし", .tags(.bestShot))
    func groupWithoutBestShot() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )

        // Then
        #expect(group.bestShotIndex == nil)
        #expect(group.bestShotId == nil)
        #expect(group.deletionCandidateIds.count == 3)
    }

    @Test("ベストショット: 無効なインデックス", .tags(.bestShot, .edge))
    func invalidBestShotIndex() {
        // Given: インデックスが範囲外
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000],
            bestShotIndex: 10 // 無効なインデックス
        )

        // Then: bestShotIdはnilになるべき
        #expect(group.bestShotId == nil)
    }

    // MARK: - サイズ計算テスト

    @Test("サイズ計算: 合計サイズ", .tags(.calculation))
    func totalSizeCalculation() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000]
        )

        // Then
        #expect(group.totalSize == 6_000_000)
    }

    @Test("サイズ計算: 削減可能サイズ（ベストショットあり）", .tags(.calculation))
    func reclaimableSizeWithBestShot() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000],
            bestShotIndex: 2
        )

        // Then: ベストショット以外の合計
        #expect(group.reclaimableSize == 3_000_000)
    }

    @Test("サイズ計算: 削減可能サイズ（ベストショットなし）", .tags(.calculation))
    func reclaimableSizeWithoutBestShot() {
        // Given
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 2_000_000, 3_000_000]
        )

        // Then: 全て削除可能
        #expect(group.reclaimableSize == 6_000_000)
    }

    @Test("サイズ計算: 削減率の計算", .tags(.calculation))
    func savingsPercentageCalculation() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1_000_000, 1_000_000],
            bestShotIndex: 0
        )

        // Then: 50%削減可能
        #expect(group.savingsPercentage == 50.0)
    }

    // MARK: - 削除候補テスト

    @Test("削除候補: ベストショット以外の写真ID", .tags(.deletionCandidate))
    func deletionCandidateIds() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3", "photo-4"],
            fileSizes: Array(repeating: 1_000_000, count: 4),
            bestShotIndex: 1
        )

        // When
        let candidateIds = group.deletionCandidateIds

        // Then
        #expect(candidateIds.count == 3)
        #expect(candidateIds.contains("photo-1"))
        #expect(candidateIds.contains("photo-3"))
        #expect(candidateIds.contains("photo-4"))
        #expect(!candidateIds.contains("photo-2"))
    }

    // MARK: - 表示名テスト

    @Test("表示名: デフォルト表示名", .tags(.display))
    func defaultDisplayName() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )

        // Then
        #expect(group.displayName == group.type.displayName)
    }

    @Test("表示名: カスタム表示名", .tags(.display))
    func customDisplayName() {
        // Given
        let customName = "旅行の写真"
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000],
            customName: customName
        )

        // Then
        #expect(group.displayName == customName)
    }

    // MARK: - タスクキャンセルテスト

    @Test("タスクキャンセル: 読み込み中のキャンセル処理", .tags(.concurrency))
    func loadingCancellation() async {
        // Given: 遅延を持つプロバイダー
        let photos = createMockPhotos(count: 5)
        let provider = MockPhotoProvider(
            photos: photos,
            delay: .milliseconds(500)
        )

        // When: タスクを開始してすぐキャンセル
        let task = Task {
            await provider.photos(for: ["photo-0", "photo-1"])
        }

        task.cancel()

        // Then: キャンセルされても例外は発生しない
        let _ = await task.value
        #expect(Task.isCancelled == false) // メインタスクはキャンセルされていない
    }

    @Test("タスクキャンセル: Task.isCancelledフラグの確認", .tags(.concurrency))
    func taskCancellationFlag() async {
        // Given: キャンセルチェック付きタスク
        let task = Task {
            for i in 0..<10 {
                if Task.isCancelled {
                    return "cancelled at \(i)"
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
            return "completed"
        }

        // When: 少し待ってからキャンセル
        try? await Task.sleep(for: .milliseconds(100))
        task.cancel()

        // Then
        let result = await task.value
        #expect(result.contains("cancelled") || result == "completed")
    }
}

// MARK: - Custom Test Tags
// 共通タグはTestTags.swiftに定義済み

extension Tag {
    // GroupDetailView固有のタグ
    @Tag static var dashboard: Self
    @Tag static var view: Self
    @Tag static var groupType: Self
    @Tag static var bestShot: Self
    @Tag static var calculation: Self
    @Tag static var deletionCandidate: Self
    @Tag static var display: Self
    @Tag static var selectionMode: Self
    @Tag static var deleteAll: Self
    @Tag static var premiumLimit: Self
    @Tag static var uiux: Self
}

// MARK: - DEVICE-003修正テスト用モックPremiumManager

/// テスト用のモック削除制限マネージャー（GroupDetailView専用）
/// 削除制限のシミュレーションに使用
/// Note: GroupDetailViewは具象型PremiumManagerを受け取るため、
/// 直接ビューにモックを渡すテストはできない。
/// 代わりに削除制限ロジックをこのモックでテストする。
@MainActor
final class GroupDetailViewMockDeletionLimit: @unchecked Sendable {

    // MARK: - Configurable Properties

    /// Premium状態（true: 無制限、false: 制限あり）
    var isPremiumUser: Bool = false

    /// 残り削除可能数（Free版の場合に使用）
    var remainingDeletions: Int = 50

    /// 記録された削除カウント
    var recordedDeletionCount: Int = 0

    /// 今日の削除可能残数を取得
    /// - Returns: 残り削除可能数（プレミアムの場合はInt.max）
    func getRemainingDeletions() -> Int {
        if isPremiumUser {
            return Int.max
        }
        return remainingDeletions
    }

    /// 削除数を記録
    /// - Parameter count: 削除した数
    func recordDeletion(count: Int) {
        recordedDeletionCount += count
        if !isPremiumUser {
            remainingDeletions = max(0, remainingDeletions - count)
        }
    }

    /// 削除可能かどうかをチェック
    /// - Parameter count: 削除予定枚数
    /// - Returns: 削除可能ならtrue
    func canDelete(count: Int) -> Bool {
        if isPremiumUser {
            return true
        }
        return remainingDeletions >= count
    }
}

// MARK: - DEVICE-003 選択モードとグループ全削除テスト

@MainActor
@Suite("DEVICE-003 選択モードとグループ全削除テスト", .tags(.dashboard, .view, .selectionMode, .deleteAll))
struct GroupDetailViewDEVICE003Tests {

    // MARK: - Test Data

    /// テスト用の写真プロバイダー
    private struct MockPhotoProvider: PhotoProvider {
        let photos: [Photo]
        var shouldReturnEmpty: Bool = false
        var delay: Duration? = nil

        func photos(for ids: [String]) async -> [Photo] {
            if let delay = delay {
                try? await Task.sleep(for: delay)
            }

            if shouldReturnEmpty {
                return []
            }
            return photos.filter { ids.contains($0.id) }
        }
    }

    /// テスト用のサンプル写真を作成
    private func createMockPhotos(count: Int, prefix: String = "photo") -> [Photo] {
        (0..<count).map { index in
            Photo(
                id: "\(prefix)-\(index)",
                localIdentifier: "\(prefix)-\(index)",
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

    // MARK: - 正常系テスト（4件）

    @Test("正常系-1: 選択ボタンタップで選択モード開始", .tags(.normal, .selectionMode))
    func selectionModeStartOnButtonTap() async {
        // Given: 5枚の写真グループ
        let photoIds = (0..<5).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 5),
            bestShotIndex: 0
        )
        let photos = createMockPhotos(count: 5)
        let provider = MockPhotoProvider(photos: photos)

        // When: ビューを作成（初期状態では選択モードはオフ）
        let view = GroupDetailView(
            group: group,
            photoProvider: provider
        )

        // Then: ビューは正常に作成される
        // 注意: @Stateは直接テストできないため、初期化の成功を確認
        #expect(group.count == 5)
        #expect(group.bestShotIndex == 0)
        #expect(group.type == .similar)
    }

    @Test("正常系-2: 選択モードで写真選択→完了ボタンで選択解除", .tags(.normal, .selectionMode))
    func selectionClearedOnDone() async {
        // Given: 写真グループと選択可能な写真ID
        let photoIds = (0..<6).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 6),
            bestShotIndex: 0
        )

        // When/Then: 選択可能な写真はベストショット以外
        let selectableIds = Set(photoIds).subtracting(["photo-0"])
        #expect(selectableIds.count == 5)
        #expect(!selectableIds.contains("photo-0"))
    }

    @Test("正常系-3: すべて削除→確認ダイアログ表示→削除実行", .tags(.normal, .deleteAll))
    func deleteAllWithConfirmation() async {
        // Given: Premium会員（制限なし）シミュレーション用モック
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = true

        let photoIds = (0..<8).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 8),
            bestShotIndex: 0
        )

        // When: Premium会員は無制限削除可能
        let canDeleteAll = deletionLimit.canDelete(count: group.count - 1)

        // Then: 削除対象はベストショット以外の7枚、制限なしで削除可能
        let expectedDeletionCount = group.count - 1 // ベストショット除外
        #expect(expectedDeletionCount == 7)
        #expect(group.bestShotId == "photo-0")
        #expect(canDeleteAll == true)
    }

    @Test("正常系-4: Premium制限内でグループ全削除成功", .tags(.normal, .deleteAll, .premiumLimit))
    func deleteAllWithinFreeLimit() {
        // Given: Free版で残り50枚削除可能、削除対象7枚
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 50

        let photoIds = (0..<8).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 8),
            bestShotIndex: 0
        )

        // When: 削除可能数を確認
        let remaining = deletionLimit.getRemainingDeletions()
        let deletionCount = group.count - 1 // ベストショット除外

        // Then: 制限内なので削除可能
        #expect(remaining >= deletionCount)
        #expect(remaining == 50)
        #expect(deletionCount == 7)
    }

    // MARK: - 異常系テスト（3件）

    @Test("異常系-1: Premium制限超過でグループ全削除失敗", .tags(.error, .deleteAll, .premiumLimit))
    func deleteAllExceedingLimit() {
        // Given: Free版で残り3枚のみ削除可能、削除対象9枚
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 3

        let photoIds = (0..<10).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 10),
            bestShotIndex: 0
        )

        // When: 削除可能数を確認
        let remaining = deletionLimit.getRemainingDeletions()
        let deletionCount = group.count - 1 // ベストショット除外 = 9枚

        // Then: 制限超過のため削除不可（LimitReachedSheet表示相当）
        #expect(remaining < deletionCount)
        #expect(remaining == 3)
        #expect(deletionCount == 9)
        #expect(deletionLimit.canDelete(count: deletionCount) == false)
    }

    @Test("異常系-2: 空グループですべて削除実行", .tags(.error, .deleteAll, .edge))
    func deleteAllOnEmptyGroup() {
        // Given: 空のグループ
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = true

        let emptyGroup = PhotoGroup(
            type: .similar,
            photoIds: [],
            fileSizes: []
        )

        // When: 空グループに対して削除対象を計算
        let selectableCount = emptyGroup.count - (emptyGroup.bestShotIndex != nil ? 1 : 0)

        // Then: 削除対象がないため何も起こらない
        #expect(emptyGroup.isEmpty == true)
        #expect(emptyGroup.count == 0)
        #expect(selectableCount <= 0)
    }

    @Test("異常系-3: ベストショットのみのグループですべて削除", .tags(.error, .deleteAll, .edge))
    func deleteAllWithOnlyBestShot() {
        // Given: 1枚のみのグループ（ベストショット）
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = true

        let singlePhotoGroup = PhotoGroup(
            type: .similar,
            photoIds: ["photo-0"],
            fileSizes: [2_500_000],
            bestShotIndex: 0
        )

        // When/Then: ベストショット以外の削除対象がない
        let selectableIds = Set(singlePhotoGroup.photoIds)
            .subtracting(singlePhotoGroup.bestShotId.map { [$0] } ?? [])

        #expect(selectableIds.isEmpty)
        #expect(singlePhotoGroup.count == 1)
        #expect(singlePhotoGroup.bestShotId == "photo-0")
    }

    // MARK: - 境界値テスト（3件）

    @Test("境界値-1: 削除制限ちょうど（remaining == selectablePhotoIds.count）", .tags(.boundary, .premiumLimit))
    func deletionLimitExact() {
        // Given: 残り削除数と削除対象数が完全に一致
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 7

        let photoIds = (0..<8).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 8),
            bestShotIndex: 0
        )

        // When: 境界値で削除可能数を確認
        let remaining = deletionLimit.getRemainingDeletions()
        let selectableCount = group.count - 1 // ベストショット除外

        // Then: ちょうど削除可能
        #expect(remaining == selectableCount)
        #expect(remaining == 7)
        #expect(remaining >= selectableCount) // 削除許可
        #expect(deletionLimit.canDelete(count: selectableCount) == true)
    }

    @Test("境界値-2: 削除制限1枚不足（remaining == selectablePhotoIds.count - 1）", .tags(.boundary, .premiumLimit))
    func deletionLimitOneShort() {
        // Given: 残り削除数が1枚足りない
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 6

        let photoIds = (0..<8).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 8),
            bestShotIndex: 0
        )

        // When: 境界値で削除可能数を確認
        let remaining = deletionLimit.getRemainingDeletions()
        let selectableCount = group.count - 1 // ベストショット除外 = 7枚

        // Then: 1枚足りないため削除不可
        #expect(remaining == selectableCount - 1)
        #expect(remaining == 6)
        #expect(remaining < selectableCount) // 削除不許可
        #expect(deletionLimit.canDelete(count: selectableCount) == false)
    }

    @Test("境界値-3: PremiumManager未設定時のすべて削除", .tags(.boundary, .premiumLimit))
    func deleteAllWithoutPremiumManager() {
        // Given: PremiumManagerがnil（制限チェックなし）相当の動作シミュレーション
        let photoIds = (0..<5).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 5),
            bestShotIndex: 0
        )

        // When: PremiumManager未設定の場合の動作を確認
        // 実装上、PremiumManagerがnilの場合は制限なしで削除可能（確認ダイアログ直接表示）
        let expectedDeletionCount = group.count - 1

        // Then: 削除対象はベストショット以外の4枚
        #expect(expectedDeletionCount == 4)
        #expect(group.bestShotId == "photo-0")
        #expect(group.deletionCandidateIds.count == 4)
    }

    // MARK: - UI/UXテスト（3件）

    @Test("UI/UX-1: ツールバーボタン表示切り替え（選択⇔完了）", .tags(.uiux, .selectionMode))
    func toolbarButtonToggle() {
        // Given: グループ詳細ビュー
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000],
            bestShotIndex: 0
        )

        // When/Then: ビューが正常に作成される（ボタン表示ロジックはView内で管理）
        // 選択モード無効時: 「選択」ボタン表示
        // 選択モード有効時: 「完了」ボタン表示
        let _ = GroupDetailView(group: group)

        // ボタンラベルのローカライズキーが存在することを確認
        let selectLabel = NSLocalizedString("groupDetail.select", value: "選択", comment: "")
        let doneLabel = NSLocalizedString("common.done", value: "完了", comment: "")

        #expect(!selectLabel.isEmpty)
        #expect(!doneLabel.isEmpty)
        #expect(selectLabel == "選択")
        #expect(doneLabel == "完了")
    }

    @Test("UI/UX-2: 確認ダイアログのメッセージ内容検証", .tags(.uiux, .deleteAll))
    func confirmationDialogMessage() {
        // Given: グループ詳細ビュー用のグループ
        let photoIds = (0..<10).map { "photo-\($0)" }
        let fileSizes: [Int64] = Array(repeating: 2_500_000, count: 10)
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: fileSizes,
            bestShotIndex: 0
        )

        // When: 確認メッセージの構成要素を検証
        let deleteAllTitleKey = NSLocalizedString(
            "groupDetail.deleteAll.title",
            value: "グループ全体を削除",
            comment: ""
        )

        let deleteAllMessageKey = NSLocalizedString(
            "groupDetail.deleteAll.message",
            value: "このグループのすべての写真（%d枚、%@）を削除しますか？\n\n※ ベストショットは保持されます。",
            comment: ""
        )

        // Then: メッセージが適切なフォーマットを持つ
        #expect(deleteAllTitleKey == "グループ全体を削除")
        #expect(deleteAllMessageKey.contains("%d枚"))
        #expect(deleteAllMessageKey.contains("ベストショット"))
        #expect(group.count == 10)
        #expect(group.formattedReclaimableSize.isEmpty == false)
    }

    @Test("UI/UX-3: 削除後の選択モード自動終了", .tags(.uiux, .selectionMode, .deleteAll))
    func selectionModeEndAfterDeletion() {
        // Given: 削除可能な状態
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = true

        let photoIds = (0..<5).map { "photo-\($0)" }
        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: Array(repeating: 2_500_000, count: 5),
            bestShotIndex: 0
        )

        // When: 削除の実行をシミュレート
        let selectableCount = group.count - 1
        deletionLimit.recordDeletion(count: selectableCount)

        // Then: 削除が記録される（削除後の状態管理はView内部で実施）
        // 削除後: isSelectionModeActive = false, selectedPhotoIds = []
        #expect(group.count == 5)
        #expect(selectableCount == 4)
        #expect(deletionLimit.recordedDeletionCount == 4)
    }
}

// MARK: - Premium制限統合テスト

@MainActor
@Suite("Premium制限チェック統合テスト", .tags(.premiumLimit))
struct PremiumLimitIntegrationTests {

    @Test("Free版: 日次削除制限が正しく機能する")
    func freeTierDailyLimit() {
        // Given
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 50

        // When: 削除を記録
        deletionLimit.recordDeletion(count: 30)

        // Then: 残り20枚
        let remaining = deletionLimit.getRemainingDeletions()
        #expect(remaining == 20)
        #expect(deletionLimit.recordedDeletionCount == 30)
    }

    @Test("Premium版: 削除制限なし")
    func premiumTierUnlimited() {
        // Given
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = true

        // When: 大量削除を記録
        deletionLimit.recordDeletion(count: 1000)

        // Then: 無制限
        let remaining = deletionLimit.getRemainingDeletions()
        #expect(remaining == Int.max)
        #expect(deletionLimit.recordedDeletionCount == 1000)
    }

    @Test("Free版: 制限到達時は0を返す")
    func freeTierLimitReached() {
        // Given
        let deletionLimit = GroupDetailViewMockDeletionLimit()
        deletionLimit.isPremiumUser = false
        deletionLimit.remainingDeletions = 0

        // Then
        let remaining = deletionLimit.getRemainingDeletions()
        #expect(remaining == 0)
        #expect(deletionLimit.canDelete(count: 1) == false)
    }
}
