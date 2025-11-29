//
//  ScanPhotosUseCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ScanPhotosUseCaseの包括的な単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing

@testable import LightRoll_CleanerFeature

// MARK: - ScanPhotosUseCaseError Tests

@Suite("ScanPhotosUseCaseError テスト")
struct ScanPhotosUseCaseErrorTests {

    @Test("photoAccessDeniedエラーの説明文が正しい")
    func testPhotoAccessDeniedErrorDescription() {
        let error = ScanPhotosUseCaseError.photoAccessDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("許可"))
    }

    @Test("scanAlreadyInProgressエラーの説明文が正しい")
    func testScanAlreadyInProgressErrorDescription() {
        let error = ScanPhotosUseCaseError.scanAlreadyInProgress
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("実行中"))
    }

    @Test("scanCancelledエラーの説明文が正しい")
    func testScanCancelledErrorDescription() {
        let error = ScanPhotosUseCaseError.scanCancelled
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("キャンセル"))
    }

    @Test("scanFailedエラーが理由を含む")
    func testScanFailedErrorWithReason() {
        let reason = "ネットワークエラー"
        let error = ScanPhotosUseCaseError.scanFailed(reason: reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("analysisFailedエラーが理由を含む")
    func testAnalysisFailedErrorWithReason() {
        let reason = "メモリ不足"
        let error = ScanPhotosUseCaseError.analysisFailed(reason: reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("photoAccessDeniedのリカバリー提案がある")
    func testPhotoAccessDeniedRecoverySuggestion() {
        let error = ScanPhotosUseCaseError.photoAccessDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("設定"))
    }

    @Test("scanAlreadyInProgressのリカバリー提案がある")
    func testScanAlreadyInProgressRecoverySuggestion() {
        let error = ScanPhotosUseCaseError.scanAlreadyInProgress
        #expect(error.recoverySuggestion != nil)
    }

    @Test("scanCancelledにはリカバリー提案がない")
    func testScanCancelledNoRecoverySuggestion() {
        let error = ScanPhotosUseCaseError.scanCancelled
        #expect(error.recoverySuggestion == nil)
    }

    @Test("scanFailedのリカバリー提案がある")
    func testScanFailedRecoverySuggestion() {
        let error = ScanPhotosUseCaseError.scanFailed(reason: "エラー")
        #expect(error.recoverySuggestion != nil)
    }

    @Test("analysisFailedのリカバリー提案がある")
    func testAnalysisFailedRecoverySuggestion() {
        let error = ScanPhotosUseCaseError.analysisFailed(reason: "エラー")
        #expect(error.recoverySuggestion != nil)
    }
}

// MARK: - ScanPhotosUseCaseError Equatable Tests

@Suite("ScanPhotosUseCaseError Equatable テスト")
struct ScanPhotosUseCaseErrorEquatableTests {

    @Test("同じphotoAccessDeniedエラーは等しい")
    func testPhotoAccessDeniedEquatable() {
        let error1 = ScanPhotosUseCaseError.photoAccessDenied
        let error2 = ScanPhotosUseCaseError.photoAccessDenied
        #expect(error1 == error2)
    }

    @Test("同じscanAlreadyInProgressエラーは等しい")
    func testScanAlreadyInProgressEquatable() {
        let error1 = ScanPhotosUseCaseError.scanAlreadyInProgress
        let error2 = ScanPhotosUseCaseError.scanAlreadyInProgress
        #expect(error1 == error2)
    }

    @Test("同じscanCancelledエラーは等しい")
    func testScanCancelledEquatable() {
        let error1 = ScanPhotosUseCaseError.scanCancelled
        let error2 = ScanPhotosUseCaseError.scanCancelled
        #expect(error1 == error2)
    }

    @Test("同じ理由のscanFailedエラーは等しい")
    func testScanFailedEquatable() {
        let error1 = ScanPhotosUseCaseError.scanFailed(reason: "同じ理由")
        let error2 = ScanPhotosUseCaseError.scanFailed(reason: "同じ理由")
        #expect(error1 == error2)
    }

    @Test("異なる理由のscanFailedエラーは等しくない")
    func testScanFailedNotEquatable() {
        let error1 = ScanPhotosUseCaseError.scanFailed(reason: "理由1")
        let error2 = ScanPhotosUseCaseError.scanFailed(reason: "理由2")
        #expect(error1 != error2)
    }

    @Test("同じ理由のanalysisFailedエラーは等しい")
    func testAnalysisFailedEquatable() {
        let error1 = ScanPhotosUseCaseError.analysisFailed(reason: "同じ理由")
        let error2 = ScanPhotosUseCaseError.analysisFailed(reason: "同じ理由")
        #expect(error1 == error2)
    }

    @Test("異なるエラータイプは等しくない")
    func testDifferentErrorTypesNotEquatable() {
        let error1 = ScanPhotosUseCaseError.photoAccessDenied
        let error2 = ScanPhotosUseCaseError.scanCancelled
        #expect(error1 != error2)
    }
}

// MARK: - ScanProgress UseCase Tests

@Suite("ScanProgress UseCase テスト")
struct ScanProgressUseCaseTests {

    @Test("初期状態のScanProgressを作成できる")
    func testInitialScanProgress() {
        let progress = ScanProgress.initial
        #expect(progress.phase == .preparing)
        #expect(progress.progress == 0)
    }

    @Test("完了状態のScanProgressを作成できる")
    func testCompletedScanProgress() {
        let progress = ScanProgress.completed
        #expect(progress.phase == .completed)
        #expect(progress.progress == 1.0)
    }

    @Test("ScanProgressのプロパティを設定できる")
    func testScanProgressProperties() {
        let progress = ScanProgress(
            phase: .analyzing,
            progress: 0.5,
            processedCount: 50,
            totalCount: 100,
            currentTask: "分析中..."
        )

        #expect(progress.phase == .analyzing)
        #expect(progress.progress == 0.5)
        #expect(progress.processedCount == 50)
        #expect(progress.totalCount == 100)
        #expect(progress.currentTask == "分析中...")
    }

    @Test("進捗率は0〜1の範囲にクランプされる")
    func testProgressClamping() {
        let progress1 = ScanProgress(phase: .analyzing, progress: -0.5)
        #expect(progress1.progress == 0)

        let progress2 = ScanProgress(phase: .analyzing, progress: 1.5)
        #expect(progress2.progress == 1.0)
    }
}

// MARK: - ScanPhase UseCase Tests

@Suite("ScanPhase UseCase テスト")
struct ScanPhaseUseCaseTests {

    @Test("全てのScanPhaseがdisplayNameを持つ")
    func testAllPhasesHaveDisplayName() {
        for phase in ScanPhase.allCases {
            #expect(!phase.displayName.isEmpty)
        }
    }

    @Test("アクティブなフェーズを正しく識別できる")
    func testActivePhases() {
        #expect(ScanPhase.preparing.isActive)
        #expect(ScanPhase.fetchingPhotos.isActive)
        #expect(ScanPhase.analyzing.isActive)
        #expect(ScanPhase.grouping.isActive)
        #expect(ScanPhase.optimizing.isActive)
        #expect(!ScanPhase.completed.isActive)
        #expect(!ScanPhase.error.isActive)
    }
}

// MARK: - ScanResult UseCase Tests

@Suite("ScanResult UseCase テスト")
struct ScanResultUseCaseTests {

    @Test("空のScanResultを作成できる")
    func testEmptyScanResult() {
        let result = ScanResult.empty
        #expect(result.totalPhotosScanned == 0)
        #expect(result.groupsFound == 0)
        #expect(result.potentialSavings == 0)
        #expect(result.duration == 0)
    }

    @Test("ScanResultのプロパティを設定できる")
    func testScanResultProperties() {
        let result = ScanResult(
            totalPhotosScanned: 1000,
            groupsFound: 50,
            potentialSavings: 2_000_000_000,
            duration: 30.5
        )

        #expect(result.totalPhotosScanned == 1000)
        #expect(result.groupsFound == 50)
        #expect(result.potentialSavings == 2_000_000_000)
        #expect(result.duration == 30.5)
    }

    @Test("ScanResultのフォーマット済み削減可能容量が正しい")
    func testFormattedPotentialSavings() {
        let result = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1_073_741_824, // 1GB
            duration: 10
        )

        #expect(!result.formattedPotentialSavings.isEmpty)
    }

    @Test("ScanResultのフォーマット済み時間が正しい")
    func testFormattedDuration() {
        let result = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 125 // 2分5秒
        )

        #expect(!result.formattedDuration.isEmpty)
    }
}

// MARK: - GroupBreakdown UseCase Tests

@Suite("GroupBreakdown UseCase テスト")
struct GroupBreakdownUseCaseTests {

    @Test("空のGroupBreakdownを作成できる")
    func testEmptyGroupBreakdown() {
        let breakdown = GroupBreakdown()
        #expect(breakdown.similarGroups == 0)
        #expect(breakdown.selfieGroups == 0)
        #expect(breakdown.screenshotCount == 0)
        #expect(breakdown.blurryCount == 0)
        #expect(breakdown.largeVideoCount == 0)
    }

    @Test("GroupBreakdownの合計を正しく計算できる")
    func testGroupBreakdownTotalItems() {
        let breakdown = GroupBreakdown(
            similarGroups: 10,
            selfieGroups: 5,
            screenshotCount: 20,
            blurryCount: 15,
            largeVideoCount: 8
        )

        #expect(breakdown.totalItems == 58)
    }

    @Test("GroupBreakdownからグループタイプ別の数を取得できる")
    func testGroupBreakdownCountForType() {
        let breakdown = GroupBreakdown(
            similarGroups: 10,
            selfieGroups: 5,
            screenshotCount: 20,
            blurryCount: 15,
            largeVideoCount: 8
        )

        #expect(breakdown.count(for: .similar) == 10)
        #expect(breakdown.count(for: .selfie) == 5)
        #expect(breakdown.count(for: .screenshot) == 20)
        #expect(breakdown.count(for: .blurry) == 15)
        #expect(breakdown.count(for: .largeVideo) == 8)
        #expect(breakdown.count(for: .duplicate) == 0)
    }
}

// MARK: - ScanResult Equatable UseCase Tests

@Suite("ScanResult Equatable UseCase テスト")
struct ScanResultEquatableUseCaseTests {

    @Test("同じ値のScanResultは等しい")
    func testScanResultEquatable() {
        let timestamp = Date()
        let result1 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10,
            timestamp: timestamp
        )
        let result2 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10,
            timestamp: timestamp
        )

        #expect(result1 == result2)
    }

    @Test("異なる値のScanResultは等しくない")
    func testScanResultNotEquatable() {
        let result1 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10
        )
        let result2 = ScanResult(
            totalPhotosScanned: 200,
            groupsFound: 20,
            potentialSavings: 2000,
            duration: 20
        )

        #expect(result1 != result2)
    }
}

// MARK: - ScanResult Hashable UseCase Tests

@Suite("ScanResult Hashable UseCase テスト")
struct ScanResultHashableUseCaseTests {

    @Test("ScanResultはハッシュ可能")
    func testScanResultHashable() {
        let timestamp = Date()
        let result1 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10,
            timestamp: timestamp
        )
        let result2 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10,
            timestamp: timestamp
        )

        #expect(result1.hashValue == result2.hashValue)
    }

    @Test("ScanResultをSetに追加できる")
    func testScanResultInSet() {
        let timestamp = Date()
        let result1 = ScanResult(
            totalPhotosScanned: 100,
            groupsFound: 10,
            potentialSavings: 1000,
            duration: 10,
            timestamp: timestamp
        )
        let result2 = ScanResult(
            totalPhotosScanned: 200,
            groupsFound: 20,
            potentialSavings: 2000,
            duration: 20,
            timestamp: timestamp
        )

        var set = Set<ScanResult>()
        set.insert(result1)
        set.insert(result2)

        #expect(set.count == 2)
    }
}
