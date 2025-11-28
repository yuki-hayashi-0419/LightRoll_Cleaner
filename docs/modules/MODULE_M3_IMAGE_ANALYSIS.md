# MODULE M3: Image Analysis & Grouping

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M3 |
| モジュール名 | Image Analysis & Grouping |
| 責務 | 画像分析、類似度判定、写真グルーピング、ベストショット選定 |
| 依存先 | M1 (Core), M2 (Photo Access) |
| 依存元 | M5 (Dashboard), M6 (Deletion) |

---

## 2. 主要コンポーネント

### 2.1 AnalysisRepository
```swift
// Repositories/AnalysisRepository.swift
final class AnalysisRepository: AnalysisRepositoryProtocol {
    func analyzePhoto(_ photo: Photo) async throws -> PhotoAnalysisResult
    func extractFeaturePrint(_ photo: Photo) async throws -> VNFeaturePrintObservation
    func detectFaces(_ photo: Photo) async throws -> [VNFaceObservation]
    func calculateQualityScore(_ photo: Photo) async throws -> Float
}
```

### 2.2 SimilarityAnalyzer
```swift
// Services/SimilarityAnalyzer.swift
final class SimilarityAnalyzer {
    func findSimilarPhotos(_ photos: [Photo]) async throws -> [[Photo]]
    func calculateSimilarity(_ photo1: Photo, _ photo2: Photo) async throws -> Float
}
```

### 2.3 PhotoGrouper
```swift
// Services/PhotoGrouper.swift
final class PhotoGrouper {
    func groupPhotos(_ photos: [Photo], analysisResults: [PhotoAnalysisResult]) -> [PhotoGroup]
    func groupBySimilarity(_ photos: [Photo]) async throws -> [PhotoGroup]
    func groupSelfies(_ photos: [Photo]) -> PhotoGroup?
    func groupScreenshots(_ photos: [Photo]) -> PhotoGroup?
    func groupBlurryPhotos(_ photos: [Photo], results: [PhotoAnalysisResult]) -> PhotoGroup?
    func groupLargeVideos(_ photos: [Photo]) -> PhotoGroup?
    func groupDuplicates(_ photos: [Photo]) -> [PhotoGroup]  // ファイルサイズ・ピクセルサイズが同一の写真を検出
}
```

### 2.4 BestShotSelector
```swift
// Services/BestShotSelector.swift
final class BestShotSelector {
    func selectBestShot(from group: PhotoGroup) -> Int?
    func rankPhotos(_ photos: [Photo]) -> [Photo]
}
```

### 2.5 Domain Models
```swift
// Models/PhotoAnalysisResult.swift
struct PhotoAnalysisResult {
    let photoId: String
    let qualityScore: Float          // 0.0〜1.0
    let blurScore: Float             // 0.0〜1.0（高いほどブレ）
    let brightnessScore: Float       // 0.0〜1.0
    let faceCount: Int
    let faceQualityScores: [Float]   // 各顔の品質
    let isScreenshot: Bool
    let featurePrint: VNFeaturePrintObservation?
}

// Models/PhotoGroup.swift
struct PhotoGroup: Identifiable {
    let id: UUID
    let type: GroupType
    var photos: [Photo]
    var bestShotIndex: Int?
    var isSelected: Bool = false

    var totalSize: Int64 {
        photos.reduce(0) { $0 + $1.fileSize }
    }

    var reclaimableSize: Int64 {
        guard let bestIndex = bestShotIndex else { return totalSize }
        return photos.enumerated()
            .filter { $0.offset != bestIndex }
            .reduce(0) { $0 + $1.element.fileSize }
    }
}

enum GroupType: CaseIterable {
    case similar       // 類似写真（連写含む）
    case selfie        // 自撮り
    case screenshot    // スクリーンショット
    case blurry        // ブレ・ピンボケ
    case largeVideo    // 大容量動画
    case duplicate     // 重複写真（同一ファイル）

    var displayName: String {
        switch self {
        case .similar: return "類似写真"
        case .selfie: return "自撮り"
        case .screenshot: return "スクリーンショット"
        case .blurry: return "ブレ写真"
        case .largeVideo: return "大容量動画"
        case .duplicate: return "重複写真"
        }
    }

    var icon: String {
        switch self {
        case .similar: return "square.on.square"
        case .selfie: return "person.crop.circle"
        case .screenshot: return "rectangle.dashed"
        case .blurry: return "camera.metering.unknown"
        case .duplicate: return "doc.on.doc"
        case .largeVideo: return "video.fill"
        }
    }
}
```

---

## 3. ディレクトリ構造

```
src/modules/ImageAnalysis/
├── Repositories/
│   └── AnalysisRepository.swift
├── Services/
│   ├── SimilarityAnalyzer.swift
│   ├── PhotoGrouper.swift
│   ├── BestShotSelector.swift
│   ├── BlurDetector.swift
│   ├── ScreenshotDetector.swift
│   └── FaceAnalyzer.swift
├── Models/
│   ├── PhotoAnalysisResult.swift
│   └── PhotoGroup.swift
└── Utils/
    └── VisionRequestHandler.swift
```

---

## 4. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M3-T01 | PhotoAnalysisResultモデル | 分析結果モデルの定義 | 1h | M1-T08 |
| M3-T02 | PhotoGroupモデル | グループモデルの定義 | 1h | M3-T01 |
| M3-T03 | VisionRequestHandler | Vision API共通処理 | 2h | M2-T05 |
| M3-T04 | 特徴量抽出 | VNFeaturePrintObservation取得 | 2.5h | M3-T03 |
| M3-T05 | 類似度計算 | コサイン類似度アルゴリズム | 2h | M3-T04 |
| M3-T06 | SimilarityAnalyzer実装 | 類似写真検出サービス | 2.5h | M3-T05 |
| M3-T07 | 顔検出実装 | VNDetectFaceRectangles使用 | 2h | M3-T03 |
| M3-T08 | ブレ検出実装 | VNCalculateImageAestheticsScores | 2h | M3-T03 |
| M3-T09 | スクリーンショット検出 | 画面サイズ・メタデータ判定 | 1.5h | M2-T04 |
| M3-T10 | PhotoGrouper実装 | グルーピングロジック | 2.5h | M3-T06,M3-T07,M3-T08,M3-T09 |
| M3-T11 | BestShotSelector実装 | ベストショット選定アルゴリズム | 2h | M3-T10 |
| M3-T12 | AnalysisRepository統合 | Repository層の完成 | 2h | M3-T11 |
| M3-T13 | 単体テスト作成 | 分析機能のテスト | 2.5h | M3-T12 |

---

## 5. テストケース

### M3-T05: 類似度計算
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M3-T05-TC01 | 同一画像の類似度 | 1.0（完全一致） |
| M3-T05-TC02 | 全く異なる画像の類似度 | 0.5未満 |
| M3-T05-TC03 | 連写画像の類似度 | 0.85以上 |

### M3-T08: ブレ検出実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M3-T08-TC01 | シャープな画像のスコア | 0.7以上 |
| M3-T08-TC02 | ブレた画像のスコア | 0.3未満 |
| M3-T08-TC03 | 動きのある被写体 | 被写体ブレを検出 |

### M3-T10: PhotoGrouper実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M3-T10-TC01 | 類似写真5枚のグルーピング | 1グループに集約 |
| M3-T10-TC02 | スクリーンショット分類 | screenshot型に分類 |
| M3-T10-TC03 | 自撮り写真の検出 | selfie型に分類 |

### M3-T11: BestShotSelector実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M3-T11-TC01 | 品質スコア最高の選定 | 最高スコアの写真がベスト |
| M3-T11-TC02 | 顔写真での選定 | 顔が正面向きの写真優先 |
| M3-T11-TC03 | 複数基準での順位付け | 総合スコアで順位付け |

---

## 6. 受け入れ条件

- [ ] 類似写真が正しくグルーピングされる（精度85%以上）
- [ ] 自撮り写真が正しく検出される（精度90%以上）
- [ ] スクリーンショットが100%検出される
- [ ] ブレ写真が適切に検出される（精度80%以上）
- [ ] ベストショットが妥当に選定される
- [ ] 1000枚の分析が30秒以内で完了

---

## 7. 技術的考慮事項

### 7.1 Vision API制限
- iOS 16以上が必要
- VNFeaturePrintObservationは画像依存
- メモリ使用量に注意

### 7.2 アルゴリズム調整
```swift
// 閾値設定（AppConfigで管理）
let similarityThreshold: Float = 0.85    // 類似判定
let blurThreshold: Float = 0.3           // ブレ判定
let minFaceSize: CGFloat = 0.1           // 最小顔サイズ（画像比）
```

### 7.3 並列処理
- TaskGroupで並列分析
- CPUコア数に応じた並列度調整
- プログレス通知との同期

---

*最終更新: 2025-11-27*
