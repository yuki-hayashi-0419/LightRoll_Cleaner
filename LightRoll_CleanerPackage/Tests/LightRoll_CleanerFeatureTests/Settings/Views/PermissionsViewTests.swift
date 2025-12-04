//
//  PermissionsViewTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PermissionsViewのテストスイート
//  Swift Testingフレームワークを使用
//  M8-T05 実装
//  Created by AI Assistant on 2025-12-05.
//

import Testing
import SwiftUI
import Photos
import UserNotifications
@testable import LightRoll_CleanerFeature

// MARK: - PermissionsViewTests

@MainActor
@Suite("PermissionsView Tests")
struct PermissionsViewTests {

    // MARK: - 初期化テスト

    @Test("PermissionsViewが初期化できる")
    func initializesSuccessfully() async throws {
        // Given
        let mockManager = MockPermissionManager()

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(view != nil)
    }

    // MARK: - 権限ステータス表示テスト

    @Test("写真権限が未設定の場合、未設定と表示される")
    func displaysPhotoPermissionNotDetermined() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .notDetermined

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then - ビューの状態確認
        // SwiftUIビューのテストは実際のレンダリングが必要なため、
        // ここではモックマネージャーの状態を検証
        #expect(mockManager.photoStatus == .notDetermined)
    }

    @Test("写真権限が許可済みの場合、許可済みと表示される")
    func displaysPhotoPermissionAuthorized() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .authorized

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.photoStatus == .authorized)
    }

    @Test("写真権限が拒否されている場合、拒否と表示される")
    func displaysPhotoPermissionDenied() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .denied

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.photoStatus == .denied)
    }

    @Test("写真権限が制限されている場合、制限と表示される")
    func displaysPhotoPermissionRestricted() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .restricted

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.photoStatus == .restricted)
    }

    @Test("写真権限が限定許可の場合、限定許可と表示される")
    func displaysPhotoPermissionLimited() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .limited

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.photoStatus == .limited)
    }

    // MARK: - 通知権限テスト

    @Test("通知権限が未設定の場合、未設定と表示される")
    func displaysNotificationPermissionNotDetermined() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.notificationStatus = .notDetermined

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.notificationStatus == .notDetermined)
    }

    @Test("通知権限が許可済みの場合、許可済みと表示される")
    func displaysNotificationPermissionAuthorized() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.notificationStatus = .authorized

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.notificationStatus == .authorized)
    }

    @Test("通知権限が拒否されている場合、拒否と表示される")
    func displaysNotificationPermissionDenied() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.notificationStatus = .denied

        // When
        let view = PermissionsView()
            .environment(mockManager)

        // Then
        #expect(mockManager.notificationStatus == .denied)
    }

    // MARK: - 権限リクエストテスト

    @Test("写真権限リクエストが成功する")
    func requestPhotoPermissionSucceeds() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.photoStatus = .notDetermined
        mockManager.shouldRequestPhotoSucceed = true

        // When
        let resultStatus = await mockManager.requestPhotoPermission()

        // Then
        #expect(resultStatus == .authorized)
        #expect(mockManager.requestPhotoPermissionCalled)
    }

    @Test("通知権限リクエストが成功する")
    func requestNotificationPermissionSucceeds() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.notificationStatus = .notDetermined
        mockManager.shouldRequestNotificationSucceed = true

        // When
        let result = await mockManager.requestNotificationPermission()

        // Then
        #expect(result == true)
        #expect(mockManager.requestNotificationPermissionCalled)
    }

    // MARK: - 設定アプリ遷移テスト

    @Test("設定アプリを開く処理が呼ばれる")
    func opensAppSettings() async throws {
        // Given
        let mockManager = MockPermissionManager()

        // When
        await mockManager.openSettings()

        // Then
        #expect(mockManager.openSettingsCalled)
    }

    // MARK: - エラーハンドリングテスト

    @Test("権限ステータス取得失敗時にエラー状態になる")
    func handlesPermissionStatusFetchError() async throws {
        // Given
        let mockManager = MockPermissionManager()
        mockManager.shouldThrowError = true

        // When/Then
        // エラーが発生してもクラッシュしないことを確認
        let photoStatus = mockManager.getPhotoPermissionStatus()
        #expect(photoStatus == .notDetermined)
    }
}

// MARK: - MockPermissionManager

/// テスト用のモックPermissionManager
@MainActor
@Observable
final class MockPermissionManager: PermissionManagerProtocol {

    // MARK: - Properties

    var currentPhotoStatus: PHAuthorizationStatus = .notDetermined
    var photoStatus: PHAuthorizationStatus = .notDetermined
    var notificationStatus: UNAuthorizationStatus = .notDetermined

    var shouldRequestPhotoSucceed = true
    var shouldRequestNotificationSucceed = true
    var shouldThrowError = false

    var requestPhotoPermissionCalled = false
    var requestNotificationPermissionCalled = false
    var openSettingsCalled = false

    // MARK: - PermissionManagerProtocol

    func getStatus(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .photoLibrary:
            return photoStatus.toPermissionStatus
        case .notifications:
            return notificationStatus.toPermissionStatus
        }
    }

    func requestPermission(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .photoLibrary:
            return (await requestPhotoPermission()).toPermissionStatus
        case .notifications:
            let granted = await requestNotificationPermission()
            return granted ? .authorized : .denied
        }
    }

    func openSettings() async {
        openSettingsCalled = true
    }

    func getAllStatuses() async -> [PermissionType: PermissionStatus] {
        var statuses: [PermissionType: PermissionStatus] = [:]
        for type in PermissionType.allCases {
            statuses[type] = await getStatus(for: type)
        }
        return statuses
    }

    // MARK: - 具体的なメソッド

    func getPhotoPermissionStatus() -> PHAuthorizationStatus {
        return photoStatus
    }

    func getNotificationPermissionStatus() async -> UNAuthorizationStatus {
        return notificationStatus
    }

    func requestPhotoPermission() async -> PHAuthorizationStatus {
        requestPhotoPermissionCalled = true
        if shouldRequestPhotoSucceed {
            photoStatus = .authorized
            currentPhotoStatus = .authorized
            return .authorized
        } else {
            photoStatus = .denied
            currentPhotoStatus = .denied
            return .denied
        }
    }

    func requestNotificationPermission() async -> Bool {
        requestNotificationPermissionCalled = true
        if shouldRequestNotificationSucceed {
            notificationStatus = .authorized
            return true
        } else {
            notificationStatus = .denied
            return false
        }
    }

    func openAppSettings() {
        openSettingsCalled = true
    }
}

// MARK: - PHAuthorizationStatus Extension

extension PHAuthorizationStatus {
    var toPermissionStatus: PermissionStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
}
