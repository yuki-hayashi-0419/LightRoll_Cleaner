# 修正計画書: ゴミ箱機能バグ修正

## 作成日: 2025-12-24
## 作成者: @spec-architect
## ステータス: 計画策定完了

---

## 1. 概要

### 対象問題

| 問題ID | 問題名 | 影響度 |
|--------|--------|--------|
| BUG-TRASH-001 | ゴミ箱での写真選択問題 | Medium |
| BUG-TRASH-002 | 復元操作時のクラッシュ問題 | Critical |

### 修正目的
1. ゴミ箱での写真選択をより直感的に改善
2. 復元操作時のクラッシュを完全解消
3. 非同期処理の安全性向上

### 期待される効果
- ユーザーがストレスなく写真を選択・復元できる
- アプリの安定性向上（クラッシュゼロ）
- エラーハンドリングの堅牢化

---

## 2. 優先順位付け

各修正項目を以下の基準で評価：

| 項目 | 緊急度 | 影響度 | 難易度 | 時間 | 優先度 |
|------|--------|--------|--------|------|--------|
| BUG-TRASH-002-A: RestorePhotosUseCaseでのID不一致修正 | High | High | Medium | 1.5h | P1 |
| BUG-TRASH-002-B: Photos Frameworkコールバック問題修正 | High | High | Medium | 1h | P1 |
| BUG-TRASH-002-C: SwiftUI環境オブジェクト未注入修正 | High | High | Easy | 0.5h | P1 |
| BUG-TRASH-002-D: 非同期処理中のビュー破棄対策 | Medium | Medium | Medium | 1h | P2 |
| BUG-TRASH-001: ゴミ箱選択UX改善 | Medium | Medium | Easy | 1h | P2 |

**合計推定時間: 5時間**

---

## 3. 修正手順（優先度順）

### P1-A: RestorePhotosUseCaseでのID不一致修正（1.5h）

**問題の詳細**:
- `RestorePhotosUseCase.execute()`で`PhotoAsset.id`と`TrashPhoto.originalPhotoId`のマッチングを行っている
- しかし、`TrashView`からは`selectedPhotoIds`（originalPhotoId）を使用
- `PhotoAsset`を作成する際に`originalPhotoId`を正しく渡す必要がある

**現状コード（TrashView.swift:738-745）**:
```swift
let input = RestorePhotosInput(
    photos: selectedPhotos.map {
        PhotoAsset(
            id: $0.originalPhotoId,  // ← ここは正しい
            creationDate: nil,
            fileSize: $0.fileSize
        )
    }
)
```

**現状コード（RestorePhotosUseCase.swift:237-239）**:
```swift
let photoIdSet = Set(photoAssets.map { $0.id })
let matchedPhotos = allTrashPhotos.filter {
    photoIdSet.contains($0.originalPhotoId)  // ← マッチングロジック
}
```

**分析結果**: IDマッチングロジック自体は正しい。問題は他にある可能性。

**修正ステップ**:
1. デバッグログを追加してIDの流れを確認
2. `TrashPhoto`のID生成ロジックを確認
3. 必要に応じてID一致検証を強化

**テスト方法**:
- 単体テスト: `RestorePhotosUseCaseTests`でID不一致ケース追加
- 統合テスト: TrashView → RestorePhotosUseCase → TrashManager のフロー確認

**ロールバック方法**:
- 変更前のRestorePhotosUseCase.swiftを復元

---

### P1-B: Photos Frameworkコールバック問題修正（1h）

**問題の詳細**:
- `TrashManager.generateThumbnailData()`で`withCheckedContinuation`を使用
- `PHImageManager.requestImage`は複数回コールバックを呼ぶ可能性がある
- 2回目のコールバックで`continuation.resume()`を呼ぶとクラッシュ

**現状コード（TrashManager.swift:339-360）**:
```swift
let image: PlatformImage? = await withCheckedContinuation { continuation in
    PHImageManager.default().requestImage(
        for: asset,
        targetSize: thumbnailSize,
        contentMode: .aspectFill,
        options: options
    ) { image, info in
        // ここが複数回呼ばれる可能性
        continuation.resume(returning: image)
    }
}
```

**修正内容**:
```swift
let image: PlatformImage? = await withCheckedContinuation { continuation in
    var hasResumed = false  // フラグ追加

    PHImageManager.default().requestImage(
        for: asset,
        targetSize: thumbnailSize,
        contentMode: .aspectFill,
        options: options
    ) { image, info in
        // 既にresumeしていたら無視
        guard !hasResumed else { return }

        // 劣化画像（isDegraded）の場合はスキップ
        if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
            return  // 高品質画像を待つ
        }

        hasResumed = true
        continuation.resume(returning: image)
    }
}
```

**テスト方法**:
- 大量の写真（50枚以上）をゴミ箱に移動してサムネイル生成
- iCloud写真でネットワーク経由取得のケースをテスト

**ロールバック方法**:
- 変更前のTrashManager.swiftを復元

---

### P1-C: SwiftUI環境オブジェクト未注入修正（0.5h）

**問題の詳細**:
- `TrashView`が`SettingsService`を`@Environment`から取得
- 親ビューで`.environment(SettingsService())`が設定されていない場合クラッシュ

**確認項目**:
1. `ContentView`でTrashViewを表示する際に環境が注入されているか
2. TrashViewのPreviewで環境が設定されているか

**現状コード（TrashView.swift:62）**:
```swift
@Environment(SettingsService.self) private var settingsService
```

**修正方針**:
- TrashViewを呼び出す全ての箇所で`.environment(settingsService)`を確認
- デフォルト値を持つ安全なアクセス方法を検討

**テスト方法**:
- Preview表示確認
- 実機でゴミ箱画面遷移テスト

**ロールバック方法**:
- 環境注入箇所を元に戻す

---

### P2-A: 非同期処理中のビュー破棄対策（1h）

**問題の詳細**:
- 復元処理中にユーザーがビューを閉じると、`@State`変数へのアクセスでクラッシュ
- `Task`がビューのライフサイクルと連動していない

**現状コード（TrashView.swift:474-477）**:
```swift
Button {
    Task {
        await handleRestore()  // 非同期処理
    }
} label: {
```

**修正方針**:
```swift
// Option 1: @State var restoreTask: Task<Void, Never>? を追加
// .onDisappear でキャンセル

// Option 2: 処理中フラグ + 完了時のビュー存在確認
@State private var isRestoring = false

private func executeRestore() async {
    guard !isRestoring else { return }
    isRestoring = true
    defer { isRestoring = false }

    // ... 復元処理
}
```

**テスト方法**:
- 復元中に素早くビューを閉じる操作を繰り返す
- メモリリーク確認（Instruments使用）

**ロールバック方法**:
- 追加したタスク管理コードを削除

---

### P2-B: ゴミ箱選択UX改善（1h）

**問題の詳細**:
- `toggleSelection`が`isEditMode`時のみ動作
- ユーザーは「選択」ボタンを押さずに写真をタップしても何も起きないと混乱

**現状コード（TrashView.swift:703-711）**:
```swift
private func toggleSelection(_ photo: TrashPhoto) {
    guard isEditMode else { return }  // ← 編集モード時のみ

    if selectedPhotoIds.contains(photo.originalPhotoId) {
        selectedPhotoIds.remove(photo.originalPhotoId)
    } else {
        selectedPhotoIds.insert(photo.originalPhotoId)
    }
}
```

**修正案**:

**案A（推奨）: タップで自動編集モード開始**
```swift
private func toggleSelection(_ photo: TrashPhoto) {
    // 編集モードでない場合は自動的に開始
    if !isEditMode {
        withAnimation {
            isEditMode = true
        }
    }

    if selectedPhotoIds.contains(photo.originalPhotoId) {
        selectedPhotoIds.remove(photo.originalPhotoId)
    } else {
        selectedPhotoIds.insert(photo.originalPhotoId)
    }
}
```

**案B: 長押しで選択開始（iOSの標準動作に準拠）**
```swift
trashPhotoCell(photo)
    .onLongPressGesture {
        if !isEditMode {
            withAnimation {
                isEditMode = true
            }
        }
        selectedPhotoIds.insert(photo.originalPhotoId)
    }
```

**推奨: 案A**
- 理由: ゴミ箱は「復元または削除」が主目的なので、タップで即選択が直感的

**テスト方法**:
- 編集モードOFF状態で写真をタップ → 編集モードが開始し選択される
- 複数選択後に「完了」ボタンで編集モード終了

**ロールバック方法**:
- `guard isEditMode else { return }`を復元

---

## 4. リスク評価

| リスク | 発生確率 | 影響度 | 対策 |
|--------|----------|--------|------|
| Photos Framework API変更 | Low | High | iOS 18 API互換性テスト |
| 既存テストの破壊 | Medium | Medium | 変更前に全テスト実行 |
| パフォーマンス劣化 | Low | Medium | 大量データでベンチマーク |
| 新規バグ導入 | Medium | Medium | 段階的リリース（P1→P2） |
| UI/UXの違和感 | Medium | Low | ユーザーテスト実施 |

---

## 5. テスト計画

### 単体テスト

| テストケース | 対象 | 期待結果 |
|--------------|------|----------|
| IDマッチング正常系 | RestorePhotosUseCase | 全写真が正しくマッチ |
| IDマッチング異常系（存在しないID） | RestorePhotosUseCase | 適切なエラー |
| Continuation重複呼び出し | TrashManager | クラッシュしない |
| 編集モード自動開始 | TrashView | isEditMode = true |

### 統合テスト

| テストケース | フロー | 期待結果 |
|--------------|--------|----------|
| 復元フロー完全テスト | TrashView → UseCase → Manager | 写真が復元される |
| 大量データ復元 | 100枚選択 → 復元 | 全件成功、パフォーマンス許容範囲 |
| エラー時の挙動 | ネットワーク切断中に復元 | エラーダイアログ表示 |

### 実機テスト

| テストケース | 条件 | 期待結果 |
|--------------|------|----------|
| iPhone 15 Pro Max | iOS 18.x | クラッシュなし |
| 低メモリ状態 | バックグラウンドアプリ多数 | 正常動作 |
| iCloud同期中 | 写真同期中に操作 | 正常動作 |
| 処理中ビュー遷移 | 復元中に戻るボタン | クラッシュなし |

### リグレッションテスト

| 対象機能 | テスト内容 |
|----------|------------|
| ゴミ箱一覧表示 | 写真が正しく表示される |
| 完全削除 | 選択した写真が削除される |
| ゴミ箱を空にする | 全写真が削除される |
| 期限切れ自動削除 | 30日経過した写真が消える |

---

## 6. 実装チェックリスト

### BUG-TRASH-002: クラッシュ問題

- [ ] **P1-A: RestorePhotosUseCaseでのID不一致修正**
  - [ ] デバッグログ追加
  - [ ] IDマッチングロジック確認
  - [ ] 必要に応じて修正
  - [ ] 単体テスト追加
  - [ ] 実機確認

- [ ] **P1-B: Photos Frameworkコールバック問題修正**
  - [ ] `hasResumed`フラグ追加
  - [ ] `isDegraded`チェック追加
  - [ ] 単体テスト追加
  - [ ] 大量データテスト
  - [ ] 実機確認

- [ ] **P1-C: SwiftUI環境オブジェクト未注入修正**
  - [ ] 呼び出し箇所の環境注入確認
  - [ ] Previewの環境設定確認
  - [ ] 実機でゴミ箱画面遷移テスト

- [ ] **P2-A: 非同期処理中のビュー破棄対策**
  - [ ] タスク管理コード追加
  - [ ] `isRestoring`フラグ追加
  - [ ] ビュー破棄テスト
  - [ ] メモリリークテスト

### BUG-TRASH-001: ゴミ箱選択問題

- [ ] **P2-B: ゴミ箱選択UX改善**
  - [ ] `toggleSelection`修正（自動編集モード開始）
  - [ ] UIテスト
  - [ ] 実機確認

### ドキュメント更新

- [ ] ERROR_KNOWLEDGE_BASE.md更新
- [ ] PROGRESS.md更新
- [ ] TASKS.md更新
- [ ] IMPLEMENTED.md更新

---

## 7. 成功条件

| 条件 | 検証方法 | 基準 |
|------|----------|------|
| ゴミ箱での写真選択が直感的に動作する | ユーザーテスト | タップで選択開始 |
| 復元操作でクラッシュが発生しない | 100回繰り返しテスト | クラッシュ0回 |
| 大量データでも安定動作 | 500枚のゴミ箱データ | 復元成功率100% |
| 既存機能に影響がない | リグレッションテスト | 全テストパス |
| テストが全てパスする | CI実行 | 100%パス |
| 品質スコア90点以上 | @spec-validator評価 | 90点以上 |

---

## 8. タイムライン

| フェーズ | 内容 | 所要時間 | 担当 |
|----------|------|----------|------|
| Phase 1 | P1-A, P1-B, P1-C（クラッシュ修正） | 3h | @spec-developer |
| Phase 2 | P2-A, P2-B（UX改善） | 2h | @spec-developer |
| Phase 3 | 統合テスト・実機テスト | 1h | @spec-validator |
| Phase 4 | ドキュメント更新 | 0.5h | @spec-architect |
| **合計** | - | **6.5h** | - |

---

## 9. 依存関係

```
Phase 1（クラッシュ修正）
├── P1-A: RestorePhotosUseCase修正
├── P1-B: TrashManager修正
└── P1-C: 環境注入確認
    │
    ▼
Phase 2（UX改善）
├── P2-A: 非同期処理対策
└── P2-B: 選択UX改善
    │
    ▼
Phase 3（検証）
└── 統合テスト・実機テスト
    │
    ▼
Phase 4（ドキュメント）
└── ドキュメント更新
```

---

## 10. 備考

### 関連タスク
- DISPLAY-001〜004: DisplaySettings統合（完了済み）
- SETTINGS-001/002: 設定ページ統合（完了済み）

### 参考資料
- [Apple Developer: PHImageManager](https://developer.apple.com/documentation/photokit/phimagemanager)
- [Swift Concurrency: withCheckedContinuation](https://developer.apple.com/documentation/swift/withcheckedcontinuation(function:_:))

### 次回セッション推奨
1. **本修正計画の実装開始**（Phase 1: 3h）
2. M10リリース準備と並行可能

---

*計画策定: @spec-architect*
*レビュー待ち: @spec-developer, @spec-validator*
