//
//  DeletePhotosUseCase.swift
//  LightRoll_CleanerFeature
//
//  写真削除ユースケース
//  TrashManagerとPhotoRepositoryを統合し、写真の削除またはゴミ箱への移動を実行
//  Created by AI Assistant
//

import Foundation

// MARK: - DeletePhotosUseCaseError

/// DeletePhotosUseCase で発生するエラー
public enum DeletePhotosUseCaseError: LocalizedError, Sendable {
    /// 写真が空
    case emptyPhotos

    /// 削除上限到達（Free版）
    case deletionLimitReached(current: Int, limit: Int, requested: Int)

    /// ゴミ箱への移動失敗
    case trashMoveFailed(underlying: Error)

    /// 完全削除失敗
    case permanentDeletionFailed(underlying: Error)

    /// 部分的な失敗
    case partialFailure(successCount: Int, failedCount: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyPhotos:
            return NSLocalizedString(
                "deletePhotosUseCase.error.emptyPhotos",
                value: "削除する写真がありません",
                comment: "Empty photos error"
            )
        case .deletionLimitReached(let current, let limit, let requested):
            return String(
                format: NSLocalizedString(
                    "deletePhotosUseCase.error.deletionLimitReached",
                    value: "本日の削除上限に到達しました（%d/%d枚）。%d枚の削除はできません。",
                    comment: "Deletion limit reached error"
                ),
                current,
                limit,
                requested
            )
        case .trashMoveFailed(let error):
            return String(
                format: NSLocalizedString(
                    "deletePhotosUseCase.error.trashMoveFailed",
                    value: "ゴミ箱への移動に失敗しました: %@",
                    comment: "Trash move failed"
                ),
                error.localizedDescription
            )
        case .permanentDeletionFailed(let error):
            return String(
                format: NSLocalizedString(
                    "deletePhotosUseCase.error.permanentDeletionFailed",
                    value: "完全削除に失敗しました: %@",
                    comment: "Permanent deletion failed"
                ),
                error.localizedDescription
            )
        case .partialFailure(let successCount, let failedCount):
            return String(
                format: NSLocalizedString(
                    "deletePhotosUseCase.error.partialFailure",
                    value: "%d枚中%d枚の削除に失敗しました",
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
                "deletePhotosUseCase.error.emptyPhotos.reason",
                value: "削除対象の写真を選択してください",
                comment: "Empty photos reason"
            )
        case .deletionLimitReached:
            return NSLocalizedString(
                "deletePhotosUseCase.error.deletionLimitReached.reason",
                value: "無料版は1日50枚まで削除できます",
                comment: "Deletion limit reached reason"
            )
        case .trashMoveFailed:
            return NSLocalizedString(
                "deletePhotosUseCase.error.trashMoveFailed.reason",
                value: "写真をゴミ箱に移動できませんでした",
                comment: "Trash move failed reason"
            )
        case .permanentDeletionFailed:
            return NSLocalizedString(
                "deletePhotosUseCase.error.permanentDeletionFailed.reason",
                value: "写真を削除できませんでした",
                comment: "Permanent deletion failed reason"
            )
        case .partialFailure:
            return NSLocalizedString(
                "deletePhotosUseCase.error.partialFailure.reason",
                value: "一部の写真の削除に失敗しました",
                comment: "Partial failure reason"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .emptyPhotos:
            return nil
        case .deletionLimitReached:
            return NSLocalizedString(
                "deletePhotosUseCase.error.deletionLimitReached.recoverySuggestion",
                value: "プレミアム版にアップグレードすると無制限に削除できます",
                comment: "Deletion limit reached suggestion"
            )
        case .trashMoveFailed, .permanentDeletionFailed:
            return NSLocalizedString(
                "deletePhotosUseCase.error.recoverySuggestion",
                value: "もう一度お試しいただくか、写真へのアクセス権限を確認してください",
                comment: "Recovery suggestion"
            )
        case .partialFailure:
            return NSLocalizedString(
                "deletePhotosUseCase.error.partialFailure.recoverySuggestion",
                value: "失敗した写真を個別に削除してください",
                comment: "Partial failure suggestion"
            )
        }
    }
}

// MARK: - DeletePhotosUseCase

/// 写真削除ユースケースの実装
/// 写真の削除またはゴミ箱への移動を統合的に実行
///
/// ## 主な責務
/// - TrashManagerでゴミ箱への移動を実行
/// - PhotoRepositoryで完全削除を実行（将来実装）
/// - 削除容量を計算
/// - 削除結果を集計
///
/// ## 使用例
/// ```swift
/// let useCase = DeletePhotosUseCase(
///     trashManager: trashManager,
///     photoRepository: photoRepository
/// )
///
/// let input = DeletePhotosInput(
///     photos: photosToDelete,
///     permanently: false // ゴミ箱へ移動
/// )
///
/// let result = try await useCase.execute(input)
/// print("削除成功: \(result.deletedCount)枚")
/// print("空き容量: \(result.formattedFreedBytes)")
/// ```
@MainActor
public final class DeletePhotosUseCase: DeletePhotosUseCaseProtocol {

    // MARK: - Properties

    /// TrashManager インスタンス
    private let trashManager: any TrashManagerProtocol

    /// PhotoRepository インスタンス（将来の完全削除用）
    private let photoRepository: (any PhotoRepositoryProtocol)?

    /// PremiumManager インスタンス（削除制限チェック用）
    private let premiumManager: (any PremiumManagerProtocol)?

    /// 削除理由（オプション）
    private let deletionReason: TrashPhoto.DeletionReason?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - trashManager: TrashManager インスタンス
    ///   - photoRepository: PhotoRepository インスタンス（オプション）
    ///   - premiumManager: PremiumManager インスタンス（オプション）
    ///   - deletionReason: 削除理由（オプション）
    public init(
        trashManager: any TrashManagerProtocol,
        photoRepository: (any PhotoRepositoryProtocol)? = nil,
        premiumManager: (any PremiumManagerProtocol)? = nil,
        deletionReason: TrashPhoto.DeletionReason? = nil
    ) {
        self.trashManager = trashManager
        self.photoRepository = photoRepository
        self.premiumManager = premiumManager
        self.deletionReason = deletionReason
    }

    // MARK: - DeletePhotosUseCaseProtocol

    /// 削除を実行
    /// - Parameter input: 削除入力（写真と削除モード）
    /// - Returns: 削除結果
    /// - Throws: DeletePhotosUseCaseError
    public func execute(_ input: DeletePhotosInput) async throws -> DeletePhotosOutput {
        // 入力検証
        guard !input.photos.isEmpty else {
            throw DeletePhotosUseCaseError.emptyPhotos
        }

        // 削除制限チェック（PremiumManagerが設定されている場合のみ）
        if let premiumManager = premiumManager {
            let remaining = await premiumManager.getRemainingDeletions()
            if remaining < input.photos.count {
                // 削除不可の場合はエラーをスロー
                let limit = 50 // Free版の上限
                let current = limit - remaining
                throw DeletePhotosUseCaseError.deletionLimitReached(
                    current: current,
                    limit: limit,
                    requested: input.photos.count
                )
            }
        }

        // PhotoAssetからPhotoへの変換
        let photos = convertToPhotos(input.photos)

        // 削除容量を計算
        let totalSize = photos.reduce(0) { $0 + $1.fileSize }

        // 削除モードに応じて処理を分岐
        let result: DeletePhotosOutput
        if input.permanently {
            // 完全削除（将来実装）
            result = try await executePermanentDeletion(photos: photos, totalSize: totalSize)
        } else {
            // ゴミ箱へ移動
            result = try await executeMoveToTrash(photos: photos, totalSize: totalSize)
        }

        // 削除成功後、カウントを更新
        if let premiumManager = premiumManager {
            await premiumManager.recordDeletion(count: result.deletedCount)
        }

        return result
    }

    // MARK: - Private Methods

    /// ゴミ箱への移動を実行
    /// - Parameters:
    ///   - photos: 移動する写真
    ///   - totalSize: 合計サイズ
    /// - Returns: 削除結果
    /// - Throws: DeletePhotosUseCaseError
    private func executeMoveToTrash(
        photos: [Photo],
        totalSize: Int64
    ) async throws -> DeletePhotosOutput {
        do {
            // TrashManagerでゴミ箱へ移動
            try await trashManager.moveToTrash(photos, reason: deletionReason)

            // 成功結果を返す
            return DeletePhotosOutput(
                deletedCount: photos.count,
                freedBytes: totalSize,
                failedIds: []
            )
        } catch {
            // エラーをラップして再スロー
            throw DeletePhotosUseCaseError.trashMoveFailed(underlying: error)
        }
    }

    /// 完全削除を実行
    /// - Parameters:
    ///   - photos: 削除する写真
    ///   - totalSize: 合計サイズ
    /// - Returns: 削除結果
    /// - Throws: DeletePhotosUseCaseError
    private func executePermanentDeletion(
        photos: [Photo],
        totalSize: Int64
    ) async throws -> DeletePhotosOutput {
        // PhotoRepositoryが必要
        guard let repository = photoRepository else {
            throw DeletePhotosUseCaseError.permanentDeletionFailed(
                underlying: NSError(
                    domain: "DeletePhotosUseCase",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString(
                            "deletePhotosUseCase.error.repositoryNotProvided",
                            value: "写真リポジトリが設定されていません",
                            comment: "Repository not provided"
                        )
                    ]
                )
            )
        }

        do {
            // PhotoをPhotoAssetに変換
            let photoAssets = photos.map { photo in
                PhotoAsset(
                    id: photo.localIdentifier,
                    creationDate: photo.creationDate,
                    fileSize: photo.fileSize
                )
            }

            // PhotoRepositoryで完全削除を実行
            // PHPhotoLibrary.performChanges経由でシステム削除確認ダイアログが表示される
            try await repository.deletePhotos(photoAssets)

            // 成功結果を返す
            return DeletePhotosOutput(
                deletedCount: photos.count,
                freedBytes: totalSize,
                failedIds: []
            )
        } catch {
            // エラーをラップして再スロー
            throw DeletePhotosUseCaseError.permanentDeletionFailed(underlying: error)
        }
    }

    /// PhotoAssetからPhotoへの変換
    /// - Parameter photoAssets: 変換元のPhotoAsset配列
    /// - Returns: 変換後のPhoto配列
    private func convertToPhotos(_ photoAssets: [PhotoAsset]) -> [Photo] {
        photoAssets.compactMap { asset in
            // PhotoAsset.idはPhoto.localIdentifierと対応
            // 実際の実装ではPhotoRepositoryを使ってIDから取得する必要がある
            // 現時点では簡易実装として、PhotoAssetからPhotoを生成
            // TODO: PhotoRepositoryを使った正確な変換実装
            Photo(
                id: asset.id,
                localIdentifier: asset.id,
                creationDate: asset.creationDate ?? Date(),
                modificationDate: asset.creationDate ?? Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 0,
                pixelHeight: 0,
                duration: 0,
                fileSize: asset.fileSize,
                isFavorite: false
            )
        }
    }
}

// MARK: - Batch Operations Extension

extension DeletePhotosUseCase {

    /// 複数のグループから写真を一括削除
    /// - Parameters:
    ///   - photoGroups: 削除する写真グループ
    ///   - permanently: 完全削除かどうか
    /// - Returns: 削除結果
    public func executeFromGroups(
        _ photoGroups: [PhotoGroup],
        permanently: Bool = false
    ) async throws -> DeletePhotosOutput {
        // 全グループから写真IDとファイルサイズを抽出
        let allPhotos = photoGroups.flatMap { group in
            zip(group.photoIds, group.fileSizes).map { photoId, fileSize in
                PhotoAsset(
                    id: photoId,
                    creationDate: nil,
                    fileSize: fileSize
                )
            }
        }

        let input = DeletePhotosInput(
            photos: allPhotos,
            permanently: permanently
        )

        return try await execute(input)
    }

    /// 削除理由別に写真を一括削除
    /// - Parameters:
    ///   - photosByReason: 削除理由ごとの写真辞書
    ///   - permanently: 完全削除かどうか
    /// - Returns: 削除結果の配列
    public func executeBatchByReason(
        _ photosByReason: [TrashPhoto.DeletionReason: [PhotoAsset]],
        permanently: Bool = false
    ) async throws -> [TrashPhoto.DeletionReason: DeletePhotosOutput] {
        var results: [TrashPhoto.DeletionReason: DeletePhotosOutput] = [:]

        for (reason, photos) in photosByReason {
            // 削除理由ごとに新しいUseCaseインスタンスを作成
            let useCase = DeletePhotosUseCase(
                trashManager: trashManager,
                photoRepository: photoRepository,
                premiumManager: premiumManager,
                deletionReason: reason
            )

            let input = DeletePhotosInput(
                photos: photos,
                permanently: permanently
            )

            results[reason] = try await useCase.execute(input)
        }

        return results
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックDeletePhotosUseCase
@MainActor
public final class MockDeletePhotosUseCase: DeletePhotosUseCaseProtocol {

    // MARK: - Mock Storage

    public var executeCalled = false
    public var lastInput: DeletePhotosInput?
    public var mockOutput: DeletePhotosOutput?
    public var shouldThrowError = false
    public var errorToThrow: DeletePhotosUseCaseError?

    // MARK: - Initialization

    public init() {}

    // MARK: - Protocol Implementation

    public func execute(_ input: DeletePhotosInput) async throws -> DeletePhotosOutput {
        executeCalled = true
        lastInput = input

        if shouldThrowError {
            throw errorToThrow ?? DeletePhotosUseCaseError.emptyPhotos
        }

        return mockOutput ?? DeletePhotosOutput(
            deletedCount: input.photos.count,
            freedBytes: 0,
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
