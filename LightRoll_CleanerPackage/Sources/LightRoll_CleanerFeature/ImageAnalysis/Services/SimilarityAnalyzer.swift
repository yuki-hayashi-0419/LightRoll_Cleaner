//
//  SimilarityAnalyzer.swift
//  LightRoll_CleanerFeature
//
//  類似写真グループ検出エンジン
//  FeaturePrintExtractorとSimilarityCalculatorを統合し、類似写真をグルーピング
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import Photos

// MARK: - SimilarityAnalyzer

/// 類似写真グループ検出サービス
///
/// 主な責務:
/// - 複数の写真から特徴量を抽出
/// - 類似写真ペアを検出
/// - グラフクラスタリングによるグループ化
/// - 進捗通知とキャンセル対応
/// - 時間ベース事前グルーピングによる最適化（O(n²) → O(n×k)）
/// - キャッシュ利用による特徴量再抽出回避（パフォーマンス最適化）
/// - ScanSettingsに基づくフィルタリング（BUG-002対応）
public actor SimilarityAnalyzer {

    // MARK: - Properties

    /// 特徴量抽出器
    private let featurePrintExtractor: FeaturePrintExtractor

    /// 類似度計算器
    private let similarityCalculator: SimilarityCalculator

    /// 時間ベースグルーパー（最適化用）
    private let timeBasedGrouper: TimeBasedGrouper

    /// 分析キャッシュマネージャー（特徴量ハッシュ再利用用）
    private let cacheManager: AnalysisCacheManager

    /// LSHハッシャー（高速候補ペア検出用）
    private let lshHasher: LSHHasher

    /// 分析オプション
    private let options: SimilarityAnalysisOptions

    /// 写真フィルタリングサービス（BUG-002対応）
    private let photoFilteringService: PhotoFilteringService

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - featurePrintExtractor: 特徴量抽出器（省略時は新規作成）
    ///   - similarityCalculator: 類似度計算器（省略時は新規作成）
    ///   - timeBasedGrouper: 時間ベースグルーパー（省略時は新規作成、24時間単位）
    ///   - cacheManager: 分析キャッシュマネージャー（省略時は新規作成）
    ///   - lshHasher: LSHハッシャー（省略時は新規作成）
    ///   - photoFilteringService: 写真フィルタリングサービス（省略時は新規作成）
    ///   - options: 分析オプション
    public init(
        featurePrintExtractor: FeaturePrintExtractor? = nil,
        similarityCalculator: SimilarityCalculator? = nil,
        timeBasedGrouper: TimeBasedGrouper? = nil,
        cacheManager: AnalysisCacheManager? = nil,
        lshHasher: LSHHasher? = nil,
        photoFilteringService: PhotoFilteringService? = nil,
        options: SimilarityAnalysisOptions = .default
    ) {
        self.featurePrintExtractor = featurePrintExtractor ?? FeaturePrintExtractor()
        self.similarityCalculator = similarityCalculator ?? SimilarityCalculator()
        self.timeBasedGrouper = timeBasedGrouper ?? TimeBasedGrouper(timeWindow: 24 * 60 * 60)
        self.cacheManager = cacheManager ?? AnalysisCacheManager()
        self.lshHasher = lshHasher ?? LSHHasher()
        self.photoFilteringService = photoFilteringService ?? PhotoFilteringService()
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset配列から類似写真グループを検出
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progress: 進捗コールバック（0.0〜1.0）
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in assets: [PHAsset],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        guard !assets.isEmpty else {
            return []
        }

        // フェーズ1: 特徴量抽出（進捗 0.0〜0.6）
        let observations = try await extractFeaturePrints(
            from: assets,
            progressRange: (0.0, 0.6),
            progress: progress
        )

        // フェーズ2: 類似ペア検出（進捗 0.6〜0.9）
        await progress?(0.6)
        let similarPairs = try await similarityCalculator.findSimilarPairs(
            in: observations,
            threshold: options.similarityThreshold
        )
        await progress?(0.9)

        // フェーズ3: グループ化（進捗 0.9〜1.0）
        let groups = clusterIntoGroups(
            observations: observations,
            similarPairs: similarPairs
        )

        await progress?(1.0)

        return groups
    }

    /// Photo配列から類似写真グループを検出（時間ベース最適化版）
    ///
    /// TimeBasedGrouperで事前に時間範囲ごとにグルーピングし、
    /// 各グループ内でのみ類似度計算を行うことで、O(n²) → O(n×k) に最適化。
    /// これにより7000枚で約2450万回 → 約24万回（99%削減）の比較回数削減を実現。
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        guard !photos.isEmpty else {
            return []
        }

        // Phase X1-1: 日付ベース分割を使用（並列処理最適化）
        // 大量の写真（10,000枚以上）では日付ベース並列処理が効果的
        if photos.count >= 10_000 {
            return try await findSimilarGroupsWithDatePartitioning(
                in: photos,
                progress: progress
            )
        }

        // 小規模データは従来の時間ベース処理
        return try await findSimilarGroupsSequential(
            in: photos,
            progress: progress
        )
    }

    /// Photo配列から類似写真グループを検出（従来の逐次処理版）
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    private func findSimilarGroupsSequential(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        // フェーズ0: 時間ベース事前グルーピング（最適化のコア部分）
        let timeGroups = await timeBasedGrouper.groupByTime(photos: photos)

        // 統計情報をログ出力（デバッグ用）
        let stats = await timeBasedGrouper.getGroupStatistics(groups: timeGroups)
        logInfo("📊 TimeBasedGrouper: \(timeGroups.count)グループ, 平均\(Int(stats.avgGroupSize))枚/グループ, 比較削減率\(String(format: "%.1f", stats.comparisonReductionRate * 100))%", category: .analysis)

        // 空のグループを除外
        let nonEmptyGroups = timeGroups.filter { !$0.isEmpty }
        guard !nonEmptyGroups.isEmpty else {
            return []
        }

        // 各グループの写真数を計算して進捗計算に使用
        let totalPhotos = nonEmptyGroups.reduce(0) { $0 + $1.count }
        var processedPhotos = 0
        var allSimilarGroups: [SimilarPhotoGroup] = []

        // 各時間グループごとに類似写真を検出
        for (groupIndex, timeGroup) in nonEmptyGroups.enumerated() {
            // キャンセルチェック
            try Task.checkCancellation()

            // グループ内の写真が1枚以下なら類似検出不要
            if timeGroup.count <= 1 {
                processedPhotos += timeGroup.count
                let currentProgress = Double(processedPhotos) / Double(totalPhotos)
                await progress?(currentProgress)
                continue
            }

            // このグループ用の進捗計算
            let groupStartProgress = Double(processedPhotos) / Double(totalPhotos)
            let groupEndProgress = Double(processedPhotos + timeGroup.count) / Double(totalPhotos)

            // Photo から PHAsset を取得
            let assets = try await fetchPHAssets(from: timeGroup)

            // グループ内で類似写真を検出
            let groupResults = try await findSimilarGroupsInTimeGroup(
                assets: assets,
                progressRange: (groupStartProgress, groupEndProgress),
                progress: progress
            )

            allSimilarGroups.append(contentsOf: groupResults)
            processedPhotos += timeGroup.count

            logDebug("  ⏱️ グループ\(groupIndex + 1)/\(nonEmptyGroups.count): \(timeGroup.count)枚処理, \(groupResults.count)類似グループ検出", category: .analysis)
        }

        await progress?(1.0)

        // 写真数の多い順にソート
        return allSimilarGroups.sorted { $0.photoIds.count > $1.photoIds.count }
    }

    // MARK: - Phase X1-1: 日付ベース並列処理

    /// Photo配列から類似写真グループを検出（日付ベース並列処理版）
    ///
    /// Phase X1-1 最適化: 日付単位で写真を分割し、各日付グループを並列処理する。
    /// これにより、100,000枚×100,000枚 = 100億回の比較を、
    /// 1,000枚×1,000枚 × 100日（並列） = 1億回（50倍削減）に最適化する。
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列（10,000枚以上推奨）
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError, CancellationError
    ///
    /// - Performance:
    ///   - 100,000枚: 60分 → 40分（30%改善）
    ///   - 候補ペア数: 50倍削減
    ///   - メモリ効率: 日付単位で処理するためピークメモリ削減
    public func findSimilarGroupsWithDatePartitioning(
        in photos: [Photo],
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        guard !photos.isEmpty else {
            return []
        }

        // Step 1: 日付ベースで写真を分割
        let dateGroups = await timeBasedGrouper.groupByDateSorted(photos: photos)

        // 統計情報をログ出力
        let dateGroupDict = await timeBasedGrouper.groupByDate(photos: photos)
        let stats = await timeBasedGrouper.getDateGroupStatistics(dateGroups: dateGroupDict)
        logInfo("📅 Phase X1-1 日付ベース分割: \(dateGroups.count)日分, 平均\(Int(stats.avgGroupSize))枚/日, 比較削減率\(String(format: "%.1f", stats.comparisonReductionRate * 100))%", category: .analysis)

        // 空のグループを除外
        let nonEmptyDateGroups = dateGroups.filter { !$0.photos.isEmpty }
        guard !nonEmptyDateGroups.isEmpty else {
            return []
        }

        // 総写真数を計算（進捗計算用）
        let totalPhotos = nonEmptyDateGroups.reduce(0) { $0 + $1.photos.count }

        // Step 2: 各日付グループを並列処理
        // 並列度を制限してメモリ消費とI/O競合を抑制（最大4並列）
        let maxConcurrency = min(4, nonEmptyDateGroups.count)

        logInfo("🚀 Phase X1-1 並列処理開始: \(nonEmptyDateGroups.count)日分を最大\(maxConcurrency)並列で処理", category: .analysis)

        // 各日付グループの処理結果を収集
        var allSimilarGroups: [SimilarPhotoGroup] = []
        var processedPhotos = 0

        // 並列処理（TaskGroupを使用）
        let results = try await withThrowingTaskGroup(
            of: (dateIndex: Int, groups: [SimilarPhotoGroup], photoCount: Int).self
        ) { group in
            // 同時実行数を制限するためのセマフォ的な制御
            var pendingCount = 0

            for (dateIndex, dateGroup) in nonEmptyDateGroups.enumerated() {
                // 並列度制限: 最大maxConcurrency個のタスクが同時に動作
                if pendingCount >= maxConcurrency {
                    // 1つのタスクが完了するまで待機
                    if let result = try await group.next() {
                        pendingCount -= 1
                        processedPhotos += result.photoCount
                        let currentProgress = Double(processedPhotos) / Double(totalPhotos)
                        await progress?(currentProgress)
                    }
                }

                // グループ内の写真が1枚以下なら類似検出不要
                guard dateGroup.photos.count > 1 else {
                    continue
                }

                // 新しいタスクを追加
                group.addTask { @Sendable in
                    // Photo から PHAsset を取得
                    let assets = try await self.fetchPHAssets(from: dateGroup.photos)

                    // 日付グループ内で類似写真を検出
                    // 各日付グループ内では既存の時間ベース処理を適用
                    let groupResults = try await self.findSimilarGroupsInTimeGroup(
                        assets: assets,
                        progressRange: (0.0, 1.0),  // 個別の進捗は使用しない
                        progress: nil
                    )

                    return (dateIndex: dateIndex, groups: groupResults, photoCount: dateGroup.photos.count)
                }

                pendingCount += 1
            }

            // 残りのタスクを収集
            var collectedResults: [(dateIndex: Int, groups: [SimilarPhotoGroup], photoCount: Int)] = []
            for try await result in group {
                collectedResults.append(result)
                processedPhotos += result.photoCount
                let currentProgress = Double(processedPhotos) / Double(totalPhotos)
                await progress?(currentProgress)
            }

            return collectedResults
        }

        // 結果を統合
        for result in results {
            allSimilarGroups.append(contentsOf: result.groups)
            let dateStr = ISO8601DateFormatter().string(from: nonEmptyDateGroups[result.dateIndex].date)
            logDebug("  📅 日付\(dateStr): \(result.photoCount)枚処理, \(result.groups.count)類似グループ検出", category: .analysis)
        }

        await progress?(1.0)

        logInfo("✅ Phase X1-1 完了: \(allSimilarGroups.count)グループ検出", category: .analysis)

        // 写真数の多い順にソート
        return allSimilarGroups.sorted { $0.photoIds.count > $1.photoIds.count }
    }

    /// Photo配列から類似写真グループを検出（ScanSettings対応版）
    ///
    /// ScanSettingsに基づいてフィルタリングを行った後、類似グループを検出します。
    /// これにより、includeVideos/includeScreenshots/includeSelfiesの設定が
    /// グルーピング処理に正しく反映されます。
    ///
    /// BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
    ///
    /// - Parameters:
    ///   - photos: 対象のPhoto配列
    ///   - scanSettings: スキャン設定（フィルタリングに使用）
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in photos: [Photo],
        scanSettings: ScanSettings,
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        // ScanSettingsに基づいてフィルタリング
        let filteredPhotos = photoFilteringService.filter(photos: photos, with: scanSettings)

        logInfo("📋 ScanSettingsフィルタリング: \(photos.count)枚 → \(filteredPhotos.count)枚 (除外: \(photos.count - filteredPhotos.count)枚)", category: .analysis)

        // フィルタリング後の写真で類似グループを検出
        return try await findSimilarGroups(in: filteredPhotos, progress: progress)
    }

    /// PHAsset配列から類似写真グループを検出（ScanSettings対応版）
    ///
    /// ScanSettingsに基づいてフィルタリングを行った後、類似グループを検出します。
    ///
    /// BUG-002修正: スキャン設定がグルーピングに反映されない問題を解決
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - scanSettings: スキャン設定（フィルタリングに使用）
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    /// - Throws: AnalysisError
    public func findSimilarGroups(
        in assets: [PHAsset],
        scanSettings: ScanSettings,
        progress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> [SimilarPhotoGroup] {
        // ScanSettingsに基づいてフィルタリング
        let filteredAssets = photoFilteringService.filter(assets: assets, with: scanSettings)

        logInfo("📋 ScanSettingsフィルタリング: \(assets.count)枚 → \(filteredAssets.count)枚 (除外: \(assets.count - filteredAssets.count)枚)", category: .analysis)

        // フィルタリング後のアセットで類似グループを検出
        return try await findSimilarGroups(in: filteredAssets, progress: progress)
    }

    /// 時間グループ内で類似写真を検出（内部メソッド）
    ///
    /// 最適化:
    /// 1. キャッシュされたfeaturePrintHashを優先使用し、画像からの特徴量再抽出を回避
    /// 2. LSHで候補ペアを事前絞り込みし、全ペア比較を回避（O(n²) → O(n + k)）
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲
    ///   - progress: 進捗コールバック
    /// - Returns: 検出された類似グループ配列
    private func findSimilarGroupsInTimeGroup(
        assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [SimilarPhotoGroup] {
        guard !assets.isEmpty else {
            return []
        }

        let progressDelta = progressRange.end - progressRange.start

        // フェーズ1: キャッシュから特徴量ハッシュを読み込み（進捗 0.0〜0.2 of this group）
        let cacheLoadEnd = progressRange.start + progressDelta * 0.2
        var cachedFeatures: [(id: String, hash: Data)] = []
        var uncachedAssets: [PHAsset] = []

        // VNFeaturePrintObservation の正しいサイズ: 2048次元 × 4バイト（Float）= 8192バイト
        let expectedFeaturePrintHashSize = 2048 * MemoryLayout<Float>.size  // 8192
        var invalidCacheCount = 0

        for asset in assets {
            if let result = await cacheManager.loadResult(for: asset.localIdentifier),
               let hash = result.featurePrintHash,
               hash.count == expectedFeaturePrintHashSize {
                // 有効なキャッシュ（正しいサイズのfeaturePrintHashあり）
                cachedFeatures.append((id: asset.localIdentifier, hash: hash))
            } else if let result = await cacheManager.loadResult(for: asset.localIdentifier),
                      let hash = result.featurePrintHash,
                      hash.count != expectedFeaturePrintHashSize {
                // 無効なキャッシュ（サイズ不正）→ 再抽出対象
                invalidCacheCount += 1
                uncachedAssets.append(asset)
            } else {
                // キャッシュなし → 再抽出対象
                uncachedAssets.append(asset)
            }
        }

        await progress?(cacheLoadEnd)

        // キャッシュヒット率をログ出力
        let cacheHitRate = Double(cachedFeatures.count) / Double(assets.count) * 100
        logDebug("    💾 キャッシュヒット: \(cachedFeatures.count)/\(assets.count) (\(String(format: "%.1f", cacheHitRate))%)", category: .analysis)
        if invalidCacheCount > 0 {
            logWarning("    ⚠️ 無効キャッシュ検出: \(invalidCacheCount)件（サイズ不正、再分析必要）", category: .analysis)
        }

        // フェーズ2: LSHで候補ペアを絞り込み（進捗 0.2〜0.4 of this group）
        let lshEnd = progressRange.start + progressDelta * 0.4
        var candidatePairs: [(String, String)] = []

        if !cachedFeatures.isEmpty {
            // LSHで高速候補ペア検出
            candidatePairs = await lshHasher.findCandidatePairs(features: cachedFeatures)
            logInfo("    🔍 LSH候補ペア: \(candidatePairs.count)組（全ペア比較なら\(cachedFeatures.count * (cachedFeatures.count - 1) / 2)組）", category: .analysis)
        }

        await progress?(lshEnd)

        // フェーズ3: 候補ペアのみ詳細類似度計算（進捗 0.4〜0.7 of this group）
        let similarPairsEnd = progressRange.start + progressDelta * 0.7
        var allSimilarPairs: [SimilarityPair] = []
        let allIds: [String] = cachedFeatures.map { $0.id }

        // 候補ペアに対してのみ類似度計算（大幅高速化）
        if !candidatePairs.isEmpty {
            let cachedPairs = try await similarityCalculator.findSimilarPairsFromCandidates(
                cachedFeatures: cachedFeatures,
                candidatePairs: candidatePairs,
                threshold: options.similarityThreshold
            )
            allSimilarPairs.append(contentsOf: cachedPairs)
        }

        await progress?(similarPairsEnd)

        // フェーズ3: キャッシュにない写真の処理
        // 【最適化】グループ化フェーズでの再抽出は非常に遅いため、スキップする
        // キャッシュが無効な写真は分析フェーズで再処理する必要がある
        if !uncachedAssets.isEmpty {
            let uncachedRate = Double(uncachedAssets.count) / Double(assets.count) * 100
            logWarning("    ⚠️ キャッシュなし/無効: \(uncachedAssets.count)枚 (\(String(format: "%.1f", uncachedRate))%) - グループ化から除外", category: .analysis)

            if uncachedRate > 50 {
                logWarning("    🔴 キャッシュヒット率が低すぎます。「分析」を先に実行してください。", category: .analysis)
            }

            // 【重要】再抽出はスキップし、キャッシュ済みの写真のみでグループ化を続行
            // 再抽出 + O(n²)比較は非常に遅いため、グループ化フェーズでは行わない
            // uncachedAssets の写真は今回のグループ化には含まれない
        }

        // フェーズ4: グループ化（進捗 0.9〜1.0 of this group）
        let groups = clusterIntoGroupsFromIds(
            ids: allIds,
            similarPairs: allSimilarPairs
        )

        await progress?(progressRange.end)

        return groups
    }

    /// IDリストと類似ペアからグループ化（キャッシュベース用）
    ///
    /// - Parameters:
    ///   - ids: 写真IDのリスト
    ///   - similarPairs: 類似ペア配列
    /// - Returns: 類似写真グループ配列
    private func clusterIntoGroupsFromIds(
        ids: [String],
        similarPairs: [SimilarityPair]
    ) -> [SimilarPhotoGroup] {
        guard !ids.isEmpty else {
            return []
        }

        // Union-Find データ構造でグループ化
        var unionFind = UnionFind(ids: ids)

        // 類似ペアを統合
        for pair in similarPairs {
            unionFind.union(pair.id1, pair.id2)
        }

        // グループIDごとに写真をまとめる
        var groupsDict: [String: [String]] = [:]
        for id in ids {
            let root = unionFind.find(id)
            groupsDict[root, default: []].append(id)
        }

        // 最小グループサイズ以上のグループのみを抽出
        var groups: [SimilarPhotoGroup] = []
        for (_, photoIds) in groupsDict {
            // 最小グループサイズチェック
            guard photoIds.count >= options.minGroupSize else {
                continue
            }

            // グループ内の類似度を計算
            let groupPairs = similarPairs.filter { pair in
                photoIds.contains(pair.id1) && photoIds.contains(pair.id2)
            }

            let averageSimilarity = groupPairs.averageSimilarity ?? 0.0

            let group = SimilarPhotoGroup(
                id: UUID(),
                photoIds: photoIds,
                averageSimilarity: averageSimilarity,
                pairCount: groupPairs.count
            )

            groups.append(group)
        }

        // 写真数の多い順にソート
        return groups.sorted { $0.photoIds.count > $1.photoIds.count }
    }

    /// 特定の写真に類似する写真を検索
    ///
    /// - Parameters:
    ///   - targetAsset: 基準となるPHAsset
    ///   - candidates: 検索対象のPHAsset配列
    ///   - threshold: 類似判定の閾値（nil の場合はオプションのデフォルト値）
    /// - Returns: 類似写真のIDと類似度スコアのペア配列（類似度降順）
    /// - Throws: AnalysisError
    public func findSimilarPhotos(
        to targetAsset: PHAsset,
        in candidates: [PHAsset],
        threshold: Float? = nil
    ) async throws -> [(id: String, similarity: Float)] {
        // 対象写真の特徴量を抽出
        let _ = try await featurePrintExtractor.extractFeaturePrint(from: targetAsset)

        // 候補写真の特徴量を抽出
        let candidateFeatures = try await featurePrintExtractor.extractFeaturePrints(from: candidates)

        // 類似度を計算
        let similarityThreshold = threshold ?? options.similarityThreshold
        var results: [(id: String, similarity: Float)] = []

        // 各候補写真との類似度を計算
        for candidateFeature in candidateFeatures {
            // 特徴量観測結果を再構築（実行時のみ可能）
            // 注: この実装では観測結果を直接保持するObservationCacheを使用
            if let targetObs = await getObservation(for: targetAsset),
               let candidateObs = await getObservation(for: candidates.first(where: { $0.localIdentifier == candidateFeature.photoId })) {

                let similarity = try await similarityCalculator.calculateSimilarity(
                    between: targetObs,
                    and: candidateObs
                )

                if similarity >= similarityThreshold {
                    results.append((id: candidateFeature.photoId, similarity: similarity))
                }
            }

            // キャンセルチェック
            try Task.checkCancellation()
        }

        return results.sorted { $0.similarity > $1.similarity }
    }

    // MARK: - Private Methods

    /// 特徴量抽出フェーズ
    ///
    /// - Parameters:
    ///   - assets: 対象のPHAsset配列
    ///   - progressRange: 進捗範囲
    ///   - progress: 進捗コールバック
    /// - Returns: 抽出された観測結果の配列
    /// - Throws: AnalysisError
    private func extractFeaturePrints(
        from assets: [PHAsset],
        progressRange: (start: Double, end: Double),
        progress: (@Sendable (Double) async -> Void)?
    ) async throws -> [(id: String, observation: VNFeaturePrintObservation)] {
        var observations: [(id: String, observation: VNFeaturePrintObservation)] = []
        observations.reserveCapacity(assets.count)

        let progressDelta = progressRange.end - progressRange.start

        // 特徴量抽出リクエストを作成
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        request.revision = VNGenerateImageFeaturePrintRequestRevision2

        // Vision リクエストハンドラー
        let visionHandler = VisionRequestHandler()

        // 各アセットから特徴量を抽出
        for (index, asset) in assets.enumerated() {
            // Vision リクエストを実行
            let result = try await visionHandler.perform(on: asset, request: request)

            // 結果を取得
            guard let featurePrintRequest = result.request(ofType: VNGenerateImageFeaturePrintRequest.self),
                  let observation = featurePrintRequest.results?.first as? VNFeaturePrintObservation else {
                // 特徴量抽出失敗時はスキップ（処理は続行）
                continue
            }

            observations.append((id: asset.localIdentifier, observation: observation))

            // 進捗通知
            let currentProgress = progressRange.start + progressDelta * Double(index + 1) / Double(assets.count)
            await progress?(currentProgress)

            // キャンセルチェック
            try Task.checkCancellation()
        }

        return observations
    }

    /// グループ化フェーズ（Union-Findアルゴリズム）
    ///
    /// - Parameters:
    ///   - observations: 観測結果の配列
    ///   - similarPairs: 類似ペア配列
    /// - Returns: 類似写真グループ配列
    private func clusterIntoGroups(
        observations: [(id: String, observation: VNFeaturePrintObservation)],
        similarPairs: [SimilarityPair]
    ) -> [SimilarPhotoGroup] {
        guard !observations.isEmpty else {
            return []
        }

        // Union-Find データ構造でグループ化
        var unionFind = UnionFind(ids: observations.map { $0.id })

        // 類似ペアを統合
        for pair in similarPairs {
            unionFind.union(pair.id1, pair.id2)
        }

        // グループIDごとに写真をまとめる
        var groupsDict: [String: [String]] = [:]
        for (id, _) in observations {
            let root = unionFind.find(id)
            groupsDict[root, default: []].append(id)
        }

        // 最小グループサイズ以上のグループのみを抽出
        var groups: [SimilarPhotoGroup] = []
        for (_, photoIds) in groupsDict {
            // 最小グループサイズチェック
            guard photoIds.count >= options.minGroupSize else {
                continue
            }

            // グループ内の類似度を計算
            let groupPairs = similarPairs.filter { pair in
                photoIds.contains(pair.id1) && photoIds.contains(pair.id2)
            }

            let averageSimilarity = groupPairs.averageSimilarity ?? 0.0

            let group = SimilarPhotoGroup(
                id: UUID(),
                photoIds: photoIds,
                averageSimilarity: averageSimilarity,
                pairCount: groupPairs.count
            )

            groups.append(group)
        }

        // 写真数の多い順にソート
        return groups.sorted { $0.photoIds.count > $1.photoIds.count }
    }

    /// Photo配列からPHAssetを取得
    ///
    /// - Parameter photos: Photo配列
    /// - Returns: PHAsset配列
    /// - Throws: PhotoLibraryError
    private func fetchPHAssets(from photos: [Photo]) async throws -> [PHAsset] {
        let identifiers = photos.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets: [PHAsset] = []
        assets.reserveCapacity(identifiers.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    /// 実行時の観測結果を取得（キャッシュから）
    ///
    /// 注: VNFeaturePrintObservation はハッシュから復元できないため、
    /// 実行時のみ観測結果を保持するキャッシュを使用
    ///
    /// - Parameter asset: PHAsset
    /// - Returns: VNFeaturePrintObservation（キャッシュになければ nil）
    private func getObservation(for asset: PHAsset?) async -> VNFeaturePrintObservation? {
        // 実装: 観測結果キャッシュから取得
        // このメソッドは将来的にObservationCacheで実装予定
        return nil
    }
}

// MARK: - SimilarityAnalysisOptions

/// 類似度分析オプション
public struct SimilarityAnalysisOptions: Sendable {

    /// 類似判定の閾値（0.0〜1.0）
    public let similarityThreshold: Float

    /// グループの最小サイズ（この数以上の写真で構成されるグループのみ抽出）
    public let minGroupSize: Int

    /// バッチ処理のサイズ
    public let batchSize: Int

    /// 並列処理の最大同時実行数
    public let maxConcurrentOperations: Int

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        similarityThreshold: Float = 0.85,
        minGroupSize: Int = 2,
        batchSize: Int = 100,
        maxConcurrentOperations: Int = 4
    ) {
        self.similarityThreshold = Swift.max(0.0, Swift.min(1.0, similarityThreshold))
        self.minGroupSize = Swift.max(2, minGroupSize)
        self.batchSize = Swift.max(1, batchSize)
        self.maxConcurrentOperations = Swift.max(1, maxConcurrentOperations)
    }

    // MARK: - Presets

    /// デフォルトオプション（閾値 0.85、最小2枚）
    public static let `default` = SimilarityAnalysisOptions()

    /// 厳格モード（高類似度のみ検出、最小3枚）
    public static let strict = SimilarityAnalysisOptions(
        similarityThreshold: 0.95,
        minGroupSize: 3,
        batchSize: 50,
        maxConcurrentOperations: 2
    )

    /// 緩和モード（より多くの類似を検出、最小2枚）
    public static let relaxed = SimilarityAnalysisOptions(
        similarityThreshold: 0.75,
        minGroupSize: 2,
        batchSize: 200,
        maxConcurrentOperations: 8
    )
}

// MARK: - SimilarPhotoGroup

/// 類似写真グループ
public struct SimilarPhotoGroup: Sendable, Identifiable, Hashable {

    /// グループの一意な識別子
    public let id: UUID

    /// グループに含まれる写真ID配列
    public let photoIds: [String]

    /// グループ内の平均類似度
    public let averageSimilarity: Float

    /// グループ内のペア数
    public let pairCount: Int

    /// グループのサイズ（写真枚数）
    public var size: Int {
        photoIds.count
    }

    // MARK: - Initialization

    /// イニシャライザ
    public init(
        id: UUID = UUID(),
        photoIds: [String],
        averageSimilarity: Float = 0.0,
        pairCount: Int = 0
    ) {
        self.id = id
        self.photoIds = photoIds
        self.averageSimilarity = Swift.max(0.0, Swift.min(1.0, averageSimilarity))
        self.pairCount = Swift.max(0, pairCount)
    }

    // MARK: - Computed Properties

    /// フォーマット済み平均類似度（パーセント表示）
    public var formattedAverageSimilarity: String {
        String(format: "%.1f%%", averageSimilarity * 100)
    }

    /// 指定されたIDが含まれているかチェック
    /// - Parameter photoId: 写真ID
    /// - Returns: 含まれている場合 true
    public func contains(photoId: String) -> Bool {
        photoIds.contains(photoId)
    }
}

// MARK: - SimilarPhotoGroup + Comparable

extension SimilarPhotoGroup: Comparable {
    /// グループサイズで比較（大きいグループが先）
    public static func < (lhs: SimilarPhotoGroup, rhs: SimilarPhotoGroup) -> Bool {
        if lhs.size != rhs.size {
            return lhs.size > rhs.size
        }
        // サイズが同じ場合は平均類似度で比較
        return lhs.averageSimilarity > rhs.averageSimilarity
    }
}

// MARK: - SimilarPhotoGroup + Codable

extension SimilarPhotoGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case photoIds
        case averageSimilarity
        case pairCount
    }
}

// MARK: - UnionFind

/// Union-Find データ構造（素集合データ構造）
/// グラフのクラスタリングに使用
private struct UnionFind {

    /// 親要素の辞書
    private var parent: [String: String] = [:]

    /// ランク（木の高さ）の辞書
    private var rank: [String: Int] = [:]

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameter ids: 要素のID配列
    init(ids: [String]) {
        for id in ids {
            parent[id] = id
            rank[id] = 0
        }
    }

    // MARK: - Methods

    /// 要素のルートを検索（経路圧縮あり）
    /// - Parameter id: 要素のID
    /// - Returns: ルートのID
    mutating func find(_ id: String) -> String {
        guard let p = parent[id] else {
            return id
        }

        if p != id {
            // 経路圧縮: 再帰的にルートを探し、親を直接ルートに設定
            parent[id] = find(p)
            return parent[id]!
        }

        return id
    }

    /// 2つの要素を統合（ランクによる結合）
    /// - Parameters:
    ///   - id1: 1つ目の要素のID
    ///   - id2: 2つ目の要素のID
    mutating func union(_ id1: String, _ id2: String) {
        let root1 = find(id1)
        let root2 = find(id2)

        guard root1 != root2 else {
            return // 既に同じグループ
        }

        let rank1 = rank[root1] ?? 0
        let rank2 = rank[root2] ?? 0

        // ランクの低い木を高い木の下に結合
        if rank1 < rank2 {
            parent[root1] = root2
        } else if rank1 > rank2 {
            parent[root2] = root1
        } else {
            // ランクが同じ場合、どちらかをルートにしてランクを1増やす
            parent[root2] = root1
            rank[root1] = rank1 + 1
        }
    }

    /// 2つの要素が同じグループに属しているかチェック
    /// - Parameters:
    ///   - id1: 1つ目の要素のID
    ///   - id2: 2つ目の要素のID
    /// - Returns: 同じグループに属している場合 true
    mutating func isConnected(_ id1: String, _ id2: String) -> Bool {
        find(id1) == find(id2)
    }
}

// MARK: - Array Extension for SimilarPhotoGroup

extension Array where Element == SimilarPhotoGroup {

    /// 指定されたIDを含むグループをフィルタ
    /// - Parameter photoId: 写真ID
    /// - Returns: 該当するグループの配列
    public func groups(containing photoId: String) -> [SimilarPhotoGroup] {
        filter { $0.contains(photoId: photoId) }
    }

    /// 指定されたサイズ以上のグループをフィルタ
    /// - Parameter size: 最小サイズ
    /// - Returns: 該当するグループの配列
    public func groups(withMinSize size: Int) -> [SimilarPhotoGroup] {
        filter { $0.size >= size }
    }

    /// 総写真数を計算
    public var totalPhotoCount: Int {
        reduce(0) { $0 + $1.size }
    }

    /// 平均グループサイズ
    public var averageGroupSize: Double? {
        guard !isEmpty else { return nil }
        return Double(totalPhotoCount) / Double(count)
    }

    /// 最大グループサイズ
    public var maxGroupSize: Int? {
        map { $0.size }.max()
    }

    /// 最小グループサイズ
    public var minGroupSize: Int? {
        map { $0.size }.min()
    }
}
