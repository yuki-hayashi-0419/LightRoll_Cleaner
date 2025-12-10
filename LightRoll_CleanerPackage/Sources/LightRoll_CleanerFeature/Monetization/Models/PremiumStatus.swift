//
//  PremiumStatus.swift
//  LightRoll_CleanerFeature
//
//  プレミアムステータスモデル
//  - サブスクリプション情報
//  - トライアル情報
//  - 有効期限管理
//

import Foundation

// MARK: - SubscriptionType

/// サブスクリプション種類
public enum SubscriptionType: String, Codable, Sendable, Equatable, CaseIterable {
    case free = "free"
    case monthly = "monthly"
    case yearly = "yearly"

    /// 表示用ラベル
    public var displayName: String {
        switch self {
        case .free:
            return "無料版"
        case .monthly:
            return "月額プラン"
        case .yearly:
            return "年額プラン"
        }
    }

    /// 期間（秒数）
    public var duration: TimeInterval? {
        switch self {
        case .free:
            return nil
        case .monthly:
            return 2592000 // 30日
        case .yearly:
            return 31536000 // 365日
        }
    }
}

// MARK: - PremiumStatus

/// プレミアムステータスモデル
public struct PremiumStatus: Codable, Sendable, Equatable {

    // MARK: - Properties

    /// プレミアム会員かどうか
    public var isPremium: Bool

    /// サブスクリプション種類
    public var subscriptionType: SubscriptionType

    /// 有効期限（プレミアムの場合）
    public var expirationDate: Date?

    /// トライアル期間中かどうか
    public var isTrialActive: Bool

    /// トライアル終了日
    public var trialEndDate: Date?

    /// 購入日
    public var purchaseDate: Date?

    /// 自動更新が有効か
    public var autoRenewEnabled: Bool

    // MARK: - Initialization

    public init(
        isPremium: Bool = false,
        subscriptionType: SubscriptionType = .free,
        expirationDate: Date? = nil,
        isTrialActive: Bool = false,
        trialEndDate: Date? = nil,
        purchaseDate: Date? = nil,
        autoRenewEnabled: Bool = false
    ) {
        self.isPremium = isPremium
        self.subscriptionType = subscriptionType
        self.expirationDate = expirationDate
        self.isTrialActive = isTrialActive
        self.trialEndDate = trialEndDate
        self.purchaseDate = purchaseDate
        self.autoRenewEnabled = autoRenewEnabled
    }
}

// MARK: - Helper Methods

extension PremiumStatus {

    /// 無料版かどうか
    public var isFree: Bool {
        return !isPremium && subscriptionType == .free
    }

    /// 有効なプレミアムステータスかどうか（期限切れチェック含む）
    public var isActive: Bool {
        guard isPremium else { return false }

        if isTrialActive {
            return isTrialValid
        }

        return isSubscriptionValid
    }

    /// トライアルが有効かどうか
    public var isTrialValid: Bool {
        guard isTrialActive, let endDate = trialEndDate else {
            return false
        }
        return Date() < endDate
    }

    /// サブスクリプションが有効かどうか
    public var isSubscriptionValid: Bool {
        guard isPremium, let expDate = expirationDate else {
            return false
        }
        return Date() < expDate
    }

    /// 残り日数（トライアルまたはサブスクリプション）
    public var daysRemaining: Int? {
        let targetDate: Date?

        if isTrialActive {
            targetDate = trialEndDate
        } else {
            targetDate = expirationDate
        }

        guard let date = targetDate else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0)
    }

    /// ステータス表示用テキスト
    public var statusText: String {
        if isFree {
            return "無料版"
        }

        if isTrialActive && isTrialValid {
            if let days = daysRemaining {
                return "トライアル中（残り\(days)日）"
            }
            return "トライアル中"
        }

        if isActive {
            if let days = daysRemaining {
                if autoRenewEnabled {
                    return "\(subscriptionType.displayName)（自動更新）"
                } else {
                    return "\(subscriptionType.displayName)（残り\(days)日）"
                }
            }
            return subscriptionType.displayName
        }

        return "期限切れ"
    }
}

// MARK: - Factory Methods

extension PremiumStatus {

    /// 無料版ステータス
    public static var free: PremiumStatus {
        return PremiumStatus(
            isPremium: false,
            subscriptionType: .free,
            expirationDate: nil,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: nil,
            autoRenewEnabled: false
        )
    }

    /// トライアルステータス
    /// - Parameter trialDays: トライアル期間（日数）
    /// - Returns: トライアルステータス
    public static func trial(days trialDays: Int = 7) -> PremiumStatus {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: trialDays, to: now)

        return PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: endDate,
            isTrialActive: true,
            trialEndDate: endDate,
            purchaseDate: now,
            autoRenewEnabled: true
        )
    }

    /// 月額プランステータス
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - autoRenew: 自動更新フラグ
    /// - Returns: 月額プランステータス
    public static func monthly(startDate: Date = Date(), autoRenew: Bool = true) -> PremiumStatus {
        let expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)

        return PremiumStatus(
            isPremium: true,
            subscriptionType: .monthly,
            expirationDate: expirationDate,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: startDate,
            autoRenewEnabled: autoRenew
        )
    }

    /// 年額プランステータス
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - autoRenew: 自動更新フラグ
    /// - Returns: 年額プランステータス
    public static func yearly(startDate: Date = Date(), autoRenew: Bool = true) -> PremiumStatus {
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)

        return PremiumStatus(
            isPremium: true,
            subscriptionType: .yearly,
            expirationDate: expirationDate,
            isTrialActive: false,
            trialEndDate: nil,
            purchaseDate: startDate,
            autoRenewEnabled: autoRenew
        )
    }

    /// プレミアムステータス（一般的な有効期限付き）
    /// - Parameters:
    ///   - subscriptionType: サブスクリプション種類（デフォルト: .monthly）
    ///   - startDate: 購入開始日（デフォルト: 現在日時）
    ///   - autoRenew: 自動更新フラグ（デフォルト: true）
    /// - Returns: プレミアムステータス
    public static func premium(
        subscriptionType: SubscriptionType = .monthly,
        startDate: Date = Date(),
        autoRenew: Bool = true
    ) -> PremiumStatus {
        switch subscriptionType {
        case .free:
            return .free
        case .monthly:
            return .monthly(startDate: startDate, autoRenew: autoRenew)
        case .yearly:
            return .yearly(startDate: startDate, autoRenew: autoRenew)
        }
    }
}
