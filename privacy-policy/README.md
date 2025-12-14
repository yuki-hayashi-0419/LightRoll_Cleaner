# プライバシーポリシー 公開ガイド

## 📋 概要

このディレクトリには、LightRoll CleanerのApp Store提出に必須のプライバシーポリシーが含まれています。

**最終更新**: 2025-12-14
**バージョン**: 1.0.0
**言語**: 日本語、英語

---

## 📁 ファイル構成

```
privacy-policy/
├── index.html           # 日本語版プライバシーポリシー
├── en/
│   └── index.html      # 英語版プライバシーポリシー
└── README.md           # このファイル（公開手順）
```

---

## 🌐 公開方法

### オプション1: GitHub Pages（推奨）

GitHub Pagesを使用すると、無料でHTMLファイルをホスティングできます。

#### 手順

1. **GitHubリポジトリを作成**（まだ作成していない場合）
   ```bash
   # プロジェクトルートで実行
   git init
   git add .
   git commit -m "Initial commit"
   gh repo create LightRoll-Cleaner --private --source=. --push
   ```

2. **プライバシーポリシーを専用ブランチにプッシュ**
   ```bash
   # gh-pagesブランチを作成
   git checkout --orphan gh-pages

   # privacy-policy/以外を削除
   git rm -rf .
   git checkout HEAD -- privacy-policy

   # privacy-policy/の中身をルートに移動
   mv privacy-policy/* .
   rmdir privacy-policy

   # コミット＆プッシュ
   git add .
   git commit -m "Add privacy policy"
   git push origin gh-pages
   ```

3. **GitHub Pagesを有効化**
   - GitHubリポジトリページへ移動
   - "Settings" → "Pages"
   - Source: "Deploy from a branch"
   - Branch: "gh-pages" / "/ (root)"
   - "Save"をクリック

4. **公開URLを確認**
   - 数分後、以下のURLでアクセス可能になります：
   ```
   日本語版: https://[ユーザー名].github.io/LightRoll-Cleaner/
   英語版:   https://[ユーザー名].github.io/LightRoll-Cleaner/en/
   ```

5. **App Store Connectに登録**
   - App Store Connect → アプリ情報
   - "プライバシーポリシーURL"に上記URLを入力

---

### オプション2: 独自ドメイン

独自ドメインを持っている場合は、Webサーバーにアップロードします。

#### 手順

1. **FTP/SFTPでアップロード**
   ```bash
   # 例: SCPを使用
   scp -r privacy-policy/* user@yourserver.com:/var/www/html/privacy/
   ```

2. **公開URLを確認**
   ```
   日本語版: https://yourserver.com/privacy/
   英語版:   https://yourserver.com/privacy/en/
   ```

3. **App Store Connectに登録**

---

### オプション3: Netlify（簡単デプロイ）

Netlifyを使用すると、ドラッグ&ドロップで簡単にデプロイできます。

#### 手順

1. **Netlifyアカウント作成**
   - https://www.netlify.com/ にアクセス
   - 無料アカウントを作成

2. **ドラッグ&ドロップでデプロイ**
   - `privacy-policy/`フォルダ全体をNetlifyにドラッグ
   - 自動的にデプロイされます

3. **公開URLを確認**
   ```
   日本語版: https://[ランダム名].netlify.app/
   英語版:   https://[ランダム名].netlify.app/en/
   ```

4. **カスタムドメイン設定（オプション）**
   - Site settings → Domain management
   - カスタムドメインを追加

---

## ✅ 公開前チェックリスト

プライバシーポリシーを公開する前に、以下を確認してください：

- [ ] **両方の言語版が正しく表示される**
  - [ ] 日本語版（index.html）
  - [ ] 英語版（en/index.html）

- [ ] **リンクが正常に機能する**
  - [ ] 言語切り替えリンク
  - [ ] 外部リンク（Google Privacy Policy）
  - [ ] メールアドレスリンク

- [ ] **モバイルで読みやすい**
  - [ ] iPhone Safari でテスト
  - [ ] テキストが小さすぎない（最小14px）
  - [ ] スクロールが正常
  - [ ] レスポンシブデザインが機能

- [ ] **必須情報が含まれている**
  - [ ] 収集するデータの種類
  - [ ] データの使用目的
  - [ ] 第三者提供（Google AdMob）
  - [ ] データ保存場所（ローカルのみ）
  - [ ] ユーザーの権利
  - [ ] 連絡先情報
  - [ ] 最終更新日

- [ ] **App Store審査要件を満たす**
  - [ ] 写真データは外部送信されないことを明記
  - [ ] Google AdMobの使用を明記
  - [ ] 子どものプライバシー保護について記載
  - [ ] データ削除方法を説明

---

## 📝 App Store Connectでの設定

プライバシーポリシーURLを公開したら、App Store Connectで設定します。

### 手順

1. **App Store Connectにログイン**
   - https://appstoreconnect.apple.com/

2. **アプリ情報を開く**
   - "マイApp" → "LightRoll Cleaner"
   - "アプリ情報"タブ

3. **プライバシーポリシーURLを入力**
   - "プライバシーポリシー"セクション
   - 公開したURLを入力（例: `https://yourname.github.io/LightRoll-Cleaner/`）
   - "保存"をクリック

4. **App Privacy詳細を設定**
   - "App Privacy"タブ
   - 以下の質問に回答：
     - **データ収集**: あり
     - **トラッキング**: なし
     - **収集するデータ**:
       - 写真（分析用、端末内のみ）
       - デバイスID（広告用）
     - **第三者共有**: Google AdMob（広告配信のみ）

---

## 🔄 更新手順

プライバシーポリシーを更新する必要がある場合：

1. **HTMLファイルを編集**
   ```bash
   # 日本語版
   vim privacy-policy/index.html

   # 英語版
   vim privacy-policy/en/index.html
   ```

2. **最終更新日を変更**
   - `<p class="update-date">` タグ内の日付を更新

3. **変更をデプロイ**
   - GitHub Pages: `git push origin gh-pages`
   - Netlify: 自動デプロイ
   - 独自サーバー: FTP/SFTPで再アップロード

4. **App内で通知（重要な変更の場合）**
   - アプリ内通知を実装
   - または次回アップデート時に「What's New」に記載

---

## 🚨 よくある問題と解決策

### Q1: GitHub Pagesが404エラーになる

**原因**: デプロイが完了していない、またはブランチ設定が間違っている

**解決策**:
- GitHub Pagesの設定を確認（Settings → Pages）
- ブランチが`gh-pages`、ディレクトリが`/ (root)`になっているか確認
- デプロイ完了まで5〜10分待つ

### Q2: モバイルでレイアウトが崩れる

**原因**: CSSのメディアクエリが機能していない

**解決策**:
- `<meta name="viewport">` タグが正しく設定されているか確認
- ブラウザのキャッシュをクリア
- 別のモバイルブラウザでテスト

### Q3: App Store審査でリジェクトされた

**原因**: プライバシーポリシーの内容が不十分

**解決策**:
- 審査担当者のコメントを確認
- 不足している情報を追記
- 特に「写真データの外部送信なし」を強調
- App Privacy詳細とプライバシーポリシーの一貫性を確認

---

## 📞 サポート

プライバシーポリシーの公開でお困りの場合は、以下を確認してください：

- **GitHub Pages公式ドキュメント**: https://docs.github.com/pages
- **Netlifyドキュメント**: https://docs.netlify.com/
- **App Store審査ガイドライン**: https://developer.apple.com/app-store/review/guidelines/

---

## ✅ 完了確認

プライバシーポリシーが正しく公開されたことを確認：

- [ ] 日本語版URLがブラウザで開ける
- [ ] 英語版URLがブラウザで開ける
- [ ] モバイル（iPhone Safari）で正常に表示される
- [ ] すべてのリンクが機能する
- [ ] App Store Connectに登録済み
- [ ] URLがHTTPS（セキュア接続）

**すべてチェックできたら、M10-T03完了です！** 🎉

---

**次のステップ**: M10-T04（App Store Connect設定）に進んでください。
