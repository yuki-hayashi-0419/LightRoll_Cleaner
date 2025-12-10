//
//  ProductIdentifiersTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ProductIdentifier テストスイート
//  - 製品ID定数テスト
//  - プロパティテスト
//  - ヘルパーメソッドテスト
//

import Testing
@testable import LightRoll_CleanerFeature

@Suite("ProductIdentifier Tests")
struct ProductIdentifiersTests {

    // MARK: - Basic Properties Tests

    @Test("ProductIdentifier - CaseIterable準拠")
    func productIdentifierCaseIterable() {
        // When: allCasesを取得
        let allCases = ProductIdentifier.allCases

        // Then: 2つのケースが含まれること
        #expect(allCases.count == 2, "2つのケースが含まれること")
        #expect(allCases.contains(.monthlyPremium), "monthlyPremiumが含まれること")
        #expect(allCases.contains(.yearlyPremium), "yearlyPremiumが含まれること")
    }

    @Test("ProductIdentifier - rawValue")
    func productIdentifierRawValue() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: rawValueが正しいこと
        #expect(monthly.rawValue == "monthly_premium", "月額プランのrawValueが正しいこと")
        #expect(yearly.rawValue == "yearly_premium", "年額プランのrawValueが正しいこと")
    }

    @Test("ProductIdentifier - displayName")
    func productIdentifierDisplayName() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: 表示名が正しいこと
        #expect(monthly.displayName == "月額プラン", "月額プランの表示名が正しいこと")
        #expect(yearly.displayName == "年額プラン", "年額プランの表示名が正しいこと")
    }

    @Test("ProductIdentifier - description")
    func productIdentifierDescription() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: 説明が空でないこと
        #expect(!monthly.description.isEmpty, "月額プランの説明が空でないこと")
        #expect(!yearly.description.isEmpty, "年額プランの説明が空でないこと")

        // Then: 説明に適切なキーワードが含まれること
        #expect(monthly.description.contains("月"), "月額プランの説明に「月」が含まれること")
        #expect(yearly.description.contains("年"), "年額プランの説明に「年」が含まれること")
    }

    // MARK: - Subscription Period Tests

    @Test("ProductIdentifier - subscriptionPeriod")
    func productIdentifierSubscriptionPeriod() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: サブスクリプション期間が正しいこと
        #expect(monthly.subscriptionPeriod == .monthly, "月額プランのサブスクリプション期間が月次であること")
        #expect(yearly.subscriptionPeriod == .yearly, "年額プランのサブスクリプション期間が年次であること")
    }

    @Test("ProductIdentifier - isMonthly")
    func productIdentifierIsMonthly() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: isMonthlyが正しいこと
        #expect(monthly.isMonthly, "月額プランがisMonthly == trueであること")
        #expect(!yearly.isMonthly, "年額プランがisMonthly == falseであること")
    }

    @Test("ProductIdentifier - isYearly")
    func productIdentifierIsYearly() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: isYearlyが正しいこと
        #expect(!monthly.isYearly, "月額プランがisYearly == falseであること")
        #expect(yearly.isYearly, "年額プランがisYearly == trueであること")
    }

    // MARK: - Free Trial Tests

    @Test("ProductIdentifier - hasFreeTrial")
    func productIdentifierHasFreeTrial() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: 無料トライアルの有無が正しいこと
        #expect(monthly.hasFreeTrial, "月額プランに無料トライアルがあること")
        #expect(!yearly.hasFreeTrial, "年額プランに無料トライアルがないこと")
    }

    @Test("ProductIdentifier - freeTrialDays")
    func productIdentifierFreeTrialDays() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: トライアル期間が正しいこと
        #expect(monthly.freeTrialDays == 7, "月額プランのトライアル期間が7日間であること")
        #expect(yearly.freeTrialDays == nil, "年額プランにトライアル期間が設定されていないこと")
    }

    // MARK: - Helper Methods Tests

    @Test("ProductIdentifier - allIdentifiers")
    func productIdentifierAllIdentifiers() {
        // When: 全製品IDを取得
        let identifiers = ProductIdentifier.allIdentifiers

        // Then: 正しい製品IDが含まれること
        #expect(identifiers.count == 2, "2つの製品IDが含まれること")
        #expect(identifiers.contains("monthly_premium"), "月額プランIDが含まれること")
        #expect(identifiers.contains("yearly_premium"), "年額プランIDが含まれること")
    }

    @Test("ProductIdentifier - createProductInfo - 月額プラン")
    func productIdentifierCreateProductInfoMonthly() {
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
        #expect(!productInfo.description.isEmpty, "説明が空でないこと")
        #expect(productInfo.price == 980, "価格が正しいこと")
        #expect(productInfo.priceFormatted == "¥980", "フォーマット済み価格が正しいこと")
        #expect(productInfo.subscriptionPeriod == .monthly, "サブスクリプション期間が月次であること")
        #expect(productInfo.isMonthlySubscription, "月額サブスクリプションであること")
        #expect(productInfo.hasIntroOffer, "初回オファーが設定されていること")
        #expect(productInfo.hasFreeTrial, "無料トライアルが設定されていること")

        // Then: 初回オファーの内容が正しいこと
        if let offer = productInfo.introductoryOffer {
            #expect(offer.price == 0, "トライアル価格が0であること")
            #expect(offer.priceFormatted == "¥0", "トライアルフォーマット価格が¥0であること")
            #expect(offer.period == 7, "トライアル期間が7日間であること")
            #expect(offer.type == .freeTrial, "オファータイプが無料トライアルであること")
            #expect(offer.isFreeTrial, "無料トライアルであること")
        } else {
            Issue.record("初回オファーが設定されていません")
        }
    }

    @Test("ProductIdentifier - createProductInfo - 年額プラン")
    func productIdentifierCreateProductInfoYearly() {
        // Given: 年額プランID
        let yearly = ProductIdentifier.yearlyPremium

        // When: ProductInfoを作成
        let productInfo = yearly.createProductInfo(
            price: 9800,
            priceFormatted: "¥9,800"
        )

        // Then: ProductInfoが正しく作成されること
        #expect(productInfo.id == "yearly_premium", "製品IDが正しいこと")
        #expect(productInfo.displayName == "年額プラン", "表示名が正しいこと")
        #expect(!productInfo.description.isEmpty, "説明が空でないこと")
        #expect(productInfo.price == 9800, "価格が正しいこと")
        #expect(productInfo.priceFormatted == "¥9,800", "フォーマット済み価格が正しいこと")
        #expect(productInfo.subscriptionPeriod == .yearly, "サブスクリプション期間が年次であること")
        #expect(productInfo.isYearlySubscription, "年額サブスクリプションであること")
        #expect(!productInfo.hasIntroOffer, "初回オファーが設定されていないこと")
        #expect(!productInfo.hasFreeTrial, "無料トライアルが設定されていないこと")
        #expect(productInfo.introductoryOffer == nil, "初回オファーがnilであること")
    }

    // MARK: - String Description Tests

    @Test("ProductIdentifier - stringDescription")
    func productIdentifierStringDescription() {
        // Given: 各製品ID
        let monthly = ProductIdentifier.monthlyPremium
        let yearly = ProductIdentifier.yearlyPremium

        // Then: stringDescription（文字列表現）が適切な形式であること
        let monthlyDescription = monthly.stringDescription
        let yearlyDescription = yearly.stringDescription

        #expect(monthlyDescription.contains("月額プラン"), "月額プランの説明に表示名が含まれること")
        #expect(monthlyDescription.contains("monthly_premium"), "月額プランの説明にrawValueが含まれること")
        #expect(yearlyDescription.contains("年額プラン"), "年額プランの説明に表示名が含まれること")
        #expect(yearlyDescription.contains("yearly_premium"), "年額プランの説明にrawValueが含まれること")
    }

    // MARK: - Equatable & Hashable Tests

    @Test("ProductIdentifier - Equatable")
    func productIdentifierEquatable() {
        // Given: 同じ製品ID
        let monthly1 = ProductIdentifier.monthlyPremium
        let monthly2 = ProductIdentifier.monthlyPremium

        // Then: 等価であること
        #expect(monthly1 == monthly2, "同じ製品IDは等価であること")

        // Given: 異なる製品ID
        let yearly = ProductIdentifier.yearlyPremium

        // Then: 等価でないこと
        #expect(monthly1 != yearly, "異なる製品IDは等価でないこと")
    }

    @Test("ProductIdentifier - Hashable")
    func productIdentifierHashable() {
        // Given: 製品IDセット
        var productSet = Set<ProductIdentifier>()

        // When: セットに追加
        productSet.insert(.monthlyPremium)
        productSet.insert(.yearlyPremium)
        productSet.insert(.monthlyPremium) // 重複

        // Then: 重複なく2つの要素が含まれること
        #expect(productSet.count == 2, "重複なく2つの要素が含まれること")
        #expect(productSet.contains(.monthlyPremium), "月額プランが含まれること")
        #expect(productSet.contains(.yearlyPremium), "年額プランが含まれること")
    }

    // MARK: - Sendable Tests

    @Test("ProductIdentifier - Sendable準拠")
    func productIdentifierSendable() async {
        // Given: 製品ID
        let monthly = ProductIdentifier.monthlyPremium

        // When: 別のタスクに送信
        let result = await Task.detached {
            return monthly.displayName
        }.value

        // Then: 正しく送信されること
        #expect(result == "月額プラン", "Sendableプロトコルに準拠していること")
    }
}
