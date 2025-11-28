//
//  ThumbnailCache.swift
//  LightRoll_CleanerFeature
//
//  NSCacheベースのサムネイルキャッシュシステム
//  メモリ効率的なサムネイル管理とメモリ警告への自動対応
//  Created by AI Assistant
//

import Foundation

#if canImport(UIKit)
import UIKit

// MARK: - ThumbnailCachePolicy

/// サムネイルキャッシュのポリシー設定
/// キャッシュの動作とリソース制限を定義
public struct ThumbnailCachePolicy: Sendable, Equatable {

    /// 最大キャッシュ数
    public let maxCount: Int

    /// 最大メモリ使用量（MB）
    public let maxMemoryMB: Int

    /// 削除ポリシー
    public let evictionPolicy: EvictionPolicy

    /// 削除ポリシーの種類
    public enum EvictionPolicy: Sendable, Equatable {
        /// 最も使用されていないものを優先削除（LRU）
        case leastRecentlyUsed
        /// 最も使用頻度が低いものを優先削除（LFU）
        case leastFrequentlyUsed
        /// 大きいサムネイルを優先削除
        case sizeFirst
    }

    /// 初期化
    /// - Parameters:
    ///   - maxCount: 最大キャッシュ数
    ///   - maxMemoryMB: 最大メモリ使用量（MB）
    ///   - evictionPolicy: 削除ポリシー
    public init(
        maxCount: Int,
        maxMemoryMB: Int,
        evictionPolicy: EvictionPolicy
    ) {
        self.maxCount = maxCount
        self.maxMemoryMB = maxMemoryMB
        self.evictionPolicy = evictionPolicy
    }

    /// デフォルトポリシー
    /// 一般的な使用に適した設定
    public static let `default` = ThumbnailCachePolicy(
        maxCount: 500,
        maxMemoryMB: 100,
        evictionPolicy: .leastRecentlyUsed
    )

    /// 低メモリデバイス用ポリシー
    /// メモリ使用量を抑えた設定
    public static let lowMemory = ThumbnailCachePolicy(
        maxCount: 100,
        maxMemoryMB: 30,
        evictionPolicy: .sizeFirst
    )

    /// ハイパフォーマンスポリシー
    /// キャッシュヒット率を優先した設定
    public static let highPerformance = ThumbnailCachePolicy(
        maxCount: 1000,
        maxMemoryMB: 200,
        evictionPolicy: .leastRecentlyUsed
    )

    /// 最大メモリ使用量（バイト）
    var maxMemoryBytes: Int {
        maxMemoryMB * 1024 * 1024
    }
}

// MARK: - ThumbnailCacheEntry

/// キャッシュエントリのラッパークラス
/// NSCacheで使用するためにclass型として定義
private final class ThumbnailCacheEntry: @unchecked Sendable {
    let image: UIImage
    let cost: Int
    let createdAt: Date
    var lastAccessedAt: Date
    var accessCount: Int

    init(image: UIImage, cost: Int) {
        self.image = image
        self.cost = cost
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.accessCount = 1
    }

    func recordAccess() {
        lastAccessedAt = Date()
        accessCount += 1
    }
}

// MARK: - ThumbnailCacheKey

/// キャッシュキーのラッパークラス
/// NSCacheのキーとして使用するためにNSObjectを継承
private final class ThumbnailCacheKey: NSObject {
    let assetId: String
    let size: CGSize

    init(assetId: String, size: CGSize) {
        self.assetId = assetId
        self.size = size
        super.init()
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(assetId)
        hasher.combine(Int(size.width))
        hasher.combine(Int(size.height))
        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ThumbnailCacheKey else {
            return false
        }
        return assetId == other.assetId && size == other.size
    }
}

// MARK: - ThumbnailCacheStatistics

/// キャッシュ統計情報
public struct ThumbnailCacheStatistics: Sendable, Equatable {
    /// キャッシュヒット数
    public let hitCount: Int

    /// キャッシュミス数
    public let missCount: Int

    /// 現在のキャッシュ数
    public let currentCount: Int

    /// 推定メモリ使用量（バイト）
    public let estimatedMemoryUsage: Int

    /// ヒット率（0.0〜1.0）
    public var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0.0 }
        return Double(hitCount) / Double(total)
    }

    /// 推定メモリ使用量（MB）
    public var estimatedMemoryUsageMB: Double {
        Double(estimatedMemoryUsage) / (1024.0 * 1024.0)
    }

    /// 初期化
    public init(
        hitCount: Int,
        missCount: Int,
        currentCount: Int,
        estimatedMemoryUsage: Int
    ) {
        self.hitCount = hitCount
        self.missCount = missCount
        self.currentCount = currentCount
        self.estimatedMemoryUsage = estimatedMemoryUsage
    }

    /// 空の統計
    public static let empty = ThumbnailCacheStatistics(
        hitCount: 0,
        missCount: 0,
        currentCount: 0,
        estimatedMemoryUsage: 0
    )
}

// MARK: - ThumbnailCache

/// NSCacheベースのサムネイルキャッシュ
/// スレッドセーフで自動メモリ管理を提供
public final class ThumbnailCache: @unchecked Sendable {

    // MARK: - Singleton

    /// 共有インスタンス
    public static let shared = ThumbnailCache()

    // MARK: - Properties

    /// 内部キャッシュ（NSCacheはスレッドセーフ）
    private let cache: NSCache<ThumbnailCacheKey, ThumbnailCacheEntry>

    /// 現在のポリシー
    private var _policy: ThumbnailCachePolicy

    /// 統計情報用のロック
    private let statsLock = NSLock()

    /// キャッシュヒット数
    private var _hitCount: Int = 0

    /// キャッシュミス数
    private var _missCount: Int = 0

    /// 現在のキャッシュエントリ数
    private var _currentCount: Int = 0

    /// 推定メモリ使用量（バイト）
    private var _estimatedMemoryUsage: Int = 0

    /// キャッシュされたキーのトラッキング用
    private var trackedKeys: Set<String> = []
    private let keysLock = NSLock()

    /// メモリ警告オブザーバー
    private var memoryWarningObserver: NSObjectProtocol?

    // MARK: - Public Properties

    /// キャッシュ数の上限
    public var countLimit: Int {
        get { cache.countLimit }
        set {
            cache.countLimit = newValue
            _policy = ThumbnailCachePolicy(
                maxCount: newValue,
                maxMemoryMB: _policy.maxMemoryMB,
                evictionPolicy: _policy.evictionPolicy
            )
        }
    }

    /// 総コスト上限（バイト）
    public var totalCostLimit: Int {
        get { cache.totalCostLimit }
        set {
            cache.totalCostLimit = newValue
            _policy = ThumbnailCachePolicy(
                maxCount: _policy.maxCount,
                maxMemoryMB: newValue / (1024 * 1024),
                evictionPolicy: _policy.evictionPolicy
            )
        }
    }

    /// キャッシュされたエントリ数
    public var cachedCount: Int {
        statsLock.lock()
        defer { statsLock.unlock() }
        return _currentCount
    }

    /// 推定メモリ使用量（バイト）
    public var estimatedMemoryUsage: Int {
        statsLock.lock()
        defer { statsLock.unlock() }
        return _estimatedMemoryUsage
    }

    /// 現在のポリシー
    public var policy: ThumbnailCachePolicy {
        statsLock.lock()
        defer { statsLock.unlock() }
        return _policy
    }

    // MARK: - Initialization

    /// デフォルト初期化
    public convenience init() {
        self.init(policy: .default)
    }

    /// ポリシーを指定して初期化
    /// - Parameter policy: キャッシュポリシー
    public init(policy: ThumbnailCachePolicy) {
        self.cache = NSCache<ThumbnailCacheKey, ThumbnailCacheEntry>()
        self._policy = policy

        // キャッシュの制限を設定
        cache.countLimit = policy.maxCount
        cache.totalCostLimit = policy.maxMemoryBytes

        // メモリ警告オブザーバーを設定
        setupMemoryWarningObserver()
    }

    deinit {
        // メモリ警告オブザーバーを解除
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    /// サムネイルを取得
    /// - Parameters:
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    /// - Returns: キャッシュされた画像（存在しない場合はnil）
    public func thumbnail(for assetId: String, size: CGSize) -> UIImage? {
        let key = ThumbnailCacheKey(assetId: assetId, size: size)

        guard let entry = cache.object(forKey: key) else {
            recordMiss()
            return nil
        }

        // アクセス記録を更新
        entry.recordAccess()
        recordHit()

        return entry.image
    }

    /// サムネイルを保存
    /// - Parameters:
    ///   - image: 保存する画像
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    public func setThumbnail(_ image: UIImage, for assetId: String, size: CGSize) {
        let key = ThumbnailCacheKey(assetId: assetId, size: size)
        let cost = calculateCost(for: image)
        let entry = ThumbnailCacheEntry(image: image, cost: cost)

        cache.setObject(entry, forKey: key, cost: cost)

        // 統計を更新
        updateStatsOnInsert(assetId: assetId, cost: cost)
    }

    /// キャッシュキーを生成
    /// - Parameters:
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    /// - Returns: キャッシュキー文字列
    public func cacheKey(for assetId: String, size: CGSize) -> String {
        "\(assetId)_\(Int(size.width))x\(Int(size.height))"
    }

    /// 全てのキャッシュをクリア
    public func removeAll() {
        cache.removeAllObjects()

        statsLock.lock()
        _currentCount = 0
        _estimatedMemoryUsage = 0
        statsLock.unlock()

        keysLock.lock()
        trackedKeys.removeAll()
        keysLock.unlock()
    }

    /// 特定アセットのサムネイルを削除
    /// - Parameter assetId: アセットID
    public func removeThumbnail(for assetId: String) {
        // 一般的なサイズで削除を試みる
        let commonSizes: [CGSize] = [
            ThumbnailRequestOptions.smallSize,
            ThumbnailRequestOptions.mediumSize,
            ThumbnailRequestOptions.largeSize,
            ThumbnailRequestOptions.extraLargeSize
        ]

        for size in commonSizes {
            let key = ThumbnailCacheKey(assetId: assetId, size: size)
            if let entry = cache.object(forKey: key) {
                updateStatsOnRemove(cost: entry.cost)
                cache.removeObject(forKey: key)
            }
        }

        keysLock.lock()
        trackedKeys.remove(assetId)
        keysLock.unlock()
    }

    /// 複数アセットのサムネイルを削除
    /// - Parameter assetIds: アセットID配列
    public func removeThumbnails(for assetIds: [String]) {
        for assetId in assetIds {
            removeThumbnail(for: assetId)
        }
    }

    /// 特定サイズのサムネイルを削除
    /// - Parameters:
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    public func removeThumbnail(for assetId: String, size: CGSize) {
        let key = ThumbnailCacheKey(assetId: assetId, size: size)
        if let entry = cache.object(forKey: key) {
            updateStatsOnRemove(cost: entry.cost)
            cache.removeObject(forKey: key)
        }
    }

    /// キャッシュ統計を取得
    /// - Returns: キャッシュ統計情報
    public func statistics() -> ThumbnailCacheStatistics {
        statsLock.lock()
        defer { statsLock.unlock() }

        return ThumbnailCacheStatistics(
            hitCount: _hitCount,
            missCount: _missCount,
            currentCount: _currentCount,
            estimatedMemoryUsage: _estimatedMemoryUsage
        )
    }

    /// 統計をリセット
    public func resetStatistics() {
        statsLock.lock()
        _hitCount = 0
        _missCount = 0
        statsLock.unlock()
    }

    /// ポリシーを更新
    /// - Parameter newPolicy: 新しいポリシー
    public func updatePolicy(_ newPolicy: ThumbnailCachePolicy) {
        statsLock.lock()
        _policy = newPolicy
        statsLock.unlock()

        cache.countLimit = newPolicy.maxCount
        cache.totalCostLimit = newPolicy.maxMemoryBytes
    }

    /// キャッシュにサムネイルが存在するかチェック
    /// - Parameters:
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    /// - Returns: 存在する場合はtrue
    public func contains(assetId: String, size: CGSize) -> Bool {
        let key = ThumbnailCacheKey(assetId: assetId, size: size)
        return cache.object(forKey: key) != nil
    }

    // MARK: - Memory Warning

    /// メモリ警告オブザーバーを設定
    public func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    /// メモリ警告時の処理
    public func handleMemoryWarning() {
        // キャッシュを半分クリア
        let currentCount = cachedCount

        if currentCount > 0 {
            // NSCacheは自動的にオブジェクトを削除するが、
            // 追加で制限を一時的に厳しくする
            let originalLimit = cache.countLimit
            cache.countLimit = max(1, currentCount / 2)

            // 少し待ってから元に戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.cache.countLimit = originalLimit
            }
        }

        // 統計をリセット
        resetStatistics()
    }

    // MARK: - Private Methods

    /// 画像のコスト（メモリ使用量）を計算
    /// - Parameter image: 対象の画像
    /// - Returns: 推定バイト数
    private func calculateCost(for image: UIImage) -> Int {
        // CGImageからピクセルサイズを取得
        if let cgImage = image.cgImage {
            let bytesPerRow = cgImage.bytesPerRow
            let height = cgImage.height
            return bytesPerRow * height
        }

        // フォールバック：画像サイズから推定
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        let bytesPerPixel = 4  // RGBA
        return width * height * bytesPerPixel
    }

    /// キャッシュヒットを記録
    private func recordHit() {
        statsLock.lock()
        _hitCount += 1
        statsLock.unlock()
    }

    /// キャッシュミスを記録
    private func recordMiss() {
        statsLock.lock()
        _missCount += 1
        statsLock.unlock()
    }

    /// 挿入時の統計更新
    private func updateStatsOnInsert(assetId: String, cost: Int) {
        statsLock.lock()
        _currentCount += 1
        _estimatedMemoryUsage += cost
        statsLock.unlock()

        keysLock.lock()
        trackedKeys.insert(assetId)
        keysLock.unlock()
    }

    /// 削除時の統計更新
    private func updateStatsOnRemove(cost: Int) {
        statsLock.lock()
        _currentCount = max(0, _currentCount - 1)
        _estimatedMemoryUsage = max(0, _estimatedMemoryUsage - cost)
        statsLock.unlock()
    }
}

// MARK: - ThumbnailCache + Convenience Methods

extension ThumbnailCache {

    /// サムネイルを取得し、存在しない場合はローダーで取得して保存
    /// - Parameters:
    ///   - assetId: アセットID
    ///   - size: サムネイルサイズ
    ///   - loader: サムネイルローダー（キャッシュミス時に呼ばれる）
    /// - Returns: サムネイル画像
    /// - Throws: ローダーのエラー
    public func thumbnail(
        for assetId: String,
        size: CGSize,
        loader: () async throws -> UIImage
    ) async throws -> UIImage {
        // キャッシュヒットをチェック
        if let cached = thumbnail(for: assetId, size: size) {
            return cached
        }

        // ローダーで取得
        let image = try await loader()

        // キャッシュに保存
        setThumbnail(image, for: assetId, size: size)

        return image
    }

    /// 複数のサムネイルをプリロード
    /// - Parameters:
    ///   - assetIds: アセットID配列
    ///   - size: サムネイルサイズ
    ///   - loader: サムネイルローダー
    public func preload(
        assetIds: [String],
        size: CGSize,
        loader: @escaping @Sendable (String) async throws -> UIImage
    ) async {
        await withTaskGroup(of: Void.self) { group in
            for assetId in assetIds {
                // 既にキャッシュされている場合はスキップ
                if contains(assetId: assetId, size: size) {
                    continue
                }

                group.addTask { [weak self] in
                    guard let self = self else { return }
                    do {
                        let image = try await loader(assetId)
                        self.setThumbnail(image, for: assetId, size: size)
                    } catch {
                        // プリロード時のエラーは無視
                    }
                }
            }
        }
    }
}

// MARK: - ThumbnailCache + CustomStringConvertible

extension ThumbnailCache: CustomStringConvertible {
    public var description: String {
        let stats = statistics()
        return """
        ThumbnailCache(\
        count: \(stats.currentCount), \
        memory: \(String(format: "%.1f", stats.estimatedMemoryUsageMB))MB, \
        hitRate: \(String(format: "%.1f", stats.hitRate * 100))%)
        """
    }
}
#endif
