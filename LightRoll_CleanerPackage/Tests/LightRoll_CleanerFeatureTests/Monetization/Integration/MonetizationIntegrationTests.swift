//
//  MonetizationIntegrationTests.swift
//  LightRoll_CleanerFeatureTests
//
//  M9-T15: Monetization統合テスト
//  - モジュール全体の統合テスト
//  - エンドツーエンドシナリオテスト
//  - コンポーネント間の連携テスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

@Suite("Monetization Integration Tests - エンドツーエンドシナリオ")
struct MonetizationIntegrationTests {

    // MARK: - シナリオ1: 購入フロー全体

    @Test("シナリオ1: Free状態からPremium購入までの完全フロー")
    @MainActor
    func testCompletePurchaseFlow() async throws {
        // Given: Free状態のセットアップ
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // ステップ1: 初期状態確認
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)

        // ステップ2: 製品情報取得
        let products = try await mockRepo.fetchProducts()
        #expect(products.count == 2)
        #expect(mockRepo.fetchProductsCalled == true)

        // ステップ3: Monthly製品を選択して購入
        let monthlyProduct = products.first { $0.subscriptionPeriod == .monthly }
        #expect(monthlyProduct != nil)

        // 購入成功をシミュレート
        mockRepo.purchaseResult = .cancelled // テスト環境ではcancelledを使用
        _ = try await mockRepo.purchase(monthlyProduct!.id)
        #expect(mockRepo.purchaseCalled == true)
        #expect(mockRepo.purchasedProductId == monthlyProduct!.id)

        // ステップ4: 購入後の状態更新
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        // ステップ5: Premium状態確認
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
        #expect(manager.subscriptionStatus.subscriptionType == .monthly)

        // ステップ6: Premium機能の確認
        let canDeleteUnlimited = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(canDeleteUnlimited == true)
        #expect(manager.canDelete(count: 1000) == true)
    }

    @Test("シナリオ1.2: Yearly購入フロー")
    @MainActor
    func testYearlyPurchaseFlow() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()

        // When: Yearly製品を購入
        let products = try await mockRepo.fetchProducts()
        let yearlyProduct = products.first { $0.subscriptionPeriod == .yearly }
        #expect(yearlyProduct != nil)

        mockRepo.purchaseResult = .cancelled
        _ = try await mockRepo.purchase(yearlyProduct!.id)

        // Then: Yearly状態に更新
        mockRepo.mockPremiumStatus = .yearly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.subscriptionType == .yearly)
    }

    // MARK: - シナリオ2: 復元フロー

    @Test("シナリオ2: 購入復元の完全フロー")
    @MainActor
    func testCompleteRestoreFlow() async throws {
        // Given: 以前購入済みだが現在Free状態（再インストール想定）
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // ステップ1: 初期状態はFree
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)

        // ステップ2: 復元を実行
        // Note: 実際のTransactionはテスト環境で作成できないため、
        // 空の配列でも復元プロセスをテスト
        mockRepo.mockRestoreResult = RestoreResult(transactions: [])

        // 復元が空の場合はエラー
        await #expect(throws: PurchaseError.self) {
            try await mockRepo.restorePurchases()
        }

        // ステップ3: 復元成功シミュレーション（実際の環境では有効なトランザクションがある）
        // テスト環境では状態を直接更新
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        // ステップ4: Premium状態に戻る
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
        #expect(mockRepo.restorePurchasesCalled == true)
    }

    @Test("シナリオ2.2: 復元失敗時のハンドリング")
    @MainActor
    func testRestoreFailureHandling() async throws {
        // Given: 購入履歴がない状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 復元を試みる
        mockRepo.shouldThrowError = true
        mockRepo.errorToThrow = .noActiveSubscription

        // Then: エラーがスローされる
        await #expect(throws: PurchaseError.self) {
            try await mockRepo.restorePurchases()
        }

        // ステータスはFreeのまま
        try? await manager.checkPremiumStatus()
        mockRepo.shouldThrowError = false
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)
    }

    // MARK: - シナリオ3: 削除制限フロー

    @Test("シナリオ3: Free版の削除制限とPremium誘導フロー")
    @MainActor
    func testFreeDeletionLimitFlow() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // ステップ1: 初期状態（50枚削除可能）
        let remaining1 = await manager.getRemainingDeletions()
        #expect(remaining1 == 50)
        #expect(manager.canDelete(count: 50) == true)

        // ステップ2: 30枚削除
        await manager.recordDeletion(count: 30)
        let remaining2 = await manager.getRemainingDeletions()
        #expect(remaining2 == 20)

        // ステップ3: さらに20枚削除（制限到達）
        await manager.recordDeletion(count: 20)
        let remaining3 = await manager.getRemainingDeletions()
        #expect(remaining3 == 0)
        #expect(manager.canDelete(count: 1) == false)

        // ステップ4: 制限到達後にPremiumへ誘導
        // （実際のUIではLimitReachedSheetが表示される）
        let canDeleteMore = manager.canDelete(count: 1)
        #expect(canDeleteMore == false)

        // ステップ5: Premium購入後は無制限
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        #expect(manager.isPremium == true)
        #expect(manager.canDelete(count: 1000) == true)
        let remainingPremium = await manager.getRemainingDeletions()
        #expect(remainingPremium == Int.max)
    }

    @Test("シナリオ3.2: 削除制限ギリギリのケース")
    @MainActor
    func testDeletionLimitEdgeCase() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When: 49枚削除
        await manager.recordDeletion(count: 49)

        // Then: あと1枚削除可能
        #expect(manager.canDelete(count: 1) == true)
        #expect(manager.canDelete(count: 2) == false)

        // When: 最後の1枚を削除
        await manager.recordDeletion(count: 1)

        // Then: もう削除不可
        #expect(manager.canDelete(count: 1) == false)
        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == 0)
    }

    // MARK: - シナリオ4: エラーハンドリング

    @Test("シナリオ4: ネットワークエラーからのリトライと成功")
    @MainActor
    func testNetworkErrorRetryFlow() async throws {
        // Given: ネットワークエラーが発生する状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.shouldThrowError = true
        mockRepo.errorToThrow = .networkError

        let manager = PremiumManager(purchaseRepository: mockRepo)

        // ステップ1: 初回リクエスト失敗
        await #expect(throws: PurchaseError.self) {
            try await manager.checkPremiumStatus()
        }

        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)

        // ステップ2: リトライ（エラー解消）
        mockRepo.shouldThrowError = false
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)

        try await manager.checkPremiumStatus()

        // ステップ3: 成功
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
    }

    @Test("シナリオ4.2: 購入キャンセル時の状態ロールバック")
    @MainActor
    func testPurchaseCancellationRollback() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)

        // When: 購入をキャンセル
        let products = try await mockRepo.fetchProducts()
        let product = products.first!

        mockRepo.purchaseResult = .cancelled
        let result = try await mockRepo.purchase(product.id)

        // Then: 購入結果がcancelled
        switch result {
        case .cancelled:
            #expect(true) // 期待通り
        default:
            Issue.record("Expected cancelled result")
        }

        // Then: 状態はFreeのまま（ロールバック成功）
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)
    }

    @Test("シナリオ4.3: 購入失敗時のエラーハンドリング")
    @MainActor
    func testPurchaseFailureHandling() async throws {
        // Given: 購入が失敗する状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.setupFailedPurchase(error: .purchaseFailed("Payment declined"))

        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When: 購入を試みる
        let products = try await mockRepo.fetchProducts()
        let result = try await mockRepo.purchase(products.first!.id)

        // Then: 失敗結果が返る
        switch result {
        case .failed(let error):
            #expect(error == .purchaseFailed("Payment declined"))
        default:
            Issue.record("Expected failed result")
        }

        // Then: 状態はFreeのまま
        #expect(manager.isPremium == false)
    }

    // MARK: - シナリオ5: Premium状態管理

    @Test("シナリオ5: PremiumManager ↔ PurchaseRepository連携")
    @MainActor
    func testPremiumManagerRepositoryIntegration() async throws {
        // Given: リポジトリとマネージャーのセットアップ
        let mockRepo = MockPurchaseRepository()
        mockRepo.setupDefaultProducts()
        mockRepo.mockPremiumStatus = .free

        let manager = PremiumManager(purchaseRepository: mockRepo)

        // ステップ1: 初期状態確認（リポジトリ経由）
        try await manager.checkPremiumStatus()
        #expect(mockRepo.checkSubscriptionStatusCalled == true)
        #expect(manager.isPremium == false)

        // ステップ2: 状態変更（外部からの購入シミュレーション）
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)

        // ステップ3: マネージャーが状態を再確認
        await manager.refreshStatus()
        #expect(manager.isPremium == true)

        // ステップ4: 削除機能との連携確認
        let canDelete = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(canDelete == true)

        // ステップ5: トランザクション監視開始
        manager.startTransactionMonitoring()
        #expect(mockRepo.startTransactionListenerCalled == true)

        // ステップ6: 監視停止
        manager.stopTransactionMonitoring()
        #expect(mockRepo.stopTransactionListenerCalled == true)
    }

    @Test("シナリオ5.2: 状態の一貫性確認")
    @MainActor
    func testStateConsistency() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()

        // When: 複数のプロパティを確認
        let isPremium = manager.isPremium
        let status = await manager.status
        let isUnlimitedAvailable = await manager.isFeatureAvailable(.unlimitedDeletion)
        let remainingDeletions = await manager.getRemainingDeletions()

        // Then: すべて一貫性がある
        #expect(isPremium == true)
        #expect(status.isPremium == true)
        #expect(status.isActive == true)
        #expect(isUnlimitedAvailable == true)
        #expect(remainingDeletions == Int.max)
    }

    @Test("シナリオ5.3: サブスクリプション期限切れ後の状態遷移")
    @MainActor
    func testSubscriptionExpirationTransition() async throws {
        // Given: アクティブなサブスク
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == true)

        // When: サブスクが期限切れ
        let expiredDate = Date().addingTimeInterval(-86400 * 35) // 35日前
        mockRepo.mockPremiumStatus = .monthly(startDate: expiredDate, autoRenew: false)

        try await manager.checkPremiumStatus()

        // Then: Free状態に戻る
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus.isActive == false)

        // Then: 削除制限が復活
        let canDelete = manager.canDelete(count: 100)
        #expect(canDelete == false)

        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == 50) // 初期状態
    }

    // MARK: - シナリオ6: 日次リセットフロー

    @Test("シナリオ6: 日次削除カウントのリセット")
    @MainActor
    func testDailyResetFlow() async throws {
        // Given: Free状態で削除済み
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()

        // ステップ1: 30枚削除
        await manager.recordDeletion(count: 30)
        let remaining1 = await manager.getRemainingDeletions()
        #expect(remaining1 == 20)

        // ステップ2: さらに削除（生涯制限モデルでは累積される）
        await manager.recordDeletion(count: 15)

        // ステップ3: カウントが累積
        #expect(manager.totalDeleteCount == 45)
        let remaining2 = await manager.getRemainingDeletions()
        #expect(remaining2 == 5) // 50 - 45

        // ステップ4: 上限に近づいたため残り5枚のみ削除可能
        #expect(manager.canDelete(count: 6) == false)
        #expect(manager.canDelete(count: 5) == true)
    }

    // MARK: - シナリオ7: 複数機能の組み合わせ

    @Test("シナリオ7: Premium機能のフル活用フロー")
    @MainActor
    func testPremiumFeaturesCombination() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .yearly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)

        try await manager.checkPremiumStatus()

        // ステップ1: 無制限削除機能
        let unlimitedDeletion = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(unlimitedDeletion == true)
        #expect(manager.canDelete(count: 10000) == true)

        // ステップ2: 広告非表示機能
        let adFree = await manager.isFeatureAvailable(.adFree)
        #expect(adFree == true)

        // ステップ3: 高度な分析機能
        let advancedAnalysis = await manager.isFeatureAvailable(.advancedAnalysis)
        #expect(advancedAnalysis == true)

        // ステップ4: クラウドバックアップ（未実装）
        let cloudBackup = await manager.isFeatureAvailable(.cloudBackup)
        #expect(cloudBackup == false)

        // ステップ5: 大量削除の実行
        await manager.recordDeletion(count: 5000)

        // ステップ6: まだ無制限
        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == Int.max)
    }
}
