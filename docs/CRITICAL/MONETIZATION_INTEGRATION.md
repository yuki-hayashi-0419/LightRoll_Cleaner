# マネタイズコンポーネント統合ガイド

## 概要

このドキュメントは、Phase 1で実装したマネタイズコンポーネントをLightRoll Cleanerアプリに統合する手順を説明します。

## 実装済みコンポーネント

### 1. ScanLimitManager
- **目的**: Freeユーザーのスキャンを初回のみに制限
- **場所**: `LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Monetization/Services/ScanLimitManager.swift`
- **機能**:
  - `canScan(isPremium:)`: スキャン可能かチェック
  - `recordScan()`: スキャン実行を記録
  - `daysSinceFirstScan()`: 初回スキャンからの経過日数取得

### 2. PremiumManager (修正版)
- **変更内容**: 日次削除制限 → 生涯削除制限
- **場所**: `LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Monetization/Services/PremiumManager.swift`
- **変更点**:
  - `dailyDeleteCount` → `totalDeleteCount`
  - `freeDailyLimit` (50/日) → `freeTotalLimit` (50生涯)
  - UserDefaults永続化対応

### 3. LimitReachedSheet (改善版)
- **変更内容**: 価値訴求 + 7日間無料トライアルCTA追加
- **場所**: `LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Monetization/Views/LimitReachedSheet.swift`
- **新機能**:
  - `remainingDuplicates`: 残り重複写真数表示
  - `potentialFreeSpace`: 解放可能ストレージ表示
  - 7日間無料トライアルバナー
  - 3プラン比較表示（年額・月額・買い切り）

### 4. AdInterstitialManager
- **目的**: Freeユーザーへの削除後インタースティシャル広告表示
- **場所**: `LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Advertising/Services/AdInterstitialManager.swift`
- **機能**:
  - `preload()`: 広告事前読み込み
  - `showIfReady(from:isPremium:)`: 条件付き広告表示
  - セッション制限: 1セッション1回
  - 時間制限: 30分以上の間隔

### 5. ProductIdentifiers (更新版)
- **変更内容**: Lifetimeプラン追加、価格更新
- **場所**: `LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Monetization/Constants/ProductIdentifiers.swift`
- **新機能**:
  - `lifetimePremium`: $30買い切りプラン
  - 価格更新: 月額$3、年額$20、買い切り$30
  - 7日間無料トライアル設定（月額プランのみ）

---

## 統合手順

### Phase 1: スキャン画面への統合

#### 1.1 スキャンViewModel/Viewへの統合

**対象ファイル**: `ScanView.swift` または `ScanViewModel.swift`

```swift
import LightRoll_CleanerFeature

@MainActor
struct ScanView: View {
    // 既存の依存性
    @Environment(PremiumManager.self) private var premiumManager

    // 新規追加: ScanLimitManager
    @State private var scanLimitManager = ScanLimitManager()

    // 新規追加: Paywall表示フラグ
    @State private var showScanLimitPaywall = false

    var body: some View {
        VStack {
            // スキャンボタン
            Button("写真をスキャン") {
                handleScanTapped()
            }
        }
        .sheet(isPresented: $showScanLimitPaywall) {
            ScanLimitPaywallSheet {
                // Premium画面へ遷移
                // navigation.navigate(to: .premium)
            }
        }
    }

    private func handleScanTapped() {
        // スキャン可能かチェック
        guard scanLimitManager.canScan(isPremium: premiumManager.isPremium) else {
            // Freeユーザーで2回目以降 → Paywall表示
            showScanLimitPaywall = true
            return
        }

        // スキャン実行
        Task {
            // スキャン記録
            scanLimitManager.recordScan()

            // 実際のスキャン処理
            await performScan()
        }
    }
}
```

#### 1.2 ScanLimitPaywallSheetの作成

**新規ファイル**: `ScanLimitPaywallSheet.swift`

```swift
import SwiftUI

/// スキャン制限到達時のPaywall
struct ScanLimitPaywallSheet: View {
    let onUpgrade: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("初回スキャンが完了しました！")
                        .font(.title2.bold())

                    Text("さらにスキャンするにはPremiumプランが必要です")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 価値訴求
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "infinity",
                        title: "無制限スキャン",
                        description: "いつでも何度でもスキャンできます"
                    )

                    FeatureRow(
                        icon: "photo.stack",
                        title: "無制限削除",
                        description: "何枚でも削除できます"
                    )

                    FeatureRow(
                        icon: "eye.slash.fill",
                        title: "広告非表示",
                        description: "快適な操作体験"
                    )
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)

                Spacer()

                // CTA
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
            }
            .padding()
            .navigationTitle("Premiumプランへアップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

---

### Phase 2: 削除画面への統合

#### 2.1 削除ViewModel/Viewへの統合

**対象ファイル**: `DeleteView.swift` または `DeleteViewModel.swift`

```swift
import LightRoll_CleanerFeature

@MainActor
struct DeleteView: View {
    @Environment(PremiumManager.self) private var premiumManager

    // 新規追加: AdInterstitialManager
    @State private var adManager = AdInterstitialManager()

    // 新規追加: LimitReachedSheet表示フラグ
    @State private var showLimitReached = false

    // 削除可能情報（価値訴求用）
    @State private var remainingDuplicates: Int?
    @State private var potentialFreeSpace: String?

    var body: some View {
        VStack {
            // 削除ボタン
            Button("選択した写真を削除") {
                handleDeleteTapped()
            }
        }
        .task {
            // 広告を事前読み込み（アプリ起動時またはシーン表示時）
            adManager.preload()
        }
        .sheet(isPresented: $showLimitReached) {
            LimitReachedSheet(
                currentCount: premiumManager.totalDeleteCount,
                limit: 50,
                remainingDuplicates: remainingDuplicates,
                potentialFreeSpace: potentialFreeSpace,
                onUpgrade: {
                    // Premium画面へ遷移
                    // navigation.navigate(to: .premium)
                }
            )
        }
    }

    private func handleDeleteTapped() {
        let selectedCount = selectedPhotos.count

        // 削除可能かチェック
        guard premiumManager.canDelete(count: selectedCount) else {
            // 制限到達 → LimitReachedSheet表示

            // 残り価値を計算（価値訴求用）
            calculateRemainingValue()

            showLimitReached = true
            return
        }

        // 削除実行
        Task {
            await performDeletion()

            // 削除カウント記録
            premiumManager.incrementDeleteCount(selectedCount)

            // 削除後に広告表示（Freeユーザーのみ）
            showAdIfEligible()
        }
    }

    private func showAdIfEligible() {
        // 現在のViewControllerを取得
        guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }

        // 広告表示（条件を満たす場合のみ）
        adManager.showIfReady(
            from: viewController,
            isPremium: premiumManager.isPremium
        )
    }

    private func calculateRemainingValue() {
        // 残り重複写真数を計算
        // 例: scanResult.duplicateGroups.flatMap { $0.photos }.count
        remainingDuplicates = 450  // 実際の計算ロジックに置き換え

        // 解放可能ストレージを計算
        // 例: remainingDuplicates * averagePhotoSize
        potentialFreeSpace = "2.5 GB"  // 実際の計算ロジックに置き換え
    }
}
```

---

### Phase 3: App起動時の初期化

#### 3.1 App EntryPointでの設定

**対象ファイル**: `LightRoll_CleanerApp.swift`

```swift
import SwiftUI
import LightRoll_CleanerFeature
import GoogleMobileAds

@main
struct LightRoll_CleanerApp: App {
    @State private var premiumManager: PremiumManager

    init() {
        // PremiumManager初期化
        let purchaseRepo = PurchaseRepository()  // 既存のリポジトリ
        _premiumManager = State(wrappedValue: PremiumManager(
            purchaseRepository: purchaseRepo
        ))

        // Google AdMob初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(premiumManager)
                .task {
                    // Premium状態を確認
                    try? await premiumManager.checkPremiumStatus()

                    // トランザクション監視開始
                    premiumManager.startTransactionMonitoring()
                }
        }
    }
}
```

---

## テスト手順

### 1. スキャン制限のテスト

```swift
@Test func scanLimitWorksForFreeUsers() async throws {
    let manager = ScanLimitManager()

    // 初回スキャン: 可能
    #expect(manager.canScan(isPremium: false))
    manager.recordScan()

    // 2回目スキャン: 不可
    #expect(!manager.canScan(isPremium: false))
}

@Test func scanUnlimitedForPremiumUsers() async throws {
    let manager = ScanLimitManager()

    // Premiumユーザーは常に可能
    #expect(manager.canScan(isPremium: true))
    manager.recordScan()
    #expect(manager.canScan(isPremium: true))
}
```

### 2. 削除制限のテスト

```swift
@Test func deleteLimit50ForFreeUsers() async throws {
    let repo = MockPurchaseRepository()
    let manager = PremiumManager(purchaseRepository: repo)

    // 50枚まで削除可能
    #expect(manager.canDelete(count: 50))
    manager.incrementDeleteCount(50)

    // 51枚目は不可
    #expect(!manager.canDelete(count: 1))
}

@Test func deleteUnlimitedForPremiumUsers() async throws {
    let repo = MockPurchaseRepository(isPremium: true)
    let manager = PremiumManager(purchaseRepository: repo)
    try await manager.checkPremiumStatus()

    // 無制限に削除可能
    #expect(manager.canDelete(count: 1000))
}
```

### 3. 広告表示のテスト

```swift
@Test func adOnlyForFreeUsers() async throws {
    let manager = AdInterstitialManager()

    // テスト環境では実際の広告読み込みをスキップ
    // 表示ロジックのみテスト

    // Premiumユーザーには表示しない
    // showIfReady(from: mockVC, isPremium: true) → 何も起こらない

    // Freeユーザーには表示（条件を満たす場合）
    // showIfReady(from: mockVC, isPremium: false) → 広告表示
}
```

---

## トラブルシューティング

### 問題1: スキャン制限が機能しない

**原因**: ScanLimitManagerが初期化されていない、またはcanScan()が呼ばれていない

**解決策**:
```swift
// Viewで必ず初期化
@State private var scanLimitManager = ScanLimitManager()

// スキャン前に必ずチェック
guard scanLimitManager.canScan(isPremium: premiumManager.isPremium) else {
    showScanLimitPaywall = true
    return
}
```

### 問題2: 広告が表示されない

**原因1**: AdMobが初期化されていない

**解決策**:
```swift
// App起動時に初期化
GADMobileAds.sharedInstance().start(completionHandler: nil)
```

**原因2**: 広告が事前読み込みされていない

**解決策**:
```swift
// Viewの.task内で事前読み込み
.task {
    adManager.preload()
}
```

**原因3**: テスト広告IDが設定されていない

**解決策**: `AdMobIdentifiers.swift`で正しいテストIDが設定されているか確認

### 問題3: 削除カウントがリセットされる

**原因**: PremiumManagerの初期化時にUserDefaultsが読み込まれていない

**解決策**:
```swift
// PremiumManager.swiftで確認
public init(
    purchaseRepository: any PurchaseRepositoryProtocol,
    userDefaults: UserDefaults = .standard
) {
    self.purchaseRepository = purchaseRepository
    self.userDefaults = userDefaults

    // UserDefaultsから読み込み
    self.totalDeleteCount = userDefaults.integer(forKey: Keys.totalDeleteCount)
}
```

### 問題4: LimitReachedSheetで価値訴求が表示されない

**原因**: `remainingDuplicates`や`potentialFreeSpace`がnilのまま

**解決策**:
```swift
private func calculateRemainingValue() {
    // 実際の重複写真数を計算
    let allDuplicates = scanResult.duplicateGroups.flatMap { $0.photos }
    let alreadyDeleted = premiumManager.totalDeleteCount
    remainingDuplicates = max(0, allDuplicates.count - alreadyDeleted)

    // 解放可能ストレージを計算
    let averagePhotoSize: Double = 5_000_000  // 5MB
    let potentialBytes = Double(remainingDuplicates ?? 0) * averagePhotoSize
    potentialFreeSpace = ByteCountFormatter.string(fromByteCount: Int64(potentialBytes), countStyle: .file)
}
```

---

## 次のステップ

Phase 1の統合が完了したら、以下を実施してください:

1. **App Store Connect設定**: 製品ID登録、価格設定、7日間無料トライアル設定
2. **Firebase Analytics統合**: イベントトラッキング実装
3. **Phase 2開始**: A/Bテスト機能実装

詳細は以下のドキュメントを参照:
- `docs/CRITICAL/APP_STORE_CONNECT_SETUP.md` (次に作成予定)
- `MONETIZATION_STRATEGY.md` (Phase 2以降の計画)

---

## 参考リンク

- [MONETIZATION_STRATEGY.md](../../MONETIZATION_STRATEGY.md) - 全体戦略
- [StoreKit 2公式ドキュメント](https://developer.apple.com/documentation/storekit)
- [Google AdMob SDK](https://developers.google.com/admob/ios/quick-start)
