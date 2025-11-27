//
//  Array+Extensions.swift
//  LightRoll_CleanerFeature
//
//  配列操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - Array Extensions

extension Array {

    // MARK: - Safe Access

    /// 安全にインデックスで要素を取得
    /// - Parameter index: インデックス
    /// - Returns: 要素、または範囲外の場合nil
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

    /// 安全に範囲で部分配列を取得
    /// - Parameter range: 範囲
    /// - Returns: 部分配列
    public subscript(safe range: Range<Int>) -> ArraySlice<Element> {
        let startIndex = Swift.max(0, range.lowerBound)
        let endIndex = Swift.min(count, range.upperBound)
        guard startIndex < endIndex else { return [] }
        return self[startIndex..<endIndex]
    }

    // MARK: - Chunking

    /// 配列を指定サイズのチャンクに分割
    /// - Parameter size: チャンクサイズ
    /// - Returns: チャンクの配列
    public func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    // MARK: - Uniqueness

    /// 重複を除去した配列を取得（Hashableな要素の場合）
    /// 元の順序を維持
    public func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = element[keyPath: keyPath]
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Transformation

    /// 配列内の各要素にインデックスを付与
    /// - Returns: (インデックス, 要素)のタプル配列
    public var indexed: [(index: Int, element: Element)] {
        enumerated().map { (index: $0.offset, element: $0.element) }
    }

    /// 配列の先頭にnilでない要素を追加
    /// - Parameter newElement: 追加する要素（オプショナル）
    /// - Returns: 要素が追加された新しい配列
    public func prepending(_ newElement: Element?) -> [Element] {
        guard let element = newElement else { return self }
        return [element] + self
    }

    /// 配列の末尾にnilでない要素を追加
    /// - Parameter newElement: 追加する要素（オプショナル）
    /// - Returns: 要素が追加された新しい配列
    public func appending(_ newElement: Element?) -> [Element] {
        guard let element = newElement else { return self }
        return self + [element]
    }

    // MARK: - Filtering

    /// 条件に一致する最初のn個の要素を取得
    /// - Parameters:
    ///   - count: 取得する最大数
    ///   - predicate: フィルタ条件
    /// - Returns: フィルタされた要素の配列
    public func first(_ count: Int, where predicate: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        for element in self where result.count < count {
            if predicate(element) {
                result.append(element)
            }
        }
        return result
    }

    // MARK: - Nil Handling

    /// nil要素を除去（Optionalの配列の場合）
    /// - Returns: nilを除去した配列
    public func compactedNils<T>() -> [T] where Element == T? {
        compactMap { $0 }
    }
}

// MARK: - Array where Element: Hashable

extension Array where Element: Hashable {

    /// 重複を除去した配列を取得（順序維持）
    /// - Returns: 重複を除去した配列
    public var uniqued: [Element] {
        var seen = Set<Element>()
        return filter { element in
            guard !seen.contains(element) else { return false }
            seen.insert(element)
            return true
        }
    }

    /// 別の配列との差分を取得
    /// - Parameter other: 比較対象の配列
    /// - Returns: 自身にのみ含まれる要素の配列
    public func difference(from other: [Element]) -> [Element] {
        let otherSet = Set(other)
        return filter { !otherSet.contains($0) }
    }

    /// 別の配列との共通要素を取得
    /// - Parameter other: 比較対象の配列
    /// - Returns: 共通要素の配列
    public func intersection(with other: [Element]) -> [Element] {
        let otherSet = Set(other)
        return filter { otherSet.contains($0) }
    }
}

// MARK: - Array where Element: Equatable

extension Array where Element: Equatable {

    /// 指定した要素を削除した配列を取得
    /// - Parameter element: 削除する要素
    /// - Returns: 要素が削除された新しい配列
    public func removing(_ element: Element) -> [Element] {
        filter { $0 != element }
    }

    /// 指定した要素のすべてを削除
    /// - Parameter element: 削除する要素
    public mutating func removeAll(_ element: Element) {
        removeAll { $0 == element }
    }

    /// 要素が含まれているかどうかを確認し、含まれていなければ追加
    /// - Parameter element: 追加する要素
    /// - Returns: 要素が追加されたかどうか
    @discardableResult
    public mutating func appendIfNotContains(_ element: Element) -> Bool {
        guard !contains(element) else { return false }
        append(element)
        return true
    }
}

// MARK: - Array where Element: Numeric

extension Array where Element: Numeric {

    /// 配列の要素の合計を取得
    /// - Returns: 合計値
    public var sum: Element {
        reduce(0, +)
    }
}

// MARK: - Array where Element: BinaryInteger

extension Array where Element: BinaryInteger {

    /// 配列の要素の平均を取得
    /// - Returns: 平均値（空の場合は0）
    public var average: Double {
        guard !isEmpty else { return 0 }
        return Double(sum) / Double(count)
    }
}

// MARK: - Array where Element: FloatingPoint

extension Array where Element: FloatingPoint {

    /// 配列の要素の平均を取得
    /// - Returns: 平均値（空の場合は0）
    public var average: Element {
        guard !isEmpty else { return 0 }
        return sum / Element(count)
    }
}

// MARK: - Array where Element: Comparable

extension Array where Element: Comparable {

    /// 最小値と最大値のタプルを取得
    /// - Returns: (最小値, 最大値)のタプル、または空の場合nil
    public var minMax: (min: Element, max: Element)? {
        guard let minValue = self.min(), let maxValue = self.max() else {
            return nil
        }
        return (min: minValue, max: maxValue)
    }
}
