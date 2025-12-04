//
//  PermissionsView.swift
//  LightRoll_CleanerFeature
//
//  権限管理画面のSwiftUIビュー（MV Pattern）
//  ViewModelを使用せず、@Observableサービス + @State で状態管理
//  M8-T05 実装
//  Created by AI Assistant on 2025-12-05.
//

import SwiftUI
import Photos
import UserNotifications

// MARK: - PermissionsView

/// 権限管理画面
///
/// MV Patternに従い、ViewModelではなく@Stateと@Environmentで状態管理
/// - PermissionManagerを@Environment経由で注入
/// - 画面状態は@Stateで管理
/// - .task modifierで非同期処理
@MainActor
public struct PermissionsView: View {

    // MARK: - Environment

    /// 権限マネージャー（@Environment経由で注入）
    @Environment(PermissionManager.self) private var permissionManager

    // MARK: - State

    /// 画面状態
    @State private var viewState: ViewState = .loading

    /// 写真権限ステータス
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined

    /// 通知権限ステータス
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    /// エラーアラート表示フラグ
    @State private var showingError = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    /// リクエスト中フラグ
    @State private var isRequesting = false

    // MARK: - ViewState

    /// 画面状態の列挙型
    enum ViewState {
        /// 読み込み中
        case loading

        /// 読み込み完了
        case loaded

        /// エラー
        case error(String)
    }

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
        .navigationTitle("権限設定")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadPermissionStatuses()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    /// 読み込み中ビュー
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("権限状態を確認中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// メインコンテンツビュー
    private var contentView: some View {
        List {
            photoPermissionSection
            notificationPermissionSection
            settingsSection
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
                    await loadPermissionStatuses()
                }
            }
        }
    }

    /// 写真権限セクション
    private var photoPermissionSection: some View {
        Section {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("写真ライブラリ")
                        .font(.headline)

                    Text(photoStatusDescription)
                        .font(.caption)
                        .foregroundColor(photoStatusColor)
                }

                Spacer()

                photoActionButton
            }
            .padding(.vertical, 8)
        } header: {
            Text("必須権限")
        } footer: {
            Text("写真の分析と管理には、写真ライブラリへのアクセス権限が必要です。")
        }
    }

    /// 通知権限セクション
    private var notificationPermissionSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.orange)
                    .font(.title2)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("通知")
                        .font(.headline)

                    Text(notificationStatusDescription)
                        .font(.caption)
                        .foregroundColor(notificationStatusColor)
                }

                Spacer()

                notificationActionButton
            }
            .padding(.vertical, 8)
        } header: {
            Text("オプション権限")
        } footer: {
            Text("スキャン完了やストレージ警告の通知を受け取るには、通知権限が必要です。")
        }
    }

    /// 設定セクション
    private var settingsSection: some View {
        Section {
            Button {
                Task {
                    await permissionManager.openSettings()
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                    Text("システム設定を開く")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } footer: {
            Text("権限を変更するには、システム設定から行ってください。")
        }
    }

    /// 写真権限アクションボタン
    @ViewBuilder
    private var photoActionButton: some View {
        if isRequesting {
            ProgressView()
        } else {
            switch photoStatus {
            case .notDetermined:
                Button("許可する") {
                    Task {
                        await requestPhotoPermission()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)

            case .restricted, .denied:
                Button("設定を開く") {
                    Task {
                        await permissionManager.openSettings()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)

            case .authorized, .limited:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

            @unknown default:
                EmptyView()
            }
        }
    }

    /// 通知権限アクションボタン
    @ViewBuilder
    private var notificationActionButton: some View {
        if isRequesting {
            ProgressView()
        } else {
            switch notificationStatus {
            case .notDetermined:
                Button("許可する") {
                    Task {
                        await requestNotificationPermission()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)

            case .denied:
                Button("設定を開く") {
                    Task {
                        await permissionManager.openSettings()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)

            case .authorized, .provisional, .ephemeral:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Permission Status Descriptions

    /// 写真権限ステータスの説明文
    private var photoStatusDescription: String {
        switch photoStatus {
        case .notDetermined:
            return "未設定"
        case .restricted:
            return "制限されています"
        case .denied:
            return "拒否されています"
        case .authorized:
            return "すべての写真にアクセス可"
        case .limited:
            return "選択した写真のみアクセス可"
        @unknown default:
            return "不明"
        }
    }

    /// 通知権限ステータスの説明文
    private var notificationStatusDescription: String {
        notificationStatus.localizedDescription
    }

    /// 写真権限ステータスの色
    private var photoStatusColor: Color {
        switch photoStatus {
        case .notDetermined:
            return .secondary
        case .restricted, .denied:
            return .red
        case .authorized, .limited:
            return .green
        @unknown default:
            return .secondary
        }
    }

    /// 通知権限ステータスの色
    private var notificationStatusColor: Color {
        switch notificationStatus {
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

    // MARK: - Actions

    /// 権限ステータスを読み込み
    private func loadPermissionStatuses() async {
        viewState = .loading

        // 写真権限ステータスを取得
        photoStatus = permissionManager.getPhotoPermissionStatus()

        // 通知権限ステータスを取得
        notificationStatus = await permissionManager.getNotificationPermissionStatus()

        viewState = .loaded
    }

    /// 写真権限をリクエスト
    private func requestPhotoPermission() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        photoStatus = await permissionManager.requestPhotoPermission()
    }

    /// 通知権限をリクエスト
    private func requestNotificationPermission() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        _ = await permissionManager.requestNotificationPermission()
        // 権限ステータスを再取得
        notificationStatus = await permissionManager.getNotificationPermissionStatus()
    }
}

// MARK: - Preview

#Preview("すべて未設定") {
    NavigationStack {
        PermissionsView()
            .environment(PermissionManager(
                settingsOpener: PreviewSettingsOpener(),
                notificationCenter: PreviewNotificationCenter(status: .notDetermined)
            ))
    }
}

#Preview("写真拒否・通知許可") {
    NavigationStack {
        PermissionsView()
            .environment(PermissionManager(
                settingsOpener: PreviewSettingsOpener(),
                notificationCenter: PreviewNotificationCenter(status: .authorized)
            ))
    }
}

// MARK: - Preview Helpers

/// プレビュー用設定オープナー
private struct PreviewSettingsOpener: SettingsOpenerProtocol {
    func openSettings() {
        print("Settings opened (preview)")
    }
}

/// プレビュー用通知センター
private struct PreviewNotificationCenter: NotificationCenterProtocol {
    let status: UNAuthorizationStatus

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async -> Bool {
        return status == .authorized
    }
}
