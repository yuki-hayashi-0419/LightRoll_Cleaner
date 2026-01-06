//
//  PremiumManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  M9-T05: PremiumManager実装テスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

@Suite("PremiumManager Tests")
struct PremiumManagerTests {

    // MARK: - M9-T05-TC01: Free状態の確認

    @Test("Free状態では課金フラグがfalse")
    @MainActor
    func testFreeStatus() async throws {
        // Given: Free状態のMockリポジトリ
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 状態確認
        try await manager.checkPremiumStatus()

        // Then: Free状態
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)
    }

    @Test("Free状態では削除制限が有効")
    @MainActor
    func testFreeDeletionLimit() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: 50枚までOK
        #expect(manager.canDelete(count: 50) == true)

        // When/Then: 51枚はNG
        #expect(manager.canDelete(count: 51) == false)

        // When: 30枚削除
        manager.incrementDeleteCount(30)

        // Then: 残り20枚まで
        #expect(manager.canDelete(count: 20) == true)
        #expect(manager.canDelete(count: 21) == false)
    }

    // MARK: - M9-T05-TC02: サブスク購入後の状態

    @Test("アクティブなサブスクでは課金フラグがtrue")
    @MainActor
    func testActiveSubscription() async throws {
        // Given: アクティブなサブスク
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 状態確認
        try await manager.checkPremiumStatus()

        // Then: Premium状態
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
    }

    @Test("Premium状態では削除制限なし")
    @MainActor
    func testPremiumUnlimitedDeletion() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: 大量削除もOK
        #expect(manager.canDelete(count: 1000) == true)
        #expect(manager.canDelete(count: 10000) == true)

        // When: 削除実行
        manager.incrementDeleteCount(1000)

        // Then: まだ無制限
        #expect(manager.canDelete(count: 9999) == true)
    }

    // MARK: - M9-T05-TC03: 期限切れ後の状態

    @Test("期限切れサブスクではFree状態に戻る")
    @MainActor
    func testExpiredSubscription() async throws {
        // Given: 期限切れサブスク（31日以上前に購入）
        let mockRepo = MockPurchaseRepository()
        let expiredStartDate = Date().addingTimeInterval(-86400 * 35) // 35日前に購入
        mockRepo.mockPremiumStatus = .monthly(startDate: expiredStartDate, autoRenew: false)
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 状態確認
        try await manager.checkPremiumStatus()

        // Then: Free状態に戻る（期限切れでisActiveがfalseになる）
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus.isActive == false)
    }

    @Test("期限切れ後は削除制限が復活")
    @MainActor
    func testExpiredRestoresLimit() async throws {
        // Given: 期限切れサブスク
        let mockRepo = MockPurchaseRepository()
        let expiredStartDate = Date().addingTimeInterval(-86400 * 35)
        mockRepo.mockPremiumStatus = .monthly(startDate: expiredStartDate, autoRenew: false)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: 制限が復活
        #expect(manager.canDelete(count: 50) == true)
        #expect(manager.canDelete(count: 51) == false)
    }

    // MARK: - カウント管理テスト

    @Test("削除カウントの増加")
    @MainActor
    func testIncrementDeleteCount() {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 複数回削除
        manager.incrementDeleteCount(10)
        manager.incrementDeleteCount(15)
        manager.incrementDeleteCount(5)

        // Then: カウント合計
        #expect(manager.totalDeleteCount == 30)
    }

    @Test("削除カウントのリセット（テスト用）")
    @MainActor
    func testResetDeleteCount() {
        // Given: カウントがある状態
        let mockRepo = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: mockRepo)
        manager.incrementDeleteCount(30)

        // When: リセット（テスト用、本番では使用しない）
        manager.resetDeleteCount()

        // Then: カウントが0に
        #expect(manager.totalDeleteCount == 0)
        #expect(manager.canDelete(count: 50) == true)
    }

    // MARK: - エラーハンドリング

    @Test("状態確認エラー時はFreeにフォールバック")
    @MainActor
    func testErrorFallbackToFree() async throws {
        // Given: エラーを返すリポジトリ
        let mockRepo = MockPurchaseRepository()
        mockRepo.shouldThrowError = true
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 状態確認（エラー発生）
        await #expect(throws: PurchaseError.self) {
            try await manager.checkPremiumStatus()
        }

        // Then: Free状態にフォールバック
        #expect(manager.isPremium == false)
        #expect(manager.subscriptionStatus == .free)
    }

    // MARK: - トランザクション監視

    @Test("トランザクション監視の開始")
    @MainActor
    func testStartTransactionMonitoring() {
        // Given
        let mockRepo = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 監視開始
        manager.startTransactionMonitoring()

        // Then: リスナーが開始されている
        #expect(mockRepo.startTransactionListenerCalled == true)
    }

    @Test("トランザクション監視の停止")
    @MainActor
    func testStopTransactionMonitoring() {
        // Given
        let mockRepo = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 監視停止
        manager.stopTransactionMonitoring()

        // Then: リスナーが停止
        #expect(mockRepo.stopTransactionListenerCalled == true)
    }

    // MARK: - M9-T06: PremiumManagerProtocol準拠テスト

    @Test("status プロパティがsubscriptionStatusを返す")
    @MainActor
    func testStatusProperty() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When: statusプロパティを取得
        let status = await manager.status

        // Then: subscriptionStatusと一致
        #expect(status.isPremium == true)
        #expect(status.isActive == true)
    }

    @Test("isFeatureAvailable - 無制限削除機能の判定")
    @MainActor
    func testIsFeatureAvailableUnlimitedDeletion() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: Free版では利用不可
        let freeAvailable = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(freeAvailable == false)

        // Given: Premium状態に変更
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        // When/Then: Premium版では利用可能
        let premiumAvailable = await manager.isFeatureAvailable(.unlimitedDeletion)
        #expect(premiumAvailable == true)
    }

    @Test("isFeatureAvailable - 広告非表示機能の判定")
    @MainActor
    func testIsFeatureAvailableAdFree() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: Free版では利用不可
        let available = await manager.isFeatureAvailable(.adFree)
        #expect(available == false)

        // Given: Premium状態に変更
        mockRepo.mockPremiumStatus = .yearly(startDate: Date(), autoRenew: true)
        try await manager.checkPremiumStatus()

        // When/Then: Premium版では利用可能
        let premiumAvailable = await manager.isFeatureAvailable(.adFree)
        #expect(premiumAvailable == true)
    }

    @Test("isFeatureAvailable - 高度な分析機能の判定")
    @MainActor
    func testIsFeatureAvailableAdvancedAnalysis() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: Premium版で利用可能
        let available = await manager.isFeatureAvailable(.advancedAnalysis)
        #expect(available == true)
    }

    @Test("isFeatureAvailable - クラウドバックアップは未実装")
    @MainActor
    func testIsFeatureAvailableCloudBackup() async throws {
        // Given: Premium状態でも
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: クラウドバックアップは常に利用不可（将来機能）
        let available = await manager.isFeatureAvailable(.cloudBackup)
        #expect(available == false)
    }

    @Test("getRemainingDeletions - Free版での残数計算")
    @MainActor
    func testGetRemainingDeletionsFree() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When: 初期状態
        let remaining1 = await manager.getRemainingDeletions()

        // Then: 50枚残り
        #expect(remaining1 == 50)

        // When: 30枚削除
        manager.incrementDeleteCount(30)
        let remaining2 = await manager.getRemainingDeletions()

        // Then: 20枚残り
        #expect(remaining2 == 20)

        // When: さらに20枚削除
        manager.incrementDeleteCount(20)
        let remaining3 = await manager.getRemainingDeletions()

        // Then: 0枚残り
        #expect(remaining3 == 0)
    }

    @Test("getRemainingDeletions - Premium版では無制限")
    @MainActor
    func testGetRemainingDeletionsPremium() async throws {
        // Given: Premium状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()

        // When/Then: Int.maxを返す
        let remaining = await manager.getRemainingDeletions()
        #expect(remaining == Int.max)

        // When: 削除しても
        manager.incrementDeleteCount(1000)

        // Then: まだInt.max
        let stillRemaining = await manager.getRemainingDeletions()
        #expect(stillRemaining == Int.max)
    }

    @Test("recordDeletion - 削除記録")
    @MainActor
    func testRecordDeletion() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        let manager = PremiumManager(purchaseRepository: mockRepo)

        // When: 削除を記録
        await manager.recordDeletion(count: 15)

        // Then: カウントが増加
        #expect(manager.totalDeleteCount == 15)

        // When: さらに記録
        await manager.recordDeletion(count: 10)

        // Then: カウント合計
        #expect(manager.totalDeleteCount == 25)
    }

    @Test("refreshStatus - ステータス更新")
    @MainActor
    func testRefreshStatus() async throws {
        // Given: Free状態
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .free
        let manager = PremiumManager(purchaseRepository: mockRepo)
        try await manager.checkPremiumStatus()
        #expect(manager.isPremium == false)

        // When: Premium状態に変更してrefresh
        mockRepo.mockPremiumStatus = .monthly(startDate: Date(), autoRenew: true)
        await manager.refreshStatus()

        // Then: Premium状態に更新される
        #expect(manager.isPremium == true)
        #expect(manager.subscriptionStatus.isActive == true)
    }
}
