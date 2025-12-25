# Phase 2 実装ガイド（中規模改善）

## 概要

| 項目 | 値 |
|------|-----|
| 期間 | Day 6-15 |
| 目標改善率 | 追加30%（30-40分 → 15-20分） |
| 対象施策 | B1, B2, B3, B4 |
| 前提条件 | Phase 1 完了 |
| 作成日 | 2025-12-25 |
| 作成者 | @spec-architect |

---

## B1: PhotoAnalysisResult への fileSize 統合

### B1-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 | 変更種別 |
|----------|--------------|--------|----------|
| PhotoAnalysisResult.swift | struct 定義 | 18-99 | プロパティ追加 |
| PhotoAnalysisResult.swift | init | 69-99 | パラメータ追加 |
| PhotoAnalysisResult.swift | Builder | 398-512 | メソッド追加 |
| AnalysisCacheManager.swift | saveResult/loadResult | 84-160 | 変更なし（Codable） |
| PhotoGrouper.swift | 各グループ化メソッド | 複数 | キャッシュ活用 |
| SimilarityAnalyzer.swift | findSimilarGroupsInTimeGroup | 264-365 | キャッシュ活用 |

#### 現状の問題

```
現在のデータフロー:
PhotoAnalysisResult（キャッシュ済み）
    ↓ 類似グループ検出
findSimilarGroupsInTimeGroup
    ↓ グループ化
PhotoGroup 生成
    ↓ ファイルサイズ取得
getFileSizes() ← 毎回 PHAsset I/O が発生！

問題点:
- 分析結果にファイルサイズがないため、表示時に再取得が必要
- 100,000枚 × 複数回参照 = 大量の重複 I/O
```

#### 変更後のデータフロー

```
変更後:
分析時に fileSize も取得 → PhotoAnalysisResult に保存
    ↓
キャッシュ読み込み時に fileSize も復元
    ↓
グループ化時にキャッシュから fileSize 取得（I/O 不要）

メリット:
- 2回目以降のファイルサイズ取得が完全にキャッシュヒット
- 分析済み写真は I/O ゼロでグループ化可能
```

#### スキーマ変更

```swift
// 変更前
public struct PhotoAnalysisResult {
    public let id: String
    public let photoId: String
    public let analyzedAt: Date
    public let qualityScore: Float
    public let blurScore: Float
    // ... 他のプロパティ
    public let featurePrintHash: Data?
}

// 変更後
public struct PhotoAnalysisResult {
    public let id: String
    public let photoId: String
    public let analyzedAt: Date
    public let qualityScore: Float
    public let blurScore: Float
    // ... 他のプロパティ
    public let featurePrintHash: Data?
    public let fileSize: Int64?  // 新規追加
}
```

#### エッジケース

| ケース | 対応方針 |
|--------|----------|
| 既存キャッシュに fileSize がない | nil として扱い、必要時に取得 |
| fileSize 取得失敗 | nil を保存、フォールバックで再取得 |
| iCloud 写真で fileSize 不明 | nil を保存、オンデマンドで取得 |
| キャッシュサイズの増加 | 1件あたり +8バイト（Int64）、影響軽微 |

---

### B1-2: 実装手順

#### Step 1: PhotoAnalysisResult への fileSize プロパティ追加

```swift
// 擬似コード: PhotoAnalysisResult.swift

public struct PhotoAnalysisResult: Identifiable, Hashable, Sendable, Codable {
    // 既存プロパティ...

    /// ファイルサイズ（バイト）、取得できない場合は nil
    public let fileSize: Int64?

    public init(
        id: String = UUID().uuidString,
        photoId: String,
        analyzedAt: Date = Date(),
        qualityScore: Float = 0.5,
        blurScore: Float = 0.2,
        brightnessScore: Float = 0.5,
        contrastScore: Float = 0.5,
        saturationScore: Float = 0.5,
        faceCount: Int = 0,
        faceQualityScores: [Float] = [],
        faceAngles: [FaceAngle] = [],
        isScreenshot: Bool = false,
        isSelfie: Bool = false,
        featurePrintHash: Data? = nil,
        fileSize: Int64? = nil  // 新規追加
    ) {
        // 既存の初期化...
        self.fileSize = fileSize
    }
}
```

**テストポイント 1**: Codable エンコード/デコードが正常動作することを確認

#### Step 2: Builder パターンへの追加

```swift
// 擬似コード: PhotoAnalysisResult.Builder

extension PhotoAnalysisResult {
    public final class Builder {
        // 既存プロパティ...
        private var fileSize: Int64?

        public func setFileSize(_ size: Int64?) -> Builder {
            self.fileSize = size
            return self
        }

        public func build() -> PhotoAnalysisResult {
            PhotoAnalysisResult(
                // 既存パラメータ...
                fileSize: fileSize
            )
        }
    }
}
```

**テストポイント 2**: Builder で fileSize が設定できることを確認

#### Step 3: 分析時の fileSize 取得

```swift
// 擬似コード: PhotoAnalyzer での変更

public func analyze(_ asset: PHAsset) async throws -> PhotoAnalysisResult {
    // 既存の分析処理...

    // ファイルサイズを取得（A4 の getFileSizeFast を使用）
    let fileSize: Int64? = try? await asset.getFileSizeFast()

    return PhotoAnalysisResult.Builder()
        .setPhotoId(asset.localIdentifier)
        // 既存の設定...
        .setFileSize(fileSize)
        .build()
}
```

**テストポイント 3**: 分析結果に fileSize が含まれることを確認

#### Step 4: キャッシュ読み込み時の互換性対応

```swift
// 擬似コード: AnalysisCacheManager

// Codable の CodingKeys で optional を明示
extension PhotoAnalysisResult {
    enum CodingKeys: String, CodingKey {
        case id, photoId, analyzedAt, qualityScore, blurScore
        // ... 他のキー
        case fileSize  // optional として自動処理
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 既存のデコード...

        // fileSize は optional なので、存在しなければ nil
        self.fileSize = try container.decodeIfPresent(Int64.self, forKey: .fileSize)
    }
}
```

**テストポイント 4**: 旧フォーマットのキャッシュが正常に読み込めることを確認

#### Step 5: グループ化ロジックでのキャッシュ活用

```swift
// 擬似コード: PhotoGrouper での変更

private func getFileSizesFromCache(
    for photoIds: [String],
    cachedResults: [String: PhotoAnalysisResult]
) -> [Int64?] {
    return photoIds.map { photoId in
        cachedResults[photoId]?.fileSize
    }
}

// groupSimilarPhotos 等で使用
public func groupSimilarPhotos(
    _ assets: [PHAsset],
    cachedResults: [String: PhotoAnalysisResult]? = nil,  // キャッシュを受け取る
    progressRange: (start: Double, end: Double),
    progress: (@Sendable (Double) async -> Void)?
) async throws -> [PhotoGroup] {
    // ...

    // キャッシュからファイルサイズを取得（キャッシュミスのみ I/O）
    let fileSizes: [Int64]
    if let cache = cachedResults {
        let cached = getFileSizesFromCache(for: photoIds, cachedResults: cache)
        // nil がある場合のみフォールバック
        if cached.contains(where: { $0 == nil }) {
            fileSizes = try await getFileSizes(for: photoIds, from: assets)
        } else {
            fileSizes = cached.compactMap { $0 }
        }
    } else {
        fileSizes = try await getFileSizes(for: photoIds, from: assets)
    }

    // ...
}
```

**テストポイント 5**: キャッシュヒット時に I/O が発生しないことを確認

---

### B1-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| PhotoAnalysisResult.swift | 高 | fileSize プロパティ追加 |
| PhotoAnalyzer.swift | 中 | 分析時に fileSize 取得 |
| PhotoGrouper.swift | 中 | キャッシュ活用ロジック追加 |
| SimilarityAnalyzer.swift | 中 | キャッシュ活用ロジック追加 |
| AnalysisRepository.swift | 低 | キャッシュ受け渡し調整 |
| PhotoAnalysisResultTests.swift | 中 | テストケース追加 |

#### 依存関係図

```
PhotoAnalysisResult (変更)
    ↓ 使用箇所
├── PhotoAnalyzer（分析結果生成）
├── AnalysisCacheManager（永続化）
├── PhotoGrouper（グループ化）
├── SimilarityAnalyzer（類似検出）
└── AnalysisRepository（統合調整）
```

#### 破壊的変更

- **API互換性**: 維持（Optional パラメータ追加のため）
- **キャッシュ互換性**: 維持（Codable の decodeIfPresent で対応）

#### マイグレーション

```swift
// 擬似コード: 必要に応じてキャッシュを更新するマイグレーション

public actor CacheMigrator {
    /// 既存キャッシュに fileSize を付与するマイグレーション
    /// - Note: バックグラウンドで段階的に実行
    public func migrateToFileSizeCache(
        cacheManager: AnalysisCacheManager,
        photoAccessor: PhotoAccessorProtocol,
        batchSize: Int = 100
    ) async {
        // 1. fileSize が nil のキャッシュを検索
        let allResults = await cacheManager.getAllResults()
        let needsMigration = allResults.filter { $0.fileSize == nil }

        // 2. バッチ単位でファイルサイズを取得・更新
        for batch in needsMigration.chunked(into: batchSize) {
            for result in batch {
                guard let asset = await photoAccessor.fetchAsset(for: result.photoId) else {
                    continue
                }
                let fileSize = try? await asset.getFileSizeFast()

                // 更新済み結果を保存
                let updated = result.withFileSize(fileSize)
                await cacheManager.saveResult(updated)
            }

            // バッチ間で少し待機（メインスレッドへの負荷軽減）
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
```

---

### B1-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| B1-UT-01 | fileSize 付き初期化 | 正常に保存 |
| B1-UT-02 | fileSize nil 初期化 | 正常に保存 |
| B1-UT-03 | Codable エンコード | JSON に fileSize 含む |
| B1-UT-04 | Codable デコード（新形式） | fileSize 復元 |
| B1-UT-05 | Codable デコード（旧形式） | fileSize が nil |
| B1-UT-06 | Builder での設定 | 正常に設定 |
| B1-UT-07 | withFileSize メソッド | 新インスタンス生成 |

#### 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| B1-IT-01 | 分析→キャッシュ保存→読み込み | fileSize 維持 |
| B1-IT-02 | 旧キャッシュ→新コード読み込み | クラッシュなし |
| B1-IT-03 | グループ化でキャッシュ活用 | I/O 削減 |
| B1-IT-04 | マイグレーション実行 | 正常完了 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| B1-PT-01 | キャッシュヒット時の処理時間 | I/O 時間 0 |
| B1-PT-02 | 10,000枚の2回目グループ化 | 1回目の 50% 以下 |
| B1-PT-03 | マイグレーション処理時間 | 100,000件で 10分以内 |

---

### B1-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| 旧キャッシュとの互換性問題 | 高 | 低 | decodeIfPresent で対応 |
| キャッシュサイズの増大 | 低 | 中 | 1件 8バイト増、影響軽微 |
| マイグレーション中のパフォーマンス低下 | 中 | 中 | バックグラウンド実行、バッチ処理 |
| fileSize と実際のサイズの乖離 | 中 | 低 | 更新日時チェック、必要時再取得 |

---

## B2: マルチプローブ LSH 最適化

### B2-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| LSHHasher.swift | findCandidatePairsMultiProbe | 189-219 |
| SimilarityAnalyzer.swift | findSimilarGroupsInTimeGroup | 264-365 |

#### 現状の問題

```
現在の LSH 実装:
- シングルプローブ: 1つのハッシュテーブルのみ使用
- ハッシュビット数: 64ビット
- 問題: 類似だがハッシュが異なるペアを見逃す可能性

マルチプローブの実装は存在するが:
- findCandidatePairsMultiProbe は存在
- 実際の呼び出しで使用されているか要確認
- パラメータ最適化の余地あり
```

#### 変更方針

```
最適化ポイント:
1. ハッシュテーブル数の調整（4 → 最適値探索）
2. ビット数の調整（64 → 精度/速度トレードオフ）
3. マルチプローブの積極的活用
4. 候補ペア生成の効率化
```

---

### B2-2: 実装手順

#### Step 1: パラメータチューニング調査

```swift
// 擬似コード: ベンチマーク用コード

public struct LSHBenchmark {
    /// 異なるパラメータでの精度/速度を測定
    static func benchmark(
        features: [(id: String, hash: Data)],
        groundTruth: [(String, String)]  // 正解ペア
    ) async -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []

        // パラメータ組み合わせ
        let bitOptions = [32, 48, 64, 96]
        let tableOptions = [2, 4, 6, 8]

        for bits in bitOptions {
            for tables in tableOptions {
                let hasher = LSHHasher(numberOfBits: bits)
                let startTime = CFAbsoluteTimeGetCurrent()

                let candidates = await hasher.findCandidatePairsMultiProbe(
                    features: features,
                    numberOfHashTables: tables
                )

                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                let precision = calculatePrecision(candidates, groundTruth)
                let recall = calculateRecall(candidates, groundTruth)

                results.append(BenchmarkResult(
                    bits: bits,
                    tables: tables,
                    time: elapsed,
                    precision: precision,
                    recall: recall
                ))
            }
        }

        return results
    }
}
```

#### Step 2: LSHHasher のパラメータ最適化

```swift
// 擬似コード: 最適化後の LSHHasher 初期化

public actor LSHHasher: Sendable {
    /// 最適化されたデフォルトパラメータ
    /// - numberOfBits: 48（精度と速度のバランス）
    /// - numberOfHashTables: 4（Recall 向上）
    public static let optimizedDefaults = (bits: 48, tables: 4)

    public init(
        numberOfBits: Int = optimizedDefaults.bits,
        featureDimension: Int? = nil,
        seed: UInt64 = 42
    ) {
        // ...
    }
}
```

#### Step 3: SimilarityAnalyzer での活用確認

```swift
// 擬似コード: マルチプローブ LSH の明示的使用

public func findSimilarGroupsInTimeGroup(
    _ group: [PhotoAnalysisResult],
    similarityThreshold: Float = 0.9
) async throws -> [[String]] {
    // ...

    // マルチプローブ LSH で候補ペアを取得（高精度版）
    let candidatePairs = await lshHasher.findCandidatePairsMultiProbe(
        features: features,
        numberOfHashTables: LSHHasher.optimizedDefaults.tables
    )

    // 候補ペアのみ詳細比較（O(n²) → O(k) に削減）
    // ...
}
```

---

### B2-3: 影響範囲分析

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| LSHHasher.swift | 中 | パラメータ調整、メソッド追加 |
| SimilarityAnalyzer.swift | 低 | 呼び出しパラメータ調整 |
| LSHHasherTests.swift | 中 | ベンチマークテスト追加 |

---

### B2-4: テスト計画

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| B2-UT-01 | 新パラメータでのハッシュ生成 | 正常動作 |
| B2-UT-02 | マルチプローブ候補ペア生成 | 重複なし |
| B2-UT-03 | 精度測定（Recall） | 90% 以上 |
| B2-PT-01 | 10,000件での処理時間 | 現状比 -10% |

---

### B2-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| パラメータ変更による精度低下 | 高 | 中 | ベンチマーク測定で検証 |
| 処理時間増加 | 中 | 低 | テーブル数の適正値探索 |

---

## B3: 動的時間窓

### B3-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| TimeBasedGrouper.swift | groupByTimeWindow | 全体 |

#### 現状の問題

```
現在の実装:
- 固定時間窓: 24時間
- 問題: 写真が多い期間と少ない期間で効率が異なる
  - 旅行中: 1日1000枚 → 1グループが大きすぎ、O(n²) 影響大
  - 通常日: 1日10枚 → グループ細分化のオーバーヘッド
```

#### 変更方針

```
動的時間窓:
- 写真密度に応じて時間窓を調整
- 高密度期間: 時間窓を狭める（例: 1時間）
- 低密度期間: 時間窓を広げる（例: 72時間）

目標:
- 1グループあたり 50-200 枚程度に収める
- 比較回数の最適化
```

---

### B3-2: 実装手順

#### Step 1: 写真密度計算

```swift
// 擬似コード: TimeBasedGrouper に追加

/// 時間範囲内の写真密度を計算
private func calculatePhotoDensity(
    photos: [PhotoAnalysisResult],
    timeRange: ClosedRange<Date>
) -> Double {
    let duration = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
    guard duration > 0 else { return 0 }
    return Double(photos.count) / (duration / 3600)  // 枚/時間
}
```

#### Step 2: 動的時間窓の計算

```swift
// 擬似コード: 動的時間窓

public struct DynamicTimeWindow {
    /// 目標グループサイズ
    static let targetGroupSize = 100

    /// 最小時間窓（1時間）
    static let minWindowHours: Double = 1

    /// 最大時間窓（72時間）
    static let maxWindowHours: Double = 72

    /// 写真密度に基づく時間窓を計算
    static func calculateWindow(
        density: Double,  // 枚/時間
        totalCount: Int
    ) -> TimeInterval {
        guard density > 0 else {
            return maxWindowHours * 3600
        }

        // 目標グループサイズを達成する時間窓を計算
        let idealHours = Double(targetGroupSize) / density

        // 最小/最大でクランプ
        let clampedHours = max(minWindowHours, min(idealHours, maxWindowHours))

        return clampedHours * 3600
    }
}
```

#### Step 3: groupByTimeWindow のリファクタリング

```swift
// 擬似コード: 動的時間窓版

public func groupByDynamicTimeWindow(
    _ photos: [PhotoAnalysisResult]
) -> [[PhotoAnalysisResult]] {
    guard !photos.isEmpty else { return [] }

    // 日付でソート
    let sorted = photos.sorted { $0.analyzedAt < $1.analyzedAt }

    var groups: [[PhotoAnalysisResult]] = []
    var currentGroup: [PhotoAnalysisResult] = []
    var windowStart: Date = sorted[0].analyzedAt

    // 全体の密度を計算（初期時間窓の決定用）
    let totalRange = sorted[0].analyzedAt...sorted[sorted.count - 1].analyzedAt
    let avgDensity = calculatePhotoDensity(photos: sorted, timeRange: totalRange)
    var currentWindow = DynamicTimeWindow.calculateWindow(
        density: avgDensity,
        totalCount: sorted.count
    )

    for photo in sorted {
        let elapsed = photo.analyzedAt.timeIntervalSince(windowStart)

        if elapsed > currentWindow && !currentGroup.isEmpty {
            // 現在のグループを確定
            groups.append(currentGroup)

            // 次のグループの密度に基づいて時間窓を再計算
            let localDensity = Double(currentGroup.count) / elapsed * 3600
            currentWindow = DynamicTimeWindow.calculateWindow(
                density: localDensity,
                totalCount: sorted.count - groups.flatMap { $0 }.count
            )

            currentGroup = [photo]
            windowStart = photo.analyzedAt
        } else {
            currentGroup.append(photo)
        }
    }

    // 最後のグループ
    if !currentGroup.isEmpty {
        groups.append(currentGroup)
    }

    return groups
}
```

---

### B3-3: 影響範囲分析

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| TimeBasedGrouper.swift | 高 | 動的時間窓ロジック追加 |
| SimilarityAnalyzer.swift | 低 | 呼び出し方法調整 |

---

### B3-4: テスト計画

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| B3-UT-01 | 高密度期間のグループ化 | 小さい時間窓使用 |
| B3-UT-02 | 低密度期間のグループ化 | 大きい時間窓使用 |
| B3-UT-03 | 混合密度のグループ化 | 適応的に調整 |
| B3-UT-04 | グループサイズ分布 | 50-200枚が中央値 |
| B3-PT-01 | 100,000枚での処理時間 | 固定窓比 -10% |

---

### B3-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| グループが細かくなりすぎる | 中 | 中 | 最小時間窓の設定 |
| アルゴリズムの複雑化 | 低 | 中 | 十分なテストカバレッジ |
| 既存結果との差異 | 低 | 低 | 段階的ロールアウト |

---

## B4: インメモリキャッシュ拡大

### B4-1: 設計仕様

#### 変更対象

| ファイル | 関数/メソッド | 行番号 |
|----------|--------------|--------|
| AnalysisCacheManager.swift | maxMemoryCacheSize | 72 |
| AnalysisCacheManager.swift | memoryCache 管理 | 複数 |

#### 現状の問題

```
現在の設定:
- maxMemoryCacheSize = 100
- 100件を超えると LRU で古いエントリが削除
- 100,000枚処理時、99.9% がディスクI/O 必要

問題:
- UserDefaults からの読み込みは比較的遅い
- 頻繁にアクセスされるエントリが削除される可能性
```

#### 変更方針

```
変更後:
- maxMemoryCacheSize = 5,000（または動的調整）
- メモリ使用量: 約50MB増加（1件10KB想定）
- メモリ警告時に自動縮小
```

---

### B4-2: 実装手順

#### Step 1: キャッシュサイズの拡大

```swift
// 擬似コード: AnalysisCacheManager

public actor AnalysisCacheManager: AnalysisCacheManagerProtocol {
    /// インメモリキャッシュの最大サイズ（拡大版）
    private let maxMemoryCacheSize: Int

    /// デフォルトのキャッシュサイズ
    public static let defaultCacheSize = 5_000

    public init(
        userDefaults: UserDefaults = .standard,
        maxMemoryCacheSize: Int = defaultCacheSize
    ) {
        self.userDefaults = userDefaults
        self.maxMemoryCacheSize = maxMemoryCacheSize
    }
}
```

#### Step 2: メモリ警告対応

```swift
// 擬似コード: メモリ警告時の自動縮小

extension AnalysisCacheManager {
    /// メモリ警告時にキャッシュを縮小
    public func handleMemoryWarning() {
        // キャッシュの半分を削除（LRU）
        let removeCount = memoryCache.count / 2
        let keysToRemove = Array(memoryCache.keys.prefix(removeCount))
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
        }
        logInfo("メモリ警告: キャッシュを \(removeCount) 件削除")
    }
}

// AppDelegate または SceneDelegate で監視
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil,
    queue: .main
) { _ in
    Task {
        await cacheManager.handleMemoryWarning()
    }
}
```

#### Step 3: LRU 実装の改善

```swift
// 擬似コード: アクセス順序を追跡する改善版

public actor AnalysisCacheManager {
    /// アクセス順序を追跡するキュー
    private var accessOrder: [String] = []

    private func addToMemoryCache(_ result: PhotoAnalysisResult) {
        let photoId = result.photoId

        // 既存エントリがあれば順序を更新
        if memoryCache[photoId] != nil {
            accessOrder.removeAll { $0 == photoId }
        }

        // キャッシュに追加
        memoryCache[photoId] = result
        accessOrder.append(photoId)

        // サイズ制限を超えたら古いものを削除（LRU）
        while memoryCache.count > maxMemoryCacheSize {
            if let oldest = accessOrder.first {
                accessOrder.removeFirst()
                memoryCache.removeValue(forKey: oldest)
            }
        }
    }

    public func loadResult(for photoId: String) async -> PhotoAnalysisResult? {
        if let cached = memoryCache[photoId] {
            // アクセス順序を更新（LRU）
            accessOrder.removeAll { $0 == photoId }
            accessOrder.append(photoId)
            return cached
        }

        // UserDefaults から読み込み...
    }
}
```

---

### B4-3: 影響範囲分析

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| AnalysisCacheManager.swift | 中 | キャッシュサイズ、LRU改善 |
| AppDelegate.swift | 低 | メモリ警告ハンドラ追加 |

---

### B4-4: テスト計画

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| B4-UT-01 | 5,000件キャッシュ | 正常動作 |
| B4-UT-02 | LRU 削除順序 | 古いものから削除 |
| B4-UT-03 | メモリ警告対応 | キャッシュ縮小 |
| B4-PT-01 | キャッシュヒット率測定 | 80% 以上 |
| B4-PT-02 | メモリ使用量測定 | 100MB 未満増加 |

---

### B4-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| メモリ使用量増大 | 高 | 高 | メモリ警告対応、上限設定 |
| 低メモリデバイスでのクラッシュ | 高 | 中 | デバイスメモリに応じた動的調整 |
| LRU オーバーヘッド | 低 | 低 | 配列操作の最適化 |

---

## Phase 2 統合テスト計画

### P2-INT: 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| P2-INT-01 | B1-B4 全適用後の分析処理 | 正常完了 |
| P2-INT-02 | 2回目分析（キャッシュ活用） | 大幅高速化 |
| P2-INT-03 | 100,000枚での E2E テスト | 15-20分以内 |
| P2-INT-04 | 旧キャッシュとの互換性 | マイグレーション成功 |

### P2-PERF: パフォーマンス計測

| 計測項目 | 計測方法 | 目標値 |
|----------|----------|--------|
| 処理時間（100,000枚） | Instruments / Time Profiler | 15-20分 |
| 2回目処理時間 | Time Profiler | 5分以内 |
| ピークメモリ使用量 | Instruments / Allocations | 1.5GB未満 |
| キャッシュヒット率 | ログ分析 | 80% 以上 |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 1.0 | 2025-12-25 | 初版作成 |
