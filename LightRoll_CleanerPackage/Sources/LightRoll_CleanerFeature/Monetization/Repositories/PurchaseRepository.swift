//
//  PurchaseRepository.swift
//  LightRoll_CleanerFeature
//
//  StoreKit 2を使った購入リポジトリ実装
//  - 製品情報読み込み
//  - 購入処理
//  - 購入復元
//  - トランザクション検証
//  - サブスクリプション状態確認
//

import Foundation
import StoreKit

// MARK: - PurchaseRepository

/// StoreKit 2を使った購入リポジトリ実装
@MainActor
@Observable
public final class PurchaseRepository: PurchaseRepositoryProtocol {

    // MARK: - Properties

    /// 利用可能な製品キャッシュ
    private var availableProducts: [Product] = []

    /// トランザクション監視タスク
    nonisolated(unsafe) private var transactionListenerTask: Task<Void, Never>?

    /// トランザクション更新ハンドラ（テスト用）
    private var onTransactionUpdate: ((Transaction) -> Void)?

    // MARK: - Initialization

    public init() {
        // 初期化時は何もしない（startTransactionListenerで監視開始）
    }

    nonisolated deinit {
        // トランザクション監視タスクをキャンセル
        transactionListenerTask?.cancel()
    }

    // MARK: - PurchaseRepositoryProtocol

    /// 製品情報を読み込む
    public func fetchProducts() async throws -> [ProductInfo] {
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
            return products.compactMap { convertToProductInfo($0) }

        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.unknownError
        }
    }

    /// 製品を購入する
    public func purchase(_ productId: String) async throws -> PurchaseResult {
        // 製品を検索
        guard let product = availableProducts.first(where: { $0.id == productId }) else {
            // キャッシュになければ再読み込み
            _ = try await fetchProducts()

            guard let product = availableProducts.first(where: { $0.id == productId }) else {
                throw PurchaseError.productNotFound
            }

            return try await executePurchase(product)
        }

        return try await executePurchase(product)
    }

    /// 購入を復元する
    public func restorePurchases() async throws -> RestoreResult {
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

            return RestoreResult(transactions: restoredTransactions)

        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.restorationFailed(error.localizedDescription)
        }
    }

    /// サブスクリプション状態を確認する
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
                        return createPremiumStatus(
                            from: transaction,
                            identifier: identifier,
                            expirationDate: expirationDate
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

    /// トランザクション監視を開始する
    public func startTransactionListener() {
        // 既に監視中なら何もしない
        guard transactionListenerTask == nil else { return }

        transactionListenerTask = Task.detached { [weak self] in
            // 未完了のトランザクションを監視
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    /// トランザクション監視を停止する
    public func stopTransactionListener() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
    }

    // MARK: - Private Methods

    /// 購入を実行する
    private func executePurchase(_ product: Product) async throws -> PurchaseResult {
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

                return .success(transaction)

            case .userCancelled:
                return .cancelled

            case .pending:
                return .pending

            @unknown default:
                return .failed(.unknownError)
            }

        } catch let error as PurchaseError {
            return .failed(error)
        } catch {
            return .failed(.purchaseFailed(error.localizedDescription))
        }
    }

    /// トランザクション検証
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// トランザクション更新を処理
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)

            // トランザクション完了
            await transaction.finish()

            // テスト用ハンドラ呼び出し
            onTransactionUpdate?(transaction)

        } catch {
            // エラーは無視（ロギングのみ）
            print("Transaction listener error: \(error)")
        }
    }

    /// ProductをProductInfoに変換
    private func convertToProductInfo(_ product: Product) -> ProductInfo? {
        // ProductIdentifier取得
        guard let identifier = ProductIdentifier(rawValue: product.id) else {
            return nil
        }

        // サブスクリプション情報取得
        let subscriptionInfo = product.subscription

        // 初回オファー取得
        let introOffer: IntroductoryOffer? = extractIntroductoryOffer(from: subscriptionInfo)

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

    /// 初回オファーを抽出
    private func extractIntroductoryOffer(
        from subscriptionInfo: Product.SubscriptionInfo?
    ) -> IntroductoryOffer? {
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
    }

    /// PremiumStatusを作成
    private func createPremiumStatus(
        from transaction: Transaction,
        identifier: ProductIdentifier,
        expirationDate: Date
    ) -> PremiumStatus {
        // トライアル判定
        let isTrialActive = transaction.offerType == .introductory

        // サブスクリプションタイプ
        let subscriptionType: SubscriptionType = {
            switch identifier.subscriptionPeriod {
            case .monthly:
                return .monthly
            case .yearly:
                return .yearly
            }
        }()

        return PremiumStatus(
            isPremium: true,
            subscriptionType: subscriptionType,
            expirationDate: expirationDate,
            isTrialActive: isTrialActive,
            trialEndDate: isTrialActive ? expirationDate : nil,
            purchaseDate: transaction.purchaseDate,
            autoRenewEnabled: transaction.isUpgraded == false
        )
    }

    // MARK: - Test Helpers

    /// トランザクション更新ハンドラを設定（テスト用）
    internal func setTransactionUpdateHandler(_ handler: @escaping (Transaction) -> Void) {
        onTransactionUpdate = handler
    }
}
