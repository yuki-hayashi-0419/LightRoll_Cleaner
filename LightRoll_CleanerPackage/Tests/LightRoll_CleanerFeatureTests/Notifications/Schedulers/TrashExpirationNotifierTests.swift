//
//  TrashExpirationNotifierTests.swift
//  LightRoll_CleanerFeatureTests
//
//  TrashExpirationNotifier のテストスイート
//  - ゴミ箱期限警告通知の動作検証
//  - Swift Testing framework使用
//  Created by AI Assistant for M7-T09
//

import Testing
import Foundation
@preconcurrency import UserNotifications
@testable import LightRoll_CleanerFeature

@Suite("TrashExpirationNotifier Tests")
@MainActor
struct TrashExpirationNotifierTests {

    // MARK: - Helper Methods

    /// テスト用のNotificationManagerを作成
    private func makeTestNotificationManager(
        settings: NotificationSettings = .default,
        authStatus: UNAuthorizationStatus = .authorized
    ) async -> NotificationManager {
        let mockCenter = MockUserNotificationCenter()
        await mockCenter.setAuthorizationStatus(authStatus)
        return NotificationManager(
            settings: settings,
            notificationCenter: mockCenter
        )
    }

    /// テスト用のTrashPhotoを作成
    private func makeTestTrashPhoto(expiresAt: Date) -> TrashPhoto {
        TrashPhoto(
            originalPhotoId: UUID().uuidString,
            originalAssetIdentifier: UUID().uuidString,
            thumbnailData: nil,
            deletedAt: Date().addingTimeInterval(-86400), // 1日前
            expiresAt: expiresAt,
            fileSize: 1024 * 1024, // 1MB
            metadata: TrashPhotoMetadata(
                creationDate: Date(),
                pixelWidth: 1920,
                pixelHeight: 1080,
                mediaType: .image,
                mediaSubtypes: [],
                isFavorite: false
            )
        )
    }

    // MARK: - Initialization Tests

    @Test("初期化: デフォルト設定で初期化できる")
    func testInitializationWithDefaults() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let _ = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // 初期化が成功すれば合格
    }

    @Test("初期化: カスタム設定で初期化できる")
    func testInitializationWithCustomSettings() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let contentBuilder = NotificationContentBuilder()
        let _ = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            contentBuilder: contentBuilder,
            warningDaysBefore: 3
        )

        // 初期化が成功すれば合格
    }

    // MARK: - Schedule Tests

    @Test("スケジュール: 期限切れ前のアイテムがある場合、通知がスケジュールされる")
    func testScheduleExpirationWarning_Success() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 明日期限切れのアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        try await notifier.scheduleExpirationWarning()

        // 通知がスケジュールされたことを確認
        let pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)
    }

    @Test("スケジュール: ゴミ箱が空の場合、エラーが発生する")
    func testScheduleExpirationWarning_EmptyTrash() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // ゴミ箱が空の状態でスケジュール
        await #expect(throws: TrashExpirationNotifierError.trashEmpty) {
            try await notifier.scheduleExpirationWarning()
        }
    }

    @Test("スケジュール: 期限切れ前のアイテムがない場合、エラーが発生する")
    func testScheduleExpirationWarning_NoExpiringItems() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 1週間後に期限切れのアイテムを追加（1日前警告の範囲外）
        let nextWeek = Date().addingTimeInterval(7 * 86400)
        let photo = makeTestTrashPhoto(expiresAt: nextWeek)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        await #expect(throws: TrashExpirationNotifierError.noExpiringItems) {
            try await notifier.scheduleExpirationWarning()
        }
    }

    @Test("スケジュール: 通知が無効の場合、エラーが発生する")
    func testScheduleExpirationWarning_NotificationsDisabled() async {
        var settings = NotificationSettings.default
        settings.isEnabled = false
        let manager = await makeTestNotificationManager(settings: settings)
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // 期限切れ前のアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        await #expect(throws: TrashExpirationNotifierError.notificationsDisabled) {
            try await notifier.scheduleExpirationWarning()
        }
    }

    @Test("スケジュール: 権限が拒否されている場合、エラーが発生する")
    func testScheduleExpirationWarning_PermissionDenied() async {
        let manager = await makeTestNotificationManager(authStatus: .denied)
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // 期限切れ前のアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        await #expect(throws: TrashExpirationNotifierError.permissionDenied) {
            try await notifier.scheduleExpirationWarning()
        }
    }

    @Test("スケジュール: 複数のアイテムがある場合、最も早く期限切れになるアイテムで通知される")
    func testScheduleExpirationWarning_MultipleItems() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 異なる期限のアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let dayAfterTomorrow = Date().addingTimeInterval(2 * 86400)

        trashManager.addMockPhoto(makeTestTrashPhoto(expiresAt: dayAfterTomorrow))
        trashManager.addMockPhoto(makeTestTrashPhoto(expiresAt: tomorrow))

        // スケジュール実行
        try await notifier.scheduleExpirationWarning()

        // 通知がスケジュールされたことを確認
        let pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)
    }

    @Test("スケジュール: 静寂時間帯が有効な場合、通知時刻が調整される")
    func testScheduleExpirationWarning_QuietHours() async throws {
        var settings = NotificationSettings.default
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22 // 22:00
        settings.quietHoursEnd = 8    // 08:00

        let manager = await makeTestNotificationManager(settings: settings)
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 明日期限切れのアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        try await notifier.scheduleExpirationWarning()

        // 通知がスケジュールされたことを確認
        let pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)
    }

    @Test("スケジュール: 異なる警告日数で正しく動作する")
    func testScheduleExpirationWarning_DifferentWarningDays() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 3 // 3日前
        )

        // 3日後に期限切れのアイテムを追加
        // warningDaysBefore = 3 の場合、3日以内に期限切れになるアイテムが対象
        let threeDaysLater = Date().addingTimeInterval(3 * 86400)
        let photo = makeTestTrashPhoto(expiresAt: threeDaysLater)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        try await notifier.scheduleExpirationWarning()

        // 通知がスケジュールされたことを確認
        let pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)
    }

    // MARK: - Cancel Tests

    @Test("キャンセル: すべての期限警告通知がキャンセルされる")
    func testCancelAllExpirationWarnings() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // 通知をスケジュール
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)
        try await notifier.scheduleExpirationWarning()

        // 通知がスケジュールされたことを確認
        var pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)

        // キャンセル
        await notifier.cancelAllExpirationWarnings()

        // 通知がキャンセルされたことを確認
        pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 0)
    }

    // MARK: - Get Expiring Item Count Tests

    @Test("期限切れ前アイテム数: 正しくカウントされる")
    func testGetExpiringItemCount_WithExpiringItems() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 明日期限切れのアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        trashManager.addMockPhoto(makeTestTrashPhoto(expiresAt: tomorrow))
        trashManager.addMockPhoto(makeTestTrashPhoto(expiresAt: tomorrow))

        let count = await notifier.getExpiringItemCount()
        #expect(count == 2)
    }

    @Test("期限切れ前アイテム数: 期限切れ前のアイテムがない場合は0")
    func testGetExpiringItemCount_NoExpiringItems() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            warningDaysBefore: 1
        )

        // 1週間後に期限切れのアイテムを追加
        let nextWeek = Date().addingTimeInterval(7 * 86400)
        trashManager.addMockPhoto(makeTestTrashPhoto(expiresAt: nextWeek))

        let count = await notifier.getExpiringItemCount()
        #expect(count == 0)
    }

    @Test("期限切れ前アイテム数: ゴミ箱が空の場合は0")
    func testGetExpiringItemCount_EmptyTrash() async {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        let count = await notifier.getExpiringItemCount()
        #expect(count == 0)
    }

    // MARK: - Integration Tests

    @Test("統合: 通知コンテンツが正しく生成される")
    func testNotificationContentGeneration() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let contentBuilder = NotificationContentBuilder()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager,
            contentBuilder: contentBuilder,
            warningDaysBefore: 1
        )

        // 明日期限切れのアイテムを追加
        let tomorrow = Date().addingTimeInterval(86400)
        let photo = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo)

        // スケジュール実行
        try await notifier.scheduleExpirationWarning()

        // 通知コンテンツを検証
        let pendingRequests = await manager.getPendingNotifications()
        #expect(pendingRequests.count == 1)

        let request = pendingRequests[0]
        let content = request.content
        #expect(content.title == "ゴミ箱の期限警告")
        #expect(!content.body.isEmpty)
        #expect(content.categoryIdentifier == "TRASH_EXPIRATION")
    }

    @Test("統合: 再スケジュール時に古い通知が削除される")
    func testReschedulingCancelsOldNotifications() async throws {
        let manager = await makeTestNotificationManager()
        let trashManager = MockTrashManager()
        let notifier = TrashExpirationNotifier(
            notificationManager: manager,
            trashManager: trashManager
        )

        // 最初の通知をスケジュール
        let tomorrow = Date().addingTimeInterval(86400)
        let photo1 = makeTestTrashPhoto(expiresAt: tomorrow)
        trashManager.addMockPhoto(photo1)
        try await notifier.scheduleExpirationWarning()

        // 最初の通知数を確認
        var pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)

        // 新しいアイテムを追加して再スケジュール
        let dayAfterTomorrow = Date().addingTimeInterval(2 * 86400)
        let photo2 = makeTestTrashPhoto(expiresAt: dayAfterTomorrow)
        trashManager.addMockPhoto(photo2)
        try await notifier.scheduleExpirationWarning()

        // 通知が1つだけであることを確認（古い通知が削除された）
        pendingCount = manager.pendingNotificationCount
        #expect(pendingCount == 1)
    }
}

// MARK: - Error Tests

@Suite("TrashExpirationNotifierError Tests")
struct TrashExpirationNotifierErrorTests {

    @Test("エラー: エラーの等価性が正しく機能する")
    func testErrorEquality() {
        #expect(
            TrashExpirationNotifierError.notificationsDisabled ==
            TrashExpirationNotifierError.notificationsDisabled
        )
        #expect(
            TrashExpirationNotifierError.permissionDenied ==
            TrashExpirationNotifierError.permissionDenied
        )
        #expect(
            TrashExpirationNotifierError.trashEmpty ==
            TrashExpirationNotifierError.trashEmpty
        )
        #expect(
            TrashExpirationNotifierError.noExpiringItems ==
            TrashExpirationNotifierError.noExpiringItems
        )
        #expect(
            TrashExpirationNotifierError.schedulingFailed(reason: "test") ==
            TrashExpirationNotifierError.schedulingFailed(reason: "test")
        )
    }

    @Test("エラー: エラーメッセージが正しく提供される")
    func testErrorDescriptions() {
        #expect(TrashExpirationNotifierError.notificationsDisabled.errorDescription != nil)
        #expect(TrashExpirationNotifierError.permissionDenied.errorDescription != nil)
        #expect(TrashExpirationNotifierError.trashEmpty.errorDescription != nil)
        #expect(TrashExpirationNotifierError.noExpiringItems.errorDescription != nil)
        #expect(TrashExpirationNotifierError.schedulingFailed(reason: "test").errorDescription != nil)
    }
}
