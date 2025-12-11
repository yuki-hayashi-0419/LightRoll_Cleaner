//
//  AdMobIdentifiers.swift
//  LightRoll_CleanerFeature
//
//  AdMob App ID と Ad Unit ID の定義
//  テストIDを使用（本番時はGoogle AdMobで取得したIDに変更）
//

import Foundation

/// AdMob識別子の定義
///
/// **重要**: このファイルに定義されているIDは全て**テスト用ID**です。
/// 本番環境にリリースする際は、Google AdMobコンソールで取得した
/// 実際のApp IDとAd Unit IDに置き換える必要があります。
///
/// ## テストIDについて
/// Googleが提供するテストIDを使用することで、開発中にポリシー違反を
/// 心配せずに広告実装をテストできます。
///
/// ## 本番環境への移行手順
/// 1. [AdMobコンソール](https://apps.admob.com/)にログイン
/// 2. 新しいアプリを作成
/// 3. 必要な広告ユニット（バナー、インタースティシャル、リワード）を作成
/// 4. このファイル内のIDを実際のIDに置き換え
/// 5. Info.plistの`GADApplicationIdentifier`も更新
public struct AdMobIdentifiers: Sendable {

    // MARK: - App ID

    /// AdMob App ID（テスト用）
    ///
    /// **本番時に変更必須**: Google AdMobコンソールで取得した
    /// 実際のApp IDに置き換えてください。
    ///
    /// 形式: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
    public static let appID = "ca-app-pub-3940256099942544~1458002511"

    // MARK: - Ad Unit IDs

    /// 広告ユニットの種類
    public enum AdUnitID: Sendable {
        /// バナー広告
        case banner

        /// インタースティシャル広告（全画面）
        case interstitial

        /// リワード広告（報酬型動画）
        case rewarded

        /// 広告ユニットIDを取得
        ///
        /// **本番時に変更必須**: 各ケースのreturn値を
        /// Google AdMobコンソールで取得した実際のAd Unit IDに
        /// 置き換えてください。
        ///
        /// 形式: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`
        public var id: String {
            switch self {
            case .banner:
                // テスト用バナー広告ID
                return "ca-app-pub-3940256099942544/2934735716"

            case .interstitial:
                // テスト用インタースティシャル広告ID
                return "ca-app-pub-3940256099942544/4411468910"

            case .rewarded:
                // テスト用リワード広告ID
                return "ca-app-pub-3940256099942544/1712485313"
            }
        }
    }

    // MARK: - Validation

    /// 現在使用中のIDがテストIDかどうかを判定
    ///
    /// - Returns: テストIDの場合true
    public static var isUsingTestIDs: Bool {
        return appID.contains("3940256099942544")
    }

    /// 本番環境での使用が可能かどうかを検証
    ///
    /// - Returns: 本番環境で使用可能な場合true
    /// - Note: テストIDが使用されている場合はfalseを返す
    public static func validateForProduction() -> Bool {
        guard !isUsingTestIDs else {
            print("⚠️ 警告: テストIDが使用されています。本番環境ではAdMobコンソールで取得した実際のIDに置き換えてください。")
            return false
        }
        return true
    }
}
