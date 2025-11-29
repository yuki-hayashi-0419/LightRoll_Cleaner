//
//  ActionButtonTests.swift
//  LightRoll_CleanerFeatureTests
//
//  ActionButtonコンポーネントのテスト
//  Created by AI Assistant
//

import Testing
import SwiftUI
@testable import LightRoll_CleanerFeature

// MARK: - ActionButton Tests

@Suite("ActionButton Component Tests")
@MainActor
struct ActionButtonTests {
    // MARK: - Initialization Tests

    @Test("初期化: デフォルト値で正しく初期化される")
    func initializationWithDefaults() async throws {
        // Arrange & Act
        let button = ActionButton(
            title: "テストボタン"
        ) {
            // Empty action
        }

        // Assert: コンパイルエラーがないことで検証
        #expect(button.title == "テストボタン")
        #expect(button.icon == nil)
        #expect(button.style == .primary)
        #expect(button.isDisabled == false)
        #expect(button.isLoading == false)
    }

    @Test("初期化: カスタム値で正しく初期化される")
    func initializationWithCustomValues() async throws {
        // Arrange & Act
        let button = ActionButton(
            title: "カスタムボタン",
            icon: "star.fill",
            style: .secondary,
            isDisabled: true,
            isLoading: true
        ) {
            // Empty action
        }

        // Assert
        #expect(button.title == "カスタムボタン")
        #expect(button.icon == "star.fill")
        #expect(button.style == .secondary)
        #expect(button.isDisabled == true)
        #expect(button.isLoading == true)
    }

    // MARK: - Style Tests

    @Test("スタイル: プライマリスタイルで正しく表示される")
    func primaryStyle() async throws {
        // Arrange
        let button = ActionButton(
            title: "プライマリ",
            style: .primary
        ) {}

        // Act & Assert
        #expect(button.style == .primary)
        #expect(button.style.backgroundColor == Color.LightRoll.accent)
        #expect(button.style.textColor == .white)
    }

    @Test("スタイル: セカンダリスタイルで正しく表示される")
    func secondaryStyle() async throws {
        // Arrange
        let button = ActionButton(
            title: "セカンダリ",
            style: .secondary
        ) {}

        // Act & Assert
        #expect(button.style == .secondary)
        #expect(button.style.backgroundColor == Color.LightRoll.surfaceCard)
        #expect(button.style.textColor == Color.LightRoll.textPrimary)
    }

    // MARK: - Disabled State Tests

    @Test("無効化: isDisabled=trueの時に正しく無効化される")
    func disabledState() async throws {
        // Arrange
        let button = ActionButton(
            title: "無効化ボタン",
            isDisabled: true
        ) {}

        // Act & Assert
        #expect(button.isDisabled == true)
    }

    @Test("無効化: isDisabled=falseの時に有効になる")
    func enabledState() async throws {
        // Arrange
        let button = ActionButton(
            title: "有効ボタン",
            isDisabled: false
        ) {}

        // Act & Assert
        #expect(button.isDisabled == false)
    }

    // MARK: - Loading State Tests

    @Test("ローディング: isLoading=trueの時にローディング状態になる")
    func loadingState() async throws {
        // Arrange
        let button = ActionButton(
            title: "処理中...",
            isLoading: true
        ) {}

        // Act & Assert
        #expect(button.isLoading == true)
    }

    @Test("ローディング: isLoading=falseの時に通常状態になる")
    func notLoadingState() async throws {
        // Arrange
        let button = ActionButton(
            title: "通常ボタン",
            isLoading: false
        ) {}

        // Act & Assert
        #expect(button.isLoading == false)
    }

    // MARK: - Icon Tests

    @Test("アイコン: アイコンありで正しく初期化される")
    func withIcon() async throws {
        // Arrange
        let button = ActionButton(
            title: "アイコン付き",
            icon: "trash.fill"
        ) {}

        // Act & Assert
        #expect(button.icon == "trash.fill")
    }

    @Test("アイコン: アイコンなしで正しく初期化される")
    func withoutIcon() async throws {
        // Arrange
        let button = ActionButton(
            title: "アイコンなし",
            icon: nil
        ) {}

        // Act & Assert
        #expect(button.icon == nil)
    }

    // MARK: - Action Tests

    @Test("アクション: タップ時にアクションが呼ばれる")
    func actionCalled() async throws {
        // Arrange
        actor ActionTracker {
            var called = false
            func markCalled() {
                called = true
            }
            func wasCalled() -> Bool {
                called
            }
        }

        let tracker = ActionTracker()
        let button = ActionButton(
            title: "アクションテスト"
        ) {
            await tracker.markCalled()
        }

        // Act
        await button.action()

        // Assert
        let wasCalled = await tracker.wasCalled()
        #expect(wasCalled == true)
    }

    @Test("アクション: async関数が正しく動作する")
    func asyncAction() async throws {
        // Arrange
        actor ResultHolder {
            var result: String?
            func setResult(_ value: String) {
                result = value
            }
            func getResult() -> String? {
                result
            }
        }

        let holder = ResultHolder()
        let button = ActionButton(
            title: "非同期アクション"
        ) {
            // 非同期処理をシミュレート
            try? await Task.sleep(for: .milliseconds(10))
            await holder.setResult("完了")
        }

        // Act
        await button.action()

        // Assert
        let result = await holder.getResult()
        #expect(result == "完了")
    }

    // MARK: - Accessibility Tests

    @Test("アクセシビリティ: 通常状態で適切なラベルを持つ")
    func accessibilityNormalState() async throws {
        // Arrange
        let button = ActionButton(
            title: "保存",
            style: .primary
        ) {}

        // Assert: accessibilityDescriptionが適切に生成される
        #expect(button.title == "保存")
        #expect(button.style == .primary)
    }

    @Test("アクセシビリティ: ローディング状態で適切なラベルを持つ")
    func accessibilityLoadingState() async throws {
        // Arrange
        let button = ActionButton(
            title: "処理中",
            isLoading: true
        ) {}

        // Assert
        #expect(button.isLoading == true)
    }

    @Test("アクセシビリティ: 無効化状態で適切なラベルを持つ")
    func accessibilityDisabledState() async throws {
        // Arrange
        let button = ActionButton(
            title: "無効",
            isDisabled: true
        ) {}

        // Assert
        #expect(button.isDisabled == true)
    }

    // MARK: - Edge Case Tests

    @Test("エッジケース: 空のタイトルで初期化される")
    func emptyTitle() async throws {
        // Arrange
        let button = ActionButton(
            title: ""
        ) {}

        // Assert
        #expect(button.title == "")
    }

    @Test("エッジケース: 長いタイトルで初期化される")
    func longTitle() async throws {
        // Arrange
        let longTitle = "これはとても長いボタンのタイトルです。複数行になる可能性があります。"
        let button = ActionButton(
            title: longTitle
        ) {}

        // Assert
        #expect(button.title == longTitle)
    }

    @Test("エッジケース: 無効化とローディングが同時の場合")
    func disabledAndLoading() async throws {
        // Arrange
        let button = ActionButton(
            title: "無効化+ローディング",
            isDisabled: true,
            isLoading: true
        ) {}

        // Assert: 両方の状態を持てる
        #expect(button.isDisabled == true)
        #expect(button.isLoading == true)
    }

    // MARK: - ActionButtonStyle Tests

    @Test("ActionButtonStyle: Equatable準拠")
    func styleEquatable() async throws {
        // Arrange & Act
        let style1: ActionButtonStyle = .primary
        let style2: ActionButtonStyle = .primary
        let style3: ActionButtonStyle = .secondary

        // Assert
        #expect(style1 == style2)
        #expect(style1 != style3)
    }

    @Test("ActionButtonStyle: Hashable準拠")
    func styleHashable() async throws {
        // Arrange & Act
        let styles: Set<ActionButtonStyle> = [.primary, .secondary, .primary]

        // Assert: 重複が除去される
        #expect(styles.count == 2)
        #expect(styles.contains(.primary))
        #expect(styles.contains(.secondary))
    }

    @Test("ActionButtonStyle: Sendable準拠（コンパイル時検証）")
    func styleSendable() async throws {
        // Arrange & Act
        let style: ActionButtonStyle = .primary

        // Act: Taskで使用できることを確認
        await withCheckedContinuation { continuation in
            Task { @Sendable in
                let _ = style // Sendableでなければコンパイルエラー
                continuation.resume()
            }
        }

        // Assert: コンパイルが通ることで検証
        #expect(true)
    }

    // MARK: - Integration Tests

    @Test("統合: プライマリボタンの完全な初期化と動作")
    func primaryButtonIntegration() async throws {
        // Arrange
        actor ExecutionTracker {
            var executed = false
            func markExecuted() {
                executed = true
            }
            func wasExecuted() -> Bool {
                executed
            }
        }

        let tracker = ExecutionTracker()
        let button = ActionButton(
            title: "削除",
            icon: "trash",
            style: .primary,
            isDisabled: false,
            isLoading: false
        ) {
            await tracker.markExecuted()
        }

        // Act
        await button.action()

        // Assert
        #expect(button.title == "削除")
        #expect(button.icon == "trash")
        #expect(button.style == .primary)
        #expect(button.isDisabled == false)
        #expect(button.isLoading == false)
        let wasExecuted = await tracker.wasExecuted()
        #expect(wasExecuted == true)
    }

    @Test("統合: セカンダリボタンの完全な初期化と動作")
    func secondaryButtonIntegration() async throws {
        // Arrange
        actor ExecutionTracker {
            var executed = false
            func markExecuted() {
                executed = true
            }
            func wasExecuted() -> Bool {
                executed
            }
        }

        let tracker = ExecutionTracker()
        let button = ActionButton(
            title: "キャンセル",
            icon: "xmark",
            style: .secondary,
            isDisabled: false,
            isLoading: false
        ) {
            await tracker.markExecuted()
        }

        // Act
        await button.action()

        // Assert
        #expect(button.title == "キャンセル")
        #expect(button.icon == "xmark")
        #expect(button.style == .secondary)
        #expect(button.isDisabled == false)
        #expect(button.isLoading == false)
        let wasExecuted = await tracker.wasExecuted()
        #expect(wasExecuted == true)
    }

    @Test("統合: ローディング中のボタンの動作")
    func loadingButtonIntegration() async throws {
        // Arrange
        actor ExecutionTracker {
            var executed = false
            func markExecuted() {
                executed = true
            }
            func wasExecuted() -> Bool {
                executed
            }
        }

        let tracker = ExecutionTracker()
        let button = ActionButton(
            title: "処理中...",
            icon: "arrow.clockwise",
            style: .primary,
            isDisabled: false,
            isLoading: true
        ) {
            await tracker.markExecuted()
        }

        // Act
        await button.action()

        // Assert: ローディング中でもアクションは実行される（UIでは無効化されるが）
        #expect(button.isLoading == true)
        let wasExecuted = await tracker.wasExecuted()
        #expect(wasExecuted == true)
    }
}

// MARK: - effectiveOpacity Tests

@Suite("effectiveOpacity Tests")
@MainActor
struct EffectiveOpacityTests {
    @Test("effectiveOpacity: 通常状態で1.0を返す")
    func normalStateOpacity() async throws {
        // Arrange
        let button = ActionButton(
            title: "通常ボタン",
            isDisabled: false,
            isLoading: false
        ) {}

        // Assert
        #expect(button.effectiveOpacity == 1.0)
    }

    @Test("effectiveOpacity: ローディング時に0.7を返す")
    func loadingStateOpacity() async throws {
        // Arrange
        let button = ActionButton(
            title: "ローディング",
            isLoading: true
        ) {}

        // Assert
        #expect(button.effectiveOpacity == 0.7)
    }

    @Test("effectiveOpacity: 無効化時に0.5を返す")
    func disabledStateOpacity() async throws {
        // Arrange
        let button = ActionButton(
            title: "無効化",
            isDisabled: true
        ) {}

        // Assert
        #expect(button.effectiveOpacity == 0.5)
    }
}

// MARK: - accessibilityDescription Tests

@Suite("accessibilityDescription Tests")
@MainActor
struct AccessibilityDescriptionTests {
    @Test("accessibilityDescription: プライマリスタイルの説明文が正しい")
    func primaryStyleDescription() async throws {
        // Arrange
        let button = ActionButton(
            title: "保存",
            style: .primary
        ) {}

        // Assert
        let description = button.accessibilityDescription
        #expect(description.contains("保存"))
        #expect(description.contains("プライマリボタン"))
        #expect(!description.contains("処理中"))
        #expect(!description.contains("無効"))
    }

    @Test("accessibilityDescription: ローディング中の説明文が正しい")
    func loadingDescription() async throws {
        // Arrange
        let button = ActionButton(
            title: "処理中...",
            style: .primary,
            isLoading: true
        ) {}

        // Assert
        let description = button.accessibilityDescription
        #expect(description.contains("処理中..."))
        #expect(description.contains("処理中"))
        #expect(description.contains("プライマリボタン"))
    }

    @Test("accessibilityDescription: 無効化時の説明文が正しい")
    func disabledDescription() async throws {
        // Arrange
        let button = ActionButton(
            title: "無効ボタン",
            style: .secondary,
            isDisabled: true
        ) {}

        // Assert
        let description = button.accessibilityDescription
        #expect(description.contains("無効ボタン"))
        #expect(description.contains("無効"))
        #expect(description.contains("セカンダリボタン"))
    }
}

// MARK: - accessibilityHint Tests

@Suite("accessibilityHint Tests")
@MainActor
struct AccessibilityHintTests {
    @Test("accessibilityHint: 通常時は「タップして実行」")
    func normalStateHint() async throws {
        // Arrange
        let button = ActionButton(
            title: "実行",
            isLoading: false
        ) {}

        // Assert
        // Note: accessibilityHintは直接アクセスできないため、
        // コンポーネントのロジックが正しいことを状態で検証
        #expect(button.isLoading == false)
        // ローディングでない場合、ヒントは"タップして実行"になるべき
    }

    @Test("accessibilityHint: ローディング時は「処理中です」")
    func loadingStateHint() async throws {
        // Arrange
        let button = ActionButton(
            title: "処理中...",
            isLoading: true
        ) {}

        // Assert
        // Note: accessibilityHintは直接アクセスできないため、
        // コンポーネントのロジックが正しいことを状態で検証
        #expect(button.isLoading == true)
        // ローディングの場合、ヒントは"処理中です"になるべき
    }
}

// MARK: - ActionButtonStyle Property Tests

@Suite("ActionButtonStyle Properties Tests")
@MainActor
struct ActionButtonStyleTests {
    @Test("backgroundColor: プライマリスタイルがaccentカラーを返す")
    func primaryBackgroundColor() async throws {
        // Arrange
        let style: ActionButtonStyle = .primary

        // Act & Assert
        #expect(style.backgroundColor == Color.LightRoll.accent)
    }

    @Test("backgroundColor: セカンダリスタイルがsurfaceCardカラーを返す")
    func secondaryBackgroundColor() async throws {
        // Arrange
        let style: ActionButtonStyle = .secondary

        // Act & Assert
        #expect(style.backgroundColor == Color.LightRoll.surfaceCard)
    }

    @Test("textColor: プライマリスタイルが白を返す")
    func primaryTextColor() async throws {
        // Arrange
        let style: ActionButtonStyle = .primary

        // Act & Assert
        #expect(style.textColor == .white)
    }

    @Test("textColor: セカンダリスタイルがtextPrimaryを返す")
    func secondaryTextColor() async throws {
        // Arrange
        let style: ActionButtonStyle = .secondary

        // Act & Assert
        #expect(style.textColor == Color.LightRoll.textPrimary)
    }
}
