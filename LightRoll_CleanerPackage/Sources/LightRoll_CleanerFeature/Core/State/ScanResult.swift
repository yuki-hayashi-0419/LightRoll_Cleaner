//
//  ScanResult.swift
//  LightRoll_CleanerFeature
//
//  スキャン結果モデル
//  写真ライブラリのスキャン完了時の結果を表現
//  Created by AI Assistant
//

import Foundation

// MARK: - ScanResult

/// スキャン結果
/// 写真ライブラリのスキャン完了時の結果データ
public struct ScanResult: Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// スキャンされた写真の総数
    public let totalPhotosScanned: Int

    /// 発見されたグループ数
    public let groupsFound: Int

    /// 削減可能な容量（バイト）
    public let potentialSavings: Int64

    /// スキャンにかかった時間（秒）
    public let duration: TimeInterval

    /// スキャン完了時刻
    public let timestamp: Date

    /// グループタイプ別の内訳
    public let groupBreakdown: GroupBreakdown

    // MARK: - Initialization

    public init(
        totalPhotosScanned: Int,
        groupsFound: Int,
        potentialSavings: Int64,
        duration: TimeInterval,
        timestamp: Date = Date(),
        groupBreakdown: GroupBreakdown = GroupBreakdown()
    ) {
        self.totalPhotosScanned = totalPhotosScanned
        self.groupsFound = groupsFound
        self.potentialSavings = potentialSavings
        self.duration = duration
        self.timestamp = timestamp
        self.groupBreakdown = groupBreakdown
    }

    // MARK: - Computed Properties

    /// 人間が読みやすい削減可能容量
    public var formattedPotentialSavings: String {
        ByteCountFormatter.string(
            fromByteCount: potentialSavings,
            countStyle: .file
        )
    }

    /// 人間が読みやすいスキャン時間
    public var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "\(Int(duration))秒"
    }

    /// スキャン完了日時の表示用文字列
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// 相対的な時間表示（例: "3分前"）
    public var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    // MARK: - Factory Methods

    /// 空のスキャン結果を生成
    public static var empty: ScanResult {
        ScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: 0,
            timestamp: Date()
        )
    }
}

// MARK: - GroupBreakdown

/// グループタイプ別の内訳
public struct GroupBreakdown: Equatable, Hashable, Sendable {

    /// 類似写真グループ数
    public let similarGroups: Int

    /// 自撮りグループ数
    public let selfieGroups: Int

    /// スクリーンショットの数
    public let screenshotCount: Int

    /// ブレ写真の数
    public let blurryCount: Int

    /// 大容量動画の数
    public let largeVideoCount: Int

    // MARK: - Initialization

    public init(
        similarGroups: Int = 0,
        selfieGroups: Int = 0,
        screenshotCount: Int = 0,
        blurryCount: Int = 0,
        largeVideoCount: Int = 0
    ) {
        self.similarGroups = similarGroups
        self.selfieGroups = selfieGroups
        self.screenshotCount = screenshotCount
        self.blurryCount = blurryCount
        self.largeVideoCount = largeVideoCount
    }

    // MARK: - Computed Properties

    /// 総アイテム数
    public var totalItems: Int {
        similarGroups + selfieGroups + screenshotCount + blurryCount + largeVideoCount
    }

    /// 特定のグループタイプの数を取得
    public func count(for type: GroupType) -> Int {
        switch type {
        case .similar:
            return similarGroups
        case .selfie:
            return selfieGroups
        case .screenshot:
            return screenshotCount
        case .blurry:
            return blurryCount
        case .largeVideo:
            return largeVideoCount
        }
    }
}

// MARK: - ScanProgress

/// スキャン進捗状態
public struct ScanProgress: Equatable, Sendable {

    /// 現在のフェーズ
    public let phase: ScanPhase

    /// 進捗率（0.0〜1.0）
    public let progress: Double

    /// 処理済み件数
    public let processedCount: Int

    /// 総件数
    public let totalCount: Int

    /// 現在処理中の説明
    public let currentTask: String

    // MARK: - Initialization

    public init(
        phase: ScanPhase = .preparing,
        progress: Double = 0,
        processedCount: Int = 0,
        totalCount: Int = 0,
        currentTask: String = ""
    ) {
        self.phase = phase
        self.progress = min(max(progress, 0), 1)
        self.processedCount = processedCount
        self.totalCount = totalCount
        self.currentTask = currentTask
    }

    // MARK: - Factory Methods

    /// 初期状態
    public static var initial: ScanProgress {
        ScanProgress(phase: .preparing)
    }

    /// 完了状態
    public static var completed: ScanProgress {
        ScanProgress(
            phase: .completed,
            progress: 1.0,
            currentTask: NSLocalizedString(
                "scan.progress.completed",
                value: "スキャン完了",
                comment: "Scan completed message"
            )
        )
    }
}

// MARK: - ScanPhase

/// スキャンのフェーズ
public enum ScanPhase: String, CaseIterable, Sendable {

    /// 準備中
    case preparing

    /// 写真取得中
    case fetchingPhotos

    /// 分析中
    case analyzing

    /// グルーピング中
    case grouping

    /// 最適化中
    case optimizing

    /// 完了
    case completed

    /// エラー
    case error

    // MARK: - Display Properties

    /// フェーズの表示名
    public var displayName: String {
        switch self {
        case .preparing:
            return NSLocalizedString(
                "scan.phase.preparing",
                value: "準備中...",
                comment: "Scan preparing phase"
            )
        case .fetchingPhotos:
            return NSLocalizedString(
                "scan.phase.fetchingPhotos",
                value: "写真を取得中...",
                comment: "Scan fetching photos phase"
            )
        case .analyzing:
            return NSLocalizedString(
                "scan.phase.analyzing",
                value: "分析中...",
                comment: "Scan analyzing phase"
            )
        case .grouping:
            return NSLocalizedString(
                "scan.phase.grouping",
                value: "グループ化中...",
                comment: "Scan grouping phase"
            )
        case .optimizing:
            return NSLocalizedString(
                "scan.phase.optimizing",
                value: "最適化中...",
                comment: "Scan optimizing phase"
            )
        case .completed:
            return NSLocalizedString(
                "scan.phase.completed",
                value: "完了",
                comment: "Scan completed phase"
            )
        case .error:
            return NSLocalizedString(
                "scan.phase.error",
                value: "エラー",
                comment: "Scan error phase"
            )
        }
    }

    /// フェーズがアクティブ（処理中）かどうか
    public var isActive: Bool {
        switch self {
        case .preparing, .fetchingPhotos, .analyzing, .grouping, .optimizing:
            return true
        case .completed, .error:
            return false
        }
    }
}
