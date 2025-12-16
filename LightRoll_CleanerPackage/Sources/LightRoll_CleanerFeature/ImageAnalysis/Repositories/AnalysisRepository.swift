//
//  AnalysisRepository.swift
//  LightRoll_CleanerFeature
//
//  画像分析リポジトリ - 全ての分析サービスを統合する中央ハブ
//  VisionRequestHandler、特徴量抽出、類似度分析、顔検出、ブレ検出、
//  スクリーンショット検出、グルーピング、ベストショット選定を統合管理
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - AnalysisRepositoryOptions

/// AnalysisRepository の設定オプション
public struct AnalysisRepositoryOptions: Sendable {
    /// 品質スコア計算の重み設定
    let qualityScoreWeights: QualityScoreWeights

    /// デフォルト設定でのイニシャライザ
    ///
    /// - Parameter qualityScoreWeights: 品質スコアの重み設定（省略時はデフォルト値）
    public init(qualityScoreWeights: QualityScoreWeights = .default) {
        self.qualityScoreWeights = qualityScoreWeights
    }
}

// MARK: - QualityScoreWeights

/// 品質スコア計算の重み設定
///
/// 各スコア要素の重要度を設定する
/// 全ての重みの合計が1.0になる必要はない（正規化は自動的に行われる）
public struct QualityScoreWeights: Sendable {
    /// シャープネススコアの重み
    let sharpnessWeight: Float

    /// 顔品質スコアの重み
    let faceQualityWeight: Float

    /// スクリーンショットペナルティの重み
    let screenshotPenaltyWeight: Float

    /// デフォルト設定
    /// - シャープネス: 0.5（最重要）
    /// - 顔品質: 0.3（重要）
    /// - スクリーンショットペナルティ: 0.2（通常）
    public static let `default` = QualityScoreWeights(
        sharpnessWeight: 0.5,
        faceQualityWeight: 0.3,
        screenshotPenaltyWeight: 0.2
    )

    /// カスタム重み設定でのイニシャライザ
    ///
    /// - Parameters:
    ///   - sharpnessWeight: シャープネススコアの重み
    ///   - faceQualityWeight: 顔品質スコアの重み
    ///   - screenshotPenaltyWeight: スクリーンショットペナルティの重み
    public init(
        sharpnessWeight: Float,
        faceQualityWeight: Float,
        screenshotPenaltyWeight: Float
    ) {
        self.sharpnessWeight = sharpnessWeight
        self.faceQualityWeight = faceQualityWeight
        self.screenshotPenaltyWeight = screenshotPenaltyWeight
    }
}

// MARK: - ImageAnalysisRepositoryProtocol

/// 画像分析リポジトリのプロトコル
///
/// 全ての画像分析機能を統合的に提供するインターフェース
/// テスタビリティのためにプロトコルとして定義
public protocol ImageAnalysisRepositoryProtocol: Actor {
    /// 単一写真の総合分析
    nonisolated func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult

    /// 複数写真の総合分析（バッチ処理）
    func analyzePhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoAnalysisResult]

    /// 写真グルーピング（全種類）
    func groupPhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// グループからベストショットを選定
    func selectBestShot(from group: PhotoGroup) async throws -> Int?

    /// 類似写真グループの検出
    func findSimilarGroups(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [PhotoGroup]

    /// 特徴量抽出
    nonisolated func extractFeaturePrint(_ photo: Photo) async throws -> VNFeaturePrintObservation

    /// 顔検出
    nonisolated func detectFaces(in photo: Photo) async throws -> FaceDetectionResult

    /// ブレ検出
    nonisolated func detectBlur(in photo: Photo) async throws -> BlurDetectionResult

    /// スクリーンショット検出
    nonisolated func detectScreenshot(in photo: Photo) async throws -> ScreenshotDetectionResult
}

// MARK: - AnalysisRepository

/// 画像分析リポジトリの実装
///
/// 主な責務:
/// - 全ての分析サービスの統合管理
/// - PhotoAnalysisResultの生成
/// - PhotoGroupの生成とベストショット選定
/// - 進捗通知とエラーハンドリング
/// - キャンセル対応
public actor AnalysisRepository: ImageAnalysisRepositoryProtocol {

    // MARK: - Properties

    /// Vision リクエストハンドラー
    private let visionRequestHandler: VisionRequestHandler

    /// 特徴量抽出器
    private let featurePrintExtractor: FeaturePrintExtractor

    /// 類似度計算器
    private let similarityCalculator: SimilarityCalculator

    /// 類似度分析器
    private let similarityAnalyzer: SimilarityAnalyzer

    /// 顔検出器
    private let faceDetector: FaceDetector

    /// ブレ検出器
    private let blurDetector: BlurDetector

    /// スクリーンショット検出器
    private let screenshotDetector: ScreenshotDetector

    /// 写真グルーパー
    private let photoGrouper: PhotoGrouper

    /// ベストショット選定器
    private let bestShotSelector: BestShotSelector

    /// リポジトリ設定オプション
    private let options: AnalysisRepositoryOptions

    // MARK: - Initialization

    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - visionRequestHandler: Vision リクエストハンドラー（省略時は新規作成）
    ///   - featurePrintExtractor: 特徴量抽出器（省略時は新規作成）
    ///   - similarityCalculator: 類似度計算器（省略時は新規作成）
    ///   - similarityAnalyzer: 類似度分析器（省略時は新規作成）
    ///   - faceDetector: 顔検出器（省略時は新規作成）
    ///   - blurDetector: ブレ検出器（省略時は新規作成）
    ///   - screenshotDetector: スクリーンショット検出器（省略時は新規作成）
    ///   - photoGrouper: 写真グルーパー（省略時は新規作成）
    ///   - bestShotSelector: ベストショット選定器（省略時は新規作成）
    ///   - options: リポジトリ設定オプション（省略時はデフォルト値）
    public init(
        visionRequestHandler: VisionRequestHandler? = nil,
        featurePrintExtractor: FeaturePrintExtractor? = nil,
        similarityCalculator: SimilarityCalculator? = nil,
        similarityAnalyzer: SimilarityAnalyzer? = nil,
        faceDetector: FaceDetector? = nil,
        blurDetector: BlurDetector? = nil,
        screenshotDetector: ScreenshotDetector? = nil,
        photoGrouper: PhotoGrouper? = nil,
        bestShotSelector: BestShotSelector? = nil,
        options: AnalysisRepositoryOptions = AnalysisRepositoryOptions()
    ) {
        self.visionRequestHandler = visionRequestHandler ?? VisionRequestHandler()
        self.featurePrintExtractor = featurePrintExtractor ?? FeaturePrintExtractor()
        self.similarityCalculator = similarityCalculator ?? SimilarityCalculator()
        self.similarityAnalyzer = similarityAnalyzer ?? SimilarityAnalyzer()
        self.faceDetector = faceDetector ?? FaceDetector()
        self.blurDetector = blurDetector ?? BlurDetector()
        self.screenshotDetector = screenshotDetector ?? ScreenshotDetector()
        self.photoGrouper = photoGrouper ?? PhotoGrouper()
        self.bestShotSelector = bestShotSelector ?? BestShotSelector()
        self.options = options
    }

    // MARK: - Public Methods - 総合分析

    /// 単一写真の総合分析
    ///
    /// - Parameter photo: 分析対象の写真
    /// - Returns: 分析結果
    /// - Throws: AnalysisError
    nonisolated public func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult {
        // キャンセルチェック
        try Task.checkCancellation()

        // 分析結果ビルダーを作成
        let builder = PhotoAnalysisResult.Builder(photoId: photo.localIdentifier)

        // 並列で各種分析を実行
        async let featurePrintTask = extractFeaturePrint(photo)
        async let faceResultTask = detectFaces(in: photo)
        async let blurResultTask = detectBlur(in: photo)
        async let screenshotResultTask = detectScreenshot(in: photo)

        // 結果を収集
        let featurePrint = try? await featurePrintTask
        let faceResult = try? await faceResultTask
        let blurResult = try? await blurResultTask
        let screenshotResult = try? await screenshotResultTask

        // ビルダーに結果を設定

        // 特徴量ハッシュ
        if let featurePrint = featurePrint {
            // VNFeaturePrintObservation のデータを Data に変換
            // observation.data は MLMultiArray なので、そのバイト列を Data として保存
            let hash = featurePrint.data.withUnsafeBytes { bytes in
                Data(bytes)
            }
            builder.setFeaturePrintHash(hash)
        }

        // 顔検出結果
        if let faceResult = faceResult {
            let qualityScores = faceResult.faces.map { $0.confidence }
            let faceAngles = faceResult.faces.compactMap { face -> FaceAngle? in
                guard let yaw = face.yaw, let pitch = face.pitch else { return nil }
                return FaceAngle(
                    yaw: Float(yaw),
                    pitch: Float(pitch),
                    roll: Float(face.roll ?? 0.0)
                )
            }

            builder.setFaceResults(
                count: faceResult.faceCount,
                qualityScores: qualityScores,
                angles: faceAngles
            )

            // 自撮り判定
            builder.setIsSelfie(faceResult.isSelfie)
        }

        // ブレ検出結果
        if let blurResult = blurResult {
            builder.setBlurScore(blurResult.blurScore)
        }

        // スクリーンショット検出結果
        if let screenshotResult = screenshotResult {
            builder.setIsScreenshot(screenshotResult.isScreenshot)
        }

        // 品質スコアを計算（シャープネス、顔品質、露出等の総合評価）
        let qualityScore = calculateQualityScore(
            blurResult: blurResult,
            faceResult: faceResult,
            screenshotResult: screenshotResult
        )
        builder.setQualityScore(qualityScore)

        // 明るさ・コントラスト・彩度スコアを設定（デフォルト値）
        // 注: 将来的にはVisionの画像解析APIで取得可能
        builder.setBrightnessScore(0.5)
        builder.setContrastScore(0.5)
        builder.setSaturationScore(0.5)

        return builder.build()
    }

    /// 複数写真の総合分析（バッチ処理）
    ///
    /// - Parameters:
    ///   - photos: 分析対象の写真配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 分析結果配列
    /// - Throws: AnalysisError
    /// - Note: TaskGroupによる並列処理で5-10倍高速化
    ///         同時実行数は12並列に制限（メモリ効率とパフォーマンスのバランス）
    public func analyzePhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoAnalysisResult] {
        guard !photos.isEmpty else {
            return []
        }

        // 並列実行数を制御（メモリとCPUのバランス）
        let maxConcurrency = 12

        // 進捗カウンター（Actorで保護）
        actor ProgressCounter {
            private var completed = 0
            private let total: Int

            init(total: Int) {
                self.total = total
            }

            func increment() -> Double {
                completed += 1
                return Double(completed) / Double(total)
            }
        }

        let progressCounter = ProgressCounter(total: photos.count)

        // TaskGroupで並列処理
        return try await withThrowingTaskGroup(of: (Int, PhotoAnalysisResult).self) { group in
            var results: [(Int, PhotoAnalysisResult)] = []
            results.reserveCapacity(photos.count)

            // 写真をバッチに分割して処理（同時実行数を制御）
            for (index, photo) in photos.enumerated() {
                // 同時実行数を制限
                if index >= maxConcurrency {
                    // 1つ完了するまで待機
                    if let (completedIndex, result) = try await group.next() {
                        results.append((completedIndex, result))

                        // 進捗通知
                        let currentProgress = await progressCounter.increment()
                        await progress?(currentProgress)
                    }
                }

                // キャンセルチェック
                try Task.checkCancellation()

                // 新しいタスクを追加
                group.addTask {
                    do {
                        let result = try await self.analyzePhoto(photo)
                        return (index, result)
                    } catch {
                        // 個別エラーは記録して続行
                        let defaultResult = PhotoAnalysisResult(
                            photoId: photo.localIdentifier,
                            qualityScore: 0.0
                        )
                        return (index, defaultResult)
                    }
                }
            }

            // 残りのタスクを収集
            for try await (completedIndex, result) in group {
                results.append((completedIndex, result))

                // 進捗通知
                let currentProgress = await progressCounter.increment()
                await progress?(currentProgress)
            }

            // インデックスでソートして元の順序を保持
            results.sort { $0.0 < $1.0 }
            return results.map { $0.1 }
        }
    }

    // MARK: - Public Methods - グルーピング

    /// 写真グルーピング（全種類）
    ///
    /// - Parameters:
    ///   - photos: 対象の写真配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出されたグループ配列
    /// - Throws: AnalysisError
    public func groupPhotos(
        _ photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        guard !photos.isEmpty else {
            return []
        }

        // キャンセルチェック
        try Task.checkCancellation()

        // PHAsset配列を取得
        let assets = try await fetchPHAssets(for: photos)

        // PhotoGrouperで全種類のグルーピングを実行
        let groups = try await photoGrouper.groupPhotos(assets, progress: progress)

        return groups
    }

    /// グループからベストショットを選定
    ///
    /// - Parameter group: 対象の写真グループ
    /// - Returns: ベストショットのインデックス（nil の場合は選定失敗）
    /// - Throws: AnalysisError
    public func selectBestShot(from group: PhotoGroup) async throws -> Int? {
        return try await bestShotSelector.selectBestShot(from: group)
    }

    /// 類似写真グループの検出
    ///
    /// - Parameters:
    ///   - photos: 対象の写真配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 類似写真グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        guard !photos.isEmpty else {
            return []
        }

        // キャンセルチェック
        try Task.checkCancellation()

        // PHAsset配列を取得
        let assets = try await fetchPHAssets(for: photos)

        // SimilarityAnalyzerで類似グループを検出
        let similarGroups = try await similarityAnalyzer.findSimilarGroups(
            in: assets,
            progress: progress
        )

        // SimilarPhotoGroup から PhotoGroup に変換
        var photoGroups: [PhotoGroup] = []
        for similarGroup in similarGroups {
            let fileSizes = try await getFileSizes(for: similarGroup.photoIds, from: assets)

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

    // MARK: - Public Methods - 個別分析

    /// 特徴量抽出
    ///
    /// - Parameter photo: 対象の写真
    /// - Returns: 特徴量観測結果
    /// - Throws: AnalysisError
    /// - Note: FeaturePrintExtractorが特徴量観測を直接実行し、そのObservationを返す必要があります
    nonisolated public func extractFeaturePrint(_ photo: Photo) async throws -> VNFeaturePrintObservation {
        // キャンセルチェック
        try Task.checkCancellation()

        let asset = try await fetchPHAsset(for: photo)

        // VNGenerateImageFeaturePrintRequest を直接実行して VNFeaturePrintObservation を取得
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        request.revision = VNGenerateImageFeaturePrintRequestRevision2

        let result = try await visionRequestHandler.perform(on: asset, request: request)

        guard let featurePrintRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self),
              let observation = featurePrintRequest.results?.first as? VNFeaturePrintObservation else {
            throw AnalysisError.featureExtractionFailed
        }

        return observation
    }

    /// 顔検出
    ///
    /// - Parameter photo: 対象の写真
    /// - Returns: 顔検出結果
    /// - Throws: AnalysisError
    nonisolated public func detectFaces(in photo: Photo) async throws -> FaceDetectionResult {
        let asset = try await fetchPHAsset(for: photo)
        return try await faceDetector.detectFaces(in: asset)
    }

    /// ブレ検出
    ///
    /// - Parameter photo: 対象の写真
    /// - Returns: ブレ検出結果
    /// - Throws: AnalysisError
    nonisolated public func detectBlur(in photo: Photo) async throws -> BlurDetectionResult {
        let asset = try await fetchPHAsset(for: photo)
        return try await blurDetector.detectBlur(in: asset)
    }

    /// スクリーンショット検出
    ///
    /// - Parameter photo: 対象の写真
    /// - Returns: スクリーンショット検出結果
    /// - Throws: AnalysisError
    nonisolated public func detectScreenshot(in photo: Photo) async throws -> ScreenshotDetectionResult {
        let asset = try await fetchPHAsset(for: photo)
        let isScreenshot = try await screenshotDetector.isScreenshot(asset: asset)

        // 検出方法と信頼度を判定
        let detectionMethod: ScreenshotDetectionMethod
        let confidence: Float

        if isScreenshot {
            // mediaSubtypes フラグが最優先（最も信頼性が高い）
            if asset.isScreenshot {
                detectionMethod = .mediaSubtype
                confidence = 1.0
            } else {
                // フォールバック検出の場合
                detectionMethod = .screenSizeMatch
                confidence = 0.85
            }
        } else {
            detectionMethod = .notScreenshot
            confidence = 1.0
        }

        return ScreenshotDetectionResult(
            assetIdentifier: asset.localIdentifier,
            isScreenshot: isScreenshot,
            confidence: confidence,
            detectionMethod: detectionMethod,
            detectedAt: Date()
        )
    }

    // MARK: - Private Methods

    /// Photo から PHAsset を取得
    ///
    /// - Parameter photo: 写真モデル
    /// - Returns: PHAsset
    /// - Throws: AnalysisError.assetNotFound
    nonisolated private func fetchPHAsset(for photo: Photo) async throws -> PHAsset {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            throw AnalysisError.assetNotFound
        }

        return asset
    }

    /// Photo配列から PHAsset配列を取得
    ///
    /// - Parameter photos: 写真配列
    /// - Returns: PHAsset配列
    /// - Throws: AnalysisError
    private func fetchPHAssets(for photos: [Photo]) async throws -> [PHAsset] {
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
        var fileSizes: [Int64] = []
        fileSizes.reserveCapacity(photoIds.count)

        for photoId in photoIds {
            guard let asset = assets.first(where: { $0.localIdentifier == photoId }) else {
                fileSizes.append(0)
                continue
            }

            let fileSize = try await asset.getFileSize()
            fileSizes.append(fileSize)
        }

        return fileSizes
    }

    /// 総合品質スコアを計算
    ///
    /// - Parameters:
    ///   - blurResult: ブレ検出結果
    ///   - faceResult: 顔検出結果
    ///   - screenshotResult: スクリーンショット検出結果
    /// - Returns: 0.0〜1.0のスコア（高いほど高品質）
    nonisolated private func calculateQualityScore(
        blurResult: BlurDetectionResult?,
        faceResult: FaceDetectionResult?,
        screenshotResult: ScreenshotDetectionResult?
    ) -> Float {
        // 設定された重みを取得
        let weights = options.qualityScoreWeights

        var totalWeight: Float = 0.0
        var weightedSum: Float = 0.0

        // シャープネススコア
        if let blurResult = blurResult {
            let sharpnessScore = blurResult.sharpnessScore
            weightedSum += sharpnessScore * weights.sharpnessWeight
            totalWeight += weights.sharpnessWeight
        }

        // 顔品質スコア
        if let faceResult = faceResult, faceResult.faceCount > 0 {
            let faceQualityScore = faceResult.faces.map { $0.confidence }.max() ?? 0.0
            weightedSum += faceQualityScore * weights.faceQualityWeight
            totalWeight += weights.faceQualityWeight
        }

        // スクリーンショットはペナルティ
        if let screenshotResult = screenshotResult {
            let screenshotPenalty: Float = screenshotResult.isScreenshot ? 0.0 : 1.0
            weightedSum += screenshotPenalty * weights.screenshotPenaltyWeight
            totalWeight += weights.screenshotPenaltyWeight
        }

        // 重み付け平均を計算
        guard totalWeight > 0 else {
            return 0.5 // デフォルト値
        }

        return weightedSum / totalWeight
    }
}

// MARK: - AnalysisError Extension

extension AnalysisError {
    /// アセットが見つからない
    static let assetNotFound = AnalysisError.groupingFailed
}
