# UI/UX設計ガイド

## 作成日
2025-12-22

## 概要
LightRoll CleanerのUI/UX設計原則とガイドラインを定義します。

---

## UI/UX設計原則

### 1. 1画面1目的
- 各画面は単一の明確な目的を持つ
- ユーザーがその画面で何をすべきかが一目でわかる

**例**:
- **HomeView**: ストレージ状況の確認とスキャン開始
- **GroupListView**: 写真グループの一覧表示
- **GroupDetailView**: グループ内の写真選択と削除
- **SettingsView**: アプリ設定の変更

### 2. 3クリック以内で目的達成
- 主要なタスクは3クリック（タップ）以内で完了できる

**タスク例**:
1. **写真削除**:
   - クリック1: ホーム画面で「グループを確認」
   - クリック2: グループ詳細で写真選択
   - クリック3: 削除ボタンタップ → 確認 → 完了

2. **スキャン実行**:
   - クリック1: ホーム画面で「スキャン」ボタン
   - （自動実行）
   - クリック2: 完了後「グループを確認」

### 3. エラーは具体的に、解決策も提示
- エラーメッセージは何が起きたかを明確に説明
- 次に何をすべきか（解決策）を提示

**例**:
```swift
// ❌ 悪い例
"エラーが発生しました"

// ✅ 良い例
"写真の読み込みに失敗しました。
写真へのアクセス権限を確認してください。
設定 > プライバシー > 写真 から許可してください。"
```

---

## 必須UI要素チェックリスト

すべての画面で以下の要素を実装する必要があります。

### □ ローディング表示
- **目的**: 処理中であることをユーザーに伝える
- **実装**: `ProgressView()` または カスタムローディング
- **タイミング**: データ取得、API呼び出し、削除処理中

```swift
// 実装例
switch viewState {
case .loading:
    ProgressView()
        .scaleEffect(1.5)
}
```

### □ エラー表示
- **目的**: 問題が発生したことを伝え、解決策を提示
- **実装**: `Alert` または `EmptyStateView(type: .error)`
- **タイミング**: API失敗、権限拒否、ネットワークエラー

```swift
// 実装例
.alert("エラー", isPresented: $showErrorAlert) {
    Button("OK") { showErrorAlert = false }
} message: {
    Text(errorMessage)
}
```

### □ 成功表示
- **目的**: 操作が成功したことをユーザーに伝える
- **実装**: `ToastView` または `Banner`
- **タイミング**: 削除完了、保存完了、設定変更完了

```swift
// 実装例（推奨）
@State private var showSuccessToast = false
@State private var successMessage = ""

// 削除成功時
showSuccessToast = true
successMessage = "3枚（12.5 MB）を削除しました"

// UI
.overlay {
    if showSuccessToast {
        ToastView(message: successMessage, type: .success)
    }
}
```

### □ 空状態
- **目的**: データがないことを伝え、次のアクションを促す
- **実装**: `EmptyStateView(type: .empty)`
- **タイミング**: 検索結果なし、グループなし、履歴なし

```swift
// 実装例
if photos.isEmpty {
    EmptyStateView(
        type: .empty,
        customIcon: "photo",
        customTitle: "写真がありません",
        customMessage: "このグループに写真が見つかりませんでした"
    )
}
```

### □ 確認ダイアログ
- **目的**: 重要な操作（削除等）の前に確認を取る
- **実装**: `confirmationDialog` または `Alert`
- **タイミング**: 削除、復元、設定リセット

```swift
// 実装例
.confirmationDialog(
    "選択した写真を削除",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("削除する", role: .destructive) {
        Task { await deleteSelectedPhotos() }
    }
    Button("キャンセル", role: .cancel) {}
} message: {
    Text("3枚の写真（12.5 MB）を削除しますか？")
}
```

---

## 状態管理パターン（MV Pattern）

### ViewState パターン
複雑な状態は `enum ViewState` で統合管理します。

```swift
public enum ViewState: Sendable, Equatable {
    case loading          // 初回読み込み中
    case loaded           // 読み込み完了
    case processing       // 処理中（削除等）
    case error(String)    // エラー発生
}

@State private var viewState: ViewState = .loading

var body: some View {
    switch viewState {
    case .loading:
        loadingView
    case .loaded, .processing:
        contentView
    case .error(let message):
        errorView(message: message)
    }
}
```

### 個別Boolean状態
単純なフラグは個別の`@State`で管理します。

```swift
@State private var showDeleteConfirmation = false  // 削除確認ダイアログ
@State private var showErrorAlert = false          // エラーアラート
@State private var showSuccessToast = false        // 成功トースト
```

---

## アニメーション・トランジション

### 推奨アニメーション
```swift
// リスト項目の追加・削除
.animation(.easeOut(duration: 0.3), value: photos)

// モーダル表示
.transition(.move(edge: .bottom).combined(with: .opacity))

// スケールアニメーション
.scaleEffect(isSelected ? 1.1 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
```

---

## アクセシビリティ

### VoiceOver対応
```swift
Image(systemName: "trash")
    .accessibilityLabel("削除")
    .accessibilityHint("選択した写真を削除します")
```

### Dynamic Type対応
```swift
Text("タイトル")
    .font(.headline) // システムフォントを使用（自動スケール）
```

### カラーコントラスト
- WCAG 2.1 AA基準（4.5:1以上）を満たす
- DesignSystem.Colors で定義済み

---

## パフォーマンス最適化

### 画像読み込み
- サムネイルサイズ: 200x200
- LazyVGrid使用でオンデマンド読み込み

```swift
LazyVGrid(columns: columns, spacing: spacing) {
    ForEach(photos) { photo in
        PhotoThumbnail(photo: photo)
    }
}
```

### キャッシュ戦略
- サムネイル: PHCachingImageManager
- 統計情報: UserDefaults（有効期限30秒）
- 分析結果: NSCache

---

## デザインシステム（Design Tokens）

### Spacing
```swift
LRSpacing.xs   // 4pt
LRSpacing.sm   // 8pt
LRSpacing.md   // 16pt
LRSpacing.lg   // 24pt
LRSpacing.xl   // 32pt
LRSpacing.xxl  // 48pt
```

### Colors
```swift
Color.LightRoll.primary       // アクセントカラー
Color.LightRoll.background    // 背景色
Color.LightRoll.surfaceCard   // カード背景
Color.LightRoll.success       // 成功（緑）
Color.LightRoll.error         // エラー（赤）
```

### Typography
```swift
.font(.largeTitle)  // 34pt
.font(.title)       // 28pt
.font(.headline)    // 17pt
.font(.body)        // 17pt
.font(.caption)     // 12pt
```

---

## ユーザーフィードバック設計

### 削除操作のフィードバック例

#### 1. 確認ダイアログ
```
┌─────────────────────────────┐
│   選択した写真を削除         │
│                             │
│ 3枚の写真（12.5 MB）を      │
│ 削除しますか？              │
│                             │
│  [キャンセル]  [削除する]    │
└─────────────────────────────┘
```

#### 2. 処理中表示
```
┌─────────────────────────────┐
│                             │
│      削除中...               │
│      ●●●●●○○○                │
│                             │
└─────────────────────────────┘
```

#### 3. 成功トースト（★ 実装必須）
```
┌─────────────────────────────┐
│  ✓ 3枚（12.5 MB）を削除しました │
└─────────────────────────────┘
```

---

## 実装チェックリスト（新規画面作成時）

### 基本UI要素
- [ ] ローディング表示（viewState = .loading）
- [ ] エラー表示（viewState = .error）
- [ ] 空状態表示（photos.isEmpty）
- [ ] ナビゲーションタイトル
- [ ] 戻るボタン（必要な場合）

### インタラクション
- [ ] 確認ダイアログ（削除等の重要操作）
- [ ] 成功フィードバック（トースト）
- [ ] エラーハンドリング（try-catch）
- [ ] プログレス表示（長時間処理）

### アクセシビリティ
- [ ] VoiceOverラベル（画像、ボタン）
- [ ] Dynamic Type対応（システムフォント使用）
- [ ] カラーコントラスト（WCAG AA準拠）

### パフォーマンス
- [ ] LazyVGrid/LazyVStack使用（長いリスト）
- [ ] .task修飾子でライフサイクル管理
- [ ] キャッシュ活用（統計情報、サムネイル）

---

## 既知の問題と改善点（2025-12-22 設計レビュー）

### 問題3: GroupDetailView UX問題（72点）

**欠如している要素**:
- ❌ 削除成功トースト
- ❌ deleteSelectedPhotos()のエラーハンドリング
- ❌ 削除アニメーション

**改善方針**:
```swift
// ✅ 成功トーストの追加
@State private var showSuccessToast = false
@State private var successMessage = ""

// deleteSelectedPhotos()の改善
private func deleteSelectedPhotos() async {
    guard !selectedPhotoIds.isEmpty else { return }

    viewState = .processing

    do {
        let idsToDelete = Array(selectedPhotoIds)
        let deletedPhotos = photos.filter { idsToDelete.contains($0.id) }
        let totalSize = deletedPhotos.reduce(0) { $0 + $1.fileSize }

        await onDeletePhotos?(idsToDelete)

        selectedPhotoIds.removeAll()
        photos = photos.filter { !idsToDelete.contains($0.id) }

        viewState = .loaded

        // ✅ 成功トースト表示
        let formattedSize = ByteCountFormatter.string(
            fromByteCount: totalSize,
            countStyle: .file
        )
        successMessage = "\(idsToDelete.count)枚（\(formattedSize)）を削除しました"
        showSuccessToast = true

    } catch {
        // ✅ エラーハンドリング
        viewState = .loaded
        errorMessage = error.localizedDescription
        showErrorAlert = true
    }
}
```

---

*最終更新: 2025-12-22*
*対応ARCHITECTURE.md: Section 7.2（エラー表示）*
