//
//  FileManager+Extensions.swift
//  LightRoll_CleanerFeature
//
//  ファイル操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - FileManager Extensions

extension FileManager {

    // MARK: - Directory URLs

    /// ドキュメントディレクトリのURL
    public var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// キャッシュディレクトリのURL
    public var cachesDirectory: URL {
        urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    // 注: temporaryDirectory は Foundation の FileManager に標準で存在するため、
    // 拡張では定義しない。FileManager.default.temporaryDirectory を使用すること。

    /// アプリケーションサポートディレクトリのURL
    public var applicationSupportDirectory: URL {
        let url = urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        // アプリケーションサポートディレクトリは存在しない場合があるため作成
        if !fileExists(atPath: url.path) {
            try? createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: - File Operations

    /// ファイルが存在するかどうかを確認
    /// - Parameter url: ファイルURL
    /// - Returns: 存在する場合true
    public func fileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }

    /// ディレクトリが存在するかどうかを確認
    /// - Parameter url: ディレクトリURL
    /// - Returns: 存在しディレクトリである場合true
    public func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    /// ディレクトリを作成（既存の場合はスキップ）
    /// - Parameter url: ディレクトリURL
    /// - Throws: ディレクトリ作成に失敗した場合
    public func createDirectoryIfNeeded(at url: URL) throws {
        guard !directoryExists(at: url) else { return }
        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// ファイルを安全に削除（存在しない場合は無視）
    /// - Parameter url: ファイルURL
    /// - Throws: 削除に失敗した場合
    public func removeItemIfExists(at url: URL) throws {
        guard fileExists(at: url) else { return }
        try removeItem(at: url)
    }

    /// ファイルをコピー（既存の場合は上書き）
    /// - Parameters:
    ///   - srcURL: コピー元URL
    ///   - dstURL: コピー先URL
    /// - Throws: コピーに失敗した場合
    public func copyItemOverwriting(at srcURL: URL, to dstURL: URL) throws {
        try removeItemIfExists(at: dstURL)
        try copyItem(at: srcURL, to: dstURL)
    }

    /// ファイルを移動（既存の場合は上書き）
    /// - Parameters:
    ///   - srcURL: 移動元URL
    ///   - dstURL: 移動先URL
    /// - Throws: 移動に失敗した場合
    public func moveItemOverwriting(at srcURL: URL, to dstURL: URL) throws {
        try removeItemIfExists(at: dstURL)
        try moveItem(at: srcURL, to: dstURL)
    }

    // MARK: - File Size

    /// ファイルサイズを取得
    /// - Parameter url: ファイルURL
    /// - Returns: ファイルサイズ（バイト）、または失敗時nil
    public func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    /// ディレクトリ内の全ファイルの合計サイズを取得
    /// - Parameter url: ディレクトリURL
    /// - Returns: 合計サイズ（バイト）
    public func directorySize(at url: URL) -> Int64 {
        guard let enumerator = self.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = fileSize(at: fileURL) {
                totalSize += size
            }
        }
        return totalSize
    }

    // MARK: - Directory Contents

    /// ディレクトリ内のファイルURLを取得（サブディレクトリを含まない）
    /// - Parameter url: ディレクトリURL
    /// - Returns: ファイルURLの配列
    /// - Throws: 取得に失敗した場合
    public func filesInDirectory(at url: URL) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { !directoryExists(at: $0) }
    }

    /// ディレクトリ内のサブディレクトリURLを取得
    /// - Parameter url: ディレクトリURL
    /// - Returns: サブディレクトリURLの配列
    /// - Throws: 取得に失敗した場合
    public func subdirectoriesInDirectory(at url: URL) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { directoryExists(at: $0) }
    }

    /// 指定した拡張子のファイルを取得
    /// - Parameters:
    ///   - url: ディレクトリURL
    ///   - extension: ファイル拡張子
    /// - Returns: ファイルURLの配列
    /// - Throws: 取得に失敗した場合
    public func files(in url: URL, withExtension ext: String) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == ext.lowercased() }
    }

    // MARK: - Storage Info

    /// 利用可能なディスク容量を取得
    /// - Returns: 利用可能な容量（バイト）、または失敗時nil
    public var availableDiskSpace: Int64? {
        guard let attributes = try? attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return nil
        }
        return freeSpace
    }

    /// 総ディスク容量を取得
    /// - Returns: 総容量（バイト）、または失敗時nil
    public var totalDiskSpace: Int64? {
        guard let attributes = try? attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSpace = attributes[.systemSize] as? Int64 else {
            return nil
        }
        return totalSpace
    }

    /// ディスク使用率を取得（0.0〜1.0）
    /// - Returns: 使用率、または失敗時nil
    public var diskUsageRatio: Double? {
        guard let total = totalDiskSpace, let available = availableDiskSpace, total > 0 else {
            return nil
        }
        return Double(total - available) / Double(total)
    }

    // MARK: - File Attributes

    /// ファイルの作成日時を取得
    /// - Parameter url: ファイルURL
    /// - Returns: 作成日時、または失敗時nil
    public func creationDate(of url: URL) -> Date? {
        guard let attributes = try? attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.creationDate] as? Date
    }

    /// ファイルの更新日時を取得
    /// - Parameter url: ファイルURL
    /// - Returns: 更新日時、または失敗時nil
    public func modificationDate(of url: URL) -> Date? {
        guard let attributes = try? attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }

    // MARK: - Unique File Names

    /// ユニークなファイルURLを生成
    /// 同名のファイルが存在する場合、連番を付与
    /// - Parameter url: 元のファイルURL
    /// - Returns: ユニークなファイルURL
    public func uniqueFileURL(for url: URL) -> URL {
        guard fileExists(at: url) else { return url }

        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL: URL

        repeat {
            let newFilename = ext.isEmpty ? "\(filename)_\(counter)" : "\(filename)_\(counter).\(ext)"
            newURL = directory.appendingPathComponent(newFilename)
            counter += 1
        } while fileExists(at: newURL)

        return newURL
    }

    // MARK: - Cleanup

    /// 指定した日数より古いファイルを削除
    /// - Parameters:
    ///   - url: ディレクトリURL
    ///   - days: 日数
    /// - Returns: 削除されたファイル数
    /// - Throws: 操作に失敗した場合
    @discardableResult
    public func removeFilesOlderThan(days: Int, in url: URL) throws -> Int {
        let cutoffDate = Date().adding(days: -days)
        var removedCount = 0

        let contents = try contentsOfDirectory(at: url, includingPropertiesForKeys: [.contentModificationDateKey])

        for fileURL in contents {
            if let modDate = modificationDate(of: fileURL), modDate < cutoffDate {
                try removeItem(at: fileURL)
                removedCount += 1
            }
        }

        return removedCount
    }
}

// MARK: - ByteCountFormatter Helper

extension Int64 {

    /// 人間が読みやすいファイルサイズ文字列に変換
    /// - Returns: フォーマットされた文字列（例: "1.5 GB"）
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }

    /// 適切な単位でのファイルサイズ文字列に変換（ロケール対応）
    /// - Returns: フォーマットされた文字列
    public var localizedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: self)
    }
}
