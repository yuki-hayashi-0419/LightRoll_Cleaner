//
//  BannerAdView.swift
//  LightRoll_CleanerFeature
//
//  バナー広告表示View
//  - SwiftUIでGoogle Mobile Adsバナー広告を表示
//  - AdManagerと統合してロード状態を管理
//  - Premium対応（Premium時は非表示）
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// バナー広告を表示するSwiftUI View
///
/// AdManagerと連携してバナー広告の表示・非表示を制御します。
///
/// ## 機能
/// - 広告のロード状態に応じた表示（Loading/Loaded/Failed）
/// - Premium会員時の広告非表示
/// - エラー時の適切なフォールバック
///
/// ## 使用例
/// ```swift
/// @Environment(AdManager.self) private var adManager
/// @Environment(PremiumManager.self) private var premiumManager
///
/// var body: some View {
///     VStack {
///         // コンテンツ
///         Spacer()
///         BannerAdView()
///     }
/// }
/// ```
@MainActor
public struct BannerAdView: View {

    // MARK: - Environment

    /// 広告管理サービス
    @Environment(AdManager.self) private var adManager

    /// Premium管理サービス
    @Environment(PremiumManager.self) private var premiumManager

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Premium会員は広告非表示
            if premiumManager.isPremium {
                EmptyView()
            } else {
                // 広告表示領域
                bannerContent
                    .task {
                        // ビューが表示されたら広告をロード
                        await loadBannerIfNeeded()
                    }
            }
        }
    }

    // MARK: - Private Views

    /// バナー広告のコンテンツ表示
    @ViewBuilder
    private var bannerContent: some View {
        switch adManager.bannerAdState {
        case .idle:
            // 初期状態: ローディングインジケーター表示
            loadingView

        case .loading:
            // ロード中: ローディングインジケーター表示
            loadingView

        case .loaded:
            // ロード完了: バナー広告を表示
            #if canImport(GoogleMobileAds) && canImport(UIKit)
            if let bannerView = adManager.showBannerAd() {
                BannerAdViewRepresentable(bannerView: bannerView)
                    .frame(height: 50) // GADAdSizeBannerの高さ
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("広告")
                    .accessibilityHint("バナー広告が表示されています")
            } else {
                // バナーViewが取得できない場合は空のView
                emptyView
            }
            #else
            // Google Mobile Ads SDKが利用できない場合は空のView
            emptyView
            #endif

        case .failed(let error):
            // エラー時: エラー内容に応じて処理
            if case .premiumUserNoAds = error {
                // Premiumユーザーの場合は何も表示しない
                EmptyView()
            } else {
                // その他のエラーの場合は空のViewを表示
                emptyView
            }
        }
    }

    /// ローディング表示View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        #if canImport(UIKit)
        .background(Color(uiColor: .systemGray6))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .accessibilityLabel("広告読み込み中")
    }

    /// 空のView（エラー時や広告未表示時）
    private var emptyView: some View {
        Color.clear
            .frame(height: 0)
            .accessibilityHidden(true)
    }

    // MARK: - Private Methods

    /// 必要に応じて広告をロード
    private func loadBannerIfNeeded() async {
        // Premium会員は広告をロードしない
        guard !premiumManager.isPremium else {
            return
        }

        // 既にロード済みまたはロード中の場合はスキップ
        if adManager.bannerAdState.isLoaded || adManager.bannerAdState.isLoading {
            return
        }

        // 広告をロード
        do {
            try await adManager.loadBannerAd()
        } catch {
            // エラーはAdManagerが状態を管理するので、ここでは何もしない
            #if DEBUG
            print("⚠️ バナー広告のロードに失敗: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Initialization

    /// BannerAdViewを初期化
    public init() {}
}

// MARK: - BannerAdViewRepresentable

#if canImport(GoogleMobileAds) && canImport(UIKit)
/// GADBannerViewをSwiftUIで使用するためのラッパー
///
/// UIViewRepresentableを実装してGADBannerViewをSwiftUIで表示します。
@MainActor
struct BannerAdViewRepresentable: UIViewRepresentable {

    // MARK: - Properties

    /// 表示するバナー広告View
    let bannerView: GADBannerView

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> GADBannerView {
        // バナーViewを返す
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 更新処理は不要（バナーViewは既にロード済み）
    }

    /// UIViewのサイズを計算
    static func dismantleUIView(_ uiView: GADBannerView, coordinator: ()) {
        // クリーンアップ処理（必要に応じて）
    }
}
#endif

// MARK: - Preview

#Preview("バナー広告 - Loading") {
    // プレビュー用のMockAdManager
    @Previewable @State var mockAdManager = {
        let manager = AdManager(
            premiumManager: MockPremiumManager(isPremiumValue: false)
        )
        // ロード中状態をシミュレート
        Task { @MainActor in
            // bannerAdStateを.loadingに設定したいが、
            // private(set)のため直接設定できない
            // 実際の使用では自動的にロードされる
        }
        return manager
    }()

    @Previewable @State var mockPremiumManager = MockPremiumManager(isPremiumValue: false)

    return BannerAdView()
        .environment(mockAdManager)
        .environment(mockPremiumManager)
        .frame(height: 200)
}

#Preview("バナー広告 - Premium（非表示）") {
    @Previewable @State var mockAdManager = AdManager(
        premiumManager: MockPremiumManager(isPremiumValue: true)
    )

    @Previewable @State var mockPremiumManager = MockPremiumManager(isPremiumValue: true)

    return VStack {
        Text("Premium会員")
            .font(.headline)
        BannerAdView()
        Text("広告が表示されません")
            .foregroundColor(.secondary)
    }
    .environment(mockAdManager)
    .environment(mockPremiumManager)
}

#Preview("バナー広告 - Failed") {
    // エラー状態のプレビュー
    @Previewable @State var mockAdManager = {
        let manager = AdManager(
            premiumManager: MockPremiumManager(isPremiumValue: false)
        )
        // エラー状態をシミュレート
        // 実際にはloadBannerAdが失敗した際にfailed状態になる
        return manager
    }()

    @Previewable @State var mockPremiumManager = MockPremiumManager(isPremiumValue: false)

    return VStack {
        Text("エラー状態（広告非表示）")
            .font(.headline)
        BannerAdView()
        Text("広告のロードに失敗しました")
            .foregroundColor(.red)
    }
    .environment(mockAdManager)
    .environment(mockPremiumManager)
}

// MARK: - MockPremiumManager for Preview

/// プレビュー用のMockPremiumManager
@MainActor
@Observable
private final class MockPremiumManager: PremiumManagerProtocol {
    var isPremium: Bool
    var subscriptionStatus: PremiumStatus
    var dailyDeleteCount: Int = 0

    init(isPremiumValue: Bool) {
        self.isPremium = isPremiumValue
        self.subscriptionStatus = isPremiumValue ? .monthly(startDate: Date(), autoRenew: true) : .free
    }

    func checkPremiumStatus() async throws {
        // プレビュー用の空実装
    }

    func canDelete(count: Int) -> Bool {
        return isPremium || dailyDeleteCount + count <= 50
    }

    func incrementDeleteCount(_ count: Int) {
        dailyDeleteCount += count
    }

    func resetDailyCount() {
        dailyDeleteCount = 0
    }

    func startTransactionMonitoring() {
        // プレビュー用の空実装
    }

    func stopTransactionMonitoring() {
        // プレビュー用の空実装
    }

    var status: PremiumStatus {
        get async {
            return subscriptionStatus
        }
    }

    func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
        switch feature {
        case .unlimitedDeletion, .adFree, .advancedAnalysis:
            return isPremium
        case .cloudBackup:
            return false
        }
    }

    func getRemainingDeletions() async -> Int {
        return isPremium ? Int.max : max(0, 50 - dailyDeleteCount)
    }

    func recordDeletion(count: Int) async {
        incrementDeleteCount(count)
    }

    func refreshStatus() async {
        // プレビュー用の空実装
    }
}
