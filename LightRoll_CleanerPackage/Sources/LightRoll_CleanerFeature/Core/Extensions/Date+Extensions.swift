//
//  Date+Extensions.swift
//  LightRoll_CleanerFeature
//
//  日付操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - Date Extensions

extension Date {

    // MARK: - Components

    /// 年を取得
    public var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// 月を取得
    public var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// 日を取得
    public var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// 時を取得
    public var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// 分を取得
    public var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// 秒を取得
    public var second: Int {
        Calendar.current.component(.second, from: self)
    }

    /// 曜日を取得（1:日曜日, 2:月曜日, ..., 7:土曜日）
    public var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    // MARK: - Day Start/End

    /// その日の開始時刻（0:00:00）を取得
    public var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// その日の終了時刻（23:59:59）を取得
    public var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// その月の開始日を取得
    public var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// その月の終了日を取得
    public var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// その年の開始日を取得
    public var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    // MARK: - Comparison

    /// 今日かどうかを判定
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 昨日かどうかを判定
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 明日かどうかを判定
    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// 今週かどうかを判定
    public var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 今月かどうかを判定
    public var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// 今年かどうかを判定
    public var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// 過去かどうかを判定
    public var isPast: Bool {
        self < Date()
    }

    /// 未来かどうかを判定
    public var isFuture: Bool {
        self > Date()
    }

    /// 同じ日かどうかを判定
    /// - Parameter date: 比較対象の日付
    /// - Returns: 同じ日の場合true
    public func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    // MARK: - Date Arithmetic

    /// 日数を加算
    /// - Parameter days: 加算する日数
    /// - Returns: 加算後の日付
    public func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 月数を加算
    /// - Parameter months: 加算する月数
    /// - Returns: 加算後の日付
    public func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// 年数を加算
    /// - Parameter years: 加算する年数
    /// - Returns: 加算後の日付
    public func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    /// 時間を加算
    /// - Parameter hours: 加算する時間数
    /// - Returns: 加算後の日付
    public func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// 分を加算
    /// - Parameter minutes: 加算する分数
    /// - Returns: 加算後の日付
    public func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// 秒を加算
    /// - Parameter seconds: 加算する秒数
    /// - Returns: 加算後の日付
    public func adding(seconds: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }

    // MARK: - Distance

    /// 別の日付との日数差を取得
    /// - Parameter date: 比較対象の日付
    /// - Returns: 日数差（負の値も可）
    public func days(from date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }

    /// 別の日付との月数差を取得
    /// - Parameter date: 比較対象の日付
    /// - Returns: 月数差（負の値も可）
    public func months(from date: Date) -> Int {
        Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }

    /// 別の日付との年数差を取得
    /// - Parameter date: 比較対象の日付
    /// - Returns: 年数差（負の値も可）
    public func years(from date: Date) -> Int {
        Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }

    /// 現在からの経過時間を取得
    public var timeAgo: TimeInterval {
        Date().timeIntervalSince(self)
    }

    // MARK: - Formatting

    /// 指定したフォーマットで文字列に変換
    /// - Parameter format: 日付フォーマット文字列
    /// - Returns: フォーマットされた文字列
    public func formatted(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// 日本語の相対時間表記を取得
    /// - Returns: 相対時間文字列（例: "3時間前", "2日前"）
    public var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// 短い日付文字列を取得（例: "11/28"）
    public var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// 長い日付文字列を取得（例: "2025年11月28日"）
    public var longDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// 時刻文字列を取得（例: "14:30"）
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// 日時文字列を取得（例: "2025/11/28 14:30"）
    public var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// ISO8601形式の文字列を取得
    public var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    // MARK: - Factory

    /// ISO8601文字列から日付を生成
    /// - Parameter string: ISO8601形式の文字列
    /// - Returns: 日付、またはパース失敗時nil
    public static func fromISO8601(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    /// 指定した年月日から日付を生成
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    ///   - hour: 時（デフォルト: 0）
    ///   - minute: 分（デフォルト: 0）
    ///   - second: 秒（デフォルト: 0）
    /// - Returns: 生成された日付、または失敗時nil
    public static func from(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)
    }
}
