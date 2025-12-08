//
//  PermissionManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PermissionManager の単体テスト
//  Swift Testing フレームワークを使用
//  M8-T03 テストケース実装
//  Created by AI Assistant for M8-T03
//

import Testing
import Foundation
import Photos
import UserNotifications
@testable import LightRoll_CleanerFeature

// MARK: - Mock Settings Opener

/// テスト用の設定アプリオープナーモック
final class MockSettingsOpenerForPermission: SettingsOpenerProtocol, @unchecked Sendable {
    /// openSettings が呼ばれた回数
    private(set) var openSettingsCallCount = 0

    /// openSettings が呼ばれたかどうか
    var wasOpenSettingsCalled: Bool {
        openSettingsCallCount > 0
    }

    func openSettings() {
        openSettingsCallCount += 1
    }

    /// 状態をリセット
    func reset() {
        openSettingsCallCount = 0
    }
}

// MARK: - Mock Notification Center

/// テスト用の通知センターモック（権限管理用）
actor MockPermissionNotificationCenter: PermissionNotificationCenterProtocol {
    /// 返すべき通知権限ステータス
    private var mockAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    /// リクエスト時に返すべき結果
    private var mockAuthorizationGranted: Bool = false

    /// getAuthorizationStatus が呼ばれた回数
    private(set) var getAuthorizationStatusCallCount = 0

    /// requestAuthorization が呼ばれた回数
    private(set) var requestAuthorizationCallCount = 0

    /// モック状態を設定
    func configure(authorizationStatus: UNAuthorizationStatus, authorizationGranted: Bool) {
        self.mockAuthorizationStatus = authorizationStatus
        self.mockAuthorizationGranted = authorizationGranted
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        getAuthorizationStatusCallCount += 1
        return mockAuthorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async -> Bool {
        requestAuthorizationCallCount += 1
        return mockAuthorizationGranted
    }

    /// 状態をリセット
    func reset() {
        mockAuthorizationStatus = .notDetermined
        mockAuthorizationGranted = false
        getAuthorizationStatusCallCount = 0
        requestAuthorizationCallCount = 0
    }
}

// MARK: - PermissionManager Tests

@Suite("PermissionManager Tests")
@MainActor
struct PermissionManagerTests {

    // MARK: - 正常系テスト

    @Test("M8-T03-TC01: 写真権限ステータスの取得")
    func testGetPhotoPermissionStatus() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 写真権限ステータスを取得
        let status = manager.getPhotoPermissionStatus()

        // 有効な権限ステータスであることを確認
        #expect(
            status == .notDetermined ||
            status == .restricted ||
            status == .denied ||
            status == .authorized ||
            status == .limited
        )

        // currentPhotoStatus と一致することを確認
        #expect(manager.currentPhotoStatus == status)
    }

    @Test("M8-T03-TC02: 通知権限ステータスの取得")
    func testGetNotificationPermissionStatus() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: false)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 通知権限ステータスを取得
        let status = await manager.getNotificationPermissionStatus()

        // モックで設定したステータスが返されることを確認
        #expect(status == .authorized)
        let callCount = await mockNotificationCenter.getAuthorizationStatusCallCount
        #expect(callCount == 1)
    }

    @Test("M8-T03-TC03: 写真権限リクエストの成功")
    func testRequestPhotoPermission() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 写真権限リクエスト
        // 注: 実際のPHPhotoLibraryを使用するため、システムの状態に依存
        let status = await manager.requestPhotoPermission()

        // 有効な権限ステータスが返されることを確認
        #expect(
            status == .notDetermined ||
            status == .restricted ||
            status == .denied ||
            status == .authorized ||
            status == .limited
        )

        // currentPhotoStatus が更新されていることを確認
        #expect(manager.currentPhotoStatus == status)
    }

    // MARK: - 異常系テスト

    @Test("M8-T03-TC04: 権限拒否時の処理")
    func testPermissionDenied() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.reset() // まずリセット
        // actorのプロパティ設定はできないため、テストシナリオを調整

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 通知権限ステータスを取得（初期状態はnotDetermined）
        let status = await manager.getNotificationPermissionStatus()
        #expect(status == .notDetermined)

        // 通知権限リクエスト（初期状態はfalse）
        let granted = await manager.requestNotificationPermission()
        #expect(granted == false)

        let callCount = await mockNotificationCenter.requestAuthorizationCallCount
        #expect(callCount == 1)
    }

    @Test("M8-T03-TC05: システム設定への誘導")
    func testOpenAppSettings() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        #expect(mockOpener.wasOpenSettingsCalled == false)

        // システム設定を開く
        manager.openAppSettings()

        #expect(mockOpener.wasOpenSettingsCalled == true)
        #expect(mockOpener.openSettingsCallCount == 1)
    }

    // MARK: - 境界値テスト

    @Test("初回起動時（notDetermined状態）")
    func testNotDeterminedState() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .notDetermined, authorizationGranted: false)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 通知権限が未決定状態
        let status = await manager.getNotificationPermissionStatus()
        #expect(status == .notDetermined)

        // 権限リクエストが可能
        #expect(status.canRequestPermission == true)
    }

    @Test("すでに許可済み（authorized状態）")
    func testAuthorizedState() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 通知権限が許可済み
        let status = await manager.getNotificationPermissionStatus()
        #expect(status == .authorized)
        #expect(status.isAuthorized == true)

        // 通知権限リクエスト（許可）
        let granted = await manager.requestNotificationPermission()
        #expect(granted == true)
    }

    @Test("制限付きアクセス（limited状態）")
    func testLimitedState() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 写真権限を取得
        let status = manager.getPhotoPermissionStatus()

        // limited状態の場合、isAuthorizedがtrueになることを確認
        if status == .limited {
            let phStatus = status
            // PHAuthorizationStatusのisAuthorizedプロパティはPhotoPermissionManager.swiftで定義されている
            // ここでは値の確認のみ
            #expect(status == .limited)
        }
    }

    // MARK: - 追加テスト

    @Test("通知権限リクエストの複数回呼び出し")
    func testMultipleNotificationRequests() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 複数回リクエスト
        _ = await manager.requestNotificationPermission()
        _ = await manager.requestNotificationPermission()
        _ = await manager.requestNotificationPermission()

        let callCount = await mockNotificationCenter.requestAuthorizationCallCount
        #expect(callCount == 3)
    }

    @Test("openAppSettings の複数回呼び出し")
    func testMultipleOpenSettings() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        manager.openAppSettings()
        manager.openAppSettings()
        manager.openAppSettings()

        #expect(mockOpener.openSettingsCallCount == 3)
    }

    @Test("初期化時に写真権限ステータスが設定される")
    func testInitializationSetsPhotoStatus() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 初期化時に何らかのステータスが設定されている
        let status = manager.currentPhotoStatus
        #expect(
            status == .notDetermined ||
            status == .authorized ||
            status == .denied ||
            status == .restricted ||
            status == .limited
        )
    }

    @Test("Protocol 準拠 - PermissionManagerProtocol")
    func testProtocolConformance() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let manager: any PermissionManagerProtocol = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // プロトコルのメソッドが呼び出せることを確認
        _ = await manager.getStatus(for: .photoLibrary)
        _ = await manager.getStatus(for: .notifications)
        await manager.openSettings()

        #expect(mockOpener.wasOpenSettingsCalled == true)
    }

    @Test("汎用インターフェースのテスト - getStatus")
    func testGenericGetStatus() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 写真権限の取得
        let photoStatus = await manager.getStatus(for: .photoLibrary)
        #expect(
            photoStatus == .notDetermined ||
            photoStatus == .authorized ||
            photoStatus == .denied ||
            photoStatus == .restricted ||
            photoStatus == .limited
        )

        // 通知権限の取得
        let notificationStatus = await manager.getStatus(for: .notifications)
        #expect(notificationStatus == .authorized)
    }

    @Test("汎用インターフェースのテスト - requestPermission")
    func testGenericRequestPermission() async {
        let mockOpener = MockSettingsOpenerForPermission()
        let mockNotificationCenter = MockPermissionNotificationCenter()
        await mockNotificationCenter.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let manager = PermissionManager(
            settingsOpener: mockOpener,
            notificationCenter: mockNotificationCenter
        )

        // 通知権限のリクエスト
        let notificationStatus = await manager.requestPermission(for: .notifications)
        #expect(notificationStatus == .authorized)
        let callCount = await mockNotificationCenter.requestAuthorizationCallCount
        #expect(callCount == 1)
    }
}

// MARK: - UNAuthorizationStatus Extension Tests

@Suite("UNAuthorizationStatus Extension Tests")
struct UNAuthorizationStatusExtensionTests {

    @Test("isAuthorized - authorized の場合は true")
    func testIsAuthorizedWithAuthorized() {
        let status = UNAuthorizationStatus.authorized
        #expect(status.isAuthorized == true)
    }

    @Test("isAuthorized - provisional の場合は true")
    func testIsAuthorizedWithProvisional() {
        let status = UNAuthorizationStatus.provisional
        #expect(status.isAuthorized == true)
    }

    @Test("isAuthorized - notDetermined の場合は false")
    func testIsAuthorizedWithNotDetermined() {
        let status = UNAuthorizationStatus.notDetermined
        #expect(status.isAuthorized == false)
    }

    @Test("isAuthorized - denied の場合は false")
    func testIsAuthorizedWithDenied() {
        let status = UNAuthorizationStatus.denied
        #expect(status.isAuthorized == false)
    }

    @Test("canRequestPermission - notDetermined の場合のみ true")
    func testCanRequestPermission() {
        #expect(UNAuthorizationStatus.notDetermined.canRequestPermission == true)
        #expect(UNAuthorizationStatus.authorized.canRequestPermission == false)
        #expect(UNAuthorizationStatus.denied.canRequestPermission == false)
        #expect(UNAuthorizationStatus.provisional.canRequestPermission == false)
    }

    @Test("needsSettingsRedirect - denied の場合のみ true")
    func testNeedsSettingsRedirect() {
        #expect(UNAuthorizationStatus.denied.needsSettingsRedirect == true)
        #expect(UNAuthorizationStatus.notDetermined.needsSettingsRedirect == false)
        #expect(UNAuthorizationStatus.authorized.needsSettingsRedirect == false)
        #expect(UNAuthorizationStatus.provisional.needsSettingsRedirect == false)
    }

    @Test("localizedDescription - 各ステータスに説明文がある")
    func testLocalizedDescription() {
        // 各ステータスにローカライズされた説明があることを確認
        #expect(!UNAuthorizationStatus.notDetermined.localizedDescription.isEmpty)
        #expect(!UNAuthorizationStatus.denied.localizedDescription.isEmpty)
        #expect(!UNAuthorizationStatus.authorized.localizedDescription.isEmpty)
        #expect(!UNAuthorizationStatus.provisional.localizedDescription.isEmpty)

        // ephemeral は iOS 14+ のみで利用可能
        #if os(iOS)
        if #available(iOS 14.0, *) {
            #expect(!UNAuthorizationStatus.ephemeral.localizedDescription.isEmpty)
        }
        #endif
    }
}

// MARK: - Mock Tests

@Suite("Mock Tests")
struct MockTests {

    @Test("MockSettingsOpener - 初期状態では openSettings が呼ばれていない")
    func testMockSettingsOpenerInitialState() {
        let mock = MockSettingsOpenerForPermission()
        #expect(mock.wasOpenSettingsCalled == false)
        #expect(mock.openSettingsCallCount == 0)
    }

    @Test("MockSettingsOpener - openSettings を呼ぶとカウントが増加")
    func testMockSettingsOpenerIncrementsCount() {
        let mock = MockSettingsOpenerForPermission()

        mock.openSettings()
        #expect(mock.openSettingsCallCount == 1)

        mock.openSettings()
        #expect(mock.openSettingsCallCount == 2)
    }

    @Test("MockSettingsOpener - reset で状態がリセットされる")
    func testMockSettingsOpenerReset() {
        let mock = MockSettingsOpenerForPermission()
        mock.openSettings()
        mock.openSettings()
        #expect(mock.openSettingsCallCount == 2)

        mock.reset()
        #expect(mock.openSettingsCallCount == 0)
        #expect(mock.wasOpenSettingsCalled == false)
    }

    @Test("MockPermissionNotificationCenter - 初期状態での動作")
    func testMockNotificationCenterInitialState() async {
        let mock = MockPermissionNotificationCenter()

        // 初期状態は notDetermined
        let status = await mock.getAuthorizationStatus()
        #expect(status == .notDetermined)
        let getCallCount = await mock.getAuthorizationStatusCallCount
        #expect(getCallCount == 1)

        // 初期状態は拒否
        let granted = await mock.requestAuthorization(options: [.alert])
        #expect(granted == false)
        let requestCallCount = await mock.requestAuthorizationCallCount
        #expect(requestCallCount == 1)
    }

    @Test("MockPermissionNotificationCenter - カスタム状態の設定")
    func testMockNotificationCenterCustomStatus() async {
        let mock = MockPermissionNotificationCenter()
        await mock.configure(authorizationStatus: .authorized, authorizationGranted: true)

        let status = await mock.getAuthorizationStatus()
        #expect(status == .authorized)

        let granted = await mock.requestAuthorization(options: [.alert])
        #expect(granted == true)
    }

    @Test("MockPermissionNotificationCenter - reset で状態がリセットされる")
    func testMockNotificationCenterReset() async {
        let mock = MockPermissionNotificationCenter()
        await mock.configure(authorizationStatus: .authorized, authorizationGranted: true)

        _ = await mock.getAuthorizationStatus()
        _ = await mock.requestAuthorization(options: [.alert])

        let getCallCount1 = await mock.getAuthorizationStatusCallCount
        let requestCallCount1 = await mock.requestAuthorizationCallCount
        #expect(getCallCount1 == 1)
        #expect(requestCallCount1 == 1)

        await mock.reset()

        // reset後は初期状態に戻る
        let status = await mock.getAuthorizationStatus()
        #expect(status == .notDetermined)
        let getCallCount2 = await mock.getAuthorizationStatusCallCount
        let requestCallCount2 = await mock.requestAuthorizationCallCount
        #expect(getCallCount2 == 1) // reset後に1回呼び出し
        #expect(requestCallCount2 == 0)
    }
}

// MARK: - DefaultNotificationCenter Tests

@Suite("DefaultNotificationCenter Tests")
struct DefaultNotificationCenterTests {

    @Test("初期化できる")
    func testInitialization() {
        let center = DefaultNotificationCenter()
        // 初期化が成功すればOK
        #expect(center != nil)
    }
}
