//
//  PremiumManager.swift
//  LightRoll_CleanerFeature
//
//  プレミアム機能管理サービス
//  - 課金状態の管理
//  - 削除制限の判定
//  - トランザクション監視
//

import Foundation
import StoreKit

/// プレミアム機能の管理を担当するサービス
///
/// - 課金状態の管理
/// - 削除制限の判定
/// - トランザクション監視
@MainActor
@Observable
public final class PremiumManager: PremiumManagerProtocol {
    // MARK: - Published Properties

    /// プレミアム状態（サブスク有効かどうか）
    public private(set) var isPremium: Bool = false

    /// 現在のサブスクリプション状態
    public private(set) var subscriptionStatus: PremiumStatus = .free

    /// 生涯の総削除カウント（Free版制限用）
    public private(set) var totalDeleteCount: Int = 0

    // MARK: - Private Properties

    private let purchaseRepository: any PurchaseRepositoryProtocol
    nonisolated(unsafe) private var transactionTask: Task<Void, Never>?
    private let userDefaults: UserDefaults

    // MARK: - Constants

    /// Free版の生涯削除上限（"Try & Lock"モデル）
    private static let freeTotalLimit = 50

    private enum Keys {
        static let totalDeleteCount = "free_total_delete_count"
    }

    // MARK: - Initialization

    /// PremiumManagerを初期化
    /// - Parameters:
    ///   - purchaseRepository: 課金リポジトリ
    ///   - userDefaults: 永続化ストレージ（デフォルトは.standard）
    public init(
        purchaseRepository: any PurchaseRepositoryProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.purchaseRepository = purchaseRepository
        self.userDefaults = userDefaults

        // UserDefaultsから削除カウントを読み込み
        self.totalDeleteCount = userDefaults.integer(forKey: Keys.totalDeleteCount)
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Public Methods

    /// プレミアム状態を確認して更新
    ///
    /// - Throws: 課金状態の確認に失敗した場合
    public func checkPremiumStatus() async throws {
        do {
            let status = try await purchaseRepository.checkSubscriptionStatus()

            // 状態を更新
            subscriptionStatus = status
            isPremium = status.isActive

        } catch {
            // エラー時はFree状態にフォールバック
            subscriptionStatus = .free
            isPremium = false
            throw error
        }
    }

    /// 指定枚数の写真を削除可能か判定
    ///
    /// - Parameter count: 削除予定枚数
    /// - Returns: 削除可能ならtrue
    public func canDelete(count: Int) -> Bool {
        // Premium版は無制限
        if isPremium {
            return true
        }

        // Free版は生涯50枚まで（"Try & Lock"モデル）
        return totalDeleteCount + count <= Self.freeTotalLimit
    }

    /// 削除カウントを増加
    ///
    /// - Parameter count: 削除した枚数
    /// - Note: 呼び出し前にcanDelete()で確認済みであること
    public func incrementDeleteCount(_ count: Int) {
        totalDeleteCount += count

        // UserDefaultsに永続化
        userDefaults.set(totalDeleteCount, forKey: Keys.totalDeleteCount)
    }

    /// 日次カウントをリセット（互換性のため残すが、何もしない）
    ///
    /// - Note: "Try & Lock"モデルでは生涯カウントを使用するため、日次リセットは不要
    @available(*, deprecated, message: "生涯削除制限モデルでは使用しません")
    public func resetDailyCount() {
        // 何もしない（互換性のため残す）
    }

    /// 削除カウントをリセット（テスト用）
    ///
    /// - Warning: 本番環境では使用しないこと。開発・テスト目的のみ。
    public func resetDeleteCount() {
        totalDeleteCount = 0
        userDefaults.removeObject(forKey: Keys.totalDeleteCount)
    }

    /// トランザクション監視を開始
    ///
    /// - Note: アプリ起動時に1回だけ呼び出すこと
    public func startTransactionMonitoring() {
        // 既存のタスクをキャンセル
        transactionTask?.cancel()

        // リポジトリのトランザクション監視を開始
        purchaseRepository.startTransactionListener()

        // 新しい監視タスクを開始（detachedでバックグラウンド実行）
        // Note: テスト環境ではTransaction.updatesがクラッシュする可能性があるため、
        //       実際のトランザクション監視は本番環境でのみ動作する
        transactionTask = Task.detached { [weak self] in
            guard let self else { return }

            // トランザクション更新を監視
            for await _ in Transaction.updates {
                // キャンセルチェック
                if Task.isCancelled {
                    break
                }

                // 状態を再確認（MainActorに切り替え）
                await MainActor.run {
                    Task {
                        try? await self.checkPremiumStatus()
                    }
                }
            }
        }
    }

    /// トランザクション監視を停止
    public func stopTransactionMonitoring() {
        transactionTask?.cancel()
        transactionTask = nil
        purchaseRepository.stopTransactionListener()
    }

    // MARK: - PremiumManagerProtocol Conformance

    /// 現在のプレミアムステータスを取得
    public var status: PremiumStatus {
        get async {
            return subscriptionStatus
        }
    }

    /// 指定機能が利用可能かどうかを判定
    ///
    /// - Parameter feature: 確認する機能
    /// - Returns: 利用可能かどうか
    public func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
        switch feature {
        case .unlimitedDeletion:
            // 無制限削除はプレミアム会員のみ
            return isPremium

        case .adFree:
            // 広告非表示はプレミアム会員のみ
            return isPremium

        case .advancedAnalysis:
            // 高度な分析はプレミアム会員のみ
            return isPremium

        case .cloudBackup:
            // クラウドバックアップは将来機能（現在は未実装）
            return false
        }
    }

    /// 残り削除可能数を取得
    ///
    /// - Returns: 残り削除可能数（プレミアムの場合はInt.max）
    public func getRemainingDeletions() async -> Int {
        if isPremium {
            return Int.max
        }
        return max(0, Self.freeTotalLimit - totalDeleteCount)
    }

    /// 削除数を記録
    ///
    /// - Parameter count: 削除した数
    public func recordDeletion(count: Int) async {
        incrementDeleteCount(count)
    }

    /// ステータスを更新
    public func refreshStatus() async {
        try? await checkPremiumStatus()
    }
}
