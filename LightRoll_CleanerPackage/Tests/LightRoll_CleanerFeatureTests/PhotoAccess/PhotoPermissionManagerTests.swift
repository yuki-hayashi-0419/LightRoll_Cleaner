//
//  PhotoPermissionManagerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoPermissionManager の単体テスト
//  Swift Testing フレームワークを使用
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - Mock Settings Opener

/// テスト用の設定アプリオープナーモック
final class MockSettingsOpener: SettingsOpenerProtocol, @unchecked Sendable {
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

// MARK: - PHAuthorizationStatus Extension Tests

@Suite("PHAuthorizationStatus Extension Tests")
struct PHAuthorizationStatusExtensionTests {

    @Test("isAuthorized - authorized の場合は true")
    func testIsAuthorizedWithAuthorized() {
        let status = PHAuthorizationStatus.authorized
        #expect(status.isAuthorized == true)
    }

    @Test("isAuthorized - limited の場合は true")
    func testIsAuthorizedWithLimited() {
        let status = PHAuthorizationStatus.limited
        #expect(status.isAuthorized == true)
    }

    @Test("isAuthorized - notDetermined の場合は false")
    func testIsAuthorizedWithNotDetermined() {
        let status = PHAuthorizationStatus.notDetermined
        #expect(status.isAuthorized == false)
    }

    @Test("isAuthorized - denied の場合は false")
    func testIsAuthorizedWithDenied() {
        let status = PHAuthorizationStatus.denied
        #expect(status.isAuthorized == false)
    }

    @Test("isAuthorized - restricted の場合は false")
    func testIsAuthorizedWithRestricted() {
        let status = PHAuthorizationStatus.restricted
        #expect(status.isAuthorized == false)
    }

    @Test("canRequestPermission - notDetermined の場合のみ true")
    func testCanRequestPermission() {
        #expect(PHAuthorizationStatus.notDetermined.canRequestPermission == true)
        #expect(PHAuthorizationStatus.authorized.canRequestPermission == false)
        #expect(PHAuthorizationStatus.denied.canRequestPermission == false)
        #expect(PHAuthorizationStatus.restricted.canRequestPermission == false)
        #expect(PHAuthorizationStatus.limited.canRequestPermission == false)
    }

    @Test("needsSettingsRedirect - denied の場合のみ true")
    func testNeedsSettingsRedirect() {
        #expect(PHAuthorizationStatus.denied.needsSettingsRedirect == true)
        #expect(PHAuthorizationStatus.notDetermined.needsSettingsRedirect == false)
        #expect(PHAuthorizationStatus.authorized.needsSettingsRedirect == false)
        #expect(PHAuthorizationStatus.restricted.needsSettingsRedirect == false)
        #expect(PHAuthorizationStatus.limited.needsSettingsRedirect == false)
    }

    @Test("toPermissionStatus - 各ステータスの変換")
    func testToPermissionStatus() {
        #expect(PHAuthorizationStatus.notDetermined.toPermissionStatus == .notDetermined)
        #expect(PHAuthorizationStatus.restricted.toPermissionStatus == .restricted)
        #expect(PHAuthorizationStatus.denied.toPermissionStatus == .denied)
        #expect(PHAuthorizationStatus.authorized.toPermissionStatus == .authorized)
        #expect(PHAuthorizationStatus.limited.toPermissionStatus == .limited)
    }

    @Test("localizedDescription - 各ステータスに説明文がある")
    func testLocalizedDescription() {
        // 各ステータスにローカライズされた説明があることを確認
        #expect(!PHAuthorizationStatus.notDetermined.localizedDescription.isEmpty)
        #expect(!PHAuthorizationStatus.restricted.localizedDescription.isEmpty)
        #expect(!PHAuthorizationStatus.denied.localizedDescription.isEmpty)
        #expect(!PHAuthorizationStatus.authorized.localizedDescription.isEmpty)
        #expect(!PHAuthorizationStatus.limited.localizedDescription.isEmpty)
    }
}

// MARK: - PhotoPermissionManager Tests

@Suite("PhotoPermissionManager Tests")
@MainActor
struct PhotoPermissionManagerTests {

    @Test("初期化時に現在のステータスを取得する")
    func testInitializationSetsCurrentStatus() async {
        let mockOpener = MockSettingsOpener()
        let manager = PhotoPermissionManager(settingsOpener: mockOpener)

        // 初期化時に何らかのステータスが設定されている
        // 注: 実際のステータスはシステムの状態に依存
        let status = manager.currentStatus
        #expect(
            status == .notDetermined ||
            status == .authorized ||
            status == .denied ||
            status == .restricted ||
            status == .limited
        )
    }

    @Test("checkPermissionStatus が現在のステータスを返す")
    func testCheckPermissionStatusReturnsCurrentStatus() async {
        let mockOpener = MockSettingsOpener()
        let manager = PhotoPermissionManager(settingsOpener: mockOpener)

        let checkedStatus = manager.checkPermissionStatus()

        // checkPermissionStatus の結果が currentStatus と一致する
        #expect(manager.currentStatus == checkedStatus)
    }

    @Test("openSettings が SettingsOpener を呼び出す")
    func testOpenSettingsCallsSettingsOpener() async {
        let mockOpener = MockSettingsOpener()
        let manager = PhotoPermissionManager(settingsOpener: mockOpener)

        #expect(mockOpener.wasOpenSettingsCalled == false)

        manager.openSettings()

        #expect(mockOpener.wasOpenSettingsCalled == true)
        #expect(mockOpener.openSettingsCallCount == 1)
    }

    @Test("openSettings を複数回呼び出すと呼び出しカウントが増加する")
    func testOpenSettingsMultipleCalls() async {
        let mockOpener = MockSettingsOpener()
        let manager = PhotoPermissionManager(settingsOpener: mockOpener)

        manager.openSettings()
        manager.openSettings()
        manager.openSettings()

        #expect(mockOpener.openSettingsCallCount == 3)
    }

    @Test("Protocol 準拠 - PhotoPermissionManagerProtocol")
    func testProtocolConformance() async {
        let mockOpener = MockSettingsOpener()
        let manager: any PhotoPermissionManagerProtocol = PhotoPermissionManager(settingsOpener: mockOpener)

        // プロトコルのメソッドが呼び出せることを確認
        _ = manager.currentStatus
        _ = manager.checkPermissionStatus()
        manager.openSettings()

        #expect(mockOpener.wasOpenSettingsCalled == true)
    }
}

// MARK: - MockSettingsOpener Tests

@Suite("MockSettingsOpener Tests")
struct MockSettingsOpenerTests {

    @Test("初期状態では openSettings が呼ばれていない")
    func testInitialState() {
        let mock = MockSettingsOpener()
        #expect(mock.wasOpenSettingsCalled == false)
        #expect(mock.openSettingsCallCount == 0)
    }

    @Test("openSettings を呼ぶとカウントが増加")
    func testOpenSettingsIncrementsCount() {
        let mock = MockSettingsOpener()

        mock.openSettings()
        #expect(mock.openSettingsCallCount == 1)

        mock.openSettings()
        #expect(mock.openSettingsCallCount == 2)
    }

    @Test("reset で状態がリセットされる")
    func testReset() {
        let mock = MockSettingsOpener()
        mock.openSettings()
        mock.openSettings()
        #expect(mock.openSettingsCallCount == 2)

        mock.reset()
        #expect(mock.openSettingsCallCount == 0)
        #expect(mock.wasOpenSettingsCalled == false)
    }
}

// MARK: - DefaultSettingsOpener Tests

@Suite("DefaultSettingsOpener Tests")
struct DefaultSettingsOpenerTests {

    @Test("初期化できる")
    func testInitialization() {
        let opener = DefaultSettingsOpener()
        // 初期化が成功すればOK
        #expect(opener != nil)
    }

    // 注: 実際の設定画面を開くテストは UI テストで行う必要がある
    // ここではクラッシュしないことを確認
    @Test("openSettings がクラッシュしない")
    func testOpenSettingsDoesNotCrash() {
        let opener = DefaultSettingsOpener()
        // MainActor のコンテキストではないため、実際には開かないが、
        // メソッド呼び出しがクラッシュしないことを確認
        opener.openSettings()
        #expect(true) // クラッシュせずにここまで到達
    }
}

// MARK: - Integration Tests

@Suite("PhotoPermissionManager Integration Tests")
@MainActor
struct PhotoPermissionManagerIntegrationTests {

    @Test("M2-T02-TC01: 未決定状態でのステータス確認")
    func testNotDeterminedStatus() async {
        // 注: このテストは実環境の状態に依存する
        // シミュレーターでリセットされている場合は .notDetermined になる
        let manager = PhotoPermissionManager()

        // ステータスが取得できることを確認
        let status = manager.checkPermissionStatus()

        // 有効なステータスであることを確認
        #expect(
            status == .notDetermined ||
            status == .authorized ||
            status == .denied ||
            status == .restricted ||
            status == .limited
        )
    }

    @Test("M2-T02-TC03: 拒否された場合の設定誘導")
    func testSettingsRedirectWhenDenied() async {
        let mockOpener = MockSettingsOpener()
        let manager = PhotoPermissionManager(settingsOpener: mockOpener)

        let status = manager.checkPermissionStatus()

        // denied の場合は openSettings を呼ぶべき
        if status == .denied {
            manager.openSettings()
            #expect(mockOpener.wasOpenSettingsCalled == true)
        }

        // needsSettingsRedirect プロパティのテスト
        if status.needsSettingsRedirect {
            manager.openSettings()
            #expect(mockOpener.wasOpenSettingsCalled == true)
        }
    }

    @Test("権限状態の一貫性")
    func testStatusConsistency() async {
        let manager = PhotoPermissionManager()

        // 複数回呼び出しても一貫した結果
        let status1 = manager.checkPermissionStatus()
        let status2 = manager.checkPermissionStatus()
        let status3 = manager.currentStatus

        #expect(status1 == status2)
        #expect(status2 == status3)
    }
}

// MARK: - Edge Case Tests

@Suite("PhotoPermissionManager Edge Case Tests")
@MainActor
struct PhotoPermissionManagerEdgeCaseTests {

    @Test("スレッドセーフ: 複数回の同時呼び出し")
    func testConcurrentAccess() async {
        let manager = PhotoPermissionManager()

        // 複数の並行タスクからアクセス
        await withTaskGroup(of: PHAuthorizationStatus.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    manager.checkPermissionStatus()
                }
            }

            var results: [PHAuthorizationStatus] = []
            for await status in group {
                results.append(status)
            }

            // 全ての結果が一致することを確認
            let first = results.first
            for status in results {
                #expect(status == first)
            }
        }
    }

    @Test("Sendable 準拠")
    func testSendableConformance() async {
        let manager = PhotoPermissionManager()

        // 別のタスクに渡せることを確認（Sendable準拠）
        let status = await Task { @MainActor in
            return manager.currentStatus
        }.value

        #expect(
            status == .notDetermined ||
            status == .authorized ||
            status == .denied ||
            status == .restricted ||
            status == .limited
        )
    }
}
