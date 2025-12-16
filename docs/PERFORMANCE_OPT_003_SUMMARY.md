# performance-opt-003: Actor直列化問題の修正

## 実装日
2025-12-16

## タスク概要
AnalysisRepository の actor 直列化問題を修正し、真の並列実行を実現

## 問題の詳細

### 問題点
- `AnalysisRepository` が actor として定義されている
- actor は同時に1つのメソッドしか実行できない（直列化される）
- `analyzePhotos()` で TaskGroup による12並列を実装していたが、actor の制約により実際は直列実行されていた
- 結果として、並列化の効果が得られていなかった

### 根本原因
```swift
// 問題のあるコード
public actor AnalysisRepository {
    public func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult {
        // この関数は actor-isolated なので、
        // TaskGroup で複数呼び出しても直列実行される
    }
}
```

## 実装内容

### 1. analyzePhoto() を nonisolated 化
**ファイル**: `AnalysisRepository.swift`

#### 変更箇所
- `analyzePhoto()` メソッドに `nonisolated` キーワードを追加
- `extractFeaturePrint()` メソッドに `nonisolated` キーワードを追加
- `detectFaces()` メソッドに `nonisolated` キーワードを追加
- `detectBlur()` メソッドに `nonisolated` キーワードを追加
- `detectScreenshot()` メソッドに `nonisolated` キーワードを追加
- `fetchPHAsset()` ヘルパーメソッドに `nonisolated` キーワードを追加
- `calculateQualityScore()` ヘルパーメソッドに `nonisolated` キーワードを追加

```swift
// 修正後
public actor AnalysisRepository {
    nonisolated public func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult {
        // nonisolated なので、並列実行可能
        // 内部で actor サービスを並列呼び出し
        async let featurePrintTask = extractFeaturePrint(photo)
        async let faceResultTask = detectFaces(in: photo)
        async let blurResultTask = detectBlur(in: photo)
        async let screenshotResultTask = detectScreenshot(in: photo)
        // ...
    }

    nonisolated public func extractFeaturePrint(_ photo: Photo) async throws -> VNFeaturePrintObservation {
        // ...
    }

    nonisolated public func detectFaces(in photo: Photo) async throws -> FaceDetectionResult {
        // ...
    }

    nonisolated public func detectBlur(in photo: Photo) async throws -> BlurDetectionResult {
        // ...
    }

    nonisolated public func detectScreenshot(in photo: Photo) async throws -> ScreenshotDetectionResult {
        // ...
    }
}
```

### 2. プロトコル更新
**ファイル**: `AnalysisRepository.swift`

```swift
public protocol ImageAnalysisRepositoryProtocol: Actor {
    nonisolated func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult
    nonisolated func extractFeaturePrint(_ photo: Photo) async throws -> VNFeaturePrintObservation
    nonisolated func detectFaces(in photo: Photo) async throws -> FaceDetectionResult
    nonisolated func detectBlur(in photo: Photo) async throws -> BlurDetectionResult
    nonisolated func detectScreenshot(in photo: Photo) async throws -> ScreenshotDetectionResult
    // ...
}
```

### 3. スレッドセーフ性の確保

#### 依存サービス
すべての依存サービスは既に actor として定義されている:
- `VisionRequestHandler`: actor
- `FeaturePrintExtractor`: actor
- `FaceDetector`: actor
- `BlurDetector`: actor
- `ScreenshotDetector`: actor
- `SimilarityCalculator`: actor
- `SimilarityAnalyzer`: actor
- `PhotoGrouper`: actor
- `BestShotSelector`: actor

#### 不変プロパティ
`calculateQualityScore()` でアクセスする `options` プロパティは `let` で不変なので安全:
```swift
private let options: AnalysisRepositoryOptions
```

## 並列化の仕組み

### Before（修正前）
```
analyzePhotos() → TaskGroup
  ├─ Task 1 → analyzePhoto() ─┐
  ├─ Task 2 → analyzePhoto() ─┤
  ├─ Task 3 → analyzePhoto() ─┼→ actor が直列化（1つずつ実行）
  ├─ ...                      ─┤
  └─ Task 12 → analyzePhoto() ─┘

結果: 実質的に直列実行（並列化の効果なし）
```

### After（修正後）
```
analyzePhotos() → TaskGroup
  ├─ Task 1 → analyzePhoto() (nonisolated)
  │    ├─ extractFeaturePrint() → actor (並列)
  │    ├─ detectFaces() → actor (並列)
  │    ├─ detectBlur() → actor (並列)
  │    └─ detectScreenshot() → actor (並列)
  ├─ Task 2 → analyzePhoto() (nonisolated)
  │    ├─ extractFeaturePrint() → actor (並列)
  │    ├─ detectFaces() → actor (並列)
  │    ├─ detectBlur() → actor (並列)
  │    └─ detectScreenshot() → actor (並列)
  ├─ ...（同時に12タスク並列実行）
  └─ Task 12 → analyzePhoto() (nonisolated)

結果: 真の並列実行（最大12並列）
```

## ビルド結果
✅ ビルド成功（警告のみ、エラーなし）

## 期待される効果

### 1. パフォーマンス向上
- **理論値**: 最大12倍の高速化（12並列実行）
- **実測値**: CPU コア数と依存サービスのボトルネックに依存
- **推定**: 5〜10倍の高速化（既存コメントの記載通り）

### 2. リソース効率化
- CPU の複数コアを有効活用
- I/O 待ち時間の有効活用（Vision フレームワークの処理待ち）
- メモリ使用量は maxConcurrency=12 で制御

### 3. ユーザー体験向上
- 大量写真のスキャン時間が大幅短縮
- プログレスバーの更新がスムーズに
- アプリの応答性向上

## 安全性の確認

### 1. Swift Concurrency 準拠
- すべてのサービスが actor として定義されている
- `nonisolated` メソッドは不変データのみアクセス
- `@Sendable` クロージャで進捗通知

### 2. データ競合の防止
- 各 actor サービスは内部で排他制御を提供
- 不変プロパティ（`options`）へのアクセスは安全
- PHAsset の取得は Photos フレームワークがスレッドセーフ

### 3. Swift 6 strict mode 対応
- ビルド成功（strict concurrency モード）
- 警告なし（actor 分離関連）

## テスト

### 作成したテスト
**ファイル**: `AnalysisRepositoryParallelizationTests.swift`

テスト内容:
1. `analyzePhoto()` が nonisolated で並列実行可能
2. `analyzePhotos()` が TaskGroup で並列実行
3. 個別分析メソッドも nonisolated で並列実行可能
4. 最大並列数（12）が守られることを確認

### 既存テストの状況
- 既存のテストファイルに多数のコンパイルエラーあり
- これらは今回の変更とは無関係（以前から存在）
- AnalysisRepository の変更自体はビルド成功

## まとめ

### 実装完了項目
- ✅ `analyzePhoto()` を `nonisolated` 化
- ✅ 関連メソッド（個別分析）を `nonisolated` 化
- ✅ プロトコル定義の更新
- ✅ スレッドセーフ性の確認
- ✅ ビルド成功
- ✅ 並列化テストの作成

### パフォーマンス向上の見込み
- **従来**: actor 直列化により1枚ずつ処理
- **修正後**: 最大12枚を並列処理
- **期待効果**: 5〜10倍の高速化

### 次のステップ
1. 実機でのパフォーマンス測定
2. 大量写真（1000枚以上）での検証
3. メモリ使用量の監視
4. バッテリー消費量の確認

## 関連ファイル
- `/Users/yukihayashi/Documents/dev/projects/LightRoll_Cleaner/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/ImageAnalysis/Repositories/AnalysisRepository.swift`
- `/Users/yukihayashi/Documents/dev/projects/LightRoll_Cleaner/LightRoll_CleanerPackage/Tests/LightRoll_CleanerFeatureTests/ImageAnalysis/Repositories/AnalysisRepositoryParallelizationTests.swift`
