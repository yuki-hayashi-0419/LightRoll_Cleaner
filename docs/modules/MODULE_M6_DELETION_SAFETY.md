# MODULE M6: Deletion & Safety

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M6 |
| モジュール名 | Deletion & Safety |
| 責務 | 写真削除、ゴミ箱機能、復元、誤削除防止 |
| 依存先 | M1, M2, M4 |
| 依存元 | M5, M9 |

---

## 2. 主要コンポーネント

### 2.1 DeletePhotosUseCase
```swift
// UseCases/DeletePhotosUseCase.swift
final class DeletePhotosUseCase: DeletePhotosUseCaseProtocol {
    enum DeletionMode {
        case moveToTrash    // アプリ内ゴミ箱へ移動
        case permanentDelete // 完全削除（システム確認あり）
    }

    func execute(
        photos: [Photo],
        mode: DeletionMode
    ) async throws -> DeletionResult
}

struct DeletionResult {
    let deletedCount: Int
    let freedSpace: Int64
    let failedPhotos: [Photo]
}
```

### 2.2 RestorePhotosUseCase
```swift
// UseCases/RestorePhotosUseCase.swift
final class RestorePhotosUseCase: RestorePhotosUseCaseProtocol {
    func execute(photos: [TrashPhoto]) async throws -> RestoreResult
}

struct RestoreResult {
    let restoredCount: Int
    let failedPhotos: [TrashPhoto]
}
```

### 2.3 TrashManager
```swift
// Services/TrashManager.swift
final class TrashManager {
    private let retentionDays = 30

    func moveToTrash(_ photos: [Photo]) async throws
    func restoreFromTrash(_ photos: [TrashPhoto]) async throws
    func emptyTrash() async throws
    func getTrashPhotos() -> [TrashPhoto]
    func getTrashSize() -> Int64
    func cleanupExpiredItems() async  // 30日経過したものを自動削除
}
```

### 2.4 DeletionConfirmationService
```swift
// Services/DeletionConfirmationService.swift
final class DeletionConfirmationService {
    func shouldShowWarning(photoCount: Int) -> Bool
    func formatConfirmationMessage(photos: [Photo]) -> ConfirmationMessage
}

struct ConfirmationMessage {
    let title: String
    let message: String
    let photoCount: Int
    let reclaimableSize: Int64
}
```

### 2.5 Domain Models
```swift
// Models/TrashPhoto.swift
struct TrashPhoto: Identifiable, Codable {
    let id: UUID
    let originalPhotoId: String
    let originalPath: String
    let thumbnailData: Data
    let deletedAt: Date
    let expiresAt: Date
    let fileSize: Int64
    let metadata: PhotoMetadata

    var isExpired: Bool {
        Date() > expiresAt
    }

    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }
}

struct PhotoMetadata: Codable {
    let creationDate: Date
    let pixelWidth: Int
    let pixelHeight: Int
    let mediaType: String
}
```

---

## 3. ゴミ箱画面

### 3.1 TrashView
```
┌─────────────────────────────────────────┐
│  [←] ゴミ箱                      [編集] │
├─────────────────────────────────────────┤
│  ⚠️ 30日後に自動削除されます           │
│  使用容量: 1.2GB                        │
├─────────────────────────────────────────┤
│  ■ 今日削除 (3枚)                       │
│  ┌─────┬─────┬─────┐                  │
│  │ 📷  │ 📷  │ 📷  │  残り30日         │
│  └─────┴─────┴─────┘                  │
│                                         │
│  ■ 昨日削除 (5枚)                       │
│  ┌─────┬─────┬─────┬─────┬─────┐      │
│  │ 📷  │ 📷  │ 📷  │ 📷  │ 📷  │  29日 │
│  └─────┴─────┴─────┴─────┴─────┘      │
│                                         │
│  ■ 7日前 (12枚)                         │
│  ...                                    │
├─────────────────────────────────────────┤
│  [🔄 選択した写真を復元]                │
│  [🗑️ ゴミ箱を空にする]                 │
└─────────────────────────────────────────┘
```

---

## 4. ディレクトリ構造

```
src/modules/Deletion/
├── UseCases/
│   ├── DeletePhotosUseCase.swift
│   └── RestorePhotosUseCase.swift
├── Services/
│   ├── TrashManager.swift
│   ├── DeletionConfirmationService.swift
│   └── TrashStorage.swift
├── Views/
│   ├── TrashView.swift
│   └── DeletionConfirmationSheet.swift
├── ViewModels/
│   └── TrashViewModel.swift
├── Models/
│   └── TrashPhoto.swift
└── Storage/
    └── TrashDataStore.swift
```

---

## 5. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M6-T01 | TrashPhotoモデル | ゴミ箱写真モデル定義 | 1h | M1-T08 |
| M6-T02 | TrashDataStore実装 | ゴミ箱データ永続化 | 2h | M6-T01 |
| M6-T03 | TrashManager基盤 | ゴミ箱管理の基本実装 | 2h | M6-T02 |
| M6-T04 | moveToTrash実装 | ゴミ箱への移動処理 | 2h | M6-T03 |
| M6-T05 | restoreFromTrash実装 | 復元処理 | 2h | M6-T04 |
| M6-T06 | 自動クリーンアップ | 30日経過アイテムの削除 | 1.5h | M6-T03 |
| M6-T07 | DeletePhotosUseCase実装 | 削除UseCase | 2h | M6-T04 |
| M6-T08 | RestorePhotosUseCase実装 | 復元UseCase | 1.5h | M6-T05 |
| M6-T09 | DeletionConfirmationService | 確認サービス | 1h | M4-T11 |
| M6-T10 | TrashViewModel実装 | ゴミ箱画面VM | 2h | M6-T07,M6-T08 |
| M6-T11 | TrashView実装 | ゴミ箱画面View | 2.5h | M6-T10,M4-T06 |
| M6-T12 | DeletionConfirmationSheet | 削除確認シート | 1.5h | M6-T09 |
| M6-T13 | PHAsset削除連携 | システム削除確認との連携 | 2h | M2-T05 |
| M6-T14 | 単体テスト作成 | Deletion機能テスト | 2h | M6-T13 |

---

## 6. テストケース

### M6-T04: moveToTrash実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M6-T04-TC01 | 1枚の写真をゴミ箱へ | TrashPhotoが作成される |
| M6-T04-TC02 | 複数枚の一括移動 | 全てがゴミ箱に追加 |
| M6-T04-TC03 | 有効期限の設定 | 30日後の日付が設定 |

### M6-T05: restoreFromTrash実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M6-T05-TC01 | ゴミ箱から復元 | 写真ライブラリに戻る |
| M6-T05-TC02 | 期限切れアイテムの復元試行 | エラーが返る |
| M6-T05-TC03 | 複数枚の一括復元 | 全てが復元される |

### M6-T06: 自動クリーンアップ
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M6-T06-TC01 | 30日経過アイテムの検出 | isExpired=true |
| M6-T06-TC02 | クリーンアップ実行 | 期限切れが削除 |
| M6-T06-TC03 | 有効なアイテムは保持 | 削除されない |

### M6-T13: PHAsset削除連携
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M6-T13-TC01 | システム確認ダイアログ表示 | ダイアログ表示される |
| M6-T13-TC02 | ユーザーキャンセル時 | 削除されない |
| M6-T13-TC03 | ユーザー承認時 | 完全削除される |

---

## 7. 受け入れ条件

- [ ] ゴミ箱への移動が正しく動作
- [ ] 30日後に自動削除される
- [ ] ゴミ箱から復元が可能
- [ ] システムの削除確認ダイアログが表示される
- [ ] 削除容量が正しく計算される
- [ ] ゴミ箱を空にする機能が動作

---

## 8. 技術的考慮事項

### 8.1 データ保護
- ゴミ箱データは暗号化して保存
- サムネイルのみ保持（元データはPHAssetを参照）
- アプリ削除時にゴミ箱も削除される

### 8.2 Photos Framework制限
```swift
// 完全削除にはユーザー確認が必須
PHPhotoLibrary.shared().performChanges {
    PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
} completionHandler: { success, error in
    // ユーザーがキャンセルした場合はsuccess=false
}
```

### 8.3 ストレージ管理
- ゴミ箱使用量の上限設定（オプション）
- 容量逼迫時の警告表示
- バックグラウンドでの期限切れ処理

---

*最終更新: 2025-11-27*
