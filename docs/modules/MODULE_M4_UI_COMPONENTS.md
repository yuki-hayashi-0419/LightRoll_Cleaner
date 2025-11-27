# MODULE M4: UI Components

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M4 |
| モジュール名 | UI Components |
| 責務 | 再利用可能なUIコンポーネント、デザインシステム |
| 依存先 | M1 (Core) |
| 依存元 | M5, M6, M7, M8, M9 |

---

## 2. デザインシステム

### 2.1 カラーパレット
```swift
// Design/Colors.swift
extension Color {
    // Primary
    static let lrPrimary = Color("Primary")           // シアン #00D4FF
    static let lrSecondary = Color("Secondary")       // ブルー #0066FF

    // Background
    static let lrBackground = Color("Background")     // ダークブルー #0D1B2A
    static let lrSurface = Color("Surface")           // #1B2838
    static let lrSurfaceElevated = Color("SurfaceElevated") // #243B53

    // Text
    static let lrTextPrimary = Color.white
    static let lrTextSecondary = Color.white.opacity(0.7)
    static let lrTextTertiary = Color.white.opacity(0.5)

    // Semantic
    static let lrSuccess = Color.green
    static let lrWarning = Color.orange
    static let lrError = Color.red
}
```

### 2.2 タイポグラフィ
```swift
// Design/Typography.swift
extension Font {
    static let lrLargeTitle = Font.system(size: 34, weight: .bold)
    static let lrTitle1 = Font.system(size: 28, weight: .bold)
    static let lrTitle2 = Font.system(size: 22, weight: .semibold)
    static let lrTitle3 = Font.system(size: 20, weight: .semibold)
    static let lrHeadline = Font.system(size: 17, weight: .semibold)
    static let lrBody = Font.system(size: 17, weight: .regular)
    static let lrCallout = Font.system(size: 16, weight: .regular)
    static let lrCaption = Font.system(size: 12, weight: .regular)
}
```

### 2.3 グラスモーフィズム
```swift
// Design/GlassMorphism.swift
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}
```

---

## 3. 主要コンポーネント

### 3.1 PhotoThumbnail
```swift
// Components/PhotoThumbnail.swift
struct PhotoThumbnail: View {
    let photo: Photo
    let isSelected: Bool
    let showBadge: Bool

    var body: some View { ... }
}
```

### 3.2 PhotoGrid
```swift
// Components/PhotoGrid.swift
struct PhotoGrid: View {
    let photos: [Photo]
    let columns: Int
    let onPhotoTap: (Photo) -> Void
    @Binding var selectedPhotos: Set<String>
}
```

### 3.3 StorageIndicator
```swift
// Components/StorageIndicator.swift
struct StorageIndicator: View {
    let storageInfo: StorageInfo
    let showDetails: Bool
}
```

### 3.4 GroupCard
```swift
// Components/GroupCard.swift
struct GroupCard: View {
    let group: PhotoGroup
    let onTap: () -> Void
}
```

### 3.5 ActionButton
```swift
// Components/ActionButton.swift
struct ActionButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void
}
```

### 3.6 ProgressOverlay
```swift
// Components/ProgressOverlay.swift
struct ProgressOverlay: View {
    let title: String
    let progress: Double
    let onCancel: (() -> Void)?
}
```

### 3.7 ConfirmationDialog
```swift
// Components/ConfirmationDialog.swift
struct DeleteConfirmationDialog: View {
    let photoCount: Int
    let reclaimableSize: Int64
    let onConfirm: () -> Void
    let onCancel: () -> Void
}
```

### 3.8 EmptyStateView
```swift
// Components/EmptyStateView.swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
}
```

---

## 4. ディレクトリ構造

```
src/modules/UIComponents/
├── Design/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── GlassMorphism.swift
│   └── Spacing.swift
├── Components/
│   ├── PhotoThumbnail.swift
│   ├── PhotoGrid.swift
│   ├── StorageIndicator.swift
│   ├── GroupCard.swift
│   ├── ActionButton.swift
│   ├── ProgressOverlay.swift
│   ├── ConfirmationDialog.swift
│   ├── EmptyStateView.swift
│   └── ToastView.swift
├── Modifiers/
│   ├── GlassBackground.swift
│   └── PressAnimation.swift
└── Preview/
    └── PreviewProvider+Extensions.swift
```

---

## 5. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M4-T01 | カラーパレット定義 | Assets.xcassets + Color拡張 | 1h | M1-T01 |
| M4-T02 | タイポグラフィ定義 | Font拡張 | 0.5h | M4-T01 |
| M4-T03 | グラスモーフィズム実装 | ViewModifier作成 | 1.5h | M4-T01 |
| M4-T04 | Spacing定義 | 余白の共通定義 | 0.5h | M4-T01 |
| M4-T05 | PhotoThumbnail実装 | サムネイル表示コンポーネント | 2h | M4-T03 |
| M4-T06 | PhotoGrid実装 | グリッド表示コンポーネント | 2h | M4-T05 |
| M4-T07 | StorageIndicator実装 | 容量表示コンポーネント | 1.5h | M4-T03 |
| M4-T08 | GroupCard実装 | グループカードコンポーネント | 1.5h | M4-T05 |
| M4-T09 | ActionButton実装 | アクションボタン | 1h | M4-T03 |
| M4-T10 | ProgressOverlay実装 | 進捗オーバーレイ | 1.5h | M4-T03 |
| M4-T11 | ConfirmationDialog実装 | 確認ダイアログ | 1h | M4-T09 |
| M4-T12 | EmptyStateView実装 | 空状態表示 | 1h | M4-T03 |
| M4-T13 | ToastView実装 | トースト通知 | 1h | M4-T03 |
| M4-T14 | プレビュー環境整備 | SwiftUI Previewsの設定 | 1h | M4-T13 |

---

## 6. テストケース

### M4-T05: PhotoThumbnail実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M4-T05-TC01 | 選択状態の表示 | チェックマーク表示 |
| M4-T05-TC02 | バッジ表示 | ベストショットバッジ |
| M4-T05-TC03 | 動画サムネイル | 再生アイコン表示 |

### M4-T07: StorageIndicator実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M4-T07-TC01 | 容量50%使用時の表示 | グラフが半分 |
| M4-T07-TC02 | 容量90%以上の警告 | 赤色表示 |
| M4-T07-TC03 | アニメーション | スムーズな更新 |

### M4-T10: ProgressOverlay実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M4-T10-TC01 | 進捗0%表示 | 空のプログレスバー |
| M4-T10-TC02 | 進捗100%表示 | 満タンのプログレスバー |
| M4-T10-TC03 | キャンセルボタン | コールバック発火 |

---

## 7. 受け入れ条件

- [ ] 全コンポーネントがダークモードで正しく表示
- [ ] グラスモーフィズム効果が適用されている
- [ ] アクセシビリティ対応（VoiceOver）
- [ ] SwiftUI Previewsで全コンポーネント確認可能
- [ ] iPhone SE〜iPhone 15 Pro Maxで正しくレイアウト

---

## 8. 技術的考慮事項

### 8.1 パフォーマンス
- LazyVGrid/LazyHGridの活用
- 画像のリサイズ・キャッシュ
- 不要な再描画の防止

### 8.2 アクセシビリティ
```swift
// アクセシビリティ対応例
PhotoThumbnail(photo: photo)
    .accessibilityLabel("写真、\(photo.creationDate.formatted())")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
```

### 8.3 アニメーション
- 標準的なiOSアニメーション（.spring()）
- 過度なアニメーションは避ける
- Reduce Motionへの対応

---

*最終更新: 2025-11-27*
