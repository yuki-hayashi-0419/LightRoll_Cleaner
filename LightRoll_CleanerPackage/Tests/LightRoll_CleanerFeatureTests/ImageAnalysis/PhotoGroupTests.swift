//
//  PhotoGroupTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoGroupモデルの包括的な単体テスト
//  Created by AI Assistant
//

import Foundation
import Testing

@testable import LightRoll_CleanerFeature

// MARK: - GroupType Tests

@Suite("GroupType Tests")
struct GroupTypeTests {

    // MARK: - Display Properties Tests

    @Test("全てのGroupTypeがdisplayNameを持つ")
    func testAllGroupTypesHaveDisplayName() {
        for type in GroupType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("GroupType.displayNameが正しい値を返す")
    func testDisplayNames() {
        #expect(GroupType.similar.displayName == "類似写真")
        #expect(GroupType.selfie.displayName == "自撮り")
        #expect(GroupType.screenshot.displayName == "スクリーンショット")
        #expect(GroupType.blurry.displayName == "ブレ写真")
        #expect(GroupType.largeVideo.displayName == "大容量動画")
        #expect(GroupType.duplicate.displayName == "重複写真")
    }

    @Test("全てのGroupTypeがiconを持つ")
    func testAllGroupTypesHaveIcon() {
        for type in GroupType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    @Test("GroupType.iconがSF Symbol名を返す")
    func testIcons() {
        #expect(GroupType.similar.icon == "square.on.square")
        #expect(GroupType.selfie.icon == "person.crop.circle")
        #expect(GroupType.screenshot.icon == "rectangle.dashed")
        #expect(GroupType.blurry.icon == "camera.metering.unknown")
        #expect(GroupType.largeVideo.icon == "video.fill")
        #expect(GroupType.duplicate.icon == "doc.on.doc")
    }

    @Test("全てのGroupTypeがdescriptionを持つ")
    func testAllGroupTypesHaveDescription() {
        for type in GroupType.allCases {
            #expect(!type.description.isEmpty)
        }
    }

    @Test("全てのGroupTypeがemojiを持つ")
    func testAllGroupTypesHaveEmoji() {
        for type in GroupType.allCases {
            #expect(!type.emoji.isEmpty)
        }
    }

    @Test("GroupType.emojiが正しい絵文字を返す")
    func testEmojis() {
        #expect(GroupType.similar.emoji == "📸")
        #expect(GroupType.selfie.emoji == "🤳")
        #expect(GroupType.screenshot.emoji == "📱")
        #expect(GroupType.blurry.emoji == "🌫️")
        #expect(GroupType.largeVideo.emoji == "🎬")
        #expect(GroupType.duplicate.emoji == "👯")
    }

    // MARK: - Sort Order Tests

    @Test("全てのGroupTypeが一意なsortOrderを持つ")
    func testUniqueSortOrders() {
        let sortOrders = GroupType.allCases.map { $0.sortOrder }
        let uniqueSortOrders = Set(sortOrders)
        #expect(sortOrders.count == uniqueSortOrders.count)
    }

    @Test("GroupType.sortOrderが期待通りの順序")
    func testSortOrder() {
        #expect(GroupType.duplicate.sortOrder == 0)
        #expect(GroupType.similar.sortOrder == 1)
        #expect(GroupType.blurry.sortOrder == 2)
        #expect(GroupType.screenshot.sortOrder == 3)
        #expect(GroupType.selfie.sortOrder == 4)
        #expect(GroupType.largeVideo.sortOrder == 5)
    }

    @Test("GroupTypeのComparableがsortOrderに基づく")
    func testComparable() {
        #expect(GroupType.duplicate < GroupType.similar)
        #expect(GroupType.similar < GroupType.blurry)
        #expect(GroupType.blurry < GroupType.screenshot)
        #expect(GroupType.screenshot < GroupType.selfie)
        #expect(GroupType.selfie < GroupType.largeVideo)
    }

    // MARK: - Behavior Flags Tests

    @Test("isAutoDeleteRecommendedが正しいタイプでtrueを返す")
    func testIsAutoDeleteRecommended() {
        #expect(GroupType.duplicate.isAutoDeleteRecommended == true)
        #expect(GroupType.blurry.isAutoDeleteRecommended == true)
        #expect(GroupType.similar.isAutoDeleteRecommended == false)
        #expect(GroupType.screenshot.isAutoDeleteRecommended == false)
        #expect(GroupType.selfie.isAutoDeleteRecommended == false)
        #expect(GroupType.largeVideo.isAutoDeleteRecommended == false)
    }

    @Test("needsBestShotSelectionが正しいタイプでtrueを返す")
    func testNeedsBestShotSelection() {
        #expect(GroupType.similar.needsBestShotSelection == true)
        #expect(GroupType.selfie.needsBestShotSelection == true)
        #expect(GroupType.screenshot.needsBestShotSelection == false)
        #expect(GroupType.blurry.needsBestShotSelection == false)
        #expect(GroupType.largeVideo.needsBestShotSelection == false)
        #expect(GroupType.duplicate.needsBestShotSelection == false)
    }

    // MARK: - Codable Tests

    @Test("GroupTypeがCodable準拠している")
    func testCodable() throws {
        for type in GroupType.allCases {
            let encoded = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(GroupType.self, from: encoded)
            #expect(decoded == type)
        }
    }

    @Test("GroupTypeがrawValueでエンコードされる")
    func testRawValueEncoding() throws {
        let type = GroupType.similar
        let encoded = try JSONEncoder().encode(type)
        let jsonString = String(data: encoded, encoding: .utf8)
        #expect(jsonString?.contains("similar") == true)
    }
}

// MARK: - PhotoGroup Initialization Tests

@Suite("PhotoGroup Initialization Tests")
struct PhotoGroupInitializationTests {

    @Test("標準イニシャライザで正しく初期化される")
    func testStandardInitialization() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3"],
            fileSizes: [1000, 2000, 3000]
        )

        #expect(group.type == .similar)
        #expect(group.photoIds.count == 3)
        #expect(group.fileSizes.count == 3)
        #expect(group.bestShotIndex == nil)
        #expect(group.isSelected == false)
    }

    @Test("fileSizesが空の場合に自動で0配列が設定される")
    func testEmptyFileSizesDefaultsToZeros() {
        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["photo-1", "photo-2"]
        )

        #expect(group.fileSizes.count == 2)
        #expect(group.fileSizes == [0, 0])
    }

    @Test("簡易イニシャライザでタプル配列から作成できる")
    func testConvenienceInitializer() {
        let photos: [(id: String, fileSize: Int64)] = [
            (id: "photo-1", fileSize: 1000),
            (id: "photo-2", fileSize: 2000)
        ]
        let group = PhotoGroup(type: .selfie, photos: photos)

        #expect(group.photoIds == ["photo-1", "photo-2"])
        #expect(group.fileSizes == [1000, 2000])
    }

    @Test("全てのパラメータを指定して初期化できる")
    func testFullInitialization() {
        let id = UUID()
        let date = Date()

        let group = PhotoGroup(
            id: id,
            type: .duplicate,
            photoIds: ["photo-1", "photo-2"],
            fileSizes: [1000, 1000],
            bestShotIndex: 0,
            isSelected: true,
            createdAt: date,
            similarityScore: 0.95,
            customName: "カスタム名"
        )

        #expect(group.id == id)
        #expect(group.type == .duplicate)
        #expect(group.bestShotIndex == 0)
        #expect(group.isSelected == true)
        #expect(group.createdAt == date)
        #expect(group.similarityScore == 0.95)
        #expect(group.customName == "カスタム名")
    }

    @Test("similarityScoreが0-1の範囲にクランプされる")
    func testSimilarityScoreClamping() {
        let groupOver = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            similarityScore: 1.5
        )
        #expect(groupOver.similarityScore == 1.0)

        let groupUnder = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            similarityScore: -0.5
        )
        #expect(groupUnder.similarityScore == 0.0)
    }
}

// MARK: - PhotoGroup Computed Properties Tests

@Suite("PhotoGroup Computed Properties Tests")
struct PhotoGroupComputedPropertiesTests {

    @Test("displayNameがcustomName優先で返される")
    func testDisplayNameWithCustomName() {
        var group = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        #expect(group.displayName == "類似写真")

        group = group.withCustomName("マイグループ")
        #expect(group.displayName == "マイグループ")
    }

    @Test("countが正しい写真数を返す")
    func testCount() {
        let group = PhotoGroup(type: .similar, photoIds: ["1", "2", "3"])
        #expect(group.count == 3)
    }

    @Test("isEmptyが正しく判定される")
    func testIsEmpty() {
        let emptyGroup = PhotoGroup(type: .similar, photoIds: [])
        #expect(emptyGroup.isEmpty == true)

        let nonEmptyGroup = PhotoGroup(type: .similar, photoIds: ["1"])
        #expect(nonEmptyGroup.isEmpty == false)
    }

    @Test("isValidが2枚以上でtrueを返す")
    func testIsValid() {
        let singlePhoto = PhotoGroup(type: .similar, photoIds: ["1"])
        #expect(singlePhoto.isValid == false)

        let twoPhotos = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        #expect(twoPhotos.isValid == true)

        let threePhotos = PhotoGroup(type: .similar, photoIds: ["1", "2", "3"])
        #expect(threePhotos.isValid == true)
    }

    @Test("totalSizeが正しく計算される")
    func testTotalSize() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )
        #expect(group.totalSize == 6000)
    }

    @Test("reclaimableSizeがベストショットなしで全サイズを返す")
    func testReclaimableSizeWithoutBestShot() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )
        #expect(group.reclaimableSize == 6000)
    }

    @Test("reclaimableSizeがベストショット以外のサイズを返す")
    func testReclaimableSizeWithBestShot() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000],
            bestShotIndex: 1
        )
        // ベストショット（index 1, 2000バイト）以外 = 1000 + 3000 = 4000
        #expect(group.reclaimableSize == 4000)
    }

    @Test("reclaimableSizeが無効なベストショットインデックスで全サイズを返す")
    func testReclaimableSizeWithInvalidBestShotIndex() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000],
            bestShotIndex: 10 // 無効なインデックス
        )
        #expect(group.reclaimableSize == 3000)
    }

    @Test("reclaimableCountが正しく計算される")
    func testReclaimableCount() {
        let groupNoBestShot = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"]
        )
        #expect(groupNoBestShot.reclaimableCount == 3)

        let groupWithBestShot = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            bestShotIndex: 0
        )
        #expect(groupWithBestShot.reclaimableCount == 2)
    }

    @Test("bestShotIdが正しく返される")
    func testBestShotId() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3"],
            bestShotIndex: 1
        )
        #expect(group.bestShotId == "photo-2")

        let groupNoBestShot = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2"]
        )
        #expect(groupNoBestShot.bestShotId == nil)
    }

    @Test("deletionCandidateIdsがベストショット以外を返す")
    func testDeletionCandidateIds() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2", "photo-3"],
            bestShotIndex: 1
        )
        #expect(group.deletionCandidateIds == ["photo-1", "photo-3"])

        let groupNoBestShot = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2"]
        )
        #expect(groupNoBestShot.deletionCandidateIds == ["photo-1", "photo-2"])
    }

    @Test("savingsPercentageが正しく計算される")
    func testSavingsPercentage() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 1000],
            bestShotIndex: 0
        )
        // 削減可能: 1000 / 合計: 2000 = 50%
        #expect(group.savingsPercentage == 50.0)
    }

    @Test("savingsPercentageがtotalSize=0で0を返す")
    func testSavingsPercentageWithZeroTotal() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [0, 0]
        )
        #expect(group.savingsPercentage == 0)
    }

    @Test("formattedTotalSizeが人間可読形式を返す")
    func testFormattedTotalSize() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1"],
            fileSizes: [1_000_000] // 1MB
        )
        // ByteCountFormatter.string(fromByteCount:countStyle:)の結果
        #expect(!group.formattedTotalSize.isEmpty)
    }
}

// MARK: - PhotoGroup Mutation Methods Tests

@Suite("PhotoGroup Mutation Methods Tests")
struct PhotoGroupMutationMethodsTests {

    @Test("withBestShotが新しいインスタンスを返す")
    func testWithBestShot() {
        let original = PhotoGroup(type: .similar, photoIds: ["1", "2", "3"])
        let updated = original.withBestShot(at: 1)

        #expect(original.bestShotIndex == nil)
        #expect(updated.bestShotIndex == 1)
        #expect(original.id == updated.id)
    }

    @Test("withSelectionが新しいインスタンスを返す")
    func testWithSelection() {
        let original = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        let updated = original.withSelection(true)

        #expect(original.isSelected == false)
        #expect(updated.isSelected == true)
    }

    @Test("addingが写真を追加した新しいインスタンスを返す")
    func testAdding() {
        let original = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )
        let updated = original.adding(photoId: "3", fileSize: 3000)

        #expect(original.count == 2)
        #expect(updated.count == 3)
        #expect(updated.photoIds.contains("3"))
        #expect(updated.fileSizes.last == 3000)
    }

    @Test("removingが写真を削除した新しいインスタンスを返す")
    func testRemoving() {
        let original = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1000, 2000, 3000]
        )
        let updated = original.removing(photoId: "2")

        #expect(original.count == 3)
        #expect(updated.count == 2)
        #expect(!updated.photoIds.contains("2"))
        #expect(updated.fileSizes == [1000, 3000])
    }

    @Test("removingで存在しない写真IDの場合は同じインスタンスを返す")
    func testRemovingNonexistent() {
        let original = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        let updated = original.removing(photoId: "nonexistent")

        #expect(updated.photoIds == original.photoIds)
    }

    @Test("removingでベストショットインデックスが調整される")
    func testRemovingAdjustsBestShotIndex() {
        // ベストショットより前の写真を削除
        let group1 = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            bestShotIndex: 2
        )
        let updated1 = group1.removing(photoId: "1")
        #expect(updated1.bestShotIndex == 1) // 2 -> 1に調整

        // ベストショット自体を削除
        let group2 = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            bestShotIndex: 1
        )
        let updated2 = group2.removing(photoId: "2")
        #expect(updated2.bestShotIndex == nil) // リセット
    }

    @Test("withCustomNameがカスタム名を設定する")
    func testWithCustomName() {
        let original = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        let updated = original.withCustomName("マイグループ")

        #expect(original.customName == nil)
        #expect(updated.customName == "マイグループ")
        #expect(updated.displayName == "マイグループ")

        let reset = updated.withCustomName(nil)
        #expect(reset.customName == nil)
        #expect(reset.displayName == "類似写真")
    }
}

// MARK: - PhotoGroup Helper Methods Tests

@Suite("PhotoGroup Helper Methods Tests")
struct PhotoGroupHelperMethodsTests {

    @Test("containsが写真IDの存在を正しく判定する")
    func testContains() {
        let group = PhotoGroup(type: .similar, photoIds: ["photo-1", "photo-2"])

        #expect(group.contains(photoId: "photo-1") == true)
        #expect(group.contains(photoId: "photo-2") == true)
        #expect(group.contains(photoId: "photo-3") == false)
    }

    @Test("indexOfが正しいインデックスを返す")
    func testIndexOf() {
        let group = PhotoGroup(type: .similar, photoIds: ["photo-1", "photo-2", "photo-3"])

        #expect(group.index(of: "photo-1") == 0)
        #expect(group.index(of: "photo-2") == 1)
        #expect(group.index(of: "photo-3") == 2)
        #expect(group.index(of: "nonexistent") == nil)
    }
}

// MARK: - PhotoGroup Codable Tests

@Suite("PhotoGroup Codable Tests")
struct PhotoGroupCodableTests {

    @Test("PhotoGroupがエンコード・デコードできる")
    func testCodable() throws {
        let original = PhotoGroup(
            type: .similar,
            photoIds: ["photo-1", "photo-2"],
            fileSizes: [1000, 2000],
            bestShotIndex: 0,
            isSelected: true,
            similarityScore: 0.9,
            customName: "テスト"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhotoGroup.self, from: encoded)

        #expect(decoded.type == original.type)
        #expect(decoded.photoIds == original.photoIds)
        #expect(decoded.fileSizes == original.fileSizes)
        #expect(decoded.bestShotIndex == original.bestShotIndex)
        #expect(decoded.isSelected == original.isSelected)
        #expect(decoded.similarityScore == original.similarityScore)
        #expect(decoded.customName == original.customName)
    }

    @Test("fileSizesがデコード時に空の場合に自動補完される")
    func testDecodingWithMissingFileSizes() throws {
        // fileSizesキーがないJSONをシミュレート
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "type": "similar",
            "photoIds": ["1", "2", "3"]
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PhotoGroup.self, from: data)

        #expect(decoded.fileSizes.count == 3)
        #expect(decoded.fileSizes == [0, 0, 0])
    }

    @Test("デフォルト値がデコード時に正しく設定される")
    func testDecodingDefaults() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "type": "screenshot",
            "photoIds": ["1"]
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PhotoGroup.self, from: data)

        #expect(decoded.isSelected == false)
        #expect(decoded.bestShotIndex == nil)
        #expect(decoded.similarityScore == nil)
        #expect(decoded.customName == nil)
    }
}

// MARK: - PhotoGroup Comparable Tests

@Suite("PhotoGroup Comparable Tests")
struct PhotoGroupComparableTests {

    @Test("削減可能サイズで降順にソートされる")
    func testComparable() {
        let small = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [100, 100]
        )
        let large = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 1000]
        )

        // < 演算子は reclaimableSize が大きい方が「小さい」と判定
        // （降順ソート用）
        #expect(large < small)
    }
}

// MARK: - PhotoGroupStatistics Tests

@Suite("PhotoGroupStatistics Tests")
struct PhotoGroupStatisticsTests {

    @Test("空のstatisticsが正しい初期値を持つ")
    func testEmptyStatistics() {
        let empty = PhotoGroupStatistics.empty

        #expect(empty.totalGroups == 0)
        #expect(empty.totalPhotos == 0)
        #expect(empty.totalSize == 0)
        #expect(empty.reclaimableSize == 0)
        #expect(empty.countByType.isEmpty)
        #expect(empty.reclaimableSizeByType.isEmpty)
    }

    @Test("savingsPercentageが正しく計算される")
    func testSavingsPercentage() {
        let stats = PhotoGroupStatistics(
            totalGroups: 2,
            totalPhotos: 4,
            totalSize: 1000,
            reclaimableSize: 750,
            countByType: [:],
            reclaimableSizeByType: [:]
        )

        #expect(stats.savingsPercentage == 75.0)
    }

    @Test("savingsPercentageがtotalSize=0で0を返す")
    func testSavingsPercentageZeroTotal() {
        let stats = PhotoGroupStatistics(
            totalGroups: 0,
            totalPhotos: 0,
            totalSize: 0,
            reclaimableSize: 0,
            countByType: [:],
            reclaimableSizeByType: [:]
        )

        #expect(stats.savingsPercentage == 0)
    }

    @Test("formattedSizesが文字列を返す")
    func testFormattedSizes() {
        let stats = PhotoGroupStatistics(
            totalGroups: 1,
            totalPhotos: 2,
            totalSize: 1_000_000,
            reclaimableSize: 500_000,
            countByType: [:],
            reclaimableSizeByType: [:]
        )

        #expect(!stats.formattedTotalSize.isEmpty)
        #expect(!stats.formattedReclaimableSize.isEmpty)
    }
}

// MARK: - GroupingOptions Tests

@Suite("GroupingOptions Tests")
struct GroupingOptionsTests {

    @Test("デフォルトオプションが正しい初期値を持つ")
    func testDefaultOptions() {
        let options = GroupingOptions.default

        #expect(options.similarityThreshold == 0.85)
        #expect(options.minimumGroupSize == 2)
        #expect(options.includeScreenshots == true)
        #expect(options.includeSelfies == true)
        #expect(options.includeBlurry == true)
        #expect(options.includeLargeVideos == true)
        #expect(options.autoSelectBestShot == true)
        #expect(options.dateRange == nil)
    }

    @Test("strictオプションが高い閾値を持つ")
    func testStrictOptions() {
        let options = GroupingOptions.strict

        #expect(options.similarityThreshold == 0.95)
    }

    @Test("relaxedオプションが低い閾値を持つ")
    func testRelaxedOptions() {
        let options = GroupingOptions.relaxed

        #expect(options.similarityThreshold == 0.75)
    }

    @Test("similarityThresholdが0-1にクランプされる")
    func testSimilarityThresholdClamping() {
        let overOptions = GroupingOptions(similarityThreshold: 1.5)
        #expect(overOptions.similarityThreshold == 1.0)

        let underOptions = GroupingOptions(similarityThreshold: -0.5)
        #expect(underOptions.similarityThreshold == 0.0)
    }

    @Test("minimumGroupSizeが最小2に制限される")
    func testMinimumGroupSizeClamping() {
        let options = GroupingOptions(minimumGroupSize: 1)
        #expect(options.minimumGroupSize == 2)

        let validOptions = GroupingOptions(minimumGroupSize: 5)
        #expect(validOptions.minimumGroupSize == 5)
    }

    @Test("DateRangeのlastDaysが正しい範囲を作成する")
    func testDateRangeLastDays() {
        let range = GroupingOptions.DateRange.lastDays(7)

        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        // 許容範囲内かチェック（1秒以内）
        #expect(abs(range.end.timeIntervalSince(now)) < 1)
        #expect(abs(range.start.timeIntervalSince(sevenDaysAgo)) < 1)
    }

    @Test("GroupingOptionsがCodable準拠している")
    func testCodable() throws {
        let original = GroupingOptions(
            similarityThreshold: 0.9,
            minimumGroupSize: 3,
            includeScreenshots: false,
            dateRange: .lastDays(30)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GroupingOptions.self, from: encoded)

        #expect(decoded.similarityThreshold == original.similarityThreshold)
        #expect(decoded.minimumGroupSize == original.minimumGroupSize)
        #expect(decoded.includeScreenshots == original.includeScreenshots)
        #expect(decoded.dateRange != nil)
    }
}

// MARK: - Array+PhotoGroup Extension Tests

@Suite("Array+PhotoGroup Extension Tests")
struct ArrayPhotoGroupExtensionTests {

    // テスト用のサンプルグループ配列を作成
    private func createSampleGroups() -> [PhotoGroup] {
        [
            PhotoGroup(
                type: .similar,
                photoIds: ["s1", "s2", "s3"],
                fileSizes: [1000, 2000, 3000],
                bestShotIndex: 0,
                isSelected: false
            ),
            PhotoGroup(
                type: .screenshot,
                photoIds: ["sc1", "sc2"],
                fileSizes: [500, 500],
                isSelected: true
            ),
            PhotoGroup(
                type: .selfie,
                photoIds: ["se1", "se2", "se3", "se4"],
                fileSizes: [1500, 1500, 1500, 1500],
                bestShotIndex: 1,
                isSelected: false
            ),
            PhotoGroup(
                type: .similar,
                photoIds: ["s4", "s5"],
                fileSizes: [4000, 4000],
                isSelected: true
            )
        ]
    }

    // MARK: - Filtering Tests

    @Test("filterByTypeが指定タイプのみを返す")
    func testFilterByType() {
        let groups = createSampleGroups()
        let similarGroups = groups.filterByType(.similar)

        #expect(similarGroups.count == 2)
        #expect(similarGroups.allSatisfy { $0.type == .similar })
    }

    @Test("filterByTypesが複数タイプでフィルタする")
    func testFilterByTypes() {
        let groups = createSampleGroups()
        let filtered = groups.filterByTypes([.similar, .screenshot])

        #expect(filtered.count == 3)
        #expect(filtered.allSatisfy { $0.type == .similar || $0.type == .screenshot })
    }

    @Test("validGroupsが有効なグループのみを返す")
    func testValidGroups() {
        let groups = [
            PhotoGroup(type: .similar, photoIds: ["1"]), // 無効
            PhotoGroup(type: .similar, photoIds: ["1", "2"]), // 有効
            PhotoGroup(type: .similar, photoIds: []) // 無効
        ]

        #expect(groups.validGroups.count == 1)
    }

    @Test("selectedGroupsが選択されたグループのみを返す")
    func testSelectedGroups() {
        let groups = createSampleGroups()
        let selected = groups.selectedGroups

        #expect(selected.count == 2)
        #expect(selected.allSatisfy { $0.isSelected })
    }

    @Test("unselectedGroupsが選択されていないグループのみを返す")
    func testUnselectedGroups() {
        let groups = createSampleGroups()
        let unselected = groups.unselectedGroups

        #expect(unselected.count == 2)
        #expect(unselected.allSatisfy { !$0.isSelected })
    }

    @Test("withBestShotがベストショット設定済みグループのみを返す")
    func testWithBestShot() {
        let groups = createSampleGroups()
        let withBestShot = groups.withBestShot

        #expect(withBestShot.count == 2)
        #expect(withBestShot.allSatisfy { $0.bestShotIndex != nil })
    }

    @Test("withoutBestShotがベストショット未設定グループのみを返す")
    func testWithoutBestShot() {
        let groups = createSampleGroups()
        let withoutBestShot = groups.withoutBestShot

        #expect(withoutBestShot.count == 2)
        #expect(withoutBestShot.allSatisfy { $0.bestShotIndex == nil })
    }

    // MARK: - Sorting Tests

    @Test("sortedByReclaimableSizeが降順でソートする")
    func testSortedByReclaimableSize() {
        let groups = createSampleGroups()
        let sorted = groups.sortedByReclaimableSize

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].reclaimableSize >= sorted[i + 1].reclaimableSize)
        }
    }

    @Test("sortedByPhotoCountが降順でソートする")
    func testSortedByPhotoCount() {
        let groups = createSampleGroups()
        let sorted = groups.sortedByPhotoCount

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].count >= sorted[i + 1].count)
        }
    }

    @Test("sortedByTypeがsortOrder順でソートする")
    func testSortedByType() {
        let groups = createSampleGroups()
        let sorted = groups.sortedByType

        for i in 0..<(sorted.count - 1) {
            #expect(sorted[i].type.sortOrder <= sorted[i + 1].type.sortOrder)
        }
    }

    // MARK: - Statistics Tests

    @Test("statisticsが正しく計算される")
    func testStatistics() {
        let groups = createSampleGroups()
        let stats = groups.statistics

        #expect(stats.totalGroups == 4)
        #expect(stats.totalPhotos == 11) // 3 + 2 + 4 + 2
        #expect(stats.countByType[.similar] == 2)
        #expect(stats.countByType[.screenshot] == 1)
        #expect(stats.countByType[.selfie] == 1)
    }

    @Test("totalReclaimableSizeが正しく計算される")
    func testTotalReclaimableSize() {
        let groups = createSampleGroups()
        let expected = groups.reduce(0) { $0 + $1.reclaimableSize }
        #expect(groups.totalReclaimableSize == expected)
    }

    @Test("totalSizeが正しく計算される")
    func testTotalSize() {
        let groups = createSampleGroups()
        let expected = groups.reduce(0) { $0 + $1.totalSize }
        #expect(groups.totalSize == expected)
    }

    @Test("totalPhotoCountが正しく計算される")
    func testTotalPhotoCount() {
        let groups = createSampleGroups()
        #expect(groups.totalPhotoCount == 11)
    }

    // MARK: - Lookup Tests

    @Test("groupWithIdが正しいグループを返す")
    func testGroupWithId() {
        let groups = createSampleGroups()
        let target = groups[1]

        let found = groups.group(withId: target.id)
        #expect(found?.id == target.id)

        let notFound = groups.group(withId: UUID())
        #expect(notFound == nil)
    }

    @Test("groupsContainingが写真IDを含むグループを返す")
    func testGroupsContaining() {
        let groups = createSampleGroups()
        let containing = groups.groups(containing: "s1")

        #expect(containing.count == 1)
        #expect(containing.first?.contains(photoId: "s1") == true)
    }

    // MARK: - Batch Operations Tests

    @Test("settingSelectionが全グループの選択状態を設定する")
    func testSettingSelection() {
        let groups = createSampleGroups()

        let allSelected = groups.settingSelection(true)
        #expect(allSelected.allSatisfy { $0.isSelected })

        let noneSelected = groups.settingSelection(false)
        #expect(noneSelected.allSatisfy { !$0.isSelected })
    }

    @Test("groupedByTypeがタイプ別に分類する")
    func testGroupedByType() {
        let groups = createSampleGroups()
        let grouped = groups.groupedByType

        #expect(grouped[.similar]?.count == 2)
        #expect(grouped[.screenshot]?.count == 1)
        #expect(grouped[.selfie]?.count == 1)
    }

    @Test("allDeletionCandidateIdsが全削除候補を返す")
    func testAllDeletionCandidateIds() {
        let groups = createSampleGroups()
        let candidates = groups.allDeletionCandidateIds

        // ベストショット以外の全写真ID
        #expect(!candidates.isEmpty)
    }

    @Test("allPhotoIdsが全写真IDを返す")
    func testAllPhotoIds() {
        let groups = createSampleGroups()
        let allIds = groups.allPhotoIds

        #expect(allIds.count == 11)
    }

    @Test("uniquePhotoIdsが重複なしの写真IDセットを返す")
    func testUniquePhotoIds() {
        let groups = createSampleGroups()
        let uniqueIds = groups.uniquePhotoIds

        #expect(uniqueIds.count == 11)
    }
}

// MARK: - PhotoGroup Protocol Conformance Tests

@Suite("PhotoGroup Protocol Conformance Tests")
struct PhotoGroupProtocolConformanceTests {

    @Test("PhotoGroupがIdentifiable準拠している")
    func testIdentifiable() {
        let group = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        let _ = group.id // Identifiable要件
    }

    @Test("PhotoGroupがHashable準拠している")
    func testHashable() {
        let group1 = PhotoGroup(type: .similar, photoIds: ["1", "2"])
        let group2 = PhotoGroup(type: .similar, photoIds: ["1", "2"])

        // 同じIDでない限り異なるハッシュ値
        #expect(group1.hashValue != group2.hashValue)

        // Setに追加可能
        var set = Set<PhotoGroup>()
        set.insert(group1)
        set.insert(group2)
        #expect(set.count == 2)
    }

    @Test("PhotoGroupがSendable準拠している")
    func testSendable() async {
        let group = PhotoGroup(type: .similar, photoIds: ["1", "2"])

        // 別のコンテキストに渡せる
        let result = await Task.detached {
            group.type
        }.value

        #expect(result == .similar)
    }

    @Test("PhotoGroupがEquatable準拠している")
    func testEquatable() {
        let id = UUID()
        let group1 = PhotoGroup(id: id, type: .similar, photoIds: ["1", "2"])
        let group2 = PhotoGroup(id: id, type: .similar, photoIds: ["1", "2"])

        #expect(group1 == group2)
    }

    @Test("PhotoGroupのdescriptionが期待通りの形式")
    func testCustomStringConvertible() {
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2"],
            fileSizes: [1000, 2000]
        )

        let description = group.description
        #expect(description.contains("PhotoGroup"))
        #expect(description.contains("類似写真"))
        #expect(description.contains("count: 2"))
    }
}
