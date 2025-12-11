//
//  PurchaseRepositoryProtocol.swift
//  LightRoll_CleanerFeature
//
//  購入リポジトリプロトコル
//  - StoreKit 2へのアクセスを抽象化
//  - テスト可能な設計
//  - 依存性注入対応
//

import Foundation
import StoreKit

// MARK: - PurchaseResult

/// 購入処理結果
public enum PurchaseResult: Sendable, Equatable {
    /// 購入成功（トランザクション付き）
    case success(Transaction)

    /// 購入保留中（承認待ち）
    case pending

    /// ユーザーによるキャンセル
    case cancelled

    /// 購入失敗（エラー詳細付き）
    case failed(PurchaseError)

    // MARK: - Helper Properties

    /// 購入が成功したかどうか
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// トランザクション取得（成功時のみ）
    public var transaction: Transaction? {
        if case .success(let transaction) = self {
            return transaction
        }
        return nil
    }
}

// MARK: - RestoreResult

/// 復元処理結果
public struct RestoreResult: Sendable, Equatable {
    /// 復元されたトランザクション配列
    public let transactions: [Transaction]

    /// 復元成功かどうか
    public var isSuccess: Bool {
        return !transactions.isEmpty
    }

    /// 復元されたトランザクション数
    public var count: Int {
        return transactions.count
    }

    public init(transactions: [Transaction]) {
        self.transactions = transactions
    }
}

// MARK: - PurchaseRepositoryProtocol

/// 購入リポジトリプロトコル
///
/// StoreKit 2へのアクセスを抽象化し、テスト可能にする
@MainActor
public protocol PurchaseRepositoryProtocol: Sendable {

    /// 製品情報を読み込む
    ///
    /// - Returns: 利用可能な製品情報の配列
    /// - Throws: PurchaseError
    func fetchProducts() async throws -> [ProductInfo]

    /// 製品を購入する
    ///
    /// - Parameter productId: 製品ID
    /// - Returns: 購入結果
    /// - Throws: PurchaseError
    func purchase(_ productId: String) async throws -> PurchaseResult

    /// 購入を復元する
    ///
    /// - Returns: 復元結果
    /// - Throws: PurchaseError
    func restorePurchases() async throws -> RestoreResult

    /// サブスクリプション状態を確認する
    ///
    /// - Returns: 現在のプレミアムステータス
    /// - Throws: PurchaseError
    func checkSubscriptionStatus() async throws -> PremiumStatus

    /// トランザクション監視を開始する
    func startTransactionListener()

    /// トランザクション監視を停止する
    func stopTransactionListener()
}

// MARK: - Default Implementations

extension PurchaseRepositoryProtocol {

    /// 特定の製品IDの製品情報を取得
    ///
    /// - Parameter productId: 製品ID
    /// - Returns: 製品情報（見つからない場合はnil）
    public func getProduct(by productId: String) async throws -> ProductInfo? {
        let products = try await fetchProducts()
        return products.first { $0.id == productId }
    }

    /// すべての月額製品を取得
    ///
    /// - Returns: 月額製品の配列
    public func getMonthlyProducts() async throws -> [ProductInfo] {
        let products = try await fetchProducts()
        return products.filter { $0.isMonthlySubscription }
    }

    /// すべての年額製品を取得
    ///
    /// - Returns: 年額製品の配列
    public func getYearlyProducts() async throws -> [ProductInfo] {
        let products = try await fetchProducts()
        return products.filter { $0.isYearlySubscription }
    }

    /// 現在プレミアム会員かどうかを確認
    ///
    /// - Returns: プレミアム会員の場合true
    public func isPremiumActive() async throws -> Bool {
        let status = try await checkSubscriptionStatus()
        return status.isActive
    }
}
