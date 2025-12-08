//
//  NotificationPermissionView.swift
//  LightRoll_CleanerFeature
//
//  通知権限リクエストビュー
//  - NotificationManagerを使用した権限リクエストフロー
//  - ユーザーフレンドリーな許可ダイアログ表示
//  - 権限状態に応じたUI制御（未確認/許可/拒否）
//  - 拒否時の適切なフィードバック
//  MV Pattern: @Observable + @State で状態管理
//  Created by AI Assistant for M7-T04
//

import SwiftUI
import UserNotifications

// MARK: - NotificationPermissionView

/// 通知権限リクエストビュー
///
/// MV Patternに従い、ViewModelではなく@Stateと@Environmentで状態管理
/// - NotificationManagerを@Environment経由で注入
/// - 画面状態は@Stateで管理
/// - .task modifierで非同期処理
@MainActor
public struct NotificationPermissionView: View {

    // MARK: - Environment

    /// 通知マネージャー（@Environment経由で注入）
    @Environment(NotificationManager.self) private var notificationManager

    // MARK: - State

    /// 画面状態
    @State private var viewState: ViewState = .loading

    /// 権限ステータス
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// リクエスト中フラグ
    @State private var isRequesting = false

    /// エラーアラート表示フラグ
    @State private var showingError = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    /// 設定画面への誘導アラート表示フラグ
    @State private var showingSettingsAlert = false

    // MARK: - ViewState

    /// 画面状態の列挙型
    enum ViewState: Equatable {
        /// 読み込み中
        case loading

        /// 読み込み完了
        case loaded

        /// エラー
        case error(String)
    }

    // MARK: - Initialization

    /// イニシャライザ
    public init() {}

    // MARK: - Body

    public var body: some View {
        Group {
            switch viewState {
            case .loading:
                loadingView
            case .loaded:
                contentView
            case .error(let message):
                errorView(message: message)
            }
        }
        .navigationTitle("通知設定")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadAuthorizationStatus()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("通知を許可してください", isPresented: $showingSettingsAlert) {
            Button("設定を開く") {
                openSettings()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("通知が拒否されています。設定アプリから通知を許可してください。")
        }
    }

    // MARK: - Subviews

    /// 読み込み中ビュー
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("通知権限を確認中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// メインコンテンツビュー
    private var contentView: some View {
        List {
            statusSection
            benefitsSection
            actionSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.automatic)
        #endif
    }

    /// エラービュー
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("読み込みエラー", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("再試行") {
                Task {
                    await loadAuthorizationStatus()
                }
            }
        }
    }

    /// ステータスセクション
    private var statusSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: statusIcon)
                    .font(.system(size: 48))
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("通知の状態")
                        .font(.headline)

                    Text(statusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    /// メリットセクション
    private var benefitsSection: some View {
        Section {
            benefitRow(
                icon: "photo.badge.checkmark",
                title: "スキャン完了通知",
                description: "バックグラウンドでのスキャンが完了すると通知でお知らせします。"
            )

            benefitRow(
                icon: "externaldrive.badge.exclamationmark",
                title: "ストレージ警告",
                description: "端末の空き容量が少なくなったときに通知でお知らせします。"
            )

            benefitRow(
                icon: "calendar.badge.clock",
                title: "定期リマインダー",
                description: "写真の整理を定期的にリマインドします。"
            )

            benefitRow(
                icon: "trash.circle",
                title: "ゴミ箱期限警告",
                description: "ゴミ箱の写真が自動削除される前に通知でお知らせします。"
            )
        } header: {
            Text("通知を許可するメリット")
        } footer: {
            Text("通知は後から設定で変更できます。")
        }
    }

    /// アクションセクション
    private var actionSection: some View {
        Section {
            if isRequesting {
                HStack {
                    Spacer()
                    ProgressView()
                    Text("処理中...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                switch authorizationStatus {
                case .notDetermined:
                    requestButton

                case .denied:
                    deniedMessageView
                    openSettingsButton

                case .authorized, .provisional, .ephemeral:
                    authorizedMessageView

                @unknown default:
                    unknownStatusView
                }
            }
        }
    }

    /// リクエストボタン
    private var requestButton: some View {
        Button {
            Task {
                await requestPermission()
            }
        } label: {
            HStack {
                Spacer()
                Image(systemName: "bell.badge.fill")
                Text("通知を許可する")
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }

    /// 拒否時メッセージビュー
    private var deniedMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("通知が拒否されています")
                    .font(.headline)
            }

            Text("通知を有効にするには、設定アプリから許可してください。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    /// 設定を開くボタン
    private var openSettingsButton: some View {
        Button {
            showingSettingsAlert = true
        } label: {
            HStack {
                Spacer()
                Image(systemName: "gear")
                Text("設定を開く")
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
    }

    /// 許可済みメッセージビュー
    private var authorizedMessageView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)

            Text("通知が許可されています")
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    /// 不明な状態ビュー
    private var unknownStatusView: some View {
        Text("不明な権限状態です")
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }

    /// メリット行ビュー
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Properties

    /// ステータスアイコン
    private var statusIcon: String {
        switch authorizationStatus {
        case .notDetermined:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .authorized, .provisional:
            return "bell.fill"
        case .ephemeral:
            return "bell.circle.fill"
        @unknown default:
            return "bell"
        }
    }

    /// ステータス色
    private var statusColor: Color {
        switch authorizationStatus {
        case .notDetermined:
            return .secondary
        case .denied:
            return .red
        case .authorized, .provisional, .ephemeral:
            return .green
        @unknown default:
            return .secondary
        }
    }

    /// ステータス説明
    private var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "通知の許可が未設定です"
        case .denied:
            return "通知が拒否されています"
        case .authorized:
            return "通知が許可されています"
        case .provisional:
            return "静かな通知が許可されています"
        case .ephemeral:
            return "一時的な通知が許可されています"
        @unknown default:
            return "不明な権限状態です"
        }
    }

    // MARK: - Actions

    /// 権限ステータスを読み込み
    private func loadAuthorizationStatus() async {
        viewState = .loading

        do {
            await notificationManager.updateAuthorizationStatus()
            authorizationStatus = notificationManager.authorizationStatus
            viewState = .loaded
        } catch {
            viewState = .error("権限ステータスの取得に失敗しました")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    /// 権限をリクエスト
    private func requestPermission() async {
        guard !isRequesting else { return }
        guard authorizationStatus == .notDetermined else { return }

        isRequesting = true
        defer { isRequesting = false }

        do {
            let granted = try await notificationManager.requestPermission()

            if granted {
                // 成功時は状態を再読み込み
                await loadAuthorizationStatus()
            } else {
                // 拒否時はアラート表示
                showingSettingsAlert = true
            }
        } catch {
            errorMessage = "通知権限のリクエストに失敗しました"
            showingError = true
        }
    }

    /// 設定アプリを開く
    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Preview

#Preview("未確認") {
    NavigationStack {
        NotificationPermissionView()
            .environment(NotificationManager(
                notificationCenter: PreviewNotificationCenter(status: .notDetermined)
            ))
    }
}

#Preview("許可済み") {
    NavigationStack {
        NotificationPermissionView()
            .environment(NotificationManager(
                notificationCenter: PreviewNotificationCenter(status: .authorized)
            ))
    }
}

#Preview("拒否") {
    NavigationStack {
        NotificationPermissionView()
            .environment(NotificationManager(
                notificationCenter: PreviewNotificationCenter(status: .denied)
            ))
    }
}

// MARK: - Preview Helpers

/// プレビュー用通知センター
private struct PreviewNotificationCenter: UserNotificationCenterProtocol {
    let status: UNAuthorizationStatus
    var shouldGrantPermission: Bool = true

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return shouldGrantPermission
    }

    func add(_ request: UNNotificationRequest) async throws {
        // プレビュー用の空実装
    }

    func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return []
    }

    func removeAllPendingNotificationRequests() async {
        // プレビュー用の空実装
    }

    func removePendingNotificationRequests(withIdentifiers: [String]) async {
        // プレビュー用の空実装
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return []
    }

    func removeAllDeliveredNotifications() async {
        // プレビュー用の空実装
    }
}
