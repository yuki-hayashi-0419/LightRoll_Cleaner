# BUILD_CONFIG.md

> **変更不可**: このファイルはCRITICALドキュメントです。変更は禁止されています。

## プロジェクト識別子

| 項目 | 値 |
|------|-----|
| Product Name | LightRoll_Cleaner |
| Display Name | LightRoll Cleaner |
| Bundle Identifier | com.lightroll.cleaner |
| Marketing Version | 1.0 |
| Build Number | 1 |

## プラットフォーム設定

| 項目 | 値 |
|------|-----|
| iOS Deployment Target | 17.0 |
| Targeted Device Family | iPhone, iPad |
| Swift Tools Version | 6.1 |
| Swift Language Mode | 5 |

## ビルド構成

### XCConfig ファイル構成

```
Config/
├── Shared.xcconfig      # 共通設定
├── Debug.xcconfig       # デバッグ設定
├── Release.xcconfig     # リリース設定
└── Tests.xcconfig       # テスト設定
```

### プロジェクト構造

```
LightRoll_Cleaner.xcworkspace/    # ワークスペース（ビルドエントリポイント）
LightRoll_Cleaner.xcodeproj/      # アプリシェル
LightRoll_CleanerPackage/         # SPM Feature Package（主要開発領域）
```

## 環境定義

### Debug環境
- コード署名: 開発用
- 最適化: 無効
- デバッグシンボル: 有効
- Swift最適化レベル: -Onone

### Release環境
- コード署名: 配布用
- 最適化: 有効
- デバッグシンボル: 無効
- Swift最適化レベル: -O

## 権限設定（Entitlements）

設定ファイル: `Config/LightRoll_Cleaner.entitlements`

### 必要な権限
| 権限 | 用途 |
|------|------|
| NSPhotoLibraryUsageDescription | 写真ライブラリ読み取り |
| NSPhotoLibraryAddUsageDescription | 写真ライブラリ書き込み（将来） |

## ビルドコマンド

### シミュレータビルド
```bash
xcodebuild -workspace LightRoll_Cleaner.xcworkspace \
  -scheme LightRoll_Cleaner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  build
```

### テスト実行
```bash
swift test --package-path LightRoll_CleanerPackage
```

### クリーンビルド
```bash
xcodebuild -workspace LightRoll_Cleaner.xcworkspace \
  -scheme LightRoll_Cleaner \
  clean
```

## 依存関係

### 外部依存関係
なし（フレームワークはすべてApple標準）

### Apple フレームワーク
- SwiftUI
- Photos
- Vision
- CoreImage
- Foundation

## CI/CD

GitHub Actions を使用（将来実装予定）
- `.github/workflows/` に設定ファイルを配置予定

---

**最終更新**: 2025-11-29（v3.0マイグレーション時）
