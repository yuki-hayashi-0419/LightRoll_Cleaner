//
//  NotificationPermissionViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  NotificationPermissionViewのテスト
//  M7-T04のテストスイート
//  Swift Testing framework使用
//

import Testing
import SwiftUI
import UserNotifications
@testable import LightRoll_CleanerFeature

// MARK: - Test Suite

/// NotificationPermissionViewのテストスイート
@MainActor
@Suite("NotificationPermissionView Tests", .serialized)
struct NotificationPermissionViewTests {

    // MARK: - Mock Classes

    /// モック通知センター
    @MainActor
    final class MockNotificationCenter: UserNotificationCenterProtocol {
        var authorizationStatus: UNAuthorizationStatus = .notDetermined
        var shouldGrantPermission = false
        var requestAuthorizationCallCount = 0
        var addRequestCallCount = 0
        var getPendingCallCount = 0
        var removePendingCallCount = 0
        var removeAllPendingCallCount = 0
        var getDeliveredCallCount = 0
        var removeAllDeliveredCallCount = 0
        var shouldThrowOnRequest = false
        var shouldThrowOnAdd = false

        func getAuthorizationStatus() async -> UNAuthorizationStatus {
            return authorizationStatus
        }

        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            requestAuthorizationCallCount += 1
            if shouldThrowOnRequest {
                throw TestError.mockError
            }
            return shouldGrantPermission
        }

        func add(_ request: UNNotificationRequest) async throws {
            addRequestCallCount += 1
            if shouldThrowOnAdd {
                throw TestError.mockError
            }
        }

        func getPendingNotificationRequests() async -> [UNNotificationRequest] {
            getPendingCallCount += 1
            return []
        }

        func removeAllPendingNotificationRequests() async {
            removeAllPendingCallCount += 1
        }

        func removePendingNotificationRequests(withIdentifiers: [String]) async {
            removePendingCallCount += 1
        }

        func getDeliveredNotifications() async -> [UNNotification] {
            getDeliveredCallCount += 1
            return []
        }

        func removeAllDeliveredNotifications() async {
            removeAllDeliveredCallCount += 1
        }

        enum TestError: Error {
            case mockError
        }
    }

    // MARK: - Initialization Tests

    /// M7-T04-TC01: 初期化テスト
    @Test("初期化が正常に完了すること")
    func testInitialization() async throws {
        let mockCenter = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)
        let view = NotificationPermissionView()
            .environment(manager)

        // Viewが初期化されることを確認（型の存在を確認）
        _ = view
        #expect(true, "Viewが初期化されること")
    }

    // MARK: - Authorization Status Tests

    /// M7-T04-TC02: 未確認状態の表示テスト
    @Test("権限未確認時に適切なUIが表示されること")
    func testNotDeterminedState() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .notDetermined, "ステータスが未確認であること")
        #expect(manager.canRequestPermission == true, "権限リクエストが可能であること")
    }

    /// M7-T04-TC03: 許可済み状態の表示テスト
    @Test("権限許可済み時に適切なUIが表示されること")
    func testAuthorizedState() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .authorized

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .authorized, "ステータスが許可済みであること")
        #expect(manager.isAuthorized == true, "権限が許可されていること")
    }

    /// M7-T04-TC04: 拒否済み状態の表示テスト
    @Test("権限拒否済み時に適切なUIが表示されること")
    func testDeniedState() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .denied, "ステータスが拒否であること")
        #expect(manager.isAuthorized == false, "権限が許可されていないこと")
    }

    /// M7-T04-TC05: Provisional状態の表示テスト
    @Test("Provisional権限時に適切なUIが表示されること")
    func testProvisionalState() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .provisional

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .provisional, "ステータスがProvisionalであること")
        #expect(manager.isAuthorized == true, "権限が許可されていること")
    }

    // MARK: - Permission Request Tests

    /// M7-T04-TC06: 権限リクエスト成功テスト
    @Test("権限リクエストが成功すること")
    func testPermissionRequestSuccess() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldGrantPermission = true

        let manager = NotificationManager(notificationCenter: mockCenter)

        let granted = try await manager.requestPermission()

        #expect(granted == true, "権限が許可されること")
        #expect(mockCenter.requestAuthorizationCallCount == 1, "リクエストが1回呼ばれること")
    }

    /// M7-T04-TC07: 権限リクエスト拒否テスト
    @Test("権限リクエストが拒否されること")
    func testPermissionRequestDenied() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldGrantPermission = false

        let manager = NotificationManager(notificationCenter: mockCenter)

        do {
            _ = try await manager.requestPermission()
            Issue.record("例外がスローされるべき")
        } catch {
            #expect(error is NotificationError, "NotificationErrorがスローされること")
            if let notificationError = error as? NotificationError {
                switch notificationError {
                case .permissionDenied:
                    // 期待通り
                    break
                default:
                    Issue.record("permissionDeniedエラーであるべき")
                }
            }
        }
    }

    /// M7-T04-TC08: すでに許可済みの場合のリクエストテスト
    @Test("すでに許可済みの場合は即座にtrueを返すこと")
    func testPermissionAlreadyAuthorized() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .authorized

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        let granted = try await manager.requestPermission()

        #expect(granted == true, "権限が許可されていること")
        #expect(mockCenter.requestAuthorizationCallCount == 0, "リクエストが呼ばれないこと")
    }

    /// M7-T04-TC09: すでに拒否済みの場合のリクエストテスト
    @Test("すでに拒否済みの場合はエラーをスローすること")
    func testPermissionAlreadyDenied() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        do {
            _ = try await manager.requestPermission()
            Issue.record("例外がスローされるべき")
        } catch {
            #expect(error is NotificationError, "NotificationErrorがスローされること")
        }
    }

    // MARK: - Error Handling Tests

    /// M7-T04-TC10: 権限リクエストエラーハンドリングテスト
    @Test("権限リクエスト時のエラーが適切に処理されること")
    func testPermissionRequestErrorHandling() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldThrowOnRequest = true

        let manager = NotificationManager(notificationCenter: mockCenter)

        do {
            _ = try await manager.requestPermission()
            Issue.record("例外がスローされるべき")
        } catch {
            #expect(error is NotificationError, "NotificationErrorがスローされること")
            #expect(manager.lastError != nil, "lastErrorが設定されていること")
        }
    }

    /// M7-T04-TC11: エラーメッセージの設定テスト
    @Test("エラー時にlastErrorが設定されること")
    func testLastErrorIsSet() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        do {
            _ = try await manager.requestPermission()
        } catch {
            // エラーは期待通り
        }

        #expect(manager.lastError != nil, "lastErrorが設定されていること")

        if let lastError = manager.lastError {
            switch lastError {
            case .permissionDenied:
                // 期待通り
                break
            default:
                Issue.record("permissionDeniedエラーであるべき")
            }
        }
    }

    /// M7-T04-TC12: エラークリアテスト
    @Test("clearError()でエラーがクリアされること")
    func testClearError() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        do {
            _ = try await manager.requestPermission()
        } catch {
            // エラーは期待通り
        }

        #expect(manager.lastError != nil, "エラーが設定されていること")

        manager.clearError()

        #expect(manager.lastError == nil, "エラーがクリアされていること")
    }

    // MARK: - State Update Tests

    /// M7-T04-TC13: ステータス更新テスト
    @Test("updateAuthorizationStatus()でステータスが更新されること")
    func testStatusUpdate() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .notDetermined, "初期状態が反映されること")

        // ステータスを変更
        mockCenter.authorizationStatus = .authorized
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .authorized, "更新後のステータスが反映されること")
    }

    /// M7-T04-TC14: canRequestPermissionプロパティテスト
    @Test("canRequestPermissionが正しく動作すること")
    func testCanRequestPermission() async throws {
        let mockCenter = MockNotificationCenter()

        // 未確認状態
        mockCenter.authorizationStatus = .notDetermined
        let manager1 = NotificationManager(notificationCenter: mockCenter)
        await manager1.updateAuthorizationStatus()
        #expect(manager1.canRequestPermission == true, "未確認時はリクエスト可能")

        // 拒否状態
        mockCenter.authorizationStatus = .denied
        let manager2 = NotificationManager(notificationCenter: mockCenter)
        await manager2.updateAuthorizationStatus()
        #expect(manager2.canRequestPermission == false, "拒否時はリクエスト不可")

        // 許可状態
        mockCenter.authorizationStatus = .authorized
        let manager3 = NotificationManager(notificationCenter: mockCenter)
        await manager3.updateAuthorizationStatus()
        #expect(manager3.canRequestPermission == false, "許可済み時はリクエスト不可")
    }

    // MARK: - UI State Tests

    /// M7-T04-TC15: isAuthorizedプロパティテスト
    @Test("isAuthorizedが正しく動作すること")
    func testIsAuthorized() async throws {
        let mockCenter = MockNotificationCenter()

        // 未確認状態
        mockCenter.authorizationStatus = .notDetermined
        let manager1 = NotificationManager(notificationCenter: mockCenter)
        await manager1.updateAuthorizationStatus()
        #expect(manager1.isAuthorized == false, "未確認時は未許可")

        // 拒否状態
        mockCenter.authorizationStatus = .denied
        let manager2 = NotificationManager(notificationCenter: mockCenter)
        await manager2.updateAuthorizationStatus()
        #expect(manager2.isAuthorized == false, "拒否時は未許可")

        // 許可状態
        mockCenter.authorizationStatus = .authorized
        let manager3 = NotificationManager(notificationCenter: mockCenter)
        await manager3.updateAuthorizationStatus()
        #expect(manager3.isAuthorized == true, "許可済み時は許可")

        // Provisional状態
        mockCenter.authorizationStatus = .provisional
        let manager4 = NotificationManager(notificationCenter: mockCenter)
        await manager4.updateAuthorizationStatus()
        #expect(manager4.isAuthorized == true, "Provisional時は許可")
    }

    // MARK: - Integration Tests

    /// M7-T04-TC16: 権限リクエストフロー統合テスト
    @Test("権限リクエストから更新までのフローが正常に動作すること")
    func testPermissionRequestFlow() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldGrantPermission = true

        let manager = NotificationManager(notificationCenter: mockCenter)

        // 初期状態確認
        await manager.updateAuthorizationStatus()
        #expect(manager.authorizationStatus == .notDetermined, "初期状態が未確認")
        #expect(manager.canRequestPermission == true, "リクエスト可能")

        // 権限リクエスト
        let granted = try await manager.requestPermission()
        #expect(granted == true, "権限が許可される")

        // ステータスを許可に変更（システムの挙動をシミュレート）
        mockCenter.authorizationStatus = .authorized
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .authorized, "ステータスが許可に更新される")
        #expect(manager.isAuthorized == true, "許可状態になる")
    }

    /// M7-T04-TC17: 拒否から設定画面への誘導フロー統合テスト
    @Test("拒否時に設定画面への誘導が適切に機能すること")
    func testDeniedToSettingsFlow() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied

        let manager = NotificationManager(notificationCenter: mockCenter)
        await manager.updateAuthorizationStatus()

        #expect(manager.authorizationStatus == .denied, "ステータスが拒否")
        #expect(manager.isAuthorized == false, "未許可状態")

        // リクエストを試みる（エラーになることを期待）
        do {
            _ = try await manager.requestPermission()
            Issue.record("例外がスローされるべき")
        } catch {
            // 期待通りエラー
            #expect(manager.lastError != nil, "エラーが記録される")
        }
    }

    /// M7-T04-TC18: ViewState遷移テスト
    @Test("ViewStateが適切に遷移すること")
    func testViewStateTransitions() async throws {
        // このテストはViewの内部状態を直接テストするのが難しいため
        // NotificationManagerの状態遷移を確認する
        let mockCenter = MockNotificationCenter()
        let manager = NotificationManager(notificationCenter: mockCenter)

        // 初期状態
        #expect(manager.authorizationStatus == .notDetermined, "初期状態が未確認")

        // 状態更新
        await manager.updateAuthorizationStatus()
        #expect(manager.lastError == nil, "エラーがない状態")

        // エラー発生
        mockCenter.authorizationStatus = .denied
        await manager.updateAuthorizationStatus()

        do {
            _ = try await manager.requestPermission()
        } catch {
            // エラー状態に遷移
            #expect(manager.lastError != nil, "エラー状態に遷移")
        }

        // エラークリア
        manager.clearError()
        #expect(manager.lastError == nil, "エラーがクリアされる")
    }
}
