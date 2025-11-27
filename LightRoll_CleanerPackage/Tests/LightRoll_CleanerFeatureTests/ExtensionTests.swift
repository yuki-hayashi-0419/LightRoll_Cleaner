//
//  ExtensionTests.swift
//  LightRoll_CleanerFeatureTests
//
//  拡張ユーティリティのユニットテスト
//  Created by AI Assistant
//

import Foundation
import Testing
@testable import LightRoll_CleanerFeature

// MARK: - String Extensions Tests

@Suite("String Extensions Tests")
struct StringExtensionsTests {

    // MARK: - Validation Tests

    @Test("isBlankが空白文字列を正しく判定する")
    func testIsBlank() {
        #expect("".isBlank == true)
        #expect("   ".isBlank == true)
        #expect("\n\t".isBlank == true)
        #expect("hello".isBlank == false)
        #expect(" hello ".isBlank == false)
    }

    @Test("isValidEmailがメールアドレスを正しく判定する")
    func testIsValidEmail() {
        #expect("test@example.com".isValidEmail == true)
        #expect("user.name@domain.co.jp".isValidEmail == true)
        #expect("invalid".isValidEmail == false)
        #expect("@example.com".isValidEmail == false)
        #expect("test@".isValidEmail == false)
    }

    @Test("isNumericが数字のみを正しく判定する")
    func testIsNumeric() {
        #expect("12345".isNumeric == true)
        #expect("0".isNumeric == true)
        #expect("".isNumeric == false)
        #expect("123abc".isNumeric == false)
        #expect("12.34".isNumeric == false)
    }

    // MARK: - Transformation Tests

    @Test("trimmedが空白を削除する")
    func testTrimmed() {
        #expect("  hello  ".trimmed == "hello")
        #expect("\n\thello\n\t".trimmed == "hello")
        #expect("hello".trimmed == "hello")
    }

    @Test("nilIfEmptyが空文字列でnilを返す")
    func testNilIfEmpty() {
        #expect("".nilIfEmpty == nil)
        #expect("hello".nilIfEmpty == "hello")
    }

    @Test("nilIfBlankが空白のみでnilを返す")
    func testNilIfBlank() {
        #expect("".nilIfBlank == nil)
        #expect("   ".nilIfBlank == nil)
        #expect("hello".nilIfBlank == "hello")
    }

    @Test("snakeCasedがキャメルケースを変換する")
    func testSnakeCased() {
        #expect("camelCase".snakeCased == "camel_case")
        // 連続大文字はそのまま小文字化される（HTTP→http）
        #expect("HTTPResponse".snakeCased == "httpresponse")
        #expect("simpletext".snakeCased == "simpletext")
        // userID → user_id（小文字と大文字の境界で区切られる）
        #expect("userID".snakeCased == "user_id")
    }

    @Test("camelCasedがスネークケースを変換する")
    func testCamelCased() {
        #expect("snake_case".camelCased == "snakeCase")
        #expect("http_response".camelCased == "httpResponse")
        #expect("simple".camelCased == "simple")
    }

    @Test("capitalizedFirstが最初の文字を大文字にする")
    func testCapitalizedFirst() {
        #expect("hello".capitalizedFirst == "Hello")
        #expect("Hello".capitalizedFirst == "Hello")
        #expect("".capitalizedFirst == "")
    }

    // MARK: - Truncation Tests

    @Test("truncatedが文字列を切り詰める")
    func testTruncated() {
        #expect("Hello, World!".truncated(to: 8) == "Hello...")
        #expect("Short".truncated(to: 10) == "Short")
        // 文字列が指定長以下の場合はそのまま返す
        #expect("Hello".truncated(to: 5, suffix: "..") == "Hello")
        #expect("Hello World".truncated(to: 8, suffix: "..") == "Hello ..")
    }

    // MARK: - File Path Tests

    @Test("fileNameがファイル名を取得する")
    func testFileName() {
        #expect("/path/to/file.txt".fileName == "file.txt")
        #expect("file.txt".fileName == "file.txt")
    }

    @Test("fileExtensionが拡張子を取得する")
    func testFileExtension() {
        #expect("/path/to/file.txt".fileExtension == "txt")
        #expect("file.swift".fileExtension == "swift")
        #expect("noextension".fileExtension == "")
    }

    @Test("fileNameWithoutExtensionが拡張子なしファイル名を取得する")
    func testFileNameWithoutExtension() {
        #expect("/path/to/file.txt".fileNameWithoutExtension == "file")
        #expect("photo.jpeg".fileNameWithoutExtension == "photo")
    }

    // MARK: - Safe Access Tests

    @Test("safeインデックスアクセスが安全に動作する")
    func testSafeIndexAccess() {
        let str = "Hello"
        #expect(str[safe: 0] == "H")
        #expect(str[safe: 4] == "o")
        #expect(str[safe: 5] == nil)
        #expect(str[safe: -1] == nil)
    }

    @Test("safe範囲アクセスが安全に動作する")
    func testSafeRangeAccess() {
        let str = "Hello"
        #expect(str[safe: 0..<3] == "Hel")
        #expect(str[safe: 3..<10] == "lo")
        #expect(str[safe: 10..<15] == nil)
    }

    // MARK: - Masking Tests

    @Test("maskedが文字列をマスクする")
    func testMasked() {
        #expect("1234567890".masked(keeping: 4) == "1234******")
        #expect("Short".masked(keeping: 10) == "Short")
        #expect("Password".masked(keeping: 2, with: "#") == "Pa######")
    }
}

// MARK: - Optional String Extensions Tests

@Suite("Optional String Extensions Tests")
struct OptionalStringExtensionsTests {

    @Test("isNilOrEmptyが正しく判定する")
    func testIsNilOrEmpty() {
        let nilString: String? = nil
        let emptyString: String? = ""
        let validString: String? = "hello"

        #expect(nilString.isNilOrEmpty == true)
        #expect(emptyString.isNilOrEmpty == true)
        #expect(validString.isNilOrEmpty == false)
    }

    @Test("isNilOrBlankが正しく判定する")
    func testIsNilOrBlank() {
        let nilString: String? = nil
        let blankString: String? = "   "
        let validString: String? = "hello"

        #expect(nilString.isNilOrBlank == true)
        #expect(blankString.isNilOrBlank == true)
        #expect(validString.isNilOrBlank == false)
    }

    @Test("orEmptyStringがnilで空文字列を返す")
    func testOrEmptyString() {
        let nilString: String? = nil
        let validString: String? = "hello"

        #expect(nilString.orEmptyString == "")
        #expect(validString.orEmptyString == "hello")
    }
}

// MARK: - Array Extensions Tests

@Suite("Array Extensions Tests")
struct ArrayExtensionsTests {

    // MARK: - Safe Access Tests

    @Test("safeインデックスアクセスが安全に動作する")
    func testSafeIndexAccess() {
        let array = [1, 2, 3, 4, 5]
        #expect(array[safe: 0] == 1)
        #expect(array[safe: 4] == 5)
        #expect(array[safe: 5] == nil)
        #expect(array[safe: -1] == nil)
    }

    @Test("safe範囲アクセスが安全に動作する")
    func testSafeRangeAccess() {
        let array = [1, 2, 3, 4, 5]
        #expect(Array(array[safe: 0..<3]) == [1, 2, 3])
        #expect(Array(array[safe: 3..<10]) == [4, 5])
        #expect(Array(array[safe: 10..<15]) == [])
    }

    // MARK: - Chunking Tests

    @Test("chunkedが配列を分割する")
    func testChunked() {
        let array = [1, 2, 3, 4, 5, 6, 7]
        let chunks = array.chunked(into: 3)
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2, 3])
        #expect(chunks[1] == [4, 5, 6])
        #expect(chunks[2] == [7])
    }

    @Test("chunkedが0以下のサイズで空を返す")
    func testChunkedZeroSize() {
        let array = [1, 2, 3]
        #expect(array.chunked(into: 0).isEmpty)
        #expect(array.chunked(into: -1).isEmpty)
    }

    // MARK: - Uniqueness Tests

    @Test("uniquedが重複を除去する")
    func testUniqued() {
        let array = [1, 2, 2, 3, 1, 4]
        #expect(array.uniqued == [1, 2, 3, 4])
    }

    @Test("uniqued(by:)がキーパスで重複を除去する")
    func testUniquedByKeyPath() {
        struct Item {
            let id: Int
            let name: String
        }
        let items = [
            Item(id: 1, name: "A"),
            Item(id: 2, name: "B"),
            Item(id: 1, name: "C")
        ]
        let uniqued = items.uniqued(by: \.id)
        #expect(uniqued.count == 2)
        #expect(uniqued[0].name == "A")
        #expect(uniqued[1].name == "B")
    }

    // MARK: - Transformation Tests

    @Test("indexedがインデックス付きタプルを返す")
    func testIndexed() {
        let array = ["a", "b", "c"]
        let indexed = array.indexed
        #expect(indexed[0].index == 0)
        #expect(indexed[0].element == "a")
        #expect(indexed[2].index == 2)
        #expect(indexed[2].element == "c")
    }

    @Test("appendingが要素を追加した新配列を返す")
    func testAppending() {
        let array = [1, 2, 3]
        #expect(array.appending(4) == [1, 2, 3, 4])
        #expect(array.appending(nil) == [1, 2, 3])
    }

    @Test("prependingが要素を先頭に追加した新配列を返す")
    func testPrepending() {
        let array = [1, 2, 3]
        #expect(array.prepending(0) == [0, 1, 2, 3])
        #expect(array.prepending(nil) == [1, 2, 3])
    }

    // MARK: - Set Operations Tests

    @Test("differenceが差分を返す")
    func testDifference() {
        let array1 = [1, 2, 3, 4, 5]
        let array2 = [2, 4, 6]
        #expect(array1.difference(from: array2) == [1, 3, 5])
    }

    @Test("intersectionが共通要素を返す")
    func testIntersection() {
        let array1 = [1, 2, 3, 4, 5]
        let array2 = [2, 4, 6]
        #expect(array1.intersection(with: array2) == [2, 4])
    }

    // MARK: - Numeric Tests

    @Test("sumが合計を計算する")
    func testSum() {
        #expect([1, 2, 3, 4, 5].sum == 15)
        let doubleArray: [Double] = [1.5, 2.5, 3.0]
        #expect(doubleArray.sum == 7.0)
    }

    @Test("averageが平均を計算する")
    func testAverage() {
        #expect([1, 2, 3, 4, 5].average == 3.0)
        #expect([1.0, 2.0, 3.0].average == 2.0)
        #expect([Int]().average == 0)
    }

    @Test("minMaxが最小最大を返す")
    func testMinMax() {
        let result = [3, 1, 4, 1, 5, 9, 2, 6].minMax
        #expect(result?.min == 1)
        #expect(result?.max == 9)
        #expect([Int]().minMax == nil)
    }
}

// MARK: - Date Extensions Tests

@Suite("Date Extensions Tests")
struct DateExtensionsTests {

    // MARK: - Components Tests

    @Test("日付コンポーネントが正しく取得できる")
    func testDateComponents() {
        guard let date = Date.from(year: 2025, month: 11, day: 28, hour: 14, minute: 30, second: 45) else {
            Issue.record("日付の生成に失敗")
            return
        }
        #expect(date.year == 2025)
        #expect(date.month == 11)
        #expect(date.day == 28)
        #expect(date.hour == 14)
        #expect(date.minute == 30)
        #expect(date.second == 45)
    }

    // MARK: - Day Start/End Tests

    @Test("startOfDayがその日の開始時刻を返す")
    func testStartOfDay() {
        guard let date = Date.from(year: 2025, month: 11, day: 28, hour: 14, minute: 30) else {
            Issue.record("日付の生成に失敗")
            return
        }
        let start = date.startOfDay
        #expect(start.hour == 0)
        #expect(start.minute == 0)
        #expect(start.second == 0)
    }

    @Test("endOfDayがその日の終了時刻を返す")
    func testEndOfDay() {
        guard let date = Date.from(year: 2025, month: 11, day: 28, hour: 14, minute: 30) else {
            Issue.record("日付の生成に失敗")
            return
        }
        let end = date.endOfDay
        #expect(end.hour == 23)
        #expect(end.minute == 59)
        #expect(end.second == 59)
    }

    // MARK: - Comparison Tests

    @Test("isTodayが今日を正しく判定する")
    func testIsToday() {
        #expect(Date().isToday == true)
        #expect(Date().adding(days: -1).isToday == false)
    }

    @Test("isSameDay(as:)が同じ日を正しく判定する")
    func testIsSameDay() {
        guard let date1 = Date.from(year: 2025, month: 11, day: 28, hour: 10),
              let date2 = Date.from(year: 2025, month: 11, day: 28, hour: 20),
              let date3 = Date.from(year: 2025, month: 11, day: 29) else {
            Issue.record("日付の生成に失敗")
            return
        }
        #expect(date1.isSameDay(as: date2) == true)
        #expect(date1.isSameDay(as: date3) == false)
    }

    @Test("isPastとisFutureが正しく判定する")
    func testPastAndFuture() {
        let past = Date().adding(days: -1)
        let future = Date().adding(days: 1)
        #expect(past.isPast == true)
        #expect(past.isFuture == false)
        #expect(future.isPast == false)
        #expect(future.isFuture == true)
    }

    // MARK: - Arithmetic Tests

    @Test("日付の加算が正しく動作する")
    func testDateArithmetic() {
        guard let date = Date.from(year: 2025, month: 11, day: 28) else {
            Issue.record("日付の生成に失敗")
            return
        }
        #expect(date.adding(days: 3).day == 1)
        #expect(date.adding(days: 3).month == 12)
        #expect(date.adding(months: 2).month == 1)
        #expect(date.adding(months: 2).year == 2026)
    }

    @Test("日数差が正しく計算される")
    func testDaysFrom() {
        guard let date1 = Date.from(year: 2025, month: 11, day: 28),
              let date2 = Date.from(year: 2025, month: 12, day: 5) else {
            Issue.record("日付の生成に失敗")
            return
        }
        #expect(date2.days(from: date1) == 7)
        #expect(date1.days(from: date2) == -7)
    }

    // MARK: - Formatting Tests

    @Test("formatted(with:)が正しくフォーマットする")
    func testFormatted() {
        guard let date = Date.from(year: 2025, month: 11, day: 28) else {
            Issue.record("日付の生成に失敗")
            return
        }
        let formatted = date.formatted(with: "yyyy-MM-dd")
        #expect(formatted == "2025-11-28")
    }

    @Test("iso8601Stringが正しいフォーマットを返す")
    func testISO8601String() {
        let date = Date()
        let iso = date.iso8601String
        #expect(!iso.isEmpty)
        #expect(iso.contains("T"))
    }

    // MARK: - Factory Tests

    @Test("fromISO8601がISO8601文字列をパースする")
    func testFromISO8601() {
        let date = Date.fromISO8601("2025-11-28T14:30:00Z")
        #expect(date != nil)
    }

    @Test("from(year:month:day:)が日付を生成する")
    func testFromComponents() {
        let date = Date.from(year: 2025, month: 11, day: 28)
        #expect(date != nil)
        #expect(date?.year == 2025)
        #expect(date?.month == 11)
        #expect(date?.day == 28)
    }
}

// MARK: - Optional Extensions Tests

@Suite("Optional Extensions Tests")
struct OptionalExtensionsTests {

    @Test("isNilとisNotNilが正しく判定する")
    func testIsNilAndIsNotNil() {
        let nilValue: Int? = nil
        let someValue: Int? = 42

        #expect(nilValue.isNil == true)
        #expect(nilValue.isNotNil == false)
        #expect(someValue.isNil == false)
        #expect(someValue.isNotNil == true)
    }

    @Test("ifPresentが値存在時に実行される")
    func testIfPresent() {
        var executed = false
        let value: Int? = 42
        value.ifPresent { _ in executed = true }
        #expect(executed == true)

        executed = false
        let nilValue: Int? = nil
        nilValue.ifPresent { _ in executed = true }
        #expect(executed == false)
    }

    @Test("ifNilがnil時に実行される")
    func testIfNil() {
        var executed = false
        let nilValue: Int? = nil
        nilValue.ifNil { executed = true }
        #expect(executed == true)

        executed = false
        let value: Int? = 42
        value.ifNil { executed = true }
        #expect(executed == false)
    }

    @Test("orThrowがnilでエラーをスローする")
    func testOrThrow() throws {
        let value: Int? = 42
        let result = try value.orThrow("Value is nil")
        #expect(result == 42)

        let nilValue: Int? = nil
        #expect(throws: NilError.self) {
            _ = try nilValue.orThrow("Value is nil")
        }
    }

    @Test("filterが条件に一致する値のみ返す")
    func testFilter() {
        let value: Int? = 42
        #expect(value.filter { $0 > 40 } == 42)
        #expect(value.filter { $0 > 50 } == nil)

        let nilValue: Int? = nil
        #expect(nilValue.filter { $0 > 0 } == nil)
    }

    @Test("Optional<Bool>の拡張が正しく動作する")
    func testOptionalBool() {
        let trueValue: Bool? = true
        let falseValue: Bool? = false
        let nilValue: Bool? = nil

        #expect(trueValue.isTrue == true)
        #expect(falseValue.isTrue == false)
        #expect(nilValue.isTrue == false)

        #expect(trueValue.orFalse == true)
        #expect(nilValue.orFalse == false)
        #expect(nilValue.orTrue == true)
    }

    @Test("Optional<Numeric>のorZeroが正しく動作する")
    func testOrZero() {
        let value: Int? = 42
        let nilValue: Int? = nil

        #expect(value.orZero == 42)
        #expect(nilValue.orZero == 0)
    }

    @Test("Optional<Collection>のisNilOrEmptyが正しく動作する")
    func testOptionalCollectionIsNilOrEmpty() {
        let nilArray: [Int]? = nil
        let emptyArray: [Int]? = []
        let validArray: [Int]? = [1, 2, 3]

        #expect(nilArray.isNilOrEmpty == true)
        #expect(emptyArray.isNilOrEmpty == true)
        #expect(validArray.isNilOrEmpty == false)
    }
}

// MARK: - Collection Extensions Tests

@Suite("Collection Extensions Tests")
struct CollectionExtensionsTests {

    @Test("isNotEmptyが正しく判定する")
    func testIsNotEmpty() {
        #expect([1, 2, 3].isNotEmpty == true)
        #expect([Int]().isNotEmpty == false)
    }

    @Test("Dictionary.hasKeyが正しく判定する")
    func testDictionaryHasKey() {
        let dict = ["a": 1, "b": 2]
        #expect(dict.hasKey("a") == true)
        #expect(dict.hasKey("c") == false)
    }

    @Test("Dictionary.mergedが正しくマージする")
    func testDictionaryMerged() {
        let dict1 = ["a": 1, "b": 2]
        let dict2 = ["b": 3, "c": 4]

        let merged1 = dict1.merged(with: dict2, preferOther: true)
        #expect(merged1["b"] == 3)

        let merged2 = dict1.merged(with: dict2, preferOther: false)
        #expect(merged2["b"] == 2)
    }

    @Test("Set.toggleが正しく動作する")
    func testSetToggle() {
        var set: Set<Int> = [1, 2, 3]

        let added = set.toggle(4)
        #expect(added == true)
        #expect(set.contains(4))

        let removed = set.toggle(4)
        #expect(removed == false)
        #expect(!set.contains(4))
    }

    @Test("countOccurrencesが出現回数をカウントする")
    func testCountOccurrences() {
        let array = [1, 2, 2, 3, 3, 3]
        let counts = array.countOccurrences()
        #expect(counts[1] == 1)
        #expect(counts[2] == 2)
        #expect(counts[3] == 3)
    }

    @Test("mostFrequentが最頻出要素を返す")
    func testMostFrequent() {
        let array = [1, 2, 2, 3, 3, 3]
        let result = array.mostFrequent
        #expect(result?.element == 3)
        #expect(result?.count == 3)
    }
}

// MARK: - Result Extensions Tests

@Suite("Result Extensions Tests")
struct ResultExtensionsTests {

    enum TestError: Error {
        case failed
        case anotherError
    }

    @Test("isSuccessとisFailureが正しく判定する")
    func testIsSuccessAndIsFailure() {
        let success: Result<Int, TestError> = .success(42)
        let failure: Result<Int, TestError> = .failure(.failed)

        #expect(success.isSuccess == true)
        #expect(success.isFailure == false)
        #expect(failure.isSuccess == false)
        #expect(failure.isFailure == true)
    }

    @Test("successとfailureが値を取得する")
    func testSuccessAndFailureValues() {
        let success: Result<Int, TestError> = .success(42)
        let failure: Result<Int, TestError> = .failure(.failed)

        #expect(success.success == 42)
        #expect(success.failure == nil)
        #expect(failure.success == nil)
        #expect(failure.failure == .failed)
    }

    @Test("valueOrがデフォルト値を返す")
    func testValueOr() {
        let success: Result<Int, TestError> = .success(42)
        let failure: Result<Int, TestError> = .failure(.failed)

        #expect(success.valueOr(0) == 42)
        #expect(failure.valueOr(0) == 0)
    }

    @Test("onSuccessが成功時に実行される")
    func testOnSuccess() {
        var executed = false
        let success: Result<Int, TestError> = .success(42)
        success.onSuccess { _ in executed = true }
        #expect(executed == true)

        executed = false
        let failure: Result<Int, TestError> = .failure(.failed)
        failure.onSuccess { _ in executed = true }
        #expect(executed == false)
    }

    @Test("onFailureが失敗時に実行される")
    func testOnFailure() {
        var executed = false
        let failure: Result<Int, TestError> = .failure(.failed)
        failure.onFailure { _ in executed = true }
        #expect(executed == true)

        executed = false
        let success: Result<Int, TestError> = .success(42)
        success.onFailure { _ in executed = true }
        #expect(executed == false)
    }

    @Test("recoverが失敗から回復する")
    func testRecover() {
        let failure: Result<Int, TestError> = .failure(.failed)
        let recovered = failure.recover { _ in 0 }
        #expect(recovered.success == 0)

        let success: Result<Int, TestError> = .success(42)
        let unchanged = success.recover { _ in 0 }
        #expect(unchanged.success == 42)
    }

    @Test("Result.fromがOptionalから生成する")
    func testFromOptional() {
        let value: Int? = 42
        let result1 = Result<Int, TestError>.from(value, error: .failed)
        #expect(result1.success == 42)

        let nilValue: Int? = nil
        let result2 = Result<Int, TestError>.from(nilValue, error: .failed)
        #expect(result2.failure == .failed)
    }

    @Test("Result.fromが条件から生成する")
    func testFromCondition() {
        let result1 = Result<Int, TestError>.from(condition: true, success: 42, failure: .failed)
        #expect(result1.success == 42)

        let result2 = Result<Int, TestError>.from(condition: false, success: 42, failure: .failed)
        #expect(result2.failure == .failed)
    }
}

// MARK: - FileManager Extensions Tests

@Suite("FileManager Extensions Tests")
struct FileManagerExtensionsTests {

    @Test("ディレクトリURLが取得できる")
    func testDirectoryURLs() {
        let fm = FileManager.default
        #expect(fm.documentsDirectory.path.contains("Documents"))
        #expect(fm.cachesDirectory.path.contains("Caches"))
        #expect(!fm.temporaryDirectory.path.isEmpty)
    }

    @Test("fileExistsとdirectoryExistsが正しく判定する")
    func testFileAndDirectoryExists() {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory

        #expect(fm.directoryExists(at: tempDir) == true)
        #expect(fm.fileExists(at: tempDir.appendingPathComponent("nonexistent.txt")) == false)
    }

    @Test("ディスク容量情報が取得できる")
    func testDiskSpaceInfo() {
        let fm = FileManager.default
        #expect(fm.totalDiskSpace != nil)
        #expect(fm.availableDiskSpace != nil)
        #expect(fm.diskUsageRatio != nil)

        if let ratio = fm.diskUsageRatio {
            #expect(ratio >= 0.0)
            #expect(ratio <= 1.0)
        }
    }

    @Test("uniqueFileURLがユニークなURLを生成する")
    func testUniqueFileURL() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_unique.txt")

        // クリーンアップ
        try? fm.removeItem(at: testFile)
        try? fm.removeItem(at: tempDir.appendingPathComponent("test_unique_1.txt"))

        // ファイルが存在しない場合、同じURLを返す
        #expect(fm.uniqueFileURL(for: testFile) == testFile)

        // ファイルを作成
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // ファイルが存在する場合、連番付きURLを返す
        let uniqueURL = fm.uniqueFileURL(for: testFile)
        #expect(uniqueURL.lastPathComponent == "test_unique_1.txt")

        // クリーンアップ
        try? fm.removeItem(at: testFile)
    }

    @Test("createDirectoryIfNeededが正しく動作する")
    func testCreateDirectoryIfNeeded() throws {
        let fm = FileManager.default
        let testDir = fm.temporaryDirectory.appendingPathComponent("test_create_dir")

        // クリーンアップ
        try? fm.removeItem(at: testDir)

        // 存在しない場合は作成
        try fm.createDirectoryIfNeeded(at: testDir)
        #expect(fm.directoryExists(at: testDir) == true)

        // 既に存在する場合もエラーにならない
        try fm.createDirectoryIfNeeded(at: testDir)

        // クリーンアップ
        try? fm.removeItem(at: testDir)
    }

    @Test("Int64.formattedFileSizeが正しくフォーマットする")
    func testFormattedFileSize() {
        let size1: Int64 = 1024
        let size2: Int64 = 1_000_000_000

        #expect(!size1.formattedFileSize.isEmpty)
        #expect(!size2.formattedFileSize.isEmpty)
    }
}
