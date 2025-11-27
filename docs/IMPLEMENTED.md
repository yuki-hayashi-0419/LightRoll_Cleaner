# 実装済み機能一覧

このファイルは、ユーザー視点で「できるようになったこと」を記録します。

---

## 現在の実装状況

### バージョン: 0.3.0（Phase 1 基盤構築 進行中）

**アプリ機能**: デザインシステム基盤が完成し、一貫したUIスタイルでの開発が可能に。グラスモーフィズム効果を使った美しいカードやボタンが実装可能。Protocol層の定義により、各機能モジュールの実装準備が整った。

---

## 基盤構築（Phase 1 進行中）

### デザインシステム完成 - 2025-11-28（本セッション）

#### タイポグラフィ（15フォントスタイル）
- **Dynamic Type完全対応**: 全フォントスタイルがアクセシビリティ設定に追従
- **4カテゴリ構成**:
  - Display系（largeTitle, title1〜3）
  - Body系（headline, body, callout, subheadline）
  - Supporting系（footnote, caption, caption2）
  - 数値専用（largeNumber, mediumNumber, smallNumber, monospaced）
- **便利な拡張API**: `.lightRollTextStyle()` / `.primaryStyle()` / `.secondaryStyle()`

#### グラスモーフィズム（iOS 17+対応、iOS 26準備済み）
- **5段階のスタイル**: ultraThin / thin / regular / thick / chrome
- **4種の形状**: roundedRectangle / capsule / circle / continuousRoundedRectangle
- **即使用可能なコンポーネント**:
  - `GlassCardView` - グラス効果カード
  - `GlassButtonStyle` - グラスボタンスタイル（`.buttonStyle(.glass())`）
- **便利な拡張API**: `.glassCard()` / `.glassCapsule()` / `.glassCircle()` / `.adaptiveGlass()`

#### スペーシングシステム（8ptグリッド）
- **8段階のスペーシング**: xxs(2) / xs(4) / sm(8) / md(12) / lg(16) / xl(24) / xxl(32) / xxxl(40)
- **6段階の角丸**: XS(4) / SM(8) / MD(12) / LG(16) / XL(20) / XXL(24)
- **7段階のアイコンサイズ**: XS(12) / SM(16) / MD(20) / LG(24) / XL(32) / XXL(48) / Huge(64)
- **EdgeInsets拡張**: `.LightRoll.card` / `.LightRoll.button` など
- **便利な拡張API**: `.componentPadding()` / `.cardPadding()` / `.ensureMinTouchTarget()`

#### Protocol層（各モジュールのインターフェース定義）
- **UseCase Protocols**: ScanPhotos / GroupPhotos / DeletePhotos / RestorePhotos / GetStatistics / AnalyzePhoto / SelectBestShot / Purchase / CheckDeletionLimit
- **ViewModel Protocols**: Dashboard / PhotoGroup / Settings / Deletion の各画面用
- **Service Protocols**: PhotoLibrary / ImageAnalysis / Storage / StoreKit / Notification の各サービス用
- **Repository Protocols**: Photo / User / Config の各データアクセス用

### Core Infrastructure - 2025-11-28

#### プロジェクト基盤
- Xcodeプロジェクト作成完了（iOS 17+/SwiftUI/SPM構成）
- 5層アーキテクチャ（Domain/Data/Presentation/Core/Utils）

#### 設定・状態管理
- AppConfig実装（設定永続化・検証機能）
- AppState実装（@Observable対応のアプリ状態管理）
- 統一エラー型定義（LightRollError）
- DIコンテナ基盤（ServiceLocatorパターン）

#### カラーパレット（16色セット）
- ダークモード完全対応、アクセシビリティ考慮済み

---

## ユーザー視点での進捗サマリー

| 観点 | 状態 | 説明 |
|------|------|------|
| アプリ起動 | **実装中** | 基本構造動作可能、デザインシステム適用準備完了 |
| 写真スキャン | 設計完了 | Photos Framework統合の仕様策定済み |
| 類似写真検出 | 設計完了 | Vision/pHash併用アルゴリズム設計済み |
| 一括削除 | 設計完了 | 安全な削除フローを仕様化済み |
| 容量表示 | 設計完了 | ダッシュボードUI設計済み |
| 課金機能 | 設計完了 | StoreKit 2統合の仕様策定済み |

---

## 次回実装予定

### Phase 1 継続 - Core Infrastructure（M1）
- [ ] M1-T04: Logger実装
- [ ] M1-T09〜T12: ユニットテスト

### Phase 1 継続 - UI Components（M4）
- [ ] M4-T05〜T08: 共通コンポーネント（ボタン、進捗表示、空状態）

### Phase 2 - データ層（M2）
- [ ] Photos Framework統合
- [ ] 写真スキャン機能
- [ ] メタデータ取得

---

## 機能リリース履歴

| バージョン | リリース日 | 主な機能 |
|-----------|-----------|----------|
| 0.1.0 | 2025-11-27 | 設計フェーズ完了 |
| 0.2.0 | 2025-11-28 | 基盤構築開始（Core + カラーパレット） |
| 0.3.0 | 2025-11-28 | デザインシステム基盤完成（Typography + Glass + Spacing + Protocols） |
| 1.0.0 | 予定 | 初回リリース（MVP） |

---

*最終更新: 2025-11-28*
