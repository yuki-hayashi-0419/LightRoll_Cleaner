//
//  AdInitializer.swift
//  LightRoll_CleanerFeature
//
//  Google Mobile Ads SDK初期化サービス
//  - GMA SDK初期化
//  - ATTrackingTransparency対応
//  - プライバシー設定管理
//

import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

/// Google Mobile Ads SDK初期化サービス
///
/// アプリ起動時に一度だけ呼び出すことで、GMA SDKを初期化します。
/// iOS 14以降では、ATTrackingTransparencyによるトラッキング許可も
/// 自動的にリクエストします。
///
/// ## 使用例
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         Task {
///             await AdInitializer.shared.initialize()
///         }
///     }
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
@MainActor
public final class AdInitializer: Sendable {

    // MARK: - Singleton

    /// シングルトンインスタンス
    public static let shared = AdInitializer()

    // MARK: - Private Properties

    /// 初期化完了フラグ
    nonisolated(unsafe) private var isInitialized = false

    /// 初期化エラー
    nonisolated(unsafe) private var initializationError: Error?

    // MARK: - Initialization

    private init() {
        // プライベートイニシャライザ
    }

    // MARK: - Public Methods

    /// Google Mobile Ads SDKを初期化
    ///
    /// アプリ起動時に一度だけ呼び出してください。
    /// 複数回呼び出しても、初回のみ実行されます。
    ///
    /// ## 処理フロー
    /// 1. ATTrackingTransparency許可リクエスト（iOS 14+）
    /// 2. GMA SDK初期化
    /// 3. テストIDチェック（デバッグ時）
    ///
    /// - Throws: 初期化に失敗した場合
    public func initialize() async throws {
        // 既に初期化済みの場合はスキップ
        if isInitialized {
            if let error = initializationError {
                throw error
            }
            return
        }

        do {
            // ステップ1: ATTrackingTransparency許可リクエスト
            #if !targetEnvironment(simulator)
            await requestTrackingAuthorization()
            #else
            print("ℹ️ シミュレーター環境のため、ATTrackingAuthorizationをスキップします")
            #endif

            // ステップ2: GMA SDK初期化
            try await initializeGoogleMobileAds()

            // ステップ3: テストIDチェック
            #if DEBUG
            validateTestIDs()
            #endif

            isInitialized = true
            print("✅ Google Mobile Ads SDK初期化完了")

        } catch {
            initializationError = error
            print("❌ Google Mobile Ads SDK初期化エラー: \(error.localizedDescription)")
            throw error
        }
    }

    /// 初期化ステータスを取得
    ///
    /// - Returns: 初期化済みの場合true
    public var initialized: Bool {
        return isInitialized
    }

    // MARK: - Private Methods

    /// ATTrackingTransparency許可をリクエスト
    ///
    /// iOS 14以降で、ユーザーにトラッキング許可を求めます。
    /// Info.plistに`NSUserTrackingUsageDescription`が必須です。
    private func requestTrackingAuthorization() async {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus

            // まだ許可/拒否が決まっていない場合のみリクエスト
            if status == .notDetermined {
                let result = await ATTrackingManager.requestTrackingAuthorization()
                logTrackingStatus(result)
            } else {
                logTrackingStatus(status)
            }
        }
        #endif
    }

    /// トラッキング許可状態をログ出力
    ///
    /// - Parameter status: ATTrackingManager.AuthorizationStatus
    private func logTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) {
        #if canImport(AppTrackingTransparency)
        switch status {
        case .authorized:
            print("✅ トラッキング許可: 承認されました")
        case .denied:
            print("⚠️ トラッキング許可: 拒否されました")
        case .restricted:
            print("⚠️ トラッキング許可: 制限されています")
        case .notDetermined:
            print("ℹ️ トラッキング許可: 未確定")
        @unknown default:
            print("⚠️ トラッキング許可: 不明な状態")
        }
        #endif
    }

    /// Google Mobile Ads SDKを初期化
    ///
    /// - Throws: 初期化に失敗した場合
    private func initializeGoogleMobileAds() async throws {
        return await withCheckedContinuation { continuation in
            GADMobileAds.sharedInstance().start { status in
                // 初期化完了ログ
                print("📱 GMA SDK初期化ステータス:")
                for (adapterName, adapterStatus) in status.adapterStatusesByClassName {
                    print("  - \(adapterName): \(adapterStatus.state.rawValue)")
                }

                continuation.resume()
            }
        }
    }

    /// テストIDの使用状況を検証（デバッグ時のみ）
    private func validateTestIDs() {
        if AdMobIdentifiers.isUsingTestIDs {
            print("⚠️ [DEBUG] テストIDが使用されています")
            print("   本番環境ではAdMobコンソールで取得した実際のIDに置き換えてください")
            print("   現在のApp ID: \(AdMobIdentifiers.appID)")
        } else {
            print("✅ [DEBUG] 本番用IDが設定されています")
        }
    }
}

// MARK: - Error Types

/// AdInitializerのエラー型
public enum AdInitializerError: LocalizedError, Sendable {
    /// 初期化タイムアウト
    case timeout

    /// 初期化失敗
    case initializationFailed(String)

    /// トラッキング許可が必要
    case trackingAuthorizationRequired

    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "広告SDK初期化がタイムアウトしました"

        case .initializationFailed(let message):
            return "広告SDK初期化に失敗しました: \(message)"

        case .trackingAuthorizationRequired:
            return "広告表示にはトラッキング許可が必要です"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .timeout:
            return "ネットワーク接続を確認して、アプリを再起動してください"

        case .initializationFailed:
            return "アプリを再起動してください。問題が続く場合は開発者にお問い合わせください"

        case .trackingAuthorizationRequired:
            return "設定アプリからトラッキングを許可してください"
        }
    }
}
