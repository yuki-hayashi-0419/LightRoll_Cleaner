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

### ERR-PHOTOS-001: CheckedContinuation二重resume（致命的クラッシュ）
- **発生日**: 2025-12-19
- **エラーメッセージ**:
  ```
  _Concurrency/CheckedContinuation.swift:172: Fatal error: SWIFT TASK CONTINUATION MISUSE:
  loadThumbnail() tried to resume its continuation more than once, returning ()!
  ```

- **症状**:
  - アプリ起動時に画面上部に読み込み数字が表示される
  - アプリが重い
  - 「グループを確認」ボタン押下後、一瞬表示されるがすぐにクラッシュ

- **根本原因**:
  `PHImageManager.requestImage` は `deliveryMode = .opportunistic` の場合、以下の理由で**複数回コールバックを呼び出す**：
  1. 低解像度の画像を先に返し、その後高解像度の画像を返す
  2. iCloud写真の場合、ローカルキャッシュ→ダウンロード完了後と複数回呼ばれる

  `withCheckedContinuation` と組み合わせると、2回目のコールバック時に `continuation.resume()` が再度呼ばれ、致命的エラーでクラッシュする。

- **問題のコード（修正前）**:
  ```swift
  // PhotoThumbnail.swift（修正前）
  await withCheckedContinuation { continuation in
      let options = PHImageRequestOptions()
      options.deliveryMode = .opportunistic  // ❌ 複数回コールバックを呼ぶ

      PHImageManager.default().requestImage(...) { image, info in
          Task { @MainActor in
              // 画像処理...
              continuation.resume()  // ❌ 2回目の呼び出しでクラッシュ
          }
      }
  }
  ```

- **解決策**:
  **方法1: deliveryModeを変更（推奨）**
  ```swift
  // PhotoThumbnail.swift（修正後）
  let options = PHImageRequestOptions()
  options.deliveryMode = .highQualityFormat  // ✅ コールバックは1回のみ

  // Continuationを使用せず、コールバックベースで直接状態更新
  PHImageManager.default().requestImage(...) { [weak self] image, info in
      Task { @MainActor [weak self] in
          guard let self = self else { return }
          if let image = image {
              self.thumbnailImage = image
          }
          self.isLoading = false
      }
  }
  ```

  **方法2: isResumedフラグで二重呼び出しを防止**
  ```swift
  // PhotoRepository.swift の実装例
  try await withCheckedThrowingContinuation { continuation in
      var isResumed = false  // ✅ フラグで管理

      imageManager.requestImage(...) { image, info in
          guard !isResumed else { return }  // ✅ 既にresumeされていたら無視

          if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded {
              return  // 低解像度画像はスキップ
          }

          isResumed = true
          continuation.resume(returning: image!)
      }
  }
  ```

- **検証結果**:
  - ✅ シミュレータビルド成功
  - ✅ クラッシュ問題解消

- **関連ファイル**:
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Views/Components/PhotoThumbnail.swift`
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/PhotoAccess/Repositories/PhotoRepository.swift`

- **教訓**:
  - Photos FrameworkのAPIはコールバックが複数回呼ばれる可能性がある
  - `withCheckedContinuation` を使用する場合は、APIの呼び出し回数を事前に確認
  - `deliveryMode = .opportunistic` は高速だが、Continuationと組み合わせると危険
  - 複数回呼ばれる可能性がある場合は `isResumed` フラグで保護するか、`deliveryMode` を変更

- **品質スコア**: 90点（合格）

---

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
