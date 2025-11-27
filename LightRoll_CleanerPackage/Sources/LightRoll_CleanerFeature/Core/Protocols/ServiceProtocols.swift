//
//  ServiceProtocols.swift
//  LightRoll_CleanerFeature
//
//  サービス層のプロトコル定義
//  アプリケーション全体で使用されるサービスを抽象化
//  Created by AI Assistant
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Trash Manager Protocol

/// ゴミ箱データモデル
public struct TrashPhoto: Identifiable, Equatable, Hashable, Sendable {
    /// 元の写真
    public let photo: PhotoAsset

    /// ゴミ箱に移動した日時
    public let trashedDate: Date

    /// 元の場所情報（復元用）
    public let originalContext: TrashContext?

    public var id: String { photo.id }

    public init(
        photo: PhotoAsset,
        trashedDate: Date = Date(),
        originalContext: TrashContext? = nil
    ) {
        self.photo = photo
        self.trashedDate = trashedDate
        self.originalContext = originalContext
    }

    /// 削除予定日を計算
    /// - Parameter retentionDays: 保持日数
    /// - Returns: 削除予定日
    public func deletionDate(retentionDays: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: retentionDays, to: trashedDate) ?? trashedDate
    }

    /// 残り日数を計算
    /// - Parameter retentionDays: 保持日数
    /// - Returns: 残り日数（0未満の場合は期限切れ）
    public func daysUntilDeletion(retentionDays: Int) -> Int {
        let deletion = deletionDate(retentionDays: retentionDays)
        return Calendar.current.dateComponents([.day], from: Date(), to: deletion).day ?? 0
    }
}

/// ゴミ箱コンテキスト（復元時に使用）
public struct TrashContext: Equatable, Hashable, Sendable {
    /// 元のグループタイプ
    public let groupType: GroupType?

    /// 追加情報
    public let metadata: [String: String]

    public init(
        groupType: GroupType? = nil,
        metadata: [String: String] = [:]
    ) {
        self.groupType = groupType
        self.metadata = metadata
    }
}

/// ゴミ箱マネージャープロトコル
/// アプリ内ゴミ箱機能を管理
public protocol TrashManagerProtocol: AnyObject, Sendable {

    /// ゴミ箱内の全写真を取得
    /// - Returns: ゴミ箱内の写真配列
    func fetchAllTrashPhotos() async -> [TrashPhoto]

    /// 写真をゴミ箱に移動
    /// - Parameters:
    ///   - photos: 移動する写真
    ///   - context: コンテキスト情報（復元用）
    func moveToTrash(_ photos: [PhotoAsset], context: TrashContext?) async throws

    /// ゴミ箱から復元
    /// - Parameter photos: 復元する写真
    func restore(_ photos: [TrashPhoto]) async throws

    /// ゴミ箱から完全削除
    /// - Parameter photos: 削除する写真
    func permanentlyDelete(_ photos: [TrashPhoto]) async throws

    /// 期限切れの写真を自動削除
    /// - Returns: 削除された写真数
    @discardableResult
    func cleanupExpired() async -> Int

    /// ゴミ箱を空にする
    func emptyTrash() async throws

    /// ゴミ箱内の写真数を取得
    var trashCount: Int { get async }

    /// ゴミ箱内の写真が使用している容量
    var trashSize: Int64 { get async }
}

// MARK: - Notification Manager Protocol

/// 通知種別
public enum NotificationType: String, CaseIterable, Sendable {
    /// 空き容量警告
    case lowStorage

    /// スキャン完了
    case scanCompleted

    /// ゴミ箱期限警告
    case trashExpiring

    /// 定期リマインド
    case periodicReminder
}

/// 通知コンテンツ
public struct NotificationContent: Sendable {
    /// タイトル
    public let title: String

    /// 本文
    public let body: String

    /// バッジ数（nilの場合は変更なし）
    public let badge: Int?

    /// カスタムデータ
    public let userInfo: [String: String]

    public init(
        title: String,
        body: String,
        badge: Int? = nil,
        userInfo: [String: String] = [:]
    ) {
        self.title = title
        self.body = body
        self.badge = badge
        self.userInfo = userInfo
    }
}

/// 通知マネージャープロトコル
/// プッシュ通知・ローカル通知を管理
public protocol NotificationManagerProtocol: AnyObject, Sendable {

    /// 通知権限をリクエスト
    /// - Returns: 許可されたかどうか
    func requestAuthorization() async -> Bool

    /// 現在の通知権限状態を取得
    /// - Returns: 権限状態
    func getAuthorizationStatus() async -> NotificationAuthorizationStatus

    /// ローカル通知をスケジュール
    /// - Parameters:
    ///   - type: 通知種別
    ///   - content: 通知コンテンツ
    ///   - trigger: トリガー条件
    func scheduleNotification(
        type: NotificationType,
        content: NotificationContent,
        trigger: NotificationTrigger
    ) async throws

    /// 指定種別の通知をキャンセル
    /// - Parameter type: 通知種別
    func cancelNotification(type: NotificationType) async

    /// 全ての通知をキャンセル
    func cancelAllNotifications() async

    /// バッジをクリア
    func clearBadge() async
}

/// 通知権限状態
public enum NotificationAuthorizationStatus: Sendable {
    /// 未確定
    case notDetermined

    /// 拒否
    case denied

    /// 許可
    case authorized

    /// 仮許可（iOS 12+）
    case provisional

    /// 一時的（iOS 14+）
    case ephemeral
}

/// 通知トリガー
public enum NotificationTrigger: Sendable {
    /// 即時
    case immediate

    /// 指定秒後
    case timeInterval(TimeInterval)

    /// 指定日時
    case date(DateComponents)

    /// 毎日指定時刻
    case daily(hour: Int, minute: Int)
}

// MARK: - Permission Manager Protocol

/// 権限種別
public enum PermissionType: String, CaseIterable, Sendable {
    /// 写真ライブラリ
    case photoLibrary

    /// 通知
    case notifications
}

/// 権限状態
public enum PermissionStatus: Sendable, Equatable {
    /// 未確定
    case notDetermined

    /// 制限あり（ペアレンタルコントロール等）
    case restricted

    /// 拒否
    case denied

    /// 許可
    case authorized

    /// 限定的に許可（写真ライブラリの場合、選択した写真のみ）
    case limited
}

/// 権限マネージャープロトコル
/// 各種権限の状態確認とリクエストを管理
public protocol PermissionManagerProtocol: AnyObject, Sendable {

    /// 権限状態を取得
    /// - Parameter type: 権限種別
    /// - Returns: 権限状態
    func getStatus(for type: PermissionType) async -> PermissionStatus

    /// 権限をリクエスト
    /// - Parameter type: 権限種別
    /// - Returns: リクエスト後の権限状態
    func requestPermission(for type: PermissionType) async -> PermissionStatus

    /// 設定アプリを開く
    func openSettings() async

    /// 全権限の状態を取得
    /// - Returns: 権限種別と状態のマップ
    func getAllStatuses() async -> [PermissionType: PermissionStatus]
}

// MARK: - Premium Manager Protocol

/// プレミアム機能
public enum PremiumFeature: String, CaseIterable, Sendable {
    /// 無制限削除
    case unlimitedDeletion

    /// 広告非表示
    case adFree

    /// 高度な分析
    case advancedAnalysis

    /// クラウドバックアップ（将来機能）
    case cloudBackup
}

/// プレミアムマネージャープロトコル
/// プレミアム機能のゲート管理
public protocol PremiumManagerProtocol: AnyObject, Sendable {

    /// 現在のプレミアムステータス
    var status: PremiumStatus { get async }

    /// 指定機能が利用可能かどうか
    /// - Parameter feature: 確認する機能
    /// - Returns: 利用可能かどうか
    func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool

    /// 今日の削除可能残数を取得
    /// - Returns: 残り削除可能数（プレミアムの場合はInt.max）
    func getRemainingDeletions() async -> Int

    /// 削除数を記録
    /// - Parameter count: 削除した数
    func recordDeletion(count: Int) async

    /// ステータスを更新
    func refreshStatus() async
}

// MARK: - Cache Manager Protocol

/// キャッシュマネージャープロトコル
/// 分析結果やサムネイルのキャッシュを管理
public protocol CacheManagerProtocol: AnyObject, Sendable {

    /// 分析結果をキャッシュ
    /// - Parameters:
    ///   - result: 分析結果
    ///   - photoId: 写真ID
    func cacheAnalysisResult(_ result: PhotoAnalysisResult, for photoId: String) async

    /// キャッシュされた分析結果を取得
    /// - Parameter photoId: 写真ID
    /// - Returns: キャッシュされた結果（存在しない場合はnil）
    func getCachedAnalysisResult(for photoId: String) async -> PhotoAnalysisResult?

    /// サムネイルをキャッシュ
    /// - Parameters:
    ///   - imageData: 画像データ
    ///   - photoId: 写真ID
    ///   - size: サムネイルサイズ
    func cacheThumbnail(_ imageData: Data, for photoId: String, size: CGSize) async

    /// キャッシュされたサムネイルを取得
    /// - Parameters:
    ///   - photoId: 写真ID
    ///   - size: サムネイルサイズ
    /// - Returns: キャッシュされた画像データ（存在しない場合はnil）
    func getCachedThumbnail(for photoId: String, size: CGSize) async -> Data?

    /// 指定写真のキャッシュをクリア
    /// - Parameter photoId: 写真ID
    func clearCache(for photoId: String) async

    /// 全キャッシュをクリア
    func clearAllCache() async

    /// キャッシュサイズを取得
    /// - Returns: キャッシュサイズ（バイト）
    var cacheSize: Int64 { get async }
}

// MARK: - Storage Monitor Protocol

/// ストレージ監視プロトコル
/// デバイスのストレージ状態を監視
public protocol StorageMonitorProtocol: AnyObject, Sendable {

    /// 現在のストレージ情報を取得
    /// - Returns: ストレージ情報
    func getCurrentStorageInfo() async -> StorageInfo

    /// 空き容量が閾値以下かどうか
    /// - Parameter threshold: 閾値（バイト）
    /// - Returns: 閾値以下かどうか
    func isStorageLow(threshold: Int64) async -> Bool

    /// ストレージ変更を監視開始
    /// - Parameter handler: 変更時のハンドラー
    func startMonitoring(handler: @escaping @Sendable (StorageInfo) -> Void)

    /// ストレージ監視を停止
    func stopMonitoring()
}

// MARK: - Photo Scanner Protocol

/// 写真スキャナープロトコル
/// 写真ライブラリのスキャンを実行
public protocol PhotoScannerProtocol: AnyObject, Sendable {

    /// スキャンを開始
    /// - Parameter progressHandler: 進捗ハンドラー
    /// - Returns: スキャン結果
    func scan(progressHandler: @escaping @Sendable (ScanProgress) -> Void) async throws -> ScanResult

    /// スキャンをキャンセル
    func cancel()

    /// 現在スキャン中かどうか
    var isScanning: Bool { get }
}

// MARK: - Image Analyzer Protocol

/// 画像分析器プロトコル
/// Vision/CoreMLを使用した画像分析
public protocol ImageAnalyzerProtocol: AnyObject, Sendable {

    /// 画像の特徴量を抽出
    /// - Parameter imageData: 画像データ
    /// - Returns: 特徴量ベクトル
    func extractFeatures(from imageData: Data) async throws -> [Float]

    /// 2つの特徴量の類似度を計算
    /// - Parameters:
    ///   - features1: 特徴量1
    ///   - features2: 特徴量2
    /// - Returns: 類似度（0.0〜1.0）
    func calculateSimilarity(
        _ features1: [Float],
        _ features2: [Float]
    ) -> Float

    /// 画像のブレ度を検出
    /// - Parameter imageData: 画像データ
    /// - Returns: ブレ度（0.0〜1.0、高いほどブレている）
    func detectBlur(in imageData: Data) async throws -> Float

    /// 画像の品質スコアを算出
    /// - Parameter imageData: 画像データ
    /// - Returns: 品質スコア（0.0〜1.0）
    func calculateQualityScore(for imageData: Data) async throws -> Float

    /// 顔を検出
    /// - Parameter imageData: 画像データ
    /// - Returns: 検出された顔の数
    func detectFaces(in imageData: Data) async throws -> Int
}
