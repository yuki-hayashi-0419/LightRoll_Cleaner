import Testing
import Foundation

/// プライバシーポリシードキュメントの検証テストスイート
///
/// このテストスイートは、privacy-policy/配下のプライバシーポリシーファイルの品質を検証します。
/// M10-T03「プライバシーポリシー作成」タスクのため、ドキュメントの完全性、正確性、
/// モバイルフレンドリー性を保証する検証テストを提供します。
@Suite("プライバシーポリシー検証")
struct PrivacyPolicyValidationTests {

    // MARK: - テストデータ

    let projectRoot = "/Users/yukihayashi/Documents/dev/projects/LightRoll_Cleaner"
    let privacyPolicyDir = "privacy-policy"

    /// プライバシーポリシーディレクトリのフルパスを取得
    private func getPrivacyPolicyDirPath() -> String {
        return "\(projectRoot)/\(privacyPolicyDir)"
    }

    /// 日本語版プライバシーポリシーのパスを取得
    private func getJapanesePrivacyPolicyPath() -> String {
        return "\(getPrivacyPolicyDirPath())/index.html"
    }

    /// 英語版プライバシーポリシーのパスを取得
    private func getEnglishPrivacyPolicyPath() -> String {
        return "\(getPrivacyPolicyDirPath())/en/index.html"
    }

    /// README.mdのパスを取得
    private func getReadmePath() -> String {
        return "\(getPrivacyPolicyDirPath())/README.md"
    }

    /// HTMLファイルの内容を読み込む
    private func loadHTMLContent(from path: String) throws -> String {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ValidationError.fileNotFound(path: path)
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    // MARK: - Test 1: ファイル存在確認

    @Test("日本語版プライバシーポリシー（index.html）が存在する")
    func japanesePrivacyPolicyExists() throws {
        let filePath = getJapanesePrivacyPolicyPath()
        #expect(
            FileManager.default.fileExists(atPath: filePath),
            "日本語版プライバシーポリシーが存在しません: \(filePath)"
        )
    }

    @Test("英語版プライバシーポリシー（en/index.html）が存在する")
    func englishPrivacyPolicyExists() throws {
        let filePath = getEnglishPrivacyPolicyPath()
        #expect(
            FileManager.default.fileExists(atPath: filePath),
            "英語版プライバシーポリシーが存在しません: \(filePath)"
        )
    }

    @Test("README.mdが存在する")
    func readmeExists() throws {
        let filePath = getReadmePath()
        #expect(
            FileManager.default.fileExists(atPath: filePath),
            "README.mdが存在しません: \(filePath)"
        )
    }

    // MARK: - Test 2: 必須セクション存在確認（日本語版）

    @Test("日本語版に必須セクションがすべて存在する")
    func japaneseRequiredSectionsExist() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        let requiredSections = [
            // プライバシーポリシーの基本構成
            "プライバシーポリシー",
            "最終更新日",

            // 必須セクション
            "収集するデータ",
            "データの使用目的",
            "データの保存と処理",
            "第三者への提供",
            "ユーザーの権利",
            "連絡先情報",

            // アプリ固有の情報
            "LightRoll Cleaner",
            "写真整理アプリ"
        ]

        for section in requiredSections {
            #expect(
                content.contains(section),
                "日本語版に必須セクションが見つかりません: \(section)"
            )
        }
    }

    // MARK: - Test 3: 必須セクション存在確認（英語版）

    @Test("英語版に必須セクションがすべて存在する")
    func englishRequiredSectionsExist() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        let requiredSections = [
            // Privacy Policy basic structure
            "Privacy Policy",
            "Last Updated",

            // Required sections
            "Data We Collect",
            "How We Use Data",
            "Data Storage and Processing",
            "Third-Party Services",
            "Your Rights",
            "Contact Information",

            // App-specific information
            "LightRoll Cleaner",
            "photo organization"
        ]

        for section in requiredSections {
            #expect(
                content.contains(section),
                "英語版に必須セクションが見つかりません: \(section)"
            )
        }
    }

    // MARK: - Test 4: 重要キーワード存在確認（日本語版）

    @Test("日本語版に重要キーワードがすべて含まれている")
    func japaneseRequiredKeywordsExist() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        let requiredKeywords = [
            // 広告関連
            "Google AdMob",
            "Google LLC",
            "広告配信",

            // データ収集関連
            "写真ライブラリ",
            "写真データ",
            "端末内のみ",
            "外部に送信されません",
            "サーバーに保存されません",

            // プライバシー保護
            "プライバシー",
            "個人情報",
            "データ保護",

            // ユーザー権利
            "削除",
            "アンインストール",

            // 法的要件
            "iOS",
            "Apple"
        ]

        for keyword in requiredKeywords {
            #expect(
                content.contains(keyword),
                "日本語版に必須キーワードが見つかりません: \(keyword)"
            )
        }
    }

    // MARK: - Test 5: 重要キーワード存在確認（英語版）

    @Test("英語版に重要キーワードがすべて含まれている")
    func englishRequiredKeywordsExist() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        let requiredKeywords = [
            // Advertising
            "Google AdMob",
            "Google LLC",
            "advertising",

            // Data collection
            "photo library",
            "photo data",
            "device only",
            "not transmitted",
            "not stored on servers",

            // Privacy protection
            "privacy",
            "personal information",
            "data protection",

            // User rights
            "delete",
            "uninstall",

            // Legal requirements
            "iOS",
            "Apple"
        ]

        for keyword in requiredKeywords {
            #expect(
                content.contains(keyword),
                "英語版に必須キーワードが見つかりません: \(keyword)"
            )
        }
    }

    // MARK: - Test 6: HTMLファイルの妥当性（日本語版）

    @Test("日本語版HTMLが基本的な妥当性を持つ")
    func japaneseHTMLValidityCheck() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        // UTF-8エンコーディング宣言
        #expect(
            content.contains("charset=UTF-8") || content.contains("charset=\"UTF-8\""),
            "UTF-8エンコーディング宣言が見つかりません"
        )

        // viewport メタタグ（モバイルフレンドリー）
        #expect(
            content.contains("<meta name=\"viewport\"") || content.contains("<meta name='viewport'"),
            "viewportメタタグが見つかりません"
        )

        // DOCTYPE宣言
        #expect(
            content.contains("<!DOCTYPE html>") || content.contains("<!doctype html>"),
            "DOCTYPE宣言が見つかりません"
        )

        // htmlタグ
        #expect(
            content.contains("<html") && content.contains("</html>"),
            "htmlタグが正しく閉じられていません"
        )

        // headタグ
        #expect(
            content.contains("<head>") && content.contains("</head>"),
            "headタグが正しく閉じられていません"
        )

        // bodyタグ
        #expect(
            content.contains("<body>") && content.contains("</body>"),
            "bodyタグが正しく閉じられていません"
        )

        // titleタグ
        #expect(
            content.contains("<title>") && content.contains("</title>"),
            "titleタグが見つかりません"
        )
    }

    // MARK: - Test 7: HTMLファイルの妥当性（英語版）

    @Test("英語版HTMLが基本的な妥当性を持つ")
    func englishHTMLValidityCheck() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        // UTF-8エンコーディング宣言
        #expect(
            content.contains("charset=UTF-8") || content.contains("charset=\"UTF-8\""),
            "UTF-8エンコーディング宣言が見つかりません"
        )

        // viewport メタタグ（モバイルフレンドリー）
        #expect(
            content.contains("<meta name=\"viewport\"") || content.contains("<meta name='viewport'"),
            "viewportメタタグが見つかりません"
        )

        // DOCTYPE宣言
        #expect(
            content.contains("<!DOCTYPE html>") || content.contains("<!doctype html>"),
            "DOCTYPE宣言が見つかりません"
        )

        // htmlタグ（lang="en"推奨）
        #expect(
            content.contains("<html") && content.contains("</html>"),
            "htmlタグが正しく閉じられていません"
        )

        // headタグ
        #expect(
            content.contains("<head>") && content.contains("</head>"),
            "headタグが正しく閉じられていません"
        )

        // bodyタグ
        #expect(
            content.contains("<body>") && content.contains("</body>"),
            "bodyタグが正しく閉じられていません"
        )

        // titleタグ
        #expect(
            content.contains("<title>") && content.contains("</title>"),
            "titleタグが見つかりません"
        )
    }

    // MARK: - Test 8: 最終更新日の記載確認

    @Test("日本語版に最終更新日が記載されている")
    func japaneseLastUpdatedExists() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        #expect(
            content.contains("最終更新日") || content.contains("最終更新"),
            "最終更新日の記載が見つかりません"
        )

        // 日付形式の確認（YYYY年MM月DD日 または YYYY-MM-DD）
        let datePattern = #"\d{4}年\d{1,2}月\d{1,2}日|\d{4}-\d{2}-\d{2}"#
        let dateRegex = try NSRegularExpression(pattern: datePattern)
        let range = NSRange(content.startIndex..., in: content)

        #expect(
            dateRegex.firstMatch(in: content, range: range) != nil,
            "有効な日付形式が見つかりません"
        )
    }

    @Test("英語版に最終更新日が記載されている")
    func englishLastUpdatedExists() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        #expect(
            content.contains("Last Updated") || content.contains("Last updated"),
            "最終更新日の記載が見つかりません"
        )

        // 日付形式の確認（様々な英語日付形式に対応）
        let datePattern = #"\d{4}-\d{2}-\d{2}|\w+ \d{1,2}, \d{4}|\d{1,2} \w+ \d{4}"#
        let dateRegex = try NSRegularExpression(pattern: datePattern)
        let range = NSRange(content.startIndex..., in: content)

        #expect(
            dateRegex.firstMatch(in: content, range: range) != nil,
            "有効な日付形式が見つかりません"
        )
    }

    // MARK: - Test 9: モバイルフレンドリー検証（日本語版）

    @Test("日本語版がモバイルフレンドリーである（フォントサイズ、レスポンシブ）")
    func japaneseMobileFriendly() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        // フォントサイズが14px以上であることを確認
        // CSSまたはインラインスタイルでfont-sizeを検索
        let fontSizePattern = #"font-size:\s*(\d+)px"#
        let fontSizeRegex = try NSRegularExpression(pattern: fontSizePattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = fontSizeRegex.matches(in: content, range: range)

        if !matches.isEmpty {
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let sizeRange = match.range(at: 1)
                    if let swiftRange = Range(sizeRange, in: content) {
                        let sizeString = String(content[swiftRange])
                        if let size = Int(sizeString) {
                            #expect(
                                size >= 14,
                                "フォントサイズが小さすぎます: \(size)px（最小14px推奨）"
                            )
                        }
                    }
                }
            }
        }

        // レスポンシブデザインの確認（viewport設定）
        #expect(
            content.contains("width=device-width") || content.contains("initial-scale=1"),
            "レスポンシブデザインのviewport設定が見つかりません"
        )

        // モバイル最適化のための推奨設定
        let mobileOptimizations = [
            "max-width",  // レスポンシブ幅制限
            "padding",    // 適切な余白
            "line-height" // 読みやすい行間
        ]

        var foundOptimizations = 0
        for optimization in mobileOptimizations {
            if content.contains(optimization) {
                foundOptimizations += 1
            }
        }

        #expect(
            foundOptimizations >= 2,
            "モバイル最適化が不足しています（\(foundOptimizations)/\(mobileOptimizations.count)項目）"
        )
    }

    // MARK: - Test 10: モバイルフレンドリー検証（英語版）

    @Test("英語版がモバイルフレンドリーである（フォントサイズ、レスポンシブ）")
    func englishMobileFriendly() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        // フォントサイズが14px以上であることを確認
        let fontSizePattern = #"font-size:\s*(\d+)px"#
        let fontSizeRegex = try NSRegularExpression(pattern: fontSizePattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = fontSizeRegex.matches(in: content, range: range)

        if !matches.isEmpty {
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let sizeRange = match.range(at: 1)
                    if let swiftRange = Range(sizeRange, in: content) {
                        let sizeString = String(content[swiftRange])
                        if let size = Int(sizeString) {
                            #expect(
                                size >= 14,
                                "フォントサイズが小さすぎます: \(size)px（最小14px推奨）"
                            )
                        }
                    }
                }
            }
        }

        // レスポンシブデザインの確認
        #expect(
            content.contains("width=device-width") || content.contains("initial-scale=1"),
            "レスポンシブデザインのviewport設定が見つかりません"
        )

        // モバイル最適化のための推奨設定
        let mobileOptimizations = [
            "max-width",
            "padding",
            "line-height"
        ]

        var foundOptimizations = 0
        for optimization in mobileOptimizations {
            if content.contains(optimization) {
                foundOptimizations += 1
            }
        }

        #expect(
            foundOptimizations >= 2,
            "モバイル最適化が不足しています（\(foundOptimizations)/\(mobileOptimizations.count)項目）"
        )
    }

    // MARK: - Test 11: App Store審査対応の重要事項確認（日本語版）

    @Test("日本語版にApp Store審査対応の重要事項が記載されている")
    func japaneseAppStoreComplianceKeywords() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        let complianceKeywords = [
            // App Store Required Disclosures
            "収集",
            "使用",
            "保存",
            "共有",

            // Privacy Details
            "個人を特定する情報",
            "デバイス",

            // User Control
            "削除",
            "権利",
            "選択",

            // Legal Compliance
            "法律",
            "規制"
        ]

        var foundCount = 0
        for keyword in complianceKeywords {
            if content.contains(keyword) {
                foundCount += 1
            }
        }

        #expect(
            foundCount >= complianceKeywords.count * 7 / 10, // 70%以上
            "App Store審査対応のキーワードが不足しています（\(foundCount)/\(complianceKeywords.count)項目）"
        )
    }

    // MARK: - Test 12: README.md内容確認

    @Test("README.mdに必要な情報が記載されている")
    func readmeContentComplete() throws {
        let content = try loadHTMLContent(from: getReadmePath())

        let requiredSections = [
            // 基本情報
            "プライバシーポリシー",
            "LightRoll Cleaner",

            // ファイル構成
            "index.html",
            "en/index.html",

            // 用途説明
            "App Store",
            "審査",

            // アクセス方法
            "URL" // プライバシーポリシーのURL情報
        ]

        var foundCount = 0
        for section in requiredSections {
            if content.contains(section) {
                foundCount += 1
            }
        }

        #expect(
            foundCount >= requiredSections.count * 6 / 10, // 60%以上
            "README.mdに必要な情報が不足しています（\(foundCount)/\(requiredSections.count)項目）"
        )
    }

    // MARK: - Test 13: Google AdMobポリシーリンク確認

    @Test("Google AdMobのプライバシーポリシーへのリンクが存在する")
    func adMobPrivacyPolicyLinkExists() throws {
        let japaneseContent = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())
        let englishContent = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        // Google AdMobプライバシーポリシーのURL
        let adMobPolicyURL = "https://policies.google.com/privacy"

        #expect(
            japaneseContent.contains(adMobPolicyURL),
            "日本語版にGoogle AdMobのプライバシーポリシーリンクが見つかりません"
        )

        #expect(
            englishContent.contains(adMobPolicyURL),
            "英語版にGoogle AdMobのプライバシーポリシーリンクが見つかりません"
        )
    }

    // MARK: - Test 14: データ処理の明確性確認（日本語版）

    @Test("日本語版でデータ処理方法が明確に記載されている")
    func japaneseDataProcessingClarity() throws {
        let content = try loadHTMLContent(from: getJapanesePrivacyPolicyPath())

        let dataProcessingKeywords = [
            // 処理場所の明確化
            "端末内",
            "ローカル",
            "デバイス",

            // 外部送信しないことの明示
            "送信されません",
            "送信しません",
            "アップロードしません",

            // サーバー保存しないことの明示
            "サーバーに保存されません",
            "クラウドに保存されません",

            // データの削除
            "削除されます",
            "アンインストール"
        ]

        var foundCount = 0
        for keyword in dataProcessingKeywords {
            if content.contains(keyword) {
                foundCount += 1
            }
        }

        #expect(
            foundCount >= dataProcessingKeywords.count * 6 / 10, // 60%以上
            "データ処理方法の明確性が不足しています（\(foundCount)/\(dataProcessingKeywords.count)項目）"
        )
    }

    // MARK: - Test 15: データ処理の明確性確認（英語版）

    @Test("英語版でデータ処理方法が明確に記載されている")
    func englishDataProcessingClarity() throws {
        let content = try loadHTMLContent(from: getEnglishPrivacyPolicyPath())

        let dataProcessingKeywords = [
            // Processing location
            "device",
            "local",
            "on your device",

            // No external transmission
            "not transmitted",
            "not sent",
            "not uploaded",

            // No server storage
            "not stored on servers",
            "not stored in the cloud",

            // Data deletion
            "deleted",
            "uninstall"
        ]

        var foundCount = 0
        for keyword in dataProcessingKeywords {
            if content.contains(keyword) {
                foundCount += 1
            }
        }

        #expect(
            foundCount >= dataProcessingKeywords.count * 6 / 10, // 60%以上
            "データ処理方法の明確性が不足しています（\(foundCount)/\(dataProcessingKeywords.count)項目）"
        )
    }

    // MARK: - エラー型定義

    enum ValidationError: Error, CustomStringConvertible {
        case fileNotFound(path: String)
        case invalidFormat(reason: String)
        case missingSection(section: String)
        case invalidEncoding

        var description: String {
            switch self {
            case .fileNotFound(let path):
                return "ファイルが見つかりません: \(path)"
            case .invalidFormat(let reason):
                return "フォーマットエラー: \(reason)"
            case .missingSection(let section):
                return "必須セクションが見つかりません: \(section)"
            case .invalidEncoding:
                return "エンコーディングエラー: UTF-8でファイルを読み込めません"
            }
        }
    }
}
