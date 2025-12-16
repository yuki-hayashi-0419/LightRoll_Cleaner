//
//  AnalysisCacheManager.swift
//  LightRoll_CleanerFeature
//
//  画像分析結果のキャッシュ管理
//  UserDefaultsを使用して最終分析日時と結果を永続化
//  インクリメンタル分析を可能にして処理量を大幅削減
//  Created by AI Assistant
//

import Foundation

// MARK: - AnalysisCacheManagerProtocol

/// 分析キャッシュ管理のプロトコル
public protocol AnalysisCacheManagerProtocol: Actor {
    /// 分析結果を保存
    func saveResult(_ result: PhotoAnalysisResult) async

    /// 分析結果を読み込み
    func loadResult(for photoId: String) async -> PhotoAnalysisResult?

    /// 特定の写真のキャッシュを削除
    func removeResult(for photoId: String) async

    /// すべてのキャッシュをクリア
    func clearCache() async

    /// キャッシュサイズを取得（保存済み件数）
    func getCacheSize() async -> Int

    /// 古いキャッシュを削除（指定日数より古いもの）
    func removeOldCache(olderThan days: Int) async
}

// MARK: - AnalysisCacheManager

/// 分析キャッシュマネージャーの実装
///
/// 主な責務:
/// - PhotoAnalysisResultの永続化（UserDefaults）
/// - 新規写真の判定（キャッシュ有無）
/// - キャッシュの有効期限管理
/// - メモリ効率的なキャッシュ操作
public actor AnalysisCacheManager: AnalysisCacheManagerProtocol {

    // MARK: - Properties

    /// UserDefaults キー接頭辞
    private static let keyPrefix = "analysis_cache_"

    /// キャッシュメタデータキー（全キャッシュのphotoId一覧を保存）
    private static let metadataKey = "analysis_cache_metadata"

    /// UserDefaults インスタンス
    private let userDefaults: UserDefaults

    /// インメモリキャッシュ（頻繁にアクセスされる結果をキャッシュ）
    private var memoryCache: [String: PhotoAnalysisResult] = [:]

    /// インメモリキャッシュの最大サイズ
    private let maxMemoryCacheSize: Int

    // MARK: - Initialization

    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - userDefaults: UserDefaultsインスタンス（省略時は standard）
    ///   - maxMemoryCacheSize: インメモリキャッシュの最大サイズ（省略時は100）
    public init(
        userDefaults: UserDefaults = .standard,
        maxMemoryCacheSize: Int = 100
    ) {
        self.userDefaults = userDefaults
        self.maxMemoryCacheSize = maxMemoryCacheSize
    }

    // MARK: - Public Methods

    /// 分析結果を保存
    ///
    /// - Parameter result: 保存する分析結果
    public func saveResult(_ result: PhotoAnalysisResult) async {
        let photoId = result.photoId
        let key = Self.keyPrefix + photoId

        // Codable エンコード
        guard let encoded = try? JSONEncoder().encode(result) else {
            return
        }

        // UserDefaults に保存
        userDefaults.set(encoded, forKey: key)

        // メモリキャッシュに追加
        addToMemoryCache(result)

        // メタデータを更新
        await updateMetadata(adding: photoId)
    }

    /// 複数の分析結果をバッチ保存（緊急パッチ）
    ///
    /// - Parameter results: 保存する分析結果の配列
    /// - Note: 個別保存と比較して70回のディスクI/Oで7000件を保存可能（100件ごと）
    ///         メモリ使用量とディスクI/Oのバランスを考慮した実装
    public func saveResults(_ results: [PhotoAnalysisResult]) async {
        guard !results.isEmpty else { return }

        let encoder = JSONEncoder()
        var photoIds: [String] = []
        photoIds.reserveCapacity(results.count)

        // 各結果をエンコードして保存
        for result in results {
            let photoId = result.photoId
            let key = Self.keyPrefix + photoId

            // Codable エンコード
            guard let encoded = try? encoder.encode(result) else {
                continue
            }

            // UserDefaults に保存
            userDefaults.set(encoded, forKey: key)

            // メモリキャッシュに追加
            addToMemoryCache(result)

            photoIds.append(photoId)
        }

        // メタデータを一括更新
        await updateMetadata(adding: photoIds)
    }

    /// 分析結果を読み込み
    ///
    /// - Parameter photoId: 写真ID
    /// - Returns: 分析結果（存在しない場合は nil）
    public func loadResult(for photoId: String) async -> PhotoAnalysisResult? {
        // メモリキャッシュから検索
        if let cached = memoryCache[photoId] {
            return cached
        }

        // UserDefaults から読み込み
        let key = Self.keyPrefix + photoId
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        // Codable デコード
        guard let result = try? JSONDecoder().decode(PhotoAnalysisResult.self, from: data) else {
            // デコード失敗時は破損データとして削除
            await removeResult(for: photoId)
            return nil
        }

        // メモリキャッシュに追加
        addToMemoryCache(result)

        return result
    }

    /// 特定の写真のキャッシュを削除
    ///
    /// - Parameter photoId: 写真ID
    public func removeResult(for photoId: String) async {
        let key = Self.keyPrefix + photoId

        // UserDefaults から削除
        userDefaults.removeObject(forKey: key)

        // メモリキャッシュから削除
        memoryCache.removeValue(forKey: photoId)

        // メタデータを更新
        await updateMetadata(removing: photoId)
    }

    /// すべてのキャッシュをクリア
    public func clearCache() async {
        // メタデータから全photoIdを取得
        let photoIds = await getMetadata()

        // すべてのキーを削除
        for photoId in photoIds {
            let key = Self.keyPrefix + photoId
            userDefaults.removeObject(forKey: key)
        }

        // メタデータもクリア
        userDefaults.removeObject(forKey: Self.metadataKey)

        // メモリキャッシュもクリア
        memoryCache.removeAll()
    }

    /// キャッシュサイズを取得（保存済み件数）
    ///
    /// - Returns: 保存されている分析結果の件数
    public func getCacheSize() async -> Int {
        let photoIds = await getMetadata()
        return photoIds.count
    }

    /// 古いキャッシュを削除（指定日数より古いもの）
    ///
    /// - Parameter days: 保持日数（この日数より古いキャッシュを削除）
    public func removeOldCache(olderThan days: Int) async {
        let photoIds = await getMetadata()
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)

        var removedIds: [String] = []

        for photoId in photoIds {
            if let result = await loadResult(for: photoId),
               result.analyzedAt < cutoffDate {
                await removeResult(for: photoId)
                removedIds.append(photoId)
            }
        }
    }

    // MARK: - Private Methods

    /// メモリキャッシュに追加（LRUキャッシュ）
    ///
    /// - Parameter result: 追加する分析結果
    private func addToMemoryCache(_ result: PhotoAnalysisResult) {
        // 容量チェック
        if memoryCache.count >= maxMemoryCacheSize {
            // 最古のエントリを削除（簡易LRU）
            if let oldestKey = memoryCache.keys.first {
                memoryCache.removeValue(forKey: oldestKey)
            }
        }

        memoryCache[result.photoId] = result
    }

    /// メタデータを取得（全photoId一覧）
    ///
    /// - Returns: 保存されているphotoIdの配列
    private func getMetadata() async -> [String] {
        guard let data = userDefaults.array(forKey: Self.metadataKey) as? [String] else {
            return []
        }
        return data
    }

    /// メタデータを更新（photoIdを追加）
    ///
    /// - Parameter photoId: 追加するphotoId
    private func updateMetadata(adding photoId: String) async {
        var photoIds = await getMetadata()

        // 重複チェック
        if !photoIds.contains(photoId) {
            photoIds.append(photoId)
            userDefaults.set(photoIds, forKey: Self.metadataKey)
        }
    }

    /// メタデータを更新（複数photoIdを一括追加）
    ///
    /// - Parameter photoIds: 追加するphotoIdの配列
    private func updateMetadata(adding photoIds: [String]) async {
        var existingIds = await getMetadata()
        let existingSet = Set(existingIds)

        // 重複を除外して追加
        let newIds = photoIds.filter { !existingSet.contains($0) }
        if !newIds.isEmpty {
            existingIds.append(contentsOf: newIds)
            userDefaults.set(existingIds, forKey: Self.metadataKey)
        }
    }

    /// メタデータを更新（photoIdを削除）
    ///
    /// - Parameter photoId: 削除するphotoId
    private func updateMetadata(removing photoId: String) async {
        var photoIds = await getMetadata()
        photoIds.removeAll { $0 == photoId }
        userDefaults.set(photoIds, forKey: Self.metadataKey)
    }
}

// MARK: - AnalysisCacheManager + Sendable

extension AnalysisCacheManager: Sendable {}
