# App Store Connect準備チェックリスト

## 概要

このドキュメントは、LightRoll CleanerをApp Store Connectに提出するための完全なチェックリストです。すべての項目を確認し、審査を円滑に通過できるよう準備してください。

**最終更新**: 2025-12-13
**対象バージョン**: 1.0.0
**ターゲットiOS**: 18.0+

---

## 📋 提出前必須チェック項目

### ✅ アプリビルド準備

- [ ] **本番用ビルド設定確認**
  - [ ] Build Configuration: Release
  - [ ] Code Signing: Distribution証明書
  - [ ] Provisioning Profile: App Store Distribution
  - [ ] Bitcode: 無効化確認（iOS 14以降は不要）
  - [ ] App Thining: 有効化

- [ ] **バージョン情報**
  - [ ] CFBundleShortVersionString: 1.0.0（マーケティングバージョン）
  - [ ] CFBundleVersion: 1（ビルドナンバー）
  - [ ] 次回以降のバージョンルール策定

- [ ] **署名と証明書**
  - [ ] Distribution証明書の有効期限確認
  - [ ] App IDの登録確認（com.example.LightRoll-Cleaner）
  - [ ] Push通知証明書の設定（該当する場合）
  - [ ] Associated Domainsの設定（該当する場合）

- [ ] **ビルド実行**
  - [ ] Archive作成成功
  - [ ] Validation成功（Xcode Organizer）
  - [ ] TestFlightへのアップロード成功
  - [ ] 実機での動作確認（最低3機種）

---

### ✅ App Store Connect設定

#### 1. アプリ情報（App Information）

- [ ] **基本情報**
  - [ ] アプリ名: LightRoll Cleaner（30文字以内）
  - [ ] サブタイトル: 写真整理でストレージ解放（30文字以内）
  - [ ] バンドルID: com.example.LightRoll-Cleaner
  - [ ] SKU: LRC-001（内部管理用ID）
  - [ ] プライマリ言語: 日本語

- [ ] **カテゴリ**
  - [ ] プライマリカテゴリ: ユーティリティ（Utilities）
  - [ ] セカンダリカテゴリ: 写真/ビデオ（Photo & Video）

- [ ] **年齢レーティング**
  - [ ] 4+（すべての年齢）
  - [ ] コンテンツ評価質問票の回答完了

#### 2. 価格と配信可否（Pricing and Availability）

- [ ] **価格設定**
  - [ ] 基本料金: 無料
  - [ ] App内課金あり: はい
  - [ ] 配信開始日: 手動リリース（審査通過後に公開）

- [ ] **配信地域**
  - [ ] 日本: 配信
  - [ ] その他の地域: 段階的展開を検討

#### 3. App内課金設定（In-App Purchases）

- [ ] **サブスクリプション設定**
  - [ ] Premium Monthly（月額）
    - [ ] 製品ID: com.example.LightRoll-Cleaner.premium.monthly
    - [ ] 価格: ¥480
    - [ ] 無料トライアル: なし
    - [ ] 自動更新: はい
  - [ ] Premium Yearly（年額）
    - [ ] 製品ID: com.example.LightRoll-Cleaner.premium.yearly
    - [ ] 価格: ¥3,800
    - [ ] 無料トライアル: なし
    - [ ] 自動更新: はい
  - [ ] Lifetime（買い切り）
    - [ ] 製品ID: com.example.LightRoll-Cleaner.premium.lifetime
    - [ ] 価格: ¥9,800
    - [ ] 種類: 非消費型

- [ ] **サブスクリプショングループ**
  - [ ] グループ名: Premium Features
  - [ ] 階層設定: Monthly < Yearly < Lifetime

- [ ] **審査用メモ**
  - [ ] 課金機能のテスト手順を記載
  - [ ] サンドボックステストアカウント情報を提供

---

### ✅ アプリプレビュー情報（App Review Information）

- [ ] **連絡先情報**
  - [ ] 名前: [担当者名]
  - [ ] 電話番号: [国際フォーマット]
  - [ ] メールアドレス: [サポートメール]

- [ ] **デモアカウント（必要に応じて）**
  - [ ] ユーザー名: demo@example.com
  - [ ] パスワード: [安全なパスワード]
  - [ ] 追加情報: 写真アクセス許可が必要です

- [ ] **審査メモ（Review Notes）**
  ```
  【審査担当者様へ】

  このアプリは、iOSデバイスのカメラロールから不要な写真を自動検出し、
  削除できる写真クリーナーアプリです。

  ■ 主要機能
  - 写真ライブラリへのアクセス（必須）
  - Vision/CoreMLによる画像分析
  - 類似写真・ブレ写真・スクリーンショットの自動グルーピング
  - ベストショット提案
  - 一括削除機能（ゴミ箱経由で30日間復元可能）
  - 無料版：1日50枚削除上限、広告表示
  - プレミアム版：無制限削除、広告非表示

  ■ テスト手順
  1. アプリ起動後、写真アクセスを許可してください
  2. スキャン開始ボタンをタップ
  3. 自動グルーピング結果を確認
  4. グループから写真を選択して削除

  ■ 課金テスト
  - ホーム画面右上の「Premium」ボタンから課金画面へ
  - サンドボックス環境で購入をテスト可能

  ■ プライバシー
  - 写真データは端末内のみで処理され、外部送信されません
  - 分析結果もローカル保存のみです

  ご不明点があれば、上記連絡先までお問い合わせください。
  ```

---

### ✅ スクリーンショット要件

#### iPhone（必須）

**6.9インチディスプレイ（iPhone 16 Pro Max / 15 Pro Max）**
- [ ] 解像度: 1320 x 2868 px（縦向き）
- [ ] 枚数: 3〜10枚（推奨: 5枚）
- [ ] ファイル形式: PNG または JPEG（sRGB色空間）

**6.7インチディスプレイ（iPhone 16 Plus / 15 Plus / 14 Pro Max）**
- [ ] 解像度: 1290 x 2796 px（縦向き）
- [ ] 枚数: 3〜10枚（推奨: 5枚）

**6.5インチディスプレイ（iPhone XS Max / 11 Pro Max）**
- [ ] 解像度: 1242 x 2688 px（縦向き）
- [ ] 枚数: 3〜10枚（推奨: 5枚）

**5.5インチディスプレイ（iPhone 8 Plus / 7 Plus）**
- [ ] 解像度: 1242 x 2208 px（縦向き）
- [ ] 枚数: 3〜10枚（推奨: 5枚）

#### 推奨スクリーンショット構成

1. **ホーム画面**：ストレージ概要、スキャンボタン
2. **グループリスト画面**：自動グルーピング結果
3. **グループ詳細画面**：写真選択UI、ベストショット提案
4. **削除確認画面**：削除前の確認ダイアログ
5. **Premium画面**：課金プラン一覧

**スクリーンショット作成のポイント**
- [ ] デバイスフレームは不要
- [ ] ステータスバーは9:41 AM、フルバッテリー、フル電波
- [ ] テキストオーバーレイは最小限に
- [ ] 実際のアプリUIを使用（モックアップNG）
- [ ] 多言語対応の場合、各言語で別途用意

---

### ✅ アプリ説明文（日本語）

#### アプリ名
```
LightRoll Cleaner
```

#### サブタイトル（30文字以内）
```
写真整理でストレージ解放
```

#### 説明文（4000文字以内）
```
【写真の断捨離を自動化】
スマホのストレージ、写真でパンパンになっていませんか？

LightRoll Cleanerは、iPhoneのカメラロールから不要な写真を自動で見つけ出し、
まとめて削除できる写真クリーナーアプリです。

■ こんな方におすすめ
・似たような写真がたくさんある
・失敗写真を削除するのが面倒
・スクリーンショットが溜まっている
・ストレージ容量が足りない
・写真整理の時間がない

■ 主な機能
【自動グルーピング】
AIが写真を分析し、似た写真・ブレ写真・スクリーンショット・自撮りを
自動でグループ分け。どの写真が不要かひと目で分かります。

【ベストショット提案】
似た写真の中から、AIが最もキレイに撮れた1枚を自動選択。
あなたは提案を確認して削除するだけ。

【安全な削除】
削除した写真は30日間ゴミ箱に保管。
万が一間違えて削除しても、すぐに復元できます。

【ストレージダッシュボード】
現在の使用容量と、削除可能な容量をひと目で確認。
削除後にどれだけ空き容量が増えるか事前にわかります。

【定期リマインド】
週次/月次で写真整理のリマインド通知。
定期的な整理でストレージを常にクリーンに保てます。

■ プレミアム機能（アプリ内課金）
【Freeプラン】
・1日50枚まで削除可能
・広告表示あり

【Premiumプラン】
・無制限削除
・広告非表示
・優先サポート

月額プラン: ¥480/月
年額プラン: ¥3,800/年（2ヶ月分お得）
買い切りプラン: ¥9,800（永久利用）

■ プライバシー保護
・写真データは端末内のみで処理
・インターネット接続不要（広告表示時を除く）
・写真は一切外部に送信されません
・Appleの写真アクセス権限で完全保護

■ 動作環境
・iOS 18.0以降
・iPhone 12以降推奨

さあ、今すぐLightRoll Cleanerで写真を整理して、
スッキリしたカメラロールを手に入れましょう！
```

#### キーワード（100文字以内、カンマ区切り）
```
写真整理,写真削除,ストレージ解放,重複写真,類似写真,ブレ写真,スクリーンショット整理,カメラロール,容量不足,写真管理
```

#### プロモーション用テキスト（170文字以内）
```
📸 新機能：AIベストショット提案
似た写真の中から、最もキレイな1枚を自動選択！
写真整理がさらにカンタンになりました。
```

#### サポートURL
```
https://example.com/support
```

#### マーケティングURL（任意）
```
https://example.com/lightroll-cleaner
```

---

### ✅ アプリ説明文（英語 - グローバル展開時）

#### App Name
```
LightRoll Cleaner
```

#### Subtitle
```
Clean photos, free storage
```

#### Description
```
【Automate Your Photo Decluttering】
Is your iPhone storage full of photos?

LightRoll Cleaner is a smart photo cleaning app that automatically finds
unnecessary photos in your Camera Roll and helps you delete them in bulk.

■ Perfect for those who:
・Have many similar photos
・Find deleting failed photos tedious
・Have accumulated screenshots
・Are running out of storage
・Don't have time to organize photos

■ Key Features
【Auto Grouping】
AI analyzes photos and automatically groups similar photos, blurry shots,
screenshots, and selfies. See which photos are unnecessary at a glance.

【Best Shot Suggestion】
AI automatically selects the best shot from similar photos.
You just review the suggestions and delete.

【Safe Deletion】
Deleted photos are kept in trash for 30 days.
If you delete by mistake, you can restore immediately.

【Storage Dashboard】
Check current usage and deletable capacity at a glance.
Know how much space you'll free up before deleting.

【Scheduled Reminders】
Weekly/monthly photo cleanup reminders.
Keep your storage clean with regular maintenance.

■ Premium Features (In-App Purchase)
【Free Plan】
・Delete up to 50 photos per day
・Ads displayed

【Premium Plan】
・Unlimited deletion
・No ads
・Priority support

Monthly: $4.99/month
Yearly: $39.99/year (Save 2 months)
Lifetime: $99.99 (Use forever)

■ Privacy Protection
・Photos processed only on device
・No internet required (except for ads)
・Photos never sent externally
・Fully protected by Apple's photo access permissions

■ Requirements
・iOS 18.0 or later
・iPhone 12 or later recommended

Start organizing your photos with LightRoll Cleaner today
and get a clean Camera Roll!
```

#### Keywords
```
photo cleaner,duplicate photos,storage cleaner,similar photos,blurry photos,screenshot cleaner,camera roll,storage full,photo manager,cleanup
```

---

### ✅ プライバシーポリシー

- [ ] **プライバシーポリシーURL設定**
  - [ ] URL: https://example.com/privacy-policy
  - [ ] アクセス可能確認（審査時にチェックされます）

- [ ] **App Privacy詳細（App Store Connect）**
  - [ ] データ収集: なし（写真データは端末内処理のみ）
  - [ ] トラッキング: なし（広告IDは使用しますが追跡なし）
  - [ ] データ使用目的: 写真分析・削除機能提供のみ
  - [ ] 第三者共有: なし
  - [ ] 広告表示: あり（Google Mobile Ads）
    - [ ] 広告識別子の使用について明記
    - [ ] ユーザー追跡なし（ATT不要）

#### プライバシーポリシー必須記載事項

```markdown
# プライバシーポリシー

【収集する情報】
・写真ライブラリメタデータ（分析のみ、保存なし）
・デバイス情報（クラッシュレポート用）
・広告識別子（広告表示用、追跡なし）

【情報の使用目的】
・写真の類似性・品質分析
・アプリの改善
・広告表示

【第三者提供】
・なし（写真データは一切外部送信されません）

【データ保存】
・すべて端末内のみ
・サーバーへのアップロードなし

【お問い合わせ】
privacy@example.com
```

---

### ✅ 審査ガイドライン対応

#### 1. Guideline 2.1: App Completeness
- [ ] すべての機能が正常動作
- [ ] クラッシュなし
- [ ] プレースホルダーコンテンツなし
- [ ] デモモードなし

#### 2. Guideline 2.3: Accurate Metadata
- [ ] スクリーンショットがアプリの実際のUIと一致
- [ ] 説明文が機能を正確に反映
- [ ] 誇大広告なし

#### 3. Guideline 3.1: Payments
- [ ] In-App Purchase実装済み
- [ ] StoreKit 2使用
- [ ] リストア機能実装済み
- [ ] 価格表記明確

#### 4. Guideline 4.0: Design
- [ ] iOS Human Interface Guidelines準拠
- [ ] SwiftUI使用
- [ ] ダークモード対応
- [ ] アクセシビリティ対応

#### 5. Guideline 5.1.1: Privacy - Data Collection
- [ ] 写真アクセス許可ダイアログに目的明記
- [ ] 端末内処理のみ
- [ ] 外部送信なし

#### 6. Guideline 5.1.2: Privacy - Data Use
- [ ] プライバシーポリシーURL設定済み
- [ ] App Privacy詳細入力済み
- [ ] 広告表示について明記

---

### ✅ テストフライト配信

- [ ] **内部テスター招待**
  - [ ] 開発チームメンバー追加
  - [ ] ビルド配信
  - [ ] フィードバック収集（最低1週間）

- [ ] **外部テスター招待（任意）**
  - [ ] ベータ版説明文作成
  - [ ] テスターグループ作成
  - [ ] ビルド配信
  - [ ] フィードバック収集（最低2週間）

- [ ] **バグ修正**
  - [ ] 重大なバグはすべて修正
  - [ ] マイナーバグはIssue管理
  - [ ] 最終ビルド作成

---

### ✅ 最終確認

- [ ] **機能確認**
  - [ ] 写真スキャン動作確認（100枚以上）
  - [ ] グルーピング精度確認
  - [ ] 削除・復元動作確認
  - [ ] 課金フロー確認（サンドボックス）
  - [ ] リストア機能確認
  - [ ] 広告表示確認（Free版）

- [ ] **パフォーマンス確認**
  - [ ] 起動時間: 3秒以内
  - [ ] スキャン速度: 100枚/10秒以内
  - [ ] メモリ使用量: 300MB以内
  - [ ] バッテリー消費: 正常範囲内

- [ ] **互換性確認**
  - [ ] iPhone 12 Pro Max: 動作確認
  - [ ] iPhone 13: 動作確認
  - [ ] iPhone 14 Pro: 動作確認
  - [ ] iPhone 15: 動作確認
  - [ ] iPhone 16: 動作確認
  - [ ] iOS 18.0: 動作確認
  - [ ] iOS 18.1: 動作確認

- [ ] **アクセシビリティ確認**
  - [ ] VoiceOver対応
  - [ ] Dynamic Type対応
  - [ ] カラーコントラスト確認
  - [ ] タッチターゲットサイズ（44x44pt以上）

---

## 📊 提出手順

### Step 1: Archive作成
```bash
# Xcodeで実行
Product > Archive
```

### Step 2: Validation
```bash
# Xcode Organizer
Window > Organizer > Archives > Validate App
```

### Step 3: Upload
```bash
# Xcode Organizer
Distribute App > App Store Connect > Upload
```

### Step 4: App Store Connectで設定
1. App Store Connect にログイン
2. 「マイApp」→「LightRoll Cleaner」
3. 「+バージョンまたはプラットフォーム」→「iOS」
4. バージョン情報入力（1.0.0）
5. スクリーンショットアップロード
6. 説明文入力
7. プライバシー設定
8. 価格設定
9. ビルド選択
10. 「審査に提出」

### Step 5: 審査待ち
- 平均審査期間: 24〜48時間
- ステータス確認: App Store Connect
- 追加情報要求があれば速やかに対応

### Step 6: 承認後
- 手動リリース: 「このバージョンをリリース」ボタン
- 自動リリース: 審査通過後自動公開（事前設定必要）

---

## 🚨 よくあるリジェクト理由と対策

### 1. Guideline 2.1 - クラッシュ
**原因**: 審査中にアプリがクラッシュ
**対策**:
- TestFlightで十分テスト
- クラッシュレポート監視
- エラーハンドリング徹底

### 2. Guideline 4.2 - 最小機能要件
**原因**: アプリが単純すぎる
**対策**:
- 本アプリは十分な機能を持つため問題なし
- 審査メモで機能詳細を説明

### 3. Guideline 5.1.1 - プライバシー
**原因**: 写真アクセス目的が不明確
**対策**:
- Info.plistのNSPhotoLibraryUsageDescriptionを詳細に
- プライバシーポリシー明記

### 4. Guideline 3.1.1 - 課金機能
**原因**: リストア機能がない
**対策**:
- M9-T14でリストア機能実装済み
- 審査メモでリストア手順を明記

---

## 📞 サポート体制

### 審査期間中の対応
- メール監視: 毎日3回（朝・昼・夕）
- 追加情報要求への応答: 24時間以内
- 緊急連絡先: [担当者電話番号]

### リリース後の監視
- クラッシュレポート: 毎日確認
- レビュー監視: 毎日確認
- サポートメール: 24時間以内に返信

---

## ✅ チェックリスト進捗

**全体進捗**: [ ] 0% → 提出準備開始

**セクション別**:
- [ ] アプリビルド準備: 0/4
- [ ] App Store Connect設定: 0/12
- [ ] スクリーンショット: 0/5
- [ ] 説明文: 0/3
- [ ] プライバシー: 0/2
- [ ] 審査ガイドライン: 0/6
- [ ] テストフライト: 0/3
- [ ] 最終確認: 0/4

---

**次のステップ**:
1. Development/Distribution証明書の準備
2. App Store Connectでアプリ登録
3. スクリーンショット撮影開始

---

*このチェックリストは、実際の審査経験をもとに随時更新されます。*
