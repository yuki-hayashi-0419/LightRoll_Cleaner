//
//  PremiumView.swift
//  LightRoll_CleanerFeature
//
//  M9-T12: PremiumView実装
//

import SwiftUI
import Observation

// MARK: - LoadingState

/// ロード状態を表すenum
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - PremiumView

/// Premium機能のメインUI
///
/// サブスクリプションプラン表示、購入、復元機能を提供します。
///
/// ## 使用例
/// ```swift
/// NavigationLink(destination: PremiumView()) {
///     Label("Premium", systemImage: "crown.fill")
/// }
/// .environment(premiumManager)
/// .environment(purchaseRepository)
/// ```
@MainActor
public struct PremiumView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PurchaseRepository.self) private var purchaseRepository

    @State private var productsLoadState: LoadingState = .idle
    @State private var purchaseState: LoadingState = .idle
    @State private var restoreState: LoadingState = .idle
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    public init() {}

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // ヘッダー
                headerView

                // 現在のステータス
                StatusCard(
                    isPremium: premiumManager.isPremium,
                    subscriptionStatus: premiumManager.subscriptionStatus,
                    remainingDeletions: premiumManager.dailyDeleteCount
                )

                // プラン表示
                if productsLoadState.isLoading {
                    ProgressView("プランを読み込み中...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if case .error(let message) = productsLoadState {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("プランの読み込みに失敗しました")
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("再試行") {
                            Task { await loadProducts() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 40)
                } else if !premiumManager.isPremium {
                    // プランカード
                    plansSection
                }

                // Premium機能説明
                featuresSection

                // 復元ボタン
                if !premiumManager.isPremium {
                    RestoreButton(
                        isLoading: restoreState.isLoading
                    ) {
                        Task { await handleRestore() }
                    }
                }

                // フッター
                FooterLinks()
            }
            .padding()
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadProducts()
        }
        .onChange(of: premiumManager.isPremium) { _, newValue in
            if newValue {
                // Premium状態になったら成功メッセージ
                successMessage = "Premiumにアップグレードされました！"
                showSuccessAlert = true
            }
        }
        .alert("成功", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("LightRoll Premium")
                .font(.largeTitle.bold())

            Text("無制限の削除と高度な機能をアンロック")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: 16) {
            ForEach(purchaseRepository.availableProducts) { product in
                PlanCard(
                    product: product,
                    isLoading: purchaseState.isLoading
                ) {
                    Task { await handlePurchase(product) }
                }
            }
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium機能")
                .font(.title2.bold())
                .padding(.horizontal)

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "無制限削除",
                    description: "1日の削除制限なしで、いつでも好きなだけ写真を整理できます"
                )

                FeatureRow(
                    icon: "eye.slash",
                    title: "広告非表示",
                    description: "広告なしの快適な体験で、アプリをスムーズに使用できます"
                )

                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "高度な分析",
                    description: "詳細な統計情報とインサイトで、写真ライブラリを深く理解できます"
                )

                FeatureRow(
                    icon: "icloud.fill",
                    title: "クラウドバックアップ",
                    description: "近日公開：削除前のバックアップで、安心して整理できます"
                )
                .opacity(0.5)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Actions

    private func loadProducts() async {
        productsLoadState = .loading

        do {
            try await purchaseRepository.fetchProducts()
            productsLoadState = .loaded
        } catch {
            productsLoadState = .error(handlePurchaseError(error))
        }
    }

    private func handlePurchase(_ product: ProductInfo) async {
        purchaseState = .loading

        do {
            _ = try await purchaseRepository.purchase(product.id)
            purchaseState = .loaded

            // Premium状態を更新
            try await premiumManager.checkPremiumStatus()

            successMessage = "\(product.displayName)の購入が完了しました！"
            showSuccessAlert = true
        } catch {
            purchaseState = .idle
            errorMessage = handlePurchaseError(error)

            // キャンセルの場合はアラート表示なし
            if !errorMessage.contains("キャンセル") {
                showErrorAlert = true
            }
        }
    }

    private func handleRestore() async {
        restoreState = .loading

        do {
            try await purchaseRepository.restorePurchases()
            restoreState = .loaded

            // Premium状態を更新
            try await premiumManager.checkPremiumStatus()

            if premiumManager.isPremium {
                successMessage = "購入が復元されました！"
                showSuccessAlert = true
            } else {
                errorMessage = "復元する購入が見つかりませんでした"
                showErrorAlert = true
            }
        } catch {
            restoreState = .idle
            errorMessage = handlePurchaseError(error)
            showErrorAlert = true
        }
    }

    private func handlePurchaseError(_ error: Error) -> String {
        if let purchaseError = error as? PurchaseError {
            switch purchaseError {
            case .cancelled:
                return "購入がキャンセルされました"
            case .productNotFound:
                return "商品が見つかりませんでした"
            case .purchaseFailed(let message):
                return "購入に失敗しました: \(message)"
            case .invalidProduct:
                return "無効な商品です"
            case .networkError:
                return "ネットワークエラーが発生しました。接続を確認してください"
            case .unknown(let message):
                return "エラーが発生しました: \(message)"
            case .restorationFailed(let message):
                return "復元に失敗しました: \(message)"
            }
        }
        return "予期しないエラーが発生しました"
    }
}

// MARK: - StatusCard

private struct StatusCard: View {
    let isPremium: Bool
    let subscriptionStatus: PremiumStatus
    let remainingDeletions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isPremium {
                premiumStatusView
            } else {
                freeStatusView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isPremium ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPremium ? "Premium会員" : "Free版")
    }

    private var premiumStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Premium会員")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }

            if case .monthly(let startDate, let autoRenew) = subscriptionStatus {
                Text("月額プラン")
                    .font(.subheadline)

                if let renewalDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate) {
                    Text("次回更新: \(renewalDate, format: .dateTime.year().month().day())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(autoRenew ? "自動更新: ON" : "自動更新: OFF")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if case .yearly(let startDate, let autoRenew) = subscriptionStatus {
                Text("年額プラン")
                    .font(.subheadline)

                if let renewalDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) {
                    Text("次回更新: \(renewalDate, format: .dateTime.year().month().day())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(autoRenew ? "自動更新: ON" : "自動更新: OFF")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if case .lifetime = subscriptionStatus {
                Text("買い切りプラン")
                    .font(.subheadline)
            }
        }
    }

    private var freeStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                Text("Free版")
                    .font(.headline)
            }

            Text("今日の削除可能数: \(50 - remainingDeletions)枚")
                .font(.subheadline)

            Text("Premiumにアップグレードして無制限削除を利用しましょう")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - PlanCard

private struct PlanCard: View {
    let product: ProductInfo
    let isLoading: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.title2.bold())

                    if product.hasFreeTrial, let offer = product.introductoryOffer {
                        Text("\(offer.period)日間無料トライアル")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(product.priceFormatted)
                        .font(.title.bold())
                    Text(product.subscriptionPeriod == .monthly ? "/月" : "/年")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 説明
            Text(product.fullDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 購入ボタン
            Button {
                onPurchase()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isLoading ? "処理中..." : "購入する")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .accessibilityLabel("\(product.displayName)を購入")
            .accessibilityHint(product.priceDescription)
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - RestoreButton

private struct RestoreButton: View {
    let isLoading: Bool
    let onRestore: () -> Void

    var body: some View {
        Button {
            onRestore()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                Text(isLoading ? "復元中..." : "購入を復元")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.bordered)
        .disabled(isLoading)
        .accessibilityLabel("購入を復元")
        .accessibilityHint("以前購入したPremiumプランを復元します")
    }
}

// MARK: - FooterLinks

private struct FooterLinks: View {
    var body: some View {
        VStack(spacing: 8) {
            Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                .font(.caption)

            Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
                .font(.caption)
        }
        .padding(.vertical)
        .foregroundColor(.secondary)
    }
}

// MARK: - Previews

#Preview("Free User") {
    NavigationStack {
        PremiumView()
            .environment(MockPremiumManager(isPremiumValue: false))
            .environment(MockPurchaseRepository())
    }
}

#Preview("Premium User") {
    NavigationStack {
        PremiumView()
            .environment(MockPremiumManager(isPremiumValue: true))
            .environment(MockPurchaseRepository())
    }
}

#Preview("Loading") {
    NavigationStack {
        PremiumView()
            .environment(MockPremiumManager(isPremiumValue: false))
            .environment(MockPurchaseRepository(loading: true))
    }
}

#Preview("Error") {
    NavigationStack {
        PremiumView()
            .environment(MockPremiumManager(isPremiumValue: false))
            .environment(MockPurchaseRepository(error: true))
    }
}

// MARK: - Mock for Preview

@MainActor
@Observable
final class MockPurchaseRepository: PurchaseRepositoryProtocol {
    var availableProducts: [ProductInfo]
    var loading: Bool
    var hasError: Bool

    init(loading: Bool = false, error: Bool = false) {
        self.loading = loading
        self.hasError = error

        // Mock products
        self.availableProducts = [
            .monthlyPlan(id: "monthly", price: 5.99, priceFormatted: "¥600"),
            .yearlyPlan(id: "yearly", price: 49.99, priceFormatted: "¥5,000")
        ]
    }

    func fetchProducts() async throws -> [ProductInfo] {
        if hasError {
            throw PurchaseError.networkError
        }
        try await Task.sleep(nanoseconds: 500_000_000)
        return availableProducts
    }

    func purchase(_ productId: String) async throws -> PurchaseResult {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return .pending
    }

    func restorePurchases() async throws -> RestoreResult {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return RestoreResult(transactions: [])
    }

    func checkSubscriptionStatus() async throws -> PremiumStatus {
        return .free
    }

    func startTransactionListener() {}
    func stopTransactionListener() {}
}
