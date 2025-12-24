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
/// 選択状態、ベストショットバッジ、動画アイコン、ファイルサイズ・撮影日表示に対応
public struct PhotoThumbnail: View {
    // MARK: - Properties

    /// 表示する写真
    let photo: Photo

    /// 選択状態
    let isSelected: Bool

    /// ベストショットバッジを表示するか
    let showBadge: Bool

    /// ファイルサイズを表示するか
    /// DISPLAY-002: 表示設定からの反映
    let showFileSize: Bool

    /// 撮影日を表示するか
    /// DISPLAY-002: 表示設定からの反映
    let showDate: Bool

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

    /// 現在の画像リクエストID（キャンセル用）
    @State private var currentRequestId: PHImageRequestID?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photo: 表示する写真
    ///   - isSelected: 選択状態（デフォルト: false）
    ///   - showBadge: ベストショットバッジ表示（デフォルト: false）
    ///   - showFileSize: ファイルサイズ表示（デフォルト: false）
    ///   - showDate: 撮影日表示（デフォルト: false）
    public init(
        photo: Photo,
        isSelected: Bool = false,
        showBadge: Bool = false,
        showFileSize: Bool = false,
        showDate: Bool = false
    ) {
        self.photo = photo
        self.isSelected = isSelected
        self.showBadge = showBadge
        self.showFileSize = showFileSize
        self.showDate = showDate
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

                // 情報表示オーバーレイ（ファイルサイズ・撮影日）
                // DISPLAY-002: 表示設定に基づく情報表示
                if showFileSize || showDate {
                    photoInfoOverlay
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
        .onDisappear {
            // View解放時に進行中の画像リクエストをキャンセル
            cancelCurrentRequest()
        }
    }

    // MARK: - Request Cancellation

    /// 進行中の画像リクエストをキャンセル
    private func cancelCurrentRequest() {
        if let requestId = currentRequestId {
            PHImageManager.default().cancelImageRequest(requestId)
            currentRequestId = nil
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

    /// 情報表示オーバーレイ（ファイルサイズ・撮影日）
    /// DISPLAY-002: 表示設定に基づく情報表示
    /// 下部にグラデーションオーバーレイを配置し、テキストを表示
    private var photoInfoOverlay: some View {
        VStack {
            Spacer()

            // 下部にグラデーション背景とテキスト
            VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                // 撮影日表示
                if showDate {
                    Text(formattedCreationDate)
                        .font(Font.LightRoll.caption2)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                // ファイルサイズ表示
                if showFileSize {
                    Text(photo.formattedFileSize)
                        .font(Font.LightRoll.caption2)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LRSpacing.xs)
            .padding(.vertical, LRSpacing.xxs)
            .background {
                // グラデーション背景（下から上へ透明に）
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
        }
    }

    /// 撮影日のフォーマット済み文字列
    /// DISPLAY-002: 日付表示用ヘルパー
    private var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: photo.creationDate)
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
    /// DISPLAY-002: ファイルサイズ・撮影日情報を追加
    private var accessibilityDescription: String {
        var parts: [String] = []

        // メディアタイプ
        parts.append(photo.mediaType.localizedName)

        // 作成日時（撮影日表示時のみ詳細を読み上げ）
        if showDate {
            parts.append("撮影日: \(formattedCreationDate)")
        } else {
            // 基本的な日時情報
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            parts.append(dateFormatter.string(from: photo.creationDate))
        }

        // ファイルサイズ（表示時のみ）
        if showFileSize {
            parts.append("サイズ: \(photo.formattedFileSize)")
        }

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

    /// 画像読み込み結果を表す列挙型
    private enum ThumbnailLoadResult: Sendable {
        #if canImport(UIKit)
        case success(UIImage)
        #else
        case success(NSImage)
        #endif
        case cancelled
        case error
    }

    /// サムネイル画像を非同期で読み込む
    ///
    /// ## 重要: クラッシュ防止対策
    /// 以下の問題に対処:
    /// 1. View解放後の@State access → withCheckedContinuationで安全にラップ
    /// 2. PHImageManager.requestImageの二重コールバック → deliveryMode = .highQualityFormat
    /// 3. Taskキャンセル時の処理 → CancellationErrorをチェック
    ///
    /// ## 修正履歴
    /// - 2025-01-XX: View deallocate後のクラッシュ防止（P0バグ修正）
    @MainActor
    private func loadThumbnail() async {
        // 既存のリクエストをキャンセル
        cancelCurrentRequest()

        isLoading = true
        loadError = false

        // Taskキャンセルチェック
        guard !Task.isCancelled else {
            isLoading = false
            return
        }

        // PHAssetを取得
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            isLoading = false
            loadError = true
            print("⚠️ PhotoThumbnail: PHAsset not found for localIdentifier: \(photo.localIdentifier)")
            return
        }

        // Taskキャンセルチェック
        guard !Task.isCancelled else {
            isLoading = false
            return
        }

        // 画像リクエストオプションの設定
        // CRITICAL: deliveryMode を .highQualityFormat に設定
        // .opportunistic はコールバックを複数回呼び出すため使用禁止
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        // サムネイルサイズを計算（Retina対応）
        #if canImport(UIKit)
        let scale = await MainActor.run { UIScreen.main.scale }
        #else
        let scale: CGFloat = 2.0 // macOSデフォルト
        #endif
        let thumbnailSize = CGSize(
            width: LRLayout.thumbnailSizeMD * scale,
            height: LRLayout.thumbnailSizeMD * scale
        )

        // withCheckedContinuationを使用して安全に非同期処理をラップ
        // View解放時にTaskがキャンセルされるため、continuation resumeは1回のみ保証
        let result: ThumbnailLoadResult = await withCheckedContinuation { continuation in
            let requestId = PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // キャンセルされた場合
                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    continuation.resume(returning: .cancelled)
                    return
                }

                // エラーチェック
                if info?[PHImageErrorKey] as? Error != nil {
                    continuation.resume(returning: .error)
                    return
                }

                // 画像取得成功/失敗
                if let image = image {
                    continuation.resume(returning: .success(image))
                } else {
                    continuation.resume(returning: .error)
                }
            }

            // リクエストIDを保存（キャンセル用）
            Task { @MainActor in
                currentRequestId = requestId
            }
        }

        // Taskキャンセルチェック（continuation resume後）
        guard !Task.isCancelled else {
            isLoading = false
            currentRequestId = nil
            return
        }

        // 結果を適用（@MainActor保証下で安全に状態更新）
        switch result {
        case .success(let image):
            thumbnailImage = image
            loadError = false
        case .cancelled:
            // キャンセル時は何もしない
            break
        case .error:
            loadError = true
        }

        isLoading = false
        currentRequestId = nil
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
