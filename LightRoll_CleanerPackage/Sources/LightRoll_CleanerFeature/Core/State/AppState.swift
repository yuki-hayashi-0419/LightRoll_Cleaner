//
//  AppState.swift
//  LightRoll_CleanerFeature
//
//  アプリケーション全体の状態管理
//  シングルトンパターンで全体の状態を一元管理
//  Created by AI Assistant
//

import SwiftUI
import Combine

// MARK: - AppState

/// アプリケーション状態管理
/// アプリ全体の状態を一元管理するObservableObject
@MainActor
public final class AppState: ObservableObject {

    // MARK: - Singleton

    /// 共有インスタンス
    public static let shared = AppState()

    // MARK: - Navigation State

    /// 現在選択中のタブ
    @Published public var currentTab: Tab = .dashboard

    /// ナビゲーションパス（NavigationStack用）
    @Published public var navigationPath: NavigationPath = NavigationPath()

    /// モーダルで表示中の遷移先
    @Published public var presentedDestination: NavigationDestination?

    // MARK: - Scan State

    /// スキャン中フラグ
    @Published public var isScanning: Bool = false

    /// スキャン進捗
    @Published public var scanProgress: ScanProgress = .initial

    /// 最後のスキャン日時
    @Published public var lastScanDate: Date?

    /// 最新のスキャン結果
    @Published public var scanResult: ScanResult?

    // MARK: - Photo State

    /// 写真グループ一覧
    @Published public var photoGroups: [PhotoGroup] = []

    /// 選択中の写真ID一覧
    @Published public var selectedPhotos: Set<String> = []

    /// 写真の総数
    @Published public var totalPhotosCount: Int = 0

    // MARK: - Storage State

    /// ストレージ情報
    @Published public var storageInfo: StorageInfo?

    /// 削減可能な容量（バイト）
    @Published public var potentialSavings: Int64 = 0

    // MARK: - UI State

    /// ローディング中フラグ
    @Published public var isLoading: Bool = false

    /// エラーメッセージ
    @Published public var errorMessage: String?

    /// 削除確認ダイアログ表示フラグ
    @Published public var showingDeleteConfirmation: Bool = false

    /// 削除確認のコンテキスト
    @Published public var deleteConfirmationContext: DeleteConfirmationContext?

    /// トースト表示用メッセージ
    @Published public var toastMessage: String?

    /// アラート表示フラグ
    @Published public var showingAlert: Bool = false

    /// アラートのタイトル
    @Published public var alertTitle: String = ""

    /// アラートのメッセージ
    @Published public var alertMessage: String = ""

    // MARK: - Premium State

    /// プレミアムユーザーフラグ
    @Published public var isPremium: Bool = false

    /// 本日の削除件数（無料ユーザー向け制限用）
    @Published public var todayDeleteCount: Int = 0

    /// プレミアムアップグレード画面表示フラグ
    @Published public var showingPremiumUpgrade: Bool = false

    // MARK: - Permission State

    /// 写真ライブラリアクセス権限
    @Published public var photoPermissionGranted: Bool = false

    /// 通知権限
    @Published public var notificationPermissionGranted: Bool = false

    // MARK: - Initialization

    private init() {
        // シングルトンのためprivate
        loadPersistedState()
    }

    /// テスト用イニシャライザ
    #if DEBUG
    public init(forTesting: Bool) {
        // テスト用は永続化を読み込まない
    }
    #endif

    // MARK: - State Persistence

    /// 永続化された状態を読み込み
    private func loadPersistedState() {
        if let lastScanDateData = UserDefaults.standard.object(forKey: "lastScanDate") as? Date {
            lastScanDate = lastScanDateData
        }

        isPremium = UserDefaults.standard.bool(forKey: "isPremium")

        // 本日の削除カウントをリセット（日付が変わっていたら）
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDeleteDate = UserDefaults.standard.object(forKey: "lastDeleteDate") as? Date {
            let lastDeleteDay = Calendar.current.startOfDay(for: lastDeleteDate)
            if today > lastDeleteDay {
                todayDeleteCount = 0
                UserDefaults.standard.set(0, forKey: "todayDeleteCount")
            } else {
                todayDeleteCount = UserDefaults.standard.integer(forKey: "todayDeleteCount")
            }
        }
    }

    /// 状態を永続化
    private func persistState() {
        if let lastScanDate = lastScanDate {
            UserDefaults.standard.set(lastScanDate, forKey: "lastScanDate")
        }
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        UserDefaults.standard.set(todayDeleteCount, forKey: "todayDeleteCount")
        UserDefaults.standard.set(Date(), forKey: "lastDeleteDate")
    }

    // MARK: - Navigation Actions

    /// 指定した遷移先に移動
    /// - Parameter destination: 遷移先
    public func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }

    /// 一つ前の画面に戻る
    public func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    /// ナビゲーションをルートまで戻す
    public func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    /// タブを切り替え
    /// - Parameter tab: 切り替え先のタブ
    public func switchTab(to tab: Tab) {
        currentTab = tab
    }

    /// モーダルを表示
    /// - Parameter destination: 表示する遷移先
    public func present(_ destination: NavigationDestination) {
        presentedDestination = destination
    }

    /// モーダルを閉じる
    public func dismiss() {
        presentedDestination = nil
    }

    // MARK: - Scan Actions

    /// スキャンを開始
    public func startScan() {
        isScanning = true
        scanProgress = .initial
        errorMessage = nil
    }

    /// スキャン進捗を更新
    /// - Parameter progress: 新しい進捗状態
    public func updateScanProgress(_ progress: ScanProgress) {
        scanProgress = progress
    }

    /// スキャンを完了
    /// - Parameter result: スキャン結果
    public func completeScan(result: ScanResult) {
        isScanning = false
        scanProgress = .completed
        scanResult = result
        lastScanDate = result.timestamp
        potentialSavings = result.potentialSavings
        persistState()
    }

    /// スキャンをキャンセル
    public func cancelScan() {
        isScanning = false
        scanProgress = .initial
    }

    /// スキャンエラーを設定
    /// - Parameter error: エラー
    public func setScanError(_ error: Error) {
        isScanning = false
        scanProgress = ScanProgress(phase: .error)
        errorMessage = error.localizedDescription
    }

    // MARK: - Photo Selection Actions

    /// 写真を選択
    /// - Parameter id: 写真ID
    public func selectPhoto(_ id: String) {
        selectedPhotos.insert(id)
    }

    /// 写真の選択を解除
    /// - Parameter id: 写真ID
    public func deselectPhoto(_ id: String) {
        selectedPhotos.remove(id)
    }

    /// 写真の選択状態をトグル
    /// - Parameter id: 写真ID
    public func togglePhotoSelection(_ id: String) {
        if selectedPhotos.contains(id) {
            selectedPhotos.remove(id)
        } else {
            selectedPhotos.insert(id)
        }
    }

    /// 全選択をクリア
    public func clearSelection() {
        selectedPhotos.removeAll()
    }

    /// 全ての写真を選択
    /// - Parameter ids: 選択する写真IDの配列
    public func selectAllPhotos(_ ids: [String]) {
        selectedPhotos = Set(ids)
    }

    // MARK: - Photo Group Actions

    /// グループを更新
    /// - Parameter groups: 新しいグループ配列
    public func updateGroups(_ groups: [PhotoGroup]) {
        photoGroups = groups
    }

    /// 指定したグループを削除
    /// - Parameter groupId: グループID
    public func removeGroup(_ groupId: UUID) {
        photoGroups.removeAll { $0.id == groupId }
    }

    // MARK: - Storage Actions

    /// ストレージ情報を更新
    /// - Parameter info: 新しいストレージ情報
    public func updateStorageInfo(_ info: StorageInfo) {
        storageInfo = info
    }

    // MARK: - Delete Actions

    /// 削除確認を表示
    /// - Parameter context: 削除確認のコンテキスト
    public func showDeleteConfirmation(context: DeleteConfirmationContext) {
        deleteConfirmationContext = context
        showingDeleteConfirmation = true
    }

    /// 削除確認を閉じる
    public func hideDeleteConfirmation() {
        showingDeleteConfirmation = false
        deleteConfirmationContext = nil
    }

    /// 削除件数を加算（無料ユーザー向け）
    /// - Parameter count: 削除した件数
    public func incrementDeleteCount(by count: Int) {
        todayDeleteCount += count
        persistState()
    }

    // MARK: - Alert Actions

    /// アラートを表示
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    public func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    /// アラートを閉じる
    public func hideAlert() {
        showingAlert = false
        alertTitle = ""
        alertMessage = ""
    }

    // MARK: - Toast Actions

    /// トーストを表示
    /// - Parameter message: メッセージ
    public func showToast(_ message: String) {
        toastMessage = message

        // 3秒後に自動で非表示
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    /// トーストを非表示
    public func hideToast() {
        toastMessage = nil
    }

    // MARK: - Error Actions

    /// エラーを設定
    /// - Parameter message: エラーメッセージ
    public func setError(_ message: String) {
        errorMessage = message
    }

    /// エラーをクリア
    public func clearError() {
        errorMessage = nil
    }

    // MARK: - Premium Actions

    /// プレミアムステータスを更新
    /// - Parameter isPremium: プレミアムかどうか
    public func updatePremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        persistState()
    }

    /// プレミアムアップグレード画面を表示
    public func showPremiumUpgrade() {
        showingPremiumUpgrade = true
    }

    /// プレミアムアップグレード画面を閉じる
    public func hidePremiumUpgrade() {
        showingPremiumUpgrade = false
    }

    // MARK: - Reset Actions

    /// 状態をリセット
    public func reset() {
        currentTab = .dashboard
        navigationPath = NavigationPath()
        presentedDestination = nil

        isScanning = false
        scanProgress = .initial
        scanResult = nil

        photoGroups = []
        selectedPhotos = []
        totalPhotosCount = 0

        storageInfo = nil
        potentialSavings = 0

        isLoading = false
        errorMessage = nil
        showingDeleteConfirmation = false
        deleteConfirmationContext = nil
        toastMessage = nil
        showingAlert = false
    }
}

// MARK: - Convenience Computed Properties

extension AppState {

    /// 選択中の写真数
    public var selectedPhotosCount: Int {
        selectedPhotos.count
    }

    /// 写真が選択されているか
    public var hasSelection: Bool {
        !selectedPhotos.isEmpty
    }

    /// 無料ユーザーの本日の残り削除可能数
    public var remainingFreeDeletes: Int {
        let limit = 20 // 無料ユーザーの1日の削除上限
        return max(0, limit - todayDeleteCount)
    }

    /// 無料ユーザーが削除上限に達しているか
    public var hasReachedFreeLimit: Bool {
        !isPremium && remainingFreeDeletes <= 0
    }

    /// 指定件数の削除が可能か
    /// - Parameter count: 削除予定件数
    /// - Returns: 削除可能かどうか
    public func canDelete(count: Int) -> Bool {
        isPremium || count <= remainingFreeDeletes
    }
}
