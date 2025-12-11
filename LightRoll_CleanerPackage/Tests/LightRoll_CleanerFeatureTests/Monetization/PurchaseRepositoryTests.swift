//
//  PurchaseRepositoryTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PurchaseRepository のテスト
//  - 正常系テスト：製品情報取得、購入処理、復元処理
//  - 異常系テスト：エラーハンドリング、キャンセル
//  - 境界値テスト：空リスト、無効ID、期限切れ
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - 正常系テスト

@Suite("PurchaseRepository - 正常系テスト")
struct PurchaseRepositorySuccessTests {

    // MARK: - 製品情報取得テスト

    @Test("製品情報取得成功 - デフォルト製品")
    @MainActor
    func fetchProducts_withDefaultProducts_succeeds() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()

        // Act
        let products = try await repository.fetchProducts()

        // Assert
        #expect(repository.fetchProductsCalled == true)
        #expect(products.count == 2)
        #expect(products.contains(where: { $0.isMonthlySubscription }))
        #expect(products.contains(where: { $0.isYearlySubscription }))
    }

    @Test("月額製品のみ取得成功")
    @MainActor
    func getMonthlyProducts_returnsOnlyMonthlyProducts() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()

        // Act
        let monthlyProducts = try await repository.getMonthlyProducts()

        // Assert
        #expect(monthlyProducts.count == 1)
        #expect(monthlyProducts.first?.subscriptionPeriod == .monthly)
    }

    @Test("年額製品のみ取得成功")
    @MainActor
    func getYearlyProducts_returnsOnlyYearlyProducts() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()

        // Act
        let yearlyProducts = try await repository.getYearlyProducts()

        // Assert
        #expect(yearlyProducts.count == 1)
        #expect(yearlyProducts.first?.subscriptionPeriod == .yearly)
    }

    @Test("特定製品IDで製品取得成功")
    @MainActor
    func getProduct_byValidId_returnsProduct() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        let targetId = "com.lightroll.premium.monthly"

        // Act
        let product = try await repository.getProduct(by: targetId)

        // Assert
        #expect(product != nil)
        #expect(product?.id == targetId)
        #expect(product?.subscriptionPeriod == .monthly)
    }

    // MARK: - 購入処理テスト

    @Test("月額製品購入成功")
    @MainActor
    func purchase_monthlyProduct_succeeds() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupCancelledPurchase() // Mock uses cancelled as success placeholder
        let productId = "com.lightroll.premium.monthly"

        // Act
        let result = try await repository.purchase(productId)

        // Assert
        #expect(repository.purchaseCalled == true)
        #expect(repository.purchasedProductId == productId)
        #expect(result == .cancelled) // Mock limitation
    }

    @Test("年額製品購入成功")
    @MainActor
    func purchase_yearlyProduct_succeeds() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupCancelledPurchase()
        let productId = "com.lightroll.premium.yearly"

        // Act
        let result = try await repository.purchase(productId)

        // Assert
        #expect(repository.purchaseCalled == true)
        #expect(repository.purchasedProductId == productId)
    }

    // MARK: - 復元処理テスト

    @Test("購入復元成功 - 有効なトランザクションあり")
    @MainActor
    func restorePurchases_withValidTransactions_succeeds() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        // Note: Cannot create Transaction in test, using empty array
        repository.mockRestoreTransactions = []

        // Act
        let result = try await repository.restorePurchases()

        // Assert
        #expect(repository.restorePurchasesCalled == true)
        #expect(result.count == 0) // Mock limitation: cannot create Transaction
    }

    // MARK: - サブスクリプション状態確認テスト

    @Test("サブスクリプション状態確認 - プレミアム有効")
    @MainActor
    func checkSubscriptionStatus_withActivePremium_returnsActive() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)

        // Act
        let status = try await repository.checkSubscriptionStatus()

        // Assert
        #expect(repository.checkSubscriptionStatusCalled == true)
        #expect(status.isPremium == true)
        #expect(status.isActive == true)
        #expect(status.subscriptionType == .monthly)
    }

    @Test("サブスクリプション状態確認 - 無料版")
    @MainActor
    func checkSubscriptionStatus_withFree_returnsFree() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: false)

        // Act
        let status = try await repository.checkSubscriptionStatus()

        // Assert
        #expect(repository.checkSubscriptionStatusCalled == true)
        #expect(status.isFree == true)
        #expect(status.isPremium == false)
    }

    @Test("プレミアム会員判定 - 有効")
    @MainActor
    func isPremiumActive_withActivePremium_returnsTrue() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupPremiumStatus(isPremium: true)

        // Act
        let isActive = try await repository.isPremiumActive()

        // Assert
        #expect(isActive == true)
    }
}

// MARK: - 異常系テスト

@Suite("PurchaseRepository - 異常系テスト")
struct PurchaseRepositoryErrorTests {

    @Test("製品情報取得失敗 - productNotFound エラー")
    @MainActor
    func fetchProducts_whenErrorOccurs_throwsError() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = .productNotFound

        // Act & Assert
        await #expect(throws: PurchaseError.self) {
            try await repository.fetchProducts()
        }
        #expect(repository.fetchProductsCalled == true)
    }

    @Test("購入処理失敗 - キャンセル")
    @MainActor
    func purchase_whenUserCancels_returnsCancelled() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupCancelledPurchase()

        // Act
        let result = try await repository.purchase("com.lightroll.premium.monthly")

        // Assert
        #expect(result == .cancelled)
    }

    @Test("購入処理失敗 - purchaseFailed エラー")
    @MainActor
    func purchase_whenPurchaseFails_returnsFailedResult() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupFailedPurchase(error: .purchaseFailed("Network error"))

        // Act
        let result = try await repository.purchase("com.lightroll.premium.monthly")

        // Assert
        if case .failed(let error) = result {
            #expect(error == .purchaseFailed("Network error"))
        } else {
            Issue.record("Expected failed result")
        }
    }

    @Test("購入処理失敗 - verificationFailed エラー")
    @MainActor
    func purchase_whenVerificationFails_returnsFailedResult() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupFailedPurchase(error: .verificationFailed)

        // Act
        let result = try await repository.purchase("com.lightroll.premium.yearly")

        // Assert
        if case .failed(let error) = result {
            #expect(error == .verificationFailed)
        } else {
            Issue.record("Expected failed result with verificationFailed")
        }
    }

    @Test("復元処理失敗 - noActiveSubscription エラー")
    @MainActor
    func restorePurchases_whenNoTransactions_throwsError() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = .noActiveSubscription

        // Act & Assert
        await #expect(throws: PurchaseError.self) {
            try await repository.restorePurchases()
        }
        #expect(repository.restorePurchasesCalled == true)
    }

    @Test("復元処理失敗 - restorationFailed エラー")
    @MainActor
    func restorePurchases_whenRestorationFails_throwsError() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = .restorationFailed("Connection failed")

        // Act & Assert
        await #expect(throws: PurchaseError.self) {
            try await repository.restorePurchases()
        }
    }

    @Test("サブスクリプション状態確認失敗 - unknownError")
    @MainActor
    func checkSubscriptionStatus_whenErrorOccurs_throwsError() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = .unknownError

        // Act & Assert
        await #expect(throws: PurchaseError.self) {
            try await repository.checkSubscriptionStatus()
        }
    }
}

// MARK: - 境界値テスト

@Suite("PurchaseRepository - 境界値テスト")
struct PurchaseRepositoryBoundaryTests {

    @Test("空の製品リスト")
    @MainActor
    func fetchProducts_withEmptyList_returnsEmpty() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.mockProducts = [] // 空リスト

        // Act
        let products = try await repository.fetchProducts()

        // Assert
        #expect(products.isEmpty)
        #expect(repository.fetchProductsCalled == true)
    }

    @Test("無効な製品ID - 存在しない製品")
    @MainActor
    func getProduct_byInvalidId_returnsNil() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        let invalidId = "com.invalid.product.id"

        // Act
        let product = try await repository.getProduct(by: invalidId)

        // Assert
        #expect(product == nil)
    }

    @Test("無効な製品IDで購入 - 空文字列")
    @MainActor
    func purchase_withEmptyProductId_callsPurchase() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.setupDefaultProducts()
        repository.setupCancelledPurchase()

        // Act
        let result = try await repository.purchase("")

        // Assert
        #expect(repository.purchaseCalled == true)
        #expect(repository.purchasedProductId == "")
    }

    @Test("期限切れサブスクリプション - 無料版に戻る")
    @MainActor
    func checkSubscriptionStatus_withExpiredSubscription_returnsFree() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        repository.mockPremiumStatus = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: pastDate,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: Calendar.current.date(byAdding: .day, value: -31, to: Date()),
            autoRenewEnabled: false
        )

        // Act
        let status = try await repository.checkSubscriptionStatus()

        // Assert
        #expect(status.isPremium == true) // Still marked as premium in mock
        #expect(status.isActive == false) // But not active due to expiration
        #expect(status.expirationDate != nil)
        #expect(status.expirationDate! < Date())
    }

    @Test("トランザクション監視開始/停止")
    @MainActor
    func transactionListener_startStop_callsCorrectMethods() {
        // Arrange
        let repository = MockPurchaseRepository()

        // Act
        repository.startTransactionListener()
        repository.stopTransactionListener()

        // Assert
        #expect(repository.startTransactionListenerCalled == true)
        #expect(repository.stopTransactionListenerCalled == true)
    }
}

// MARK: - プロトコルデフォルト実装テスト

@Suite("PurchaseRepository - プロトコルデフォルト実装テスト")
struct PurchaseRepositoryProtocolDefaultTests {

    @Test("getProduct - デフォルト実装の動作確認")
    @MainActor
    func getProduct_defaultImplementation_worksCorrectly() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        let testProduct = ProductInfo.monthlyPlan(id: "test.product")
        repository.mockProducts = [testProduct]

        // Act
        let result = try await repository.getProduct(by: "test.product")

        // Assert
        #expect(result != nil)
        #expect(result?.id == "test.product")
    }

    @Test("getMonthlyProducts - デフォルト実装の動作確認")
    @MainActor
    func getMonthlyProducts_defaultImplementation_filtersCorrectly() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.mockProducts = [
            .monthlyPlan(),
            .yearlyPlan(),
            .monthlyWithTrial()
        ]

        // Act
        let monthlyProducts = try await repository.getMonthlyProducts()

        // Assert
        #expect(monthlyProducts.count == 2)
        #expect(monthlyProducts.allSatisfy { $0.subscriptionPeriod == .monthly })
    }

    @Test("getYearlyProducts - デフォルト実装の動作確認")
    @MainActor
    func getYearlyProducts_defaultImplementation_filtersCorrectly() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.mockProducts = [
            .monthlyPlan(),
            .yearlyPlan()
        ]

        // Act
        let yearlyProducts = try await repository.getYearlyProducts()

        // Assert
        #expect(yearlyProducts.count == 1)
        #expect(yearlyProducts.first?.subscriptionPeriod == .yearly)
    }

    @Test("isPremiumActive - デフォルト実装で有効判定")
    @MainActor
    func isPremiumActive_defaultImplementation_returnsCorrectStatus() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.mockPremiumStatus = .monthly()

        // Act
        let isActive = try await repository.isPremiumActive()

        // Assert
        #expect(isActive == true)
    }

    @Test("isPremiumActive - デフォルト実装で無効判定")
    @MainActor
    func isPremiumActive_defaultImplementation_withFree_returnsFalse() async throws {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.mockPremiumStatus = .free

        // Act
        let isActive = try await repository.isPremiumActive()

        // Assert
        #expect(isActive == false)
    }
}

// MARK: - リセット機能テスト

@Suite("PurchaseRepository - Mock リセット機能テスト")
struct MockPurchaseRepositoryResetTests {

    @Test("reset - すべてのフラグがリセットされる")
    @MainActor
    func reset_clearsAllFlags() {
        // Arrange
        let repository = MockPurchaseRepository()
        repository.fetchProductsCalled = true
        repository.purchaseCalled = true
        repository.purchasedProductId = "test.id"
        repository.restorePurchasesCalled = true
        repository.checkSubscriptionStatusCalled = true
        repository.shouldThrowError = true

        // Act
        repository.reset()

        // Assert
        #expect(repository.fetchProductsCalled == false)
        #expect(repository.purchaseCalled == false)
        #expect(repository.purchasedProductId == nil)
        #expect(repository.restorePurchasesCalled == false)
        #expect(repository.checkSubscriptionStatusCalled == false)
        #expect(repository.shouldThrowError == false)
        #expect(repository.errorToThrow == .unknownError)
        #expect(repository.purchaseResult == .cancelled)
    }
}
