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
    ///
    /// ## 重要: PHImageManager.requestImage の二重コールバック対策
    /// Photos Frameworkの `requestImage` は以下の場合に複数回コールバックを呼ぶ：
    /// - deliveryMode = .opportunistic の場合（低解像度→高解像度）
    /// - iCloud写真のダウンロード中
    ///
    /// この問題を解決するため、以下の対策を実施：
    /// 1. deliveryMode を .highQualityFormat に変更し、コールバックを1回のみに
    /// 2. Continuationは使用せず、直接Task内で状態更新
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
        // CRITICAL: deliveryMode を .highQualityFormat に設定
        // .opportunistic はコールバックを複数回呼び出すため、Continuationと相性が悪い
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat  // 変更: .opportunistic → .highQualityFormat
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

        // Continuationを使用せず、コールバックベースで直接状態更新
        // deliveryMode = .highQualityFormat により、コールバックは必ず1回のみ呼ばれる
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            Task { @MainActor in
                // キャンセルされた場合は何もしない
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    isLoading = false
                    return
                }

                // エラーチェック
                if info?[PHImageErrorKey] as? Error != nil {
                    loadError = true
                    isLoading = false
                    return
                }

                if let image = image {
                    thumbnailImage = image
                    loadError = false
                } else {
                    loadError = true
                }
                isLoading = false
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

// MARK: - Modern Previews (iOS 17+)

#Preview("通常状態") {
    PhotoThumbnail(photo: MockPhoto.standard)
        .frame(width: 120, height: 120)
        .padding()
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

#Preview("選択状態") {
    PhotoThumbnail(
        photo: MockPhoto.standard,
        isSelected: true
    )
    .frame(width: 120, height: 120)
    .padding()
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

#Preview("ベストショットバッジ") {
    PhotoThumbnail(
        photo: MockPhoto.standard,
        showBadge: true
    )
    .frame(width: 120, height: 120)
    .padding()
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
#endif
