//
//  GroupCard.swift
//  LightRoll_CleanerFeature
//
//  類似写真グループ表示カードコンポーネント
//  PhotoThumbnailを活用したグループ情報の表示とタップアクション
//  Created by AI Assistant
//

import SwiftUI

// MARK: - GroupCard

/// 類似写真グループを表示するカードコンポーネント
/// グループ情報（タイトル、写真枚数、削減可能容量）とサムネイルを表示
/// グラスモーフィズム効果とタップアクションに対応
public struct GroupCard: View {
    // MARK: - Properties

    /// 表示するグループ
    let group: PhotoGroup

    /// グループ内の代表写真（最大3枚まで表示）
    let representativePhotos: [Photo]

    /// タップ時のアクション
    let onTap: () -> Void

    // MARK: - State

    /// プレスアニメーション用の状態
    @State private var isPressed: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - group: 表示する写真グループ
    ///   - representativePhotos: グループ内の代表写真（最大3枚）
    ///   - onTap: タップ時のアクション
    public init(
        group: PhotoGroup,
        representativePhotos: [Photo],
        onTap: @escaping () -> Void
    ) {
        self.group = group
        self.representativePhotos = Array(representativePhotos.prefix(3))
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        Button(action: {
            onTap()
        }) {
            cardContent
        }
        .buttonStyle(GroupCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("タップしてグループの詳細を表示")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    /// カードのメインコンテンツ
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: LRSpacing.md) {
            // ヘッダー: アイコン + タイトル
            headerSection

            // サムネイルプレビュー
            thumbnailPreview

            // フッター: 写真枚数 + 削減可能容量
            footerSection
        }
        .padding(LRSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(
            cornerRadius: LRLayout.cornerRadiusLG,
            style: .regular
        )
    }

    /// ヘッダーセクション（アイコン + タイトル）
    private var headerSection: some View {
        HStack(spacing: LRSpacing.sm) {
            // グループタイプのアイコン
            ZStack {
                Circle()
                    .fill(Color.LightRoll.primary.opacity(0.2))
                    .frame(
                        width: LRLayout.iconSizeXL,
                        height: LRLayout.iconSizeXL
                    )

                Image(systemName: group.type.icon)
                    .font(.system(size: LRLayout.iconSizeMD))
                    .foregroundColor(Color.LightRoll.primary)
            }

            // グループ名
            Text(group.displayName)
                .font(Font.LightRoll.headline)
                .foregroundColor(Color.LightRoll.textPrimary)
                .lineLimit(1)

            Spacer()

            // 右矢印アイコン
            Image(systemName: "chevron.right")
                .font(.system(size: LRLayout.iconSizeSM, weight: .semibold))
                .foregroundColor(Color.LightRoll.textTertiary)
        }
    }

    /// サムネイルプレビュー（最大3枚）
    private var thumbnailPreview: some View {
        HStack(spacing: LRSpacing.gridSpacing) {
            if representativePhotos.isEmpty {
                // 写真がない場合のプレースホルダー
                placeholderThumbnails
            } else {
                // 代表写真のサムネイル
                ForEach(representativePhotos) { photo in
                    PhotoThumbnail(
                        photo: photo,
                        isSelected: false,
                        showBadge: group.bestShotId == photo.id
                    )
                    .frame(
                        width: thumbnailSize,
                        height: thumbnailSize
                    )
                }

                // 3枚未満の場合はプレースホルダーで埋める
                if representativePhotos.count < 3 {
                    ForEach(0..<(3 - representativePhotos.count), id: \.self) { _ in
                        placeholderThumbnail
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// プレースホルダーサムネイル（写真がない場合）
    private var placeholderThumbnails: some View {
        ForEach(0..<3, id: \.self) { _ in
            placeholderThumbnail
        }
    }

    /// 単一のプレースホルダーサムネイル
    private var placeholderThumbnail: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: LRLayout.cornerRadiusSM,
                style: .continuous
            )
            .fill(Color.LightRoll.surfaceCard)

            Image(systemName: "photo")
                .font(.system(size: LRLayout.iconSizeMD))
                .foregroundColor(Color.LightRoll.textTertiary)
        }
        .frame(
            width: thumbnailSize,
            height: thumbnailSize
        )
    }

    /// フッターセクション（写真枚数 + 削減可能容量）
    private var footerSection: some View {
        HStack(spacing: LRSpacing.lg) {
            // 写真枚数
            HStack(spacing: LRSpacing.xs) {
                Image(systemName: "photo.stack")
                    .font(.system(size: LRLayout.iconSizeSM))
                    .foregroundColor(Color.LightRoll.textSecondary)

                Text("\(group.count)枚")
                    .font(Font.LightRoll.callout)
                    .foregroundColor(Color.LightRoll.textSecondary)
            }

            Spacer()

            // 削減可能容量
            HStack(spacing: LRSpacing.xs) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: LRLayout.iconSizeSM))
                    .foregroundColor(Color.LightRoll.success)

                Text(group.formattedReclaimableSize)
                    .font(Font.LightRoll.smallNumber)
                    .foregroundColor(Color.LightRoll.success)
            }
        }
    }

    // MARK: - Computed Properties

    /// サムネイルのサイズ（カードの幅に合わせて計算）
    private var thumbnailSize: CGFloat {
        // カード幅から計算（3列 + グリッドスペース + パディング）
        // 概算値として 80pt を使用
        LRLayout.thumbnailSizeMD
    }

    /// アクセシビリティ用の説明文
    var accessibilityDescription: String {
        var parts: [String] = []

        // グループタイプ
        parts.append(group.displayName)

        // 写真枚数
        parts.append("\(group.count)枚の写真")

        // 削減可能容量
        if group.reclaimableSize > 0 {
            parts.append("削減可能容量: \(group.formattedReclaimableSize)")
        }

        // ベストショット情報
        if group.bestShotIndex != nil {
            parts.append("ベストショット選定済み")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - GroupCardButtonStyle

/// GroupCard専用のボタンスタイル
/// タップ時のプレスアニメーションを提供
private struct GroupCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct GroupCard_Previews: PreviewProvider {
    static var previews: some View {
        // サンプルデータ
        let samplePhotos = (0..<3).map { index in
            Photo(
                id: "sample-photo-\(index)",
                localIdentifier: "sample-local-id-\(index)",
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

        let sampleGroup = PhotoGroup(
            type: .similar,
            photoIds: samplePhotos.map { $0.id },
            fileSizes: samplePhotos.map { $0.fileSize },
            bestShotIndex: 0
        )

        let screenshotGroup = PhotoGroup(
            type: .screenshot,
            photoIds: Array(repeating: "screenshot-1", count: 15),
            fileSizes: Array(repeating: 1_200_000, count: 15)
        )

        let blurryGroup = PhotoGroup(
            type: .blurry,
            photoIds: Array(repeating: "blurry-1", count: 8),
            fileSizes: Array(repeating: 3_500_000, count: 8),
            bestShotIndex: nil
        )

        let largeVideoGroup = PhotoGroup(
            type: .largeVideo,
            photoIds: Array(repeating: "video-1", count: 3),
            fileSizes: Array(repeating: 150_000_000, count: 3)
        )

        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Group Cards")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // 類似写真グループ（ベストショット付き）
                VStack(alignment: .leading, spacing: LRSpacing.sm) {
                    Text("類似写真グループ（ベストショット選定済み）")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .padding(.horizontal)

                    GroupCard(
                        group: sampleGroup,
                        representativePhotos: samplePhotos
                    ) {
                        print("類似写真グループをタップ")
                    }
                    .padding(.horizontal)
                }

                // スクリーンショットグループ
                VStack(alignment: .leading, spacing: LRSpacing.sm) {
                    Text("スクリーンショットグループ")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .padding(.horizontal)

                    GroupCard(
                        group: screenshotGroup,
                        representativePhotos: samplePhotos
                    ) {
                        print("スクリーンショットグループをタップ")
                    }
                    .padding(.horizontal)
                }

                // ブレ写真グループ（ベストショットなし）
                VStack(alignment: .leading, spacing: LRSpacing.sm) {
                    Text("ブレ写真グループ（ベストショット未選定）")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .padding(.horizontal)

                    GroupCard(
                        group: blurryGroup,
                        representativePhotos: samplePhotos
                    ) {
                        print("ブレ写真グループをタップ")
                    }
                    .padding(.horizontal)
                }

                // 大容量動画グループ
                VStack(alignment: .leading, spacing: LRSpacing.sm) {
                    Text("大容量動画グループ")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .padding(.horizontal)

                    GroupCard(
                        group: largeVideoGroup,
                        representativePhotos: samplePhotos
                    ) {
                        print("大容量動画グループをタップ")
                    }
                    .padding(.horizontal)
                }

                // 写真なしのグループ（プレースホルダー表示）
                VStack(alignment: .leading, spacing: LRSpacing.sm) {
                    Text("写真なし（プレースホルダー表示）")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .padding(.horizontal)

                    GroupCard(
                        group: sampleGroup,
                        representativePhotos: []
                    ) {
                        print("空グループをタップ")
                    }
                    .padding(.horizontal)
                }

                // グリッド表示例
                VStack(alignment: .leading, spacing: LRSpacing.md) {
                    Text("リスト表示例")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)
                        .padding(.horizontal)

                    VStack(spacing: LRSpacing.md) {
                        GroupCard(
                            group: sampleGroup,
                            representativePhotos: samplePhotos
                        ) {
                            print("グループ1をタップ")
                        }

                        GroupCard(
                            group: screenshotGroup,
                            representativePhotos: samplePhotos
                        ) {
                            print("グループ2をタップ")
                        }

                        GroupCard(
                            group: blurryGroup,
                            representativePhotos: samplePhotos
                        ) {
                            print("グループ3をタップ")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
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
        .previewDisplayName("Group Card (Dark)")

        // ライトモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.lg) {
                GroupCard(
                    group: sampleGroup,
                    representativePhotos: samplePhotos
                ) {
                    print("類似写真グループをタップ")
                }

                GroupCard(
                    group: screenshotGroup,
                    representativePhotos: samplePhotos
                ) {
                    print("スクリーンショットグループをタップ")
                }

                GroupCard(
                    group: largeVideoGroup,
                    representativePhotos: samplePhotos
                ) {
                    print("大容量動画グループをタップ")
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
        .previewDisplayName("Group Card (Light)")
    }
}
#endif
