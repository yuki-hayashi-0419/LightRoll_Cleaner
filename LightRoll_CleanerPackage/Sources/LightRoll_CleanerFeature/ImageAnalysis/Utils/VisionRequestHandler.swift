//
//  VisionRequestHandler.swift
//  LightRoll_CleanerFeature
//
//  Vision Framework のリクエスト処理を統括する基盤クラス
//  画像解析リクエストの実行、エラーハンドリング、リソース管理を担当
//  Created by AI Assistant
//

import Foundation
@preconcurrency import Vision
import CoreImage
import Photos

// MARK: - VisionRequestHandler

/// Vision Framework のリクエスト処理を統括するハンドラー
///
/// 主な責務:
/// - VNImageRequestHandler のライフサイクル管理
/// - リクエストの並列実行と結果集約
/// - エラーハンドリングと再試行ロジック
/// - メモリ効率的な画像処理
public actor VisionRequestHandler {

    // MARK: - Properties

    /// キャンセルトークン（並列処理のキャンセル用）
    private var isCancelled = false

    /// リクエスト実行オプション
    private let options: VisionRequestOptions

    // MARK: - Initialization

    /// 標準イニシャライザ
    /// - Parameter options: リクエスト実行オプション
    public init(options: VisionRequestOptions = .default) {
        self.options = options
    }

    // MARK: - Public Methods

    /// PHAsset から画像を読み込んで Vision リクエストを実行
    ///
    /// - Parameters:
    ///   - asset: 対象の PHAsset
    ///   - requests: 実行する Vision リクエストの配列
    /// - Returns: リクエスト実行結果
    /// - Throws: AnalysisError（画像読み込み失敗、Vision エラー等）
    public func perform(
        on asset: PHAsset,
        requests: [VNRequest]
    ) async throws -> VisionRequestResult {
        // キャンセルチェック
        try Task.checkCancellation()
        guard !isCancelled else {
            throw AnalysisError.cancelled
        }

        // PHAsset から CIImage を取得
        let ciImage = try await loadCIImage(from: asset)

        // Vision リクエストを実行
        return try await perform(on: ciImage, requests: requests)
    }

    /// CIImage に対して Vision リクエストを実行
    ///
    /// - Parameters:
    ///   - ciImage: 対象の CIImage
    ///   - requests: 実行する Vision リクエストの配列
    /// - Returns: リクエスト実行結果
    /// - Throws: AnalysisError（Vision エラー等）
    public func perform(
        on ciImage: CIImage,
        requests: [VNRequest]
    ) async throws -> VisionRequestResult {
        // キャンセルチェック
        try Task.checkCancellation()
        guard !isCancelled else {
            throw AnalysisError.cancelled
        }

        // リクエストが空の場合はエラー
        guard !requests.isEmpty else {
            throw AnalysisError.visionFrameworkError("リクエストが指定されていません")
        }

        // Vision リクエストハンドラーを作成
        let handler = VNImageRequestHandler(
            ciImage: ciImage,
            orientation: .up,
            options: options.requestHandlerOptions
        )

        // リクエストを実行（バックグラウンドスレッドで）
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: options.qos).async {
                do {
                    // リクエストを一括実行
                    try handler.perform(requests)

                    // 結果を収集
                    let result = VisionRequestResult(
                        requests: requests,
                        executedAt: Date()
                    )

                    continuation.resume(returning: result)
                } catch let error as NSError {
                    // Vision エラーを AnalysisError に変換
                    let analysisError = AnalysisError.visionFrameworkError(
                        error.localizedDescription
                    )
                    continuation.resume(throwing: analysisError)
                }
            }
        }
    }

    /// Data から Vision リクエストを実行
    ///
    /// - Parameters:
    ///   - imageData: 画像データ
    ///   - requests: 実行する Vision リクエストの配列
    /// - Returns: リクエスト実行結果
    /// - Throws: AnalysisError
    public func perform(
        on imageData: Data,
        requests: [VNRequest]
    ) async throws -> VisionRequestResult {
        // キャンセルチェック
        try Task.checkCancellation()
        guard !isCancelled else {
            throw AnalysisError.cancelled
        }

        // Data から CIImage を作成
        guard let ciImage = CIImage(data: imageData) else {
            throw AnalysisError.visionFrameworkError("画像データの読み込みに失敗しました")
        }

        return try await perform(on: ciImage, requests: requests)
    }

    /// 処理をキャンセル
    public func cancel() {
        isCancelled = true
    }

    /// キャンセル状態をリセット
    public func reset() {
        isCancelled = false
    }

    // MARK: - Private Methods

    /// PHAsset から CIImage を読み込む
    ///
    /// - Parameter asset: 対象の PHAsset
    /// - Returns: CIImage
    /// - Throws: AnalysisError
    private func loadCIImage(from asset: PHAsset) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            options.resizeMode = .none

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: options
            ) { image, info in
                // エラーチェック
                if let error = info?[PHImageErrorKey] as? Error {
                    let analysisError = AnalysisError.visionFrameworkError(
                        "画像読み込みエラー: \(error.localizedDescription)"
                    )
                    continuation.resume(throwing: analysisError)
                    return
                }

                // キャンセルチェック
                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    continuation.resume(throwing: AnalysisError.cancelled)
                    return
                }

                // UIImage から CIImage を作成
                guard let uiImage = image else {
                    let error = AnalysisError.visionFrameworkError(
                        "画像の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }

                // UIImage/NSImage -> CIImage への変換
                #if os(iOS)
                // iOS環境: UIImage.cgImage を使用
                guard let cgImage = uiImage.cgImage else {
                    let error = AnalysisError.visionFrameworkError(
                        "CGImage の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }
                let ciImage = CIImage(cgImage: cgImage)
                #else
                // macOS環境: NSImage から CGImage を取得
                guard let cgImage = uiImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    let error = AnalysisError.visionFrameworkError(
                        "CGImage の取得に失敗しました"
                    )
                    continuation.resume(throwing: error)
                    return
                }
                let ciImage = CIImage(cgImage: cgImage)
                #endif

                continuation.resume(returning: ciImage)
            }
        }
    }
}

// MARK: - VisionRequestOptions

/// Vision リクエスト実行時のオプション
public struct VisionRequestOptions: @unchecked Sendable {

    /// 実行時の QoS（Quality of Service）
    public let qos: DispatchQoS.QoSClass

    /// リクエストハンドラーに渡すオプション
    public let requestHandlerOptions: [VNImageOption: Any]

    /// タイムアウト時間（秒）
    public let timeout: TimeInterval

    /// 再試行回数
    public let maxRetries: Int

    // MARK: - Initialization

    /// カスタムイニシャライザ
    public init(
        qos: DispatchQoS.QoSClass = .userInitiated,
        requestHandlerOptions: [VNImageOption: Any] = [:],
        timeout: TimeInterval = 30.0,
        maxRetries: Int = 2
    ) {
        self.qos = qos
        self.requestHandlerOptions = requestHandlerOptions
        self.timeout = timeout
        self.maxRetries = maxRetries
    }

    // MARK: - Presets

    /// デフォルトオプション
    public static let `default` = VisionRequestOptions()

    /// 高速処理優先（精度より速度）
    public static let fast = VisionRequestOptions(
        qos: .userInitiated,
        requestHandlerOptions: [:],
        timeout: 10.0,
        maxRetries: 1
    )

    /// 高精度優先（速度より精度）
    public static let accurate = VisionRequestOptions(
        qos: .userInitiated,
        requestHandlerOptions: [:],
        timeout: 60.0,
        maxRetries: 3
    )

    /// バックグラウンド処理用
    public static let background = VisionRequestOptions(
        qos: .utility,
        requestHandlerOptions: [:],
        timeout: 120.0,
        maxRetries: 3
    )
}

// MARK: - VisionRequestResult

/// Vision リクエストの実行結果
public struct VisionRequestResult: @unchecked Sendable {

    /// 実行されたリクエストの配列
    public let requests: [VNRequest]

    /// 実行日時
    public let executedAt: Date

    // MARK: - Initialization

    /// イニシャライザ
    /// - Parameters:
    ///   - requests: 実行されたリクエスト配列
    ///   - executedAt: 実行日時
    public init(requests: [VNRequest], executedAt: Date = Date()) {
        self.requests = requests
        self.executedAt = executedAt
    }

    // MARK: - Result Access

    /// 特定タイプのリクエスト結果を取得
    /// - Parameter type: リクエストの型
    /// - Returns: 該当するリクエスト（見つからない場合は nil）
    public func request<T: VNRequest>(ofType type: T.Type) -> T? {
        requests.first { $0 is T } as? T
    }

    /// 特定タイプのリクエスト結果をすべて取得
    /// - Parameter type: リクエストの型
    /// - Returns: 該当するリクエストの配列
    public func requests<T: VNRequest>(ofType type: T.Type) -> [T] {
        requests.compactMap { $0 as? T }
    }

    /// すべてのリクエストが完了しているかチェック
    public var allRequestsCompleted: Bool {
        requests.allSatisfy { request in
            // results が空でない、または error が nil ならば完了とみなす
            if let imageBased = request as? VNImageBasedRequest {
                return !(imageBased.results?.isEmpty ?? true) || request.results != nil
            }
            return request.results != nil
        }
    }

    /// エラーが発生したリクエストの一覧
    public var failedRequests: [VNRequest] {
        requests.filter { request in
            // VNRequest には標準の error プロパティがないため、
            // results が空かどうかで判定
            if let imageBased = request as? VNImageBasedRequest {
                return imageBased.results?.isEmpty ?? true
            }
            return request.results == nil || (request.results?.isEmpty ?? true)
        }
    }

    /// 成功したリクエストの数
    public var successCount: Int {
        requests.count - failedRequests.count
    }

    /// 失敗したリクエストの数
    public var failureCount: Int {
        failedRequests.count
    }
}

// MARK: - VisionRequestHandler + Convenience

extension VisionRequestHandler {

    /// 単一リクエストを実行（便利メソッド）
    ///
    /// - Parameters:
    ///   - asset: 対象の PHAsset
    ///   - request: 実行するリクエスト
    /// - Returns: リクエスト実行結果
    /// - Throws: AnalysisError
    public func perform(
        on asset: PHAsset,
        request: VNRequest
    ) async throws -> VisionRequestResult {
        try await perform(on: asset, requests: [request])
    }

    /// 単一リクエストを CIImage に対して実行（便利メソッド）
    ///
    /// - Parameters:
    ///   - ciImage: 対象の CIImage
    ///   - request: 実行するリクエスト
    /// - Returns: リクエスト実行結果
    /// - Throws: AnalysisError
    public func perform(
        on ciImage: CIImage,
        request: VNRequest
    ) async throws -> VisionRequestResult {
        try await perform(on: ciImage, requests: [request])
    }
}

// MARK: - VisionRequestResult + CustomStringConvertible

extension VisionRequestResult: CustomStringConvertible {
    public var description: String {
        """
        VisionRequestResult(
            requestCount: \(requests.count),
            successCount: \(successCount),
            failureCount: \(failureCount),
            executedAt: \(executedAt)
        )
        """
    }
}
