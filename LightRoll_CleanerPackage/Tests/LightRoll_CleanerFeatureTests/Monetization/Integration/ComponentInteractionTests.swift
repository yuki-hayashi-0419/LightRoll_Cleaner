//
//  ComponentInteractionTests.swift
//  LightRoll_CleanerFeatureTests
//
//  コンポーネント間連携テスト
//  - PremiumManager ↔ PurchaseRepository
//  - PremiumView ↔ PurchaseRepository
//  - RestorePurchasesView ↔ PremiumManager
//

import Testing
import Foundation
import StoreKit
@testable import LightRoll_CleanerFeature

// MARK: - Manager ↔ Repository Interaction Tests

/// PremiumManager ↔ PurchaseRepository連携テストスイート
@Suite("PremiumManager ↔ PurchaseRepository連携", .tags(.integration, .component))
struct ManagerRepositoryInteractionTests {

    // MARK: - Test: トランザクション監視連携

    @Test("Manager監視開始 → Repository監視開始 → 連携確認")
    @MainActor
    func transactionMonitoringInteraction() async throws {
        // Given: リポジトリとマネージャー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        // 初期状態
        #expect(repository.startTransactionListenerCalled == false)

        // When: マネージャーで監視開始
        manager.startTransactionMonitoring()

        // Then: リポジトリでも監視開始される
        #expect(repository.startTransactionListenerCalled == true)

        // When: 監視停止
        manager.stopTransactionMonitoring()

        // Then: リポジトリでも監視停止される
        #expect(repository.stopTransactionListenerCalled == true)
    }

    // MARK: - Test: 状態確認連携

    @Test("Manager状態確認 → Repository問い合わせ → 状態更新")
    @MainActor
    func statusCheckInteraction() async throws {
        // Given: リポジトリ
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)
        repository.mockPremiumStatus = .monthly()

        let manager = PremiumManager(purchaseRepository: repository)

        // When: マネージャーで状態確認
        try await manager.checkPremiumStatus()

        // Then: リポジトリが呼ばれた
        #expect(repository.checkSubscriptionStatusCalled == true)

        // Then: マネージャーの状態が更新された
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
        #expect(manager.subscriptionStatus.subscriptionType == .monthly)
    }

    // MARK: - Test: エラー伝搬連携

    @Test("Repositoryエラー → Manager状態リセット → エラー伝搬")
    @MainActor
    func errorPropagationInteraction() async throws {
        // Given: エラーを返すリポジトリ
        let repository = MockPurchaseRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = .networkError

        let manager = PremiumManager(purchaseRepository: repository)

        // Initially premium for test
        repository.shouldThrowError = false
        repository.setupPremiumStatus(isPremium: true)
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == true)

        // When: エラー状態で確認
        repository.shouldThrowError = true

        do {
            try await manager.checkPremiumStatus()
            Issue.record("エラーがスローされるべき")
        } catch {
            // Then: エラーが伝搬
            #expect(error is PurchaseError)
        }

        // Then: マネージャーの状態がリセットされた
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)
    }

    // MARK: - Test: 削除カウント連携

    @Test("無料ユーザー削除 → カウント更新 → 制限確認")
    @MainActor
    func deletionCountInteraction() async throws {
        // Given: 無料ユーザー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)

        // When: 10枚削除
        #expect(manager.canDelete(count: 10) == true)
        await manager.recordDeletion(count: 10)

        // Then: カウントが増加
        #expect(manager.dailyDeleteCount == 10)

        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == 40) // 50 - 10

        // When: さらに40枚削除
        #expect(manager.canDelete(count: 40) == true)
        await manager.recordDeletion(count: 40)

        // Then: 上限到達
        #expect(manager.dailyDeleteCount == 50)
        #expect(manager.canDelete(count: 1) == false)

        let remainingAfter = await manager.getRemainingDeletions()
        #expect(remainingAfter == 0)
    }
}

// MARK: - Feature Availability Tests

/// 機能利用可能性連携テストスイート
@Suite("機能利用可能性連携", .tags(.integration, .feature))
struct FeatureAvailabilityTests {

    // MARK: - Test: 無制限削除機能

    @Test("無制限削除機能 → Premium判定 → 利用可否")
    @MainActor
    func unlimitedDeletionFeatureInteraction() async throws {
        // Given: リポジトリとマネージャー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        // When: 無料ユーザー
        try await manager.checkPremiumStatus()
        let freeCanUse = await manager.isFeatureAvailable(.unlimitedDeletion)

        // Then: 利用不可
        #expect(freeCanUse == false)

        // When: Premiumユーザー
        repository.setupPremiumStatus(isPremium: true)
        try await manager.checkPremiumStatus()
        let premiumCanUse = await manager.isFeatureAvailable(.unlimitedDeletion)

        // Then: 利用可能
        #expect(premiumCanUse == true)
    }

    // MARK: - Test: 広告非表示機能

    @Test("広告非表示機能 → Premium判定 → 利用可否")
    @MainActor
    func adFreeFeatureInteraction() async throws {
        // Given: マネージャー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        // When: 無料ユーザー
        try await manager.checkPremiumStatus()
        let freeCanUse = await manager.isFeatureAvailable(.adFree)

        // Then: 利用不可
        #expect(freeCanUse == false)

        // When: Premiumユーザー
        repository.setupPremiumStatus(isPremium: true)
        try await manager.checkPremiumStatus()
        let premiumCanUse = await manager.isFeatureAvailable(.adFree)

        // Then: 利用可能
        #expect(premiumCanUse == true)
    }

    // MARK: - Test: 高度な分析機能

    @Test("高度な分析機能 → Premium判定 → 利用可否")
    @MainActor
    func advancedAnalysisFeatureInteraction() async throws {
        // Given: マネージャー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        // When: 無料ユーザー
        try await manager.checkPremiumStatus()
        let freeCanUse = await manager.isFeatureAvailable(.advancedAnalysis)

        // Then: 利用不可
        #expect(freeCanUse == false)

        // When: Premiumユーザー
        repository.setupPremiumStatus(isPremium: true)
        try await manager.checkPremiumStatus()
        let premiumCanUse = await manager.isFeatureAvailable(.advancedAnalysis)

        // Then: 利用可能
        #expect(premiumCanUse == true)
    }

    // MARK: - Test: クラウドバックアップ機能（未実装）

    @Test("クラウドバックアップ機能 → 未実装確認")
    @MainActor
    func cloudBackupFeatureInteraction() async throws {
        // Given: Premiumユーザー
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)

        let manager = PremiumManager(purchaseRepository: repository)
        try await manager.checkPremiumStatus()

        #expect(manager.isPremium == true)

        // When: クラウドバックアップ確認
        let canUse = await manager.isFeatureAvailable(.cloudBackup)

        // Then: 未実装のため利用不可
        #expect(canUse == false)
    }
}

// MARK: - Purchase Flow Component Tests

/// 購入フローコンポーネント連携テストスイート
@Suite("購入フローコンポーネント連携", .tags(.integration, .purchase))
struct PurchaseFlowComponentTests {

    // MARK: - Test: 製品情報取得 → 購入 → 状態更新

    @Test("製品情報取得 → 購入実行 → Manager状態更新")
    @MainActor
    func productFetchToPurchaseFlow() async throws {
        // Given: リポジトリとマネージャー
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()

        let manager = PremiumManager(purchaseRepository: repository)

        // When: 製品情報を取得
        let products = try await repository.fetchProducts()
        #expect(products.count == 2)

        // When: 月額プランを選択
        let monthlyProduct = try #require(
            products.first { $0.subscriptionPeriod == .monthly }
        )

        // When: 購入
        repository.setupPremiumStatus(isPremium: true)
        repository.mockPremiumStatus = .monthly()
        repository.purchaseResult = .cancelled // Mock

        _ = try await repository.purchase(monthlyProduct.id)

        // When: マネージャーで状態確認
        try await manager.checkPremiumStatus()

        // Then: Premium状態に更新
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.subscriptionType == .monthly)
    }

    // MARK: - Test: 復元 → 状態確認 → 機能解放

    @Test("復元実行 → 状態確認 → 機能利用可能")
    @MainActor
    func restoreToPremiumFeatureFlow() async throws {
        // Given: リポジトリとマネージャー
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)
        repository.mockPremiumStatus = .yearly()

        let manager = PremiumManager(purchaseRepository: repository)

        // 初期状態
        #expect(manager.isPremium == false)
        let beforeRestore = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(beforeRestore == false)

        // When: 復元実行
        _ = try await repository.restorePurchases()

        // When: 状態確認
        try await manager.checkPremiumStatus()

        // Then: Premium状態
        #expect(manager.isPremium == true)

        // Then: 機能が利用可能
        let afterRestore = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(afterRestore == true)

        let adFree = await manager.isFeatureAvailable(.adFree)
        #expect(adFree == true)

        let analysis = await manager.isFeatureAvailable(.advancedAnalysis)
        #expect(analysis == true)
    }

    // MARK: - Test: 削除上限到達 → Premium購入 → 即時解除

    @Test("削除上限到達 → Premium購入 → 制限即時解除")
    @MainActor
    func limitReachedToPremiumPurchaseFlow() async throws {
        // Given: 上限到達した無料ユーザー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        try await manager.checkPremiumStatus()

        // When: 上限まで削除
        await manager.recordDeletion(count: 50)
        #expect(manager.canDelete(count: 1) == false)

        // When: Premium購入
        repository.setupDefaultProducts()
        repository.setupPremiumStatus(isPremium: true)
        repository.mockPremiumStatus = .monthly()
        repository.purchaseResult = .cancelled // Mock

        let products = try await repository.fetchProducts()
        let monthlyProduct = try #require(
            products.first { $0.subscriptionPeriod == .monthly }
        )

        _ = try await repository.purchase(monthlyProduct.id)

        // When: 状態更新
        try await manager.checkPremiumStatus()

        // Then: 制限即時解除
        #expect(manager.isPremium == true)
        #expect(manager.canDelete(count: 100) == true)
        #expect(manager.canDelete(count: 1000) == true)

        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == Int.max)
    }
}

// MARK: - State Refresh Tests

/// 状態更新連携テストスイート
@Suite("状態更新連携", .tags(.integration, .refresh))
struct StateRefreshTests {

    // MARK: - Test: 手動状態更新

    @Test("手動状態更新 → Repository確認 → Manager更新")
    @MainActor
    func manualRefreshInteraction() async throws {
        // Given: リポジトリとマネージャー
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: false)

        let manager = PremiumManager(purchaseRepository: repository)

        // 初期確認
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)

        // When: バックグラウンドで購入が完了（リポジトリ状態変更）
        repository.setupPremiumStatus(isPremium: true)
        repository.mockPremiumStatus = .monthly()

        // When: 手動更新
        await manager.refreshStatus()

        // Then: 状態が更新された
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
    }

    // MARK: - Test: エラー時の状態リセット

    @Test("エラー発生 → 状態リセット → 再試行可能")
    @MainActor
    func errorStateResetInteraction() async throws {
        // Given: 正常なリポジトリ
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)

        let manager = PremiumManager(purchaseRepository: repository)
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == true)

        // When: エラー発生
        repository.shouldThrowError = true
        repository.errorToThrow = .networkError

        do {
            try await manager.checkPremiumStatus()
            Issue.record("エラーがスローされるべき")
        } catch {
            #expect(error is PurchaseError)
        }

        // Then: 無料状態にリセット
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)

        // When: エラー解消後に再試行
        repository.shouldThrowError = false

        try await manager.checkPremiumStatus()

        // Then: Premium状態に復帰
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
    }

    // MARK: - Test: 日次カウントリセット

    @Test("日次カウントリセット → 削除可能数復元")
    @MainActor
    func dailyCountResetInteraction() async throws {
        // Given: 削除済みの無料ユーザー
        let repository = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: repository)

        try await manager.checkPremiumStatus()

        // When: 30枚削除
        await manager.recordDeletion(count: 30)
        #expect(manager.dailyDeleteCount == 30)

        let beforeReset = await manager.getRemainingDeletions()
        #expect(beforeReset == 20) // 50 - 30

        // When: 日次リセット（日付変更）
        manager.resetDailyCount()

        // Then: カウントがリセット
        #expect(manager.dailyDeleteCount == 0)

        let afterReset = await manager.getRemainingDeletions()
        #expect(afterReset == 50)

        // Then: 再度削除可能
        #expect(manager.canDelete(count: 50) == true)
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var component: Tag
    @Tag static var feature: Tag
    @Tag static var purchase: Tag
    @Tag static var refresh: Tag
}
