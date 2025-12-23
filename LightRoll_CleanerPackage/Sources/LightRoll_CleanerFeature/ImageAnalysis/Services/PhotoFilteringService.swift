//
//  PhotoFilteringService.swift
//  LightRoll_CleanerFeature
//
//  ScanSettingsに基づいて写真をフィルタリングするサービス
//  BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
//  Created by AI Assistant on 2025-12-23.
//

import Foundation
import Photos

// MARK: - PhotoFilteringService

/// ScanSettingsに基づいて写真をフィルタリングするサービス
///
/// 主な責務:
/// - ScanSettings（includeVideos, includeScreenshots, includeSelfies）に基づくフィルタリング
/// - Photo配列のフィルタリング
/// - PHAsset配列のフィルタリング
/// - フィルタリング統計の提供
///
/// ## 使用例
/// ```swift
/// let filteringService = PhotoFilteringService()
/// let scanSettings = ScanSettings(includeVideos: true, includeScreenshots: false, includeSelfies: true)
/// let filteredPhotos = filteringService.filter(photos: photos, with: scanSettings)
/// ```
public struct PhotoFilteringService: Sendable {

    // MARK: - Initialization

    /// イニシャライザ
    public init() {}

    // MARK: - Public Methods

    /// ScanSettingsに基づいてPhoto配列をフィルタリング
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング後のPhoto配列
    public func filter(
        photos: [Photo],
        with scanSettings: ScanSettings
    ) -> [Photo] {
        photos.filter { photo in
            shouldInclude(photo: photo, with: scanSettings)
        }
    }

    /// ScanSettingsに基づいてPhoto配列をフィルタリング（統計付き）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング結果（フィルタ後の写真と統計情報）
    public func filterWithStats(
        photos: [Photo],
        with scanSettings: ScanSettings
    ) -> PhotoFilteringResult {
        var includedPhotos: [Photo] = []
        var excludedVideoCount = 0
        var excludedScreenshotCount = 0
        // Note: selfieの判定はPhotoモデルにはないため、
        // 分析結果が必要な場合は別途処理が必要

        for photo in photos {
            if shouldInclude(photo: photo, with: scanSettings) {
                includedPhotos.append(photo)
            } else {
                // 除外理由をカウント
                if photo.isVideo && !scanSettings.includeVideos {
                    excludedVideoCount += 1
                }
                if photo.isScreenshot && !scanSettings.includeScreenshots {
                    excludedScreenshotCount += 1
                }
            }
        }

        return PhotoFilteringResult(
            filteredPhotos: includedPhotos,
            originalCount: photos.count,
            excludedVideoCount: excludedVideoCount,
            excludedScreenshotCount: excludedScreenshotCount,
            excludedSelfieCount: 0 // PhotoモデルにはisSelfieがないため0
        )
    }

    /// ScanSettingsに基づいてPHAsset配列をフィルタリング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング後のPHAsset配列
    public func filter(
        assets: [PHAsset],
        with scanSettings: ScanSettings
    ) -> [PHAsset] {
        assets.filter { asset in
            shouldInclude(asset: asset, with: scanSettings)
        }
    }

    /// ScanSettingsに基づいてPhotoとPhotoAnalysisResultのペアをフィルタリング
    ///
    /// selfieのフィルタリングには分析結果が必要なため、
    /// 分析済みの写真をフィルタリングする場合はこのメソッドを使用
    ///
    /// - Parameters:
    ///   - photosWithResults: (Photo, PhotoAnalysisResult?)のペア配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング後のペア配列
    public func filterWithAnalysisResults(
        photosWithResults: [(photo: Photo, result: PhotoAnalysisResult?)],
        with scanSettings: ScanSettings
    ) -> [(photo: Photo, result: PhotoAnalysisResult?)] {
        photosWithResults.filter { pair in
            shouldInclude(
                photo: pair.photo,
                analysisResult: pair.result,
                with: scanSettings
            )
        }
    }

    // MARK: - Private Methods

    /// 単一のPhotoをフィルタリング判定
    ///
    /// - Parameters:
    ///   - photo: 対象のPhoto
    ///   - scanSettings: スキャン設定
    /// - Returns: 含める場合はtrue
    private func shouldInclude(
        photo: Photo,
        with scanSettings: ScanSettings
    ) -> Bool {
        // 動画チェック
        if photo.isVideo && !scanSettings.includeVideos {
            return false
        }

        // スクリーンショットチェック
        if photo.isScreenshot && !scanSettings.includeScreenshots {
            return false
        }

        // Note: selfieはPhotoモデルにプロパティがないため、
        // ここではチェックできない。分析結果と合わせてチェックする場合は
        // shouldInclude(photo:analysisResult:with:)を使用

        return true
    }

    /// 単一のPhotoとPhotoAnalysisResultをフィルタリング判定
    ///
    /// - Parameters:
    ///   - photo: 対象のPhoto
    ///   - analysisResult: 分析結果（nil許容）
    ///   - scanSettings: スキャン設定
    /// - Returns: 含める場合はtrue
    private func shouldInclude(
        photo: Photo,
        analysisResult: PhotoAnalysisResult?,
        with scanSettings: ScanSettings
    ) -> Bool {
        // 動画チェック
        if photo.isVideo && !scanSettings.includeVideos {
            return false
        }

        // スクリーンショットチェック
        if photo.isScreenshot && !scanSettings.includeScreenshots {
            return false
        }

        // selfieチェック（分析結果がある場合のみ）
        if let result = analysisResult,
           result.isSelfie && !scanSettings.includeSelfies {
            return false
        }

        return true
    }

    /// 単一のPHAssetをフィルタリング判定
    ///
    /// - Parameters:
    ///   - asset: 対象のPHAsset
    ///   - scanSettings: スキャン設定
    /// - Returns: 含める場合はtrue
    private func shouldInclude(
        asset: PHAsset,
        with scanSettings: ScanSettings
    ) -> Bool {
        // 動画チェック
        if asset.mediaType == .video && !scanSettings.includeVideos {
            return false
        }

        // スクリーンショットチェック
        if asset.mediaSubtypes.contains(.photoScreenshot) && !scanSettings.includeScreenshots {
            return false
        }

        // Note: selfieはPHAssetのメタデータからは直接判定できない
        // 分析結果と合わせてチェックする必要がある

        return true
    }
}

// MARK: - PhotoFilteringResult

/// フィルタリング結果
public struct PhotoFilteringResult: Sendable, Equatable {

    /// フィルタリング後の写真配列
    public let filteredPhotos: [Photo]

    /// 元の写真数
    public let originalCount: Int

    /// 除外された動画数
    public let excludedVideoCount: Int

    /// 除外されたスクリーンショット数
    public let excludedScreenshotCount: Int

    /// 除外されたセルフィー数
    public let excludedSelfieCount: Int

    // MARK: - Computed Properties

    /// フィルタリング後の写真数
    public var filteredCount: Int {
        filteredPhotos.count
    }

    /// 除外された総数
    public var totalExcludedCount: Int {
        excludedVideoCount + excludedScreenshotCount + excludedSelfieCount
    }

    /// フィルタリング率（0.0〜1.0）
    public var filteringRate: Double {
        guard originalCount > 0 else { return 0.0 }
        return Double(filteredCount) / Double(originalCount)
    }

    /// フォーマット済みフィルタリング率
    public var formattedFilteringRate: String {
        String(format: "%.1f%%", filteringRate * 100)
    }

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        filteredPhotos: [Photo],
        originalCount: Int,
        excludedVideoCount: Int = 0,
        excludedScreenshotCount: Int = 0,
        excludedSelfieCount: Int = 0
    ) {
        self.filteredPhotos = filteredPhotos
        self.originalCount = originalCount
        self.excludedVideoCount = excludedVideoCount
        self.excludedScreenshotCount = excludedScreenshotCount
        self.excludedSelfieCount = excludedSelfieCount
    }
}

// MARK: - PhotoFilteringResult + CustomStringConvertible

extension PhotoFilteringResult: CustomStringConvertible {
    public var description: String {
        """
        PhotoFilteringResult(
            filtered: \(filteredCount)/\(originalCount) (\(formattedFilteringRate)),
            excluded: videos=\(excludedVideoCount), screenshots=\(excludedScreenshotCount), selfies=\(excludedSelfieCount)
        )
        """
    }
}
