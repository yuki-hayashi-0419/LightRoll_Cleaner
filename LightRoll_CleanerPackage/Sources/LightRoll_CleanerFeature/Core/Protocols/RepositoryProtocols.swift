//
//  RepositoryProtocols.swift
//  LightRoll_CleanerFeature
//
//  Repositoryレイヤーのプロトコル定義
//  DIコンテナで使用され、テスト時にモック注入可能
//  Created by AI Assistant
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Photo Repository Protocol

/// 写真リポジトリプロトコル
/// Photos Frameworkへのアクセスを抽象化
public protocol PhotoRepositoryProtocol: AnyObject, Sendable {

    /// 全ての写真を取得
    /// - Returns: 写真の配列
    /// - Throws: PhotoLibraryError
    func fetchAllPhotos() async throws -> [PhotoAsset]

    /// 指定されたIDの写真を取得
    /// - Parameter id: 写真のID
    /// - Returns: 写真、見つからない場合はnil
    func fetchPhoto(by id: String) async -> PhotoAsset?

    /// 写真を削除
    /// - Parameter photos: 削除する写真の配列
    /// - Throws: PhotoLibraryError
    func deletePhotos(_ photos: [PhotoAsset]) async throws

    /// 写真をゴミ箱に移動（アプリ内管理）
    /// - Parameter photos: 移動する写真の配列
    /// - Throws: PhotoLibraryError
    func moveToTrash(_ photos: [PhotoAsset]) async throws

    /// ゴミ箱から復元
    /// - Parameter photos: 復元する写真の配列
    /// - Throws: PhotoLibraryError
    func restoreFromTrash(_ photos: [PhotoAsset]) async throws

    /// サムネイル画像を取得
    /// - Parameters:
    ///   - photo: 対象の写真
    ///   - size: サムネイルサイズ
    /// - Returns: サムネイル画像
    #if canImport(UIKit)
    func fetchThumbnail(for photo: PhotoAsset, size: CGSize) async throws -> UIImage
    #endif
}

// MARK: - Analysis Repository Protocol

/// 分析リポジトリプロトコル
/// Vision/CoreMLへのアクセスを抽象化
public protocol AnalysisRepositoryProtocol: AnyObject, Sendable {

    /// 写真を分析
    /// - Parameter photo: 分析対象の写真
    /// - Returns: 分析結果
    /// - Throws: AnalysisError
    func analyzePhoto(_ photo: PhotoAsset) async throws -> PhotoAnalysisResult

    /// 類似写真をグルーピング
    /// - Parameter photos: 対象の写真配列
    /// - Returns: 類似写真のグループ配列
    /// - Throws: AnalysisError
    func findSimilarPhotos(_ photos: [PhotoAsset]) async throws -> [[PhotoAsset]]

    /// ブレている写真を検出
    /// - Parameter photos: 対象の写真配列
    /// - Returns: ブレている写真の配列
    /// - Throws: AnalysisError
    func detectBlurryPhotos(_ photos: [PhotoAsset]) async throws -> [PhotoAsset]

    /// スクリーンショットを検出
    /// - Parameter photos: 対象の写真配列
    /// - Returns: スクリーンショットの配列
    func detectScreenshots(_ photos: [PhotoAsset]) async -> [PhotoAsset]

    /// ベストショットを選択
    /// - Parameter photos: 対象の類似写真グループ
    /// - Returns: ベストショットのインデックス
    func selectBestShot(from photos: [PhotoAsset]) async -> Int?
}

// MARK: - Storage Repository Protocol

/// ストレージリポジトリプロトコル
/// デバイスのストレージ情報へのアクセスを抽象化
public protocol StorageRepositoryProtocol: AnyObject, Sendable {

    /// ストレージ情報を取得
    /// - Returns: ストレージ情報
    func fetchStorageInfo() async -> StorageInfo

    /// 写真が使用している容量を計算
    /// - Parameter photos: 対象の写真配列
    /// - Returns: 使用容量（バイト）
    func calculatePhotosSize(_ photos: [PhotoAsset]) async -> Int64

    /// 削減可能な容量を計算
    /// - Parameter photos: 削除候補の写真配列
    /// - Returns: 削減可能容量（バイト）
    func calculateReclaimableSize(_ photos: [PhotoAsset]) async -> Int64
}

// MARK: - Settings Repository Protocol

/// 設定リポジトリプロトコル
/// UserDefaultsへのアクセスを抽象化
public protocol SettingsRepositoryProtocol: AnyObject, Sendable {

    /// 設定を読み込み
    /// - Returns: ユーザー設定
    func load() -> UserSettings

    /// 設定を保存
    /// - Parameter settings: 保存する設定
    func save(_ settings: UserSettings)

    /// 設定をリセット
    func reset()
}

// MARK: - Purchase Repository Protocol

/// 課金リポジトリプロトコル
/// StoreKitへのアクセスを抽象化
public protocol PurchaseRepositoryProtocol: AnyObject, Sendable {

    /// 購入可能な商品を取得
    /// - Returns: 商品の配列
    /// - Throws: PurchaseError
    func fetchProducts() async throws -> [ProductInfo]

    /// 商品を購入
    /// - Parameter productId: 商品ID
    /// - Returns: 購入結果
    /// - Throws: PurchaseError
    func purchase(_ productId: String) async throws -> PurchaseResult

    /// 購入を復元
    /// - Throws: PurchaseError
    func restorePurchases() async throws

    /// 現在のプレミアムステータスを取得
    /// - Returns: プレミアムステータス
    func getPremiumStatus() async -> PremiumStatus
}

// MARK: - Placeholder Types

// 注意: これらは仮の型定義です。
// 各モジュール実装時に正式な型に置き換えます。

/// 写真アセット（仮定義）
public struct PhotoAsset: Identifiable, Hashable, Sendable {
    public let id: String
    public let creationDate: Date?
    public let fileSize: Int64

    public init(id: String, creationDate: Date? = nil, fileSize: Int64 = 0) {
        self.id = id
        self.creationDate = creationDate
        self.fileSize = fileSize
    }
}

/// 写真分析結果（仮定義）
public struct PhotoAnalysisResult: Sendable {
    public let photoId: String
    public let qualityScore: Float
    public let hasFaces: Bool
    public let isBlurry: Bool
    public let isScreenshot: Bool

    public init(
        photoId: String,
        qualityScore: Float = 0,
        hasFaces: Bool = false,
        isBlurry: Bool = false,
        isScreenshot: Bool = false
    ) {
        self.photoId = photoId
        self.qualityScore = qualityScore
        self.hasFaces = hasFaces
        self.isBlurry = isBlurry
        self.isScreenshot = isScreenshot
    }
}

/// ストレージ情報（仮定義）
public struct StorageInfo: Sendable {
    public let totalCapacity: Int64
    public let usedCapacity: Int64
    public let photosSize: Int64
    public let reclaimableSize: Int64

    public init(
        totalCapacity: Int64 = 0,
        usedCapacity: Int64 = 0,
        photosSize: Int64 = 0,
        reclaimableSize: Int64 = 0
    ) {
        self.totalCapacity = totalCapacity
        self.usedCapacity = usedCapacity
        self.photosSize = photosSize
        self.reclaimableSize = reclaimableSize
    }

    /// 使用率（0.0〜1.0）
    public var usageRatio: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }

    /// 空き容量
    public var freeCapacity: Int64 {
        return max(0, totalCapacity - usedCapacity)
    }
}

/// ユーザー設定（仮定義）
public struct UserSettings: Sendable, Equatable {
    public var similarityThreshold: Float
    public var autoDeleteDays: Int
    public var notificationsEnabled: Bool
    public var scanOnLaunch: Bool

    public init(
        similarityThreshold: Float = 0.85,
        autoDeleteDays: Int = 30,
        notificationsEnabled: Bool = true,
        scanOnLaunch: Bool = false
    ) {
        self.similarityThreshold = similarityThreshold
        self.autoDeleteDays = autoDeleteDays
        self.notificationsEnabled = notificationsEnabled
        self.scanOnLaunch = scanOnLaunch
    }

    public static let `default` = UserSettings()
}

/// 商品情報（仮定義）
public struct ProductInfo: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let displayPrice: String

    public init(id: String, displayName: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
    }
}

/// 購入結果（仮定義）
public enum PurchaseResult: Sendable {
    case success
    case pending
    case cancelled
    case failed(Error)

    // Sendableへの対応
    public static func failure(_ error: Error) -> PurchaseResult {
        return .failed(error)
    }
}

/// プレミアムステータス（仮定義）
public enum PremiumStatus: Sendable, Equatable {
    case free
    case premium
    case expired
}
