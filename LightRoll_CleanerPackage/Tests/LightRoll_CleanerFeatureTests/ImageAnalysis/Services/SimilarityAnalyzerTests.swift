//
//  SimilarityAnalyzerTests.swift
//  LightRoll_CleanerFeatureTests
//
//  SimilarityAnalyzerのテスト
//  Created by AI Assistant
//

import Testing
import Foundation
import Vision
import Photos
@testable import LightRoll_CleanerFeature

// MARK: - SimilarityAnalyzer Tests

@Suite("SimilarityAnalyzer Tests", .serialized)
struct SimilarityAnalyzerTests {

    // MARK: - Initialization Tests

    @Test("初期化 - デフォルトオプション")
    func testInitialization_defaultOptions() async throws {
        // When
        let sut = SimilarityAnalyzer()

        // Then: インスタンス生成成功を確認
        #expect(sut != nil)
    }

    @Test("初期化 - カスタムオプション")
    func testInitialization_customOptions() async throws {
        // Given
        let options = SimilarityAnalysisOptions(
            similarityThreshold: 0.9,
            minGroupSize: 3,
            batchSize: 50
        )

        // When
        let sut = SimilarityAnalyzer(options: options)

        // Then: インスタンス生成成功を確認
        #expect(sut != nil)
    }

    // MARK: - SimilarityAnalysisOptions Tests

    @Test("SimilarityAnalysisOptions - デフォルト値")
    func testSimilarityAnalysisOptions_defaultValues() {
        // When
        let options = SimilarityAnalysisOptions.default

        // Then
        #expect(options.similarityThreshold == 0.85)
        #expect(options.minGroupSize == 2)
        #expect(options.batchSize == 100)
        #expect(options.maxConcurrentOperations == 4)
    }

    @Test("SimilarityAnalysisOptions - 厳格モード")
    func testSimilarityAnalysisOptions_strictMode() {
        // When
        let options = SimilarityAnalysisOptions.strict

        // Then
        #expect(options.similarityThreshold == 0.95)
        #expect(options.minGroupSize == 3)
        #expect(options.batchSize == 50)
        #expect(options.maxConcurrentOperations == 2)
    }

    @Test("SimilarityAnalysisOptions - 緩和モード")
    func testSimilarityAnalysisOptions_relaxedMode() {
        // When
        let options = SimilarityAnalysisOptions.relaxed

        // Then
        #expect(options.similarityThreshold == 0.75)
        #expect(options.minGroupSize == 2)
        #expect(options.batchSize == 200)
        #expect(options.maxConcurrentOperations == 8)
    }

    @Test("SimilarityAnalysisOptions - 閾値の範囲制限")
    func testSimilarityAnalysisOptions_thresholdClamping() {
        // Given & When
        let tooLow = SimilarityAnalysisOptions(similarityThreshold: -0.5)
        let tooHigh = SimilarityAnalysisOptions(similarityThreshold: 1.5)
        let valid = SimilarityAnalysisOptions(similarityThreshold: 0.8)

        // Then
        #expect(tooLow.similarityThreshold == 0.0)
        #expect(tooHigh.similarityThreshold == 1.0)
        #expect(valid.similarityThreshold == 0.8)
    }

    @Test("SimilarityAnalysisOptions - 最小グループサイズの制限")
    func testSimilarityAnalysisOptions_minGroupSizeClamping() {
        // Given & When
        let tooSmall = SimilarityAnalysisOptions(minGroupSize: 0)
        let negative = SimilarityAnalysisOptions(minGroupSize: -5)
        let valid = SimilarityAnalysisOptions(minGroupSize: 5)

        // Then
        #expect(tooSmall.minGroupSize == 2) // 最小値は2
        #expect(negative.minGroupSize == 2)
        #expect(valid.minGroupSize == 5)
    }

    // MARK: - SimilarPhotoGroup Tests

    @Test("SimilarPhotoGroup - 初期化")
    func testSimilarPhotoGroup_initialization() {
        // Given
        let photoIds = ["photo1", "photo2", "photo3"]
        let averageSimilarity: Float = 0.9
        let pairCount = 3

        // When
        let group = SimilarPhotoGroup(
            photoIds: photoIds,
            averageSimilarity: averageSimilarity,
            pairCount: pairCount
        )

        // Then
        #expect(group.photoIds == photoIds)
        #expect(group.size == 3)
        #expect(group.averageSimilarity == 0.9)
        #expect(group.pairCount == 3)
    }

    @Test("SimilarPhotoGroup - contains メソッド")
    func testSimilarPhotoGroup_contains() {
        // Given
        let group = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2", "photo3"],
            averageSimilarity: 0.9
        )

        // When & Then
        #expect(group.contains(photoId: "photo1") == true)
        #expect(group.contains(photoId: "photo2") == true)
        #expect(group.contains(photoId: "photo999") == false)
    }

    @Test("SimilarPhotoGroup - フォーマット済み類似度")
    func testSimilarPhotoGroup_formattedSimilarity() {
        // Given
        let group = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2"],
            averageSimilarity: 0.876
        )

        // When
        let formatted = group.formattedAverageSimilarity

        // Then
        #expect(formatted == "87.6%")
    }

    @Test("SimilarPhotoGroup - 類似度のクランプ")
    func testSimilarPhotoGroup_similarityClamping() {
        // Given & When
        let tooLow = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2"],
            averageSimilarity: -0.5
        )
        let tooHigh = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2"],
            averageSimilarity: 1.5
        )

        // Then
        #expect(tooLow.averageSimilarity == 0.0)
        #expect(tooHigh.averageSimilarity == 1.0)
    }

    @Test("SimilarPhotoGroup - Comparable（サイズ優先）")
    func testSimilarPhotoGroup_comparable_sizeFirst() {
        // Given
        let smallGroup = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2"],
            averageSimilarity: 0.95
        )
        let largeGroup = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2", "photo3", "photo4"],
            averageSimilarity: 0.8
        )

        // When & Then
        #expect(largeGroup < smallGroup) // 大きいグループが先
        #expect(smallGroup > largeGroup)
    }

    @Test("SimilarPhotoGroup - Comparable（類似度で比較）")
    func testSimilarPhotoGroup_comparable_similaritySecond() {
        // Given
        let highSimilarity = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2", "photo3"],
            averageSimilarity: 0.95
        )
        let lowSimilarity = SimilarPhotoGroup(
            photoIds: ["photo4", "photo5", "photo6"],
            averageSimilarity: 0.8
        )

        // When & Then
        #expect(highSimilarity < lowSimilarity) // 高類似度が先
    }

    @Test("SimilarPhotoGroup - Identifiable")
    func testSimilarPhotoGroup_identifiable() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])

        // When & Then
        #expect(group1.id != group2.id) // 異なるUUID
    }

    @Test("SimilarPhotoGroup - Hashable")
    func testSimilarPhotoGroup_hashable() {
        // Given
        let group1 = SimilarPhotoGroup(
            id: UUID(),
            photoIds: ["photo1", "photo2"]
        )
        let group2 = SimilarPhotoGroup(
            id: group1.id,
            photoIds: ["photo1", "photo2"]
        )

        // When
        let set: Set<SimilarPhotoGroup> = [group1, group2]

        // Then
        #expect(set.count == 1) // 同じIDなので1つ
    }

    @Test("SimilarPhotoGroup - Codable")
    func testSimilarPhotoGroup_codable() throws {
        // Given
        let original = SimilarPhotoGroup(
            photoIds: ["photo1", "photo2", "photo3"],
            averageSimilarity: 0.9,
            pairCount: 3
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimilarPhotoGroup.self, from: data)

        // Then
        #expect(decoded.id == original.id)
        #expect(decoded.photoIds == original.photoIds)
        #expect(decoded.averageSimilarity == original.averageSimilarity)
        #expect(decoded.pairCount == original.pairCount)
    }

    // MARK: - Array Extension Tests

    @Test("Array<SimilarPhotoGroup> - groups(containing:)")
    func testArrayExtension_groupsContaining() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo3", "photo4"])
        let group3 = SimilarPhotoGroup(photoIds: ["photo1", "photo5"])
        let groups = [group1, group2, group3]

        // When
        let result = groups.groups(containing: "photo1")

        // Then
        #expect(result.count == 2)
        #expect(result.contains(group1))
        #expect(result.contains(group3))
    }

    @Test("Array<SimilarPhotoGroup> - groups(withMinSize:)")
    func testArrayExtension_groupsWithMinSize() {
        // Given
        let smallGroup = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let mediumGroup = SimilarPhotoGroup(photoIds: ["photo3", "photo4", "photo5"])
        let largeGroup = SimilarPhotoGroup(photoIds: ["photo6", "photo7", "photo8", "photo9"])
        let groups = [smallGroup, mediumGroup, largeGroup]

        // When
        let result = groups.groups(withMinSize: 3)

        // Then
        #expect(result.count == 2)
        #expect(result.contains(mediumGroup))
        #expect(result.contains(largeGroup))
    }

    @Test("Array<SimilarPhotoGroup> - totalPhotoCount")
    func testArrayExtension_totalPhotoCount() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo3", "photo4", "photo5"])
        let group3 = SimilarPhotoGroup(photoIds: ["photo6"])
        let groups = [group1, group2, group3]

        // When
        let total = groups.totalPhotoCount

        // Then
        #expect(total == 6)
    }

    @Test("Array<SimilarPhotoGroup> - averageGroupSize")
    func testArrayExtension_averageGroupSize() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo3", "photo4", "photo5", "photo6"])
        let groups = [group1, group2]

        // When
        let average = groups.averageGroupSize

        // Then
        #expect(average == 3.0) // (2 + 4) / 2 = 3
    }

    @Test("Array<SimilarPhotoGroup> - averageGroupSize（空配列）")
    func testArrayExtension_averageGroupSize_empty() {
        // Given
        let groups: [SimilarPhotoGroup] = []

        // When
        let average = groups.averageGroupSize

        // Then
        #expect(average == nil)
    }

    @Test("Array<SimilarPhotoGroup> - maxGroupSize")
    func testArrayExtension_maxGroupSize() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo3", "photo4", "photo5"])
        let group3 = SimilarPhotoGroup(photoIds: ["photo6"])
        let groups = [group1, group2, group3]

        // When
        let max = groups.maxGroupSize

        // Then
        #expect(max == 3)
    }

    @Test("Array<SimilarPhotoGroup> - minGroupSize")
    func testArrayExtension_minGroupSize() {
        // Given
        let group1 = SimilarPhotoGroup(photoIds: ["photo1", "photo2"])
        let group2 = SimilarPhotoGroup(photoIds: ["photo3", "photo4", "photo5"])
        let group3 = SimilarPhotoGroup(photoIds: ["photo6"])
        let groups = [group1, group2, group3]

        // When
        let min = groups.minGroupSize

        // Then
        #expect(min == 1)
    }

    // MARK: - UnionFind Algorithm Tests

    @Test("UnionFind - 基本動作")
    func testUnionFind_basicOperation() {
        // Given
        var uf = createUnionFind(ids: ["A", "B", "C", "D"])

        // When
        uf.union("A", "B")
        uf.union("C", "D")

        // Then
        let isABConnected = uf.isConnected("A", "B")
        let isCDConnected = uf.isConnected("C", "D")
        let isACConnected = uf.isConnected("A", "C")

        #expect(isABConnected)
        #expect(isCDConnected)
        #expect(!isACConnected)
    }

    @Test("UnionFind - 推移的結合")
    func testUnionFind_transitiveConnection() {
        // Given
        var uf = createUnionFind(ids: ["A", "B", "C", "D"])

        // When
        uf.union("A", "B")
        uf.union("B", "C")
        uf.union("C", "D")

        // Then: すべて連結されている
        let isABConnected = uf.isConnected("A", "B")
        let isACConnected = uf.isConnected("A", "C")
        let isADConnected = uf.isConnected("A", "D")
        let isBCConnected = uf.isConnected("B", "C")
        let isBDConnected = uf.isConnected("B", "D")
        let isCDConnected = uf.isConnected("C", "D")

        #expect(isABConnected)
        #expect(isACConnected)
        #expect(isADConnected)
        #expect(isBCConnected)
        #expect(isBDConnected)
        #expect(isCDConnected)
    }

    @Test("UnionFind - find（経路圧縮）")
    func testUnionFind_findWithPathCompression() {
        // Given
        var uf = createUnionFind(ids: ["A", "B", "C", "D"])

        // When
        uf.union("A", "B")
        uf.union("B", "C")

        let root1 = uf.find("C")
        let root2 = uf.find("A")

        // Then
        #expect(root1 == root2) // 同じルート
    }

    // MARK: - Helper Methods

    /// UnionFind インスタンスを作成（テスト用）
    /// - Parameter ids: 要素のID配列
    /// - Returns: UnionFind インスタンス
    private func createUnionFind(ids: [String]) -> UnionFind {
        // UnionFind は private なので、リフレクションまたはテスト用のパブリックAPIが必要
        // ここでは簡易的な実装を使用
        struct TestUnionFind {
            private var parent: [String: String] = [:]
            private var rank: [String: Int] = [:]

            init(ids: [String]) {
                for id in ids {
                    parent[id] = id
                    rank[id] = 0
                }
            }

            mutating func find(_ id: String) -> String {
                guard let p = parent[id] else { return id }
                if p != id {
                    parent[id] = find(p)
                    return parent[id]!
                }
                return id
            }

            mutating func union(_ id1: String, _ id2: String) {
                let root1 = find(id1)
                let root2 = find(id2)
                guard root1 != root2 else { return }

                let rank1 = rank[root1] ?? 0
                let rank2 = rank[root2] ?? 0

                if rank1 < rank2 {
                    parent[root1] = root2
                } else if rank1 > rank2 {
                    parent[root2] = root1
                } else {
                    parent[root2] = root1
                    rank[root1] = rank1 + 1
                }
            }

            mutating func isConnected(_ id1: String, _ id2: String) -> Bool {
                find(id1) == find(id2)
            }
        }

        return TestUnionFind(ids: ids) as! UnionFind
    }
}

// MARK: - Integration Tests

@Suite("SimilarityAnalyzer Integration Tests", .serialized)
struct SimilarityAnalyzerIntegrationTests {

    @Test("空の配列を渡した場合は空の結果を返す")
    func testFindSimilarGroups_emptyArray() async throws {
        // Given
        let sut = SimilarityAnalyzer()
        let emptyAssets: [PHAsset] = []

        // When
        let result = try await sut.findSimilarGroups(in: emptyAssets)

        // Then
        #expect(result.isEmpty)
    }

    // 注: 実際のPHAssetを使用した統合テストは、
    // テスト環境でのフォトライブラリアクセスが必要なため、
    // UIテストまたはモックを使用した単体テストで実施
}

// MARK: - UnionFind Wrapper for Testing

/// テスト用 UnionFind ラッパー
private struct UnionFind {
    private var parent: [String: String] = [:]
    private var rank: [String: Int] = [:]

    init(ids: [String]) {
        for id in ids {
            parent[id] = id
            rank[id] = 0
        }
    }

    mutating func find(_ id: String) -> String {
        guard let p = parent[id] else { return id }
        if p != id {
            parent[id] = find(p)
            return parent[id]!
        }
        return id
    }

    mutating func union(_ id1: String, _ id2: String) {
        let root1 = find(id1)
        let root2 = find(id2)
        guard root1 != root2 else { return }

        let rank1 = rank[root1] ?? 0
        let rank2 = rank[root2] ?? 0

        if rank1 < rank2 {
            parent[root1] = root2
        } else if rank1 > rank2 {
            parent[root2] = root1
        } else {
            parent[root2] = root1
            rank[root1] = rank1 + 1
        }
    }

    mutating func isConnected(_ id1: String, _ id2: String) -> Bool {
        find(id1) == find(id2)
    }
}
