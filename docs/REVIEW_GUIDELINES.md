# LightRoll Cleaner - レビュー体制とPR管理ガイドライン

**作成日**: 2025-11-28
**対象プロジェクト**: LightRoll Cleaner（iOS写真クリーナーアプリ）
**総タスク数**: 118タスク / 190時間
**モジュール数**: 9（M1〜M9）

---

## 1. コードレビューチェックリスト

### 1.1 必須チェック項目（Critical - 全てパス必須）

#### アーキテクチャ準拠
| チェック項目 | 確認内容 |
|-------------|----------|
| MVVM分離 | ViewにビジネスロジックがないかViewModelに集約されているか |
| Repository Pattern | データアクセスはRepositoryProtocol経由か、直接Framework呼び出しがないか |
| Protocol依存 | ViewModelはProtocol型に依存しているか（具象クラス直接依存禁止） |
| DI注入 | 依存オブジェクトはイニシャライザ注入またはEnvironment経由か |
| @MainActor | UI関連の状態変更は@MainActorで保護されているか |

#### セキュリティ
| チェック項目 | 確認内容 |
|-------------|----------|
| データ送信禁止 | 写真データをネットワーク経由で送信していないか |
| 権限最小化 | Photos Frameworkへのアクセスは必要最小限か |
| 暗号化 | ゴミ箱データ等の機密情報は暗号化されているか |
| ユーザー同意 | 削除処理にユーザー確認が入っているか |

#### エラーハンドリング
| チェック項目 | 確認内容 |
|-------------|----------|
| LightRollError使用 | カスタムエラー型を使用しているか（生のError禁止） |
| 全パス処理 | 全てのエラーパスが適切に処理されているか |
| UI表示 | ユーザーに分かりやすいエラーメッセージを表示しているか |
| ログ出力 | デバッグ用にエラー詳細をログ出力しているか |

### 1.2 品質チェック項目（Major - 修正推奨）

#### Swift/SwiftUI品質
| チェック項目 | 確認内容 |
|-------------|----------|
| 命名規則 | Swift API Design Guidelines準拠の命名か |
| ドキュメント | 公開APIに///コメントがあるか |
| アクセス修飾子 | 適切なアクセス修飾子（private/internal/public）を使用しているか |
| 型安全性 | 強制アンラップ（!）を避けているか |
| Optional処理 | guard let / if letを適切に使用しているか |

#### SwiftUI特有
| チェック項目 | 確認内容 |
|-------------|----------|
| @State vs @StateObject | 値型は@State、参照型は@StateObjectを使用しているか |
| View分割 | 1つのViewが100行を超えていないか（超える場合は分割） |
| Preview対応 | Preview用のモックデータが用意されているか |
| LazyStack | 大量データにはLazyVStack/LazyHGridを使用しているか |

#### パフォーマンス
| チェック項目 | 確認内容 |
|-------------|----------|
| async/await | 非同期処理にasync/awaitを適切に使用しているか |
| TaskGroup | 並列処理可能な場合はTaskGroupを使用しているか |
| メモリ | 大量画像処理でautoreleasepool/バッチ処理を使用しているか |
| キャッシュ | 計算コストの高い結果はキャッシュしているか |

### 1.3 推奨チェック項目（Minor - 任意修正）

| チェック項目 | 確認内容 |
|-------------|----------|
| マジックナンバー | 定数はAppConfigに定義されているか |
| コード重複 | 類似コードがある場合は共通化されているか |
| TODO/FIXME | 残っている場合はIssue化されているか |
| コメント | 複雑なロジックに説明コメントがあるか |

---

## 2. PRテンプレート

### 2.1 Pull Request テンプレート

```markdown
## タスク情報
- **タスクID**: M{n}-T{nn}
- **タスク名**:
- **モジュール**:
- **見積時間**:
- **実作業時間**:

## 変更概要
<!-- 変更内容を簡潔に説明 -->

## 変更種別
- [ ] 新規機能（feat）
- [ ] バグ修正（fix）
- [ ] リファクタリング（refactor）
- [ ] テスト追加（test）
- [ ] ドキュメント（docs）
- [ ] その他（chore）

## 変更ファイル一覧
<!-- 主要な変更ファイルを列挙 -->
- `path/to/file1.swift`: 追加/変更/削除の内容
- `path/to/file2.swift`: 追加/変更/削除の内容

## レビューチェックリスト（自己確認）
### Critical
- [ ] MVVM分離: ViewにビジネスロジックがないViewModelに集約
- [ ] Repository Pattern: Protocolを通じたデータアクセス
- [ ] セキュリティ: データ送信なし、権限最小化
- [ ] エラーハンドリング: LightRollError使用、全パス処理

### Major
- [ ] Swift命名規則準拠
- [ ] 公開APIにドキュメントコメント
- [ ] Preview用モックデータ準備
- [ ] async/await適切に使用

### テスト
- [ ] ユニットテスト追加/更新
- [ ] テストカバレッジ80%以上（対象コード）
- [ ] 全テストパス確認済み

## テスト結果
```
# テスト実行コマンドと結果を記載
xcodebuild test -scheme LightRollCleaner -destination 'platform=iOS Simulator,name=iPhone 15'
```

## スクリーンショット（UI変更がある場合）
<!-- Before/After のスクリーンショットを添付 -->

## 関連Issue/PR
- closes #issue_number
- related #pr_number

## 特記事項
<!-- レビュアーに伝えたいことがあれば記載 -->
```

### 2.2 PRの粒度ガイドライン

| 粒度 | 推奨ケース | ファイル数目安 |
|------|-----------|---------------|
| **タスク単位**（推奨） | 通常の機能開発、独立したタスク | 5〜15ファイル |
| **サブタスク単位** | 大規模タスク（3h超）の分割 | 3〜8ファイル |
| **モジュール単位** | 初期構築フェーズ、大規模リファクタリング | 15〜30ファイル |

#### PR粒度の判断基準

```
タスク見積 ≤ 2h → 1タスク = 1PR
タスク見積 > 2h → サブタスク分割を検討
モジュール初期構築 → モジュール単位PR可
依存タスク群 → まとめて1PR検討
```

---

## 3. コンフリクト検出・防止戦略

### 3.1 コンフリクトリスク箇所マッピング

| リスクレベル | ファイル/ディレクトリ | 理由 | 関連モジュール |
|-------------|----------------------|------|---------------|
| **高** | `DIContainer.swift` | 全モジュールが依存を追加 | M1〜M9全て |
| **高** | `AppState.swift` | 状態プロパティの追加が頻繁 | M2, M3, M5, M6 |
| **高** | `Protocols/Repositories.swift` | Repository定義の追加 | M2, M3, M6, M8, M9 |
| **高** | `LightRollError.swift` | エラーケースの追加 | M1〜M9全て |
| **中** | `Navigation.swift` | 画面遷移の追加 | M5, M6, M8, M9 |
| **中** | `AppConfig.swift` | 設定値の追加 | M3, M6, M7, M9 |
| **中** | `Assets.xcassets` | 画像/色リソースの追加 | M4, M5 |
| **低** | 各ViewModelファイル | モジュール内で独立 | モジュール固有 |
| **低** | 各Viewファイル | モジュール内で独立 | モジュール固有 |

### 3.2 コンフリクト防止策

#### 3.2.1 ファイル分割戦略

```
【変更前】
Protocols/Repositories.swift  ← 全Repository定義（コンフリクト高）

【変更後】
Protocols/
├── PhotoRepositoryProtocol.swift      ← M2担当
├── AnalysisRepositoryProtocol.swift   ← M3担当
├── SettingsRepositoryProtocol.swift   ← M8担当
├── PurchaseRepositoryProtocol.swift   ← M9担当
├── TrashRepositoryProtocol.swift      ← M6担当
└── NotificationRepositoryProtocol.swift ← M7担当
```

#### 3.2.2 Extension分割戦略

```swift
// 【コンフリクト高】全て1ファイル
// LightRollError.swift
enum LightRollError: LocalizedError {
    // 全エラーケース
}

// 【コンフリクト低】モジュール別Extension
// LightRollError+Core.swift (M1)
extension LightRollError {
    static func coreErrors() -> [LightRollError] { ... }
}

// LightRollError+Photo.swift (M2)
extension LightRollError {
    case photoAccessDenied
    case photoFetchFailed
}
```

#### 3.2.3 DIContainer分割戦略

```swift
// DIContainer+PhotoModule.swift
extension DIContainer {
    var photoRepository: PhotoRepositoryProtocol { ... }
    var photoScanner: PhotoScannerProtocol { ... }
}

// DIContainer+AnalysisModule.swift
extension DIContainer {
    var analysisRepository: AnalysisRepositoryProtocol { ... }
    var similarityAnalyzer: SimilarityAnalyzerProtocol { ... }
}
```

### 3.3 並行開発時のルール

#### 3.3.1 ファイルロック制度

| 状況 | 対応 |
|------|------|
| 高リスクファイルを変更する | SlackでPR作成まで「ロック宣言」 |
| 同一ファイルを複数人が変更 | 先にPRした方が優先、後発はrebase |
| 緊急修正が必要 | `hotfix/`ブランチで対応、即座にmerge |

#### 3.3.2 ブランチ同期ルール

```bash
# 毎日開発開始時に必ず実行
git fetch origin
git rebase origin/develop

# 高リスクファイル変更前に必ず実行
git pull --rebase origin develop
```

### 3.4 コンフリクト発生時の解決手順

```
Step 1: コンフリクト発生を確認
        ↓
Step 2: 変更内容の比較（両方の意図を理解）
        ↓
Step 3: 優先度判断
        - 機能追加同士 → 両方取り込み
        - 同一機能の異なる実装 → 先行PR優先
        - リファクタリングvs機能追加 → 機能追加優先
        ↓
Step 4: 手動マージ実施
        ↓
Step 5: 全テスト実行で動作確認
        ↓
Step 6: レビュー再依頼
```

---

## 4. 品質ゲート定義

### 4.1 フェーズ別品質チェックポイント

#### Phase 1: 基盤構築（M1, M4前半）

| ゲート | チェック項目 | 合格基準 |
|--------|------------|----------|
| **G1-1** | プロジェクトビルド | エラー0、警告10以下 |
| **G1-2** | ディレクトリ構造 | 設計書通りの構造 |
| **G1-3** | Protocol定義 | 全Repository/UseCaseプロトコル定義完了 |
| **G1-4** | DIContainer | 全依存解決可能 |
| **G1-5** | 基盤テスト | M1テストカバレッジ80%以上 |

#### Phase 2: データ層（M2, M3）

| ゲート | チェック項目 | 合格基準 |
|--------|------------|----------|
| **G2-1** | 権限処理 | 全権限状態（granted/denied/restricted/notDetermined）をハンドリング |
| **G2-2** | 写真取得 | 1000枚を10秒以内で取得 |
| **G2-3** | 分析精度 | 類似度判定精度90%以上（テストセット） |
| **G2-4** | メモリ | スキャン中200MB以内 |
| **G2-5** | データ層テスト | M2/M3テストカバレッジ80%以上 |

#### Phase 3: UI層（M4後半, M5）

| ゲート | チェック項目 | 合格基準 |
|--------|------------|----------|
| **G3-1** | UIコンポーネント | 全共通コンポーネントPreview確認 |
| **G3-2** | レイアウト | iPhone SE〜iPhone 15 Pro Maxで崩れなし |
| **G3-3** | ダークモード | 全画面ダークモード対応 |
| **G3-4** | アクセシビリティ | VoiceOver基本対応 |
| **G3-5** | UI層テスト | ViewModelテストカバレッジ80%以上 |

#### Phase 4: 機能完成（M6, M8）

| ゲート | チェック項目 | 合格基準 |
|--------|------------|----------|
| **G4-1** | 削除フロー | 確認ダイアログ→削除→完了通知の一連フロー動作 |
| **G4-2** | ゴミ箱 | 30日自動削除、復元機能動作 |
| **G4-3** | 設定永続化 | アプリ再起動後も設定維持 |
| **G4-4** | 機能テスト | M6/M8テストカバレッジ80%以上 |

#### Phase 5: 仕上げ（M7, M9）

| ゲート | チェック項目 | 合格基準 |
|--------|------------|----------|
| **G5-1** | 通知 | 権限リクエスト、通知表示動作 |
| **G5-2** | 課金フロー | 購入、復元、機能解放の一連フロー動作 |
| **G5-3** | 広告 | バナー広告表示（無料ユーザー） |
| **G5-4** | E2Eテスト | 主要ユースケース10パターン通過 |
| **G5-5** | 総合カバレッジ | プロジェクト全体80%以上 |

### 4.2 自動チェック項目（CI/CD）

#### 4.2.1 PR作成時（必須パス）

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    branches: [develop, main]

jobs:
  lint:
    runs-on: macos-latest
    steps:
      - name: SwiftLint
        run: swiftlint lint --strict

  build:
    runs-on: macos-latest
    steps:
      - name: Build
        run: xcodebuild build -scheme LightRollCleaner -destination 'platform=iOS Simulator,name=iPhone 15'

  test:
    runs-on: macos-latest
    steps:
      - name: Test
        run: xcodebuild test -scheme LightRollCleaner -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES

  coverage:
    runs-on: macos-latest
    steps:
      - name: Check Coverage
        run: |
          # カバレッジ80%未満でfail
          xcrun xccov view --report *.xcresult --json | jq '.lineCoverage' | awk '{ if ($1 < 0.8) exit 1 }'
```

#### 4.2.2 自動チェック一覧

| チェック | ツール | 失敗時 |
|---------|--------|--------|
| Lint | SwiftLint | PRブロック |
| ビルド | xcodebuild | PRブロック |
| ユニットテスト | XCTest | PRブロック |
| カバレッジ | xccov | 80%未満でPRブロック |
| 静的解析 | SwiftLint analyzer | 警告表示（ブロックなし） |

### 4.3 手動レビュー項目

| カテゴリ | チェック項目 | 担当 |
|---------|------------|------|
| **アーキテクチャ** | MVVM/Repository準拠 | レビュアー |
| **セキュリティ** | データ送信なし、権限適切 | レビュアー |
| **UX** | 操作性、フィードバック適切 | レビュアー/デザイナー |
| **パフォーマンス** | 大量データでの動作確認 | レビュアー |
| **エッジケース** | 権限拒否、ネットワークなし等 | レビュアー |

---

## 5. レビュースコアリング（100点満点）

### 5.1 採点基準

| カテゴリ | 配点 | 内訳 |
|---------|------|------|
| **コード品質** | 30点 | MVVM準拠(10) / 命名規則(5) / 可読性(5) / 重複なし(5) / コメント(5) |
| **セキュリティ** | 30点 | データ保護(15) / 権限管理(10) / エラー処理(5) |
| **パフォーマンス** | 20点 | 非同期処理(10) / メモリ管理(5) / キャッシュ活用(5) |
| **テスト** | 10点 | カバレッジ(5) / テストケース品質(5) |
| **ドキュメント** | 10点 | APIコメント(5) / 特記事項記載(5) |

### 5.2 合格基準

| スコア | 判定 | アクション |
|--------|------|------------|
| 90〜100点 | Excellent | 即マージ可 |
| 80〜89点 | Good | 軽微な指摘後マージ |
| 70〜79点 | Acceptable | 指摘事項修正後再レビュー |
| 60〜69点 | Needs Work | 大幅修正後再レビュー |
| 59点以下 | Rejected | 設計見直し必要 |

---

## 6. マージ基準

### 6.1 developへのマージ条件

- [ ] CI全チェックパス（Lint/Build/Test/Coverage）
- [ ] レビュースコア70点以上
- [ ] レビュアー1名以上のApprove
- [ ] Critical指摘事項なし
- [ ] コンフリクト解消済み

### 6.2 mainへのマージ条件（リリース時）

- [ ] developの全条件を満たす
- [ ] E2Eテスト全パターン通過
- [ ] パフォーマンステスト合格
- [ ] セキュリティ監査完了
- [ ] App Store Connect準備完了

---

## 7. 並行開発推奨スケジュール

### 7.1 モジュール並行開発マトリクス

| Phase | Week1 | Week2 | Week3 | Week4 |
|-------|-------|-------|-------|-------|
| **1** | M1（全員） | M4前半（全員） | - | - |
| **2** | M2（Dev A） | M2（Dev A） | M3（Dev A） | M3（Dev A） |
| **2** | M3前半（Dev B） | M3（Dev B） | M2確認（Dev B） | - |
| **3** | M4後半（Dev A） | M5（Dev A） | M5（Dev A） | - |
| **3** | M5前半（Dev B） | M5（Dev B） | M4確認（Dev B） | - |
| **4** | M6（Dev A） | M6（Dev A） | M8（Dev A） | M8（Dev A） |
| **4** | M8前半（Dev B） | M8（Dev B） | M6確認（Dev B） | - |
| **5** | M7（Dev A） | M9（Dev A） | M9（Dev A） | 統合テスト |
| **5** | M9前半（Dev B） | M7（Dev B） | M7（Dev B） | 統合テスト |

### 7.2 並行開発可能な組み合わせ

| 組み合わせ | 可否 | 理由 |
|-----------|------|------|
| M2 + M4 | OK | 依存なし、共有ファイルなし |
| M3 + M4 | OK | M3はM2完了後、M4と並行可 |
| M5 + M6 | 要注意 | Navigation共有、調整必要 |
| M7 + M8 | OK | 通知設定連携あるが疎結合 |
| M8 + M9 | OK | 設定と課金は独立 |

---

*最終更新: 2025-11-28*
*作成者: spec-reviewer*
