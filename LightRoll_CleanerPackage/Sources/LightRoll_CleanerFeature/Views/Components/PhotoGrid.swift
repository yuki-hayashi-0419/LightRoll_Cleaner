//
//  PhotoGrid.swift
//  LightRoll_CleanerFeature
//
//  写真グリッド表示コンポーネント
//  LazyVGridを使用した効率的な写真一覧表示
//  選択状態管理、タップハンドリング、アクセシビリティ対応
//  Created by AI Assistant
//

import SwiftUI

// MARK: - PhotoGrid

/// 写真グリッド表示コンポーネント
/// LazyVGridを使用して写真を効率的にグリッド表示
/// PhotoThumbnailを活用し、選択状態管理とタップハンドリングを実装
/// DISPLAY-002: ファイルサイズ・撮影日表示機能を追加
public struct PhotoGrid: View {
    // MARK: - Properties

    /// 表示する写真の配列
    let photos: [Photo]

    /// グリッドの列数（デフォルト: 3）
    let columns: Int

    /// 選択された写真のIDセット
    @Binding var selectedPhotos: Set<String>

    /// ベストショットを表示する写真のIDセット
    var bestShotPhotos: Set<String> = []

    /// ファイルサイズを表示するか
    /// DISPLAY-002: 表示設定からの反映
    var showFileSize: Bool = false

    /// 撮影日を表示するか
    /// DISPLAY-002: 表示設定からの反映
    var showDate: Bool = false

    /// 写真がタップされた時のコールバック
    var onPhotoTap: ((Photo) -> Void)?

    /// 写真が長押しされた時のコールバック（選択モード切り替え等）
    var onPhotoLongPress: ((Photo) -> Void)?

    // MARK: - Computed Properties

    /// LazyVGridのカラム設定
    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(),
                spacing: LRSpacing.gridSpacing
            ),
            count: columns
        )
    }

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photos: 表示する写真の配列
    ///   - columns: グリッドの列数（デフォルト: 3）
    ///   - selectedPhotos: 選択された写真のIDセットのバインディング
    ///   - bestShotPhotos: ベストショットを表示する写真のIDセット（デフォルト: 空）
    ///   - showFileSize: ファイルサイズを表示するか（デフォルト: false）
    ///   - showDate: 撮影日を表示するか（デフォルト: false）
    ///   - onPhotoTap: 写真がタップされた時のコールバック
    ///   - onPhotoLongPress: 写真が長押しされた時のコールバック
    public init(
        photos: [Photo],
        columns: Int = 3,
        selectedPhotos: Binding<Set<String>>,
        bestShotPhotos: Set<String> = [],
        showFileSize: Bool = false,
        showDate: Bool = false,
        onPhotoTap: ((Photo) -> Void)? = nil,
        onPhotoLongPress: ((Photo) -> Void)? = nil
    ) {
        self.photos = photos
        self.columns = columns
        self._selectedPhotos = selectedPhotos
        self.bestShotPhotos = bestShotPhotos
        self.showFileSize = showFileSize
        self.showDate = showDate
        self.onPhotoTap = onPhotoTap
        self.onPhotoLongPress = onPhotoLongPress
    }

    // MARK: - Body

    public var body: some View {
        if photos.isEmpty {
            // 写真がない場合の空状態
            emptyStateView
        } else {
            // グリッド表示
            ScrollView {
                LazyVGrid(
                    columns: gridColumns,
                    spacing: LRSpacing.gridSpacing
                ) {
                    ForEach(photos) { photo in
                        photoCell(for: photo)
                    }
                }
                .padding(LRSpacing.md)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("写真グリッド")
            .accessibilityHint("\(photos.count)枚の写真、\(selectedPhotos.count)枚選択中")
        }
    }

    // MARK: - Subviews

    /// 写真セル
    /// DISPLAY-002: showFileSize/showDateパラメータを追加
    @ViewBuilder
    private func photoCell(for photo: Photo) -> some View {
        let isSelected = selectedPhotos.contains(photo.id)
        let showBadge = bestShotPhotos.contains(photo.id)

        PhotoThumbnail(
            photo: photo,
            isSelected: isSelected,
            showBadge: showBadge,
            showFileSize: showFileSize,
            showDate: showDate
        )
        .aspectRatio(1.0, contentMode: .fit)
        .onTapGesture {
            handleTap(on: photo)
        }
        .onLongPressGesture {
            handleLongPress(on: photo)
        }
        .accessibilityIdentifier("photo-\(photo.id)")
        #if canImport(UIKit)
        .accessibilityAddTraits(.isButton)
        #endif
        .accessibilityHint(isSelected ? "タップして選択解除" : "タップして選択")
    }

    /// 空状態のビュー
    private var emptyStateView: some View {
        VStack(spacing: LRSpacing.lg) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: LRLayout.iconSizeXXL))
                .foregroundColor(Color.LightRoll.textTertiary)

            Text("写真がありません")
                .font(Font.LightRoll.headline)
                .foregroundColor(Color.LightRoll.textSecondary)

            Text("写真をスキャンしてください")
                .font(Font.LightRoll.body)
                .foregroundColor(Color.LightRoll.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("写真がありません")
    }

    // MARK: - Actions

    /// タップ時の処理
    private func handleTap(on photo: Photo) {
        // タップコールバックがあればそれを実行
        if let onPhotoTap = onPhotoTap {
            onPhotoTap(photo)
        } else {
            // デフォルト動作: 選択状態のトグル
            toggleSelection(for: photo)
        }
    }

    /// 長押し時の処理
    private func handleLongPress(on photo: Photo) {
        // 長押しコールバックがあればそれを実行
        if let onPhotoLongPress = onPhotoLongPress {
            onPhotoLongPress(photo)
        } else {
            // デフォルト動作: 選択状態のトグル（ハプティックフィードバック付き）
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif

            toggleSelection(for: photo)
        }
    }

    /// 選択状態のトグル
    private func toggleSelection(for photo: Photo) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedPhotos.contains(photo.id) {
                selectedPhotos.remove(photo.id)
            } else {
                selectedPhotos.insert(photo.id)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PhotoGrid_Previews: PreviewProvider {
    static var previews: some View {
        // サンプル写真データ
        let samplePhotos = (0..<20).map { index in
            Photo(
                id: "sample-\(index)",
                localIdentifier: "sample-local-id-\(index)",
                creationDate: Date().addingTimeInterval(TimeInterval(-index * 86400)),
                modificationDate: Date(),
                mediaType: index % 5 == 0 ? .video : .image,
                mediaSubtypes: index % 3 == 0 ? [.screenshot] : [],
                pixelWidth: 4032,
                pixelHeight: 3024,
                duration: index % 5 == 0 ? 45.5 : 0,
                fileSize: Int64.random(in: 1_000_000...5_000_000),
                isFavorite: index % 7 == 0
            )
        }

        // 3列グリッド
        PreviewWrapper(
            title: "3列グリッド（デフォルト）",
            photos: samplePhotos,
            columns: 3
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("3列グリッド (Dark)")

        // 4列グリッド
        PreviewWrapper(
            title: "4列グリッド",
            photos: samplePhotos,
            columns: 4
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("4列グリッド (Dark)")

        // 選択状態のグリッド
        PreviewWrapperWithSelection(
            title: "選択状態",
            photos: samplePhotos,
            columns: 3,
            initialSelection: Set(samplePhotos.prefix(5).map(\.id))
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("選択状態 (Dark)")

        // ベストショット表示
        PreviewWrapperWithBestShots(
            title: "ベストショット表示",
            photos: samplePhotos,
            columns: 3,
            bestShots: Set(samplePhotos.prefix(3).map(\.id))
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("ベストショット (Dark)")

        // 空状態
        PreviewWrapper(
            title: "空状態",
            photos: [],
            columns: 3
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("空状態 (Dark)")

        // ライトモード
        PreviewWrapper(
            title: "ライトモード",
            photos: samplePhotos,
            columns: 3
        )
        .preferredColorScheme(.light)
        .previewDisplayName("ライトモード")
    }

    // MARK: - Preview Helpers

    /// 基本的なプレビューラッパー
    struct PreviewWrapper: View {
        let title: String
        let photos: [Photo]
        let columns: Int
        @State private var selectedPhotos: Set<String> = []

        var body: some View {
            NavigationStack {
                PhotoGrid(
                    photos: photos,
                    columns: columns,
                    selectedPhotos: $selectedPhotos
                )
                .navigationTitle(title)
                #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    #if canImport(UIKit)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !selectedPhotos.isEmpty {
                            Button("クリア") {
                                selectedPhotos.removeAll()
                            }
                        }
                    }
                    #else
                    ToolbarItem(placement: .automatic) {
                        if !selectedPhotos.isEmpty {
                            Button("クリア") {
                                selectedPhotos.removeAll()
                            }
                        }
                    }
                    #endif
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.LightRoll.background,
                        Color.LightRoll.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    /// 選択状態付きプレビューラッパー
    struct PreviewWrapperWithSelection: View {
        let title: String
        let photos: [Photo]
        let columns: Int
        @State var selectedPhotos: Set<String>

        init(title: String, photos: [Photo], columns: Int, initialSelection: Set<String>) {
            self.title = title
            self.photos = photos
            self.columns = columns
            self._selectedPhotos = State(initialValue: initialSelection)
        }

        var body: some View {
            NavigationStack {
                PhotoGrid(
                    photos: photos,
                    columns: columns,
                    selectedPhotos: $selectedPhotos
                )
                .navigationTitle(title)
                #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    #if canImport(UIKit)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(selectedPhotos.count)枚選択")
                            .font(Font.LightRoll.caption)
                            .foregroundColor(Color.LightRoll.primary)
                    }
                    #else
                    ToolbarItem(placement: .automatic) {
                        Text("\(selectedPhotos.count)枚選択")
                            .font(Font.LightRoll.caption)
                            .foregroundColor(Color.LightRoll.primary)
                    }
                    #endif
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.LightRoll.background,
                        Color.LightRoll.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    /// ベストショット表示付きプレビューラッパー
    struct PreviewWrapperWithBestShots: View {
        let title: String
        let photos: [Photo]
        let columns: Int
        let bestShots: Set<String>
        @State private var selectedPhotos: Set<String> = []

        var body: some View {
            NavigationStack {
                PhotoGrid(
                    photos: photos,
                    columns: columns,
                    selectedPhotos: $selectedPhotos,
                    bestShotPhotos: bestShots
                )
                .navigationTitle(title)
                #if canImport(UIKit)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    #if canImport(UIKit)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(selectedPhotos.count)枚選択")
                                .font(Font.LightRoll.caption2)
                            Text("⭐️ \(bestShots.count)枚")
                                .font(Font.LightRoll.caption2)
                        }
                        .foregroundColor(Color.LightRoll.primary)
                    }
                    #else
                    ToolbarItem(placement: .automatic) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(selectedPhotos.count)枚選択")
                                .font(Font.LightRoll.caption2)
                            Text("⭐️ \(bestShots.count)枚")
                                .font(Font.LightRoll.caption2)
                        }
                        .foregroundColor(Color.LightRoll.primary)
                    }
                    #endif
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.LightRoll.background,
                        Color.LightRoll.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}
#endif
