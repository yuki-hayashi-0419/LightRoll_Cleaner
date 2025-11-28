//
//  ThumbnailRequestOptions.swift
//  LightRoll_CleanerFeature
//
//  サムネイル取得のオプション設定
//  PHCachingImageManagerで使用する各種パラメータをカプセル化
//  Created by AI Assistant
//

import Foundation
import Photos

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ThumbnailQuality

/// サムネイルの品質レベル
/// 取得速度と画質のトレードオフを制御
public enum ThumbnailQuality: Int, Sendable, Codable, Hashable {
    /// 高速取得（低品質）
    /// スクロール中などの一時的な表示に最適
    case fast = 0

    /// バランス（標準品質）
    /// 一般的な一覧表示に最適
    case balanced = 1

    /// 高品質
    /// 詳細画面や拡大表示に最適
    case highQuality = 2

    /// PHImageRequestOptionsDeliveryMode への変換
    var deliveryMode: PHImageRequestOptionsDeliveryMode {
        switch self {
        case .fast:
            return .fastFormat
        case .balanced:
            return .opportunistic
        case .highQuality:
            return .highQualityFormat
        }
    }

    /// PHImageRequestOptionsResizeMode への変換
    var resizeMode: PHImageRequestOptionsResizeMode {
        switch self {
        case .fast:
            return .fast
        case .balanced:
            return .fast
        case .highQuality:
            return .exact
        }
    }

    /// ローカライズされた名称
    public var localizedName: String {
        switch self {
        case .fast:
            return NSLocalizedString(
                "thumbnailQuality.fast",
                value: "高速",
                comment: "Fast thumbnail quality"
            )
        case .balanced:
            return NSLocalizedString(
                "thumbnailQuality.balanced",
                value: "バランス",
                comment: "Balanced thumbnail quality"
            )
        case .highQuality:
            return NSLocalizedString(
                "thumbnailQuality.highQuality",
                value: "高品質",
                comment: "High quality thumbnail"
            )
        }
    }
}

// MARK: - ThumbnailRequestOptions

/// サムネイル取得オプション
/// PHCachingImageManagerで使用する各種設定をまとめた構造体
public struct ThumbnailRequestOptions: Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// サムネイルサイズ（ポイント単位）
    /// 実際のピクセルサイズはスケールファクターを考慮して計算される
    public let size: CGSize

    /// コンテンツモード
    /// アスペクト比の処理方法を指定
    public let contentMode: PHImageContentMode

    /// 品質レベル
    public let quality: ThumbnailQuality

    /// ネットワークアクセスを許可するか
    /// trueの場合、iCloudからのダウンロードを許可
    public let isNetworkAccessAllowed: Bool

    /// 同期的に取得するか
    /// trueの場合、完全な画像を取得するまでブロック
    public let isSynchronous: Bool

    // MARK: - Initialization

    /// 全てのパラメータを指定して初期化
    /// - Parameters:
    ///   - size: サムネイルサイズ（ポイント）
    ///   - contentMode: コンテンツモード
    ///   - quality: 品質レベル
    ///   - isNetworkAccessAllowed: ネットワークアクセス許可
    ///   - isSynchronous: 同期的取得フラグ
    public init(
        size: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        quality: ThumbnailQuality = .balanced,
        isNetworkAccessAllowed: Bool = true,
        isSynchronous: Bool = false
    ) {
        self.size = size
        self.contentMode = contentMode
        self.quality = quality
        self.isNetworkAccessAllowed = isNetworkAccessAllowed
        self.isSynchronous = isSynchronous
    }

    // MARK: - Computed Properties

    #if canImport(UIKit)
    /// スケールファクターを考慮した実際のピクセルサイズ
    @MainActor
    public var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
    #endif

    // MARK: - PHImageRequestOptions Conversion

    /// PHImageRequestOptions への変換
    public func toPHImageRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = quality.deliveryMode
        options.resizeMode = quality.resizeMode
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.isSynchronous = isSynchronous

        // 高品質の場合は正確なサイズを要求
        if quality == .highQuality {
            options.resizeMode = .exact
        }

        return options
    }

    // MARK: - Static Factory Methods

    /// デフォルトオプション
    /// 一般的な使用に適したバランス設定
    public static var `default`: ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            quality: .balanced,
            isNetworkAccessAllowed: true
        )
    }

    /// グリッド表示用オプション
    /// 写真一覧のグリッド表示に最適化
    /// - Parameter size: グリッドセルのサイズ
    /// - Returns: グリッド用のThumbnailRequestOptions
    public static func grid(size: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: .aspectFill,
            quality: .fast,
            isNetworkAccessAllowed: false
        )
    }

    /// 詳細表示用オプション
    /// 写真詳細画面など高品質な表示に最適化
    /// - Parameter size: 表示サイズ
    /// - Returns: 詳細表示用のThumbnailRequestOptions
    public static func detail(size: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: .aspectFit,
            quality: .highQuality,
            isNetworkAccessAllowed: true
        )
    }

    /// プレビュー用オプション
    /// サムネイルよりやや高品質な中間的なオプション
    /// - Parameter size: プレビューサイズ
    /// - Returns: プレビュー用のThumbnailRequestOptions
    public static func preview(size: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: .aspectFit,
            quality: .balanced,
            isNetworkAccessAllowed: true
        )
    }

    /// 高速スクロール用オプション
    /// 高速スクロール中の一時的な表示に最適化
    /// - Parameter size: サムネイルサイズ
    /// - Returns: 高速スクロール用のThumbnailRequestOptions
    public static func fastScroll(size: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: .aspectFill,
            quality: .fast,
            isNetworkAccessAllowed: false,
            isSynchronous: false
        )
    }

    /// プリキャッシュ用オプション
    /// バックグラウンドでのキャッシュ準備に最適化
    /// - Parameter size: キャッシュするサムネイルサイズ
    /// - Returns: プリキャッシュ用のThumbnailRequestOptions
    public static func preCache(size: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: .aspectFill,
            quality: .fast,
            isNetworkAccessAllowed: false,
            isSynchronous: false
        )
    }

    // MARK: - Mutation Methods

    /// サイズを変更した新しいオプションを返す
    /// - Parameter newSize: 新しいサイズ
    /// - Returns: サイズを変更したThumbnailRequestOptions
    public func withSize(_ newSize: CGSize) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: newSize,
            contentMode: contentMode,
            quality: quality,
            isNetworkAccessAllowed: isNetworkAccessAllowed,
            isSynchronous: isSynchronous
        )
    }

    /// 品質を変更した新しいオプションを返す
    /// - Parameter newQuality: 新しい品質
    /// - Returns: 品質を変更したThumbnailRequestOptions
    public func withQuality(_ newQuality: ThumbnailQuality) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: contentMode,
            quality: newQuality,
            isNetworkAccessAllowed: isNetworkAccessAllowed,
            isSynchronous: isSynchronous
        )
    }

    /// ネットワークアクセス設定を変更した新しいオプションを返す
    /// - Parameter allowed: ネットワークアクセス許可フラグ
    /// - Returns: 設定を変更したThumbnailRequestOptions
    public func withNetworkAccess(_ allowed: Bool) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: contentMode,
            quality: quality,
            isNetworkAccessAllowed: allowed,
            isSynchronous: isSynchronous
        )
    }

    /// コンテンツモードを変更した新しいオプションを返す
    /// - Parameter newContentMode: 新しいコンテンツモード
    /// - Returns: 設定を変更したThumbnailRequestOptions
    public func withContentMode(_ newContentMode: PHImageContentMode) -> ThumbnailRequestOptions {
        ThumbnailRequestOptions(
            size: size,
            contentMode: newContentMode,
            quality: quality,
            isNetworkAccessAllowed: isNetworkAccessAllowed,
            isSynchronous: isSynchronous
        )
    }

    // MARK: - Size Presets

    /// 小サイズ（グリッド用）
    public static let smallSize = CGSize(width: 80, height: 80)

    /// 中サイズ（一覧用）
    public static let mediumSize = CGSize(width: 150, height: 150)

    /// 大サイズ（プレビュー用）
    public static let largeSize = CGSize(width: 300, height: 300)

    /// 特大サイズ（詳細表示用）
    public static let extraLargeSize = CGSize(width: 600, height: 600)
}

// MARK: - ThumbnailRequestOptions + CustomStringConvertible

extension ThumbnailRequestOptions: CustomStringConvertible {
    public var description: String {
        """
        ThumbnailRequestOptions(\
        size: \(Int(size.width))x\(Int(size.height)), \
        quality: \(quality.localizedName), \
        network: \(isNetworkAccessAllowed))
        """
    }
}

// MARK: - ThumbnailResult

/// サムネイル取得結果
/// 取得したサムネイルと関連情報を保持
#if canImport(UIKit)
public struct ThumbnailResult: Sendable {

    /// 取得した画像
    public let image: UIImage

    /// 劣化画像かどうか（低解像度の一時的な画像）
    public let isDegraded: Bool

    /// ローカルに存在するか（iCloud専用でないか）
    public let isLocallyAvailable: Bool

    /// 初期化
    /// - Parameters:
    ///   - image: 取得した画像
    ///   - isDegraded: 劣化画像フラグ
    ///   - isLocallyAvailable: ローカル利用可能フラグ
    public init(
        image: UIImage,
        isDegraded: Bool = false,
        isLocallyAvailable: Bool = true
    ) {
        self.image = image
        self.isDegraded = isDegraded
        self.isLocallyAvailable = isLocallyAvailable
    }
}
#endif

// MARK: - ThumbnailBatchProgress

/// バッチ取得の進捗情報
public struct ThumbnailBatchProgress: Sendable {
    /// 完了数
    public let completed: Int

    /// 総数
    public let total: Int

    /// 進捗率（0.0〜1.0）
    public var progress: Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }

    /// 完了済みかどうか
    public var isCompleted: Bool {
        completed >= total
    }

    /// 初期化
    /// - Parameters:
    ///   - completed: 完了数
    ///   - total: 総数
    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }
}
