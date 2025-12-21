//
//  TestTags.swift
//  LightRoll_CleanerFeatureTests
//
//  共通テストタグ定義
//  Created: 2025-12-21
//

import Testing

// MARK: - 共通テストタグ

extension Tag {
    // 基本カテゴリ
    @Tag static var normal: Self
    @Tag static var error: Self
    @Tag static var boundary: Self
    @Tag static var concurrency: Self
    @Tag static var performance: Self
    @Tag static var accessibility: Self

    // 機能カテゴリ
    @Tag static var ui: Self
    @Tag static var state: Self
    @Tag static var async: Self
    @Tag static var task: Self

    // メディアタイプ
    @Tag static var photo: Self
    @Tag static var video: Self
    @Tag static var screenshot: Self
    @Tag static var livePhoto: Self

    // ビジネスロジック
    @Tag static var grouping: Self
    @Tag static var analysis: Self
    @Tag static var similarity: Self
    @Tag static var metadata: Self

    // テストタイプ
    @Tag static var unit: Self
    @Tag static var integration: Self
    @Tag static var e2e: Self
}
