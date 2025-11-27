//
//  DIContainer.swift
//  LightRoll_CleanerFeature
//
//  依存性注入コンテナ
//  アプリケーション全体の依存性を管理
//  Created by AI Assistant
//

import SwiftUI
import Combine

// MARK: - DIContainer

/// 依存性注入コンテナ
/// アプリケーション全体のサービスとRepositoryを管理
@MainActor
public final class DIContainer: ObservableObject {

    // MARK: - Singleton

    /// 共有インスタンス
    public static let shared = DIContainer()

    // MARK: - Published Properties

    /// コンテナの初期化状態
    @Published public private(set) var isInitialized: Bool = false

    // MARK: - Repositories (Lazy Initialization)

    /// 写真リポジトリ
    public lazy var photoRepository: any PhotoRepositoryProtocol = {
        createPhotoRepository()
    }()

    /// 分析リポジトリ
    public lazy var analysisRepository: any AnalysisRepositoryProtocol = {
        createAnalysisRepository()
    }()

    /// ストレージリポジトリ
    public lazy var storageRepository: any StorageRepositoryProtocol = {
        createStorageRepository()
    }()

    /// 設定リポジトリ
    public lazy var settingsRepository: any SettingsRepositoryProtocol = {
        createSettingsRepository()
    }()

    /// 課金リポジトリ
    public lazy var purchaseRepository: any PurchaseRepositoryProtocol = {
        createPurchaseRepository()
    }()

    // MARK: - Factory Closures (For Testing)

    /// カスタムファクトリ（テスト用）
    private var photoRepositoryFactory: (() -> any PhotoRepositoryProtocol)?
    private var analysisRepositoryFactory: (() -> any AnalysisRepositoryProtocol)?
    private var storageRepositoryFactory: (() -> any StorageRepositoryProtocol)?
    private var settingsRepositoryFactory: (() -> any SettingsRepositoryProtocol)?
    private var purchaseRepositoryFactory: (() -> any PurchaseRepositoryProtocol)?

    // MARK: - Initialization

    private init() {
        // シングルトンのためprivate
        isInitialized = true
    }

    /// テスト用イニシャライザ
    /// - Parameter mock: モックフラグ（将来の拡張用）
    #if DEBUG
    public init(forTesting: Bool) {
        // テスト用は何も初期化しない（後からファクトリを設定）
        isInitialized = true
    }
    #endif

    // MARK: - Repository Factory Methods

    private func createPhotoRepository() -> any PhotoRepositoryProtocol {
        if let factory = photoRepositoryFactory {
            return factory()
        }
        // デフォルト実装（StubRepository）
        return StubPhotoRepository()
    }

    private func createAnalysisRepository() -> any AnalysisRepositoryProtocol {
        if let factory = analysisRepositoryFactory {
            return factory()
        }
        // デフォルト実装（StubRepository）
        return StubAnalysisRepository()
    }

    private func createStorageRepository() -> any StorageRepositoryProtocol {
        if let factory = storageRepositoryFactory {
            return factory()
        }
        // デフォルト実装（StubRepository）
        return StubStorageRepository()
    }

    private func createSettingsRepository() -> any SettingsRepositoryProtocol {
        if let factory = settingsRepositoryFactory {
            return factory()
        }
        // デフォルト実装（StubRepository）
        return StubSettingsRepository()
    }

    private func createPurchaseRepository() -> any PurchaseRepositoryProtocol {
        if let factory = purchaseRepositoryFactory {
            return factory()
        }
        // デフォルト実装（StubRepository）
        return StubPurchaseRepository()
    }

    // MARK: - ViewModel Factory Methods

    /// DashboardViewModelを生成
    /// - Returns: 新しいDashboardViewModelインスタンス
    public func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            photoRepository: photoRepository,
            analysisRepository: analysisRepository,
            storageRepository: storageRepository
        )
    }

    /// GroupDetailViewModelを生成
    /// - Parameter group: 対象のPhotoGroup
    /// - Returns: 新しいGroupDetailViewModelインスタンス
    public func makeGroupDetailViewModel(group: PhotoGroup) -> GroupDetailViewModel {
        return GroupDetailViewModel(
            group: group,
            photoRepository: photoRepository,
            analysisRepository: analysisRepository
        )
    }

    /// SettingsViewModelを生成
    /// - Returns: 新しいSettingsViewModelインスタンス
    public func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            settingsRepository: settingsRepository,
            purchaseRepository: purchaseRepository
        )
    }

    // MARK: - Testing Support

    #if DEBUG
    /// テスト用のモックコンテナを生成
    /// - Returns: モック設定されたDIContainer
    public static func mock() -> DIContainer {
        let container = DIContainer(forTesting: true)
        container.photoRepositoryFactory = { MockPhotoRepository() }
        container.analysisRepositoryFactory = { MockAnalysisRepository() }
        container.storageRepositoryFactory = { MockStorageRepository() }
        container.settingsRepositoryFactory = { MockSettingsRepository() }
        container.purchaseRepositoryFactory = { MockPurchaseRepository() }
        return container
    }

    /// PhotoRepositoryをカスタム設定
    public func setPhotoRepository(_ factory: @escaping () -> any PhotoRepositoryProtocol) {
        photoRepositoryFactory = factory
    }

    /// AnalysisRepositoryをカスタム設定
    public func setAnalysisRepository(_ factory: @escaping () -> any AnalysisRepositoryProtocol) {
        analysisRepositoryFactory = factory
    }

    /// StorageRepositoryをカスタム設定
    public func setStorageRepository(_ factory: @escaping () -> any StorageRepositoryProtocol) {
        storageRepositoryFactory = factory
    }

    /// SettingsRepositoryをカスタム設定
    public func setSettingsRepository(_ factory: @escaping () -> any SettingsRepositoryProtocol) {
        settingsRepositoryFactory = factory
    }

    /// PurchaseRepositoryをカスタム設定
    public func setPurchaseRepository(_ factory: @escaping () -> any PurchaseRepositoryProtocol) {
        purchaseRepositoryFactory = factory
    }
    #endif
}

// MARK: - PhotoGroup (Placeholder)

/// 写真グループ（仮定義）
public struct PhotoGroup: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let type: GroupType
    public let photos: [PhotoAsset]
    public let bestShotIndex: Int?
    public let totalSize: Int64

    public init(
        id: UUID = UUID(),
        type: GroupType,
        photos: [PhotoAsset] = [],
        bestShotIndex: Int? = nil,
        totalSize: Int64 = 0
    ) {
        self.id = id
        self.type = type
        self.photos = photos
        self.bestShotIndex = bestShotIndex
        self.totalSize = totalSize
    }
}

/// グループタイプ
public enum GroupType: String, CaseIterable, Sendable {
    case similar       // 類似写真
    case selfie        // 自撮り
    case screenshot    // スクリーンショット
    case blurry        // ブレ・ピンボケ
    case largeVideo    // 大容量動画

    public var displayName: String {
        switch self {
        case .similar:
            return "類似写真"
        case .selfie:
            return "自撮り"
        case .screenshot:
            return "スクリーンショット"
        case .blurry:
            return "ブレ・ピンボケ"
        case .largeVideo:
            return "大容量動画"
        }
    }

    public var iconName: String {
        switch self {
        case .similar:
            return "photo.on.rectangle"
        case .selfie:
            return "person.crop.circle"
        case .screenshot:
            return "camera.viewfinder"
        case .blurry:
            return "circle.slash"
        case .largeVideo:
            return "video.fill"
        }
    }
}

// MARK: - Placeholder ViewModels

/// DashboardViewModel（仮定義）
@MainActor
public final class DashboardViewModel: ObservableObject {
    private let photoRepository: any PhotoRepositoryProtocol
    private let analysisRepository: any AnalysisRepositoryProtocol
    private let storageRepository: any StorageRepositoryProtocol

    @Published public var isLoading: Bool = false
    @Published public var storageInfo: StorageInfo?
    @Published public var groups: [PhotoGroup] = []

    public init(
        photoRepository: any PhotoRepositoryProtocol,
        analysisRepository: any AnalysisRepositoryProtocol,
        storageRepository: any StorageRepositoryProtocol
    ) {
        self.photoRepository = photoRepository
        self.analysisRepository = analysisRepository
        self.storageRepository = storageRepository
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        storageInfo = await storageRepository.fetchStorageInfo()
        // グループの読み込みは将来実装
    }
}

/// GroupDetailViewModel（仮定義）
@MainActor
public final class GroupDetailViewModel: ObservableObject {
    private let photoRepository: any PhotoRepositoryProtocol
    private let analysisRepository: any AnalysisRepositoryProtocol

    @Published public var group: PhotoGroup
    @Published public var selectedPhotos: Set<String> = []
    @Published public var isDeleting: Bool = false

    public init(
        group: PhotoGroup,
        photoRepository: any PhotoRepositoryProtocol,
        analysisRepository: any AnalysisRepositoryProtocol
    ) {
        self.group = group
        self.photoRepository = photoRepository
        self.analysisRepository = analysisRepository
    }

    public func deleteSelected() async throws {
        isDeleting = true
        defer { isDeleting = false }

        let photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
        try await photoRepository.deletePhotos(photosToDelete)
    }
}

/// SettingsViewModel（仮定義）
@MainActor
public final class SettingsViewModel: ObservableObject {
    private let settingsRepository: any SettingsRepositoryProtocol
    private let purchaseRepository: any PurchaseRepositoryProtocol

    @Published public var settings: UserSettings
    @Published public var premiumStatus: PremiumStatus = .free

    public init(
        settingsRepository: any SettingsRepositoryProtocol,
        purchaseRepository: any PurchaseRepositoryProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.purchaseRepository = purchaseRepository
        self.settings = settingsRepository.load()
    }

    public func saveSettings() {
        settingsRepository.save(settings)
    }

    public func loadPremiumStatus() async {
        premiumStatus = await purchaseRepository.getPremiumStatus()
    }
}
