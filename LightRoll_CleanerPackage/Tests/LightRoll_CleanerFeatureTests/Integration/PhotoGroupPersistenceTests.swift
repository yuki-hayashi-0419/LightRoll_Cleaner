//
//  PhotoGroupPersistenceTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoGroup永続化機能の統合テスト
//  Created by AI Assistant
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - PhotoGroupPersistenceTests

/// PhotoGroup永続化機能のテスト
/// PhotoGroupのCodable実装とUserDefaults永続化の動作を検証
@MainActor
@Suite("PhotoGroup永続化機能")
struct PhotoGroupPersistenceTests {

    // MARK: - Setup

    /// テスト用UserDefaults
    private let testDefaults: UserDefaults

    /// テスト用キー
    private let testKey = "test_photo_groups"

    init() {
        // 各テストで独立したUserDefaultsを使用
        testDefaults = UserDefaults(suiteName: "test.suite.\(UUID().uuidString)")!
    }

    // MARK: - 正常系テスト

    @Test("空配列の保存と読み込み")
    func testSaveAndLoadEmptyArray() throws {
        // Given: 空のグループ配列
        let emptyGroups: [PhotoGroup] = []

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode(emptyGroups)
        testDefaults.set(data, forKey: testKey)

        // Then: 読み込み成功
        let loadedData = testDefaults.data(forKey: testKey)
        #expect(loadedData != nil)

        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)
        #expect(loaded.isEmpty)
    }

    @Test("1件のグループの保存と読み込み")
    func testSaveAndLoadSingleGroup() throws {
        // Given: 1件のグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2", "photo3"],
            fileSizes: [1_000_000, 1_200_000, 900_000],
            bestShotIndex: 1
        )
        let groups = [group]

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode(groups)
        testDefaults.set(data, forKey: testKey)

        // Then: 読み込み成功
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        #expect(loaded.count == 1)
        #expect(loaded[0].type == .similar)
        #expect(loaded[0].photoIds == ["photo1", "photo2", "photo3"])
        #expect(loaded[0].fileSizes == [1_000_000, 1_200_000, 900_000])
        #expect(loaded[0].bestShotIndex == 1)
    }

    @Test("複数グループの保存と読み込み")
    func testSaveAndLoadMultipleGroups() throws {
        // Given: 複数のグループ
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["a1", "a2"],
                fileSizes: [1_000_000, 1_200_000],
                bestShotIndex: 0
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["s1", "s2", "s3"],
                fileSizes: [500_000, 600_000, 550_000]
            ),
            PhotoGroup(
                type: .blurry,
                photoIds: ["b1", "b2", "b3", "b4"],
                fileSizes: [2_000_000, 1_800_000, 2_200_000, 1_900_000]
            )
        ]

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode(groups)
        testDefaults.set(data, forKey: testKey)

        // Then: 読み込み成功
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        #expect(loaded.count == 3)
        #expect(loaded[0].type == .similar)
        #expect(loaded[1].type == .screenshot)
        #expect(loaded[2].type == .blurry)
    }

    @Test("すべてのGroupTypeの保存")
    func testSaveAllGroupTypes() throws {
        // Given: すべてのGroupTypeを含むグループ
        let groups = GroupType.allCases.map { type in
            PhotoGroup(
                type: type,
                photoIds: ["photo1", "photo2"],
                fileSizes: [1_000_000, 1_000_000]
            )
        }

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode(groups)
        testDefaults.set(data, forKey: testKey)

        // Then: すべてのタイプが正しく読み込まれる
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        #expect(loaded.count == GroupType.allCases.count)

        let loadedTypes = Set(loaded.map { $0.type })
        let allTypes = Set(GroupType.allCases)
        #expect(loadedTypes == allTypes)
    }

    @Test("オプショナルフィールドの保存")
    func testSaveOptionalFields() throws {
        // Given: オプショナルフィールドを持つグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2"],
            fileSizes: [1_000_000, 1_000_000],
            bestShotIndex: 1,
            isSelected: true,
            similarityScore: 0.92,
            customName: "カスタムグループ"
        )

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        // Then: オプショナルフィールドも正しく読み込まれる
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        #expect(loaded[0].bestShotIndex == 1)
        #expect(loaded[0].isSelected == true)
        #expect(loaded[0].similarityScore == 0.92)
        #expect(loaded[0].customName == "カスタムグループ")
    }

    // MARK: - 異常系テスト

    @Test("存在しないキーの読み込み")
    func testLoadNonExistentKey() {
        // When: 存在しないキーから読み込み
        let data = testDefaults.data(forKey: "nonexistent_key")

        // Then: nilが返る
        #expect(data == nil)
    }

    @Test("不正なデータのデコード")
    func testDecodeInvalidData() {
        // Given: 不正なデータ
        let invalidData = "invalid json".data(using: .utf8)!
        testDefaults.set(invalidData, forKey: testKey)

        // When/Then: デコード失敗
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()

        #expect(throws: (any Error).self) {
            _ = try decoder.decode([PhotoGroup].self, from: loadedData!)
        }
    }

    @Test("fileSizesが空の場合のフォールバック")
    func testEmptyFileSizesFallback() throws {
        // Given: fileSizesが空のJSON（古いバージョンを想定）
        let jsonString = """
        [{
            "id": "12345678-1234-1234-1234-123456789012",
            "type": "similar",
            "photoIds": ["photo1", "photo2", "photo3"],
            "fileSizes": [],
            "createdAt": 0
        }]
        """
        let data = jsonString.data(using: .utf8)!

        // When: デコード
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: data)

        // Then: fileSizesは0で埋められる
        #expect(loaded[0].fileSizes.count == 3)
        #expect(loaded[0].fileSizes.allSatisfy { $0 == 0 })
    }

    // MARK: - 境界値テスト

    @Test("大量のグループの保存と読み込み")
    func testSaveLargeNumberOfGroups() throws {
        // Given: 100件のグループ
        let groups = (0..<100).map { index in
            PhotoGroup(
                type: GroupType.allCases[index % GroupType.allCases.count],
                photoIds: (0..<10).map { "photo\(index)-\($0)" },
                fileSizes: Array(repeating: 1_000_000, count: 10)
            )
        }

        // When: 保存
        let encoder = JSONEncoder()
        let data = try encoder.encode(groups)
        testDefaults.set(data, forKey: testKey)

        // Then: 読み込み成功
        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        #expect(loaded.count == 100)
    }

    @Test("グループ内に1枚の写真（最小値）")
    func testGroupWithSinglePhoto() throws {
        // Given: 1枚だけの写真を持つグループ
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["photo1"],
            fileSizes: [500_000]
        )

        // When: 保存・読み込み
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        // Then: 正しく読み込まれる
        #expect(loaded[0].photoIds.count == 1)
        #expect(loaded[0].fileSizes.count == 1)
    }

    @Test("グループ内に大量の写真")
    func testGroupWithManyPhotos() throws {
        // Given: 1000枚の写真を持つグループ
        let photoIds = (0..<1000).map { "photo\($0)" }
        let fileSizes = Array(repeating: Int64(1_000_000), count: 1000)

        let group = PhotoGroup(
            type: .similar,
            photoIds: photoIds,
            fileSizes: fileSizes
        )

        // When: 保存・読み込み
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        // Then: すべての写真が保存される
        #expect(loaded[0].photoIds.count == 1000)
        #expect(loaded[0].fileSizes.count == 1000)
    }

    @Test("極小ファイルサイズ（0バイト）")
    func testZeroFileSize() throws {
        // Given: 0バイトのファイルサイズ
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["photo1", "photo2"],
            fileSizes: [0, 0]
        )

        // When: 保存・読み込み
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        // Then: 0バイトが保持される
        #expect(loaded[0].totalSize == 0)
    }

    @Test("極大ファイルサイズ")
    func testLargeFileSize() throws {
        // Given: 10GBのファイルサイズ
        let largeSize: Int64 = 10 * 1024 * 1024 * 1024
        let group = PhotoGroup(
            type: .largeVideo,
            photoIds: ["video1"],
            fileSizes: [largeSize]
        )

        // When: 保存・読み込み
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        // Then: 大きなサイズが保持される
        #expect(loaded[0].totalSize == largeSize)
    }

    // MARK: - 永続化ヘルパー関数のテスト

    @Test("クリア処理")
    func testClearGroups() {
        // Given: 保存されたグループ
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2"],
            fileSizes: [1_000_000, 1_000_000]
        )

        let encoder = JSONEncoder()
        if let data = try? encoder.encode([group]) {
            testDefaults.set(data, forKey: testKey)
        }

        // When: クリア
        testDefaults.removeObject(forKey: testKey)

        // Then: データが削除される
        let loadedData = testDefaults.data(forKey: testKey)
        #expect(loadedData == nil)
    }

    @Test("存在確認")
    func testHasGroups() {
        // Given: 初期状態（データなし）
        #expect(testDefaults.data(forKey: testKey) == nil)

        // When: データを保存
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo1", "photo2"],
            fileSizes: [1_000_000, 1_000_000]
        )

        let encoder = JSONEncoder()
        if let data = try? encoder.encode([group]) {
            testDefaults.set(data, forKey: testKey)
        }

        // Then: データが存在する
        #expect(testDefaults.data(forKey: testKey) != nil)
    }

    // MARK: - UUIDの一貫性テスト

    @Test("UUID保存後の一貫性")
    func testUUIDConsistency() throws {
        // Given: 特定のUUIDを持つグループ
        let uuid = UUID()
        let group = PhotoGroup(
            id: uuid,
            type: .similar,
            photoIds: ["photo1", "photo2"],
            fileSizes: [1_000_000, 1_000_000]
        )

        // When: 保存・読み込み
        let encoder = JSONEncoder()
        let data = try encoder.encode([group])
        testDefaults.set(data, forKey: testKey)

        let loadedData = testDefaults.data(forKey: testKey)
        let decoder = JSONDecoder()
        let loaded = try decoder.decode([PhotoGroup].self, from: loadedData!)

        // Then: UUIDが保持される
        #expect(loaded[0].id == uuid)
    }
}
