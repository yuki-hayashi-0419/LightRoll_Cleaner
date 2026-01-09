//
//  MemoryPressureMonitor.swift
//  LightRoll_CleanerFeature
//
//  メモリ使用量の監視と制限を行うサービス
//  メモリ枯渇を防ぎ、安定した処理を実現
//  Created by AI Assistant
//

import Foundation

// MARK: - MemoryPressureLevel

/// メモリプレッシャーレベル
public enum MemoryPressureLevel: Int, Comparable, Sendable {
    /// 正常（メモリに余裕あり）
    case normal = 0

    /// 警告（メモリ使用量が増加中）
    case warning = 1

    /// 危険（メモリ使用量が高い）
    case critical = 2

    public static func < (lhs: MemoryPressureLevel, rhs: MemoryPressureLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - MemoryPressureMonitor

/// メモリ使用量を監視し、プレッシャーレベルを報告するサービス
///
/// 主な機能:
/// - 現在のメモリ使用量の取得
/// - メモリプレッシャーレベルの判定
/// - 閾値に基づいた自動調整のサポート
///
/// ## 使用例
/// ```swift
/// let monitor = MemoryPressureMonitor()
///
/// if await monitor.currentPressureLevel() == .critical {
///     // 並列数を減らす等の対応
/// }
/// ```
public actor MemoryPressureMonitor {

    // MARK: - Configuration

    /// メモリ監視設定
    public struct Configuration: Sendable {
        /// 警告レベルのメモリ使用率（0.0〜1.0）
        public let warningThreshold: Double

        /// 危険レベルのメモリ使用率（0.0〜1.0）
        public let criticalThreshold: Double

        /// ポーリング間隔（秒）
        public let pollingInterval: TimeInterval

        /// デフォルト設定
        public static let `default` = Configuration(
            warningThreshold: 0.70,
            criticalThreshold: 0.85,
            pollingInterval: 1.0
        )

        /// 高感度設定（より早く警告）
        public static let sensitive = Configuration(
            warningThreshold: 0.60,
            criticalThreshold: 0.75,
            pollingInterval: 0.5
        )

        /// イニシャライザ
        public init(
            warningThreshold: Double,
            criticalThreshold: Double,
            pollingInterval: TimeInterval
        ) {
            precondition(warningThreshold > 0 && warningThreshold < 1, "warningThreshold must be between 0 and 1")
            precondition(criticalThreshold > warningThreshold && criticalThreshold < 1, "criticalThreshold must be between warningThreshold and 1")
            precondition(pollingInterval > 0, "pollingInterval must be positive")

            self.warningThreshold = warningThreshold
            self.criticalThreshold = criticalThreshold
            self.pollingInterval = pollingInterval
        }
    }

    // MARK: - Properties

    /// 設定
    private let configuration: Configuration

    /// 最後に取得したメモリ情報
    private var lastMemoryInfo: MemoryInfo?

    /// 監視タスク
    private var monitoringTask: Task<Void, Never>?

    /// プレッシャーレベル変更時のコールバック
    private var onPressureLevelChange: (@Sendable (MemoryPressureLevel) async -> Void)?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter configuration: 監視設定
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// 現在のメモリ使用情報を取得
    /// - Returns: メモリ使用情報
    public func currentMemoryInfo() -> MemoryInfo {
        let info = MemoryInfo.current()
        lastMemoryInfo = info
        return info
    }

    /// 現在のメモリプレッシャーレベルを取得
    /// - Returns: プレッシャーレベル
    public func currentPressureLevel() -> MemoryPressureLevel {
        let info = currentMemoryInfo()
        return pressureLevel(for: info.usedRatio)
    }

    /// 処理を続行しても安全かどうかを判定
    /// - Returns: 安全な場合true
    public func isSafeToProcess() -> Bool {
        currentPressureLevel() != .critical
    }

    /// プレッシャーレベルに基づいた推奨並列数を取得
    /// - Parameter baseParallelism: 基準並列数
    /// - Returns: 推奨並列数
    public func recommendedParallelism(base baseParallelism: Int) -> Int {
        let level = currentPressureLevel()

        switch level {
        case .normal:
            return baseParallelism
        case .warning:
            return max(1, baseParallelism / 2)
        case .critical:
            return 1
        }
    }

    /// メモリ監視を開始
    /// - Parameter onLevelChange: プレッシャーレベル変更時のコールバック
    public func startMonitoring(
        onLevelChange: @escaping @Sendable (MemoryPressureLevel) async -> Void
    ) {
        stopMonitoring()

        self.onPressureLevelChange = onLevelChange

        monitoringTask = Task { [weak self] in
            var lastLevel: MemoryPressureLevel = .normal

            while !Task.isCancelled {
                guard let self = self else { break }

                let currentLevel = await self.currentPressureLevel()

                if currentLevel != lastLevel {
                    await onLevelChange(currentLevel)
                    lastLevel = currentLevel
                }

                try? await Task.sleep(for: .seconds(self.configuration.pollingInterval))
            }
        }
    }

    /// メモリ監視を停止
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        onPressureLevelChange = nil
    }

    // MARK: - Private Methods

    /// 使用率からプレッシャーレベルを判定
    private func pressureLevel(for usedRatio: Double) -> MemoryPressureLevel {
        if usedRatio >= configuration.criticalThreshold {
            return .critical
        } else if usedRatio >= configuration.warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }

    deinit {
        monitoringTask?.cancel()
    }
}

// MARK: - MemoryInfo

/// メモリ使用情報
public struct MemoryInfo: Sendable, Equatable {

    /// 物理メモリ総量（バイト）
    public let totalPhysicalMemory: UInt64

    /// 使用中メモリ（バイト）
    public let usedMemory: UInt64

    /// 空きメモリ（バイト）
    public let freeMemory: UInt64

    /// アプリのメモリ使用量（バイト）
    public let appMemoryUsage: UInt64

    /// メモリ使用率（0.0〜1.0）
    public var usedRatio: Double {
        guard totalPhysicalMemory > 0 else { return 0 }
        return Double(usedMemory) / Double(totalPhysicalMemory)
    }

    /// アプリのメモリ使用率（0.0〜1.0）
    public var appMemoryRatio: Double {
        guard totalPhysicalMemory > 0 else { return 0 }
        return Double(appMemoryUsage) / Double(totalPhysicalMemory)
    }

    /// 人間が読みやすいフォーマットで使用メモリを表示
    public var formattedUsedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedMemory), countStyle: .memory)
    }

    /// 人間が読みやすいフォーマットでアプリメモリを表示
    public var formattedAppMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(appMemoryUsage), countStyle: .memory)
    }

    /// 現在のメモリ情報を取得
    public static func current() -> MemoryInfo {
        let totalPhysicalMemory = ProcessInfo.processInfo.physicalMemory
        let appMemoryUsage = getAppMemoryUsage()

        // システムのメモリ統計を取得
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { statsPointer in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    statsPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            // フォールバック: アプリメモリのみで計算
            return MemoryInfo(
                totalPhysicalMemory: totalPhysicalMemory,
                usedMemory: appMemoryUsage,
                freeMemory: totalPhysicalMemory - appMemoryUsage,
                appMemoryUsage: appMemoryUsage
            )
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let freeMemory = UInt64(vmStats.free_count) * pageSize
        let activeMemory = UInt64(vmStats.active_count) * pageSize
        let inactiveMemory = UInt64(vmStats.inactive_count) * pageSize
        let wiredMemory = UInt64(vmStats.wire_count) * pageSize

        let usedMemory = activeMemory + wiredMemory

        return MemoryInfo(
            totalPhysicalMemory: totalPhysicalMemory,
            usedMemory: usedMemory,
            freeMemory: freeMemory + inactiveMemory,
            appMemoryUsage: appMemoryUsage
        )
    }

    /// アプリのメモリ使用量を取得
    private static func getAppMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { infoPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    infoPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return info.phys_footprint
    }
}

// MARK: - MemoryInfo + CustomStringConvertible

extension MemoryInfo: CustomStringConvertible {
    public var description: String {
        """
        MemoryInfo(
            total: \(ByteCountFormatter.string(fromByteCount: Int64(totalPhysicalMemory), countStyle: .memory)),
            used: \(formattedUsedMemory) (\(String(format: "%.1f%%", usedRatio * 100))),
            app: \(formattedAppMemory) (\(String(format: "%.1f%%", appMemoryRatio * 100)))
        )
        """
    }
}

// MARK: - MemoryPressureLevel + CustomStringConvertible

extension MemoryPressureLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:
            return "normal"
        case .warning:
            return "warning"
        case .critical:
            return "critical"
        }
    }
}
