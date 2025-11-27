# MODULE M9: Monetization

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M9 |
| モジュール名 | Monetization |
| 責務 | 課金処理、広告表示、機能制限管理 |
| 依存先 | M1, M4 |
| 依存元 | M5, M6, M8 |

---

## 2. ビジネスモデル

### 2.1 プラン構成
| プラン | 価格 | 機能 |
|--------|------|------|
| Free | 無料 | 1日50枚まで削除、広告表示、基本グルーピング |
| Premium Monthly | ¥480/月 | 無制限削除、広告非表示、自動スキャン、高度な分析 |
| Premium Yearly | ¥3,800/年 | Monthly同等（約35%オフ） |
| Lifetime | ¥9,800 | 永久ライセンス |

### 2.2 機能制限マトリクス
| 機能 | Free | Premium |
|------|------|---------|
| 写真スキャン | ○ | ○ |
| 類似写真グルーピング | 基本 | 高精度 |
| 1日の削除上限 | 50枚 | 無制限 |
| 広告表示 | あり | なし |
| 自動スキャン | × | ○ |
| ベストショット提案 | 基本 | AI強化 |
| バックグラウンド処理 | × | ○ |
| 優先サポート | × | ○ |

---

## 3. 主要コンポーネント

### 3.1 PurchaseRepository
```swift
// Repositories/PurchaseRepository.swift
final class PurchaseRepository: PurchaseRepositoryProtocol {
    func fetchProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> PurchaseResult
    func restorePurchases() async throws -> [Transaction]
    func checkSubscriptionStatus() async -> SubscriptionStatus
}

enum PurchaseResult {
    case success(Transaction)
    case pending
    case cancelled
    case failed(Error)
}

enum SubscriptionStatus {
    case active(expirationDate: Date)
    case expired
    case none
}
```

### 3.2 PremiumManager
```swift
// Services/PremiumManager.swift
@MainActor
final class PremiumManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var dailyDeleteCount: Int = 0

    func checkPremiumStatus() async
    func canDelete(count: Int) -> Bool
    func incrementDeleteCount(_ count: Int)
    func resetDailyCount()
}
```

### 3.3 AdManager
```swift
// Services/AdManager.swift
final class AdManager {
    func loadBannerAd() -> GADBannerView
    func loadInterstitialAd() async -> GADInterstitialAd?
    func showInterstitialAd(from viewController: UIViewController)
    func shouldShowAd() -> Bool
}
```

### 3.4 FeatureGate
```swift
// Services/FeatureGate.swift
final class FeatureGate {
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool
    func getLimit(for feature: LimitedFeature) -> Int
}

enum PremiumFeature {
    case unlimitedDelete
    case autoScan
    case advancedAnalysis
    case backgroundProcessing
    case adFree
}

enum LimitedFeature {
    case dailyDelete
}
```

### 3.5 Domain Models
```swift
// Models/PremiumStatus.swift
enum PremiumStatus: Codable {
    case free
    case premiumMonthly(expiresAt: Date)
    case premiumYearly(expiresAt: Date)
    case lifetime

    var isPremium: Bool {
        switch self {
        case .free: return false
        default: return true
        }
    }
}

// Models/ProductInfo.swift
struct ProductInfo: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let priceLocale: Locale
    let subscriptionPeriod: SubscriptionPeriod?
}

enum SubscriptionPeriod {
    case monthly
    case yearly
    case lifetime
}
```

---

## 4. 画面構成

### 4.1 PremiumView（アップグレード画面）
```
┌─────────────────────────────────────────┐
│  [×]                                    │
├─────────────────────────────────────────┤
│                                         │
│            🌟 Premium                   │
│                                         │
│     すべての機能を解放しましょう        │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ✅ 削除制限なし                        │
│  ✅ 広告非表示                          │
│  ✅ 自動スキャン                        │
│  ✅ 高精度な類似写真検出                │
│  ✅ バックグラウンド処理                │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 月額プラン                        │  │
│  │ ¥480/月                           │  │
│  │ [選択]                            │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 年額プラン        ⭐ おすすめ     │  │
│  │ ¥3,800/年（¥317/月相当）         │  │
│  │ 35%お得                           │  │
│  │ [選択]                            │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 買い切り                          │  │
│  │ ¥9,800（一度だけ）               │  │
│  │ [選択]                            │  │
│  └───────────────────────────────────┘  │
│                                         │
│  [購入を復元]                           │
│                                         │
│  利用規約 | プライバシーポリシー        │
│                                         │
└─────────────────────────────────────────┘
```

### 4.2 制限到達ダイアログ
```
┌─────────────────────────────────────────┐
│                                         │
│  😢 本日の削除上限に達しました          │
│                                         │
│  無料版では1日50枚まで削除できます。    │
│  プレミアムにアップグレードすると       │
│  無制限で写真を整理できます。           │
│                                         │
│  [プレミアムを見る]                     │
│  [明日まで待つ]                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 5. ディレクトリ構造

```
src/modules/Monetization/
├── Repositories/
│   └── PurchaseRepository.swift
├── Services/
│   ├── PremiumManager.swift
│   ├── AdManager.swift
│   ├── FeatureGate.swift
│   └── ReceiptValidator.swift
├── Views/
│   ├── PremiumView.swift
│   ├── PremiumFeatureRow.swift
│   ├── PlanCard.swift
│   └── LimitReachedSheet.swift
├── ViewModels/
│   └── PremiumViewModel.swift
├── Models/
│   ├── PremiumStatus.swift
│   └── ProductInfo.swift
└── Ads/
    ├── BannerAdView.swift
    └── InterstitialAdCoordinator.swift
```

---

## 6. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M9-T01 | PremiumStatusモデル | 課金状態モデル | 1h | M1-T08 |
| M9-T02 | ProductInfoモデル | 商品情報モデル | 0.5h | M9-T01 |
| M9-T03 | StoreKit 2設定 | App Store Connect設定 | 1h | M1-T01 |
| M9-T04 | PurchaseRepository実装 | StoreKit 2連携 | 3h | M9-T03 |
| M9-T05 | PremiumManager実装 | 課金状態管理 | 2.5h | M9-T04 |
| M9-T06 | FeatureGate実装 | 機能制限管理 | 1.5h | M9-T05 |
| M9-T07 | 削除上限管理 | Daily limit機能 | 1.5h | M9-T06 |
| M9-T08 | Google Mobile Ads導入 | AdMob SDK設定 | 2h | M1-T01 |
| M9-T09 | AdManager実装 | 広告管理サービス | 2h | M9-T08 |
| M9-T10 | BannerAdView実装 | バナー広告表示 | 1.5h | M9-T09 |
| M9-T11 | PremiumViewModel実装 | 課金画面VM | 2h | M9-T05 |
| M9-T12 | PremiumView実装 | 課金画面View | 2.5h | M9-T11,M4-T03 |
| M9-T13 | LimitReachedSheet実装 | 制限到達シート | 1h | M9-T06 |
| M9-T14 | 購入復元実装 | リストア機能 | 1.5h | M9-T04 |
| M9-T15 | 単体テスト作成 | Monetization機能テスト | 2h | M9-T14 |

---

## 7. テストケース

### M9-T05: PremiumManager実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M9-T05-TC01 | Free状態の確認 | isPremium=false |
| M9-T05-TC02 | サブスク購入後の状態 | isPremium=true |
| M9-T05-TC03 | 期限切れ後の状態 | isPremium=false |

### M9-T06: FeatureGate実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M9-T06-TC01 | Free版での機能チェック | 制限あり |
| M9-T06-TC02 | Premium版での機能チェック | 制限なし |
| M9-T06-TC03 | Daily limit確認 | 50枚/日 |

### M9-T07: 削除上限管理
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M9-T07-TC01 | 50枚削除後の状態 | canDelete=false |
| M9-T07-TC02 | 日付変更後のリセット | カウントが0に |
| M9-T07-TC03 | Premium版の制限 | 常にtrue |

### M9-T12: PremiumView実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M9-T12-TC01 | プラン表示 | 3プラン表示 |
| M9-T12-TC02 | 購入フロー | StoreKitシート表示 |
| M9-T12-TC03 | 復元ボタン | 復元処理実行 |

---

## 8. 受け入れ条件

- [ ] StoreKit 2で購入処理が正常に動作
- [ ] サブスクリプション状態が正しく反映される
- [ ] Free版で1日50枚の制限が機能する
- [ ] Premium版で制限が解除される
- [ ] 広告がFree版のみで表示される
- [ ] 購入復元が正しく動作する

---

## 9. 技術的考慮事項

### 9.1 StoreKit 2
```swift
// 購入処理の例
func purchase(_ product: Product) async throws -> PurchaseResult {
    let result = try await product.purchase()

    switch result {
    case .success(let verification):
        let transaction = try checkVerified(verification)
        await transaction.finish()
        return .success(transaction)
    case .pending:
        return .pending
    case .userCancelled:
        return .cancelled
    @unknown default:
        return .failed(PurchaseError.unknown)
    }
}
```

### 9.2 レシート検証
- App Store Server APIでのサーバーサイド検証（推奨）
- オンデバイス検証（オフライン対応）
- 不正対策

### 9.3 広告実装
```swift
// Google Mobile Ads SDK
import GoogleMobileAds

// バナー広告
let bannerView = GADBannerView(adSize: GADAdSizeBanner)
bannerView.adUnitID = "ca-app-pub-xxxxx/yyyyy"
bannerView.load(GADRequest())
```

### 9.4 テスト環境
- StoreKit Configuration File使用
- Sandbox環境でのテスト
- テスト用広告ユニットID

---

*最終更新: 2025-11-27*
