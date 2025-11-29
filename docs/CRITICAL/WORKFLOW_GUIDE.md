# WORKFLOW_GUIDE.md

> **変更不可**: このファイルはCRITICALドキュメントです。変更は禁止されています。

## AI駆動開発ワークフロー v3.0

### ドキュメント階層

```
docs/
├── CRITICAL/           # 変更不可（ARCHITECTURE, CORE_RULES, BUILD_CONFIG, WORKFLOW_GUIDE）
├── TASKS.md            # 追記のみ（完了タスクはarchiveへ）
├── PROGRESS.md         # 追記のみ（10件制限、古いものはarchiveへ）
├── IMPLEMENTED.md      # 追記のみ（ユーザー視点）
├── PROJECT_SUMMARY.md  # 追記のみ
├── modules/            # MODULE_M*.md（設計書）
└── archive/
    ├── TASKS_COMPLETED.md
    ├── PROGRESS_ARCHIVE.md
    ├── IMPLEMENTED_HISTORY.md
    └── legacy/         # 旧運用ドキュメント
```

### コンテキストファイル

| ファイル | 場所 | 説明 |
|---------|------|------|
| CONTEXT_HANDOFF.json | ルート | セッション引き継ぎ（v2.1スキーマ） |
| ERROR_KNOWLEDGE_BASE.md | ルート | エラー知識ベース |
| BUILD_ERRORS.md | ルート | ビルドエラー記録 |
| DEVICE_ISSUES.md | ルート | デバイス問題記録 |
| INCIDENT_LOG.md | ルート | インシデント記録 |
| FEEDBACK_LOG.md | ルート | フィードバック記録 |

## ワークフロー

### 1. セッション開始

1. `CONTEXT_HANDOFF.json` を読み込み
2. 現在のタスクと進捗を確認
3. 必要に応じて `TASKS.md` を参照

### 2. タスク実行

1. タスクIDを M*-T* 形式で管理
2. 実装完了時は品質スコアを記録
3. テスト実行・合格を確認

### 3. セッション終了

1. `CONTEXT_HANDOFF.json` を更新
2. 完了タスクを `docs/archive/TASKS_COMPLETED.md` に移動
3. `PROGRESS.md` にエントリを追加（10件制限）
4. `IMPLEMENTED.md` を更新（ユーザー視点で）

## 品質基準

### 品質スコア（120点満点）

| カテゴリ | 配点 |
|---------|------|
| 機能完全性 | 40点 |
| コード品質 | 30点 |
| テストカバレッジ | 30点 |
| 性能・最適化 | 20点 |

### 合格基準
- 最低: 80点（66.7%）
- 推奨: 100点（83.3%）
- 目標: 110点以上（91.7%）

## コンテキスト最適化

### PROGRESS.md 制限
- 最大10エントリ
- 古いエントリは `PROGRESS_ARCHIVE.md` へ

### TASKS.md 管理
- 未完了タスクのみ保持
- 完了タスクは即座に `TASKS_COMPLETED.md` へ

### 最適化タイミング
- 10エントリ到達時
- 10タスク完了ごと
- フェーズ完了時

## サブエージェント

| サブエージェント | 役割 |
|-----------------|------|
| @spec-orchestrator | 全体統括、ワークフロー制御 |
| @spec-architect | アーキテクチャ設計、設計書管理 |
| @spec-developer | タスク実装、エラー対応 |
| @spec-validator | 品質検証、テスト実行 |
| @spec-context-optimizer | コンテキスト最適化 |
| @spec-test-generator | テストケース生成 |
| @spec-handover | 引き継ぎドキュメント作成 |

## Git運用

### コミットメッセージ形式

```
<type>: <description>

- <detail1>
- <detail2>

🤖 Generated with Claude Code
```

### ブランチ戦略
- `main`: 安定版
- `feature/*`: 機能開発
- `fix/*`: バグ修正

---

**バージョン**: v3.0
**最終更新**: 2025-11-29
