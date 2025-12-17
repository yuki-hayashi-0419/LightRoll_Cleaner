//
//  AdManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AdManagerサービスのテスト
//

import Testing
@testable import LightRoll_CleanerFeature

@Suite("AdManager Tests")
@MainActor
struct AdManagerTests {

    // MARK: - Mock Objects

    /// MockPremiumManager（テスト用）
    final class MockPremiumManager: PremiumManagerProtocol, @unchecked Sendable {
        var premiumStatus: PremiumStatus
        var adFreeEnabled: Bool

        init(isPremium: Bool = false) {
            self.premiumStatus = isPremium ? .monthly() : .free
            self.adFreeEnabled = isPremium
        }

        var status: PremiumStatus {
            get async { premiumStatus }
        }

        func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
            switch feature {
            case .adFree:
                return adFreeEnabled
            default:
                return false
            }
        }

        func getRemainingDeletions() async -> Int {
            return 50
        }

        func recordDeletion(count: Int) async {
            // モック実装
        }

        func refreshStatus() async {
            // モック実装
        }
    }

    // MARK: - Initialization Tests

    @Test("init: AdManagerが初期化される")
    func initialization() {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        #expect(adManager.bannerAdState == .idle)
        #expect(adManager.interstitialAdState == .idle)
        #expect(adManager.rewardedAdState == .idle)
    }

    // MARK: - State Management Tests

    @Test("初期状態: 全ての広告状態がidleである")
    func initialStateIsIdle() {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        #expect(adManager.bannerAdState == .idle)
        #expect(adManager.interstitialAdState == .idle)
        #expect(adManager.rewardedAdState == .idle)
    }

    @Test("Observable: @Observableマクロが適用されている")
    func observableConformance() {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        // @Observableオブジェクトが生成可能であることを確認
        #expect(adManager.bannerAdState == .idle)
    }

    // MARK: - Premium User Tests

    @Test("loadBannerAd: Premiumユーザーの場合エラーを投げる")
    func loadBannerAdThrowsForPremiumUser() async {
        let mockPremiumManager = MockPremiumManager(isPremium: true)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.loadBannerAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            return adError == .premiumUserNoAds
        })

        #expect(adManager.bannerAdState == .failed(.premiumUserNoAds))
    }

    @Test("loadInterstitialAd: Premiumユーザーの場合エラーを投げる")
    func loadInterstitialAdThrowsForPremiumUser() async {
        let mockPremiumManager = MockPremiumManager(isPremium: true)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.loadInterstitialAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            return adError == .premiumUserNoAds
        })

        #expect(adManager.interstitialAdState == .failed(.premiumUserNoAds))
    }

    @Test("loadRewardedAd: Premiumユーザーの場合エラーを投げる")
    func loadRewardedAdThrowsForPremiumUser() async {
        let mockPremiumManager = MockPremiumManager(isPremium: true)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.loadRewardedAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            return adError == .premiumUserNoAds
        })

        #expect(adManager.rewardedAdState == .failed(.premiumUserNoAds))
    }

    // MARK: - SDK Not Initialized Tests

    @Test("loadBannerAd: SDK未初期化の場合エラーを投げる")
    func loadBannerAdThrowsWhenNotInitialized() async {
        let mockPremiumManager = MockPremiumManager(isPremium: false)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        // AdInitializerが初期化されていない状態を想定
        await #expect(performing: {
            try await adManager.loadBannerAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            // SDK未初期化またはロード失敗のいずれか
            switch adError {
            case .notInitialized, .loadFailed:
                return true
            default:
                return false
            }
        })
    }

    @Test("loadInterstitialAd: SDK未初期化の場合エラーを投げる")
    func loadInterstitialAdThrowsWhenNotInitialized() async {
        let mockPremiumManager = MockPremiumManager(isPremium: false)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.loadInterstitialAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            switch adError {
            case .notInitialized, .loadFailed:
                return true
            default:
                return false
            }
        })
    }

    @Test("loadRewardedAd: SDK未初期化の場合エラーを投げる")
    func loadRewardedAdThrowsWhenNotInitialized() async {
        let mockPremiumManager = MockPremiumManager(isPremium: false)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.loadRewardedAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            switch adError {
            case .notInitialized, .loadFailed:
                return true
            default:
                return false
            }
        })
    }

    // MARK: - Show Ad Tests

    @Test("showBannerAd: ロード未完了の場合nilを返す")
    func showBannerAdReturnsNilWhenNotLoaded() {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        let bannerView = adManager.showBannerAd()
        #expect(bannerView == nil)
    }

    @Test("showInterstitialAd: ロード未完了の場合エラーを投げる")
    func showInterstitialAdThrowsWhenNotLoaded() async {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.showInterstitialAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            return adError == .adNotReady
        })
    }

    @Test("showRewardedAd: ロード未完了の場合エラーを投げる")
    func showRewardedAdThrowsWhenNotLoaded() async {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        await #expect(performing: {
            try await adManager.showRewardedAd()
        }, throws: { error in
            guard let adError = error as? AdManagerError else {
                return false
            }
            return adError == .adNotReady
        })
    }

    // MARK: - MainActor Isolation Tests

    @Test("MainActor: AdManagerは@MainActorで実行される")
    func mainActorIsolation() async {
        let mockPremiumManager = MockPremiumManager()
        let adManager = AdManager(premiumManager: mockPremiumManager)

        // MainActorコンテキストで実行可能
        #expect(adManager.bannerAdState == .idle)
    }

    // MARK: - Concurrent Access Tests

    @Test("並行アクセス: 複数のロード呼び出しが安全に実行される")
    func concurrentLoadCalls() async {
        let mockPremiumManager = MockPremiumManager(isPremium: true)
        let adManager = AdManager(premiumManager: mockPremiumManager)

        // 複数の広告を同時にロード試行（Premiumのためエラーになる）
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await adManager.loadBannerAd()
            }
            group.addTask {
                try? await adManager.loadInterstitialAd()
            }
            group.addTask {
                try? await adManager.loadRewardedAd()
            }
        }

        // 全てPremiumエラーになっている
        #expect(adManager.bannerAdState == .failed(.premiumUserNoAds))
        #expect(adManager.interstitialAdState == .failed(.premiumUserNoAds))
        #expect(adManager.rewardedAdState == .failed(.premiumUserNoAds))
    }

    // MARK: - Memory Safety Tests

    @Test("メモリ安全性: AdManagerが解放される")
    func memoryDeallocation() async {
        var adManager: AdManager? = AdManager(
            premiumManager: MockPremiumManager()
        )

        weak var weakReference = adManager

        // AdManagerを解放
        adManager = nil

        // 弱参照がnilになることを確認
        #expect(weakReference == nil)
    }

    // MARK: - Conditional Compilation Tests

    @Suite("Conditional Compilation Tests")
    @MainActor
    struct ConditionalCompilationTests {

        @Test("条件付きコンパイル: GoogleMobileAds利用可能時 - showBannerAdが正しい型を返す")
        func showBannerAdReturnsCorrectTypeWhenGMAAvailable() {
            let mockPremiumManager = MockPremiumManager()
            let adManager = AdManager(premiumManager: mockPremiumManager)

            #if canImport(GoogleMobileAds)
            // GoogleMobileAds利用可能時：GADBannerViewまたはnilが返る
            let bannerView = adManager.showBannerAd()
            // ロード未完了のためnilを期待
            #expect(bannerView == nil)
            #else
            // GoogleMobileAds利用不可時：nilが返る
            let bannerView = adManager.showBannerAd()
            #expect(bannerView == nil)
            #endif
        }

        @Test("条件付きコンパイル: GoogleMobileAds利用不可時 - loadBannerAdが適切なエラーを投げる")
        func loadBannerAdThrowsAppropriateErrorWhenGMAUnavailable() async {
            let mockPremiumManager = MockPremiumManager(isPremium: false)
            let adManager = AdManager(premiumManager: mockPremiumManager)

            #if canImport(GoogleMobileAds)
            // GoogleMobileAds利用可能時：SDK未初期化エラー
            await #expect(performing: {
                try await adManager.loadBannerAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                switch adError {
                case .notInitialized, .loadFailed:
                    return true
                default:
                    return false
                }
            })
            #else
            // GoogleMobileAds利用不可時：SDK利用不可エラー
            await #expect(performing: {
                try await adManager.loadBannerAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                if case .loadFailed(let message) = adError {
                    return message.contains("GoogleMobileAds SDK が利用できません")
                }
                return false
            })
            #endif
        }

        @Test("条件付きコンパイル: GoogleMobileAds利用不可時 - loadInterstitialAdが適切なエラーを投げる")
        func loadInterstitialAdThrowsAppropriateErrorWhenGMAUnavailable() async {
            let mockPremiumManager = MockPremiumManager(isPremium: false)
            let adManager = AdManager(premiumManager: mockPremiumManager)

            #if canImport(GoogleMobileAds)
            // GoogleMobileAds利用可能時：SDK未初期化エラー
            await #expect(performing: {
                try await adManager.loadInterstitialAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                switch adError {
                case .notInitialized, .loadFailed:
                    return true
                default:
                    return false
                }
            })
            #else
            // GoogleMobileAds利用不可時：SDK利用不可エラー
            await #expect(performing: {
                try await adManager.loadInterstitialAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                if case .loadFailed(let message) = adError {
                    return message.contains("GoogleMobileAds SDK が利用できません")
                }
                return false
            })
            #endif
        }

        @Test("条件付きコンパイル: GoogleMobileAds利用不可時 - loadRewardedAdが適切なエラーを投げる")
        func loadRewardedAdThrowsAppropriateErrorWhenGMAUnavailable() async {
            let mockPremiumManager = MockPremiumManager(isPremium: false)
            let adManager = AdManager(premiumManager: mockPremiumManager)

            #if canImport(GoogleMobileAds)
            // GoogleMobileAds利用可能時：SDK未初期化エラー
            await #expect(performing: {
                try await adManager.loadRewardedAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                switch adError {
                case .notInitialized, .loadFailed:
                    return true
                default:
                    return false
                }
            })
            #else
            // GoogleMobileAds利用不可時：SDK利用不可エラー
            await #expect(performing: {
                try await adManager.loadRewardedAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                if case .loadFailed(let message) = adError {
                    return message.contains("GoogleMobileAds SDK が利用できません")
                }
                return false
            })
            #endif
        }

        @Test("条件付きコンパイル: GoogleMobileAds利用不可時 - showRewardedAdが適切なエラーを投げる")
        func showRewardedAdThrowsAppropriateErrorWhenGMAUnavailable() async {
            let mockPremiumManager = MockPremiumManager(isPremium: false)
            let adManager = AdManager(premiumManager: mockPremiumManager)

            #if canImport(GoogleMobileAds)
            // GoogleMobileAds利用可能時：広告未準備エラー
            await #expect(performing: {
                _ = try await adManager.showRewardedAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                return adError == .adNotReady
            })
            #else
            // GoogleMobileAds利用不可時：SDK利用不可エラー
            await #expect(performing: {
                _ = try await adManager.showRewardedAd()
            }, throws: { error in
                guard let adError = error as? AdManagerError else {
                    return false
                }
                if case .showFailed(let message) = adError {
                    return message.contains("GoogleMobileAds SDK が利用できません")
                }
                return false
            })
            #endif
        }
    }
}
