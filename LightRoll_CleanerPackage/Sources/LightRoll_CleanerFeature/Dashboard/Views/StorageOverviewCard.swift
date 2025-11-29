//
//  StorageOverviewCard.swift
//  LightRoll_CleanerFeature
//
//  ストレージ概要を表示するカードコンポーネント
//  ダッシュボードのメインカードとして使用
//  StorageStatisticsモデルを使用して統計情報を表示
//  Created by AI Assistant (M5-T06)
//

import SwiftUI

// MARK: - StorageOverviewCard

/// ストレージ概要を表示するカードコンポーネント
/// ダッシュボードのメイン表示として、ストレージ使用状況と削減可能容量を視覚的に表示
///
/// ## 主な機能
/// - 円グラフまたはバーでストレージ使用状況を表示
/// - 写真ライブラリの使用容量を表示
/// - 削減可能な容量をハイライト表示
/// - グループサマリーへの導線
///
/// ## 使用例
/// ```swift
/// StorageOverviewCard(
///     statistics: storageStatistics,
///     onScanTap: { await startScan() }
/// )
/// ```
@MainActor
public struct StorageOverviewCard: View {

    // MARK: - Properties

    /// 表示する統計情報
    let statistics: StorageStatistics

    /// 表示スタイル
    let displayStyle: DisplayStyle

    /// スキャンボタンのタップアクション（オプション）
    let onScanTap: (() async -> Void)?

    /// グループサマリータップ時のアクション
    let onGroupTap: ((GroupType) -> Void)?

    // MARK: - State

    /// アニメーション用の進捗値
    @State private var animatedProgress: Double = 0

    /// 表示されているかどうか
    @State private var isAppeared: Bool = false

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - statistics: ストレージ統計情報
    ///   - displayStyle: 表示スタイル（デフォルト: .full）
    ///   - onScanTap: スキャンボタンのタップアクション
    ///   - onGroupTap: グループサマリータップ時のアクション
    public init(
        statistics: StorageStatistics,
        displayStyle: DisplayStyle = .full,
        onScanTap: (() async -> Void)? = nil,
        onGroupTap: ((GroupType) -> Void)? = nil
    ) {
        self.statistics = statistics
        self.displayStyle = displayStyle
        self.onScanTap = onScanTap
        self.onGroupTap = onGroupTap
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: LRSpacing.lg) {
            // ヘッダー
            headerSection

            // メインコンテンツ
            switch displayStyle {
            case .full:
                fullContentSection
            case .compact:
                compactContentSection
            case .minimal:
                minimalContentSection
            }
        }
        .padding(LRSpacing.cardPadding)
        .glassCard(cornerRadius: LRLayout.cornerRadiusLG, style: .thick)
        .onAppear {
            // 表示時のアニメーション
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = statistics.storageInfo.usagePercentage
                isAppeared = true
            }
        }
        .onChange(of: statistics.storageInfo.usagePercentage) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ストレージ概要")
        .accessibilityIdentifier("StorageOverviewCard")
    }

    // MARK: - Subviews

    /// ヘッダーセクション
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                Text("ストレージ概要")
                    .font(Font.LightRoll.headline)
                    .foregroundColor(Color.LightRoll.textPrimary)

                Text(statistics.formattedRelativeTimestamp)
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.textTertiary)
            }

            Spacer()

            // ステータスバッジ
            statusBadge
        }
    }

    /// ステータスバッジ
    private var statusBadge: some View {
        Group {
            if statistics.storageInfo.isCriticalStorage {
                Label("危険", systemImage: "exclamationmark.triangle.fill")
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.error)
                    .padding(.horizontal, LRSpacing.sm)
                    .padding(.vertical, LRSpacing.xxs)
                    .background(Color.LightRoll.error.opacity(0.15))
                    .clipShape(Capsule())
            } else if statistics.storageInfo.isLowStorage {
                Label("警告", systemImage: "exclamationmark.circle.fill")
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.warning)
                    .padding(.horizontal, LRSpacing.sm)
                    .padding(.vertical, LRSpacing.xxs)
                    .background(Color.LightRoll.warning.opacity(0.15))
                    .clipShape(Capsule())
            } else if statistics.hasSignificantSavings {
                Label("削減可能", systemImage: "checkmark.circle.fill")
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.success)
                    .padding(.horizontal, LRSpacing.sm)
                    .padding(.vertical, LRSpacing.xxs)
                    .background(Color.LightRoll.success.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    /// フルコンテンツセクション
    private var fullContentSection: some View {
        VStack(spacing: LRSpacing.lg) {
            // ストレージビジュアル
            storageVisualSection

            Divider()
                .background(Color.LightRoll.textTertiary.opacity(0.3))

            // 写真ライブラリ情報
            photosLibrarySection

            // 削減可能容量セクション（あれば）
            if statistics.hasData {
                reclaimableSection
            }

            // グループサマリー
            if !statistics.sortedGroupSummaries.isEmpty {
                groupSummarySection
            }
        }
    }

    /// コンパクトコンテンツセクション
    private var compactContentSection: some View {
        VStack(spacing: LRSpacing.md) {
            // ストレージバー
            StorageIndicator(
                storageInfo: statistics.storageInfo,
                showDetails: false,
                style: .bar
            )

            // 削減可能容量
            if statistics.totalReclaimableSize > 0 {
                compactReclaimableRow
            }
        }
    }

    /// ミニマルコンテンツセクション
    private var minimalContentSection: some View {
        HStack {
            // リング表示
            StorageIndicator(
                storageInfo: statistics.storageInfo,
                showDetails: false,
                style: .ring
            )
            .frame(width: 80, height: 80)

            Spacer()

            // 削減可能容量
            if statistics.totalReclaimableSize > 0 {
                VStack(alignment: .trailing, spacing: LRSpacing.xs) {
                    Text("削減可能")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)

                    Text(statistics.formattedTotalReclaimableSize)
                        .font(Font.LightRoll.title3)
                        .foregroundColor(Color.LightRoll.success)
                }
            }
        }
    }

    /// ストレージビジュアルセクション
    private var storageVisualSection: some View {
        HStack(spacing: LRSpacing.xl) {
            // リング表示
            StorageIndicator(
                storageInfo: statistics.storageInfo,
                showDetails: false,
                style: .ring
            )

            // テキスト情報
            VStack(alignment: .leading, spacing: LRSpacing.sm) {
                // 使用量
                VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                    Text("使用中")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)

                    Text(statistics.storageInfo.formattedUsedCapacity)
                        .font(Font.LightRoll.title3)
                        .foregroundColor(Color.LightRoll.textPrimary)
                }

                // 空き容量
                VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                    Text("空き容量")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)

                    Text(statistics.storageInfo.formattedAvailableCapacity)
                        .font(Font.LightRoll.callout)
                        .foregroundColor(storageStatusColor)
                }
            }
        }
    }

    /// 写真ライブラリセクション
    private var photosLibrarySection: some View {
        HStack {
            HStack(spacing: LRSpacing.sm) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: LRLayout.iconSizeMD))
                    .foregroundColor(Color.LightRoll.storagePhotos)

                VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                    Text("写真ライブラリ")
                        .font(Font.LightRoll.callout)
                        .foregroundColor(Color.LightRoll.textSecondary)

                    Text("\(statistics.scannedPhotoCount)枚")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textTertiary)
                }
            }

            Spacer()

            Text(statistics.storageInfo.formattedPhotosUsedCapacity)
                .font(Font.LightRoll.headline)
                .foregroundColor(Color.LightRoll.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("写真ライブラリ: \(statistics.scannedPhotoCount)枚、\(statistics.storageInfo.formattedPhotosUsedCapacity)")
    }

    /// 削減可能容量セクション
    private var reclaimableSection: some View {
        HStack {
            HStack(spacing: LRSpacing.sm) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: LRLayout.iconSizeMD))
                    .foregroundColor(Color.LightRoll.success)

                VStack(alignment: .leading, spacing: LRSpacing.xxs) {
                    Text("削減可能")
                        .font(Font.LightRoll.callout)
                        .foregroundColor(Color.LightRoll.textSecondary)

                    Text("\(statistics.totalGroupedPhotoCount)枚")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: LRSpacing.xxs) {
                Text(statistics.formattedTotalReclaimableSize)
                    .font(Font.LightRoll.headline)
                    .foregroundColor(Color.LightRoll.success)

                Text(String(format: "%.1f%%削減", statistics.savingsPercentage))
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.success.opacity(0.8))
            }
        }
        .padding(LRSpacing.md)
        .background(Color.LightRoll.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: LRLayout.cornerRadiusMD, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("削減可能: \(statistics.formattedTotalReclaimableSize)")
    }

    /// コンパクト版削減可能行
    private var compactReclaimableRow: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: LRLayout.iconSizeSM))
                .foregroundColor(Color.LightRoll.success)

            Text("削減可能")
                .font(Font.LightRoll.caption)
                .foregroundColor(Color.LightRoll.textSecondary)

            Spacer()

            Text(statistics.formattedTotalReclaimableSize)
                .font(Font.LightRoll.callout)
                .foregroundColor(Color.LightRoll.success)
                .fontWeight(.semibold)
        }
    }

    /// グループサマリーセクション
    private var groupSummarySection: some View {
        VStack(alignment: .leading, spacing: LRSpacing.md) {
            Text("グループ別")
                .font(Font.LightRoll.subheadline)
                .foregroundColor(Color.LightRoll.textSecondary)

            VStack(spacing: LRSpacing.sm) {
                ForEach(statistics.sortedGroupSummaries.prefix(4)) { summary in
                    GroupSummaryRow(
                        summary: summary,
                        onTap: onGroupTap != nil ? { onGroupTap?(summary.type) } : nil
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// ストレージ状態に応じた色
    private var storageStatusColor: Color {
        if statistics.storageInfo.isCriticalStorage {
            return Color.LightRoll.error
        } else if statistics.storageInfo.isLowStorage {
            return Color.LightRoll.warning
        } else {
            return Color.LightRoll.success
        }
    }
}

// MARK: - DisplayStyle

extension StorageOverviewCard {
    /// 表示スタイル
    public enum DisplayStyle: Sendable {
        /// フル表示（全情報を表示）
        case full
        /// コンパクト表示（主要情報のみ）
        case compact
        /// ミニマル表示（最小限の情報）
        case minimal
    }
}

// MARK: - GroupSummaryRow

/// グループサマリーの1行表示
@MainActor
struct GroupSummaryRow: View {
    let summary: GroupSummary
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: LRSpacing.sm) {
                // アイコン
                Image(systemName: summary.icon)
                    .font(.system(size: LRLayout.iconSizeSM))
                    .foregroundColor(Color.LightRoll.primary)
                    .frame(width: LRLayout.iconSizeMD)

                // グループ名
                Text(summary.displayName)
                    .font(Font.LightRoll.callout)
                    .foregroundColor(Color.LightRoll.textPrimary)

                // 写真枚数
                Text("\(summary.photoCount)枚")
                    .font(Font.LightRoll.caption)
                    .foregroundColor(Color.LightRoll.textTertiary)

                Spacer()

                // 削減可能容量
                Text(summary.formattedReclaimableSize)
                    .font(Font.LightRoll.smallNumber)
                    .foregroundColor(Color.LightRoll.success)

                // 矢印（タップ可能な場合）
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: LRLayout.iconSizeXS, weight: .semibold))
                        .foregroundColor(Color.LightRoll.textTertiary)
                }
            }
            .padding(.vertical, LRSpacing.xs)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.displayName): \(summary.photoCount)枚、削減可能: \(summary.formattedReclaimableSize)")
        .accessibilityHint(onTap != nil ? "タップして詳細を表示" : "")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
}

// MARK: - Preview

#if DEBUG
struct StorageOverviewCard_Previews: PreviewProvider {
    static var previews: some View {
        // サンプルデータ
        let normalStats = createSampleStatistics(
            usagePercentage: 0.5,
            reclaimableGB: 3.5
        )

        let warningStats = createSampleStatistics(
            usagePercentage: 0.92,
            reclaimableGB: 8.0
        )

        let criticalStats = createSampleStatistics(
            usagePercentage: 0.97,
            reclaimableGB: 12.0
        )

        let emptyStats = StorageStatistics.fromDevice()

        // ダークモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                Text("Storage Overview Card")
                    .font(Font.LightRoll.title2)
                    .foregroundColor(Color.LightRoll.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // フル表示 - 正常状態
                Group {
                    Text("フル表示 - 正常状態")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: normalStats,
                        displayStyle: .full,
                        onScanTap: { print("スキャン開始") },
                        onGroupTap: { type in print("グループタップ: \(type)") }
                    )
                }

                // フル表示 - 警告状態
                Group {
                    Text("フル表示 - 警告状態")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: warningStats,
                        displayStyle: .full
                    )
                }

                // フル表示 - 危険状態
                Group {
                    Text("フル表示 - 危険状態")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: criticalStats,
                        displayStyle: .full
                    )
                }

                // コンパクト表示
                Group {
                    Text("コンパクト表示")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: normalStats,
                        displayStyle: .compact
                    )
                }

                // ミニマル表示
                Group {
                    Text("ミニマル表示")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: normalStats,
                        displayStyle: .minimal
                    )
                }

                // データなし
                Group {
                    Text("データなし")
                        .font(Font.LightRoll.caption)
                        .foregroundColor(Color.LightRoll.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StorageOverviewCard(
                        statistics: emptyStats,
                        displayStyle: .full
                    )
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
        .previewDisplayName("Storage Overview Card (Dark)")

        // ライトモードプレビュー
        ScrollView {
            VStack(spacing: LRSpacing.xl) {
                StorageOverviewCard(
                    statistics: normalStats,
                    displayStyle: .full
                )

                StorageOverviewCard(
                    statistics: warningStats,
                    displayStyle: .compact
                )

                StorageOverviewCard(
                    statistics: normalStats,
                    displayStyle: .minimal
                )
            }
            .padding()
        }
        .background(Color.LightRoll.background)
        .preferredColorScheme(.light)
        .previewDisplayName("Storage Overview Card (Light)")
    }

    // サンプル統計データ生成
    private static func createSampleStatistics(
        usagePercentage: Double,
        reclaimableGB: Double
    ) -> StorageStatistics {
        let totalCapacity: Int64 = 128_000_000_000
        let usedCapacity = Int64(Double(totalCapacity) * usagePercentage)
        let availableCapacity = totalCapacity - usedCapacity
        let photosUsed = Int64(Double(usedCapacity) * 0.4)
        let reclaimable = Int64(reclaimableGB * 1_000_000_000)

        let storageInfo = StorageInfo(
            totalCapacity: totalCapacity,
            availableCapacity: availableCapacity,
            photosUsedCapacity: photosUsed,
            reclaimableCapacity: reclaimable
        )

        let groupSummaries: [GroupType: GroupSummary] = [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 45,
                photoCount: 342,
                totalSize: 2_100_000_000,
                reclaimableSize: Int64(reclaimableGB * 0.4 * 1_000_000_000)
            ),
            .screenshot: GroupSummary(
                type: .screenshot,
                groupCount: 1,
                photoCount: 256,
                totalSize: 1_200_000_000,
                reclaimableSize: Int64(reclaimableGB * 0.2 * 1_000_000_000)
            ),
            .blurry: GroupSummary(
                type: .blurry,
                groupCount: 1,
                photoCount: 89,
                totalSize: 520_000_000,
                reclaimableSize: Int64(reclaimableGB * 0.15 * 1_000_000_000)
            ),
            .largeVideo: GroupSummary(
                type: .largeVideo,
                groupCount: 1,
                photoCount: 12,
                totalSize: 3_800_000_000,
                reclaimableSize: Int64(reclaimableGB * 0.25 * 1_000_000_000)
            )
        ]

        return StorageStatistics(
            storageInfo: storageInfo,
            groupSummaries: groupSummaries,
            scannedPhotoCount: 2500,
            scannedVideoCount: 150
        )
    }
}

// MARK: - Modern Previews (iOS 17+)

#Preview("フル表示") {
    let stats = StorageStatistics(
        storageInfo: StorageInfo(
            totalCapacity: 128_000_000_000,
            availableCapacity: 64_000_000_000,
            photosUsedCapacity: 25_000_000_000,
            reclaimableCapacity: 3_500_000_000
        ),
        groupSummaries: [
            .similar: GroupSummary(
                type: .similar,
                groupCount: 45,
                photoCount: 342,
                totalSize: 2_100_000_000,
                reclaimableSize: 1_400_000_000
            )
        ],
        scannedPhotoCount: 2500
    )

    StorageOverviewCard(
        statistics: stats,
        displayStyle: .full
    )
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

#Preview("コンパクト表示") {
    let stats = StorageStatistics(
        storageInfo: StorageInfo(
            totalCapacity: 64_000_000_000,
            availableCapacity: 5_000_000_000,
            photosUsedCapacity: 40_000_000_000,
            reclaimableCapacity: 8_000_000_000
        ),
        scannedPhotoCount: 1500
    )

    StorageOverviewCard(
        statistics: stats,
        displayStyle: .compact
    )
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
