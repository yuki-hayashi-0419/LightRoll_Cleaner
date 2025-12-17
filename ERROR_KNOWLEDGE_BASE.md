# エラー知識ベース

このドキュメントは、プロジェクト開発中に発生したエラーとその解決策を記録するものです。

## 目次

1. [ビルドエラー](#ビルドエラー)
2. [ランタイムエラー](#ランタイムエラー)
3. [Photos Framework関連](#photos-framework関連)
4. [SwiftUI関連](#swiftui関連)
5. [その他](#その他)

---

## ビルドエラー

### テンプレート

```
### エラー名: [エラータイトル]
- **発生日**: YYYY-MM-DD
- **エラーメッセージ**:
  ```
  エラーメッセージをここに記載
  ```
- **原因**: 原因の説明
- **解決策**: 解決方法の説明
- **関連ファイル**: ファイルパス
- **参考リンク**: URL
```

---

## ランタイムエラー

### ERR-CACHE-001: Phase 2-Phase 3キャッシュ検証ロジック不整合
- **発生日**: 2025-12-17
- **問題の概要**:
  - Phase 2（分析）とPhase 3（グループ化）でキャッシュ検証条件が不一致
  - Phase 2では `loadResult(for:) != nil` のみチェック（featurePrintHash検証なし）
  - Phase 3では `featurePrintHash != nil` が必須のため、Phase 2で有効と判断されたキャッシュがPhase 3で再抽出される
  - 結果：7000枚中216枚が再度Vision API呼び出し（約11秒の遅延）

- **影響範囲**:
  - グループ化処理の開始時間が遅延（7000枚で約11秒）
  - 不必要なVision API呼び出しによるCPU負荷

- **根本原因**:
  ```swift
  // AnalysisRepository.swift（修正前）
  if let cached = await cacheManager.loadResult(for: photo.localIdentifier) {
      cachedResults.append((index, cached)) // ❌ featurePrintHashがnilでも有効扱い
  }
  ```

- **解決策**:
  ```swift
  // AnalysisRepository.swift（修正後）360-372行目
  if let cached = await cacheManager.loadResult(for: photo.localIdentifier),
     cached.featurePrintHash != nil {
      cachedResults.append((index, cached)) // ✅ Phase 3互換性確保
  } else {
      photosToAnalyze.append((index, photo)) // 再分析対象
  }
  ```

- **検証結果**:
  - ✅ シミュレータビルド成功
  - ✅ 実機ビルド成功
  - ✅ 実機デプロイ・起動成功
  - ✅ テストケース追加（エッジケース含む）

- **関連ファイル**:
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/ImageAnalysis/Repositories/AnalysisRepository.swift`
  - `/LightRoll_CleanerPackage/Tests/LightRoll_CleanerFeatureTests/ImageAnalysis/Repositories/AnalysisRepositoryCacheValidationTests.swift`
  - `/LightRoll_CleanerPackage/Tests/LightRoll_CleanerFeatureTests/ImageAnalysis/Repositories/AnalysisRepositoryCacheValidationEdgeCaseTests.swift`

- **教訓**:
  - 複数フェーズ間でキャッシュを共有する場合、全フェーズの必須条件を満たすバリデーションが必要
  - キャッシュヒット判定時は、後続フェーズでの利用可能性も検証すべき
  - Phase間の依存関係を明確に文書化すべき

- **品質スコア**: 88点（条件付き合格）

---

## Photos Framework関連

（エラー発生時に追記）

---

## SwiftUI関連

（エラー発生時に追記）

---

## その他

（エラー発生時に追記）

---

## 更新履歴

| 日付 | 更新内容 | 担当者 |
|------|----------|--------|
| 2025-11-27 | 初期テンプレート作成 | - |
