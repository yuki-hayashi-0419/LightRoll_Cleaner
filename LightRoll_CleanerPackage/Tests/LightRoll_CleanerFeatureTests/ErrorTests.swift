//
//  ErrorTests.swift
//  LightRoll_CleanerFeatureTests
//
//  エラー型（LightRollError, PhotoLibraryError, AnalysisError, StorageError, ConfigurationError）の単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - PhotoLibraryError Tests

@Suite("PhotoLibraryError Tests")
struct PhotoLibraryErrorTests {

    // MARK: - Equatable Tests

    @Test("PhotoLibraryErrorがEquatableに準拠している")
    func testEquatable() {
        #expect(PhotoLibraryError.accessDenied == PhotoLibraryError.accessDenied)
        #expect(PhotoLibraryError.accessRestricted == PhotoLibraryError.accessRestricted)
        #expect(PhotoLibraryError.fetchFailed("reason") == PhotoLibraryError.fetchFailed("reason"))
        #expect(PhotoLibraryError.fetchFailed("reason1") != PhotoLibraryError.fetchFailed("reason2"))
        #expect(PhotoLibraryError.assetNotFound("id1") == PhotoLibraryError.assetNotFound("id1"))
        #expect(PhotoLibraryError.assetNotFound("id1") != PhotoLibraryError.assetNotFound("id2"))
        #expect(PhotoLibraryError.deletionFailed("reason") == PhotoLibraryError.deletionFailed("reason"))
        #expect(PhotoLibraryError.thumbnailGenerationFailed == PhotoLibraryError.thumbnailGenerationFailed)
    }

    @Test("異なるPhotoLibraryErrorケースは等しくない")
    func testDifferentCasesNotEqual() {
        #expect(PhotoLibraryError.accessDenied != PhotoLibraryError.accessRestricted)
        #expect(PhotoLibraryError.accessDenied != PhotoLibraryError.thumbnailGenerationFailed)
        #expect(PhotoLibraryError.fetchFailed("reason") != PhotoLibraryError.deletionFailed("reason"))
    }

    // MARK: - LocalizedError Tests

    @Test("accessDeniedのerrorDescriptionが空でない")
    func testAccessDeniedErrorDescription() {
        let error = PhotoLibraryError.accessDenied
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("accessRestrictedのerrorDescriptionが空でない")
    func testAccessRestrictedErrorDescription() {
        let error = PhotoLibraryError.accessRestricted
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("fetchFailedのerrorDescriptionに理由が含まれる")
    func testFetchFailedErrorDescription() {
        let reason = "ネットワークエラー"
        let error = PhotoLibraryError.fetchFailed(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("assetNotFoundのerrorDescriptionに識別子が含まれる")
    func testAssetNotFoundErrorDescription() {
        let identifier = "ABC123"
        let error = PhotoLibraryError.assetNotFound(identifier)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(identifier))
    }

    @Test("deletionFailedのerrorDescriptionに理由が含まれる")
    func testDeletionFailedErrorDescription() {
        let reason = "権限がありません"
        let error = PhotoLibraryError.deletionFailed(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("thumbnailGenerationFailedのerrorDescriptionが空でない")
    func testThumbnailGenerationFailedErrorDescription() {
        let error = PhotoLibraryError.thumbnailGenerationFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - FailureReason Tests

    @Test("全てのPhotoLibraryErrorケースがfailureReasonを持つ")
    func testAllCasesHaveFailureReason() {
        let allCases: [PhotoLibraryError] = [
            .accessDenied,
            .accessRestricted,
            .fetchFailed("reason"),
            .assetNotFound("id"),
            .deletionFailed("reason"),
            .thumbnailGenerationFailed
        ]

        for error in allCases {
            #expect(error.failureReason != nil)
            #expect(!error.failureReason!.isEmpty)
        }
    }

    // MARK: - RecoverySuggestion Tests

    @Test("全てのPhotoLibraryErrorケースがrecoverySuggestionを持つ")
    func testAllCasesHaveRecoverySuggestion() {
        let allCases: [PhotoLibraryError] = [
            .accessDenied,
            .accessRestricted,
            .fetchFailed("reason"),
            .assetNotFound("id"),
            .deletionFailed("reason"),
            .thumbnailGenerationFailed
        ]

        for error in allCases {
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - AnalysisError Tests

@Suite("AnalysisError Tests")
struct AnalysisErrorTests {

    // MARK: - Equatable Tests

    @Test("AnalysisErrorがEquatableに準拠している")
    func testEquatable() {
        #expect(AnalysisError.visionFrameworkError("reason") == AnalysisError.visionFrameworkError("reason"))
        #expect(AnalysisError.visionFrameworkError("reason1") != AnalysisError.visionFrameworkError("reason2"))
        #expect(AnalysisError.featureExtractionFailed == AnalysisError.featureExtractionFailed)
        #expect(AnalysisError.similarityCalculationFailed == AnalysisError.similarityCalculationFailed)
        #expect(AnalysisError.groupingFailed == AnalysisError.groupingFailed)
        #expect(AnalysisError.cancelled == AnalysisError.cancelled)
    }

    @Test("異なるAnalysisErrorケースは等しくない")
    func testDifferentCasesNotEqual() {
        #expect(AnalysisError.featureExtractionFailed != AnalysisError.similarityCalculationFailed)
        #expect(AnalysisError.groupingFailed != AnalysisError.cancelled)
        #expect(AnalysisError.visionFrameworkError("reason") != AnalysisError.featureExtractionFailed)
    }

    // MARK: - LocalizedError Tests

    @Test("visionFrameworkErrorのerrorDescriptionに理由が含まれる")
    func testVisionFrameworkErrorDescription() {
        let reason = "モデル読み込み失敗"
        let error = AnalysisError.visionFrameworkError(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    @Test("featureExtractionFailedのerrorDescriptionが空でない")
    func testFeatureExtractionFailedErrorDescription() {
        let error = AnalysisError.featureExtractionFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("similarityCalculationFailedのerrorDescriptionが空でない")
    func testSimilarityCalculationFailedErrorDescription() {
        let error = AnalysisError.similarityCalculationFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("groupingFailedのerrorDescriptionが空でない")
    func testGroupingFailedErrorDescription() {
        let error = AnalysisError.groupingFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("cancelledのerrorDescriptionが空でない")
    func testCancelledErrorDescription() {
        let error = AnalysisError.cancelled
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - FailureReason and RecoverySuggestion Tests

    @Test("全てのAnalysisErrorケースがfailureReasonとrecoverySuggestionを持つ")
    func testAllCasesHaveFailureReasonAndRecoverySuggestion() {
        let allCases: [AnalysisError] = [
            .visionFrameworkError("reason"),
            .featureExtractionFailed,
            .similarityCalculationFailed,
            .groupingFailed,
            .cancelled
        ]

        for error in allCases {
            #expect(error.failureReason != nil)
            #expect(!error.failureReason!.isEmpty)
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - StorageError Tests

@Suite("StorageError Tests")
struct StorageErrorTests {

    // MARK: - Equatable Tests

    @Test("StorageErrorがEquatableに準拠している")
    func testEquatable() {
        #expect(StorageError.insufficientSpace == StorageError.insufficientSpace)
        #expect(StorageError.calculationFailed == StorageError.calculationFailed)
        #expect(StorageError.persistenceFailed("reason") == StorageError.persistenceFailed("reason"))
        #expect(StorageError.persistenceFailed("reason1") != StorageError.persistenceFailed("reason2"))
    }

    @Test("異なるStorageErrorケースは等しくない")
    func testDifferentCasesNotEqual() {
        #expect(StorageError.insufficientSpace != StorageError.calculationFailed)
        #expect(StorageError.insufficientSpace != StorageError.persistenceFailed("reason"))
        #expect(StorageError.calculationFailed != StorageError.persistenceFailed("reason"))
    }

    // MARK: - LocalizedError Tests

    @Test("insufficientSpaceのerrorDescriptionが空でない")
    func testInsufficientSpaceErrorDescription() {
        let error = StorageError.insufficientSpace
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("calculationFailedのerrorDescriptionが空でない")
    func testCalculationFailedErrorDescription() {
        let error = StorageError.calculationFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("persistenceFailedのerrorDescriptionに理由が含まれる")
    func testPersistenceFailedErrorDescription() {
        let reason = "ディスク書き込みエラー"
        let error = StorageError.persistenceFailed(reason)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(reason))
    }

    // MARK: - FailureReason and RecoverySuggestion Tests

    @Test("全てのStorageErrorケースがfailureReasonとrecoverySuggestionを持つ")
    func testAllCasesHaveFailureReasonAndRecoverySuggestion() {
        let allCases: [StorageError] = [
            .insufficientSpace,
            .calculationFailed,
            .persistenceFailed("reason")
        ]

        for error in allCases {
            #expect(error.failureReason != nil)
            #expect(!error.failureReason!.isEmpty)
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - ConfigurationError Tests

@Suite("ConfigurationError Tests")
struct ConfigurationErrorTests {

    // MARK: - Equatable Tests

    @Test("ConfigurationErrorがEquatableに準拠している")
    func testEquatable() {
        #expect(ConfigurationError.invalidConfiguration("desc") == ConfigurationError.invalidConfiguration("desc"))
        #expect(ConfigurationError.invalidConfiguration("desc1") != ConfigurationError.invalidConfiguration("desc2"))
        #expect(ConfigurationError.loadFailed == ConfigurationError.loadFailed)
        #expect(ConfigurationError.saveFailed == ConfigurationError.saveFailed)
    }

    @Test("異なるConfigurationErrorケースは等しくない")
    func testDifferentCasesNotEqual() {
        #expect(ConfigurationError.loadFailed != ConfigurationError.saveFailed)
        #expect(ConfigurationError.invalidConfiguration("desc") != ConfigurationError.loadFailed)
        #expect(ConfigurationError.invalidConfiguration("desc") != ConfigurationError.saveFailed)
    }

    // MARK: - LocalizedError Tests

    @Test("invalidConfigurationのerrorDescriptionに説明が含まれる")
    func testInvalidConfigurationErrorDescription() {
        let description = "閾値が範囲外です"
        let error = ConfigurationError.invalidConfiguration(description)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains(description))
    }

    @Test("loadFailedのerrorDescriptionが空でない")
    func testLoadFailedErrorDescription() {
        let error = ConfigurationError.loadFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("saveFailedのerrorDescriptionが空でない")
    func testSaveFailedErrorDescription() {
        let error = ConfigurationError.saveFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    // MARK: - FailureReason and RecoverySuggestion Tests

    @Test("全てのConfigurationErrorケースがfailureReasonとrecoverySuggestionを持つ")
    func testAllCasesHaveFailureReasonAndRecoverySuggestion() {
        let allCases: [ConfigurationError] = [
            .invalidConfiguration("desc"),
            .loadFailed,
            .saveFailed
        ]

        for error in allCases {
            #expect(error.failureReason != nil)
            #expect(!error.failureReason!.isEmpty)
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - LightRollError Tests

@Suite("LightRollError Tests")
struct LightRollErrorTests {

    // MARK: - Equatable Tests

    @Test("LightRollErrorがEquatableに準拠している")
    func testEquatable() {
        // photoLibrary
        #expect(LightRollError.photoLibrary(.accessDenied) == LightRollError.photoLibrary(.accessDenied))
        #expect(LightRollError.photoLibrary(.accessDenied) != LightRollError.photoLibrary(.accessRestricted))

        // analysis
        #expect(LightRollError.analysis(.cancelled) == LightRollError.analysis(.cancelled))
        #expect(LightRollError.analysis(.cancelled) != LightRollError.analysis(.groupingFailed))

        // storage
        #expect(LightRollError.storage(.insufficientSpace) == LightRollError.storage(.insufficientSpace))
        #expect(LightRollError.storage(.insufficientSpace) != LightRollError.storage(.calculationFailed))

        // configuration
        #expect(LightRollError.configuration(.loadFailed) == LightRollError.configuration(.loadFailed))
        #expect(LightRollError.configuration(.loadFailed) != LightRollError.configuration(.saveFailed))

        // unknown
        #expect(LightRollError.unknown("message") == LightRollError.unknown("message"))
        #expect(LightRollError.unknown("message1") != LightRollError.unknown("message2"))
        #expect(LightRollError.unknown(nil) == LightRollError.unknown(nil))
    }

    @Test("異なるLightRollErrorカテゴリは等しくない")
    func testDifferentCategoriesNotEqual() {
        #expect(LightRollError.photoLibrary(.accessDenied) != LightRollError.analysis(.cancelled))
        #expect(LightRollError.storage(.insufficientSpace) != LightRollError.configuration(.loadFailed))
        #expect(LightRollError.unknown("message") != LightRollError.photoLibrary(.accessDenied))
    }

    // MARK: - LocalizedError Tests - photoLibrary

    @Test("photoLibraryエラーのerrorDescriptionがネストされたエラーの説明を返す")
    func testPhotoLibraryErrorDescription() {
        let nestedError = PhotoLibraryError.accessDenied
        let error = LightRollError.photoLibrary(nestedError)
        #expect(error.errorDescription == nestedError.errorDescription)
    }

    @Test("photoLibraryエラーのfailureReasonがネストされたエラーの理由を返す")
    func testPhotoLibraryFailureReason() {
        let nestedError = PhotoLibraryError.accessDenied
        let error = LightRollError.photoLibrary(nestedError)
        #expect(error.failureReason == nestedError.failureReason)
    }

    @Test("photoLibraryエラーのrecoverySuggestionがネストされたエラーの提案を返す")
    func testPhotoLibraryRecoverySuggestion() {
        let nestedError = PhotoLibraryError.accessDenied
        let error = LightRollError.photoLibrary(nestedError)
        #expect(error.recoverySuggestion == nestedError.recoverySuggestion)
    }

    // MARK: - LocalizedError Tests - analysis

    @Test("analysisエラーのerrorDescriptionがネストされたエラーの説明を返す")
    func testAnalysisErrorDescription() {
        let nestedError = AnalysisError.featureExtractionFailed
        let error = LightRollError.analysis(nestedError)
        #expect(error.errorDescription == nestedError.errorDescription)
    }

    @Test("analysisエラーのfailureReasonがネストされたエラーの理由を返す")
    func testAnalysisFailureReason() {
        let nestedError = AnalysisError.featureExtractionFailed
        let error = LightRollError.analysis(nestedError)
        #expect(error.failureReason == nestedError.failureReason)
    }

    @Test("analysisエラーのrecoverySuggestionがネストされたエラーの提案を返す")
    func testAnalysisRecoverySuggestion() {
        let nestedError = AnalysisError.featureExtractionFailed
        let error = LightRollError.analysis(nestedError)
        #expect(error.recoverySuggestion == nestedError.recoverySuggestion)
    }

    // MARK: - LocalizedError Tests - storage

    @Test("storageエラーのerrorDescriptionがネストされたエラーの説明を返す")
    func testStorageErrorDescription() {
        let nestedError = StorageError.insufficientSpace
        let error = LightRollError.storage(nestedError)
        #expect(error.errorDescription == nestedError.errorDescription)
    }

    @Test("storageエラーのfailureReasonがネストされたエラーの理由を返す")
    func testStorageFailureReason() {
        let nestedError = StorageError.insufficientSpace
        let error = LightRollError.storage(nestedError)
        #expect(error.failureReason == nestedError.failureReason)
    }

    @Test("storageエラーのrecoverySuggestionがネストされたエラーの提案を返す")
    func testStorageRecoverySuggestion() {
        let nestedError = StorageError.insufficientSpace
        let error = LightRollError.storage(nestedError)
        #expect(error.recoverySuggestion == nestedError.recoverySuggestion)
    }

    // MARK: - LocalizedError Tests - configuration

    @Test("configurationエラーのerrorDescriptionがネストされたエラーの説明を返す")
    func testConfigurationErrorDescription() {
        let nestedError = ConfigurationError.saveFailed
        let error = LightRollError.configuration(nestedError)
        #expect(error.errorDescription == nestedError.errorDescription)
    }

    @Test("configurationエラーのfailureReasonがネストされたエラーの理由を返す")
    func testConfigurationFailureReason() {
        let nestedError = ConfigurationError.saveFailed
        let error = LightRollError.configuration(nestedError)
        #expect(error.failureReason == nestedError.failureReason)
    }

    @Test("configurationエラーのrecoverySuggestionがネストされたエラーの提案を返す")
    func testConfigurationRecoverySuggestion() {
        let nestedError = ConfigurationError.saveFailed
        let error = LightRollError.configuration(nestedError)
        #expect(error.recoverySuggestion == nestedError.recoverySuggestion)
    }

    // MARK: - LocalizedError Tests - unknown

    @Test("unknownエラーのerrorDescriptionがメッセージを返す")
    func testUnknownErrorDescriptionWithMessage() {
        let message = "予期しないエラーが発生しました"
        let error = LightRollError.unknown(message)
        #expect(error.errorDescription == message)
    }

    @Test("unknownエラー（nilメッセージ）のerrorDescriptionがデフォルトメッセージを返す")
    func testUnknownErrorDescriptionWithNilMessage() {
        let error = LightRollError.unknown(nil)
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("unknownエラーのfailureReasonがnilを返す")
    func testUnknownFailureReason() {
        let error = LightRollError.unknown("message")
        #expect(error.failureReason == nil)
    }

    @Test("unknownエラーのrecoverySuggestionがデフォルト提案を返す")
    func testUnknownRecoverySuggestion() {
        let error = LightRollError.unknown("message")
        #expect(error.recoverySuggestion != nil)
        #expect(!error.recoverySuggestion!.isEmpty)
    }

    // MARK: - wrap() Factory Method Tests

    @Test("wrapがLightRollErrorをそのまま返す")
    func testWrapLightRollError() {
        let originalError = LightRollError.photoLibrary(.accessDenied)
        let wrappedError = LightRollError.wrap(originalError)
        #expect(wrappedError == originalError)
    }

    @Test("wrapが一般的なErrorをunknownでラップする")
    func testWrapGenericError() {
        struct GenericError: Error, LocalizedError {
            var errorDescription: String? { "Generic error occurred" }
        }

        let genericError = GenericError()
        let wrappedError = LightRollError.wrap(genericError)

        if case .unknown(let message) = wrappedError {
            #expect(message != nil)
            #expect(message!.contains("Generic error occurred"))
        } else {
            Issue.record("Expected .unknown case")
        }
    }

    @Test("wrapがNSErrorをunknownでラップする")
    func testWrapNSError() {
        let nsError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "NSError description"])
        let wrappedError = LightRollError.wrap(nsError)

        if case .unknown(let message) = wrappedError {
            #expect(message != nil)
            #expect(message!.contains("NSError description"))
        } else {
            Issue.record("Expected .unknown case")
        }
    }
}

// MARK: - Error Conformance Tests

@Suite("Error Conformance Tests")
struct ErrorConformanceTests {

    @Test("PhotoLibraryErrorがErrorプロトコルに準拠している")
    func testPhotoLibraryErrorConformance() {
        let error: Error = PhotoLibraryError.accessDenied
        #expect(error is PhotoLibraryError)
    }

    @Test("AnalysisErrorがErrorプロトコルに準拠している")
    func testAnalysisErrorConformance() {
        let error: Error = AnalysisError.cancelled
        #expect(error is AnalysisError)
    }

    @Test("StorageErrorがErrorプロトコルに準拠している")
    func testStorageErrorConformance() {
        let error: Error = StorageError.insufficientSpace
        #expect(error is StorageError)
    }

    @Test("ConfigurationErrorがErrorプロトコルに準拠している")
    func testConfigurationErrorConformance() {
        let error: Error = ConfigurationError.loadFailed
        #expect(error is ConfigurationError)
    }

    @Test("LightRollErrorがErrorプロトコルに準拠している")
    func testLightRollErrorConformance() {
        let error: Error = LightRollError.unknown("test")
        #expect(error is LightRollError)
    }
}

// MARK: - Error All Cases Coverage Tests

@Suite("Error All Cases Coverage Tests")
struct ErrorAllCasesCoverageTests {

    @Test("PhotoLibraryErrorの全ケースがテストされている")
    func testPhotoLibraryErrorAllCases() {
        // 全ケースを列挙して確認
        let allCases: [PhotoLibraryError] = [
            .accessDenied,
            .accessRestricted,
            .fetchFailed("reason"),
            .assetNotFound("id"),
            .deletionFailed("reason"),
            .thumbnailGenerationFailed
        ]

        #expect(allCases.count == 6)
    }

    @Test("AnalysisErrorの全ケースがテストされている")
    func testAnalysisErrorAllCases() {
        let allCases: [AnalysisError] = [
            .visionFrameworkError("reason"),
            .featureExtractionFailed,
            .similarityCalculationFailed,
            .groupingFailed,
            .cancelled
        ]

        #expect(allCases.count == 5)
    }

    @Test("StorageErrorの全ケースがテストされている")
    func testStorageErrorAllCases() {
        let allCases: [StorageError] = [
            .insufficientSpace,
            .calculationFailed,
            .persistenceFailed("reason")
        ]

        #expect(allCases.count == 3)
    }

    @Test("ConfigurationErrorの全ケースがテストされている")
    func testConfigurationErrorAllCases() {
        let allCases: [ConfigurationError] = [
            .invalidConfiguration("desc"),
            .loadFailed,
            .saveFailed
        ]

        #expect(allCases.count == 3)
    }

    @Test("LightRollErrorの全ケースがテストされている")
    func testLightRollErrorAllCases() {
        let allCases: [LightRollError] = [
            .photoLibrary(.accessDenied),
            .analysis(.cancelled),
            .storage(.insufficientSpace),
            .configuration(.loadFailed),
            .unknown(nil)
        ]

        #expect(allCases.count == 5)
    }
}
