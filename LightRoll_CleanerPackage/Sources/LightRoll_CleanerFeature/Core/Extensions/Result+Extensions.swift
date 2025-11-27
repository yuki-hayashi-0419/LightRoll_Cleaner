//
//  Result+Extensions.swift
//  LightRoll_CleanerFeature
//
//  Result型操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - Result Extensions

extension Result {

    // MARK: - Inspection

    /// 成功かどうかを判定
    /// - Returns: 成功の場合true
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// 失敗かどうかを判定
    /// - Returns: 失敗の場合true
    public var isFailure: Bool {
        !isSuccess
    }

    /// 成功値を取得（失敗の場合nil）
    public var success: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    /// 失敗エラーを取得（成功の場合nil）
    public var failure: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }

    // MARK: - Transformation

    /// 成功値を取得、または失敗の場合デフォルト値を返す
    /// - Parameter defaultValue: デフォルト値
    /// - Returns: 成功値またはデフォルト値
    public func valueOr(_ defaultValue: @autoclosure () -> Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return defaultValue()
        }
    }

    /// 成功値を取得、または失敗の場合クロージャの結果を返す
    /// - Parameter transform: エラーを受け取り、代替値を返すクロージャ
    /// - Returns: 成功値または代替値
    public func valueOr(_ transform: (Failure) -> Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            return transform(error)
        }
    }

    /// 成功の場合に処理を実行
    /// - Parameter action: 成功値に対して実行する処理
    /// - Returns: 自身（チェーン用）
    @discardableResult
    public func onSuccess(_ action: (Success) -> Void) -> Result<Success, Failure> {
        if case .success(let value) = self {
            action(value)
        }
        return self
    }

    /// 失敗の場合に処理を実行
    /// - Parameter action: エラーに対して実行する処理
    /// - Returns: 自身（チェーン用）
    @discardableResult
    public func onFailure(_ action: (Failure) -> Void) -> Result<Success, Failure> {
        if case .failure(let error) = self {
            action(error)
        }
        return self
    }

    /// 成功または失敗に応じて処理を実行
    /// - Parameters:
    ///   - success: 成功時の処理
    ///   - failure: 失敗時の処理
    public func handle(
        success: (Success) -> Void,
        failure: (Failure) -> Void
    ) {
        switch self {
        case .success(let value):
            success(value)
        case .failure(let error):
            failure(error)
        }
    }

    /// 失敗をリカバリして成功に変換
    /// - Parameter recovery: リカバリ処理
    /// - Returns: リカバリ後のResult
    public func recover(_ recovery: (Failure) -> Success) -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return .success(recovery(error))
        }
    }

    /// 失敗エラーを変換
    /// - Parameter transform: エラー変換処理
    /// - Returns: エラーが変換されたResult
    public func mapError<NewFailure: Error>(
        _ transform: (Failure) -> NewFailure
    ) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }

    /// 両方の値を変換
    /// - Parameters:
    ///   - success: 成功値の変換処理
    ///   - failure: エラーの変換処理
    /// - Returns: 変換されたResult
    public func bimap<NewSuccess, NewFailure: Error>(
        success: (Success) -> NewSuccess,
        failure: (Failure) -> NewFailure
    ) -> Result<NewSuccess, NewFailure> {
        switch self {
        case .success(let value):
            return .success(success(value))
        case .failure(let error):
            return .failure(failure(error))
        }
    }
}

// MARK: - Result where Failure == Error

extension Result where Failure == Error {

    /// 汎用Errorをラップしてリカバリ
    /// - Parameter recovery: リカバリ処理
    /// - Returns: リカバリ後のResult
    public func tryRecover(_ recovery: (Error) throws -> Success) -> Result<Success, Error> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            do {
                let recovered = try recovery(error)
                return .success(recovered)
            } catch {
                return .failure(error)
            }
        }
    }
}

// MARK: - Result where Success == Void

extension Result where Success == Void {

    /// 成功を表すResultを生成
    public static var success: Result<Void, Failure> {
        .success(())
    }
}

// MARK: - Result Factory

extension Result {

    /// 条件に基づいてResultを生成
    /// - Parameters:
    ///   - condition: 成功条件
    ///   - success: 成功時の値
    ///   - failure: 失敗時のエラー
    /// - Returns: 条件に応じたResult
    public static func from(
        condition: Bool,
        success: @autoclosure () -> Success,
        failure: @autoclosure () -> Failure
    ) -> Result<Success, Failure> {
        condition ? .success(success()) : .failure(failure())
    }

    /// Optionalから変換
    /// - Parameters:
    ///   - optional: Optional値
    ///   - error: nilの場合のエラー
    /// - Returns: Optionalから生成されたResult
    public static func from(
        _ optional: Success?,
        error: @autoclosure () -> Failure
    ) -> Result<Success, Failure> {
        if let value = optional {
            return .success(value)
        }
        return .failure(error())
    }
}

// MARK: - Async Result Extensions

extension Result {

    /// 非同期で成功値を変換
    /// - Parameter transform: 非同期変換処理
    /// - Returns: 変換されたResult
    public func asyncMap<NewSuccess>(
        _ transform: (Success) async throws -> NewSuccess
    ) async rethrows -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return .success(try await transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 非同期でflatMap処理
    /// - Parameter transform: 非同期変換処理
    /// - Returns: 変換されたResult
    public func asyncFlatMap<NewSuccess>(
        _ transform: (Success) async throws -> Result<NewSuccess, Failure>
    ) async rethrows -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return try await transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
