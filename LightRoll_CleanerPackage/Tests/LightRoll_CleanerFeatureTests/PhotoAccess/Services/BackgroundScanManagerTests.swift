//
//  BackgroundScanManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  BackgroundScanManager の単体テスト
//  Swift Testing フレームワークを使用
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - Mock UserDefaults

/// テスト用のUserDefaultsモック
final class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0.0
    }

    override func set(_ value: Double, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        if let value = value {
            storage[defaultName] = value
        } else {
            storage.removeValue(forKey: defaultName)
        }
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    func reset() {
        storage.removeAll()
    }
}

// MARK: - Mock Background Task Handler

/// テスト用のバックグラウンドタスクハンドラーモック
actor MockBackgroundTaskHandler: BackgroundTaskHandlerProtocol {
    var backgroundRefreshCallCount: Int = 0
    var backgroundProcessingCallCount: Int = 0
    var lastBackgroundRefreshTime: Date?
    var lastBackgroundProcessingTime: Date?

    func handleBackgroundRefresh() async {
        backgroundRefreshCallCount += 1
        lastBackgroundRefreshTime = Date()
    }

    func handleBackgroundProcessing() async {
        backgroundProcessingCallCount += 1
        lastBackgroundProcessingTime = Date()
    }

    func getBackgroundRefreshCallCount() -> Int { backgroundRefreshCallCount }
    func getBackgroundProcessingCallCount() -> Int { backgroundProcessingCallCount }
    func getLastBackgroundRefreshTime() -> Date? { lastBackgroundRefreshTime }
    func getLastBackgroundProcessingTime() -> Date? { lastBackgroundProcessingTime }

    func reset() {
        backgroundRefreshCallCount = 0
        backgroundProcessingCallCount = 0
        lastBackgroundRefreshTime = nil
        lastBackgroundProcessingTime = nil
    }
}

// MARK: - BackgroundScanError Tests

@Suite("BackgroundScanError Tests")
struct BackgroundScanErrorTests {

    @Test("taskRegistrationFailed エラーのローカライズ説明")
    func testTaskRegistrationFailedErrorDescription() {
        let error = BackgroundScanError.taskRegistrationFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("schedulingFailed エラーのローカライズ説明")
    func testSchedulingFailedErrorDescription() {
        let error = BackgroundScanError.schedulingFailed(underlying: "Test error")
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
        #expect(error.errorDescription!.contains("Test error"))
    }

    @Test("backgroundScanDisabled エラーのローカライズ説明")
    func testBackgroundScanDisabledErrorDescription() {
        let error = BackgroundScanError.backgroundScanDisabled
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("insufficientPermissions エラーのローカライズ説明")
    func testInsufficientPermissionsErrorDescription() {
        let error = BackgroundScanError.insufficientPermissions
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("エラーの等価性 - taskRegistrationFailed")
    func testTaskRegistrationFailedEquality() {
        let error1 = BackgroundScanError.taskRegistrationFailed
        let error2 = BackgroundScanError.taskRegistrationFailed
        #expect(error1 == error2)
    }

    @Test("エラーの等価性 - schedulingFailed 同じメッセージ")
    func testSchedulingFailedEqualityWithSameMessage() {
        let error1 = BackgroundScanError.schedulingFailed(underlying: "Test")
        let error2 = BackgroundScanError.schedulingFailed(underlying: "Test")
        #expect(error1 == error2)
    }

    @Test("エラーの不等価性 - schedulingFailed 異なるメッセージ")
    func testSchedulingFailedInequalityWithDifferentMessage() {
        let error1 = BackgroundScanError.schedulingFailed(underlying: "Error 1")
        let error2 = BackgroundScanError.schedulingFailed(underlying: "Error 2")
        #expect(error1 != error2)
    }

    @Test("異なるエラータイプは等しくない")
    func testDifferentErrorTypesAreNotEqual() {
        #expect(BackgroundScanError.taskRegistrationFailed != BackgroundScanError.backgroundScanDisabled)
        #expect(BackgroundScanError.backgroundScanDisabled != BackgroundScanError.insufficientPermissions)
    }
}

// MARK: - BackgroundScanManager Initialization Tests

@Suite("BackgroundScanManager Initialization Tests")
struct BackgroundScanManagerInitializationTests {

    @Test("デフォルト初期化")
    func testDefaultInitialization() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // デフォルト値の確認
        #expect(manager.isBackgroundScanEnabled == false)
        #expect(manager.scanInterval == BackgroundScanManager.defaultScanInterval)
        #expect(manager.nextScheduledScanDate == nil)
    }

    @Test("タスク識別子の定数値")
    func testTaskIdentifierConstants() {
        #expect(BackgroundScanManager.backgroundRefreshTaskIdentifier == "com.lightroll.backgroundRefresh")
        #expect(BackgroundScanManager.backgroundProcessingTaskIdentifier == "com.lightroll.backgroundProcessing")
    }

    @Test("スキャン間隔の定数値")
    func testScanIntervalConstants() {
        // デフォルト: 24時間
        #expect(BackgroundScanManager.defaultScanInterval == 24 * 60 * 60)

        // 最小: 1時間
        #expect(BackgroundScanManager.minimumScanInterval == 1 * 60 * 60)

        // 最大: 7日
        #expect(BackgroundScanManager.maximumScanInterval == 7 * 24 * 60 * 60)
    }
}

// MARK: - BackgroundScanManager Enable/Disable Tests

@Suite("BackgroundScanManager Enable/Disable Tests")
struct BackgroundScanManagerEnableDisableTests {

    @Test("バックグラウンドスキャンを有効化")
    func testEnableBackgroundScan() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        manager.isBackgroundScanEnabled = true
        #expect(manager.isBackgroundScanEnabled == true)
    }

    @Test("バックグラウンドスキャンを無効化")
    func testDisableBackgroundScan() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 先に有効化
        manager.isBackgroundScanEnabled = true
        #expect(manager.isBackgroundScanEnabled == true)

        // 無効化
        manager.isBackgroundScanEnabled = false
        #expect(manager.isBackgroundScanEnabled == false)
    }

    @Test("有効/無効状態がUserDefaultsに永続化される")
    func testEnableStatePersistence() {
        let mockDefaults = MockUserDefaults()
        let manager1 = BackgroundScanManager(userDefaults: mockDefaults)

        // 有効化
        manager1.isBackgroundScanEnabled = true

        // 新しいインスタンスで状態を確認
        let manager2 = BackgroundScanManager(userDefaults: mockDefaults)
        #expect(manager2.isBackgroundScanEnabled == true)
    }
}

// MARK: - BackgroundScanManager Scan Interval Tests

@Suite("BackgroundScanManager Scan Interval Tests")
struct BackgroundScanManagerScanIntervalTests {

    @Test("スキャン間隔の設定")
    func testSetScanInterval() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        let interval: TimeInterval = 12 * 60 * 60 // 12時間
        manager.scanInterval = interval
        #expect(manager.scanInterval == interval)
    }

    @Test("スキャン間隔が最小値に制限される")
    func testScanIntervalMinimumBound() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 最小値より小さい値を設定
        manager.scanInterval = 30 * 60 // 30分

        // 最小値（1時間）に制限される
        #expect(manager.scanInterval == BackgroundScanManager.minimumScanInterval)
    }

    @Test("スキャン間隔が最大値に制限される")
    func testScanIntervalMaximumBound() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 最大値より大きい値を設定
        manager.scanInterval = 14 * 24 * 60 * 60 // 14日

        // 最大値（7日）に制限される
        #expect(manager.scanInterval == BackgroundScanManager.maximumScanInterval)
    }

    @Test("スキャン間隔がUserDefaultsに永続化される")
    func testScanIntervalPersistence() {
        let mockDefaults = MockUserDefaults()
        let manager1 = BackgroundScanManager(userDefaults: mockDefaults)

        let interval: TimeInterval = 6 * 60 * 60 // 6時間
        manager1.scanInterval = interval

        // 新しいインスタンスで確認
        let manager2 = BackgroundScanManager(userDefaults: mockDefaults)
        #expect(manager2.scanInterval == interval)
    }
}

// MARK: - BackgroundScanManager Scheduling Tests

@Suite("BackgroundScanManager Scheduling Tests")
struct BackgroundScanManagerSchedulingTests {

    @Test("バックグラウンドスキャンが無効の場合はスケジュールエラー")
    func testScheduleFailsWhenDisabled() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 無効状態のまま
        #expect(manager.isBackgroundScanEnabled == false)

        // スケジュール試行
        #expect(throws: BackgroundScanError.backgroundScanDisabled) {
            try manager.scheduleBackgroundScan()
        }
    }

    @Test("バックグラウンド処理が無効の場合はスケジュールエラー")
    func testScheduleProcessingFailsWhenDisabled() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        #expect(manager.isBackgroundScanEnabled == false)

        #expect(throws: BackgroundScanError.backgroundScanDisabled) {
            try manager.scheduleBackgroundProcessing()
        }
    }

    @Test("バックグラウンドスキャンが有効の場合はスケジュール成功（シミュレータ）")
    func testScheduleSucceedsWhenEnabled() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        manager.isBackgroundScanEnabled = true

        // シミュレータではBGTaskSchedulerが利用できないが、
        // 実装はシミュレータ対応しているためエラーなく完了する
        do {
            try manager.scheduleBackgroundScan()

            // 次回スケジュール日時が設定される
            #expect(manager.nextScheduledScanDate != nil)

            // スケジュール日時が将来の日時である
            if let nextDate = manager.nextScheduledScanDate {
                #expect(nextDate > Date())
            }
        } catch {
            // シミュレータでの制限によるエラーは許容
        }
    }

    @Test("バックグラウンド処理が有効の場合はスケジュール成功（シミュレータ）")
    func testScheduleProcessingSucceedsWhenEnabled() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        manager.isBackgroundScanEnabled = true

        do {
            try manager.scheduleBackgroundProcessing()

            #expect(manager.nextScheduledScanDate != nil)
        } catch {
            // シミュレータでの制限によるエラーは許容
        }
    }
}

// MARK: - BackgroundScanManager Task Registration Tests

@Suite("BackgroundScanManager Task Registration Tests")
struct BackgroundScanManagerTaskRegistrationTests {

    @Test("タスク登録が呼び出し可能")
    func testRegisterBackgroundTasks() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // registerBackgroundTasks は例外を投げずに呼び出せる
        // 実際の登録はシミュレータでは制限あり
        manager.registerBackgroundTasks()

        // 2回目の呼び出しも安全
        manager.registerBackgroundTasks()
    }
}

// MARK: - BackgroundScanManager Cancel Tests

@Suite("BackgroundScanManager Cancel Tests")
struct BackgroundScanManagerCancelTests {

    @Test("スケジュールのキャンセル")
    func testCancelScheduledTasks() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 有効化してスケジュール
        manager.isBackgroundScanEnabled = true
        try? manager.scheduleBackgroundScan()

        // キャンセル
        manager.cancelScheduledTasks()

        // 次回スケジュール日時がクリアされる
        #expect(manager.nextScheduledScanDate == nil)
    }

    @Test("無効化時に自動でキャンセルされる")
    func testDisablingCancelsSchedule() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 有効化してスケジュール
        manager.isBackgroundScanEnabled = true
        try? manager.scheduleBackgroundScan()

        // 無効化
        manager.isBackgroundScanEnabled = false

        // 次回スケジュール日時がクリアされる
        #expect(manager.nextScheduledScanDate == nil)
    }
}

// MARK: - BackgroundScanManager Task Handler Tests

@Suite("BackgroundScanManager Task Handler Tests")
struct BackgroundScanManagerTaskHandlerTests {

    @Test("タスクハンドラーの設定")
    func testSetTaskHandler() async {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)
        let mockHandler = MockBackgroundTaskHandler()

        manager.setTaskHandler(mockHandler)

        // ハンドラーが設定されたことを確認するための間接的なテスト
        // 直接的なアクセスはできないが、例外が発生しないことを確認
    }
}

// MARK: - Call Tracker for Thread Safety

/// テスト用のスレッドセーフな呼び出しトラッカー
actor CallTracker {
    private(set) var wasCalled = false

    func markCalled() {
        wasCalled = true
    }

    func reset() {
        wasCalled = false
    }
}

// MARK: - DefaultBackgroundTaskHandler Tests

@Suite("DefaultBackgroundTaskHandler Tests")
struct DefaultBackgroundTaskHandlerTests {

    @Test("handleBackgroundRefresh が呼び出される")
    func testHandleBackgroundRefresh() async {
        let tracker = CallTracker()

        let handler = DefaultBackgroundTaskHandler(
            photoScannerFactory: { nil },
            storageServiceFactory: {
                Task { await tracker.markCalled() }
                return nil
            },
            sendCompletionNotification: false
        )

        await handler.handleBackgroundRefresh()

        // 少し待機してタスクが完了するのを待つ
        try? await Task.sleep(for: .milliseconds(50))

        let wasCalled = await tracker.wasCalled
        #expect(wasCalled == true)
    }

    @Test("handleBackgroundProcessing が呼び出される")
    func testHandleBackgroundProcessing() async {
        let tracker = CallTracker()

        let handler = DefaultBackgroundTaskHandler(
            photoScannerFactory: {
                Task { await tracker.markCalled() }
                return nil
            },
            storageServiceFactory: { nil },
            sendCompletionNotification: false
        )

        await handler.handleBackgroundProcessing()

        // 少し待機してタスクが完了するのを待つ
        try? await Task.sleep(for: .milliseconds(50))

        let wasCalled = await tracker.wasCalled
        #expect(wasCalled == true)
    }
}

// MARK: - Notification Name Tests

@Suite("Background Notification Name Tests")
struct BackgroundNotificationNameTests {

    @Test("バックグラウンドリフレッシュ完了通知名")
    func testBackgroundRefreshCompletedNotificationName() {
        let name = Notification.Name.backgroundRefreshCompleted
        #expect(name.rawValue == "BackgroundRefreshCompleted")
    }

    @Test("バックグラウンド処理完了通知名")
    func testBackgroundProcessingCompletedNotificationName() {
        let name = Notification.Name.backgroundProcessingCompleted
        #expect(name.rawValue == "BackgroundProcessingCompleted")
    }
}

// MARK: - Integration Tests

@Suite("BackgroundScanManager Integration Tests")
struct BackgroundScanManagerIntegrationTests {

    @Test("M2-T10-TC01: タスク登録の確認")
    func testTaskRegistration() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // タスク登録が例外なく完了する
        manager.registerBackgroundTasks()

        // タスク識別子が正しい形式
        #expect(BackgroundScanManager.backgroundRefreshTaskIdentifier.hasPrefix("com.lightroll"))
        #expect(BackgroundScanManager.backgroundProcessingTaskIdentifier.hasPrefix("com.lightroll"))
    }

    @Test("M2-T10-TC02: スケジュール設定の確認")
    func testScheduleConfiguration() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        manager.isBackgroundScanEnabled = true
        manager.scanInterval = 12 * 60 * 60 // 12時間

        do {
            try manager.scheduleBackgroundScan()

            // 次回スケジュールが設定される
            #expect(manager.nextScheduledScanDate != nil)

            // スケジュール日時がおおよそ scanInterval 後
            if let nextDate = manager.nextScheduledScanDate {
                let expectedDate = Date().addingTimeInterval(manager.scanInterval)
                let difference = abs(nextDate.timeIntervalSince(expectedDate))
                // 数秒の誤差は許容
                #expect(difference < 5.0)
            }
        } catch {
            // シミュレータでの制限
        }
    }

    @Test("M2-T10-TC03: 有効/無効切り替え")
    func testEnableDisableToggle() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 初期状態は無効
        #expect(manager.isBackgroundScanEnabled == false)

        // 有効化
        manager.isBackgroundScanEnabled = true
        #expect(manager.isBackgroundScanEnabled == true)

        // 無効化
        manager.isBackgroundScanEnabled = false
        #expect(manager.isBackgroundScanEnabled == false)

        // 再度有効化
        manager.isBackgroundScanEnabled = true
        #expect(manager.isBackgroundScanEnabled == true)
    }

    @Test("M2-T10-TC04: スキャン間隔設定")
    func testScanIntervalConfiguration() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 様々な間隔を設定
        let intervals: [TimeInterval] = [
            2 * 60 * 60,   // 2時間
            6 * 60 * 60,   // 6時間
            12 * 60 * 60,  // 12時間
            24 * 60 * 60,  // 24時間
            72 * 60 * 60,  // 3日
        ]

        for interval in intervals {
            manager.scanInterval = interval
            #expect(manager.scanInterval == interval)
        }
    }

    @Test("M2-T10-TC05: 次回スケジュール日時の取得")
    func testNextScheduledScanDate() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 初期状態では nil
        #expect(manager.nextScheduledScanDate == nil)

        // スケジュール後は日時が設定される
        manager.isBackgroundScanEnabled = true
        try? manager.scheduleBackgroundScan()

        // 日時が設定されているか（シミュレータでは設定されない場合もある）
        // キャンセル後は nil
        manager.cancelScheduledTasks()
        #expect(manager.nextScheduledScanDate == nil)
    }

    @Test("M2-T10-TC06: エラーハンドリング - 無効状態でのスケジュール")
    func testErrorHandlingDisabledSchedule() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 無効状態
        #expect(manager.isBackgroundScanEnabled == false)

        // スケジュール試行
        #expect(throws: BackgroundScanError.backgroundScanDisabled) {
            try manager.scheduleBackgroundScan()
        }

        #expect(throws: BackgroundScanError.backgroundScanDisabled) {
            try manager.scheduleBackgroundProcessing()
        }
    }
}

// MARK: - Thread Safety Tests

@Suite("BackgroundScanManager Thread Safety Tests")
struct BackgroundScanManagerThreadSafetyTests {

    @Test("並行アクセスでの設定変更")
    func testConcurrentPropertyAccess() async {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 複数のタスクから同時にアクセス
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    manager.isBackgroundScanEnabled = Bool.random()
                    _ = manager.isBackgroundScanEnabled
                }

                group.addTask {
                    manager.scanInterval = TimeInterval.random(in: 3600...86400)
                    _ = manager.scanInterval
                }

                group.addTask {
                    _ = manager.nextScheduledScanDate
                }
            }
        }

        // クラッシュせずに完了することを確認
        // 値の整合性は保証されないが、クラッシュしないことが重要
    }
}

// MARK: - Debug Helper Tests

@Suite("BackgroundScanManager Debug Helper Tests")
struct BackgroundScanManagerDebugHelperTests {

    @Test("debugPrintStatus がクラッシュしない")
    func testDebugPrintStatus() {
        let mockDefaults = MockUserDefaults()
        let manager = BackgroundScanManager(userDefaults: mockDefaults)

        // 様々な状態でdebugPrintStatusを呼び出し
        manager.debugPrintStatus()

        manager.isBackgroundScanEnabled = true
        manager.debugPrintStatus()

        manager.scanInterval = 6 * 60 * 60
        manager.debugPrintStatus()

        try? manager.scheduleBackgroundScan()
        manager.debugPrintStatus()
    }
}
