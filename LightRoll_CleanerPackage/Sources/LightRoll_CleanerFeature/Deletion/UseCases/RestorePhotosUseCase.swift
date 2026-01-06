//
//  RestorePhotosUseCase.swift
//  LightRoll_CleanerFeature
//
//  写真復元ユースケース
//  TrashManagerを統合し、ゴミ箱からの写真復元を実行
//  Created by AI Assistant
//

import Foundation

// MARK: - RestorePhotosUseCaseError

/// RestorePhotosUseCase で発生するエラー
public enum RestorePhotosUseCaseError: LocalizedError, Sendable {
    /// 写真が空
    case emptyPhotos

    /// 復元失敗
    case restorationFailed(underlying: Error)

    /// 期限切れ写真が含まれている
    case containsExpiredPhotos(count: Int)

    /// 部分的な失敗
    case partialFailure(successCount: Int, failedCount: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyPhotos:
            return NSLocalizedString(
                "restorePhotosUseCase.error.emptyPhotos",
                value: "復元する写真がありません",
                comment: "Empty photos error"
            )
        case .restorationFailed(let error):
            return String(
                format: NSLocalizedString(
                    "restorePhotosUseCase.error.restorationFailed",
                    value: "復元に失敗しました: %@",
                    comment: "Restoration failed"
                ),
                error.localizedDescription
            )
        case .containsExpiredPhotos(let count):
            return String(
                format: NSLocalizedString(
                    "restorePhotosUseCase.error.containsExpiredPhotos",
                    value: "%d枚の写真が期限切れのため復元できません",
                    comment: "Contains expired photos"
                ),
                count
            )
        case .partialFailure(let successCount, let failedCount):
            return String(
                format: NSLocalizedString(
                    "restorePhotosUseCase.error.partialFailure",
                    value: "%d枚中%d枚の復元に失敗しました",
                    comment: "Partial failure"
                ),
                successCount + failedCount,
                failedCount
            )
        }
    }

    public var failureReason: String? {
        switch self {
        case .emptyPhotos:
            return NSLocalizedString(
                "restorePhotosUseCase.error.emptyPhotos.reason",
                value: "復元対象の写真を選択してください",
                comment: "Empty photos reason"
            )
        case .restorationFailed:
            return NSLocalizedString(
                "restorePhotosUseCase.error.restorationFailed.reason",
                value: "写真を復元できませんでした",
                comment: "Restoration failed reason"
            )
        case .containsExpiredPhotos:
            return NSLocalizedString(
                "restorePhotosUseCase.error.containsExpiredPhotos.reason",
                value: "30日の保持期間を過ぎた写真は復元できません",
                comment: "Contains expired photos reason"
            )
        case .partialFailure:
            return NSLocalizedString(
                "restorePhotosUseCase.error.partialFailure.reason",
                value: "一部の写真の復元に失敗しました",
                comment: "Partial failure reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .emptyPhotos:
            return nil
        case .restorationFailed:
            return NSLocalizedString(
                "restorePhotosUseCase.error.recoverySuggestion",
                value: "もう一度お試しいただくか、写真へのアクセス権限を確認してください",
                comment: "Recovery suggestion"
            )
        case .containsExpiredPhotos:
            return NSLocalizedString(
                "restorePhotosUseCase.error.containsExpiredPhotos.suggestion",
                value: "期限内の写真のみ選択してください",
                comment: "Contains expired photos suggestion"
            )
        case .partialFailure:
            return NSLocalizedString(
                "restorePhotosUseCase.error.partialFailure.recoverySuggestion",
                value: "失敗した写真を個別に復元してください",
                comment: "Partial failure suggestion"
            )
        }
    }
}

// MARK: - RestorePhotosUseCase

/// 写真復元ユースケースの実装
/// ゴミ箱から写真を復元する
///
/// ## 主な責務
/// - TrashManagerで復元を実行
/// - 期限切れチェック
/// - 復元結果を集計
///
/// ## 使用例
/// ```swift
/// let useCase = RestorePhotosUseCase(trashManager: trashManager)
///
/// let input = RestorePhotosInput(photos: photosToRestore)
/// let result = try await useCase.execute(input)
/// print("復元成功: \(result.restoredCount)枚")
/// ```
@MainActor
public final class RestorePhotosUseCase: RestorePhotosUseCaseProtocol {

    // MARK: - Properties

    /// TrashManager インスタンス
    private let trashManager: any TrashManagerProtocol

    /// 期限切れ写真を自動的にスキップするかどうか
    private let autoSkipExpired: Bool

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - trashManager: TrashManager インスタンス
    ///   - autoSkipExpired: 期限切れ写真を自動的にスキップするかどうか（デフォルトはfalse）
    public init(
        trashManager: any TrashManagerProtocol,
        autoSkipExpired: Bool = false
    ) {
        self.trashManager = trashManager
        self.autoSkipExpired = autoSkipExpired
    }

    // MARK: - RestorePhotosUseCaseProtocol

    /// 復元を実行
    /// - Parameter input: 復元入力（写真のID配列）
    /// - Returns: 復元結果
    /// - Throws: RestorePhotosUseCaseError
    public func execute(_ input: RestorePhotosInput) async throws -> RestorePhotosOutput {
        // 入力検証
        guard !input.photos.isEmpty else {
            throw RestorePhotosUseCaseError.emptyPhotos
        }

        // PhotoAssetからTrashPhotoへの変換
        let trashPhotos = try await convertToTrashPhotos(input.photos)

        // 期限切れチェック
        let expiredPhotos = trashPhotos.filter { $0.isExpired }
        let validPhotos = trashPhotos.filter { !$0.isExpired }

        // 期限切れ写真の処理
        if !expiredPhotos.isEmpty {
            if autoSkipExpired {
                // 自動スキップの場合は警告のみ
                if validPhotos.isEmpty {
                    // 全て期限切れの場合はエラー
                    throw RestorePhotosUseCaseError.containsExpiredPhotos(count: expiredPhotos.count)
                }
            } else {
                // 自動スキップしない場合はエラー
                throw RestorePhotosUseCaseError.containsExpiredPhotos(count: expiredPhotos.count)
            }
        }

        // 復元実行
        return try await executeRestore(validPhotos, expiredCount: expiredPhotos.count)
    }

    // MARK: - Private Methods

    /// 復元を実行
    /// - Parameters:
    ///   - photos: 復元する写真
    ///   - expiredCount: スキップされた期限切れ写真数
    /// - Returns: 復元結果
    /// - Throws: RestorePhotosUseCaseError
    private func executeRestore(
        _ photos: [TrashPhoto],
        expiredCount: Int
    ) async throws -> RestorePhotosOutput {
        do {
            // TrashManagerで復元
            try await trashManager.restore(photos)

            // 成功結果を返す
            return RestorePhotosOutput(
                restoredCount: photos.count,
                failedIds: []
            )
        } catch {
            // エラーをラップして再スロー
            throw RestorePhotosUseCaseError.restorationFailed(underlying: error)
        }
    }

    /// PhotoAssetからTrashPhotoへの変換
    /// - Parameter photoAssets: 変換元のPhotoAsset配列
    /// - Returns: 変換後のTrashPhoto配列
    /// - Throws: RestorePhotosUseCaseError
    ///
    /// ## BUG-TRASH-002-P1A デバッグ情報追加
    /// - IDマッチングの詳細ログを出力
    /// - 不一致時の原因特定を容易化
    private func convertToTrashPhotos(_ photoAssets: [PhotoAsset]) async throws -> [TrashPhoto] {
        // ゴミ箱内の全写真を取得
        let allTrashPhotos = await trashManager.fetchAllTrashPhotos()

        #if DEBUG
        // BUG-TRASH-002-P1A: デバッグログ
        print("[RestorePhotosUseCase] 復元リクエスト: \(photoAssets.count)件")
        print("[RestorePhotosUseCase] ゴミ箱内写真数: \(allTrashPhotos.count)件")
        print("[RestorePhotosUseCase] リクエストID: \(photoAssets.map { $0.id }.prefix(5))...")
        print("[RestorePhotosUseCase] ゴミ箱originalPhotoId: \(allTrashPhotos.map { $0.originalPhotoId }.prefix(5))...")
        #endif

        // PhotoAssetのIDとTrashPhotoのoriginalPhotoIdでマッチング
        let photoIdSet = Set(photoAssets.map { $0.id })
        let matchedPhotos = allTrashPhotos.filter { photoIdSet.contains($0.originalPhotoId) }

        #if DEBUG
        print("[RestorePhotosUseCase] マッチした写真数: \(matchedPhotos.count)件")
        #endif

        // 見つからない写真があればエラー
        if matchedPhotos.count != photoAssets.count {
            let foundIds = Set(matchedPhotos.map { $0.originalPhotoId })
            let missingIds = photoIdSet.subtracting(foundIds)

            #if DEBUG
            print("[RestorePhotosUseCase] ERROR: 不一致検出")
            print("[RestorePhotosUseCase] 見つからないID: \(missingIds)")
            #endif

            throw RestorePhotosUseCaseError.restorationFailed(
                underlying: NSError(
                    domain: "RestorePhotosUseCase",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString(
                            "restorePhotosUseCase.error.photosNotFound",
                            value: "\(missingIds.count)枚の写真がゴミ箱に見つかりませんでした",
                            comment: "Photos not found"
                        )
                    ]
                )
            )
        }

        return matchedPhotos
    }
}

// MARK: - Batch Operations Extension

extension RestorePhotosUseCase {

    /// TrashPhotoから直接復元
    /// - Parameter trashPhotos: 復元するTrashPhoto配列
    /// - Returns: 復元結果
    public func executeFromTrashPhotos(_ trashPhotos: [TrashPhoto]) async throws -> RestorePhotosOutput {
        guard !trashPhotos.isEmpty else {
            throw RestorePhotosUseCaseError.emptyPhotos
        }

        // 期限切れチェック
        let expiredPhotos = trashPhotos.filter { $0.isExpired }
        let validPhotos = trashPhotos.filter { !$0.isExpired }

        // 期限切れ写真の処理
        if !expiredPhotos.isEmpty {
            if autoSkipExpired {
                if validPhotos.isEmpty {
                    throw RestorePhotosUseCaseError.containsExpiredPhotos(count: expiredPhotos.count)
                }
            } else {
                throw RestorePhotosUseCaseError.containsExpiredPhotos(count: expiredPhotos.count)
            }
        }

        return try await executeRestore(validPhotos, expiredCount: expiredPhotos.count)
    }

    /// 削除理由別に復元
    /// - Parameter photosByReason: 削除理由ごとの写真辞書
    /// - Returns: 削除理由ごとの復元結果
    public func executeBatchByReason(
        _ photosByReason: [TrashPhoto.DeletionReason: [TrashPhoto]]
    ) async throws -> [TrashPhoto.DeletionReason: RestorePhotosOutput] {
        var results: [TrashPhoto.DeletionReason: RestorePhotosOutput] = [:]

        for (reason, photos) in photosByReason {
            results[reason] = try await executeFromTrashPhotos(photos)
        }

        return results
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックRestorePhotosUseCase
@MainActor
public final class MockRestorePhotosUseCase: RestorePhotosUseCaseProtocol {

    // MARK: - Mock Storage

    public var executeCalled = false
    public var lastInput: RestorePhotosInput?
    public var mockOutput: RestorePhotosOutput?
    public var shouldThrowError = false
    public var errorToThrow: RestorePhotosUseCaseError?

    // MARK: - Initialization

    public init() {}

    // MARK: - Protocol Implementation

    public func execute(_ input: RestorePhotosInput) async throws -> RestorePhotosOutput {
        executeCalled = true
        lastInput = input

        if shouldThrowError {
            throw errorToThrow ?? RestorePhotosUseCaseError.emptyPhotos
        }

        return mockOutput ?? RestorePhotosOutput(
            restoredCount: input.photos.count,
            failedIds: []
        )
    }

    // MARK: - Test Helper Methods

    public func reset() {
        executeCalled = false
        lastInput = nil
        mockOutput = nil
        shouldThrowError = false
        errorToThrow = nil
    }
}

#endif
