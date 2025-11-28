//
//  BackgroundScanManager.swift
//  LightRoll_CleanerFeature
//
//  BGTaskSchedulerを使用したバックグラウンド写真スキャン機能
//  バックグラウンドでの定期的な写真スキャンをスケジューリング・管理する
//  Created by AI Assistant
//

import Foundation

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

// MARK: - BackgroundScanError

/// バックグラウンドスキャン関連のエラー
public enum BackgroundScanError: Error, LocalizedError, Equatable {
    /// タスク登録に失敗
    case taskRegistrationFailed

    /// スケジューリングに失敗
    case schedulingFailed(underlying: String)

    /// バックグラウンドスキャンが無効
    case backgroundScanDisabled

    /// 権限が不十分
    case insufficientPermissions

    /// プラットフォーム非対応
    case platformNotSupported

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .taskRegistrationFailed:
            return NSLocalizedString(
                "error.backgroundScan.registrationFailed",
                value: "バックグラウンドタスクの登録に失敗しました",
                comment: "Task registration failed error"
            )
        case .schedulingFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "error.backgroundScan.schedulingFailed",
                    value: "スケジューリングに失敗しました: %@",
                    comment: "Scheduling failed error"
                ),
                underlying
            )
        case .backgroundScanDisabled:
            return NSLocalizedString(
                "error.backgroundScan.disabled",
                value: "バックグラウンドスキャンが無効です",
                comment: "Background scan disabled error"
            )
        case .insufficientPermissions:
            return NSLocalizedString(
                "error.backgroundScan.insufficientPermissions",
                value: "写真ライブラリへのアクセス権限がありません",
                comment: "Insufficient permissions error"
            )
        case .platformNotSupported:
            return NSLocalizedString(
                "error.backgroundScan.platformNotSupported",
                value: "このプラットフォームではバックグラウンドスキャンはサポートされていません",
                comment: "Platform not supported error"
            )
        }
    }
}

// MARK: - BackgroundTaskHandlerProtocol

/// バックグラウンドタスクハンドラープロトコル
/// バックグラウンドでの実際の処理を抽象化
public protocol BackgroundTaskHandlerProtocol: Sendable {
    /// バックグラウンドリフレッシュ処理（短時間）
    func handleBackgroundRefresh() async

    /// バックグラウンド処理タスク（長時間）
    func handleBackgroundProcessing() async
}

// MARK: - BackgroundScanManagerProtocol

/// バックグラウンドスキャンマネージャーのプロトコル
/// テスタビリティのための抽象化
public protocol BackgroundScanManagerProtocol: AnyObject, Sendable {
    /// バックグラウンドタスク識別子（リフレッシュ用）
    static var backgroundRefreshTaskIdentifier: String { get }

    /// バックグラウンドタスク識別子（処理用）
    static var backgroundProcessingTaskIdentifier: String { get }

    /// バックグラウンドスキャンが有効かどうか
    var isBackgroundScanEnabled: Bool { get set }

    /// スキャン間隔（秒）
    var scanInterval: TimeInterval { get set }

    /// 次回スケジュール日時
    var nextScheduledScanDate: Date? { get }

    /// タスクを登録
    func registerBackgroundTasks()

    /// バックグラウンドスキャンをスケジュール
    func scheduleBackgroundScan() throws

    /// バックグラウンド処理タスクをスケジュール
    func scheduleBackgroundProcessing() throws

    /// スケジュールをキャンセル
    func cancelScheduledTasks()
}

// MARK: - BackgroundScanManager

/// バックグラウンドスキャンマネージャー
/// BGTaskSchedulerを使用してバックグラウンドでの写真スキャンを管理する
///
/// 使用方法:
/// 1. AppDelegate/App初期化時に `registerBackgroundTasks()` を呼び出す
/// 2. アプリがバックグラウンドに移行する際に `scheduleBackgroundScan()` を呼び出す
///
/// Info.plist設定（手動追加が必要）:
/// ```xml
/// <key>BGTaskSchedulerPermittedIdentifiers</key>
/// <array>
///     <string>com.lightroll.backgroundRefresh</string>
///     <string>com.lightroll.backgroundProcessing</string>
/// </array>
/// ```
///
/// また、UIBackgroundModesも設定が必要:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///     <string>fetch</string>
///     <string>processing</string>
/// </array>
/// ```
public final class BackgroundScanManager: BackgroundScanManagerProtocol, @unchecked Sendable {

    // MARK: - Static Properties

    /// バックグラウンドリフレッシュタスク識別子
    /// 短時間のバックグラウンドリフレッシュ（約30秒）に使用
    public static let backgroundRefreshTaskIdentifier = "com.lightroll.backgroundRefresh"

    /// バックグラウンド処理タスク識別子
    /// 長時間のバックグラウンド処理（最大数分）に使用
    public static let backgroundProcessingTaskIdentifier = "com.lightroll.backgroundProcessing"

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let isBackgroundScanEnabled = "BackgroundScanManager.isEnabled"
        static let scanInterval = "BackgroundScanManager.scanInterval"
        static let nextScheduledScanDate = "BackgroundScanManager.nextScheduledDate"
    }

    // MARK: - Properties

    /// シングルトンインスタンス
    public static let shared = BackgroundScanManager()

    /// ロック用
    private let lock = NSLock()

    /// UserDefaults
    private let userDefaults: UserDefaults

    /// タスクハンドラー
    private var taskHandler: BackgroundTaskHandlerProtocol?

    /// タスク登録済みフラグ
    private var isTasksRegistered: Bool = false

    /// バックグラウンドスキャンが有効かどうか
    public var isBackgroundScanEnabled: Bool {
        get {
            lock.withLock {
                userDefaults.bool(forKey: UserDefaultsKeys.isBackgroundScanEnabled)
            }
        }
        set {
            lock.withLock {
                userDefaults.set(newValue, forKey: UserDefaultsKeys.isBackgroundScanEnabled)
            }
            // 無効になった場合はスケジュールをキャンセル
            if !newValue {
                cancelScheduledTasks()
            }
        }
    }

    /// スキャン間隔（秒）
    /// デフォルト: 24時間（86400秒）
    public var scanInterval: TimeInterval {
        get {
            lock.withLock {
                let interval = userDefaults.double(forKey: UserDefaultsKeys.scanInterval)
                return interval > 0 ? interval : Self.defaultScanInterval
            }
        }
        set {
            lock.withLock {
                let clampedValue = max(Self.minimumScanInterval, min(Self.maximumScanInterval, newValue))
                userDefaults.set(clampedValue, forKey: UserDefaultsKeys.scanInterval)
            }
        }
    }

    /// 次回スケジュール日時
    public var nextScheduledScanDate: Date? {
        get {
            lock.withLock {
                userDefaults.object(forKey: UserDefaultsKeys.nextScheduledScanDate) as? Date
            }
        }
    }

    /// 次回スケジュール日時を設定（内部用）
    private func setNextScheduledScanDate(_ date: Date?) {
        lock.withLock {
            if let date = date {
                userDefaults.set(date, forKey: UserDefaultsKeys.nextScheduledScanDate)
            } else {
                userDefaults.removeObject(forKey: UserDefaultsKeys.nextScheduledScanDate)
            }
        }
    }

    // MARK: - Constants

    /// デフォルトのスキャン間隔（24時間）
    public static let defaultScanInterval: TimeInterval = 24 * 60 * 60

    /// 最小スキャン間隔（1時間）
    public static let minimumScanInterval: TimeInterval = 1 * 60 * 60

    /// 最大スキャン間隔（7日）
    public static let maximumScanInterval: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - userDefaults: 設定を保存するUserDefaults
    ///   - taskHandler: バックグラウンドタスクハンドラー
    public init(
        userDefaults: UserDefaults = .standard,
        taskHandler: BackgroundTaskHandlerProtocol? = nil
    ) {
        self.userDefaults = userDefaults
        self.taskHandler = taskHandler
    }

    /// タスクハンドラーを設定
    /// - Parameter handler: バックグラウンドタスクハンドラー
    public func setTaskHandler(_ handler: BackgroundTaskHandlerProtocol) {
        lock.withLock {
            self.taskHandler = handler
        }
    }

    // MARK: - Task Registration

    /// バックグラウンドタスクを登録
    /// AppDelegate/App初期化時に呼び出す必要がある
    ///
    /// 注意: この関数はアプリ起動時に一度だけ呼び出す必要がある
    /// BGTaskSchedulerへのタスク登録はアプリ起動後すぐに行う必要がある
    public func registerBackgroundTasks() {
        guard !isTasksRegistered else { return }

        #if os(iOS) || os(tvOS)
        #if targetEnvironment(simulator)
        // シミュレータではBGTaskSchedulerが利用できないため、
        // 登録のみ行い実際のスケジューリングはスキップ
        isTasksRegistered = true
        return
        #else
        // バックグラウンドリフレッシュタスクの登録
        let refreshRegistered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundRefreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleAppRefreshTask(task)
        }

        // バックグラウンド処理タスクの登録
        let processingRegistered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundProcessingTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGProcessingTask else { return }
            self?.handleProcessingTask(task)
        }

        isTasksRegistered = refreshRegistered && processingRegistered
        #endif
        #else
        // macOS等ではBGTaskSchedulerが利用できない
        isTasksRegistered = true
        #endif
    }

    // MARK: - Scheduling

    /// バックグラウンドスキャンをスケジュール
    /// アプリがバックグラウンドに移行する際に呼び出す
    ///
    /// - Throws: BackgroundScanError
    public func scheduleBackgroundScan() throws {
        guard isBackgroundScanEnabled else {
            throw BackgroundScanError.backgroundScanDisabled
        }

        #if os(iOS) || os(tvOS)
        #if targetEnvironment(simulator)
        // シミュレータではスケジューリングをスキップ
        let nextDate = Date().addingTimeInterval(scanInterval)
        setNextScheduledScanDate(nextDate)
        return
        #else
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: scanInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            setNextScheduledScanDate(request.earliestBeginDate)
        } catch {
            throw BackgroundScanError.schedulingFailed(underlying: error.localizedDescription)
        }
        #endif
        #else
        // macOS等ではスケジューリング不可
        let nextDate = Date().addingTimeInterval(scanInterval)
        setNextScheduledScanDate(nextDate)
        #endif
    }

    /// バックグラウンド処理タスクをスケジュール
    /// 長時間の処理が必要な場合に使用
    ///
    /// - Throws: BackgroundScanError
    public func scheduleBackgroundProcessing() throws {
        guard isBackgroundScanEnabled else {
            throw BackgroundScanError.backgroundScanDisabled
        }

        #if os(iOS) || os(tvOS)
        #if targetEnvironment(simulator)
        // シミュレータではスケジューリングをスキップ
        let nextDate = Date().addingTimeInterval(scanInterval)
        setNextScheduledScanDate(nextDate)
        return
        #else
        let request = BGProcessingTaskRequest(identifier: Self.backgroundProcessingTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: scanInterval)
        // 電源接続時のみ実行（バッテリー消費を抑制）
        request.requiresExternalPower = false
        // ネットワーク接続は不要（ローカル処理のみ）
        request.requiresNetworkConnectivity = false

        do {
            try BGTaskScheduler.shared.submit(request)
            setNextScheduledScanDate(request.earliestBeginDate)
        } catch {
            throw BackgroundScanError.schedulingFailed(underlying: error.localizedDescription)
        }
        #endif
        #else
        // macOS等ではスケジューリング不可
        let nextDate = Date().addingTimeInterval(scanInterval)
        setNextScheduledScanDate(nextDate)
        #endif
    }

    /// スケジュールされたタスクをキャンセル
    public func cancelScheduledTasks() {
        #if os(iOS) || os(tvOS)
        #if !targetEnvironment(simulator)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundRefreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundProcessingTaskIdentifier)
        #endif
        #endif
        setNextScheduledScanDate(nil)
    }

    // MARK: - Task Handlers (iOS/tvOS only)

    #if os(iOS) || os(tvOS)
    /// バックグラウンドリフレッシュタスクを処理
    private func handleAppRefreshTask(_ task: BGAppRefreshTask) {
        // 次回のスキャンをスケジュール
        try? scheduleBackgroundScan()

        // タスクの期限切れハンドラを設定
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // ハンドラーが設定されている場合は処理を実行
        if let handler = taskHandler {
            // BGTaskはSendableではないため、nonisolated(unsafe)で明示的にキャプチャ
            nonisolated(unsafe) let bgTask = task
            let sendableHandler = handler
            Task.detached { @Sendable in
                await sendableHandler.handleBackgroundRefresh()
                bgTask.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: true)
        }
    }

    /// バックグラウンド処理タスクを処理
    private func handleProcessingTask(_ task: BGProcessingTask) {
        // 次回のスキャンをスケジュール
        try? scheduleBackgroundProcessing()

        // タスクの期限切れハンドラを設定
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // ハンドラーが設定されている場合は処理を実行
        if let handler = taskHandler {
            // BGTaskはSendableではないため、nonisolated(unsafe)で明示的にキャプチャ
            nonisolated(unsafe) let bgTask = task
            let sendableHandler = handler
            Task.detached { @Sendable in
                await sendableHandler.handleBackgroundProcessing()
                bgTask.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: true)
        }
    }
    #endif
}

// MARK: - BackgroundScanManager + Debug

extension BackgroundScanManager {

    /// デバッグ用: バックグラウンドタスクをシミュレート
    /// Xcodeのデバッグコンソールから以下のコマンドで実行可能:
    /// `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.lightroll.backgroundRefresh"]`
    /// `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.lightroll.backgroundProcessing"]`
    public func debugPrintStatus() {
        print("""
        === BackgroundScanManager Status ===
        Enabled: \(isBackgroundScanEnabled)
        Scan Interval: \(scanInterval / 3600) hours
        Next Scheduled: \(nextScheduledScanDate?.description ?? "None")
        Tasks Registered: \(isTasksRegistered)
        Refresh Task ID: \(Self.backgroundRefreshTaskIdentifier)
        Processing Task ID: \(Self.backgroundProcessingTaskIdentifier)
        =====================================
        """)
    }
}

// MARK: - DefaultBackgroundTaskHandler

/// デフォルトのバックグラウンドタスクハンドラー
/// PhotoScannerとStorageServiceを使用してバックグラウンドスキャンを実行
public final class DefaultBackgroundTaskHandler: BackgroundTaskHandlerProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// PhotoScanner生成クロージャ
    private let photoScannerFactory: @Sendable () async -> PhotoScanner?

    /// StorageService生成クロージャ
    private let storageServiceFactory: @Sendable () async -> StorageServiceProtocol?

    /// 完了通知を送信するか
    private let sendCompletionNotification: Bool

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - photoScannerFactory: PhotoScanner生成クロージャ
    ///   - storageServiceFactory: StorageService生成クロージャ
    ///   - sendCompletionNotification: 完了通知を送信するか
    public init(
        photoScannerFactory: @escaping @Sendable () async -> PhotoScanner?,
        storageServiceFactory: @escaping @Sendable () async -> StorageServiceProtocol?,
        sendCompletionNotification: Bool = true
    ) {
        self.photoScannerFactory = photoScannerFactory
        self.storageServiceFactory = storageServiceFactory
        self.sendCompletionNotification = sendCompletionNotification
    }

    // MARK: - BackgroundTaskHandlerProtocol

    /// バックグラウンドリフレッシュ処理
    /// 短時間で完了する処理を実行（ストレージ情報の更新など）
    public func handleBackgroundRefresh() async {
        // ストレージ情報を更新
        guard let storageService = await storageServiceFactory() else { return }

        do {
            _ = try await storageService.getDeviceStorageInfo()

            // 完了通知（将来的にNotificationCenterと連携）
            if sendCompletionNotification {
                await postBackgroundRefreshCompletedNotification()
            }
        } catch {
            // エラーはログに記録（バックグラウンドなのでUIには表示しない）
            print("Background refresh failed: \(error.localizedDescription)")
        }
    }

    /// バックグラウンド処理タスク
    /// 長時間の処理を実行（写真スキャンなど）
    public func handleBackgroundProcessing() async {
        guard let photoScanner = await photoScannerFactory() else { return }

        do {
            // バックグラウンドでスキャンを実行
            let photos = try await photoScanner.scan()

            // 完了通知
            if sendCompletionNotification {
                await postBackgroundProcessingCompletedNotification(photoCount: photos.count)
            }
        } catch {
            // エラーはログに記録
            print("Background processing failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notifications

    /// バックグラウンドリフレッシュ完了通知を投稿
    @MainActor
    private func postBackgroundRefreshCompletedNotification() {
        NotificationCenter.default.post(
            name: .backgroundRefreshCompleted,
            object: nil
        )
    }

    /// バックグラウンド処理完了通知を投稿
    @MainActor
    private func postBackgroundProcessingCompletedNotification(photoCount: Int) {
        NotificationCenter.default.post(
            name: .backgroundProcessingCompleted,
            object: nil,
            userInfo: ["photoCount": photoCount]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// バックグラウンドリフレッシュ完了通知
    public static let backgroundRefreshCompleted = Notification.Name("BackgroundRefreshCompleted")

    /// バックグラウンド処理完了通知
    public static let backgroundProcessingCompleted = Notification.Name("BackgroundProcessingCompleted")
}
