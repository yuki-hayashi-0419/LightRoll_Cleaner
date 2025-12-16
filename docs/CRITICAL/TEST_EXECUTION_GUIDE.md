# 並列実行テスト実行ガイド

## 概要
このガイドでは、`FeaturePrintExtractor` の並列実行を検証するテストの実行方法を説明します。

## 前提条件

### 環境
- macOS (Apple Silicon または Intel)
- Xcode 16.0+
- Swift 6.1+

### プロジェクト
```bash
cd /Users/yukihayashi/Documents/dev/projects/LightRoll_Cleaner/LightRoll_CleanerPackage
```

## テストファイル

### 1. ConcurrencyPerformanceTests.swift
**場所**: `Tests/LightRoll_CleanerFeatureTests/ImageAnalysis/ConcurrencyPerformanceTests.swift`

**含まれるテストスイート**:
- `ConcurrencyVerificationTests`: 並列実行検証
- `PerformanceTests`: パフォーマンス測定
- `ThreadSafetyTests`: スレッドセーフ性検証
- `IntegrationTests`: 総合検証

### 2. FeaturePrintExtractorConcurrencyTests.swift
**場所**: `Tests/LightRoll_CleanerFeatureTests/ImageAnalysis/FeaturePrintExtractorConcurrencyTests.swift`

**含まれるテストスイート**:
- `FeaturePrintExtractorConcurrencyTests`: FeaturePrintExtractor統合テスト
- `FeaturePrintExtractorRealDeviceTests`: 実機テスト（デフォルト無効）
- `ConcurrencyMeasurementTests`: 詳細測定

## テスト実行方法

### オプション1: 全テストを実行

```bash
swift test
```

### オプション2: 特定のテストスイートを実行

#### 並列実行検証テスト
```bash
swift test --filter ConcurrencyVerificationTests
```

**期待される出力**:
```
✅ 並列実行検証: ピーク同時実行数 = 8/12
✅ 高負荷並列実行検証: ピーク同時実行数 = 45/100
📊 並列度測定:
  - ピーク同時実行数: 8
  - 実行時間: 150 ms
  - 理論最小時間（完全並列）: 100 ms
  - 理論最大時間（完全直列）: 1200 ms
  - 実際の並列度: 8.00倍
```

#### パフォーマンステスト
```bash
swift test --filter PerformanceTests
```

**期待される出力**:
```
⚡️ パフォーマンス比較:
  - 直列実行時間: 600 ms
  - 並列実行時間: 105 ms
  - 高速化率: 5.71倍

📈 スケーラビリティ測定:
  - 4タスク: 直列=200ms, 並列=60ms, 高速化=3.33倍
  - 8タスク: 直列=400ms, 並列=90ms, 高速化=4.44倍
  - 16タスク: 直列=800ms, 並列=150ms, 高速化=5.33倍
  - 32タスク: 直列=1600ms, 並列=280ms, 高速化=5.71倍

✅ メモリ効率テスト完了: 5000タスク実行
```

#### スレッドセーフ性テスト
```bash
swift test --filter ThreadSafetyTests
```

**期待される出力**:
```
✅ スレッドセーフ性検証: 1000回のインクリメントが正確に完了
✅ 安定性テスト完了: 10回×100タスク実行
✅ エラーハンドリングテスト完了: 20タスク中10タスク成功
```

#### 総合検証テスト
```bash
swift test --filter IntegrationTests
```

**期待される出力**:
```
🏆 総合検証結果:
  ✓ 並列実行: ピーク同時実行数 = 8 (>= 4: 合格)
  ✓ パフォーマンス: 実行時間 = 150ms / 理論最大 = 600ms (合格)
  ✓ スレッドセーフ性: 実行数 = 12/12 (合格)
✅ 全ての検証項目に合格しました！
```

### オプション3: 特定のテストを実行

```bash
# 並列実行が正しく動作することを検証
swift test --filter verifyConcurrentExecution

# 5倍以上の高速化を検証
swift test --filter compareSerialVsParallel

# データ競合がないことを検証
swift test --filter testNoDataRace
```

## 実機テストの実行（オプション）

### 注意事項
- 実機テストはデフォルトで無効化されています
- フォトライブラリへのアクセス権限が必要です
- CI環境では実行できません

### 有効化手順

1. テストファイルを編集:
```swift
// FeaturePrintExtractorConcurrencyTests.swift

@Test("実機テスト - 実際のフォトライブラリで並列処理",
      .enabled(if: true, "実機でのみ実行")) // false → true に変更
func testRealPhotoLibrary() async throws {
    // ...
}
```

2. テストを実行:
```bash
swift test --filter FeaturePrintExtractorRealDeviceTests
```

3. フォトライブラリアクセスを許可:
- 初回実行時にアクセス許可のダイアログが表示されます
- 「許可」を選択してください

### 期待される出力
```
📸 実機テスト開始:
  - アセット数: 12

✅ 実機テスト完了:
  - 抽出成功: 12/12枚
  - 実行時間: 2340 ms
  - 平均処理時間: 195 ms/枚

  - 画像1: elementCount=2048, hashSize=8192 bytes
  - 画像2: elementCount=2048, hashSize=8192 bytes
  ...
```

## トラブルシューティング

### コンパイルエラーが発生する

**原因**: 既存のテストファイルにコンパイルエラーがある

**解決策1**: 並列実行テストのみをビルド
```bash
# 特定のテストファイルのみをビルド
swift build --target LightRoll_CleanerFeatureTests
```

**解決策2**: 既存のエラーを修正
- `DashboardEdgeCaseTests.swift` の Tag 競合を修正
- `RestorePurchasesViewTests.swift` のエラーを修正

### テストがスキップされる

**原因**: `.enabled(if: false)` で無効化されている

**解決策**: テストを有効化
```swift
.enabled(if: true, "コメント")
```

### フォトライブラリアクセスが拒否される

**原因**: アクセス権限が許可されていない

**解決策**:
1. システム設定を開く
2. 「プライバシーとセキュリティ」→「写真」
3. テストアプリケーションを許可

### 並列度が低い

**原因**: システムリソースが不足している

**解決策**:
1. 他のアプリケーションを終了
2. バックグラウンドタスクを停止
3. マシンを再起動

## パフォーマンス測定のベストプラクティス

### 1. 測定環境を整える
- ✅ 他のアプリケーションを終了
- ✅ バックグラウンドタスクを停止
- ✅ 電源に接続（バッテリー駆動は避ける）
- ✅ クリーンビルド状態で実行

### 2. 複数回測定して平均を取る
```bash
# 5回実行して平均を計算
for i in {1..5}; do
    echo "Run $i:"
    swift test --filter compareSerialVsParallel
done
```

### 3. 結果を記録する
- 実行時間
- ピーク同時実行数
- 高速化率
- マシンスペック（CPU, メモリ）

## 検証チェックリスト

### ✅ 並列実行の検証
- [ ] ピーク同時実行数 >= 4
- [ ] 全タスクが完了
- [ ] 並列度が理論値の30%以上

### ✅ パフォーマンスの検証
- [ ] 5倍以上の高速化
- [ ] スケーラビリティの確認
- [ ] メモリリークなし

### ✅ スレッドセーフ性の検証
- [ ] データ競合なし
- [ ] 複数回実行でクラッシュなし
- [ ] エラー発生時も安全

### ✅ 実機テスト（オプション）
- [ ] フォトライブラリから画像取得
- [ ] 並列抽出が動作
- [ ] 5秒以内に処理完了
- [ ] 平均500ms/枚未満

## レポート作成

### テスト実行後
以下の情報をレポートに記録してください:

1. **実行環境**
   - macOS バージョン
   - Xcode バージョン
   - CPU（M1/M2/M3、Intel）
   - メモリ容量

2. **テスト結果**
   - ピーク同時実行数
   - 実行時間
   - 高速化率
   - 合格/不合格

3. **観察事項**
   - 期待値との差異
   - 特記事項
   - 改善点

### レポートテンプレート
```markdown
# 並列実行テスト実行レポート

## 実行日時
YYYY-MM-DD HH:MM:SS

## 環境
- macOS: 15.x
- Xcode: 16.x
- CPU: M3 Pro
- メモリ: 32GB

## テスト結果

### 並列実行検証
- ピーク同時実行数: 8/12
- 判定: 合格（>= 4）

### パフォーマンス
- 直列実行時間: 600 ms
- 並列実行時間: 105 ms
- 高速化率: 5.71倍
- 判定: 合格（>= 5.0倍）

### スレッドセーフ性
- データ競合: なし
- 判定: 合格

## 総合評価
✅ 全ての検証項目に合格
```

## まとめ

### 実行コマンド一覧
```bash
# 全テスト
swift test

# 並列実行検証
swift test --filter ConcurrencyVerificationTests

# パフォーマンス
swift test --filter PerformanceTests

# スレッドセーフ性
swift test --filter ThreadSafetyTests

# 総合検証
swift test --filter IntegrationTests
```

### 期待される成功条件
- ✅ ピーク同時実行数 >= 4
- ✅ 高速化率 >= 5.0倍
- ✅ データ競合なし
- ✅ メモリリークなし

---

**作成者**: AI Assistant
**日付**: 2025-12-16
