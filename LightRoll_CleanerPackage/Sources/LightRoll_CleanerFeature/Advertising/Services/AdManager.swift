//
//  AdManager.swift
//  LightRoll_CleanerFeature
//
//  広告管理サービス
//  - バナー広告、インタースティシャル広告、リワード広告の管理
//  - Premium状態による広告表示制御
//  - 広告ロード・表示のライフサイクル管理
//

import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(UIKit)
import UIKit
#endif

/// 広告管理サービス
///
/// 各種広告のロード・表示を統括管理します。
///
/// ## 責務
/// - バナー広告、インタースティシャル広告、リワード広告のロード管理
/// - Premium状態による広告表示制御
/// - 広告表示頻度の制御
/// - エラーハンドリングとリトライロジック
///
/// ## 使用例
/// ```swift
/// let adManager = AdManager(premiumManager: premiumManager)
///
/// // バナー広告をロード
/// try await adManager.loadBannerAd()
///
/// // バナー広告を表示
/// if let bannerView = adManager.showBannerAd() {
///     // UIに追加
/// }
///
/// // インタースティシャル広告を表示
/// try await adManager.showInterstitialAd()
///
/// // リワード広告を表示
/// if let reward = try await adManager.showRewardedAd() {
///     print("獲得報酬: \(reward.amount) \(reward.type)")
/// }
/// ```
@MainActor
@Observable
public final class AdManager {

    // MARK: - Published Properties

    /// バナー広告のロード状態
    public private(set) var bannerAdState: AdLoadState = .idle

    /// インタースティシャル広告のロード状態
    public private(set) var interstitialAdState: AdLoadState = .idle

    /// リワード広告のロード状態
    public private(set) var rewardedAdState: AdLoadState = .idle

    // MARK: - Private Properties

    /// Premium管理サービス
    private let premiumManager: PremiumManagerProtocol

    /// ロード済みバナー広告
    private var bannerAdView: GADBannerView?

    /// ロード済みインタースティシャル広告
    private var interstitialAd: GADInterstitialAd?

    /// ロード済みリワード広告
    private var rewardedAd: GADRewardedAd?

    /// 最後にインタースティシャル広告を表示した時刻
    nonisolated(unsafe) private var lastInterstitialShowTime: Date?

    /// 最後にリワード広告を表示した時刻
    nonisolated(unsafe) private var lastRewardedShowTime: Date?

    // MARK: - Constants

    /// インタースティシャル広告の最小表示間隔（秒）
    private static let minInterstitialInterval: TimeInterval = 60

    /// リワード広告の最小表示間隔（秒）
    private static let minRewardedInterval: TimeInterval = 30

    /// 広告ロードのタイムアウト（秒）
    private static let loadTimeout: TimeInterval = 10

    // MARK: - Initialization

    /// AdManagerを初期化
    ///
    /// - Parameter premiumManager: Premium管理サービス
    public init(premiumManager: PremiumManagerProtocol) {
        self.premiumManager = premiumManager
    }

    // MARK: - Banner Ad

    /// バナー広告をロード
    ///
    /// - Throws: ロードに失敗した場合
    public func loadBannerAd() async throws {
        // Premium確認
        if await shouldShowAds() == false {
            bannerAdState = .failed(.premiumUserNoAds)
            throw AdManagerError.premiumUserNoAds
        }

        // 初期化確認
        guard AdInitializer.shared.initialized else {
            bannerAdState = .failed(.notInitialized)
            throw AdManagerError.notInitialized
        }

        // 既にロード済みの場合はスキップ
        if bannerAdState.isLoaded {
            return
        }

        bannerAdState = .loading

        do {
            // タイムアウト付きでロード
            try await withTimeout(seconds: Self.loadTimeout) {
                try await self.loadBannerAdInternal()
            }

            bannerAdState = .loaded
            #if DEBUG
            print("✅ バナー広告ロード成功")
            #endif

        } catch let error as AdManagerError {
            bannerAdState = .failed(error)
            #if DEBUG
            print("❌ バナー広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw error
        } catch {
            let adError = AdManagerError.loadFailed(error.localizedDescription)
            bannerAdState = .failed(adError)
            #if DEBUG
            print("❌ バナー広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw adError
        }
    }

    /// バナー広告を表示
    ///
    /// - Returns: バナー広告ビュー（ロード未完了の場合はnil）
    public func showBannerAd() -> GADBannerView? {
        guard bannerAdState.isLoaded else {
            #if DEBUG
            print("⚠️ バナー広告が準備できていません")
            #endif
            return nil
        }

        return bannerAdView
    }

    // MARK: - Interstitial Ad

    /// インタースティシャル広告をロード
    ///
    /// - Throws: ロードに失敗した場合
    public func loadInterstitialAd() async throws {
        // Premium確認
        if await shouldShowAds() == false {
            interstitialAdState = .failed(.premiumUserNoAds)
            throw AdManagerError.premiumUserNoAds
        }

        // 初期化確認
        guard AdInitializer.shared.initialized else {
            interstitialAdState = .failed(.notInitialized)
            throw AdManagerError.notInitialized
        }

        // 既にロード済みの場合はスキップ
        if interstitialAdState.isLoaded {
            return
        }

        interstitialAdState = .loading

        do {
            // タイムアウト付きでロード
            try await withTimeout(seconds: Self.loadTimeout) {
                try await self.loadInterstitialAdInternal()
            }

            interstitialAdState = .loaded
            #if DEBUG
            print("✅ インタースティシャル広告ロード成功")
            #endif

        } catch let error as AdManagerError {
            interstitialAdState = .failed(error)
            #if DEBUG
            print("❌ インタースティシャル広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw error
        } catch {
            let adError = AdManagerError.loadFailed(error.localizedDescription)
            interstitialAdState = .failed(adError)
            #if DEBUG
            print("❌ インタースティシャル広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw adError
        }
    }

    /// インタースティシャル広告を表示
    ///
    /// - Throws: 表示に失敗した場合
    public func showInterstitialAd() async throws {
        // 表示間隔チェック
        if let lastShow = lastInterstitialShowTime,
           Date().timeIntervalSince(lastShow) < Self.minInterstitialInterval {
            #if DEBUG
            print("⚠️ インタースティシャル広告の表示間隔が短すぎます")
            #endif
            throw AdManagerError.showFailed("表示間隔が短すぎます")
        }

        // ロード状態確認
        guard interstitialAdState.isLoaded, let ad = interstitialAd else {
            throw AdManagerError.adNotReady
        }

        do {
            // ルートビューコントローラーを取得
            guard let rootViewController = await getRootViewController() else {
                throw AdManagerError.showFailed("ルートビューコントローラーが取得できません")
            }

            // 広告を表示
            ad.present(fromRootViewController: rootViewController)

            // 表示時刻を記録
            lastInterstitialShowTime = Date()

            // 次回のためにプリロード
            Task {
                try? await loadInterstitialAd()
            }

            #if DEBUG
            print("✅ インタースティシャル広告表示成功")
            #endif

        } catch {
            let adError = AdManagerError.showFailed(error.localizedDescription)
            #if DEBUG
            print("❌ インタースティシャル広告表示失敗: \(error.localizedDescription)")
            #endif
            throw adError
        }
    }

    // MARK: - Rewarded Ad

    /// リワード広告をロード
    ///
    /// - Throws: ロードに失敗した場合
    public func loadRewardedAd() async throws {
        // Premium確認
        if await shouldShowAds() == false {
            rewardedAdState = .failed(.premiumUserNoAds)
            throw AdManagerError.premiumUserNoAds
        }

        // 初期化確認
        guard AdInitializer.shared.initialized else {
            rewardedAdState = .failed(.notInitialized)
            throw AdManagerError.notInitialized
        }

        // 既にロード済みの場合はスキップ
        if rewardedAdState.isLoaded {
            return
        }

        rewardedAdState = .loading

        do {
            // タイムアウト付きでロード
            try await withTimeout(seconds: Self.loadTimeout) {
                try await self.loadRewardedAdInternal()
            }

            rewardedAdState = .loaded
            #if DEBUG
            print("✅ リワード広告ロード成功")
            #endif

        } catch let error as AdManagerError {
            rewardedAdState = .failed(error)
            #if DEBUG
            print("❌ リワード広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw error
        } catch {
            let adError = AdManagerError.loadFailed(error.localizedDescription)
            rewardedAdState = .failed(adError)
            #if DEBUG
            print("❌ リワード広告ロード失敗: \(error.localizedDescription)")
            #endif
            throw adError
        }
    }

    /// リワード広告を表示
    ///
    /// - Returns: 獲得した報酬（視聴完了した場合）
    /// - Throws: 表示に失敗した場合
    public func showRewardedAd() async throws -> AdReward? {
        // 表示間隔チェック
        if let lastShow = lastRewardedShowTime,
           Date().timeIntervalSince(lastShow) < Self.minRewardedInterval {
            #if DEBUG
            print("⚠️ リワード広告の表示間隔が短すぎます")
            #endif
            throw AdManagerError.showFailed("表示間隔が短すぎます")
        }

        // ロード状態確認
        guard rewardedAdState.isLoaded, let ad = rewardedAd else {
            throw AdManagerError.adNotReady
        }

        do {
            // ルートビューコントローラーを取得
            guard let rootViewController = await getRootViewController() else {
                throw AdManagerError.showFailed("ルートビューコントローラーが取得できません")
            }

            // 広告を表示して報酬を取得
            let reward = await withCheckedContinuation { continuation in
                ad.present(fromRootViewController: rootViewController) {
                    let adReward = AdReward(
                        amount: Int($0.amount),
                        type: $0.type
                    )
                    continuation.resume(returning: adReward)
                }
            }

            // 表示時刻を記録
            lastRewardedShowTime = Date()

            // 次回のためにプリロード
            Task {
                try? await loadRewardedAd()
            }

            #if DEBUG
            print("✅ リワード広告表示成功: \(reward.amount) \(reward.type)")
            #endif

            return reward

        } catch {
            let adError = AdManagerError.showFailed(error.localizedDescription)
            #if DEBUG
            print("❌ リワード広告表示失敗: \(error.localizedDescription)")
            #endif
            throw adError
        }
    }

    // MARK: - Premium Check

    /// 広告を表示すべきかどうかを判定
    ///
    /// - Returns: 広告を表示する場合true
    private func shouldShowAds() async -> Bool {
        let feature = await premiumManager.isFeatureAvailable(.adFree)
        return !feature
    }

    // MARK: - Internal Loading Methods

    /// バナー広告をロード（内部実装）
    private func loadBannerAdInternal() async throws {
        return await withCheckedContinuation { continuation in
            let adUnitID = AdMobIdentifiers.AdUnitID.banner.id
            let bannerView = GADBannerView(adSize: GADAdSizeBanner)
            bannerView.adUnitID = adUnitID

            // デリゲート設定（ロード完了待機）
            let delegate = BannerAdDelegate { [weak self] result in
                switch result {
                case .success:
                    self?.bannerAdView = bannerView
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: AdManagerError.loadFailed(error.localizedDescription))
                }
            }

            // デリゲートを保持（リーク防止のためweakで保持）
            objc_setAssociatedObject(
                bannerView,
                &AssociatedKeys.delegateKey,
                delegate,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            bannerView.delegate = delegate

            // ルートビューコントローラーを設定
            Task { @MainActor in
                if let rootVC = await self.getRootViewController() {
                    bannerView.rootViewController = rootVC
                    let request = GADRequest()
                    bannerView.load(request)
                } else {
                    continuation.resume(throwing: AdManagerError.loadFailed("ルートビューコントローラーが取得できません"))
                }
            }
        }
    }

    /// インタースティシャル広告をロード（内部実装）
    private func loadInterstitialAdInternal() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let adUnitID = AdMobIdentifiers.AdUnitID.interstitial.id
            let request = GADRequest()

            GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
                if let error = error {
                    continuation.resume(throwing: AdManagerError.loadFailed(error.localizedDescription))
                    return
                }

                guard let ad = ad else {
                    continuation.resume(throwing: AdManagerError.loadFailed("広告の取得に失敗しました"))
                    return
                }

                self?.interstitialAd = ad
                continuation.resume()
            }
        }
    }

    /// リワード広告をロード（内部実装）
    private func loadRewardedAdInternal() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let adUnitID = AdMobIdentifiers.AdUnitID.rewarded.id
            let request = GADRequest()

            GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
                if let error = error {
                    continuation.resume(throwing: AdManagerError.loadFailed(error.localizedDescription))
                    return
                }

                guard let ad = ad else {
                    continuation.resume(throwing: AdManagerError.loadFailed("広告の取得に失敗しました"))
                    return
                }

                self?.rewardedAd = ad
                continuation.resume()
            }
        }
    }

    // MARK: - Utilities

    /// ルートビューコントローラーを取得
    private func getRootViewController() async -> UIViewController? {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
        #else
        return nil
        #endif
    }

    /// タイムアウト付きで処理を実行
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw AdManagerError.timeout
            }

            guard let result = try await group.next() else {
                throw AdManagerError.timeout
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - BannerAdDelegate

/// バナー広告のデリゲート
private final class BannerAdDelegate: NSObject, GADBannerViewDelegate, @unchecked Sendable {
    private let completion: @Sendable (Result<Void, Error>) -> Void

    init(completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        self.completion = completion
    }

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        completion(.success(()))
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        completion(.failure(error))
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var delegateKey: UInt8 = 0
}
