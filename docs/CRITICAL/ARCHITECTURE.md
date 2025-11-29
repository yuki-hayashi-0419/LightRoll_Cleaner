# LightRoll Cleaner - System Architecture

## 0. アーキテクチャ選定

### 0.1 採用パターン: MV Pattern（Model-View）

**【2025-11-30更新】** 本プロジェクトは **MV Pattern** を採用しています。ViewModelを使用せず、SwiftUI本来の状態管理機能を最大限に活用します。

### 0.2 MV Pattern の特徴

```
Views (@State, @Environment) → Services (@Observable) → Frameworks
```

- **ViewModelなし**: 状態は全てView内の@Stateで管理
- **@Observable**: サービス/モデルクラスは@Observableマクロで監視可能に
- **@Environment**: アプリ全体で共有するサービスの依存性注入
- **enum ViewState**: 複雑な状態は列挙型パターンで管理

### 0.3 採用理由

| 観点 | MV Pattern のメリット |
|------|----------------------|
| **SwiftUI親和性** | SwiftUI本来の設計思想に忠実 |
| **シンプル性** | 中間層（ViewModel）を排除し、コードパスを短縮 |
| **パフォーマンス** | @Observableは使用されるプロパティのみを追跡、再描画を最小化 |
| **テスタビリティ** | Servicesをモック化してViewをテスト |
| **保守性** | 状態の流れが直感的で追跡しやすい |

### 0.4 アーキテクチャ原則

1. **Views as Pure State Expressions**: Viewは状態の表現に徹する
2. **Single Source of Truth**: 状態は@Stateまたは@Environmentで一元管理
3. **Declarative Side Effects**: .task修飾子で非同期処理を宣言的に記述
4. **Environment for App-wide Services**: Router, Theme, Services等は@Environment経由

---

## 1. アーキテクチャ概要

### 1.1 全体構成（MV Pattern）
```
┌─────────────────────────────────────────────────────────────────┐
│                      View Layer (SwiftUI)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │  Home    │ │  Group   │ │ Detail   │ │ Settings │           │
│  │  View    │ │  List    │ │  View    │ │   View   │           │
│  │ (@State) │ │ (@State) │ │ (@State) │ │ (@State) │           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                   │
│       └────────────┴────────────┴────────────┘                   │
│                            │                                     │
│                  @Environment(Service.self)                      │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            │ @Observable Services
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              @Observable Services                        │    │
│  │  PhotoScanner / PhotoGrouper / BestShotSelector          │    │
│  │  StorageService / DashboardService / TrashManager        │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────┐    │
│  │              Domain Models                               │    │
│  │  Photo, PhotoGroup, StorageInfo, UserSettings            │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ actor / Repository
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Data Layer                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Actors & Repositories                       │    │
│  │  PhotoRepository / AnalysisRepository / ThumbnailCache   │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           │                                      │
│  ┌─────────────┬──────────┼──────────┬─────────────┐            │
│  │             │          │          │             │            │
│  ▼             ▼          ▼          ▼             ▼            │
│ Photos     Vision     CoreML    UserDefaults   StoreKit        │
│ Framework  Framework  (分析)    (設定)         (課金)           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 設計パターン
- **MV Pattern (Model-View)**: ViewModelを使わず、SwiftUI本来の状態管理を活用
- **@Observable**: サービスの状態変化を自動追跡
- **@Environment**: アプリ全体で共有するサービスの依存性注入
- **Actor**: データアクセス層のスレッドセーフティ確保

### 1.3 採用しなかったパターン
- **ViewModel層**: SwiftUIの@State/@Environmentで十分
- **UseCase層**: 現時点のビジネスロジック複雑性では過剰（将来追加可能）
- **Coordinator Pattern**: NavigationStack/NavigationPathで十分
- **DIコンテナ（Swinject等）**: @Environmentで代替

---

## 2. レイヤー詳細

### 2.1 View Layer（SwiftUI）

#### 画面構成
```swift
// 画面構成
- HomeView          // ダッシュボード（ストレージ情報、クイックアクション）
- GroupListView     // グループ一覧（類似写真、スクショ、ブレ写真など）
- GroupDetailView   // グループ詳細（写真選択、ベストショット提案）
- SettingsView      // 設定画面
- TrashView         // ゴミ箱（復元機能）
```

#### View設計パターン（MV Pattern）
```swift
/// MV PatternのView実装例
/// ViewModelなし、状態は@Stateで管理
@MainActor
struct HomeView: View {
    // Services are injected via Environment
    @Environment(PhotoScanner.self) private var scanner
    @Environment(StorageService.self) private var storageService

    // Local state management
    @State private var viewState: ViewState = .loading
    @State private var storageInfo: StorageInfo?
    @State private var photoGroups: [PhotoGroup] = []

    enum ViewState {
        case loading
        case loaded
        case scanning(progress: Double)
        case error(String)
    }

    var body: some View {
        // View implementation
    }
}
```

#### 状態管理の原則
```swift
// 1. @State: View固有のローカル状態
@State private var isShowingSheet = false
@State private var selectedItems: Set<String> = []

// 2. @Environment: アプリ全体で共有するサービス
@Environment(PhotoScanner.self) private var scanner

// 3. enum ViewState: 複雑な状態の統合管理
enum ViewState {
    case loading
    case loaded(data: [Item])
    case error(String)
}

// 4. .task: 非同期処理（自動キャンセル対応）
.task {
    await loadData()
}

// 5. .task(id:): 値変更時の再実行
.task(id: selectedGroupId) {
    await loadGroupDetails(selectedGroupId)
}
```

### 2.2 Domain Layer

#### Repository Protocols（テスタビリティの要）
```swift
/// 写真リポジトリプロトコル
/// Photos Frameworkへのアクセスを抽象化
protocol PhotoRepositoryProtocol {
    func fetchAllPhotos() async throws -> [Photo]
    func deletePhotos(_ photos: [Photo]) async throws
    func moveToTrash(_ photos: [Photo]) async throws
    func restoreFromTrash(_ photos: [Photo]) async throws
}

/// 分析リポジトリプロトコル
/// Vision/CoreMLへのアクセスを抽象化
protocol AnalysisRepositoryProtocol {
    func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult
    func findSimilarPhotos(_ photos: [Photo]) async throws -> [[Photo]]
    func detectBlurryPhotos(_ photos: [Photo]) async throws -> [Photo]
}

/// 設定リポジトリプロトコル
protocol SettingsRepositoryProtocol {
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}

/// 課金リポジトリプロトコル
protocol PurchaseRepositoryProtocol {
    func fetchProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> PurchaseResult
    func restorePurchases() async throws
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

#### Repository Implementations
```swift
/// PhotoRepositoryの実装
/// Photos Frameworkを直接使用
final class PhotoRepository: PhotoRepositoryProtocol {
    func fetchAllPhotos() async throws -> [Photo] {
        // PHAssetを取得してPhotoに変換
    }

    func deletePhotos(_ photos: [Photo]) async throws {
        // PHAssetChangeRequestで削除
    }
    // ...
}

/// テスト用モックリポジトリ
final class MockPhotoRepository: PhotoRepositoryProtocol {
    var mockPhotos: [Photo] = []
    var deletePhotosCalled = false

    func fetchAllPhotos() async throws -> [Photo] {
        return mockPhotos
    }

    func deletePhotos(_ photos: [Photo]) async throws {
        deletePhotosCalled = true
    }
    // ...
}
```

---

## 3. 依存性注入パターン

### 3.1 @Environment経由のDI
```swift
// DIキー定義
private struct PhotoRepositoryKey: EnvironmentKey {
    static let defaultValue: PhotoRepositoryProtocol = PhotoRepository()
}

extension EnvironmentValues {
    var photoRepository: PhotoRepositoryProtocol {
        get { self[PhotoRepositoryKey.self] }
        set { self[PhotoRepositoryKey.self] = newValue }
    }
}

// Viewでの使用
struct HomeView: View {
    @Environment(\.photoRepository) private var photoRepository
    @StateObject private var viewModel: HomeViewModel

    init() {
        // EnvironmentからRepositoryを取得してViewModelに注入
    }
}

// テストでの使用
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.photoRepository, MockPhotoRepository())
    }
}
```

### 3.2 イニシャライザ注入（推奨）
```swift
// ViewModelへの直接注入（テストで使用）
let mockRepo = MockPhotoRepository()
mockRepo.mockPhotos = [testPhoto1, testPhoto2]
let viewModel = HomeViewModel(photoRepository: mockRepo)

// テストケース
func testScanPhotos() async throws {
    // Given
    let mockRepo = MockPhotoRepository()
    mockRepo.mockPhotos = [Photo.mock()]
    let sut = HomeViewModel(photoRepository: mockRepo)

    // When
    sut.send(.scan)
    await sut.waitForScanComplete()

    // Then
    XCTAssertEqual(sut.state.photos.count, 1)
}
```

---

## 4. データフロー

### 4.1 写真スキャンフロー
```
User Action: スキャン開始
       │
       ▼
┌──────────────────┐
│   HomeViewModel  │
│  send(.scan)     │
└────────┬─────────┘
         │
         │ protocol経由
         ▼
┌──────────────────┐     ┌──────────────────┐
│ PhotoRepository  │     │ AnalysisRepository│
│  (Protocol)      │     │   (Protocol)      │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         ▼                        ▼
┌──────────────────┐     ┌──────────────────┐
│ PhotoRepository  │     │AnalysisRepository│
│  (Implementation)│     │ (Implementation) │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         ▼                        ▼
    [PHAssets]            [Vision/ML分析]
         │                        │
         └──────────┬─────────────┘
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

### 4.2 削除フロー
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
│  GroupViewModel  │
│ send(.delete)    │
└────────┬─────────┘
         │
         │ protocol経由
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

## 5. 画像分析アーキテクチャ

### 5.1 分析パイプライン
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

### 5.2 使用フレームワーク
| 処理 | フレームワーク | 用途 |
|------|---------------|------|
| 特徴抽出 | Vision (VNFeaturePrintObservation) | 類似画像判定 |
| 顔検出 | Vision (VNDetectFaceRectangles) | 自撮り判定 |
| ブレ検出 | Vision (VNDetectImageQuality) | 品質スコア |
| スクショ判定 | CoreML / ヒューリスティック | 画面キャプチャ検出 |

### 5.3 類似度判定ロジック
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

## 6. 状態管理

### 6.1 AppState
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

### 6.2 Navigation
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

## 7. エラーハンドリング

### 7.1 エラー型定義
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

### 7.2 エラー表示
- 非致命的エラー: トースト通知
- 致命的エラー: アラートダイアログ
- 権限エラー: 設定アプリへの誘導

---

## 8. セキュリティアーキテクチャ

### 8.1 データ保護
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

### 8.2 権限フロー
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

## 9. パフォーマンス最適化

### 9.1 並行処理
- `TaskGroup`を使用した並列画像分析
- `AsyncStream`によるプログレス通知
- メインスレッドブロッキングの回避

### 9.2 メモリ管理
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

### 9.3 キャッシング戦略
- 分析結果: NSCache + ディスクキャッシュ
- サムネイル: PHCachingImageManager
- 統計情報: UserDefaults

---

## 10. 将来の拡張性

### 10.1 予定機能
- [ ] iPad対応
- [ ] iCloud写真対応
- [ ] ウィジェット
- [ ] Siriショートカット

### 10.2 拡張ポイント
- `GroupType`の追加による新しいグルーピング
- 分析アルゴリズムのプラグイン化
- 外部ストレージ連携（将来）

### 10.3 UseCase層の追加（将来オプション）
ビジネスロジックが複雑化した場合、ViewModelとRepositoryの間にUseCase層を追加可能：
```swift
// 将来追加する場合の例
protocol ScanPhotosUseCaseProtocol {
    func execute() async throws -> ScanResult
}

final class ScanPhotosUseCase: ScanPhotosUseCaseProtocol {
    private let photoRepository: PhotoRepositoryProtocol
    private let analysisRepository: AnalysisRepositoryProtocol

    func execute() async throws -> ScanResult {
        // 複雑なビジネスロジックをカプセル化
    }
}
```

---

## 11. 技術的制約

### 11.1 Photos Framework制限
- 完全削除にはユーザー確認が必須
- PHAssetの変更は非同期
- アルバム情報の変更に制限あり

### 11.2 デバイス制約
- iOS 16以上（Vision API要件）
- メモリ制限（バックグラウンド時は特に）
- バッテリー消費への配慮

---

## 12. 開発フェーズ状況

### 12.1 Phase完了状況

| Phase | 内容 | ステータス | 完了日 |
|-------|------|----------|--------|
| **Phase 1** | 基盤構築（M1 Core Infrastructure） | 完了 | 2025-11-27 |
| **Phase 2** | データ層（M2 Photo Access + M3 Image Analysis） | 完了 | 2025-11-29 |
| **Phase 3** | UI層（M4 UI Components） | 完了 | 2025-11-30 |
| **Phase 4** | Dashboard（M5 Dashboard & Statistics） | 次フェーズ | - |
| **Phase 5** | 機能完成（M6 Deletion + M8 Settings） | 未着手 | - |
| **Phase 6** | 仕上げ（M7 Notifications + M9 Monetization） | 未着手 | - |

### 12.2 完了モジュール

| モジュール | タスク数 | テスト数 | 平均品質スコア |
|-----------|---------|---------|---------------|
| M1 Core Infrastructure | 10 | - | - |
| M2 Photo Access | 12 | 多数 | 111.5/120点 |
| M3 Image Analysis | 13 | 27 | 111.1/120点 |
| M4 UI Components | 14 | 108 | 93.5/100点 |
| **合計** | **49** | **135+** | **高品質** |

### 12.3 全体進捗
- 完了タスク: 49/118 (41.5%)
- 完了時間: 79.5h/192.5h (41.3%)
- テスト総数: 1500+件

---

*最終更新: 2025-11-30*
*アーキテクチャ: MV Pattern（ViewModelを使用しないSwiftUI本来の設計）*
*Phase 3完了: M1 + M2 + M3 + M4*
