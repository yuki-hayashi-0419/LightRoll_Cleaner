import SwiftUI
import LightRoll_CleanerFeature
import GoogleMobileAds
import UIKit

// MARK: - App Delegate

/// アプリデリゲート - Google Mobile Ads SDK初期化
///
/// GMA SDKは`application(_:didFinishLaunchingWithOptions:)`で
/// 初期化することがGoogleの推奨パターンです。
/// `GADApplicationIdentifier`はConfig/Shared.xcconfigで設定済み。
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Google Mobile Ads SDK初期化
        GADMobileAds.sharedInstance().start { status in
            #if DEBUG
            print("✅ Google Mobile Ads SDK初期化完了")
            for (adapterName, adapterStatus) in status.adapterStatusesByClassName {
                let stateDescription = switch adapterStatus.state {
                case .notReady: "not ready"
                case .ready: "ready"
                @unknown default: "unknown"
                }
                print("  - \(adapterName): \(stateDescription)")
            }
            #endif
        }
        return true
    }
}

// MARK: - Main App

@main
struct LightRoll_CleanerApp: App {
    /// AppDelegateを接続してGMA SDK初期化を確実に実行
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
