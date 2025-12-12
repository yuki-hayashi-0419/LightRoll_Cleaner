//
//  LimitReachedSheet.swift
//  LightRoll_CleanerFeature
//
//  M9-T13: LimitReachedSheet実装
//  削除上限に達した時のシート表示とプレミアムプロモーション
//

import SwiftUI

/// 削除上限到達時に表示するシート
///
/// Free版ユーザーが1日の削除上限（50枚）に達した時に表示され、
/// Premium版へのアップグレードを促します。
///
/// ## 使用例
/// ```swift
/// .sheet(isPresented: $showLimitReached) {
///     LimitReachedSheet(
///         currentCount: 50,
///         dailyLimit: 50
///     ) {
///         // Premiumページへ移動
///         navigationPath.append(.premium)
///     }
/// }
/// ```
@MainActor
public struct LimitReachedSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// 現在の削除カウント
    let currentCount: Int

    /// 1日の削除上限
    let dailyLimit: Int

    /// Premiumページへ移動するアクション
    let onUpgradeTap: () -> Void

    /// 初期化
    /// - Parameters:
    ///   - currentCount: 現在の削除カウント
    ///   - dailyLimit: 1日の削除上限（デフォルト: 50）
    ///   - onUpgradeTap: Premiumページへ移動するアクション
    public init(
        currentCount: Int,
        dailyLimit: Int = 50,
        onUpgradeTap: @escaping () -> Void
    ) {
        self.currentCount = currentCount
        self.dailyLimit = dailyLimit
        self.onUpgradeTap = onUpgradeTap
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダーアイコン
                    headerIcon

                    // メインメッセージ
                    messageSection

                    // 統計情報
                    statsSection

                    // Premium機能のハイライト
                    featuresSection

                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("削除上限到達")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .accessibilityLabel("シートを閉じる")
                }
            }
            .interactiveDismissDisabled(false)
        }
    }

    // MARK: - Header Icon

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.2), .red.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .accessibilityHidden(true)
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(spacing: 16) {
            Text("本日の削除上限に達しました")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Free版では1日に\(dailyLimit)枚まで削除できます。\nPremiumにアップグレードして無制限に削除しましょう！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("本日の削除上限\(dailyLimit)枚に達しました。Premiumにアップグレードして無制限に削除できます")
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 0) {
            StatCard(
                title: "本日の削除数",
                value: "\(currentCount)",
                icon: "photo.on.rectangle.angled",
                color: .blue
            )

            Divider()
                .frame(height: 60)
                .padding(.horizontal, 8)

            StatCard(
                title: "残り削除可能",
                value: "0",
                icon: "clock.fill",
                color: .orange
            )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premiumで解決！")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                PremiumFeatureRow(
                    icon: "infinity",
                    title: "無制限削除",
                    description: "1日の制限なし"
                )

                PremiumFeatureRow(
                    icon: "eye.slash.fill",
                    title: "広告非表示",
                    description: "快適な操作"
                )

                PremiumFeatureRow(
                    icon: "chart.bar.fill",
                    title: "高度な分析",
                    description: "詳細な統計"
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Premiumアップグレードボタン
            Button {
                onUpgradeTap()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Premiumにアップグレード")
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
            .accessibilityLabel("Premiumにアップグレード")
            .accessibilityHint("Premium機能の詳細ページへ移動します")

            // 後でボタン
            Button {
                dismiss()
            } label: {
                Text("後で")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("後で")
            .accessibilityHint("シートを閉じて後でアップグレードします")
        }
        .padding(.horizontal)
    }
}

// MARK: - StatCard

/// 統計カード
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - PremiumFeatureRow

/// Premium機能の行
private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Previews

#Preview("Default") {
    LimitReachedSheet(
        currentCount: 50,
        dailyLimit: 50
    ) {
        print("Upgrade tapped")
    }
}

#Preview("Custom Limit") {
    LimitReachedSheet(
        currentCount: 100,
        dailyLimit: 100
    ) {
        print("Upgrade tapped")
    }
}

#Preview("In Navigation") {
    NavigationStack {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                LimitReachedSheet(
                    currentCount: 50,
                    dailyLimit: 50
                ) {
                    print("Upgrade tapped")
                }
            }
    }
}
