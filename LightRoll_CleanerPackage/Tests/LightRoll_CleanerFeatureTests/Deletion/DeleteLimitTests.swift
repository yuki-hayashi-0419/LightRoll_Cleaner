//
//  DeleteLimitTests.swift
//  LightRoll_CleanerFeatureTests
//
//  M9-T07: 削除上限管理のテスト
//  - Free版の50枚制限チェック
//  - 日付変更時の自動リセット
//  - Premium版の無制限削除
//  - エラーメッセージの多言語対応
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - DeletePhotosUseCase + PremiumManager Integration Tests

@Suite("M9-T07: 削除上限管理テスト")
@MainActor
struct DeleteLimitTests {

    // MARK: - M9-T07-TC01: 50枚削除後の状態

    @Test("M9-T07-TC01: Free版で50枚削除済み後、51枚目の削除でエラー")
    func testFreeVersionDeletionLimitReached() async throws {
        // Given: Free版のPremiumManagerをセットアップ（既に50枚削除済み）
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        // 50枚削除済みにセット
        premiumManager.incrementDeleteCount(50)

        // DeletePhotosUseCaseにPremiumManagerを設定
        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 1枚の削除を試行
        let photos = [PhotoAsset(id: "photo51", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: deletionLimitReachedエラーが発生
        do {
            _ = try await useCase.execute(input)
            Issue.record("エラーが発生すべきだが成功した")
        } catch let error as DeletePhotosUseCaseError {
            // エラーの詳細を検証
            switch error {
            case .deletionLimitReached(let current, let limit, let requested):
                #expect(current == 50)
                #expect(limit == 50)
                #expect(requested == 1)
            default:
                Issue.record("予期しないエラータイプ: \(error)")
            }

            // エラーメッセージの検証
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)

        } catch {
            Issue.record("予期しないエラー型: \(error)")
        }

        // ゴミ箱への移動は実行されない
        #expect(!mockTrashManager.moveToTrashCalled)
    }

    @Test("M9-T07-TC01-境界値: Free版で49枚削除済み後、1枚削除は成功")
    func testFreeVersionDeleteAt49Boundary() async throws {
        // Given: Free版で49枚削除済み
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(49)

        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 1枚削除（合計50枚）
        let photos = [PhotoAsset(id: "photo50", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: 成功する
        let result = try await useCase.execute(input)
        #expect(result.deletedCount == 1)
        #expect(mockTrashManager.moveToTrashCalled)

        // カウントが更新されている
        let remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 0)
    }

    @Test("M9-T07-TC01-境界値: Free版で49枚削除済み後、2枚削除は失敗")
    func testFreeVersionDeleteExceedsBoundary() async throws {
        // Given: Free版で49枚削除済み
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(49)

        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 2枚削除を試行（合計51枚）
        let photos = [
            PhotoAsset(id: "photo50", creationDate: Date(), fileSize: 1000),
            PhotoAsset(id: "photo51", creationDate: Date(), fileSize: 1000)
        ]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: エラーが発生
        await #expect(throws: DeletePhotosUseCaseError.self) {
            try await useCase.execute(input)
        }

        // ゴミ箱への移動は実行されない
        #expect(!mockTrashManager.moveToTrashCalled)
    }

    // MARK: - M9-T07-TC02: 日付変更後のリセット

    @Test("M9-T07-TC02: 日付変更後に削除カウントが0にリセットされる")
    func testDailyCountResetAfterDateChange() async throws {
        // Given: Free版で30枚削除済み
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(30)

        // 削除前の残数確認
        var remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 20)

        // When: 日付変更を模擬（AppStateのcheckAndResetDailyCountIfNeededを使用）
        let appState = AppState(forTesting: true)
        appState.lastDeleteDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        appState.todayDeleteCount = 30

        // 日付変更チェック実行
        appState.checkAndResetDailyCountIfNeeded(premiumManager: premiumManager)

        // Then: カウントが0にリセット
        remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 50)
        #expect(appState.todayDeleteCount == 0)
    }

    @Test("M9-T07-TC02: 同日内ではリセットされない")
    func testDailyCountNotResetSameDay() async throws {
        // Given: Free版で30枚削除済み（本日）
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(30)

        let appState = AppState(forTesting: true)
        appState.lastDeleteDate = Date()
        appState.todayDeleteCount = 30

        // When: 同日内でチェック実行
        appState.checkAndResetDailyCountIfNeeded(premiumManager: premiumManager)

        // Then: カウントは維持される
        let remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 20)
        #expect(appState.todayDeleteCount == 30)
    }

    @Test("M9-T07-TC02: 日付変更後の削除が成功する")
    func testDeleteAfterDailyReset() async throws {
        // Given: Free版で50枚削除済み（昨日）
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        let appState = AppState(forTesting: true)
        appState.lastDeleteDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        appState.todayDeleteCount = 50

        // When: 日付変更後にリセット
        appState.checkAndResetDailyCountIfNeeded(premiumManager: premiumManager)

        // 削除を実行
        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        let photos = [PhotoAsset(id: "photo1", creationDate: Date(), fileSize: 1000)]
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: 削除が成功する
        let result = try await useCase.execute(input)
        #expect(result.deletedCount == 1)
        #expect(mockTrashManager.moveToTrashCalled)
    }

    // MARK: - M9-T07-TC03: Premium版の制限

    @Test("M9-T07-TC03: Premium版では100枚削除しても制限なし")
    func testPremiumVersionUnlimitedDeletion() async throws {
        // Given: Premium版（月額）
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .monthly()

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        #expect(premiumManager.isPremium == true)

        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 100枚の削除を実行
        let photos = (1...100).map { index in
            PhotoAsset(id: "photo\(index)", creationDate: Date(), fileSize: 1000)
        }
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: 成功する
        let result = try await useCase.execute(input)
        #expect(result.deletedCount == 100)
        #expect(mockTrashManager.moveToTrashCalled)

        // 残数は無制限
        let remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == Int.max)
    }

    @Test("M9-T07-TC03: Premium版（年額）でも無制限削除可能")
    func testPremiumYearlyUnlimitedDeletion() async throws {
        // Given: Premium版（年額）
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .yearly()

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        #expect(premiumManager.isPremium == true)

        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 200枚の削除を実行
        let photos = (1...200).map { index in
            PhotoAsset(id: "photo\(index)", creationDate: Date(), fileSize: 1000)
        }
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: 成功する
        let result = try await useCase.execute(input)
        #expect(result.deletedCount == 200)
        #expect(mockTrashManager.moveToTrashCalled)
    }

    @Test("M9-T07-TC03: Premium版では日付変更の影響を受けない")
    func testPremiumNotAffectedByDateChange() async throws {
        // Given: Premium版で100枚削除済み
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .monthly()

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        await premiumManager.recordDeletion(count: 100)

        // When: 日付変更
        let appState = AppState(forTesting: true)
        appState.lastDeleteDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        appState.checkAndResetDailyCountIfNeeded(premiumManager: premiumManager)

        // Then: 依然として無制限
        let remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == Int.max)
    }

    // MARK: - Additional Test Cases

    @Test("削除成功後のカウント更新確認")
    func testDeleteCountUpdateAfterSuccess() async throws {
        // Given: Free版で10枚削除可能
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        var remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 50)

        // When: 10枚削除
        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        let photos = (1...10).map { index in
            PhotoAsset(id: "photo\(index)", creationDate: Date(), fileSize: 1000)
        }
        let input = DeletePhotosInput(photos: photos, permanently: false)

        _ = try await useCase.execute(input)

        // Then: カウントが更新される
        remaining = await premiumManager.getRemainingDeletions()
        #expect(remaining == 40)
    }

    @Test("エラーメッセージに削除可能数が含まれる")
    func testErrorMessageContainsLimitInfo() async throws {
        // Given: Free版で50枚削除済み
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(50)

        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        // When: 5枚削除を試行
        let photos = (1...5).map { index in
            PhotoAsset(id: "photo\(index)", creationDate: Date(), fileSize: 1000)
        }
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: エラーメッセージに詳細が含まれる
        do {
            _ = try await useCase.execute(input)
            Issue.record("エラーが発生すべき")
        } catch let error as DeletePhotosUseCaseError {
            let description = error.errorDescription ?? ""

            // メッセージに数値が含まれることを確認
            #expect(description.contains("50"))  // current
            #expect(description.contains("5"))   // requested

            // リカバリー提案があることを確認
            let suggestion = error.recoverySuggestion ?? ""
            #expect(suggestion.contains("プレミアム") || suggestion.contains("Premium"))
        }
    }

    @Test("PremiumManagerなしの場合は制限チェックをスキップ")
    func testNoPremiumManagerSkipsLimitCheck() async throws {
        // Given: PremiumManagerを設定しないUseCase
        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: nil  // PremiumManagerなし
        )

        // When: 大量（100枚）削除を試行
        let photos = (1...100).map { index in
            PhotoAsset(id: "photo\(index)", creationDate: Date(), fileSize: 1000)
        }
        let input = DeletePhotosInput(photos: photos, permanently: false)

        // Then: 制限なく成功
        let result = try await useCase.execute(input)
        #expect(result.deletedCount == 100)
        #expect(mockTrashManager.moveToTrashCalled)
    }

    @Test("0枚削除でもカウントは増えない")
    func testZeroPhotosDoesNotIncrementCount() async throws {
        // Given: Free版
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        let initialRemaining = await premiumManager.getRemainingDeletions()

        // When: 空配列で削除試行（エラーになるはず）
        let mockTrashManager = MockTrashManager()
        let useCase = DeletePhotosUseCase(
            trashManager: mockTrashManager,
            premiumManager: premiumManager
        )

        let input = DeletePhotosInput(photos: [], permanently: false)

        // Then: エラーが発生し、カウントは変わらない
        do {
            _ = try await useCase.execute(input)
            Issue.record("空配列でエラーが発生すべき")
        } catch {
            // エラーは期待通り
        }

        let finalRemaining = await premiumManager.getRemainingDeletions()
        #expect(finalRemaining == initialRemaining)
    }
}

// MARK: - GroupDetailView Limit Check Tests

@Suite("M9-T07: GroupDetailView削除制限チェックテスト")
@MainActor
struct GroupDetailViewLimitTests {

    @Test("削除前に制限チェックが実行される")
    func testLimitCheckBeforeDelete() async throws {
        // Given: Free版で残り5枚削除可能
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(45)  // 残り5枚

        // When: 10枚選択して削除しようとする
        let remaining = await premiumManager.getRemainingDeletions()
        let canDelete = premiumManager.canDelete(count: 10)

        // Then: 削除不可
        #expect(remaining == 5)
        #expect(!canDelete)
    }

    @Test("削除可能数以内なら確認ダイアログが表示される")
    func testShowConfirmationWhenWithinLimit() async throws {
        // Given: Free版で残り10枚削除可能
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .free

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()
        premiumManager.incrementDeleteCount(40)

        // When: 5枚選択
        let canDelete = premiumManager.canDelete(count: 5)

        // Then: 削除可能
        #expect(canDelete)
    }

    @Test("Premium版では制限チェックが常にtrue")
    func testPremiumAlwaysCanDelete() async throws {
        // Given: Premium版
        let mockPurchaseRepo = MockPurchaseRepository()
        mockPurchaseRepo.mockPremiumStatus = .monthly()

        let premiumManager = PremiumManager(purchaseRepository: mockPurchaseRepo)
        try await premiumManager.checkPremiumStatus()

        // When: 任意の枚数で削除可能性をチェック
        let canDelete1 = premiumManager.canDelete(count: 1)
        let canDelete100 = premiumManager.canDelete(count: 100)
        let canDelete1000 = premiumManager.canDelete(count: 1000)

        // Then: すべてtrue
        #expect(canDelete1)
        #expect(canDelete100)
        #expect(canDelete1000)
    }
}

// MARK: - Localization Tests

@Suite("M9-T07: エラーメッセージ多言語対応テスト")
struct ErrorMessageLocalizationTests {

    @Test("削除上限エラーのローカライゼーションキーが存在する")
    func testDeletionLimitErrorLocalizationKeys() {
        let error = DeletePhotosUseCaseError.deletionLimitReached(
            current: 50,
            limit: 50,
            requested: 1
        )

        // errorDescription
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)

        // failureReason
        #expect(error.failureReason != nil)
        #expect(!error.failureReason!.isEmpty)

        // recoverySuggestion
        #expect(error.recoverySuggestion != nil)
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    @Test("エラーメッセージに動的な値が挿入される")
    func testErrorMessageContainsDynamicValues() {
        let error = DeletePhotosUseCaseError.deletionLimitReached(
            current: 45,
            limit: 50,
            requested: 10
        )

        let description = error.errorDescription ?? ""

        // 数値が含まれることを確認
        #expect(description.contains("45") || description.contains("50") || description.contains("10"))
    }

    @Test("各エラータイプのローカライゼーション")
    func testAllErrorTypesHaveLocalization() {
        let errors: [DeletePhotosUseCaseError] = [
            .emptyPhotos,
            .deletionLimitReached(current: 50, limit: 50, requested: 1),
            .trashMoveFailed(underlying: NSError(domain: "Test", code: -1)),
            .permanentDeletionFailed(underlying: NSError(domain: "Test", code: -1)),
            .partialFailure(successCount: 3, failedCount: 2)
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
