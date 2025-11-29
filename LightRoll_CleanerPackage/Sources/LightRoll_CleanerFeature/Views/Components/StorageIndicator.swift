//
//  StorageIndicator.swift
//  LightRoll_CleanerFeature
//
//  ストレージ使用量の視覚的インジケータコンポーネント
//  プログレスバー/円グラフで使用量・空き容量を表示
//  Created by AI Assistant (M4-T07)
//

import SwiftUI

// MARK: - StorageIndicator

/// ストレージ使用量の視覚的インジケータコンポーネント
/// プログレスバー形式で使用量・空き容量を表示し、警告状態も色で判別可能
public struct StorageIndicator: View {

    // MARK: - Properties

    /// ストレージ情報
    let storageInfo: StorageInfo

    /// 詳細情報を表示するか
    let showDetails: Bool

    /// インジケータのスタイル
    let style: IndicatorStyle

    // MARK: - State

    /// アニメーション用の進捗値
    @State private var animatedProgress: Double = 0

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - storageInfo: ストレージ情報
    ///   - showDetails: 詳細情報の表示有無（デフォルト: true）
    ///   - style: インジケータスタイル（デフォルト: .bar）
    public init(
        storageInfo: StorageInfo,
        showDetails: Bool = true,
        style: IndicatorStyle = .bar
    ) {
        self.storageInfo = storageInfo
        self.showDetails = showDetails
        self.style = style
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: LRSpacing.md) {
            // ヘッダー（使用量サマリー）
            if showDetails {
                storageHeader
            }

            // インジケータ本体
            switch style {
            case .bar:
                storageBar
            case .ring:
                storageRing
            }

            // 詳細情報
            if showDetails {
                storageDetails
            }
        }
        .onAppear {
            // スムーズなアニメーションで進捗を表示
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = storageInfo.usagePercentage
            }
        }
        .onChange(of: storageInfo.usagePercentage) { oldValue, newValue in
            // 値が変更されたらアニメーション
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue("\(Int(storageInfo.usagePercentage * 100))%使用中")
        .accessibilityIdentifier("StorageIndicator")
    }

    // MARK: - Subviews

    /// ストレージヘッダー（使用量サマリー）
    private var storageHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                Text("ストレージ使用量")
                    .font(Font.LightRoll.subheadline)
                    .foregroundColor(Color.LightRoll.textSecondary)

                Text(storageInfo.formattedUsedCapacity)
                    .font(Font.LightRoll.title3)
                    .foregroundColor(Color.LightRoll.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: LRSpacing.xxs) {
                Text("空き容量")
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.textTertiary)

                Text(storageInfo.formattedAvailableCapacity)
                    .font(Font.LightRoll.callout)
                    .foregroundColor(usageColor)
            }
        }
    }

    /// バー形式のストレージインジケータ
    private var storageBar: some View {
        VStack(alignment: .leading, spacing: LRSpacing.xs) {
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景（空き容量）
                    RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM, style: .continuous)
                        .fill(Color.LightRoll.storageFree.opacity(0.2))

                    // 使用量バー
                    RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    usageColor,
                                    usageColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress)

                    // 削減可能容量のオーバーレイ（ある場合）
                    if storageInfo.hasSignificantReclaimable {
                        reclaimableOverlay(width: geometry.size.width)
                    }
                }
            }
            .frame(height: 24)

            // パーセント表示
            HStack {
                Text(storageInfo.formattedUsagePercentage)
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.textSecondary)

                Spacer()

                // 警告アイコン
                if storageInfo.isCriticalStorage {
                    Label("危険", systemImage: "exclamationmark.triangle.fill")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.error)
                        .labelStyle(.iconOnly)
                } else if storageInfo.isLowStorage {
                    Label("警告", systemImage: "exclamationmark.circle.fill")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.warning)
                        .labelStyle(.iconOnly)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ストレージバー")
        .accessibilityValue(accessibilityDescription)
    }

    /// リング形式のストレージインジケータ
    private var storageRing: some View {
        VStack(spacing: LRSpacing.md) {
            ZStack {
                // 背景リング
                Circle()
                    .stroke(
                        Color.LightRoll.storageFree.opacity(0.2),
                        lineWidth: 12
                    )

                // 使用量リング
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        usageColor,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))

                // 中央のテキスト
                VStack(spacing: LRSpacing.xxs) {
                    Text(storageInfo.formattedUsagePercentage)
                        .font(Font.LightRoll.mediumNumber)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    Text("使用中")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("ストレージリング")
            .accessibilityValue(accessibilityDescription)
        }
    }

    /// 削減可能容量のオーバーレイ
    private func reclaimableOverlay(width: CGFloat) -> some View {
        let reclaimableWidth = width * storageInfo.reclaimablePercentage * animatedProgress

        return HStack {
            Spacer()

            RoundedRectangle(cornerRadius: LRLayout.cornerRadiusSM, style: .continuous)
                .fill(
                    Color.LightRoll.success.opacity(0.4)
                )
                .frame(width: reclaimableWidth)
        }
        .accessibilityHidden(true)
    }

    /// ストレージ詳細情報
    private var storageDetails: some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            Divider()
                .background(Color.LightRoll.textTertiary.opacity(0.3))

            // 写真使用容量
            DetailRow(
                icon: "photo.stack",
                label: "写真ライブラリ",
                value: storageInfo.formattedPhotosUsedCapacity,
                color: Color.LightRoll.storagePhotos
            )

            // 削減可能容量
            if storageInfo.hasSignificantReclaimable {
                DetailRow(
                    icon: "arrow.down.circle",
                    label: "削減可能",
                    value: storageInfo.formattedReclaimableCapacity,
                    color: Color.LightRoll.success
                )
            }

            // 総容量
            DetailRow(
                icon: "internaldrive",
                label: "デバイス容量",
                value: storageInfo.formattedTotalCapacity,
                color: Color.LightRoll.textSecondary
            )
        }
    }

    // MARK: - Computed Properties

    /// 使用量に応じた色
    private var usageColor: Color {
        if storageInfo.isCriticalStorage {
            return Color.LightRoll.error
        } else if storageInfo.isLowStorage {
            return Color.LightRoll.warning
        } else {
            return Color.LightRoll.storageUsed
        }
    }

    /// アクセシビリティ用の説明
    private var accessibilityDescription: String {
        var description = "ストレージ使用量 \(storageInfo.formattedUsedCapacity)、"
        description += "空き容量 \(storageInfo.formattedAvailableCapacity)、"

        if storageInfo.isCriticalStorage {
            description += "危険レベル"
        } else if storageInfo.isLowStorage {
            description += "警告レベル"
        } else {
            description += "正常"
        }

        return description
    }
}

// MARK: - IndicatorStyle

extension StorageIndicator {
    /// インジケータのスタイル
    public enum IndicatorStyle: Sendable {
        /// プログレスバー形式
        case bar
        /// リング（円形）形式
        case ring
    }
}

// MARK: - DetailRow

/// ストレージ詳細情報の1行
private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: LRSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: LRLayout.iconSizeMD))
                .foregroundColor(color)
                .frame(width: LRLayout.iconSizeLG)

            Text(label)
                .font(Font.LightRoll.callout)
                .foregroundColor(Color.LightRoll.textSecondary)

            Spacer()

            Text(value)
                .font(Font.LightRoll.callout)
                .foregroundColor(Color.LightRoll.textPrimary)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}

// MARK: - Preview

#if DEBUG
struct StorageIndicator_Previews: PreviewProvider {
    static var previews: some View {
        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                // 正常状態
                Group {
                    Text("正常状態 (50%使用)")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    StorageIndicator(
                        storageInfo: StorageInfo(
                            totalCapacity: 128_000_000_000,
                            availableCapacity: 64_000_000_000,
                            photosUsedCapacity: 25_000_000_000,
                            reclaimableCapacity: 3_500_000_000
                        ),
                        showDetails: true,
                        style: .bar
                    )
                    .cardPadding()
                    .glassCard()
                }

                // 警告状態
                Group {
                    Text("警告状態 (92%使用)")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    StorageIndicator(
                        storageInfo: StorageInfo(
                            totalCapacity: 64_000_000_000,
                            availableCapacity: 5_000_000_000,
                            photosUsedCapacity: 40_000_000_000,
                            reclaimableCapacity: 8_000_000_000
                        ),
                        showDetails: true,
                        style: .bar
                    )
                    .cardPadding()
                    .glassCard()
                }

                // 危険状態
                Group {
                    Text("危険状態 (97%使用)")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    StorageIndicator(
                        storageInfo: StorageInfo(
                            totalCapacity: 128_000_000_000,
                            availableCapacity: 3_000_000_000,
                            photosUsedCapacity: 80_000_000_000,
                            reclaimableCapacity: 12_000_000_000
                        ),
                        showDetails: true,
                        style: .bar
                    )
                    .cardPadding()
                    .glassCard()
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // リングスタイル
                Group {
                    Text("リングスタイル")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    HStack(spacing: LRSpacing.lg) {
                        StorageIndicator(
                            storageInfo: StorageInfo(
                                totalCapacity: 128_000_000_000,
                                availableCapacity: 64_000_000_000,
                                photosUsedCapacity: 25_000_000_000,
                                reclaimableCapacity: 3_500_000_000
                            ),
                            showDetails: false,
                            style: .ring
                        )

                        StorageIndicator(
                            storageInfo: StorageInfo(
                                totalCapacity: 64_000_000_000,
                                availableCapacity: 5_000_000_000,
                                photosUsedCapacity: 40_000_000_000,
                                reclaimableCapacity: 8_000_000_000
                            ),
                            showDetails: false,
                            style: .ring
                        )
                    }
                    .cardPadding()
                    .glassCard()
                }

                // 詳細なしのバー
                Group {
                    Text("詳細なし")
                        .font(Font.LightRoll.headline)
                        .foregroundColor(Color.LightRoll.textPrimary)

                    StorageIndicator(
                        storageInfo: StorageInfo(
                            totalCapacity: 128_000_000_000,
                            availableCapacity: 64_000_000_000,
                            photosUsedCapacity: 25_000_000_000,
                            reclaimableCapacity: 3_500_000_000
                        ),
                        showDetails: false,
                        style: .bar
                    )
                    .cardPadding()
                    .glassCard()
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.primary.opacity(0.3),
                    Color.LightRoll.secondary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Storage Indicator (Dark)")

        // ライトモードプレビュー
        VStack(spacing: LRSpacing.xl) {
            StorageIndicator(
                storageInfo: StorageInfo(
                    totalCapacity: 128_000_000_000,
                    availableCapacity: 64_000_000_000,
                    photosUsedCapacity: 25_000_000_000,
                    reclaimableCapacity: 3_500_000_000
                ),
                showDetails: true,
                style: .bar
            )
            .cardPadding()
            .glassCard()

            StorageIndicator(
                storageInfo: StorageInfo(
                    totalCapacity: 64_000_000_000,
                    availableCapacity: 5_000_000_000,
                    photosUsedCapacity: 40_000_000_000,
                    reclaimableCapacity: 8_000_000_000
                ),
                showDetails: false,
                style: .ring
            )
            .cardPadding()
            .glassCard()
        }
        .padding()
        .background(Color.LightRoll.background)
        .preferredColorScheme(.light)
        .previewDisplayName("Storage Indicator (Light)")
    }
}
#endif
