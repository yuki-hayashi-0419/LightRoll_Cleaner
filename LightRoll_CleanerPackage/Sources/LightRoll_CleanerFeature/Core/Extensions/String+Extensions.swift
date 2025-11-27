//
//  String+Extensions.swift
//  LightRoll_CleanerFeature
//
//  文字列操作のための便利な拡張メソッド群
//  Created by AI Assistant
//

import Foundation

// MARK: - String Extensions

extension String {

    // MARK: - Validation

    /// 文字列が空白のみかどうかを判定
    /// - Returns: 空白のみの場合true
    public var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 有効なメールアドレス形式かどうかを判定
    /// - Returns: 有効なメールアドレス形式の場合true
    public var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    /// 数字のみで構成されているかどうかを判定
    /// - Returns: 数字のみの場合true
    public var isNumeric: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    // MARK: - Transformation

    /// 先頭と末尾の空白を削除した文字列を取得
    /// - Returns: トリミングされた文字列
    public var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// nilまたは空文字列の場合にnilを返す
    /// - Returns: 空でない場合は自身、空の場合はnil
    public var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    /// nilまたは空白のみの場合にnilを返す
    /// - Returns: 空白のみでない場合は自身、そうでない場合はnil
    public var nilIfBlank: String? {
        isBlank ? nil : self
    }

    /// キャメルケースをスネークケースに変換
    /// - Returns: スネークケースの文字列
    public var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: utf16.count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased() ?? lowercased()
    }

    /// スネークケースをキャメルケースに変換
    /// - Returns: キャメルケースの文字列
    public var camelCased: String {
        let components = split(separator: "_")
        guard !components.isEmpty else { return self }

        let first = String(components[0]).lowercased()
        let rest = components.dropFirst().map { String($0).capitalized }
        return first + rest.joined()
    }

    /// 最初の文字を大文字にした文字列を取得
    /// - Returns: 最初の文字が大文字の文字列
    public var capitalizedFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }

    // MARK: - Truncation

    /// 指定した長さで文字列を切り詰め、省略記号を追加
    /// - Parameters:
    ///   - length: 最大長
    ///   - suffix: 省略記号（デフォルト: "..."）
    /// - Returns: 切り詰められた文字列
    public func truncated(to length: Int, suffix: String = "...") -> String {
        guard count > length else { return self }
        return String(prefix(length - suffix.count)) + suffix
    }

    // MARK: - Localization

    /// ローカライズされた文字列を取得
    /// - Parameter comment: ローカライズコメント
    /// - Returns: ローカライズされた文字列
    public func localized(comment: String = "") -> String {
        NSLocalizedString(self, comment: comment)
    }

    /// 引数付きでローカライズされた文字列を取得
    /// - Parameters:
    ///   - arguments: フォーマット引数
    ///   - comment: ローカライズコメント
    /// - Returns: フォーマットされたローカライズ文字列
    public func localized(with arguments: CVarArg..., comment: String = "") -> String {
        String(format: NSLocalizedString(self, comment: comment), arguments: arguments)
    }

    // MARK: - File Path

    /// ファイルパスからファイル名のみを取得
    /// - Returns: ファイル名
    public var fileName: String {
        (self as NSString).lastPathComponent
    }

    /// ファイルパスから拡張子を取得
    /// - Returns: 拡張子
    public var fileExtension: String {
        (self as NSString).pathExtension
    }

    /// ファイルパスから拡張子を除いたファイル名を取得
    /// - Returns: 拡張子を除いたファイル名
    public var fileNameWithoutExtension: String {
        ((self as NSString).lastPathComponent as NSString).deletingPathExtension
    }

    // MARK: - Substring

    /// 安全にインデックスで文字を取得
    /// - Parameter index: インデックス
    /// - Returns: 文字、または範囲外の場合nil
    public subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// 安全に範囲で部分文字列を取得
    /// - Parameter range: 範囲
    /// - Returns: 部分文字列、または範囲外の場合nil
    public subscript(safe range: Range<Int>) -> String? {
        let startIndex = max(0, range.lowerBound)
        let endIndex = min(count, range.upperBound)
        guard startIndex < endIndex else { return nil }

        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: endIndex)
        return String(self[start..<end])
    }

    // MARK: - Masking

    /// 文字列の一部をマスク
    /// - Parameters:
    ///   - unmaskedCount: マスクしない先頭の文字数
    ///   - maskCharacter: マスク文字（デフォルト: "*"）
    /// - Returns: マスクされた文字列
    public func masked(keeping unmaskedCount: Int, with maskCharacter: Character = "*") -> String {
        guard count > unmaskedCount else { return self }
        let unmasked = prefix(unmaskedCount)
        let maskedPortion = String(repeating: maskCharacter, count: count - unmaskedCount)
        return String(unmasked) + maskedPortion
    }
}

// MARK: - Optional String Extensions

extension Optional where Wrapped == String {

    /// nilまたは空文字列かどうかを判定
    /// - Returns: nilまたは空の場合true
    public var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let string):
            return string.isEmpty
        }
    }

    /// nilまたは空白のみかどうかを判定
    /// - Returns: nilまたは空白のみの場合true
    public var isNilOrBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let string):
            return string.isBlank
        }
    }

    /// nilの場合に空文字列を返す
    /// - Returns: 自身または空文字列
    public var orEmptyString: String {
        self ?? ""
    }
}
