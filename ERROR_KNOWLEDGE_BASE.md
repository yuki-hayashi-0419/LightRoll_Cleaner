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

### ERR-DATA-001: ゴミ箱fileSize=0マイグレーション不足（Zero KB表示問題）
- **発生日**: 2025-12-22
- **問題の概要**:
  - ゴミ箱の確認ダイアログで「削除後の容量: Zero KB」と表示される
  - 新規削除時のfileSize取得修正は実施済みだが、既存データには適用されない
  - 結果：既存のゴミ箱データはfileSize=0のまま保存されている

- **症状**:
  - ゴミ箱タブを開く
  - 「空にする」ボタンをタップ
  - 確認ダイアログに「削除後の容量: Zero KB」と表示される

- **根本原因**:
  1. `PHAsset+Extensions.swift` の `toPhotoWithoutFileSize()` はパフォーマンス優先でfileSize=0を返す
  2. `TrashManager.createTrashPhoto()` には修正済み（photo.fileSize == 0の場合にfetchFileSizeを呼び出す）
  3. しかし、**修正前に作成された既存のゴミ箱データ**（JSON永続化済み）はfileSize=0のまま
  4. `TrashDataStore.loadAll()` はJSONを読み込むだけでfileSize更新処理がない
  5. `TrashView` は `allPhotos.totalSize` で全写真のfileSizeを合計 → 0の合計で「Zero KB」

- **問題のコード（修正前）**:
  ```swift
  // TrashManager.swift - fetchAllTrashPhotos()（修正前）
  public func fetchAllTrashPhotos() async -> [TrashPhoto] {
      if let expiration = cacheExpiration,
         Date() < expiration {
          return cachedPhotos
      }

      do {
          let photos = try await dataStore.loadAll()  // ❌ fileSize=0のまま返す
          updateCache(photos)
          return photos
      } catch {
          return []
      }
  }
  ```

- **解決策**:
  ```swift
  // TrashManager.swift - fetchAllTrashPhotos()（修正後）
  public func fetchAllTrashPhotos() async -> [TrashPhoto] {
      if let expiration = cacheExpiration,
         Date() < expiration {
          return cachedPhotos
      }

      do {
          var photos = try await dataStore.loadAll()

          // ✅ fileSize=0の写真があればマイグレーション実行
          let needsMigration = photos.contains { $0.fileSize == 0 }
          if needsMigration {
              photos = await migrateFileSizes(photos)
              // ✅ マイグレーション結果を保存
              try? await dataStore.save(photos)
          }

          updateCache(photos)
          return photos
      } catch {
          return []
      }
  }

  /// fileSize=0の写真についてPHAssetから実際のファイルサイズを取得してマイグレーション
  private func migrateFileSizes(_ photos: [TrashPhoto]) async -> [TrashPhoto] {
      var migratedPhotos: [TrashPhoto] = []
      migratedPhotos.reserveCapacity(photos.count)

      for photo in photos {
          if photo.fileSize == 0 {
              if let newFileSize = await fetchFileSize(for: photo.originalPhotoId),
                 newFileSize > 0 {
                  // ✅ 新しいファイルサイズで写真を再作成
                  let migratedPhoto = TrashPhoto(
                      id: photo.id,
                      originalPhotoId: photo.originalPhotoId,
                      originalAssetIdentifier: photo.originalAssetIdentifier,
                      thumbnailData: photo.thumbnailData,
                      deletedAt: photo.deletedAt,
                      expiresAt: photo.expiresAt,
                      fileSize: newFileSize,  // ✅ 正しいファイルサイズ
                      metadata: photo.metadata,
                      deletionReason: photo.deletionReason
                  )
                  migratedPhotos.append(migratedPhoto)
              } else {
                  migratedPhotos.append(photo)
              }
          } else {
              migratedPhotos.append(photo)
          }
      }

      return migratedPhotos
  }
  ```

- **検証結果**:
  - ✅ シミュレータビルド成功

- **関連ファイル**:
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Deletion/Services/TrashManager.swift`
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Deletion/Views/TrashView.swift`
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Deletion/Services/DeletionConfirmationService.swift`

- **教訓**:
  - 既存データに影響する修正では、マイグレーション処理が必要
  - データ取得時に自動マイグレーションを行うパターンが有効
  - マイグレーション後は永続化ストアに保存して次回以降の処理を省略
  - 読み込み時にデータ整合性チェックを入れることで、段階的なデータ修正が可能

- **品質スコア**: 85点（条件付き合格 - 実機テスト待ち）

---

## SwiftUI関連

### ERR-ENV-001: SwiftUI環境オブジェクト未注入によるクラッシュ
- **発生日**: 2025-12-24
- **エラーメッセージ**:
  ```
  Fatal error: No observable object of type NotificationManager found.
  A View.environment(_:) for NotificationManager may be missing as an ancestor of this view.
  ```

- **症状**:
  - 設定画面を開こうとするとアプリがクラッシュ
  - 特定のsheet表示時のみ発生

- **根本原因**:
  SwiftUIの`.sheet(isPresented:)`で表示されるビューは、親ビューの環境オブジェクトを**自動的に継承しない**。
  子ビューが`@Environment(NotificationManager.self)`で環境オブジェクトを参照している場合、
  sheet表示時に明示的に`.environment()`で注入しないとクラッシュする。

- **問題のコード（修正前）**:
  ```swift
  // ContentView.swift（修正前）
  .sheet(isPresented: $isShowingSettings) {
      SettingsView()  // SettingsViewはNotificationManagerを@Environmentで参照
  }
  ```

- **解決策**:
  ```swift
  // ContentView.swift（修正後）
  .sheet(isPresented: $isShowingSettings) {
      SettingsView()
          .environment(notificationManager)  // 明示的に環境オブジェクトを注入
  }
  ```

- **検証結果**:
  - 実機ビルド成功
  - 実機デプロイ成功
  - 設定画面正常表示確認

- **関連ファイル**:
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Views/ContentView.swift`
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Settings/Views/SettingsView.swift`
  - `/LightRoll_CleanerPackage/Sources/LightRoll_CleanerFeature/Settings/Views/NotificationSettingsView.swift`

- **教訓**:
  - `.sheet()`、`.fullScreenCover()`、`.popover()`などのモーダル表示では環境オブジェクトは自動継承されない
  - 子ビューが必要とするすべての環境オブジェクトを明示的に`.environment()`で渡す必要がある
  - 新しいビューを追加する際は、そのビューが参照する環境オブジェクトを確認し、親ビューで注入されているか確認すること
  - テスト時は、sheet表示のケースも必ず実機で確認すること

- **品質スコア**: 95点（合格）

---

---

## その他

（エラー発生時に追記）

---

## 更新履歴

| 日付 | 更新内容 | 担当者 |
|------|----------|--------|
| 2025-11-27 | 初期テンプレート作成 | - |
| 2025-12-22 | ERR-DATA-001: ゴミ箱fileSize=0マイグレーション不足問題を追加 | @spec-orchestrator |
| 2025-12-24 | ERR-ENV-001: SwiftUI環境オブジェクト未注入によるクラッシュを追加 | @spec-orchestrator |
