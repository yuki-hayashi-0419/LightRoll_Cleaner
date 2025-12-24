# タスク管理

## 最終更新: 2025-12-24

---

## 未完了タスク（8件）

### ゴミ箱バグ修正（優先度：Critical/High）

- [ ] **BUG-TRASH-002-P1A: RestorePhotosUseCase ID不一致修正**
  - 目的：復元時のIDマッチング問題解決
  - 推定時間：1.5時間
  - 担当：@spec-developer

- [ ] **BUG-TRASH-002-P1B: Photos Frameworkコールバック問題修正**
  - 目的：withCheckedContinuation二重resume防止
  - 推定時間：1時間
  - 担当：@spec-developer

- [ ] **BUG-TRASH-002-P1C: SwiftUI環境オブジェクト未注入修正**
  - 目的：SettingsService環境注入確認・修正
  - 推定時間：0.5時間
  - 担当：@spec-developer

- [ ] **BUG-TRASH-002-P2A: 非同期処理中のビュー破棄対策**
  - 目的：復元中ビュー遷移でのクラッシュ防止
  - 推定時間：1時間
  - 担当：@spec-developer

- [ ] **BUG-TRASH-001-P2B: ゴミ箱選択UX改善**
  - 目的：タップで自動編集モード開始
  - 推定時間：1時間
  - 担当：@spec-developer

### M10リリース準備（優先度：高）

- [ ] **M10-T04: App Store Connect設定**
  - 目的：App Store Connectでアプリ情報登録
  - 実施内容：
    - アプリメタデータ登録
    - スクリーンショット準備
    - プライバシーポリシー設定
  - 推定時間：3時間
  - 担当：@spec-release-manager

- [ ] **M10-T05: TestFlight配信**
  - 目的：ベータテスト実施
  - 前提条件：M10-T04完了
  - 推定時間：2時間
  - 担当：@spec-release-manager

- [ ] **M10-T06: 最終ビルド・審査提出**
  - 目的：App Store審査提出
  - 前提条件：M10-T05完了
  - 推定時間：4時間
  - 担当：@spec-release-manager

---

## タスク統計

| 項目 | 値 |
|------|-----|
| 全体進捗 | 95%（157/165タスク完了） |
| 完了時間 | 254.5h |
| 残作業時間 | 15.5h（BUG修正6.5h + M10リリース9h） |
| 品質スコア平均 | 92点 |

### 直近の品質スコア

| タスク | スコア | 判定 |
|--------|--------|------|
| DISPLAY-001〜004 | 93点 | 合格 |
| SETTINGS-001 | 95点 | 合格 |
| SETTINGS-002 | 95点 | 合格 |
| BUG-002 Phase 2 | 95点 | 合格 |
| BUG-001 Phase 2 | 90点 | 合格 |

---

## 次回セッション推奨

### 推奨順序（優先度順）

#### Phase 1: クラッシュ修正（最優先、3h）
1. **BUG-TRASH-002-P1A**: RestorePhotosUseCase ID不一致修正（1.5h）
2. **BUG-TRASH-002-P1B**: Photos Frameworkコールバック問題修正（1h）
3. **BUG-TRASH-002-P1C**: SwiftUI環境オブジェクト未注入修正（0.5h）

#### Phase 2: UX改善（2h）
4. **BUG-TRASH-002-P2A**: 非同期処理中のビュー破棄対策（1h）
5. **BUG-TRASH-001-P2B**: ゴミ箱選択UX改善（1h）

#### Phase 3: M10リリース準備（9h）
6. **M10-T04**: App Store Connect設定（3h）
7. **M10-T05**: TestFlight配信（2h）
8. **M10-T06**: 最終ビルド・審査提出（4h）

### 期待される成果
- ゴミ箱機能のクラッシュ完全解消
- ゴミ箱選択UXの直感化
- App Store審査提出準備完了
- プロジェクト100%完了

---

## アーカイブ情報

完了タスク（157件）は `docs/archive/TASKS_COMPLETED.md` に移動済み

### 直近アーカイブ済みタスク（2025-12-24）
- DISPLAY-001〜004: DisplaySettings統合（品質スコア93点）
- SETTINGS-001/002: 設定ページ統合（品質スコア95点）

*詳細は `docs/archive/TASKS_COMPLETED.md` を参照*
