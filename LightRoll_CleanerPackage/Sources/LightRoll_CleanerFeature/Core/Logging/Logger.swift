//
//  Logger.swift
//  LightRoll_CleanerFeature
//
//  アプリケーション全体のロギング機能を提供
//  OSLogを使用した統合ログシステム
//  Created by AI Assistant
//

import Foundation
import OSLog

// MARK: - LogCategory

/// ログカテゴリの定義
/// 機能別にログを分類するための列挙型
public enum LogCategory: String, CaseIterable, Sendable {
    /// 一般的なアプリケーションログ
    case general = "General"

    /// 写真ライブラリ関連のログ
    case photoLibrary = "PhotoLibrary"

    /// 画像分析関連のログ
    case analysis = "Analysis"

    /// ストレージ関連のログ
    case storage = "Storage"

    /// UI関連のログ
    case ui = "UI"

    /// ネットワーク関連のログ
    case network = "Network"

    /// 課金・購入関連のログ
    case purchase = "Purchase"

    /// パフォーマンス計測のログ
    case performance = "Performance"

    /// デバッグ用のログ
    case debug = "Debug"

    /// サブシステム識別子を取得
    var subsystem: String {
        Bundle.main.bundleIdentifier ?? "com.lightroll.cleaner"
    }

    /// OSLoggerインスタンスを取得
    var osLogger: os.Logger {
        os.Logger(subsystem: subsystem, category: rawValue)
    }
}

// MARK: - LogLevel

/// ログレベルの定義
public enum LogLevel: Int, Comparable, CaseIterable, Sendable {
    /// 詳細なデバッグ情報
    case verbose = 0

    /// デバッグ情報
    case debug = 1

    /// 一般的な情報
    case info = 2

    /// 警告（問題の可能性があるが動作は継続）
    case warning = 3

    /// エラー（問題が発生したが回復可能）
    case error = 4

    /// 致命的エラー（アプリケーションの継続が困難）
    case fault = 5

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 表示用のプレフィックス
    var prefix: String {
        switch self {
        case .verbose: return "[VERBOSE]"
        case .debug:   return "[DEBUG]"
        case .info:    return "[INFO]"
        case .warning: return "[WARNING]"
        case .error:   return "[ERROR]"
        case .fault:   return "[FAULT]"
        }
    }

    /// 対応するOSLogType
    var osLogType: OSLogType {
        switch self {
        case .verbose: return .debug
        case .debug:   return .debug
        case .info:    return .info
        case .warning: return .default
        case .error:   return .error
        case .fault:   return .fault
        }
    }
}

// MARK: - LogEntry

/// ログエントリ
/// 個々のログメッセージを表現する構造体
public struct LogEntry: Identifiable, Sendable {
    /// 一意識別子
    public let id: UUID

    /// タイムスタンプ
    public let timestamp: Date

    /// ログレベル
    public let level: LogLevel

    /// ログカテゴリ
    public let category: LogCategory

    /// メッセージ本文
    public let message: String

    /// ファイル名
    public let file: String

    /// 関数名
    public let function: String

    /// 行番号
    public let line: Int

    /// メタデータ（追加情報）
    public let metadata: [String: String]?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        category: LogCategory,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }

    /// フォーマット済みのログ文字列
    public var formattedString: String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timeString = dateFormatter.string(from: timestamp)

        let fileName = (file as NSString).lastPathComponent
        var result = "\(timeString) \(level.prefix) [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"

        if let metadata = metadata, !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            result += " {\(metaString)}"
        }

        return result
    }
}

// MARK: - LogDestination Protocol

/// ログ出力先のプロトコル
public protocol LogDestination: Sendable {
    /// ログを出力
    /// - Parameter entry: ログエントリ
    func write(_ entry: LogEntry) async

    /// 出力先をフラッシュ
    func flush() async
}

// MARK: - ConsoleLogDestination

/// コンソール出力先
public final class ConsoleLogDestination: LogDestination, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.lightroll.logger.console")

    public init() {}

    public func write(_ entry: LogEntry) async {
        await withCheckedContinuation { continuation in
            queue.async {
                print(entry.formattedString)
                continuation.resume()
            }
        }
    }

    public func flush() async {
        // コンソールはフラッシュ不要
    }
}

// MARK: - OSLogDestination

/// OSLog出力先
public final class OSLogDestination: LogDestination, @unchecked Sendable {
    public init() {}

    public func write(_ entry: LogEntry) async {
        let logger = entry.category.osLogger
        let message = "[\(entry.file):\(entry.line)] \(entry.function) - \(entry.message)"

        switch entry.level {
        case .verbose, .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        }
    }

    public func flush() async {
        // OSLogはフラッシュ不要
    }
}

// MARK: - InMemoryLogDestination

/// メモリ内ログ保存先（デバッグ用）
public actor InMemoryLogDestination: LogDestination {
    /// 保存されたログエントリ
    private var entries: [LogEntry] = []

    /// 最大保存数
    private let maxEntries: Int

    public init(maxEntries: Int = 1000) {
        self.maxEntries = maxEntries
    }

    public func write(_ entry: LogEntry) async {
        entries.append(entry)

        // 最大数を超えたら古いエントリを削除
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    public func flush() async {
        // メモリ内なのでフラッシュ不要
    }

    /// 全エントリを取得
    public func getAllEntries() -> [LogEntry] {
        entries
    }

    /// 特定レベル以上のエントリを取得
    public func getEntries(minLevel: LogLevel) -> [LogEntry] {
        entries.filter { $0.level >= minLevel }
    }

    /// 特定カテゴリのエントリを取得
    public func getEntries(category: LogCategory) -> [LogEntry] {
        entries.filter { $0.category == category }
    }

    /// エントリをクリア
    public func clear() {
        entries.removeAll()
    }

    /// エントリ数を取得
    public func count() -> Int {
        entries.count
    }
}

// MARK: - Logger

/// アプリケーション全体のロガー
/// シングルトンパターンで実装し、複数の出力先をサポート
public actor AppLogger {
    // MARK: - Singleton

    /// 共有インスタンス
    public static let shared = AppLogger()

    // MARK: - Properties

    /// 最小ログレベル（これ以上のレベルのみ出力）
    private var minimumLevel: LogLevel

    /// ログ出力先のリスト
    private var destinations: [any LogDestination]

    /// ロギングが有効かどうか
    private var isEnabled: Bool

    /// カテゴリ別の有効/無効設定
    private var categoryEnabled: [LogCategory: Bool]

    // MARK: - Initialization

    private init() {
        #if DEBUG
        self.minimumLevel = .verbose
        self.isEnabled = true
        self.destinations = [
            ConsoleLogDestination(),
            OSLogDestination()
        ]
        #else
        self.minimumLevel = .info
        self.isEnabled = true
        self.destinations = [OSLogDestination()]
        #endif

        // デフォルトで全カテゴリを有効化
        self.categoryEnabled = Dictionary(
            uniqueKeysWithValues: LogCategory.allCases.map { ($0, true) }
        )
    }

    // MARK: - Configuration

    /// 最小ログレベルを設定
    /// - Parameter level: 最小ログレベル
    public func setMinimumLevel(_ level: LogLevel) {
        minimumLevel = level
    }

    /// ロギングの有効/無効を設定
    /// - Parameter enabled: 有効にする場合はtrue
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// 出力先を追加
    /// - Parameter destination: 追加する出力先
    public func addDestination(_ destination: any LogDestination) {
        destinations.append(destination)
    }

    /// 出力先をクリア
    public func clearDestinations() {
        destinations.removeAll()
    }

    /// カテゴリの有効/無効を設定
    /// - Parameters:
    ///   - category: 対象カテゴリ
    ///   - enabled: 有効にする場合はtrue
    public func setCategoryEnabled(_ category: LogCategory, enabled: Bool) {
        categoryEnabled[category] = enabled
    }

    // MARK: - Logging Methods

    /// ログを出力
    /// - Parameters:
    ///   - level: ログレベル
    ///   - category: カテゴリ
    ///   - message: メッセージ
    ///   - metadata: メタデータ
    ///   - file: ファイル名（自動取得）
    ///   - function: 関数名（自動取得）
    ///   - line: 行番号（自動取得）
    public func log(
        _ level: LogLevel,
        category: LogCategory,
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // ロギングが無効の場合はスキップ
        guard isEnabled else { return }

        // レベルチェック
        guard level >= minimumLevel else { return }

        // カテゴリが無効の場合はスキップ
        guard categoryEnabled[category] ?? true else { return }

        let entry = LogEntry(
            level: level,
            category: category,
            message: message(),
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )

        // 全出力先に書き込み
        for destination in destinations {
            await destination.write(entry)
        }
    }

    /// 全出力先をフラッシュ
    public func flush() async {
        for destination in destinations {
            await destination.flush()
        }
    }
}

// MARK: - Convenience Methods

extension AppLogger {
    /// Verboseログを出力
    public func verbose(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.verbose, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }

    /// Debugログを出力
    public func debug(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.debug, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }

    /// Infoログを出力
    public func info(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.info, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }

    /// Warningログを出力
    public func warning(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.warning, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }

    /// Errorログを出力
    public func error(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.error, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }

    /// Faultログを出力
    public func fault(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(.fault, category: category, message(), metadata: metadata, file: file, function: function, line: line)
    }
}

// MARK: - Error Logging

extension AppLogger {
    /// エラーをログ出力
    /// - Parameters:
    ///   - error: エラーオブジェクト
    ///   - category: カテゴリ
    ///   - file: ファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    public func logError(
        _ error: Error,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        let metadata: [String: String] = [
            "errorType": String(describing: type(of: error)),
            "localizedDescription": error.localizedDescription
        ]

        await log(
            .error,
            category: category,
            "Error occurred: \(error.localizedDescription)",
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }

    /// LightRollErrorをログ出力
    /// - Parameters:
    ///   - error: LightRollErrorオブジェクト
    ///   - file: ファイル名
    ///   - function: 関数名
    ///   - line: 行番号
    public func logLightRollError(
        _ error: LightRollError,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        let category: LogCategory
        var metadata: [String: String] = [
            "errorDescription": error.errorDescription ?? "N/A"
        ]

        if let failureReason = error.failureReason {
            metadata["failureReason"] = failureReason
        }

        if let recoverySuggestion = error.recoverySuggestion {
            metadata["recoverySuggestion"] = recoverySuggestion
        }

        switch error {
        case .photoLibrary:
            category = .photoLibrary
        case .analysis:
            category = .analysis
        case .storage:
            category = .storage
        case .configuration:
            category = .general
        case .unknown:
            category = .general
        }

        await log(
            .error,
            category: category,
            "LightRollError: \(error.errorDescription ?? "Unknown error")",
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

// MARK: - Performance Logging

extension AppLogger {
    /// パフォーマンス計測を開始
    /// - Parameter operation: 操作名
    /// - Returns: 開始時刻
    public func startPerformanceMeasure(_ operation: String) async -> Date {
        let startTime = Date()
        await debug(
            "Starting: \(operation)",
            category: .performance,
            metadata: ["operation": operation]
        )
        return startTime
    }

    /// パフォーマンス計測を終了
    /// - Parameters:
    ///   - operation: 操作名
    ///   - startTime: 開始時刻
    public func endPerformanceMeasure(_ operation: String, startTime: Date) async {
        let duration = Date().timeIntervalSince(startTime)
        let durationString = String(format: "%.3f", duration)

        await info(
            "Completed: \(operation) in \(durationString)s",
            category: .performance,
            metadata: [
                "operation": operation,
                "duration": durationString
            ]
        )
    }

    /// 操作の実行時間を計測してログ出力
    /// - Parameters:
    ///   - operation: 操作名
    ///   - block: 計測対象の処理
    /// - Returns: 処理の戻り値
    public func measure<T>(
        _ operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let startTime = await startPerformanceMeasure(operation)
        defer {
            Task {
                await endPerformanceMeasure(operation, startTime: startTime)
            }
        }
        return try await block()
    }
}

// MARK: - Global Logger Functions

/// グローバルログ関数（便利関数）
/// Swift 6のStrict Concurrency対応のため、メッセージを先に評価してからTaskに渡す

/// Verboseログを出力
public func logVerbose(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .verbose,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Debugログを出力
public func logDebug(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .debug,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Infoログを出力
public func logInfo(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .info,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Warningログを出力
public func logWarning(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .warning,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Errorログを出力
public func logError(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .error,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

/// Faultログを出力
public func logFault(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    metadata: [String: String]? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let evaluatedMessage = message()
    Task {
        await AppLogger.shared.log(
            .fault,
            category: category,
            evaluatedMessage,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}
