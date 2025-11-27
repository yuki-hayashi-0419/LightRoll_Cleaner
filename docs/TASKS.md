# タスク管理

完了したタスクは `docs/archive/TASKS_COMPLETED.md` に移動されます。

---

## 凡例

- **ステータス**: 未着手 / 進行中 / 完了 / 保留
- **優先度**: 高 / 中 / 低
- **見積もり**: 時間単位（h）

---

## M1: Core Infrastructure ✅ 完了

**M1モジュール完了**: 全10タスク / 16時間 -> アーカイブ済

| タスクID | タスク名 | スコア | 備考 |
|----------|----------|--------|------|
| M1-T04 | ロガー実装 | 116点 | Logger.swift, 41テスト |
| M1-T09 | 拡張ユーティリティ | 113点 | 7拡張ファイル, 73テスト |
| M1-T10 | 単体テスト作成 | 112点 | ConfigTests, ErrorTests, 92テスト追加 |

---

## M2: Photo Access & Scanning

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M2-T01 | Info.plist権限設定 | 未着手 | 高 | 0.5h | M1-T01 |
| M2-T02 | PhotoPermissionManager実装 | 未着手 | 高 | 2h | M2-T01 |
| M2-T03 | Photoモデル実装 | 未着手 | 高 | 1h | M1-T08 |
| M2-T04 | PHAsset拡張 | 未着手 | 高 | 1.5h | M2-T03 |
| M2-T05 | PhotoRepository基盤 | 未着手 | 高 | 2h | M2-T04 |
| M2-T06 | 写真一覧取得 | 未着手 | 高 | 2h | M2-T05 |
| M2-T07 | サムネイル取得 | 未着手 | 高 | 2h | M2-T06 |
| M2-T08 | ストレージ情報取得 | 未着手 | 中 | 1.5h | M2-T06 |
| M2-T09 | PhotoScanner実装 | 未着手 | 高 | 2.5h | M2-T06 |
| M2-T10 | バックグラウンドスキャン | 未着手 | 低 | 2h | M2-T09 |
| M2-T11 | ThumbnailCache実装 | 未着手 | 中 | 1.5h | M2-T07 |
| M2-T12 | 単体テスト作成 | 未着手 | 中 | 2h | M2-T09 |

**M2合計: 12タスク / 20.5時間**

---

## M3: Image Analysis & Grouping

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M3-T01 | PhotoAnalysisResultモデル | 未着手 | 高 | 1h | M1-T08 |
| M3-T02 | PhotoGroupモデル | 未着手 | 高 | 1h | M3-T01 |
| M3-T03 | VisionRequestHandler | 未着手 | 高 | 2h | M2-T05 |
| M3-T04 | 特徴量抽出 | 未着手 | 高 | 2.5h | M3-T03 |
| M3-T05 | 類似度計算 | 未着手 | 高 | 2h | M3-T04 |
| M3-T06 | SimilarityAnalyzer実装 | 未着手 | 高 | 2.5h | M3-T05 |
| M3-T07 | 顔検出実装 | 未着手 | 高 | 2h | M3-T03 |
| M3-T08 | ブレ検出実装 | 未着手 | 高 | 2h | M3-T03 |
| M3-T09 | スクリーンショット検出 | 未着手 | 高 | 1.5h | M2-T04 |
| M3-T10 | PhotoGrouper実装 | 未着手 | 高 | 2.5h | M3-T06,M3-T07,M3-T08,M3-T09 |
| M3-T11 | BestShotSelector実装 | 未着手 | 高 | 2h | M3-T10 |
| M3-T12 | AnalysisRepository統合 | 未着手 | 高 | 2h | M3-T11 |
| M3-T13 | 単体テスト作成 | 未着手 | 中 | 2.5h | M3-T12 |

**M3合計: 13タスク / 25.5時間**

---

## M4: UI Components

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M4-T05 | PhotoThumbnail実装 | 未着手 | 高 | 2h | M4-T03 |
| M4-T06 | PhotoGrid実装 | 未着手 | 高 | 2h | M4-T05 |
| M4-T07 | StorageIndicator実装 | 未着手 | 高 | 1.5h | M4-T03 |
| M4-T08 | GroupCard実装 | 未着手 | 高 | 1.5h | M4-T05 |
| M4-T09 | ActionButton実装 | 未着手 | 中 | 1h | M4-T03 |
| M4-T10 | ProgressOverlay実装 | 未着手 | 高 | 1.5h | M4-T03 |
| M4-T11 | ConfirmationDialog実装 | 未着手 | 高 | 1h | M4-T09 |
| M4-T12 | EmptyStateView実装 | 未着手 | 中 | 1h | M4-T03 |
| M4-T13 | ToastView実装 | 未着手 | 中 | 1h | M4-T03 |
| M4-T14 | プレビュー環境整備 | 未着手 | 中 | 1h | M4-T13 |

**M4残: 10タスク / 13.5時間** (完了: 4タスク / 3.5時間 -> アーカイブ済)

---

## M5: Dashboard & Statistics

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M5-T01 | CleanupRecordモデル | 未着手 | 中 | 0.5h | M1-T08 |
| M5-T02 | StorageStatisticsモデル | 未着手 | 中 | 0.5h | M3-T02 |
| M5-T03 | ScanPhotosUseCase実装 | 未着手 | 高 | 2.5h | M2-T09,M3-T12 |
| M5-T04 | GetStatisticsUseCase実装 | 未着手 | 中 | 1.5h | M5-T02 |
| M5-T05 | HomeViewModel実装 | 未着手 | 高 | 2h | M5-T03,M5-T04 |
| M5-T06 | StorageOverviewCard実装 | 未着手 | 高 | 2h | M4-T07 |
| M5-T07 | HomeView実装 | 未着手 | 高 | 2.5h | M5-T05,M5-T06 |
| M5-T08 | GroupListViewModel実装 | 未着手 | 高 | 2h | M3-T10 |
| M5-T09 | GroupListView実装 | 未着手 | 高 | 2.5h | M5-T08,M4-T08 |
| M5-T10 | GroupDetailViewModel実装 | 未着手 | 高 | 2h | M5-T08 |
| M5-T11 | GroupDetailView実装 | 未着手 | 高 | 2.5h | M5-T10,M4-T06 |
| M5-T12 | Navigation設定 | 未着手 | 高 | 1.5h | M5-T07,M5-T09,M5-T11 |
| M5-T13 | 単体テスト作成 | 未着手 | 中 | 2h | M5-T12 |

**M5合計: 13タスク / 24時間**

---

## M6: Deletion & Safety

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M6-T01 | TrashPhotoモデル | 未着手 | 高 | 1h | M1-T08 |
| M6-T02 | TrashDataStore実装 | 未着手 | 高 | 2h | M6-T01 |
| M6-T03 | TrashManager基盤 | 未着手 | 高 | 2h | M6-T02 |
| M6-T04 | moveToTrash実装 | 未着手 | 高 | 2h | M6-T03 |
| M6-T05 | restoreFromTrash実装 | 未着手 | 高 | 2h | M6-T04 |
| M6-T06 | 自動クリーンアップ | 未着手 | 中 | 1.5h | M6-T03 |
| M6-T07 | DeletePhotosUseCase実装 | 未着手 | 高 | 2h | M6-T04 |
| M6-T08 | RestorePhotosUseCase実装 | 未着手 | 高 | 1.5h | M6-T05 |
| M6-T09 | DeletionConfirmationService | 未着手 | 高 | 1h | M4-T11 |
| M6-T10 | TrashViewModel実装 | 未着手 | 高 | 2h | M6-T07,M6-T08 |
| M6-T11 | TrashView実装 | 未着手 | 高 | 2.5h | M6-T10,M4-T06 |
| M6-T12 | DeletionConfirmationSheet | 未着手 | 高 | 1.5h | M6-T09 |
| M6-T13 | PHAsset削除連携 | 未着手 | 高 | 2h | M2-T05 |
| M6-T14 | 単体テスト作成 | 未着手 | 中 | 2h | M6-T13 |

**M6合計: 14タスク / 25時間**

---

## M7: Notifications

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M7-T01 | NotificationSettingsモデル | 未着手 | 中 | 1h | M1-T08 |
| M7-T02 | Info.plist権限設定 | 未着手 | 高 | 0.5h | M1-T01 |
| M7-T03 | NotificationManager基盤 | 未着手 | 高 | 2h | M7-T02 |
| M7-T04 | 権限リクエスト実装 | 未着手 | 高 | 1h | M7-T03 |
| M7-T05 | NotificationContentBuilder | 未着手 | 中 | 1.5h | M7-T03 |
| M7-T06 | 空き容量警告通知 | 未着手 | 中 | 2h | M7-T05,M2-T08 |
| M7-T07 | StorageMonitor実装 | 未着手 | 中 | 2h | M2-T08 |
| M7-T08 | 定期リマインド実装 | 未着手 | 低 | 1.5h | M7-T05 |
| M7-T09 | スキャン完了通知 | 未着手 | 低 | 1h | M7-T05 |
| M7-T10 | ゴミ箱期限警告 | 未着手 | 低 | 1h | M7-T05,M6-T03 |
| M7-T11 | NotificationDelegate実装 | 未着手 | 中 | 1.5h | M7-T03 |
| M7-T12 | 設定画面連携 | 未着手 | 中 | 1h | M8-T08 |
| M7-T13 | 単体テスト作成 | 未着手 | 中 | 1.5h | M7-T11 |

**M7合計: 13タスク / 17.5時間**

---

## M8: Settings & Preferences

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M8-T01 | UserSettingsモデル | 未着手 | 高 | 1.5h | M1-T08 |
| M8-T02 | SettingsRepository実装 | 未着手 | 高 | 1.5h | M8-T01 |
| M8-T03 | PermissionManager実装 | 未着手 | 高 | 2h | M2-T02,M7-T04 |
| M8-T04 | SettingsViewModel実装 | 未着手 | 高 | 2h | M8-T02 |
| M8-T05 | PermissionsViewModel | 未着手 | 中 | 1h | M8-T03 |
| M8-T06 | SettingsRow/Toggle実装 | 未着手 | 高 | 1.5h | M4-T03 |
| M8-T07 | SettingsView実装 | 未着手 | 高 | 2.5h | M8-T04,M8-T06 |
| M8-T08 | ScanSettingsView実装 | 未着手 | 中 | 1.5h | M8-T07 |
| M8-T09 | AnalysisSettingsView実装 | 未着手 | 低 | 1h | M8-T07 |
| M8-T10 | NotificationSettingsView | 未着手 | 中 | 1.5h | M8-T07,M7-T01 |
| M8-T11 | DisplaySettingsView実装 | 未着手 | 低 | 1h | M8-T07 |
| M8-T12 | PermissionsView実装 | 未着手 | 中 | 1.5h | M8-T05 |
| M8-T13 | AboutView実装 | 未着手 | 低 | 1h | M4-T03 |
| M8-T14 | 単体テスト作成 | 未着手 | 中 | 1.5h | M8-T13 |

**M8合計: 14タスク / 21時間**

---

## M9: Monetization

| タスクID | タスク名 | ステータス | 優先度 | 見積 | 依存 |
|----------|----------|------------|--------|------|------|
| M9-T01 | PremiumStatusモデル | 未着手 | 高 | 1h | M1-T08 |
| M9-T02 | ProductInfoモデル | 未着手 | 中 | 0.5h | M9-T01 |
| M9-T03 | StoreKit 2設定 | 未着手 | 高 | 1h | M1-T01 |
| M9-T04 | PurchaseRepository実装 | 未着手 | 高 | 3h | M9-T03 |
| M9-T05 | PremiumManager実装 | 未着手 | 高 | 2.5h | M9-T04 |
| M9-T06 | FeatureGate実装 | 未着手 | 高 | 1.5h | M9-T05 |
| M9-T07 | 削除上限管理 | 未着手 | 高 | 1.5h | M9-T06 |
| M9-T08 | Google Mobile Ads導入 | 未着手 | 中 | 2h | M1-T01 |
| M9-T09 | AdManager実装 | 未着手 | 中 | 2h | M9-T08 |
| M9-T10 | BannerAdView実装 | 未着手 | 中 | 1.5h | M9-T09 |
| M9-T11 | PremiumViewModel実装 | 未着手 | 高 | 2h | M9-T05 |
| M9-T12 | PremiumView実装 | 未着手 | 高 | 2.5h | M9-T11,M4-T03 |
| M9-T13 | LimitReachedSheet実装 | 未着手 | 高 | 1h | M9-T06 |
| M9-T14 | 購入復元実装 | 未着手 | 高 | 1.5h | M9-T04 |
| M9-T15 | 単体テスト作成 | 未着手 | 中 | 2h | M9-T14 |

**M9合計: 15タスク / 25.5時間**

---

## サマリー

| モジュール | 残タスク | 残時間 | 完了タスク |
|------------|----------|--------|------------|
| M1: Core Infrastructure | 0 | 0h | 10 (16h) ✅ |
| M2: Photo Access | 12 | 20.5h | 0 |
| M3: Image Analysis | 13 | 25.5h | 0 |
| M4: UI Components | 10 | 13.5h | 4 (3.5h) |
| M5: Dashboard | 13 | 24h | 0 |
| M6: Deletion & Safety | 14 | 25h | 0 |
| M7: Notifications | 13 | 17.5h | 0 |
| M8: Settings | 14 | 21h | 0 |
| M9: Monetization | 15 | 25.5h | 0 |
| **残合計** | **104** | **172.5h** | **14 (17.5h)** |

*進捗: 14/118タスク完了 (11.9%) / 17.5h/190h (9.2%)*

---

## 推奨実装順序

1. **Phase 1 - 基盤構築**（M1, M4前半）
   - M1-T01〜M1-T08（Xcodeプロジェクト、基盤クラス）
   - M4-T01〜M4-T04（デザインシステム基盤）

2. **Phase 2 - データ層**（M2, M3）
   - M2-T01〜M2-T09（写真アクセス）
   - M3-T01〜M3-T12（画像分析）

3. **Phase 3 - UI層**（M4後半, M5）
   - M4-T05〜M4-T14（UIコンポーネント）
   - M5-T01〜M5-T12（ダッシュボード画面）

4. **Phase 4 - 機能完成**（M6, M8）
   - M6-T01〜M6-T13（削除・ゴミ箱）
   - M8-T01〜M8-T13（設定）

5. **Phase 5 - 仕上げ**（M7, M9, テスト）
   - M7-T01〜M7-T12（通知）
   - M9-T01〜M9-T14（課金）
   - 各モジュールの単体テスト

---

*最終更新: 2025-11-28*
