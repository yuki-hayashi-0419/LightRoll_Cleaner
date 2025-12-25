# Phase 1 実装ガイド（クイック修正）

## 概要

| 項目 | 値 |
|------|-----|
| 期間 | Day 1-5 |
| 目標改善率 | 50%（60-80分 → 30-40分） |
| 対象施策 | A1, A2, A3, A4 |
| 作成日 | 2025-12-25 |
| 作成者 | @spec-architect |

---

## A1: groupDuplicates 並列化

### A1-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| PhotoGrouper.swift | `groupDuplicates(_:)` | 505-554 |

#### 現状の問題

```
現在のデータフロー:
imageAssets → for asset in imageAssets → getFileSize() → sizeGroups構築
                     ↓（逐次処理）
              asset 1 → getFileSize() → 完了
              asset 2 → getFileSize() → 完了
              asset 3 → getFileSize() → 完了
              ...
              asset n → getFileSize() → 完了

問題点:
- 100,000枚の場合、100,000回の逐次I/O操作
- 各getFileSize()が50-100msかかる場合、合計5,000-10,000秒（83-166分）
```

#### 変更後のデータフロー

```
変更後のデータフロー:
imageAssets → TaskGroup (並列処理) → sizeGroups構築
                     ↓
              ┌─ batch 1 (500枚) → 並列 getFileSize() → 完了
              ├─ batch 2 (500枚) → 並列 getFileSize() → 完了
              ├─ batch 3 (500枚) → 並列 getFileSize() → 完了
              └─ ...

改善点:
- バッチ単位で並列処理（メモリ制御付き）
- 500枚並列 × 200バッチ = 合計処理時間 200 × 100ms = 20秒
- 理論上最大 15% 改善
```

#### エッジケース

| ケース | 対応方針 |
|--------|----------|
| 空の配列 | 早期リターン（既存動作維持） |
| 画像が1枚のみ | 早期リターン（既存動作維持） |
| 一部のgetFileSizeが失敗 | 失敗したアセットはスキップ、ログ出力 |
| メモリ警告発生 | バッチサイズを動的に縮小 |
| キャンセル要求 | 処理中のバッチ完了後に中断 |

---

### A1-2: 実装手順

#### Step 1: バッチ処理ヘルパー関数の追加

```swift
// 擬似コード: PhotoGrouper.swift に追加

/// バッチ単位でファイルサイズを並列取得
/// - Parameters:
///   - assets: 対象アセット配列
///   - batchSize: 1バッチあたりの処理数（デフォルト: 500）
/// - Returns: (localIdentifier, fileSize) のタプル配列
private func getFileSizesInBatches(
    _ assets: [PHAsset],
    batchSize: Int = 500
) async throws -> [(id: String, size: Int64)] {
    var results: [(id: String, size: Int64)] = []
    results.reserveCapacity(assets.count)

    // バッチ分割
    let batches = assets.chunked(into: batchSize)

    for batch in batches {
        // 1バッチを並列処理
        let batchResults = try await withThrowingTaskGroup(of: (String, Int64)?.self) { group in
            for asset in batch {
                group.addTask { @Sendable in
                    do {
                        let size = try await asset.getFileSize()
                        return (asset.localIdentifier, size)
                    } catch {
                        // 失敗時はnilを返す（スキップ）
                        logWarning("ファイルサイズ取得失敗: \(asset.localIdentifier)")
                        return nil
                    }
                }
            }

            var collected: [(String, Int64)] = []
            for try await result in group {
                if let r = result {
                    collected.append(r)
                }
            }
            return collected
        }

        results.append(contentsOf: batchResults)

        // キャンセルチェック
        try Task.checkCancellation()
    }

    return results
}
```

**テストポイント 1**: バッチ分割が正しく動作することを確認

#### Step 2: groupDuplicates のリファクタリング

```swift
// 擬似コード: 変更後の groupDuplicates

public func groupDuplicates(_ assets: [PHAsset]) async throws -> [PhotoGroup] {
    let imageAssets = assets.filter { $0.mediaType == .image }
    guard imageAssets.count >= 2 else { return [] }

    // Step 1: 並列でファイルサイズを取得
    let fileSizeResults = try await getFileSizesInBatches(imageAssets)

    // Step 2: ファイルサイズ + ピクセルサイズでグルーピング
    // fileSizeResults を Dictionary に変換
    let sizeMap = Dictionary(uniqueKeysWithValues: fileSizeResults)

    var sizeGroups: [String: [PHAsset]] = [:]
    for asset in imageAssets {
        guard let fileSize = sizeMap[asset.localIdentifier] else { continue }
        let keyString = "\(fileSize)_\(asset.pixelWidth)_\(asset.pixelHeight)"
        sizeGroups[keyString, default: []].append(asset)
    }

    // Step 3: 重複グループを生成
    var duplicateGroups: [PhotoGroup] = []
    for (_, assetsInGroup) in sizeGroups where assetsInGroup.count >= 2 {
        let photoIds = assetsInGroup.map { $0.localIdentifier }
        let fileSizes = photoIds.compactMap { sizeMap[$0] }

        let photoGroup = PhotoGroup(
            type: .duplicate,
            photoIds: photoIds,
            fileSizes: fileSizes,
            similarityScore: 1.0
        )
        duplicateGroups.append(photoGroup)
    }

    return duplicateGroups
}
```

**テストポイント 2**: 既存の動作と結果が一致することを確認

#### Step 3: Array.chunked 拡張の追加

```swift
// 擬似コード: Array+Extensions.swift

extension Array {
    /// 配列を指定サイズのチャンクに分割
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

**テストポイント 3**: chunked関数の単体テスト

---

### A1-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| PhotoGrouper.swift | 高 | groupDuplicates 変更 |
| Array+Extensions.swift | 低 | chunked 拡張追加（新規） |
| PhotoGrouperTests.swift | 中 | テストケース追加 |

#### 依存関係

```
groupDuplicates (変更)
    ↓ 呼び出し元
groupPhotos(_:progress:)
    ↓ 呼び出し元
AnalysisRepository.analyzePhotos()
    ↓ 呼び出し元
PhotoLibraryViewModel
```

#### 破壊的変更

- **なし**: 戻り値の型・形式は同一
- **なし**: パブリックAPI変更なし

#### マイグレーション

- **不要**: 内部実装の変更のみ

---

### A1-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| A1-UT-01 | 空配列の処理 | 空配列を返す |
| A1-UT-02 | 1枚のみの処理 | 空配列を返す |
| A1-UT-03 | 2枚同サイズの処理 | 1グループ返す |
| A1-UT-04 | 100枚混合サイズの処理 | 正しいグループ数 |
| A1-UT-05 | バッチ境界（500枚）の処理 | 正常完了 |
| A1-UT-06 | バッチ超過（1000枚）の処理 | 正常完了 |
| A1-UT-07 | キャンセル時の処理 | CancellationError |
| A1-UT-08 | 一部失敗時の処理 | 成功分のみ返す |

#### 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| A1-IT-01 | groupPhotos経由での呼び出し | 既存動作と同一 |
| A1-IT-02 | 実デバイスでの処理 | クラッシュなし |
| A1-IT-03 | メモリ使用量測定 | ピーク2GB未満 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| A1-PT-01 | 1,000枚の処理時間 | 旧実装比 -10% 以上 |
| A1-PT-02 | 10,000枚の処理時間 | 旧実装比 -15% 以上 |
| A1-PT-03 | 100,000枚の処理時間 | 旧実装比 -15% 以上 |

---

### A1-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| 並列処理によるメモリ枯渇 | 高 | 中 | バッチサイズ動的調整、メモリ警告監視 |
| 並列処理によるクラッシュ | 高 | 低 | TaskGroupの適切なエラーハンドリング |
| 処理結果の順序不整合 | 中 | 低 | 明示的なソート実装 |
| パフォーマンス改善が期待未満 | 低 | 中 | A4と組み合わせて効果測定 |

#### ロールバック手順

1. `groupDuplicates` を旧実装に戻す
2. `chunked` 拡張は残しても問題なし
3. テストで旧動作を確認

---

## A2: groupLargeVideos 並列化

### A2-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| PhotoGrouper.swift | `groupLargeVideos(_:progressRange:progress:)` | 453-498 |

#### 現状の問題

```
現在のデータフロー:
videoAssets → for asset in videoAssets → getFileSize() → 閾値判定
                     ↓（逐次処理）
              video 1 → getFileSize() → 閾値判定
              video 2 → getFileSize() → 閾値判定
              ...

問題点:
- 動画ファイルは大きいため I/O コストが高い
- 進捗通知が逐次的（UX 改善の余地）
```

#### 変更後のデータフロー

```
変更後:
videoAssets → TaskGroup (並列) → 閾値判定 → PhotoGroup生成
                 ↓
         ┌─ batch 1 → 並列 getFileSize()
         ├─ batch 2 → 並列 getFileSize()
         └─ ...

※ 進捗通知はバッチ完了ごとに更新
```

#### エッジケース

| ケース | 対応方針 |
|--------|----------|
| 動画が0件 | 早期リターン（既存動作維持） |
| 全動画が閾値未満 | 空配列を返す |
| 一部の getFileSize 失敗 | 失敗分はスキップ |
| 進捗コールバックが nil | 進捗通知をスキップ |

---

### A2-2: 実装手順

#### Step 1: 並列処理への変更

```swift
// 擬似コード: 変更後の groupLargeVideos

public func groupLargeVideos(
    _ assets: [PHAsset],
    progressRange: (start: Double, end: Double) = (0.0, 1.0),
    progress: (@Sendable (Double) async -> Void)? = nil
) async throws -> [PhotoGroup] {
    let videoAssets = assets.filter { $0.mediaType == .video }
    guard !videoAssets.isEmpty else { return [] }

    await progress?(progressRange.start)

    // A1で追加した getFileSizesInBatches を再利用
    let fileSizeResults = try await getFileSizesInBatches(videoAssets, batchSize: 100)

    // 閾値以上の動画を抽出
    let largeVideoData = fileSizeResults.filter { $0.size >= options.largeVideoThreshold }

    await progress?(progressRange.end)

    guard !largeVideoData.isEmpty else { return [] }

    let photoGroup = PhotoGroup(
        type: .largeVideo,
        photoIds: largeVideoData.map { $0.id },
        fileSizes: largeVideoData.map { $0.size }
    )

    return [photoGroup]
}
```

**テストポイント**: 閾値判定が正しく動作することを確認

#### Step 2: 進捗通知の改善（オプション）

```swift
// 擬似コード: バッチごとの進捗通知

// getFileSizesInBatches に進捗コールバックを追加
private func getFileSizesInBatches(
    _ assets: [PHAsset],
    batchSize: Int = 500,
    progress: (@Sendable (Double) async -> Void)? = nil
) async throws -> [(id: String, size: Int64)] {
    // ... 既存実装 ...

    for (batchIndex, batch) in batches.enumerated() {
        // バッチ処理
        // ...

        // 進捗通知
        let currentProgress = Double(batchIndex + 1) / Double(batches.count)
        await progress?(currentProgress)
    }

    // ...
}
```

---

### A2-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| PhotoGrouper.swift | 中 | groupLargeVideos 変更 |
| PhotoGrouperTests.swift | 中 | テストケース追加 |

#### 依存関係

```
groupLargeVideos (変更)
    ↓ 呼び出し元
groupPhotos(_:progress:)
    ↓
（A1と同じ呼び出しチェーン）
```

#### 破壊的変更・マイグレーション

- **なし**

---

### A2-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| A2-UT-01 | 動画0件の処理 | 空配列を返す |
| A2-UT-02 | 全動画が閾値未満 | 空配列を返す |
| A2-UT-03 | 1動画が閾値以上 | 1グループ返す |
| A2-UT-04 | 混合サイズの処理 | 閾値以上のみ含む |
| A2-UT-05 | 進捗コールバック確認 | 正しい進捗値 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| A2-PT-01 | 100動画の処理時間 | 旧実装比 -5% 以上 |
| A2-PT-02 | 1,000動画の処理時間 | 旧実装比 -5% 以上 |

---

### A2-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| 動画ファイル読み込みのメモリ消費 | 中 | 中 | バッチサイズを100に制限 |
| 進捗通知の精度低下 | 低 | 低 | バッチ完了ごとの通知で許容 |

---

## A3: getFileSizes バッチ制限

### A3-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| PhotoGrouper.swift | `getFileSizes(for:from:)` | 584-606 |

#### 現状の問題

```
現在の実装:
- TaskGroup で全photoIds を並列処理
- photoIds が 10,000 件の場合、10,000 個のタスクが同時生成
- メモリ消費が急増、I/O 競合が発生
```

#### 変更方針

```
変更後:
- バッチサイズ（デフォルト 500）でタスク数を制限
- 1バッチ完了後に次のバッチを開始
- メモリ使用量を安定化
```

---

### A3-2: 実装手順

#### Step 1: 既存 getFileSizes のリファクタリング

```swift
// 擬似コード: 変更後の getFileSizes

private func getFileSizes(
    for photoIds: [String],
    from assets: [PHAsset],
    batchSize: Int = 500
) async throws -> [Int64] {
    let assetLookup = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0) })

    var results: [(Int, Int64)] = []
    results.reserveCapacity(photoIds.count)

    // バッチ分割してインデックス付きで処理
    for batchStart in stride(from: 0, to: photoIds.count, by: batchSize) {
        let batchEnd = min(batchStart + batchSize, photoIds.count)
        let batchIds = Array(photoIds[batchStart..<batchEnd])

        let batchResults = try await withThrowingTaskGroup(of: (Int, Int64).self) { group in
            for (localIndex, photoId) in batchIds.enumerated() {
                let globalIndex = batchStart + localIndex
                group.addTask { @Sendable in
                    let size = try await assetLookup[photoId]?.getFileSize() ?? 0
                    return (globalIndex, size)
                }
            }

            var collected: [(Int, Int64)] = []
            for try await result in group {
                collected.append(result)
            }
            return collected
        }

        results.append(contentsOf: batchResults)

        // キャンセルチェック
        try Task.checkCancellation()
    }

    return results.sorted { $0.0 < $1.0 }.map { $0.1 }
}
```

---

### A3-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| PhotoGrouper.swift | 中 | getFileSizes 変更 |

#### 依存関係

```
getFileSizes (変更)
    ↓ 呼び出し元
groupDuplicates (A1で変更済みの場合、影響軽微)
groupSimilarPhotos
groupBlurryPhotos
```

**注意**: A1 の変更で `getFileSizes` の呼び出しパターンが変わる場合、A3 の変更は A1 完了後に適用

---

### A3-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| A3-UT-01 | 空配列の処理 | 空配列を返す |
| A3-UT-02 | 500件未満の処理 | 1バッチで完了 |
| A3-UT-03 | 500件ちょうどの処理 | 1バッチで完了 |
| A3-UT-04 | 501件の処理 | 2バッチで完了 |
| A3-UT-05 | 結果順序の確認 | photoIds と同順序 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| A3-PT-01 | メモリ使用量測定（10,000件） | ピーク1GB未満 |
| A3-PT-02 | 処理時間測定（10,000件） | 旧実装と同等以上 |

---

### A3-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| バッチ化による処理時間増加 | 低 | 中 | ベンチマーク測定で検証 |
| 順序保証の破綻 | 中 | 低 | 明示的ソートで対応 |

---

## A4: estimatedFileSize 優先使用

### A4-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| PHAsset+Extensions.swift | `getFileSize()` | 90-121 |
| PHAsset+Extensions.swift | `estimatedFileSize` | 125-131 |
| PhotoGrouper.swift | 各 getFileSize 呼び出し箇所 | 複数 |

#### 現状の問題

```
現在の getFileSize() フロー:
1. キャッシュチェック
2. PHAssetResource.assetResources 取得
3. resource.value(forKey: "fileSize") 試行（高速）
4. 失敗時 → PHAssetResourceManager でデータ読み込み（低速、I/O コスト大）

問題点:
- Step 4 のフォールバックが頻繁に発生
- 特に iCloud 写真で発生しやすい
```

#### 変更方針

```
変更後のフロー:
1. estimatedFileSize を先に試行（同期、超高速）
2. 成功 → その値を使用（精度は ±5% 程度）
3. 失敗 → 従来の getFileSize() にフォールバック

用途別使い分け:
- 重複判定: 高精度必要 → getFileSize() 維持
- 大容量検出: ±5% 許容 → estimatedFileSize 優先
- 類似グループ表示: ±5% 許容 → estimatedFileSize 優先
```

---

### A4-2: 実装手順

#### Step 1: 高速ファイルサイズ取得メソッド追加

```swift
// 擬似コード: PHAsset+Extensions.swift に追加

/// 高速なファイルサイズ取得（推定値優先）
/// - Parameter fallbackToActual: 推定値取得失敗時に実際のサイズを取得するか
/// - Returns: ファイルサイズ（バイト）
public func getFileSizeFast(fallbackToActual: Bool = true) async throws -> Int64 {
    // Step 1: 推定値を試行（同期、超高速）
    if let estimated = estimatedFileSize, estimated > 0 {
        return estimated
    }

    // Step 2: フォールバック
    if fallbackToActual {
        return try await getFileSize()
    }

    return 0
}
```

#### Step 2: groupLargeVideos での使用

```swift
// 擬似コード: groupLargeVideos 内で getFileSizeFast を使用

// 閾値判定では推定値で十分
let fileSize = try await asset.getFileSizeFast()
```

#### Step 3: 類似グループ表示での使用

```swift
// 擬似コード: groupSimilarPhotos 等で使用

// 表示用ファイルサイズは推定値で十分
let displaySize = try await asset.getFileSizeFast()
```

#### Step 4: groupDuplicates は従来通り

```swift
// 重複判定は高精度必要 → 従来の getFileSize() を維持
let fileSize = try await asset.getFileSize()
```

---

### A4-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| PHAsset+Extensions.swift | 中 | getFileSizeFast 追加 |
| PhotoGrouper.swift | 中 | 呼び出し箇所を選択的に変更 |

#### 精度影響

| 用途 | 推定値使用 | 精度影響 |
|------|-----------|----------|
| 重複検出 | 不可 | 誤判定リスク |
| 大容量判定 | 可 | ±5%（許容範囲） |
| 表示用サイズ | 可 | ±5%（許容範囲） |
| 削減容量計算 | 要注意 | 累積誤差の可能性 |

---

### A4-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| A4-UT-01 | estimatedFileSize 取得成功 | 推定値を返す |
| A4-UT-02 | estimatedFileSize 取得失敗 | getFileSize にフォールバック |
| A4-UT-03 | estimatedFileSize が 0 | フォールバック |
| A4-UT-04 | fallbackToActual = false | 0 を返す |

#### 精度テスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| A4-AC-01 | 推定値と実測値の差異 | 95% のアセットで ±10% 以内 |
| A4-AC-02 | iCloud 写真での動作 | 正常動作 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| A4-PT-01 | 1,000枚の処理時間 | 旧実装比 -20% 以上 |
| A4-PT-02 | 10,000枚の処理時間 | 旧実装比 -20% 以上 |

---

### A4-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| 推定値の精度不足 | 中 | 高 | 用途別に使い分け、精度テスト実施 |
| iCloud 写真での動作不良 | 高 | 中 | 事前テスト、フォールバック確保 |
| 累積誤差による削減容量ずれ | 低 | 中 | 最終計算時は実測値使用 |

#### ロールバック手順

1. `getFileSizeFast` 呼び出しを `getFileSize` に戻す
2. `getFileSizeFast` メソッド自体は残しても問題なし

---

## Phase 1 統合テスト計画

### P1-INT: 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| P1-INT-01 | A1-A4 全適用後の groupPhotos | 既存動作と同一結果 |
| P1-INT-02 | 10,000枚での E2E テスト | 正常完了 |
| P1-INT-03 | 100,000枚での E2E テスト | 正常完了、30-40分以内 |
| P1-INT-04 | キャンセル動作 | 即座に中断 |
| P1-INT-05 | メモリリーク検証 | リーク検出なし |

### P1-PERF: パフォーマンス計測

| 計測項目 | 計測方法 | 目標値 |
|----------|----------|--------|
| 処理時間（100,000枚） | Instruments / Time Profiler | 30-40分 |
| ピークメモリ使用量 | Instruments / Allocations | 2GB未満 |
| CPU 使用率 | Instruments / Activity Monitor | 安定動作 |
| I/O 待機時間 | Instruments / System Trace | 現状比 -30% |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 1.0 | 2025-12-25 | 初版作成 |
