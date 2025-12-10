//
//  StoreKitManager.swift
//  LightRoll_CleanerFeature
//
//  StoreKit 2購入・復元マネージャー
//  - 製品情報読み込み
//  - 購入処理
//  - 購入復元
//  - サブスクリプション状態確認
//

import Foundation
import StoreKit

// MARK: - PurchaseError

/// StoreKit購入関連エラー
public enum PurchaseError: Error, LocalizedError, Sendable, Equatable {
    case productNotFound
    case purchaseFailed(String)
    case purchaseCancelled
    case verificationFailed
    case noActiveSubscription
    case restorationFailed(String)
    case networkError
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "製品が見つかりませんでした"
        case .purchaseFailed(let reason):
            return "購入に失敗しました: \(reason)"
        case .purchaseCancelled:
            return "購入がキャンセルされました"
        case .verificationFailed:
            return "購入の検証に失敗しました"
        case .noActiveSubscription:
            return "有効なサブスクリプションがありません"
        case .restorationFailed(let reason):
            return "復元に失敗しました: \(reason)"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknownError:
            return "不明なエラーが発生しました"
        }
    }
}

// MARK: - StoreKitManager

/// StoreKit 2購入・復元マネージャー
///
/// サブスクリプション製品の購入、復元、状態確認を管理する
@MainActor
public final class StoreKitManager: Sendable {

    // MARK: - Properties

    /// 利用可能な製品
    private var availableProducts: [Product] = []

    /// トランザクション監視タスク
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Singleton

    /// シングルトンインスタンス
    public static let shared = StoreKitManager()

    private init() {
        // トランザクション監視開始
        startTransactionListener()
    }

    // MARK: - Public Methods

    /// 製品情報を読み込む
    ///
    /// - Throws: PurchaseError
    /// - Returns: 読み込まれた製品情報の配列
    public func loadProducts() async throws -> [ProductInfo] {
        do {
            // StoreKitから製品情報取得
            let products = try await Product.products(
                for: ProductIdentifier.allIdentifiers
            )

            guard !products.isEmpty else {
                throw PurchaseError.productNotFound
            }

            // キャッシュに保存
            availableProducts = products

            // ProductInfo配列に変換
            return products.compactMap { product in
                // ProductIdentifier取得
                guard let identifier = ProductIdentifier(rawValue: product.id) else {
                    return nil
                }

                // サブスクリプション情報取得
                let subscriptionInfo = product.subscription

                // 初回オファー取得
                let introOffer: IntroductoryOffer? = {
                    guard let offer = subscriptionInfo?.introductoryOffer else {
                        return nil
                    }

                    let offerType: OfferType
                    switch offer.paymentMode {
                    case .freeTrial:
                        offerType = .freeTrial
                    case .payUpFront:
                        offerType = .payUpFront
                    case .payAsYouGo:
                        offerType = .introPrice
                    default:
                        offerType = .introPrice
                    }

                    return IntroductoryOffer(
                        price: offer.price,
                        priceFormatted: offer.displayPrice,
                        period: offer.period.value,
                        type: offerType
                    )
                }()

                return ProductInfo(
                    id: product.id,
                    displayName: product.displayName,
                    description: product.description,
                    price: product.price,
                    priceFormatted: product.displayPrice,
                    subscriptionPeriod: identifier.subscriptionPeriod,
                    introductoryOffer: introOffer
                )
            }

        } catch {
            if let skError = error as? PurchaseError {
                throw skError
            }
            throw PurchaseError.unknownError
        }
    }

    /// 製品を購入する
    ///
    /// - Parameter productId: 製品ID
    /// - Throws: PurchaseError
    /// - Returns: 購入成功した場合のトランザクション
    public func purchase(_ productId: String) async throws -> Transaction {
        // 製品を検索
        guard let product = availableProducts.first(where: { $0.id == productId }) else {
            throw PurchaseError.productNotFound
        }

        do {
            // 購入実行
            let result = try await product.purchase()

            // 結果処理
            switch result {
            case .success(let verification):
                // トランザクション検証
                let transaction = try checkVerified(verification)

                // トランザクション完了
                await transaction.finish()

                return transaction

            case .userCancelled:
                throw PurchaseError.purchaseCancelled

            case .pending:
                throw PurchaseError.purchaseFailed("購入が保留中です")

            @unknown default:
                throw PurchaseError.unknownError
            }

        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.purchaseFailed(error.localizedDescription)
        }
    }

    /// 購入を復元する
    ///
    /// - Throws: PurchaseError
    /// - Returns: 復元されたトランザクションの配列
    public func restorePurchases() async throws -> [Transaction] {
        var restoredTransactions: [Transaction] = []

        do {
            // 現在のエンタイトルメントを列挙
            for await result in Transaction.currentEntitlements {
                do {
                    // トランザクション検証
                    let transaction = try checkVerified(result)
                    restoredTransactions.append(transaction)
                } catch {
                    // 検証失敗は無視して続行
                    continue
                }
            }

            guard !restoredTransactions.isEmpty else {
                throw PurchaseError.noActiveSubscription
            }

            return restoredTransactions

        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.restorationFailed(error.localizedDescription)
        }
    }

    /// サブスクリプション状態を確認する
    ///
    /// - Throws: PurchaseError
    /// - Returns: PremiumStatus
    public func checkSubscriptionStatus() async throws -> PremiumStatus {
        // 現在のエンタイトルメントを確認
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // 製品ID確認
                guard let identifier = ProductIdentifier(rawValue: transaction.productID) else {
                    continue
                }

                // サブスクリプション情報取得
                if let expirationDate = transaction.expirationDate {
                    // 有効期限が未来なら有効
                    if expirationDate > Date() {
                        // トライアル判定
                        let isTrialActive = transaction.offerType == .introductory

                        return PremiumStatus(
                            isPremium: true,
                            subscriptionType: identifier.subscriptionPeriod == .monthly ? .monthly : .yearly,
                            expirationDate: expirationDate,
                            isTrialActive: isTrialActive,
                            trialEndDate: isTrialActive ? expirationDate : nil,
                            purchaseDate: transaction.purchaseDate,
                            autoRenewEnabled: transaction.isUpgraded == false
                        )
                    }
                }

            } catch {
                // 検証失敗は無視して続行
                continue
            }
        }

        // 有効なサブスクリプションがない場合は無料版
        return PremiumStatus.free
    }

    // MARK: - Private Methods

    /// トランザクション検証
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// トランザクション監視を開始
    private func startTransactionListener() {
        transactionListenerTask = Task.detached {
            // 未完了のトランザクションを監視
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // トランザクション完了
                    await transaction.finish()

                } catch {
                    // エラーは無視（ロギングのみ）
                    print("Transaction listener error: \(error)")
                }
            }
        }
    }

    /// トランザクション監視を停止
    public func stopTransactionListener() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
    }
}
