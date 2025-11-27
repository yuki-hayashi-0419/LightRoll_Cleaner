//
//  Optional+Extensions.swift
//  LightRoll_CleanerFeature
//
//  Optional型操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - Optional Extensions

extension Optional {

    // MARK: - Inspection

    /// nilかどうかを判定
    /// - Returns: nilの場合true
    public var isNil: Bool {
        self == nil
    }

    /// nilでないかどうかを判定
    /// - Returns: nilでない場合true
    public var isNotNil: Bool {
        self != nil
    }

    // MARK: - Transformation

    /// 値が存在する場合に処理を実行
    /// - Parameter action: 値に対して実行する処理
    public func ifPresent(_ action: (Wrapped) -> Void) {
        if let value = self {
            action(value)
        }
    }

    /// 値が存在しない場合に処理を実行
    /// - Parameter action: 実行する処理
    public func ifNil(_ action: () -> Void) {
        if self == nil {
            action()
        }
    }

    /// 値を取得、またはエラーをスロー
    /// - Parameter error: nilの場合にスローするエラー
    /// - Returns: ラップされた値
    /// - Throws: 値がnilの場合に指定されたエラー
    public func orThrow(_ error: Error) throws -> Wrapped {
        guard let value = self else {
            throw error
        }
        return value
    }

    /// 値を取得、またはnilの場合にエラーをスロー
    /// - Parameter message: エラーメッセージ
    /// - Returns: ラップされた値
    /// - Throws: 値がnilの場合にNilError
    public func orThrow(_ message: String) throws -> Wrapped {
        guard let value = self else {
            throw NilError(message: message)
        }
        return value
    }

    /// 条件に一致する場合のみ値を返す
    /// - Parameter predicate: フィルタ条件
    /// - Returns: 条件に一致する場合は値、そうでない場合はnil
    public func filter(_ predicate: (Wrapped) -> Bool) -> Wrapped? {
        guard let value = self, predicate(value) else {
            return nil
        }
        return value
    }

    /// 値のマップ（nilの場合はデフォルト値を使用）
    /// - Parameters:
    ///   - defaultValue: デフォルト値
    ///   - transform: 変換処理
    /// - Returns: 変換された値
    public func map<T>(default defaultValue: T, _ transform: (Wrapped) -> T) -> T {
        guard let value = self else {
            return defaultValue
        }
        return transform(value)
    }
}

// MARK: - Optional where Wrapped: Collection

extension Optional where Wrapped: Collection {

    /// nilまたは空コレクションかどうかを判定
    /// - Returns: nilまたは空の場合true
    public var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let collection):
            return collection.isEmpty
        }
    }

    /// nilでなく、空でもないかどうかを判定
    /// - Returns: nilでなく空でもない場合true
    public var isNotNilOrEmpty: Bool {
        !isNilOrEmpty
    }
}

// MARK: - Optional where Wrapped == Bool

extension Optional where Wrapped == Bool {

    /// trueかどうかを判定（nilはfalse扱い）
    /// - Returns: trueの場合true、nilまたはfalseの場合false
    public var isTrue: Bool {
        self == true
    }

    /// falseまたはnilかどうかを判定
    /// - Returns: falseまたはnilの場合true
    public var isFalseOrNil: Bool {
        self != true
    }

    /// nilをfalseとして扱う
    /// - Returns: 値またはfalse
    public var orFalse: Bool {
        self ?? false
    }

    /// nilをtrueとして扱う
    /// - Returns: 値またはtrue
    public var orTrue: Bool {
        self ?? true
    }
}

// MARK: - Optional where Wrapped: Numeric

extension Optional where Wrapped: Numeric {

    /// nilを0として扱う
    /// - Returns: 値または0
    public var orZero: Wrapped {
        self ?? 0
    }
}

// MARK: - Optional where Wrapped: RangeReplaceableCollection

extension Optional where Wrapped: RangeReplaceableCollection {

    /// nilを空コレクションとして扱う
    /// - Returns: 値または空コレクション
    public var orEmptyCollection: Wrapped {
        self ?? Wrapped()
    }
}

// MARK: - NilError

/// Optional値がnilの場合に使用するエラー型
public struct NilError: Error, LocalizedError, Sendable {
    public let message: String

    public init(message: String = "Unexpected nil value") {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

// MARK: - Optional Comparison

extension Optional where Wrapped: Comparable {

    /// 安全な比較（nilは常に小さいとみなす）
    /// - Parameters:
    ///   - lhs: 左辺値
    ///   - rhs: 右辺値
    /// - Returns: 左辺が小さい場合true
    public static func safeCompare(_ lhs: Wrapped?, _ rhs: Wrapped?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return false
        case (nil, _):
            return true
        case (_, nil):
            return false
        case (let l?, let r?):
            return l < r
        }
    }
}

// MARK: - Optional Operators

/// オプショナル値のデフォルト代入演算子
infix operator ??= : AssignmentPrecedence

/// 左辺がnilの場合のみ右辺を代入
/// - Parameters:
///   - lhs: オプショナル値（inout）
///   - rhs: デフォルト値
public func ??= <T>(lhs: inout T?, rhs: @autoclosure () -> T) {
    if lhs == nil {
        lhs = rhs()
    }
}
