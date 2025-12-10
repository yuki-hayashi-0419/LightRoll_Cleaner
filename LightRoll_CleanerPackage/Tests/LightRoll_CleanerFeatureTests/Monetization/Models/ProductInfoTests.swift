//
//  ProductInfoTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ProductInfoモデルのテスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - SubscriptionPeriod Tests

@Suite("SubscriptionPeriod Tests")
struct SubscriptionPeriodTests {

    @Test("月額期間の表示名と日数")
    func monthlyPeriodProperties() {
        let period = SubscriptionPeriod.monthly

        #expect(period.displayName == "月額")
        #expect(period.durationInDays == 30)
        #expect(period.rawValue == "monthly")
    }

    @Test("年額期間の表示名と日数")
    func yearlyPeriodProperties() {
        let period = SubscriptionPeriod.yearly

        #expect(period.displayName == "年額")
        #expect(period.durationInDays == 365)
        #expect(period.rawValue == "yearly")
    }

    @Test("SubscriptionPeriodのCodable")
    func subscriptionPeriodCodable() throws {
        let period = SubscriptionPeriod.monthly

        let encoder = JSONEncoder()
        let data = try encoder.encode(period)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SubscriptionPeriod.self, from: data)

        #expect(decoded == period)
    }
}

// MARK: - OfferType Tests

@Suite("OfferType Tests")
struct OfferTypeTests {

    @Test("無料トライアルの表示名")
    func freeTrialDisplayName() {
        let offer = OfferType.freeTrial

        #expect(offer.displayName == "無料トライアル")
        #expect(offer.rawValue == "free_trial")
    }

    @Test("割引価格の表示名")
    func introPriceDisplayName() {
        let offer = OfferType.introPrice

        #expect(offer.displayName == "割引価格")
        #expect(offer.rawValue == "intro_price")
    }

    @Test("前払いの表示名")
    func payUpFrontDisplayName() {
        let offer = OfferType.payUpFront

        #expect(offer.displayName == "前払い")
        #expect(offer.rawValue == "pay_up_front")
    }
}

// MARK: - IntroductoryOffer Tests

@Suite("IntroductoryOffer Tests")
struct IntroductoryOfferTests {

    @Test("無料トライアルオファーの初期化")
    func initializeFreeTrial() {
        let offer = IntroductoryOffer(
            price: 0,
            priceFormatted: "¥0",
            period: 7,
            type: .freeTrial
        )

        #expect(offer.price == 0)
        #expect(offer.priceFormatted == "¥0")
        #expect(offer.period == 7)
        #expect(offer.type == .freeTrial)
    }

    @Test("無料トライアル判定")
    func isFreeTrialCheck() {
        let freeTrial = IntroductoryOffer(
            price: 0,
            priceFormatted: "¥0",
            period: 7,
            type: .freeTrial
        )
        #expect(freeTrial.isFreeTrial == true)

        let paidIntro = IntroductoryOffer(
            price: 100,
            priceFormatted: "¥100",
            period: 7,
            type: .introPrice
        )
        #expect(paidIntro.isFreeTrial == false)
    }

    @Test("オファー説明テキスト生成")
    func offerDescriptionText() {
        let freeTrial = IntroductoryOffer(
            price: 0,
            priceFormatted: "¥0",
            period: 7,
            type: .freeTrial
        )
        #expect(freeTrial.descriptionText == "7日間無料トライアル")

        let paidIntro = IntroductoryOffer(
            price: 100,
            priceFormatted: "¥100",
            period: 14,
            type: .introPrice
        )
        #expect(paidIntro.descriptionText == "¥100で14日間")
    }

    @Test("IntroductoryOfferのCodable")
    func introductoryOfferCodable() throws {
        let offer = IntroductoryOffer(
            price: 100,
            priceFormatted: "¥100",
            period: 7,
            type: .introPrice
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(offer)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(IntroductoryOffer.self, from: data)

        #expect(decoded == offer)
    }

    @Test("IntroductoryOfferのEquatable")
    func introductoryOfferEquatable() {
        let offer1 = IntroductoryOffer(
            price: 0,
            priceFormatted: "¥0",
            period: 7,
            type: .freeTrial
        )

        let offer2 = IntroductoryOffer(
            price: 0,
            priceFormatted: "¥0",
            period: 7,
            type: .freeTrial
        )

        let offer3 = IntroductoryOffer(
            price: 100,
            priceFormatted: "¥100",
            period: 7,
            type: .introPrice
        )

        #expect(offer1 == offer2)
        #expect(offer1 != offer3)
    }
}

// MARK: - ProductInfo Tests

@Suite("ProductInfo Tests")
struct ProductInfoTests {

    @Test("基本的な製品情報の初期化")
    func initializeBasicProduct() {
        let product = ProductInfo(
            id: "com.test.product",
            displayName: "テスト製品",
            description: "テスト用の製品",
            price: 1000,
            priceFormatted: "¥1,000",
            subscriptionPeriod: .monthly,
            introductoryOffer: nil
        )

        #expect(product.id == "com.test.product")
        #expect(product.displayName == "テスト製品")
        #expect(product.description == "テスト用の製品")
        #expect(product.price == 1000)
        #expect(product.priceFormatted == "¥1,000")
        #expect(product.subscriptionPeriod == .monthly)
        #expect(product.introductoryOffer == nil)
    }

    @Test("月額製品判定")
    func monthlySubscriptionCheck() {
        let monthly = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly
        )

        #expect(monthly.isSubscription == true)
        #expect(monthly.isMonthlySubscription == true)
        #expect(monthly.isYearlySubscription == false)
    }

    @Test("年額製品判定")
    func yearlySubscriptionCheck() {
        let yearly = ProductInfo(
            id: "test",
            displayName: "年額",
            description: "",
            price: 9800,
            priceFormatted: "¥9,800",
            subscriptionPeriod: .yearly
        )

        #expect(yearly.isSubscription == true)
        #expect(yearly.isYearlySubscription == true)
        #expect(yearly.isMonthlySubscription == false)
    }

    @Test("非サブスクリプション製品判定")
    func nonSubscriptionCheck() {
        let product = ProductInfo(
            id: "test",
            displayName: "買い切り",
            description: "",
            price: 5000,
            priceFormatted: "¥5,000",
            subscriptionPeriod: nil
        )

        #expect(product.isSubscription == false)
        #expect(product.isMonthlySubscription == false)
        #expect(product.isYearlySubscription == false)
    }

    @Test("トライアルオファー判定")
    func introOfferCheck() {
        let withTrial = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly,
            introductoryOffer: IntroductoryOffer(
                price: 0,
                priceFormatted: "¥0",
                period: 7,
                type: .freeTrial
            )
        )

        #expect(withTrial.hasIntroOffer == true)
        #expect(withTrial.hasFreeTrial == true)

        let withoutTrial = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly
        )

        #expect(withoutTrial.hasIntroOffer == false)
        #expect(withoutTrial.hasFreeTrial == false)
    }

    @Test("完全な製品説明テキスト")
    func fullDescriptionGeneration() {
        let basicProduct = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "基本プラン",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly
        )
        #expect(basicProduct.fullDescription == "基本プラン - 月額")

        let withTrial = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "トライアル付きプラン",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly,
            introductoryOffer: IntroductoryOffer(
                price: 0,
                priceFormatted: "¥0",
                period: 7,
                type: .freeTrial
            )
        )
        #expect(withTrial.fullDescription == "トライアル付きプラン - 月額\n7日間無料トライアル")
    }

    @Test("価格説明テキスト")
    func priceDescriptionGeneration() {
        let monthly = ProductInfo(
            id: "test",
            displayName: "月額",
            description: "",
            price: 980,
            priceFormatted: "¥980",
            subscriptionPeriod: .monthly
        )
        #expect(monthly.priceDescription == "¥980 / 月")

        let yearly = ProductInfo(
            id: "test",
            displayName: "年額",
            description: "",
            price: 9800,
            priceFormatted: "¥9,800",
            subscriptionPeriod: .yearly
        )
        #expect(yearly.priceDescription == "¥9,800 / 年")

        let oneTime = ProductInfo(
            id: "test",
            displayName: "買い切り",
            description: "",
            price: 5000,
            priceFormatted: "¥5,000"
        )
        #expect(oneTime.priceDescription == "¥5,000")
    }

    @Test("ProductInfoのCodable")
    func productInfoCodable() throws {
        let product = ProductInfo(
            id: "com.test.product",
            displayName: "テスト製品",
            description: "説明",
            price: 1000,
            priceFormatted: "¥1,000",
            subscriptionPeriod: .monthly,
            introductoryOffer: IntroductoryOffer(
                price: 0,
                priceFormatted: "¥0",
                period: 7,
                type: .freeTrial
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(product)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProductInfo.self, from: data)

        #expect(decoded == product)
    }

    @Test("ProductInfoのEquatable")
    func productInfoEquatable() {
        let product1 = ProductInfo(
            id: "test",
            displayName: "製品",
            description: "説明",
            price: 1000,
            priceFormatted: "¥1,000"
        )

        let product2 = ProductInfo(
            id: "test",
            displayName: "製品",
            description: "説明",
            price: 1000,
            priceFormatted: "¥1,000"
        )

        let product3 = ProductInfo(
            id: "different",
            displayName: "別製品",
            description: "説明",
            price: 2000,
            priceFormatted: "¥2,000"
        )

        #expect(product1 == product2)
        #expect(product1 != product3)
    }

    @Test("月額プランファクトリ")
    func monthlyPlanFactory() {
        let product = ProductInfo.monthlyPlan()

        #expect(product.id == "com.lightroll.premium.monthly")
        #expect(product.displayName == "月額プラン")
        #expect(product.price == 980)
        #expect(product.priceFormatted == "¥980")
        #expect(product.subscriptionPeriod == .monthly)
        #expect(product.introductoryOffer == nil)
    }

    @Test("年額プランファクトリ")
    func yearlyPlanFactory() {
        let product = ProductInfo.yearlyPlan()

        #expect(product.id == "com.lightroll.premium.yearly")
        #expect(product.displayName == "年額プラン")
        #expect(product.price == 9800)
        #expect(product.priceFormatted == "¥9,800")
        #expect(product.subscriptionPeriod == .yearly)
        #expect(product.introductoryOffer == nil)
    }

    @Test("トライアル付き月額プランファクトリ")
    func monthlyWithTrialFactory() {
        let product = ProductInfo.monthlyWithTrial()

        #expect(product.id == "com.lightroll.premium.monthly")
        #expect(product.displayName == "月額プラン")
        #expect(product.price == 980)
        #expect(product.subscriptionPeriod == .monthly)
        #expect(product.hasFreeTrial == true)
        #expect(product.introductoryOffer?.period == 7)
    }

    @Test("カスタムパラメータ付きファクトリ")
    func customParameterFactory() {
        let product = ProductInfo.monthlyWithTrial(
            id: "custom.id",
            price: 1500,
            priceFormatted: "¥1,500",
            trialDays: 14
        )

        #expect(product.id == "custom.id")
        #expect(product.price == 1500)
        #expect(product.priceFormatted == "¥1,500")
        #expect(product.introductoryOffer?.period == 14)
    }
}
