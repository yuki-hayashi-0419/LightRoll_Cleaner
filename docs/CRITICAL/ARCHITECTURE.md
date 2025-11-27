# LightRoll Cleaner - System Architecture

## 1. アーキテクチャ概要

### 1.1 全体構成
```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │  Home    │ │  Group   │ │ Detail   │ │ Settings │           │
│  │  View    │ │  List    │ │  View    │ │   View   │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                   │
│  ┌────┴────────────┴────────────┴────────────┴─────┐            │
│  │              ViewModel Layer                     │            │
│  │  (ObservableObject, @Published properties)       │            │
│  └────────────────────────┬────────────────────────┘            │
└───────────────────────────┼─────────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────────┐
│                      Domain Layer                                │
│  ┌────────────────────────┴────────────────────────┐            │
│  │                  Use Cases                       │            │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │            │
│  │  │  Scan    │ │  Group   │ │  Delete/Restore  │ │            │
│  │  │  Photos  │ │  Photos  │ │     Photos       │ │            │
│  │  └────┬─────┘ └────┬─────┘ └────────┬─────────┘ │            │
│  └───────┼────────────┼────────────────┼───────────┘            │
│          │            │                │                         │
│  ┌───────┴────────────┴────────────────┴───────────┐            │
│  │              Domain Models                       │            │
│  │  Photo, PhotoGroup, StorageInfo, UserSettings    │            │
│  └─────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────────┐
│                       Data Layer                                 │
│  ┌────────────────────────┴────────────────────────┐            │
│  │                 Repositories                     │            │
│  └────────────────────────┬────────────────────────┘            │
│                           │                                      │
│  ┌─────────────┬──────────┼──────────┬─────────────┐            │
│  │             │          │          │             │            │
│  ▼             ▼          ▼          ▼             ▼            │
│ Photos     Vision     CoreML    UserDefaults   StoreKit        │
│ Framework  Framework  (分析)    (設定)         (課金)           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 設計パターン
- **MVVM (Model-View-ViewModel)**: UI層の責務分離
- **Repository Pattern**: データソースの抽象化
- **Dependency Injection**: テスタビリティの確保
- **Protocol Oriented Programming**: 柔軟な実装の入れ替え

---

## 2. レイヤー詳細

### 2.1 Presentation Layer

#### Views
```swift
// 画面構成
- HomeView          // ダッシュボード（ストレージ情報、クイックアクション）
- GroupListView     // グループ一覧（類似写真、スクショ、ブレ写真など）
- GroupDetailView   // グループ詳細（写真選択、ベストショット提案）
- SettingsView      // 設定画面
- TrashView         // ゴミ箱（復元機能）
```

#### ViewModels
```swift
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get }
    func send(_ action: Action)
}
```

### 2.2 Domain Layer

#### Use Cases
```swift
// 写真スキャン
protocol ScanPhotosUseCaseProtocol {
    func execute() async throws -> ScanResult
}

// グルーピング
protocol GroupPhotosUseCaseProtocol {
    func execute(photos: [Photo]) async throws -> [PhotoGroup]
}

// 削除処理
protocol DeletePhotosUseCaseProtocol {
    func execute(photos: [Photo], permanent: Bool) async throws
}

// 復元処理
protocol RestorePhotosUseCaseProtocol {
    func execute(photos: [Photo]) async throws
}
```

#### Domain Models
```swift
struct Photo: Identifiable {
    let id: String
    let asset: PHAsset
    let thumbnail: UIImage?
    let fileSize: Int64
    let creationDate: Date
    let analysisResult: PhotoAnalysisResult?
}

struct PhotoGroup: Identifiable {
    let id: UUID
    let type: GroupType
    let photos: [Photo]
    let bestShotIndex: Int?
    let totalSize: Int64
}

enum GroupType {
    case similar       // 類似写真
    case selfie        // 自撮り
    case screenshot    // スクリーンショット
    case blurry        // ブレ・ピンボケ
    case largeVideo    // 大容量動画
}

struct StorageInfo {
    let totalCapacity: Int64
    let usedCapacity: Int64
    let photosSize: Int64
    let reclaimableSize: Int64
}
```

### 2.3 Data Layer

#### Repositories
```swift
protocol PhotoRepositoryProtocol {
    func fetchAllPhotos() async throws -> [Photo]
    func deletePhotos(_ photos: [Photo]) async throws
    func moveToTrash(_ photos: [Photo]) async throws
    func restoreFromTrash(_ photos: [Photo]) async throws
}

protocol AnalysisRepositoryProtocol {
    func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult
    func findSimilarPhotos(_ photos: [Photo]) async throws -> [[Photo]]
    func detectBlurryPhotos(_ photos: [Photo]) async throws -> [Photo]
}

protocol SettingsRepositoryProtocol {
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}

protocol PurchaseRepositoryProtocol {
    func fetchProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> PurchaseResult
    func restorePurchases() async throws
}
```

---

## 3. データフロー

### 3.1 写真スキャンフロー
```
User Action: スキャン開始
       │
       ▼
┌──────────────────┐
│   HomeViewModel  │
│  send(.scan)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ScanPhotosUseCase│
│   execute()      │
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌──────────┐
│Photos │ │ Analysis │
│ Repo  │ │   Repo   │
└───┬───┘ └────┬─────┘
    │          │
    ▼          ▼
[PHAssets]  [Vision/ML分析]
    │          │
    └────┬─────┘
         │
         ▼
┌──────────────────┐
│ GroupPhotosUseCase│
│   execute()       │
└────────┬─────────┘
         │
         ▼
   [PhotoGroup配列]
         │
         ▼
┌──────────────────┐
│   HomeViewModel  │
│ state.groups =   │
└──────────────────┘
```

### 3.2 削除フロー
```
User Action: 削除確認
       │
       ▼
┌──────────────────┐
│ 確認ダイアログ   │
│ 削除枚数/容量表示│
└────────┬─────────┘
         │ 確認
         ▼
┌──────────────────┐
│DeletePhotosUseCase│
│ moveToTrash()    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  PhotoRepository │
│  moveToTrash()   │
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
[アプリ内   [PHAsset
 ゴミ箱]    非表示化]
         │
         ▼
┌──────────────────┐
│ 完了通知         │
│ 解放容量表示     │
└──────────────────┘
```

---

## 4. 画像分析アーキテクチャ

### 4.1 分析パイプライン
```
┌──────────────────────────────────────────────────────────────┐
│                    Analysis Pipeline                          │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌───────┐ │
│  │ Feature  │───▶│ Similar  │───▶│  Group   │───▶│ Best  │ │
│  │ Extract  │    │  Match   │    │ Cluster  │    │ Shot  │ │
│  └──────────┘    └──────────┘    └──────────┘    └───────┘ │
│       │                                                      │
│       ▼                                                      │
│  ┌──────────┐    ┌──────────┐                               │
│  │   Face   │    │  Blur    │                               │
│  │ Detect   │    │ Detect   │                               │
│  └──────────┘    └──────────┘                               │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 使用フレームワーク
| 処理 | フレームワーク | 用途 |
|------|---------------|------|
| 特徴抽出 | Vision (VNFeaturePrintObservation) | 類似画像判定 |
| 顔検出 | Vision (VNDetectFaceRectangles) | 自撮り判定 |
| ブレ検出 | Vision (VNDetectImageQuality) | 品質スコア |
| スクショ判定 | CoreML / ヒューリスティック | 画面キャプチャ検出 |

### 4.3 類似度判定ロジック
```swift
// コサイン類似度でグルーピング
func calculateSimilarity(
    _ featurePrint1: VNFeaturePrintObservation,
    _ featurePrint2: VNFeaturePrintObservation
) throws -> Float {
    var distance: Float = 0
    try featurePrint1.computeDistance(&distance, to: featurePrint2)
    return 1.0 - distance  // 類似度に変換
}

// 閾値: 0.85以上で「類似」と判定
let similarityThreshold: Float = 0.85
```

---

## 5. 状態管理

### 5.1 AppState
```swift
@MainActor
final class AppState: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var photoGroups: [PhotoGroup] = []
    @Published var storageInfo: StorageInfo?
    @Published var trashPhotos: [Photo] = []
    @Published var userSettings: UserSettings = .default
    @Published var purchaseState: PurchaseState = .free
}
```

### 5.2 Navigation
```swift
enum NavigationDestination: Hashable {
    case groupList
    case groupDetail(PhotoGroup)
    case settings
    case trash
    case premium
}
```

---

## 6. エラーハンドリング

### 6.1 エラー型定義
```swift
enum LightRollError: LocalizedError {
    case photoAccessDenied
    case photoAccessRestricted
    case analysisFailed(underlying: Error)
    case deletionFailed(count: Int)
    case restoreFailed
    case purchaseFailed(underlying: Error)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .photoAccessDenied:
            return "写真へのアクセスが拒否されています"
        // ...
        }
    }
}
```

### 6.2 エラー表示
- 非致命的エラー: トースト通知
- 致命的エラー: アラートダイアログ
- 権限エラー: 設定アプリへの誘導

---

## 7. セキュリティアーキテクチャ

### 7.1 データ保護
```
┌─────────────────────────────────────────┐
│              Device Only                 │
│  ┌───────────────────────────────────┐  │
│  │     Photos.app (System)           │  │
│  │     ・オリジナル写真              │  │
│  │     ・PHAssetで参照               │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ┌───────────────────────────────────┐  │
│  │     App Sandbox                    │  │
│  │     ・分析キャッシュ（暗号化）    │  │
│  │     ・ゴミ箱データ（暗号化）      │  │
│  │     ・設定情報                     │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ★ ネットワーク送信なし              │
└─────────────────────────────────────────┘
```

### 7.2 権限フロー
```
アプリ起動
    │
    ▼
┌──────────────────┐
│ PHAuthorizationStatus │
│      確認         │
└────────┬─────────┘
         │
    ┌────┼────┬────┐
    ▼    ▼    ▼    ▼
  .notDet .auth .denied .restricted
    │      │      │        │
    ▼      │      ▼        ▼
 [権限    │   [設定     [機能
 リクエスト] │   誘導]    制限]
    │      │
    └──────┘
         │
         ▼
    [機能利用可能]
```

---

## 8. パフォーマンス最適化

### 8.1 並行処理
- `TaskGroup`を使用した並列画像分析
- `AsyncStream`によるプログレス通知
- メインスレッドブロッキングの回避

### 8.2 メモリ管理
```swift
// サムネイルサイズの最適化
let thumbnailSize = CGSize(width: 200, height: 200)

// バッチ処理
let batchSize = 100

// Autoreleasepool活用
func processPhotos(_ photos: [Photo]) async {
    for batch in photos.chunked(into: batchSize) {
        autoreleasepool {
            // バッチ処理
        }
    }
}
```

### 8.3 キャッシング戦略
- 分析結果: NSCache + ディスクキャッシュ
- サムネイル: PHCachingImageManager
- 統計情報: UserDefaults

---

## 9. 将来の拡張性

### 9.1 予定機能
- [ ] iPad対応
- [ ] iCloud写真対応
- [ ] ウィジェット
- [ ] Siriショートカット

### 9.2 拡張ポイント
- `GroupType`の追加による新しいグルーピング
- 分析アルゴリズムのプラグイン化
- 外部ストレージ連携（将来）

---

## 10. 技術的制約

### 10.1 Photos Framework制限
- 完全削除にはユーザー確認が必須
- PHAssetの変更は非同期
- アルバム情報の変更に制限あり

### 10.2 デバイス制約
- iOS 16以上（Vision API要件）
- メモリ制限（バックグラウンド時は特に）
- バッテリー消費への配慮

---

*最終更新: 2025-11-27*
