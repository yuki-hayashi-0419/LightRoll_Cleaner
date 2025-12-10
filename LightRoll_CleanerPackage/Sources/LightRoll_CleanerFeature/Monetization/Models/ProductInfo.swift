//
//  ProductInfo.swift
//  LightRoll_CleanerFeature
//
//  StoreKit 2 製品情報モデル
//  - 製品ID、名前、価格情報
//  - サブスクリプション期間
//  - 初回割引オファー
//

import Foundation

// MARK: - SubscriptionPeriod

/// サブスクリプション期間
public enum SubscriptionPeriod: String, Codable, Sendable, Equatable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"

    /// 表示用ラベル
    public var displayName: String {
        switch self {
        case .monthly:
            return "月額"
        case .yearly:
            return "年額"
        }
    }

    /// 期間（日数）
    public var durationInDays: Int {
        switch self {
        case .monthly:
            return 30
        case .yearly:
            return 365
        }
    }
}

// MARK: - OfferType

/// オファー種類
public enum OfferType: String, Codable, Sendable, Equatable, CaseIterable {
    case freeTrial = "free_trial"
    case introPrice = "intro_price"
    case payUpFront = "pay_up_front"

    /// 表示用ラベル
    public var displayName: String {
        switch self {
        case .freeTrial:
            return "無料トライアル"
        case .introPrice:
            return "割引価格"
        case .payUpFront:
            return "前払い"
        }
    }
}

// MARK: - IntroductoryOffer

/// 初回割引オファー
public struct IntroductoryOffer: Codable, Sendable, Equatable {

    // MARK: - Properties

    /// 割引価格
    public var price: Decimal

    /// フォーマット済み価格
    public var priceFormatted: String

    /// 期間（日数）
    public var period: Int

    /// オファー種類
    public var type: OfferType

    // MARK: - Initialization

    public init(
        price: Decimal,
        priceFormatted: String,
        period: Int,
        type: OfferType
    ) {
        self.price = price
        self.priceFormatted = priceFormatted
        self.period = period
        self.type = type
    }
}

// MARK: - Helper Methods

extension IntroductoryOffer {

    /// 無料トライアルかどうか
    public var isFreeTrial: Bool {
        return type == .freeTrial && price == 0
    }

    /// オファー説明テキスト
    public var descriptionText: String {
        if isFreeTrial {
            return "\(period)日間無料トライアル"
        }
        return "\(priceFormatted)で\(period)日間"
    }
}

// MARK: - ProductInfo

/// StoreKit 2 製品情報モデル
public struct ProductInfo: Codable, Sendable, Equatable {

    // MARK: - Properties

    /// 製品ID（StoreKit Product.id）
    public var id: String

    /// 表示名
    public var displayName: String

    /// 説明
    public var description: String

    /// 価格
    public var price: Decimal

    /// フォーマット済み価格表示（例: "¥980"）
    public var priceFormatted: String

    /// サブスクリプション期間
    public var subscriptionPeriod: SubscriptionPeriod?

    /// 初回割引オファー
    public var introductoryOffer: IntroductoryOffer?

    // MARK: - Initialization

    public init(
        id: String,
        displayName: String,
        description: String,
        price: Decimal,
        priceFormatted: String,
        subscriptionPeriod: SubscriptionPeriod? = nil,
        introductoryOffer: IntroductoryOffer? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.priceFormatted = priceFormatted
        self.subscriptionPeriod = subscriptionPeriod
        self.introductoryOffer = introductoryOffer
    }
}

// MARK: - Helper Methods

extension ProductInfo {

    /// サブスクリプション製品かどうか
    public var isSubscription: Bool {
        return subscriptionPeriod != nil
    }

    /// 月額製品かどうか
    public var isMonthlySubscription: Bool {
        return subscriptionPeriod == .monthly
    }

    /// 年額製品かどうか
    public var isYearlySubscription: Bool {
        return subscriptionPeriod == .yearly
    }

    /// トライアルありかどうか
    public var hasIntroOffer: Bool {
        return introductoryOffer != nil
    }

    /// 無料トライアルありかどうか
    public var hasFreeTrial: Bool {
        return introductoryOffer?.isFreeTrial ?? false
    }

    /// 製品説明テキスト（期間付き）
    public var fullDescription: String {
        var text = description

        if let period = subscriptionPeriod {
            text += " - \(period.displayName)"
        }

        if let offer = introductoryOffer {
            text += "\n" + offer.descriptionText
        }

        return text
    }

    /// 価格説明テキスト
    public var priceDescription: String {
        guard let period = subscriptionPeriod else {
            return priceFormatted
        }

        switch period {
        case .monthly:
            return "\(priceFormatted) / 月"
        case .yearly:
            return "\(priceFormatted) / 年"
        }
    }
}

// MARK: - Identifiable

extension ProductInfo: Identifiable {
    // IDプロトコル準拠（SwiftUI対応）
}

// MARK: - Factory Methods

extension ProductInfo {

    /// 月額プラン製品
    /// - Parameters:
    ///   - id: 製品ID
    ///   - price: 価格
    ///   - priceFormatted: フォーマット済み価格
    /// - Returns: 月額プラン製品情報
    public static func monthlyPlan(
        id: String = "com.lightroll.premium.monthly",
        price: Decimal = 980,
        priceFormatted: String = "¥980"
    ) -> ProductInfo {
        return ProductInfo(
            id: id,
            displayName: "月額プラン",
            description: "毎月自動更新されるプレミアムプラン",
            price: price,
            priceFormatted: priceFormatted,
            subscriptionPeriod: .monthly,
            introductoryOffer: nil
        )
    }

    /// 年額プラン製品
    /// - Parameters:
    ///   - id: 製品ID
    ///   - price: 価格
    ///   - priceFormatted: フォーマット済み価格
    /// - Returns: 年額プラン製品情報
    public static func yearlyPlan(
        id: String = "com.lightroll.premium.yearly",
        price: Decimal = 9800,
        priceFormatted: String = "¥9,800"
    ) -> ProductInfo {
        return ProductInfo(
            id: id,
            displayName: "年額プラン",
            description: "年1回自動更新されるプレミアムプラン（2ヶ月分お得）",
            price: price,
            priceFormatted: priceFormatted,
            subscriptionPeriod: .yearly,
            introductoryOffer: nil
        )
    }

    /// トライアル付き月額プラン製品
    /// - Parameters:
    ///   - id: 製品ID
    ///   - price: 価格
    ///   - priceFormatted: フォーマット済み価格
    ///   - trialDays: トライアル期間（日数）
    /// - Returns: トライアル付き月額プラン製品情報
    public static func monthlyWithTrial(
        id: String = "com.lightroll.premium.monthly",
        price: Decimal = 980,
        priceFormatted: String = "¥980",
        trialDays: Int = 7
    ) -> ProductInfo {
        return ProductInfo(
            id: id,
            displayName: "月額プラン",
            description: "毎月自動更新されるプレミアムプラン",
            price: price,
            priceFormatted: priceFormatted,
            subscriptionPeriod: .monthly,
            introductoryOffer: IntroductoryOffer(
                price: 0,
                priceFormatted: "¥0",
                period: trialDays,
                type: .freeTrial
            )
        )
    }
}
