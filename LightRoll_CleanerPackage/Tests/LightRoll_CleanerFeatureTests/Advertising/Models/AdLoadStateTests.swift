//
//  AdLoadStateTests.swift
//  LightRoll_CleanerFeatureTests
//
//  AdLoadStateモデルのテスト
//

import Testing
@testable import LightRoll_CleanerFeature

@Suite("AdLoadState Tests")
struct AdLoadStateTests {

    // MARK: - Computed Properties Tests

    @Test("isLoaded: loaded状態でtrueを返す")
    func isLoadedReturnsTrue() {
        let state = AdLoadState.loaded
        #expect(state.isLoaded == true)
    }

    @Test("isLoaded: idle状態でfalseを返す")
    func isLoadedReturnsFalseForIdle() {
        let state = AdLoadState.idle
        #expect(state.isLoaded == false)
    }

    @Test("isLoaded: loading状態でfalseを返す")
    func isLoadedReturnsFalseForLoading() {
        let state = AdLoadState.loading
        #expect(state.isLoaded == false)
    }

    @Test("isLoaded: failed状態でfalseを返す")
    func isLoadedReturnsFalseForFailed() {
        let state = AdLoadState.failed(.notInitialized)
        #expect(state.isLoaded == false)
    }

    @Test("isLoading: loading状態でtrueを返す")
    func isLoadingReturnsTrue() {
        let state = AdLoadState.loading
        #expect(state.isLoading == true)
    }

    @Test("isLoading: idle状態でfalseを返す")
    func isLoadingReturnsFalseForIdle() {
        let state = AdLoadState.idle
        #expect(state.isLoading == false)
    }

    @Test("isError: failed状態でtrueを返す")
    func isErrorReturnsTrue() {
        let state = AdLoadState.failed(.adNotReady)
        #expect(state.isError == true)
    }

    @Test("isError: loaded状態でfalseを返す")
    func isErrorReturnsFalseForLoaded() {
        let state = AdLoadState.loaded
        #expect(state.isError == false)
    }

    @Test("errorMessage: failed状態でエラーメッセージを返す")
    func errorMessageReturnsMessage() {
        let state = AdLoadState.failed(.loadFailed("テストエラー"))
        #expect(state.errorMessage != nil)
        #expect(state.errorMessage?.contains("テストエラー") == true)
    }

    @Test("errorMessage: idle状態でnilを返す")
    func errorMessageReturnsNilForIdle() {
        let state = AdLoadState.idle
        #expect(state.errorMessage == nil)
    }

    // MARK: - Equatable Tests

    @Test("Equatable: 同じidle状態は等しい")
    func equatableIdleStates() {
        let state1 = AdLoadState.idle
        let state2 = AdLoadState.idle
        #expect(state1 == state2)
    }

    @Test("Equatable: 同じloading状態は等しい")
    func equatableLoadingStates() {
        let state1 = AdLoadState.loading
        let state2 = AdLoadState.loading
        #expect(state1 == state2)
    }

    @Test("Equatable: 同じloaded状態は等しい")
    func equatableLoadedStates() {
        let state1 = AdLoadState.loaded
        let state2 = AdLoadState.loaded
        #expect(state1 == state2)
    }

    @Test("Equatable: 同じfailed状態は等しい")
    func equatableFailedStates() {
        let state1 = AdLoadState.failed(.notInitialized)
        let state2 = AdLoadState.failed(.notInitialized)
        #expect(state1 == state2)
    }

    @Test("Equatable: 異なる状態は等しくない")
    func equatableDifferentStates() {
        let state1 = AdLoadState.idle
        let state2 = AdLoadState.loading
        #expect(state1 != state2)
    }
}

@Suite("AdManagerError Tests")
struct AdManagerErrorTests {

    // MARK: - LocalizedError Tests

    @Test("errorDescription: notInitializedで適切な説明を返す")
    func errorDescriptionForNotInitialized() {
        let error = AdManagerError.notInitialized
        #expect(error.errorDescription?.contains("初期化") == true)
    }

    @Test("errorDescription: loadFailedで適切な説明を返す")
    func errorDescriptionForLoadFailed() {
        let error = AdManagerError.loadFailed("テストエラー")
        #expect(error.errorDescription?.contains("ロード") == true)
        #expect(error.errorDescription?.contains("テストエラー") == true)
    }

    @Test("errorDescription: showFailedで適切な説明を返す")
    func errorDescriptionForShowFailed() {
        let error = AdManagerError.showFailed("表示エラー")
        #expect(error.errorDescription?.contains("表示") == true)
        #expect(error.errorDescription?.contains("表示エラー") == true)
    }

    @Test("errorDescription: premiumUserNoAdsで適切な説明を返す")
    func errorDescriptionForPremiumUserNoAds() {
        let error = AdManagerError.premiumUserNoAds
        #expect(error.errorDescription?.contains("プレミアム") == true)
    }

    @Test("errorDescription: adNotReadyで適切な説明を返す")
    func errorDescriptionForAdNotReady() {
        let error = AdManagerError.adNotReady
        #expect(error.errorDescription?.contains("準備") == true)
    }

    @Test("errorDescription: networkErrorで適切な説明を返す")
    func errorDescriptionForNetworkError() {
        let error = AdManagerError.networkError
        #expect(error.errorDescription?.contains("ネットワーク") == true)
    }

    @Test("errorDescription: timeoutで適切な説明を返す")
    func errorDescriptionForTimeout() {
        let error = AdManagerError.timeout
        #expect(error.errorDescription?.contains("タイムアウト") == true)
    }

    @Test("recoverySuggestion: notInitializedで提案を返す")
    func recoverySuggestionForNotInitialized() {
        let error = AdManagerError.notInitialized
        #expect(error.recoverySuggestion != nil)
    }

    @Test("recoverySuggestion: premiumUserNoAdsでnilを返す")
    func recoverySuggestionForPremiumUserNoAds() {
        let error = AdManagerError.premiumUserNoAds
        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - Equatable Tests

    @Test("Equatable: 同じnotInitializedは等しい")
    func equatableNotInitialized() {
        let error1 = AdManagerError.notInitialized
        let error2 = AdManagerError.notInitialized
        #expect(error1 == error2)
    }

    @Test("Equatable: 同じloadFailedは等しい")
    func equatableLoadFailed() {
        let error1 = AdManagerError.loadFailed("テスト")
        let error2 = AdManagerError.loadFailed("テスト")
        #expect(error1 == error2)
    }

    @Test("Equatable: 異なるloadFailedは等しくない")
    func equatableDifferentLoadFailed() {
        let error1 = AdManagerError.loadFailed("テスト1")
        let error2 = AdManagerError.loadFailed("テスト2")
        #expect(error1 != error2)
    }

    @Test("Equatable: 異なるエラータイプは等しくない")
    func equatableDifferentTypes() {
        let error1 = AdManagerError.notInitialized
        let error2 = AdManagerError.adNotReady
        #expect(error1 != error2)
    }
}

@Suite("AdReward Tests")
struct AdRewardTests {

    // MARK: - Initialization Tests

    @Test("init: プロパティが正しく設定される")
    func initializationSetsProperties() {
        let reward = AdReward(amount: 10, type: "コイン")

        #expect(reward.amount == 10)
        #expect(reward.type == "コイン")
    }

    // MARK: - Equatable Tests

    @Test("Equatable: 同じ値の報酬は等しい")
    func equatableSameValues() {
        let reward1 = AdReward(amount: 5, type: "ポイント")
        let reward2 = AdReward(amount: 5, type: "ポイント")
        #expect(reward1 == reward2)
    }

    @Test("Equatable: 異なる量の報酬は等しくない")
    func equatableDifferentAmounts() {
        let reward1 = AdReward(amount: 5, type: "ポイント")
        let reward2 = AdReward(amount: 10, type: "ポイント")
        #expect(reward1 != reward2)
    }

    @Test("Equatable: 異なるタイプの報酬は等しくない")
    func equatableDifferentTypes() {
        let reward1 = AdReward(amount: 5, type: "ポイント")
        let reward2 = AdReward(amount: 5, type: "コイン")
        #expect(reward1 != reward2)
    }

    // MARK: - Sendable Tests

    @Test("Sendable: 並行コンテキストで使用可能")
    func sendableTest() async {
        let reward = AdReward(amount: 10, type: "コイン")

        await Task.detached {
            // Sendableなので並行コンテキストでも使用可能
            let localReward = reward
            #expect(localReward.amount == 10)
        }.value
    }
}
