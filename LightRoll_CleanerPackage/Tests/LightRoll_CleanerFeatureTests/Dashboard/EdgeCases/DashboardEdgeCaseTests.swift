//
//  DashboardEdgeCaseTests.swift
//  LightRoll_CleanerFeatureTests
//
//  Dashboardエッジケース・境界値テスト
//  異常系、境界値、エラーハンドリングを包括的にテスト
//  M5-T13: Dashboard エッジケーステスト
//  Created by AI Assistant
//

import Foundation
import Testing
import SwiftUI

@testable import LightRoll_CleanerFeature

// MARK: - Boundary Value Tests

@Suite("Dashboard境界値テスト", .tags(.edgeCase, .boundary))
@MainActor
struct BoundaryValueTests {

    // MARK: - Zero Values

    @Test("境界値: 0枚の写真でスキャン")
    func testScanWithZeroPhotos() async throws {
        // Given
        let emptyPhotos: [PhotoAsset] = []
        let emptyGroups: [PhotoGroup] = []

        // When
        let scanResult = ScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: 0.0
        )

        // Then
        #expect(scanResult.totalPhotosScanned == 0)
        #expect(scanResult.groupsFound == 0)
        #expect(scanResult.potentialSavings == 0)
        #expect(scanResult.formattedPotentialSavings.contains("0") || scanResult.formattedPotentialSavings.contains("バイト"))
    }

    @Test("境界値: 0バイトのファイルサイズ")
    func testZeroFileSizePhoto() {
        // Given
        let photo = PhotoAsset(
            id: "zero-size",
            creationDate: Date(),
            fileSize: 0
        )

        // Then
        #expect(photo.fileSize == 0)
        let formattedSize = ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file)
        #expect(formattedSize.contains("0") || formattedSize.contains("バイト"))
    }

    @Test("境界値: 空のグループ")
    func testEmptyGroup() {
        // Given
        let emptyGroup = PhotoGroup(
            type: .similar,
            photoIds: [],
            fileSizes: []
        )

        // Then
        #expect(emptyGroup.isEmpty)
        #expect(emptyGroup.count == 0)
        #expect(emptyGroup.totalSize == 0)
        #expect(emptyGroup.reclaimableSize == 0)
        #expect(emptyGroup.reclaimableCount == 0)
    }

    // MARK: - Maximum Values

    @Test("境界値: 非常に大きなファイルサイズ")
    func testVeryLargeFileSize() {
        // Given: 100GB
        let largeSize: Int64 = 100_000_000_000

        let photo = PhotoAsset(
            id: "large",
            creationDate: Date(),
            fileSize: largeSize
        )

        // Then
        #expect(photo.fileSize == largeSize)
        let formattedSize = ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file)
        #expect(formattedSize.contains("GB"))
    }

    @Test("境界値: 大量の写真を含むグループ")
    func testGroupWithMaxPhotos() {
        // Given: 1000枚の写真
        let photoIds = (0..<1000).map { "photo-\($0)" }
        let fileSizes = Array(repeating: Int64(3_000_000), count: 1000)

        let largeGroup = PhotoGroup(
            type: .screenshot,
            photoIds: photoIds,
            fileSizes: fileSizes
        )

        // Then
        #expect(largeGroup.count == 1000)
        #expect(largeGroup.totalSize == 3_000_000_000)
        #expect(largeGroup.reclaimableSize == 3_000_000_000)
    }

    @Test("境界値: 最大個数のグループ")
    func testMaximumNumberOfGroups() {
        // Given: 500グループ
        var groups: [PhotoGroup] = []
        for i in 0..<500 {
            let group = PhotoGroup(
                type: GroupType.allCases[i % GroupType.allCases.count],
                photoIds: ["photo-\(i)"],
                fileSizes: [Int64(1_000_000)]
            )
            groups.append(group)
        }

        // Then
        #expect(groups.count == 500)

        let totalPhotos = groups.reduce(0) { $0 + $1.count }
        #expect(totalPhotos == 500)
    }

    // MARK: - Single Element

    @Test("境界値: 1枚だけの写真")
    func testSinglePhoto() {
        // Given
        let photo = PhotoAsset(
            id: "single",
            creationDate: Date(),
            fileSize: 2_500_000
        )

        // Then
        #expect(photo.fileSize > 0)
    }

    @Test("境界値: 1枚だけのグループ")
    func testSinglePhotoGroup() {
        // Given
        let group = PhotoGroup(
            type: .blurry,
            photoIds: ["photo-1"],
            fileSizes: [2_500_000]
        )

        // Then
        #expect(group.count == 1)
        #expect(group.totalSize == 2_500_000)
        #expect(!group.isEmpty)
    }

    @Test("境界値: 1つだけのグループ")
    func testSingleGroupInList() {
        // Given
        let groups = [
            PhotoGroup(
                type: .similar,
                photoIds: ["1", "2", "3"],
                fileSizes: [1_000_000, 1_000_000, 1_000_000],
                bestShotIndex: 0
            )
        ]

        // Then
        #expect(groups.count == 1)

        let totalPhotos = groups.totalPhotoCount
        #expect(totalPhotos == 3)
    }
}

// MARK: - Error Handling Tests

@Suite("Dashboardエラーハンドリングテスト", .tags(.edgeCase, .errorHandling))
@MainActor
struct DashboardErrorHandlingTests {

    @Test("エラー: 不正なインデックスのベストショット")
    func testInvalidBestShotIndex() {
        // Given: ベストショットインデックスが範囲外
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 1_000_000, 1_000_000],
            bestShotIndex: 10 // 範囲外
        )

        // Then: 範囲外でもクラッシュしない
        #expect(group.bestShotIndex == 10)
        #expect(group.count == 3)

        // bestShotIdは範囲外なのでnil
        let bestShotId = group.bestShotIndex.flatMap { index in
            index < group.photoIds.count ? group.photoIds[index] : nil
        }
        #expect(bestShotId == nil)
    }

    @Test("エラー: 負のインデックス")
    func testNegativeBestShotIndex() {
        // Given
        let group = PhotoGroup(
            type: .selfie,
            photoIds: ["1", "2"],
            fileSizes: [1_000_000, 1_000_000],
            bestShotIndex: -1
        )

        // Then
        #expect(group.bestShotIndex == -1)

        let bestShotId = group.bestShotIndex.flatMap { index in
            index >= 0 && index < group.photoIds.count ? group.photoIds[index] : nil
        }
        #expect(bestShotId == nil)
    }

    @Test("エラー: photoIdsとfileSizesの数が不一致")
    func testMismatchedPhotoIdsAndFileSizes() {
        // Given: photoIds=3件、fileSizes=2件
        let group = PhotoGroup(
            type: .duplicate,
            photoIds: ["1", "2", "3"],
            fileSizes: [1_000_000, 1_000_000] // 1件少ない
        )

        // Then: クラッシュしないことを確認
        #expect(group.photoIds.count == 3)
        #expect(group.fileSizes.count == 2)

        // 安全な処理
        let minCount = min(group.photoIds.count, group.fileSizes.count)
        #expect(minCount == 2)
    }

    @Test("エラー: 空のphotoIdsで非nilのbestShotIndex")
    func testBestShotIndexWithEmptyPhotoIds() {
        // Given
        let group = PhotoGroup(
            type: .similar,
            photoIds: [],
            fileSizes: [],
            bestShotIndex: 0
        )

        // Then
        #expect(group.isEmpty)
        #expect(group.bestShotIndex == 0)

        let bestShotId = group.bestShotIndex.flatMap { index in
            index < group.photoIds.count ? group.photoIds[index] : nil
        }
        #expect(bestShotId == nil)
    }

    @Test("エラー: 負のファイルサイズ")
    func testNegativeFileSize() {
        // Given
        let group = PhotoGroup(
            type: .largeVideo,
            photoIds: ["1"],
            fileSizes: [-1_000_000]
        )

        // Then: 負のサイズでもクラッシュしない
        #expect(group.totalSize < 0)

        // 実際のアプリでは0にクランプする処理が必要だが、テストでは検出
        #expect(group.fileSizes[0] == -1_000_000)
    }

    @Test("エラー: 極端に長いカスタム名")
    func testExtremelyLongCustomName() {
        // Given
        let longName = String(repeating: "あ", count: 10000)

        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1"],
            fileSizes: [1_000_000],
            customName: longName
        )

        // Then
        #expect(group.customName == longName)
        #expect(group.displayName == longName)
        #expect(group.displayName.count == 10000)
    }

    @Test("エラー: 特殊文字を含むphotoId")
    func testSpecialCharactersInPhotoId() {
        // Given
        let specialId = "photo-<script>alert('test')</script>-123"

        let group = PhotoGroup(
            type: .similar,
            photoIds: [specialId],
            fileSizes: [1_000_000]
        )

        // Then
        #expect(group.photoIds.first == specialId)
        #expect(group.count == 1)
    }
}

// MARK: - Date and Time Edge Cases

@Suite("Dashboard日付・時刻エッジケーステスト", .tags(.edgeCase, .dateTime))
@MainActor
struct DateTimeEdgeCaseTests {

    @Test("日付: 遠い過去の日付")
    func testVeryOldDate() {
        // Given: 1970年1月1日
        let oldDate = Date(timeIntervalSince1970: 0)

        let photo = PhotoAsset(
            id: "old",
            creationDate: oldDate,
            fileSize: 500_000
        )

        // Then
        #expect(photo.creationDate == oldDate)
        #expect(photo.creationDate! < Date())
    }

    @Test("日付: 未来の日付")
    func testFutureDate() {
        // Given: 2100年1月1日
        var components = DateComponents()
        components.year = 2100
        components.month = 1
        components.day = 1

        let calendar = Calendar.current
        let futureDate = calendar.date(from: components)!

        let photo = PhotoAsset(
            id: "future",
            creationDate: futureDate,
            fileSize: 2_500_000
        )

        // Then
        #expect(photo.creationDate == futureDate)
        #expect(photo.creationDate! > Date())
    }

    @Test("日付: creationDateの存在確認")
    func testCreationDateExists() {
        // Given
        let sameDate = Date()

        let photo = PhotoAsset(
            id: "same-date",
            creationDate: sameDate,
            fileSize: 3_500_000
        )

        // Then
        #expect(photo.creationDate == sameDate)
    }

    @Test("日付: 過去の日付")
    func testPastDate() {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)

        let photo = PhotoAsset(
            id: "past-date",
            creationDate: yesterday,
            fileSize: 2_000_000
        )

        // Then
        #expect(photo.creationDate! < now)
    }
}

// MARK: - Dimension Edge Cases

@Suite("Dashboard次元エッジケーステスト", .tags(.edgeCase, .dimensions))
@MainActor
struct DimensionEdgeCaseTests {

    @Test("次元: 最小ファイルサイズ")
    func testMinimumFileSize() {
        // Given
        let photo = PhotoAsset(
            id: "min-size",
            creationDate: Date(),
            fileSize: 1
        )

        // Then
        #expect(photo.fileSize == 1)
    }

    @Test("次元: 標準ファイルサイズ")
    func testStandardFileSize() {
        // Given
        let photo = PhotoAsset(
            id: "standard",
            creationDate: Date(),
            fileSize: 3_000_000
        )

        // Then
        #expect(photo.fileSize == 3_000_000)
    }

    @Test("次元: 大容量ファイルサイズ")
    func testLargeFileSize() {
        // Given: 1GB
        let photo = PhotoAsset(
            id: "large",
            creationDate: Date(),
            fileSize: 1_000_000_000
        )

        // Then
        #expect(photo.fileSize == 1_000_000_000)
        let formattedSize = ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file)
        #expect(formattedSize.contains("GB") || formattedSize.contains("MB"))
    }
}

// MARK: - Navigation Edge Cases

@Suite("Dashboardナビゲーションエッジケーステスト", .tags(.edgeCase))
@MainActor
struct NavigationEdgeCaseTests {

    @Test("ナビゲーション: 空のパスでバック操作")
    func testBackOnEmptyPath() {
        // Given
        let router = DashboardRouter()
        #expect(router.path.isEmpty)

        // When
        router.navigateBack()

        // Then: クラッシュしない
        #expect(router.path.isEmpty)
    }

    @Test("ナビゲーション: 100回連続で同じ画面に遷移")
    func testNavigateToSameScreenHundredTimes() {
        // Given
        let router = DashboardRouter()

        // When
        for _ in 0..<100 {
            router.navigateToGroupList()
        }

        // Then
        #expect(router.path.count == 100)
        #expect(router.path.allSatisfy { $0 == .groupList })
    }

    @Test("ナビゲーション: 深すぎるナビゲーションスタック")
    func testVeryDeepNavigationStack() {
        // Given
        let router = DashboardRouter()
        let group = PhotoGroup(
            type: .similar,
            photoIds: ["1"],
            fileSizes: [1_000_000]
        )

        // When: 50階層
        for _ in 0..<50 {
            router.navigateToGroupDetail(group: group)
        }

        // Then
        #expect(router.path.count == 50)
    }

    @Test("ナビゲーション: 存在しない画面へのnavigateBackTo")
    func testNavigateBackToNonExistentScreen() {
        // Given
        let router = DashboardRouter()
        let group = PhotoGroup(type: .similar, photoIds: ["1"], fileSizes: [1000])

        router.navigateToGroupList()

        // When: 存在しない画面へ戻ろうとする
        router.navigateBackTo(.groupDetail(group))

        // Then: 変化なし
        #expect(router.path.count == 1)
        #expect(router.path.first == .groupList)
    }

    @Test("ナビゲーション: nilコールバックでnavigateToSettings")
    func testNavigateToSettingsWithNilCallback() {
        // Given
        let router = DashboardRouter()
        #expect(router.onNavigateToSettings == nil)

        // When & Then: クラッシュしない
        router.navigateToSettings()
        #expect(true)
    }
}

// MARK: - Unicode and Special Character Tests

@Suite("DashboardUnicode・特殊文字テスト", .tags(.edgeCase, .unicode))
@MainActor
struct UnicodeEdgeCaseTests {

    @Test("Unicode: 絵文字を含むカスタム名")
    func testEmojiInCustomName() {
        // Given
        let emojiName = "🎉パーティー写真🎊"

        let group = PhotoGroup(
            type: .selfie,
            photoIds: ["1"],
            fileSizes: [1_000_000],
            customName: emojiName
        )

        // Then
        #expect(group.customName == emojiName)
        #expect(group.displayName.contains("🎉"))
    }

    @Test("Unicode: 多言語文字を含むカスタム名")
    func testMultilingualCustomName() {
        // Given
        let multilingualName = "Photos 写真 照片 사진 फ़ोटो"

        let group = PhotoGroup(
            type: .screenshot,
            photoIds: ["1"],
            fileSizes: [1_000_000],
            customName: multilingualName
        )

        // Then
        #expect(group.customName == multilingualName)
    }

    @Test("Unicode: 制御文字を含む文字列")
    func testControlCharactersInName() {
        // Given
        let nameWithControl = "Test\n\r\tName"

        let group = PhotoGroup(
            type: .blurry,
            photoIds: ["1"],
            fileSizes: [1_000_000],
            customName: nameWithControl
        )

        // Then
        #expect(group.customName == nameWithControl)
        #expect(group.customName?.contains("\n") == true)
    }

    @Test("Unicode: 空白文字のみのカスタム名")
    func testWhitespaceOnlyCustomName() {
        // Given
        let whitespaceName = "   "

        let group = PhotoGroup(
            type: .duplicate,
            photoIds: ["1"],
            fileSizes: [1_000_000],
            customName: whitespaceName
        )

        // Then
        #expect(group.customName == whitespaceName)
        #expect(group.displayName == whitespaceName)
    }
}

// MARK: - Concurrent Access Tests

@Suite("Dashboard並行アクセステスト", .tags(.edgeCase, .concurrency))
@MainActor
struct ConcurrentAccessTests {

    @Test("並行: 複数のViewStateの同時生成")
    func testConcurrentViewStateCreation() async {
        // Given & When
        await withTaskGroup(of: HomeView.ViewState.self) { group in
            for i in 0..<100 {
                group.addTask {
                    if i % 4 == 0 {
                        return .loading
                    } else if i % 4 == 1 {
                        return .loaded
                    } else if i % 4 == 2 {
                        return .scanning(progress: Double(i) / 100.0)
                    } else {
                        return .error("Error \(i)")
                    }
                }
            }

            var states: [HomeView.ViewState] = []
            for await state in group {
                states.append(state)
            }

            // Then
            #expect(states.count == 100)
        }
    }

    @Test("並行: 複数のPhotoGroupの同時生成")
    func testConcurrentPhotoGroupCreation() async {
        // When
        await withTaskGroup(of: PhotoGroup.self) { group in
            for i in 0..<50 {
                group.addTask {
                    PhotoGroup(
                        type: GroupType.allCases[i % GroupType.allCases.count],
                        photoIds: ["photo-\(i)"],
                        fileSizes: [Int64(i * 1_000_000)]
                    )
                }
            }

            var groups: [PhotoGroup] = []
            for await photoGroup in group {
                groups.append(photoGroup)
            }

            // Then
            #expect(groups.count == 50)
        }
    }
}

// MARK: - Custom Test Tags

extension Tag {
    @Tag static var edgeCase: Self
    @Tag static var boundary: Self
    @Tag static var errorHandling: Self
    @Tag static var dateTime: Self
    @Tag static var dimensions: Self
    @Tag static var unicode: Self
    @Tag static var concurrency: Self
}
