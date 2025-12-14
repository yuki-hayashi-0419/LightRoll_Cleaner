import Testing
import Foundation

/// App Store Connect提出ドキュメントの検証テストスイート
///
/// このテストスイートは、APP_STORE_SUBMISSION_CHECKLIST.mdの品質を検証します。
/// コード実装ではなくドキュメント作成タスクのため、ドキュメントの完全性と
/// 正確性を保証する検証テストを提供します。
@Suite("App Store提出ドキュメント検証")
struct AppStoreSubmissionValidationTests {

    // MARK: - テストデータ

    let projectRoot = "/Users/yukihayashi/Documents/dev/projects/LightRoll_Cleaner"
    let checklistPath = "docs/CRITICAL/APP_STORE_SUBMISSION_CHECKLIST.md"

    /// チェックリストファイルのフルパスを取得
    private func getChecklistFilePath() -> String {
        return "\(projectRoot)/\(checklistPath)"
    }

    /// チェックリストファイルの内容を読み込む
    private func loadChecklistContent() throws -> String {
        let filePath = getChecklistFilePath()
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ValidationError.fileNotFound(path: filePath)
        }
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Test 1: ドキュメント存在確認

    @Test("APP_STORE_SUBMISSION_CHECKLIST.mdが存在する")
    func documentExists() throws {
        let filePath = getChecklistFilePath()
        #expect(
            FileManager.default.fileExists(atPath: filePath),
            "APP_STORE_SUBMISSION_CHECKLIST.mdが存在しません: \(filePath)"
        )
    }

    // MARK: - Test 2: 必須セクション存在確認

    @Test("必須セクションがすべて存在する")
    func requiredSectionsExist() throws {
        let content = try loadChecklistContent()

        let requiredSections = [
            "## 概要",
            "## 📋 提出前必須チェック項目",
            "### ✅ アプリビルド準備",
            "### ✅ App Store Connect設定",
            "### ✅ スクリーンショット要件",
            "### ✅ アプリ説明文（日本語）",
            "### ✅ プライバシーポリシー",
            "### ✅ 審査ガイドライン対応",
            "### ✅ テストフライト配信",
            "### ✅ 最終確認",
            "## 📊 提出手順",
            "## 🚨 よくあるリジェクト理由と対策",
            "## 📞 サポート体制",
            "## ✅ チェックリスト進捗"
        ]

        for section in requiredSections {
            #expect(
                content.contains(section),
                "必須セクションが見つかりません: \(section)"
            )
        }
    }

    // MARK: - Test 3: チェックボックス数確認

    @Test("チェックボックスが十分な数存在する（最低50個）")
    func sufficientCheckboxes() throws {
        let content = try loadChecklistContent()

        // チェックボックスパターン: "- [ ]"
        let checkboxPattern = #"- \[ \]"#
        let checkboxRegex = try NSRegularExpression(pattern: checkboxPattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = checkboxRegex.matches(in: content, range: range)

        let checkboxCount = matches.count

        #expect(
            checkboxCount >= 50,
            "チェックボックスが不足しています。期待: 50個以上, 実際: \(checkboxCount)個"
        )
    }

    // MARK: - Test 4: 重要キーワード存在確認

    @Test("App Store提出に必要なキーワードが含まれている")
    func requiredKeywordsExist() throws {
        let content = try loadChecklistContent()

        let requiredKeywords = [
            // ビルド関連
            "Archive",
            "Distribution",
            "Provisioning Profile",
            "Code Signing",

            // App Store Connect関連
            "App Store Connect",
            "バンドルID",
            "スクリーンショット",
            "In-App Purchase",

            // 審査関連
            "審査",
            "Guideline",
            "リジェクト",

            // プライバシー
            "プライバシーポリシー",
            "写真アクセス",

            // バージョン情報
            "1.0.0",
            "iOS 18.0"
        ]

        for keyword in requiredKeywords {
            #expect(
                content.contains(keyword),
                "必須キーワードが見つかりません: \(keyword)"
            )
        }
    }

    // MARK: - Test 5: Markdown構文正確性確認

    @Test("Markdown構文が正しい（見出し階層、リスト形式）")
    func markdownSyntaxValid() throws {
        let content = try loadChecklistContent()
        let lines = content.components(separatedBy: .newlines)

        var issues: [String] = []

        // 見出し階層チェック（# → ## → ### のみ、#### 以降は使用しない）
        let invalidHeadingPattern = #"^####+ "#
        let invalidHeadingRegex = try NSRegularExpression(pattern: invalidHeadingPattern)

        for (index, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..., in: line)
            if invalidHeadingRegex.firstMatch(in: line, range: range) != nil {
                issues.append("行\(index + 1): 4階層以上の見出し（####）は使用しないでください")
            }
        }

        // チェックボックス形式チェック（"- [ ]" のみ、インデント対応）
        let validCheckboxPattern = #"^( )*- \[ \] "#
        let checkboxLikePattern = #"^\[[ x]\]"#

        let validCheckboxRegex = try NSRegularExpression(pattern: validCheckboxPattern)
        let checkboxLikeRegex = try NSRegularExpression(pattern: checkboxLikePattern)

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("[ ]") || trimmedLine.hasPrefix("[x]") {
                let range = NSRange(line.startIndex..., in: line)
                if validCheckboxRegex.firstMatch(in: line, range: range) == nil {
                    issues.append("行\(index + 1): チェックボックスは '- [ ] ' 形式で記述してください")
                }
            }
        }

        #expect(
            issues.isEmpty,
            "Markdown構文エラー:\n\(issues.joined(separator: "\n"))"
        )
    }

    // MARK: - Test 6: 日本語と英語の説明文が両方存在

    @Test("日本語と英語のApp説明文が両方存在する")
    func bilingualDescriptionsExist() throws {
        let content = try loadChecklistContent()

        // 日本語セクション
        #expect(
            content.contains("### ✅ アプリ説明文（日本語）"),
            "日本語のアプリ説明文セクションが見つかりません"
        )

        #expect(
            content.contains("LightRoll Cleaner"),
            "アプリ名が見つかりません"
        )

        #expect(
            content.contains("写真整理でストレージ解放"),
            "日本語サブタイトルが見つかりません"
        )

        // 英語セクション
        #expect(
            content.contains("### ✅ アプリ説明文（英語 - グローバル展開時）"),
            "英語のアプリ説明文セクションが見つかりません"
        )

        #expect(
            content.contains("Clean photos, free storage"),
            "英語サブタイトルが見つかりません"
        )
    }

    // MARK: - Test 7: スクリーンショット要件の詳細確認

    @Test("スクリーンショット要件に必要なデバイスサイズが網羅されている")
    func screenshotRequirementsComplete() throws {
        let content = try loadChecklistContent()

        let requiredScreenshotSizes = [
            "6.9インチ", // iPhone 16 Pro Max
            "6.7インチ", // iPhone 16 Plus
            "6.5インチ", // iPhone XS Max
            "5.5インチ"  // iPhone 8 Plus
        ]

        for size in requiredScreenshotSizes {
            #expect(
                content.contains(size),
                "スクリーンショット要件に\(size)ディスプレイの記載がありません"
            )
        }

        // 解像度の記載確認
        let requiredResolutions = [
            "1320 x 2868",  // 6.9インチ
            "1290 x 2796",  // 6.7インチ
            "1242 x 2688",  // 6.5インチ
            "1242 x 2208"   // 5.5インチ
        ]

        for resolution in requiredResolutions {
            #expect(
                content.contains(resolution),
                "スクリーンショット解像度\(resolution)の記載がありません"
            )
        }
    }

    // MARK: - Test 8: In-App Purchase設定の完全性

    @Test("In-App Purchase（課金）の設定が詳細に記載されている")
    func inAppPurchaseDetailsComplete() throws {
        let content = try loadChecklistContent()

        // 3つの課金プラン
        let requiredPlans = [
            "Premium Monthly",
            "Premium Yearly",
            "Lifetime"
        ]

        for plan in requiredPlans {
            #expect(
                content.contains(plan),
                "課金プラン\(plan)の記載がありません"
            )
        }

        // Product IDの記載
        let requiredProductIDs = [
            "com.example.LightRoll-Cleaner.premium.monthly",
            "com.example.LightRoll-Cleaner.premium.yearly",
            "com.example.LightRoll-Cleaner.premium.lifetime"
        ]

        for productID in requiredProductIDs {
            #expect(
                content.contains(productID),
                "Product ID \(productID)の記載がありません"
            )
        }

        // 価格の記載
        #expect(content.contains("¥480"), "月額価格の記載がありません")
        #expect(content.contains("¥3,800"), "年額価格の記載がありません")
        #expect(content.contains("¥9,800"), "買い切り価格の記載がありません")
    }

    // MARK: - Test 9: プライバシーガイドライン対応確認

    @Test("プライバシーガイドライン（Guideline 5.1）への対応が記載されている")
    func privacyGuidelineCompliance() throws {
        let content = try loadChecklistContent()

        #expect(
            content.contains("Guideline 5.1.1"),
            "Guideline 5.1.1（データ収集）の記載がありません"
        )

        #expect(
            content.contains("Guideline 5.1.2"),
            "Guideline 5.1.2（データ使用）の記載がありません"
        )

        // プライバシー関連の重要事項
        let privacyKeywords = [
            "写真アクセス",
            "端末内処理",
            "外部送信なし",
            "プライバシーポリシー"
        ]

        for keyword in privacyKeywords {
            #expect(
                content.contains(keyword),
                "プライバシー関連キーワード\(keyword)が見つかりません"
            )
        }
    }

    // MARK: - Test 10: 提出手順のステップバイステップ確認

    @Test("提出手順が6ステップで明確に記載されている")
    func submissionStepsComplete() throws {
        let content = try loadChecklistContent()

        let requiredSteps = [
            "Step 1: Archive作成",
            "Step 2: Validation",
            "Step 3: Upload",
            "Step 4: App Store Connectで設定",
            "Step 5: 審査待ち",
            "Step 6: 承認後"
        ]

        for step in requiredSteps {
            #expect(
                content.contains(step),
                "提出手順に\(step)の記載がありません"
            )
        }
    }

    // MARK: - エラー型定義

    enum ValidationError: Error, CustomStringConvertible {
        case fileNotFound(path: String)
        case invalidFormat(reason: String)
        case missingSection(section: String)

        var description: String {
            switch self {
            case .fileNotFound(let path):
                return "ファイルが見つかりません: \(path)"
            case .invalidFormat(let reason):
                return "フォーマットエラー: \(reason)"
            case .missingSection(let section):
                return "必須セクションが見つかりません: \(section)"
            }
        }
    }
}
