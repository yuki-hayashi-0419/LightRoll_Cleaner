//
//  PhotoGroupRepository.swift
//  LightRoll_CleanerFeature
//
//  PhotoGroupの永続化を管理するリポジトリ
//  JSONファイルベースの軽量な実装
//  Created by AI Assistant
//

import Foundation

// MARK: - PhotoGroupRepositoryProtocol

/// PhotoGroup永続化リポジトリのプロトコル
public protocol PhotoGroupRepositoryProtocol: Sendable {
    /// グループを保存
    /// - Parameter groups: 保存するPhotoGroup配列
    /// - Throws: 保存に失敗した場合
    func save(_ groups: [PhotoGroup]) async throws

    /// グループを読み込み
    /// - Returns: 保存されているPhotoGroup配列（なければ空配列）
    /// - Throws: 読み込みに失敗した場合
    func load() async throws -> [PhotoGroup]

    /// 保存されているグループをクリア
    /// - Throws: クリアに失敗した場合
    func clear() async throws

    /// グループが保存されているかチェック
    /// - Returns: グループが存在する場合true
    func hasGroups() async -> Bool
}

// MARK: - FileSystemPhotoGroupRepository

/// JSONファイルベースのPhotoGroup永続化リポジトリ
public final class FileSystemPhotoGroupRepository: PhotoGroupRepositoryProtocol {

    // MARK: - Properties

    /// 保存先ファイルURL
    private let fileURL: URL

    /// JSONエンコーダー
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// JSONデコーダー
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// ファイルマネージャー
    private let fileManager: FileManager

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - filename: 保存ファイル名（デフォルト: "photo_groups.json"）
    ///   - fileManager: ファイルマネージャー（テスト用）
    /// - Throws: 保存先ディレクトリの取得に失敗した場合
    public init(
        filename: String = "photo_groups.json",
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager

        // Documentsディレクトリを取得
        guard let documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw PhotoGroupRepositoryError.directoryNotFound
        }

        self.fileURL = documentsDirectory.appendingPathComponent(filename)
    }

    // MARK: - PhotoGroupRepositoryProtocol

    /// グループを保存
    public func save(_ groups: [PhotoGroup]) async throws {
        do {
            let data = try encoder.encode(groups)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            throw PhotoGroupRepositoryError.saveFailed(underlying: error)
        }
    }

    /// グループを読み込み
    public func load() async throws -> [PhotoGroup] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []  // ファイルがない場合は空配列
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let groups = try decoder.decode([PhotoGroup].self, from: data)
            return groups
        } catch {
            throw PhotoGroupRepositoryError.loadFailed(underlying: error)
        }
    }

    /// 保存されているグループをクリア
    public func clear() async throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return  // ファイルがなければ何もしない
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw PhotoGroupRepositoryError.clearFailed(underlying: error)
        }
    }

    /// グループが保存されているかチェック
    public func hasGroups() async -> Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }
}

// MARK: - PhotoGroupRepositoryError

/// PhotoGroupRepositoryで発生するエラー
public enum PhotoGroupRepositoryError: Error, LocalizedError, Sendable {
    /// 保存先ディレクトリが見つからない
    case directoryNotFound

    /// 保存に失敗
    case saveFailed(underlying: Error)

    /// 読み込みに失敗
    case loadFailed(underlying: Error)

    /// クリアに失敗
    case clearFailed(underlying: Error)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return NSLocalizedString(
                "error.photoGroupRepository.directoryNotFound",
                value: "保存先ディレクトリが見つかりません",
                comment: "Directory not found error"
            )
        case .saveFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "error.photoGroupRepository.saveFailed",
                    value: "グループの保存に失敗しました: %@",
                    comment: "Save failed error"
                ),
                underlying.localizedDescription
            )
        case .loadFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "error.photoGroupRepository.loadFailed",
                    value: "グループの読み込みに失敗しました: %@",
                    comment: "Load failed error"
                ),
                underlying.localizedDescription
            )
        case .clearFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "error.photoGroupRepository.clearFailed",
                    value: "グループのクリアに失敗しました: %@",
                    comment: "Clear failed error"
                ),
                underlying.localizedDescription
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            return NSLocalizedString(
                "error.photoGroupRepository.directoryNotFound.suggestion",
                value: "アプリを再起動してください",
                comment: "Directory not found recovery suggestion"
            )
        case .saveFailed, .loadFailed, .clearFailed:
            return NSLocalizedString(
                "error.photoGroupRepository.operation.suggestion",
                value: "空き容量を確認し、再度お試しください",
                comment: "Operation failed recovery suggestion"
            )
        }
    }
}

// MARK: - Factory

extension FileSystemPhotoGroupRepository {
    /// デフォルトインスタンスを作成
    /// - Returns: FileSystemPhotoGroupRepository インスタンス
    /// - Throws: 初期化に失敗した場合
    public static func makeDefault() throws -> FileSystemPhotoGroupRepository {
        try FileSystemPhotoGroupRepository()
    }
}

// MARK: - NoOpPhotoGroupRepository

/// 何もしないPhotoGroupRepository（フォールバック用）
/// テストやエラー時のフォールバックとして使用
struct NoOpPhotoGroupRepository: PhotoGroupRepositoryProtocol {
    func save(_ groups: [PhotoGroup]) async throws {
        // 何もしない
    }

    func load() async throws -> [PhotoGroup] {
        return []
    }

    func clear() async throws {
        // 何もしない
    }

    func hasGroups() async -> Bool {
        return false
    }
}
