import SwiftUI

public struct ContentView: View {
    // MARK: - Dependencies

    /// 写真権限マネージャー
    private let permissionManager: PhotoPermissionManager

    /// 写真リポジトリ
    private let photoRepository: PhotoRepository

    /// 写真スキャナー
    private let photoScanner: PhotoScanner

    /// 分析リポジトリ
    private let analysisRepository: AnalysisRepository

    /// スキャンユースケース
    private let scanPhotosUseCase: ScanPhotosUseCase

    /// 統計取得ユースケース
    private let getStatisticsUseCase: GetStatisticsUseCase

    // MARK: - Settings State

    /// 設定サービス
    @State private var settingsService = SettingsService()

    /// 権限マネージャー（設定画面用）
    @State private var settingsPermissionManager = PermissionManager()

    /// プレミアムマネージャー
    @State private var premiumManager: PremiumManager

    /// 広告管理マネージャー
    @State private var adManager: AdManager

    /// スキャン制限マネージャー
    @State private var scanLimitManager = ScanLimitManager()

    /// インタースティシャル広告マネージャー
    @State private var adInterstitialManager = AdInterstitialManager()

    /// ゴミ箱マネージャー
    @State private var trashManager: TrashManager

    /// 写真削除ユースケース
    @State private var deletePhotosUseCase: DeletePhotosUseCase

    /// 写真復元ユースケース
    @State private var restorePhotosUseCase: RestorePhotosUseCase

    /// 削除確認サービス
    @State private var confirmationService: DeletionConfirmationService

    /// 通知マネージャー（SettingsView用）
    @State private var notificationManager = NotificationManager()

    /// バックグラウンドスキャンマネージャー
    private let backgroundScanManager = BackgroundScanManager.shared

    /// 設定画面表示フラグ
    @State private var showingSettings = false

    // MARK: - Initialization

    public init() {
        // 依存関係の初期化チェーン
        let permissionManager = PhotoPermissionManager()
        let photoRepository = PhotoRepository(permissionManager: permissionManager)
        let photoScanner = PhotoScanner(
            repository: photoRepository,
            permissionManager: permissionManager
        )
        let analysisRepository = AnalysisRepository()
        let scanPhotosUseCase = ScanPhotosUseCase(
            photoScanner: photoScanner,
            analysisRepository: analysisRepository
        )
        let getStatisticsUseCase = GetStatisticsUseCase(
            photoRepository: photoRepository
        )

        // 課金関連の初期化
        let purchaseRepository = PurchaseRepository()
        let premiumManager = PremiumManager(purchaseRepository: purchaseRepository)

        // 広告関連の初期化
        let adManager = AdManager(premiumManager: premiumManager)

        // ゴミ箱関連の初期化
        let trashManager = TrashManager()
        let deletePhotosUseCase = DeletePhotosUseCase(
            trashManager: trashManager,
            photoRepository: photoRepository,
            premiumManager: premiumManager
        )
        let restorePhotosUseCase = RestorePhotosUseCase(
            trashManager: trashManager
        )
        let confirmationService = DeletionConfirmationService()

        // プロパティに保存
        self.permissionManager = permissionManager
        self.photoRepository = photoRepository
        self.photoScanner = photoScanner
        self.analysisRepository = analysisRepository
        self.scanPhotosUseCase = scanPhotosUseCase
        self.getStatisticsUseCase = getStatisticsUseCase
        self.premiumManager = premiumManager
        self.adManager = adManager
        self.trashManager = trashManager
        self.deletePhotosUseCase = deletePhotosUseCase
        self.restorePhotosUseCase = restorePhotosUseCase
        self.confirmationService = confirmationService
    }

    // MARK: - Body

    public var body: some View {
        DashboardNavigationContainer(
            scanPhotosUseCase: scanPhotosUseCase,
            getStatisticsUseCase: getStatisticsUseCase,
            photoProvider: photoRepository, // PhotoRepositoryはPhotoProviderに準拠
            onDeletePhotos: { photoIds in
                // 写真削除の実装
                Task { @MainActor in
                    do {
                        // PhotoAsset配列を作成
                        let photoAssets = photoIds.map { id in
                            PhotoAsset(id: id, creationDate: Date(), fileSize: 0)
                        }

                        // DeletePhotosUseCaseを使用してゴミ箱へ移動
                        let input = DeletePhotosInput(
                            photos: photoAssets,
                            permanently: false // ゴミ箱へ移動
                        )
                        _ = try await deletePhotosUseCase.execute(input)

                        // 削除後、ストレージ情報キャッシュをクリア
                        photoRepository.clearStorageInfoCache()

                    } catch let error as DeletePhotosUseCaseError {
                        // DeletePhotosUseCaseエラーハンドリング
                        print("写真削除エラー: \(error.localizedDescription)")
                    } catch let error as PhotoRepositoryError {
                        // PhotoRepositoryエラーハンドリング（ユーザーキャンセル含む）
                        print("写真削除エラー: \(error.localizedDescription)")
                    } catch {
                        print("予期しないエラー: \(error.localizedDescription)")
                    }
                }
            },
            onDeleteGroups: { groups in
                // グループ削除の実装（グループ内の全写真を削除）
                Task { @MainActor in
                    do {
                        // 全グループの写真IDを収集
                        let allPhotoIds = groups.flatMap { $0.photoIds }

                        // PhotoAsset配列を作成
                        let photoAssets = allPhotoIds.map { id in
                            PhotoAsset(id: id, creationDate: Date(), fileSize: 0)
                        }

                        // DeletePhotosUseCaseを使用してゴミ箱へ移動
                        let input = DeletePhotosInput(
                            photos: photoAssets,
                            permanently: false // ゴミ箱へ移動
                        )
                        _ = try await deletePhotosUseCase.execute(input)

                        // 削除後、ストレージ情報キャッシュをクリア
                        photoRepository.clearStorageInfoCache()

                    } catch let error as DeletePhotosUseCaseError {
                        // DeletePhotosUseCaseエラーハンドリング
                        print("グループ削除エラー: \(error.localizedDescription)")
                    } catch let error as PhotoRepositoryError {
                        // PhotoRepositoryエラーハンドリング（ユーザーキャンセル含む）
                        print("グループ削除エラー: \(error.localizedDescription)")
                    } catch {
                        print("予期しないエラー: \(error.localizedDescription)")
                    }
                }
            },
            onNavigateToSettings: {
                showingSettings = true
            }
        )
        .environment(settingsService)  // グループ詳細画面で必須（DISPLAY-001〜003で使用）
        .environment(premiumManager)
        .environment(adManager)
        .environment(scanLimitManager)
        .environment(adInterstitialManager)
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView(
                    deletePhotosUseCase: deletePhotosUseCase,
                    restorePhotosUseCase: restorePhotosUseCase,
                    confirmationService: confirmationService
                )
                .environment(settingsService)
                .environment(settingsPermissionManager)
                .environment(premiumManager)
                .environment(trashManager)
                .environment(notificationManager)
            }
        }
        .onChange(of: settingsService.settings.scanSettings.autoScanEnabled) { _, newValue in
            syncBackgroundScanSettings()
        }
        .onChange(of: settingsService.settings.scanSettings.autoScanInterval) { _, newValue in
            syncBackgroundScanSettings()
        }
        .task {
            // 初回起動時にも同期を実行
            syncBackgroundScanSettings()
        }
    }

    // MARK: - Private Methods

    /// UserSettingsの変更をBackgroundScanManagerに同期
    private func syncBackgroundScanSettings() {
        let scanSettings = settingsService.settings.scanSettings

        // AutoScanIntervalをTimeIntervalに変換
        let timeInterval = scanSettings.autoScanInterval.timeInterval ?? BackgroundScanManager.defaultScanInterval

        // BackgroundScanManagerに同期
        backgroundScanManager.syncSettings(
            autoScanEnabled: scanSettings.autoScanEnabled,
            scanInterval: timeInterval
        )
    }
}
