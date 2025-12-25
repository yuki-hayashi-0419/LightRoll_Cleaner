# Phase 3 実装ガイド（大規模改修）

## 概要

| 項目 | 値 |
|------|-----|
| 期間 | Day 16-30 |
| 目標改善率 | 追加15%（15-20分 → 5-10分） |
| 対象施策 | C1, C2, C3 |
| 前提条件 | Phase 2 完了推奨 |
| 作成日 | 2025-12-25 |
| 作成者 | @spec-architect |

---

## C1: SwiftData への移行

### C1-1: 設計仕様

#### 変更対象

| ファイル | 変更種別 | 概要 |
|----------|----------|------|
| AnalysisCacheManager.swift | 大幅変更 | UserDefaults → SwiftData |
| SettingsRepository.swift | 大幅変更 | UserDefaults → SwiftData |
| PhotoAnalysisResult.swift | 変更 | @Model マクロ対応 |
| 新規: SwiftDataModels.swift | 新規作成 | SwiftData モデル定義 |
| 新規: SwiftDataContainer.swift | 新規作成 | ModelContainer 設定 |
| 新規: MigrationManager.swift | 新規作成 | データ移行処理 |

#### 現状の問題

```
現在のストレージ:
UserDefaults
├── 分析キャッシュ（analysis_cache_*）
├── 設定データ（user_settings）
└── メタデータ（analysis_cache_metadata）

問題点:
1. UserDefaults はキー/値ストアのため検索が非効率
2. 大量データ（100,000件）でパフォーマンス劣化
3. クエリ機能がない（全件読み込み必要）
4. 関係性（リレーション）を表現できない
5. インデックス機能がない
```

#### SwiftData 移行後の構造

```
SwiftData ModelContainer
├── PhotoAnalysisResultEntity（分析結果）
│   ├── @Attribute(.unique) photoId: String
│   ├── analyzedAt: Date（インデックス付き）
│   ├── qualityScore: Float
│   ├── featurePrintHash: Data?
│   ├── fileSize: Int64?
│   └── 他のプロパティ...
├── UserSettingsEntity（設定）
│   └── 各種設定プロパティ
└── AnalysisMetadataEntity（メタデータ）
    ├── lastAnalyzedDate: Date
    └── totalAnalyzedCount: Int

メリット:
1. SQLite ベースの高速クエリ
2. インデックスによる検索最適化
3. 遅延読み込み（Lazy Loading）
4. 自動マイグレーション対応
5. CloudKit 同期（将来対応可能）
```

#### エンティティ設計

```swift
// 擬似コード: SwiftData モデル

import SwiftData

@Model
final class PhotoAnalysisResultEntity {
    @Attribute(.unique) var photoId: String
    var id: String
    var analyzedAt: Date
    var qualityScore: Float
    var blurScore: Float
    var brightnessScore: Float
    var contrastScore: Float
    var saturationScore: Float
    var faceCount: Int
    var faceQualityScores: [Float]
    var faceAngles: Data  // Codable からシリアライズ
    var isScreenshot: Bool
    var isSelfie: Bool
    var featurePrintHash: Data?
    var fileSize: Int64?

    init(from result: PhotoAnalysisResult) {
        self.photoId = result.photoId
        self.id = result.id
        self.analyzedAt = result.analyzedAt
        // ... 他のプロパティ
    }

    func toPhotoAnalysisResult() -> PhotoAnalysisResult {
        // ドメインモデルに変換
    }
}

@Model
final class UserSettingsEntity {
    @Attribute(.unique) var settingsId: String = "default"
    var similarityThreshold: Float
    var duplicateCheckEnabled: Bool
    var largeVideoThreshold: Int64
    // ... 他の設定
}
```

---

### C1-2: 実装手順

#### Step 1: SwiftData モデル定義（Day 16-18）

```swift
// SwiftDataModels.swift

import SwiftData
import Foundation

// MARK: - PhotoAnalysisResultEntity

@Model
final class PhotoAnalysisResultEntity {
    // 主キー（写真ID）
    @Attribute(.unique)
    var photoId: String

    // 基本プロパティ
    var id: String
    var analyzedAt: Date
    var qualityScore: Float
    var blurScore: Float
    var brightnessScore: Float
    var contrastScore: Float
    var saturationScore: Float
    var faceCount: Int
    var isScreenshot: Bool
    var isSelfie: Bool

    // バイナリデータ
    var faceQualityScoresData: Data?
    var faceAnglesData: Data?
    var featurePrintHash: Data?

    // 新規追加（B1対応）
    var fileSize: Int64?

    // MARK: - Initialization

    init(from result: PhotoAnalysisResult) {
        self.photoId = result.photoId
        self.id = result.id
        self.analyzedAt = result.analyzedAt
        self.qualityScore = result.qualityScore
        self.blurScore = result.blurScore
        self.brightnessScore = result.brightnessScore
        self.contrastScore = result.contrastScore
        self.saturationScore = result.saturationScore
        self.faceCount = result.faceCount
        self.isScreenshot = result.isScreenshot
        self.isSelfie = result.isSelfie

        // 配列・構造体はシリアライズ
        self.faceQualityScoresData = try? JSONEncoder().encode(result.faceQualityScores)
        self.faceAnglesData = try? JSONEncoder().encode(result.faceAngles)
        self.featurePrintHash = result.featurePrintHash
        self.fileSize = result.fileSize
    }

    // MARK: - Conversion

    func toPhotoAnalysisResult() -> PhotoAnalysisResult {
        let faceQualityScores: [Float] = (try? JSONDecoder().decode([Float].self, from: faceQualityScoresData ?? Data())) ?? []
        let faceAngles: [FaceAngle] = (try? JSONDecoder().decode([FaceAngle].self, from: faceAnglesData ?? Data())) ?? []

        return PhotoAnalysisResult(
            id: id,
            photoId: photoId,
            analyzedAt: analyzedAt,
            qualityScore: qualityScore,
            blurScore: blurScore,
            brightnessScore: brightnessScore,
            contrastScore: contrastScore,
            saturationScore: saturationScore,
            faceCount: faceCount,
            faceQualityScores: faceQualityScores,
            faceAngles: faceAngles,
            isScreenshot: isScreenshot,
            isSelfie: isSelfie,
            featurePrintHash: featurePrintHash,
            fileSize: fileSize
        )
    }
}

// MARK: - UserSettingsEntity

@Model
final class UserSettingsEntity {
    @Attribute(.unique)
    var settingsId: String = "default"

    var similarityThreshold: Float = 0.85
    var duplicateCheckEnabled: Bool = true
    var screenshotGroupingEnabled: Bool = true
    var selfieGroupingEnabled: Bool = true
    var blurryPhotoDetectionEnabled: Bool = true
    var largeVideoThreshold: Int64 = 100_000_000  // 100MB
    var qualityThreshold: Float = 0.3
}
```

**テストポイント 1**: エンティティの初期化・変換が正常動作

#### Step 2: ModelContainer 設定（Day 18-20）

```swift
// SwiftDataContainer.swift

import SwiftData
import Foundation

@MainActor
final class SwiftDataContainer {
    // MARK: - Singleton

    static let shared = SwiftDataContainer()

    // MARK: - Properties

    let container: ModelContainer

    // MARK: - Initialization

    private init() {
        let schema = Schema([
            PhotoAnalysisResultEntity.self,
            UserSettingsEntity.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("SwiftData コンテナ初期化失敗: \(error)")
        }
    }

    // MARK: - Context Access

    var mainContext: ModelContext {
        container.mainContext
    }

    func newBackgroundContext() -> ModelContext {
        ModelContext(container)
    }
}
```

**テストポイント 2**: コンテナ初期化が成功

#### Step 3: Repository 層実装（Day 20-22）

```swift
// SwiftDataAnalysisCacheManager.swift

import SwiftData
import Foundation

public actor SwiftDataAnalysisCacheManager: AnalysisCacheManagerProtocol {
    // MARK: - Properties

    private let container: ModelContainer

    /// インメモリキャッシュ（B4対応）
    private var memoryCache: [String: PhotoAnalysisResult] = [:]
    private var accessOrder: [String] = []
    private let maxMemoryCacheSize: Int

    // MARK: - Initialization

    public init(
        container: ModelContainer,
        maxMemoryCacheSize: Int = 5_000
    ) {
        self.container = container
        self.maxMemoryCacheSize = maxMemoryCacheSize
    }

    // MARK: - Public Methods

    public func saveResult(_ result: PhotoAnalysisResult) async {
        // メモリキャッシュに追加
        addToMemoryCache(result)

        // SwiftData に保存（バックグラウンド）
        Task.detached { [container] in
            let context = ModelContext(container)
            let entity = PhotoAnalysisResultEntity(from: result)
            context.insert(entity)
            try? context.save()
        }
    }

    public func saveResults(_ results: [PhotoAnalysisResult]) async {
        guard !results.isEmpty else { return }

        // メモリキャッシュに追加
        for result in results {
            addToMemoryCache(result)
        }

        // SwiftData にバッチ保存
        Task.detached { [container] in
            let context = ModelContext(container)
            for result in results {
                let entity = PhotoAnalysisResultEntity(from: result)
                context.insert(entity)
            }
            try? context.save()
        }
    }

    public func loadResult(for photoId: String) async -> PhotoAnalysisResult? {
        // メモリキャッシュから検索
        if let cached = memoryCache[photoId] {
            updateAccessOrder(photoId)
            return cached
        }

        // SwiftData から読み込み
        let context = ModelContext(container)
        let predicate = #Predicate<PhotoAnalysisResultEntity> { $0.photoId == photoId }
        let descriptor = FetchDescriptor<PhotoAnalysisResultEntity>(predicate: predicate)

        guard let entity = try? context.fetch(descriptor).first else {
            return nil
        }

        let result = entity.toPhotoAnalysisResult()
        addToMemoryCache(result)
        return result
    }

    public func loadResults(for photoIds: [String]) async -> [PhotoAnalysisResult] {
        // バッチ読み込み（SwiftData の IN クエリ相当）
        let context = ModelContext(container)
        let predicate = #Predicate<PhotoAnalysisResultEntity> { entity in
            photoIds.contains(entity.photoId)
        }
        let descriptor = FetchDescriptor<PhotoAnalysisResultEntity>(predicate: predicate)

        guard let entities = try? context.fetch(descriptor) else {
            return []
        }

        return entities.map { $0.toPhotoAnalysisResult() }
    }

    public func removeResult(for photoId: String) async {
        memoryCache.removeValue(forKey: photoId)

        Task.detached { [container] in
            let context = ModelContext(container)
            let predicate = #Predicate<PhotoAnalysisResultEntity> { $0.photoId == photoId }
            try? context.delete(model: PhotoAnalysisResultEntity.self, where: predicate)
        }
    }

    public func clearCache() async {
        memoryCache.removeAll()
        accessOrder.removeAll()

        Task.detached { [container] in
            let context = ModelContext(container)
            try? context.delete(model: PhotoAnalysisResultEntity.self)
        }
    }

    public func getCacheSize() async -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PhotoAnalysisResultEntity>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    public func removeOldCache(olderThan days: Int) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        Task.detached { [container] in
            let context = ModelContext(container)
            let predicate = #Predicate<PhotoAnalysisResultEntity> { $0.analyzedAt < cutoffDate }
            try? context.delete(model: PhotoAnalysisResultEntity.self, where: predicate)
        }

        // メモリキャッシュからも削除
        let keysToRemove = memoryCache.filter { $0.value.analyzedAt < cutoffDate }.keys
        for key in keysToRemove {
            memoryCache.removeValue(forKey: key)
        }
    }

    // MARK: - 高速クエリメソッド（新規）

    /// 特定日時以降の分析結果を取得（差分分析用）
    public func loadResultsAfter(date: Date) async -> [PhotoAnalysisResult] {
        let context = ModelContext(container)
        let predicate = #Predicate<PhotoAnalysisResultEntity> { $0.analyzedAt >= date }
        let descriptor = FetchDescriptor<PhotoAnalysisResultEntity>(predicate: predicate)

        guard let entities = try? context.fetch(descriptor) else {
            return []
        }

        return entities.map { $0.toPhotoAnalysisResult() }
    }

    /// fileSize が nil の結果を取得（B1マイグレーション用）
    public func loadResultsWithoutFileSize() async -> [PhotoAnalysisResult] {
        let context = ModelContext(container)
        let predicate = #Predicate<PhotoAnalysisResultEntity> { $0.fileSize == nil }
        let descriptor = FetchDescriptor<PhotoAnalysisResultEntity>(predicate: predicate)

        guard let entities = try? context.fetch(descriptor) else {
            return []
        }

        return entities.map { $0.toPhotoAnalysisResult() }
    }

    // MARK: - Private Methods

    private func addToMemoryCache(_ result: PhotoAnalysisResult) {
        // 既存エントリの順序更新
        if memoryCache[result.photoId] != nil {
            accessOrder.removeAll { $0 == result.photoId }
        }

        memoryCache[result.photoId] = result
        accessOrder.append(result.photoId)

        // LRU 削除
        while memoryCache.count > maxMemoryCacheSize {
            if let oldest = accessOrder.first {
                accessOrder.removeFirst()
                memoryCache.removeValue(forKey: oldest)
            }
        }
    }

    private func updateAccessOrder(_ photoId: String) {
        accessOrder.removeAll { $0 == photoId }
        accessOrder.append(photoId)
    }
}
```

**テストポイント 3**: CRUD 操作が正常動作

#### Step 4: マイグレーション実装（Day 22-24）

```swift
// MigrationManager.swift

import Foundation
import SwiftData

public actor MigrationManager {
    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let swiftDataContainer: ModelContainer

    // MARK: - Initialization

    public init(
        userDefaults: UserDefaults = .standard,
        swiftDataContainer: ModelContainer
    ) {
        self.userDefaults = userDefaults
        self.swiftDataContainer = swiftDataContainer
    }

    // MARK: - Public Methods

    /// UserDefaults から SwiftData へのマイグレーション
    public func migrateFromUserDefaults(
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws {
        // 1. マイグレーション済みかチェック
        let migrationKey = "swiftdata_migration_completed"
        if userDefaults.bool(forKey: migrationKey) {
            logInfo("SwiftData マイグレーション: 既に完了済み")
            return
        }

        logInfo("SwiftData マイグレーション: 開始")

        // 2. メタデータからキャッシュキー一覧を取得
        let metadataKey = "analysis_cache_metadata"
        guard let metadata = userDefaults.array(forKey: metadataKey) as? [String] else {
            logInfo("SwiftData マイグレーション: 既存キャッシュなし")
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        let totalCount = metadata.count
        var migratedCount = 0

        // 3. バッチ単位でマイグレーション
        let batchSize = 500
        let batches = metadata.chunked(into: batchSize)

        for (batchIndex, batch) in batches.enumerated() {
            let context = ModelContext(swiftDataContainer)

            for photoId in batch {
                let key = "analysis_cache_\(photoId)"
                guard let data = userDefaults.data(forKey: key),
                      let result = try? JSONDecoder().decode(PhotoAnalysisResult.self, from: data) else {
                    continue
                }

                let entity = PhotoAnalysisResultEntity(from: result)
                context.insert(entity)
                migratedCount += 1
            }

            // バッチ保存
            try context.save()

            // 進捗通知
            let progressValue = Double(batchIndex + 1) / Double(batches.count)
            await progress?(progressValue)

            logInfo("SwiftData マイグレーション: \(migratedCount)/\(totalCount) 件完了")
        }

        // 4. マイグレーション完了フラグ
        userDefaults.set(true, forKey: migrationKey)
        logInfo("SwiftData マイグレーション: 完了（\(migratedCount) 件）")
    }

    /// 旧キャッシュのクリーンアップ（マイグレーション後に実行）
    public func cleanupOldCache() async {
        let metadataKey = "analysis_cache_metadata"
        guard let metadata = userDefaults.array(forKey: metadataKey) as? [String] else {
            return
        }

        // 各キャッシュエントリを削除
        for photoId in metadata {
            let key = "analysis_cache_\(photoId)"
            userDefaults.removeObject(forKey: key)
        }

        // メタデータを削除
        userDefaults.removeObject(forKey: metadataKey)

        logInfo("旧キャッシュクリーンアップ: 完了")
    }
}
```

**テストポイント 4**: マイグレーションが正常完了、データ整合性確認

---

### C1-3: 影響範囲分析

#### 影響を受けるファイル

| ファイル | 影響度 | 変更内容 |
|----------|--------|----------|
| AnalysisCacheManager.swift | 高 | SwiftData 版に置換 |
| SettingsRepository.swift | 高 | SwiftData 版に置換 |
| PhotoAnalysisResult.swift | 中 | Codable 維持、@Model 非適用 |
| LightRoll_CleanerApp.swift | 低 | ModelContainer 初期化追加 |
| 新規: SwiftDataModels.swift | - | 新規作成 |
| 新規: SwiftDataContainer.swift | - | 新規作成 |
| 新規: SwiftDataAnalysisCacheManager.swift | - | 新規作成 |
| 新規: MigrationManager.swift | - | 新規作成 |

#### 依存関係図

```
SwiftDataContainer
    ↓
SwiftDataAnalysisCacheManager
    ↓ 使用
├── AnalysisRepository
├── PhotoGrouper
├── SimilarityAnalyzer
└── PhotoAnalyzer

MigrationManager
    ↓ 使用
├── UserDefaults（読み取り）
└── SwiftDataContainer（書き込み）
```

#### 破壊的変更

- **内部実装の変更**: ストレージ層が完全に置換
- **API互換性**: 維持（AnalysisCacheManagerProtocol 準拠）
- **データ互換性**: マイグレーション必須

---

### C1-4: テスト計画

#### 単体テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| C1-UT-01 | エンティティ初期化 | 正常動作 |
| C1-UT-02 | エンティティ → ドメインモデル変換 | データ一致 |
| C1-UT-03 | CRUD 操作 | 正常動作 |
| C1-UT-04 | バッチ保存 | 正常動作 |
| C1-UT-05 | Predicate クエリ | 正しい結果 |
| C1-UT-06 | インデックス効率 | 高速検索 |

#### 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| C1-IT-01 | マイグレーション実行 | データ完全移行 |
| C1-IT-02 | マイグレーション後の分析処理 | 正常動作 |
| C1-IT-03 | 旧キャッシュクリーンアップ | 完全削除 |
| C1-IT-04 | アプリ再起動後のデータ永続化 | データ維持 |

#### パフォーマンステスト

| テストID | テスト内容 | 合格基準 |
|----------|-----------|----------|
| C1-PT-01 | 100,000件の読み込み時間 | UserDefaults 比 -50% |
| C1-PT-02 | Predicate クエリ速度 | 100ms 未満 |
| C1-PT-03 | バッチ保存速度 | 10,000件/秒 以上 |
| C1-PT-04 | ストレージサイズ | UserDefaults 比同等以下 |

---

### C1-5: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| マイグレーション失敗 | 高 | 中 | ロールバック手順、バックアップ |
| SwiftData クラッシュ | 高 | 低 | try/catch の徹底、フォールバック |
| データ破損 | 高 | 低 | 整合性チェック、再分析機能 |
| パフォーマンス劣化 | 中 | 低 | ベンチマーク測定、インデックス最適化 |

#### ロールバック手順

1. マイグレーションフラグをリセット
2. SwiftDataAnalysisCacheManager を旧実装に差し替え
3. 旧キャッシュが残っていれば復元可能
4. 旧キャッシュ削除前にロールバック判断

---

## C2: バックグラウンド処理

### C2-1: 設計仕様

#### 変更対象

| ファイル | 変更種別 | 概要 |
|----------|----------|------|
| 新規: BackgroundAnalysisManager.swift | 新規作成 | BGTaskScheduler 管理 |
| 新規: BackgroundTasks.swift | 新規作成 | バックグラウンドタスク定義 |
| Info.plist | 変更 | BGTaskSchedulerPermittedIdentifiers 追加 |
| LightRoll_CleanerApp.swift | 変更 | バックグラウンドタスク登録 |

#### 現状の問題

```
現在の動作:
- 分析処理はフォアグラウンドのみ
- アプリ終了時に処理が中断
- 大量写真の分析には長時間のフォアグラウンド維持が必要

問題点:
- ユーザー体験の悪化（アプリを開き続ける必要）
- バッテリー消費の増加
- 中断時の再開ロジックの複雑さ
```

#### バックグラウンド処理設計

```
BGProcessingTask（長時間処理用）:
- 夜間充電中に実行
- 新規写真の分析処理
- キャッシュのクリーンアップ

BGAppRefreshTask（短時間処理用）:
- 定期的な差分チェック
- 次回フォアグラウンド時の準備
```

---

### C2-2: 実装手順

#### Step 1: Info.plist 設定

```xml
<!-- Info.plist に追加 -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.lightrollcleaner.analysis</string>
    <string>com.example.lightrollcleaner.refresh</string>
</array>
```

#### Step 2: バックグラウンドタスク定義

```swift
// BackgroundTasks.swift

import BackgroundTasks
import Foundation

public enum BackgroundTaskIdentifier {
    static let analysis = "com.example.lightrollcleaner.analysis"
    static let refresh = "com.example.lightrollcleaner.refresh"
}

public struct BackgroundTaskRegistration {
    /// アプリ起動時に呼び出す
    @MainActor
    public static func register() {
        // 分析タスク（長時間処理）
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.analysis,
            using: nil
        ) { task in
            Task {
                await handleAnalysisTask(task as! BGProcessingTask)
            }
        }

        // リフレッシュタスク（短時間処理）
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.refresh,
            using: nil
        ) { task in
            Task {
                await handleRefreshTask(task as! BGAppRefreshTask)
            }
        }
    }

    private static func handleAnalysisTask(_ task: BGProcessingTask) async {
        // 分析マネージャーを取得
        let manager = BackgroundAnalysisManager.shared

        // 期限切れハンドラ
        task.expirationHandler = {
            Task {
                await manager.cancelCurrentTask()
            }
        }

        // 分析実行
        let success = await manager.performBackgroundAnalysis()
        task.setTaskCompleted(success: success)

        // 次回タスクをスケジュール
        scheduleNextAnalysisTask()
    }

    private static func handleRefreshTask(_ task: BGAppRefreshTask) async {
        let manager = BackgroundAnalysisManager.shared

        task.expirationHandler = {
            Task {
                await manager.cancelCurrentTask()
            }
        }

        let success = await manager.performQuickRefresh()
        task.setTaskCompleted(success: success)

        scheduleNextRefreshTask()
    }

    public static func scheduleNextAnalysisTask() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifier.analysis)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true  // 充電中のみ
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)  // 4時間後

        do {
            try BGTaskScheduler.shared.submit(request)
            logInfo("バックグラウンド分析タスクをスケジュール")
        } catch {
            logError("バックグラウンド分析タスクのスケジュール失敗: \(error)")
        }
    }

    public static func scheduleNextRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskIdentifier.refresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15分後

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logError("リフレッシュタスクのスケジュール失敗: \(error)")
        }
    }
}
```

#### Step 3: BackgroundAnalysisManager 実装

```swift
// BackgroundAnalysisManager.swift

import Foundation
import Photos

public actor BackgroundAnalysisManager {
    // MARK: - Singleton

    public static let shared = BackgroundAnalysisManager()

    // MARK: - Properties

    private var currentTask: Task<Void, Never>?
    private let analysisRepository: AnalysisRepositoryProtocol
    private let cacheManager: AnalysisCacheManagerProtocol

    // MARK: - Initialization

    private init() {
        // 依存関係の解決（実際は DI コンテナ使用推奨）
        self.analysisRepository = AnalysisRepository.shared
        self.cacheManager = SwiftDataAnalysisCacheManager.shared
    }

    // MARK: - Public Methods

    /// バックグラウンド分析を実行
    public func performBackgroundAnalysis() async -> Bool {
        logInfo("バックグラウンド分析: 開始")

        // 写真ライブラリへのアクセス確認
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized else {
            logWarning("バックグラウンド分析: 写真アクセス権限なし")
            return false
        }

        // 未分析の写真を取得
        let lastAnalyzedDate = await getLastAnalyzedDate()
        let newPhotos = await fetchPhotosAfter(date: lastAnalyzedDate)

        guard !newPhotos.isEmpty else {
            logInfo("バックグラウンド分析: 新規写真なし")
            return true
        }

        logInfo("バックグラウンド分析: \(newPhotos.count) 件の新規写真を処理")

        // バッチ処理（バックグラウンドは時間制限あり）
        let batchSize = 100
        var processedCount = 0

        for batch in newPhotos.chunked(into: batchSize) {
            // タスクキャンセルチェック
            if Task.isCancelled {
                logInfo("バックグラウンド分析: キャンセルされました")
                break
            }

            do {
                try await analysisRepository.analyzePhotos(Array(batch), progress: nil)
                processedCount += batch.count
                logInfo("バックグラウンド分析: \(processedCount)/\(newPhotos.count) 件完了")
            } catch {
                logError("バックグラウンド分析エラー: \(error)")
                // エラーが発生しても続行
            }
        }

        // 最終分析日時を更新
        await updateLastAnalyzedDate()

        logInfo("バックグラウンド分析: 完了（\(processedCount) 件処理）")
        return true
    }

    /// クイックリフレッシュ（差分チェックのみ）
    public func performQuickRefresh() async -> Bool {
        logInfo("クイックリフレッシュ: 開始")

        // 新規写真の件数をカウント
        let lastAnalyzedDate = await getLastAnalyzedDate()
        let newPhotosCount = await countPhotosAfter(date: lastAnalyzedDate)

        // 次回フォアグラウンド時に表示するための情報を保存
        UserDefaults.standard.set(newPhotosCount, forKey: "pending_analysis_count")

        logInfo("クイックリフレッシュ: \(newPhotosCount) 件の未分析写真")
        return true
    }

    /// 現在のタスクをキャンセル
    public func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        logInfo("バックグラウンドタスク: キャンセル")
    }

    // MARK: - Private Methods

    private func getLastAnalyzedDate() async -> Date {
        UserDefaults.standard.object(forKey: "last_analyzed_date") as? Date ?? .distantPast
    }

    private func updateLastAnalyzedDate() async {
        UserDefaults.standard.set(Date(), forKey: "last_analyzed_date")
    }

    private func fetchPhotosAfter(date: Date) async -> [PHAsset] {
        // PHAsset を取得するロジック
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate > %@", date as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    private func countPhotosAfter(date: Date) async -> Int {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate > %@", date as NSDate)
        return PHAsset.fetchAssets(with: options).count
    }
}
```

#### Step 4: アプリ起動時の登録

```swift
// LightRoll_CleanerApp.swift

import SwiftUI
import BackgroundTasks

@main
struct LightRoll_CleanerApp: App {
    init() {
        // バックグラウンドタスクを登録
        BackgroundTaskRegistration.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 初回起動時にスケジュール
                    BackgroundTaskRegistration.scheduleNextAnalysisTask()
                    BackgroundTaskRegistration.scheduleNextRefreshTask()
                }
        }
    }
}
```

---

### C2-3: テスト計画

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| C2-UT-01 | タスク登録 | エラーなし |
| C2-UT-02 | タスクスケジュール | エラーなし |
| C2-IT-01 | バックグラウンド分析実行 | 正常完了 |
| C2-IT-02 | タスク期限切れ時のキャンセル | 正常中断 |
| C2-IT-03 | 電源接続時のみ実行 | 条件判定正常 |

---

### C2-4: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| システムによるタスクキル | 中 | 高 | 進捗保存、再開ロジック |
| バッテリー消費 | 中 | 中 | requiresExternalPower 設定 |
| 権限問題 | 高 | 低 | 事前の権限チェック |

---

## C3: 差分グループ化

### C3-1: 設計仕様

#### 変更対象

| ファイル | 変更種別 | 概要 |
|----------|----------|------|
| PhotoGrouper.swift | 変更 | 差分グループ化ロジック追加 |
| AnalysisRepository.swift | 変更 | 差分検出ロジック統合 |
| 新規: IncrementalGrouper.swift | 新規作成 | 差分グループ化専用クラス |

#### 現状の問題

```
現在の処理:
1. 全写真を取得
2. 全写真を分析（キャッシュ活用）
3. 全写真をグループ化 ← ここが毎回 O(n²) に近い

問題点:
- 既存グループに変化がなくても再計算
- 新規写真追加時も全体再計算
```

#### 差分グループ化設計

```
差分グループ化:
1. 新規写真のみを検出
2. 新規写真を既存グループに追加可能か判定
3. 既存グループとマッチしない場合のみ新規グループ検討
4. 削除された写真を含むグループのみ再計算

メリット:
- 新規写真追加時: O(n) → O(k)（k = 新規写真数）
- 削除時: 影響グループのみ再計算
```

---

### C3-2: 実装手順

#### Step 1: 差分検出ロジック

```swift
// IncrementalGrouper.swift

import Foundation

public actor IncrementalGrouper {
    // MARK: - Properties

    private let cacheManager: AnalysisCacheManagerProtocol
    private let photoGrouper: PhotoGrouperProtocol
    private let lshHasher: LSHHasher

    /// 既存グループのキャッシュ
    private var cachedGroups: [PhotoGroup] = []
    private var lastGroupingDate: Date?

    // MARK: - Initialization

    public init(
        cacheManager: AnalysisCacheManagerProtocol,
        photoGrouper: PhotoGrouperProtocol,
        lshHasher: LSHHasher
    ) {
        self.cacheManager = cacheManager
        self.photoGrouper = photoGrouper
        self.lshHasher = lshHasher
    }

    // MARK: - Public Methods

    /// 差分グループ化を実行
    public func groupIncrementally(
        currentPhotoIds: Set<String>,
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [PhotoGroup] {
        // 1. 前回のグループ化状態を復元
        let previousPhotoIds = Set(cachedGroups.flatMap { $0.photoIds })

        // 2. 差分を計算
        let addedIds = currentPhotoIds.subtracting(previousPhotoIds)
        let removedIds = previousPhotoIds.subtracting(currentPhotoIds)

        logInfo("差分グループ化: 追加 \(addedIds.count) 件、削除 \(removedIds.count) 件")

        // 3. 変更がない場合はキャッシュを返す
        if addedIds.isEmpty && removedIds.isEmpty {
            logInfo("差分グループ化: 変更なし、キャッシュを使用")
            return cachedGroups
        }

        await progress?(0.1)

        // 4. 削除された写真を含むグループを特定
        var groupsToRecalculate: Set<Int> = []
        for (index, group) in cachedGroups.enumerated() {
            if !removedIds.isDisjoint(with: Set(group.photoIds)) {
                groupsToRecalculate.insert(index)
            }
        }

        await progress?(0.2)

        // 5. 新規写真を既存グループにマッチング
        let addedResults = await loadAnalysisResults(for: Array(addedIds))
        var unmatchedAdditions: [PhotoAnalysisResult] = []

        for result in addedResults {
            var matched = false

            for (index, group) in cachedGroups.enumerated() where !groupsToRecalculate.contains(index) {
                if try await canAddToGroup(result, group: group) {
                    // グループに追加
                    cachedGroups[index] = group.adding(photoId: result.photoId)
                    matched = true
                    break
                }
            }

            if !matched {
                unmatchedAdditions.append(result)
            }
        }

        await progress?(0.5)

        // 6. マッチしなかった写真と再計算グループを処理
        var updatedGroups = cachedGroups.enumerated().compactMap { index, group in
            groupsToRecalculate.contains(index) ? nil : group
        }

        // 削除された写真を除去
        updatedGroups = updatedGroups.map { group in
            let filteredIds = group.photoIds.filter { !removedIds.contains($0) }
            return group.with(photoIds: filteredIds)
        }.filter { $0.photoIds.count >= 2 }  // 2枚以上のグループのみ維持

        await progress?(0.7)

        // 7. 再計算が必要な写真を収集
        var photosToRegroup: [String] = unmatchedAdditions.map { $0.photoId }
        for index in groupsToRecalculate {
            let group = cachedGroups[index]
            let validIds = group.photoIds.filter { !removedIds.contains($0) }
            photosToRegroup.append(contentsOf: validIds)
        }

        // 8. 再グループ化が必要な場合
        if !photosToRegroup.isEmpty {
            let assets = try await fetchAssets(for: photosToRegroup)
            let newGroups = try await photoGrouper.groupPhotos(assets, progress: nil)
            updatedGroups.append(contentsOf: newGroups)
        }

        await progress?(1.0)

        // 9. キャッシュを更新
        cachedGroups = updatedGroups
        lastGroupingDate = Date()

        logInfo("差分グループ化: 完了（\(updatedGroups.count) グループ）")
        return updatedGroups
    }

    // MARK: - Private Methods

    private func canAddToGroup(_ result: PhotoAnalysisResult, group: PhotoGroup) async throws -> Bool {
        switch group.type {
        case .similar:
            // LSH でマッチング判定
            guard let hash = result.featurePrintHash else { return false }
            let lshHash = await lshHasher.computeLSHHash(from: hash)

            // グループ内の任意の写真と同じバケットになるか
            for photoId in group.photoIds {
                if let existingResult = await cacheManager.loadResult(for: photoId),
                   let existingHash = existingResult.featurePrintHash {
                    let existingLSH = await lshHasher.computeLSHHash(from: existingHash)
                    if lshHash == existingLSH {
                        return true
                    }
                }
            }
            return false

        case .duplicate:
            // ファイルサイズでマッチング
            guard let fileSize = result.fileSize else { return false }
            return group.fileSizes.contains(fileSize)

        default:
            return false
        }
    }

    private func loadAnalysisResults(for photoIds: [String]) async -> [PhotoAnalysisResult] {
        var results: [PhotoAnalysisResult] = []
        for photoId in photoIds {
            if let result = await cacheManager.loadResult(for: photoId) {
                results.append(result)
            }
        }
        return results
    }

    private func fetchAssets(for photoIds: [String]) async throws -> [PHAsset] {
        // PHAsset を取得
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: photoIds, options: nil)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}

// MARK: - PhotoGroup Extension

extension PhotoGroup {
    func adding(photoId: String) -> PhotoGroup {
        var newPhotoIds = photoIds
        newPhotoIds.append(photoId)
        return PhotoGroup(
            type: type,
            photoIds: newPhotoIds,
            fileSizes: fileSizes,
            similarityScore: similarityScore
        )
    }

    func with(photoIds: [String]) -> PhotoGroup {
        PhotoGroup(
            type: type,
            photoIds: photoIds,
            fileSizes: fileSizes,
            similarityScore: similarityScore
        )
    }
}
```

---

### C3-3: テスト計画

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| C3-UT-01 | 追加のみの差分処理 | 追加分のみ処理 |
| C3-UT-02 | 削除のみの差分処理 | 影響グループのみ再計算 |
| C3-UT-03 | 追加＋削除の混合 | 正しく処理 |
| C3-UT-04 | 変更なしの場合 | キャッシュ返却 |
| C3-PT-01 | 100件追加時の処理時間 | 全体再計算の 10% 以下 |

---

### C3-4: リスク分析

| リスク | 影響度 | 発生確率 | 対策 |
|--------|--------|----------|------|
| グループの不整合 | 高 | 中 | 定期的な全体再計算 |
| マッチング精度の低下 | 中 | 中 | 閾値調整、フォールバック |
| キャッシュの肥大化 | 低 | 低 | 定期クリーンアップ |

---

## Phase 3 統合テスト計画

### P3-INT: 統合テスト

| テストID | テスト内容 | 期待結果 |
|----------|-----------|----------|
| P3-INT-01 | C1-C3 全適用後の分析処理 | 正常完了 |
| P3-INT-02 | SwiftData + バックグラウンド連携 | 正常動作 |
| P3-INT-03 | 差分グループ化の精度検証 | 95% 一致 |
| P3-INT-04 | 100,000枚での E2E テスト | 5-10分以内 |

### P3-PERF: 最終パフォーマンス計測

| 計測項目 | 計測方法 | 目標値 |
|----------|----------|--------|
| 初回処理時間（100,000枚） | Instruments | 5-10分 |
| 2回目処理時間（100,000枚） | Instruments | 1分以内 |
| 差分処理時間（1,000枚追加） | Instruments | 30秒以内 |
| ピークメモリ使用量 | Instruments | 1GB未満 |
| ストレージ使用量 | デバイス設定 | 500MB未満 |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 1.0 | 2025-12-25 | 初版作成 |
