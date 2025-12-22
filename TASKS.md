# タスク管理

## 完了タスク（141/147）

### ゴミ箱統合修正（2025-12-22完了）
- [x] ContentView.swift onDeletePhotos修正（DeletePhotosUseCase使用）
  - 完了日：2025-12-22
  - 品質スコア：94点
  - 担当：@spec-developer

- [x] ContentView.swift onDeleteGroups修正（DeletePhotosUseCase使用）
  - 完了日：2025-12-22
  - 品質スコア：94点
  - 担当：@spec-developer

- [x] エラーハンドリング改善（DeletePhotosUseCaseError対応）
  - 完了日：2025-12-22
  - 担当：@spec-developer

### 実機テスト（2025-12-22完了）
- [x] 実機ビルド・インストール
  - 完了日：2025-12-22
  - デバイス：iPhone 15 Pro Max
  - 担当：@spec-builder

- [x] ゴミ箱統合機能E2Eテスト
  - 完了日：2025-12-22
  - 結果：3つの問題発見
  - 担当：@spec-validator

- [x] 発見問題の根本原因分析
  - 完了日：2025-12-22
  - 結果：全問題の原因特定・解決策策定完了
  - 担当：@spec-architect

## 未完了タスク（6/147）

### 優先度：最高（P0 - ブロッカー）
- [ ] **DEVICE-001: グループ一覧→ホーム遷移で画面固まり**
  - 症状：グループ一覧タブからホームタブに戻ると画面が固まる
  - 根本原因：
    - `.task`修飾子で毎回データ再読み込み
    - デバッグログが過剰（パフォーマンス低下）
  - 対象ファイル：`HomeView.swift`
  - 解決策：
    - `.task(id:)`で変更時のみ再読み込み
    - デバッグログを`#if DEBUG`で囲む
  - 推定時間：2時間
  - 品質向上：+3点
  - 担当：@spec-developer

### 優先度：高（P1）
- [ ] **DEVICE-002: ゴミ箱サムネイル未表示**
  - 症状：ゴミ箱タブを開いてもサムネイルが表示されない
  - 根本原因：`TrashManager.swift`のサムネイル生成が未実装
  - 対象ファイル：`TrashManager.swift`
  - 解決策：`PHImageManager`を使用したサムネイル生成ロジック追加
  - 推定時間：2時間
  - 品質向上：+2点
  - 担当：@spec-developer

### 優先度：中（P2）
- [ ] **DEVICE-003: グループ詳細UX問題**
  - 症状：選択モードボタン未実装、全削除ボタン未実装
  - 根本原因：`GroupDetailView.swift`のUI要素が未実装
  - 対象ファイル：`GroupDetailView.swift`
  - 解決策：選択モードと一括削除UIの実装
  - 推定時間：3時間
  - 品質向上：+1点
  - 担当：@spec-developer

### 優先度：中（M10リリース準備）
- [ ] **M10-T04: App Store Connect設定**
  - 目的：App Store Connectでアプリ情報登録
  - 前提条件：P0〜P2問題修正完了
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

## タスク統計
- **全体進捗**: 96%（141/147タスク完了）
- **完了時間**: 227h
- **残作業時間**: 16h
  - P0修正: 2h
  - P1修正: 2h
  - P2修正: 3h
  - M10リリース準備: 9h
- **品質スコア平均**: 90.5点
- **目標品質スコア**: 99点（全問題解決後）

## 次回セッション推奨

### 推奨順序（優先度順）
1. **P0: グループ一覧→ホーム遷移固まり修正**（2h）
   - HomeView.swiftの.taskを.task(id:)に変更
   - デバッグログを#if DEBUGで囲む

2. **P1: ゴミ箱サムネイル未表示修正**（2h）
   - TrashManager.swiftにPHImageManagerでサムネイル生成追加

3. **P2: グループ詳細UX問題修正**（3h）
   - GroupDetailView.swiftに選択モード・全削除ボタン追加

4. **M10リリース準備**（9h）
   - 全問題解決後に実施

### 期待される成果
- 全問題解決で品質スコア99点達成
- ユーザー体験の大幅改善
- App Store審査準備完了

---

## アーカイブ済みタスク
過去の完了タスク（M1〜M9）は TASKS_COMPLETED.md に移動済み（136タスク）
