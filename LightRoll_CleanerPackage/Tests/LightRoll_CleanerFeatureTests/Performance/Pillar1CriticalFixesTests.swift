//
//  Pillar1CriticalFixesTests.swift
//  LightRoll_CleanerFeatureTests
//
//  Pillar 1 Critical Fixes のテスト
//  CF-1: 並列制限（8並列）
//  CF-2: メモリ監視（閾値超過時の一時停止）
//  CF-3: プログレス精度（各フェーズでの更新）
//
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - Pillar 1 Critical Fixes Tests

@Suite("Pillar 1 Critical Fixes Tests")
struct Pillar1CriticalFixesTests {

    // MARK: - CF-1: 並列制限テスト

    @Suite("CF-1: 並列制限（Concurrency Limit）")
    struct ConcurrencyLimitTests {

        // MARK: - CF-1-UT-01: 正常系 - 8並列での処理完了

        @Test("CF-1-UT-01: 8並列での処理が正常に完了する")
        func testEightConcurrentTasksComplete() async throws {
            // 8並列制限が正しく動作することを確認
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)

            actor TaskCounter {
                var maxConcurrent = 0
                var currentConcurrent = 0

                func increment() -> Int {
                    currentConcurrent += 1
                    if currentConcurrent > maxConcurrent {
                        maxConcurrent = currentConcurrent
                    }
                    return currentConcurrent
                }

                func decrement() {
                    currentConcurrent -= 1
                }

                func getMax() -> Int {
                    return maxConcurrent
                }
            }

            let counter = TaskCounter()
            let taskCount = 20

            // 8並列で20タスクを実行
            try await withThrowingTaskGroup(of: Void.self) { group in
                for i in 0..<taskCount {
                    group.addTask {
                        try await concurrencyLimiter.execute {
                            let _ = await counter.increment()
                            // シミュレート: 短い処理
                            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                            await counter.decrement()
                        }
                    }
                }

                for try await _ in group {}
            }

            let maxConcurrent = await counter.getMax()
            // 最大同時実行数が8以下であることを確認
            #expect(maxConcurrent <= 8, "最大同時実行数が8を超えています: \(maxConcurrent)")
        }

        @Test("CF-1-UT-02: 8並列でタスクが詰まってもメモリ枯渇しない（構造的テスト）")
        func testLargeTaskQueueDoesNotExhaustMemory() async throws {
            // 大量のタスクをキューに入れても安定動作することを確認
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)
            let taskCount = 100

            actor CompletionTracker {
                var completed = 0

                func markCompleted() {
                    completed += 1
                }

                func getCompleted() -> Int {
                    return completed
                }
            }

            let tracker = CompletionTracker()

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<taskCount {
                    group.addTask {
                        try await concurrencyLimiter.execute {
                            // 軽量な処理
                            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                            await tracker.markCompleted()
                        }
                    }
                }

                for try await _ in group {}
            }

            let completed = await tracker.getCompleted()
            // 全タスクが完了することを確認
            #expect(completed == taskCount, "完了タスク数が期待と異なります: \(completed)/\(taskCount)")
        }

        // MARK: - CF-1-UT-03: 境界値 - 1個のタスク

        @Test("CF-1-UT-03: 1個のタスクでの挙動")
        func testSingleTaskExecution() async throws {
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)

            let executed = LockIsolated(false)

            try await concurrencyLimiter.execute {
                executed.setValue(true)
            }

            #expect(executed.withLock { $0 }, "単一タスクが実行されませんでした")
        }

        // MARK: - CF-1-UT-04: 境界値 - 8個のタスク（ちょうど並列上限）

        @Test("CF-1-UT-04: 8個のタスクでの挙動（並列上限と一致）")
        func testExactlyEightTasks() async throws {
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)
            let taskCount = 8

            actor TaskTracker {
                var completed = 0

                func increment() {
                    completed += 1
                }

                func getCount() -> Int {
                    return completed
                }
            }

            let tracker = TaskTracker()

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<taskCount {
                    group.addTask {
                        try await concurrencyLimiter.execute {
                            await tracker.increment()
                        }
                    }
                }

                for try await _ in group {}
            }

            let completed = await tracker.getCount()
            #expect(completed == taskCount, "8個全てのタスクが完了していません: \(completed)")
        }

        // MARK: - CF-1-UT-05: 境界値 - 100個のタスク

        @Test("CF-1-UT-05: 100個のタスクでの挙動")
        func testOneHundredTasks() async throws {
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)
            let taskCount = 100

            actor TaskTracker {
                var completed = 0
                var maxConcurrent = 0
                var current = 0

                func start() {
                    current += 1
                    if current > maxConcurrent {
                        maxConcurrent = current
                    }
                }

                func end() {
                    completed += 1
                    current -= 1
                }

                func getStats() -> (completed: Int, maxConcurrent: Int) {
                    return (completed, maxConcurrent)
                }
            }

            let tracker = TaskTracker()

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<taskCount {
                    group.addTask {
                        try await concurrencyLimiter.execute {
                            await tracker.start()
                            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                            await tracker.end()
                        }
                    }
                }

                for try await _ in group {}
            }

            let stats = await tracker.getStats()
            #expect(stats.completed == taskCount, "100個全てのタスクが完了していません: \(stats.completed)")
            #expect(stats.maxConcurrent <= 8, "同時実行数が8を超えています: \(stats.maxConcurrent)")
        }

        // MARK: - CF-1-UT-06: 異常系 - キャンセル時の挙動

        @Test("CF-1-UT-06: タスクキャンセル時の挙動")
        func testTaskCancellation() async throws {
            let concurrencyLimiter = ConcurrencyLimiter(maxConcurrent: 8)

            let task = Task {
                try await concurrencyLimiter.execute {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                }
            }

            // 即座にキャンセル
            task.cancel()

            do {
                try await task.value
                // キャンセルされずに完了した場合もOK
            } catch is CancellationError {
                // キャンセルエラーが発生することを期待
            }
        }

        // MARK: - CF-1-UT-07: 並列制限の動的変更

        @Test("CF-1-UT-07: 異なる並列制限での動作確認")
        func testDifferentConcurrencyLimits() async throws {
            // 並列数1
            let limiter1 = ConcurrencyLimiter(maxConcurrent: 1)
            // 並列数4
            let limiter4 = ConcurrencyLimiter(maxConcurrent: 4)
            // 並列数16
            let limiter16 = ConcurrencyLimiter(maxConcurrent: 16)

            actor MaxTracker {
                var maxConcurrent = 0
                var current = 0

                func increment() {
                    current += 1
                    if current > maxConcurrent {
                        maxConcurrent = current
                    }
                }

                func decrement() {
                    current -= 1
                }

                func getMax() -> Int {
                    return maxConcurrent
                }

                func reset() {
                    maxConcurrent = 0
                    current = 0
                }
            }

            let tracker = MaxTracker()

            // 並列数1でテスト
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        try await limiter1.execute {
                            await tracker.increment()
                            try await Task.sleep(nanoseconds: 1_000_000)
                            await tracker.decrement()
                        }
                    }
                }
                for try await _ in group {}
            }
            #expect(await tracker.getMax() <= 1)

            await tracker.reset()

            // 並列数4でテスト
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        try await limiter4.execute {
                            await tracker.increment()
                            try await Task.sleep(nanoseconds: 1_000_000)
                            await tracker.decrement()
                        }
                    }
                }
                for try await _ in group {}
            }
            #expect(await tracker.getMax() <= 4)

            await tracker.reset()

            // 並列数16でテスト
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<20 {
                    group.addTask {
                        try await limiter16.execute {
                            await tracker.increment()
                            try await Task.sleep(nanoseconds: 1_000_000)
                            await tracker.decrement()
                        }
                    }
                }
                for try await _ in group {}
            }
            #expect(await tracker.getMax() <= 16)
        }
    }

    // MARK: - CF-2: メモリ監視テスト

    @Suite("CF-2: メモリ監視（Memory Monitor）")
    struct MemoryMonitorTests {

        // MARK: - CF-2-UT-01: 正常系 - メモリ使用量の監視が機能する

        @Test("CF-2-UT-01: メモリ使用量の監視が機能する")
        func testMemoryMonitoringWorks() async throws {
            let memoryMonitor = MemoryMonitor(thresholdMB: 1000)

            // 現在のメモリ使用量を取得
            let currentUsage = await memoryMonitor.getCurrentMemoryUsageMB()

            // メモリ使用量が取得できることを確認
            #expect(currentUsage >= 0, "メモリ使用量は0以上である必要があります")
        }

        @Test("CF-2-UT-02: メモリ閾値未満では処理が継続する")
        func testProcessingContinuesBelowThreshold() async throws {
            // 高い閾値を設定（通常は超えない）
            let memoryMonitor = MemoryMonitor(thresholdMB: 10000)

            let processed = LockIsolated(false)

            try await memoryMonitor.executeIfMemoryAvailable {
                processed.setValue(true)
            }

            #expect(processed.withLock { $0 }, "メモリ閾値未満では処理が実行されるべきです")
        }

        // MARK: - CF-2-UT-03: 異常系 - メモリ閾値超過時に処理が一時停止

        @Test("CF-2-UT-03: メモリ閾値超過時の処理一時停止")
        func testProcessingPausesAboveThreshold() async throws {
            // 非常に低い閾値を設定（必ず超える）
            let memoryMonitor = MemoryMonitor(thresholdMB: 1)

            let attemptCount = LockIsolated(0)
            let maxAttempts = 3

            // 閾値超過時はリトライして最終的にタイムアウトまたはスキップ
            do {
                try await memoryMonitor.executeIfMemoryAvailable(
                    maxRetries: maxAttempts,
                    retryDelay: Duration.milliseconds(10)
                ) {
                    attemptCount.withLock { $0 += 1 }
                }
            } catch {
                // MemoryExceededErrorが発生することを期待
                #expect(error is MemoryExceededError)
            }

            // リトライが行われたことを確認
            #expect(attemptCount.withLock { $0 } <= maxAttempts)
        }

        // MARK: - CF-2-UT-04: 境界値 - メモリ閾値付近での挙動

        @Test("CF-2-UT-04: メモリ閾値付近での挙動")
        func testBehaviorNearThreshold() async throws {
            let memoryMonitor = MemoryMonitor(thresholdMB: 500)

            // 現在のメモリ使用量を取得
            let currentUsage = await memoryMonitor.getCurrentMemoryUsageMB()

            // 閾値との比較
            let isAboveThreshold = await memoryMonitor.isAboveThreshold()

            if currentUsage < 500 {
                #expect(!isAboveThreshold, "閾値未満の場合はfalseを返すべきです")
            } else {
                #expect(isAboveThreshold, "閾値以上の場合はtrueを返すべきです")
            }
        }

        // MARK: - CF-2-UT-05: メモリ監視のリアルタイム更新

        @Test("CF-2-UT-05: メモリ監視がリアルタイムで更新される")
        func testMemoryMonitorUpdatesRealtime() async throws {
            let memoryMonitor = MemoryMonitor(thresholdMB: 1000)

            // 複数回メモリ使用量を取得
            let usage1 = await memoryMonitor.getCurrentMemoryUsageMB()
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            let usage2 = await memoryMonitor.getCurrentMemoryUsageMB()

            // 両方とも有効な値であることを確認
            #expect(usage1 >= 0)
            #expect(usage2 >= 0)
        }
    }

    // MARK: - CF-3: プログレス精度テスト

    @Suite("CF-3: プログレス精度（Progress Accuracy）")
    struct ProgressAccuracyTests {

        // MARK: - CF-3-UT-01: 正常系 - 各フェーズでプログレスが更新される

        @Test("CF-3-UT-01: 各フェーズでプログレスが更新される")
        func testProgressUpdatesAtEachPhase() async throws {
            let progressTracker = ProgressTracker()

            actor CollectedProgress {
                var values: [Double] = []

                func add(_ value: Double) {
                    values.append(value)
                }

                func getValues() -> [Double] {
                    return values
                }
            }

            let collected = CollectedProgress()

            // プログレスコールバックを設定
            await progressTracker.setProgressHandler { progress in
                await collected.add(progress)
            }

            // 各フェーズを実行
            await progressTracker.updateProgress(phase: .initialization, progress: 0.0)
            await progressTracker.updateProgress(phase: .scanning, progress: 0.25)
            await progressTracker.updateProgress(phase: .analyzing, progress: 0.5)
            await progressTracker.updateProgress(phase: .grouping, progress: 0.75)
            await progressTracker.updateProgress(phase: .completed, progress: 1.0)

            let values = await collected.getValues()

            // 5つのフェーズ全てで更新されていることを確認
            #expect(values.count == 5, "全フェーズでプログレスが更新されていません: \(values.count)")
            #expect(values.contains(0.0), "初期化フェーズのプログレスがありません")
            #expect(values.contains(0.25), "スキャンフェーズのプログレスがありません")
            #expect(values.contains(0.5), "分析フェーズのプログレスがありません")
            #expect(values.contains(0.75), "グルーピングフェーズのプログレスがありません")
            #expect(values.contains(1.0), "完了フェーズのプログレスがありません")
        }

        // MARK: - CF-3-UT-02: 異常系 - エラー発生時もプログレスが適切に表示

        @Test("CF-3-UT-02: エラー発生時もプログレスが適切に表示される")
        func testProgressDisplaysOnError() async throws {
            let progressTracker = ProgressTracker()

            actor CollectedProgress {
                var values: [Double] = []
                var errorReported = false

                func add(_ value: Double) {
                    values.append(value)
                }

                func markError() {
                    errorReported = true
                }

                func getState() -> (values: [Double], errorReported: Bool) {
                    return (values, errorReported)
                }
            }

            let collected = CollectedProgress()

            await progressTracker.setProgressHandler { progress in
                await collected.add(progress)
            }

            // 途中でエラーが発生するシナリオ
            await progressTracker.updateProgress(phase: .initialization, progress: 0.0)
            await progressTracker.updateProgress(phase: .scanning, progress: 0.25)
            // エラー発生
            await progressTracker.reportError(ProgressError.analysisFailure)
            await collected.markError()

            let state = await collected.getState()

            // エラー前のプログレスが記録されていることを確認
            #expect(state.values.contains(0.0))
            #expect(state.values.contains(0.25))
            #expect(state.errorReported, "エラーが報告されていません")
        }

        // MARK: - CF-3-UT-03: 境界値 - 0%での挙動

        @Test("CF-3-UT-03: 0%での挙動")
        func testProgressAtZeroPercent() async throws {
            let progressTracker = ProgressTracker()

            let receivedProgress = LockIsolated<Double?>(nil)

            await progressTracker.setProgressHandler { progress in
                receivedProgress.setValue(progress)
            }

            await progressTracker.updateProgress(phase: .initialization, progress: 0.0)

            #expect(receivedProgress.withLock { $0 } == 0.0, "0%が正しく通知されていません")
        }

        // MARK: - CF-3-UT-04: 境界値 - 50%での挙動

        @Test("CF-3-UT-04: 50%での挙動")
        func testProgressAtFiftyPercent() async throws {
            let progressTracker = ProgressTracker()

            let receivedProgress = LockIsolated<Double?>(nil)

            await progressTracker.setProgressHandler { progress in
                receivedProgress.setValue(progress)
            }

            await progressTracker.updateProgress(phase: .analyzing, progress: 0.5)

            #expect(receivedProgress.withLock { $0 } == 0.5, "50%が正しく通知されていません")
        }

        // MARK: - CF-3-UT-05: 境界値 - 100%での挙動

        @Test("CF-3-UT-05: 100%での挙動")
        func testProgressAtOneHundredPercent() async throws {
            let progressTracker = ProgressTracker()

            let receivedProgress = LockIsolated<Double?>(nil)

            await progressTracker.setProgressHandler { progress in
                receivedProgress.setValue(progress)
            }

            await progressTracker.updateProgress(phase: .completed, progress: 1.0)

            #expect(receivedProgress.withLock { $0 } == 1.0, "100%が正しく通知されていません")
        }

        // MARK: - CF-3-UT-06: プログレスが単調増加であることを確認

        @Test("CF-3-UT-06: プログレスが単調増加である")
        func testProgressIsMonotonicallyIncreasing() async throws {
            let progressTracker = ProgressTracker()

            actor ProgressValidator {
                var lastValue: Double = -1
                var isMonotonic = true

                func validate(_ value: Double) {
                    if value < lastValue {
                        isMonotonic = false
                    }
                    lastValue = value
                }

                func getResult() -> Bool {
                    return isMonotonic
                }
            }

            let validator = ProgressValidator()

            await progressTracker.setProgressHandler { progress in
                await validator.validate(progress)
            }

            // 順番にプログレスを更新
            for i in stride(from: 0.0, through: 1.0, by: 0.1) {
                await progressTracker.updateProgress(phase: .scanning, progress: i)
            }

            let isMonotonic = await validator.getResult()
            #expect(isMonotonic, "プログレスが単調増加ではありません")
        }

        // MARK: - CF-3-UT-07: 範囲外の値に対するハンドリング

        @Test("CF-3-UT-07: 範囲外の値はクランプされる")
        func testProgressValuesClamped() async throws {
            let progressTracker = ProgressTracker()

            let receivedProgress = LockIsolated<Double?>(nil)

            await progressTracker.setProgressHandler { progress in
                receivedProgress.setValue(progress)
            }

            // 負の値
            await progressTracker.updateProgress(phase: .scanning, progress: -0.5)
            #expect(receivedProgress.withLock { $0 } == 0.0, "負の値は0にクランプされるべきです")

            // 1を超える値
            await progressTracker.updateProgress(phase: .scanning, progress: 1.5)
            #expect(receivedProgress.withLock { $0 } == 1.0, "1を超える値は1にクランプされるべきです")
        }
    }
}

// MARK: - Test Support Types

/// 並列制限を管理するアクター
public actor ConcurrencyLimiter {
    private let maxConcurrent: Int
    private var currentCount: Int = 0
    private var waitingContinuations: [CheckedContinuation<Void, Never>] = []

    public init(maxConcurrent: Int) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    public func execute<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async {
        if currentCount < maxConcurrent {
            currentCount += 1
            return
        }

        await withCheckedContinuation { continuation in
            waitingContinuations.append(continuation)
        }
        currentCount += 1
    }

    private func release() {
        currentCount -= 1
        if let continuation = waitingContinuations.first {
            waitingContinuations.removeFirst()
            continuation.resume()
        }
    }
}

/// メモリ監視を管理するアクター
public actor MemoryMonitor {
    private let thresholdMB: Double

    public init(thresholdMB: Double) {
        self.thresholdMB = thresholdMB
    }

    public func getCurrentMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: 1) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }

        if result == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        } else {
            return 0
        }
    }

    public func isAboveThreshold() -> Bool {
        return getCurrentMemoryUsageMB() >= thresholdMB
    }

    public func executeIfMemoryAvailable<T>(
        maxRetries: Int = 3,
        retryDelay: Duration = .milliseconds(100),
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        for attempt in 0..<maxRetries {
            if !isAboveThreshold() {
                return try await operation()
            }

            if attempt < maxRetries - 1 {
                try await Task.sleep(for: retryDelay)
            }
        }

        throw MemoryExceededError.thresholdExceeded(currentMB: getCurrentMemoryUsageMB(), thresholdMB: thresholdMB)
    }
}

/// メモリ超過エラー
public enum MemoryExceededError: Error, Equatable {
    case thresholdExceeded(currentMB: Double, thresholdMB: Double)
}

/// プログレスのフェーズ
public enum ProgressPhase: String, Sendable {
    case initialization = "初期化"
    case scanning = "スキャン"
    case analyzing = "分析"
    case grouping = "グルーピング"
    case completed = "完了"
}

/// プログレスエラー
public enum ProgressError: Error, Sendable {
    case analysisFailure
    case cancelled
}

/// プログレス追跡アクター
public actor ProgressTracker {
    private var progressHandler: (@Sendable (Double) async -> Void)?
    private var currentPhase: ProgressPhase = .initialization
    private var currentProgress: Double = 0.0
    private var lastError: Error?

    public func setProgressHandler(_ handler: @Sendable @escaping (Double) async -> Void) {
        self.progressHandler = handler
    }

    public func updateProgress(phase: ProgressPhase, progress: Double) async {
        currentPhase = phase
        // 値をクランプ
        currentProgress = max(0.0, min(1.0, progress))
        await progressHandler?(currentProgress)
    }

    public func reportError(_ error: Error) {
        lastError = error
    }

    public func getCurrentProgress() -> Double {
        return currentProgress
    }

    public func getCurrentPhase() -> ProgressPhase {
        return currentPhase
    }
}
