//
//  AsyncSemaphore.swift
//  LightRoll_CleanerFeature
//
//  Swift Concurrency対応の非同期セマフォ
//  並列実行数を制限するためのユーティリティ
//  Created by AI Assistant
//

import Foundation

// MARK: - AsyncSemaphore

/// Swift Concurrency対応の非同期セマフォ
///
/// 並列タスクの同時実行数を制限するために使用します。
/// Thread-safeなactor実装で、Swift 6.0 strict concurrency compliant。
///
/// ## 使用例
/// ```swift
/// let semaphore = AsyncSemaphore(limit: 8)
///
/// await withTaskGroup(of: Result.self) { group in
///     for item in items {
///         group.addTask {
///             await semaphore.wait()
///             defer { Task { await semaphore.signal() } }
///             return await processItem(item)
///         }
///     }
/// }
/// ```
public actor AsyncSemaphore {

    // MARK: - Properties

    /// 同時実行の最大数
    private let limit: Int

    /// 現在使用中のスロット数
    private var currentCount: Int = 0

    /// 待機中のタスクのキュー
    private var waiters: [CheckedContinuation<Void, Never>] = []

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter limit: 同時実行の最大数（1以上）
    public init(limit: Int) {
        precondition(limit > 0, "Semaphore limit must be greater than 0")
        self.limit = limit
    }

    // MARK: - Public Methods

    /// セマフォの取得を待機
    ///
    /// スロットが利用可能になるまで待機します。
    /// スロットが取得できた場合、処理完了後に必ず `signal()` を呼び出してください。
    public func wait() async {
        if currentCount < limit {
            currentCount += 1
            return
        }

        // 待機が必要な場合
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    /// セマフォを解放
    ///
    /// 使用中のスロットを解放し、待機中のタスクがあれば再開させます。
    public func signal() {
        if waiters.isEmpty {
            currentCount -= 1
            return
        }

        // 待機中のタスクを再開
        let waiter = waiters.removeFirst()
        waiter.resume()
    }

    /// 現在の使用中スロット数を取得
    public var count: Int {
        currentCount
    }

    /// 待機中のタスク数を取得
    public var waitingCount: Int {
        waiters.count
    }

    /// セマフォの最大スロット数を取得
    public var maxLimit: Int {
        limit
    }
}

// MARK: - AsyncSemaphore + withSemaphore

extension AsyncSemaphore {

    /// セマフォで保護されたスコープ内で処理を実行
    ///
    /// - Parameter operation: 実行する処理
    /// - Returns: 処理の結果
    /// - Throws: 処理から投げられたエラー
    ///
    /// ## 使用例
    /// ```swift
    /// let result = try await semaphore.withSemaphore {
    ///     try await performExpensiveOperation()
    /// }
    /// ```
    public func withSemaphore<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        defer {
            Task { await signal() }
        }
        return try await operation()
    }
}

// MARK: - AsyncSemaphore + CustomStringConvertible

extension AsyncSemaphore: CustomStringConvertible {
    nonisolated public var description: String {
        "AsyncSemaphore(limit: \(limit))"
    }
}
