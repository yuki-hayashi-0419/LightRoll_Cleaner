//
//  AdInterstitialManager.swift
//  LightRoll_CleanerFeature
//
//  インタースティシャル広告（全画面広告）の管理サービス
//  削除完了後に表示し、Freeユーザーの収益化を図る
//
//  "Try & Lock"マネタイズモデルの実装
//

import Foundation
import GoogleMobileAds
import UIKit

/// インタースティシャル広告の管理を担当するサービス
///
/// ## 表示ルール
/// - **Freeユーザーのみ**: Proユーザーには表示しない
/// - **セッション制限**: 1セッション（アプリ起動）につき1回のみ
/// - **時間制限**: 前回表示から30分以上経過している場合のみ
/// - **タイミング**: 写真削除完了後に表示
///
/// ## 使用例
/// ```swift
/// @MainActor
/// class DeleteViewModel {
///     let adManager = AdInterstitialManager()
///
///     func deletePhotos() async {
///         // 削除処理...
///
///         // 削除後に広告を表示
///         if let viewController = UIApplication.shared.windows.first?.rootViewController {
///             adManager.showIfReady(from: viewController, isPremium: false)
///         }
///     }
/// }
/// ```
@MainActor
@Observable
public final class AdInterstitialManager: NSObject, GADFullScreenContentDelegate {

    // MARK: - Published Properties

    /// 広告の読み込み状態
    public private(set) var isLoading: Bool = false

    /// 広告の準備完了状態
    public private(set) var isReady: Bool = false

    // MARK: - Private Properties

    /// 読み込まれた広告インスタンス
    private var interstitialAd: GADInterstitialAd?

    /// このセッションで既に表示したか
    private var hasShownThisSession: Bool = false

    /// 最後に広告を表示した時刻
    private var lastShowTime: Date?

    /// 広告ID
    private let adUnitID: String

    /// 広告表示の最小間隔（秒）
    private static let minimumInterval: TimeInterval = 1800  // 30分

    /// UserDefaults保存用のキー
    private enum Keys {
        static let lastShowTime = "ad_interstitial_last_show_time"
    }

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// AdInterstitialManagerを初期化
    /// - Parameters:
    ///   - adUnitID: 広告ユニットID（デフォルトはAdMobIdentifiersから取得）
    ///   - userDefaults: 永続化ストレージ（デフォルトは.standard）
    public init(
        adUnitID: String = AdMobIdentifiers.AdUnitID.interstitial.id,
        userDefaults: UserDefaults = .standard
    ) {
        self.adUnitID = adUnitID
        self.userDefaults = userDefaults

        // UserDefaultsから最終表示時刻を読み込み
        self.lastShowTime = userDefaults.object(forKey: Keys.lastShowTime) as? Date

        super.init()
    }

    // MARK: - Public Methods

    /// 広告を事前読み込み
    ///
    /// - Note: アプリ起動時やシーン移行時に呼び出して事前準備することを推奨
    public func preload() {
        guard !isLoading, interstitialAd == nil else {
            return
        }

        isLoading = true

        Task { @MainActor in
            do {
                let ad = try await GADInterstitialAd.load(
                    withAdUnitID: adUnitID,
                    request: GADRequest()
                )

                ad.fullScreenContentDelegate = self
                interstitialAd = ad
                isReady = true
                isLoading = false

                print("✅ インタースティシャル広告の読み込み成功")

            } catch {
                isLoading = false
                isReady = false
                print("❌ インタースティシャル広告の読み込み失敗: \(error.localizedDescription)")
            }
        }
    }

    /// 広告を表示（条件を満たす場合のみ）
    ///
    /// - Parameters:
    ///   - viewController: 広告を表示する親ビューコントローラー
    ///   - isPremium: プレミアムユーザーかどうか
    ///
    /// ## 表示条件
    /// 1. Freeユーザーであること（isPremium = false）
    /// 2. このセッションでまだ表示していない
    /// 3. 前回表示から30分以上経過している
    /// 4. 広告が読み込み済み
    public func showIfReady(from viewController: UIViewController, isPremium: Bool) {
        // Premium会員は広告をスキップ
        guard !isPremium else {
            print("ℹ️ プレミアムユーザーのため広告をスキップ")
            return
        }

        // セッション制限チェック
        guard !hasShownThisSession else {
            print("ℹ️ このセッションで既に表示済みのため広告をスキップ")
            return
        }

        // 時間制限チェック
        guard canShowAd() else {
            print("ℹ️ 前回表示から30分経過していないため広告をスキップ")
            return
        }

        // 広告準備チェック
        guard let ad = interstitialAd, isReady else {
            print("⚠️ 広告が準備できていません。preload()を呼び出してください。")
            return
        }

        // 広告を表示
        ad.present(fromRootViewController: viewController)

        // 表示フラグを更新
        hasShownThisSession = true
        lastShowTime = Date()
        userDefaults.set(lastShowTime, forKey: Keys.lastShowTime)

        // 次回用に広告を再読み込み
        interstitialAd = nil
        isReady = false
        preload()
    }

    /// リセット（主にテスト用）
    ///
    /// - Warning: 本番環境では使用しないこと。開発・テスト目的のみ。
    public func reset() {
        hasShownThisSession = false
        lastShowTime = nil
        userDefaults.removeObject(forKey: Keys.lastShowTime)
        interstitialAd = nil
        isReady = false
    }

    // MARK: - Private Methods

    /// 広告を表示可能か判定（時間制限チェック）
    ///
    /// - Returns: 表示可能な場合true
    private func canShowAd() -> Bool {
        guard let lastShow = lastShowTime else {
            return true  // 初回は常に表示可能
        }

        let timeSinceLastShow = Date().timeIntervalSince(lastShow)
        return timeSinceLastShow >= Self.minimumInterval
    }

    // MARK: - GADFullScreenContentDelegate

    /// 広告が正常に表示された
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("✅ インタースティシャル広告が表示されました")
    }

    /// 広告が閉じられた
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("ℹ️ インタースティシャル広告が閉じられました")
    }

    /// 広告の表示に失敗した
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ インタースティシャル広告の表示失敗: \(error.localizedDescription)")

        // 失敗時は再読み込み
        interstitialAd = nil
        isReady = false
        preload()
    }
}
