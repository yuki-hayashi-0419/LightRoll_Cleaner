//
//  PhotoAnalysisResult.swift
//  LightRoll_CleanerFeature
//
//  画像分析結果のドメインモデル
//  Vision Framework による分析結果を格納し、品質評価・グルーピングに使用
//  Created by AI Assistant
//

import Foundation
import Vision

// MARK: - PhotoAnalysisResult

/// 写真の分析結果を表すドメインモデル
/// Vision Framework による各種分析結果を統合的に管理
/// Sendable 準拠により Swift Concurrency で安全に使用可能
public struct PhotoAnalysisResult: Identifiable, Hashable, Sendable {

    // MARK: - Properties

    /// 一意な識別子（分析対象の Photo.id と同一）
    public let id: String

    /// 分析対象の写真ID（Photo.localIdentifier）
    public let photoId: String

    /// 分析実行日時
    public let analyzedAt: Date

    /// 総合品質スコア（0.0〜1.0、高いほど高品質）
    public let qualityScore: Float

    /// ブレスコア（0.0〜1.0、高いほどブレが大きい）
    public let blurScore: Float

    /// 明るさスコア（0.0〜1.0、0.5が適正）
    public let brightnessScore: Float

    /// コントラストスコア（0.0〜1.0、高いほど高コントラスト）
    public let contrastScore: Float

    /// 彩度スコア（0.0〜1.0）
    public let saturationScore: Float

    /// 検出された顔の数
    public let faceCount: Int

    /// 各顔の品質スコア（0.0〜1.0）
    public let faceQualityScores: [Float]

    /// 各顔の向き情報
    public let faceAngles: [FaceAngle]

    /// スクリーンショット判定
    public let isScreenshot: Bool

    /// 自撮り（セルフィー）判定
    public let isSelfie: Bool

    /// 特徴量ハッシュ（類似度比較用、nil の場合は抽出失敗）
    public let featurePrintHash: Data?

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    ///
    /// すべての引数にデフォルト値があるため、必要な引数のみ指定可能
    public init(
        id: String = UUID().uuidString,
        photoId: String,
        analyzedAt: Date = Date(),
        qualityScore: Float = 0.5,
        blurScore: Float = 0.2,
        brightnessScore: Float = 0.5,
        contrastScore: Float = 0.5,
        saturationScore: Float = 0.5,
        faceCount: Int = 0,
        faceQualityScores: [Float] = [],
        faceAngles: [FaceAngle] = [],
        isScreenshot: Bool = false,
        isSelfie: Bool = false,
        featurePrintHash: Data? = nil
    ) {
        self.id = id
        self.photoId = photoId
        self.analyzedAt = analyzedAt
        self.qualityScore = Self.clamp(qualityScore)
        self.blurScore = Self.clamp(blurScore)
        self.brightnessScore = Self.clamp(brightnessScore)
        self.contrastScore = Self.clamp(contrastScore)
        self.saturationScore = Self.clamp(saturationScore)
        self.faceCount = max(0, faceCount)
        self.faceQualityScores = faceQualityScores.map { Self.clamp($0) }
        self.faceAngles = faceAngles
        self.isScreenshot = isScreenshot
        self.isSelfie = isSelfie
        self.featurePrintHash = featurePrintHash
    }

    // MARK: - Computed Properties

    /// シャープネススコア（1.0 - blurScore、高いほどシャープ）
    public var sharpnessScore: Float {
        1.0 - blurScore
    }

    /// ブレ写真かどうか（閾値 0.4 以上でブレと判定）
    public var isBlurry: Bool {
        blurScore >= AnalysisThresholds.blurThreshold
    }

    /// 高品質かどうか（閾値 0.7 以上で高品質）
    public var isHighQuality: Bool {
        qualityScore >= AnalysisThresholds.highQualityThreshold
    }

    /// 低品質かどうか（閾値 0.4 未満で低品質）
    public var isLowQuality: Bool {
        qualityScore < AnalysisThresholds.lowQualityThreshold
    }

    /// 明るすぎるかどうか（閾値 0.8 以上）
    public var isOverexposed: Bool {
        brightnessScore >= AnalysisThresholds.overexposedThreshold
    }

    /// 暗すぎるかどうか（閾値 0.2 以下）
    public var isUnderexposed: Bool {
        brightnessScore <= AnalysisThresholds.underexposedThreshold
    }

    /// 適正露出かどうか
    public var hasProperExposure: Bool {
        !isOverexposed && !isUnderexposed
    }

    /// 顔が含まれているかどうか
    public var hasFaces: Bool {
        faceCount > 0
    }

    /// 複数の顔が含まれているかどうか
    public var hasMultipleFaces: Bool {
        faceCount > 1
    }

    /// 平均顔品質スコア
    public var averageFaceQuality: Float? {
        guard !faceQualityScores.isEmpty else { return nil }
        let sum = faceQualityScores.reduce(0, +)
        return sum / Float(faceQualityScores.count)
    }

    /// 最高顔品質スコア
    public var bestFaceQuality: Float? {
        faceQualityScores.max()
    }

    /// 正面を向いている顔の数
    public var frontalFaceCount: Int {
        faceAngles.filter { $0.isFrontal }.count
    }

    /// 特徴量が利用可能かどうか
    public var hasFeaturePrint: Bool {
        featurePrintHash != nil
    }

    /// 削除候補かどうか（ブレ・低品質・露出異常のいずれか）
    public var isDeletionCandidate: Bool {
        isBlurry || isLowQuality || !hasProperExposure
    }

    /// 問題点の一覧
    public var issues: [AnalysisIssue] {
        var result: [AnalysisIssue] = []

        if isBlurry {
            result.append(.blurry(score: blurScore))
        }
        if isLowQuality {
            result.append(.lowQuality(score: qualityScore))
        }
        if isOverexposed {
            result.append(.overexposed(score: brightnessScore))
        }
        if isUnderexposed {
            result.append(.underexposed(score: brightnessScore))
        }

        return result
    }

    // MARK: - Helper Methods

    /// スコアを 0.0〜1.0 の範囲にクランプ
    private static func clamp(_ value: Float) -> Float {
        min(max(value, 0.0), 1.0)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(photoId)
        hasher.combine(qualityScore)
    }

    public static func == (lhs: PhotoAnalysisResult, rhs: PhotoAnalysisResult) -> Bool {
        lhs.id == rhs.id && lhs.photoId == rhs.photoId
    }
}

// MARK: - FaceAngle

/// 顔の向き情報
public struct FaceAngle: Hashable, Sendable, Codable {

    /// 左右の回転角度（-90〜90度、0が正面）
    public let yaw: Float

    /// 上下の傾き角度（-90〜90度、0が正面）
    public let pitch: Float

    /// 首の傾き角度（-180〜180度、0が垂直）
    public let roll: Float

    public init(yaw: Float, pitch: Float, roll: Float) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
    }

    /// 正面を向いているかどうか（yaw, pitch が閾値内）
    public var isFrontal: Bool {
        abs(yaw) <= 30 && abs(pitch) <= 30
    }

    /// 横を向いているかどうか
    public var isSideProfile: Bool {
        abs(yaw) > 45
    }

    /// 顔向きの説明テキスト
    public var description: String {
        if isFrontal {
            return NSLocalizedString("faceAngle.frontal", value: "正面", comment: "Frontal face")
        } else if yaw > 30 {
            return NSLocalizedString("faceAngle.left", value: "左向き", comment: "Face turned left")
        } else if yaw < -30 {
            return NSLocalizedString("faceAngle.right", value: "右向き", comment: "Face turned right")
        } else if pitch > 30 {
            return NSLocalizedString("faceAngle.up", value: "上向き", comment: "Face looking up")
        } else if pitch < -30 {
            return NSLocalizedString("faceAngle.down", value: "下向き", comment: "Face looking down")
        }
        return NSLocalizedString("faceAngle.angled", value: "斜め", comment: "Angled face")
    }
}

// MARK: - AnalysisIssue

/// 分析で検出された問題点
public enum AnalysisIssue: Hashable, Sendable {
    /// ブレている
    case blurry(score: Float)
    /// 低品質
    case lowQuality(score: Float)
    /// 明るすぎる
    case overexposed(score: Float)
    /// 暗すぎる
    case underexposed(score: Float)

    /// 問題の説明テキスト
    public var description: String {
        switch self {
        case .blurry:
            return NSLocalizedString("issue.blurry", value: "ブレ", comment: "Blurry issue")
        case .lowQuality:
            return NSLocalizedString("issue.lowQuality", value: "低品質", comment: "Low quality issue")
        case .overexposed:
            return NSLocalizedString("issue.overexposed", value: "明るすぎ", comment: "Overexposed issue")
        case .underexposed:
            return NSLocalizedString("issue.underexposed", value: "暗すぎ", comment: "Underexposed issue")
        }
    }

    /// 問題の SF Symbol アイコン名
    public var iconName: String {
        switch self {
        case .blurry:
            return "camera.metering.unknown"
        case .lowQuality:
            return "exclamationmark.triangle"
        case .overexposed:
            return "sun.max.fill"
        case .underexposed:
            return "moon.fill"
        }
    }

    /// 問題の深刻度（0.0〜1.0）
    public var severity: Float {
        switch self {
        case .blurry(let score):
            return score
        case .lowQuality(let score):
            return 1.0 - score
        case .overexposed(let score):
            return (score - 0.5) * 2.0
        case .underexposed(let score):
            return (0.5 - score) * 2.0
        }
    }
}

// MARK: - AnalysisThresholds

/// 分析判定の閾値設定
///
/// デフォルト値を提供します。カスタマイズが必要な場合は、
/// 分析時にパラメータとして渡すことを推奨します。
public enum AnalysisThresholds: Sendable {
    /// ブレ判定の閾値（これ以上でブレと判定）
    public static let blurThreshold: Float = 0.4

    /// 高品質判定の閾値（これ以上で高品質）
    public static let highQualityThreshold: Float = 0.7

    /// 低品質判定の閾値（これ未満で低品質）
    public static let lowQualityThreshold: Float = 0.4

    /// 明るすぎ判定の閾値
    public static let overexposedThreshold: Float = 0.8

    /// 暗すぎ判定の閾値
    public static let underexposedThreshold: Float = 0.2

    /// 類似度判定の閾値（これ以上で類似と判定）
    public static let similarityThreshold: Float = 0.85

    /// 自撮り判定の最小顔サイズ比率（画像に対する顔の占める割合）
    public static let selfieMinFaceRatio: Float = 0.15
}

// MARK: - PhotoAnalysisResult + Codable

/// Codable 対応用の中間構造体
/// VNFeaturePrintObservation は Codable 非対応のため、ハッシュ化した Data として保存
extension PhotoAnalysisResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoId
        case analyzedAt
        case qualityScore
        case blurScore
        case brightnessScore
        case contrastScore
        case saturationScore
        case faceCount
        case faceQualityScores
        case faceAngles
        case isScreenshot
        case isSelfie
        case featurePrintHash
    }
}

// MARK: - PhotoAnalysisResult + CustomStringConvertible

extension PhotoAnalysisResult: CustomStringConvertible {
    public var description: String {
        """
        AnalysisResult(photoId: \(photoId), \
        quality: \(String(format: "%.2f", qualityScore)), \
        blur: \(String(format: "%.2f", blurScore)), \
        faces: \(faceCount), \
        issues: \(issues.count))
        """
    }
}

// MARK: - PhotoAnalysisResult + Comparable

extension PhotoAnalysisResult: Comparable {
    /// 品質スコアで比較（高品質が先）
    public static func < (lhs: PhotoAnalysisResult, rhs: PhotoAnalysisResult) -> Bool {
        lhs.qualityScore > rhs.qualityScore
    }
}

// MARK: - PhotoAnalysisResult.Builder

extension PhotoAnalysisResult {
    /// 分析結果を段階的に構築するためのビルダー
    /// 各分析処理が個別に完了した際に結果を追加可能
    public final class Builder: @unchecked Sendable {
        private let lock = NSLock()

        private var photoId: String
        private var qualityScore: Float = 0.5
        private var blurScore: Float = 0.0
        private var brightnessScore: Float = 0.5
        private var contrastScore: Float = 0.5
        private var saturationScore: Float = 0.5
        private var faceCount: Int = 0
        private var faceQualityScores: [Float] = []
        private var faceAngles: [FaceAngle] = []
        private var isScreenshot: Bool = false
        private var isSelfie: Bool = false
        private var featurePrintHash: Data?

        /// 分析対象の写真IDで初期化
        public init(photoId: String) {
            self.photoId = photoId
        }

        /// 品質スコアを設定
        @discardableResult
        public func setQualityScore(_ score: Float) -> Builder {
            lock.withLock { qualityScore = score }
            return self
        }

        /// ブレスコアを設定
        @discardableResult
        public func setBlurScore(_ score: Float) -> Builder {
            lock.withLock { blurScore = score }
            return self
        }

        /// 明るさスコアを設定
        @discardableResult
        public func setBrightnessScore(_ score: Float) -> Builder {
            lock.withLock { brightnessScore = score }
            return self
        }

        /// コントラストスコアを設定
        @discardableResult
        public func setContrastScore(_ score: Float) -> Builder {
            lock.withLock { contrastScore = score }
            return self
        }

        /// 彩度スコアを設定
        @discardableResult
        public func setSaturationScore(_ score: Float) -> Builder {
            lock.withLock { saturationScore = score }
            return self
        }

        /// 顔検出結果を設定
        @discardableResult
        public func setFaceResults(
            count: Int,
            qualityScores: [Float],
            angles: [FaceAngle] = []
        ) -> Builder {
            lock.withLock {
                faceCount = count
                faceQualityScores = qualityScores
                faceAngles = angles
            }
            return self
        }

        /// スクリーンショットフラグを設定
        @discardableResult
        public func setIsScreenshot(_ value: Bool) -> Builder {
            lock.withLock { isScreenshot = value }
            return self
        }

        /// 自撮りフラグを設定
        @discardableResult
        public func setIsSelfie(_ value: Bool) -> Builder {
            lock.withLock { isSelfie = value }
            return self
        }

        /// 特徴量ハッシュを設定
        @discardableResult
        public func setFeaturePrintHash(_ hash: Data?) -> Builder {
            lock.withLock { featurePrintHash = hash }
            return self
        }

        /// PhotoAnalysisResult を構築
        public func build() -> PhotoAnalysisResult {
            lock.withLock {
                PhotoAnalysisResult(
                    id: photoId,
                    photoId: photoId,
                    analyzedAt: Date(),
                    qualityScore: qualityScore,
                    blurScore: blurScore,
                    brightnessScore: brightnessScore,
                    contrastScore: contrastScore,
                    saturationScore: saturationScore,
                    faceCount: faceCount,
                    faceQualityScores: faceQualityScores,
                    faceAngles: faceAngles,
                    isScreenshot: isScreenshot,
                    isSelfie: isSelfie,
                    featurePrintHash: featurePrintHash
                )
            }
        }
    }
}

// MARK: - Array Extension for PhotoAnalysisResult

extension Array where Element == PhotoAnalysisResult {
    /// 品質スコア順でソート（高品質が先）
    public func sortedByQuality() -> [PhotoAnalysisResult] {
        sorted { $0.qualityScore > $1.qualityScore }
    }

    /// ブレスコア順でソート（シャープが先）
    public func sortedBySharpness() -> [PhotoAnalysisResult] {
        sorted { $0.blurScore < $1.blurScore }
    }

    /// 削除候補のみをフィルタ
    public func filterDeletionCandidates() -> [PhotoAnalysisResult] {
        filter { $0.isDeletionCandidate }
    }

    /// 高品質のみをフィルタ
    public func filterHighQuality() -> [PhotoAnalysisResult] {
        filter { $0.isHighQuality }
    }

    /// 顔が含まれるもののみをフィルタ
    public func filterWithFaces() -> [PhotoAnalysisResult] {
        filter { $0.hasFaces }
    }

    /// 自撮りのみをフィルタ
    public func filterSelfies() -> [PhotoAnalysisResult] {
        filter { $0.isSelfie }
    }

    /// スクリーンショットのみをフィルタ
    public func filterScreenshots() -> [PhotoAnalysisResult] {
        filter { $0.isScreenshot }
    }

    /// ブレ写真のみをフィルタ
    public func filterBlurry() -> [PhotoAnalysisResult] {
        filter { $0.isBlurry }
    }

    /// 平均品質スコアを計算
    public var averageQualityScore: Float? {
        guard !isEmpty else { return nil }
        let sum = reduce(Float(0)) { $0 + $1.qualityScore }
        return sum / Float(count)
    }

    /// 最高品質の結果を取得
    public var bestQuality: PhotoAnalysisResult? {
        self.max { $0.qualityScore < $1.qualityScore }
    }

    /// 最低品質の結果を取得
    public var worstQuality: PhotoAnalysisResult? {
        self.min { $0.qualityScore < $1.qualityScore }
    }
}
