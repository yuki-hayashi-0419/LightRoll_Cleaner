# 表示設定（DisplaySettings）統合状態調査結果

**調査日**: 2025-12-24
**セッションID**: display-settings-analysis-001
**調査者**: @spec-architect

---

## エグゼクティブサマリー

DisplaySettingsViewの**4つの設定項目すべてが未統合**であることが判明。
設定UIは完全に実装されているが、実際のアプリ機能には一切反映されていない。

---

## 調査対象

DisplaySettingsViewで管理されている以下の4つの設定項目：

1. **グリッド列数** (gridColumns: 2〜6列)
2. **ファイルサイズ表示** (showFileSize: Bool)
3. **撮影日表示** (showDate: Bool)
4. **並び順** (sortOrder: SortOrder列挙型)

---

## 詳細調査結果

### 1. グリッド列数（gridColumns）

#### 設定UI
- ✅ **実装済み**: DisplaySettingsView.swift:116-123
- ステッパーで2〜6列を調整可能
- onChange時にSettingsServiceへ保存

#### 統合状態
- ❌ **未統合**

#### 問題箇所

| ファイル | 行数 | 問題内容 |
|----------|------|----------|
| GroupDetailView.swift | 272 | `columns: 3`にハードコード |
| TrashView.swift | 105-107 | `GridItem(.adaptive(...))`にハードコード |

#### 原因
- PhotoGridコンポーネントは`columns`パラメータを受け取る機能はある
- しかし、呼び出し側がSettingsServiceから取得していない
- 各ビューでハードコードされた値を使用

---

### 2. ファイルサイズ表示（showFileSize）

#### 設定UI
- ✅ **実装済み**: DisplaySettingsView.swift:140-149
- トグルスイッチでオン/オフ可能
- onChange時にSettingsServiceへ保存

#### 統合状態
- ❌ **未統合**

#### 問題箇所

| コンポーネント | 問題内容 |
|----------------|----------|
| PhotoThumbnail.swift | ファイルサイズ表示機能が実装されていない |
| PhotoGrid.swift | ファイルサイズ表示機能なし |

#### 原因
- PhotoThumbnailはサムネイル画像の表示に特化
- ファイルサイズをオーバーレイ表示する機能が存在しない
- どのビューでもshowFileSizeフラグを参照していない

---

### 3. 撮影日表示（showDate）

#### 設定UI
- ✅ **実装済み**: DisplaySettingsView.swift:153-162
- トグルスイッチでオン/オフ可能
- onChange時にSettingsServiceへ保存

#### 統合状態
- ❌ **未統合**

#### 問題箇所

| コンポーネント | 問題内容 |
|----------------|----------|
| PhotoThumbnail.swift | 撮影日表示機能が実装されていない |
| PhotoGrid.swift | 撮影日表示機能なし |

#### 原因
- PhotoThumbnailはサムネイル画像の表示に特化
- 撮影日をオーバーレイ表示する機能が存在しない
- どのビューでもshowDateフラグを参照していない

---

### 4. 並び順（sortOrder）

#### 設定UI
- ✅ **実装済み**: DisplaySettingsView.swift:181-190
- Pickerで以下の選択肢：
  - 新しい順 (dateDescending)
  - 古い順 (dateAscending)
  - 容量大きい順 (sizeDescending)
  - 容量小さい順 (sizeAscending)
- onChange時にSettingsServiceへ保存

#### 統合状態
- ❌ **未統合**

#### 問題箇所

| ファイル | 問題内容 |
|----------|----------|
| GroupDetailView.swift | `loadPhotos()`で並び替えロジックなし |
| TrashView.swift | `loadTrashPhotos()`で並び替えロジックなし |

#### 原因
- PhotoRepositoryから取得した写真の配列をそのまま表示
- sortOrderフラグを参照して`sorted(by:)`を実行していない

---

## 影響範囲

### 影響を受けるビュー

1. **GroupDetailView.swift** (グループ詳細画面)
   - グリッド列数がハードコード（3列固定）
   - 並び替えが機能しない
   - ファイルサイズ・撮影日が表示されない

2. **TrashView.swift** (ゴミ箱画面)
   - グリッド列数がハードコード（adaptive）
   - 並び替えが機能しない
   - ファイルサイズ・撮影日が表示されない

3. **PhotoGrid.swift** (写真グリッドコンポーネント)
   - columns パラメータは受け取れるが、呼び出し側が未対応

4. **PhotoThumbnail.swift** (サムネイルコンポーネント)
   - 情報表示機能が実装されていない

---

## 修正計画

### DISPLAY-001: グリッド列数の統合

**優先度**: P1（高）
**推定工数**: 2時間
**品質目標**: 90点以上

#### 実施内容

1. **GroupDetailView.swift の修正**
   - `@Environment(SettingsService.self)`を追加
   - `PhotoGrid`の`columns`パラメータを`settingsService.settings.displaySettings.gridColumns`から取得
   - 設定変更時の即時反映確認

2. **TrashView.swift の修正**
   - `@Environment(SettingsService.self)`を追加
   - `gridColumns`をハードコードから`settingsService.settings.displaySettings.gridColumns`に変更
   - GridItemの生成ロジックを調整

#### 成果物
- グリッド列数が設定画面から変更可能になる
- 設定変更が即座に反映される

---

### DISPLAY-002: ファイルサイズ・撮影日表示の実装

**優先度**: P2（中）
**推定工数**: 3時間
**品質目標**: 90点以上

#### 実施内容

1. **PhotoThumbnail.swift の拡張**
   - 情報表示用オーバーレイレイヤー追加
   - `showFileSize: Bool`パラメータ追加
   - `showDate: Bool`パラメータ追加
   - ファイルサイズ表示ロジック実装（例: "2.3 MB"）
   - 撮影日表示ロジック実装（例: "2025/12/24"）
   - レイアウト調整（グラデーションオーバーレイ + テキスト）

2. **PhotoGrid.swift の修正**
   - `showFileSize`パラメータ追加
   - `showDate`パラメータ追加
   - PhotoThumbnailへパラメータ転送

3. **GroupDetailView.swift / TrashView.swift の修正**
   - `@Environment(SettingsService.self)`追加（既にDISPLAY-001で追加済み）
   - PhotoGridに`showFileSize`/`showDate`パラメータを渡す

#### 成果物
- ファイルサイズ・撮影日がサムネイル上に表示される
- 設定画面でオン/オフ可能になる
- アクセシビリティ対応完了

---

### DISPLAY-003: 並び順の実装

**優先度**: P1（高）
**推定工数**: 2.5時間
**品質目標**: 90点以上

#### 実施内容

1. **GroupDetailView.swift の修正**
   - `loadPhotos()`メソッド内で並び替えロジック追加
   - SortOrderに基づく`sorted(by:)`実装：
     ```swift
     let sortOrder = settingsService.settings.displaySettings.sortOrder
     switch sortOrder {
     case .dateDescending:
         photos.sort { $0.creationDate > $1.creationDate }
     case .dateAscending:
         photos.sort { $0.creationDate < $1.creationDate }
     case .sizeDescending:
         photos.sort { $0.fileSize > $1.fileSize }
     case .sizeAscending:
         photos.sort { $0.fileSize < $1.fileSize }
     }
     ```
   - 設定変更時の即時反映確認

2. **TrashView.swift の修正**
   - `loadTrashPhotos()`メソッド内で並び替えロジック追加
   - 同様のswitchロジック実装

#### 成果物
- 写真一覧が設定した並び順で表示される
- 設定変更が即座に反映される

---

### DISPLAY-004: テスト生成

**優先度**: P3（低）
**推定工数**: 1.5時間
**品質目標**: カバレッジ80%以上

#### 実施内容

1. **グリッド列数変更のテスト**
   - 2列〜6列の各設定でPhotoGridが正しく表示されるか
   - 設定変更時に即座に反映されるか

2. **ファイルサイズ/撮影日表示のテスト**
   - オン時に情報が表示されるか
   - オフ時に情報が非表示になるか
   - フォーマットが正しいか

3. **並び順変更のテスト**
   - 各並び順で正しくソートされるか
   - 設定変更時に即座に反映されるか

#### 成果物
- Swift Testingテストケース（15〜20件）
- 全テスト合格

---

## 推定合計工数

| タスクID | 内容 | 工数 |
|----------|------|------|
| DISPLAY-001 | グリッド列数統合 | 2h |
| DISPLAY-002 | 情報表示実装 | 3h |
| DISPLAY-003 | 並び順実装 | 2.5h |
| DISPLAY-004 | テスト生成 | 1.5h |
| **合計** | | **9時間** |

---

## 実装推奨順序

1. **DISPLAY-001** (グリッド列数)
   - 影響が大きく、実装も比較的簡単
   - ユーザー体験への即効性が高い

2. **DISPLAY-003** (並び順)
   - ユーザー体験への影響が大きい
   - ロジック実装のみで完結

3. **DISPLAY-002** (情報表示)
   - UI改修が必要で工数大
   - 視覚的な効果が高い

4. **DISPLAY-004** (テスト)
   - 全機能実装後にまとめて実施
   - 品質担保

---

## 次回セッション推奨アクション

### Option A: DisplaySettings統合を優先（推奨）
- DISPLAY-001〜003を実施（合計7.5時間）
- ユーザー体験の大幅改善
- 設定画面の信頼性向上

### Option B: M10リリース準備を優先
- App Store Connect設定（M10-T04）
- TestFlight配信（M10-T05）
- 最終ビルド・審査提出（M10-T06）
- v1.0リリース後、v1.1でDisplaySettings統合

---

**最終更新**: 2025-12-24
**次回セッション**: display-settings-integration-001（DISPLAY-001実装）またはM10-T04
