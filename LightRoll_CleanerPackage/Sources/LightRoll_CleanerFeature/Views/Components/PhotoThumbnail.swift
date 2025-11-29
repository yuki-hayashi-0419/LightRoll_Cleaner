//
//  PhotoThumbnail.swift
//  LightRoll_CleanerFeature
//
//  写真サムネイル表示コンポーネント
//  グラスモーフィズム効果、選択状態、ベストショットバッジ、動画対応を含む
//  Created by AI Assistant
//

import SwiftUI
import Photos
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PhotoThumbnail

/// 写真サムネイル表示コンポーネント
/// グリッド表示に最適化された正方形サムネイル
/// 選択状態、ベストショットバッジ、動画アイコンに対応
public struct PhotoThumbnail: View {
    // MARK: - Properties

    /// 表示する写真
    let photo: Photo

    /// 選択状態
    let isSelected: Bool

    /// ベストショットバッジを表示するか
    let showBadge: Bool

    // MARK: - State

    /// サムネイル画像（非同期読み込み）
    #if canImport(UIKit)
    @State private var thumbnailImage: UIImage?
    #else
    @State private var thumbnailImage: NSImage?
    #endif

    /// 画像読み込み中フラグ
    @State private var isLoading: Bool = true

    /// 画像読み込みエラーフラグ
    @State private var loadError: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photo: 表示する写真
    ///   - isSelected: 選択状態（デフォルト: false）
    ///   - showBadge: ベストショットバッジ表示（デフォルト: false）
    public init(
        photo: Photo,
        isSelected: Bool = false,
        showBadge: Bool = false
    ) {
        self.photo = photo
        self.isSelected = isSelected
        self.showBadge = showBadge
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景とサムネイル画像
                thumbnailContent(size: geometry.size)

                // 動画アイコン（動画の場合のみ）
                if photo.isVideo {
                    videoOverlay
                }

                // ベストショットバッジ
                if showBadge {
                    bestShotBadge
                }

                // 選択状態オーバーレイ
                if isSelected {
                    selectionOverlay
                }
            }
            .aspectRatio(1.0, contentMode: .fill)
            .lightRollCornerRadius(LRLayout.cornerRadiusSM)
            .overlay {
                // 選択時のボーダー
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: LRLayout.cornerRadiusSM,
                        style: .continuous
                    )
                    .stroke(
                        Color.LightRoll.primary,
                        lineWidth: LRLayout.borderWidthThick
                    )
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .aspectRatio(1.0, contentMode: .fit)
        .task {
            await loadThumbnail()
        }
    }

    // MARK: - Subviews

    /// サムネイル画像とローディング状態
    @ViewBuilder
    private func thumbnailContent(size: CGSize) -> some View {
        if let image = thumbnailImage {
            // 画像が読み込まれた場合
            #if canImport(UIKit)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
            #else
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
            #endif
        } else if isLoading {
            // 読み込み中
            ZStack {
                Color.LightRoll.surfaceCard
                ProgressView()
                    .tint(Color.LightRoll.primary)
            }
        } else if loadError {
            // エラー状態
            ZStack {
                Color.LightRoll.surfaceCard
                VStack(spacing: LRSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: LRLayout.iconSizeMD))
                        .foregroundColor(Color.LightRoll.error)
                    Text("読込失敗")
                        .font(Font.LightRoll.caption2)
                        .foregroundColor(Color.LightRoll.textSecondary)
                }
            }
        } else {
            // 画像なし（予期しない状態）
            Color.LightRoll.surfaceCard
        }
    }

    /// 動画アイコンオーバーレイ
    private var videoOverlay: some View {
        VStack {
            HStack {
                Spacer()

                // 動画再生アイコン
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(
                            width: LRLayout.iconSizeXL,
                            height: LRLayout.iconSizeXL
                        )

                    Image(systemName: "play.fill")
                        .font(.system(size: LRLayout.iconSizeSM))
                        .foregroundColor(.white)
                }
                .padding(LRSpacing.xs)
            }

            Spacer()

            // 動画の長さ表示
            if !photo.formattedDuration.isEmpty {
                HStack {
                    Spacer()

                    Text(photo.formattedDuration)
                        .font(Font.LightRoll.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, LRSpacing.xs)
                        .padding(.vertical, LRSpacing.xxs)
                        .background {
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        }
                        .padding(LRSpacing.xs)
                }
            }
        }
    }

    /// ベストショットバッジ
    private var bestShotBadge: some View {
        VStack {
            HStack {
                // 左上にバッジを配置
                ZStack {
                    Circle()
                        .fill(Color.LightRoll.accent)
                        .frame(
                            width: LRLayout.iconSizeLG,
                            height: LRLayout.iconSizeLG
                        )

                    Image(systemName: "star.fill")
                        .font(.system(size: LRLayout.iconSizeSM))
                        .foregroundColor(.white)
                }
                .glassBackground(
                    style: .thin,
                    shape: .circle,
                    showBorder: false,
                    showShadow: true
                )
                .padding(LRSpacing.xs)

                Spacer()
            }

            Spacer()
        }
    }

    /// 選択状態オーバーレイ
    private var selectionOverlay: some View {
        ZStack {
            // 半透明の青いオーバーレイ
            Color.LightRoll.primary.opacity(0.2)

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    // チェックマーク
                    ZStack {
                        Circle()
                            .fill(Color.LightRoll.primary)
                            .frame(
                                width: LRLayout.iconSizeLG,
                                height: LRLayout.iconSizeLG
                            )

                        Image(systemName: "checkmark")
                            .font(.system(size: LRLayout.iconSizeSM, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .glassBackground(
                        style: .thin,
                        shape: .circle,
                        showBorder: false,
                        showShadow: true
                    )
                    .padding(LRSpacing.xs)
                }
            }
        }
    }

    // MARK: - Accessibility

    /// アクセシビリティ用の説明文
    private var accessibilityDescription: String {
        var parts: [String] = []

        // メディアタイプ
        parts.append(photo.mediaType.localizedName)

        // 作成日時
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        parts.append(dateFormatter.string(from: photo.creationDate))

        // 動画の長さ
        if photo.isVideo, !photo.formattedDuration.isEmpty {
            parts.append("長さ: \(photo.formattedDuration)")
        }

        // ベストショット
        if showBadge {
            parts.append("ベストショット")
        }

        // 選択状態
        if isSelected {
            parts.append("選択済み")
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Image Loading

    /// サムネイル画像を非同期で読み込む
    @MainActor
    private func loadThumbnail() async {
        isLoading = true
        loadError = false

        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            isLoading = false
            loadError = true
            return
        }

        // 画像リクエストオプションの設定
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // サムネイルサイズを計算（Retina対応）
        #if canImport(UIKit)
        let scale = UIScreen.main.scale
        #else
        let scale: CGFloat = 2.0 // macOSデフォルト
        #endif
        let thumbnailSize = CGSize(
            width: LRLayout.thumbnailSizeMD * scale,
            height: LRLayout.thumbnailSizeMD * scale
        )

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                Task { @MainActor in
                    if let image = image {
                        self.thumbnailImage = image
                        self.loadError = false
                    } else {
                        self.loadError = true
                    }
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PhotoThumbnail_Previews: PreviewProvider {
    static var previews: some View {
        // サンプル写真データ
        let samplePhoto = Photo(
            id: "sample-1",
            localIdentifier: "sample-local-id",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 2_500_000,
            isFavorite: false
        )

        let sampleVideo = Photo(
            id: "sample-video-1",
            localIdentifier: "sample-video-local-id",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 45.5,
            fileSize: 15_000_000,
            isFavorite: false
        )

        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Photo Thumbnails")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)

                // 通常状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("通常状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    PhotoThumbnail(photo: samplePhoto)
                        .frame(width: 120, height: 120)
                }

                // 選択状態
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("選択状態")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    PhotoThumbnail(
                        photo: samplePhoto,
                        isSelected: true
                    )
                    .frame(width: 120, height: 120)
                }

                // ベストショットバッジ付き
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("ベストショットバッジ")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    PhotoThumbnail(
                        photo: samplePhoto,
                        showBadge: true
                    )
                    .frame(width: 120, height: 120)
                }

                // 選択 + バッジ
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("選択 + ベストショット")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    PhotoThumbnail(
                        photo: samplePhoto,
                        isSelected: true,
                        showBadge: true
                    )
                    .frame(width: 120, height: 120)
                }

                // 動画
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("動画（再生アイコン + 長さ表示）")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    PhotoThumbnail(photo: sampleVideo)
                        .frame(width: 120, height: 120)
                }

                // グリッド表示例
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("グリッド表示例（3列）")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(
                                .flexible(),
                                spacing: LRSpacing.gridSpacing
                            ),
                            count: 3
                        ),
                        spacing: LRSpacing.gridSpacing
                    ) {
                        PhotoThumbnail(photo: samplePhoto)
                        PhotoThumbnail(photo: samplePhoto, isSelected: true)
                        PhotoThumbnail(photo: samplePhoto, showBadge: true)
                        PhotoThumbnail(photo: sampleVideo)
                        PhotoThumbnail(photo: sampleVideo, isSelected: true)
                        PhotoThumbnail(photo: samplePhoto)
                    }
                }
            }
            .padding()
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
        .preferredColorScheme(.dark)
        .previewDisplayName("Photo Thumbnail (Dark)")

        // ライトモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Photo Thumbnails")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(
                            .flexible(),
                            spacing: LRSpacing.gridSpacing
                        ),
                        count: 3
                    ),
                    spacing: LRSpacing.gridSpacing
                ) {
                    PhotoThumbnail(photo: samplePhoto)
                    PhotoThumbnail(photo: samplePhoto, isSelected: true)
                    PhotoThumbnail(photo: samplePhoto, showBadge: true)
                    PhotoThumbnail(photo: sampleVideo)
                    PhotoThumbnail(photo: sampleVideo, isSelected: true)
                    PhotoThumbnail(photo: samplePhoto, isSelected: true, showBadge: true)
                }
            }
            .padding()
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
        .preferredColorScheme(.light)
        .previewDisplayName("Photo Thumbnail (Light)")
    }
}
#endif
