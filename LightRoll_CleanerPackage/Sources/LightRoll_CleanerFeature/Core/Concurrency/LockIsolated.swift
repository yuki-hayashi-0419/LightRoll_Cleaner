//
//  LockIsolated.swift
//  LightRoll_CleanerFeature
//
//  スレッドセーフな値アクセスを提供するラッパー
//  Swift 6.0 strict concurrency対応
//  Created by AI Assistant
//

import Foundation

// MARK: - LockIsolated

/// スレッドセーフな値アクセスを提供するラッパー
///
/// 並列コンテキストから安全に値を読み書きするために使用します。
/// `@unchecked Sendable` を使用していますが、内部でロックにより安全性を保証しています。
///
/// ## 使用例
/// ```swift
/// let counter = LockIsolated(0)
///
/// // 値を更新
/// counter.withLock { value in
///     value += 1
///     return value
/// }
///
/// // 値を読み取り
/// let current = counter.withLock { $0 }
/// ```
public final class LockIsolated<Value>: @unchecked Sendable {

    // MARK: - Properties

    /// 保護する値
    private var _value: Value

    /// アクセス制御用のロック
    private let lock = NSLock()

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter value: 初期値
    public init(_ value: Value) {
        self._value = value
    }

    // MARK: - Public Methods

    /// ロックを取得して値にアクセス
    ///
    /// - Parameter operation: 値を受け取り、結果を返すクロージャ
    /// - Returns: operationの結果
    /// - Throws: operationから投げられたエラー
    @discardableResult
    public func withLock<T>(_ operation: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation(&_value)
    }

    /// 現在の値を取得（読み取り専用）
    public var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    /// 値を設定
    /// - Parameter newValue: 新しい値
    public func setValue(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        _value = newValue
    }
}

// MARK: - LockIsolated + Equatable

extension LockIsolated: Equatable where Value: Equatable {
    public static func == (lhs: LockIsolated<Value>, rhs: LockIsolated<Value>) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - LockIsolated + Hashable

extension LockIsolated: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - LockIsolated + CustomStringConvertible

extension LockIsolated: CustomStringConvertible {
    public var description: String {
        "LockIsolated(\(value))"
    }
}
