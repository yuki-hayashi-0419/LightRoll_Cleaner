//
//  StoreKitManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StoreKitManager テストスイート
//  - 製品読み込みテスト
//  - 購入処理テスト
//  - 復元処理テスト
//  - サブスクリプション状態テスト
//

import Testing
import StoreKit
@testable import LightRoll_CleanerFeature

@Suite("StoreKitManager Tests")
@MainActor
struct StoreKitManagerTests {

    // MARK: - Test Properties

    let manager = StoreKitManager.shared

    // MARK: - Product Loading Tests

    @Test("製品情報の読み込み - 成功")
    func loadProductsSuccess() async throws {
        // Given: StoreKitマネージャー

        // When: 製品情報を読み込む（実際のStoreKit設定ファイルから）
        // Note: テスト環境ではConfiguration.storekitから読み込まれる
        do {
            let products = try await manager.loadProducts()

            // Then: 製品が読み込まれること
            #expect(!products.isEmpty, "製品が読み込まれること")

            // 月額・年額プランが含まれること
            let hasMonthly = products.contains { $0.id == ProductIdentifier.monthlyPremium.rawValue }
            let hasYearly = products.contains { $0.id == ProductIdentifier.yearlyPremium.rawValue }

            #expect(hasMonthly, "月額プランが含まれること")
            #expect(hasYearly, "年額プランが含まれること")

            // 各製品の基本情報が設定されていること
            for product in products {
                #expect(!product.id.isEmpty, "製品IDが設定されていること")
                #expect(!product.displayName.isEmpty, "表示名が設定されていること")
                #expect(!product.description.isEmpty, "説明が設定されていること")
                #expect(product.price >= 0, "価格が0以上であること")
                #expect(!product.priceFormatted.isEmpty, "フォーマット済み価格が設定されていること")
                #expect(product.subscriptionPeriod != nil, "サブスクリプション期間が設定されていること")
            }

        } catch {
            // テスト環境では製品が見つからない可能性があるため、エラーを許容
            Issue.record("製品読み込みエラー（テスト環境では正常）: \(error)")
        }
    }

    @Test("製品情報の読み込み - 月額プランの詳細")
    func loadMonthlyProductDetails() async throws {
        do {
            let products = try await manager.loadProducts()

            // When: 月額プランを取得
            if let monthlyProduct = products.first(where: { $0.id == ProductIdentifier.monthlyPremium.rawValue }) {
                // Then: 月額プランの詳細が正しいこと
                #expect(monthlyProduct.isMonthlySubscription, "月額サブスクリプションであること")
                #expect(!monthlyProduct.isYearlySubscription, "年額サブスクリプションではないこと")
                #expect(monthlyProduct.subscriptionPeriod == .monthly, "サブスクリプション期間が月次であること")

                // 無料トライアルが設定されていること
                #expect(monthlyProduct.hasIntroOffer, "初回オファーが設定されていること")
                #expect(monthlyProduct.hasFreeTrial, "無料トライアルが設定されていること")

                if let offer = monthlyProduct.introductoryOffer {
                    #expect(offer.isFreeTrial, "オファーが無料トライアルであること")
                    #expect(offer.period == 7, "トライアル期間が7日間であること")
                    #expect(offer.price == 0, "トライアル価格が0であること")
                }
            }

        } catch {
            Issue.record("製品読み込みエラー（テスト環境では正常）: \(error)")
        }
    }

    @Test("製品情報の読み込み - 年額プランの詳細")
    func loadYearlyProductDetails() async throws {
        do {
            let products = try await manager.loadProducts()

            // When: 年額プランを取得
            if let yearlyProduct = products.first(where: { $0.id == ProductIdentifier.yearlyPremium.rawValue }) {
                // Then: 年額プランの詳細が正しいこと
                #expect(!yearlyProduct.isMonthlySubscription, "月額サブスクリプションではないこと")
                #expect(yearlyProduct.isYearlySubscription, "年額サブスクリプションであること")
                #expect(yearlyProduct.subscriptionPeriod == .yearly, "サブスクリプション期間が年次であること")

                // 無料トライアルが設定されていないこと
                #expect(!yearlyProduct.hasFreeTrial, "無料トライアルが設定されていないこと")
            }

        } catch {
            Issue.record("製品読み込みエラー（テスト環境では正常）: \(error)")
        }
    }

    // MARK: - Subscription Status Tests

    @Test("サブスクリプション状態確認 - 無料版")
    func checkSubscriptionStatusFree() async throws {
        // Given: StoreKitマネージャー

        // When: サブスクリプション状態を確認
        let status = try await manager.checkSubscriptionStatus()

        // Then: 初期状態は無料版であること
        #expect(status.isFree, "無料版であること")
        #expect(!status.isPremium, "プレミアムではないこと")
        #expect(status.subscriptionType == .free, "サブスクリプションタイプが無料版であること")
        #expect(!status.isTrialActive, "トライアルが有効ではないこと")
        #expect(!status.isActive, "有効なステータスではないこと")
    }

    // MARK: - Error Handling Tests

    @Test("購入処理 - 製品が見つからない")
    func purchaseProductNotFound() async throws {
        // Given: 存在しない製品ID
        let invalidProductId = "invalid_product_id"

        // When: 購入を試みる
        // Then: productNotFoundエラーがスローされること
        await #expect(throws: PurchaseError.self) {
            try await manager.purchase(invalidProductId)
        }
    }

    @Test("復元処理 - 有効なサブスクリプションがない")
    func restorePurchasesNoSubscription() async throws {
        // Given: StoreKitマネージャー（初期状態）

        // When: 購入を復元する
        // Then: noActiveSubscriptionエラーがスローされること
        await #expect(throws: PurchaseError.self) {
            try await manager.restorePurchases()
        }
    }

    // MARK: - ProductIdentifier Tests

    @Test("ProductIdentifier - 全製品ID取得")
    func productIdentifierAllIdentifiers() {
        // When: 全製品IDを取得
        let identifiers = ProductIdentifier.allIdentifiers

        // Then: 2つの製品IDが含まれること
        #expect(identifiers.count == 2, "2つの製品IDが含まれること")
        #expect(identifiers.contains("monthly_premium"), "月額プランIDが含まれること")
        #expect(identifiers.contains("yearly_premium"), "年額プランIDが含まれること")
    }

    @Test("ProductIdentifier - 月額プランの詳細")
    func productIdentifierMonthlyDetails() {
        // Given: 月額プランID
        let monthly = ProductIdentifier.monthlyPremium

        // Then: 月額プランの詳細が正しいこと
        #expect(monthly.rawValue == "monthly_premium", "製品IDが正しいこと")
        #expect(monthly.displayName == "月額プラン", "表示名が正しいこと")
        #expect(!monthly.description.isEmpty, "説明が設定されていること")
        #expect(monthly.subscriptionPeriod == .monthly, "サブスクリプション期間が月次であること")
        #expect(monthly.isMonthly, "月額製品であること")
        #expect(!monthly.isYearly, "年額製品ではないこと")
        #expect(monthly.hasFreeTrial, "無料トライアルがあること")
        #expect(monthly.freeTrialDays == 7, "トライアル期間が7日間であること")
    }

    @Test("ProductIdentifier - 年額プランの詳細")
    func productIdentifierYearlyDetails() {
        // Given: 年額プランID
        let yearly = ProductIdentifier.yearlyPremium

        // Then: 年額プランの詳細が正しいこと
        #expect(yearly.rawValue == "yearly_premium", "製品IDが正しいこと")
        #expect(yearly.displayName == "年額プラン", "表示名が正しいこと")
        #expect(!yearly.description.isEmpty, "説明が設定されていること")
        #expect(yearly.subscriptionPeriod == .yearly, "サブスクリプション期間が年次であること")
        #expect(!yearly.isMonthly, "月額製品ではないこと")
        #expect(yearly.isYearly, "年額製品であること")
        #expect(!yearly.hasFreeTrial, "無料トライアルがないこと")
        #expect(yearly.freeTrialDays == nil, "トライアル期間が設定されていないこと")
    }

    @Test("ProductIdentifier - ProductInfo作成")
    func productIdentifierCreateProductInfo() {
        // Given: 月額プランID
        let monthly = ProductIdentifier.monthlyPremium

        // When: ProductInfoを作成
        let productInfo = monthly.createProductInfo(
            price: 980,
            priceFormatted: "¥980"
        )

        // Then: ProductInfoが正しく作成されること
        #expect(productInfo.id == "monthly_premium", "製品IDが正しいこと")
        #expect(productInfo.displayName == "月額プラン", "表示名が正しいこと")
        #expect(productInfo.price == 980, "価格が正しいこと")
        #expect(productInfo.priceFormatted == "¥980", "フォーマット済み価格が正しいこと")
        #expect(productInfo.subscriptionPeriod == .monthly, "サブスクリプション期間が正しいこと")
        #expect(productInfo.hasFreeTrial, "無料トライアルが設定されていること")

        if let offer = productInfo.introductoryOffer {
            #expect(offer.period == 7, "トライアル期間が7日間であること")
            #expect(offer.price == 0, "トライアル価格が0であること")
            #expect(offer.type == .freeTrial, "オファータイプが無料トライアルであること")
        }
    }

    // MARK: - Error Tests

    @Test("PurchaseError - エラーメッセージ")
    func purchaseErrorMessages() {
        // Given: 各種エラー
        let errors: [PurchaseError] = [
            .productNotFound,
            .purchaseFailed("テスト理由"),
            .purchaseCancelled,
            .verificationFailed,
            .noActiveSubscription,
            .restorationFailed("テスト理由"),
            .networkError,
            .unknownError
        ]

        // Then: 各エラーにメッセージが設定されていること
        for error in errors {
            #expect(error.errorDescription != nil, "エラーメッセージが設定されていること")
            #expect(!error.errorDescription!.isEmpty, "エラーメッセージが空でないこと")
        }
    }

    @Test("PurchaseError - Equatable準拠")
    func purchaseErrorEquatable() {
        // Given: 同じエラー
        let error1 = PurchaseError.productNotFound
        let error2 = PurchaseError.productNotFound

        // Then: 等価であること
        #expect(error1 == error2, "同じエラーは等価であること")

        // Given: 異なるエラー
        let error3 = PurchaseError.purchaseCancelled

        // Then: 等価でないこと
        #expect(error1 != error3, "異なるエラーは等価でないこと")
    }
}
