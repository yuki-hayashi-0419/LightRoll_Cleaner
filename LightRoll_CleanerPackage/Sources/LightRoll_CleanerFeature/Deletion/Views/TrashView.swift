//
//  TrashView.swift
//  LightRoll_CleanerFeature
//
//  ゴミ箱ビュー
//  削除された写真を表示し、復元または完全削除を実行
//  Created by AI Assistant
//

import SwiftUI
import Photos

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - TrashView

/// ゴミ箱ビュー
/// 削除された写真の一覧を表示し、復元または完全削除を実行
///
/// ## 主な機能
/// - グリッドレイアウトで写真を表示
/// - 複数選択機能
/// - 復元ボタン
/// - 完全削除ボタン
/// - ゴミ箱を空にするボタン
/// - エンプティステート表示
///
/// ## 使用例
/// ```swift
/// TrashView(
///     trashManager: trashManager,
///     deletePhotosUseCase: deletePhotosUseCase,
///     restorePhotosUseCase: restorePhotosUseCase,
///     confirmationService: confirmationService
/// )
/// ```
@MainActor
public struct TrashView: View {

    // MARK: - Dependencies

    /// TrashManager
    private let trashManager: any TrashManagerProtocol

    /// DeletePhotosUseCase
    private let deletePhotosUseCase: any DeletePhotosUseCaseProtocol

    /// RestorePhotosUseCase
    private let restorePhotosUseCase: any RestorePhotosUseCaseProtocol

    /// DeletionConfirmationService
    private let confirmationService: DeletionConfirmationServiceProtocol

    // MARK: - State

    /// ビューの状態
    @State private var viewState: ViewState = .loading

    /// ゴミ箱内の写真（日付でグルーピング）
    @State private var groupedPhotos: [Date: [TrashPhoto]] = [:]

    /// 選択中の写真ID
    @State private var selectedPhotoIds: Set<String> = []

    /// 編集モードかどうか
    @State private var isEditMode: Bool = false

    /// 現在の確認メッセージ（nilでないときにシート表示）
    @State private var confirmationMessage: ConfirmationMessage?

    /// 現在の確認アクション
    @State private var confirmationAction: ConfirmationActionType = .delete

    /// トースト表示フラグ
    @State private var showToast: Bool = false

    /// トーストアイテム
    @State private var toastItem: ToastItem?

    /// エラー表示フラグ
    @State private var showError: Bool = false

    /// エラーメッセージ
    @State private var errorMessage: String = ""

    // MARK: - View State

    /// ビューの状態
    enum ViewState {
        /// 読み込み中
        case loading
        /// 読み込み完了
        case loaded
        /// エラー
        case error(String)
    }

    // MARK: - Constants

    /// グリッド列数
    private let gridColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: LRSpacing.sm)
    ]

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - trashManager: TrashManager
    ///   - deletePhotosUseCase: DeletePhotosUseCase
    ///   - restorePhotosUseCase: RestorePhotosUseCase
    ///   - confirmationService: DeletionConfirmationService
    public init(
        trashManager: any TrashManagerProtocol,
        deletePhotosUseCase: any DeletePhotosUseCaseProtocol,
        restorePhotosUseCase: any RestorePhotosUseCaseProtocol,
        confirmationService: DeletionConfirmationServiceProtocol
    ) {
        self.trashManager = trashManager
        self.deletePhotosUseCase = deletePhotosUseCase
        self.restorePhotosUseCase = restorePhotosUseCase
        self.confirmationService = confirmationService
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.LightRoll.background
                    .ignoresSafeArea()

                // コンテンツ
                content
            }
            .navigationTitle("ゴミ箱")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                toolbarContent
            }
            .task {
                await loadTrashPhotos()
            }
            .refreshable {
                await loadTrashPhotos()
            }
            .sheet(item: $confirmationMessage) { message in
                confirmationSheet(message: message)
            }
            .overlay {
                if showToast {
                    toastOverlay
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewState {
        case .loading:
            loadingView
        case .loaded:
            if groupedPhotos.isEmpty {
                emptyStateView
            } else {
                trashListView
            }
        case .error(let message):
            errorView(message)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: LRSpacing.lg) {
            ProgressView()
                .tint(Color.LightRoll.primary)

            Text("読み込み中...")
                .font(.LightRoll.body)
                .foregroundStyle(Color.LightRoll.textSecondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        EmptyStateView(
            type: .empty,
            customIcon: "trash",
            customTitle: "ゴミ箱は空です",
            customMessage: "削除した写真はここに30日間保管されます"
        )
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        EmptyStateView(
            type: .error,
            customIcon: "exclamationmark.triangle",
            customTitle: "エラーが発生しました",
            customMessage: message,
            actionTitle: "再読み込み",
            onAction: {
                await loadTrashPhotos()
            }
        )
    }

    // MARK: - Trash List View

    private var trashListView: some View {
        ScrollView {
            VStack(spacing: LRSpacing.md) {
                // ヘッダー情報
                trashHeaderView

                // 日付別セクション
                ForEach(sortedDates, id: \.self) { date in
                    trashSection(for: date)
                }
            }
            .padding(LRSpacing.md)
        }
        .safeAreaInset(edge: .bottom) {
            if isEditMode && !selectedPhotoIds.isEmpty {
                actionButtonsView
            }
        }
    }

    // MARK: - Trash Header View

    private var trashHeaderView: some View {
        VStack(spacing: LRSpacing.sm) {
            // 警告メッセージ
            HStack(spacing: LRSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.LightRoll.warning)

                Text("30日後に自動削除されます")
                    .font(.LightRoll.caption)
                    .foregroundStyle(Color.LightRoll.textSecondary)
            }
            .padding(LRSpacing.sm)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM)
                    .fill(Color.LightRoll.warning.opacity(0.1))
            }

            // 使用容量
            let totalSize = allPhotos.totalSize
            if totalSize > 0 {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundStyle(Color.LightRoll.textSecondary)

                    Text("使用容量: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                        .font(.LightRoll.caption)
                        .foregroundStyle(Color.LightRoll.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, LRSpacing.xs)
            }
        }
    }

    // MARK: - Trash Section

    private func trashSection(for date: Date) -> some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            // セクションヘッダー
            HStack {
                Text(sectionTitle(for: date))
                    .font(.LightRoll.headline)
                    .foregroundStyle(Color.LightRoll.textPrimary)

                if let photos = groupedPhotos[date] {
                    Text("(\(photos.count)枚)")
                        .font(.LightRoll.caption)
                        .foregroundStyle(Color.LightRoll.textSecondary)
                }

                Spacer()

                // 期限表示
                if let photos = groupedPhotos[date]?.first {
                    Text(photos.formattedTimeRemaining)
                        .font(.LightRoll.caption)
                        .foregroundStyle(
                            photos.daysUntilExpiration <= 7 ?
                                Color.LightRoll.error : Color.LightRoll.textSecondary
                        )
                }
            }

            // グリッド
            if let photos = groupedPhotos[date] {
                LazyVGrid(columns: gridColumns, spacing: LRSpacing.sm) {
                    ForEach(photos) { photo in
                        trashPhotoCell(photo)
                    }
                }
            }
        }
    }

    // MARK: - Trash Photo Cell

    private func trashPhotoCell(_ photo: TrashPhoto) -> some View {
        Button {
            toggleSelection(photo)
        } label: {
            ZStack(alignment: .topTrailing) {
                // サムネイル
                if let thumbnailData = photo.thumbnailData {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                    #elseif canImport(AppKit)
                    if let nsImage = NSImage(data: thumbnailData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                    #endif
                } else {
                    Rectangle()
                        .fill(Color.LightRoll.surfaceCard)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.LightRoll.textTertiary)
                        }
                }

                // 選択インジケーター
                if isEditMode {
                    Circle()
                        .fill(
                            selectedPhotoIds.contains(photo.originalPhotoId) ?
                                Color.LightRoll.primary : Color.LightRoll.surfaceCard
                        )
                        .frame(width: 24, height: 24)
                        .overlay {
                            if selectedPhotoIds.contains(photo.originalPhotoId) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(LRSpacing.xs)
                }

                // 動画アイコン
                if photo.isVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(LRSpacing.xs)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM))
            .overlay {
                if selectedPhotoIds.contains(photo.originalPhotoId) {
                    RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM)
                        .stroke(Color.LightRoll.primary, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons View

    private var actionButtonsView: some View {
        VStack(spacing: LRSpacing.sm) {
            // 復元ボタン
            Button {
                Task {
                    await handleRestore()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("選択した写真を復元 (\(selectedPhotoIds.count)枚)")
                }
                .font(.LightRoll.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(LRSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: LRLayout.cornerRadiusMD)
                        .fill(Color.LightRoll.primary)
                }
            }

            // 完全削除ボタン
            Button {
                Task {
                    await handlePermanentDelete()
                }
            } label: {
                HStack {
                    Image(systemName: "trash.circle.fill")
                    Text("完全削除 (\(selectedPhotoIds.count)枚)")
                }
                .font(.LightRoll.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(LRSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: LRLayout.cornerRadiusMD)
                        .fill(Color.LightRoll.error)
                }
            }
        }
        .padding(LRSpacing.md)
        .background {
            Rectangle()
                .fill(Color.LightRoll.surfaceCard)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // 編集ボタン
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
            if !groupedPhotos.isEmpty {
                Button {
                    withAnimation {
                        isEditMode.toggle()
                        if !isEditMode {
                            selectedPhotoIds.removeAll()
                        }
                    }
                } label: {
                    Text(isEditMode ? "完了" : "選択")
                        .font(.LightRoll.headline)
                        .foregroundStyle(Color.LightRoll.primary)
                }
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            if !groupedPhotos.isEmpty {
                Button {
                    withAnimation {
                        isEditMode.toggle()
                        if !isEditMode {
                            selectedPhotoIds.removeAll()
                        }
                    }
                } label: {
                    Text(isEditMode ? "完了" : "選択")
                        .font(.LightRoll.headline)
                        .foregroundStyle(Color.LightRoll.primary)
                }
            }
        }
        #endif

        // ゴミ箱を空にするボタン
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            if !groupedPhotos.isEmpty && !isEditMode {
                Button {
                    Task {
                        await handleEmptyTrash()
                    }
                } label: {
                    Text("空にする")
                        .font(.LightRoll.headline)
                        .foregroundStyle(Color.LightRoll.error)
                }
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            if !groupedPhotos.isEmpty && !isEditMode {
                Button {
                    Task {
                        await handleEmptyTrash()
                    }
                } label: {
                    Text("空にする")
                        .font(.LightRoll.headline)
                        .foregroundStyle(Color.LightRoll.error)
                }
            }
        }
        #endif
    }

    // MARK: - Confirmation Sheet

    @ViewBuilder
    private func confirmationSheet(message: ConfirmationMessage) -> some View {
        ConfirmationDialog(
            title: message.title,
            message: message.message,
            details: message.details.isEmpty ? nil : message.details,
            style: message.style,
            confirmTitle: message.confirmTitle,
            cancelTitle: message.cancelTitle,
            onConfirm: { @MainActor in
                await executeConfirmedAction()
            },
            onCancel: { @MainActor in
                confirmationMessage = nil
            }
        )
        .presentationDetents([.medium])
    }

    // MARK: - Toast Overlay

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast = toastItem, showToast {
            ToastView(
                toast: toast,
                onDismiss: { @MainActor in
                    showToast = false
                    toastItem = nil
                }
            )
        }
    }

    // MARK: - Helper Properties

    /// 全写真
    private var allPhotos: [TrashPhoto] {
        groupedPhotos.values.flatMap { $0 }
    }

    /// ソート済み日付
    private var sortedDates: [Date] {
        groupedPhotos.keys.sorted(by: >)
    }

    /// セクションタイトル
    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)

        if targetDate == today {
            return "今日削除"
        } else if targetDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return "昨日削除"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date) + "削除"
        }
    }

    // MARK: - Private Methods

    /// ゴミ箱写真を読み込み
    private func loadTrashPhotos() async {
        viewState = .loading

        let photos = await trashManager.fetchAllTrashPhotos()
        groupedPhotos = photos.groupedByDeletedDay
        viewState = .loaded
    }

    /// 選択トグル
    private func toggleSelection(_ photo: TrashPhoto) {
        guard isEditMode else { return }

        if selectedPhotoIds.contains(photo.originalPhotoId) {
            selectedPhotoIds.remove(photo.originalPhotoId)
        } else {
            selectedPhotoIds.insert(photo.originalPhotoId)
        }
    }

    /// 復元処理
    private func handleRestore() async {
        guard !selectedPhotoIds.isEmpty else { return }

        // 選択された写真を取得
        let selectedPhotos = allPhotos.filter { selectedPhotoIds.contains($0.originalPhotoId) }

        // 確認が必要かチェック
        if confirmationService.shouldShowConfirmation(
            photoCount: selectedPhotos.count,
            actionType: .restore
        ) {
            confirmationAction = .restore
            confirmationMessage = confirmationService.formatConfirmationMessage(
                photoCount: selectedPhotos.count,
                totalSize: nil,
                actionType: .restore,
                itemName: "写真"
            )
        } else {
            await executeRestore()
        }
    }

    /// 復元実行
    private func executeRestore() async {
        let selectedPhotos = allPhotos.filter { selectedPhotoIds.contains($0.originalPhotoId) }

        do {
            let input = RestorePhotosInput(
                photos: selectedPhotos.map { PhotoAsset(id: $0.originalPhotoId, creationDate: nil, fileSize: $0.fileSize) }
            )
            let result = try await restorePhotosUseCase.execute(input)

            // 成功トースト
            toastItem = ToastItem(
                type: .success,
                title: "\(result.restoredCount)枚の写真を復元しました"
            )
            showToast = true

            // 選択をクリア
            selectedPhotoIds.removeAll()
            isEditMode = false

            // 再読み込み
            await loadTrashPhotos()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// 完全削除処理
    private func handlePermanentDelete() async {
        guard !selectedPhotoIds.isEmpty else { return }

        // 選択された写真を取得
        let selectedPhotos = allPhotos.filter { selectedPhotoIds.contains($0.originalPhotoId) }

        // 確認メッセージ
        confirmationAction = .permanentDelete
        confirmationMessage = confirmationService.formatConfirmationMessage(
            photoCount: selectedPhotos.count,
            totalSize: selectedPhotos.totalSize,
            actionType: .permanentDelete,
            itemName: "写真"
        )
    }

    /// 完全削除実行
    private func executePermanentDelete() async {
        let selectedPhotos = allPhotos.filter { selectedPhotoIds.contains($0.originalPhotoId) }

        do {
            try await trashManager.permanentlyDelete(selectedPhotos)

            // 成功トースト
            toastItem = ToastItem(
                type: .success,
                title: "\(selectedPhotos.count)枚の写真を完全に削除しました"
            )
            showToast = true

            // 選択をクリア
            selectedPhotoIds.removeAll()
            isEditMode = false

            // 再読み込み
            await loadTrashPhotos()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// ゴミ箱を空にする処理
    private func handleEmptyTrash() async {
        let photoCount = allPhotos.count
        guard photoCount > 0 else { return }

        // 確認メッセージ
        confirmationAction = .emptyTrash
        confirmationMessage = confirmationService.formatConfirmationMessage(
            photoCount: photoCount,
            totalSize: allPhotos.totalSize,
            actionType: .emptyTrash,
            itemName: "写真"
        )
    }

    /// ゴミ箱を空にする実行
    private func executeEmptyTrash() async {
        do {
            try await trashManager.emptyTrash()

            // 成功トースト
            toastItem = ToastItem(
                type: .success,
                title: "ゴミ箱を空にしました"
            )
            showToast = true

            // 再読み込み
            await loadTrashPhotos()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// 確認済みアクション実行
    private func executeConfirmedAction() async {
        confirmationMessage = nil

        switch confirmationAction {
        case .restore:
            await executeRestore()
        case .permanentDelete:
            await executePermanentDelete()
        case .emptyTrash:
            await executeEmptyTrash()
        default:
            break
        }
    }
}

// MARK: - Preview

#if DEBUG

// Previewは削除（テスト用のMockを使用）

#endif
