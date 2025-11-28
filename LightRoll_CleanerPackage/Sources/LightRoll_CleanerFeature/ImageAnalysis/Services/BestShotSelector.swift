//
//  BestShotSelector.swift
//  LightRoll_CleanerFeature
//
//  ベストショット選定サービス - グループ内の写真を総合評価して最適な1枚を選定
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - BestShotSelector

/// ベストショット選定サービス
///
/// 主な責務:
/// - 写真グループからベストショットを自動選定
/// - シャープネス、顔品質、顔数等の総合評価
/// - 写真品質スコアランキング
/// - カスタマイズ可能な評価ウェイト
public actor BestShotSelector {

    // MARK: - Properties

    /// ブレ検出器
    private let blurDetector: BlurDetector

    /// 顔検出器
    private let faceDetector: FaceDetector

    /// 選定オプション
    private let options: BestShotSelectionOptions

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - blurDetector: ブレ検出器（省略時は新規作成）
    ///   - faceDetector: 顔検出器（省略時は新規作成）
    ///   - options: 選定オプション
    public init(
        blurDetector: BlurDetector? = nil,
        faceDetector: FaceDetector? = nil,
        options: BestShotSelectionOptions = .default
    ) {
        self.blurDetector = blurDetector ?? BlurDetector()
        self.faceDetector = faceDetector ?? FaceDetector()
        self.options = options
    }

    // MARK: - Public Methods

    /// PhotoGroup からベストショットのインデックスを選定
    ///
    /// - Parameter group: 対象の写真グループ
    /// - Returns: ベストショットのインデックス（nil の場合は選定失敗）
    /// - Throws: AnalysisError
    public func selectBestShot(from group: PhotoGroup) async throws -> Int? {
        // 空のグループは選定不可
        guard !group.photoIds.isEmpty else {
            return nil
        }

        // 単一写真の場合はそれを選定
        guard group.photoIds.count > 1 else {
            return 0
        }

        // 各写真を評価してスコアリング
        let scores = try await calculateQualityScores(for: group.photoIds)

        // 最高スコアのインデックスを返す
        guard let bestIndex = scores.enumerated().max(by: { $0.element.totalScore < $1.element.totalScore })?.offset else {
            return 0
        }

        return bestIndex
    }

    /// 写真ID配列を品質スコア順にランキング
    ///
    /// - Parameter photoIds: 対象の写真ID配列
    /// - Returns: スコア付き写真配列（降順）
    /// - Throws: AnalysisError
    public func rankPhotos(_ photoIds: [String]) async throws -> [PhotoQualityScore] {
        guard !photoIds.isEmpty else {
            return []
        }

        let scores = try await calculateQualityScores(for: photoIds)
        return scores.sorted { $0.totalScore > $1.totalScore }
    }

    // MARK: - Private Methods

    /// 写真ID配列の品質スコアを計算
    ///
    /// - Parameter photoIds: 対象の写真ID配列
    /// - Returns: 各写真の品質スコア配列
    /// - Throws: AnalysisError
    private func calculateQualityScores(for photoIds: [String]) async throws -> [PhotoQualityScore] {
        // PHAssetを取得
        let assets = fetchPHAssets(for: photoIds)
        guard !assets.isEmpty else {
            throw AnalysisError.groupingFailed
        }

        var scores: [PhotoQualityScore] = []
        scores.reserveCapacity(photoIds.count)

        for asset in assets {
            do {
                let score = try await calculateQualityScore(for: asset)
                scores.append(score)
            } catch {
                // 個別エラーは記録して続行（デフォルトスコアを使用）
                let defaultScore = PhotoQualityScore(
                    photoId: asset.localIdentifier,
                    sharpnessScore: 0.5,
                    faceQualityScore: 0.0,
                    faceCountScore: 0.0,
                    totalScore: 0.5,
                    analysisError: error
                )
                scores.append(defaultScore)
            }
        }

        return scores
    }

    /// 単一の写真の品質スコアを計算
    ///
    /// - Parameter asset: 対象のPHAsset
    /// - Returns: 品質スコア
    /// - Throws: AnalysisError
    private func calculateQualityScore(for asset: PHAsset) async throws -> PhotoQualityScore {
        // ブレ検出
        let blurResult: BlurDetectionResult
        do {
            blurResult = try await blurDetector.detectBlur(in: asset)
        } catch {
            // ブレ検出失敗時はデフォルト値
            blurResult = BlurDetectionResult(
                photoId: asset.localIdentifier,
                blurScore: 0.5,
                sharpnessScore: 0.5,
                isBlurry: false
            )
        }

        // 顔検出
        let faceResult: FaceDetectionResult
        do {
            faceResult = try await faceDetector.detectFaces(in: asset)
        } catch {
            // 顔検出失敗時はデフォルト値
            faceResult = FaceDetectionResult(
                photoId: asset.localIdentifier,
                faces: []
            )
        }

        // 各スコア要素を計算
        let sharpnessScore = calculateSharpnessScore(from: blurResult)
        let faceQualityScore = calculateFaceQualityScore(from: faceResult)
        let faceCountScore = calculateFaceCountScore(from: faceResult)

        // 総合スコアを計算（重み付け平均）
        let totalScore = (
            sharpnessScore * options.sharpnessWeight +
            faceQualityScore * options.faceQualityWeight +
            faceCountScore * options.faceCountWeight
        )

        return PhotoQualityScore(
            photoId: asset.localIdentifier,
            sharpnessScore: sharpnessScore,
            faceQualityScore: faceQualityScore,
            faceCountScore: faceCountScore,
            totalScore: totalScore,
            blurResult: blurResult,
            faceResult: faceResult
        )
    }

    /// シャープネススコアを計算
    ///
    /// - Parameter blurResult: ブレ検出結果
    /// - Returns: 0.0〜1.0のスコア（高いほど良好）
    private func calculateSharpnessScore(from blurResult: BlurDetectionResult) -> Float {
        // シャープネススコアをそのまま使用
        return blurResult.sharpnessScore
    }

    /// 顔品質スコアを計算
    ///
    /// - Parameter faceResult: 顔検出結果
    /// - Returns: 0.0〜1.0のスコア（高いほど良好）
    private func calculateFaceQualityScore(from faceResult: FaceDetectionResult) -> Float {
        guard !faceResult.faces.isEmpty else {
            return 0.0
        }

        // 各顔の品質スコアを計算
        let faceScores = faceResult.faces.map { face -> Float in
            var score: Float = 0.0

            // 信頼度スコア（0.0〜0.3）
            score += face.confidence * 0.3

            // 顔サイズスコア（0.0〜0.3）
            let faceSize = Float(face.area)
            let sizeScore = min(faceSize * 3.0, 1.0) * 0.3
            score += sizeScore

            // 正面度スコア（0.0〜0.4）
            if let yaw = face.yaw, let pitch = face.pitch {
                // yaw, pitchが0に近いほど高スコア
                let yawScore = max(0, 1.0 - abs(Float(yaw)) / 90.0)
                let pitchScore = max(0, 1.0 - abs(Float(pitch)) / 90.0)
                let frontalScore = (yawScore + pitchScore) / 2.0
                score += frontalScore * 0.4
            }

            return score
        }

        // 最高品質の顔スコアを使用
        return faceScores.max() ?? 0.0
    }

    /// 顔数スコアを計算
    ///
    /// - Parameter faceResult: 顔検出結果
    /// - Returns: 0.0〜1.0のスコア（高いほど良好）
    private func calculateFaceCountScore(from faceResult: FaceDetectionResult) -> Float {
        let faceCount = faceResult.faceCount

        switch faceCount {
        case 0:
            return 0.0
        case 1:
            return 1.0  // 1人が最適
        case 2:
            return 0.8  // 2人もOK
        case 3:
            return 0.6  // 3人はやや低め
        default:
            return 0.4  // 4人以上は低スコア
        }
    }

    /// 写真IDからPHAssetを取得
    ///
    /// - Parameter photoIds: 写真ID配列
    /// - Returns: PHAsset配列
    private func fetchPHAssets(for photoIds: [String]) -> [PHAsset] {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: photoIds, options: nil)

        var assets: [PHAsset] = []
        assets.reserveCapacity(photoIds.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }
}

// MARK: - BestShotSelectionOptions

/// ベストショット選定オプション
public struct BestShotSelectionOptions: Sendable, Equatable {

    /// シャープネスの重み（0.0〜1.0）
    public let sharpnessWeight: Float

    /// 顔品質の重み（0.0〜1.0）
    public let faceQualityWeight: Float

    /// 顔数の重み（0.0〜1.0）
    public let faceCountWeight: Float

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - sharpnessWeight: シャープネスの重み
    ///   - faceQualityWeight: 顔品質の重み
    ///   - faceCountWeight: 顔数の重み
    ///
    /// 注: 重みの合計は自動的に正規化されます
    public init(
        sharpnessWeight: Float = 0.5,
        faceQualityWeight: Float = 0.3,
        faceCountWeight: Float = 0.2
    ) {
        let total = sharpnessWeight + faceQualityWeight + faceCountWeight
        guard total > 0 else {
            // 全てゼロの場合はデフォルト値を使用
            self.sharpnessWeight = 0.5
            self.faceQualityWeight = 0.3
            self.faceCountWeight = 0.2
            return
        }

        // 正規化（合計を1.0にする）
        self.sharpnessWeight = Swift.max(0.0, sharpnessWeight / total)
        self.faceQualityWeight = Swift.max(0.0, faceQualityWeight / total)
        self.faceCountWeight = Swift.max(0.0, faceCountWeight / total)
    }

    // MARK: - Presets

    /// デフォルトオプション（バランス重視）
    public static let `default` = BestShotSelectionOptions()

    /// シャープネス重視
    public static let sharpnessPriority = BestShotSelectionOptions(
        sharpnessWeight: 0.7,
        faceQualityWeight: 0.2,
        faceCountWeight: 0.1
    )

    /// 顔品質重視
    public static let faceQualityPriority = BestShotSelectionOptions(
        sharpnessWeight: 0.2,
        faceQualityWeight: 0.6,
        faceCountWeight: 0.2
    )

    /// 人物写真最適化（顔重視）
    public static let portraitMode = BestShotSelectionOptions(
        sharpnessWeight: 0.3,
        faceQualityWeight: 0.5,
        faceCountWeight: 0.2
    )
}

// MARK: - PhotoQualityScore

/// 写真品質スコア
public struct PhotoQualityScore: Sendable, Identifiable {

    /// 一意な識別子（写真IDと同一）
    public let id: String

    /// 写真ID
    public let photoId: String

    /// シャープネススコア（0.0〜1.0）
    public let sharpnessScore: Float

    /// 顔品質スコア（0.0〜1.0）
    public let faceQualityScore: Float

    /// 顔数スコア（0.0〜1.0）
    public let faceCountScore: Float

    /// 総合スコア（0.0〜1.0）
    public let totalScore: Float

    /// ブレ検出結果（オプショナル）
    public let blurResult: BlurDetectionResult?

    /// 顔検出結果（オプショナル）
    public let faceResult: FaceDetectionResult?

    /// 分析エラー（エラーがあった場合）
    public let analysisError: Error?

    /// スコアリング日時
    public let scoredAt: Date

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        id: String? = nil,
        photoId: String,
        sharpnessScore: Float,
        faceQualityScore: Float,
        faceCountScore: Float,
        totalScore: Float,
        blurResult: BlurDetectionResult? = nil,
        faceResult: FaceDetectionResult? = nil,
        analysisError: Error? = nil,
        scoredAt: Date = Date()
    ) {
        self.id = id ?? photoId
        self.photoId = photoId
        self.sharpnessScore = Swift.max(0.0, Swift.min(1.0, sharpnessScore))
        self.faceQualityScore = Swift.max(0.0, Swift.min(1.0, faceQualityScore))
        self.faceCountScore = Swift.max(0.0, Swift.min(1.0, faceCountScore))
        self.totalScore = Swift.max(0.0, Swift.min(1.0, totalScore))
        self.blurResult = blurResult
        self.faceResult = faceResult
        self.analysisError = analysisError
        self.scoredAt = scoredAt
    }

    // MARK: - Computed Properties

    /// スコアが有効かどうか（エラーなし）
    public var isValid: Bool {
        analysisError == nil
    }

    /// 品質評価レベル
    public var qualityLevel: QualityLevel {
        if totalScore >= 0.8 {
            return .excellent
        } else if totalScore >= 0.6 {
            return .good
        } else if totalScore >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }

    /// フォーマット済み総合スコア（パーセント表示）
    public var formattedTotalScore: String {
        String(format: "%.1f%%", totalScore * 100)
    }

    /// スコアの説明テキスト
    public var scoreDescription: String {
        """
        総合: \(formattedTotalScore)
        シャープネス: \(String(format: "%.1f%%", sharpnessScore * 100))
        顔品質: \(String(format: "%.1f%%", faceQualityScore * 100))
        顔数: \(String(format: "%.1f%%", faceCountScore * 100))
        """
    }
}

// MARK: - QualityLevel

/// 品質評価レベル
public enum QualityLevel: String, Sendable, Codable {
    /// 優秀（80%以上）
    case excellent
    /// 良好（60〜79%）
    case good
    /// 普通（40〜59%）
    case fair
    /// 低品質（40%未満）
    case poor

    /// SF Symbol アイコン名
    public var iconName: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "star.leadinghalf.filled"
        case .fair:
            return "star"
        case .poor:
            return "xmark.circle"
        }
    }

    /// 表示名
    public var displayName: String {
        switch self {
        case .excellent:
            return NSLocalizedString("quality.excellent", value: "優秀", comment: "Excellent quality")
        case .good:
            return NSLocalizedString("quality.good", value: "良好", comment: "Good quality")
        case .fair:
            return NSLocalizedString("quality.fair", value: "普通", comment: "Fair quality")
        case .poor:
            return NSLocalizedString("quality.poor", value: "低品質", comment: "Poor quality")
        }
    }
}

// MARK: - PhotoQualityScore + Hashable

extension PhotoQualityScore: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: PhotoQualityScore, rhs: PhotoQualityScore) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PhotoQualityScore + Comparable

extension PhotoQualityScore: Comparable {
    /// 総合スコアで比較（高い方が先）
    public static func < (lhs: PhotoQualityScore, rhs: PhotoQualityScore) -> Bool {
        lhs.totalScore < rhs.totalScore
    }
}

// MARK: - PhotoQualityScore + CustomStringConvertible

extension PhotoQualityScore: CustomStringConvertible {
    public var description: String {
        """
        PhotoQualityScore(
            photoId: \(photoId),
            totalScore: \(String(format: "%.2f", totalScore)),
            sharpness: \(String(format: "%.2f", sharpnessScore)),
            faceQuality: \(String(format: "%.2f", faceQualityScore)),
            faceCount: \(String(format: "%.2f", faceCountScore)),
            quality: \(qualityLevel.displayName)
        )
        """
    }
}

// MARK: - Array Extension for PhotoQualityScore

extension Array where Element == PhotoQualityScore {

    /// 品質レベルでフィルタ
    public func filter(by level: QualityLevel) -> [PhotoQualityScore] {
        filter { $0.qualityLevel == level }
    }

    /// 有効なスコアのみをフィルタ（エラーなし）
    public var validScores: [PhotoQualityScore] {
        filter { $0.isValid }
    }

    /// 総合スコア順でソート（降順）
    public var sortedByTotalScore: [PhotoQualityScore] {
        sorted { $0.totalScore > $1.totalScore }
    }

    /// シャープネス順でソート（降順）
    public var sortedBySharpnessScore: [PhotoQualityScore] {
        sorted { $0.sharpnessScore > $1.sharpnessScore }
    }

    /// 顔品質順でソート（降順）
    public var sortedByFaceQuality: [PhotoQualityScore] {
        sorted { $0.faceQualityScore > $1.faceQualityScore }
    }

    /// 最高スコアの写真
    public var best: PhotoQualityScore? {
        self.max { $0.totalScore < $1.totalScore }
    }

    /// 平均総合スコア
    public var averageTotalScore: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.totalScore }
        return sum / Float(count)
    }

    /// 平均シャープネススコア
    public var averageSharpnessScore: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.sharpnessScore }
        return sum / Float(count)
    }

    /// 品質レベル別の件数
    public var countByQualityLevel: [QualityLevel: Int] {
        Dictionary(grouping: self) { $0.qualityLevel }
            .mapValues { $0.count }
    }
}
