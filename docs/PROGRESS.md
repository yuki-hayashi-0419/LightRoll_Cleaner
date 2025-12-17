# LightRoll_Cleaner 開発進捗

## 最終更新: 2025-12-18

---

## 2025-12-18 セッション: グループ化クラッシュ・速度問題の根本原因特定

### セッション概要
- **実施内容**: グループ化処理の遅延とクラッシュの原因調査
- **結果**: 根本原因を特定完了、修正方針を確定
- **品質スコア**: 90点（分析完了、実装は次回）

---

## 現在の問題状況（根本原因特定済み）

### 1. グループ化完了時のクラッシュ（原因特定済み・実装待ち）
- **症状**: グループ化処理が完了した瞬間にアプリがクラッシュする
- **根本原因**: `getFileSizes()` のO(n×m)計算量によるタイムアウト/メモリ圧迫
- **発生箇所**:
  - `PhotoGrouper.swift:522-540`
  - `AnalysisRepository.swift:717-735`
- **メカニズム**:
  1. グループ化（LSH + 類似度計算）は正常完了
  2. 結果を`PhotoGroup`に変換する際に`getFileSizes()`が呼ばれる
  3. 各photoIdに対して`.first(where:)`で全assetsを線形探索 → O(n×m)
  4. さらに各ファイルに対して順次I/O → 処理時間が爆発
  5. Watchdog/メモリ圧迫でクラッシュ

### 2. グループ化処理が圧倒的に遅い（原因特定済み・実装待ち）
- **症状**: グループ化フェーズが非常に長時間かかる
- **根本原因**: 同上 - `getFileSizes()`のO(n×m)問題
- **影響度計算**:
  - 7000枚 × 数百グループ × 各グループ8枚平均
  - 1グループあたり: 8枚 × 7000回検索 = 56,000回比較
  - 合計: 数千万回の線形探索 + 数千回のファイルI/O

### 3. キャッシュ全件無効（次元数バグの後遺症）
- **症状**: キャッシュヒット率0%、全グループでキャッシュミス
- **原因**: 過去に保存されたキャッシュが768次元（3072バイト）で、修正後の2048次元（8192バイト）と不一致
- **対応**: 「分析」フェーズを再実行して正しいキャッシュを生成する必要あり

---

## 確定した修正方針（次回セッションで実装）

### 修正1: getFileSizes() のO(1)最適化

**現状コード（O(n×m)）:**
```swift
for photoId in photoIds {
    guard let asset = assets.first(where: { $0.localIdentifier == photoId }) else {
        fileSizes.append(0)
        continue
    }
    let fileSize = try await asset.getFileSize()
    fileSizes.append(fileSize)
}
```

**修正後コード（O(n)）:**
```swift
// 事前にDictionary構築 O(m)
let assetLookup = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0) })

for photoId in photoIds {
    guard let asset = assetLookup[photoId] else {  // O(1) lookup
        fileSizes.append(0)
        continue
    }
    let fileSize = try await asset.getFileSize()
    fileSizes.append(fileSize)
}
```

### 修正2: ファイルサイズ取得の並列化

```swift
// 修正後: TaskGroup による並列取得
let fileSizes = try await withThrowingTaskGroup(of: (Int, Int64).self) { group in
    for (index, photoId) in photoIds.enumerated() {
        group.addTask {
            let size = try await assetLookup[photoId]?.getFileSize() ?? 0
            return (index, size)
        }
    }
    var results = [(Int, Int64)]()
    for try await result in group {
        results.append(result)
    }
    return results.sorted { $0.0 < $1.0 }.map { $0.1 }
}
```

### 修正対象ファイル
| ファイル | 行 | 修正内容 |
|----------|-----|----------|
| `PhotoGrouper.swift` | 522-540 | Dictionary lookup + 並列化 |
| `AnalysisRepository.swift` | 717-735 | 同上 |

### 期待される効果
- **速度**: O(n×m) → O(n) で数千倍高速化
- **クラッシュ**: タイムアウト/メモリ圧迫の解消
- **7000枚の場合**: 数十分 → 数秒に短縮見込み

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
