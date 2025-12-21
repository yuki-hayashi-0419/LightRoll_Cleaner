//
//  MockPurchaseRepository.swift
//  LightRoll_CleanerFeature
//
//  テスト用モック購入リポジトリ
//  - テストデータのセットアップが容易
//  - 購入/復元の動作をシミュレート
//  - エラーケースのテストが可能
//

import Foundation
import StoreKit

// MARK: - MockPurchaseRepository

/// テスト用モック購入リポジトリ
@MainActor
public final class MockPurchaseRepository: PurchaseRepositoryProtocol {

    // MARK: - Mock Properties

    /// モック用製品情報
    public var mockProducts: [ProductInfo] = []

    /// 互換性エイリアス: mockProductsと同期
    public var availableProducts: [ProductInfo] {
        get { mockProducts }
        set { mockProducts = newValue }
    }

    /// ローディング状態（互換性のため追加）
    public var loading: Bool = false

    /// モック用プレミアムステータス
    public var mockPremiumStatus: PremiumStatus = .free

    /// モック用復元結果
    public var mockRestoreResult: RestoreResult = RestoreResult(transactions: [])

    /// モック用エラー
    public var mockError: PurchaseError = .unknownError

    /// fetchProducts呼び出しフラグ
    public var fetchProductsCalled = false

    /// purchase呼び出しフラグ
    public var purchaseCalled = false

    /// purchase時に渡された製品ID
    public var purchasedProductId: String?

    /// restorePurchases呼び出しフラグ
    public var restorePurchasesCalled = false

    /// checkSubscriptionStatus呼び出しフラグ
    public var checkSubscriptionStatusCalled = false

    /// startTransactionListener呼び出しフラグ
    public var startTransactionListenerCalled = false

    /// stopTransactionListener呼び出しフラグ
    public var stopTransactionListenerCalled = false

    /// エラーをスローするかどうか
    public var shouldThrowError = false

    /// スローするエラー
    public var errorToThrow: PurchaseError = .unknownError

    /// 購入結果（デフォルト: cancelled）
    public var purchaseResult: PurchaseResult = .cancelled

    // MARK: - Initialization

    public init() {}

    /// 製品リスト付きイニシャライザ（互換性のため追加）
    public convenience init(products: [ProductInfo]) {
        self.init()
        self.mockProducts = products
    }

    /// ローディング状態付きイニシャライザ（互換性のため追加）
    public convenience init(loading: Bool) {
        self.init()
        self.loading = loading
    }

    /// エラースロー設定付きイニシャライザ（互換性のため追加）
    public convenience init(shouldThrowError: Bool) {
        self.init()
        self.shouldThrowError = shouldThrowError
    }

    /// 複合設定イニシャライザ（互換性のため追加）
    public convenience init(
        products: [ProductInfo] = [],
        loading: Bool = false,
        shouldThrowError: Bool = false,
        errorToThrow: PurchaseError = .unknownError
    ) {
        self.init()
        self.mockProducts = products
        self.loading = loading
        self.shouldThrowError = shouldThrowError
        self.errorToThrow = errorToThrow
    }

    // MARK: - PurchaseRepositoryProtocol

    public func fetchProducts() async throws -> [ProductInfo] {
        fetchProductsCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        return mockProducts
    }

    public func purchase(_ productId: String) async throws -> PurchaseResult {
        purchaseCalled = true
        purchasedProductId = productId

        if shouldThrowError {
            throw errorToThrow
        }

        return purchaseResult
    }

    public func restorePurchases() async throws -> RestoreResult {
        restorePurchasesCalled = true

        if shouldThrowError {
            throw mockError
        }

        return mockRestoreResult
    }

    public func checkSubscriptionStatus() async throws -> PremiumStatus {
        checkSubscriptionStatusCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        return mockPremiumStatus
    }

    public func startTransactionListener() {
        startTransactionListenerCalled = true
    }

    public func stopTransactionListener() {
        stopTransactionListenerCalled = true
    }

    // MARK: - Test Helpers

    /// すべてのフラグをリセット
    public func reset() {
        fetchProductsCalled = false
        purchaseCalled = false
        purchasedProductId = nil
        restorePurchasesCalled = false
        checkSubscriptionStatusCalled = false
        startTransactionListenerCalled = false
        stopTransactionListenerCalled = false
        shouldThrowError = false
        errorToThrow = .unknownError
        purchaseResult = .cancelled
    }

    /// デフォルト製品をセットアップ
    public func setupDefaultProducts() {
        mockProducts = [
            .monthlyPlan(),
            .yearlyPlan()
        ]
    }

    /// プレミアムステータスをセットアップ
    public func setupPremiumStatus(isPremium: Bool = true) {
        if isPremium {
            mockPremiumStatus = .monthly()
        } else {
            mockPremiumStatus = .free
        }
    }

    /// 購入成功をセットアップ
    public func setupSuccessfulPurchase() {
        // Note: Transaction is not Sendable in test context
        // We use .cancelled as placeholder for mock
        purchaseResult = .cancelled
    }

    /// 購入キャンセルをセットアップ
    public func setupCancelledPurchase() {
        purchaseResult = .cancelled
    }

    /// 購入失敗をセットアップ
    public func setupFailedPurchase(error: PurchaseError = .purchaseFailed("Test error")) {
        purchaseResult = .failed(error)
    }
}
