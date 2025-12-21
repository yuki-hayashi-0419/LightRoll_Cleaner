//
//  AdMobIdentifiersTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AdMobIdentifiersのテスト
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

@Suite("AdMobIdentifiers Tests")
struct AdMobIdentifiersTests {

    // MARK: - App ID Tests

    @Test("App IDが正しい形式である")
    func testAppIDFormat() {
        let appID = AdMobIdentifiers.appID

        // ca-app-pub-から始まる
        #expect(appID.hasPrefix("ca-app-pub-"))

        // ~を含む
        #expect(appID.contains("~"))

        // 空でない
        #expect(!appID.isEmpty)
    }

    @Test("App IDがテストIDである")
    func testAppIDIsTestID() {
        let appID = AdMobIdentifiers.appID

        // Googleのテスト用Publisher ID (3940256099942544) を含む
        #expect(appID.contains("3940256099942544"))
    }

    // MARK: - Ad Unit ID Tests

    @Test("バナー広告ユニットIDが正しい形式である")
    func testBannerAdUnitIDFormat() {
        let bannerID = AdMobIdentifiers.AdUnitID.banner.id

        // ca-app-pub-から始まる
        #expect(bannerID.hasPrefix("ca-app-pub-"))

        // /を含む
        #expect(bannerID.contains("/"))

        // 空でない
        #expect(!bannerID.isEmpty)
    }

    @Test("インタースティシャル広告ユニットIDが正しい形式である")
    func testInterstitialAdUnitIDFormat() {
        let interstitialID = AdMobIdentifiers.AdUnitID.interstitial.id

        // ca-app-pub-から始まる
        #expect(interstitialID.hasPrefix("ca-app-pub-"))

        // /を含む
        #expect(interstitialID.contains("/"))

        // 空でない
        #expect(!interstitialID.isEmpty)
    }

    @Test("リワード広告ユニットIDが正しい形式である")
    func testRewardedAdUnitIDFormat() {
        let rewardedID = AdMobIdentifiers.AdUnitID.rewarded.id

        // ca-app-pub-から始まる
        #expect(rewardedID.hasPrefix("ca-app-pub-"))

        // /を含む
        #expect(rewardedID.contains("/"))

        // 空でない
        #expect(!rewardedID.isEmpty)
    }

    @Test("全てのAd Unit IDがユニークである")
    func testAllAdUnitIDsAreUnique() {
        let bannerID = AdMobIdentifiers.AdUnitID.banner.id
        let interstitialID = AdMobIdentifiers.AdUnitID.interstitial.id
        let rewardedID = AdMobIdentifiers.AdUnitID.rewarded.id

        // 各IDが異なる
        #expect(bannerID != interstitialID)
        #expect(bannerID != rewardedID)
        #expect(interstitialID != rewardedID)
    }

    @Test("全てのAd Unit IDがテストIDである")
    func testAllAdUnitIDsAreTestIDs() {
        let bannerID = AdMobIdentifiers.AdUnitID.banner.id
        let interstitialID = AdMobIdentifiers.AdUnitID.interstitial.id
        let rewardedID = AdMobIdentifiers.AdUnitID.rewarded.id

        // Googleのテスト用Publisher ID (3940256099942544) を含む
        #expect(bannerID.contains("3940256099942544"))
        #expect(interstitialID.contains("3940256099942544"))
        #expect(rewardedID.contains("3940256099942544"))
    }

    // MARK: - Validation Tests

    @Test("isUsingTestIDsがtrueを返す")
    func testIsUsingTestIDs() {
        // 現在はテストIDを使用しているため、trueであるべき
        #expect(AdMobIdentifiers.isUsingTestIDs == true)
    }

    @Test("validateForProductionがfalseを返す（テストID使用時）")
    func testValidateForProductionWithTestIDs() {
        // テストIDを使用しているため、本番環境では使用不可
        #expect(AdMobIdentifiers.validateForProduction() == false)
    }

    // MARK: - Sendable Conformance Tests

    @Test("AdMobIdentifiersがSendableに準拠している")
    func testSendableConformance() {
        // Sendableに準拠していることをコンパイラが保証
        let _: any Sendable = AdMobIdentifiers.self
    }

    @Test("AdUnitIDがSendableに準拠している")
    func testAdUnitIDSendableConformance() {
        // AdUnitIDがSendableに準拠していることを確認
        let bannerUnit: AdMobIdentifiers.AdUnitID = .banner
        let _: any Sendable = bannerUnit
    }

    // MARK: - Edge Case Tests

    @Test("Ad Unit IDのswitchで全てのケースがカバーされている")
    func testAllAdUnitCasesCovered() {
        // 全てのケースでIDが取得できる
        let allCases: [AdMobIdentifiers.AdUnitID] = [.banner, .interstitial, .rewarded]

        for adUnitCase in allCases {
            let id = adUnitCase.id
            #expect(!id.isEmpty)
            #expect(id.hasPrefix("ca-app-pub-"))
        }
    }

    @Test("App IDが本番環境の形式と互換性がある")
    func testAppIDCompatibilityWithProduction() {
        let appID = AdMobIdentifiers.appID

        // 本番環境で使用する際の形式チェック
        // ca-app-pub-数字~数字 の形式
        let pattern = #"^ca-app-pub-\d+~\d+$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: appID.utf16.count)
        let matches = regex?.firstMatch(in: appID, range: range)

        #expect(matches != nil)
    }

    @Test("Ad Unit IDが本番環境の形式と互換性がある")
    func testAdUnitIDCompatibilityWithProduction() {
        let adUnitIDs = [
            AdMobIdentifiers.AdUnitID.banner.id,
            AdMobIdentifiers.AdUnitID.interstitial.id,
            AdMobIdentifiers.AdUnitID.rewarded.id
        ]

        // 本番環境で使用する際の形式チェック
        // ca-app-pub-数字/数字 の形式
        let pattern = #"^ca-app-pub-\d+/\d+$"#
        let regex = try? NSRegularExpression(pattern: pattern)

        for adUnitID in adUnitIDs {
            let range = NSRange(location: 0, length: adUnitID.utf16.count)
            let matches = regex?.firstMatch(in: adUnitID, range: range)
            #expect(matches != nil)
        }
    }
}
