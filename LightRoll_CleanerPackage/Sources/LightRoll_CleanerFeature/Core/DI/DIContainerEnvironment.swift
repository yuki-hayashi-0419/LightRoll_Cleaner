//
//  DIContainerEnvironment.swift
//  LightRoll_CleanerFeature
//
//  SwiftUI環境用のDIContainer拡張
//  @Environment経由でDIContainerにアクセス可能にする
//  Created by AI Assistant
//

import SwiftUI

// MARK: - DIContainer Environment Key

/// DIContainerのEnvironmentKey
/// Swift 6 コンカレンシー対応版
private struct DIContainerKey: EnvironmentKey {
    // DIContainerはMainActorで初期化される必要があるため
    // デフォルト値としてはplaceholderを使用し、実際の注入はView階層で行う
    nonisolated(unsafe) static var defaultValue: DIContainer = {
        // Note: このコードはMainActorコンテキストで呼ばれることを想定
        // 実際のアプリケーションでは必ずwithDIContainerで設定する
        MainActor.assumeIsolated {
            DIContainer.shared
        }
    }()
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    /// DIContainerへのアクセス
    /// 使用例: @Environment(\.diContainer) private var container
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// DIContainerをView階層に注入
    /// - Parameter container: 注入するDIContainer
    /// - Returns: DIContainerが設定されたView
    ///
    /// 使用例:
    /// ```swift
    /// ContentView()
    ///     .withDIContainer(DIContainer.shared)
    /// ```
    func withDIContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }

    /// モック用DIContainerを注入（DEBUG時のみ）
    /// - Returns: モックDIContainerが設定されたView
    ///
    /// 使用例（Preview用）:
    /// ```swift
    /// ContentView()
    ///     .withMockDIContainer()
    /// ```
    #if DEBUG
    @MainActor
    func withMockDIContainer() -> some View {
        environment(\.diContainer, DIContainer.mock())
    }
    #endif
}

// MARK: - Individual Repository Environment Keys

/// PhotoRepositoryのEnvironmentKey
private struct PhotoRepositoryKey: EnvironmentKey {
    static let defaultValue: any PhotoRepositoryProtocol = StubPhotoRepository()
}

/// AnalysisRepositoryのEnvironmentKey
private struct AnalysisRepositoryKey: EnvironmentKey {
    static let defaultValue: any AnalysisRepositoryProtocol = StubAnalysisRepository()
}

/// StorageRepositoryのEnvironmentKey
private struct StorageRepositoryKey: EnvironmentKey {
    static let defaultValue: any StorageRepositoryProtocol = StubStorageRepository()
}

/// SettingsRepositoryのEnvironmentKey
private struct SettingsRepositoryKey: EnvironmentKey {
    static let defaultValue: any SettingsRepositoryProtocol = StubSettingsRepository()
}

// MARK: - Individual Repository EnvironmentValues

public extension EnvironmentValues {
    /// PhotoRepositoryへの直接アクセス
    /// 使用例: @Environment(\.photoRepository) private var photoRepo
    var photoRepository: any PhotoRepositoryProtocol {
        get { self[PhotoRepositoryKey.self] }
        set { self[PhotoRepositoryKey.self] = newValue }
    }

    /// AnalysisRepositoryへの直接アクセス
    var analysisRepository: any AnalysisRepositoryProtocol {
        get { self[AnalysisRepositoryKey.self] }
        set { self[AnalysisRepositoryKey.self] = newValue }
    }

    /// StorageRepositoryへの直接アクセス
    var storageRepository: any StorageRepositoryProtocol {
        get { self[StorageRepositoryKey.self] }
        set { self[StorageRepositoryKey.self] = newValue }
    }

    /// SettingsRepositoryへの直接アクセス
    var settingsRepository: any SettingsRepositoryProtocol {
        get { self[SettingsRepositoryKey.self] }
        set { self[SettingsRepositoryKey.self] = newValue }
    }
}

// MARK: - View Extensions for Individual Repositories

public extension View {
    /// PhotoRepositoryをView階層に注入
    func withPhotoRepository(_ repository: any PhotoRepositoryProtocol) -> some View {
        environment(\.photoRepository, repository)
    }

    /// AnalysisRepositoryをView階層に注入
    func withAnalysisRepository(_ repository: any AnalysisRepositoryProtocol) -> some View {
        environment(\.analysisRepository, repository)
    }

    /// StorageRepositoryをView階層に注入
    func withStorageRepository(_ repository: any StorageRepositoryProtocol) -> some View {
        environment(\.storageRepository, repository)
    }

    /// SettingsRepositoryをView階層に注入
    func withSettingsRepository(_ repository: any SettingsRepositoryProtocol) -> some View {
        environment(\.settingsRepository, repository)
    }
}

// MARK: - Preview Support

#if DEBUG
/// Preview用のDIコンテナセットアップ
public struct DIContainerPreviewProvider {

    /// プレビュー用のモックデータを持つDIContainerを生成
    @MainActor
    public static func makePreviewContainer() -> DIContainer {
        let container = DIContainer.mock()

        // モックデータの設定
        container.setPhotoRepository {
            let repo = MockPhotoRepository()
            repo.mockPhotos = [
                PhotoAsset(id: "1", creationDate: Date(), fileSize: 1024 * 1024),
                PhotoAsset(id: "2", creationDate: Date(), fileSize: 2048 * 1024),
                PhotoAsset(id: "3", creationDate: Date(), fileSize: 512 * 1024)
            ]
            return repo
        }

        container.setStorageRepository {
            let repo = MockStorageRepository()
            repo.mockStorageInfo = StorageInfo(
                totalCapacity: 256 * 1024 * 1024 * 1024,
                usedCapacity: 180 * 1024 * 1024 * 1024,
                photosSize: 45 * 1024 * 1024 * 1024,
                reclaimableSize: 8 * 1024 * 1024 * 1024
            )
            return repo
        }

        return container
    }
}

/// Preview用のView Modifier
@MainActor
public struct PreviewDIContainerModifier: ViewModifier {
    let container: DIContainer

    public init() {
        self.container = DIContainerPreviewProvider.makePreviewContainer()
    }

    public func body(content: Content) -> some View {
        content
            .withDIContainer(container)
    }
}

public extension View {
    /// Preview用のDIContainerを設定
    @MainActor
    func withPreviewDIContainer() -> some View {
        modifier(PreviewDIContainerModifier())
    }
}
#endif
