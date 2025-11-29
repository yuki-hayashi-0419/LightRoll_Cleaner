//
//  GroupListView.swift
//  LightRoll_CleanerFeature
//
//  グループリストビュー
//  スキャン結果のグループ一覧を表示し、フィルタ・ソート・選択機能を提供
//  MV Pattern: ViewModelなし、@Stateで状態管理
//  Created by AI Assistant
//

import SwiftUI

// MARK: - GroupListView

/// グループリストビュー
/// スキャン結果の写真グループ一覧を表示し、フィルタ、ソート、選択機能を提供
///
/// ## 主な機能
/// - グループタイプ別のフィルタリング
/// - ソート順の変更（削減可能サイズ、写真数、日付）
/// - グループ選択と一括削除
/// - グループタップで詳細画面へ遷移
///
/// ## 使用例
/// ```swift
/// GroupListView(
///     groups: photoGroups,
///     onGroupTap: { group in
///         // グループ詳細へ遷移
///     }
/// )
/// ```
@MainActor
public struct GroupListView: View {

    // MARK: - Properties

    /// 表示するグループ一覧
    private let groups: [PhotoGroup]

    /// 写真リポジトリ（サムネイル取得用）
    private let photoProvider: PhotoProvider?

    /// グループタップ時のコールバック
    private let onGroupTap: ((PhotoGroup) -> Void)?

    /// 削除アクションのコールバック
    private let onDeleteGroups: (([PhotoGroup]) async -> Void)?

    /// 戻るアクションのコールバック
    private let onBack: (() -> Void)?

    /// 初期フィルタタイプ（nil の場合は全タイプ表示）
    private let initialFilterType: GroupType?

    // MARK: - State

    /// ビューの状態
    @State private var viewState: ViewState = .loaded

    /// 現在のフィルタタイプ
    @State private var filterType: GroupType?

    /// 現在のソート順
    @State private var sortOrder: SortOrder = .reclaimableSize

    /// 選択モード
    @State private var isSelectionMode: Bool = false

    /// 選択中のグループID
    @State private var selectedGroupIds: Set<UUID> = []

    /// 削除確認ダイアログ表示フラグ
    @State private var showDeleteConfirmation: Bool = false

    /// フィルタシート表示フラグ
    @State private var showFilterSheet: Bool = false

    /// エラーアラート表示フラグ
    @State private var showErrorAlert: Bool = false

    /// エラーメッセージ
    @State private var errorMessage: String = ""

    /// 代表写真キャッシュ（グループID -> 写真配列）
    @State private var representativePhotosCache: [UUID: [Photo]] = [:]

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

    // MARK: - SortOrder

    /// ソート順
    public enum SortOrder: String, CaseIterable, Sendable {
        /// 削減可能サイズ順（大きい順）
        case reclaimableSize
        /// 写真数順（多い順）
        case photoCount
        /// 作成日時順（新しい順）
        case date
        /// グループタイプ順
        case type

        /// 表示名
        var displayName: String {
            switch self {
            case .reclaimableSize:
                return NSLocalizedString("sort.reclaimableSize", value: "削減可能サイズ", comment: "Sort by reclaimable size")
            case .photoCount:
                return NSLocalizedString("sort.photoCount", value: "写真数", comment: "Sort by photo count")
            case .date:
                return NSLocalizedString("sort.date", value: "日付", comment: "Sort by date")
            case .type:
                return NSLocalizedString("sort.type", value: "タイプ", comment: "Sort by type")
            }
        }

        /// アイコン
        var icon: String {
            switch self {
            case .reclaimableSize:
                return "arrow.down.circle"
            case .photoCount:
                return "photo.stack"
            case .date:
                return "calendar"
            case .type:
                return "square.grid.2x2"
            }
        }
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - groups: 表示するグループ一覧
    ///   - photoProvider: 写真プロバイダー（サムネイル取得用）
    ///   - initialFilterType: 初期フィルタタイプ（nil で全タイプ）
    ///   - onGroupTap: グループタップ時のコールバック
    ///   - onDeleteGroups: 削除アクションのコールバック
    ///   - onBack: 戻るアクションのコールバック
    public init(
        groups: [PhotoGroup],
        photoProvider: PhotoProvider? = nil,
        initialFilterType: GroupType? = nil,
        onGroupTap: ((PhotoGroup) -> Void)? = nil,
        onDeleteGroups: (([PhotoGroup]) async -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.groups = groups
        self.photoProvider = photoProvider
        self.initialFilterType = initialFilterType
        self.onGroupTap = onGroupTap
        self.onDeleteGroups = onDeleteGroups
        self.onBack = onBack
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                backgroundGradient

                // メインコンテンツ
                mainContent
            }
            .navigationTitle(navigationTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                toolbarContent
            }
            .onAppear {
                // 初期フィルタを設定
                if filterType == nil {
                    filterType = initialFilterType
                }
            }
            .alert(
                NSLocalizedString(
                    "groupList.error.title",
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
                    "groupList.delete.title",
                    value: "選択したグループを削除",
                    comment: "Delete confirmation title"
                ),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    NSLocalizedString(
                        "groupList.delete.confirm",
                        value: "削除する",
                        comment: "Delete confirm button"
                    ),
                    role: .destructive
                ) {
                    Task {
                        await deleteSelectedGroups()
                    }
                }

                Button(
                    NSLocalizedString("common.cancel", value: "キャンセル", comment: "Cancel button"),
                    role: .cancel
                ) {}
            } message: {
                Text(deleteConfirmationMessage)
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
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

        case .loaded, .processing:
            if filteredAndSortedGroups.isEmpty {
                emptyStateView
            } else {
                groupListContent
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
                "groupList.loading",
                value: "読み込み中...",
                comment: "Loading message"
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// グループリストコンテンツ
    private var groupListContent: some View {
        VStack(spacing: 0) {
            // サマリーヘッダー
            summaryHeader

            // フィルタ・ソートバー
            filterSortBar

            // グループリスト
            ScrollView {
                LazyVStack(spacing: LRSpacing.md) {
                    ForEach(filteredAndSortedGroups) { group in
                        groupRow(for: group)
                    }
                }
                .padding(.horizontal, LRSpacing.md)
                .padding(.vertical, LRSpacing.sm)
            }

            // 選択モード時の一括操作バー
            if isSelectionMode && !selectedGroupIds.isEmpty {
                selectionActionBar
            }
        }
    }

    /// サマリーヘッダー
    private var summaryHeader: some View {
        HStack(spacing: LRSpacing.lg) {
            // グループ数
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(
                    "groupList.summary.groups",
                    value: "グループ数",
                    comment: "Groups count label"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("\(filteredAndSortedGroups.count)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Divider()
                .frame(height: 30)

            // 写真数
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(
                    "groupList.summary.photos",
                    value: "写真数",
                    comment: "Photos count label"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("\(filteredAndSortedGroups.totalPhotoCount)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Divider()
                .frame(height: 30)

            // 削減可能サイズ
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(
                    "groupList.summary.reclaimable",
                    value: "削減可能",
                    comment: "Reclaimable size label"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(filteredAndSortedGroups.formattedTotalReclaimableSize)
                    .font(.headline)
                    .foregroundStyle(Color.LightRoll.success)
            }

            Spacer()
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThinMaterial)
    }

    /// フィルタ・ソートバー
    private var filterSortBar: some View {
        HStack(spacing: LRSpacing.md) {
            // フィルタボタン
            Button {
                showFilterSheet = true
            } label: {
                HStack(spacing: LRSpacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(filterType?.displayName ?? NSLocalizedString(
                        "filter.all",
                        value: "すべて",
                        comment: "All filter"
                    ))
                    .font(.subheadline)
                }
                .padding(.horizontal, LRSpacing.sm)
                .padding(.vertical, LRSpacing.xs)
                .background(
                    filterType != nil
                        ? Color.LightRoll.primary.opacity(0.2)
                        : Color.LightRoll.surfaceCard
                )
                .clipShape(Capsule())
            }
            .foregroundStyle(filterType != nil ? Color.LightRoll.primary : .secondary)

            // ソートメニュー
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Image(systemName: order.icon)
                            Text(order.displayName)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: LRSpacing.xs) {
                    Image(systemName: sortOrder.icon)
                    Text(sortOrder.displayName)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, LRSpacing.sm)
                .padding(.vertical, LRSpacing.xs)
                .background(Color.LightRoll.surfaceCard)
                .clipShape(Capsule())
            }
            .foregroundStyle(.secondary)

            Spacer()

            // 選択モード切り替え
            Button {
                toggleSelectionMode()
            } label: {
                Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title3)
            }
            .foregroundStyle(isSelectionMode ? Color.LightRoll.primary : .secondary)
        }
        .padding(.horizontal, LRSpacing.md)
        .padding(.vertical, LRSpacing.sm)
    }

    /// グループ行
    private func groupRow(for group: PhotoGroup) -> some View {
        HStack(spacing: LRSpacing.md) {
            // 選択モード時のチェックボックス
            if isSelectionMode {
                Button {
                    toggleSelection(for: group)
                } label: {
                    Image(systemName: selectedGroupIds.contains(group.id)
                        ? "checkmark.circle.fill"
                        : "circle")
                        .font(.title2)
                        .foregroundStyle(
                            selectedGroupIds.contains(group.id)
                                ? Color.LightRoll.primary
                                : .secondary
                        )
                }
                .buttonStyle(.plain)
            }

            // グループカード
            GroupCard(
                group: group,
                representativePhotos: representativePhotosCache[group.id] ?? []
            ) {
                if isSelectionMode {
                    toggleSelection(for: group)
                } else {
                    onGroupTap?(group)
                }
            }
        }
        .task {
            await loadRepresentativePhotos(for: group)
        }
    }

    /// 選択アクションバー
    private var selectionActionBar: some View {
        HStack(spacing: LRSpacing.lg) {
            // 選択件数表示
            Text(String(format: NSLocalizedString(
                "groupList.selected.count",
                value: "%d件選択中",
                comment: "Selected count"
            ), selectedGroupIds.count))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            // 全選択/全解除
            Button {
                toggleSelectAll()
            } label: {
                Text(selectedGroupIds.count == filteredAndSortedGroups.count
                    ? NSLocalizedString("groupList.deselectAll", value: "全解除", comment: "Deselect all")
                    : NSLocalizedString("groupList.selectAll", value: "全選択", comment: "Select all"))
                .font(.subheadline)
            }

            // 削除ボタン
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: LRSpacing.xs) {
                    Image(systemName: "trash")
                    Text(NSLocalizedString("groupList.delete", value: "削除", comment: "Delete button"))
                }
            }
            .disabled(selectedGroupIds.isEmpty)
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThickMaterial)
    }

    /// 空状態ビュー
    private var emptyStateView: some View {
        EmptyStateView(
            type: .empty,
            customIcon: "photo.stack",
            customTitle: filterType != nil
                ? NSLocalizedString(
                    "groupList.empty.filtered.title",
                    value: "該当するグループがありません",
                    comment: "No filtered groups title"
                  )
                : NSLocalizedString(
                    "groupList.empty.title",
                    value: "グループがありません",
                    comment: "No groups title"
                  ),
            customMessage: filterType != nil
                ? NSLocalizedString(
                    "groupList.empty.filtered.message",
                    value: "フィルタを変更してください",
                    comment: "No filtered groups message"
                  )
                : NSLocalizedString(
                    "groupList.empty.message",
                    value: "写真をスキャンしてグループを検出してください",
                    comment: "No groups message"
                  ),
            actionTitle: filterType != nil
                ? NSLocalizedString("groupList.clearFilter", value: "フィルタをクリア", comment: "Clear filter")
                : nil,
            onAction: filterType != nil
                ? { @MainActor @Sendable in
                    filterType = nil
                  }
                : nil
        )
    }

    /// エラービュー
    private func errorView(message: String) -> some View {
        EmptyStateView(
            type: .error,
            customMessage: message,
            actionTitle: NSLocalizedString(
                "groupList.error.retry",
                value: "再読み込み",
                comment: "Retry button"
            ),
            onAction: { @MainActor @Sendable in
                viewState = .loaded
            }
        )
    }

    /// フィルタシート
    private var filterSheet: some View {
        NavigationStack {
            List {
                // 全タイプ
                Button {
                    filterType = nil
                    showFilterSheet = false
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text(NSLocalizedString("filter.all", value: "すべて", comment: "All filter"))
                        Spacer()
                        if filterType == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.LightRoll.primary)
                        }
                    }
                }
                .foregroundStyle(.primary)

                // グループタイプ別
                ForEach(availableGroupTypes, id: \.self) { type in
                    Button {
                        filterType = type
                        showFilterSheet = false
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)

                            Spacer()

                            // グループ数バッジ
                            Text("\(groups.filterByType(type).count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.LightRoll.surfaceCard)
                                .clipShape(Capsule())

                            if filterType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.LightRoll.primary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle(NSLocalizedString(
                "filter.title",
                value: "フィルタ",
                comment: "Filter sheet title"
            ))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", value: "閉じる", comment: "Close button")) {
                        showFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// ツールバーコンテンツ
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            if onBack != nil {
                Button {
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .accessibilityLabel(NSLocalizedString(
                            "common.back",
                            value: "戻る",
                            comment: "Back button"
                        ))
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if isSelectionMode {
                Button(NSLocalizedString("common.done", value: "完了", comment: "Done button")) {
                    toggleSelectionMode()
                }
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            if onBack != nil {
                Button {
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .accessibilityLabel(NSLocalizedString(
                            "common.back",
                            value: "戻る",
                            comment: "Back button"
                        ))
                }
            }
        }

        ToolbarItem(placement: .automatic) {
            if isSelectionMode {
                Button(NSLocalizedString("common.done", value: "完了", comment: "Done button")) {
                    toggleSelectionMode()
                }
            }
        }
        #endif
    }

    // MARK: - Computed Properties

    /// ナビゲーションタイトル
    private var navigationTitle: String {
        if let type = filterType {
            return type.displayName
        }
        return NSLocalizedString(
            "groupList.title",
            value: "グループ一覧",
            comment: "Group list title"
        )
    }

    /// フィルタ・ソート適用済みグループ
    private var filteredAndSortedGroups: [PhotoGroup] {
        var result = groups

        // フィルタ適用
        if let filterType = filterType {
            result = result.filterByType(filterType)
        }

        // ソート適用
        switch sortOrder {
        case .reclaimableSize:
            result = result.sortedByReclaimableSize
        case .photoCount:
            result = result.sortedByPhotoCount
        case .date:
            result = result.sortedByDate
        case .type:
            result = result.sortedByType
        }

        return result
    }

    /// 利用可能なグループタイプ（データがあるもののみ）
    private var availableGroupTypes: [GroupType] {
        GroupType.allCases.filter { type in
            groups.contains { $0.type == type }
        }
    }

    /// 削除確認メッセージ
    private var deleteConfirmationMessage: String {
        let selectedGroups = groups.filter { selectedGroupIds.contains($0.id) }
        let totalPhotos = selectedGroups.reduce(0) { $0 + $1.count }
        let totalSize = selectedGroups.reduce(0) { $0 + $1.reclaimableSize }
        let formattedSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

        return String(format: NSLocalizedString(
            "groupList.delete.message",
            value: "%d件のグループ（%d枚の写真、%@）を削除しますか？",
            comment: "Delete confirmation message"
        ), selectedGroupIds.count, totalPhotos, formattedSize)
    }

    // MARK: - Actions

    /// 選択モード切り替え
    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedGroupIds.removeAll()
        }
    }

    /// グループ選択切り替え
    private func toggleSelection(for group: PhotoGroup) {
        if selectedGroupIds.contains(group.id) {
            selectedGroupIds.remove(group.id)
        } else {
            selectedGroupIds.insert(group.id)
        }
    }

    /// 全選択/全解除
    private func toggleSelectAll() {
        if selectedGroupIds.count == filteredAndSortedGroups.count {
            selectedGroupIds.removeAll()
        } else {
            selectedGroupIds = Set(filteredAndSortedGroups.map { $0.id })
        }
    }

    /// 選択グループを削除
    private func deleteSelectedGroups() async {
        guard !selectedGroupIds.isEmpty else { return }

        viewState = .processing

        let groupsToDelete = groups.filter { selectedGroupIds.contains($0.id) }

        do {
            await onDeleteGroups?(groupsToDelete)
            selectedGroupIds.removeAll()
            isSelectionMode = false
            viewState = .loaded
        }
    }

    /// 代表写真を読み込み
    private func loadRepresentativePhotos(for group: PhotoGroup) async {
        // 既にキャッシュ済みの場合はスキップ
        guard representativePhotosCache[group.id] == nil else { return }

        // photoProvider がない場合は空配列
        guard let provider = photoProvider else {
            representativePhotosCache[group.id] = []
            return
        }

        // 最初の3枚の写真IDを取得
        let photoIds = Array(group.photoIds.prefix(3))

        // 写真を取得
        let photos = await provider.photos(for: photoIds)
        representativePhotosCache[group.id] = photos
    }
}

// MARK: - PhotoProvider Protocol

/// 写真プロバイダープロトコル
/// グループリストビューで代表写真を取得するために使用
public protocol PhotoProvider: Sendable {
    /// 指定したIDの写真を取得
    /// - Parameter ids: 写真ID配列
    /// - Returns: 写真配列
    func photos(for ids: [String]) async -> [Photo]
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
private let previewGroups: [PhotoGroup] = [
    PhotoGroup(
        type: .similar,
        photoIds: (0..<5).map { "similar-\($0)" },
        fileSizes: Array(repeating: 3_000_000, count: 5),
        bestShotIndex: 0
    ),
    PhotoGroup(
        type: .similar,
        photoIds: (0..<8).map { "similar-b-\($0)" },
        fileSizes: Array(repeating: 2_500_000, count: 8),
        bestShotIndex: 2
    ),
    PhotoGroup(
        type: .screenshot,
        photoIds: (0..<15).map { "screenshot-\($0)" },
        fileSizes: Array(repeating: 1_200_000, count: 15)
    ),
    PhotoGroup(
        type: .blurry,
        photoIds: (0..<6).map { "blurry-\($0)" },
        fileSizes: Array(repeating: 3_500_000, count: 6)
    ),
    PhotoGroup(
        type: .selfie,
        photoIds: (0..<4).map { "selfie-\($0)" },
        fileSizes: Array(repeating: 2_800_000, count: 4),
        bestShotIndex: 1
    ),
    PhotoGroup(
        type: .largeVideo,
        photoIds: (0..<3).map { "video-\($0)" },
        fileSizes: Array(repeating: 150_000_000, count: 3)
    ),
    PhotoGroup(
        type: .duplicate,
        photoIds: (0..<2).map { "duplicate-\($0)" },
        fileSizes: Array(repeating: 4_000_000, count: 2)
    )
]

#Preview("グループリスト - ダークモード") {
    GroupListView(
        groups: previewGroups,
        photoProvider: PreviewPhotoProvider(),
        onGroupTap: { group in
            print("タップ: \(group.displayName)")
        },
        onDeleteGroups: { groups in
            print("削除: \(groups.count)件")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("グループリスト - ライトモード") {
    GroupListView(
        groups: previewGroups,
        photoProvider: PreviewPhotoProvider(),
        onGroupTap: { group in
            print("タップ: \(group.displayName)")
        }
    )
    .preferredColorScheme(.light)
}

#Preview("グループリスト - フィルタ済み") {
    GroupListView(
        groups: previewGroups,
        photoProvider: PreviewPhotoProvider(),
        initialFilterType: .similar,
        onGroupTap: { group in
            print("タップ: \(group.displayName)")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("グループリスト - 空") {
    GroupListView(
        groups: [],
        onGroupTap: nil
    )
    .preferredColorScheme(.dark)
}

#endif
