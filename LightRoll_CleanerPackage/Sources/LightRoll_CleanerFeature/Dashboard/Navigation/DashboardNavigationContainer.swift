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

// MARK: - Notification Extensions

extension Notification.Name {
    /// グループ読み込み失敗時の通知
    static let groupLoadFailure = Notification.Name("groupLoadFailure")
}

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
                onNavigateToGroupList: { @MainActor groupType in
                    print("🟢 [DEBUG] DashboardNavigationContainer: onNavigateToGroupList called with groupType: \(String(describing: groupType))")
                    print("🟢 [DEBUG] DashboardNavigationContainer: Current groups count: \(currentGroups.count)")
                    // グループはtask修飾子で既に読み込まれているので、直接遷移
                    router.navigateToGroupList(filterType: groupType)
                    print("🟢 [DEBUG] DashboardNavigationContainer: router.navigateToGroupList completed")
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
            // 初回起動時に保存されているグループを読み込み
            await loadGroups()
        }
    }

    // MARK: - Helper Methods (private)

    /// グループを読み込む
    private func loadGroups() async {
        // 保存されているグループを読み込み
        if await scanPhotosUseCase.hasSavedGroups() {
            do {
                currentGroups = try await scanPhotosUseCase.loadSavedGroups()
                print("✅ グループ読み込み成功: \(currentGroups.count)件")
            } catch {
                print("⚠️ グループ読み込みエラー: \(error)")
                currentGroups = []

                // ユーザーへのエラー通知
                Task { @MainActor in
                    NotificationCenter.default.post(
                        name: .groupLoadFailure,
                        object: nil,
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        } else {
            print("ℹ️ 保存済みグループなし")
            currentGroups = []
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

    /// グループ一覧を更新（外部から呼び出し可能）
    /// - Parameter groups: 新しいグループ一覧
    public func updateGroups(_ groups: [PhotoGroup]) {
        currentGroups = groups
        print("📝 グループ更新: \(groups.count)件")
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
