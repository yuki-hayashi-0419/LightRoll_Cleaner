# LightRoll_Cleaner 開発進捗

## 最終更新: 2025-12-17

---

## 現在の問題状況

### 1. グループ化完了時のクラッシュ（未解決・最優先）
- **症状**: グループ化処理が完了した瞬間にアプリがクラッシュする
- **再現手順**: 分析 → グループ化 → 完了時にクラッシュ
- **調査方針**:
  - クラッシュログの取得
  - グループ化完了後の処理フローの確認
  - メモリ関連の問題の可能性

### 2. キャッシュ全件無効（次元数バグの後遺症）
- **症状**: キャッシュヒット率0%、全グループでキャッシュミス
- **原因**: 過去に保存されたキャッシュが768次元（3072バイト）で、修正後の2048次元（8192バイト）と不一致
- **対応**: 「分析」フェーズを再実行して正しいキャッシュを生成する必要あり
- **検討事項**: キャッシュクリア機能の実装

---

## 修正済みの問題

### LSH次元数バグ（2025-12-17 修正完了）

#### 問題の概要
LSH（Locality-Sensitive Hashing）が類似候補ペアを全く検出できず、グループ化の削減効果が0%だった。

#### 根本原因
`AnalysisRepository.swift`で`featurePrintHash`の抽出方法に誤りがあった：
- **誤**: `data.count`を使用 → 768次元（3072バイト）を取得
- **正**: `elementCount`を使用 → 2048次元（8192バイト）を取得

VNFeaturePrintObservationのdataプロパティは内部フォーマットで768要素、
実際の特徴量は`elementCount`で取得する2048要素が正しい。

#### 修正内容

**AnalysisRepository.swift**
```swift
// 修正前（誤り）
let featurePrintHash = featurePrint.data

// 修正後（正しい）
var floatArray = [Float](repeating: 0, count: featurePrint.elementCount)
floatArray.withUnsafeMutableBufferPointer { buffer in
    featurePrint.copyElement(to: buffer)
}
let featurePrintHash = Data(bytes: floatArray, count: floatArray.count * MemoryLayout<Float>.size)
```

**SimilarityAnalyzer.swift - キャッシュサイズ検証追加**
```swift
// VNFeaturePrintObservation の正しいサイズ: 2048次元 × 4バイト（Float）= 8192バイト
let expectedFeaturePrintHashSize = 2048 * MemoryLayout<Float>.size  // 8192

for asset in assets {
    if let result = await cacheManager.loadResult(for: asset.localIdentifier),
       let hash = result.featurePrintHash,
       hash.count == expectedFeaturePrintHashSize {
        // 有効なキャッシュ
        cachedFeatures.append((id: asset.localIdentifier, hash: hash))
    } else {
        // 無効なキャッシュ → 再抽出対象
        uncachedAssets.append(asset)
    }
}
```

**SimilarityAnalyzer.swift - 再抽出スキップ最適化**
```swift
// グループ化フェーズでの再抽出は非常に遅いため、スキップ
if !uncachedAssets.isEmpty {
    logWarning("⚠️ キャッシュなし/無効: \(uncachedAssets.count)枚 - グループ化から除外", category: .analysis)
    // 再抽出せず、キャッシュのある写真のみでグループ化を実行
}
```

---

## アーキテクチャメモ

### 類似画像グループ化のフロー

```
1. TimeBasedGrouper: 写真を24時間ウィンドウで事前グループ化
   └── 7000枚 → 約855グループ（平均8枚/グループ）

2. LSHHasher: 各グループ内でLSHハッシュを計算
   └── 特徴量ハッシュ（Data, 8192バイト）→ LSHハッシュ（UInt64）

3. SimilarityCalculator: LSH候補ペアのコサイン類似度を計算
   └── 候補ペアのみ比較（O(n²) → O(n)に削減）

4. グループ統合: 類似度が閾値以上のペアをグループ化
```

### 重要なファイル

| ファイル | 役割 |
|----------|------|
| `SimilarityAnalyzer.swift` | グループ化の全体制御、キャッシュ読み込み |
| `LSHHasher.swift` | LSHハッシュ計算、候補ペア検出 |
| `SimilarityCalculator.swift` | コサイン類似度計算 |
| `AnalysisRepository.swift` | 特徴量抽出、キャッシュ保存 |
| `TimeBasedGrouper.swift` | 時間ベースの事前グループ化 |

### 特徴量の仕様

- **VNFeaturePrintObservation**
  - `elementCount`: 2048（正しい次元数）
  - `elementType`: Float
  - 合計サイズ: 2048 × 4 = 8192バイト

- **LSHHasher設定**
  - ビット数: 64
  - シード: 42（再現性確保）
  - マルチプローブ: 4テーブル

---

## 次回セッションのタスク

1. **最優先**: グループ化完了時のクラッシュ原因調査
   - Xcodeデバッガでクラッシュスタックトレース取得
   - メモリ使用量の監視
   - 完了後の処理フロー確認

2. **高優先**: キャッシュ再生成の検証
   - 分析フェーズで正しい8192バイトキャッシュが生成されるか確認
   - 分析 → グループ化のフルフロー検証

3. **中優先**: キャッシュクリア機能の実装検討
   - 古い無効キャッシュを一括削除する機能

4. **低優先**: さらなるパフォーマンス改善
   - グループ化の並列処理
   - プログレス表示の改善

---

## 関連ナレッジ

### ERR-001: LSH次元数不一致
- **発生日**: 2025-12-17
- **症状**: LSH候補ペア検出0件、削減効果0%
- **原因**: featurePrintHash抽出で`data.count`(768)を使用、正しくは`elementCount`(2048)
- **解決策**: `copyElement(to:)`で正しく2048要素を抽出

### ERR-002: グループ化の速度低下
- **発生日**: 2025-12-17
- **症状**: グループ化が完了しない（非常に遅い）
- **原因**: キャッシュミス時にO(n²)のフォールバック処理が実行される
- **解決策**: グループ化フェーズでは再抽出をスキップし、キャッシュのある写真のみ処理
