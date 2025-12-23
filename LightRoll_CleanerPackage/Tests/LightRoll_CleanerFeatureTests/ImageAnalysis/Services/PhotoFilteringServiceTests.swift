//
//  PhotoFilteringServiceTests.swift
//  LightRoll_CleanerFeatureTests
//
//  PhotoFilteringServiceのテスト
//  BUG-002修正: スキャン設定がグルーピングに反映されない問題のテスト
//  Created by AI Assistant on 2025-12-23.
//

import Testing
import Foundation
@testable import LightRoll_CleanerFeature

// MARK: - PhotoFilteringService Tests

@Suite("PhotoFilteringService Tests")
struct PhotoFilteringServiceTests {

    // MARK: - Test Fixtures

    /// テスト用の写真を作成（通常の画像）
    private func createNormalPhoto(id: String = "photo-normal") -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            fileSize: 2_000_000,
            isFavorite: false
        )
    }

    /// テスト用の写真を作成（動画）
    private func createVideoPhoto(id: String = "photo-video") -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .video,
            mediaSubtypes: [],
            pixelWidth: 1920,
            pixelHeight: 1080,
            duration: 60.0,
            fileSize: 50_000_000,
            isFavorite: false
        )
    }

    /// テスト用の写真を作成（スクリーンショット）
    private func createScreenshotPhoto(id: String = "photo-screenshot") -> Photo {
        Photo(
            id: id,
            localIdentifier: id,
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: .screenshot,
            pixelWidth: 1170,
            pixelHeight: 2532,
            duration: 0,
            fileSize: 500_000,
            isFavorite: false
        )
    }

    // MARK: - Initialization Tests

    @Test("初期化 - インスタンス生成成功")
    func testInitialization() {
        let sut = PhotoFilteringService()
        #expect(sut != nil)
    }

    // MARK: - Filter Tests - All Included

    @Test("フィルタリング - すべて含める設定ではフィルタリングなし")
    func testFilter_allIncluded_noFiltering() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal"),
            createVideoPhoto(id: "video"),
            createScreenshotPhoto(id: "screenshot")
        ]
        let scanSettings = ScanSettings(
            includeVideos: true,
            includeScreenshots: true,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.count == 3)
    }

    // MARK: - Filter Tests - Exclude Videos

    @Test("フィルタリング - 動画を除外")
    func testFilter_excludeVideos() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal"),
            createVideoPhoto(id: "video"),
            createScreenshotPhoto(id: "screenshot")
        ]
        let scanSettings = ScanSettings(
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.count == 2)
        #expect(!filtered.contains { $0.id == "video" })
        #expect(filtered.contains { $0.id == "normal" })
        #expect(filtered.contains { $0.id == "screenshot" })
    }

    // MARK: - Filter Tests - Exclude Screenshots

    @Test("フィルタリング - スクリーンショットを除外")
    func testFilter_excludeScreenshots() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal"),
            createVideoPhoto(id: "video"),
            createScreenshotPhoto(id: "screenshot")
        ]
        let scanSettings = ScanSettings(
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.count == 2)
        #expect(!filtered.contains { $0.id == "screenshot" })
        #expect(filtered.contains { $0.id == "normal" })
        #expect(filtered.contains { $0.id == "video" })
    }

    // MARK: - Filter Tests - Multiple Exclusions

    @Test("フィルタリング - 動画とスクリーンショットを除外")
    func testFilter_excludeVideosAndScreenshots() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal"),
            createVideoPhoto(id: "video"),
            createScreenshotPhoto(id: "screenshot")
        ]
        let scanSettings = ScanSettings(
            includeVideos: false,
            includeScreenshots: false,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.count == 1)
        #expect(filtered.first?.id == "normal")
    }

    // MARK: - Filter Tests - Empty Array

    @Test("フィルタリング - 空配列")
    func testFilter_emptyArray() {
        // Given
        let sut = PhotoFilteringService()
        let photos: [Photo] = []
        let scanSettings = ScanSettings()

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.isEmpty)
    }

    // MARK: - FilterWithStats Tests

    @Test("フィルタリング統計 - 動画除外の統計")
    func testFilterWithStats_excludeVideos() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal1"),
            createNormalPhoto(id: "normal2"),
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createVideoPhoto(id: "video3")
        ]
        let scanSettings = ScanSettings(
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: true
        )

        // When
        let result = sut.filterWithStats(photos: photos, with: scanSettings)

        // Then
        #expect(result.originalCount == 5)
        #expect(result.filteredCount == 2)
        #expect(result.excludedVideoCount == 3)
        #expect(result.excludedScreenshotCount == 0)
        #expect(result.totalExcludedCount == 3)
    }

    @Test("フィルタリング統計 - スクリーンショット除外の統計")
    func testFilterWithStats_excludeScreenshots() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal"),
            createScreenshotPhoto(id: "screenshot1"),
            createScreenshotPhoto(id: "screenshot2")
        ]
        let scanSettings = ScanSettings(
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: true
        )

        // When
        let result = sut.filterWithStats(photos: photos, with: scanSettings)

        // Then
        #expect(result.originalCount == 3)
        #expect(result.filteredCount == 1)
        #expect(result.excludedVideoCount == 0)
        #expect(result.excludedScreenshotCount == 2)
    }

    @Test("フィルタリング統計 - フィルタリング率")
    func testFilterWithStats_filteringRate() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createNormalPhoto(id: "normal1"),
            createNormalPhoto(id: "normal2"),
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2")
        ]
        let scanSettings = ScanSettings(
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: true
        )

        // When
        let result = sut.filterWithStats(photos: photos, with: scanSettings)

        // Then
        #expect(result.filteringRate == 0.5) // 2/4 = 50%
    }

    // MARK: - Edge Cases

    @Test("フィルタリング - 動画のみの配列で動画除外")
    func testFilter_videosOnly_excludeVideos() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createVideoPhoto(id: "video1"),
            createVideoPhoto(id: "video2"),
            createVideoPhoto(id: "video3")
        ]
        let scanSettings = ScanSettings(
            includeVideos: false,
            includeScreenshots: true,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.isEmpty)
    }

    @Test("フィルタリング - スクリーンショットのみの配列でスクリーンショット除外")
    func testFilter_screenshotsOnly_excludeScreenshots() {
        // Given
        let sut = PhotoFilteringService()
        let photos = [
            createScreenshotPhoto(id: "screenshot1"),
            createScreenshotPhoto(id: "screenshot2")
        ]
        let scanSettings = ScanSettings(
            includeVideos: true,
            includeScreenshots: false,
            includeSelfies: true
        )

        // When
        let filtered = sut.filter(photos: photos, with: scanSettings)

        // Then
        #expect(filtered.isEmpty)
    }
}

// MARK: - PhotoFilteringResult Tests

@Suite("PhotoFilteringResult Tests")
struct PhotoFilteringResultTests {

    @Test("初期化 - 基本値")
    func testInitialization() {
        // Given
        let photos = [
            Photo(
                id: "test",
                localIdentifier: "test",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 0,
                fileSize: 1000,
                isFavorite: false
            )
        ]

        // When
        let result = PhotoFilteringResult(
            filteredPhotos: photos,
            originalCount: 5,
            excludedVideoCount: 2,
            excludedScreenshotCount: 1,
            excludedSelfieCount: 1
        )

        // Then
        #expect(result.filteredCount == 1)
        #expect(result.originalCount == 5)
        #expect(result.excludedVideoCount == 2)
        #expect(result.excludedScreenshotCount == 1)
        #expect(result.excludedSelfieCount == 1)
        #expect(result.totalExcludedCount == 4)
    }

    @Test("フィルタリング率 - 正常計算")
    func testFilteringRate() {
        // Given
        let result = PhotoFilteringResult(
            filteredPhotos: [],
            originalCount: 100,
            excludedVideoCount: 25,
            excludedScreenshotCount: 25,
            excludedSelfieCount: 0
        )

        // When & Then
        // 注: filteredPhotosは空なので、filteredCountは0
        // filteringRate = 0 / 100 = 0.0
        #expect(result.filteringRate == 0.0)
    }

    @Test("フィルタリング率 - ゼロ除算回避")
    func testFilteringRate_zeroDivision() {
        // Given
        let result = PhotoFilteringResult(
            filteredPhotos: [],
            originalCount: 0
        )

        // When & Then
        #expect(result.filteringRate == 0.0) // 0/0 = 0.0 (ゼロ除算回避)
    }

    @Test("フォーマット済みフィルタリング率")
    func testFormattedFilteringRate() {
        // Given
        let photos = (0..<75).map { i in
            Photo(
                id: "photo-\(i)",
                localIdentifier: "photo-\(i)",
                creationDate: Date(),
                modificationDate: Date(),
                mediaType: .image,
                mediaSubtypes: [],
                pixelWidth: 100,
                pixelHeight: 100,
                duration: 0,
                fileSize: 1000,
                isFavorite: false
            )
        }
        let result = PhotoFilteringResult(
            filteredPhotos: photos,
            originalCount: 100
        )

        // When & Then
        #expect(result.formattedFilteringRate == "75.0%")
    }

    @Test("CustomStringConvertible")
    func testDescription() {
        // Given
        let result = PhotoFilteringResult(
            filteredPhotos: [],
            originalCount: 10,
            excludedVideoCount: 3,
            excludedScreenshotCount: 2,
            excludedSelfieCount: 1
        )

        // When
        let description = result.description

        // Then
        #expect(description.contains("filtered: 0/10"))
        #expect(description.contains("videos=3"))
        #expect(description.contains("screenshots=2"))
        #expect(description.contains("selfies=1"))
    }

    @Test("Equatable")
    func testEquatable() {
        // Given
        let photo = Photo(
            id: "test",
            localIdentifier: "test",
            creationDate: Date(),
            modificationDate: Date(),
            mediaType: .image,
            mediaSubtypes: [],
            pixelWidth: 100,
            pixelHeight: 100,
            duration: 0,
            fileSize: 1000,
            isFavorite: false
        )
        let result1 = PhotoFilteringResult(
            filteredPhotos: [photo],
            originalCount: 5,
            excludedVideoCount: 2
        )
        let result2 = PhotoFilteringResult(
            filteredPhotos: [photo],
            originalCount: 5,
            excludedVideoCount: 2
        )
        let result3 = PhotoFilteringResult(
            filteredPhotos: [photo],
            originalCount: 5,
            excludedVideoCount: 3 // 異なる値
        )

        // When & Then
        #expect(result1 == result2)
        #expect(result1 != result3)
    }
}
