# 実装履歴アーカイブ

このファイルには、過去の実装詳細や旧バージョン情報をアーカイブとして保存します。

---

## 2025-11-27: 設計フェーズ完了（v0.1.0）

### 作成されたドキュメント一覧

#### 基盤ドキュメント
- `docs/CRITICAL/CORE_RULES.md` - プロジェクトルール・コーディング規約
- `docs/CRITICAL/ARCHITECTURE.md` - システムアーキテクチャ設計書

#### モジュール仕様書（9件）
- `docs/modules/MODULE_M1_CORE_INFRASTRUCTURE.md` - コア基盤
- `docs/modules/MODULE_M2_PHOTO_ACCESS.md` - 写真アクセス層
- `docs/modules/MODULE_M3_IMAGE_ANALYSIS.md` - 画像分析エンジン
- `docs/modules/MODULE_M4_UI_COMPONENTS.md` - UIコンポーネント
- `docs/modules/MODULE_M5_DASHBOARD.md` - ダッシュボード
- `docs/modules/MODULE_M6_DELETION_SAFETY.md` - 削除安全機能
- `docs/modules/MODULE_M7_NOTIFICATIONS.md` - 通知システム
- `docs/modules/MODULE_M8_SETTINGS.md` - 設定画面
- `docs/modules/MODULE_M9_MONETIZATION.md` - 課金・広告

#### 管理ドキュメント
- `docs/TASKS.md` - 118タスク定義
- `docs/PROJECT_SUMMARY.md` - プロジェクト概要
- `docs/TEST_RESULTS.md` - テスト結果テンプレート
- `docs/SECURITY_AUDIT.md` - セキュリティ監査基準

### アーキテクチャ選定プロセス

**比較対象**:
1. MVC + Coordinator
2. MVVM + Repository
3. TCA (The Composable Architecture)

**選定結果**: MVVM + Repository パターン

**選定理由**:
- SwiftUI との親和性が高い
- テスト容易性に優れる
- 学習コストと実装速度のバランスが良い
- チーム規模（1人）に適している

### 工数見積もり

| モジュール | タスク数 | 見積時間 |
|-----------|---------|---------|
| M1: Core | 12 | 20h |
| M2: Photo | 15 | 24h |
| M3: Analysis | 14 | 28h |
| M4: UI | 13 | 20h |
| M5: Dashboard | 12 | 18h |
| M6: Deletion | 14 | 22h |
| M7: Notification | 12 | 16h |
| M8: Settings | 13 | 18h |
| M9: Monetization | 13 | 24h |
| **合計** | **118** | **約190h** |

---

## 2025-11-28: Phase 1 基盤構築開始（v0.2.0）

### 完了タスク一覧

#### M1: Core Infrastructure（6タスク完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M1-T01 | Xcodeプロジェクト作成 | iOS 17+/SwiftUI/SPM構成 |
| M1-T02 | ディレクトリ構造整備 | 5層アーキテクチャ（Domain/Data/Presentation/Core/Utils） |
| M1-T03 | エラー型定義 | LightRollError統一エラー型 |
| M1-T05 | AppConfig実装 | 設定永続化・検証・デフォルト値管理 |
| M1-T06 | DIコンテナ基盤 | ServiceLocatorパターン、モック差し替え対応 |
| M1-T07 | AppState実装 | @Observable対応のアプリ状態管理 |

#### M4: UI Components（1タスク完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M4-T01 | カラーパレット定義 | 16色セット、ダークモード対応、Semantic Colors |

### 実装詳細

#### AppConfig仕様
- `similarityThreshold`: 類似度判定閾値（0.0〜1.0）
- `scanTargets`: スキャン対象アルバム設定
- `autoDeleteEnabled`: 自動削除フラグ
- UserDefaultsによる永続化

#### AppState仕様
- `isLoading`: ローディング状態
- `currentError`: エラー状態
- `scanProgress`: スキャン進捗（0.0〜1.0）
- `selectedPhotos`: 選択中の写真ID配列

#### カラーパレット仕様
- Primary系: primaryColor, primaryLight, primaryDark
- Secondary系: secondaryColor, secondaryLight
- Accent: accentColor
- Background系: backgroundColor, surfaceColor, cardBackground
- Text系: textPrimary, textSecondary, textDisabled
- Semantic: successColor, warningColor, errorColor, infoColor

---

## 2025-11-28: デザインシステム基盤完成（v0.3.0）

### 完了タスク一覧

#### M1: Core Infrastructure（1タスク完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M1-T08 | Protocol定義 | UseCase/ViewModel/Service/Repository各層のプロトコル |

#### M4: UI Components（3タスク完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M4-T02 | タイポグラフィ定義 | 15フォントスタイル、Dynamic Type対応 |
| M4-T03 | グラスモーフィズム実装 | 5スタイル、4シェイプ、GlassCardView |
| M4-T04 | Spacing定義 | 8ptグリッド、LayoutMetrics、EdgeInsets拡張 |

### 実装詳細

#### Typography（Typography.swift）
**フォントスタイル一覧（15種）**:

| カテゴリ | スタイル名 | ベースサイズ | 用途 |
|---------|-----------|-------------|------|
| Display | largeTitle | 34pt Bold | ホーム画面メインタイトル |
| Display | title1 | 28pt Bold | セクションヘッダー |
| Display | title2 | 22pt Semibold | サブセクションヘッダー |
| Display | title3 | 20pt Semibold | カード内タイトル |
| Body | headline | 17pt Semibold | 強調テキスト、ボタンラベル |
| Body | body | 17pt Regular | 本文テキスト |
| Body | callout | 16pt Regular | やや小さい本文 |
| Body | subheadline | 15pt Regular | 補助的なヘッダー |
| Supporting | footnote | 13pt Regular | 小さな補足テキスト |
| Supporting | caption | 12pt Regular | メタデータ、タイムスタンプ |
| Supporting | caption2 | 11pt Regular | 最小サイズの補助テキスト |
| Special | largeNumber | 48pt Bold Rounded | ストレージ容量等の大きな数字 |
| Special | mediumNumber | 28pt Semibold Rounded | 中程度の数値表示 |
| Special | smallNumber | 14pt Medium Rounded | バッジ等の小さい数値 |
| Special | monospaced | 14pt Regular Monospaced | 技術情報表示 |

**拡張API**:
- `View.lightRollTextStyle(_:color:)` - ViewModifierベースのスタイル適用
- `Text.primaryStyle()` / `Text.secondaryStyle()` / `Text.tertiaryStyle()` - Textチェーンメソッド
- `View.limitDynamicTypeSize(to:)` - Dynamic Typeサイズ制限

#### GlassMorphism（GlassMorphism.swift）
**GlassStyle enum（5段階）**:

| スタイル | Material | Border Opacity | Shadow Radius | 用途 |
|---------|----------|----------------|---------------|------|
| ultraThin | ultraThinMaterial | 0.15 | 8pt | 最も透明、背景を強調したい場合 |
| thin | thinMaterial | 0.2 | 10pt | ボタン、軽いオーバーレイ |
| regular | regularMaterial | 0.25 | 12pt | カード、標準的な用途 |
| thick | thickMaterial | 0.3 | 15pt | モーダル、重要なカード |
| chrome | ultraThickMaterial | 0.35 | 20pt | 強調カード、ツールバー |

**GlassShape enum（4種）**:
- `roundedRectangle(cornerRadius:)` - 角丸矩形
- `capsule` - カプセル形状
- `circle` - 円形
- `continuousRoundedRectangle(cornerRadius:)` - 滑らかな角丸（iOS 13+）

**コンポーネント**:
- `GlassCardView<Content: View>` - グラス効果カードビュー
- `GlassButtonStyle` - グラスボタンスタイル
- `LiquidGlassModifier` - iOS 26+用 Liquid Glass対応

**拡張API**:
- `View.glassBackground(style:shape:showBorder:showShadow:showInnerGlow:)`
- `View.glassCard(cornerRadius:style:)` - 簡易角丸グラス
- `View.glassCapsule(style:)` - カプセル形状グラス
- `View.glassCircle(style:)` - 円形グラス
- `View.adaptiveGlass(cornerRadius:fallbackStyle:)` - iOS 26対応の適応グラス
- `ButtonStyle.glass(style:cornerRadius:)` - ボタンスタイル

#### Spacing（Spacing.swift）
**スペーシングスケール（8ptグリッド）**:

| 名前 | 値 | 用途 |
|------|-----|------|
| xxs | 2pt | アイコンとラベルの間 |
| xs | 4pt | タイトな要素間 |
| sm | 8pt | 関連要素間 |
| md | 12pt | 中程度の要素間 |
| lg | 16pt | セクション内要素間 |
| xl | 24pt | セクション間 |
| xxl | 32pt | 主要セクション間 |
| xxxl | 40pt | 画面上部マージン |

**セマンティックスペーシング**:
- `componentPadding`: 16pt
- `cardPadding`: 16pt
- `sectionItemSpacing`: 12pt
- `sectionSpacing`: 24pt
- `listItemSpacing`: 8pt
- `gridSpacing`: 2pt
- `buttonPaddingH`: 16pt / `buttonPaddingV`: 12pt

**LayoutMetrics**:
- 角丸スケール: XS(4) / SM(8) / MD(12) / LG(16) / XL(20) / XXL(24)
- アイコンサイズ: XS(12) / SM(16) / MD(20) / LG(24) / XL(32) / XXL(48) / Huge(64)
- ボタン高さ: SM(32) / MD(44) / LG(56)
- 最小タッチターゲット: 44pt（Apple HIG準拠）

**型エイリアス**:
- `LRSpacing` = `CGFloat.LightRoll.Spacing`
- `LRLayout` = `CGFloat.LightRoll.LayoutMetrics`

#### Protocol層（UseCaseProtocols.swift, ViewModelProtocols.swift, ServiceProtocols.swift, RepositoryProtocols.swift）

**UseCase Protocols**:
| プロトコル | Input | Output | 説明 |
|-----------|-------|--------|------|
| ScanPhotosUseCaseProtocol | - | ScanResult | 写真スキャン実行 |
| GroupPhotosUseCaseProtocol | [PhotoAsset] | [PhotoGroup] | 写真グルーピング |
| DeletePhotosUseCaseProtocol | DeletePhotosInput | DeletePhotosOutput | 写真削除 |
| RestorePhotosUseCaseProtocol | RestorePhotosInput | RestorePhotosOutput | 写真復元 |
| GetStatisticsUseCaseProtocol | - | StatisticsOutput | 統計情報取得 |
| AnalyzePhotoUseCaseProtocol | AnalyzePhotoInput | PhotoAnalysisResult | 単一写真分析 |
| SelectBestShotUseCaseProtocol | SelectBestShotInput | SelectBestShotOutput | ベストショット選択 |
| PurchaseUseCaseProtocol | PurchaseInput | PurchaseResult | 購入処理 |
| RestorePurchasesUseCaseProtocol | - | PremiumStatus | 購入復元 |
| CheckDeletionLimitUseCaseProtocol | - | DeletionLimitStatus | 削除制限チェック |

**補助データ型**:
- `DeletePhotosInput/Output` - 削除処理の入出力
- `RestorePhotosInput/Output` - 復元処理の入出力
- `StatisticsOutput` / `GroupStatistics` - 統計情報
- `AnalysisOptions` - 分析オプション
- `BestShotCriteria` / `SelectBestShotOutput` - ベストショット選択
- `DeletionLimitStatus` - 削除制限状態

---

## 2025-11-28: M1 Core Infrastructure完了（v0.4.0）

### 完了タスク一覧（セッション impl-003）

#### M1: Core Infrastructure（3タスク完了 → モジュール完了）
| タスクID | タスク名 | スコア | 内容 |
|----------|---------|--------|------|
| M1-T04 | ロガー実装 | 116点 | Logger.swift, 6段階ログレベル, 9カテゴリ, OSLog統合 |
| M1-T09 | 拡張ユーティリティ | 113点 | 7拡張ファイル, 100+メソッド |
| M1-T10 | 単体テスト作成 | 112点 | ConfigTests, ErrorTests, 92テスト追加 |

### M1モジュール完了サマリー

**全10タスク完了**:
- M1-T01: Xcodeプロジェクト作成
- M1-T02: ディレクトリ構造整備
- M1-T03: エラー型定義（LightRollError）
- M1-T04: ロガー実装（Logger.swift）
- M1-T05: AppConfig実装
- M1-T06: DIコンテナ基盤（ServiceLocator）
- M1-T07: AppState実装（@Observable）
- M1-T08: Protocol定義
- M1-T09: 拡張ユーティリティ
- M1-T10: 単体テスト作成

**総工数**: 16時間（見積20時間 → 20%効率化）

### 実装詳細

#### Logger（Logger.swift）

**ログレベル（6段階）**:
| レベル | 用途 |
|--------|------|
| trace | 詳細デバッグ（開発時のみ） |
| debug | 開発時デバッグ情報 |
| info | 一般的な情報（デフォルト） |
| warning | 警告（処理は継続） |
| error | エラー（機能に影響） |
| critical | 致命的エラー（アプリ停止レベル） |

**ログカテゴリ（9種類）**:
- general: 一般的なログ
- ui: UI関連
- network: ネットワーク処理
- database: データベース操作
- photo: 写真処理
- analysis: 画像分析
- purchase: 課金処理
- notification: 通知
- performance: パフォーマンス計測

**主要機能**:
- `Logger.log(_:level:category:file:function:line:)` - 基本ログ出力
- `Logger.measure(_:category:operation:)` - パフォーマンス計測
- `Logger.log(error:context:file:function:line:)` - LightRollError連携
- OSLog統合（iOS標準Console.appで確認可能）

#### 拡張ユーティリティ

**String+Extensions.swift**:
- `isValidEmail` / `isValidPhone` / `isValidURL` - バリデーション
- `trimmed` / `nilIfEmpty` - 文字列処理
- `localized` / `localizedWithFormat(_:)` - ローカライズ
- `toDate(format:)` / `toURL()` - 型変換

**Array+Extensions.swift**:
- `safe[index]` - 安全なインデックスアクセス
- `unique()` / `uniqueBy(_:)` - 重複排除
- `chunked(into:)` - 分割
- `asyncMap(_:)` / `asyncCompactMap(_:)` - 非同期処理

**Date+Extensions.swift**:
- `isToday` / `isYesterday` / `isThisWeek` - 日付判定
- `startOfDay` / `endOfDay` / `startOfMonth` - 境界取得
- `formatted(_:)` / `relativeFormatted` - フォーマット
- `adding(_:to:)` / `daysBetween(_:)` - 計算

**Optional+Extensions.swift**:
- `isNilOrEmpty` - String?のnil/空判定
- `orEmpty` - String?のデフォルト空文字
- `unwrap(or:)` / `unwrap(orThrow:)` - アンラップ

**FileManager+Extensions.swift**:
- `documentsDirectory` / `cachesDirectory` - ディレクトリ取得
- `fileSize(at:)` / `directorySize(at:)` - サイズ取得
- `createDirectoryIfNeeded(at:)` - ディレクトリ作成
- `safeRemoveItem(at:)` - 安全な削除

**Collection+Extensions.swift**:
- `isNotEmpty` - 空でないか判定
- `average` / `sum` - 数値コレクション計算
- `sorted(by:ascending:)` - ソート
- `grouped(by:)` - グルーピング

**Result+Extensions.swift**:
- `isSuccess` / `isFailure` - 結果判定
- `successValue` / `failureError` - 値取得
- `mapBoth(success:failure:)` - 両方変換
- `flatMapError(_:)` - エラー変換

#### テストカバレッジ

**追加テスト（92テスト）**:
- ConfigTests: AppConfig, UserDefaults永続化
- ErrorTests: LightRollError, エラーコード, ローカライズ

**総テスト数**: 368 → 460テスト（+25%）

---

## 2025-11-28: M2 Photo Access完了（v0.5.0）

### 完了タスク一覧

#### M2: Photo Access & Scanning（12タスク完了 → モジュール完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M2-T01 | Info.plist権限設定 | NSPhotoLibraryUsageDescription設定 |
| M2-T02 | 権限マネージャー実装 | PhotoPermissionManager、権限状態管理 |
| M2-T03 | 写真モデル定義 | Photo構造体、StorageInfo構造体 |
| M2-T04 | PHAsset拡張 | PHAsset+Extensions.swift |
| M2-T05 | PhotoRepository実装 | 写真取得・キャッシュ・ページネーション |
| M2-T06 | ページネーション対応 | fetchPhotos(page:pageSize:)実装 |
| M2-T07 | サムネイル取得 | requestImage非同期対応 |
| M2-T08 | ストレージ情報取得 | getStorageInfo()実装 |
| M2-T09 | PhotoScanner実装 | スキャン進捗管理、キャンセル対応 |
| M2-T10 | バックグラウンドスキャン | BGTaskScheduler統合 |
| M2-T11 | ThumbnailCache実装 | LRUキャッシュ、メモリ上限管理 |
| M2-T12 | 単体テスト作成 | PhotoRepositoryTests、ScannerTests |

### 実装詳細

#### PhotoPermissionManager（PhotoPermissionManager.swift）

**権限状態（PhotoPermissionStatus）**:
| 状態 | 説明 |
|------|------|
| notDetermined | 未決定（初回起動時） |
| authorized | フルアクセス許可 |
| limited | 限定アクセス（選択した写真のみ） |
| denied | 拒否 |
| restricted | 制限（ペアレンタルコントロール等） |

**主要機能**:
- `checkPermission() -> PhotoPermissionStatus` - 現在の権限状態を取得
- `requestPermission() async -> PhotoPermissionStatus` - 権限をリクエスト
- `openSettings()` - 設定アプリを開く

#### Photo モデル（Photo.swift）

**Photo構造体**:
```swift
struct Photo: Identifiable, Hashable, Sendable {
    let id: String
    let localIdentifier: String
    let creationDate: Date?
    let modificationDate: Date?
    let mediaType: MediaType
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval?
    let isFavorite: Bool
    let isHidden: Bool
    let location: CLLocation?
    let fileSize: Int64?
}
```

**MediaType enum**:
- `.image` - 静止画像
- `.video` - 動画
- `.livePhoto` - Live Photos
- `.unknown` - その他

#### StorageInfo（StorageInfo.swift）

**StorageInfo構造体**:
```swift
struct StorageInfo: Sendable {
    let totalPhotoCount: Int
    let totalVideoCount: Int
    let totalSize: Int64
    let photoSize: Int64
    let videoSize: Int64
}
```

**便利プロパティ**:
- `formattedTotalSize` - "12.5 GB"形式の表示
- `photoPercentage` / `videoPercentage` - 割合計算

#### PhotoRepository（PhotoRepository.swift）

**主要機能**:
- `fetchPhotos(page:pageSize:) async throws -> [Photo]` - ページネーション対応取得
- `fetchAllPhotos() async throws -> [Photo]` - 全写真取得
- `requestThumbnail(for:targetSize:) async throws -> UIImage` - サムネイル取得
- `requestFullImage(for:) async throws -> UIImage` - フル解像度画像取得
- `getStorageInfo() async throws -> StorageInfo` - ストレージ情報取得
- `observeChanges() -> AsyncStream<PHChange>` - ライブラリ変更監視

**ページネーション仕様**:
- デフォルトページサイズ: 100件
- 最大ページサイズ: 500件
- ソート順: 作成日降順（新しい順）

#### PhotoScanner（PhotoScanner.swift）

**スキャン状態（ScanState）**:
| 状態 | 説明 |
|------|------|
| idle | 待機中 |
| scanning(progress: Double) | スキャン中（0.0〜1.0） |
| completed(result: ScanResult) | 完了 |
| failed(error: Error) | 失敗 |
| cancelled | キャンセル済み |

**ScanResult構造体**:
```swift
struct ScanResult: Sendable {
    let photos: [Photo]
    let storageInfo: StorageInfo
    let scanDuration: TimeInterval
    let timestamp: Date
}
```

**主要機能**:
- `startScan() async throws -> ScanResult` - スキャン開始
- `cancelScan()` - スキャンキャンセル
- `state: ScanState` - 現在の状態（@Observable）

#### バックグラウンドスキャン（BackgroundScanTask.swift）

**BGTaskScheduler統合**:
- タスク識別子: `com.lightroll.photo-scan`
- 最小間隔: 1時間
- ネットワーク不要、充電不要で実行可能

**主要機能**:
- `scheduleBackgroundScan()` - バックグラウンドスキャンをスケジュール
- `handleBackgroundScan(task:)` - バックグラウンドタスク処理

#### ThumbnailCache（ThumbnailCache.swift）

**LRUキャッシュ仕様**:
- 最大エントリ数: 500件（設定可能）
- メモリ上限: 100MB
- エビクションポリシー: LRU（Least Recently Used）

**主要機能**:
- `get(for:size:) -> UIImage?` - キャッシュから取得
- `set(_:for:size:)` - キャッシュに保存
- `clear()` - キャッシュクリア
- `trimToLimit()` - メモリ上限に合わせてトリム

**キャッシュキー生成**:
- `{localIdentifier}_{width}x{height}` 形式
- サイズごとに別エントリとして管理

### M2モジュール完了サマリー

**全12タスク完了**:
- M2-T01〜T02: 権限管理
- M2-T03〜T04: データモデル
- M2-T05〜T08: PhotoRepository
- M2-T09〜T10: PhotoScanner
- M2-T11: ThumbnailCache
- M2-T12: テスト

**総工数**: 約20時間（見積24時間 → 17%効率化）

**テストカバレッジ**:
- PhotoRepositoryTests: 24テスト
- PhotoScannerTests: 18テスト
- ThumbnailCacheTests: 12テスト
- PermissionManagerTests: 8テスト
- 合計: 62テスト追加

---

## 2025-11-28: M3 Image Analysis基盤（v0.6.0）

### 完了タスク一覧（セッション impl-007）

#### M3: Image Analysis & Grouping（2タスク完了）
| タスクID | タスク名 | 内容 |
|----------|---------|------|
| M3-T01 | PhotoAnalysisResultモデル | 写真分析結果のドメインモデル |
| M3-T02 | PhotoGroupモデル | 写真グループのドメインモデル |

### 実装詳細

#### PhotoAnalysisResult（PhotoAnalysisResult.swift）

**分析指標（12種類）**:
| プロパティ | 型 | 説明 |
|-----------|-----|------|
| qualityScore | Float | 総合品質スコア（0.0〜1.0） |
| blurScore | Float | ブレスコア（高いほどブレ大） |
| brightnessScore | Float | 明るさ（0.5が適正） |
| contrastScore | Float | コントラスト |
| saturationScore | Float | 彩度 |
| faceCount | Int | 検出された顔の数 |
| faceQualityScores | [Float] | 各顔の品質スコア |
| faceAngles | [FaceAngle] | 各顔の向き情報 |
| isScreenshot | Bool | スクリーンショット判定 |
| isSelfie | Bool | 自撮り判定 |
| featurePrintHash | Data? | 特徴量ハッシュ（類似度比較用） |

**判定機能**:
- `isBlurry`: ブレ判定（閾値0.4以上）
- `isHighQuality`: 高品質判定（閾値0.7以上）
- `isLowQuality`: 低品質判定（閾値0.4未満）
- `isOverexposed`: 明るすぎ（閾値0.8以上）
- `isUnderexposed`: 暗すぎ（閾値0.2以下）
- `isDeletionCandidate`: 削除候補判定
- `issues`: 問題点リスト

**補助型**:
- `FaceAngle`: 顔の向き（yaw/pitch/roll）
- `AnalysisIssue`: 問題種別（blurry/lowQuality/overexposed/underexposed）
- `AnalysisThresholds`: 判定閾値定数
- `Builder`: ビルダーパターンでの構築

**配列拡張（Array<PhotoAnalysisResult>）**:
- `sortedByQuality()`: 品質順ソート
- `sortedBySharpness()`: シャープネス順ソート
- `filterDeletionCandidates()`: 削除候補フィルタ
- `filterHighQuality()`: 高品質フィルタ
- `filterWithFaces()`: 顔検出フィルタ
- `filterSelfies()`: 自撮りフィルタ
- `filterScreenshots()`: スクショフィルタ
- `filterBlurry()`: ブレ写真フィルタ

#### PhotoGroup（PhotoGroup.swift）

**GroupType（6種類）**:
| タイプ | 説明 | アイコン |
|--------|------|---------|
| similar | 類似写真（連写含む） | square.on.square |
| selfie | 自撮り写真 | person.crop.circle |
| screenshot | スクリーンショット | rectangle.dashed |
| blurry | ブレ・ピンボケ写真 | camera.metering.unknown |
| largeVideo | 大容量動画 | video.fill |
| duplicate | 重複写真（完全一致） | doc.on.doc |

**PhotoGroup構造体**:
```swift
struct PhotoGroup: Identifiable, Hashable, Sendable {
    let id: UUID
    let type: GroupType
    var photoIds: [String]
    var fileSizes: [Int64]
    var bestShotIndex: Int?
    var isSelected: Bool
    let createdAt: Date
    let similarityScore: Float?
    var customName: String?
}
```

**主要機能**:
- `reclaimableSize`: 削減可能サイズ計算
- `reclaimableCount`: 削減可能写真数
- `bestShotId`: ベストショットID取得
- `deletionCandidateIds`: 削除候補ID一覧
- `savingsPercentage`: 削減率計算

**ミューテーション**:
- `withBestShot(at:)`: ベストショット設定
- `withSelection(_:)`: 選択状態変更
- `adding(photoId:fileSize:)`: 写真追加
- `removing(photoId:)`: 写真削除

**補助型**:
- `PhotoGroupStatistics`: グループ統計情報
- `GroupingOptions`: グルーピングオプション（類似度閾値、フィルタ設定等）

**配列拡張（Array<PhotoGroup>）**:
- フィルタ: `filterByType()`, `validGroups`, `selectedGroups`, `withBestShot`
- ソート: `sortedByReclaimableSize`, `sortedByPhotoCount`, `sortedByDate`, `sortedByType`
- 統計: `statistics`, `totalReclaimableSize`, `totalPhotoCount`
- 検索: `group(withId:)`, `groups(containing:)`
- 一括操作: `settingSelection()`, `groupedByType`, `allDeletionCandidateIds`

### 技術的特徴

**Swift Concurrency対応**:
- 全モデルが `Sendable` 準拠
- `Builder` クラスは `NSLock` でスレッドセーフ実装
- 非同期分析処理との安全な連携

**Codable対応**:
- 全モデルが JSON シリアライズ可能
- キャッシュやファイル保存に対応

**値型設計**:
- `struct` ベースで不変性を重視
- ミューテーションは新インスタンスを返す関数型スタイル

---

*アーカイブ更新: 2025-11-28 (impl-007)*
