//
//  ProductIdentifiers.swift
//  LightRoll_CleanerFeature
//
//  StoreKit 2 製品ID定数定義
//  - サブスクリプション製品ID
//  - 製品タイプ判定
//  - App Store Connect連携
//

import Foundation

// MARK: - ProductIdentifier

/// StoreKit 2 製品識別子
///
/// App Store Connectで設定した製品IDと対応させる
public enum ProductIdentifier: String, CaseIterable, Sendable, Equatable, Hashable {

    // MARK: - Cases

    /// 月額プレミアムプラン（$3/月、7日間無料トライアル付き）
    case monthlyPremium = "monthly_premium"

    /// 年額プレミアムプラン（$20/年、月額プランより50%割引）
    case yearlyPremium = "yearly_premium"

    /// Lifetimeプラン（$30、一度きりの買い切り）
    case lifetimePremium = "lifetime_premium"

    // MARK: - Properties

    /// 表示用名称
    public var displayName: String {
        switch self {
        case .monthlyPremium:
            return "月額プラン"
        case .yearlyPremium:
            return "年額プラン"
        case .lifetimePremium:
            return "Lifetimeプラン"
        }
    }

    /// 製品説明
    public var description: String {
        switch self {
        case .monthlyPremium:
            return "毎月自動更新されるプレミアムプラン。7日間の無料トライアル付き。"
        case .yearlyPremium:
            return "年1回自動更新されるプレミアムプラン。月額プランより約50%お得です。"
        case .lifetimePremium:
            return "一度きりの支払いで永久にすべてのプレミアム機能へアクセスできます。サブスクリプションなし。"
        }
    }

    /// サブスクリプション期間（買い切り製品の場合はnil）
    public var subscriptionPeriod: SubscriptionPeriod? {
        switch self {
        case .monthlyPremium:
            return .monthly
        case .yearlyPremium:
            return .yearly
        case .lifetimePremium:
            return nil // 買い切り製品はサブスクリプションではない
        }
    }

    /// 無料トライアルの有無
    public var hasFreeTrial: Bool {
        switch self {
        case .monthlyPremium:
            return true
        case .yearlyPremium:
            return false
        case .lifetimePremium:
            return false
        }
    }

    /// 無料トライアル期間（日数）
    public var freeTrialDays: Int? {
        switch self {
        case .monthlyPremium:
            return 7
        case .yearlyPremium:
            return nil
        case .lifetimePremium:
            return nil
        }
    }

    /// 買い切り製品かどうか
    public var isLifetime: Bool {
        return self == .lifetimePremium
    }
}

// MARK: - Helper Methods

extension ProductIdentifier {

    /// すべての製品IDを文字列配列として取得
    public static var allIdentifiers: [String] {
        return Self.allCases.map { $0.rawValue }
    }

    /// 月額製品かどうか
    public var isMonthly: Bool {
        return subscriptionPeriod == .monthly
    }

    /// 年額製品かどうか
    public var isYearly: Bool {
        return subscriptionPeriod == .yearly
    }

    /// サブスクリプション製品かどうか
    public var isSubscription: Bool {
        return subscriptionPeriod != nil
    }

    /// 製品情報テンプレート作成
    /// - Parameters:
    ///   - price: 価格
    ///   - priceFormatted: フォーマット済み価格
    /// - Returns: ProductInfo
    public func createProductInfo(
        price: Decimal,
        priceFormatted: String
    ) -> ProductInfo {

        // 初回割引オファー作成（無料トライアルがある場合）
        let introOffer: IntroductoryOffer? = {
            if let trialDays = freeTrialDays {
                return IntroductoryOffer(
                    price: 0,
                    priceFormatted: "¥0",
                    period: trialDays,
                    type: .freeTrial
                )
            }
            return nil
        }()

        return ProductInfo(
            id: rawValue,
            displayName: displayName,
            description: description,
            price: price,
            priceFormatted: priceFormatted,
            subscriptionPeriod: subscriptionPeriod,
            introductoryOffer: introOffer
        )
    }
}

// MARK: - Description Property

extension ProductIdentifier {
    /// 文字列表現
    public var stringDescription: String {
        return "\(displayName) (\(rawValue))"
    }
}
