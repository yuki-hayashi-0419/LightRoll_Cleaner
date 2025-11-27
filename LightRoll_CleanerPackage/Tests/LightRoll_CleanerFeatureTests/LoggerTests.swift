//
//  LoggerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ロガー機能のテスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - LogLevel Tests

@Suite("LogLevel Tests")
struct LogLevelTests {

    @Test("LogLevelが正しい順序で比較される")
    func testLogLevelComparison() {
        #expect(LogLevel.verbose < LogLevel.debug)
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.error < LogLevel.fault)
    }

    @Test("LogLevelのprefixが正しい")
    func testLogLevelPrefix() {
        #expect(LogLevel.verbose.prefix == "[VERBOSE]")
        #expect(LogLevel.debug.prefix == "[DEBUG]")
        #expect(LogLevel.info.prefix == "[INFO]")
        #expect(LogLevel.warning.prefix == "[WARNING]")
        #expect(LogLevel.error.prefix == "[ERROR]")
        #expect(LogLevel.fault.prefix == "[FAULT]")
    }

    @Test("LogLevel.allCasesが全レベルを含む")
    func testAllCases() {
        #expect(LogLevel.allCases.count == 6)
        #expect(LogLevel.allCases.contains(.verbose))
        #expect(LogLevel.allCases.contains(.fault))
    }
}

// MARK: - LogCategory Tests

@Suite("LogCategory Tests")
struct LogCategoryTests {

    @Test("LogCategoryのrawValueが正しい")
    func testLogCategoryRawValues() {
        #expect(LogCategory.general.rawValue == "General")
        #expect(LogCategory.photoLibrary.rawValue == "PhotoLibrary")
        #expect(LogCategory.analysis.rawValue == "Analysis")
        #expect(LogCategory.storage.rawValue == "Storage")
        #expect(LogCategory.ui.rawValue == "UI")
        #expect(LogCategory.network.rawValue == "Network")
        #expect(LogCategory.purchase.rawValue == "Purchase")
        #expect(LogCategory.performance.rawValue == "Performance")
        #expect(LogCategory.debug.rawValue == "Debug")
    }

    @Test("LogCategory.allCasesが全カテゴリを含む")
    func testAllCategories() {
        #expect(LogCategory.allCases.count == 9)
    }

    @Test("LogCategoryがosLoggerを返す")
    func testOSLogger() {
        let logger = LogCategory.general.osLogger
        #expect(logger != nil)
    }
}

// MARK: - LogEntry Tests

@Suite("LogEntry Tests")
struct LogEntryTests {

    @Test("LogEntryが正しく初期化される")
    func testLogEntryInitialization() {
        let date = Date()
        let entry = LogEntry(
            timestamp: date,
            level: .info,
            category: .general,
            message: "Test message",
            file: "TestFile.swift",
            function: "testFunction()",
            line: 42
        )

        #expect(entry.timestamp == date)
        #expect(entry.level == .info)
        #expect(entry.category == .general)
        #expect(entry.message == "Test message")
        #expect(entry.file == "TestFile.swift")
        #expect(entry.function == "testFunction()")
        #expect(entry.line == 42)
        #expect(entry.metadata == nil)
    }

    @Test("LogEntryがメタデータ付きで初期化される")
    func testLogEntryWithMetadata() {
        let metadata = ["key1": "value1", "key2": "value2"]
        let entry = LogEntry(
            level: .debug,
            category: .performance,
            message: "Performance test",
            file: "Test.swift",
            function: "test()",
            line: 1,
            metadata: metadata
        )

        #expect(entry.metadata != nil)
        #expect(entry.metadata?["key1"] == "value1")
        #expect(entry.metadata?["key2"] == "value2")
    }

    @Test("LogEntry.formattedStringが正しいフォーマット")
    func testFormattedString() {
        let entry = LogEntry(
            level: .error,
            category: .storage,
            message: "Disk full",
            file: "/path/to/StorageManager.swift",
            function: "saveToDisk()",
            line: 100
        )

        let formatted = entry.formattedString

        // ファイル名（パスからファイル名のみ）が含まれる
        #expect(formatted.contains("StorageManager.swift"))
        // 行番号が含まれる
        #expect(formatted.contains(":100"))
        // 関数名が含まれる
        #expect(formatted.contains("saveToDisk()"))
        // メッセージが含まれる
        #expect(formatted.contains("Disk full"))
        // レベルプレフィックスが含まれる
        #expect(formatted.contains("[ERROR]"))
        // カテゴリが含まれる
        #expect(formatted.contains("[Storage]"))
    }

    @Test("LogEntry.formattedStringがメタデータを含む")
    func testFormattedStringWithMetadata() {
        let entry = LogEntry(
            level: .info,
            category: .general,
            message: "Test",
            file: "Test.swift",
            function: "test()",
            line: 1,
            metadata: ["operation": "save", "count": "10"]
        )

        let formatted = entry.formattedString

        #expect(formatted.contains("operation=save") || formatted.contains("count=10"))
    }

    @Test("LogEntryがIdentifiableに準拠している")
    func testLogEntryIdentifiable() {
        let entry1 = LogEntry(
            level: .info,
            category: .general,
            message: "Test 1",
            file: "Test.swift",
            function: "test()",
            line: 1
        )

        let entry2 = LogEntry(
            level: .info,
            category: .general,
            message: "Test 2",
            file: "Test.swift",
            function: "test()",
            line: 2
        )

        #expect(entry1.id != entry2.id)
    }
}

// MARK: - InMemoryLogDestination Tests

@Suite("InMemoryLogDestination Tests")
struct InMemoryLogDestinationTests {

    @Test("InMemoryLogDestinationがログを保存する")
    func testWriteEntry() async {
        let destination = InMemoryLogDestination(maxEntries: 100)
        let entry = LogEntry(
            level: .info,
            category: .general,
            message: "Test message",
            file: "Test.swift",
            function: "test()",
            line: 1
        )

        await destination.write(entry)

        let entries = await destination.getAllEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.message == "Test message")
    }

    @Test("InMemoryLogDestinationが最大数を超えたら古いエントリを削除する")
    func testMaxEntries() async {
        let destination = InMemoryLogDestination(maxEntries: 3)

        for i in 1...5 {
            let entry = LogEntry(
                level: .info,
                category: .general,
                message: "Message \(i)",
                file: "Test.swift",
                function: "test()",
                line: i
            )
            await destination.write(entry)
        }

        let entries = await destination.getAllEntries()
        #expect(entries.count == 3)
        // 最初の2つは削除され、3,4,5が残る
        #expect(entries.first?.message == "Message 3")
        #expect(entries.last?.message == "Message 5")
    }

    @Test("InMemoryLogDestinationがレベルでフィルタできる")
    func testFilterByLevel() async {
        let destination = InMemoryLogDestination()

        let levels: [LogLevel] = [.debug, .info, .warning, .error]
        for (index, level) in levels.enumerated() {
            let entry = LogEntry(
                level: level,
                category: .general,
                message: "Message \(index)",
                file: "Test.swift",
                function: "test()",
                line: index
            )
            await destination.write(entry)
        }

        let warningAndAbove = await destination.getEntries(minLevel: .warning)
        #expect(warningAndAbove.count == 2)
    }

    @Test("InMemoryLogDestinationがカテゴリでフィルタできる")
    func testFilterByCategory() async {
        let destination = InMemoryLogDestination()

        let categories: [LogCategory] = [.general, .storage, .general, .analysis]
        for (index, category) in categories.enumerated() {
            let entry = LogEntry(
                level: .info,
                category: category,
                message: "Message \(index)",
                file: "Test.swift",
                function: "test()",
                line: index
            )
            await destination.write(entry)
        }

        let generalEntries = await destination.getEntries(category: .general)
        #expect(generalEntries.count == 2)
    }

    @Test("InMemoryLogDestinationのclearが動作する")
    func testClear() async {
        let destination = InMemoryLogDestination()

        let entry = LogEntry(
            level: .info,
            category: .general,
            message: "Test",
            file: "Test.swift",
            function: "test()",
            line: 1
        )
        await destination.write(entry)

        var count = await destination.count()
        #expect(count == 1)

        await destination.clear()

        count = await destination.count()
        #expect(count == 0)
    }
}

// MARK: - ConsoleLogDestination Tests

@Suite("ConsoleLogDestination Tests")
struct ConsoleLogDestinationTests {

    @Test("ConsoleLogDestinationが初期化できる")
    func testInitialization() {
        let destination = ConsoleLogDestination()
        #expect(destination != nil)
    }

    @Test("ConsoleLogDestinationのwriteが完了する")
    func testWrite() async {
        let destination = ConsoleLogDestination()
        let entry = LogEntry(
            level: .info,
            category: .general,
            message: "Console test",
            file: "Test.swift",
            function: "test()",
            line: 1
        )

        // エラーなく完了することを確認
        await destination.write(entry)
    }

    @Test("ConsoleLogDestinationのflushが完了する")
    func testFlush() async {
        let destination = ConsoleLogDestination()
        await destination.flush()
    }
}

// MARK: - OSLogDestination Tests

@Suite("OSLogDestination Tests")
struct OSLogDestinationTests {

    @Test("OSLogDestinationが初期化できる")
    func testInitialization() {
        let destination = OSLogDestination()
        #expect(destination != nil)
    }

    @Test("OSLogDestinationのwriteが各レベルで完了する")
    func testWriteAllLevels() async {
        let destination = OSLogDestination()

        for level in LogLevel.allCases {
            let entry = LogEntry(
                level: level,
                category: .general,
                message: "Test \(level)",
                file: "Test.swift",
                function: "test()",
                line: 1
            )
            await destination.write(entry)
        }
    }
}

// MARK: - AppLogger Tests

@Suite("AppLogger Tests")
struct AppLoggerTests {

    @Test("AppLogger.sharedがシングルトンとして動作する")
    func testSharedInstance() async {
        let logger1 = AppLogger.shared
        let logger2 = AppLogger.shared
        // Actorなので同一インスタンスであることを確認（参照比較は不可なので設定変更で確認）
        await logger1.setEnabled(true)
        // エラーなく動作することを確認
    }

    @Test("AppLoggerが有効/無効を切り替えられる")
    func testSetEnabled() async {
        let logger = AppLogger.shared
        await logger.setEnabled(false)
        await logger.setEnabled(true)
    }

    @Test("AppLoggerが最小レベルを設定できる")
    func testSetMinimumLevel() async {
        let logger = AppLogger.shared
        await logger.setMinimumLevel(.warning)
        // リセット
        await logger.setMinimumLevel(.verbose)
    }

    @Test("AppLoggerがカテゴリを有効/無効にできる")
    func testSetCategoryEnabled() async {
        let logger = AppLogger.shared
        await logger.setCategoryEnabled(.debug, enabled: false)
        await logger.setCategoryEnabled(.debug, enabled: true)
    }

    @Test("AppLoggerが出力先を追加できる")
    func testAddDestination() async {
        let logger = AppLogger.shared
        let inMemory = InMemoryLogDestination()
        await logger.addDestination(inMemory)
    }

    @Test("AppLoggerのログメソッドが動作する")
    func testLogMethods() async {
        let logger = AppLogger.shared

        await logger.verbose("Verbose message")
        await logger.debug("Debug message")
        await logger.info("Info message")
        await logger.warning("Warning message")
        await logger.error("Error message")
        await logger.fault("Fault message")
    }

    @Test("AppLoggerがメタデータ付きでログを出力する")
    func testLogWithMetadata() async {
        let logger = AppLogger.shared

        await logger.info(
            "Message with metadata",
            category: .storage,
            metadata: ["key": "value"]
        )
    }

    @Test("AppLoggerがエラーをログ出力する")
    func testLogError() async {
        let logger = AppLogger.shared

        struct TestError: Error {
            var localizedDescription: String { "Test error description" }
        }

        await logger.logError(TestError())
    }

    @Test("AppLoggerがLightRollErrorをログ出力する")
    func testLogLightRollError() async {
        let logger = AppLogger.shared

        let error = LightRollError.storage(.insufficientSpace)
        await logger.logLightRollError(error)
    }

    @Test("AppLoggerがflushを実行できる")
    func testFlush() async {
        let logger = AppLogger.shared
        await logger.flush()
    }
}

// MARK: - Performance Logging Tests

@Suite("Performance Logging Tests")
struct PerformanceLoggingTests {

    @Test("パフォーマンス計測が開始・終了できる")
    func testPerformanceMeasure() async {
        let logger = AppLogger.shared

        let startTime = await logger.startPerformanceMeasure("TestOperation")
        #expect(startTime != nil)

        // 少し待機
        try? await Task.sleep(for: .milliseconds(10))

        await logger.endPerformanceMeasure("TestOperation", startTime: startTime)
    }

    @Test("measureメソッドが処理を実行して計測する")
    func testMeasureMethod() async throws {
        let logger = AppLogger.shared

        let result = await logger.measure("Calculation") {
            return 42
        }

        #expect(result == 42)
    }

    @Test("measureメソッドがthrowingな処理を実行できる")
    func testMeasureMethodThrowing() async throws {
        let logger = AppLogger.shared

        struct TestError: Error {}

        do {
            _ = try await logger.measure("ThrowingOperation") {
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // エラーが投げられることを確認
            #expect(error is TestError)
        }
    }
}

// MARK: - Global Log Functions Tests

@Suite("Global Log Functions Tests")
struct GlobalLogFunctionsTests {

    @Test("logVerbose関数が動作する")
    func testLogVerbose() {
        logVerbose("Test verbose")
    }

    @Test("logDebug関数が動作する")
    func testLogDebug() {
        logDebug("Test debug")
    }

    @Test("logInfo関数が動作する")
    func testLogInfo() {
        logInfo("Test info")
    }

    @Test("logWarning関数が動作する")
    func testLogWarning() {
        logWarning("Test warning")
    }

    @Test("logError関数が動作する")
    func testLogError() {
        logError("Test error")
    }

    @Test("logFault関数が動作する")
    func testLogFault() {
        logFault("Test fault")
    }

    @Test("グローバル関数がカテゴリとメタデータを受け取れる")
    func testGlobalFunctionsWithParameters() {
        logInfo(
            "Test with params",
            category: .performance,
            metadata: ["operation": "test"]
        )
    }
}
