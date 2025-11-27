# MODULE M7: Notifications

## 1. モジュール概要

| 項目 | 内容 |
|------|------|
| モジュールID | M7 |
| モジュール名 | Notifications |
| 責務 | ローカル通知、リマインダー、空き容量アラート |
| 依存先 | M1, M2, M8 |
| 依存元 | - |

---

## 2. 通知種別

### 2.1 通知タイプ
| 通知ID | タイプ | トリガー | 内容 |
|--------|--------|----------|------|
| NOTIF_001 | 空き容量警告 | 空き容量が閾値以下 | ストレージクリーンアップを促す |
| NOTIF_002 | 定期リマインド | 設定した周期 | クリーンアップのリマインダー |
| NOTIF_003 | スキャン完了 | バックグラウンドスキャン完了 | 削除候補数を通知 |
| NOTIF_004 | ゴミ箱期限警告 | 期限切れ前日 | 復元が必要な場合の警告 |

### 2.2 通知設定
```swift
struct NotificationSettings: Codable {
    var isEnabled: Bool = true
    var storageAlertEnabled: Bool = true
    var storageAlertThreshold: Double = 0.9  // 90%使用時
    var reminderEnabled: Bool = false
    var reminderInterval: ReminderInterval = .weekly
    var quietHoursEnabled: Bool = true
    var quietHoursStart: Int = 22  // 22:00
    var quietHoursEnd: Int = 8     // 08:00
}

enum ReminderInterval: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily: return "毎日"
        case .weekly: return "毎週"
        case .biweekly: return "2週間ごと"
        case .monthly: return "毎月"
        }
    }
}
```

---

## 3. 主要コンポーネント

### 3.1 NotificationManager
```swift
// Services/NotificationManager.swift
final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() async -> Bool
    func checkPermissionStatus() -> UNAuthorizationStatus
    func scheduleStorageAlert(threshold: Double) async
    func scheduleReminder(interval: ReminderInterval) async
    func scheduleScanCompletionNotification(candidateCount: Int) async
    func scheduleTrashExpirationWarning(photos: [TrashPhoto]) async
    func cancelAllNotifications()
    func cancelNotification(identifier: String)
}
```

### 3.2 NotificationContentBuilder
```swift
// Services/NotificationContentBuilder.swift
struct NotificationContentBuilder {
    static func storageAlert(usagePercentage: Double, reclaimable: Int64) -> UNNotificationContent
    static func reminder() -> UNNotificationContent
    static func scanCompletion(candidateCount: Int, reclaimableSize: Int64) -> UNNotificationContent
    static func trashExpiration(count: Int) -> UNNotificationContent
}
```

### 3.3 StorageMonitor
```swift
// Services/StorageMonitor.swift
final class StorageMonitor {
    func startMonitoring()
    func stopMonitoring()
    func checkStorageStatus() async -> StorageStatus
}

enum StorageStatus {
    case normal
    case warning(usagePercentage: Double)
    case critical(usagePercentage: Double)
}
```

---

## 4. 通知内容

### 4.1 空き容量警告
```
┌─────────────────────────────────────────┐
│ 📱 LightRoll Cleaner                    │
├─────────────────────────────────────────┤
│ ストレージがいっぱいです                │
│                                         │
│ 端末の空き容量が残り10%です。           │
│ 約3.2GBの容量を解放できます。           │
│ 今すぐクリーンアップしましょう。        │
│                                         │
│ [今すぐ確認]  [後で]                    │
└─────────────────────────────────────────┘
```

### 4.2 定期リマインド
```
┌─────────────────────────────────────────┐
│ 📱 LightRoll Cleaner                    │
├─────────────────────────────────────────┤
│ 写真の整理はいかがですか？              │
│                                         │
│ 前回のクリーンアップから1週間が経過     │
│ しました。新しい不要な写真があるかも    │
│ しれません。                            │
│                                         │
│ [スキャンする]  [スキップ]              │
└─────────────────────────────────────────┘
```

---

## 5. ディレクトリ構造

```
src/modules/Notifications/
├── Services/
│   ├── NotificationManager.swift
│   ├── NotificationContentBuilder.swift
│   ├── StorageMonitor.swift
│   └── NotificationScheduler.swift
├── Models/
│   ├── NotificationSettings.swift
│   └── NotificationType.swift
├── Handlers/
│   └── NotificationDelegate.swift
└── Extensions/
    └── UNNotificationContent+Extensions.swift
```

---

## 6. タスク一覧

| タスクID | タスク名 | 説明 | 見積 | 依存 |
|----------|----------|------|------|------|
| M7-T01 | NotificationSettingsモデル | 通知設定モデル | 1h | M1-T08 |
| M7-T02 | Info.plist権限設定 | 通知権限の設定 | 0.5h | M1-T01 |
| M7-T03 | NotificationManager基盤 | 通知管理の基本実装 | 2h | M7-T02 |
| M7-T04 | 権限リクエスト実装 | 通知許可のリクエスト | 1h | M7-T03 |
| M7-T05 | NotificationContentBuilder | 通知コンテンツ生成 | 1.5h | M7-T03 |
| M7-T06 | 空き容量警告通知 | ストレージ監視と通知 | 2h | M7-T05,M2-T08 |
| M7-T07 | StorageMonitor実装 | 容量監視サービス | 2h | M2-T08 |
| M7-T08 | 定期リマインド実装 | スケジュール通知 | 1.5h | M7-T05 |
| M7-T09 | スキャン完了通知 | バックグラウンド処理通知 | 1h | M7-T05 |
| M7-T10 | ゴミ箱期限警告 | 期限切れ前通知 | 1h | M7-T05,M6-T03 |
| M7-T11 | NotificationDelegate実装 | 通知タップ時の処理 | 1.5h | M7-T03 |
| M7-T12 | 設定画面連携 | 通知設定のUI連携 | 1h | M8-T08 |
| M7-T13 | 単体テスト作成 | Notification機能テスト | 1.5h | M7-T11 |

---

## 7. テストケース

### M7-T04: 権限リクエスト実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M7-T04-TC01 | 初回権限リクエスト | ダイアログ表示 |
| M7-T04-TC02 | 許可済み状態の確認 | true返却 |
| M7-T04-TC03 | 拒否時の設定誘導 | 設定画面への案内 |

### M7-T06: 空き容量警告通知
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M7-T06-TC01 | 90%超過時の通知 | 通知がスケジュール |
| M7-T06-TC02 | 閾値未満時 | 通知されない |
| M7-T06-TC03 | 通知タップ時 | アプリが開く |

### M7-T08: 定期リマインド実装
| テストケースID | テスト内容 | 期待結果 |
|----------------|------------|----------|
| M7-T08-TC01 | 週次リマインド設定 | 毎週同時刻に通知 |
| M7-T08-TC02 | 静寂時間帯のスキップ | 時間外に延期 |
| M7-T08-TC03 | リマインド無効化 | 通知がキャンセル |

---

## 8. 受け入れ条件

- [ ] 通知権限が正しくリクエストされる
- [ ] 空き容量警告が閾値で発火する
- [ ] 定期リマインドが設定周期で届く
- [ ] バックグラウンドスキャン完了が通知される
- [ ] 静寂時間帯の設定が尊重される
- [ ] 通知タップでアプリが適切な画面で開く

---

## 9. 技術的考慮事項

### 9.1 UNUserNotificationCenter
```swift
// 通知スケジュール例
let content = UNMutableNotificationContent()
content.title = "ストレージがいっぱいです"
content.body = "約3.2GBの容量を解放できます"
content.sound = .default
content.badge = 1

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: 60,
    repeats: false
)

let request = UNNotificationRequest(
    identifier: "storage_alert",
    content: content,
    trigger: trigger
)

UNUserNotificationCenter.current().add(request)
```

### 9.2 バックグラウンド処理
- BGTaskSchedulerとの連携
- バッテリー消費への配慮
- サイレントプッシュは使用しない

### 9.3 ユーザー体験
- 過度な通知を避ける
- 静寂時間帯の尊重
- 通知の重複防止

---

*最終更新: 2025-11-27*
