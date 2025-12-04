//
//  SettingsRepository.swift
//  LightRoll_CleanerFeature
//
//  UserDefaultsベースのユーザー設定永続化層
//  Created by AI Assistant on 2025-12-04.
//

import Foundation

// MARK: - SettingsRepository

/// UserDefaultsを使用したユーザー設定リポジトリ
///
/// UserSettings構造体をJSONとしてUserDefaultsに保存/読み込みする
/// デコード失敗時はデフォルト設定を返す安全な設計
public final class SettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// UserDefaultsインスタンス
    private let userDefaults: UserDefaults

    /// 設定を保存するキー
    private let settingsKey = "user_settings"

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter userDefaults: UserDefaultsインスタンス（デフォルトは.standard）
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SettingsRepositoryProtocol

    /// 設定を読み込み
    ///
    /// UserDefaultsから設定を読み込み、デコード失敗時はデフォルト値を返す
    /// - Returns: ユーザー設定（読み込み失敗時は.default）
    public func load() -> UserSettings {
        // UserDefaultsからData取得
        guard let data = userDefaults.data(forKey: settingsKey) else {
            // データが存在しない場合（初回起動など）
            return .default
        }

        // JSONデコード
        do {
            let decoder = JSONDecoder()
            let settings = try decoder.decode(UserSettings.self, from: data)
            return settings
        } catch {
            // デコード失敗時はデフォルト値を返す
            // 設定の構造が変わった場合など
            print("⚠️ UserSettings デコード失敗: \(error.localizedDescription)")
            return .default
        }
    }

    /// 設定を保存
    ///
    /// UserSettingsをJSONエンコードしてUserDefaultsに保存
    /// エンコード失敗時はコンソールにエラーを出力
    /// - Parameter settings: 保存する設定
    public func save(_ settings: UserSettings) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 可読性向上（デバッグ用）
            let data = try encoder.encode(settings)

            // UserDefaultsに保存
            userDefaults.set(data, forKey: settingsKey)

            // 即座に同期（オプショナルだが確実性向上）
            userDefaults.synchronize()

        } catch {
            // エンコード失敗は通常発生しないが、念のためエラー出力
            print("❌ UserSettings 保存失敗: \(error.localizedDescription)")
        }
    }

    /// 設定をリセット
    ///
    /// UserDefaultsから設定を削除し、次回load()でデフォルト値を返すようにする
    public func reset() {
        // UserDefaultsから削除
        userDefaults.removeObject(forKey: settingsKey)

        // 即座に同期
        userDefaults.synchronize()
    }
}
