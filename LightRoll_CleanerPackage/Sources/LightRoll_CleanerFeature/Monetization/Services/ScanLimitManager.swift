//
//  ScanLimitManager.swift
//  LightRoll_CleanerFeature
//
//  スキャン制限管理サービス
//  - Freeユーザー: 初回スキャンのみ許可
//  - Proユーザー: 無制限スキャン
//
//  "Try & Lock" マネタイズモデルの実装
//

import Foundation

/// スキャン制限を管理するサービス
///
/// Freeユーザーは初回スキャンのみ実行可能で、2回目以降はPaywallを表示
/// Proユーザーは無制限にスキャン可能
@MainActor
@Observable
public final class ScanLimitManager {
    // MARK: - Published Properties

    /// スキャン済みフラグ（Freeユーザーが一度でもスキャンしたか）
    public private(set) var hasScannedBefore: Bool

    /// 初回スキャン日時
    public private(set) var firstScanDate: Date?

    /// 総スキャン回数（統計用）
    public private(set) var totalScanCount: Int

    // MARK: - Private Properties

    private enum Keys {
        static let hasScannedBefore = "has_scanned_before"
        static let firstScanDate = "first_scan_date"
        static let totalScanCount = "total_scan_count"
    }

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// ScanLimitManagerを初期化
    /// - Parameter userDefaults: 永続化ストレージ（デフォルトは.standard）
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // UserDefaultsから状態を読み込み
        self.hasScannedBefore = userDefaults.bool(forKey: Keys.hasScannedBefore)
        self.firstScanDate = userDefaults.object(forKey: Keys.firstScanDate) as? Date
        self.totalScanCount = userDefaults.integer(forKey: Keys.totalScanCount)
    }

    // MARK: - Public Methods

    /// スキャン実行可能か判定
    ///
    /// - Parameter isPremium: プレミアムユーザーかどうか
    /// - Returns: スキャン可能ならtrue
    public func canScan(isPremium: Bool) -> Bool {
        // Proユーザーは無制限
        if isPremium {
            return true
        }

        // Freeユーザーは初回のみ
        return !hasScannedBefore
    }

    /// スキャン実行を記録
    ///
    /// - Note: スキャン開始時に呼び出すこと。canScan()で確認済みであること。
    public func recordScan() {
        // 初回スキャンの場合のみフラグを立てる
        if !hasScannedBefore {
            hasScannedBefore = true
            firstScanDate = Date()

            // UserDefaultsに永続化
            userDefaults.set(true, forKey: Keys.hasScannedBefore)
            userDefaults.set(firstScanDate, forKey: Keys.firstScanDate)
        }

        // 総スキャン回数を増加（統計用）
        totalScanCount += 1
        userDefaults.set(totalScanCount, forKey: Keys.totalScanCount)
    }

    /// リセット（主にテスト用）
    ///
    /// - Warning: 本番環境では使用しないこと。開発・テスト目的のみ。
    public func reset() {
        hasScannedBefore = false
        firstScanDate = nil
        totalScanCount = 0

        userDefaults.removeObject(forKey: Keys.hasScannedBefore)
        userDefaults.removeObject(forKey: Keys.firstScanDate)
        userDefaults.removeObject(forKey: Keys.totalScanCount)
    }

    /// 初回スキャンからの経過日数を取得
    ///
    /// - Returns: 経過日数（初回スキャン未実施の場合はnil）
    public func daysSinceFirstScan() -> Int? {
        guard let firstDate = firstScanDate else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstDate, to: Date())
        return components.day
    }
}
