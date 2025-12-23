//
//  PhotoGrouper.swift
//  LightRoll_CleanerFeature
//
//  写真グルーピングサービス - 6種類のグルーピングロジックを統合
//  類似写真、セルフィー、スクリーンショット、ブレ、大容量動画、重複を検出
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - PhotoGrouper

/// 写真グルーピングサービス
///
/// 主な責務:
/// - 類似写真グルーピング（SimilarityAnalyzer連携）
/// - セルフィーグルーピング（FaceDetector連携）
/// - スクリーンショットグルーピング（ScreenshotDetector連携）
/// - ブレ写真グルーピング（BlurDetector連携）
/// - 大容量動画グルーピング
/// - 重複写真グルーピング
/// - ScanSettingsに基づくフィルタリング（BUG-002対応）
/// - バッチ処理と進捗通知
public actor PhotoGrouper {

    // MARK: - Properties

    /// 類似度分析器
    private let similarityAnalyzer: SimilarityAnalyzer

    /// 顔検出器
    private let faceDetector: FaceDetector

    /// ブレ検出器
    private let blurDetector: BlurDetector

    /// スクリーンショット検出器
    private let screenshotDetector: ScreenshotDetector

    /// グルーピングオプション
    private let options: GroupingOptions

    /// 写真フィルタリングサービス（BUG-002対応）
    private let photoFilteringService: PhotoFilteringService

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - similarityAnalyzer: 類似度分析器（省略時は新規作成）
    ///   - faceDetector: 顔検出器（省略時は新規作成）
    ///   - blurDetector: ブレ検出器（省略時は新規作成）
    ///   - screenshotDetector: スクリーンショット検出器（省略時は新規作成）
    ///   - photoFilteringService: 写真フィルタリングサービス（省略時は新規作成）
    ///   - options: グルーピングオプション
    public init(
        similarityAnalyzer: SimilarityAnalyzer? = nil,
        faceDetector: FaceDetector? = nil,
        blurDetector: BlurDetector? = nil,
        screenshotDetector: ScreenshotDetector? = nil,
        photoFilteringService: PhotoFilteringService? = nil,
        options: GroupingOptions = .default
    ) {
        self.similarityAnalyzer = similarityAnalyzer ?? SimilarityAnalyzer()
        self.faceDetector = faceDetector ?? FaceDetector()
        self.blurDetector = blurDetector ?? BlurDetector()
        self.screenshotDetector = screenshotDetector ?? ScreenshotDetector()
        self.photoFilteringService = photoFilteringService ?? PhotoFilteringService()
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset配列から全種類のグルーピングを実行
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出されたグループ配列
    /// - Throws: AnalysisError
    public func groupPhotos(
        _ assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        guard !assets.isEmpty else {
            return []
        }

        var allGroups: [PhotoGroup] = []

        // フェーズ1: 重複検出（進捗 0.0〜0.1）
        if options.includeScreenshots {
            await progress?(0.0)
            let duplicates = try await groupDuplicates(assets)
            allGroups.append(contentsOf: duplicates)
            await progress?(0.1)
        }

        // フェーズ2: 類似写真グルーピング（進捗 0.1〜0.4）
        let similarGroups = try await groupSimilarPhotos(
            assets,
            progressRange: (0.1, 0.4),
            progress: progress
        )
        allGroups.append(contentsOf: similarGroups)

        // フェーズ3: セルフィーグルーピング（進捗 0.4〜0.6）
        if options.includeSelfies {
            let selfieGroups = try await groupSelfies(
                assets,
                progressRange: (0.4, 0.6),
                progress: progress
            )
            allGroups.append(contentsOf: selfieGroups)
        }

        // フェーズ4: スクリーンショットグルーピング（進捗 0.6〜0.7）
        if options.includeScreenshots {
            let screenshotGroups = try await groupScreenshots(
                assets,
                progressRange: (0.6, 0.7),
                progress: progress
            )
            allGroups.append(contentsOf: screenshotGroups)
        }

        // フェーズ5: ブレ写真グルーピング（進捗 0.7〜0.9）
        if options.includeBlurry {
            let blurryGroups = try await groupBlurryPhotos(
                assets,
                progressRange: (0.7, 0.9),
                progress: progress
            )
            allGroups.append(contentsOf: blurryGroups)
        }

        // フェーズ6: 大容量動画グルーピング（進捗 0.9〜1.0）
        if options.includeLargeVideos {
            let largeVideoGroups = try await groupLargeVideos(
                assets,
                progressRange: (0.9, 1.0),
                progress: progress
            )
            allGroups.append(contentsOf: largeVideoGroups)
        }

        await progress?(1.0)

        // 最小グループサイズ以上のグループのみをフィルタ
        let validGroups = allGroups.filter { $0.isValid }

        return validGroups
    }

    /// Photo配列から全種類のグルーピングを実行（便利メソッド）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出されたグループ配列
    /// - Throws: AnalysisError
    public func groupPhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        let assets = try await fetchPHAssets(from: photos)
        return try await groupPhotos(assets, progress: progress)
    }

    /// PHAsset配列から全種類のグルーピングを実行（ScanSettings対応版）
    ///
    /// ScanSettingsに基づいてフィルタリングを行った後、グルーピングを実行します。
    /// これにより、includeVideos/includeScreenshots/includeSelfiesの設定が
    /// グルーピング処理に正しく反映されます。
    ///
    /// BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - scanSettings: スキャン設定（フィルタリングに使用）
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出されたグループ配列
    /// - Throws: AnalysisError
    public func groupPhotos(
        _ assets: [PHAsset],
        scanSettings: ScanSettings,
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // ScanSettingsに基づいてフィルタリング
        let filteredAssets = photoFilteringService.filter(assets: assets, with: scanSettings)

        logInfo("📋 PhotoGrouper: ScanSettingsフィルタリング \(assets.count)枚 → \(filteredAssets.count)枚", category: .analysis)

        // フィルタリング後のアセットでグルーピングを実行
        return try await groupPhotos(filteredAssets, progress: progress)
    }

    /// Photo配列から全種類のグルーピングを実行（ScanSettings対応版）
    ///
    /// ScanSettingsに基づいてフィルタリングを行った後、グルーピングを実行します。
    ///
    /// BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - scanSettings: スキャン設定（フィルタリングに使用）
    ///   - progress: 進捗コールバック
    /// - Returns: 検出されたグループ配列
    /// - Throws: AnalysisError
    public func groupPhotos(
        _ photos: [Photo],
        scanSettings: ScanSettings,
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // ScanSettingsに基づいてフィルタリング
        let filteredPhotos = photoFilteringService.filter(photos: photos, with: scanSettings)

        logInfo("📋 PhotoGrouper: ScanSettingsフィルタリング \(photos.count)枚 → \(filteredPhotos.count)枚", category: .analysis)

        // フィルタリング後の写真でグルーピングを実行
        let assets = try await fetchPHAssets(from: filteredPhotos)
        return try await groupPhotos(assets, progress: progress)
    }

    // MARK: - Individual Grouping Methods

    /// 類似写真グルーピング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲（start, end）
    ///   - progress: 進捗コールバック
    /// - Returns: 類似写真グループ配列
    /// - Throws: AnalysisError
    public func groupSimilarPhotos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double) = (0.0, 1.0),
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 画像のみフィルタ
        let imageAssets = assets.filter { $0.mediaType == .image }
        guard !imageAssets.isEmpty else {
            return []
        }

        // 進捗を範囲内に調整
        let adjustedProgress: (@Sendable (Double) async -> Void)? = { p in
            let adjusted = progressRange.start + (progressRange.end - progressRange.start) * p
            await progress?(adjusted)
        }

        // PHAsset を Photo に変換（TimeBasedGrouper最適化版を使用するため）
        // Note: toPhotoWithoutFileSize() は高速な同期変換（ファイルサイズ不要のため）
        let photos = imageAssets.map { $0.toPhotoWithoutFileSize() }

        // SimilarityAnalyzerで類似グループを検出（TimeBasedGrouper統合版）
        // O(n²) → O(n×k) に最適化、比較回数99%削減
        let similarGroups = try await similarityAnalyzer.findSimilarGroups(
            in: photos,
            progress: adjustedProgress
        )

        // PhotoGroup形式に変換
        var photoGroups: [PhotoGroup] = []
        for similarGroup in similarGroups {
            // ファイルサイズを取得
            let fileSizes = try await getFileSizes(for: similarGroup.photoIds, from: imageAssets)

            let photoGroup = PhotoGroup(
                type: .similar,
                photoIds: similarGroup.photoIds,
                fileSizes: fileSizes,
                similarityScore: similarGroup.averageSimilarity
            )

            photoGroups.append(photoGroup)
        }

        return photoGroups
    }

    /// セルフィーグルーピング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲（start, end）
    ///   - progress: 進捗コールバック
    /// - Returns: セルフィーグループ配列
    /// - Throws: AnalysisError
    public func groupSelfies(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double) = (0.0, 1.0),
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 画像のみフィルタ
        let imageAssets = assets.filter { $0.mediaType == .image }
        guard !imageAssets.isEmpty else {
            return []
        }

        // 進捗を範囲内に調整
        let adjustedProgress: (@Sendable (Double) async -> Void)? = { p in
            let adjusted = progressRange.start + (progressRange.end - progressRange.start) * p
            await progress?(adjusted)
        }

        // FaceDetectorでセルフィーを検出
        let faceResults = try await faceDetector.detectFaces(
            in: imageAssets,
            progress: adjustedProgress
        )

        // セルフィーのみ抽出
        let selfies = faceResults.filter { $0.isSelfie }

        guard !selfies.isEmpty else {
            return []
        }

        // セルフィーをグループ化
        let selfieIds = selfies.map { $0.photoId }
        let fileSizes = try await getFileSizes(for: selfieIds, from: imageAssets)

        let photoGroup = PhotoGroup(
            type: .selfie,
            photoIds: selfieIds,
            fileSizes: fileSizes
        )

        return [photoGroup]
    }

    /// スクリーンショットグルーピング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲（start, end）
    ///   - progress: 進捗コールバック
    /// - Returns: スクリーンショットグループ配列
    /// - Throws: AnalysisError
    public func groupScreenshots(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double) = (0.0, 1.0),
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 画像のみフィルタ
        let imageAssets = assets.filter { $0.mediaType == .image }
        guard !imageAssets.isEmpty else {
            return []
        }

        // 進捗を範囲内に調整（同期版）
        let adjustedProgress: (@Sendable (Double) -> Void)?
        if let progress = progress {
            adjustedProgress = { @Sendable (p: Double) in
                let adjusted = progressRange.start + (progressRange.end - progressRange.start) * p
                Task {
                    await progress(adjusted)
                }
            }
        } else {
            adjustedProgress = nil
        }

        // ScreenshotDetectorでスクリーンショットを検出
        let screenshotResults = try await screenshotDetector.detectScreenshots(
            in: imageAssets,
            progress: adjustedProgress
        )

        // スクリーンショットのみ抽出
        let screenshots = screenshotResults.filter { $0.isScreenshot }

        guard !screenshots.isEmpty else {
            return []
        }

        // スクリーンショットをグループ化
        let screenshotIds = screenshots.map { $0.assetIdentifier }
        let fileSizes = try await getFileSizes(for: screenshotIds, from: imageAssets)

        let photoGroup = PhotoGroup(
            type: .screenshot,
            photoIds: screenshotIds,
            fileSizes: fileSizes
        )

        return [photoGroup]
    }

    /// ブレ写真グルーピング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲（start, end）
    ///   - progress: 進捗コールバック
    /// - Returns: ブレ写真グループ配列
    /// - Throws: AnalysisError
    public func groupBlurryPhotos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double) = (0.0, 1.0),
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 画像のみフィルタ
        let imageAssets = assets.filter { $0.mediaType == .image }
        guard !imageAssets.isEmpty else {
            return []
        }

        // 進捗を範囲内に調整
        let adjustedProgress: (@Sendable (Double) async -> Void)? = { p in
            let adjusted = progressRange.start + (progressRange.end - progressRange.start) * p
            await progress?(adjusted)
        }

        // BlurDetectorでブレを検出
        let blurResults = try await blurDetector.detectBlur(
            in: imageAssets,
            progress: adjustedProgress
        )

        // ブレ写真のみ抽出
        let blurryPhotos = blurResults.filter { $0.isBlurry }

        guard !blurryPhotos.isEmpty else {
            return []
        }

        // ブレ写真をグループ化
        let blurryIds = blurryPhotos.map { $0.photoId }
        let fileSizes = try await getFileSizes(for: blurryIds, from: imageAssets)

        let photoGroup = PhotoGroup(
            type: .blurry,
            photoIds: blurryIds,
            fileSizes: fileSizes
        )

        return [photoGroup]
    }

    /// 大容量動画グルーピング
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲（start, end）
    ///   - progress: 進捗コールバック
    /// - Returns: 大容量動画グループ配列
    /// - Throws: AnalysisError
    public func groupLargeVideos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double) = (0.0, 1.0),
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 動画のみフィルタ
        let videoAssets = assets.filter { $0.mediaType == .video }
        guard !videoAssets.isEmpty else {
            return []
        }

        await progress?(progressRange.start)

        var largeVideoData: [(id: String, size: Int64)] = []

        // 各動画のファイルサイズをチェック
        for (index, asset) in videoAssets.enumerated() {
            let fileSize = try await asset.getFileSize()

            // 閾値以上の動画を抽出
            if fileSize >= options.largeVideoThreshold {
                largeVideoData.append((id: asset.localIdentifier, size: fileSize))
            }

            // 進捗通知
            let currentProgress = progressRange.start +
                (progressRange.end - progressRange.start) * Double(index + 1) / Double(videoAssets.count)
            await progress?(currentProgress)

            // キャンセルチェック
            try Task.checkCancellation()
        }

        guard !largeVideoData.isEmpty else {
            return []
        }

        // 大容量動画をグループ化
        let photoGroup = PhotoGroup(
            type: .largeVideo,
            photoIds: largeVideoData.map { $0.id },
            fileSizes: largeVideoData.map { $0.size }
        )

        return [photoGroup]
    }

    /// 重複写真グルーピング
    ///
    /// - Parameter assets: 対象のPHAsset配列
    /// - Returns: 重複写真グループ配列
    /// - Throws: AnalysisError
    public func groupDuplicates(
        _ assets: [PHAsset]
    ) async throws -> [PhotoGroup] {
        // 画像のみフィルタ
        let imageAssets = assets.filter { $0.mediaType == .image }
        guard imageAssets.count >= 2 else {
            return []
        }

        // ファイルサイズとピクセルサイズでグルーピング
        var sizeGroups: [String: [PHAsset]] = [:]

        for asset in imageAssets {
            let fileSize = try await asset.getFileSize()

            // ファイルサイズ + ピクセルサイズをキーとする
            let keyString = "\(fileSize)_\(asset.pixelWidth)_\(asset.pixelHeight)"

            if sizeGroups[keyString] == nil {
                sizeGroups[keyString] = []
            }
            sizeGroups[keyString]?.append(asset)

            // キャンセルチェック
            try Task.checkCancellation()
        }

        // 2枚以上のグループのみ抽出
        var duplicateGroups: [PhotoGroup] = []

        for (_, assetsInGroup) in sizeGroups {
            guard assetsInGroup.count >= 2 else {
                continue
            }

            let photoIds = assetsInGroup.map { $0.localIdentifier }
            let fileSizes = try await getFileSizes(for: photoIds, from: assetsInGroup)

            let photoGroup = PhotoGroup(
                type: .duplicate,
                photoIds: photoIds,
                fileSizes: fileSizes,
                similarityScore: 1.0 // 完全一致
            )

            duplicateGroups.append(photoGroup)
        }

        return duplicateGroups
    }

    // MARK: - Helper Methods

    /// Photo配列からPHAssetを取得
    ///
    /// - Parameter photos: Photo配列
    /// - Returns: PHAsset配列
    /// - Throws: AnalysisError
    private func fetchPHAssets(from photos: [Photo]) async throws -> [PHAsset] {
        let identifiers = photos.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets: [PHAsset] = []
        assets.reserveCapacity(identifiers.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    /// 指定されたIDのアセットのファイルサイズを取得
    ///
    /// - Parameters:
    ///   - photoIds: 写真ID配列
    ///   - assets: PHAsset配列
    /// - Returns: ファイルサイズ配列（photoIds と同じ順序）
    /// - Throws: AnalysisError
    private func getFileSizes(
        for photoIds: [String],
        from assets: [PHAsset]
    ) async throws -> [Int64] {
        // O(m)で事前にDictionary構築（線形探索O(n×m)を回避）
        let assetLookup = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0) })

        // TaskGroupで並列にファイルサイズを取得
        return try await withThrowingTaskGroup(of: (Int, Int64).self) { group in
            for (index, photoId) in photoIds.enumerated() {
                group.addTask { @Sendable in
                    let size = try await assetLookup[photoId]?.getFileSize() ?? 0
                    return (index, size)
                }
            }
            var results = [(Int, Int64)]()
            results.reserveCapacity(photoIds.count)
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}

// MARK: - PhotoGrouperProtocol

/// PhotoGrouper のプロトコル（テスタビリティ用）
public protocol PhotoGrouperProtocol: Actor {
    /// PHAsset配列から全種類のグルーピングを実行
    func groupPhotos(
        _ assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// Photo配列から全種類のグルーピングを実行
    func groupPhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// 類似写真グルーピング
    func groupSimilarPhotos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// セルフィーグルーピング
    func groupSelfies(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// スクリーンショットグルーピング
    func groupScreenshots(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// ブレ写真グルーピング
    func groupBlurryPhotos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// 大容量動画グルーピング
    func groupLargeVideos(
        _ assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// 重複写真グルーピング
    func groupDuplicates(
        _ assets: [PHAsset]
    ) async throws -> [PhotoGroup]
}

// MARK: - PhotoGrouper + PhotoGrouperProtocol

extension PhotoGrouper: PhotoGrouperProtocol {}
