# MODULE M2: Photo Access & Scanning

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M2 |
| モジュール名 | Photo Access & Scanning |
| 責務 | Photos Frameworkとの統合、権限管理、写真データ取得 |
| 依存先 | M1 (Core Infrastructure) |
| 依存元 | M3, M5, M6 |

---

## 2. 主要コンポーネント

### 2.1 PhotoRepository
```swift
// Repositories/PhotoRepository.swift
final class PhotoRepository: PhotoRepositoryProtocol {
    private let imageManager = PHCachingImageManager()

    func fetchAllPhotos() async throws -> [Photo]
    func fetchThumbnail(for asset: PHAsset, size: CGSize) async throws -> UIImage
    func getStorageInfo() async throws -> StorageInfo
}
```

### 2.2 PhotoPermissionManager
```swift
// Services/PhotoPermissionManager.swift
final class PhotoPermissionManager {
    func checkPermissionStatus() -> PHAuthorizationStatus
    func requestPermission() async -> PHAuthorizationStatus
    func openSettings()
}
```

### 2.3 PhotoScanner
```swift
// Services/PhotoScanner.swift
final class PhotoScanner {
    func scan(progress: @escaping (Double) -> Void) async throws -> [Photo]
    func scanInBackground() async throws
}
```

### 2.4 Domain Models
```swift
// Models/Photo.swift
struct Photo: Identifiable, Hashable {
    let id: String
    let localIdentifier: String
    let creationDate: Date
    let modificationDate: Date
    let mediaType: PHAssetMediaType
    let mediaSubtypes: PHAssetMediaSubtype
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval  // 動画の場合
    let fileSize: Int64
    let isFavorite: Bool
}

// Models/StorageInfo.swift
struct StorageInfo {
    let totalCapacity: Int64
    let availableCapacity: Int64
    let photosUsedCapacity: Int64
    let reclaimableCapacity: Int64

    var usagePercentage: Double {
        Double(totalCapacity - availableCapacity) / Double(totalCapacity)
    }
}
```

---

## 3. ディレクトリ構造

```
src/modules/PhotoAccess/
├── Repositories/
│   └── PhotoRepository.swift
├── Services/
│   ├── PhotoPermissionManager.swift
│   ├── PhotoScanner.swift
│   └── ThumbnailCache.swift
├── Models/
│   ├── Photo.swift
│   └── StorageInfo.swift
└── Extensions/
    └── PHAsset+Extensions.swift
```

---

## 4. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M2-T01 | Info.plist権限設定 | NSPhotoLibraryUsageDescription追加 | 0.5h | M1-T01 |
| M2-T02 | PhotoPermissionManager実装 | 権限チェック・リクエスト機能 | 2h | M2-T01 |
| M2-T03 | Photoモデル実装 | ドメインモデルの定義 | 1h | M1-T08 |
| M2-T04 | PHAsset拡張 | PHAssetからPhotoへの変換 | 1.5h | M2-T03 |
| M2-T05 | PhotoRepository基盤 | Repository基本実装 | 2h | M2-T04 |
| M2-T06 | 写真一覧取得 | fetchAllPhotos実装 | 2h | M2-T05 |
| M2-T07 | サムネイル取得 | PHCachingImageManager活用 | 2h | M2-T06 |
| M2-T08 | ストレージ情報取得 | 容量計算ロジック | 1.5h | M2-T06 |
| M2-T09 | PhotoScanner実装 | プログレス付きスキャン | 2.5h | M2-T06 |
| M2-T10 | バックグラウンドスキャン | BGTaskScheduler連携 | 2h | M2-T09 |
| M2-T11 | ThumbnailCache実装 | NSCacheベースのキャッシュ | 1.5h | M2-T07 |
| M2-T12 | 単体テスト作成 | PhotoAccess機能のテスト | 2h | M2-T09 |

---

## 5. テストケース

### M2-T02: PhotoPermissionManager実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M2-T02-TC01 | 未決定状態でのステータス確認 | .notDetermined |
| M2-T02-TC02 | 権限許可後のステータス | .authorized |
| M2-T02-TC03 | 拒否された場合の設定誘導 | openSettings()が呼ばれる |

### M2-T06: 写真一覧取得
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M2-T06-TC01 | 空のライブラリでの取得 | 空配列が返る |
| M2-T06-TC02 | 100枚の写真取得 | 100件のPhoto配列 |
| M2-T06-TC03 | 権限なしでの取得試行 | photoAccessDeniedエラー |

### M2-T09: PhotoScanner実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M2-T09-TC01 | スキャン中のプログレス通知 | 0.0〜1.0の範囲で通知 |
| M2-T09-TC02 | スキャンキャンセル | 途中で停止可能 |
| M2-T09-TC03 | 10000枚のスキャン性能 | 60秒以内に完了 |

---

## 6. 受け入れ条件

- [ ] 写真ライブラリへのアクセス権限が正しく処理される
- [ ] 全写真の一覧が取得できる
- [ ] サムネイルがキャッシュされる
- [ ] ストレージ情報が正確に計算される
- [ ] スキャン進捗がリアルタイムで通知される
- [ ] バックグラウンドスキャンが動作する

---

## 7. 技術的考慮事項

### 7.1 パフォーマンス
- PHFetchResultはlazy loadingを活用
- サムネイル取得は並列処理
- 大量写真はバッチ処理

### 7.2 メモリ管理
- PHCachingImageManagerでキャッシュ管理
- 不要なサムネイルは積極的に解放
- autoreleasepoolでメモリピークを抑制

### 7.3 エラーハンドリング
- 権限拒否時の適切なUI表示
- ネットワークエラー（iCloud写真）への対応
- 破損したアセットのスキップ

---

*最終更新: 2025-11-27*
