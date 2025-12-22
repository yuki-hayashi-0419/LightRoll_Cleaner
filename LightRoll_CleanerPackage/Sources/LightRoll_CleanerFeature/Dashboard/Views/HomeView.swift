//
//  HomeView.swift
//  LightRoll_CleanerFeature
//
//  ダッシュボードのメインビュー
//  ストレージ統計、グループサマリー、クリーンアップ履歴を表示
//  MV Pattern: ViewModelなし、@Stateで状態管理
//  Created by AI Assistant
//

import SwiftUI

// MARK: - HomeView

/// ダッシュボードのメインビュー
/// ストレージ統計、写真グループ、クリーンアップ履歴を表示し、スキャン機能を提供
///
/// ## 主な機能
/// - ストレージ使用状況の表示（StorageOverviewCard）
/// - スキャン実行と進捗表示
/// - 最近のクリーンアップ履歴表示
/// - グループタップでグループリストへ遷移
///
/// ## 使用例
/// ```swift
/// HomeView(
///     scanPhotosUseCase: scanUseCase,
///     getStatisticsUseCase: statsUseCase
/// )
/// .environment(router)
/// ```
@MainActor
public struct HomeView: View {

    // MARK: - Properties

    /// 写真スキャンユースケース
    private let scanPhotosUseCase: ScanPhotosUseCase

    /// 統計取得ユースケース
    private let getStatisticsUseCase: GetStatisticsUseCase

    /// グループリストへのナビゲーション
    private let onNavigateToGroupList: ((GroupType?) -> Void)?

    /// 設定へのナビゲーション
    private let onNavigateToSettings: (() -> Void)?

    // MARK: - State

    /// 写真権限マネージャー
    @State private var permissionManager = PhotoPermissionManager()

    /// ビューの状態
    @State private var viewState: ViewState = .loading

    /// ストレージ統計
    @State private var statistics: StorageStatistics?

    /// スキャン結果のグループ
    @State private var photoGroups: [PhotoGroup] = []

    /// クリーンアップ履歴
    @State private var cleanupHistory: [CleanupRecord] = []

    /// スキャン進捗
    @State private var scanProgress: ScanProgress?

    /// エラーアラート表示フラグ
    @State private var showErrorAlert: Bool = false

    /// エラーメッセージ
    @State private var errorMessage: String = ""

    /// スキャン完了トースト表示フラグ
    @State private var showScanCompleteToast: Bool = false

    /// 最後のスキャン結果
    @State private var lastScanResult: ScanResult?

    /// 初期データ読み込み済みフラグ（タブ切り替え時の不要な再読み込みを防止）
    @State private var hasLoadedInitialData: Bool = false

    // MARK: - ViewState

    /// ビューの状態を表す列挙型
    public enum ViewState: Sendable, Equatable {
        /// 読み込み中
        case loading
        /// 読み込み完了
        case loaded
        /// スキャン中（進捗付き）
        case scanning(progress: Double)
        /// エラー発生
        case error(String)

        /// スキャン中かどうか
        var isScanning: Bool {
            if case .scanning = self {
                return true
            }
            return false
        }

        /// 読み込み中かどうか
        var isLoading: Bool {
            self == .loading
        }
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - scanPhotosUseCase: 写真スキャンユースケース
    ///   - getStatisticsUseCase: 統計取得ユースケース
    ///   - onNavigateToGroupList: グループリストへのナビゲーションコールバック
    ///   - onNavigateToSettings: 設定へのナビゲーションコールバック
    public init(
        scanPhotosUseCase: ScanPhotosUseCase,
        getStatisticsUseCase: GetStatisticsUseCase,
        onNavigateToGroupList: ((GroupType?) -> Void)? = nil,
        onNavigateToSettings: (() -> Void)? = nil
    ) {
        self.scanPhotosUseCase = scanPhotosUseCase
        self.getStatisticsUseCase = getStatisticsUseCase
        self.onNavigateToGroupList = onNavigateToGroupList
        self.onNavigateToSettings = onNavigateToSettings
    }

    // MARK: - Body

    public var body: some View {
        // 注意: NavigationStackを削除
        // このビューはDashboardNavigationContainerのNavigationStack内で
        // 表示されるため、独自のNavigationStackを持つと入れ子になりクラッシュする
        ZStack {
            // 背景グラデーション
            backgroundGradient

            // メインコンテンツ
            mainContent

            // バナー広告（画面下部に固定）
            VStack {
                Spacer()
                BannerAdView()
            }
        }
        .navigationTitle(NSLocalizedString(
            "home.title",
            value: "ホーム",
            comment: "Home screen title"
        ))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            toolbarContent
        }
        .task(id: hasLoadedInitialData) {
            // 初回のみデータ読み込み（タブ切り替え時の不要な再読み込みを防止）
            guard !hasLoadedInitialData else { return }
            await loadInitialData()
            hasLoadedInitialData = true
        }
        .refreshable {
            await refreshData()
        }
        .alert(
            NSLocalizedString(
                "home.error.title",
                value: "エラー",
                comment: "Error alert title"
            ),
            isPresented: $showErrorAlert
        ) {
            Button(NSLocalizedString(
                "common.ok",
                value: "OK",
                comment: "OK button"
            )) {
                showErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            // スキャン中のプログレスオーバーレイ
            if let progress = scanProgress, viewState.isScanning {
                ProgressOverlay(
                    progress: progress.progress,
                    message: progress.currentTask.isEmpty
                        ? NSLocalizedString(
                            "scan.progress.scanning",
                            value: "スキャン中...",
                            comment: "Scanning progress message"
                          )
                        : progress.currentTask,
                    detail: progressDetailText(for: progress),
                    showCancelButton: true,
                    onCancel: { @MainActor in
                        cancelScan()
                    }
                )
            }
        }
    }

    // MARK: - View Components

    /// 背景グラデーション
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.LightRoll.background,
                Color.LightRoll.surfaceCard.opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// メインコンテンツ
    @ViewBuilder
    private var mainContent: some View {
        switch viewState {
        case .loading:
            loadingView

        case .loaded, .scanning:
            loadedContent

        case .error(let message):
            errorView(message: message)
        }
    }

    /// 読み込み中ビュー
    private var loadingView: some View {
        VStack(spacing: LRSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text(NSLocalizedString(
                "home.loading",
                value: "読み込み中...",
                comment: "Loading message"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 読み込み完了後のコンテンツ
    private var loadedContent: some View {
        ScrollView {
            VStack(spacing: LRSpacing.lg) {
                // ストレージオーバービューカード
                storageOverviewSection

                // クイックアクションセクション
                quickActionsSection

                // 最近のクリーンアップ履歴
                if !cleanupHistory.isEmpty {
                    recentCleanupSection
                }

                // スキャン結果サマリー（スキャン完了時）
                if let result = lastScanResult {
                    scanResultSection(result: result)
                }

                // 下部スペーサー
                Spacer()
                    .frame(height: LRSpacing.xxl)
            }
            .padding(.horizontal, LRSpacing.md)
            .padding(.top, LRSpacing.sm)
        }
    }

    /// ストレージオーバービューセクション
    private var storageOverviewSection: some View {
        Group {
            if let stats = statistics {
                StorageOverviewCard(
                    statistics: stats,
                    displayStyle: .full,
                    onScanTap: {
                        await startScan()
                    },
                    onGroupTap: { groupType in
                        onNavigateToGroupList?(groupType)
                    }
                )
            } else {
                // 統計未取得時のプレースホルダー
                StorageOverviewCard(
                    statistics: .empty,
                    displayStyle: .full,
                    onScanTap: {
                        await startScan()
                    },
                    onGroupTap: nil
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(NSLocalizedString(
            "home.storageOverview.accessibilityLabel",
            value: "ストレージ概要",
            comment: "Storage overview accessibility label"
        ))
    }

    /// クイックアクションセクション
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            // セクションヘッダー
            Text(NSLocalizedString(
                "home.quickActions.title",
                value: "クイックアクション",
                comment: "Quick actions section title"
            ))
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, LRSpacing.xs)

            // アクションボタン群
            HStack(spacing: LRSpacing.md) {
                // スキャンボタン
                ActionButton(
                    title: NSLocalizedString(
                        "home.action.scan",
                        value: "スキャン",
                        comment: "Scan button title"
                    ),
                    icon: "magnifyingglass",
                    style: .primary,
                    isDisabled: viewState.isScanning,
                    isLoading: viewState.isScanning
                ) {
                    await startScan()
                }

                // グループ一覧ボタン
                ActionButton(
                    title: NSLocalizedString(
                        "home.action.groups",
                        value: "グループ",
                        comment: "Groups button title"
                    ),
                    icon: "rectangle.stack",
                    style: .secondary,
                    isDisabled: viewState.isScanning || photoGroups.isEmpty
                ) { @MainActor in
                    onNavigateToGroupList?(nil)
                }
            }
        }
        .padding(LRSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG))
    }

    /// 最近のクリーンアップセクション
    private var recentCleanupSection: some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            // セクションヘッダー
            HStack {
                Text(NSLocalizedString(
                    "home.recentCleanup.title",
                    value: "最近のクリーンアップ",
                    comment: "Recent cleanup section title"
                ))
                .font(.headline)
                .foregroundStyle(.primary)

                Spacer()

                // 全件表示ボタン（履歴が多い場合）
                if cleanupHistory.count > 3 {
                    Button {
                        // 履歴一覧へのナビゲーション（将来実装）
                    } label: {
                        Text(NSLocalizedString(
                            "home.recentCleanup.showAll",
                            value: "すべて表示",
                            comment: "Show all button"
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, LRSpacing.xs)

            // 履歴リスト（最新3件）
            VStack(spacing: LRSpacing.xs) {
                ForEach(cleanupHistory.prefix(3)) { record in
                    CleanupHistoryRow(record: record)
                }
            }
        }
        .padding(LRSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG))
    }

    /// スキャン結果セクション
    private func scanResultSection(result: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            // セクションヘッダー
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text(NSLocalizedString(
                    "home.scanResult.title",
                    value: "スキャン完了",
                    comment: "Scan result section title"
                ))
                .font(.headline)
            }
            .padding(.horizontal, LRSpacing.xs)

            // 結果サマリー
            VStack(spacing: LRSpacing.sm) {
                ResultRow(
                    icon: "photo.stack",
                    label: NSLocalizedString(
                        "home.scanResult.photosScanned",
                        value: "スキャン済み",
                        comment: "Photos scanned label"
                    ),
                    value: "\(result.totalPhotosScanned)枚"
                )

                ResultRow(
                    icon: "rectangle.stack",
                    label: NSLocalizedString(
                        "home.scanResult.groupsFound",
                        value: "グループ検出",
                        comment: "Groups found label"
                    ),
                    value: "\(result.groupsFound)件"
                )

                ResultRow(
                    icon: "arrow.down.circle",
                    label: NSLocalizedString(
                        "home.scanResult.potentialSavings",
                        value: "削減可能",
                        comment: "Potential savings label"
                    ),
                    value: result.formattedPotentialSavings
                )

                ResultRow(
                    icon: "clock",
                    label: NSLocalizedString(
                        "home.scanResult.duration",
                        value: "所要時間",
                        comment: "Duration label"
                    ),
                    value: result.formattedDuration
                )
            }
            .padding(.vertical, LRSpacing.xs)

            // グループ詳細ボタン
            if result.groupsFound > 0 {
                ActionButton(
                    title: NSLocalizedString(
                        "home.scanResult.viewGroups",
                        value: "グループを確認",
                        comment: "View groups button"
                    ),
                    icon: "arrow.right.circle",
                    style: .primary
                ) { @MainActor in
                    onNavigateToGroupList?(nil)
                }
            }
        }
        .padding(LRSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG))
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }

    /// エラービュー
    private func errorView(message: String) -> some View {
        EmptyStateView(
            type: .error,
            customMessage: message,
            actionTitle: NSLocalizedString(
                "home.error.retry",
                value: "再読み込み",
                comment: "Retry button"
            ),
            onAction: {
                await loadInitialData()
            }
        )
    }

    /// ツールバーコンテンツ
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                onNavigateToSettings?()
            } label: {
                Image(systemName: "gearshape")
                    .accessibilityLabel(NSLocalizedString(
                        "home.settings.accessibilityLabel",
                        value: "設定",
                        comment: "Settings button accessibility label"
                    ))
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            Button {
                onNavigateToSettings?()
            } label: {
                Image(systemName: "gearshape")
                    .accessibilityLabel(NSLocalizedString(
                        "home.settings.accessibilityLabel",
                        value: "設定",
                        comment: "Settings button accessibility label"
                    ))
            }
        }
        #endif
    }

    // MARK: - Helper Methods

    /// 進捗詳細テキストを生成
    private func progressDetailText(for progress: ScanProgress) -> String? {
        guard progress.processedCount > 0, progress.totalCount > 0 else {
            return nil
        }
        return "\(progress.processedCount) / \(progress.totalCount)"
    }

    /// 保存されたグループからScanResultを生成
    private func createScanResultFromGroups(_ groups: [PhotoGroup]) -> ScanResult {
        // グループタイプ別の内訳を計算
        let groupedByType = Dictionary(grouping: groups) { $0.type }

        let breakdown = GroupBreakdown(
            similarGroups: groupedByType[.similar]?.count ?? 0,
            screenshotCount: groupedByType[.screenshot]?.reduce(0) { $0 + $1.count } ?? 0,
            blurryCount: groupedByType[.blurry]?.reduce(0) { $0 + $1.count } ?? 0,
            largeVideoCount: groupedByType[.largeVideo]?.reduce(0) { $0 + $1.count } ?? 0
        )

        // 削減可能容量を計算
        let potentialSavings = groups.reduce(0) { $0 + $1.reclaimableSize }

        // 総写真数を計算
        let totalPhotosScanned = groups.reduce(0) { $0 + $1.count }

        return ScanResult(
            totalPhotosScanned: totalPhotosScanned,
            groupsFound: groups.count,
            potentialSavings: potentialSavings,
            duration: 0, // 復元時は所要時間不明
            groupBreakdown: breakdown
        )
    }

    // MARK: - Data Loading

    /// 初期データを読み込み
    private func loadInitialData() async {
        viewState = .loading

        // 写真ライブラリへのアクセス許可をリクエスト
        let status = permissionManager.checkPermissionStatus()
        if status == .notDetermined {
            // 未決定の場合は権限をリクエスト
            _ = await permissionManager.requestPermission()
        }

        do {
            let output = try await getStatisticsUseCase.execute()

            // StorageStatisticsに変換
            statistics = StorageStatistics(
                storageInfo: output.storageInfo,
                groupSummaries: [:], // グループサマリーはスキャン後に更新
                scannedPhotoCount: output.totalPhotos
            )

            // 保存されているグループを読み込み
            if await scanPhotosUseCase.hasSavedGroups() {
                do {
                    photoGroups = try await scanPhotosUseCase.loadSavedGroups()

                    // グループが読み込めたら最終スキャン結果を復元
                    if !photoGroups.isEmpty {
                        lastScanResult = createScanResultFromGroups(photoGroups)
                    }
                } catch {
                    // グループ読み込みエラーはログに記録（UI表示には影響しない）
                    #if DEBUG
                    print("⚠️ 保存済みグループの読み込みに失敗: \(error.localizedDescription)")
                    #endif

                    // ユーザーへのエラー通知
                    errorMessage = NSLocalizedString(
                        "home.error.groupLoadFailure",
                        value: "グループの読み込みに失敗しました。もう一度お試しください。",
                        comment: "Group load failure error message"
                    )
                    showErrorAlert = true
                }
            }

            // TODO: クリーンアップ履歴の読み込み（CleanupRecordRepository実装後）
            cleanupHistory = []

            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    /// データを更新（プルトゥリフレッシュ）
    private func refreshData() async {
        // スキャン中は更新しない
        guard !viewState.isScanning else { return }

        do {
            let output = try await getStatisticsUseCase.execute()

            statistics = StorageStatistics(
                storageInfo: output.storageInfo,
                groupSummaries: statistics?.groupSummaries ?? [:],
                scannedPhotoCount: output.totalPhotos
            )
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Scan Operations

    /// スキャンを開始
    private func startScan() async {
        // 既にスキャン中の場合は何もしない
        guard !scanPhotosUseCase.isScanning else { return }

        viewState = .scanning(progress: 0)
        lastScanResult = nil

        // 進捗監視タスク
        let progressTask = Task {
            for await progress in scanPhotosUseCase.progressStream {
                scanProgress = progress
                viewState = .scanning(progress: progress.progress)
            }
        }

        do {
            let result = try await scanPhotosUseCase.execute()

            // progressTaskの完了を待つ（レースコンディション回避）
            progressTask.cancel()
            _ = await progressTask.result  // 完了を待機（成功/失敗を無視）

            // スキャン完了後にグループを読み込む
            lastScanResult = result

            // グループを読み込み
            do {
                photoGroups = try await scanPhotosUseCase.loadSavedGroups()
                #if DEBUG
                print("✅ グループ読み込み成功: \(photoGroups.count)件")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ グループ読み込みエラー: \(error)")
                #endif

                // ユーザーへのエラー通知
                errorMessage = NSLocalizedString(
                    "home.error.groupLoadFailure",
                    value: "グループの読み込みに失敗しました。もう一度お試しください。",
                    comment: "Group load failure error message"
                )
                showErrorAlert = true
            }

            // 統計を更新
            await refreshData()

            viewState = .loaded
            scanProgress = nil  // タスク完了後に状態をクリア
            showScanCompleteToast = true

            // 3秒後にトーストを非表示
            try? await Task.sleep(for: .seconds(3))
            showScanCompleteToast = false
        } catch {
            // エラー時もprogressTaskの完了を待つ
            progressTask.cancel()
            _ = await progressTask.result

            if case ScanPhotosUseCaseError.scanCancelled = error {
                // キャンセルは正常終了
                viewState = .loaded
            } else {
                errorMessage = error.localizedDescription
                showErrorAlert = true
                viewState = .loaded
            }
            scanProgress = nil  // エラー時も状態をクリア
        }
    }

    /// スキャンをキャンセル
    private func cancelScan() {
        scanPhotosUseCase.cancel()
        viewState = .loaded
        scanProgress = nil
    }
}

// MARK: - CleanupHistoryRow

/// クリーンアップ履歴の行
@MainActor
struct CleanupHistoryRow: View {

    let record: CleanupRecord

    var body: some View {
        HStack(spacing: LRSpacing.md) {
            // アイコン
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1), in: Circle())

            // 情報
            VStack(alignment: .leading, spacing: 2) {
                Text(record.summary)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 削減容量
            Text(record.formattedFreedSpace)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        }
        .padding(LRSpacing.sm)
        .background(Color.LightRoll.surfaceCard.opacity(0.5), in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusMD))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.detailedSummary)
    }

    /// アイコン名
    private var iconName: String {
        switch record.operationType {
        case .manual:
            return "hand.tap"
        case .quickClean:
            return "bolt"
        case .bulkDelete:
            return "trash"
        case .automatic:
            return "clock.arrow.circlepath"
        }
    }

    /// アイコン色
    private var iconColor: Color {
        switch record.operationType {
        case .manual:
            return .blue
        case .quickClean:
            return .orange
        case .bulkDelete:
            return .red
        case .automatic:
            return .purple
        }
    }
}

// MARK: - ResultRow

/// スキャン結果の行
@MainActor
struct ResultRow: View {

    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG

/// プレビュー用のローディング状態表示
struct HomeViewLoadingPreview: View {
    var body: some View {
        ZStack {
            Color.LightRoll.background
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("読み込み中...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// プレビュー用のエラー状態表示
struct HomeViewErrorPreview: View {
    var body: some View {
        ZStack {
            Color.LightRoll.background
            EmptyStateView(
                type: .error,
                customMessage: "データの読み込みに失敗しました",
                actionTitle: "再読み込み",
                onAction: {
                    // Retry action
                }
            )
        }
    }
}

/// プレビュー用のクリーンアップ履歴行表示
struct CleanupHistoryRowPreview: View {
    var body: some View {
        let record = CleanupRecord(
            deletedCount: 15,
            freedSpace: 1_500_000_000,
            groupType: .similar,
            operationType: .quickClean
        )

        VStack(spacing: 12) {
            CleanupHistoryRow(record: record)

            CleanupHistoryRow(record: CleanupRecord(
                deletedCount: 30,
                freedSpace: 3_000_000_000,
                groupType: .screenshot,
                operationType: .bulkDelete
            ))

            CleanupHistoryRow(record: CleanupRecord(
                deletedCount: 5,
                freedSpace: 500_000_000,
                groupType: .blurry,
                operationType: .manual
            ))
        }
        .padding()
        .background(Color.LightRoll.background)
    }
}

/// プレビュー用の結果行表示
struct ResultRowPreview: View {
    var body: some View {
        VStack(spacing: 8) {
            ResultRow(icon: "photo.stack", label: "スキャン済み", value: "1,000枚")
            ResultRow(icon: "rectangle.stack", label: "グループ検出", value: "25件")
            ResultRow(icon: "arrow.down.circle", label: "削減可能", value: "2.5 GB")
            ResultRow(icon: "clock", label: "所要時間", value: "5秒")
        }
        .padding()
        .background(Color.LightRoll.background)
    }
}

#Preview("HomeView - Loading") {
    HomeViewLoadingPreview()
}

#Preview("HomeView - Error") {
    HomeViewErrorPreview()
}

#Preview("CleanupHistoryRow") {
    CleanupHistoryRowPreview()
}

#Preview("ResultRow") {
    ResultRowPreview()
}

#endif
