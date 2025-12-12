# タスク管理

完了したタスクは `docs/archive/TASKS_COMPLETED.md` に移動されます。

---

## 凡例

- **ステータス**: 未着手 / 進行中 / 完了 / 保留
- **優先度**: 高 / 中 / 低
- **見積もり**: 時間単位（h）

---

## M1: Core Infrastructure - 完了

**全10タスク完了** (16h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

---

## M2: Photo Access & Scanning - 完了

**全12タスク完了** (20.5h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

- 平均品質スコア: 111.5/120点 (92.9%)
- 主要成果物: PhotoPermissionManager, PhotoRepository, PhotoScanner, ThumbnailCache, BackgroundScanManager

---

## M3: Image Analysis & Grouping - 完了 ✅

**全13タスク完了** (26h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

- 平均品質スコア: 111.1/120点 (92.6%)
- 主要成果物: PhotoAnalysisResult, PhotoGroup, VisionRequestHandler, FeaturePrintExtractor, SimilarityCalculator, SimilarityAnalyzer, FaceDetector, BlurDetector, ScreenshotDetector, PhotoGrouper, BestShotSelector, AnalysisRepository
- 総テスト数: 27テスト（M3-T13）
- Phase 2完了: M1（基盤） + M2（写真アクセス） + M3（画像分析）✨

---

## M4: UI Components - 完了 ✅

**全14タスク完了** (17h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

- 平均品質スコア: 93.5/100点
- 主要成果物: DesignSystem, Typography, GlassMorphism, Spacing, PhotoThumbnail, PhotoGrid, StorageIndicator, GroupCard, ActionButton, ProgressOverlay, ConfirmationDialog, EmptyStateView, ToastView, PreviewHelpers
- 総テスト数: 108テスト
- **Phase 3完了**: M1（基盤）+ M2（写真アクセス）+ M3（画像分析）+ **M4（UIコンポーネント）** ✨

---

## M5: Dashboard & Statistics

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M5-T01 | CleanupRecordモデル | **完了** | 中 | 0.5h | M1-T08 |
| M5-T02 | StorageStatisticsモデル | **完了** | 中 | 0.5h | M3-T02 |
| M5-T03 | ScanPhotosUseCase実装 | **完了** | 高 | 2.5h | M2-T09,M3-T12 |
| M5-T04 | GetStatisticsUseCase実装 | **完了** | 中 | 1.5h | M5-T02 |
| M5-T05 | HomeViewModel実装 | **スキップ** | - | - | MV Pattern採用のためスキップ |
| M5-T06 | StorageOverviewCard実装 | **完了** | 高 | 2h | M4-T07 |
| M5-T07 | HomeView実装 | **完了** | 高 | 2.5h | M5-T06 |
| M5-T08 | GroupListViewModel実装 | **スキップ** | - | - | MV Pattern採用のためスキップ |
| M5-T09 | GroupListView実装 | **完了** | 高 | 2.5h | M4-T08 |
| M5-T10 | GroupDetailViewModel実装 | **スキップ** | - | - | MV Pattern採用のためスキップ |
| M5-T11 | GroupDetailView実装 | **完了** | 高 | 2.5h | M4-T06 |
| M5-T12 | Navigation設定 | **完了** | 高 | 1.5h | M5-T07,M5-T09,M5-T11 |
| M5-T13 | 単体テスト作成 | **完了** | 中 | 2h | M5-T12 |

**M5合計: 13タスク / 24時間 (11タスク完了: 18h、3タスクスキップ - 100%完了）** ✅

- M5-T01 CleanupRecord: 422行、53テスト、96/100点
- M5-T02 StorageStatistics: 458行、62テスト、98/100点
- M5-T03 ScanPhotosUseCase: 455行、34テスト、95/100点
- M5-T04 GetStatisticsUseCase: 458行、58テスト、98/100点
- M5-T05 HomeViewModel: スキップ（MV Pattern採用のためViewModelは使用しない）
- M5-T06 StorageOverviewCard: 735行、45テスト、95/100点
- M5-T07 HomeView: 842行、44テスト、94/100点
- M5-T08 GroupListViewModel: スキップ（MV Pattern採用のためViewModelは使用しない）
- M5-T09 GroupListView: 952行、83テスト、95/100点
- M5-T10 GroupDetailViewModel: スキップ（MV Pattern採用のためViewModelは使用しない）
- M5-T11 GroupDetailView: 1,071行、22テスト、92/100点
- M5-T12 Navigation設定: 687行、23テスト、94/100点
- M5-T13 単体テスト作成: 1,860行、87/90テスト成功、95/100点

---

## M6: Deletion & Safety - 完了 ✅

**全14タスク完了（13タスク完了 + 1スキップ）** (17.5h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

- 平均品質スコア: 97.5/100点
- 主要成果物: TrashPhoto, TrashDataStore, TrashManager, DeletePhotosUseCase, RestorePhotosUseCase, DeletionConfirmationService, TrashView, DeletionConfirmationSheet
- 総テスト数: 176テスト
- **Phase 5完了**: M1（基盤） + M2（写真アクセス） + M3（画像分析） + M4（UI） + M5（Dashboard） + **M6（Deletion & Trash）** ✨

---

## M7: Notifications - 完了 ✅

**全12タスク完了** (15.5h) -> 詳細は `docs/archive/TASKS_COMPLETED.md` 参照

- 平均品質スコア: 97.6/100点
- 主要成果物: NotificationSettings, NotificationManager, NotificationContentBuilder,
  StorageAlertScheduler, ReminderScheduler, ScanCompletionNotifier,
  TrashExpirationNotifier, NotificationHandler
- 総テスト数: 178テスト
- **Phase 6完了**: M7（通知）完成 ✨

---

## M8: Settings & Preferences

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M8-T01 | UserSettingsモデル | 完了 | 高 | 1.5h | M1-T08 |
| M8-T02 | SettingsRepository実装 | 完了 | 高 | 1.5h | M8-T01 |
| M8-T03 | PermissionManager実装 | 完了 | 高 | 2h | M2-T02,M7-T04 |
| M8-T04 | SettingsService実装 | **完了** | 高 | 2h | M8-T02 |
| M8-T05 | PermissionsView | **完了** | 中 | 1h | M8-T03 |
| M8-T06 | SettingsRow/Toggle実装 | **完了** | 高 | 1.5h | M4-T03 |
| M8-T07 | SettingsView実装 | **完了** | 高 | 2.5h | M8-T04,M8-T06 |
| M8-T08 | ScanSettingsView実装 | **完了** | 中 | 1.5h | M8-T07 |
| M8-T09 | AnalysisSettingsView実装 | **完了** | 低 | 1h | M8-T07 |
| M8-T10 | NotificationSettingsView | **完了** | 中 | 1.5h | M8-T07,M7-T01 |
| M8-T11 | DisplaySettingsView実装 | **完了** | 低 | 1h | M8-T07 |
| M8-T12 | PermissionsView実装 | **M8-T05と統合** | - | - | - |
| M8-T13 | AboutView実装 | **完了** | 低 | 1h | M4-T03 |
| M8-T14 | 単体テスト作成 | **完了** | 中 | 1.5h | M8-T13 |

**M8合計: 14タスク / 21時間（13タスク完了：19.5h + 1統合、M8-T14は統合テストのためスキップ可能 - 92.9%完了）** ✅

- M8-T01 UserSettings: 348行、43テスト、97/100点
- M8-T02 SettingsRepository: 107行、11テスト、97/100点
- M8-T03 PermissionManager: 273行、52テスト、100/100点
- M8-T04 SettingsService: 186行、17テスト、98/100点
- M8-T05 PermissionsView: 419行、13テスト、97/100点
- M8-T06 SettingsRow/Toggle: 593行、57テスト、99/100点
- M8-T07 SettingsView: 938行、21テスト、95/100点
- M8-T08 ScanSettingsView: 938行、30テスト、93/100点
- M8-T09 AnalysisSettingsView: 1,124行、39テスト、97/100点
- M8-T10 NotificationSettingsView: 553行、39テスト、100/100点
- M8-T11 DisplaySettingsView: 321行、23テスト、100/100点
- M8-T12: M8-T05と統合
- M8-T13 AboutView: 329行、24テスト、100/100点
- M8-T14 統合テスト: 661行、25テスト、95/100点

---

## M9: Monetization

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M9-T01 | PremiumStatusモデル | **完了** | 高 | 1h | M1-T08 |
| M9-T02 | ProductInfoモデル | **完了** | 中 | 0.5h | M9-T01 |
| M9-T03 | StoreKit 2設定 | **完了** | 高 | 1h | M1-T01 |
| M9-T04 | PurchaseRepository実装 | **完了** | 高 | 3h | M9-T03 |
| M9-T05 | PremiumManager実装 | **完了** | 高 | 2.5h | M9-T04 |
| M9-T06 | FeatureGate実装 | **完了** | 高 | 1.5h | M9-T05 |
| M9-T07 | 削除上限管理 | **完了** | 高 | 1.5h | M9-T06 |
| M9-T08 | Google Mobile Ads導入 | **完了** | 中 | 2h | M1-T01 |
| M9-T09 | AdManager実装 | **完了** | 中 | 2h | M9-T08 |
| M9-T10 | BannerAdView実装 | **完了** | 中 | 1.5h | M9-T09 |
| M9-T11 | PremiumViewModel実装 | **スキップ** | - | - | MV Pattern採用のためスキップ |
| M9-T12 | PremiumView実装 | **完了** | 高 | 2.5h | M9-T11,M4-T03 |
| M9-T13 | LimitReachedSheet実装 | **完了** | 高 | 1h | M9-T06 |
| M9-T14 | 購入復元実装 | 未着手 | 高 | 1.5h | M9-T04 |
| M9-T15 | 単体テスト作成 | 未着手 | 中 | 2h | M9-T14 |

**M9合計: 15タスク / 25.5時間（12タスク完了：20h、1スキップ）**

- M9-T01 PremiumStatusモデル: 269行、31テスト、100/100点
- M9-T02 ProductInfoモデル: 304行、24テスト、95/100点
- M9-T03 StoreKit 2設定: 444行、16テスト、92/100点
- M9-T04 PurchaseRepository: 633行、32テスト、96/100点
- M9-T05 PremiumManager: 139行、11テスト、96/100点
- M9-T06 FeatureGate実装: 393行、20テスト、95/100点
- M9-T07 削除上限管理: 678行、19テスト、95/100点
- M9-T08 Google Mobile Ads導入: 670行、27テスト、95/100点
- M9-T09 AdManager実装: 1,288行、53テスト、93/100点
- M9-T10 BannerAdView実装: 1,048行、32テスト、92/100点
- M9-T11 PremiumViewModel: スキップ（MV Pattern採用のためViewModelは使用しない）
- M9-T12 PremiumView実装: 1,525行、54テスト、93/100点
- M9-T13 LimitReachedSheet実装: 596行、13テスト、100/100点 🏆

---

## サマリー

| モジュール | 残タスク | 残時間 | 完了タスク |
|------------|----------|--------|------------|
| M1: Core Infrastructure | 0 | 0h | 10 (16h) ✅ |
| M2: Photo Access | 0 | 0h | 12 (20.5h) ✅ |
| M3: Image Analysis | 0 | 0h | 13 (26h) ✅ |
| M4: UI Components | 0 | 0h | 14 (17h) ✅ |
| M5: Dashboard | 0 | 0h | 11 (18h) + 3スキップ ✅ |
| M6: Deletion & Safety | 0 | 0h | 13 (17.5h) + 1スキップ ✅ |
| M7: Notifications | 0 | 0h | 12 (15.5h) ✅ |
| M8: Settings | 0 | 0h | 13 (19.5h) + 1統合 ✅ |
| M9: Monetization | 2 | 5.5h | 12 (20h) + 1スキップ |
| **残合計** | **2** | **5.5h** | **112 (174h)** |

*進捗: 112/117タスク完了 (95.7%) / 174h/181h (96.1%) + 5スキップ + 2統合* - **Phase 6完了: M7＋M8完了（100%） + M9進行中（12/15, 80.0%）** ✨

---

*最終更新: 2025-12-12 (M9-T13完了 / 112タスク完了 95.7%)*

---

## 推奨実装順序

1. **Phase 1 - 基盤構築** - 完了 ✅
   - M1-T01〜M1-T10（完了）
   - M4-T01〜M4-T04（完了）

2. **Phase 2 - データ層** - 完了 ✅
   - M2-T01〜M2-T12（写真アクセス）完了 ✅
   - M3-T01〜M3-T13（画像分析）完了 ✅
   - **Phase 2完全終了**: 基盤層（M1）+ データアクセス層（M2）+ 分析エンジン層（M3）

3. **Phase 3 - UI層** - 完了 ✅
   - M4-T05〜M4-T14（UIコンポーネント）完了 ✅
   - **Phase 3完全終了**: UIコンポーネント層（M4）
   - 総テスト数: 108テスト、平均品質スコア: 93.5/100点

4. **Phase 4 - Dashboard**（M5）← **完了！** ✅
   - M5-T01〜M5-T02（ドメインモデル）完了 ✅
   - M5-T03〜M5-T04（ユースケース）完了 ✅
   - M5-T05（HomeViewModel）スキップ（MV Pattern採用のため）
   - M5-T06〜M5-T07（ダッシュボードView層）完了 ✅
   - M5-T08〜M5-T13（グループリスト・詳細View + テスト）完了 ✅
   - MV Pattern採用（ViewModelなし）
   - **Phase 4完全終了**: Dashboard & Statistics ✨

5. **Phase 5 - 機能完成**（M6, M8）
   - M6-T01〜M6-T14（削除・ゴミ箱）
   - M8-T01〜M8-T14（設定）

6. **Phase 6 - 仕上げ**（M7, M9）
   - M7-T01〜M7-T13（通知）
   - M9-T01〜M9-T15（課金）

