//
//  StorageInfo.swift
//  LightRoll_CleanerFeature
//
//  ストレージ情報のドメインモデル
//  デバイスの容量と写真ライブラリの使用量を管理
//  Created by AI Assistant
//

import Foundation

// MARK: - StorageInfo

/// ストレージ情報のドメインモデル
/// デバイスの総容量、空き容量、写真使用量、削減可能容量を管理
public struct StorageInfo: Sendable, Codable, Hashable {

    // MARK: - Properties

    /// デバイスの総容量（バイト）
    public let totalCapacity: Int64

    /// 利用可能な空き容量（バイト）
    public let availableCapacity: Int64

    /// 写真ライブラリが使用している容量（バイト）
    public let photosUsedCapacity: Int64

    /// 削減可能な容量（バイト）
    /// 重複や類似写真を削除した場合に解放される見込み容量
    public let reclaimableCapacity: Int64

    // MARK: - Initialization

    /// 全プロパティを指定して初期化
    /// - Parameters:
    ///   - totalCapacity: 総容量
    ///   - availableCapacity: 空き容量
    ///   - photosUsedCapacity: 写真使用容量
    ///   - reclaimableCapacity: 削減可能容量
    public init(
        totalCapacity: Int64,
        availableCapacity: Int64,
        photosUsedCapacity: Int64,
        reclaimableCapacity: Int64
    ) {
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.photosUsedCapacity = photosUsedCapacity
        self.reclaimableCapacity = reclaimableCapacity
    }

    // MARK: - Computed Properties

    /// ストレージ使用率（0.0〜1.0）
    /// 総容量が 0 の場合は 0.0 を返す
    public var usagePercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(totalCapacity - availableCapacity) / Double(totalCapacity)
    }

    /// 使用中の容量（バイト）
    public var usedCapacity: Int64 {
        totalCapacity - availableCapacity
    }

    /// 写真ライブラリの使用率（総容量に対する割合、0.0〜1.0）
    public var photosUsagePercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(photosUsedCapacity) / Double(totalCapacity)
    }

    /// 削減可能容量の写真使用量に対する割合（0.0〜1.0）
    public var reclaimablePercentage: Double {
        guard photosUsedCapacity > 0 else { return 0.0 }
        return Double(reclaimableCapacity) / Double(photosUsedCapacity)
    }

    /// フォーマット済み総容量（例: 「128 GB」）
    public var formattedTotalCapacity: String {
        ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
    }

    /// フォーマット済み空き容量（例: 「45.2 GB」）
    public var formattedAvailableCapacity: String {
        ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
    }

    /// フォーマット済み使用容量（例: 「82.8 GB」）
    public var formattedUsedCapacity: String {
        ByteCountFormatter.string(fromByteCount: usedCapacity, countStyle: .file)
    }

    /// フォーマット済み写真使用容量（例: 「25.3 GB」）
    public var formattedPhotosUsedCapacity: String {
        ByteCountFormatter.string(fromByteCount: photosUsedCapacity, countStyle: .file)
    }

    /// フォーマット済み削減可能容量（例: 「3.5 GB」）
    public var formattedReclaimableCapacity: String {
        ByteCountFormatter.string(fromByteCount: reclaimableCapacity, countStyle: .file)
    }

    /// 使用率のパーセント表示（例: 「64.7%」）
    public var formattedUsagePercentage: String {
        String(format: "%.1f%%", usagePercentage * 100)
    }

    /// 空き容量が少ないかどうか（空き容量が10%未満）
    public var isLowStorage: Bool {
        guard totalCapacity > 0 else { return false }
        return Double(availableCapacity) / Double(totalCapacity) < 0.10
    }

    /// 空き容量が非常に少ないかどうか（空き容量が5%未満または1GB未満）
    public var isCriticalStorage: Bool {
        let gigabyte: Int64 = 1_000_000_000
        if availableCapacity < gigabyte {
            return true
        }
        guard totalCapacity > 0 else { return false }
        return Double(availableCapacity) / Double(totalCapacity) < 0.05
    }

    /// 削減効果が大きいかどうか（削減可能容量が1GB以上）
    public var hasSignificantReclaimable: Bool {
        let gigabyte: Int64 = 1_000_000_000
        return reclaimableCapacity >= gigabyte
    }

    // MARK: - Factory Methods

    /// 空のストレージ情報（初期状態やエラー時用）
    public static var empty: StorageInfo {
        StorageInfo(
            totalCapacity: 0,
            availableCapacity: 0,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )
    }

    /// デバイスから取得した現在のストレージ情報を生成
    /// 写真使用量と削減可能容量は別途設定が必要
    /// - Returns: デバイスの容量情報を持つ StorageInfo
    public static func fromDevice() -> StorageInfo {
        let fileManager = FileManager.default

        // ドキュメントディレクトリのURLを取得
        guard let documentDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return .empty
        }

        do {
            let attributes = try fileManager.attributesOfFileSystem(
                forPath: documentDirectory.path
            )

            let totalCapacity = (attributes[.systemSize] as? Int64) ?? 0
            let availableCapacity = (attributes[.systemFreeSize] as? Int64) ?? 0

            return StorageInfo(
                totalCapacity: totalCapacity,
                availableCapacity: availableCapacity,
                photosUsedCapacity: 0,  // 別途計算が必要
                reclaimableCapacity: 0   // 別途計算が必要
            )
        } catch {
            return .empty
        }
    }

    // MARK: - Update Methods

    /// 写真使用容量を更新した新しいインスタンスを返す
    /// - Parameter photosUsed: 新しい写真使用容量
    /// - Returns: 更新された StorageInfo
    public func withPhotosUsedCapacity(_ photosUsed: Int64) -> StorageInfo {
        StorageInfo(
            totalCapacity: totalCapacity,
            availableCapacity: availableCapacity,
            photosUsedCapacity: photosUsed,
            reclaimableCapacity: reclaimableCapacity
        )
    }

    /// 削減可能容量を更新した新しいインスタンスを返す
    /// - Parameter reclaimable: 新しい削減可能容量
    /// - Returns: 更新された StorageInfo
    public func withReclaimableCapacity(_ reclaimable: Int64) -> StorageInfo {
        StorageInfo(
            totalCapacity: totalCapacity,
            availableCapacity: availableCapacity,
            photosUsedCapacity: photosUsedCapacity,
            reclaimableCapacity: reclaimable
        )
    }

    /// 空き容量を更新した新しいインスタンスを返す（容量解放後の状態更新用）
    /// - Parameter available: 新しい空き容量
    /// - Returns: 更新された StorageInfo
    public func withAvailableCapacity(_ available: Int64) -> StorageInfo {
        StorageInfo(
            totalCapacity: totalCapacity,
            availableCapacity: available,
            photosUsedCapacity: photosUsedCapacity,
            reclaimableCapacity: reclaimableCapacity
        )
    }
}

// MARK: - StorageInfo + CustomStringConvertible

extension StorageInfo: CustomStringConvertible {
    public var description: String {
        """
        StorageInfo(total: \(formattedTotalCapacity), \
        available: \(formattedAvailableCapacity), \
        photos: \(formattedPhotosUsedCapacity), \
        reclaimable: \(formattedReclaimableCapacity))
        """
    }
}

// MARK: - StorageInfo + Identifiable

extension StorageInfo: Identifiable {
    /// 識別子（内容のハッシュ値）
    public var id: Int {
        hashValue
    }
}

// MARK: - StorageLevel

/// ストレージ状態のレベル
public enum StorageLevel: Sendable {
    /// 正常（空き容量が10%以上）
    case normal
    /// 警告（空き容量が5〜10%）
    case warning
    /// 危険（空き容量が5%未満または1GB未満）
    case critical

    /// ローカライズされた名称
    public var localizedName: String {
        switch self {
        case .normal:
            return NSLocalizedString("storageLevel.normal", value: "正常", comment: "Normal storage level")
        case .warning:
            return NSLocalizedString("storageLevel.warning", value: "警告", comment: "Warning storage level")
        case .critical:
            return NSLocalizedString("storageLevel.critical", value: "危険", comment: "Critical storage level")
        }
    }

    /// 説明文
    public var localizedDescription: String {
        switch self {
        case .normal:
            return NSLocalizedString(
                "storageLevel.normal.description",
                value: "ストレージに十分な空き容量があります",
                comment: "Normal storage level description"
            )
        case .warning:
            return NSLocalizedString(
                "storageLevel.warning.description",
                value: "ストレージの空き容量が少なくなっています",
                comment: "Warning storage level description"
            )
        case .critical:
            return NSLocalizedString(
                "storageLevel.critical.description",
                value: "ストレージの空き容量がほとんどありません",
                comment: "Critical storage level description"
            )
        }
    }
}

// MARK: - StorageInfo + StorageLevel

extension StorageInfo {
    /// 現在のストレージレベル
    public var storageLevel: StorageLevel {
        if isCriticalStorage {
            return .critical
        } else if isLowStorage {
            return .warning
        } else {
            return .normal
        }
    }
}
