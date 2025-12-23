//
//  GroupDetailView.swift
//  LightRoll_CleanerFeature
//
//  グループ詳細ビュー
//  グループ内の写真一覧を表示し、選択・削除機能を提供
//  MV Pattern: ViewModelなし、@Stateで状態管理
//  Created by AI Assistant
//

import SwiftUI

// MARK: - GroupDetailView

/// グループ詳細ビュー
/// グループ内の写真を一覧表示し、選択・削除機能を提供
///
/// ## 主な機能
/// - グループ内の写真一覧をグリッド表示
/// - 複数選択モード
/// - 選択した写真の削除
/// - ベストショット表示
/// - 全選択/全解除機能
///
/// ## 使用例
/// ```swift
/// GroupDetailView(
///     group: photoGroup,
///     photoProvider: provider,
///     onDeletePhotos: { photos in
///         // 削除処理
///     }
/// )
/// ```
@MainActor
public struct GroupDetailView: View {

    // MARK: - Properties

    /// 表示するグループ
    private let group: PhotoGroup

    /// 写真プロバイダー（写真データ取得用）
    private let photoProvider: PhotoProvider?

    /// 削除アクションのコールバック
    private let onDeletePhotos: (([String]) async -> Void)?

    /// PremiumManager（削除制限チェック用）
    private let premiumManager: PremiumManager?

    // MARK: - State

    /// ビューの状態
    @State private var viewState: ViewState = .loading

    /// 読み込んだ写真データ
    @State private var photos: [Photo] = []

    /// 選択中の写真ID
    @State private var selectedPhotoIds: Set<String> = []

    /// 選択モード有効フラグ
    @State private var isSelectionModeActive: Bool = false

    /// 削除確認ダイアログ表示フラグ
    @State private var showDeleteConfirmation: Bool = false

    /// グループ全削除確認ダイアログ表示フラグ
    @State private var showDeleteAllConfirmation: Bool = false

    /// 削除上限到達シート表示フラグ（M9-T13で使用）
    @State private var showLimitReachedSheet: Bool = false

    /// エラーアラート表示フラグ
    @State private var showErrorAlert: Bool = false

    /// エラーメッセージ
    @State private var errorMessage: String = ""

    // MARK: - ViewState

    /// ビューの状態を表す列挙型
    public enum ViewState: Sendable, Equatable {
        /// 読み込み中
        case loading
        /// 読み込み完了
        case loaded
        /// 処理中（削除等）
        case processing
        /// エラー発生
        case error(String)
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - group: 表示するグループ
    ///   - photoProvider: 写真プロバイダー
    ///   - premiumManager: PremiumManager（削除制限チェック用）
    ///   - onDeletePhotos: 削除アクションのコールバック
    public init(
        group: PhotoGroup,
        photoProvider: PhotoProvider? = nil,
        premiumManager: PremiumManager? = nil,
        onDeletePhotos: (([String]) async -> Void)? = nil
    ) {
        self.group = group
        self.photoProvider = photoProvider
        self.premiumManager = premiumManager
        self.onDeletePhotos = onDeletePhotos
    }

    // MARK: - Body

    public var body: some View {
        // 注意: NavigationStackを削除
        // このビューはDashboardNavigationContainerのnavigationDestinationから
        // 表示されるため、独自のNavigationStackを持つと入れ子になりクラッシュする
        ZStack {
            // 背景グラデーション
            backgroundGradient

            // メインコンテンツ
            mainContent
        }
        .navigationTitle(group.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            toolbarContent
        }
        .task {
            await loadPhotos()
        }
        .alert(
            NSLocalizedString(
                "groupDetail.error.title",
                value: "エラー",
                comment: "Error alert title"
            ),
            isPresented: $showErrorAlert
        ) {
            Button(NSLocalizedString("common.ok", value: "OK", comment: "OK button")) {
                showErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            NSLocalizedString(
                "groupDetail.delete.title",
                value: "選択した写真を削除",
                comment: "Delete confirmation title"
            ),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                NSLocalizedString(
                    "groupDetail.delete.confirm",
                    value: "削除する",
                    comment: "Delete confirm button"
                ),
                role: .destructive
            ) {
                Task {
                    await deleteSelectedPhotos()
                }
            }

            Button(
                NSLocalizedString("common.cancel", value: "キャンセル", comment: "Cancel button"),
                role: .cancel
            ) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
        .confirmationDialog(
            NSLocalizedString(
                "groupDetail.deleteAll.title",
                value: "グループ全体を削除",
                comment: "Delete all confirmation title"
            ),
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                NSLocalizedString(
                    "groupDetail.deleteAll.confirm",
                    value: "すべて削除する",
                    comment: "Delete all confirm button"
                ),
                role: .destructive
            ) {
                Task {
                    await deleteAllPhotos()
                }
            }

            Button(
                NSLocalizedString("common.cancel", value: "キャンセル", comment: "Cancel button"),
                role: .cancel
            ) {}
        } message: {
            Text(deleteAllConfirmationMessage)
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

        case .loaded, .processing:
            if photos.isEmpty {
                emptyStateView
            } else {
                photoListContent
            }

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
                "groupDetail.loading",
                value: "読み込み中...",
                comment: "Loading message"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 写真リストコンテンツ
    private var photoListContent: some View {
        VStack(spacing: 0) {
            // サマリーヘッダー
            summaryHeader

            // 写真グリッド
            PhotoGrid(
                photos: photos,
                columns: 3,
                selectedPhotos: $selectedPhotoIds,
                bestShotPhotos: bestShotPhotoIds
            )

            // 選択モード時の一括操作バー
            if !selectedPhotoIds.isEmpty {
                selectionActionBar
            }
        }
    }

    /// サマリーヘッダー
    private var summaryHeader: some View {
        HStack(spacing: LRSpacing.lg) {
            // グループタイプアイコン
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: group.type.icon)
                    .font(.title2)
                    .foregroundStyle(Color.LightRoll.primary)

                Text(group.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            // 写真数
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(
                    "groupDetail.summary.photos",
                    value: "写真数",
                    comment: "Photos count label"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("\(group.count)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Divider()
                .frame(height: 40)

            // 削減可能サイズ
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(
                    "groupDetail.summary.reclaimable",
                    value: "削減可能",
                    comment: "Reclaimable size label"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(group.formattedReclaimableSize)
                    .font(.headline)
                    .foregroundStyle(Color.LightRoll.success)
            }

            Spacer()
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThinMaterial)
    }

    /// 選択アクションバー
    private var selectionActionBar: some View {
        HStack(spacing: LRSpacing.lg) {
            // 選択件数表示
            Text(String(format: NSLocalizedString(
                "groupDetail.selected.count",
                value: "%d枚選択中",
                comment: "Selected count"
            ), selectedPhotoIds.count))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            // 全選択/全解除
            Button {
                toggleSelectAll()
            } label: {
                Text(selectedPhotoIds.count == selectablePhotoIds.count
                    ? NSLocalizedString("groupDetail.deselectAll", value: "全解除", comment: "Deselect all")
                    : NSLocalizedString("groupDetail.selectAll", value: "全選択", comment: "Select all"))
                .font(.subheadline)
            }

            // 削除ボタン
            Button(role: .destructive) {
                Task {
                    await checkDeletionLimitAndShowConfirmation()
                }
            } label: {
                HStack(spacing: LRSpacing.xs) {
                    Image(systemName: "trash")
                    Text(NSLocalizedString("groupDetail.delete", value: "削除", comment: "Delete button"))
                }
            }
            .disabled(selectedPhotoIds.isEmpty)
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThickMaterial)
    }

    /// 空状態ビュー
    private var emptyStateView: some View {
        EmptyStateView(
            type: .empty,
            customIcon: "photo",
            customTitle: NSLocalizedString(
                "groupDetail.empty.title",
                value: "写真がありません",
                comment: "No photos title"
            ),
            customMessage: NSLocalizedString(
                "groupDetail.empty.message",
                value: "このグループに写真が見つかりませんでした",
                comment: "No photos message"
            )
        )
    }

    /// エラービュー
    private func errorView(message: String) -> some View {
        EmptyStateView(
            type: .error,
            customMessage: message,
            actionTitle: NSLocalizedString(
                "groupDetail.error.retry",
                value: "再読み込み",
                comment: "Retry button"
            ),
            onAction: { @MainActor @Sendable in
                Task {
                    await loadPhotos()
                }
            }
        )
    }

    /// ツールバーコンテンツ
    /// NavigationStackの自動バックボタンを使用するため、カスタムバックボタンは不要
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: LRSpacing.sm) {
                // 選択モードトグルボタン
                if !isSelectionModeActive {
                    Button {
                        toggleSelectionMode()
                    } label: {
                        Text(NSLocalizedString("groupDetail.select", value: "選択", comment: "Select button"))
                    }
                } else {
                    Button {
                        toggleSelectionMode()
                    } label: {
                        Text(NSLocalizedString("common.done", value: "完了", comment: "Done button"))
                    }
                }

                // グループ全削除ボタン
                Menu {
                    Button(role: .destructive) {
                        Task {
                            await checkDeletionLimitForAllPhotos()
                        }
                    } label: {
                        Label(
                            NSLocalizedString("groupDetail.deleteAll", value: "すべて削除", comment: "Delete all button"),
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(NSLocalizedString("common.more", value: "その他", comment: "More button"))
                }
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            HStack(spacing: LRSpacing.sm) {
                // 選択モードトグルボタン
                if !isSelectionModeActive {
                    Button {
                        toggleSelectionMode()
                    } label: {
                        Text(NSLocalizedString("groupDetail.select", value: "選択", comment: "Select button"))
                    }
                } else {
                    Button {
                        toggleSelectionMode()
                    } label: {
                        Text(NSLocalizedString("common.done", value: "完了", comment: "Done button"))
                    }
                }

                // グループ全削除ボタン
                Menu {
                    Button(role: .destructive) {
                        Task {
                            await checkDeletionLimitForAllPhotos()
                        }
                    } label: {
                        Label(
                            NSLocalizedString("groupDetail.deleteAll", value: "すべて削除", comment: "Delete all button"),
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(NSLocalizedString("common.more", value: "その他", comment: "More button"))
                }
            }
        }
        #endif
    }

    // MARK: - Computed Properties

    /// ベストショットの写真ID
    private var bestShotPhotoIds: Set<String> {
        if let bestShotId = group.bestShotId {
            return [bestShotId]
        }
        return []
    }

    /// 選択可能な写真ID（ベストショット以外）
    private var selectablePhotoIds: Set<String> {
        var ids = Set(group.photoIds)
        if let bestShotId = group.bestShotId {
            ids.remove(bestShotId)
        }
        return ids
    }

    /// 削除確認メッセージ
    private var deleteConfirmationMessage: String {
        let selectedPhotos = photos.filter { selectedPhotoIds.contains($0.id) }
        let totalSize = selectedPhotos.reduce(0) { $0 + $1.fileSize }
        let formattedSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

        return String(format: NSLocalizedString(
            "groupDetail.delete.message",
            value: "%d枚の写真（%@）を削除しますか？",
            comment: "Delete confirmation message"
        ), selectedPhotoIds.count, formattedSize)
    }

    /// グループ全削除確認メッセージ
    private var deleteAllConfirmationMessage: String {
        return String(format: NSLocalizedString(
            "groupDetail.deleteAll.message",
            value: "このグループのすべての写真（%d枚、%@）を削除しますか？\n\n※ ベストショットは保持されます。",
            comment: "Delete all confirmation message"
        ), group.count, group.formattedReclaimableSize)
    }

    // MARK: - Actions

    /// 写真を読み込み
    ///
    /// ## 修正履歴
    /// - 2025-01-XX: エラーハンドリング追加（P0バグ修正）
    ///   - 空のグループチェック追加
    ///   - Taskキャンセルチェック追加
    ///   - 詳細なログ出力追加
    ///   - 読み込み失敗時の適切なエラー状態遷移
    private func loadPhotos() async {
        viewState = .loading

        // 空のグループチェック
        guard !group.photoIds.isEmpty else {
            print("ℹ️ GroupDetailView: グループに写真IDがありません")
            photos = []
            viewState = .loaded
            return
        }

        guard let provider = photoProvider else {
            print("⚠️ GroupDetailView: photoProviderが設定されていません")
            photos = []
            viewState = .loaded
            return
        }

        // Taskキャンセルチェック
        guard !Task.isCancelled else {
            print("ℹ️ GroupDetailView: loadPhotos タスクがキャンセルされました")
            return
        }

        // 写真データを取得
        print("📸 GroupDetailView: \(group.photoIds.count)件の写真を読み込み開始")
        let loadedPhotos = await provider.photos(for: group.photoIds)

        // Taskキャンセルチェック（非同期処理後）
        guard !Task.isCancelled else {
            print("ℹ️ GroupDetailView: loadPhotos タスクがキャンセルされました（写真取得後）")
            return
        }

        // グループ内の順序を維持
        var orderedPhotos: [Photo] = []
        orderedPhotos.reserveCapacity(group.photoIds.count)

        for photoId in group.photoIds {
            if let photo = loadedPhotos.first(where: { $0.id == photoId }) {
                orderedPhotos.append(photo)
            }
        }

        // 読み込み結果のログ出力と状態更新
        let loadedCount = orderedPhotos.count
        let expectedCount = group.photoIds.count

        if loadedCount == 0 && expectedCount > 0 {
            // すべての写真読み込みに失敗
            print("❌ GroupDetailView: 写真の読み込みに失敗しました（0/\(expectedCount)件）")
            let errorMsg = NSLocalizedString(
                "groupDetail.error.loadFailed",
                value: "写真の読み込みに失敗しました。再度お試しください。",
                comment: "Photo load error message"
            )
            viewState = .error(errorMsg)
            errorMessage = errorMsg
            showErrorAlert = true
        } else if loadedCount < expectedCount {
            print("⚠️ GroupDetailView: 一部の写真が読み込めませんでした（\(loadedCount)/\(expectedCount)件）")
            photos = orderedPhotos
            viewState = .loaded
        } else {
            print("✅ GroupDetailView: 写真読み込み完了（\(loadedCount)件）")
            photos = orderedPhotos
            viewState = .loaded
        }
    }

    /// 選択モードをトグル
    private func toggleSelectionMode() {
        isSelectionModeActive.toggle()
        if !isSelectionModeActive {
            // 選択モード終了時は選択をクリア
            selectedPhotoIds.removeAll()
        }
    }

    /// 全選択/全解除
    private func toggleSelectAll() {
        if selectedPhotoIds.count == selectablePhotoIds.count {
            selectedPhotoIds.removeAll()
        } else {
            selectedPhotoIds = selectablePhotoIds
        }
    }

    /// 削除制限をチェックして確認ダイアログを表示（選択写真）
    private func checkDeletionLimitAndShowConfirmation() async {
        guard let premiumManager = premiumManager else {
            // PremiumManagerが設定されていない場合は制限チェックなしで削除
            showDeleteConfirmation = true
            return
        }

        let remaining = await premiumManager.getRemainingDeletions()
        if remaining >= selectedPhotoIds.count {
            // 削除可能
            showDeleteConfirmation = true
        } else {
            // 制限到達時はシートを表示（M9-T13で実装予定）
            showLimitReachedSheet = true
        }
    }

    /// 削除制限をチェックして確認ダイアログを表示（グループ全体）
    private func checkDeletionLimitForAllPhotos() async {
        guard let premiumManager = premiumManager else {
            // PremiumManagerが設定されていない場合は制限チェックなしで削除
            showDeleteAllConfirmation = true
            return
        }

        // ベストショット以外の全写真を削除対象とする
        let deletionCount = selectablePhotoIds.count

        let remaining = await premiumManager.getRemainingDeletions()
        if remaining >= deletionCount {
            // 削除可能
            showDeleteAllConfirmation = true
        } else {
            // 制限到達時はシートを表示
            showLimitReachedSheet = true
        }
    }

    /// 選択した写真を削除
    private func deleteSelectedPhotos() async {
        guard !selectedPhotoIds.isEmpty else { return }

        viewState = .processing

        do {
            let idsToDelete = Array(selectedPhotoIds)
            await onDeletePhotos?(idsToDelete)

            // 削除後、選択をクリア
            selectedPhotoIds.removeAll()

            // 写真リストから削除された写真を除外
            photos = photos.filter { !idsToDelete.contains($0.id) }

            viewState = .loaded
        }
    }

    /// グループ全体の写真を削除（ベストショット以外）
    private func deleteAllPhotos() async {
        viewState = .processing

        do {
            // ベストショット以外の全写真IDを取得
            let idsToDelete = Array(selectablePhotoIds)

            // 削除実行
            await onDeletePhotos?(idsToDelete)

            // 選択をクリア
            selectedPhotoIds.removeAll()

            // 選択モードを終了
            isSelectionModeActive = false

            // 写真リストから削除された写真を除外
            photos = photos.filter { !idsToDelete.contains($0.id) }

            viewState = .loaded
        }
    }
}

// MARK: - Preview

#if DEBUG

/// プレビュー用のモックデータ
private struct PreviewPhotoProvider: PhotoProvider {
    func photos(for ids: [String]) async -> [Photo] {
        ids.enumerated().map { index, id in
            Photo(
                id: id,
                localIdentifier: id,
                creationDate: Date().addingTimeInterval(TimeInterval(-3600 * index)),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: 0,
                fileSize: 2_500_000,
                isFavorite: false
            )
        }
    }
}

/// プレビュー用のサンプルグループ
private let previewGroup = PhotoGroup(
    type: .similar,
    photoIds: (0..<12).map { "photo-\($0)" },
    fileSizes: Array(repeating: 2_500_000, count: 12),
    bestShotIndex: 0
)

#Preview("グループ詳細 - ダークモード") {
    GroupDetailView(
        group: previewGroup,
        photoProvider: PreviewPhotoProvider(),
        onDeletePhotos: { photos in
            print("削除: \(photos.count)件")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("グループ詳細 - ライトモード") {
    GroupDetailView(
        group: previewGroup,
        photoProvider: PreviewPhotoProvider()
    )
    .preferredColorScheme(.light)
}

#Preview("グループ詳細 - スクリーンショット") {
    let screenshotGroup = PhotoGroup(
        type: .screenshot,
        photoIds: (0..<20).map { "screenshot-\($0)" },
        fileSizes: Array(repeating: 1_200_000, count: 20)
    )

    return GroupDetailView(
        group: screenshotGroup,
        photoProvider: PreviewPhotoProvider()
    )
    .preferredColorScheme(.dark)
}

#Preview("グループ詳細 - 空") {
    let emptyGroup = PhotoGroup(
        type: .blurry,
        photoIds: [],
        fileSizes: []
    )

    return GroupDetailView(
        group: emptyGroup,
        photoProvider: PreviewPhotoProvider()
    )
    .preferredColorScheme(.dark)
}

#endif
