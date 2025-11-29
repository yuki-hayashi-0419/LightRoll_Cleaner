# MIGRATION_LOG.md

v3.0マイグレーション実行ログ

## 移行情報

| 項目 | 値 |
|------|-----|
| 移行日時 | 2025-11-29 |
| 移行前バージョン | 旧運用 |
| 移行後バージョン | v3.0 |
| 実行者 | Claude Code (@spec-orchestrator, @spec-architect, @spec-context-optimizer) |

---

## 移動したファイル一覧

| ファイル名 | 移動理由 |
|-----------|---------|
| REVIEW_GUIDELINES.md | ホワイトリスト外（レビューガイドライン、設計情報含む） |
| PARALLEL_PLAN.md | ホワイトリスト外（Phase 2完了により内容が古くなった並行計画） |
| M3-T10_QUALITY_REVIEW_LOOP1.md | ホワイトリスト外（完了タスクの品質レビュー記録） |
| validation_request_M3-T11.md | ホワイトリスト外（完了タスクの検証リクエスト） |
| OPTIMIZATION_REPORT_OPT009.md | ホワイトリスト外（古い最適化レポート） |
| CONTEXT_OPTIMIZATION_REPORT_opt-014.md | ホワイトリスト外（古い最適化レポート） |
| CONTEXT_OPTIMIZATION_REPORT_opt-015.md | ホワイトリスト外（最新だが最適化レポート） |
| CONTEXT_STATUS_REPORT_2025-11-29.md | ホワイトリスト外（ステータスレポート） |

---

## 削除したファイル一覧

| ファイル名 | 削除理由 |
|-----------|---------|
| docs/CONTEXT_HANDOFF.json | ルートと重複（ルートの同名ファイルに統合） |

---

## 作成したディレクトリ

| パス | 目的 |
|-----|------|
| docs/archive/legacy/ | 旧運用ドキュメントの保管 |
| assets/images/ | 画像アセット用 |
| assets/icons/ | アイコンアセット用 |
| assets/fonts/ | フォントアセット用 |

---

## 生成したドキュメント

| ファイル名 | 説明 |
|-----------|------|
| docs/CRITICAL/BUILD_CONFIG.md | ビルド設定ドキュメント（v3.0必須） |
| docs/CRITICAL/WORKFLOW_GUIDE.md | ワークフローガイド（v3.0必須） |
| BUILD_ERRORS.md | ビルドエラー記録テンプレート |
| DEVICE_ISSUES.md | デバイス問題記録テンプレート |
| INCIDENT_LOG.md | インシデント記録テンプレート |
| FEEDBACK_LOG.md | フィードバック記録テンプレート |

---

## 既存ドキュメントの状態

以下のドキュメントはすでにv3.0準拠の形式・場所にあったため、変更なし：

- docs/CRITICAL/ARCHITECTURE.md
- docs/CRITICAL/CORE_RULES.md
- docs/TASKS.md（M*-T*形式、完了タスクはアーカイブ済み）
- docs/PROGRESS.md（7/10エントリ、制限内）
- docs/IMPLEMENTED.md（ユーザー視点形式）
- docs/PROJECT_SUMMARY.md
- docs/TEST_RESULTS.md
- docs/SECURITY_AUDIT.md
- docs/modules/MODULE_M*.md（9モジュール）
- docs/archive/TASKS_COMPLETED.md
- docs/archive/PROGRESS_ARCHIVE.md
- docs/archive/IMPLEMENTED_HISTORY.md
- CONTEXT_HANDOFF.json（v2.1スキーマ）
- ERROR_KNOWLEDGE_BASE.md

---

## 注意事項

1. **移動したファイルへの参照**: 移動したファイルへの参照がある場合、`docs/archive/legacy/` から復元可能
2. **CONTEXT_HANDOFF.json**: ルートのファイルが最新（docs/から統合）
3. **空ディレクトリ**: `src/modules/`, `tests/` は既存だが空（SPMパッケージで管理されているため使用されていない）

---

## 移行後の構造

```
LightRoll_Cleaner/
├── CONTEXT_HANDOFF.json        # セッション引き継ぎ（v2.1）
├── ERROR_KNOWLEDGE_BASE.md     # エラー知識ベース
├── BUILD_ERRORS.md             # ビルドエラー記録 [NEW]
├── DEVICE_ISSUES.md            # デバイス問題記録 [NEW]
├── INCIDENT_LOG.md             # インシデント記録 [NEW]
├── FEEDBACK_LOG.md             # フィードバック記録 [NEW]
├── README.md
├── CLAUDE.md
├── .gitignore
├── docs/
│   ├── CRITICAL/
│   │   ├── ARCHITECTURE.md
│   │   ├── CORE_RULES.md
│   │   ├── BUILD_CONFIG.md     [NEW]
│   │   └── WORKFLOW_GUIDE.md   [NEW]
│   ├── TASKS.md
│   ├── PROGRESS.md
│   ├── IMPLEMENTED.md
│   ├── PROJECT_SUMMARY.md
│   ├── TEST_RESULTS.md
│   ├── SECURITY_AUDIT.md
│   ├── modules/
│   │   └── MODULE_M*.md (9件)
│   └── archive/
│       ├── TASKS_COMPLETED.md
│       ├── PROGRESS_ARCHIVE.md
│       ├── IMPLEMENTED_HISTORY.md
│       └── legacy/             [NEW]
│           ├── MIGRATION_LOG.md
│           ├── REVIEW_GUIDELINES.md
│           ├── PARALLEL_PLAN.md
│           ├── M3-T10_QUALITY_REVIEW_LOOP1.md
│           ├── validation_request_M3-T11.md
│           ├── OPTIMIZATION_REPORT_OPT009.md
│           ├── CONTEXT_OPTIMIZATION_REPORT_opt-014.md
│           ├── CONTEXT_OPTIMIZATION_REPORT_opt-015.md
│           └── CONTEXT_STATUS_REPORT_2025-11-29.md
├── assets/                     [NEW]
│   ├── images/
│   ├── icons/
│   └── fonts/
├── Config/
├── LightRoll_Cleaner/
├── LightRoll_Cleaner.xcodeproj/
├── LightRoll_Cleaner.xcworkspace/
├── LightRoll_CleanerPackage/   # 主要開発領域
└── LightRoll_CleanerUITests/
```

---

**移行完了**: 2025-11-29
