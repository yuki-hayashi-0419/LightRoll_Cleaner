//
//  PhotoPage.swift
//  LightRoll_CleanerFeature
//
//  ページネーションされた写真取得結果を表すモデル
//  大量の写真を効率的に取得するためのページング機能を提供
//  Created by AI Assistant
//

import Foundation

// MARK: - PhotoPage

/// ページネーションされた写真取得結果
/// 大量の写真を効率的に取得するためのページング構造体
public struct PhotoPage: Sendable, Equatable {

    // MARK: - Properties

    /// 現在のページに含まれる写真の配列
    public let photos: [Photo]

    /// ライブラリ内の写真総数
    public let totalCount: Int

    /// 次のページが存在するかどうか
    public let hasMore: Bool

    /// 次のページのオフセット（次のページがない場合はnil）
    public let nextOffset: Int?

    /// 現在のオフセット
    public let currentOffset: Int

    /// ページサイズ（リクエストされた取得件数）
    public let pageSize: Int

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - photos: 取得した写真の配列
    ///   - totalCount: 総数
    ///   - hasMore: 次のページがあるか
    ///   - nextOffset: 次のオフセット
    ///   - currentOffset: 現在のオフセット
    ///   - pageSize: ページサイズ
    public init(
        photos: [Photo],
        totalCount: Int,
        hasMore: Bool,
        nextOffset: Int?,
        currentOffset: Int,
        pageSize: Int
    ) {
        self.photos = photos
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.nextOffset = nextOffset
        self.currentOffset = currentOffset
        self.pageSize = pageSize
    }

    // MARK: - Computed Properties

    /// 現在のページ番号（1始まり）
    public var currentPage: Int {
        guard pageSize > 0 else { return 1 }
        return (currentOffset / pageSize) + 1
    }

    /// 総ページ数
    public var totalPages: Int {
        guard pageSize > 0, totalCount > 0 else { return 1 }
        return (totalCount + pageSize - 1) / pageSize
    }

    /// 最初のページかどうか
    public var isFirstPage: Bool {
        currentOffset == 0
    }

    /// 最後のページかどうか
    public var isLastPage: Bool {
        !hasMore
    }

    /// 前のページのオフセット（最初のページの場合はnil）
    public var previousOffset: Int? {
        guard !isFirstPage else { return nil }
        let prev = currentOffset - pageSize
        return max(0, prev)
    }

    /// 取得した写真の数
    public var fetchedCount: Int {
        photos.count
    }

    /// 空のページかどうか
    public var isEmpty: Bool {
        photos.isEmpty
    }

    // MARK: - Static Factory Methods

    /// 空のページを作成
    /// - Parameter pageSize: ページサイズ
    /// - Returns: 空のPhotoPage
    public static func empty(pageSize: Int = 50) -> PhotoPage {
        PhotoPage(
            photos: [],
            totalCount: 0,
            hasMore: false,
            nextOffset: nil,
            currentOffset: 0,
            pageSize: pageSize
        )
    }

    /// 全件を1ページに含むPhotoPageを作成
    /// - Parameter photos: 写真の配列
    /// - Returns: 全件を含むPhotoPage
    public static func all(_ photos: [Photo]) -> PhotoPage {
        PhotoPage(
            photos: photos,
            totalCount: photos.count,
            hasMore: false,
            nextOffset: nil,
            currentOffset: 0,
            pageSize: photos.count
        )
    }
}

// MARK: - PhotoPage + CustomStringConvertible

extension PhotoPage: CustomStringConvertible {
    public var description: String {
        """
        PhotoPage(page: \(currentPage)/\(totalPages), \
        count: \(fetchedCount)/\(totalCount), \
        hasMore: \(hasMore))
        """
    }
}

// MARK: - PhotoPageAsset

/// ページネーションされたPhotoAsset取得結果
/// プロトコル準拠用のPhotoAsset版ページング構造体
public struct PhotoPageAsset: Sendable, Equatable {

    // MARK: - Properties

    /// 現在のページに含まれる写真の配列
    public let photos: [PhotoAsset]

    /// ライブラリ内の写真総数
    public let totalCount: Int

    /// 次のページが存在するかどうか
    public let hasMore: Bool

    /// 次のページのオフセット（次のページがない場合はnil）
    public let nextOffset: Int?

    /// 現在のオフセット
    public let currentOffset: Int

    /// ページサイズ（リクエストされた取得件数）
    public let pageSize: Int

    // MARK: - Initialization

    public init(
        photos: [PhotoAsset],
        totalCount: Int,
        hasMore: Bool,
        nextOffset: Int?,
        currentOffset: Int,
        pageSize: Int
    ) {
        self.photos = photos
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.nextOffset = nextOffset
        self.currentOffset = currentOffset
        self.pageSize = pageSize
    }

    // MARK: - Computed Properties

    /// 現在のページ番号（1始まり）
    public var currentPage: Int {
        guard pageSize > 0 else { return 1 }
        return (currentOffset / pageSize) + 1
    }

    /// 総ページ数
    public var totalPages: Int {
        guard pageSize > 0, totalCount > 0 else { return 1 }
        return (totalCount + pageSize - 1) / pageSize
    }

    /// 最初のページかどうか
    public var isFirstPage: Bool {
        currentOffset == 0
    }

    /// 最後のページかどうか
    public var isLastPage: Bool {
        !hasMore
    }

    /// 空のページかどうか
    public var isEmpty: Bool {
        photos.isEmpty
    }

    // MARK: - Static Factory Methods

    /// 空のページを作成
    public static func empty(pageSize: Int = 50) -> PhotoPageAsset {
        PhotoPageAsset(
            photos: [],
            totalCount: 0,
            hasMore: false,
            nextOffset: nil,
            currentOffset: 0,
            pageSize: pageSize
        )
    }

    /// PhotoPageから変換
    /// - Parameter page: PhotoPage
    /// - Returns: PhotoPageAsset
    public static func from(_ page: PhotoPage) -> PhotoPageAsset {
        PhotoPageAsset(
            photos: page.photos.map { photo in
                PhotoAsset(
                    id: photo.id,
                    creationDate: photo.creationDate,
                    fileSize: photo.fileSize
                )
            },
            totalCount: page.totalCount,
            hasMore: page.hasMore,
            nextOffset: page.nextOffset,
            currentOffset: page.currentOffset,
            pageSize: page.pageSize
        )
    }
}

// MARK: - PhotoDateRangeFilter

/// 日付範囲フィルター
/// 写真の日付範囲を指定するためのフィルター構造体
public struct PhotoDateRangeFilter: Sendable, Equatable {

    /// 開始日（この日以降の写真を取得）
    public let startDate: Date

    /// 終了日（この日以前の写真を取得）
    public let endDate: Date

    /// 初期化
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    /// 過去N日間のフィルターを作成
    /// - Parameter days: 日数
    /// - Returns: 過去N日間のフィルター
    public static func lastDays(_ days: Int) -> PhotoDateRangeFilter {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return PhotoDateRangeFilter(startDate: startDate, endDate: endDate)
    }

    /// 過去N週間のフィルターを作成
    /// - Parameter weeks: 週数
    /// - Returns: 過去N週間のフィルター
    public static func lastWeeks(_ weeks: Int) -> PhotoDateRangeFilter {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: endDate) ?? endDate
        return PhotoDateRangeFilter(startDate: startDate, endDate: endDate)
    }

    /// 過去Nヶ月間のフィルターを作成
    /// - Parameter months: 月数
    /// - Returns: 過去Nヶ月間のフィルター
    public static func lastMonths(_ months: Int) -> PhotoDateRangeFilter {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -months, to: endDate) ?? endDate
        return PhotoDateRangeFilter(startDate: startDate, endDate: endDate)
    }

    /// 今日のフィルターを作成
    /// - Returns: 今日のフィルター
    public static func today() -> PhotoDateRangeFilter {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        return PhotoDateRangeFilter(startDate: startOfDay, endDate: endOfDay)
    }

    /// 今週のフィルターを作成
    /// - Returns: 今週のフィルター
    public static func thisWeek() -> PhotoDateRangeFilter {
        let now = Date()
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        return PhotoDateRangeFilter(startDate: startOfWeek, endDate: endOfWeek)
    }

    /// 今月のフィルターを作成
    /// - Returns: 今月のフィルター
    public static func thisMonth() -> PhotoDateRangeFilter {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        return PhotoDateRangeFilter(startDate: startOfMonth, endDate: endOfMonth)
    }
}
