# MODULE M1: Core Infrastructure

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M1 |
| モジュール名 | Core Infrastructure |
| 責務 | アプリケーション基盤、DI、設定管理、ユーティリティ |
| 依存先 | なし（最下層モジュール） |
| 依存元 | 全モジュール |

---

## 2. 主要コンポーネント

### 2.1 DI Container
```swift
// DI/Container.swift
@MainActor
final class DIContainer {
    static let shared = DIContainer()

    // Repositories
    lazy var photoRepository: PhotoRepositoryProtocol = PhotoRepository()
    lazy var analysisRepository: AnalysisRepositoryProtocol = AnalysisRepository()
    lazy var settingsRepository: SettingsRepositoryProtocol = SettingsRepository()
    lazy var purchaseRepository: PurchaseRepositoryProtocol = PurchaseRepository()

    // Use Cases
    lazy var scanPhotosUseCase: ScanPhotosUseCaseProtocol = ...
    lazy var groupPhotosUseCase: GroupPhotosUseCaseProtocol = ...
    lazy var deletePhotosUseCase: DeletePhotosUseCaseProtocol = ...
}
```

### 2.2 AppState
```swift
// State/AppState.swift
@MainActor
final class AppState: ObservableObject {
    @Published var isInitialized: Bool = false
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var photoGroups: [PhotoGroup] = []
    @Published var storageInfo: StorageInfo?
    @Published var error: LightRollError?
}
```

### 2.3 Configuration
```swift
// Config/AppConfig.swift
enum AppConfig {
    static let similarityThreshold: Float = 0.85
    static let blurThreshold: Float = 0.3
    static let trashRetentionDays: Int = 30
    static let freeTierDailyDeleteLimit: Int = 50
    static let scanBatchSize: Int = 100
}
```

### 2.4 Logger
```swift
// Utils/Logger.swift
enum LogLevel: Int {
    case debug, info, warning, error
}

struct Logger {
    static func log(_ message: String, level: LogLevel = .info, file: String = #file)
}
```

---

## 3. ディレクトリ構造

```
src/modules/Core/
├── DI/
│   └── DIContainer.swift
├── State/
│   └── AppState.swift
├── Config/
│   └── AppConfig.swift
├── Utils/
│   ├── Logger.swift
│   ├── FileManager+Extensions.swift
│   └── Date+Extensions.swift
├── Errors/
│   └── LightRollError.swift
└── Protocols/
    ├── Repositories.swift
    └── UseCases.swift
```

---

## 4. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M1-T01 | Xcodeプロジェクト作成 | iOS向けSwiftUIプロジェクトの初期設定 | 1h | - |
| M1-T02 | ディレクトリ構造整備 | モジュール別ディレクトリ作成 | 0.5h | M1-T01 |
| M1-T03 | エラー型定義 | LightRollError列挙型の実装 | 1h | M1-T02 |
| M1-T04 | ロガー実装 | デバッグ用ロガーユーティリティ | 1h | M1-T02 |
| M1-T05 | AppConfig実装 | 設定値の一元管理クラス | 1h | M1-T02 |
| M1-T06 | DIコンテナ基盤 | 依存性注入コンテナの基本実装 | 2h | M1-T03 |
| M1-T07 | AppState実装 | グローバル状態管理クラス | 2h | M1-T06 |
| M1-T08 | Protocol定義 | Repository/UseCaseプロトコル | 2h | M1-T03 |
| M1-T09 | 拡張ユーティリティ | FileManager/Date拡張 | 1.5h | M1-T02 |
| M1-T10 | 単体テスト作成 | Core機能のユニットテスト | 2h | M1-T07 |

---

## 5. テストケース

### M1-T03: エラー型定義
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M1-T03-TC01 | photoAccessDeniedのエラーメッセージ取得 | 日本語メッセージが返る |
| M1-T03-TC02 | analysisFailed(underlying:)でラップしたエラー | 元エラーが保持される |
| M1-T03-TC03 | Equatable準拠の確認 | 同じケースで等価判定 |

### M1-T06: DIコンテナ基盤
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M1-T06-TC01 | sharedインスタンスのシングルトン確認 | 同一インスタンス |
| M1-T06-TC02 | Repositoryの遅延初期化 | アクセス時に初期化 |
| M1-T06-TC03 | モックへの差し替え | テスト用実装が使用される |

### M1-T07: AppState実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M1-T07-TC01 | 初期状態の確認 | isScanning=false, groups=[] |
| M1-T07-TC02 | @Publishedプロパティの変更通知 | ObservableObjectとして通知 |
| M1-T07-TC03 | MainActorでのアクセス | メインスレッドで実行 |

---

## 6. 受け入れ条件

- [ ] Xcodeプロジェクトがビルド可能
- [ ] 全てのプロトコルが定義済み
- [ ] DIContainerから全Repositoryが取得可能
- [ ] AppStateの状態変更が通知される
- [ ] エラー型が適切にローカライズされている
- [ ] 単体テストのカバレッジ80%以上

---

## 7. 技術的考慮事項

### 7.1 スレッドセーフティ
- AppStateは@MainActorで保護
- DIContainerのlazyプロパティはスレッドセーフ

### 7.2 メモリ管理
- DIContainerはシングルトンのため、循環参照に注意
- 必要に応じてweakリファレンスを使用

---

*最終更新: 2025-11-27*
