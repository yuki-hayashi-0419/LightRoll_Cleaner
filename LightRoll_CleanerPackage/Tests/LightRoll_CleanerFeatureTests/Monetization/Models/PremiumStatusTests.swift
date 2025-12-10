//
//  PremiumStatusTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PremiumStatusモデルのテスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

@Suite("PremiumStatus Model Tests")
struct PremiumStatusTests {

    // MARK: - Initialization Tests

    @Test("初期化 - デフォルト値")
    func testInitializationWithDefaults() {
        let status = PremiumStatus()

        #expect(!status.isPremium)
        #expect(status.subscriptionType == .free)
        #expect(status.expirationDate == nil)
        #expect(!status.isTrialActive)
        #expect(status.trialEndDate == nil)
        #expect(status.purchaseDate == nil)
        #expect(!status.autoRenewEnabled)
    }

    @Test("初期化 - カスタム値")
    func testInitializationWithCustomValues() {
        let now = Date()
        let expiration = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: expiration,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: now,
            autoRenewEnabled: true
        )

        #expect(status.isPremium)
        #expect(status.subscriptionType == .monthly)
        #expect(status.expirationDate == expiration)
        #expect(!status.isTrialActive)
        #expect(status.trialEndDate == nil)
        #expect(status.purchaseDate == now)
        #expect(status.autoRenewEnabled)
    }

    // MARK: - Factory Methods Tests

    @Test("ファクトリメソッド - 無料版")
    func testFreeFactoryMethod() {
        let status = PremiumStatus.free

        #expect(!status.isPremium)
        #expect(status.isFree)
        #expect(status.subscriptionType == .free)
        #expect(status.expirationDate == nil)
        #expect(!status.isTrialActive)
        #expect(!status.autoRenewEnabled)
    }

    @Test("ファクトリメソッド - トライアル")
    func testTrialFactoryMethod() {
        let status = PremiumStatus.trial(days: 7)

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.isTrialActive)
        #expect(status.trialEndDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(status.autoRenewEnabled)

        // トライアルが有効であることを確認
        #expect(status.isTrialValid)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - 月額プラン")
    func testMonthlyFactoryMethod() {
        let status = PremiumStatus.monthly(autoRenew: true)

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.subscriptionType == .monthly)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(status.autoRenewEnabled)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - 年額プラン")
    func testYearlyFactoryMethod() {
        let status = PremiumStatus.yearly(autoRenew: false)

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.subscriptionType == .yearly)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(!status.autoRenewEnabled)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - プレミアム（デフォルト = 月額プラン）")
    func testPremiumFactoryMethodDefault() {
        let status = PremiumStatus.premium()

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.subscriptionType == .monthly)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(status.autoRenewEnabled)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - プレミアム（年額プラン指定）")
    func testPremiumFactoryMethodYearly() {
        let status = PremiumStatus.premium(subscriptionType: .yearly)

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.subscriptionType == .yearly)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(status.autoRenewEnabled)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - プレミアム（自動更新なし）")
    func testPremiumFactoryMethodNoAutoRenew() {
        let status = PremiumStatus.premium(autoRenew: false)

        #expect(status.isPremium)
        #expect(!status.isFree)
        #expect(status.subscriptionType == .monthly)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate != nil)
        #expect(status.purchaseDate != nil)
        #expect(!status.autoRenewEnabled)
        #expect(status.isActive)
    }

    @Test("ファクトリメソッド - プレミアム（free指定で無料版に）")
    func testPremiumFactoryMethodFree() {
        let status = PremiumStatus.premium(subscriptionType: .free)

        #expect(!status.isPremium)
        #expect(status.isFree)
        #expect(status.subscriptionType == .free)
        #expect(!status.isTrialActive)
        #expect(status.expirationDate == nil)
        #expect(status.purchaseDate == nil)
        #expect(!status.autoRenewEnabled)
        #expect(!status.isActive)
    }

    @Test("ファクトリメソッド - プレミアム（カスタム開始日）")
    func testPremiumFactoryMethodCustomStartDate() {
        let customDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let status = PremiumStatus.premium(
            subscriptionType: .yearly,
            startDate: customDate,
            autoRenew: true
        )

        #expect(status.isPremium)
        #expect(status.subscriptionType == .yearly)
        #expect(status.purchaseDate == customDate)
        #expect(status.autoRenewEnabled)
        #expect(status.isActive)

        // 1年後の日付が正しく設定されているか確認
        let expectedExpiration = Calendar.current.date(byAdding: .year, value: 1, to: customDate)
        #expect(status.expirationDate == expectedExpiration)
    }

    // MARK: - Helper Methods Tests

    @Test("ヘルパーメソッド - isFree")
    func testIsFree() {
        let freeStatus = PremiumStatus.free
        let premiumStatus = PremiumStatus.monthly()

        #expect(freeStatus.isFree)
        #expect(!premiumStatus.isFree)
    }

    @Test("ヘルパーメソッド - isActive（有効なプレミアム）")
    func testIsActiveValid() {
        let future = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: future,
            autoRenewEnabled: true
        )

        #expect(status.isActive)
        #expect(status.isSubscriptionValid)
    }

    @Test("ヘルパーメソッド - isActive（期限切れ）")
    func testIsActiveExpired() {
        let past = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: past,
            autoRenewEnabled: false
        )

        #expect(!status.isActive)
        #expect(!status.isSubscriptionValid)
    }

    @Test("ヘルパーメソッド - isTrialValid（有効なトライアル）")
    func testIsTrialValid() {
        let futureTrialEnd = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            isTrialActive: true,
            trialEndDate: futureTrialEnd
        )

        #expect(status.isTrialValid)
        #expect(status.isActive)
    }

    @Test("ヘルパーメソッド - isTrialValid（期限切れトライアル）")
    func testIsTrialExpired() {
        let pastTrialEnd = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            isTrialActive: true,
            trialEndDate: pastTrialEnd
        )

        #expect(!status.isTrialValid)
        #expect(!status.isActive)
    }

    @Test("ヘルパーメソッド - daysRemaining（残り日数）")
    func testDaysRemaining() {
        let future = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: future,
            autoRenewEnabled: true
        )

        let days = status.daysRemaining
        #expect(days != nil)
        #expect(days! >= 14 && days! <= 15) // 計算の誤差を考慮
    }

    @Test("ヘルパーメソッド - daysRemaining（トライアル）")
    func testDaysRemainingForTrial() {
        let trialEnd = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: trialEnd,
            isTrialActive: true,
            trialEndDate: trialEnd
        )

        let days = status.daysRemaining
        #expect(days != nil)
        #expect(days! >= 4 && days! <= 5)
    }

    @Test("ヘルパーメソッド - statusText（各種ステータス）")
    func testStatusText() {
        // 無料版
        let freeStatus = PremiumStatus.free
        #expect(freeStatus.statusText == "無料版")

        // トライアル中
        let trialStatus = PremiumStatus.trial(days: 7)
        #expect(trialStatus.statusText.contains("トライアル中"))

        // 月額プラン（自動更新）
        let monthlyStatus = PremiumStatus.monthly(autoRenew: true)
        #expect(monthlyStatus.statusText.contains("月額プラン"))
        #expect(monthlyStatus.statusText.contains("自動更新"))

        // 期限切れ
        let expiredStatus = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )
        #expect(expiredStatus.statusText == "期限切れ")
    }

    // MARK: - Codable Tests

    @Test("Codable - エンコード・デコード")
    func testCodable() throws {
        let now = Date()
        let expiration = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        let original = PremiumStatus(
            isPremium: true,
            subscriptionType: .yearly,
            expirationDate: expiration,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: now,
            autoRenewEnabled: true
        )

        // エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // デコード
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PremiumStatus.self, from: data)

        // 検証
        #expect(decoded.isPremium == original.isPremium)
        #expect(decoded.subscriptionType == original.subscriptionType)
        #expect(decoded.expirationDate?.timeIntervalSince1970 == original.expirationDate?.timeIntervalSince1970)
        #expect(decoded.isTrialActive == original.isTrialActive)
        #expect(decoded.trialEndDate == original.trialEndDate)
        #expect(decoded.purchaseDate?.timeIntervalSince1970 == original.purchaseDate?.timeIntervalSince1970)
        #expect(decoded.autoRenewEnabled == original.autoRenewEnabled)
    }

    @Test("Codable - nilプロパティのエンコード・デコード")
    func testCodableWithNilProperties() throws {
        let original = PremiumStatus.free

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PremiumStatus.self, from: data)

        #expect(!decoded.isPremium)
        #expect(decoded.expirationDate == nil)
        #expect(decoded.trialEndDate == nil)
        #expect(decoded.purchaseDate == nil)
    }

    // MARK: - Equatable Tests

    @Test("Equatable - 同一ステータス")
    func testEquatableSameStatus() {
        let status1 = PremiumStatus.free
        let status2 = PremiumStatus.free

        #expect(status1 == status2)
    }

    @Test("Equatable - 異なるステータス")
    func testEquatableDifferentStatus() {
        let status1 = PremiumStatus.free
        let status2 = PremiumStatus.monthly()

        #expect(status1 != status2)
    }

    @Test("Equatable - 異なる日付")
    func testEquatableDifferentDates() {
        let now = Date()
        let expiration1 = Calendar.current.date(byAdding: .day, value: 30, to: now)!
        let expiration2 = Calendar.current.date(byAdding: .day, value: 60, to: now)!

        let status1 = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: expiration1
        )

        let status2 = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: expiration2
        )

        #expect(status1 != status2)
    }

    // MARK: - SubscriptionType Tests

    @Test("SubscriptionType - displayName")
    func testSubscriptionTypeDisplayName() {
        #expect(SubscriptionType.free.displayName == "無料版")
        #expect(SubscriptionType.monthly.displayName == "月額プラン")
        #expect(SubscriptionType.yearly.displayName == "年額プラン")
    }

    @Test("SubscriptionType - duration")
    func testSubscriptionTypeDuration() {
        #expect(SubscriptionType.free.duration == nil)
        #expect(SubscriptionType.monthly.duration == 2592000) // 30日
        #expect(SubscriptionType.yearly.duration == 31536000) // 365日
    }

    @Test("SubscriptionType - CaseIterable")
    func testSubscriptionTypeCaseIterable() {
        let allCases = SubscriptionType.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.free))
        #expect(allCases.contains(.monthly))
        #expect(allCases.contains(.yearly))
    }

    // MARK: - Edge Cases Tests

    @Test("エッジケース - 期限ちょうどの時刻")
    func testExactExpirationTime() {
        let exactExpiration = Date()
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: exactExpiration
        )

        // 現在時刻と完全に同じ場合は期限切れとみなされる
        #expect(!status.isSubscriptionValid)
    }

    @Test("エッジケース - 負の残り日数")
    func testNegativeDaysRemaining() {
        let past = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: past
        )

        let days = status.daysRemaining
        #expect(days == 0) // 負の日数は0に丸められる
    }

    @Test("エッジケース - トライアルフラグのみ有効（trialEndDateがnil）")
    func testTrialActiveWithoutEndDate() {
        let status = PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            isTrialActive: true,
            trialEndDate: nil
        )

        #expect(!status.isTrialValid)
        #expect(!status.isActive)
    }

    @Test("エッジケース - プレミアムフラグなしでexpirationDateあり")
    func testNonPremiumWithExpirationDate() {
        let future = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let status = PremiumStatus(
            isPremium: false,
            subscriptionType: .free,
            expirationDate: future
        )

        #expect(!status.isActive) // isPremium=falseなのでisActiveはfalse
        #expect(status.isFree)
    }
}
