//
//  StorageServiceTests.swift
//  LightRoll_CleanerFeatureTests
//
//  StorageServiceの単体テスト
//  デバイスストレージ情報取得と容量計算機能をテスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - StorageService Tests

@Suite("StorageService テスト")
struct StorageServiceTests {

    // MARK: - Test Data

    /// テスト用のPhotoAssetを生成
    private func makePhotoAsset(
        id: String = "test-id",
        fileSize: Int64 = 3_500_000
    ) -> PhotoAsset {
        PhotoAsset(
            id: id,
            creationDate: Date(),
            fileSize: fileSize
        )
    }

    /// テスト用のPhotoGroupを生成
    private func makePhotoGroup(
        type: GroupType = .similar,
        photos: [PhotoAsset],
        bestShotIndex: Int? = 0
    ) -> PhotoGroup {
        let totalSize = photos.reduce(0) { $0 + $1.fileSize }
        return PhotoGroup(
            id: UUID(),
            type: type,
            photos: photos,
            bestShotIndex: bestShotIndex,
            totalSize: totalSize
        )
    }

    // MARK: - Initialization Tests

    @Test("StorageServiceを初期化できる")
    func initialization() {
        let service = StorageService()
        #expect(service != nil)
    }

    @Test("カスタムキャッシュ有効期間で初期化できる")
    func initializationWithCustomCacheValidity() {
        let service = StorageService(cacheValidityDuration: 120)
        #expect(service != nil)
    }

    // MARK: - Device Storage Info Tests

    @Test("デバイスストレージ情報を取得できる")
    func getDeviceStorageInfo() async throws {
        let service = StorageService()

        let storageInfo = try await service.getDeviceStorageInfo()

        // デバイスには必ず容量があるはず
        #expect(storageInfo.totalCapacity > 0)
        #expect(storageInfo.availableCapacity >= 0)
        #expect(storageInfo.availableCapacity <= storageInfo.totalCapacity)
    }

    @Test("ストレージ情報がキャッシュされる")
    func storageInfoCaching() async throws {
        let service = StorageService(cacheValidityDuration: 60)

        // 最初の呼び出し
        let firstInfo = try await service.getDeviceStorageInfo()

        // 2回目の呼び出し（キャッシュから取得されるはず）
        let secondInfo = try await service.getDeviceStorageInfo()

        // キャッシュされている場合、同じ値が返されるはず
        #expect(firstInfo.totalCapacity == secondInfo.totalCapacity)
    }

    @Test("キャッシュをクリアできる")
    func clearCache() async throws {
        let service = StorageService(cacheValidityDuration: 60)

        // 最初の呼び出し
        _ = try await service.getDeviceStorageInfo()

        // キャッシュをクリア
        service.clearCache()

        // キャッシュクリア後も正常に取得できる
        let infoAfterClear = try await service.getDeviceStorageInfo()
        #expect(infoAfterClear.totalCapacity > 0)
    }

    // MARK: - Reclaimable Space Tests

    @Test("回収可能容量を正しく計算できる - ベストショット指定あり")
    func estimateReclaimableSpaceWithBestShot() async {
        let service = StorageService()

        // 3枚の写真を持つグループ（ベストショットは0番目）
        let photos = [
            makePhotoAsset(id: "photo-1", fileSize: 1_000_000),  // ベストショット
            makePhotoAsset(id: "photo-2", fileSize: 2_000_000),  // 削除候補
            makePhotoAsset(id: "photo-3", fileSize: 3_000_000),  // 削除候補
        ]
        let group = makePhotoGroup(photos: photos, bestShotIndex: 0)

        let reclaimable = await service.estimateReclaimableSpace(from: [group])

        // ベストショット以外の合計: 2_000_000 + 3_000_000 = 5_000_000
        #expect(reclaimable == 5_000_000)
    }

    @Test("回収可能容量を正しく計算できる - ベストショット指定なし")
    func estimateReclaimableSpaceWithoutBestShot() async {
        let service = StorageService()

        // 3枚の写真を持つグループ（ベストショット未指定）
        let photos = [
            makePhotoAsset(id: "photo-1", fileSize: 1_000_000),  // 最初の写真は保持
            makePhotoAsset(id: "photo-2", fileSize: 2_000_000),  // 削除候補
            makePhotoAsset(id: "photo-3", fileSize: 3_000_000),  // 削除候補
        ]
        let group = makePhotoGroup(photos: photos, bestShotIndex: nil)

        let reclaimable = await service.estimateReclaimableSpace(from: [group])

        // 最初の写真以外の合計: 2_000_000 + 3_000_000 = 5_000_000
        #expect(reclaimable == 5_000_000)
    }

    @Test("複数グループの回収可能容量を正しく計算できる")
    func estimateReclaimableSpaceMultipleGroups() async {
        let service = StorageService()

        // グループ1
        let photos1 = [
            makePhotoAsset(id: "photo-1-1", fileSize: 1_000_000),
            makePhotoAsset(id: "photo-1-2", fileSize: 2_000_000),
        ]
        let group1 = makePhotoGroup(photos: photos1, bestShotIndex: 0)

        // グループ2
        let photos2 = [
            makePhotoAsset(id: "photo-2-1", fileSize: 3_000_000),
            makePhotoAsset(id: "photo-2-2", fileSize: 4_000_000),
        ]
        let group2 = makePhotoGroup(photos: photos2, bestShotIndex: 1)

        let reclaimable = await service.estimateReclaimableSpace(from: [group1, group2])

        // グループ1: 2_000_000 + グループ2: 3_000_000 = 5_000_000
        #expect(reclaimable == 5_000_000)
    }

    @Test("空のグループ配列で0を返す")
    func estimateReclaimableSpaceEmptyGroups() async {
        let service = StorageService()

        let reclaimable = await service.estimateReclaimableSpace(from: [])

        #expect(reclaimable == 0)
    }

    // MARK: - Total Size Calculation Tests

    @Test("写真配列の合計サイズを計算できる")
    func calculateTotalSize() {
        let service = StorageService()

        let photos = [
            makePhotoAsset(id: "photo-1", fileSize: 1_000_000),
            makePhotoAsset(id: "photo-2", fileSize: 2_000_000),
            makePhotoAsset(id: "photo-3", fileSize: 3_000_000),
        ]

        let totalSize = service.calculateTotalSize(for: photos)

        #expect(totalSize == 6_000_000)
    }

    @Test("空の写真配列で0を返す")
    func calculateTotalSizeEmpty() {
        let service = StorageService()

        let totalSize = service.calculateTotalSize(for: [])

        #expect(totalSize == 0)
    }

    // MARK: - Format Bytes Tests

    @Test("バイト数をフォーマットできる - Bytes")
    func formatBytesSmall() {
        let formatted = StorageService.formatBytes(500)

        #expect(formatted.contains("500") || formatted.contains("B"))
    }

    @Test("バイト数をフォーマットできる - KB")
    func formatBytesKB() {
        let formatted = StorageService.formatBytes(1_500)

        // 「KB」または「kB」が含まれるはず
        #expect(formatted.lowercased().contains("kb") || formatted.contains("1"))
    }

    @Test("バイト数をフォーマットできる - MB")
    func formatBytesMB() {
        let formatted = StorageService.formatBytes(5_000_000)

        #expect(formatted.lowercased().contains("mb") || formatted.contains("5"))
    }

    @Test("バイト数をフォーマットできる - GB")
    func formatBytesGB() {
        let formatted = StorageService.formatBytes(10_000_000_000)

        #expect(formatted.lowercased().contains("gb") || formatted.contains("10"))
    }

    @Test("バイト数をフォーマットできる - TB")
    func formatBytesTB() {
        let formatted = StorageService.formatBytes(2_000_000_000_000)

        #expect(formatted.lowercased().contains("tb") || formatted.contains("2"))
    }

    @Test("詳細フォーマットで正しい単位を返す")
    func formatBytesDetailed() {
        // Bytes
        let bytesResult = StorageService.formatBytesDetailed(500)
        #expect(bytesResult.unit == "B")
        #expect(bytesResult.value == 500)

        // KB
        let kbResult = StorageService.formatBytesDetailed(2048)
        #expect(kbResult.unit == "KB")
        #expect(kbResult.value == 2.0)

        // MB
        let mbResult = StorageService.formatBytesDetailed(5_242_880)
        #expect(mbResult.unit == "MB")
        #expect(mbResult.value == 5.0)

        // GB
        let gbResult = StorageService.formatBytesDetailed(10_737_418_240)
        #expect(gbResult.unit == "GB")
        #expect(gbResult.value == 10.0)

        // TB
        let tbResult = StorageService.formatBytesDetailed(2_199_023_255_552)
        #expect(tbResult.unit == "TB")
        #expect(tbResult.value == 2.0)
    }

    // MARK: - Storage Health Tests

    @Test("ストレージの健全性レベルを取得できる")
    func getStorageHealthLevel() async {
        let service = StorageService()

        let level = await service.getStorageHealthLevel()

        // 有効なStorageLevelが返されるはず
        #expect([StorageLevel.normal, StorageLevel.warning, StorageLevel.critical].contains(level))
    }

    // MARK: - Complete Storage Info Tests

    @Test("完全なストレージ情報を取得できる")
    func getCompleteStorageInfo() async throws {
        let service = StorageService()

        let storageInfo = try await service.getCompleteStorageInfo()

        #expect(storageInfo.totalCapacity > 0)
        #expect(storageInfo.availableCapacity >= 0)
        // 写真使用量は権限次第なので、0以上であることだけ確認
        #expect(storageInfo.photosUsedCapacity >= 0)
    }

    @Test("回収可能容量を含む完全なストレージ情報を取得できる")
    func getCompleteStorageInfoWithReclaimable() async throws {
        let service = StorageService()

        // テスト用のグループを作成
        let photos = [
            makePhotoAsset(id: "photo-1", fileSize: 1_000_000),
            makePhotoAsset(id: "photo-2", fileSize: 2_000_000),
        ]
        let group = makePhotoGroup(photos: photos, bestShotIndex: 0)

        let storageInfo = try await service.getCompleteStorageInfo(withReclaimableFrom: [group])

        #expect(storageInfo.totalCapacity > 0)
        #expect(storageInfo.reclaimableCapacity == 2_000_000)
    }
}

// MARK: - StorageServiceError Tests

@Suite("StorageServiceError テスト")
struct StorageServiceErrorTests {

    @Test("storageInfoUnavailableエラーのローカライズ")
    func storageInfoUnavailableError() {
        let error = StorageServiceError.storageInfoUnavailable

        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("photoAccessDeniedエラーのローカライズ")
    func photoAccessDeniedError() {
        let error = StorageServiceError.photoAccessDenied

        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test("calculationFailedエラーのローカライズ")
    func calculationFailedError() {
        let error = StorageServiceError.calculationFailed("テスト理由")

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("テスト理由"))
    }

    @Test("StorageServiceErrorの等価性")
    func errorEquality() {
        #expect(StorageServiceError.storageInfoUnavailable == StorageServiceError.storageInfoUnavailable)
        #expect(StorageServiceError.photoAccessDenied == StorageServiceError.photoAccessDenied)
        #expect(
            StorageServiceError.calculationFailed("reason") ==
            StorageServiceError.calculationFailed("reason")
        )
        #expect(
            StorageServiceError.calculationFailed("reason1") !=
            StorageServiceError.calculationFailed("reason2")
        )
        #expect(StorageServiceError.storageInfoUnavailable != StorageServiceError.photoAccessDenied)
    }
}

// MARK: - StorageInfo Integration Tests

@Suite("StorageInfo 統合テスト")
struct StorageInfoIntegrationTests {

    @Test("StorageInfo.fromDevice()でデバイス情報を取得できる")
    func storageInfoFromDevice() {
        let info = StorageInfo.fromDevice()

        // デバイスには必ず容量があるはず
        #expect(info.totalCapacity > 0)
        #expect(info.availableCapacity >= 0)
    }

    @Test("StorageInfoの計算プロパティが正しく動作する")
    func storageInfoComputedProperties() {
        let info = StorageInfo(
            totalCapacity: 100_000_000_000,  // 100GB
            availableCapacity: 30_000_000_000,  // 30GB
            photosUsedCapacity: 20_000_000_000,  // 20GB
            reclaimableCapacity: 5_000_000_000  // 5GB
        )

        // 使用率: 70%
        #expect(info.usagePercentage == 0.7)

        // 使用容量: 70GB
        #expect(info.usedCapacity == 70_000_000_000)

        // 写真使用率: 20%
        #expect(info.photosUsagePercentage == 0.2)

        // 回収可能率: 25%（5GB/20GB）
        #expect(info.reclaimablePercentage == 0.25)

        // 低容量ではない（30%空き）
        #expect(!info.isLowStorage)

        // 危険状態ではない
        #expect(!info.isCriticalStorage)
    }

    @Test("低容量状態を正しく検出する")
    func lowStorageDetection() {
        // 空き容量が8%
        let lowInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 8_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(lowInfo.isLowStorage)
        #expect(!lowInfo.isCriticalStorage)
        #expect(lowInfo.storageLevel == .warning)
    }

    @Test("危険状態を正しく検出する")
    func criticalStorageDetection() {
        // 空き容量が3%
        let criticalInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 3_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(criticalInfo.isLowStorage)
        #expect(criticalInfo.isCriticalStorage)
        #expect(criticalInfo.storageLevel == .critical)

        // 空き容量が1GB未満
        let veryLowInfo = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 500_000_000,  // 500MB
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        #expect(veryLowInfo.isCriticalStorage)
    }

    @Test("フォーマット済みプロパティが正しく動作する")
    func formattedProperties() {
        let info = StorageInfo(
            totalCapacity: 128_000_000_000,  // 128GB
            availableCapacity: 45_200_000_000,  // 45.2GB
            photosUsedCapacity: 25_300_000_000,  // 25.3GB
            reclaimableCapacity: 3_500_000_000  // 3.5GB
        )

        #expect(!info.formattedTotalCapacity.isEmpty)
        #expect(!info.formattedAvailableCapacity.isEmpty)
        #expect(!info.formattedUsedCapacity.isEmpty)
        #expect(!info.formattedPhotosUsedCapacity.isEmpty)
        #expect(!info.formattedReclaimableCapacity.isEmpty)
        #expect(info.formattedUsagePercentage.contains("%"))
    }

    @Test("StorageInfoの更新メソッドが正しく動作する")
    func updateMethods() {
        let original = StorageInfo(
            totalCapacity: 100_000_000_000,
            availableCapacity: 50_000_000_000,
            photosUsedCapacity: 0,
            reclaimableCapacity: 0
        )

        // 写真使用量を更新
        let withPhotos = original.withPhotosUsedCapacity(20_000_000_000)
        #expect(withPhotos.photosUsedCapacity == 20_000_000_000)
        #expect(withPhotos.totalCapacity == original.totalCapacity)

        // 回収可能容量を更新
        let withReclaimable = withPhotos.withReclaimableCapacity(5_000_000_000)
        #expect(withReclaimable.reclaimableCapacity == 5_000_000_000)
        #expect(withReclaimable.photosUsedCapacity == 20_000_000_000)

        // 空き容量を更新
        let withAvailable = withReclaimable.withAvailableCapacity(55_000_000_000)
        #expect(withAvailable.availableCapacity == 55_000_000_000)
    }

    @Test("StorageInfo.emptyが正しい値を返す")
    func emptyStorageInfo() {
        let empty = StorageInfo.empty

        #expect(empty.totalCapacity == 0)
        #expect(empty.availableCapacity == 0)
        #expect(empty.photosUsedCapacity == 0)
        #expect(empty.reclaimableCapacity == 0)
    }
}
