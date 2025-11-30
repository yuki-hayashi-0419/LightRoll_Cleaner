//
//  TrashDataStore.swift
//  LightRoll_CleanerFeature
//
//  ゴミ箱データの永続化を担当するDataStore
//  FileManager + JSON/Codableベースでゴミ箱写真を保存・読み込み・削除
//  Created by AI Assistant
//

import Foundation

// MARK: - TrashDataStoreProtocol

/// ゴミ箱データストアのプロトコル
/// テスタビリティのためにプロトコルとして定義
public protocol TrashDataStoreProtocol: Actor {
    /// 全てのゴミ箱写真を読み込み
    /// - Returns: ゴミ箱写真の配列
    /// - Throws: TrashPhotoError.storageError
    func loadAll() async throws -> [TrashPhoto]

    /// ゴミ箱写真を保存
    /// - Parameter photos: 保存する写真配列
    /// - Throws: TrashPhotoError.storageError
    func save(_ photos: [TrashPhoto]) async throws

    /// 単一のゴミ箱写真を追加
    /// - Parameter photo: 追加する写真
    /// - Throws: TrashPhotoError.storageError
    func add(_ photo: TrashPhoto) async throws

    /// 複数のゴミ箱写真を追加
    /// - Parameter photos: 追加する写真配列
    /// - Throws: TrashPhotoError.storageError
    func addBatch(_ photos: [TrashPhoto]) async throws

    /// 指定IDの写真を削除
    /// - Parameter id: 削除する写真のID
    /// - Throws: TrashPhotoError.photoNotFound, TrashPhotoError.storageError
    func remove(id: UUID) async throws

    /// 複数の写真を削除
    /// - Parameter ids: 削除する写真のID配列
    /// - Throws: TrashPhotoError.storageError
    func removeBatch(ids: [UUID]) async throws

    /// 全ての写真を削除（ゴミ箱を空にする）
    /// - Throws: TrashPhotoError.storageError
    func removeAll() async throws

    /// 期限切れの写真を削除
    /// - Returns: 削除された写真数
    /// - Throws: TrashPhotoError.storageError
    func removeExpiredPhotos() async throws -> Int

    /// 指定IDの写真を取得
    /// - Parameter id: 写真のID
    /// - Returns: 該当する写真、見つからない場合はnil
    /// - Throws: TrashPhotoError.storageError
    func fetch(id: UUID) async throws -> TrashPhoto?

    /// ストレージ使用量を取得
    /// - Returns: 使用バイト数
    /// - Throws: TrashPhotoError.storageError
    func getStorageSize() async throws -> Int64
}

// MARK: - TrashDataStore

/// ゴミ箱データストアの実装
/// FileManagerを使用してゴミ箱写真をJSON形式で永続化
public actor TrashDataStore: TrashDataStoreProtocol {

    // MARK: - Properties

    /// JSONエンコーダ
    private let encoder: JSONEncoder

    /// JSONデコーダ
    private let decoder: JSONDecoder

    /// ファイル管理
    private let fileManager: FileManager

    /// ゴミ箱データディレクトリのURL
    private let trashDirectoryURL: URL

    /// ゴミ箱データファイルのURL
    private let trashDataFileURL: URL

    /// メモリキャッシュ（パフォーマンス最適化）
    private var cache: [TrashPhoto]?

    /// キャッシュの有効期限
    private var cacheExpiration: Date?

    /// キャッシュの有効期間（秒）
    private let cacheLifetime: TimeInterval = 60.0

    // MARK: - Initialization

    /// デフォルトイニシャライザ
    /// - Parameter fileManager: ファイルマネージャ（テスト用にカスタマイズ可能）
    public init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        // JSONエンコーダ/デコーダの設定
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        // ゴミ箱ディレクトリの設定
        guard let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw TrashPhotoError.storageError(
                underlying: NSError(
                    domain: "TrashDataStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Application Support ディレクトリにアクセスできません"]
                )
            )
        }

        // アプリ固有のディレクトリを作成
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.lightroll.cleaner"
        let appDirectory = appSupportURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
        self.trashDirectoryURL = appDirectory.appendingPathComponent("Trash", isDirectory: true)
        self.trashDataFileURL = trashDirectoryURL.appendingPathComponent("trash_data.json", isDirectory: false)

        // ディレクトリが存在しない場合は作成
        try? fileManager.createDirectory(
            at: trashDirectoryURL,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
    }

    // MARK: - Public Methods

    public func loadAll() async throws -> [TrashPhoto] {
        // キャッシュが有効な場合はそれを返す
        if let cached = cache,
           let expiration = cacheExpiration,
           Date() < expiration {
            return cached
        }

        // ファイルが存在しない場合は空配列を返す
        guard fileManager.fileExists(atPath: trashDataFileURL.path) else {
            cache = []
            cacheExpiration = Date().addingTimeInterval(cacheLifetime)
            return []
        }

        do {
            let data = try Data(contentsOf: trashDataFileURL)
            let photos = try decoder.decode([TrashPhoto].self, from: data)

            // キャッシュを更新
            cache = photos
            cacheExpiration = Date().addingTimeInterval(cacheLifetime)

            return photos
        } catch {
            throw TrashPhotoError.storageError(underlying: error)
        }
    }

    public func save(_ photos: [TrashPhoto]) async throws {
        do {
            let data = try encoder.encode(photos)
            try data.write(to: trashDataFileURL, options: .atomic)

            // キャッシュを更新
            cache = photos
            cacheExpiration = Date().addingTimeInterval(cacheLifetime)
        } catch {
            throw TrashPhotoError.storageError(underlying: error)
        }
    }

    public func add(_ photo: TrashPhoto) async throws {
        var photos = try await loadAll()
        photos.append(photo)
        try await save(photos)
    }

    public func addBatch(_ photos: [TrashPhoto]) async throws {
        var existingPhotos = try await loadAll()
        existingPhotos.append(contentsOf: photos)
        try await save(existingPhotos)
    }

    public func remove(id: UUID) async throws {
        var photos = try await loadAll()

        guard let index = photos.firstIndex(where: { $0.id == id }) else {
            throw TrashPhotoError.photoNotFound(photoId: id.uuidString)
        }

        photos.remove(at: index)
        try await save(photos)
    }

    public func removeBatch(ids: [UUID]) async throws {
        let idsSet = Set(ids)
        var photos = try await loadAll()
        photos.removeAll { idsSet.contains($0.id) }
        try await save(photos)
    }

    public func removeAll() async throws {
        try await save([])

        // ゴミ箱ディレクトリ内のその他のファイル（サムネイル等）も削除
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: trashDirectoryURL,
                includingPropertiesForKeys: nil
            )

            for url in contents where url != trashDataFileURL {
                try? fileManager.removeItem(at: url)
            }
        } catch {
            // ディレクトリが空の場合などは無視
        }
    }

    public func removeExpiredPhotos() async throws -> Int {
        let photos = try await loadAll()
        let expiredPhotos = photos.filter { $0.isExpired }
        let expiredCount = expiredPhotos.count

        if expiredCount > 0 {
            let validPhotos = photos.filter { !$0.isExpired }
            try await save(validPhotos)
        }

        return expiredCount
    }

    public func fetch(id: UUID) async throws -> TrashPhoto? {
        let photos = try await loadAll()
        return photos.first { $0.id == id }
    }

    public func getStorageSize() async throws -> Int64 {
        guard fileManager.fileExists(atPath: trashDataFileURL.path) else {
            return 0
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: trashDataFileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            throw TrashPhotoError.storageError(underlying: error)
        }
    }

    // MARK: - Private Methods

    /// キャッシュを無効化
    private func invalidateCache() {
        cache = nil
        cacheExpiration = nil
    }
}

// MARK: - Mock Implementation

#if DEBUG

/// テスト用モックDataStore
public actor MockTrashDataStore: TrashDataStoreProtocol {

    // MARK: - Mock Storage

    private var storage: [TrashPhoto] = []

    // MARK: - Test Hooks

    public var loadAllCalled = false
    public var saveCalled = false
    public var addCalled = false
    public var removeCalled = false
    public var shouldThrowError = false
    public var errorToThrow: TrashPhotoError?

    // MARK: - Initialization

    public init(initialData: [TrashPhoto] = []) {
        self.storage = initialData
    }

    // MARK: - Protocol Implementation

    public func loadAll() async throws -> [TrashPhoto] {
        loadAllCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        return storage
    }

    public func save(_ photos: [TrashPhoto]) async throws {
        saveCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        storage = photos
    }

    public func add(_ photo: TrashPhoto) async throws {
        addCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        storage.append(photo)
    }

    public func addBatch(_ photos: [TrashPhoto]) async throws {
        addCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        storage.append(contentsOf: photos)
    }

    public func remove(id: UUID) async throws {
        removeCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        guard let index = storage.firstIndex(where: { $0.id == id }) else {
            throw TrashPhotoError.photoNotFound(photoId: id.uuidString)
        }
        storage.remove(at: index)
    }

    public func removeBatch(ids: [UUID]) async throws {
        removeCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        let idsSet = Set(ids)
        storage.removeAll { idsSet.contains($0.id) }
    }

    public func removeAll() async throws {
        removeCalled = true
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        storage.removeAll()
    }

    public func removeExpiredPhotos() async throws -> Int {
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        let expiredCount = storage.filter { $0.isExpired }.count
        storage.removeAll { $0.isExpired }
        return expiredCount
    }

    public func fetch(id: UUID) async throws -> TrashPhoto? {
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        return storage.first { $0.id == id }
    }

    public func getStorageSize() async throws -> Int64 {
        if shouldThrowError {
            throw errorToThrow ?? TrashPhotoError.storageError(
                underlying: NSError(domain: "MockError", code: -1)
            )
        }
        return 0
    }

    // MARK: - Test Helper Methods

    public func reset() {
        storage.removeAll()
        loadAllCalled = false
        saveCalled = false
        addCalled = false
        removeCalled = false
        shouldThrowError = false
        errorToThrow = nil
    }
}

#endif
