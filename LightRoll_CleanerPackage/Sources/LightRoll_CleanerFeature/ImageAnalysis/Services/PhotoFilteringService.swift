//
//  PhotoFilteringService.swift
//  LightRoll_CleanerFeature
//
//  ScanSettingsに基づいて写真をフィルタリングするサービス
//  BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
//  Created by AI Assistant on 2025-12-23.
//
//  Phase 2強化 (2025-12-24):
//  - OSLogによるロギング追加
//  - バリデーションロジック強化
//  - エラーハンドリング改善
//  - PhotoFilteringError型追加
//

import Foundation
import Photos
import os.log

/// PhotoFilteringService用ロガー
private let filteringLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.lightroll.cleaner",
    category: "PhotoFiltering"
)

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

// MARK: - PhotoFilteringError

/// 写真フィルタリングエラー
public enum PhotoFilteringError: LocalizedError, Sendable, Equatable {
    /// 設定が無効（すべてのコンテンツタイプが無効）
    case invalidSettings(reason: String)
    /// 入力データが無効
    case invalidInput(reason: String)
    /// フィルタリング処理失敗
    case filteringFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidSettings(let reason):
            return "設定エラー: \(reason)"
        case .invalidInput(let reason):
            return "入力エラー: \(reason)"
        case .filteringFailed(let reason):
            return "フィルタリングエラー: \(reason)"
        }
    }
}

// MARK: - ValidatedPhotoFilteringResult

/// バリデーション付きフィルタリング結果
public struct ValidatedPhotoFilteringResult: Sendable, Equatable {
    /// フィルタリング成功フラグ
    public let success: Bool
    /// フィルタリング結果（成功時のみ）
    public let result: PhotoFilteringResult?
    /// エラー情報（失敗時のみ）
    public let error: PhotoFilteringError?
    /// バリデーション警告（設定に問題がある場合）
    public let warnings: [String]

    // MARK: - Factory Methods

    /// 成功結果を生成
    public static func success(
        result: PhotoFilteringResult,
        warnings: [String] = []
    ) -> ValidatedPhotoFilteringResult {
        ValidatedPhotoFilteringResult(
            success: true,
            result: result,
            error: nil,
            warnings: warnings
        )
    }

    /// 失敗結果を生成
    public static func failure(
        error: PhotoFilteringError
    ) -> ValidatedPhotoFilteringResult {
        ValidatedPhotoFilteringResult(
            success: false,
            result: nil,
            error: error,
            warnings: []
        )
    }
}

// MARK: - PhotoFilteringService + Validation Extension

extension PhotoFilteringService {

    /// ScanSettingsのバリデーション
    ///
    /// - Parameter scanSettings: バリデーション対象の設定
    /// - Returns: バリデーション結果（成功: nil、失敗: エラー）
    public func validateSettings(_ scanSettings: ScanSettings) -> PhotoFilteringError? {
        // 少なくとも1つのコンテンツタイプが有効であることを確認
        guard scanSettings.hasAnyContentTypeEnabled else {
            filteringLogger.error("バリデーション失敗: すべてのコンテンツタイプが無効")
            return .invalidSettings(reason: "少なくとも1つのコンテンツタイプを有効にしてください")
        }

        filteringLogger.debug("バリデーション成功: videos=\(scanSettings.includeVideos), screenshots=\(scanSettings.includeScreenshots), selfies=\(scanSettings.includeSelfies)")
        return nil
    }

    /// バリデーション付きでフィルタリングを実行
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - scanSettings: スキャン設定
    /// - Returns: バリデーション付きフィルタリング結果
    public func filterWithValidation(
        photos: [Photo],
        with scanSettings: ScanSettings
    ) -> ValidatedPhotoFilteringResult {
        filteringLogger.info("バリデーション付きフィルタリング開始: 入力=\(photos.count)枚")

        // 設定バリデーション
        if let error = validateSettings(scanSettings) {
            filteringLogger.error("フィルタリング中止: 設定バリデーション失敗")
            return .failure(error: error)
        }

        // 警告チェック
        var warnings: [String] = []

        // すべてのフィルタが有効な場合は警告
        if scanSettings.includeVideos && scanSettings.includeScreenshots && scanSettings.includeSelfies {
            filteringLogger.debug("すべてのコンテンツタイプが有効: フィルタリングなし")
        }

        // フィルタリング実行
        let result = filterWithStats(photos: photos, with: scanSettings)

        // 結果が空の場合の警告
        if result.filteredCount == 0 && result.originalCount > 0 {
            let warningMessage = "すべての写真がフィルタリングで除外されました（\(result.originalCount)枚）"
            warnings.append(warningMessage)
            filteringLogger.warning("\(warningMessage, privacy: .public)")
        }

        filteringLogger.info("フィルタリング完了: \(result.filteredCount)/\(result.originalCount)枚 (\(result.formattedFilteringRate, privacy: .public))")

        return .success(result: result, warnings: warnings)
    }

    /// バリデーション付きでPHAssetフィルタリングを実行
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング結果（エラー時はthrow）
    public func filterAssetsWithValidation(
        assets: [PHAsset],
        with scanSettings: ScanSettings
    ) throws -> [PHAsset] {
        filteringLogger.info("PHAssetバリデーション付きフィルタリング開始: 入力=\(assets.count)枚")

        // 設定バリデーション
        if let error = validateSettings(scanSettings) {
            filteringLogger.error("PHAssetフィルタリング中止: \(error.errorDescription ?? "不明なエラー", privacy: .public)")
            throw error
        }

        // フィルタリング実行
        let filteredAssets = filter(assets: assets, with: scanSettings)

        filteringLogger.info("PHAssetフィルタリング完了: \(filteredAssets.count)/\(assets.count)枚")

        return filteredAssets
    }

    /// バリデーション付きで分析結果付きフィルタリングを実行
    ///
    /// - Parameters:
    ///   - photosWithResults: (Photo, PhotoAnalysisResult?)のペア配列
    ///   - scanSettings: スキャン設定
    /// - Returns: フィルタリング結果（エラー時はthrow）
    public func filterWithAnalysisResultsValidated(
        photosWithResults: [(photo: Photo, result: PhotoAnalysisResult?)],
        with scanSettings: ScanSettings
    ) throws -> [(photo: Photo, result: PhotoAnalysisResult?)] {
        filteringLogger.info("分析結果付きバリデーションフィルタリング開始: 入力=\(photosWithResults.count)枚")

        // 設定バリデーション
        if let error = validateSettings(scanSettings) {
            filteringLogger.error("分析結果付きフィルタリング中止: \(error.errorDescription ?? "不明なエラー", privacy: .public)")
            throw error
        }

        // フィルタリング実行
        let filteredResults = filterWithAnalysisResults(
            photosWithResults: photosWithResults,
            with: scanSettings
        )

        // 警告ログ
        if filteredResults.isEmpty && !photosWithResults.isEmpty {
            filteringLogger.warning("すべての写真がフィルタリングで除外されました: \(photosWithResults.count)枚")
        }

        filteringLogger.info("分析結果付きフィルタリング完了: \(filteredResults.count)/\(photosWithResults.count)枚")

        return filteredResults
    }
}
