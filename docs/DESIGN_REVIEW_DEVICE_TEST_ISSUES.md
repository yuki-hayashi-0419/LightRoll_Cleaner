# 実機テスト問題の設計レビュー

## 実施日
2025-12-22

## レビュー概要
- **対象**: 実機テストで発見された3つの問題
- **レビュアー**: @spec-architect
- **スコープ**: アーキテクチャ設計、MV Pattern適合性、UX/UI設計

---

## 問題1: ゴミ箱サムネイル未表示

### 症状
- **現象**: 写真を削除してもゴミ箱に入らず、直接Photos.appから消える
- **期待動作**: アプリ内ゴミ箱に30日保管 → その後完全削除
- **現状動作**: PHAssetChangeRequest.deleteAssetsで即時削除

### 設計分析

#### 1. アーキテクチャ適合性（18/25点）

**問題点**:
- **ContentView.swift（Line 113-142, 143-175）**: DeletePhotosUseCaseを**使用せず**、PhotoRepository.delete()を直接呼び出している
- **設計違反**: MV Patternの「Services経由でビジネスロジック実行」原則に違反
- **責務分離の欠如**: Viewレイヤーがデータ永続化の詳細を知っている状態

```swift
// ❌ 問題のあるコード（ContentView.swift Line 113-142）
onDeletePhotos: { photoIds in
    Task { @MainActor in
        do {
            let photoAssets = photoIds.map { id in
                PhotoAsset(id: id, creationDate: Date(), fileSize: 0)
            }

            // DeletePhotosUseCaseを使うべきだが、photoRepository.delete()を直接使用
            let input = DeletePhotosInput(
                photos: photoAssets,
                permanently: false // ゴミ箱へ移動
            )
            _ = try await deletePhotosUseCase.execute(input)

            photoRepository.clearStorageInfoCache()
        } catch {
            print("写真削除エラー: \(error.localizedDescription)")
        }
    }
}
```

**正しい設計**:
```swift
// ✅ 正しい実装
onDeletePhotos: { photoIds in
    Task { @MainActor in
        do {
            let photoAssets = photoIds.map { id in
                PhotoAsset(id: id, creationDate: Date(), fileSize: 0)
            }

            // DeletePhotosUseCaseを使用
            let input = DeletePhotosInput(
                photos: photoAssets,
                permanently: false // ゴミ箱へ移動
            )
            _ = try await deletePhotosUseCase.execute(input)

            photoRepository.clearStorageInfoCache()
        } catch {
            print("写真削除エラー: \(error.localizedDescription)")
        }
    }
}
```

#### 2. データフローの問題（設計矛盾）

**期待されるデータフロー**:
```
View (ContentView)
  └─> UseCase (DeletePhotosUseCase)
      ├─> TrashManager.moveToTrash() ← ゴミ箱に保存
      └─> PhotoRepository.delete() ← Photos.appから削除（30日後）
```

**実際のデータフロー**:
```
View (ContentView)
  └─> PhotoRepository.delete() ← 直接削除（ゴミ箱をバイパス）
```

**根本原因**:
- ContentView.swiftの実装者が、DeletePhotosUseCaseの存在を認識していながら、その責務（ゴミ箱統合）を理解していなかった
- TrashManagerがEnvironmentに注入されているが、UseCaseと統合されていない

#### 3. TrashManagerの設計（問題なし）

**TrashManager.swift**:
- ✅ 責務は明確（ゴミ箱CRUD操作）
- ✅ @Observableで状態管理適切
- ✅ TrashDataStoreを介したactor分離
- ✅ 30日保管ロジック実装済み
- ✅ モック実装あり（テスタビリティ高）

**問題は統合にあり**:
- TrashManager自体の設計は正しい
- DeletePhotosUseCaseとの統合が不完全

### 改善提案

#### 即座の修正
1. **ContentView.swift Line 113-142**（onDeletePhotos）
   - `photoRepository.delete()` → `deletePhotosUseCase.execute()` に変更

2. **ContentView.swift Line 143-175**（onDeleteGroups）
   - 同様に`deletePhotosUseCase.execute()` を使用

#### 設計改善（将来）
```swift
// ViewレイヤーからUseCaseへの依存関係を明示
struct ContentView: View {
    private let deletePhotosUseCase: DeletePhotosUseCase // ✅ 明示的な依存

    var body: some View {
        DashboardNavigationContainer(
            onDeletePhotos: { photoIds in
                await deletePhotosUseCase.execute(
                    DeletePhotosInput(photos: photoAssets, permanently: false)
                )
            }
        )
    }
}
```

### スコアリング（84点）

| 項目 | スコア | 詳細 |
|------|--------|------|
| アーキテクチャ適合性 | 18/25点 | UseCase未使用で減点 |
| コード品質 | 20/25点 | 修正は簡単、既存コードは明確 |
| テスト容易性 | 23/25点 | TrashManagerのテストあり |
| 保守性 | 23/25点 | 明確な修正方針 |
| **合計** | **84点** | **条件付き実装継続** |

---

## 問題2: グループ一覧→ホーム遷移で画面固まり

### 症状
- **現象**: グループ一覧画面からホームに戻る際、画面が固まる（"s"という文字だけが表示される）
- **推測**: データ読み込み中にUIが応答しない

### 設計分析

#### 1. ナビゲーション設計（前回修正済み）

**前回の修正（セッション⑧、⑨）**:
- P0: NavigationPath.comparisonTypeMismatch修正済み（UUID化）
- P0: NavigationStack二重ネスト修正済み（GroupDetailView.swift Line 117-121）

**現在の状態**:
```swift
// GroupDetailView.swift Line 117-121
public var body: some View {
    // 注意: NavigationStackを削除
    // このビューはDashboardNavigationContainerのnavigationDestinationから
    // 表示されるため、独自のNavigationStackを持つと入れ子になりクラッシュする
    ZStack {
        backgroundGradient
        mainContent
    }
    .navigationTitle(group.displayName)
}
```

✅ **ナビゲーション設計は正しい**

#### 2. 状態管理の設計問題（"s"表示の原因）

**推測される原因**:
```swift
// HomeView.swift Line 84-93
public enum ViewState: Sendable, Equatable {
    case loading       // ← 読み込み中
    case loaded        // ← 読み込み完了
    case scanning(progress: Double) // ← スキャン中
    case error(String) // ← エラー
}
```

**"s"の正体**:
- `case scanning(progress: Double)` の "s"が表示されている可能性
- または、ViewStateの不適切な状態遷移

**設計問題**:
```swift
// HomeView.swift（推測）
// ナビゲーション復帰時に状態がリセットされない
.task {
    await loadStatistics() // ← 毎回実行される
}

// 戻る際のデータ再読み込みロジック欠如
```

#### 3. パフォーマンス設計の問題

**データ読み込みタイミング**:
- ✅ HomeView.task: 初回読み込み（正しい）
- ❌ ナビゲーション復帰時: データ再読み込み不要なのに実行される可能性
- ❌ キャッシュ戦略: PROGRESS.mdに記載がない

**ARCHITECTURE.md Line 665-668**:
```swift
### 9.3 キャッシング戦略
- 分析結果: NSCache + ディスクキャッシュ
- サムネイル: PHCachingImageManager
- 統計情報: UserDefaults  ← ★ 活用されていない可能性
```

### 改善提案

#### 即座の調査
1. **HomeView.swift**の`.task`修飾子を確認
   - ナビゲーション復帰時に不要なデータ読み込みが発生していないか
   - ViewStateの遷移ロジックを確認

2. **実機ログ確認**
   - セッションID: 37590cb8-7f87-4e87-a03b-b48dc5c4afbb
   - "s"が表示される直前のログを確認

#### 設計改善
```swift
// ✅ 改善案: ナビゲーション復帰時のキャッシュ活用
@MainActor
public struct HomeView: View {
    @State private var viewState: ViewState = .loading
    @State private var statistics: StorageStatistics?

    // ✅ キャッシュ有効期限を追加
    @State private var statisticsCacheExpiration: Date?

    var body: some View {
        // ...
    }
    .task {
        // キャッシュが有効ならスキップ
        if let expiration = statisticsCacheExpiration,
           Date() < expiration {
            return
        }
        await loadStatistics()
    }
}
```

### スコアリング（要調査）

| 項目 | スコア | 詳細 |
|------|--------|------|
| ナビゲーション設計 | 23/25点 | 前回修正で改善済み |
| 状態管理設計 | ?/25点 | 実機ログ確認が必要 |
| パフォーマンス設計 | 15/25点 | キャッシュ戦略未実装 |
| エラーハンドリング | 20/25点 | ViewState.errorあり |
| **合計** | **要調査** | **実機ログ分析後に評価** |

---

## 問題3: グループ詳細画面UX問題

### 症状
- **現象**: （具体的な症状が不明）
- **推測**: 削除後のフィードバックやインタラクション不足

### 設計分析

#### 1. UI状態管理の設計（GroupDetailView.swift）

**現在の実装**:
```swift
// GroupDetailView.swift Line 58-76
@State private var viewState: ViewState = .loading
@State private var photos: [Photo] = []
@State private var selectedPhotoIds: Set<String> = []
@State private var showDeleteConfirmation: Bool = false
@State private var showLimitReachedSheet: Bool = false
@State private var showErrorAlert: Bool = false
@State private var errorMessage: String = ""
```

✅ **状態管理は適切**:
- enum ViewStateで複雑な状態を統合管理
- 個別のBoolean状態は最小限（削除確認、エラー）

#### 2. ユーザーインタラクションフローの設計

**削除フロー**:
```
1. 写真選択（selectedPhotoIds）
2. 「削除」ボタンタップ
3. checkDeletionLimitAndShowConfirmation() ← プレミアム制限チェック
4. showDeleteConfirmation = true ← 確認ダイアログ
5. deleteSelectedPhotos() ← 実際の削除
6. 削除後のフィードバック ← ★ここが不足している可能性
```

**問題点**:
```swift
// GroupDetailView.swift Line 581-599
private func deleteSelectedPhotos() async {
    guard !selectedPhotoIds.isEmpty else { return }

    viewState = .processing  // ← ローディング表示

    do {
        let idsToDelete = Array(selectedPhotoIds)
        await onDeletePhotos?(idsToDelete)

        // 削除後、選択をクリア
        selectedPhotoIds.removeAll()

        // 写真リストから削除された写真を除外
        photos = photos.filter { !idsToDelete.contains($0.id) }

        viewState = .loaded  // ← 成功フィードバックがない
    }
    // ← エラーハンドリングがない
}
```

❌ **UX設計の問題**:
1. **成功フィードバックなし**: トースト通知がない
2. **エラーハンドリング欠如**: do-catchでcatchブロックがない
3. **削減容量の表示なし**: 「XX MB削減しました」がない

#### 3. 削除機能のUX設計

**ARCHITECTURE.md Line 582-586**:
```swift
### 7.2 エラー表示
- 非致命的エラー: トースト通知  ← ★ 削除成功時も同様に必要
- 致命的エラー: アラートダイアログ
- 権限エラー: 設定アプリへの誘導
```

**docs/UI_UX_GUIDE.md（推測）**:
```
【必須UI要素】
□ ローディング表示 ✅ viewState = .processing
□ エラー表示 ✅ showErrorAlert
□ 成功表示 ❌ 欠如
□ 空状態 ✅ emptyStateView
□ 確認ダイアログ ✅ showDeleteConfirmation
```

### 改善提案

#### 即座の修正
```swift
// ✅ 改善後のdeleteSelectedPhotos()
private func deleteSelectedPhotos() async {
    guard !selectedPhotoIds.isEmpty else { return }

    viewState = .processing

    do {
        let idsToDelete = Array(selectedPhotoIds)
        let deletedPhotos = photos.filter { idsToDelete.contains($0.id) }
        let totalSize = deletedPhotos.reduce(0) { $0 + $1.fileSize }

        await onDeletePhotos?(idsToDelete)

        // 削除後、選択をクリア
        selectedPhotoIds.removeAll()

        // 写真リストから削除された写真を除外
        photos = photos.filter { !idsToDelete.contains($0.id) }

        viewState = .loaded

        // ✅ 成功トースト表示
        let formattedSize = ByteCountFormatter.string(
            fromByteCount: totalSize,
            countStyle: .file
        )
        showSuccessToast(message: "\(idsToDelete.count)枚（\(formattedSize)）を削除しました")

    } catch {
        // ✅ エラーハンドリング追加
        viewState = .loaded
        errorMessage = error.localizedDescription
        showErrorAlert = true
    }
}
```

#### UI/UX設計改善
1. **成功トースト追加**
   ```swift
   @State private var showSuccessToast: Bool = false
   @State private var successMessage: String = ""
   ```

2. **削減容量の明示**
   - 削除確認ダイアログに容量表示（既にあり）
   - 成功トーストに容量表示（追加必要）

3. **アニメーション追加**
   ```swift
   photos = photos.filter { !idsToDelete.contains($0.id) }
       .withAnimation(.easeOut(duration: 0.3))
   ```

### スコアリング（72点）

| 項目 | スコア | 詳細 |
|------|--------|------|
| 状態管理設計 | 22/25点 | ViewState適切 |
| インタラクション設計 | 15/25点 | 成功フィードバック欠如 |
| エラーハンドリング | 12/25点 | catchブロックなし |
| アクセシビリティ | 23/25点 | VoiceOver対応あり |
| **合計** | **72点** | **設計改善が必要** |

---

## 総合評価

### 全体スコア

| 問題 | スコア | 判定 |
|------|--------|------|
| 問題1: ゴミ箱統合 | 84点 | 条件付き合格 |
| 問題2: ナビゲーション | 要調査 | 実機ログ分析必要 |
| 問題3: UX問題 | 72点 | 設計改善必要 |
| **平均** | **78点** | **条件付き実装継続** |

### 重要度別の優先度

| 優先度 | 問題 | 理由 |
|--------|------|------|
| **P0（緊急）** | 問題1: ゴミ箱統合 | データ損失リスク |
| **P1（高）** | 問題2: ナビゲーション | UX障害 |
| **P2（中）** | 問題3: UX改善 | 削除フィードバック |

---

## アーキテクチャ改善提案

### 1. MV Pattern準拠の徹底

**原則**:
```
Views (@State, @Environment) → Services (@Observable) → Frameworks
```

**違反箇所の修正**:
- ContentView.swift: DeletePhotosUseCaseを必ず使用
- HomeView.swift: キャッシュ戦略を実装

### 2. データフロー設計の明確化

**ゴミ箱フロー**:
```
View
 └─> DeletePhotosUseCase
     ├─> TrashManager.moveToTrash()   ← 30日保管
     └─> PhotoRepository.delete()      ← Photos.app非表示化
```

**統計情報フロー**:
```
View
 └─> GetStatisticsUseCase
     └─> PhotoRepository + キャッシュ
```

### 3. UX/UI設計原則の適用

**【必須UI要素】完全実装**:
- ✅ ローディング表示
- ✅ エラー表示
- ❌ 成功表示 ← 追加必要
- ✅ 空状態
- ✅ 確認ダイアログ

**【設計原則】**:
1. ✅ 1画面1目的
2. ✅ 3クリック以内で目的達成
3. ❌ エラーは具体的に、解決策も提示 ← 改善必要

---

## 推奨実装順序

### Phase 1: 緊急修正（P0）
1. **問題1: ゴミ箱統合修正**
   - ContentView.swift Line 113-142, 143-175の修正
   - 実機/シミュレーターでE2Eテスト
   - 目標: 90点以上

### Phase 2: 調査・修正（P1）
2. **問題2: ナビゲーション調査**
   - 実機ログ分析（セッションID: 37590cb8-7f87-4e87-a03b-b48dc5c4afbb）
   - HomeView.swiftのキャッシュ戦略実装
   - 目標: 85点以上

### Phase 3: UX改善（P2）
3. **問題3: UX改善**
   - GroupDetailView.swiftに成功トースト追加
   - deleteSelectedPhotos()にエラーハンドリング追加
   - 目標: 90点以上

---

## 次回セッション推奨プロンプト

```
@spec-developer

実機テスト問題の修正を開始してください。

【P0】ゴミ箱統合修正
- ファイル: ContentView.swift
- 箇所: Line 113-142（onDeletePhotos）、Line 143-175（onDeleteGroups）
- 修正: DeletePhotosUseCaseを使用してゴミ箱統合

【修正方針】
1. photoRepository.delete() の直接呼び出しを削除
2. deletePhotosUseCase.execute() を使用
3. E2Eテスト実施（シミュレーター + 実機）

【完了条件】
- ビルド成功
- E2Eテスト合格
- 品質スコア90点以上
```

---

*最終更新: 2025-12-22*
*レビュアー: @spec-architect*
*スコア: 78点（条件付き実装継続）*
