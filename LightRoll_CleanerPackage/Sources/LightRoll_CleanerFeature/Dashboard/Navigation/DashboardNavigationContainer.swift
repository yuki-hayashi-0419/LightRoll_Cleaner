//
//  DashboardNavigationContainer.swift
//  LightRoll_CleanerFeature
//
//  ダッシュボードモジュールのナビゲーションコンテナ
//  NavigationStackとDashboardRouterを統合し、画面遷移を制御
//  MV Pattern: @Environment経由でルーターを注入
//  Created by AI Assistant
//

import SwiftUI

// MARK: - DashboardNavigationContainer

/// ダッシュボードモジュールのナビゲーションコンテナ
/// NavigationStackとルーターを統合し、HomeView → GroupListView → GroupDetailView の遷移を管理
///
/// ## 使用例
/// ```swift
/// DashboardNavigationContainer(
///     scanPhotosUseCase: scanUseCase,
///     getStatisticsUseCase: statsUseCase,
///     photoProvider: provider,
///     onNavigateToSettings: {
///         // 設定画面へ遷移
///     }
/// )
/// ```
@MainActor
public struct DashboardNavigationContainer: View {

    // MARK: - Properties

    /// 写真スキャンユースケース
    private let scanPhotosUseCase: ScanPhotosUseCase

    /// 統計取得ユースケース
    private let getStatisticsUseCase: GetStatisticsUseCase

    /// 写真プロバイダー（グループリスト・詳細で使用）
    private let photoProvider: PhotoProvider?

    /// 削除アクションのコールバック
    private let onDeletePhotos: (([String]) async -> Void)?

    /// グループ削除アクションのコールバック
    private let onDeleteGroups: (([PhotoGroup]) async -> Void)?

    /// 設定へのナビゲーションコールバック
    private let onNavigateToSettings: (() -> Void)?

    // MARK: - State

    /// ダッシュボードルーター
    @State private var router: DashboardRouter

    /// 現在のグループ一覧（スキャン結果）
    @State private var currentGroups: [PhotoGroup] = []

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - scanPhotosUseCase: 写真スキャンユースケース
    ///   - getStatisticsUseCase: 統計取得ユースケース
    ///   - photoProvider: 写真プロバイダー
    ///   - onDeletePhotos: 写真削除コールバック
    ///   - onDeleteGroups: グループ削除コールバック
    ///   - onNavigateToSettings: 設定画面への遷移コールバック
    public init(
        scanPhotosUseCase: ScanPhotosUseCase,
        getStatisticsUseCase: GetStatisticsUseCase,
        photoProvider: PhotoProvider? = nil,
        onDeletePhotos: (([String]) async -> Void)? = nil,
        onDeleteGroups: (([PhotoGroup]) async -> Void)? = nil,
        onNavigateToSettings: (() -> Void)? = nil
    ) {
        self.scanPhotosUseCase = scanPhotosUseCase
        self.getStatisticsUseCase = getStatisticsUseCase
        self.photoProvider = photoProvider
        self.onDeletePhotos = onDeletePhotos
        self.onDeleteGroups = onDeleteGroups
        self.onNavigateToSettings = onNavigateToSettings

        // ルーター初期化
        let router = DashboardRouter(onNavigateToSettings: onNavigateToSettings)
        _router = State(initialValue: router)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack(path: $router.path) {
            // ルート画面: HomeView
            HomeView(
                scanPhotosUseCase: scanPhotosUseCase,
                getStatisticsUseCase: getStatisticsUseCase,
                onNavigateToGroupList: { groupType in
                    router.navigateToGroupList(filterType: groupType)
                },
                onNavigateToSettings: {
                    router.navigateToSettings()
                }
            )
            .navigationDestination(for: DashboardDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .environment(router)
        .task {
            // スキャン結果を監視してグループ一覧を更新
            // TODO: ScanPhotosUseCaseから結果を取得する仕組みを追加
        }
    }

    // MARK: - Destination Views

    /// 遷移先のビューを生成
    @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
        switch destination {
        case .groupList:
            GroupListView(
                groups: currentGroups,
                photoProvider: photoProvider,
                initialFilterType: nil,
                onGroupTap: { group in
                    router.navigateToGroupDetail(group: group)
                },
                onDeleteGroups: onDeleteGroups,
                onBack: {
                    router.navigateBack()
                }
            )

        case .groupListFiltered(let groupType):
            GroupListView(
                groups: currentGroups,
                photoProvider: photoProvider,
                initialFilterType: groupType,
                onGroupTap: { group in
                    router.navigateToGroupDetail(group: group)
                },
                onDeleteGroups: onDeleteGroups,
                onBack: {
                    router.navigateBack()
                }
            )

        case .groupDetail(let group):
            GroupDetailView(
                group: group,
                photoProvider: photoProvider,
                onDeletePhotos: onDeletePhotos,
                onBack: {
                    router.navigateBack()
                }
            )

        case .settings:
            // 設定画面は外部モジュールのため、ここでは処理しない
            // onNavigateToSettingsコールバックで処理される
            EmptyView()
        }
    }

    // MARK: - Helper Methods

    /// グループ一覧を更新
    /// - Parameter groups: 新しいグループ一覧
    public func updateGroups(_ groups: [PhotoGroup]) {
        currentGroups = groups
    }
}

// MARK: - Preview

#if DEBUG

// Preview用のモックは別途必要に応じて追加

#Preview("ダッシュボードナビゲーション") {
    // プレビューは実装例として残すが、実際の動作確認は統合テストで実施
    Text("DashboardNavigationContainer Preview")
        .font(.headline)
        .padding()
}

#endif
