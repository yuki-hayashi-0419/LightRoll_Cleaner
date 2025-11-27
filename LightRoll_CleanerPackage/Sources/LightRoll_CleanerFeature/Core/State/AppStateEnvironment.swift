//
//  AppStateEnvironment.swift
//  LightRoll_CleanerFeature
//
//  SwiftUI環境用のAppState拡張
//  @Environment経由でAppStateにアクセス可能にする
//  Created by AI Assistant
//

import SwiftUI

// MARK: - AppState Environment Key

/// AppStateのEnvironmentKey
/// Swift 6 コンカレンシー対応版
private struct AppStateKey: EnvironmentKey {
    // AppStateはMainActorで初期化される必要があるため
    // デフォルト値としてはsharedを使用
    nonisolated(unsafe) static var defaultValue: AppState = {
        // Note: このコードはMainActorコンテキストで呼ばれることを想定
        // 実際のアプリケーションでは必ずwithAppStateで設定する
        MainActor.assumeIsolated {
            AppState.shared
        }
    }()
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    /// AppStateへのアクセス
    /// 使用例: @Environment(\.appState) private var appState
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// AppStateをView階層に注入
    /// - Parameter appState: 注入するAppState
    /// - Returns: AppStateが設定されたView
    ///
    /// 使用例:
    /// ```swift
    /// ContentView()
    ///     .withAppState(AppState.shared)
    /// ```
    func withAppState(_ appState: AppState) -> some View {
        environment(\.appState, appState)
    }

    /// デフォルトのAppStateを注入
    /// - Returns: デフォルトAppStateが設定されたView
    ///
    /// 使用例:
    /// ```swift
    /// ContentView()
    ///     .withDefaultAppState()
    /// ```
    @MainActor
    func withDefaultAppState() -> some View {
        environment(\.appState, AppState.shared)
    }
}

// MARK: - Preview Support

#if DEBUG
/// Preview用のAppStateを生成
public struct AppStatePreviewProvider {

    /// プレビュー用のモックデータを持つAppStateを生成
    @MainActor
    public static func makePreviewState() -> AppState {
        let state = AppState(forTesting: true)

        // モックデータの設定
        state.totalPhotosCount = 1234
        state.potentialSavings = 2_500_000_000 // 2.5GB
        state.isPremium = false
        state.photoPermissionGranted = true

        state.storageInfo = StorageInfo(
            totalCapacity: 256 * 1024 * 1024 * 1024,
            usedCapacity: 180 * 1024 * 1024 * 1024,
            photosSize: 45 * 1024 * 1024 * 1024,
            reclaimableSize: 8 * 1024 * 1024 * 1024
        )

        state.scanResult = ScanResult(
            totalPhotosScanned: 1234,
            groupsFound: 42,
            potentialSavings: 2_500_000_000,
            duration: 45.5,
            timestamp: Date().addingTimeInterval(-3600),
            groupBreakdown: GroupBreakdown(
                similarGroups: 15,
                selfieGroups: 8,
                screenshotCount: 120,
                blurryCount: 25,
                largeVideoCount: 5
            )
        )

        state.photoGroups = [
            PhotoGroup(
                id: UUID(),
                type: .similar,
                photos: [
                    PhotoAsset(id: "1", creationDate: Date(), fileSize: 1024 * 1024),
                    PhotoAsset(id: "2", creationDate: Date(), fileSize: 2048 * 1024),
                    PhotoAsset(id: "3", creationDate: Date(), fileSize: 512 * 1024)
                ],
                bestShotIndex: 0,
                totalSize: 3_584 * 1024
            ),
            PhotoGroup(
                id: UUID(),
                type: .screenshot,
                photos: [
                    PhotoAsset(id: "4", creationDate: Date(), fileSize: 256 * 1024),
                    PhotoAsset(id: "5", creationDate: Date(), fileSize: 256 * 1024)
                ],
                bestShotIndex: nil,
                totalSize: 512 * 1024
            )
        ]

        return state
    }

    /// スキャン中状態のプレビュー用AppStateを生成
    @MainActor
    public static func makeScanningState() -> AppState {
        let state = AppState(forTesting: true)
        state.isScanning = true
        state.scanProgress = ScanProgress(
            phase: .analyzing,
            progress: 0.45,
            processedCount: 450,
            totalCount: 1000,
            currentTask: "写真を分析中..."
        )
        return state
    }

    /// プレミアムユーザー状態のプレビュー用AppStateを生成
    @MainActor
    public static func makePremiumState() -> AppState {
        let state = makePreviewState()
        state.isPremium = true
        return state
    }

    /// エラー状態のプレビュー用AppStateを生成
    @MainActor
    public static func makeErrorState() -> AppState {
        let state = AppState(forTesting: true)
        state.errorMessage = "写真ライブラリへのアクセスが拒否されました"
        state.photoPermissionGranted = false
        return state
    }
}

/// Preview用のView Modifier
@MainActor
public struct PreviewAppStateModifier: ViewModifier {
    let appState: AppState

    public init(appState: AppState? = nil) {
        self.appState = appState ?? AppStatePreviewProvider.makePreviewState()
    }

    public func body(content: Content) -> some View {
        content
            .withAppState(appState)
    }
}

public extension View {
    /// Preview用のAppStateを設定
    @MainActor
    func withPreviewAppState(_ state: AppState? = nil) -> some View {
        modifier(PreviewAppStateModifier(appState: state))
    }

    /// スキャン中状態のPreview用AppStateを設定
    @MainActor
    func withScanningPreviewState() -> some View {
        modifier(PreviewAppStateModifier(appState: AppStatePreviewProvider.makeScanningState()))
    }

    /// プレミアム状態のPreview用AppStateを設定
    @MainActor
    func withPremiumPreviewState() -> some View {
        modifier(PreviewAppStateModifier(appState: AppStatePreviewProvider.makePremiumState()))
    }

    /// エラー状態のPreview用AppStateを設定
    @MainActor
    func withErrorPreviewState() -> some View {
        modifier(PreviewAppStateModifier(appState: AppStatePreviewProvider.makeErrorState()))
    }
}
#endif

// MARK: - Combine Extensions

import Combine

public extension AppState {

    /// 特定のプロパティの変更を監視するPublisher
    /// - Parameter keyPath: 監視するプロパティのKeyPath
    /// - Returns: 値変更のPublisher
    func publisher<T>(for keyPath: KeyPath<AppState, T>) -> AnyPublisher<T, Never> {
        objectWillChange
            .map { [weak self] _ in
                self?[keyPath: keyPath]
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

// MARK: - ObservableObject Binding Helper

public extension AppState {

    /// エラーメッセージのBinding
    var errorBinding: Binding<String?> {
        Binding(
            get: { self.errorMessage },
            set: { self.errorMessage = $0 }
        )
    }

    /// 削除確認表示のBinding
    var showDeleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { self.showingDeleteConfirmation },
            set: { self.showingDeleteConfirmation = $0 }
        )
    }

    /// アラート表示のBinding
    var showAlertBinding: Binding<Bool> {
        Binding(
            get: { self.showingAlert },
            set: { self.showingAlert = $0 }
        )
    }

    /// プレミアムアップグレード表示のBinding
    var showPremiumUpgradeBinding: Binding<Bool> {
        Binding(
            get: { self.showingPremiumUpgrade },
            set: { self.showingPremiumUpgrade = $0 }
        )
    }

    /// 現在のタブのBinding
    var currentTabBinding: Binding<Tab> {
        Binding(
            get: { self.currentTab },
            set: { self.currentTab = $0 }
        )
    }
}
