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

    // MARK: - State

    /// StoreKitから取得した製品情報（動的価格表示用）
    @State private var loadedProducts: [ProductInfo] = []

    /// 製品情報読み込み中フラグ
    @State private var isLoadingProducts = false

    /// 選択中のプラン（デフォルト: 月額プラン＝7日間無料トライアル付き）
    @State private var selectedPlan: ProductIdentifier = .monthlyPremium

    /// 購入処理中フラグ
    @State private var isPurchasing = false

    /// 購入エラーメッセージ
    @State private var purchaseError: String? = nil

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
        .task {
            // シート表示時にStoreKitから最新の価格情報を取得
            isLoadingProducts = true
            if let products = try? await StoreKitManager.shared.loadProducts() {
                loadedProducts = products
            }
            isLoadingProducts = false
        }
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
                    price: yearlyPrice,
                    period: "/年",
                    badge: "50%割引",
                    savings: yearlySavingsText,
                    isRecommended: true,
                    isSelected: selectedPlan == .yearlyPremium,
                    onSelect: { selectedPlan = .yearlyPremium }
                )

                // 月額プラン
                PricingPlanRow(
                    title: "月額プラン",
                    price: monthlyPrice,
                    period: "/月",
                    badge: "7日間無料",
                    savings: nil,
                    isRecommended: false,
                    isSelected: selectedPlan == .monthlyPremium,
                    onSelect: { selectedPlan = .monthlyPremium }
                )

                // 買い切りプラン
                PricingPlanRow(
                    title: "買い切りプラン",
                    price: lifetimePrice,
                    period: "（一度きり）",
                    badge: "サブスクなし",
                    savings: "永久にすべての機能を利用可能",
                    isRecommended: false,
                    isSelected: selectedPlan == .lifetimePremium,
                    onSelect: { selectedPlan = .lifetimePremium }
                )
            }
        }
    }

    // MARK: - Dynamic Price Helpers

    /// 年額プランの表示価格
    private var yearlyPrice: String {
        loadedProducts.first(where: { $0.id == ProductIdentifier.yearlyPremium.rawValue })?.priceFormatted ?? "¥2,000"
    }

    /// 月額プランの表示価格
    private var monthlyPrice: String {
        loadedProducts.first(where: { $0.id == ProductIdentifier.monthlyPremium.rawValue })?.priceFormatted ?? "¥300"
    }

    /// 買い切りプランの表示価格
    private var lifetimePrice: String {
        loadedProducts.first(where: { $0.id == ProductIdentifier.lifetimePremium.rawValue })?.priceFormatted ?? "¥3,000"
    }

    /// 年額プランのお得額テキスト
    private var yearlySavingsText: String {
        let yearly = loadedProducts.first(where: { $0.id == ProductIdentifier.yearlyPremium.rawValue })
        let monthly = loadedProducts.first(where: { $0.id == ProductIdentifier.monthlyPremium.rawValue })
        if let yearlyProduct = yearly, let monthlyProduct = monthly {
            let savings = monthlyProduct.price * 12 - yearlyProduct.price
            if savings > 0 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = Locale.current
                let savingsStr = formatter.string(from: savings as NSDecimalNumber) ?? ""
                return "月額プランより約\(savingsStr)お得"
            }
        }
        return "月額プランより約¥1,600お得"
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
            // エラーメッセージ表示
            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // メインCTAボタン（選択中プランを購入）
            Button {
                Task {
                    await purchaseSelectedPlan()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                    }
                    Text(mainButtonLabel)
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
                .opacity(isPurchasing ? 0.8 : 1.0)
            }
            .disabled(isPurchasing)
            .accessibilityLabel(mainButtonLabel)
            .accessibilityHint("選択中のプランで購入を開始します")

            // 購入を復元
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("購入を復元")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
            }
            .disabled(isPurchasing)
            .accessibilityLabel("購入を復元する")
            .accessibilityHint("以前の購入履歴を復元します")

            // 後で
            Button {
                dismiss()
            } label: {
                Text("後で確認する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            .disabled(isPurchasing)
            .accessibilityLabel("後で確認する")
            .accessibilityHint("シートを閉じます")
        }
    }

    // MARK: - Main Button Label

    /// 選択プランに応じたボタンラベル
    private var mainButtonLabel: String {
        switch selectedPlan {
        case .monthlyPremium:
            return "7日間無料で試す（月額プラン）"
        case .yearlyPremium:
            return "年額プランで始める"
        case .lifetimePremium:
            return "買い切りプランで購入"
        }
    }

    // MARK: - Purchase Actions

    /// 選択中プランを購入する
    private func purchaseSelectedPlan() async {
        isPurchasing = true
        purchaseError = nil

        do {
            _ = try await StoreKitManager.shared.purchase(selectedPlan.rawValue)
            // 購入成功 → シートを閉じてコールバック実行
            dismiss()
            onUpgrade()
        } catch PurchaseError.purchaseCancelled {
            // ユーザーがキャンセル → エラー表示なし
        } catch PurchaseError.productNotFound {
            // 製品が未ロードの場合は先にロードして再試行
            if let _ = try? await StoreKitManager.shared.loadProducts() {
                do {
                    _ = try await StoreKitManager.shared.purchase(selectedPlan.rawValue)
                    dismiss()
                    onUpgrade()
                } catch PurchaseError.purchaseCancelled {
                    // キャンセル → 何もしない
                } catch {
                    purchaseError = error.localizedDescription
                }
            } else {
                purchaseError = "製品情報の取得に失敗しました。ネットワーク接続を確認してください。"
            }
        } catch {
            // その他のエラー → エラーメッセージを表示
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
    }

    /// 購入を復元する
    private func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil

        do {
            _ = try await StoreKitManager.shared.restorePurchases()
            // 復元成功 → シートを閉じてコールバック実行
            dismiss()
            onUpgrade()
        } catch PurchaseError.noActiveSubscription {
            purchaseError = "復元できる購入履歴が見つかりませんでした"
        } catch {
            purchaseError = error.localizedDescription
        }

        isPurchasing = false
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
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 選択インジケーター
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ?
                        AnyShapeStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(Color.gray.opacity(0.4))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

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
                            .foregroundColor(.primary)
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
                        isSelected ?
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
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
                        lineWidth: isSelected ? 2 : (isRecommended ? 2 : 1)
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.05) : (isRecommended ? Color.orange.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(price)\(period)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
