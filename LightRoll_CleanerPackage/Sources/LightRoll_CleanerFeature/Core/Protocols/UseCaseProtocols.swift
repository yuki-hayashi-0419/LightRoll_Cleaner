//
//  UseCaseProtocols.swift
//  LightRoll_CleanerFeature
//
//  UseCase層のプロトコル定義
//  ビジネスロジックを抽象化し、テスタビリティを向上
//  Created by AI Assistant
//

import Foundation

// MARK: - Base UseCase Protocol

/// UseCase基底プロトコル
/// 全てのUseCaseが共通で持つインターフェース
public protocol UseCaseProtocol: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    /// UseCaseを実行
    /// - Parameter input: 入力パラメータ
    /// - Returns: 出力結果
    /// - Throws: LightRollError
    func execute(_ input: Input) async throws -> Output
}

/// 入力パラメータなしのUseCase用
public protocol NoInputUseCaseProtocol: Sendable {
    associatedtype Output: Sendable

    /// UseCaseを実行（入力なし）
    /// - Returns: 出力結果
    /// - Throws: LightRollError
    func execute() async throws -> Output
}

// MARK: - Scan Photos UseCase Protocol

/// 写真スキャンUseCaseプロトコル
/// 写真ライブラリのスキャンと分析を実行
@MainActor
public protocol ScanPhotosUseCaseProtocol: NoInputUseCaseProtocol where Output == ScanResult {

    /// スキャン進捗を監視するためのAsyncStream
    var progressStream: AsyncStream<ScanProgress> { get }

    /// スキャンをキャンセル
    func cancel()

    /// 現在スキャン中かどうか
    var isScanning: Bool { get }
}

// MARK: - Group Photos UseCase Protocol

/// 写真グルーピングUseCaseプロトコル
/// 類似写真やカテゴリ別にグループ化
public protocol GroupPhotosUseCaseProtocol: UseCaseProtocol
    where Input == [PhotoAsset], Output == [PhotoGroup] {}

// MARK: - Delete Photos UseCase Protocol

/// 削除入力パラメータ
public struct DeletePhotosInput: Sendable {
    /// 削除対象の写真
    public let photos: [PhotoAsset]

    /// 完全削除かゴミ箱移動か
    public let permanently: Bool

    public init(photos: [PhotoAsset], permanently: Bool = false) {
        self.photos = photos
        self.permanently = permanently
    }
}

/// 削除結果
public struct DeletePhotosOutput: Sendable, Equatable {
    /// 削除成功した写真数
    public let deletedCount: Int

    /// 削減された容量（バイト）
    public let freedBytes: Int64

    /// 失敗した写真のID（あれば）
    public let failedIds: [String]

    public init(
        deletedCount: Int,
        freedBytes: Int64,
        failedIds: [String] = []
    ) {
        self.deletedCount = deletedCount
        self.freedBytes = freedBytes
        self.failedIds = failedIds
    }

    /// 全て成功したかどうか
    public var isFullySuccessful: Bool {
        failedIds.isEmpty
    }

    /// 人間が読みやすい削減容量
    public var formattedFreedBytes: String {
        ByteCountFormatter.string(
            fromByteCount: freedBytes,
            countStyle: .file
        )
    }
}

/// 写真削除UseCaseプロトコル
/// 写真の削除・ゴミ箱移動を実行
public protocol DeletePhotosUseCaseProtocol: UseCaseProtocol
    where Input == DeletePhotosInput, Output == DeletePhotosOutput {}

// MARK: - Restore Photos UseCase Protocol

/// 復元入力パラメータ
public struct RestorePhotosInput: Sendable {
    /// 復元対象の写真
    public let photos: [PhotoAsset]

    public init(photos: [PhotoAsset]) {
        self.photos = photos
    }
}

/// 復元結果
public struct RestorePhotosOutput: Sendable, Equatable {
    /// 復元成功した写真数
    public let restoredCount: Int

    /// 失敗した写真のID（あれば）
    public let failedIds: [String]

    public init(restoredCount: Int, failedIds: [String] = []) {
        self.restoredCount = restoredCount
        self.failedIds = failedIds
    }

    /// 全て成功したかどうか
    public var isFullySuccessful: Bool {
        failedIds.isEmpty
    }
}

/// 写真復元UseCaseプロトコル
/// ゴミ箱から写真を復元
public protocol RestorePhotosUseCaseProtocol: UseCaseProtocol
    where Input == RestorePhotosInput, Output == RestorePhotosOutput {}

// MARK: - Get Statistics UseCase Protocol

/// 統計情報出力
public struct StatisticsOutput: Sendable, Equatable {
    /// ストレージ情報
    public let storageInfo: StorageInfo

    /// 写真総数
    public let totalPhotos: Int

    /// グループ別の統計
    public let groupStatistics: GroupStatistics

    /// 最終スキャン日時
    public let lastScanDate: Date?

    public init(
        storageInfo: StorageInfo,
        totalPhotos: Int,
        groupStatistics: GroupStatistics = GroupStatistics(),
        lastScanDate: Date? = nil
    ) {
        self.storageInfo = storageInfo
        self.totalPhotos = totalPhotos
        self.groupStatistics = groupStatistics
        self.lastScanDate = lastScanDate
    }
}

/// グループ別統計
public struct GroupStatistics: Sendable, Equatable {
    /// 類似写真グループ数
    public let similarGroupCount: Int

    /// スクリーンショット数
    public let screenshotCount: Int

    /// ブレ写真数
    public let blurryCount: Int

    /// 大容量動画数
    public let largeVideoCount: Int

    /// ゴミ箱内の写真数
    public let trashCount: Int

    public init(
        similarGroupCount: Int = 0,
        screenshotCount: Int = 0,
        blurryCount: Int = 0,
        largeVideoCount: Int = 0,
        trashCount: Int = 0
    ) {
        self.similarGroupCount = similarGroupCount
        self.screenshotCount = screenshotCount
        self.blurryCount = blurryCount
        self.largeVideoCount = largeVideoCount
        self.trashCount = trashCount
    }

    /// 総削除候補数
    public var totalDeletionCandidates: Int {
        similarGroupCount + screenshotCount + blurryCount + largeVideoCount
    }
}

/// 統計情報取得UseCaseプロトコル
public protocol GetStatisticsUseCaseProtocol: NoInputUseCaseProtocol
    where Output == StatisticsOutput {}

// MARK: - Analyze Photo UseCase Protocol

/// 写真分析入力
public struct AnalyzePhotoInput: Sendable {
    /// 分析対象の写真
    public let photo: PhotoAsset

    /// 分析オプション
    public let options: AnalysisOptions

    public init(photo: PhotoAsset, options: AnalysisOptions = .default) {
        self.photo = photo
        self.options = options
    }
}

/// 分析オプション
public struct AnalysisOptions: Sendable, Equatable {
    /// 顔検出を実行するか
    public let detectFaces: Bool

    /// ブレ検出を実行するか
    public let detectBlur: Bool

    /// スクリーンショット判定を実行するか
    public let detectScreenshot: Bool

    /// 品質スコア算出を実行するか
    public let calculateQuality: Bool

    public init(
        detectFaces: Bool = true,
        detectBlur: Bool = true,
        detectScreenshot: Bool = true,
        calculateQuality: Bool = true
    ) {
        self.detectFaces = detectFaces
        self.detectBlur = detectBlur
        self.detectScreenshot = detectScreenshot
        self.calculateQuality = calculateQuality
    }

    /// デフォルトオプション（全て有効）
    public static let `default` = AnalysisOptions()

    /// 高速分析オプション（顔検出のみ）
    public static let fast = AnalysisOptions(
        detectFaces: true,
        detectBlur: false,
        detectScreenshot: false,
        calculateQuality: false
    )
}

/// 単一写真分析UseCaseプロトコル
public protocol AnalyzePhotoUseCaseProtocol: UseCaseProtocol
    where Input == AnalyzePhotoInput, Output == PhotoAnalysisResult {}

// MARK: - Select Best Shot UseCase Protocol

/// ベストショット選択入力
public struct SelectBestShotInput: Sendable {
    /// 対象の写真グループ
    public let photos: [PhotoAsset]

    /// 選択基準
    public let criteria: BestShotCriteria

    public init(photos: [PhotoAsset], criteria: BestShotCriteria = .default) {
        self.photos = photos
        self.criteria = criteria
    }
}

/// ベストショット選択基準
public struct BestShotCriteria: Sendable, Equatable {
    /// 品質重視度（0.0〜1.0）
    public let qualityWeight: Float

    /// 顔の鮮明さ重視度（0.0〜1.0）
    public let faceQualityWeight: Float

    /// 構図重視度（0.0〜1.0）
    public let compositionWeight: Float

    public init(
        qualityWeight: Float = 0.5,
        faceQualityWeight: Float = 0.3,
        compositionWeight: Float = 0.2
    ) {
        self.qualityWeight = qualityWeight
        self.faceQualityWeight = faceQualityWeight
        self.compositionWeight = compositionWeight
    }

    /// デフォルト基準
    public static let `default` = BestShotCriteria()
}

/// ベストショット選択結果
public struct SelectBestShotOutput: Sendable, Equatable {
    /// ベストショットのインデックス
    public let bestShotIndex: Int

    /// ベストショットの写真ID
    public let bestShotId: String

    /// 各写真のスコア（インデックス順）
    public let scores: [Float]

    public init(
        bestShotIndex: Int,
        bestShotId: String,
        scores: [Float]
    ) {
        self.bestShotIndex = bestShotIndex
        self.bestShotId = bestShotId
        self.scores = scores
    }
}

/// ベストショット選択UseCaseプロトコル
public protocol SelectBestShotUseCaseProtocol: UseCaseProtocol
    where Input == SelectBestShotInput, Output == SelectBestShotOutput {}

// MARK: - Purchase UseCase Protocol

/// 購入入力
public struct PurchaseInput: Sendable {
    /// 商品ID
    public let productId: String

    public init(productId: String) {
        self.productId = productId
    }
}

/// 購入UseCaseプロトコル
public protocol PurchaseUseCaseProtocol: UseCaseProtocol
    where Input == PurchaseInput, Output == PurchaseResult {}

/// 購入復元UseCaseプロトコル
public protocol RestorePurchasesUseCaseProtocol: NoInputUseCaseProtocol
    where Output == PremiumStatus {}

// MARK: - Check Deletion Limit UseCase Protocol

/// 削除制限チェック結果
public struct DeletionLimitStatus: Sendable, Equatable {
    /// 今日の削除済み数
    public let todayDeletedCount: Int

    /// 1日の上限
    public let dailyLimit: Int

    /// 残り削除可能数
    public let remainingCount: Int

    /// プレミアムステータス
    public let premiumStatus: PremiumStatus

    public init(
        todayDeletedCount: Int,
        dailyLimit: Int,
        premiumStatus: PremiumStatus
    ) {
        self.todayDeletedCount = todayDeletedCount
        self.dailyLimit = dailyLimit
        self.remainingCount = max(0, dailyLimit - todayDeletedCount)
        self.premiumStatus = premiumStatus
    }

    /// 削除可能かどうか
    public var canDelete: Bool {
        premiumStatus == .premium || remainingCount > 0
    }

    /// 指定数を削除可能かどうか
    public func canDelete(count: Int) -> Bool {
        premiumStatus == .premium || remainingCount >= count
    }
}

/// 削除制限チェックUseCaseプロトコル
public protocol CheckDeletionLimitUseCaseProtocol: NoInputUseCaseProtocol
    where Output == DeletionLimitStatus {}
