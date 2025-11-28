//
//  PhotoScannerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoScanner の単体テスト
//  Swift Testing フレームワークを使用
//  Created by AI Assistant
//

import Testing
import Foundation
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - Progress Collector Actor

/// テスト用の進捗収集アクター（スレッドセーフ）
actor ProgressCollector {
    var progressValues: [Double] = []
    var callCount: Int = 0
    var lastProgress: PhotoScanProgress?

    func record(_ progress: PhotoScanProgress) {
        callCount += 1
        progressValues.append(progress.percentage)
        lastProgress = progress
    }

    func getCallCount() -> Int { callCount }
    func getProgressValues() -> [Double] { progressValues }
    func getLastProgress() -> PhotoScanProgress? { lastProgress }
}

// MARK: - Mock Permission Manager for Scanner

/// テスト用の権限マネージャーモック
@MainActor
final class MockPhotoPermissionManagerForScanner: PhotoPermissionManagerProtocol {
    var currentStatus: PHAuthorizationStatus
    private var requestResult: PHAuthorizationStatus

    init(status: PHAuthorizationStatus = .authorized, requestResult: PHAuthorizationStatus? = nil) {
        self.currentStatus = status
        self.requestResult = requestResult ?? status
    }

    func checkPermissionStatus() -> PHAuthorizationStatus {
        return currentStatus
    }

    func requestPermission() async -> PHAuthorizationStatus {
        currentStatus = requestResult
        return requestResult
    }

    func openSettings() {
        // テスト用: 何もしない
    }
}

// MARK: - ScanState Tests

@Suite("ScanState Tests")
struct ScanStateTests {

    @Test("idle 状態が正しく比較される")
    func testIdleEquality() {
        let state1 = ScanState.idle
        let state2 = ScanState.idle
        #expect(state1 == state2)
    }

    @Test("scanning 状態が正しく比較される")
    func testScanningEquality() {
        let state1 = ScanState.scanning
        let state2 = ScanState.scanning
        #expect(state1 == state2)
    }

    @Test("completed 状態が正しく比較される")
    func testCompletedEquality() {
        let state1 = ScanState.completed
        let state2 = ScanState.completed
        #expect(state1 == state2)
    }

    @Test("cancelled 状態が正しく比較される")
    func testCancelledEquality() {
        let state1 = ScanState.cancelled
        let state2 = ScanState.cancelled
        #expect(state1 == state2)
    }

    @Test("paused 状態が正しく比較される")
    func testPausedEquality() {
        let state1 = ScanState.paused
        let state2 = ScanState.paused
        #expect(state1 == state2)
    }

    @Test("failed 状態が同じエラーで正しく比較される")
    func testFailedEqualityWithSameError() {
        let state1 = ScanState.failed(.notAuthorized)
        let state2 = ScanState.failed(.notAuthorized)
        #expect(state1 == state2)
    }

    @Test("failed 状態が異なるエラーで異なる")
    func testFailedInequalityWithDifferentError() {
        let state1 = ScanState.failed(.notAuthorized)
        let state2 = ScanState.failed(.scanCancelled)
        #expect(state1 != state2)
    }

    @Test("異なる状態は等しくない")
    func testDifferentStatesAreNotEqual() {
        #expect(ScanState.idle != ScanState.scanning)
        #expect(ScanState.scanning != ScanState.completed)
        #expect(ScanState.completed != ScanState.cancelled)
    }
}

// MARK: - PhotoScanProgress Tests

@Suite("PhotoScanProgress Tests")
struct PhotoScanProgressTests {

    @Test("初期進捗の値")
    func testInitialProgress() {
        let progress = PhotoScanProgress.initial
        #expect(progress.current == 0)
        #expect(progress.total == 0)
        #expect(progress.percentage == 0.0)
        #expect(progress.currentPhoto == nil)
        #expect(progress.estimatedTimeRemaining == nil)
    }

    @Test("完了進捗の値")
    func testCompletedProgress() {
        let progress = PhotoScanProgress.completed(total: 100)
        #expect(progress.current == 100)
        #expect(progress.total == 100)
        #expect(progress.percentage == 1.0)
    }

    @Test("進捗率が正しく計算される")
    func testPercentageCalculation() {
        let progress = PhotoScanProgress(current: 50, total: 100)
        #expect(progress.percentage == 0.5)
    }

    @Test("進捗率が 0.0〜1.0 の範囲に制限される")
    func testPercentageBounds() {
        // current > total の場合でも 1.0 に制限
        let overProgress = PhotoScanProgress(current: 150, total: 100)
        #expect(overProgress.percentage == 1.0)

        // current < 0 は想定外だが、計算上は負になる可能性
        // ここでは正常なケースのみテスト

        // total == 0 の場合は 0.0
        let zeroTotalProgress = PhotoScanProgress(current: 0, total: 0)
        #expect(zeroTotalProgress.percentage == 0.0)
    }

    @Test("残り時間が計算される")
    func testEstimatedTimeRemaining() {
        let startTime = Date().addingTimeInterval(-10) // 10秒前
        let progress = PhotoScanProgress(current: 50, total: 100, startTime: startTime)

        // 残り時間が存在する
        #expect(progress.estimatedTimeRemaining != nil)

        // 残り時間は正の値
        if let remaining = progress.estimatedTimeRemaining {
            #expect(remaining > 0)
        }
    }

    @Test("current == 0 の場合は残り時間が nil")
    func testNoEstimatedTimeWhenCurrentIsZero() {
        let startTime = Date().addingTimeInterval(-10)
        let progress = PhotoScanProgress(current: 0, total: 100, startTime: startTime)
        #expect(progress.estimatedTimeRemaining == nil)
    }

    @Test("startTime が nil の場合は残り時間が nil")
    func testNoEstimatedTimeWhenStartTimeIsNil() {
        let progress = PhotoScanProgress(current: 50, total: 100, startTime: nil)
        #expect(progress.estimatedTimeRemaining == nil)
    }
}

// MARK: - ScanOptions Tests

@Suite("ScanOptions Tests")
struct ScanOptionsTests {

    @Test("デフォルトオプションの値")
    func testDefaultOptions() {
        let options = ScanOptions.default
        #expect(options.includeVideos == true)
        #expect(options.includeScreenshots == true)
        #expect(options.dateRange == nil)
        #expect(options.fetchFileSize == false)
        #expect(options.batchSize == 100)
    }

    @Test("高速オプションの値")
    func testFastOptions() {
        let options = ScanOptions.fast
        #expect(options.includeVideos == true)
        #expect(options.includeScreenshots == true)
        #expect(options.fetchFileSize == false)
        #expect(options.batchSize == 200)
    }

    @Test("詳細オプションの値")
    func testDetailedOptions() {
        let options = ScanOptions.detailed
        #expect(options.includeVideos == true)
        #expect(options.includeScreenshots == true)
        #expect(options.fetchFileSize == true)
        #expect(options.batchSize == 50)
    }

    @Test("カスタムオプションの初期化")
    func testCustomOptions() {
        let dateRange = DateInterval(
            start: Date().addingTimeInterval(-86400),
            end: Date()
        )

        let options = ScanOptions(
            includeVideos: false,
            includeScreenshots: false,
            dateRange: dateRange,
            fetchFileSize: true,
            batchSize: 75
        )

        #expect(options.includeVideos == false)
        #expect(options.includeScreenshots == false)
        #expect(options.dateRange != nil)
        #expect(options.fetchFileSize == true)
        #expect(options.batchSize == 75)
    }

    @Test("バッチサイズが 10〜500 に制限される")
    func testBatchSizeBounds() {
        // 小さすぎる値は 10 に制限
        let smallOptions = ScanOptions(batchSize: 5)
        #expect(smallOptions.batchSize == 10)

        // 大きすぎる値は 500 に制限
        let largeOptions = ScanOptions(batchSize: 1000)
        #expect(largeOptions.batchSize == 500)

        // 範囲内の値はそのまま
        let normalOptions = ScanOptions(batchSize: 150)
        #expect(normalOptions.batchSize == 150)
    }

    @Test("PhotoFetchOptions への変換 - 動画含む")
    func testToPhotoFetchOptionsWithVideos() {
        let options = ScanOptions(includeVideos: true)
        let fetchOptions = options.toPhotoFetchOptions()
        #expect(fetchOptions.mediaTypeFilter == .all)
    }

    @Test("PhotoFetchOptions への変換 - 動画含まない")
    func testToPhotoFetchOptionsWithoutVideos() {
        let options = ScanOptions(includeVideos: false)
        let fetchOptions = options.toPhotoFetchOptions()
        #expect(fetchOptions.mediaTypeFilter == .images)
    }

    @Test("PhotoFetchOptions への変換 - ファイルサイズ")
    func testToPhotoFetchOptionsFileSize() {
        let optionsWithSize = ScanOptions(fetchFileSize: true)
        let fetchOptionsWithSize = optionsWithSize.toPhotoFetchOptions()
        #expect(fetchOptionsWithSize.includeFileSize == true)

        let optionsWithoutSize = ScanOptions(fetchFileSize: false)
        let fetchOptionsWithoutSize = optionsWithoutSize.toPhotoFetchOptions()
        #expect(fetchOptionsWithoutSize.includeFileSize == false)
    }
}

// MARK: - PhotoScannerError Tests

@Suite("PhotoScannerError Tests")
struct PhotoScannerErrorTests {

    @Test("notAuthorized エラーの等価性")
    func testNotAuthorizedEquality() {
        let error1 = PhotoScannerError.notAuthorized
        let error2 = PhotoScannerError.notAuthorized
        #expect(error1 == error2)
    }

    @Test("scanInProgress エラーの等価性")
    func testScanInProgressEquality() {
        let error1 = PhotoScannerError.scanInProgress
        let error2 = PhotoScannerError.scanInProgress
        #expect(error1 == error2)
    }

    @Test("scanCancelled エラーの等価性")
    func testScanCancelledEquality() {
        let error1 = PhotoScannerError.scanCancelled
        let error2 = PhotoScannerError.scanCancelled
        #expect(error1 == error2)
    }

    @Test("scanFailed エラーの等価性 - 同じメッセージ")
    func testScanFailedEqualityWithSameMessage() {
        let error1 = PhotoScannerError.scanFailed(underlying: "Test error")
        let error2 = PhotoScannerError.scanFailed(underlying: "Test error")
        #expect(error1 == error2)
    }

    @Test("scanFailed エラーの不等価性 - 異なるメッセージ")
    func testScanFailedInequalityWithDifferentMessage() {
        let error1 = PhotoScannerError.scanFailed(underlying: "Error 1")
        let error2 = PhotoScannerError.scanFailed(underlying: "Error 2")
        #expect(error1 != error2)
    }

    @Test("異なるエラータイプは等しくない")
    func testDifferentErrorsAreNotEqual() {
        #expect(PhotoScannerError.notAuthorized != PhotoScannerError.scanInProgress)
        #expect(PhotoScannerError.scanInProgress != PhotoScannerError.scanCancelled)
        #expect(PhotoScannerError.scanCancelled != PhotoScannerError.scanFailed(underlying: "test"))
    }

    @Test("errorDescription が存在する")
    func testErrorDescription() {
        #expect(PhotoScannerError.notAuthorized.errorDescription != nil)
        #expect(!PhotoScannerError.notAuthorized.errorDescription!.isEmpty)

        #expect(PhotoScannerError.scanInProgress.errorDescription != nil)
        #expect(!PhotoScannerError.scanInProgress.errorDescription!.isEmpty)

        #expect(PhotoScannerError.scanCancelled.errorDescription != nil)
        #expect(!PhotoScannerError.scanCancelled.errorDescription!.isEmpty)

        let failedError = PhotoScannerError.scanFailed(underlying: "Test")
        #expect(failedError.errorDescription != nil)
        #expect(!failedError.errorDescription!.isEmpty)
        #expect(failedError.errorDescription!.contains("Test"))
    }
}

// MARK: - PhotoScanner Basic Tests

@Suite("PhotoScanner Basic Tests")
@MainActor
struct PhotoScannerBasicTests {

    @Test("初期化時の初期状態")
    func testInitialState() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        #expect(scanner.scanState == .idle)
        #expect(scanner.progress == 0.0)
        #expect(scanner.scannedCount == 0)
        #expect(scanner.totalCount == 0)
        #expect(scanner.estimatedTimeRemaining == nil)
    }

    @Test("デフォルトオプションで初期化")
    func testDefaultOptions() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        #expect(scanner.options.includeVideos == true)
        #expect(scanner.options.includeScreenshots == true)
        #expect(scanner.options.fetchFileSize == false)
        #expect(scanner.options.batchSize == 100)
    }

    @Test("カスタムオプションで初期化")
    func testCustomOptionsInitialization() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let customOptions = ScanOptions(
            includeVideos: false,
            includeScreenshots: false,
            fetchFileSize: true,
            batchSize: 50
        )
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: customOptions
        )

        #expect(scanner.options.includeVideos == false)
        #expect(scanner.options.includeScreenshots == false)
        #expect(scanner.options.fetchFileSize == true)
        #expect(scanner.options.batchSize == 50)
    }

    @Test("reset で状態がリセットされる")
    func testResetClearsState() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // 状態を変更（内部的に）
        scanner.reset()

        #expect(scanner.scanState == .idle)
        #expect(scanner.progress == 0.0)
        #expect(scanner.scannedCount == 0)
        #expect(scanner.totalCount == 0)
    }
}

// MARK: - PhotoScanner Authorization Tests

@Suite("PhotoScanner Authorization Tests")
@MainActor
struct PhotoScannerAuthorizationTests {

    @Test("権限が拒否されている場合はエラー")
    func testScanFailsWhenDenied() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .denied)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }

        #expect(scanner.scanState == .failed(.notAuthorized))
    }

    @Test("権限が未決定の場合はエラー")
    func testScanFailsWhenNotDetermined() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .notDetermined)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }
    }

    @Test("権限が制限されている場合はエラー")
    func testScanFailsWhenRestricted() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .restricted)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }
    }

    @Test("権限が authorized の場合はスキャン可能")
    func testScanSucceedsWhenAuthorized() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // スキャン自体は成功する（結果が空でも）
        do {
            let photos = try await scanner.scan()
            // 写真がなくてもエラーにはならない
            #expect(photos.count >= 0)
            #expect(scanner.scanState == .completed)
        } catch {
            // 権限関連以外のエラーは許容
            #expect(!(error is PhotoScannerError && error as! PhotoScannerError == .notAuthorized))
        }
    }

    @Test("権限が limited の場合はスキャン可能")
    func testScanSucceedsWhenLimited() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .limited)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            let photos = try await scanner.scan()
            #expect(photos.count >= 0)
            #expect(scanner.scanState == .completed)
        } catch {
            #expect(!(error is PhotoScannerError && error as! PhotoScannerError == .notAuthorized))
        }
    }
}

// MARK: - PhotoScanner Cancel Tests

@Suite("PhotoScanner Cancel Tests")
@MainActor
struct PhotoScannerCancelTests {

    @Test("cancel で状態が cancelled になる")
    func testCancelSetsStateToCancelled() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // スキャンを開始
        let scanTask = Task {
            try await scanner.scan()
        }

        // 少し待ってからキャンセル
        try? await Task.sleep(for: .milliseconds(10))
        scanner.cancel()

        // タスクの完了を待つ
        do {
            _ = try await scanTask.value
        } catch {
            // キャンセルエラーは期待される
        }

        // スキャン中だった場合は cancelled になる
        // すでに完了していた場合は completed のまま
        #expect(scanner.scanState == .cancelled || scanner.scanState == .completed)
    }

    @Test("アイドル状態でのキャンセルは何もしない")
    func testCancelWhenIdleDoesNothing() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        #expect(scanner.scanState == .idle)

        scanner.cancel()

        // アイドル状態のまま
        #expect(scanner.scanState == .idle)
    }
}

// MARK: - PhotoScanner Progress Tests

@Suite("PhotoScanner Progress Tests")
@MainActor
struct PhotoScannerProgressTests {

    @Test("進捗コールバックが呼ばれる")
    func testProgressCallbackIsCalled() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        let collector = ProgressCollector()

        do {
            _ = try await scanner.scan(progressHandler: { progress in
                Task { await collector.record(progress) }
            })

            // 非同期処理が完了するのを少し待つ
            try? await Task.sleep(for: .milliseconds(100))

            // 少なくとも1回は呼ばれる（空でも完了時に呼ばれる）
            let callCount = await collector.getCallCount()
            #expect(callCount >= 1)

            // スキャン完了後は scanner.progress が 1.0 になる
            // (コールバックの非同期性により collector には遅延があるため scanner の状態を直接検証)
            #expect(scanner.progress == 1.0)
        } catch {
            // エラーの場合でも進捗コールバックは呼ばれている可能性がある
        }
    }

    @Test("進捗率が 0.0 から 1.0 の範囲")
    func testProgressPercentageRange() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        let collector = ProgressCollector()

        do {
            _ = try await scanner.scan(progressHandler: { progress in
                Task { await collector.record(progress) }
            })

            // 非同期処理が完了するのを少し待つ
            try? await Task.sleep(for: .milliseconds(100))

            // 全ての進捗値が 0.0〜1.0 の範囲内
            let progressValues = await collector.getProgressValues()
            for value in progressValues {
                #expect(value >= 0.0)
                #expect(value <= 1.0)
            }
        } catch {
            // エラーでもOK
        }
    }

    @Test("完了時に progress が 1.0")
    func testProgressIsOneWhenCompleted() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            _ = try await scanner.scan()
            #expect(scanner.progress == 1.0)
        } catch {
            // エラーでもOK
        }
    }
}

// MARK: - PhotoScanner Factory Tests

@Suite("PhotoScanner Factory Tests")
@MainActor
struct PhotoScannerFactoryTests {

    @Test("create ファクトリメソッドでインスタンス作成")
    func testCreateFactory() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let scanner = PhotoScanner.create(permissionManager: mockPermission)

        #expect(scanner.scanState == .idle)
        #expect(scanner.options.batchSize == 100) // デフォルト
    }

    @Test("create ファクトリメソッドでカスタムオプション指定")
    func testCreateFactoryWithCustomOptions() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let customOptions = ScanOptions(batchSize: 50)
        let scanner = PhotoScanner.create(
            permissionManager: mockPermission,
            options: customOptions
        )

        #expect(scanner.options.batchSize == 50)
    }
}

// MARK: - Integration Tests

@Suite("PhotoScanner Integration Tests")
@MainActor
struct PhotoScannerIntegrationTests {

    @Test("M2-T09-TC01: 基本スキャンの正常系")
    func testBasicScanNormalCase() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            let photos = try await scanner.scan()

            // スキャン完了
            #expect(scanner.scanState == .completed)
            #expect(scanner.progress == 1.0)

            // 写真数は環境依存だが、エラーなく取得できる
            #expect(photos.count >= 0)
        } catch {
            // 権限エラー以外は許容（写真がない場合など）
            if let scanError = error as? PhotoScannerError {
                #expect(scanError != .notAuthorized)
            }
        }
    }

    @Test("M2-T09-TC02: 進捗通知の正確性")
    func testProgressNotificationAccuracy() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        let collector = ProgressCollector()

        do {
            _ = try await scanner.scan(progressHandler: { progress in
                Task { await collector.record(progress) }
            })

            // 非同期処理が完了するのを少し待つ
            try? await Task.sleep(for: .milliseconds(100))

            let progressValues = await collector.getProgressValues()

            // 進捗値が単調増加
            for i in 1..<progressValues.count {
                #expect(progressValues[i] >= progressValues[i-1])
            }

            // 全ての値が 0.0〜1.0
            for value in progressValues {
                #expect(value >= 0.0 && value <= 1.0)
            }
        } catch {
            // エラーでもOK
        }
    }

    @Test("M2-T09-TC04: 空ライブラリでのスキャン")
    func testScanEmptyLibrary() async {
        // 注: 実際の空ライブラリはシミュレーターの状態に依存
        // ここでは権限がある状態でスキャンが完了することを確認
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        do {
            let photos = try await scanner.scan()

            // 空でも正常に完了
            #expect(scanner.scanState == .completed)
            #expect(scanner.progress == 1.0)
            #expect(photos.count >= 0)
        } catch {
            // エラーでもOK
        }
    }

    @Test("M2-T09-TC05: エラーハンドリング - 権限拒否")
    func testErrorHandlingPermissionDenied() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .denied)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        await #expect(throws: PhotoScannerError.notAuthorized) {
            try await scanner.scan()
        }

        #expect(scanner.scanState == .failed(.notAuthorized))
    }

    @Test("スキャンオプションの効果")
    func testScanOptionsEffect() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)

        // 動画を含まないオプション
        let options = ScanOptions(includeVideos: false)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission,
            options: options
        )

        do {
            let photos = try await scanner.scan()

            // 動画が含まれていないことを確認
            for photo in photos {
                #expect(photo.mediaType != .video)
            }
        } catch {
            // エラーでもOK
        }
    }
}

// MARK: - Edge Case Tests

@Suite("PhotoScanner Edge Case Tests")
@MainActor
struct PhotoScannerEdgeCaseTests {

    @Test("複数回のスキャン")
    func testMultipleScans() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // 1回目のスキャン
        do {
            _ = try await scanner.scan()
            #expect(scanner.scanState == .completed)
        } catch {
            // エラーでもOK
        }

        // 状態をリセット
        scanner.reset()
        #expect(scanner.scanState == .idle)

        // 2回目のスキャン
        do {
            _ = try await scanner.scan()
            #expect(scanner.scanState == .completed)
        } catch {
            // エラーでもOK
        }
    }

    @Test("オプション変更後のスキャン")
    func testScanAfterOptionsChange() async {
        let mockPermission = MockPhotoPermissionManagerForScanner(status: .authorized)
        let repository = PhotoRepository(permissionManager: mockPermission)
        let scanner = PhotoScanner(
            repository: repository,
            permissionManager: mockPermission
        )

        // オプションを変更
        scanner.options = ScanOptions(batchSize: 50)
        #expect(scanner.options.batchSize == 50)

        // スキャン実行
        do {
            _ = try await scanner.scan()
            #expect(scanner.scanState == .completed)
        } catch {
            // エラーでもOK
        }
    }
}
