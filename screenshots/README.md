# LightRoll Cleaner - App Store スクリーンショット

このディレクトリには、App Store Connect提出用のスクリーンショットが格納されています。

## 📁 ディレクトリ構成

```
screenshots/
├── 6.9inch/          # iPhone 16 Pro Max / 15 Pro Max
│   ├── 01_home.png
│   ├── 02_group_list.png
│   ├── 03_group_detail.png
│   ├── 04_deletion_confirm.png
│   └── 05_premium.png
├── 6.7inch/          # iPhone 16 Plus / 15 Plus / 14 Pro Max
│   ├── 01_home.png
│   ├── 02_group_list.png
│   ├── 03_group_detail.png
│   ├── 04_deletion_confirm.png
│   └── 05_premium.png
├── 6.5inch/          # iPhone XS Max / 11 Pro Max
│   ├── 01_home.png
│   ├── 02_group_list.png
│   ├── 03_group_detail.png
│   ├── 04_deletion_confirm.png
│   └── 05_premium.png
├── 5.5inch/          # iPhone 8 Plus / 7 Plus
│   ├── 01_home.png
│   ├── 02_group_list.png
│   ├── 03_group_detail.png
│   ├── 04_deletion_confirm.png
│   └── 05_premium.png
└── README.md         # このファイル
```

## 📱 画面サイズ別仕様

### 6.9インチディスプレイ（iPhone 16 Pro Max / 15 Pro Max）
- **解像度**: 1320 x 2868 px
- **アスペクト比**: 縦向き
- **対象機種**: iPhone 16 Pro Max, iPhone 15 Pro Max

### 6.7インチディスプレイ（iPhone 16 Plus / 15 Plus / 14 Pro Max）
- **解像度**: 1290 x 2796 px
- **アスペクト比**: 縦向き
- **対象機種**: iPhone 16 Plus, iPhone 15 Plus, iPhone 14 Pro Max

### 6.5インチディスプレイ（iPhone XS Max / 11 Pro Max）
- **解像度**: 1242 x 2688 px
- **アスペクト比**: 縦向き
- **対象機種**: iPhone XS Max, iPhone 11 Pro Max

### 5.5インチディスプレイ（iPhone 8 Plus / 7 Plus）
- **解像度**: 1242 x 2208 px
- **アスペクト比**: 縦向き
- **対象機種**: iPhone 8 Plus, iPhone 7 Plus

## 📸 スクリーンショット内容

各画面サイズで以下の5枚のスクリーンショットを撮影します：

### 01_home.png - ホーム画面
**概要**: アプリのメイン画面
**内容**:
- ストレージ使用状況（円グラフ）
- 削除可能な容量表示
- スキャン開始ボタン
- 最近のクリーンアップ履歴

**アピールポイント**:
- 直感的なUI
- ストレージ状況がひと目でわかる
- シンプルで使いやすいデザイン

### 02_group_list.png - グループリスト画面
**概要**: 自動グルーピング結果一覧
**内容**:
- 類似写真グループ
- ブレ写真グループ
- スクリーンショットグループ
- 各グループの写真枚数
- 削減可能なサイズ表示

**アピールポイント**:
- AIによる自動分類
- 整理のしやすさ
- 視覚的にわかりやすいカード表示

### 03_group_detail.png - グループ詳細画面
**概要**: 写真選択UI
**内容**:
- グループ内の写真グリッド表示
- ベストショット提案（★マーク）
- 複数選択UI
- 削除ボタン

**アピールポイント**:
- AIベストショット提案
- 直感的な選択UI
- 一括削除の便利さ

### 04_deletion_confirm.png - 削除確認画面
**概要**: 削除前の確認ダイアログ
**内容**:
- 削除対象の枚数
- 削減されるストレージサイズ
- ゴミ箱へ移動の説明（30日間復元可能）
- 確認ボタン

**アピールポイント**:
- 安全な削除フロー
- 誤削除防止
- ゴミ箱機能の安心感

### 05_premium.png - Premium画面
**概要**: 課金プラン一覧
**内容**:
- Free vs Premium機能比較
- 月額プラン（¥480/月）
- 年額プラン（¥3,800/年）
- 買い切りプラン（¥9,800）
- 各プランの特典

**アピールポイント**:
- わかりやすい料金体系
- 無料版でも基本機能が使える
- プレミアムの価値提案

## 🎨 スクリーンショット要件

### 技術仕様
- **ファイル形式**: PNG（推奨）または JPEG
- **色空間**: sRGB
- **圧縮**: 無損失圧縮（PNG）
- **メタデータ**: 削除済み

### ステータスバー設定
すべてのスクリーンショットで統一されたステータスバー表示：
- **時刻**: 9:41 AM
- **バッテリー**: 100%（充電完了）
- **電波**: フル（4本）
- **Wi-Fi**: 接続中
- **通知**: なし

### デザインガイドライン
- デバイスフレームは不要（画面のみ）
- テキストオーバーレイは最小限に
- 実際のアプリUIを使用（モックアップNG）
- ライトモード使用（ダークモードは任意）
- VoiceOver表示なし

## 🚀 スクリーンショット生成方法

### 自動生成（推奨）

```bash
# プロジェクトルートから実行
./scripts/generate_screenshots.sh
```

このスクリプトは以下を自動で実行します：
1. 各画面サイズのシミュレータを起動
2. ステータスバーを設定（9:41 AM、フルバッテリー、フル電波）
3. アプリをビルド & インストール
4. 各画面に遷移してスクリーンショット撮影
5. screenshots/ディレクトリに保存

### 手動撮影

```bash
# シミュレータ起動
open -a Simulator

# 特定のシミュレータを起動
xcrun simctl boot "iPhone 16 Pro Max"

# ステータスバー設定
xcrun simctl status_bar booted override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100

# スクリーンショット撮影
xcrun simctl io booted screenshot screenshot.png

# ステータスバークリア
xcrun simctl status_bar booted clear
```

## 📤 App Store Connect アップロード手順

### 1. スクリーンショット確認
```bash
# プレビュー確認
open screenshots/6.9inch/01_home.png
```

### 2. App Store Connect にログイン
1. https://appstoreconnect.apple.com にアクセス
2. 「マイApp」→「LightRoll Cleaner」選択
3. 「App Store」タブ

### 3. スクリーンショットアップロード

#### 6.9インチディスプレイ
1. 「6.9インチディスプレイ」セクション
2. 「+」ボタンをクリック
3. `screenshots/6.9inch/` から5枚を選択
4. 順序を確認（01 → 02 → 03 → 04 → 05）

#### 6.7インチディスプレイ
1. 「6.7インチディスプレイ」セクション
2. 「+」ボタンをクリック
3. `screenshots/6.7inch/` から5枚を選択
4. 順序を確認

#### 6.5インチディスプレイ
1. 「6.5インチディスプレイ」セクション
2. 「+」ボタンをクリック
3. `screenshots/6.5inch/` から5枚を選択
4. 順序を確認

#### 5.5インチディスプレイ
1. 「5.5インチディスプレイ」セクション
2. 「+」ボタンをクリック
3. `screenshots/5.5inch/` から5枚を選択
4. 順序を確認

### 4. 保存
すべてのスクリーンショットをアップロード後、「保存」をクリック

## ✅ チェックリスト

### 生成前
- [ ] Xcodeでアプリがビルド可能
- [ ] シミュレータがインストール済み
- [ ] XcodeBuildMCP設定完了
- [ ] サンプルデータが準備済み（写真データなど）

### 生成後
- [ ] 全20枚（4サイズ × 5画面）が生成されている
- [ ] 各スクリーンショットが正しい解像度
- [ ] ステータスバーが統一されている（9:41 AM、フル電波、フルバッテリー）
- [ ] 画面内容が要件を満たしている
- [ ] ファイル名が正しい（01_home.png 〜 05_premium.png）

### アップロード前
- [ ] 各スクリーンショットをプレビュー確認
- [ ] 不適切な内容がないか確認
- [ ] 解像度が要件を満たしているか確認
- [ ] ファイルサイズが適切か確認（各5MB以下推奨）

### アップロード後
- [ ] App Store Connectで正しく表示されているか確認
- [ ] 順序が正しいか確認
- [ ] すべての画面サイズでアップロード完了
- [ ] プレビューモードで最終確認

## 🛠️ トラブルシューティング

### スクリーンショットが生成されない
```bash
# シミュレータの状態確認
xcrun simctl list devices | grep Booted

# シミュレータ再起動
xcrun simctl shutdown all
./scripts/generate_screenshots.sh
```

### 解像度が間違っている
```bash
# 解像度確認
sips -g pixelWidth -g pixelHeight screenshots/6.9inch/01_home.png

# 正しい解像度に変換（非推奨、再撮影を推奨）
sips -z 2868 1320 screenshots/6.9inch/01_home.png
```

### ステータスバーが正しく設定されない
```bash
# ステータスバークリア
xcrun simctl status_bar booted clear

# 再設定
xcrun simctl status_bar booted override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100
```

### アプリが起動しない
```bash
# アプリ再インストール
xcrun simctl uninstall booted com.example.LightRoll-Cleaner
xcodebuild -workspace LightRoll_Cleaner.xcworkspace \
           -scheme LightRoll_Cleaner \
           -sdk iphonesimulator \
           build
```

## 📚 参考資料

### App Store Connect ヘルプ
- [スクリーンショット仕様](https://help.apple.com/app-store-connect/#/devd274dd925)
- [App プレビューとスクリーンショット](https://developer.apple.com/jp/help/app-store-connect/update-your-app/upload-app-previews-and-screenshots/)

### iOS Human Interface Guidelines
- [App Icon](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Marketing Resources](https://developer.apple.com/app-store/marketing/guidelines/)

## 📝 更新履歴

- **2025-12-13**: 初版作成（M10-T02）
  - 自動生成スクリプト実装
  - 4画面サイズ × 5画面 = 20枚対応
  - ステータスバー自動設定

---

**ご質問・問題がある場合**:
- Issue: GitHub Issuesに報告
- Email: support@example.com
