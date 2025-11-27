//
//  DIContainerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  DIコンテナのテスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - DIContainer Tests

@Suite("DIContainer Tests")
struct DIContainerTests {

    // MARK: - Initialization Tests

    @MainActor
    @Test("DIContainer.sharedが正常に初期化される")
    func testSharedInitialization() async throws {
        let container = DIContainer.shared
        #expect(container.isInitialized == true)
    }

    @MainActor
    @Test("DIContainer.mockが正常に生成される")
    func testMockContainerCreation() async throws {
        let container = DIContainer.mock()
        #expect(container.isInitialized == true)
    }

    // MARK: - Repository Access Tests

    @MainActor
    @Test("photoRepositoryにアクセスできる")
    func testPhotoRepositoryAccess() async throws {
        let container = DIContainer.shared
        let repo = container.photoRepository
        #expect(repo != nil)
    }

    @MainActor
    @Test("analysisRepositoryにアクセスできる")
    func testAnalysisRepositoryAccess() async throws {
        let container = DIContainer.shared
        let repo = container.analysisRepository
        #expect(repo != nil)
    }

    @MainActor
    @Test("storageRepositoryにアクセスできる")
    func testStorageRepositoryAccess() async throws {
        let container = DIContainer.shared
        let repo = container.storageRepository
        #expect(repo != nil)
    }

    @MainActor
    @Test("settingsRepositoryにアクセスできる")
    func testSettingsRepositoryAccess() async throws {
        let container = DIContainer.shared
        let repo = container.settingsRepository
        #expect(repo != nil)
    }

    @MainActor
    @Test("purchaseRepositoryにアクセスできる")
    func testPurchaseRepositoryAccess() async throws {
        let container = DIContainer.shared
        let repo = container.purchaseRepository
        #expect(repo != nil)
    }

    // MARK: - ViewModel Factory Tests

    @MainActor
    @Test("makeDashboardViewModelがViewModelを生成する")
    func testMakeDashboardViewModel() async throws {
        let container = DIContainer.shared
        let viewModel = container.makeDashboardViewModel()
        #expect(viewModel != nil)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test("makeGroupDetailViewModelがViewModelを生成する")
    func testMakeGroupDetailViewModel() async throws {
        let container = DIContainer.shared
        let group = PhotoGroup(type: .similar)
        let viewModel = container.makeGroupDetailViewModel(group: group)
        #expect(viewModel != nil)
        #expect(viewModel.group.type == .similar)
    }

    @MainActor
    @Test("makeSettingsViewModelがViewModelを生成する")
    func testMakeSettingsViewModel() async throws {
        let container = DIContainer.shared
        let viewModel = container.makeSettingsViewModel()
        #expect(viewModel != nil)
    }

    // MARK: - Mock Repository Tests

    @MainActor
    @Test("MockPhotoRepositoryが正しく動作する")
    func testMockPhotoRepository() async throws {
        let mockRepo = MockPhotoRepository()
        let testPhoto = PhotoAsset(id: "test-1", fileSize: 1024)
        mockRepo.mockPhotos = [testPhoto]

        let photos = try await mockRepo.fetchAllPhotos()
        #expect(photos.count == 1)
        #expect(photos.first?.id == "test-1")
        #expect(mockRepo.fetchAllPhotosCalled == true)
    }

    @MainActor
    @Test("MockAnalysisRepositoryが分析結果を返す")
    func testMockAnalysisRepository() async throws {
        let mockRepo = MockAnalysisRepository()
        let testPhoto = PhotoAsset(id: "test-1")

        let result = try await mockRepo.analyzePhoto(testPhoto)
        #expect(result.photoId == "test-1")
    }

    @MainActor
    @Test("MockStorageRepositoryがストレージ情報を返す")
    func testMockStorageRepository() async throws {
        let mockRepo = MockStorageRepository()
        mockRepo.mockStorageInfo = StorageInfo(
            totalCapacity: 100,
            usedCapacity: 50,
            photosSize: 20,
            reclaimableSize: 10
        )

        let info = await mockRepo.fetchStorageInfo()
        #expect(info.totalCapacity == 100)
        #expect(info.usedCapacity == 50)
        #expect(info.usageRatio == 0.5)
    }

    @MainActor
    @Test("MockSettingsRepositoryが設定を保存・読込できる")
    func testMockSettingsRepository() async throws {
        let mockRepo = MockSettingsRepository()
        var settings = UserSettings.default
        settings.similarityThreshold = 0.9

        mockRepo.save(settings)
        #expect(mockRepo.saveCalled == true)

        let loadedSettings = mockRepo.load()
        #expect(loadedSettings.similarityThreshold == 0.9)
    }

    @MainActor
    @Test("MockPurchaseRepositoryがプレミアムステータスを返す")
    func testMockPurchaseRepository() async throws {
        let mockRepo = MockPurchaseRepository()
        mockRepo.mockPremiumStatus = .premium

        let status = await mockRepo.getPremiumStatus()
        #expect(status == .premium)
    }
}

// MARK: - Model Tests

@Suite("Model Tests")
struct ModelTests {

    @Test("PhotoAssetが正しく初期化される")
    func testPhotoAssetInitialization() {
        let date = Date()
        let asset = PhotoAsset(id: "test", creationDate: date, fileSize: 2048)

        #expect(asset.id == "test")
        #expect(asset.creationDate == date)
        #expect(asset.fileSize == 2048)
    }

    @Test("StorageInfoのusageRatioが正しく計算される")
    func testStorageInfoUsageRatio() {
        let info = StorageInfo(
            totalCapacity: 1000,
            usedCapacity: 750,
            photosSize: 500,
            reclaimableSize: 100
        )

        #expect(info.usageRatio == 0.75)
        #expect(info.freeCapacity == 250)
    }

    @Test("StorageInfoのtotalCapacityが0の場合usageRatioは0")
    func testStorageInfoZeroCapacity() {
        let info = StorageInfo(
            totalCapacity: 0,
            usedCapacity: 0,
            photosSize: 0,
            reclaimableSize: 0
        )

        #expect(info.usageRatio == 0)
    }

    @Test("UserSettingsのデフォルト値が正しい")
    func testUserSettingsDefaults() {
        let settings = UserSettings.default

        #expect(settings.similarityThreshold == 0.85)
        #expect(settings.autoDeleteDays == 30)
        #expect(settings.notificationsEnabled == true)
        #expect(settings.scanOnLaunch == false)
    }

    @Test("PhotoGroupが正しく初期化される")
    func testPhotoGroupInitialization() {
        let group = PhotoGroup(type: .screenshot)

        #expect(group.type == .screenshot)
        #expect(group.photos.isEmpty)
        #expect(group.bestShotIndex == nil)
    }

    @Test("GroupTypeのdisplayNameが正しい")
    func testGroupTypeDisplayNames() {
        #expect(GroupType.similar.displayName == "類似写真")
        #expect(GroupType.selfie.displayName == "自撮り")
        #expect(GroupType.screenshot.displayName == "スクリーンショット")
        #expect(GroupType.blurry.displayName == "ブレ・ピンボケ")
        #expect(GroupType.largeVideo.displayName == "大容量動画")
    }
}

// MARK: - Protocol Conformance Tests

@Suite("Protocol Conformance Tests")
struct ProtocolConformanceTests {

    @Test("StubPhotoRepositoryがプロトコルに準拠している")
    func testStubPhotoRepositoryConformance() async throws {
        let repo: any PhotoRepositoryProtocol = StubPhotoRepository()
        let photos = try await repo.fetchAllPhotos()
        #expect(photos.isEmpty)
    }

    @Test("StubAnalysisRepositoryがプロトコルに準拠している")
    func testStubAnalysisRepositoryConformance() async throws {
        let repo: any AnalysisRepositoryProtocol = StubAnalysisRepository()
        let testPhoto = PhotoAsset(id: "test")
        let result = try await repo.analyzePhoto(testPhoto)
        #expect(result.photoId == "test")
    }

    @Test("StubStorageRepositoryがプロトコルに準拠している")
    func testStubStorageRepositoryConformance() async throws {
        let repo: any StorageRepositoryProtocol = StubStorageRepository()
        let info = await repo.fetchStorageInfo()
        #expect(info.totalCapacity > 0)
    }

    @Test("StubSettingsRepositoryがプロトコルに準拠している")
    func testStubSettingsRepositoryConformance() {
        let repo: any SettingsRepositoryProtocol = StubSettingsRepository()
        let settings = repo.load()
        #expect(settings == UserSettings.default)
    }

    @Test("StubPurchaseRepositoryがプロトコルに準拠している")
    func testStubPurchaseRepositoryConformance() async throws {
        let repo: any PurchaseRepositoryProtocol = StubPurchaseRepository()
        let products = try await repo.fetchProducts()
        #expect(products.isEmpty == false)
    }
}
