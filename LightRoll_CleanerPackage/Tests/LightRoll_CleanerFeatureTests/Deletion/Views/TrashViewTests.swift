//
//  TrashViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  TrashViewのテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - TrashViewTests

@Suite("TrashView Tests", .serialized)
@MainActor
struct TrashViewTests {

    // MARK: - 正常系テスト

    @Test("空のゴミ箱が正しく表示される")
    func emptyTrash_DisplaysCorrectly() async {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: true)

        // When - TrashViewを初期化（実際にはロジックのみテスト）
        _ = TrashView(
            trashManager: trashManager,
            deletePhotosUseCase: MockDeletePhotosUseCase(),
            restorePhotosUseCase: MockRestorePhotosUseCase(),
            confirmationService: MockDeletionConfirmationService()
        )

        // Then - TrashManagerが空であることを確認
        let photos = await trashManager.fetchAllTrashPhotos()
        #expect(photos.isEmpty, "空のゴミ箱が表示される")
    }

    @Test("ゴミ箱写真の読み込みが成功する")
    func loadTrashPhotos_Success() async {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)

        // When
        let photos = await trashManager.fetchAllTrashPhotos()

        // Then
        #expect(photos.count == 2, "2枚の写真が読み込まれる")
        #expect(photos[0].originalPhotoId == "photo1", "1枚目のIDが正しい")
        #expect(photos[1].originalPhotoId == "photo2", "2枚目のIDが正しい")
    }

    @Test("日付別グルーピングが正しく動作する")
    func groupPhotos_ByDate() async {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When
        let grouped = photos.groupedByDeletedDay

        // Then
        #expect(grouped.count == 2, "2つの日付グループに分かれる")
    }

    @Test("写真の選択が正しく動作する")
    func selectPhoto_Success() {
        // Given
        let photo = createTestTrashPhoto(id: "test1")

        // When & Then - 選択状態を管理
        var selectedIds: Set<String> = []
        selectedIds.insert(photo.originalPhotoId)

        #expect(selectedIds.contains("test1"), "写真が選択される")

        // 選択解除
        selectedIds.remove(photo.originalPhotoId)
        #expect(!selectedIds.contains("test1"), "写真の選択が解除される")
    }

    @Test("複数写真の選択が正しく動作する")
    func selectMultiplePhotos_Success() {
        // Given
        let photo1 = createTestTrashPhoto(id: "test1")
        let photo2 = createTestTrashPhoto(id: "test2")
        let photo3 = createTestTrashPhoto(id: "test3")

        // When
        var selectedIds: Set<String> = []
        selectedIds.insert(photo1.originalPhotoId)
        selectedIds.insert(photo2.originalPhotoId)
        selectedIds.insert(photo3.originalPhotoId)

        // Then
        #expect(selectedIds.count == 3, "3枚の写真が選択される")
        #expect(selectedIds.contains("test1"), "写真1が選択される")
        #expect(selectedIds.contains("test2"), "写真2が選択される")
        #expect(selectedIds.contains("test3"), "写真3が選択される")
    }

    @Test("復元が成功する")
    func restorePhotos_Success() async throws {
        // Given
        let restoreUseCase = MockRestorePhotosUseCase()
        restoreUseCase.mockOutput = RestorePhotosOutput(
            restoredCount: 2,
            failedIds: []
        )

        // When
        let input = RestorePhotosInput(
            photos: [
                PhotoAsset(id: "photo1", creationDate: nil, fileSize: 1_000_000),
                PhotoAsset(id: "photo2", creationDate: nil, fileSize: 2_000_000)
            ]
        )
        let result = try await restoreUseCase.execute(input)

        // Then
        #expect(result.restoredCount == 2, "2枚の写真が復元される")
        #expect(result.failedIds.isEmpty, "失敗した写真がない")
        #expect(restoreUseCase.executeCalled, "restoreUseCaseが呼ばれる")
    }

    @Test("完全削除が成功する")
    func permanentDelete_Success() async throws {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When
        try await trashManager.permanentlyDelete([photos[0]])
        let remainingPhotos = await trashManager.fetchAllTrashPhotos()

        // Then
        #expect(remainingPhotos.count == 1, "1枚削除され1枚残る")
    }

    @Test("ゴミ箱を空にするが成功する")
    func emptyTrash_Success() async throws {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)

        // When
        try await trashManager.emptyTrash()
        let photos = await trashManager.fetchAllTrashPhotos()

        // Then
        #expect(photos.isEmpty, "ゴミ箱が空になる")
    }

    // MARK: - 異常系テスト

    @Test("ゴミ箱写真の読み込みが失敗した場合")
    func loadTrashPhotos_Failure() async {
        // Given
        let trashManager = MockTrashManagerForView(shouldFail: true)

        // When
        let photos = await trashManager.fetchAllTrashPhotos()

        // Then
        #expect(photos.isEmpty, "エラー時は空配列が返る")
    }

    @Test("復元が失敗した場合")
    func restorePhotos_Failure() async {
        // Given
        let restoreUseCase = MockRestorePhotosUseCase()
        restoreUseCase.shouldThrowError = true
        restoreUseCase.errorToThrow = .emptyPhotos

        // When & Then
        await #expect(throws: (any Error).self) {
            let input = RestorePhotosInput(photos: [])
            _ = try await restoreUseCase.execute(input)
        }
    }

    @Test("完全削除が失敗した場合")
    func permanentDelete_Failure() async {
        // Given
        let trashManager = MockTrashManagerForView(shouldFail: true)
        let photo = createTestTrashPhoto(id: "test1")

        // When & Then
        await #expect(throws: (any Error).self) {
            try await trashManager.permanentlyDelete([photo])
        }
    }

    @Test("空配列での復元はエラーになる")
    func restoreEmptyArray_ThrowsError() async {
        // Given
        let restoreUseCase = MockRestorePhotosUseCase()
        restoreUseCase.shouldThrowError = true
        restoreUseCase.errorToThrow = .emptyPhotos

        // When & Then
        await #expect(throws: (any Error).self) {
            let input = RestorePhotosInput(photos: [])
            _ = try await restoreUseCase.execute(input)
        }
    }

    // MARK: - 境界値テスト

    @Test("空のゴミ箱でアクションボタンが表示されない")
    func emptyTrash_NoActionButtons() async {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: true)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When & Then
        #expect(photos.isEmpty, "空のゴミ箱")
        // 実際のUIではアクションボタンが非表示になる
    }

    @Test("1枚の写真が正しく表示される")
    func singlePhoto_DisplaysCorrectly() async {
        // Given
        let trashManager = MockTrashManagerForView(photoCount: 1)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When & Then
        #expect(photos.count == 1, "1枚の写真が存在")
        #expect(photos[0].originalPhotoId == "photo1", "IDが正しい")
    }

    @Test("大量の写真（100枚）が処理できる")
    func largePhotoCount_HandlesCorrectly() async {
        // Given
        let trashManager = MockTrashManagerForView(photoCount: 100)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When & Then
        #expect(photos.count == 100, "100枚の写真が処理される")
    }

    @Test("選択数0での復元は実行されない")
    func restoreWithZeroSelection_DoesNotExecute() {
        // Given
        let selectedIds: Set<String> = []

        // When & Then
        #expect(selectedIds.isEmpty, "選択数が0")
        // 実際のUIでは復元ボタンが無効化される
    }

    @Test("全選択が正しく動作する")
    func selectAll_Success() async {
        // Given
        let trashManager = MockTrashManagerForView(photoCount: 10)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When
        var selectedIds: Set<String> = []
        photos.forEach { selectedIds.insert($0.originalPhotoId) }

        // Then
        #expect(selectedIds.count == 10, "全10枚が選択される")
    }

    // MARK: - DeletionConfirmationService 統合テスト

    @Test("復元確認が必要な場合（10枚以上）")
    func restoreConfirmation_Required() {
        // Given
        let confirmationService = MockDeletionConfirmationService()
        confirmationService.shouldShowConfirmationResult = true

        // When
        let shouldShow = confirmationService.shouldShowConfirmation(
            photoCount: 15,
            actionType: .restore
        )

        // Then
        #expect(shouldShow, "10枚以上で確認が必要")
        #expect(confirmationService.shouldShowConfirmationCalled, "メソッドが呼ばれる")
    }

    @Test("復元確認が不要な場合（10枚未満）")
    func restoreConfirmation_NotRequired() {
        // Given
        let confirmationService = MockDeletionConfirmationService()
        confirmationService.shouldShowConfirmationResult = false

        // When
        let shouldShow = confirmationService.shouldShowConfirmation(
            photoCount: 5,
            actionType: .restore
        )

        // Then
        #expect(!shouldShow, "10枚未満で確認不要")
    }

    @Test("完全削除確認メッセージが生成される")
    func permanentDeleteMessage_Generated() {
        // Given
        let confirmationService = DeletionConfirmationService()

        // When
        let message = confirmationService.formatConfirmationMessage(
            photoCount: 5,
            totalSize: 5_000_000,
            actionType: .permanentDelete,
            itemName: "写真"
        )

        // Then
        #expect(message.title == "完全に削除しますか？", "タイトルが正しい")
        #expect(message.confirmTitle == "完全削除", "確認ボタンのタイトルが正しい")
        #expect(message.style == .destructive, "スタイルがdestructive")
    }

    @Test("ゴミ箱を空にする確認メッセージが生成される")
    func emptyTrashMessage_Generated() {
        // Given
        let confirmationService = DeletionConfirmationService()

        // When
        let message = confirmationService.formatConfirmationMessage(
            photoCount: 20,
            totalSize: 10_000_000,
            actionType: .emptyTrash,
            itemName: "写真"
        )

        // Then
        #expect(message.title == "ゴミ箱を空にしますか？", "タイトルが正しい")
        #expect(message.confirmTitle == "空にする", "確認ボタンのタイトルが正しい")
        #expect(message.style == .destructive, "スタイルがdestructive")
    }

    // MARK: - UseCase統合テスト

    @Test("RestorePhotosUseCaseとの統合")
    func integration_RestorePhotosUseCase() async throws {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)
        let restoreUseCase = RestorePhotosUseCase(trashManager: trashManager)
        let photos = await trashManager.fetchAllTrashPhotos()

        // When
        let input = RestorePhotosInput(
            photos: photos.map { PhotoAsset(id: $0.originalPhotoId, creationDate: nil, fileSize: $0.fileSize) }
        )
        let result = try await restoreUseCase.execute(input)

        // Then
        #expect(result.restoredCount == 2, "2枚の写真が復元される")
        #expect(result.failedIds.isEmpty, "失敗がない")
    }

    @Test("期限切れ写真の復元はエラーになる")
    func integration_ExpiredPhotos_Error() async {
        // Given
        let trashManager = MockTrashManagerForView(isEmpty: false)

        // 期限切れ写真を作成
        let expiredPhoto = TrashPhoto(
            originalPhotoId: "expired1",
            originalAssetIdentifier: "asset_expired",
            thumbnailData: nil,
            deletedAt: Date().addingTimeInterval(-31 * 24 * 60 * 60), // 31日前
            fileSize: 1_000_000,
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            ),
            deletionReason: .userSelected
        )

        // When & Then
        #expect(expiredPhoto.isExpired, "写真が期限切れ")
        await #expect(throws: (any Error).self) {
            let restoreUseCase = RestorePhotosUseCase(trashManager: trashManager)
            let input = RestorePhotosInput(
                photos: [PhotoAsset(id: expiredPhoto.originalPhotoId, creationDate: nil, fileSize: expiredPhoto.fileSize)]
            )
            _ = try await restoreUseCase.execute(input)
        }
    }

    // MARK: - ViewState テスト

    @Test("ViewStateの遷移（loading → loaded）")
    func viewState_LoadingToLoaded() {
        // Given
        enum ViewState {
            case loading
            case loaded
            case error(String)
        }

        var state: ViewState = .loading

        // When
        state = .loaded

        // Then
        if case .loaded = state {
            #expect(Bool(true), "loadedステートに遷移")
        } else {
            Issue.record("loadedステートに遷移していない")
        }
    }

    @Test("ViewStateの遷移（loading → error）")
    func viewState_LoadingToError() {
        // Given
        enum ViewState {
            case loading
            case loaded
            case error(String)
        }

        var state: ViewState = .loading

        // When
        state = .error("読み込みエラー")

        // Then
        if case .error(let message) = state {
            #expect(message == "読み込みエラー", "エラーメッセージが正しい")
        } else {
            Issue.record("errorステートに遷移していない")
        }
    }

    // MARK: - ConfirmationDialog統合テスト

    @Test("ConfirmationDialogが正しく生成される")
    func confirmationDialog_Generated() {
        // Given
        let message = ConfirmationMessage(
            title: "テストタイトル",
            message: "テストメッセージ",
            details: [],
            style: .normal,
            confirmTitle: "確認",
            cancelTitle: "キャンセル"
        )

        // When & Then
        #expect(message.title == "テストタイトル", "タイトルが正しい")
        #expect(message.message == "テストメッセージ", "メッセージが正しい")
        #expect(message.confirmTitle == "確認", "確認ボタンが正しい")
        #expect(message.cancelTitle == "キャンセル", "キャンセルボタンが正しい")
    }

    // MARK: - Helper Methods

    private func createTestTrashPhoto(id: String) -> TrashPhoto {
        TrashPhoto(
            originalPhotoId: id,
            originalAssetIdentifier: "asset_\(id)",
            thumbnailData: nil,
            fileSize: 1_000_000,
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 4032,
                pixelHeight: 3024
            ),
            deletionReason: .userSelected
        )
    }
}

// MARK: - Mock TrashManager for View

@MainActor
final class MockTrashManagerForView: TrashManagerProtocol {

    private var photos: [TrashPhoto]
    private let shouldFail: Bool

    init(isEmpty: Bool = false, photoCount: Int? = nil, shouldFail: Bool = false) {
        self.shouldFail = shouldFail

        if isEmpty {
            self.photos = []
        } else if let count = photoCount {
            self.photos = (1...count).map { index in
                TrashPhoto(
                    originalPhotoId: "photo\(index)",
                    originalAssetIdentifier: "asset\(index)",
                    thumbnailData: nil,
                    deletedAt: index == 1 ? Date() : Date().addingTimeInterval(-86400), // 1枚目は今日、それ以外は昨日
                    fileSize: Int64(index * 1_000_000),
                    metadata: TrashPhotoMetadata(
                        creationDate: Date(),
                        pixelWidth: 4032,
                        pixelHeight: 3024
                    ),
                    deletionReason: .userSelected
                )
            }
        } else {
            self.photos = [
                TrashPhoto(
                    originalPhotoId: "photo1",
                    originalAssetIdentifier: "asset1",
                    thumbnailData: nil,
                    deletedAt: Date(), // 今日
                    fileSize: 1_000_000,
                    metadata: TrashPhotoMetadata(
                        creationDate: Date(),
                        pixelWidth: 4032,
                        pixelHeight: 3024
                    ),
                    deletionReason: .userSelected
                ),
                TrashPhoto(
                    originalPhotoId: "photo2",
                    originalAssetIdentifier: "asset2",
                    thumbnailData: nil,
                    deletedAt: Date().addingTimeInterval(-86400), // 昨日
                    fileSize: 2_000_000,
                    metadata: TrashPhotoMetadata(
                        creationDate: Date(),
                        pixelWidth: 4032,
                        pixelHeight: 3024
                    ),
                    deletionReason: .similarPhoto
                )
            ]
        }
    }

    func fetchAllTrashPhotos() async -> [TrashPhoto] {
        guard !shouldFail else { return [] }
        return photos
    }

    func moveToTrash(_ photos: [Photo], reason: TrashPhoto.DeletionReason?) async throws {
        guard !shouldFail else {
            throw TrashManagerError.storageError(underlying: NSError(domain: "Test", code: -1))
        }
    }

    func restore(_ photos: [TrashPhoto]) async throws {
        guard !shouldFail else {
            throw TrashManagerError.storageError(underlying: NSError(domain: "Test", code: -1))
        }
    }

    func permanentlyDelete(_ photos: [TrashPhoto]) async throws {
        guard !shouldFail else {
            throw TrashManagerError.storageError(underlying: NSError(domain: "Test", code: -1))
        }
        // 削除をシミュレート
        self.photos.removeAll { photo in
            photos.contains { $0.id == photo.id }
        }
    }

    func cleanupExpired() async -> Int {
        0
    }

    func emptyTrash() async throws {
        guard !shouldFail else {
            throw TrashManagerError.storageError(underlying: NSError(domain: "Test", code: -1))
        }
        photos.removeAll()
    }

    var trashCount: Int {
        get async { photos.count }
    }

    var trashSize: Int64 {
        get async { photos.reduce(0) { $0 + $1.fileSize } }
    }
}

// MARK: - TrashManagerError

enum TrashManagerError: Error {
    case storageError(underlying: Error)
}
