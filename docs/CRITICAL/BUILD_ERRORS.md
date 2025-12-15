# BUILD_ERRORS.md

> **変更不可**: このファイルはCRITICALドキュメントです。ビルドエラーとその解決策を記録します。

## エラーカタログ

### ERR-001: Development Team Not Set
**発生日**: 2025-12-15

**エラーメッセージ**:
```
Signing for "LightRoll_Cleaner" requires a development team. Select a development team in the Signing & Capabilities editor.
```

**原因**:
- XCConfig に DEVELOPMENT_TEAM が設定されていない

**解決策**:
1. プロビジョニングプロファイルから Team ID を取得
```bash
security cms -D -i path/to/embedded.mobileprovision | grep -A 2 "TeamIdentifier"
```

2. `Config/Shared.xcconfig` に追加
```
DEVELOPMENT_TEAM = 7HL25LTS58
CODE_SIGN_STYLE = Automatic
```

**ステータス**: ✅ 解決済み

---

### ERR-002: No Provisioning Profile Found
**発生日**: 2025-12-15

**エラーメッセージ**:
```
No profiles for 'com.lightroll.cleaner' were found: Xcode couldn't find any iOS App Development provisioning profiles
```

**原因**:
- Automatic Signing が有効だが、プロビジョニングプロファイルの自動生成が許可されていない

**解決策**:
ビルドコマンドに `-allowProvisioningUpdates` フラグを追加
```bash
xcodebuild -workspace LightRoll_Cleaner.xcworkspace \
  -scheme LightRoll_Cleaner \
  -allowProvisioningUpdates \
  build
```

**XcodeBuildMCP での対応**:
```javascript
build_device({
  workspacePath: "path/to/workspace",
  scheme: "LightRoll_Cleaner",
  extraArgs: ["-allowProvisioningUpdates"]
})
```

**ステータス**: ✅ 解決済み

---

### ERR-003: Profile Not Trusted on Device
**発生日**: 2025-12-15

**エラーメッセージ**:
```
Unable to launch com.lightroll.cleaner because it has an invalid code signature,
inadequate entitlements or its profile has not been explicitly trusted by the user.
```

**原因**:
- デバイスで開発者プロファイルが信頼されていない（初回インストール時の正常な動作）

**解決策（手動操作が必要）**:
1. iPhone の「設定」アプリを開く
2. 「一般」→「VPNとデバイス管理」を選択
3. 開発者アプリのセクションで、開発者名（メールアドレス）をタップ
4. 「"開発者名"を信頼」をタップ
5. 確認ダイアログで「信頼」を選択

**注意**:
- この操作は各開発者証明書につき1回のみ必要
- 同じ証明書で署名された他のアプリは自動的に信頼される

**ステータス**: ⚠️ 手動対応が必要

---

### ERR-004: Swift 6 Concurrency Warnings
**発生日**: 2025-12-15

**警告メッセージ（代表例）**:
```
conformance of 'DashboardRouterKey' to protocol 'EnvironmentKey' crosses into
main actor-isolated code and can cause data races
```

**原因**:
- Swift 5 モードでビルドしているが、Swift 6 の厳格な concurrency チェックが警告を出している
- `@Observable` マクロで生成されたコードが Sendable 適合性の問題を引き起こしている

**影響**:
- ビルドは成功するが、将来的に Swift 6 モードに移行する際に修正が必要

**対処方針**:
1. 現時点では警告として許容（ビルドは成功）
2. Swift 6 モードへの移行時に以下を実施:
   - 全ての `@Observable` クラスに適切な actor isolation を追加
   - `@MainActor` の使用を適切に配置
   - Sendable 適合性を明示的に宣言

**ステータス**: ⚠️ 警告（機能に影響なし）

---

## ビルド成功の確認項目

### ✅ 必須設定
- [x] DEVELOPMENT_TEAM の設定
- [x] CODE_SIGN_STYLE = Automatic
- [x] Info.plist に GADApplicationIdentifier 設定
- [x] Info.plist に ATTrackingTransparency の説明
- [x] Info.plist に Photo Library の権限説明
- [x] SKAdNetworkItems の設定

### ✅ ビルド成果物
- [x] アプリパス: `/Users/yukihayashi/Library/Developer/Xcode/DerivedData/LightRoll_Cleaner-*/Build/Products/Debug-iphoneos/LightRoll_Cleaner.app`
- [x] Bundle ID: `com.lightroll.cleaner`
- [x] デバイスへのインストール成功

### ⚠️ 手動確認が必要
- [ ] デバイスで開発者プロファイルを信頼
- [ ] アプリ起動確認
- [ ] Google Mobile Ads の初期化確認
- [ ] ATTrackingTransparency ダイアログ表示確認

---

**最終更新**: 2025-12-15
**ビルド結果**: ✅ 成功（デバイス信頼の手動操作待ち）
