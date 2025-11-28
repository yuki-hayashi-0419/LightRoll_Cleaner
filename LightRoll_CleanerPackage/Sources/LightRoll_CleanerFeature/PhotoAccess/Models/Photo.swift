//
//  Photo.swift
//  LightRoll_CleanerFeature
//
//  写真のドメインモデル
//  PHAssetから変換可能で、アプリ全体で使用されるモデル
//  Created by AI Assistant
//

import Foundation
import Photos

// MARK: - Photo

/// 写真のドメインモデル
/// PHAsset の情報をアプリ内で扱いやすい形式に変換したもの
/// Sendable 準拠により Swift Concurrency で安全に使用可能
public struct Photo: Identifiable, Hashable, Sendable, Codable {

    // MARK: - Properties

    /// 一意な識別子（localIdentifier と同じ）
    public let id: String

    /// PHAsset の localIdentifier
    public let localIdentifier: String

    /// 写真の作成日時
    public let creationDate: Date

    /// 写真の最終更新日時
    public let modificationDate: Date

    /// メディアタイプ（画像、動画、オーディオ）
    public let mediaType: MediaType

    /// メディアサブタイプ（スクリーンショット、HDR、パノラマ等）
    public let mediaSubtypes: MediaSubtypes

    /// 横幅（ピクセル）
    public let pixelWidth: Int

    /// 高さ（ピクセル）
    public let pixelHeight: Int

    /// 動画の長さ（秒）。画像の場合は 0
    public let duration: TimeInterval

    /// ファイルサイズ（バイト）
    public let fileSize: Int64

    /// お気に入りフラグ
    public let isFavorite: Bool

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - id: 一意な識別子
    ///   - localIdentifier: PHAsset の localIdentifier
    ///   - creationDate: 作成日時
    ///   - modificationDate: 更新日時
    ///   - mediaType: メディアタイプ
    ///   - mediaSubtypes: メディアサブタイプ
    ///   - pixelWidth: 横幅（ピクセル）
    ///   - pixelHeight: 高さ（ピクセル）
    ///   - duration: 動画の長さ
    ///   - fileSize: ファイルサイズ
    ///   - isFavorite: お気に入りフラグ
    public init(
        id: String,
        localIdentifier: String,
        creationDate: Date,
        modificationDate: Date,
        mediaType: MediaType,
        mediaSubtypes: MediaSubtypes,
        pixelWidth: Int,
        pixelHeight: Int,
        duration: TimeInterval,
        fileSize: Int64,
        isFavorite: Bool
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.mediaType = mediaType
        self.mediaSubtypes = mediaSubtypes
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.duration = duration
        self.fileSize = fileSize
        self.isFavorite = isFavorite
    }

    // MARK: - Computed Properties

    /// アスペクト比（横 / 高さ）
    /// 高さが 0 の場合は 1.0 を返す
    public var aspectRatio: Double {
        guard pixelHeight > 0 else { return 1.0 }
        return Double(pixelWidth) / Double(pixelHeight)
    }

    /// 動画かどうか
    public var isVideo: Bool {
        mediaType == .video
    }

    /// スクリーンショットかどうか
    public var isScreenshot: Bool {
        mediaSubtypes.contains(.screenshot)
    }

    /// フォーマット済みファイルサイズ（例: 「1.2 MB」）
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// 解像度文字列（例: 「4032 × 3024」）
    public var resolution: String {
        "\(pixelWidth) × \(pixelHeight)"
    }

    /// 動画の長さのフォーマット済み文字列（例: 「1:23」）
    /// 画像の場合は空文字列
    public var formattedDuration: String {
        guard isVideo, duration > 0 else { return "" }

        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }

    /// 画像かどうか
    public var isImage: Bool {
        mediaType == .image
    }

    /// HDR 写真かどうか
    public var isHDR: Bool {
        mediaSubtypes.contains(.hdr)
    }

    /// パノラマ写真かどうか
    public var isPanorama: Bool {
        mediaSubtypes.contains(.panorama)
    }

    /// Live Photo かどうか
    public var isLivePhoto: Bool {
        mediaSubtypes.contains(.livePhoto)
    }

    /// 縦向きかどうか
    public var isPortrait: Bool {
        pixelHeight > pixelWidth
    }

    /// 横向きかどうか
    public var isLandscape: Bool {
        pixelWidth > pixelHeight
    }

    /// 正方形かどうか
    public var isSquare: Bool {
        pixelWidth == pixelHeight
    }

    /// 総ピクセル数
    public var totalPixels: Int {
        pixelWidth * pixelHeight
    }

    /// メガピクセル数（例: 12.2）
    public var megapixels: Double {
        Double(totalPixels) / 1_000_000.0
    }
}

// MARK: - MediaType

/// メディアタイプ
/// PHAssetMediaType に対応する Codable 対応の型
public enum MediaType: Int, Sendable, Codable, Hashable {
    /// 不明
    case unknown = 0
    /// 画像
    case image = 1
    /// 動画
    case video = 2
    /// オーディオ
    case audio = 3

    /// PHAssetMediaType から変換
    /// - Parameter assetMediaType: PHAsset のメディアタイプ
    public init(from assetMediaType: PHAssetMediaType) {
        switch assetMediaType {
        case .image:
            self = .image
        case .video:
            self = .video
        case .audio:
            self = .audio
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }

    /// PHAssetMediaType に変換
    public var toPHAssetMediaType: PHAssetMediaType {
        switch self {
        case .unknown:
            return .unknown
        case .image:
            return .image
        case .video:
            return .video
        case .audio:
            return .audio
        }
    }

    /// ローカライズされた名称
    public var localizedName: String {
        switch self {
        case .unknown:
            return NSLocalizedString("mediaType.unknown", value: "不明", comment: "Unknown media type")
        case .image:
            return NSLocalizedString("mediaType.image", value: "写真", comment: "Image media type")
        case .video:
            return NSLocalizedString("mediaType.video", value: "動画", comment: "Video media type")
        case .audio:
            return NSLocalizedString("mediaType.audio", value: "オーディオ", comment: "Audio media type")
        }
    }
}

// MARK: - MediaSubtypes

/// メディアサブタイプ
/// PHAssetMediaSubtype に対応する Codable 対応の OptionSet
public struct MediaSubtypes: OptionSet, Sendable, Codable, Hashable {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // MARK: - Photo Subtypes

    /// パノラマ写真
    public static let panorama = MediaSubtypes(rawValue: 1 << 0)

    /// HDR 写真
    public static let hdr = MediaSubtypes(rawValue: 1 << 1)

    /// スクリーンショット
    public static let screenshot = MediaSubtypes(rawValue: 1 << 2)

    /// Live Photo
    public static let livePhoto = MediaSubtypes(rawValue: 1 << 3)

    /// 深度エフェクト（ポートレートモード）
    public static let depthEffect = MediaSubtypes(rawValue: 1 << 4)

    // MARK: - Video Subtypes

    /// ストリーミング動画
    public static let streamed = MediaSubtypes(rawValue: 1 << 16)

    /// ハイフレームレート動画
    public static let highFrameRate = MediaSubtypes(rawValue: 1 << 17)

    /// タイムラプス動画
    public static let timelapse = MediaSubtypes(rawValue: 1 << 18)

    /// シネマティックビデオ
    public static let cinematicVideo = MediaSubtypes(rawValue: 1 << 21)

    /// PHAssetMediaSubtype から変換
    /// - Parameter subtype: PHAsset のサブタイプ
    public init(from subtype: PHAssetMediaSubtype) {
        var result: MediaSubtypes = []

        // Photo subtypes
        if subtype.contains(.photoPanorama) {
            result.insert(.panorama)
        }
        if subtype.contains(.photoHDR) {
            result.insert(.hdr)
        }
        if subtype.contains(.photoScreenshot) {
            result.insert(.screenshot)
        }
        if subtype.contains(.photoLive) {
            result.insert(.livePhoto)
        }
        if subtype.contains(.photoDepthEffect) {
            result.insert(.depthEffect)
        }

        // Video subtypes
        if subtype.contains(.videoStreamed) {
            result.insert(.streamed)
        }
        if subtype.contains(.videoHighFrameRate) {
            result.insert(.highFrameRate)
        }
        if subtype.contains(.videoTimelapse) {
            result.insert(.timelapse)
        }
        if subtype.contains(.videoCinematic) {
            result.insert(.cinematicVideo)
        }

        self = result
    }

    /// PHAssetMediaSubtype に変換
    public var toPHAssetMediaSubtype: PHAssetMediaSubtype {
        var result: PHAssetMediaSubtype = []

        // Photo subtypes
        if contains(.panorama) {
            result.insert(.photoPanorama)
        }
        if contains(.hdr) {
            result.insert(.photoHDR)
        }
        if contains(.screenshot) {
            result.insert(.photoScreenshot)
        }
        if contains(.livePhoto) {
            result.insert(.photoLive)
        }
        if contains(.depthEffect) {
            result.insert(.photoDepthEffect)
        }

        // Video subtypes
        if contains(.streamed) {
            result.insert(.videoStreamed)
        }
        if contains(.highFrameRate) {
            result.insert(.videoHighFrameRate)
        }
        if contains(.timelapse) {
            result.insert(.videoTimelapse)
        }
        if contains(.cinematicVideo) {
            result.insert(.videoCinematic)
        }

        return result
    }

    /// 含まれるサブタイプの名称一覧
    public var descriptions: [String] {
        var result: [String] = []

        if contains(.panorama) {
            result.append(NSLocalizedString("subtype.panorama", value: "パノラマ", comment: "Panorama subtype"))
        }
        if contains(.hdr) {
            result.append(NSLocalizedString("subtype.hdr", value: "HDR", comment: "HDR subtype"))
        }
        if contains(.screenshot) {
            result.append(NSLocalizedString("subtype.screenshot", value: "スクリーンショット", comment: "Screenshot subtype"))
        }
        if contains(.livePhoto) {
            result.append(NSLocalizedString("subtype.livePhoto", value: "Live Photo", comment: "Live Photo subtype"))
        }
        if contains(.depthEffect) {
            result.append(NSLocalizedString("subtype.depthEffect", value: "ポートレート", comment: "Depth effect subtype"))
        }
        if contains(.streamed) {
            result.append(NSLocalizedString("subtype.streamed", value: "ストリーミング", comment: "Streamed subtype"))
        }
        if contains(.highFrameRate) {
            result.append(NSLocalizedString("subtype.highFrameRate", value: "スローモーション", comment: "High frame rate subtype"))
        }
        if contains(.timelapse) {
            result.append(NSLocalizedString("subtype.timelapse", value: "タイムラプス", comment: "Timelapse subtype"))
        }
        if contains(.cinematicVideo) {
            result.append(NSLocalizedString("subtype.cinematic", value: "シネマティック", comment: "Cinematic subtype"))
        }

        return result
    }
}

// MARK: - Photo + CustomStringConvertible

extension Photo: CustomStringConvertible {
    public var description: String {
        """
        Photo(id: \(id), \
        type: \(mediaType.localizedName), \
        size: \(formattedFileSize), \
        resolution: \(resolution))
        """
    }
}

// MARK: - Photo + Comparable

extension Photo: Comparable {
    /// 作成日時で比較（新しい順）
    public static func < (lhs: Photo, rhs: Photo) -> Bool {
        lhs.creationDate > rhs.creationDate
    }
}
