//
//  PreviewHelpersTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PreviewHelpers.swiftのモックデータ生成のテストスイート
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - Test Suite

@Suite("PreviewHelpers Tests")
@MainActor
struct PreviewHelpersTests {

    // MARK: - MockPhoto Tests (10件)

    @Test("MockPhoto.standard - 標準的な写真を生成")
    func mockPhotoStandard() {
        let photo = MockPhoto.standard

        #expect(photo.id == "mock-photo-standard")
        #expect(photo.mediaType == .image)
        #expect(photo.pixelWidth == 4032)
        #expect(photo.pixelHeight == 3024)
        #expect(photo.fileSize == 2_500_000)
        #expect(photo.isFavorite == false)
    }

    @Test("MockPhoto.highResolution - 高解像度写真を生成")
    func mockPhotoHighResolution() {
        let photo = MockPhoto.highResolution

        #expect(photo.id == "mock-photo-high-res")
        #expect(photo.pixelWidth == 8000)
        #expect(photo.pixelHeight == 6000)
        #expect(photo.fileSize == 15_000_000)
        #expect(photo.isFavorite == true)
    }

    @Test("MockPhoto.screenshot - スクリーンショットを生成")
    func mockPhotoScreenshot() {
        let photo = MockPhoto.screenshot

        #expect(photo.isScreenshot == true)
        #expect(photo.pixelWidth == 1170)
        #expect(photo.pixelHeight == 2532)
    }

    @Test("MockPhoto.hdr - HDR写真を生成")
    func mockPhotoHDR() {
        let photo = MockPhoto.hdr

        #expect(photo.isHDR == true)
        #expect(photo.mediaSubtypes.contains(.hdr))
    }

    @Test("MockPhoto.panorama - パノラマ写真を生成")
    func mockPhotoPanorama() {
        let photo = MockPhoto.panorama

        #expect(photo.isPanorama == true)
        #expect(photo.pixelWidth == 12000)
        #expect(photo.pixelHeight == 3000)
        #expect(photo.isFavorite == true)
    }

    @Test("MockPhoto.livePhoto - Live Photo を生成")
    func mockPhotoLivePhoto() {
        let photo = MockPhoto.livePhoto

        #expect(photo.isLivePhoto == true)
        #expect(photo.fileSize == 3_800_000)
    }

    @Test("MockPhoto.video - 動画を生成")
    func mockPhotoVideo() {
        let photo = MockPhoto.video

        #expect(photo.isVideo == true)
        #expect(photo.duration == 45.5)
        #expect(photo.fileSize == 15_000_000)
    }

    @Test("MockPhoto.shortVideo - 短い動画を生成")
    func mockPhotoShortVideo() {
        let photo = MockPhoto.shortVideo

        #expect(photo.isVideo == true)
        #expect(photo.duration == 10.2)
    }

    @Test("MockPhoto.timelapse - タイムラプス動画を生成")
    func mockPhotoTimelapse() {
        let photo = MockPhoto.timelapse

        #expect(photo.isVideo == true)
        #expect(photo.mediaSubtypes.contains(.timelapse))
        #expect(photo.isFavorite == true)
    }

    @Test("MockPhoto.multiple - 複数の写真を生成")
    func mockPhotoMultiple() {
        let photos = MockPhoto.multiple(count: 10)

        #expect(photos.count == 10)

        // 各写真が一意のIDを持つことを確認
        let uniqueIds = Set(photos.map { $0.id })
        #expect(uniqueIds.count == 10)

        // 写真とビデオが混在している
        let hasImage = photos.contains { $0.mediaType == .image }
        let hasVideo = photos.contains { $0.mediaType == .video }
        #expect(hasImage == true)
        #expect(hasVideo == true)
    }

    // MARK: - MockPhotoGroup Tests (7件)

    @Test("MockPhotoGroup.similarPhotos - 類似写真グループを生成")
    func mockPhotoGroupSimilarPhotos() {
        let group = MockPhotoGroup.similarPhotos

        #expect(group.type == .similar)
        #expect(group.photoIds.count == 5)
        #expect(group.bestShotIndex == 2)
        #expect(group.similarityScore == 0.92)
        #expect(group.isSelected == false)
    }

    @Test("MockPhotoGroup.selfies - 自撮りグループを生成")
    func mockPhotoGroupSelfies() {
        let group = MockPhotoGroup.selfies

        #expect(group.type == .selfie)
        #expect(group.photoIds.count == 3)
        #expect(group.bestShotIndex == 1)
    }

    @Test("MockPhotoGroup.screenshots - スクリーンショットグループを生成")
    func mockPhotoGroupScreenshots() {
        let group = MockPhotoGroup.screenshots

        #expect(group.type == .screenshot)
        #expect(group.photoIds.count == 8)
        #expect(group.bestShotIndex == nil)
    }

    @Test("MockPhotoGroup.blurryPhotos - ブレ写真グループを生成")
    func mockPhotoGroupBlurryPhotos() {
        let group = MockPhotoGroup.blurryPhotos

        #expect(group.type == .blurry)
        #expect(group.photoIds.count == 4)
        #expect(group.isSelected == true)
    }

    @Test("MockPhotoGroup.largeVideos - 大容量動画グループを生成")
    func mockPhotoGroupLargeVideos() {
        let group = MockPhotoGroup.largeVideos

        #expect(group.type == .largeVideo)
        #expect(group.photoIds.count == 2)
    }

    @Test("MockPhotoGroup.duplicates - 重複写真グループを生成")
    func mockPhotoGroupDuplicates() {
        let group = MockPhotoGroup.duplicates

        #expect(group.type == .duplicate)
        #expect(group.photoIds.count == 2)
        #expect(group.bestShotIndex == 0)
        #expect(group.similarityScore == 1.0)
    }

    @Test("MockPhotoGroup.multipleGroups - 複数グループを生成")
    func mockPhotoGroupMultipleGroups() {
        let groups = MockPhotoGroup.multipleGroups()

        #expect(groups.count == 6)

        // すべてのグループタイプが含まれている
        let types = Set(groups.map { $0.type })
        #expect(types.contains(.duplicate))
        #expect(types.contains(.similar))
        #expect(types.contains(.blurry))
        #expect(types.contains(.screenshot))
        #expect(types.contains(.selfie))
        #expect(types.contains(.largeVideo))
    }

    // MARK: - MockStorageInfo Tests (5件)

    @Test("MockStorageInfo.standard - 標準的なストレージ情報を生成")
    func mockStorageInfoStandard() {
        let info = MockStorageInfo.standard

        #expect(info.totalCapacity == 128_000_000_000)
        #expect(info.availableCapacity == 45_000_000_000)
        #expect(info.photosUsedCapacity == 25_300_000_000)
        #expect(info.reclaimableCapacity == 3_500_000_000)
        #expect(info.storageLevel == .normal)
    }

    @Test("MockStorageInfo.lowStorage - 空き容量が少ないストレージ情報を生成")
    func mockStorageInfoLowStorage() {
        let info = MockStorageInfo.lowStorage

        #expect(info.totalCapacity == 128_000_000_000)
        #expect(info.availableCapacity == 8_000_000_000)
        #expect(info.isLowStorage == true)
    }

    @Test("MockStorageInfo.criticalStorage - 危機的なストレージ情報を生成")
    func mockStorageInfoCriticalStorage() {
        let info = MockStorageInfo.criticalStorage

        #expect(info.totalCapacity == 128_000_000_000)
        #expect(info.availableCapacity == 2_000_000_000)
        #expect(info.isCriticalStorage == true)
        #expect(info.storageLevel == .critical)
    }

    @Test("MockStorageInfo.largeCapacity - 大容量ストレージ情報を生成")
    func mockStorageInfoLargeCapacity() {
        let info = MockStorageInfo.largeCapacity

        #expect(info.totalCapacity == 512_000_000_000)
        #expect(info.availableCapacity == 200_000_000_000)
        #expect(info.storageLevel == .normal)
    }

    @Test("MockStorageInfo.mostlyEmpty - ほぼ空のストレージ情報を生成")
    func mockStorageInfoMostlyEmpty() {
        let info = MockStorageInfo.mostlyEmpty

        #expect(info.totalCapacity == 256_000_000_000)
        #expect(info.availableCapacity == 240_000_000_000)
        #expect(info.storageLevel == .normal)
    }

    // MARK: - MockAnalysisResult Tests (7件)

    @Test("MockAnalysisResult.highQuality - 高品質写真の分析結果を生成")
    func mockAnalysisResultHighQuality() {
        let result = MockAnalysisResult.highQuality

        #expect(result.qualityScore == 0.85)
        #expect(result.blurScore == 0.15)
        #expect(result.faceCount == 2)
        #expect(result.isScreenshot == false)
        #expect(result.isSelfie == false)
    }

    @Test("MockAnalysisResult.blurry - ブレている写真の分析結果を生成")
    func mockAnalysisResultBlurry() {
        let result = MockAnalysisResult.blurry

        #expect(result.qualityScore == 0.35)
        #expect(result.blurScore == 0.65)
        #expect(result.faceCount == 1)
    }

    @Test("MockAnalysisResult.selfie - 自撮り写真の分析結果を生成")
    func mockAnalysisResultSelfie() {
        let result = MockAnalysisResult.selfie

        #expect(result.isSelfie == true)
        #expect(result.faceCount == 1)
        #expect(result.qualityScore == 0.75)
    }

    @Test("MockAnalysisResult.screenshot - スクリーンショットの分析結果を生成")
    func mockAnalysisResultScreenshot() {
        let result = MockAnalysisResult.screenshot

        #expect(result.isScreenshot == true)
        #expect(result.faceCount == 0)
        #expect(result.blurScore == 0.05)
    }

    @Test("MockAnalysisResult.overexposed - 露出オーバーの分析結果を生成")
    func mockAnalysisResultOverexposed() {
        let result = MockAnalysisResult.overexposed

        #expect(result.brightnessScore == 0.92)
        #expect(result.qualityScore == 0.45)
    }

    @Test("MockAnalysisResult.underexposed - 露出アンダーの分析結果を生成")
    func mockAnalysisResultUnderexposed() {
        let result = MockAnalysisResult.underexposed

        #expect(result.brightnessScore == 0.15)
        #expect(result.qualityScore == 0.40)
    }

    @Test("MockAnalysisResult.multipleFaces - 複数人の顔の分析結果を生成")
    func mockAnalysisResultMultipleFaces() {
        let result = MockAnalysisResult.multipleFaces

        #expect(result.faceCount == 4)
        #expect(result.faceQualityScores.count == 4)
        #expect(result.faceAngles.count == 4)
    }

    // MARK: - Integration Tests (3件)

    @Test("統合 - すべてのMockPhotoバリエーションが正常に生成される")
    func integrationAllPhotoVariations() {
        let photos = [
            MockPhoto.standard,
            MockPhoto.highResolution,
            MockPhoto.screenshot,
            MockPhoto.hdr,
            MockPhoto.panorama,
            MockPhoto.livePhoto,
            MockPhoto.video,
            MockPhoto.shortVideo,
            MockPhoto.timelapse
        ]

        #expect(photos.count == 9)

        // すべての写真が一意のIDを持つ
        let uniqueIds = Set(photos.map { $0.id })
        #expect(uniqueIds.count == 9)
    }

    @Test("統合 - すべてのMockPhotoGroupバリエーションが正常に生成される")
    func integrationAllGroupVariations() {
        let groups = MockPhotoGroup.multipleGroups()

        // グループ数が6つ
        #expect(groups.count == 6)

        // 各グループが有効
        for group in groups {
            #expect(group.photoIds.count > 0)
            #expect(group.fileSizes.count == group.photoIds.count)
        }
    }

    @Test("統合 - すべてのMockStorageInfoバリエーションが正常に生成される")
    func integrationAllStorageVariations() {
        let storages = [
            MockStorageInfo.standard,
            MockStorageInfo.lowStorage,
            MockStorageInfo.criticalStorage,
            MockStorageInfo.largeCapacity,
            MockStorageInfo.mostlyEmpty
        ]

        #expect(storages.count == 5)

        // すべてのストレージ情報が有効
        for storage in storages {
            #expect(storage.totalCapacity > 0)
            #expect(storage.availableCapacity >= 0)
            #expect(storage.photosUsedCapacity >= 0)
        }
    }

    // MARK: - Property Validation Tests (4件)

    @Test("検証 - MockPhotoの作成日時が時系列順")
    func validationPhotoChronology() {
        let photos = MockPhoto.multiple(count: 5)

        // 後の写真ほど古い日時になっている
        for i in 0..<photos.count - 1 {
            #expect(photos[i].creationDate > photos[i + 1].creationDate)
        }
    }

    @Test("検証 - MockPhotoGroupのphotoIdsとfileSizesの数が一致")
    func validationGroupConsistency() {
        let groups = MockPhotoGroup.multipleGroups()

        for group in groups {
            #expect(group.photoIds.count == group.fileSizes.count)
        }
    }

    @Test("検証 - MockStorageInfoの使用率計算が正しい")
    func validationStorageUsageCalculation() {
        let info = MockStorageInfo.standard

        let expectedUsage = Double(info.totalCapacity - info.availableCapacity) / Double(info.totalCapacity)
        #expect(abs(info.usagePercentage - expectedUsage) < 0.001)
    }

    @Test("検証 - MockAnalysisResultの顔情報の整合性")
    func validationAnalysisResultFaceConsistency() {
        let result = MockAnalysisResult.multipleFaces

        #expect(result.faceCount == result.faceQualityScores.count)
        #expect(result.faceCount == result.faceAngles.count)
    }
}
