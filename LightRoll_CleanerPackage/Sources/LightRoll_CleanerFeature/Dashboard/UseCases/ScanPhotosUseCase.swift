//
//  ScanPhotosUseCase.swift
//  LightRoll_CleanerFeature
//
//  写真スキャンユースケース
//  PhotoScannerとAnalysisRepositoryを統合し、写真ライブラリのスキャンと分析を実行
//  Created by AI Assistant
//

import Foundation

// MARK: - ScanPhotosUseCase

/// 写真スキャンユースケースの実装
/// 写真ライブラリのスキャン、分析、グルーピングを統合的に実行
///
/// ## 主な責務
/// - PhotoScannerで写真ライブラリをスキャン
/// - AnalysisRepositoryで写真を分析
/// - グルーピング結果を生成
/// - 進捗をリアルタイムで通知
///
/// ## 使用例
/// ```swift
/// let useCase = ScanPhotosUseCase(
///     photoScanner: scanner,
///     analysisRepository: repository
/// )
///
/// // 進捗を監視
/// for await progress in useCase.progressStream {
///     print("Progress: \(progress.progress)")
/// }
///
/// // スキャン実行
/// let result = try await useCase.execute()
/// ```
@MainActor
public final class ScanPhotosUseCase: ScanPhotosUseCaseProtocol {

    // MARK: - Properties

    /// PhotoScanner インスタンス
    private let photoScanner: PhotoScanner

    /// AnalysisRepository インスタンス
    private let analysisRepository: AnalysisRepository

    /// 進捗通知用の継続オブジェクト
    private var progressContinuation: AsyncStream<ScanProgress>.Continuation?

    /// 現在スキャン中かどうか
    public private(set) var isScanning: Bool = false

    /// スキャン開始時刻
    private var startTime: Date?

    /// 現在のスキャンタスク
    private var currentTask: Task<ScanResult, Error>?

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - photoScanner: PhotoScanner インスタンス
    ///   - analysisRepository: AnalysisRepository インスタンス
    public init(
        photoScanner: PhotoScanner,
        analysisRepository: AnalysisRepository
    ) {
        self.photoScanner = photoScanner
        self.analysisRepository = analysisRepository
    }

    // MARK: - ScanPhotosUseCaseProtocol

    /// スキャン進捗を監視するためのAsyncStream
    public var progressStream: AsyncStream<ScanProgress> {
        AsyncStream { [weak self] continuation in
            self?.progressContinuation = continuation
        }
    }

    /// スキャンを実行
    /// - Returns: スキャン結果
    /// - Throws: LightRollError
    public func execute() async throws -> ScanResult {
        // 既にスキャン中の場合はエラー
        guard !isScanning else {
            throw ScanPhotosUseCaseError.scanAlreadyInProgress
        }

        isScanning = true
        startTime = Date()

        // 初期進捗を通知
        notifyProgress(ScanProgress(
            phase: .preparing,
            progress: 0,
            currentTask: NSLocalizedString(
                "scan.task.preparing",
                value: "準備中...",
                comment: "Preparing scan"
            )
        ))

        do {
            let result = try await performScan()
            isScanning = false
            progressContinuation?.finish()
            return result
        } catch {
            isScanning = false
            notifyProgress(ScanProgress(
                phase: .error,
                progress: 0,
                currentTask: error.localizedDescription
            ))
            progressContinuation?.finish()
            throw mapError(error)
        }
    }

    /// スキャンをキャンセル
    public func cancel() {
        photoScanner.cancel()
        currentTask?.cancel()
        isScanning = false
        progressContinuation?.finish()
    }

    /// 保存されているPhotoGroupを読み込み
    /// - Returns: 保存されているPhotoGroup配列（なければ空配列）
    /// - Throws: Error
    public func loadSavedGroups() async throws -> [PhotoGroup] {
        try await analysisRepository.loadGroups()
    }

    /// 保存されているPhotoGroupの有無を確認
    /// - Returns: グループが保存されている場合true
    public func hasSavedGroups() async -> Bool {
        await analysisRepository.hasGroups()
    }

    // MARK: - Private Methods

    /// スキャン処理の実行
    private func performScan() async throws -> ScanResult {
        // フェーズ1: 写真取得
        notifyProgress(ScanProgress(
            phase: .fetchingPhotos,
            progress: 0,
            currentTask: NSLocalizedString(
                "scan.task.fetchingPhotos",
                value: "写真を取得中...",
                comment: "Fetching photos"
            )
        ))

        let photos = try await photoScanner.scan { [weak self] scanProgress in
            Task { @MainActor in
                self?.notifyProgress(ScanProgress(
                    phase: .fetchingPhotos,
                    progress: scanProgress.percentage * 0.3, // 0〜30%
                    processedCount: scanProgress.current,
                    totalCount: scanProgress.total,
                    currentTask: String(
                        format: NSLocalizedString(
                            "scan.task.fetchingPhotosProgress",
                            value: "%d / %d 枚",
                            comment: "Fetching photos progress"
                        ),
                        scanProgress.current,
                        scanProgress.total
                    )
                ))
            }
        }

        // キャンセルチェック
        try Task.checkCancellation()

        // 空の写真ライブラリの場合
        guard !photos.isEmpty else {
            return createEmptyResult()
        }

        // フェーズ2: 分析
        notifyProgress(ScanProgress(
            phase: .analyzing,
            progress: 0.3,
            currentTask: NSLocalizedString(
                "scan.task.analyzing",
                value: "写真を分析中...",
                comment: "Analyzing photos"
            )
        ))

        let analysisResults = try await analysisRepository.analyzePhotos(photos) { [weak self] progress in
            Task { @MainActor in
                self?.notifyProgress(ScanProgress(
                    phase: .analyzing,
                    progress: 0.3 + progress * 0.3, // 30〜60%
                    processedCount: Int(progress * Double(photos.count)),
                    totalCount: photos.count,
                    currentTask: String(
                        format: NSLocalizedString(
                            "scan.task.analyzingProgress",
                            value: "分析中: %d%%",
                            comment: "Analyzing progress"
                        ),
                        Int(progress * 100)
                    )
                ))
            }
        }

        // キャンセルチェック
        try Task.checkCancellation()

        // フェーズ3: グルーピング
        notifyProgress(ScanProgress(
            phase: .grouping,
            progress: 0.6,
            currentTask: NSLocalizedString(
                "scan.task.grouping",
                value: "グループ化中...",
                comment: "Grouping photos"
            )
        ))

        let groups = try await analysisRepository.groupPhotos(photos) { [weak self] progress in
            Task { @MainActor in
                self?.notifyProgress(ScanProgress(
                    phase: .grouping,
                    progress: 0.6 + progress * 0.3, // 60〜90%
                    currentTask: String(
                        format: NSLocalizedString(
                            "scan.task.groupingProgress",
                            value: "グループ化中: %d%%",
                            comment: "Grouping progress"
                        ),
                        Int(progress * 100)
                    )
                ))
            }
        }

        // キャンセルチェック
        try Task.checkCancellation()

        // フェーズ4: 最適化（ベストショット選定）
        notifyProgress(ScanProgress(
            phase: .optimizing,
            progress: 0.9,
            currentTask: NSLocalizedString(
                "scan.task.optimizing",
                value: "最適化中...",
                comment: "Optimizing"
            )
        ))

        var optimizedGroups = groups
        for (index, group) in groups.enumerated() where group.type.needsBestShotSelection {
            if let bestShotIndex = try await analysisRepository.selectBestShot(from: group) {
                optimizedGroups[index] = group.withBestShot(at: bestShotIndex)
            }
        }

        // 完了
        let duration = Date().timeIntervalSince(startTime ?? Date())
        let result = createResult(
            photos: photos,
            groups: optimizedGroups,
            analysisResults: analysisResults,
            duration: duration
        )

        notifyProgress(ScanProgress.completed)

        return result
    }

    /// 進捗を通知
    private func notifyProgress(_ progress: ScanProgress) {
        progressContinuation?.yield(progress)
    }

    /// 空のスキャン結果を生成
    private func createEmptyResult() -> ScanResult {
        let duration = Date().timeIntervalSince(startTime ?? Date())
        return ScanResult(
            totalPhotosScanned: 0,
            groupsFound: 0,
            potentialSavings: 0,
            duration: duration,
            groupBreakdown: GroupBreakdown()
        )
    }

    /// スキャン結果を生成
    private func createResult(
        photos: [Photo],
        groups: [PhotoGroup],
        analysisResults: [PhotoAnalysisResult],
        duration: TimeInterval
    ) -> ScanResult {
        // グループタイプ別の内訳を計算
        let groupedByType = Dictionary(grouping: groups) { $0.type }

        let breakdown = GroupBreakdown(
            similarGroups: groupedByType[.similar]?.count ?? 0,
            selfieGroups: groupedByType[.selfie]?.count ?? 0,
            screenshotCount: groupedByType[.screenshot]?.reduce(0) { $0 + $1.count } ?? 0,
            blurryCount: groupedByType[.blurry]?.reduce(0) { $0 + $1.count } ?? 0,
            largeVideoCount: groupedByType[.largeVideo]?.reduce(0) { $0 + $1.count } ?? 0
        )

        // 削減可能容量を計算
        let potentialSavings = groups.reduce(0) { $0 + $1.reclaimableSize }

        return ScanResult(
            totalPhotosScanned: photos.count,
            groupsFound: groups.count,
            potentialSavings: potentialSavings,
            duration: duration,
            groupBreakdown: breakdown
        )
    }

    /// エラーをマッピング
    private func mapError(_ error: Error) -> Error {
        if let scannerError = error as? PhotoScannerError {
            switch scannerError {
            case .notAuthorized:
                return ScanPhotosUseCaseError.photoAccessDenied
            case .scanCancelled:
                return ScanPhotosUseCaseError.scanCancelled
            case .scanInProgress:
                return ScanPhotosUseCaseError.scanAlreadyInProgress
            case .scanFailed(let underlying):
                return ScanPhotosUseCaseError.scanFailed(reason: underlying)
            }
        }

        if let analysisError = error as? AnalysisError {
            return ScanPhotosUseCaseError.analysisFailed(reason: analysisError.localizedDescription)
        }

        if error is CancellationError {
            return ScanPhotosUseCaseError.scanCancelled
        }

        return ScanPhotosUseCaseError.scanFailed(reason: error.localizedDescription)
    }
}

// MARK: - ScanPhotosUseCaseError

/// ScanPhotosUseCase で発生するエラー
public enum ScanPhotosUseCaseError: Error, LocalizedError, Equatable, Sendable {
    /// 写真ライブラリへのアクセスが拒否された
    case photoAccessDenied

    /// 既にスキャンが実行中
    case scanAlreadyInProgress

    /// スキャンがキャンセルされた
    case scanCancelled

    /// スキャンに失敗した
    case scanFailed(reason: String)

    /// 分析に失敗した
    case analysisFailed(reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.usecase.photoAccessDenied",
                value: "写真ライブラリへのアクセスが許可されていません",
                comment: "Photo access denied error"
            )
        case .scanAlreadyInProgress:
            return NSLocalizedString(
                "error.usecase.scanAlreadyInProgress",
                value: "既にスキャンが実行中です",
                comment: "Scan already in progress error"
            )
        case .scanCancelled:
            return NSLocalizedString(
                "error.usecase.scanCancelled",
                value: "スキャンがキャンセルされました",
                comment: "Scan cancelled error"
            )
        case .scanFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.usecase.scanFailed",
                    value: "スキャンに失敗しました: %@",
                    comment: "Scan failed error"
                ),
                reason
            )
        case .analysisFailed(let reason):
            return String(
                format: NSLocalizedString(
                    "error.usecase.analysisFailed",
                    value: "分析に失敗しました: %@",
                    comment: "Analysis failed error"
                ),
                reason
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .photoAccessDenied:
            return NSLocalizedString(
                "error.usecase.photoAccessDenied.suggestion",
                value: "設定アプリから写真へのアクセスを許可してください",
                comment: "Photo access denied recovery suggestion"
            )
        case .scanAlreadyInProgress:
            return NSLocalizedString(
                "error.usecase.scanAlreadyInProgress.suggestion",
                value: "現在のスキャンが完了するまでお待ちください",
                comment: "Scan already in progress recovery suggestion"
            )
        case .scanCancelled:
            return nil
        case .scanFailed, .analysisFailed:
            return NSLocalizedString(
                "error.usecase.scanFailed.suggestion",
                value: "しばらく待ってから再度お試しください",
                comment: "Scan failed recovery suggestion"
            )
        }
    }
}

// MARK: - ScanPhotosUseCase + Factory

extension ScanPhotosUseCase {
    /// コンビニエンスファクトリ
    /// - Parameter permissionManager: 権限マネージャー
    /// - Returns: ScanPhotosUseCase インスタンス
    @MainActor
    public static func create(
        permissionManager: PhotoPermissionManagerProtocol
    ) -> ScanPhotosUseCase {
        let scanner = PhotoScanner.create(
            permissionManager: permissionManager,
            options: .default
        )
        let repository = AnalysisRepository()

        return ScanPhotosUseCase(
            photoScanner: scanner,
            analysisRepository: repository
        )
    }
}
