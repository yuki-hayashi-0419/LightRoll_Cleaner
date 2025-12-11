//
//  AdLoadState.swift
//  LightRoll_CleanerFeature
//
//  広告ロード状態の定義
//  - アイドル、ロード中、ロード完了、エラー状態の管理
//

import Foundation

/// 広告ロード状態
///
/// 広告のライフサイクルにおける各状態を表現します。
///
/// ## 状態遷移
/// ```
/// idle → loading → loaded
///   ↓       ↓
///   └─── failed
/// ```
public enum AdLoadState: Sendable, Equatable {
    /// アイドル状態（未ロード）
    case idle

    /// ロード中
    case loading

    /// ロード完了（広告表示可能）
    case loaded

    /// ロード失敗
    case failed(AdManagerError)

    // MARK: - Computed Properties

    /// ロード完了状態かどうか
    public var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }

    /// ロード中かどうか
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// エラー状態かどうか
    public var isError: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// エラーメッセージを取得
    public var errorMessage: String? {
        if case .failed(let error) = self {
            return error.localizedDescription
        }
        return nil
    }

    // MARK: - Equatable

    public static func == (lhs: AdLoadState, rhs: AdLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - AdManagerError

/// AdManagerのエラー型
public enum AdManagerError: LocalizedError, Sendable, Equatable {
    /// SDK未初期化
    case notInitialized

    /// 広告ロード失敗
    case loadFailed(String)

    /// 広告表示失敗
    case showFailed(String)

    /// プレミアムユーザーのため広告非表示
    case premiumUserNoAds

    /// 広告未準備
    case adNotReady

    /// ネットワークエラー
    case networkError

    /// タイムアウト
    case timeout

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "広告SDKが初期化されていません"

        case .loadFailed(let message):
            return "広告のロードに失敗しました: \(message)"

        case .showFailed(let message):
            return "広告の表示に失敗しました: \(message)"

        case .premiumUserNoAds:
            return "プレミアムユーザーには広告が表示されません"

        case .adNotReady:
            return "広告の準備ができていません"

        case .networkError:
            return "ネットワークエラーが発生しました"

        case .timeout:
            return "広告のロードがタイムアウトしました"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notInitialized:
            return "アプリを再起動してください"

        case .loadFailed:
            return "時間をおいて再度お試しください"

        case .showFailed:
            return "時間をおいて再度お試しください"

        case .premiumUserNoAds:
            return nil

        case .adNotReady:
            return "広告のロードが完了するまでお待ちください"

        case .networkError:
            return "インターネット接続を確認してください"

        case .timeout:
            return "ネットワーク接続を確認して、再度お試しください"
        }
    }

    // MARK: - Equatable

    public static func == (lhs: AdManagerError, rhs: AdManagerError) -> Bool {
        switch (lhs, rhs) {
        case (.notInitialized, .notInitialized):
            return true
        case (.loadFailed(let lhsMsg), .loadFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.showFailed(let lhsMsg), .showFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.premiumUserNoAds, .premiumUserNoAds):
            return true
        case (.adNotReady, .adNotReady):
            return true
        case (.networkError, .networkError):
            return true
        case (.timeout, .timeout):
            return true
        default:
            return false
        }
    }
}

// MARK: - AdReward

/// 広告視聴報酬
///
/// リワード広告視聴時にユーザーが獲得する報酬を表現します。
public struct AdReward: Sendable, Equatable {
    /// 報酬量
    public let amount: Int

    /// 報酬種類
    public let type: String

    /// イニシャライザ
    /// - Parameters:
    ///   - amount: 報酬量
    ///   - type: 報酬種類
    public init(amount: Int, type: String) {
        self.amount = amount
        self.type = type
    }
}
