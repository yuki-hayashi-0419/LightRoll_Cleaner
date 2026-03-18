//
//  SettingsView.swift
//  LightRoll_CleanerFeature
//
//  設定画面のメインビュー（MV Pattern）
//  ViewModelを使用せず、@Environment(SettingsService.self) で状態管理
//  M8-T07 実装
//  Created by AI Assistant on 2025-12-05.
//

import SwiftUI

// MARK: - SettingsView

/// 設定画面のメインビュー
///
/// MV Patternに従い、ViewModelではなく@Environment(SettingsService.self)で状態管理
/// - SettingsServiceを@Environment経由で注入
/// - 各設定セクションを表示
/// - NavigationStackで詳細画面へ遷移
@MainActor
public struct SettingsView: View {

    // MARK: - Environment

    /// 設定サービス（@Environment経由で注入）
    @Environment(SettingsService.self) private var settingsService

    /// 権限マネージャー（@Environment経由で注入）
    @Environment(PermissionManager.self) private var permissionManager

    /// プレミアムマネージャー（@Environment経由で注入）
    @Environment(PremiumManager.self) private var premiumManager

    /// ゴミ箱マネージャー（@Environment経由で注入）
    @Environment(TrashManager.self) private var trashManager

    /// 通知マネージャー（SETTINGS-002対応: NotificationSettingsViewに渡す）
    @Environment(NotificationManager.self) private var notificationManager

    // MARK: - Dependencies

    /// 写真削除ユースケース
    private let deletePhotosUseCase: DeletePhotosUseCase

    /// 写真復元ユースケース
    private let restorePhotosUseCase: RestorePhotosUseCase

    /// 削除確認サービス
    private let confirmationService: DeletionConfirmationService

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - deletePhotosUseCase: 写真削除ユースケース
    ///   - restorePhotosUseCase: 写真復元ユースケース
    ///   - confirmationService: 削除確認サービス
    public init(
        deletePhotosUseCase: DeletePhotosUseCase,
        restorePhotosUseCase: RestorePhotosUseCase,
        confirmationService: DeletionConfirmationService
    ) {
        self.deletePhotosUseCase = deletePhotosUseCase
        self.restorePhotosUseCase = restorePhotosUseCase
        self.confirmationService = confirmationService
    }

    // MARK: - State

    /// エラーアラート表示フラグ
    @State private var showingError = false

    /// エラーメッセージ
    @State private var errorMessage = ""

    /// PermissionsView表示フラグ
    @State private var showingPermissions = false

    /// プレミアムアップグレード画面表示フラグ
    @State private var showingPremiumUpgrade = false

    /// ゴミ箱画面表示フラグ
    @State private var showingTrash = false

    /// 言語変更後の再起動アラート表示フラグ
    @State private var showingRestartAlert = false

    // MARK: - URL Constants

    /// プライバシーポリシーURL
    private static let privacyPolicyURL = URL(string: "https://lightroll-cleaner.app/privacy")!

    /// 利用規約URL
    private static let termsOfServiceURL = URL(string: "https://lightroll-cleaner.app/terms")!

    /// サポートURL
    private static let supportURL = URL(string: "https://lightroll-cleaner.app/support")!

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                premiumSection
                scanSettingsSection
                analysisSettingsSection
                notificationSection
                displaySection
                languageSection
                otherSection
                appInfoSection
            }
            .navigationTitle("設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingPermissions) {
                NavigationStack {
                    PermissionsView()
                        .environment(permissionManager)
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    settingsService.clearError()
                }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: settingsService.lastError) { _, newError in
                if let error = newError {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            .sheet(isPresented: $showingTrash) {
                // BUG-TRASH-002-P1C: 環境オブジェクト明示的注入
                // sheet内のビューは親のEnvironmentを自動継承しないため、明示的に注入
                NavigationStack {
                    TrashView(
                        trashManager: trashManager,
                        deletePhotosUseCase: deletePhotosUseCase,
                        restorePhotosUseCase: restorePhotosUseCase,
                        confirmationService: confirmationService
                    )
                    .environment(settingsService)
                }
            }
        }
    }

    // MARK: - Premium Section

    /// プレミアムセクション
    private var premiumSection: some View {
        Section {
            if premiumManager.isPremium {
                // プレミアム会員の場合はステータス表示
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.yellow.gradient)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("プレミアム会員")
                            .font(.headline)

                        Text("すべての機能が利用可能です")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            } else {
                // 無料会員の場合はアップグレードボタンを表示
                Button {
                    showingPremiumUpgrade = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.yellow.gradient)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("プレミアムにアップグレード")
                                .font(.headline)

                            Text("無制限削除・広告なし・全機能解放")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("プレミアムにアップグレード。無制限削除・広告なし・全機能解放")
                .accessibilityHint("タップしてプランを選択")
                .sheet(isPresented: $showingPremiumUpgrade) {
                    LimitReachedSheet(
                        currentCount: 0,
                        limit: 50,
                        remainingDuplicates: nil,
                        potentialFreeSpace: nil,
                        onUpgrade: {
                            // アップグレード後のリフレッシュ（PremiumManagerが自動更新）
                        }
                    )
                }
            }
        }
    }

    // MARK: - Scan Settings Section

    /// スキャン設定セクション
    private var scanSettingsSection: some View {
        Section {
            @Bindable var service = settingsService

            SettingsToggle(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "自動スキャン",
                subtitle: "定期的に写真を自動でスキャン",
                isOn: .init(
                    get: { service.settings.scanSettings.autoScanEnabled },
                    set: { newValue in
                        var newSettings = service.settings.scanSettings
                        newSettings.autoScanEnabled = newValue
                        try? service.updateScanSettings(newSettings)
                    }
                )
            )

            Picker(selection: .init(
                get: { service.settings.scanSettings.autoScanInterval },
                set: { newValue in
                    var newSettings = service.settings.scanSettings
                    newSettings.autoScanInterval = newValue
                    try? service.updateScanSettings(newSettings)
                }
            )) {
                ForEach(AutoScanInterval.allCases, id: \.self) { interval in
                    Text(LocalizedStringKey(interval.rawValue)).tag(interval)
                }
            } label: {
                SettingsRow(
                    icon: "clock",
                    iconColor: .orange,
                    title: "スキャン間隔"
                )
            }

            SettingsToggle(
                icon: "video",
                iconColor: .purple,
                title: "動画を含める",
                subtitle: "スキャン対象に動画を含める",
                isOn: .init(
                    get: { service.settings.scanSettings.includeVideos },
                    set: { newValue in
                        var newSettings = service.settings.scanSettings
                        newSettings.includeVideos = newValue
                        try? service.updateScanSettings(newSettings)
                    }
                )
            )

            SettingsToggle(
                icon: "camera.viewfinder",
                iconColor: .green,
                title: "スクリーンショットを含める",
                subtitle: "スキャン対象にスクリーンショットを含める",
                isOn: .init(
                    get: { service.settings.scanSettings.includeScreenshots },
                    set: { newValue in
                        var newSettings = service.settings.scanSettings
                        newSettings.includeScreenshots = newValue
                        try? service.updateScanSettings(newSettings)
                    }
                )
            )

            SettingsToggle(
                icon: "person.crop.circle",
                iconColor: .pink,
                title: "自撮りを含める",
                subtitle: "スキャン対象に自撮り写真を含める",
                isOn: .init(
                    get: { service.settings.scanSettings.includeSelfies },
                    set: { newValue in
                        var newSettings = service.settings.scanSettings
                        newSettings.includeSelfies = newValue
                        try? service.updateScanSettings(newSettings)
                    }
                )
            )
        } header: {
            Text("スキャン設定")
        }
    }

    // MARK: - Analysis Settings Section

    /// 分析設定セクション
    private var analysisSettingsSection: some View {
        Section {
            @Bindable var service = settingsService

            HStack {
                SettingsRow(
                    icon: "slider.horizontal.3",
                    iconColor: .blue,
                    title: "類似度しきい値"
                )

                Spacer()

                Text("\(Int(service.settings.analysisSettings.similarityThreshold * 100))%")
                    .foregroundColor(.secondary)
            }

            HStack {
                SettingsRow(
                    icon: "waveform",
                    iconColor: .orange,
                    title: "ブレ判定感度"
                )

                Spacer()

                Text(LocalizedStringKey(blurThresholdLabel))
                    .foregroundColor(.secondary)
            }

            Picker(selection: .init(
                get: { service.settings.analysisSettings.minGroupSize },
                set: { newValue in
                    var newSettings = service.settings.analysisSettings
                    newSettings.minGroupSize = newValue
                    try? service.updateAnalysisSettings(newSettings)
                }
            )) {
                ForEach(2...10, id: \.self) { size in
                    Text("\(size)枚").tag(size)
                }
            } label: {
                SettingsRow(
                    icon: "square.grid.2x2",
                    iconColor: .purple,
                    title: "最小グループサイズ"
                )
            }
        } header: {
            Text("分析設定")
        }
    }

    // MARK: - Notification Section

    /// 通知セクション
    private var notificationSection: some View {
        Section {
            NavigationLink {
                NotificationSettingsView()
                    .environment(settingsService)
                    .environment(notificationManager)
            } label: {
                HStack {
                    SettingsRow(
                        icon: "bell.badge",
                        iconColor: .orange,
                        title: "通知設定",
                        subtitle: notificationSummary
                    )

                    Spacer()

                    if !settingsService.settings.notificationSettings.isEnabled {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                            .accessibilityLabel("通知が無効")
                    }
                }
            }
            .accessibilityLabel("通知設定")
            .accessibilityHint("タップして詳細設定を表示")
            .accessibilityIdentifier("notificationSettingsLink")
        } header: {
            Text("通知")
        }
    }

    /// 通知設定のサマリー
    private var notificationSummary: String {
        let settings = settingsService.settings.notificationSettings

        if !settings.isEnabled {
            return "オフ"
        }

        var components: [String] = []

        if settings.storageAlertEnabled {
            components.append("容量警告")
        }

        if settings.reminderEnabled {
            components.append("リマインダー")
        }

        if settings.quietHoursEnabled {
            components.append("静寂時間")
        }

        if components.isEmpty {
            return "オン（設定なし）"
        }

        return components.joined(separator: "、")
    }

    // MARK: - Display Section

    /// 表示セクション
    private var displaySection: some View {
        Section {
            @Bindable var service = settingsService

            Picker(selection: .init(
                get: { service.settings.displaySettings.gridColumns },
                set: { newValue in
                    var newSettings = service.settings.displaySettings
                    newSettings.gridColumns = newValue
                    try? service.updateDisplaySettings(newSettings)
                }
            )) {
                ForEach(2...6, id: \.self) { columns in
                    Text("\(columns)列").tag(columns)
                }
            } label: {
                SettingsRow(
                    icon: "square.grid.3x3",
                    iconColor: .blue,
                    title: "グリッド列数"
                )
            }

            SettingsToggle(
                icon: "doc.text",
                iconColor: .green,
                title: "ファイルサイズ表示",
                subtitle: "写真のファイルサイズを表示",
                isOn: .init(
                    get: { service.settings.displaySettings.showFileSize },
                    set: { newValue in
                        var newSettings = service.settings.displaySettings
                        newSettings.showFileSize = newValue
                        try? service.updateDisplaySettings(newSettings)
                    }
                )
            )

            SettingsToggle(
                icon: "calendar",
                iconColor: .orange,
                title: "撮影日表示",
                subtitle: "写真の撮影日を表示",
                isOn: .init(
                    get: { service.settings.displaySettings.showDate },
                    set: { newValue in
                        var newSettings = service.settings.displaySettings
                        newSettings.showDate = newValue
                        try? service.updateDisplaySettings(newSettings)
                    }
                )
            )

            Picker(selection: .init(
                get: { service.settings.displaySettings.sortOrder },
                set: { newValue in
                    var newSettings = service.settings.displaySettings
                    newSettings.sortOrder = newValue
                    try? service.updateDisplaySettings(newSettings)
                }
            )) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(LocalizedStringKey(order.rawValue)).tag(order)
                }
            } label: {
                SettingsRow(
                    icon: "arrow.up.arrow.down",
                    iconColor: .purple,
                    title: "並び順"
                )
            }
        } header: {
            Text("表示")
        }
    }

    // MARK: - Other Section

    /// その他セクション
    private var otherSection: some View {
        Section {
            Button {
                showingTrash = true
            } label: {
                SettingsRow(
                    icon: "trash",
                    iconColor: .red,
                    title: "ゴミ箱",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Button {
                showingPermissions = true
            } label: {
                SettingsRow(
                    icon: "lock.shield",
                    iconColor: .blue,
                    title: "権限の管理",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Link(destination: Self.supportURL) {
                SettingsRow(
                    icon: "questionmark.circle",
                    iconColor: .green,
                    title: "ヘルプ・サポート",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Link(destination: Self.privacyPolicyURL) {
                SettingsRow(
                    icon: "hand.raised",
                    iconColor: .orange,
                    title: "プライバシーポリシー",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Link(destination: Self.termsOfServiceURL) {
                SettingsRow(
                    icon: "doc.text",
                    iconColor: .gray,
                    title: "利用規約",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        } header: {
            Text("その他")
        }
    }

    // MARK: - Language Section

    /// 言語設定セクション
    private var languageSection: some View {
        Section {
            @Bindable var service = settingsService

            Picker(selection: .init(
                get: { service.settings.appLanguage },
                set: { newLanguage in
                    service.updateLanguage(newLanguage)
                    showingRestartAlert = true
                }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            } label: {
                SettingsRow(
                    icon: "globe",
                    iconColor: .teal,
                    title: "言語"
                )
            }
            .alert("再起動が必要です", isPresented: $showingRestartAlert) {
                Button("今すぐ再起動", role: .destructive) {
                    exit(0)
                }
                Button("後で", role: .cancel) { }
            } message: {
                Text("言語の変更はアプリの再起動後に反映されます。")
            }
        } header: {
            Text("言語設定")
        } footer: {
            Text("言語の変更はアプリの再起動後に反映されます。")
        }
    }

    // MARK: - App Info Section

    /// アプリ情報セクション
    private var appInfoSection: some View {
        Section {
            HStack {
                SettingsRow(
                    icon: "info.circle",
                    iconColor: .blue,
                    title: "バージョン"
                )

                Spacer()

                Text(appVersion)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            HStack {
                SettingsRow(
                    icon: "number",
                    iconColor: .gray,
                    title: "ビルド番号"
                )

                Spacer()

                Text(buildNumber)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        } header: {
            Text("アプリ情報")
        }
    }

    // MARK: - Computed Properties

    /// ブレ判定感度ラベル
    private var blurThresholdLabel: String {
        let threshold = settingsService.settings.analysisSettings.blurThreshold
        switch threshold {
        case 0.0..<0.2:
            return "低"
        case 0.2..<0.4:
            return "標準"
        case 0.4...1.0:
            return "高"
        default:
            return "標準"
        }
    }

    /// アプリバージョン
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// ビルド番号
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

// MARK: - Preview

#Preview("デフォルト設定") {
    // 依存関係のモック作成
    let trashManager = TrashManager()
    let photoRepository = PhotoRepository(permissionManager: PhotoPermissionManager())
    let premiumManager = PremiumManager(purchaseRepository: PurchaseRepository())
    let deletePhotosUseCase = DeletePhotosUseCase(
        trashManager: trashManager,
        photoRepository: photoRepository,
        premiumManager: premiumManager
    )
    let restorePhotosUseCase = RestorePhotosUseCase(trashManager: trashManager)
    let confirmationService = DeletionConfirmationService()

    return SettingsView(
        deletePhotosUseCase: deletePhotosUseCase,
        restorePhotosUseCase: restorePhotosUseCase,
        confirmationService: confirmationService
    )
    .environment(SettingsService())
    .environment(PermissionManager())
    .environment(premiumManager)
    .environment(trashManager)
    .environment(NotificationManager())
}

#Preview("自動スキャン有効") {
    @Previewable @State var service: SettingsService = {
        let s = SettingsService()
        var settings = s.settings
        settings.scanSettings.autoScanEnabled = true
        settings.notificationSettings.isEnabled = true
        try? s.updateScanSettings(settings.scanSettings)
        try? s.updateNotificationSettings(settings.notificationSettings)
        return s
    }()

    // 依存関係のモック作成
    let trashManager = TrashManager()
    let photoRepository = PhotoRepository(permissionManager: PhotoPermissionManager())
    let premiumManager = PremiumManager(purchaseRepository: PurchaseRepository())
    let deletePhotosUseCase = DeletePhotosUseCase(
        trashManager: trashManager,
        photoRepository: photoRepository,
        premiumManager: premiumManager
    )
    let restorePhotosUseCase = RestorePhotosUseCase(trashManager: trashManager)
    let confirmationService = DeletionConfirmationService()

    return SettingsView(
        deletePhotosUseCase: deletePhotosUseCase,
        restorePhotosUseCase: restorePhotosUseCase,
        confirmationService: confirmationService
    )
    .environment(service)
    .environment(PermissionManager())
    .environment(premiumManager)
    .environment(trashManager)
    .environment(NotificationManager())
}
