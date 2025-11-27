# MODULE M5: Dashboard & Statistics

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M5 |
| モジュール名 | Dashboard & Statistics |
| 責務 | ホーム画面、ストレージ統計、クリーンアップ履歴 |
| 依存先 | M1, M2, M3, M4 |
| 依存元 | - |

---

## 2. 画面構成

### 2.1 HomeView（ダッシュボード）
```
┌─────────────────────────────────────────┐
│  LightRoll Cleaner         [設定]      │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │     Storage Overview              │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  [円グラフ]                 │  │  │
│  │  │  64GB / 128GB 使用中        │  │  │
│  │  │  📷 写真: 42GB              │  │  │
│  │  │  🗑️ 解放可能: 8.5GB         │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  [🔍 スキャン開始]                │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ■ グループ一覧                        │
│  ┌───────────────────────────────────┐  │
│  │ 📷 類似写真  │  342枚  │  2.1GB   │  │
│  ├───────────────────────────────────┤  │
│  │ 🤳 自撮り    │  128枚  │  890MB   │  │
│  ├───────────────────────────────────┤  │
│  │ 📱 スクショ  │  256枚  │  1.2GB   │  │
│  ├───────────────────────────────────┤  │
│  │ 🌫️ ブレ写真  │   89枚  │  520MB   │  │
│  ├───────────────────────────────────┤  │
│  │ 🎬 大容量動画│   12本  │  3.8GB   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ■ クリーンアップ履歴                  │
│  ┌───────────────────────────────────┐  │
│  │  11/25 - 156枚削除 - 1.2GB解放   │  │
│  │  11/20 - 89枚削除 - 680MB解放    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 2.2 GroupListView（グループ一覧）
```
┌─────────────────────────────────────────┐
│  [←] 類似写真                    [選択] │
├─────────────────────────────────────────┤
│  ■ グループ1 (5枚)  ★ベストショット    │
│  ┌─────┬─────┬─────┬─────┬─────┐      │
│  │ 📷★ │ 📷  │ 📷  │ 📷  │ 📷  │      │
│  └─────┴─────┴─────┴─────┴─────┘      │
│  解放可能: 45MB                         │
│                                         │
│  ■ グループ2 (3枚)                     │
│  ┌─────┬─────┬─────┐                  │
│  │ 📷★ │ 📷  │ 📷  │                  │
│  └─────┴─────┴─────┘                  │
│  解放可能: 28MB                         │
│                                         │
│  ...                                    │
├─────────────────────────────────────────┤
│  [🗑️ 選択した写真を削除 (XX枚, XXMB)]  │
└─────────────────────────────────────────┘
```

### 2.3 GroupDetailView（グループ詳細）
```
┌─────────────────────────────────────────┐
│  [←] グループ詳細              [全選択] │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │         [選択中の写真プレビュー]    ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────┬─────┬─────┬─────┬─────┐      │
│  │ 📷★ │ ☑️  │ ☑️  │ ☑️  │ ☑️  │      │
│  └─────┴─────┴─────┴─────┴─────┘      │
│                                         │
│  📅 2024/11/25 14:32                   │
│  📐 4032 x 3024                         │
│  📦 12.5MB                              │
│  ⭐ 品質スコア: 85%                     │
├─────────────────────────────────────────┤
│  [ベストショットに設定]                 │
│  [🗑️ 選択した写真を削除]               │
└─────────────────────────────────────────┘
```

---

## 3. 主要コンポーネント

### 3.1 ViewModels
```swift
// ViewModels/HomeViewModel.swift
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var storageInfo: StorageInfo?
    @Published var photoGroups: [PhotoGroup] = []
    @Published var cleanupHistory: [CleanupRecord] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0

    func startScan() async
    func refreshStorageInfo() async
}

// ViewModels/GroupListViewModel.swift
@MainActor
final class GroupListViewModel: ObservableObject {
    @Published var groups: [PhotoGroup] = []
    @Published var selectedPhotoIds: Set<String> = []

    func selectAllExceptBest()
    func deleteSelectedPhotos() async throws
}

// ViewModels/GroupDetailViewModel.swift
@MainActor
final class GroupDetailViewModel: ObservableObject {
    @Published var group: PhotoGroup
    @Published var selectedPhotoIds: Set<String> = []
    @Published var currentPhotoIndex: Int = 0

    func setBestShot(photoId: String)
    func deleteSelectedPhotos() async throws
}
```

### 3.2 Use Cases
```swift
// UseCases/ScanPhotosUseCase.swift
final class ScanPhotosUseCase: ScanPhotosUseCaseProtocol {
    func execute(progress: @escaping (Double) -> Void) async throws -> ScanResult
}

// UseCases/GetStatisticsUseCase.swift
final class GetStatisticsUseCase {
    func execute() async throws -> StorageStatistics
}
```

### 3.3 Models
```swift
// Models/CleanupRecord.swift
struct CleanupRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let deletedCount: Int
    let freedSpace: Int64
}

// Models/StorageStatistics.swift
struct StorageStatistics {
    let storageInfo: StorageInfo
    let groupSummary: [GroupType: GroupSummary]
}

struct GroupSummary {
    let count: Int
    let totalSize: Int64
    let reclaimableSize: Int64
}
```

---

## 4. ディレクトリ構造

```
src/modules/Dashboard/
├── Views/
│   ├── HomeView.swift
│   ├── GroupListView.swift
│   └── GroupDetailView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── GroupListViewModel.swift
│   └── GroupDetailViewModel.swift
├── UseCases/
│   ├── ScanPhotosUseCase.swift
│   └── GetStatisticsUseCase.swift
├── Models/
│   ├── CleanupRecord.swift
│   └── StorageStatistics.swift
└── Subviews/
    ├── StorageOverviewCard.swift
    ├── GroupSummaryRow.swift
    └── CleanupHistoryRow.swift
```

---

## 5. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M5-T01 | CleanupRecordモデル | 履歴モデル定義 | 0.5h | M1-T08 |
| M5-T02 | StorageStatisticsモデル | 統計モデル定義 | 0.5h | M3-T02 |
| M5-T03 | ScanPhotosUseCase実装 | スキャン処理統合 | 2.5h | M2-T09,M3-T12 |
| M5-T04 | GetStatisticsUseCase実装 | 統計取得処理 | 1.5h | M5-T02 |
| M5-T05 | HomeViewModel実装 | ホーム画面VM | 2h | M5-T03,M5-T04 |
| M5-T06 | StorageOverviewCard実装 | 容量概要カード | 2h | M4-T07 |
| M5-T07 | HomeView実装 | ホーム画面View | 2.5h | M5-T05,M5-T06 |
| M5-T08 | GroupListViewModel実装 | 一覧画面VM | 2h | M3-T10 |
| M5-T09 | GroupListView実装 | 一覧画面View | 2.5h | M5-T08,M4-T08 |
| M5-T10 | GroupDetailViewModel実装 | 詳細画面VM | 2h | M5-T08 |
| M5-T11 | GroupDetailView実装 | 詳細画面View | 2.5h | M5-T10,M4-T06 |
| M5-T12 | Navigation設定 | 画面遷移の実装 | 1.5h | M5-T07,M5-T09,M5-T11 |
| M5-T13 | 単体テスト作成 | Dashboard機能テスト | 2h | M5-T12 |

---

## 6. テストケース

### M5-T05: HomeViewModel実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M5-T05-TC01 | スキャン開始時の状態変更 | isScanning=true |
| M5-T05-TC02 | スキャン完了後のグループ更新 | photoGroupsが更新 |
| M5-T05-TC03 | エラー時のハンドリング | エラー状態が設定される |

### M5-T07: HomeView実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M5-T07-TC01 | 初期表示 | 容量情報が表示 |
| M5-T07-TC02 | スキャンボタンタップ | スキャン処理開始 |
| M5-T07-TC03 | グループタップ | GroupListViewへ遷移 |

### M5-T11: GroupDetailView実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M5-T11-TC01 | 写真選択 | 選択状態が反映 |
| M5-T11-TC02 | ベストショット変更 | アイコン更新 |
| M5-T11-TC03 | 削除ボタン | 確認ダイアログ表示 |

---

## 7. 受け入れ条件

- [ ] ホーム画面でストレージ情報が正しく表示される
- [ ] スキャン進捗がリアルタイムで表示される
- [ ] グループ一覧から詳細へ遷移できる
- [ ] ベストショットの変更が可能
- [ ] クリーンアップ履歴が表示される
- [ ] 全画面でダークモード対応

---

## 8. 技術的考慮事項

### 8.1 状態管理
- ViewModelはMainActorで保護
- DIContainerからの依存注入
- Combineでの状態監視

### 8.2 パフォーマンス
- LazyVStackでリスト表示
- サムネイルの遅延読み込み
- 大量データのページング検討

### 8.3 UX
- スキャン中のキャンセル機能
- プルトゥリフレッシュ対応
- スケルトンローディング

---

*最終更新: 2025-11-27*
