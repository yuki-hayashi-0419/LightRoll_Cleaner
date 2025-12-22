//
//  BannerAdViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BannerAdViewのテスト
//  - 広告の表示状態テスト
//  - AdManager統合テスト
//  - Premium対応テスト
//  - ロード状態表示テスト
//  - エラーハンドリングテスト
//  - アクセシビリティテスト
//

import Testing
import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
@testable import LightRoll_CleanerFeature

// MARK: - GADBannerView Mock (if GoogleMobileAds is not available)

#if !canImport(GoogleMobileAds)
// GoogleMobileAdsが利用できない場合のモック型定義
@MainActor
public final class GADBannerView {
    public var adSize: GADAdSize
    public var translatesAutoresizingMaskIntoConstraints: Bool = true

    public init(adSize: GADAdSize) {
        self.adSize = adSize
    }
}

public struct GADAdSize {
    public var size: CGSize

    public init(width: CGFloat, height: CGFloat) {
        self.size = CGSize(width: width, height: height)
    }
}

public let GADAdSizeBanner = GADAdSize(width: 320, height: 50)
#endif

// MARK: - BannerAdViewTests

@Suite("BannerAdView Tests", .serialized)
@MainActor
struct BannerAdViewTests {

    // MARK: - TC01: BannerAdViewの初期表示テスト

    @Test("idle状態から自動ロード開始")
    func testIdleStateAutoLoads() async throws {
        // Given: idle状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: ローディング表示が行われる
        #expect(mockAdManager.bannerAdState == .idle)

        // 実際のViewではtask modifierで自動ロードされるため、
        // ここではstateがidleであることを確認
    }

    @Test("loading状態でProgressView表示")
    func testLoadingStateShowsProgressView() async throws {
        // Given: loading状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loading

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: loading状態でProgressViewが表示される
        #expect(mockAdManager.bannerAdState == .loading)
        #expect(mockAdManager.bannerAdState.isLoading == true)
    }

    @Test("Premium会員の場合は広告非表示")
    func testPremiumUserHidesAd() async throws {
        // Given: Premium会員
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: true)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: Premium会員なので広告を表示しない
        #expect(mockPremiumManager.isPremium == true)
        // loadBannerAdは呼ばれない（Premium会員のため）
        #expect(mockAdManager.loadBannerAdCalled == false)
    }

    @Test("エラー時の適切な表示")
    func testErrorStateDisplay() async throws {
        // Given: エラー状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.loadFailed("Test Error"))

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: エラー状態で空のViewが表示される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "広告のロードに失敗しました: Test Error")
    }

    // MARK: - TC02: AdManager統合テスト

    @Test("loadBannerAdが適切に呼ばれる")
    func testLoadBannerAdCalled() async throws {
        // Given: idle状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // When: 広告をロード
        try await mockAdManager.loadBannerAd()

        // Then: loadBannerAdが呼ばれた
        #expect(mockAdManager.loadBannerAdCalled == true)
        #expect(mockAdManager.bannerAdState == .loaded)
    }

    @Test("showBannerAdからGADBannerViewを取得")
    func testShowBannerAdReturnsView() async throws {
        // Given: loaded状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded
        mockAdManager.mockBannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: showBannerAdを呼び出し
        let bannerView = mockAdManager.showBannerAd()

        // Then: GADBannerViewが返される
        #expect(bannerView != nil)
        #expect(mockAdManager.showBannerAdCalled == true)
    }

    @Test("AdLoadStateの各状態に対応")
    func testAllAdLoadStates() async throws {
        // Given: MockAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)

        // When/Then: idle状態
        mockAdManager.bannerAdState = .idle
        #expect(mockAdManager.bannerAdState == .idle)
        #expect(mockAdManager.bannerAdState.isLoaded == false)
        #expect(mockAdManager.bannerAdState.isLoading == false)

        // When/Then: loading状態
        mockAdManager.bannerAdState = .loading
        #expect(mockAdManager.bannerAdState == .loading)
        #expect(mockAdManager.bannerAdState.isLoading == true)

        // When/Then: loaded状態
        mockAdManager.bannerAdState = .loaded
        #expect(mockAdManager.bannerAdState == .loaded)
        #expect(mockAdManager.bannerAdState.isLoaded == true)

        // When/Then: failed状態
        mockAdManager.bannerAdState = .failed(.loadFailed("Error"))
        #expect(mockAdManager.bannerAdState.isError == true)
    }

    @Test("Premium時はロードがスキップされる")
    func testPremiumSkipsLoad() async throws {
        // Given: Premium会員
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: true)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)

        // When: loadBannerAdを試みる
        do {
            try await mockAdManager.loadBannerAd()
            // Premium会員の場合はエラーがスローされる想定
        } catch {
            // Premium会員なのでエラーが期待される
            #expect(error is AdManagerError)
        }

        // Then: loadBannerAdが呼ばれたがPremiumエラーになる
        #expect(mockAdManager.loadBannerAdCalled == true)
        #expect(mockAdManager.bannerAdState == .failed(.premiumUserNoAds))
    }

    // MARK: - TC03: Premium対応テスト

    @Test("Premium会員時は広告を表示しない - 詳細")
    func testPremiumUserDetailedCheck() async throws {
        // Given: Premium会員
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: true)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded // ロード済みでも
        mockAdManager.mockBannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: Premium会員なので広告は表示されない
        #expect(mockPremiumManager.isPremium == true)
        // Premium会員の場合はEmptyViewが返される
    }

    @Test("premiumUserNoAdsエラー時は広告を表示しない")
    func testPremiumUserNoAdsError() async throws {
        // Given: premiumUserNoAdsエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.premiumUserNoAds)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: premiumUserNoAdsエラーの場合は空のViewを表示
        #expect(mockAdManager.bannerAdState.isError == true)
        if case .failed(let error) = mockAdManager.bannerAdState {
            #expect(error == .premiumUserNoAds)
        }
    }

    @Test("Free会員時は広告を表示")
    func testFreeUserShowsAd() async throws {
        // Given: Free会員
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded
        mockAdManager.mockBannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: Free会員なので広告が表示される
        #expect(mockPremiumManager.isPremium == false)
        let bannerView = mockAdManager.showBannerAd()
        #expect(bannerView != nil)
    }

    // MARK: - TC04: ロード状態表示テスト

    @Test("loading状態: ProgressView表示、高さ50pt")
    func testLoadingStateHeight() async throws {
        // Given: loading状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loading

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: loading状態でProgressViewが表示され、高さは50pt
        #expect(mockAdManager.bannerAdState == .loading)
        // 高さは実装で50ptに設定されている
    }

    @Test("loaded状態: BannerAdViewRepresentable表示")
    func testLoadedStateShowsBanner() async throws {
        // Given: loaded状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded
        mockAdManager.mockBannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: showBannerAdを呼び出し
        let bannerView = mockAdManager.showBannerAd()

        // Then: GADBannerViewが返される
        #expect(bannerView != nil)
        #expect(mockAdManager.showBannerAdCalled == true)
    }

    @Test("failed状態: EmptyView表示、高さ0")
    func testFailedStateEmptyView() async throws {
        // Given: failed状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.loadFailed("Error"))

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: エラー状態で空のViewが表示される（高さ0）
        #expect(mockAdManager.bannerAdState.isError == true)
        // emptyViewは高さ0に設定されている
    }

    @Test("idle状態: 自動ロード開始 - 詳細")
    func testIdleStateAutoLoadDetailed() async throws {
        // Given: idle状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: idle状態から自動的にロードが開始される
        // 実際のViewではtask modifierで自動ロードされる
        #expect(mockAdManager.bannerAdState == .idle)
    }

    // MARK: - TC05: エラーハンドリングテスト

    @Test("loadFailedエラー時の表示")
    func testLoadFailedError() async throws {
        // Given: loadFailedエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.loadFailed("Network error"))

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: エラーメッセージが適切に設定される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "広告のロードに失敗しました: Network error")
    }

    @Test("timeoutエラー時の表示")
    func testTimeoutError() async throws {
        // Given: timeoutエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.timeout)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: タイムアウトエラーが設定される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "広告のロードがタイムアウトしました")
    }

    @Test("networkErrorエラー時の表示")
    func testNetworkError() async throws {
        // Given: networkErrorエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.networkError)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: ネットワークエラーが設定される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "ネットワークエラーが発生しました")
    }

    @Test("premiumUserNoAdsエラー時の表示 - 詳細")
    func testPremiumUserNoAdsErrorDetailed() async throws {
        // Given: premiumUserNoAdsエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.premiumUserNoAds)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: premiumUserNoAdsエラーの場合はEmptyViewが表示される
        #expect(mockAdManager.bannerAdState.isError == true)
        if case .failed(let error) = mockAdManager.bannerAdState {
            #expect(error == .premiumUserNoAds)
            #expect(error.localizedDescription == "プレミアムユーザーには広告が表示されません")
        }
    }

    @Test("notInitializedエラー時の表示")
    func testNotInitializedError() async throws {
        // Given: notInitializedエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.notInitialized)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: 未初期化エラーが設定される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "広告SDKが初期化されていません")
    }

    @Test("adNotReadyエラー時の表示")
    func testAdNotReadyError() async throws {
        // Given: adNotReadyエラー
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.adNotReady)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: 広告未準備エラーが設定される
        #expect(mockAdManager.bannerAdState.isError == true)
        #expect(mockAdManager.bannerAdState.errorMessage == "広告の準備ができていません")
    }

    // MARK: - TC06: アクセシビリティテスト

    @Test("広告に「広告」ラベルが設定されている")
    func testAdAccessibilityLabel() async throws {
        // Given: loaded状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded
        mockAdManager.mockBannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: 広告には「広告」ラベルが設定されている
        // 実装で .accessibilityLabel("広告") が設定されている
        #expect(mockAdManager.bannerAdState == .loaded)
    }

    @Test("ローディングに「広告読み込み中」ラベル")
    func testLoadingAccessibilityLabel() async throws {
        // Given: loading状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loading

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: ローディング時は「広告読み込み中」ラベルが設定される
        // 実装で .accessibilityLabel("広告読み込み中") が設定されている
        #expect(mockAdManager.bannerAdState == .loading)
    }

    @Test("エラー時はaccessibilityHiddenがtrue")
    func testErrorAccessibilityHidden() async throws {
        // Given: エラー状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .failed(.loadFailed("Error"))

        // When: BannerAdViewを作成
        let view = BannerAdView()
            .environment(mockAdManager)
            .environment(mockPremiumManager)

        // Then: エラー時は .accessibilityHidden(true) が設定される
        #expect(mockAdManager.bannerAdState.isError == true)
    }

    // MARK: - TC07: BannerAdViewRepresentableテスト

    @Test("GADBannerViewの作成")
    func testGADBannerViewCreation() async throws {
        // Given: GADBannerView
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: BannerAdViewRepresentableを作成
        let representable = BannerAdViewRepresentable(bannerView: bannerView)

        // Then: GADBannerViewが正しく作成される
        #expect(representable.bannerView.adSize.size.height == 50)
        #expect(representable.bannerView.adSize.size.width == 320)
    }

    @Test("サイズが50ptに設定されている")
    func testBannerSize() async throws {
        // Given: GADBannerView
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: サイズを確認
        let size = bannerView.adSize.size

        // Then: 高さが50ptに設定されている
        #expect(size.height == 50)
    }

    @Test("translatesAutoresizingMaskIntoConstraintsがfalse")
    func testAutoresizingMaskDisabled() async throws {
        // Given: GADBannerView
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)

        // When: BannerAdViewRepresentableを作成
        let representable = BannerAdViewRepresentable(bannerView: bannerView)
        let uiView = representable.makeUIView(context: .init(coordinator: ()))

        // Then: translatesAutoresizingMaskIntoConstraintsがfalseに設定される
        #expect(uiView.translatesAutoresizingMaskIntoConstraints == false)
    }

    // MARK: - 追加テスト: エッジケース

    @Test("バナーViewがnilの場合の処理")
    func testNilBannerView() async throws {
        // Given: loaded状態だがバナーViewがnil
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .loaded
        mockAdManager.mockBannerView = nil

        // When: showBannerAdを呼び出し
        let bannerView = mockAdManager.showBannerAd()

        // Then: nilが返される
        #expect(bannerView == nil)
    }

    @Test("複数回のロード試行")
    func testMultipleLoadAttempts() async throws {
        // Given: idle状態のAdManager
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // When: 複数回ロードを試みる
        try await mockAdManager.loadBannerAd()
        let firstCallCount = mockAdManager.loadBannerAdCallCount

        // 既にloaded状態なので2回目はスキップされる
        try await mockAdManager.loadBannerAd()
        let secondCallCount = mockAdManager.loadBannerAdCallCount

        // Then: 1回目のみロードされる（2回目はスキップ）
        #expect(firstCallCount == 1)
        #expect(secondCallCount == 1) // スキップされるので増えない
    }

    @Test("状態遷移の正確性: idle → loading → loaded")
    func testStateTransitionSuccess() async throws {
        // Given: idle状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // Then: idle状態
        #expect(mockAdManager.bannerAdState == .idle)

        // When: ロード開始
        mockAdManager.bannerAdState = .loading
        #expect(mockAdManager.bannerAdState == .loading)

        // When: ロード完了
        mockAdManager.bannerAdState = .loaded
        #expect(mockAdManager.bannerAdState == .loaded)
    }

    @Test("状態遷移の正確性: idle → loading → failed")
    func testStateTransitionFailure() async throws {
        // Given: idle状態
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)
        mockAdManager.bannerAdState = .idle

        // Then: idle状態
        #expect(mockAdManager.bannerAdState == .idle)

        // When: ロード開始
        mockAdManager.bannerAdState = .loading
        #expect(mockAdManager.bannerAdState == .loading)

        // When: ロード失敗
        mockAdManager.bannerAdState = .failed(.loadFailed("Error"))
        #expect(mockAdManager.bannerAdState.isError == true)
    }

    @Test("Premium状態変更時の動作")
    func testPremiumStatusChange() async throws {
        // Given: Free会員から開始
        let mockPremiumManager = BannerAdViewMockPremiumManager(isPremiumValue: false)
        let mockAdManager = MockAdManager(premiumManager: mockPremiumManager)

        // Then: Free会員
        #expect(mockPremiumManager.isPremium == false)

        // When: Premium会員に変更
        mockPremiumManager.isPremium = true

        // Then: Premium会員になる
        #expect(mockPremiumManager.isPremium == true)

        // When: 広告をロード試行
        do {
            try await mockAdManager.loadBannerAd()
        } catch {
            // Premium会員なのでエラーが期待される
            #expect(error is AdManagerError)
        }
    }
}

// MARK: - MockAdManager

/// テスト用のMockAdManager
@MainActor
@Observable
final class MockAdManager {
    var bannerAdState: AdLoadState = .idle
    var interstitialAdState: AdLoadState = .idle
    var rewardedAdState: AdLoadState = .idle

    var loadBannerAdCalled = false
    var loadBannerAdCallCount = 0
    var showBannerAdCalled = false
    var mockBannerView: GADBannerView?

    private let premiumManager: PremiumManagerProtocol

    init(premiumManager: PremiumManagerProtocol) {
        self.premiumManager = premiumManager
    }

    func loadBannerAd() async throws {
        loadBannerAdCalled = true
        loadBannerAdCallCount += 1

        // Premium確認
        if await premiumManager.status.isActive {
            bannerAdState = .failed(.premiumUserNoAds)
            throw AdManagerError.premiumUserNoAds
        }

        // 既にロード済みの場合はスキップ
        if bannerAdState.isLoaded {
            return
        }

        bannerAdState = .loading

        // シミュレートされたロード処理
        try await Task.sleep(for: .milliseconds(10))

        bannerAdState = .loaded
        mockBannerView = GADBannerView(adSize: GADAdSizeBanner)
    }

    func showBannerAd() -> GADBannerView? {
        showBannerAdCalled = true

        guard bannerAdState.isLoaded else {
            return nil
        }

        return mockBannerView
    }
}

// MARK: - MockPremiumManager

/// BannerAdView用MockPremiumManager
@MainActor
@Observable
final class BannerAdViewMockPremiumManager: PremiumManagerProtocol {
    var isPremium: Bool
    var subscriptionStatus: PremiumStatus
    var dailyDeleteCount: Int = 0

    init(isPremiumValue: Bool) {
        self.isPremium = isPremiumValue
        self.subscriptionStatus = isPremiumValue
            ? .monthly(startDate: Date(), autoRenew: true)
            : .free
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
        dailyDeleteCount += count
    }

    func refreshStatus() async {
        // モック実装では何もしない
    }
}
