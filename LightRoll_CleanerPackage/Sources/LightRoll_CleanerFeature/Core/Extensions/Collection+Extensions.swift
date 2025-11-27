//
//  Collection+Extensions.swift
//  LightRoll_CleanerFeature
//
//  コレクション操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - Collection Extensions

extension Collection {

    // MARK: - Safe Access

    /// コレクションが空でないかどうかを判定
    /// - Returns: 空でない場合true
    public var isNotEmpty: Bool {
        !isEmpty
    }

    /// コレクションがnilでなく空でもないかどうかを判定
    /// - Returns: nilでなく空でもない場合true
    public var hasElements: Bool {
        isNotEmpty
    }

    // MARK: - Conditional Operations

    /// 空でない場合のみ処理を実行
    /// - Parameter action: 実行する処理
    public func ifNotEmpty(_ action: (Self) -> Void) {
        if isNotEmpty {
            action(self)
        }
    }

    /// 空の場合のみ処理を実行
    /// - Parameter action: 実行する処理
    public func ifEmpty(_ action: () -> Void) {
        if isEmpty {
            action()
        }
    }
}

// MARK: - Dictionary Extensions

extension Dictionary {

    // MARK: - Safe Access

    /// キーが存在するかどうかを確認
    /// - Parameter key: キー
    /// - Returns: キーが存在する場合true
    public func hasKey(_ key: Key) -> Bool {
        self[key] != nil
    }

    // MARK: - Transformation

    /// 値のみを変換した新しい辞書を生成
    /// - Parameter transform: 値の変換処理
    /// - Returns: 変換された辞書
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var result = [Key: T]()
        for (key, value) in self {
            result[key] = try transform(value)
        }
        return result
    }

    /// 別の辞書とマージ
    /// 重複するキーは指定された方を優先
    /// - Parameters:
    ///   - other: マージする辞書
    ///   - preferOther: 重複時に他方を優先する場合true
    /// - Returns: マージされた辞書
    public func merged(with other: [Key: Value], preferOther: Bool = true) -> [Key: Value] {
        var result = self
        for (key, value) in other {
            if preferOther || result[key] == nil {
                result[key] = value
            }
        }
        return result
    }

    /// キーと値を入れ替えた辞書を生成（Valueがキーとして使用可能な場合）
    /// - Returns: キーと値が入れ替わった辞書
    public func swapped() -> [Value: Key] where Value: Hashable {
        var result = [Value: Key]()
        for (key, value) in self {
            result[value] = key
        }
        return result
    }
}

// MARK: - Dictionary where Value: Collection

extension Dictionary where Value: RangeReplaceableCollection {

    /// キーに対応する配列に要素を追加（配列が存在しない場合は作成）
    /// - Parameters:
    ///   - element: 追加する要素
    ///   - key: キー
    public mutating func append(_ element: Value.Element, forKey key: Key) {
        if self[key] == nil {
            self[key] = Value()
        }
        self[key]?.append(element)
    }
}

// MARK: - Set Extensions

extension Set {

    /// 要素をトグル（存在すれば削除、存在しなければ追加）
    /// - Parameter element: トグルする要素
    /// - Returns: 追加された場合true、削除された場合false
    @discardableResult
    public mutating func toggle(_ element: Element) -> Bool {
        if contains(element) {
            remove(element)
            return false
        } else {
            insert(element)
            return true
        }
    }

    /// 複数要素をトグル
    /// - Parameter elements: トグルする要素のシーケンス
    public mutating func toggle<S: Sequence>(contentsOf elements: S) where S.Element == Element {
        for element in elements {
            toggle(element)
        }
    }
}

// MARK: - Sequence Extensions

extension Sequence {

    /// 最初にnilでない変換結果を返す
    /// - Parameter transform: 変換処理
    /// - Returns: 最初のnilでない結果、または全てnilの場合nil
    public func firstNonNil<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let result = try transform(element) {
                return result
            }
        }
        return nil
    }

    /// 非同期でマップ処理を実行
    /// - Parameter transform: 非同期変換処理
    /// - Returns: 変換された配列
    public func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results = [T]()
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }

    /// 非同期でフィルタ処理を実行
    /// - Parameter predicate: 非同期フィルタ条件
    /// - Returns: フィルタされた配列
    public func asyncFilter(_ predicate: (Element) async throws -> Bool) async rethrows -> [Element] {
        var results = [Element]()
        for element in self {
            if try await predicate(element) {
                results.append(element)
            }
        }
        return results
    }

    /// 非同期でcompactMap処理を実行
    /// - Parameter transform: 非同期変換処理
    /// - Returns: nilを除いた変換結果の配列
    public func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var results = [T]()
        for element in self {
            if let result = try await transform(element) {
                results.append(result)
            }
        }
        return results
    }

    /// 並列で非同期マップ処理を実行
    /// - Parameter transform: 非同期変換処理
    /// - Returns: 変換された配列
    public func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async rethrows -> [T] where Element: Sendable {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in enumerated() {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }

            var results = [(Int, T)]()
            for try await result in group {
                results.append(result)
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}

// MARK: - Sequence where Element: Hashable

extension Sequence where Element: Hashable {

    /// シーケンス内の要素の出現回数をカウント
    /// - Returns: 要素とその出現回数の辞書
    public func countOccurrences() -> [Element: Int] {
        var counts = [Element: Int]()
        for element in self {
            counts[element, default: 0] += 1
        }
        return counts
    }

    /// 最も頻出する要素を取得
    /// - Returns: 最頻出要素とその出現回数、または空の場合nil
    public var mostFrequent: (element: Element, count: Int)? {
        let counts = countOccurrences()
        guard let maxPair = counts.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return (element: maxPair.key, count: maxPair.value)
    }
}
