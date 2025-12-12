//
//  LimitReachedSheet.swift
//  LightRoll_CleanerFeature
//
//  M9-T13: LimitReachedSheet実装
//  削除制限到達時に表示されるシート
//

import SwiftUI

// MARK: - LimitReachedSheet

/// 削除制限到達時に表示されるシート
///
/// Free版で1日の削除上限（50枚）に達した際に表示し、
/// Premiumプランへのアップグレードを促します。
///
/// ## 使用例
/// ```swift
/// .sheet(isPresented: $showLimitReached) {
///     LimitReachedSheet(
///         currentCount: 50,
///         limit: 50,
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

    /// アップグレードアクション
    let onUpgrade: () -> Void

    /// シートを閉じるためのEnvironment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// LimitReachedSheetを初期化
    /// - Parameters:
    ///   - currentCount: 現在の削除数
    ///   - limit: 削除上限（デフォルト: 50）
    ///   - onUpgrade: アップグレードボタンタップ時のアクション
    public init(
        currentCount: Int,
        limit: Int = 50,
        onUpgrade: @escaping () -> Void
    ) {
        self.currentCount = currentCount
        self.limit = limit
        self.onUpgrade = onUpgrade
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // アイコン
                    iconView

                    // タイトルとメッセージ
                    titleSection

                    // 制限情報
                    limitInfoCard

                    // Premium機能紹介
                    premiumFeaturesSection

                    Spacer(minLength: 20)

                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("削除制限に到達")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 100, height: 100)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("本日の削除上限に到達しました")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Free版では1日に\(limit)枚まで削除できます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("本日の削除上限に到達しました。Free版では1日に\(limit)枚まで削除できます")
    }

    // MARK: - Limit Info Card

    private var limitInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の削除数")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(currentCount)枚")
                        .font(.title.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("上限")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(limit)枚")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                }
            }

            Divider()

            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)

                Text("明日になれば再度削除できるようになります")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日の削除数\(currentCount)枚、上限\(limit)枚。明日になれば再度削除できるようになります")
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

                Text("Premiumプランなら")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "無制限削除",
                    description: "1日の削除制限なし"
                )

                FeatureRow(
                    icon: "eye.slash",
                    title: "広告非表示",
                    description: "快適な操作体験"
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
            // Premiumにアップグレード
            Button {
                dismiss()
                onUpgrade()
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
            .accessibilityHint("Premiumプランの詳細を確認します")

            // 後で
            Button {
                dismiss()
            } label: {
                Text("後で")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .accessibilityLabel("後で確認する")
            .accessibilityHint("シートを閉じます")
        }
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
                .foregroundColor(.orange)
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

#Preview("Limit Reached") {
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

#Preview("Custom Limit") {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            LimitReachedSheet(
                currentCount: 25,
                limit: 25,
                onUpgrade: {
                    print("Upgrade tapped")
                }
            )
        }
}

#Preview("Near Limit") {
    Text("Main View")
        .sheet(isPresented: .constant(true)) {
            LimitReachedSheet(
                currentCount: 48,
                limit: 50,
                onUpgrade: {
                    print("Upgrade tapped")
                }
            )
        }
}
