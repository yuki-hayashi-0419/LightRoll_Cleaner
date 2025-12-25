//
//  LimitReachedSheet.swift
//  LightRoll_CleanerFeature
//
//  削除制限到達時に表示されるPaywallシート
//  "Try & Lock"マネタイズモデルの実装
//

import SwiftUI

// MARK: - LimitReachedSheet

/// 削除制限到達時に表示されるPaywallシート
///
/// Free版で生涯削除上限（50枚）に達した際に表示し、
/// 具体的な価値訴求と7日間無料トライアルでPremiumプランへの転換を促します。
///
/// ## 使用例
/// ```swift
/// .sheet(isPresented: $showLimitReached) {
///     LimitReachedSheet(
///         currentCount: 50,
///         limit: 50,
///         remainingDuplicates: 450,
///         potentialFreeSpace: "2.5 GB",
///         onUpgrade: {
///             // Premiumページへ遷移
///         }
///     )
/// }
/// ```
@MainActor
public struct LimitReachedSheet: View {

    // MARK: - Properties

    /// 現在の削除数
    let currentCount: Int

    /// 削除上限
    let limit: Int

    /// 残りの重複写真数（価値訴求用）
    let remainingDuplicates: Int?

    /// 解放可能なストレージ容量（価値訴求用）
    let potentialFreeSpace: String?

    /// アップグレードアクション
    let onUpgrade: () -> Void

    /// シートを閉じるためのEnvironment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// LimitReachedSheetを初期化
    /// - Parameters:
    ///   - currentCount: 現在の削除数
    ///   - limit: 削除上限（デフォルト: 50）
    ///   - remainingDuplicates: 残りの重複写真数（価値訴求用）
    ///   - potentialFreeSpace: 解放可能なストレージ容量（例: "2.5 GB"）
    ///   - onUpgrade: アップグレードボタンタップ時のアクション
    public init(
        currentCount: Int,
        limit: Int = 50,
        remainingDuplicates: Int? = nil,
        potentialFreeSpace: String? = nil,
        onUpgrade: @escaping () -> Void
    ) {
        self.currentCount = currentCount
        self.limit = limit
        self.remainingDuplicates = remainingDuplicates
        self.potentialFreeSpace = potentialFreeSpace
        self.onUpgrade = onUpgrade
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー: 価値実感メッセージ
                    headerSection

                    // 価値訴求カード
                    valuePropositionCard

                    // 7日間無料トライアルCTA
                    freeTrialCallToAction

                    // 料金プラン（3つ）
                    pricingPlans

                    // Premium機能紹介
                    premiumFeaturesSection

                    Spacer(minLength: 20)

                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("無料版の制限に到達")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .accessibilityLabel("シートを閉じる")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.2), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .accessibilityHidden(true)

            // タイトル
            Text("価値を実感していただけましたか？")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Free版では\(limit)枚まで削除できます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Value Proposition Card

    private var valuePropositionCard: some View {
        VStack(spacing: 16) {
            // 削除実績
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("削除した写真")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(currentCount)枚")
                        .font(.title.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
            }

            Divider()

            // 残りの価値訴求
            if let remaining = remainingDuplicates, remaining > 0 {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("まだ削除できる重複写真")
                            .font(.subheadline.bold())

                        Text("あと\(remaining)枚の重複があります")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            if let freeSpace = potentialFreeSpace {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("解放可能なストレージ")
                            .font(.subheadline.bold())

                        Text("約\(freeSpace)の空き容量を確保できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(16)
    }

    // MARK: - Free Trial CTA

    private var freeTrialCallToAction: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("7日間無料トライアル")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("今だけ")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(4)
            }

            Text("すべてのプレミアム機能を1週間無料でお試しいただけます")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Pricing Plans

    private var pricingPlans: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プランを選択")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                // 年額プラン（推奨）
                PricingPlanRow(
                    title: "年額プラン",
                    price: "¥2,000",
                    period: "/年",
                    badge: "50%割引",
                    savings: "月額プランより約¥1,600お得",
                    isRecommended: true
                )

                // 月額プラン
                PricingPlanRow(
                    title: "月額プラン",
                    price: "¥300",
                    period: "/月",
                    badge: "7日間無料",
                    savings: nil,
                    isRecommended: false
                )

                // 買い切りプラン
                PricingPlanRow(
                    title: "買い切りプラン",
                    price: "¥3,000",
                    period: "（一度きり）",
                    badge: "サブスクなし",
                    savings: "永久にすべての機能を利用可能",
                    isRecommended: false
                )
            }
        }
    }

    // MARK: - Premium Features Section

    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("Premiumプランの特典")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "無制限削除",
                    description: "何枚でも削除できます"
                )

                FeatureRow(
                    icon: "eye.slash.fill",
                    title: "広告非表示",
                    description: "快適な操作体験"
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "無制限スキャン",
                    description: "いつでもスキャンできます"
                )

                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "高度な分析",
                    description: "詳細な統計情報"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Premiumを試す
            Button {
                dismiss()
                onUpgrade()
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("7日間無料で試す")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .accessibilityLabel("7日間無料でPremiumを試す")
            .accessibilityHint("すべてのプレミアム機能が1週間無料で利用できます")

            // 後で
            Button {
                dismiss()
            } label: {
                Text("後で確認する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .accessibilityLabel("後で確認する")
            .accessibilityHint("シートを閉じます")
        }
    }
}

// MARK: - PricingPlanRow

private struct PricingPlanRow: View {
    let title: String
    let price: String
    let period: String
    let badge: String
    let savings: String?
    let isRecommended: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())

                    if isRecommended {
                        Text("おすすめ")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                    }
                }

                if let savings = savings {
                    Text(savings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title3.bold())
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(badge)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isRecommended ?
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                    lineWidth: isRecommended ? 2 : 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRecommended ? Color.orange.opacity(0.05) : Color.clear)
        )
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Previews

#Preview("Limit Reached - With Value") {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            LimitReachedSheet(
                currentCount: 50,
                limit: 50,
                remainingDuplicates: 450,
                potentialFreeSpace: "2.5 GB",
                onUpgrade: {
                    print("Upgrade tapped")
                }
            )
        }
}

#Preview("Limit Reached - Basic") {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            LimitReachedSheet(
                currentCount: 50,
                limit: 50,
                onUpgrade: {
                    print("Upgrade tapped")
                }
            )
        }
}
