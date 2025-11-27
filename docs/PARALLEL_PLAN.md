# 並行開発計画書 (PARALLEL_PLAN.md)

**作成日**: 2025-11-28
**プロジェクト**: LightRoll Cleaner
**総タスク数**: 118タスク / 190時間

---

## 1. モジュール間依存関係マップ

### 1.1 依存関係グラフ

```
                          ┌─────────────────┐
                          │   M1: Core      │
                          │  Infrastructure │
                          │   (14h, 10T)    │
                          └────────┬────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   M2: Photo      │    │   M4: UI         │    │   M9: Monetiz.   │
│   Access         │    │   Components     │    │   (部分的)       │
│   (20.5h, 12T)   │    │   (17h, 14T)     │    │   (25.5h, 15T)   │
└────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘
         │                       │                       │
         ▼                       │                       │
┌──────────────────┐             │                       │
│   M3: Image      │             │                       │
│   Analysis       │             │                       │
│   (25.5h, 13T)   │             │                       │
└────────┬─────────┘             │                       │
         │                       │                       │
         └───────────┬───────────┘                       │
                     ▼                                   │
         ┌──────────────────┐                            │
         │   M5: Dashboard  │◄───────────────────────────┘
         │   (24h, 13T)     │
         └────────┬─────────┘
                  │
         ┌───────┴───────┐
         ▼               ▼
┌──────────────────┐  ┌──────────────────┐
│   M6: Deletion   │  │   M8: Settings   │
│   (25h, 14T)     │  │   (21h, 14T)     │
└────────┬─────────┘  └────────┬─────────┘
         │                     │
         └─────────┬───────────┘
                   ▼
         ┌──────────────────┐
         │   M7: Notific.   │
         │   (17.5h, 13T)   │
         └──────────────────┘
```

### 1.2 モジュール依存関係テーブル

| モジュール | 依存先 | 依存元 | 優先度 |
|-----------|--------|--------|--------|
| M1: Core Infrastructure | なし | 全モジュール | 最高 |
| M2: Photo Access | M1 | M3, M5, M6, M7 | 高 |
| M3: Image Analysis | M1, M2 | M5, M6 | 高 |
| M4: UI Components | M1 | M5, M6, M7, M8, M9 | 高 |
| M5: Dashboard | M1, M2, M3, M4 | - | 中 |
| M6: Deletion & Safety | M1, M2, M4 | M5, M9 | 中 |
| M7: Notifications | M1, M2, M6, M8 | - | 低 |
| M8: Settings | M1, M4, M2, M7 | M7, M5, M9 | 中 |
| M9: Monetization | M1, M4 | M5, M6, M8 | 低 |

---

## 2. タスク間依存関係分析

### 2.1 クリティカルパス

最長経路（クリティカルパス）:
```
M1-T01 → M1-T02 → M1-T03 → M1-T06 → M1-T07 → M2-T05 → M2-T06 → M2-T09
→ M3-T03 → M3-T04 → M3-T05 → M3-T06 → M3-T10 → M3-T11 → M3-T12
→ M5-T03 → M5-T05 → M5-T07 → M5-T12
```

**クリティカルパス所要時間**: 約45.5時間

### 2.2 並列実行可能なタスクグループ

#### Level 0（依存なし、即座に開始可能）
- M1-T01: Xcodeプロジェクト作成 (1h)

#### Level 1（M1-T01完了後）
並列実行可能:
- M1-T02: ディレクトリ構造整備 (0.5h)
- M2-T01: Info.plist権限設定 (0.5h)
- M4-T01: カラーパレット定義 (1h)
- M7-T02: Info.plist権限設定 (0.5h)
- M9-T03: StoreKit 2設定 (1h)
- M9-T08: Google Mobile Ads導入 (2h)

#### Level 2（M1-T02完了後）
並列実行可能:
- M1-T03: エラー型定義 (1h)
- M1-T04: ロガー実装 (1h)
- M1-T05: AppConfig実装 (1h)
- M1-T09: 拡張ユーティリティ (1.5h)

---

## 3. 並行実行計画（フェーズ別）

### Phase 1: 基盤構築 (予定: 16時間 → 並列化後: 8時間)

#### Session A: Core Infrastructure（リード）
```
担当タスク:
- M1-T01: Xcodeプロジェクト作成 (1h) [開始点]
- M1-T02: ディレクトリ構造整備 (0.5h)
- M1-T03: エラー型定義 (1h)
- M1-T06: DIコンテナ基盤 (2h)
- M1-T07: AppState実装 (2h)
- M1-T08: Protocol定義 (2h)
合計: 8.5h
```

#### Session B: UI基盤 + 権限設定
```
担当タスク:
- M4-T01: カラーパレット定義 (1h) [M1-T01完了後開始]
- M4-T02: タイポグラフィ定義 (0.5h)
- M4-T03: グラスモーフィズム実装 (1.5h)
- M4-T04: Spacing定義 (0.5h)
- M2-T01: Info.plist権限設定 (0.5h) [M1-T01完了後]
- M7-T02: Info.plist権限設定 (0.5h) [M1-T01完了後]
- M1-T04: ロガー実装 (1h) [M1-T02完了後]
- M1-T05: AppConfig実装 (1h) [M1-T02完了後]
- M1-T09: 拡張ユーティリティ (1.5h) [M1-T02完了後]
合計: 8h
```

**Phase 1 マイルストーン:**
- Xcodeプロジェクトがビルド可能
- デザインシステム基盤が完成
- 全Protocolが定義済み
- DIContainerが動作

---

### Phase 2: データ層 (予定: 46時間 → 並列化後: 20時間)

#### Session A: Photo Access
```
担当タスク:
- M2-T02: PhotoPermissionManager実装 (2h)
- M2-T03: Photoモデル実装 (1h)
- M2-T04: PHAsset拡張 (1.5h)
- M2-T05: PhotoRepository基盤 (2h)
- M2-T06: 写真一覧取得 (2h)
- M2-T07: サムネイル取得 (2h)
- M2-T08: ストレージ情報取得 (1.5h)
- M2-T09: PhotoScanner実装 (2.5h)
- M2-T11: ThumbnailCache実装 (1.5h)
合計: 16h
```

#### Session B: Image Analysis（Session Aのマイルストーン後開始）
```
担当タスク:
- M3-T01: PhotoAnalysisResultモデル (1h) [M1-T08完了後]
- M3-T02: PhotoGroupモデル (1h)
- M3-T03: VisionRequestHandler (2h) [M2-T05完了後待機]
- M3-T04: 特徴量抽出 (2.5h)
- M3-T05: 類似度計算 (2h)
- M3-T06: SimilarityAnalyzer実装 (2.5h)
- M3-T07: 顔検出実装 (2h)
- M3-T08: ブレ検出実装 (2h)
- M3-T09: スクリーンショット検出 (1.5h)
合計: 16.5h
```

#### Session C: UI Components
```
担当タスク:
- M4-T05: PhotoThumbnail実装 (2h) [M4-T03完了後]
- M4-T06: PhotoGrid実装 (2h)
- M4-T07: StorageIndicator実装 (1.5h)
- M4-T08: GroupCard実装 (1.5h)
- M4-T09: ActionButton実装 (1h)
- M4-T10: ProgressOverlay実装 (1.5h)
- M4-T11: ConfirmationDialog実装 (1h)
- M4-T12: EmptyStateView実装 (1h)
- M4-T13: ToastView実装 (1h)
- M4-T14: プレビュー環境整備 (1h)
合計: 13.5h
```

#### Session D: Monetization基盤
```
担当タスク:
- M9-T01: PremiumStatusモデル (1h) [M1-T08完了後]
- M9-T02: ProductInfoモデル (0.5h)
- M9-T04: PurchaseRepository実装 (3h) [M9-T03完了後]
- M9-T05: PremiumManager実装 (2.5h)
- M9-T06: FeatureGate実装 (1.5h)
- M9-T07: 削除上限管理 (1.5h)
- M9-T09: AdManager実装 (2h) [M9-T08完了後]
合計: 12h
```

**Phase 2 マイルストーン:**
- 写真スキャン機能が動作
- 画像分析パイプラインが完成
- 全UIコンポーネントがプレビュー可能
- 課金基盤が準備完了

---

### Phase 3: 機能統合 (予定: 74時間 → 並列化後: 28時間)

#### Session A: Dashboard統合
```
担当タスク:
- M3-T10: PhotoGrouper実装 (2.5h) [M3-T06,T07,T08,T09完了後]
- M3-T11: BestShotSelector実装 (2h)
- M3-T12: AnalysisRepository統合 (2h)
- M5-T01: CleanupRecordモデル (0.5h)
- M5-T02: StorageStatisticsモデル (0.5h)
- M5-T03: ScanPhotosUseCase実装 (2.5h)
- M5-T04: GetStatisticsUseCase実装 (1.5h)
- M5-T05: HomeViewModel実装 (2h)
- M5-T06: StorageOverviewCard実装 (2h)
- M5-T07: HomeView実装 (2.5h)
合計: 18h
```

#### Session B: Deletion機能
```
担当タスク:
- M6-T01: TrashPhotoモデル (1h) [M1-T08完了後]
- M6-T02: TrashDataStore実装 (2h)
- M6-T03: TrashManager基盤 (2h)
- M6-T04: moveToTrash実装 (2h)
- M6-T05: restoreFromTrash実装 (2h)
- M6-T06: 自動クリーンアップ (1.5h)
- M6-T07: DeletePhotosUseCase実装 (2h)
- M6-T08: RestorePhotosUseCase実装 (1.5h)
- M6-T09: DeletionConfirmationService (1h)
- M6-T13: PHAsset削除連携 (2h)
合計: 17h
```

#### Session C: Settings機能
```
担当タスク:
- M8-T01: UserSettingsモデル (1.5h) [M1-T08完了後]
- M8-T02: SettingsRepository実装 (1.5h)
- M8-T04: SettingsViewModel実装 (2h)
- M8-T06: SettingsRow/Toggle実装 (1.5h)
- M8-T07: SettingsView実装 (2.5h)
- M8-T08: ScanSettingsView実装 (1.5h)
- M8-T09: AnalysisSettingsView実装 (1h)
- M8-T11: DisplaySettingsView実装 (1h)
- M8-T13: AboutView実装 (1h)
合計: 13.5h
```

#### Session D: 課金UI + 広告
```
担当タスク:
- M9-T10: BannerAdView実装 (1.5h)
- M9-T11: PremiumViewModel実装 (2h)
- M9-T12: PremiumView実装 (2.5h)
- M9-T13: LimitReachedSheet実装 (1h)
- M9-T14: 購入復元実装 (1.5h)
合計: 8.5h
```

**Phase 3 マイルストーン:**
- HomeView完全動作
- 削除・ゴミ箱機能が動作
- Settings画面が完成
- 課金UIが完成

---

### Phase 4: 画面完成 (予定: 34時間 → 並列化後: 15時間)

#### Session A: List/Detail View
```
担当タスク:
- M5-T08: GroupListViewModel実装 (2h)
- M5-T09: GroupListView実装 (2.5h)
- M5-T10: GroupDetailViewModel実装 (2h)
- M5-T11: GroupDetailView実装 (2.5h)
- M5-T12: Navigation設定 (1.5h)
合計: 10.5h
```

#### Session B: Trash/Permissions View
```
担当タスク:
- M6-T10: TrashViewModel実装 (2h)
- M6-T11: TrashView実装 (2.5h)
- M6-T12: DeletionConfirmationSheet (1.5h)
- M8-T03: PermissionManager実装 (2h)
- M8-T05: PermissionsViewModel (1h)
- M8-T12: PermissionsView実装 (1.5h)
合計: 10.5h
```

#### Session C: Notification設定
```
担当タスク:
- M7-T01: NotificationSettingsモデル (1h)
- M7-T03: NotificationManager基盤 (2h)
- M7-T04: 権限リクエスト実装 (1h)
- M7-T05: NotificationContentBuilder (1.5h)
- M8-T10: NotificationSettingsView (1.5h)
合計: 7h
```

**Phase 4 マイルストーン:**
- 全画面が完成
- Navigation完全動作
- 権限フローが完成

---

### Phase 5: 仕上げ (予定: 20時間 → 並列化後: 10時間)

#### Session A: 通知機能完成
```
担当タスク:
- M7-T06: 空き容量警告通知 (2h)
- M7-T07: StorageMonitor実装 (2h)
- M7-T08: 定期リマインド実装 (1.5h)
- M7-T09: スキャン完了通知 (1h)
- M7-T10: ゴミ箱期限警告 (1h)
- M7-T11: NotificationDelegate実装 (1.5h)
- M7-T12: 設定画面連携 (1h)
合計: 10h
```

#### Session B: バックグラウンド処理
```
担当タスク:
- M2-T10: バックグラウンドスキャン (2h)
合計: 2h
```

**Phase 5 マイルストーン:**
- 通知機能が完全動作
- バックグラウンド処理が動作

---

### Phase 6: テスト (予定: 20時間 → 並列化後: 8時間)

#### Session A: Core/Photo/Analysisテスト
```
担当タスク:
- M1-T10: 単体テスト作成 (2h)
- M2-T12: 単体テスト作成 (2h)
- M3-T13: 単体テスト作成 (2.5h)
合計: 6.5h
```

#### Session B: UI/Dashboardテスト
```
担当タスク:
- M5-T13: 単体テスト作成 (2h)
- M6-T14: 単体テスト作成 (2h)
合計: 4h
```

#### Session C: Settings/Notification/Monetizationテスト
```
担当タスク:
- M7-T13: 単体テスト作成 (1.5h)
- M8-T14: 単体テスト作成 (1.5h)
- M9-T15: 単体テスト作成 (2h)
合計: 5h
```

---

## 4. 時間短縮率の計算

### 4.1 直列実行時間
```
全タスク合計: 190時間
```

### 4.2 並列実行時間（推定）
```
Phase 1:  8時間 (最長パス)
Phase 2: 20時間 (最長パス: Session A)
Phase 3: 28時間 (最長パス: Session A)
Phase 4: 15時間 (最長パス: Session A/B)
Phase 5: 10時間 (最長パス: Session A)
Phase 6:  8時間 (最長パス: Session A)
----------------------------
合計:    89時間
```

### 4.3 短縮率
```
短縮率 = (190 - 89) / 190 = 53.2%

直列実行: 190時間 (約24日 @8h/日)
並列実行:  89時間 (約11日 @8h/日)
短縮:     101時間 (約13日)
```

### 4.4 効果的な並列度
```
推奨並列セッション数: 3-4セッション
理由:
- 依存関係の待ち時間を最小化
- コンフリクト発生率を抑制
- レビュー・統合の負荷分散
```

---

## 5. Git Flow設計

### 5.1 ブランチ戦略

```
main
  │
  ├── develop (統合ブランチ)
  │     │
  │     ├── feature/m1-core-infrastructure
  │     │     ├── feature/m1-t01-xcode-project
  │     │     ├── feature/m1-t02-directory-structure
  │     │     ├── feature/m1-t03-error-types
  │     │     └── ...
  │     │
  │     ├── feature/m2-photo-access
  │     │     ├── feature/m2-t01-info-plist
  │     │     ├── feature/m2-t02-permission-manager
  │     │     └── ...
  │     │
  │     ├── feature/m3-image-analysis
  │     ├── feature/m4-ui-components
  │     ├── feature/m5-dashboard
  │     ├── feature/m6-deletion
  │     ├── feature/m7-notifications
  │     ├── feature/m8-settings
  │     └── feature/m9-monetization
  │
  └── release/v1.0.0
```

### 5.2 ブランチ命名規則

| パターン | 用途 | 例 |
|---------|------|-----|
| `feature/m{N}-{module-name}` | モジュール親ブランチ | `feature/m1-core-infrastructure` |
| `feature/m{N}-t{NN}-{task-name}` | タスク作業ブランチ | `feature/m1-t01-xcode-project` |
| `fix/m{N}-{description}` | バグ修正 | `fix/m2-permission-crash` |
| `refactor/m{N}-{description}` | リファクタリング | `refactor/m4-color-system` |

### 5.3 マージ順序

```
Phase 1:
1. feature/m1-t01-xcode-project → feature/m1-core-infrastructure
2. feature/m4-t01-colors → feature/m4-ui-components
3. feature/m1-core-infrastructure → develop
4. feature/m4-ui-components → develop (Phase 1完了後)

Phase 2:
1. 各タスクブランチ → モジュールブランチ
2. feature/m2-photo-access → develop
3. feature/m3-image-analysis → develop (M2完了後)
...

Phase完了時:
- developからmainへマージ（リリース準備）
```

### 5.4 PRルール

| 項目 | ルール |
|------|--------|
| タイトル | `[M{N}-T{NN}] {タスク名}` |
| レビュアー | 自動割り当て（並行セッション担当者以外） |
| マージ条件 | ビルド成功 + テストパス + 1承認 |
| Squash | タスクブランチ→モジュールブランチはSquash |
| Merge | モジュールブランチ→developはMerge commit |

---

## 6. セッション別指示書

### Session A: Core Infrastructure Lead

**担当者**: Lead Developer
**担当モジュール**: M1 (Primary), M2/M3/M5/M6 (Integration)

#### Phase 1 指示
```markdown
## 作業内容
1. Xcodeプロジェクト作成（iOS 16+, SwiftUI）
2. ディレクトリ構造の整備
3. エラー型定義（LightRollError）
4. DIコンテナ基盤の実装
5. AppState実装
6. Repository/UseCase Protocol定義

## 依存関係
- なし（最初のセッション）

## 完了条件
- Xcodeプロジェクトがビルド成功
- 全Protocolがコンパイル可能
- AppStateの基本テストがパス

## 注意点
- iOS Deployment Target: 16.0
- Swift 5.9+
- @MainActor の適切な使用
- Protocol定義は他セッションと共有するため、インターフェースを先行確定

## ブランチ
- Base: `develop`
- Working: `feature/m1-core-infrastructure`
```

#### Phase 2 指示
```markdown
## 作業内容
1. PhotoPermissionManager実装
2. Photoモデル、PHAsset拡張
3. PhotoRepository基盤～PhotoScanner

## 依存関係
- M1-T08 (Protocol定義) 完了必須

## 完了条件
- 写真ライブラリへのアクセスが動作
- 写真一覧取得、サムネイル取得が動作
- PhotoScannerのプログレス通知が動作

## ブランチ
- Base: `develop`
- Working: `feature/m2-photo-access`
```

---

### Session B: UI Components

**担当者**: UI Developer
**担当モジュール**: M4 (Primary), M1補助

#### Phase 1 指示
```markdown
## 作業内容
1. カラーパレット定義（Assets.xcassets + Color拡張）
2. タイポグラフィ定義
3. グラスモーフィズムViewModifier
4. Spacing定義
5. M1-T04 ロガー実装（M1-T02完了後）
6. M1-T05 AppConfig実装
7. M1-T09 拡張ユーティリティ

## 依存関係
- M1-T01 完了後に開始可能
- M1-T02 完了後にM1補助タスク開始

## 完了条件
- デザインシステムがプレビュー可能
- グラスモーフィズムが正しく表示
- ダークモード対応

## ブランチ
- Base: `develop`
- Working: `feature/m4-ui-components`

## 注意点
- カラー定義は `docs/modules/MODULE_M4_UI_COMPONENTS.md` 参照
- プレビュー環境を常に動作状態に保つ
```

#### Phase 2 指示
```markdown
## 作業内容
1. PhotoThumbnail実装
2. PhotoGrid実装
3. StorageIndicator実装
4. GroupCard実装
5. ActionButton実装
6. ProgressOverlay実装
7. ConfirmationDialog実装
8. EmptyStateView実装
9. ToastView実装
10. プレビュー環境整備

## 依存関係
- M4-T03 (グラスモーフィズム) 完了必須

## 完了条件
- 全コンポーネントがSwiftUI Previewsで確認可能
- アクセシビリティ対応済み
- iPhone SE〜iPhone 15 Pro Maxでレイアウト確認

## ブランチ
- Working: `feature/m4-ui-components`
```

---

### Session C: Image Analysis

**担当者**: ML/Vision Developer
**担当モジュール**: M3 (Primary)

#### Phase 2 指示
```markdown
## 作業内容
1. PhotoAnalysisResult/PhotoGroupモデル
2. VisionRequestHandler
3. 特徴量抽出（VNFeaturePrintObservation）
4. 類似度計算（コサイン類似度）
5. SimilarityAnalyzer実装
6. 顔検出実装
7. ブレ検出実装
8. スクリーンショット検出

## 依存関係
- M1-T08 (Protocol定義) 完了必須
- M2-T05 (PhotoRepository基盤) 完了後にVisionRequestHandler開始

## 完了条件
- 特徴量抽出が動作
- 類似度計算が閾値0.85で正しく判定
- 顔検出、ブレ検出が動作
- スクリーンショット判定が100%正確

## 注意点
- Vision APIはiOS 16以上必須
- TaskGroupでの並列処理を活用
- メモリ使用量に注意（autoreleasepoolを活用）

## ブランチ
- Base: `develop`
- Working: `feature/m3-image-analysis`
```

---

### Session D: Monetization

**担当者**: Backend/Monetization Developer
**担当モジュール**: M9 (Primary)

#### Phase 1-2 指示
```markdown
## 作業内容
1. StoreKit 2設定（App Store Connect）
2. Google Mobile Ads SDK導入
3. PremiumStatus/ProductInfoモデル
4. PurchaseRepository実装
5. PremiumManager実装
6. FeatureGate実装
7. 削除上限管理
8. AdManager実装

## 依存関係
- M1-T01 完了後にStoreKit 2設定開始
- M1-T08 完了後にモデル実装開始

## 完了条件
- StoreKit Configuration Fileでテスト購入が動作
- Free版の50枚/日制限が機能
- テスト広告が表示

## 注意点
- StoreKit 2を使用（StoreKit 1は使用しない）
- AdMobテストユニットIDを使用
- レシート検証はオンデバイス検証で実装

## ブランチ
- Base: `develop`
- Working: `feature/m9-monetization`
```

---

## 7. 統合・マージ計画

### 7.1 統合ポイント

| フェーズ | 統合内容 | 担当 | チェック項目 |
|---------|---------|------|-------------|
| Phase 1完了 | M1 + M4基盤 | Lead | ビルド成功、Protocol整合性 |
| Phase 2完了 | M2 + M3 + M4 + M9基盤 | Lead | 写真スキャン動作、UIプレビュー |
| Phase 3完了 | M5 + M6 + M8 + M9 | Lead | HomeView動作、削除機能動作 |
| Phase 4完了 | 全画面統合 | Lead | Navigation完全動作 |
| Phase 5完了 | M7 + バックグラウンド | Lead | 通知動作確認 |
| Phase 6完了 | 全テスト | Lead | カバレッジ80%以上 |

### 7.2 コンフリクト予防

| ファイル/領域 | 担当 | 排他制御 |
|--------------|------|---------|
| `LightRollCleanerApp.swift` | Session A | 明示的ロック |
| `DIContainer.swift` | Session A | 他セッションは追加のみ |
| `Assets.xcassets` | Session B | 名前空間で分離 |
| `Info.plist` | Session A | マージ時に確認 |

---

## 8. リスクと対策

### 8.1 技術的リスク

| リスク | 確率 | 影響 | 対策 |
|-------|------|------|------|
| Vision API制限 | 中 | 高 | iOS 16以上に限定、フォールバック用意 |
| StoreKit 2統合 | 中 | 中 | Sandbox環境で十分なテスト |
| メモリ不足 | 低 | 高 | バッチ処理、autoreleasepoolを徹底 |
| Photos Framework制限 | 低 | 中 | ユーザー確認必須の動作を文書化 |

### 8.2 プロジェクトリスク

| リスク | 確率 | 影響 | 対策 |
|-------|------|------|------|
| 並列作業のコンフリクト | 中 | 中 | 明確なファイル担当分け、頻繁なマージ |
| 依存関係の遅延 | 中 | 高 | クリティカルパスの優先実行 |
| Protocol変更 | 低 | 高 | Phase 1でProtocol確定、変更時は全員に通知 |

---

## 9. 進捗追跡

### 9.1 日次スタンドアップ項目
- 昨日の完了タスク
- 今日の予定タスク
- ブロッカー/依存待ち
- マージ予定

### 9.2 Phase完了チェックリスト

```markdown
## Phase 1 完了チェック
- [ ] M1-T01〜T08 完了
- [ ] M4-T01〜T04 完了
- [ ] Xcodeビルド成功
- [ ] develop へマージ完了
- [ ] 全セッションがdevelopを同期

## Phase 2 完了チェック
- [ ] M2-T01〜T11 完了
- [ ] M3-T01〜T09 完了
- [ ] M4-T05〜T14 完了
- [ ] M9-T01〜T09 完了
- [ ] 写真スキャン動作確認
- [ ] develop へマージ完了
```

---

*最終更新: 2025-11-28*
*作成者: spec-team-manager*
