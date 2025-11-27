//
//  ViewModelProtocols.swift
//  LightRoll_CleanerFeature
//
//  ViewModel層のプロトコル定義
//  MVVM + Repository Patternに準拠したViewModel抽象化
//  Created by AI Assistant
//

import Foundation
import Combine

// MARK: - Base ViewModel Protocol

/// ViewModel基底プロトコル
/// 全てのViewModelが準拠する共通インターフェース
@MainActor
public protocol ViewModelProtocol: ObservableObject {
    /// ViewModelの状態を表す型
    associatedtype State

    /// ViewModelが処理するアクションを表す型
    associatedtype Action

    /// 現在の状態
    var state: State { get }

    /// アクションを送信
    /// - Parameter action: 実行するアクション
    func send(_ action: Action)
}

// MARK: - Loadable ViewModel Protocol

/// ローディング機能を持つViewModelプロトコル
@MainActor
public protocol LoadableViewModelProtocol: ViewModelProtocol {
    /// ローディング中かどうか
    var isLoading: Bool { get }

    /// データを読み込み
    func load() async
}

// MARK: - Refreshable ViewModel Protocol

/// リフレッシュ機能を持つViewModelプロトコル
@MainActor
public protocol RefreshableViewModelProtocol: LoadableViewModelProtocol {
    /// データをリフレッシュ
    func refresh() async
}

// MARK: - Home ViewModel Protocol

/// ホーム画面のViewModelプロトコル
@MainActor
public protocol HomeViewModelProtocol: RefreshableViewModelProtocol
    where State == HomeViewState, Action == HomeViewAction {}

/// ホーム画面の状態
public enum HomeViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// ローディング中
    case loading

    /// データ読み込み完了
    case loaded(HomeViewData)

    /// スキャン中
    case scanning(ScanProgress)

    /// エラー
    case error(String)
}

/// ホーム画面のデータ
public struct HomeViewData: Equatable, Sendable {
    /// ストレージ情報
    public let storageInfo: StorageInfo

    /// 写真グループ
    public let groups: [PhotoGroup]

    /// 最終スキャン結果
    public let lastScanResult: ScanResult?

    public init(
        storageInfo: StorageInfo,
        groups: [PhotoGroup] = [],
        lastScanResult: ScanResult? = nil
    ) {
        self.storageInfo = storageInfo
        self.groups = groups
        self.lastScanResult = lastScanResult
    }
}

/// ホーム画面のアクション
public enum HomeViewAction: Sendable {
    /// データを読み込み
    case load

    /// スキャンを開始
    case startScan

    /// スキャンをキャンセル
    case cancelScan

    /// グループを選択
    case selectGroup(PhotoGroup)

    /// 設定を開く
    case openSettings

    /// エラーを閉じる
    case dismissError
}

// MARK: - Group List ViewModel Protocol

/// グループ一覧画面のViewModelプロトコル
@MainActor
public protocol GroupListViewModelProtocol: LoadableViewModelProtocol
    where State == GroupListViewState, Action == GroupListViewAction {}

/// グループ一覧画面の状態
public enum GroupListViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// ローディング中
    case loading

    /// データ読み込み完了
    case loaded([PhotoGroup])

    /// 空の状態
    case empty

    /// エラー
    case error(String)
}

/// グループ一覧画面のアクション
public enum GroupListViewAction: Sendable {
    /// データを読み込み
    case load

    /// フィルターを適用
    case applyFilter(GroupType?)

    /// グループを選択
    case selectGroup(PhotoGroup)

    /// グループを削除
    case deleteGroup(PhotoGroup)
}

// MARK: - Group Detail ViewModel Protocol

/// グループ詳細画面のViewModelプロトコル
@MainActor
public protocol GroupDetailViewModelProtocol: ViewModelProtocol
    where State == GroupDetailViewState, Action == GroupDetailViewAction {

    /// 対象のグループ
    var group: PhotoGroup { get }

    /// 選択中の写真ID
    var selectedPhotoIds: Set<String> { get }
}

/// グループ詳細画面の状態
public enum GroupDetailViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// サムネイル読み込み中
    case loadingThumbnails

    /// 表示可能
    case ready

    /// 削除処理中
    case deleting

    /// 削除完了
    case deleted(DeletePhotosOutput)

    /// エラー
    case error(String)
}

/// グループ詳細画面のアクション
public enum GroupDetailViewAction: Sendable {
    /// サムネイルを読み込み
    case loadThumbnails

    /// 写真を選択/解除
    case togglePhotoSelection(String)

    /// ベストショット以外を全選択
    case selectAllExceptBestShot

    /// 選択を解除
    case deselectAll

    /// 選択した写真を削除
    case deleteSelected

    /// 削除をキャンセル
    case cancelDeletion

    /// エラーを閉じる
    case dismissError
}

// MARK: - Trash ViewModel Protocol

/// ゴミ箱画面のViewModelプロトコル
@MainActor
public protocol TrashViewModelProtocol: LoadableViewModelProtocol
    where State == TrashViewState, Action == TrashViewAction {

    /// ゴミ箱内の写真
    var trashPhotos: [TrashPhotoItem] { get }
}

/// ゴミ箱内の写真アイテム
public struct TrashPhotoItem: Identifiable, Equatable, Sendable {
    /// 写真
    public let photo: PhotoAsset

    /// ゴミ箱に移動した日時
    public let trashedDate: Date

    /// 自動削除までの残り日数
    public let daysUntilDeletion: Int

    public var id: String { photo.id }

    public init(
        photo: PhotoAsset,
        trashedDate: Date,
        daysUntilDeletion: Int
    ) {
        self.photo = photo
        self.trashedDate = trashedDate
        self.daysUntilDeletion = daysUntilDeletion
    }

    /// 削除期限が近いかどうか（3日以内）
    public var isNearExpiry: Bool {
        daysUntilDeletion <= 3
    }
}

/// ゴミ箱画面の状態
public enum TrashViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// ローディング中
    case loading

    /// データ読み込み完了
    case loaded

    /// 空の状態
    case empty

    /// 復元処理中
    case restoring

    /// 完全削除処理中
    case permanentlyDeleting

    /// エラー
    case error(String)
}

/// ゴミ箱画面のアクション
public enum TrashViewAction: Sendable {
    /// データを読み込み
    case load

    /// 写真を選択/解除
    case togglePhotoSelection(String)

    /// 全選択
    case selectAll

    /// 選択解除
    case deselectAll

    /// 選択した写真を復元
    case restoreSelected

    /// 選択した写真を完全削除
    case permanentlyDeleteSelected

    /// ゴミ箱を空にする
    case emptyTrash

    /// エラーを閉じる
    case dismissError
}

// MARK: - Settings ViewModel Protocol

/// 設定画面のViewModelプロトコル
@MainActor
public protocol SettingsViewModelProtocol: LoadableViewModelProtocol
    where State == SettingsViewState, Action == SettingsViewAction {

    /// 現在の設定
    var settings: UserSettings { get }

    /// プレミアムステータス
    var premiumStatus: PremiumStatus { get }
}

/// 設定画面の状態
public enum SettingsViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// ローディング中
    case loading

    /// 読み込み完了
    case loaded

    /// 保存中
    case saving

    /// エラー
    case error(String)
}

/// 設定画面のアクション
public enum SettingsViewAction: Sendable {
    /// 設定を読み込み
    case load

    /// 類似度閾値を更新
    case updateSimilarityThreshold(Float)

    /// 自動削除日数を更新
    case updateAutoDeleteDays(Int)

    /// 通知設定を更新
    case updateNotificationsEnabled(Bool)

    /// 起動時スキャン設定を更新
    case updateScanOnLaunch(Bool)

    /// 設定をリセット
    case resetSettings

    /// 設定を保存
    case saveSettings

    /// プレミアム画面を開く
    case openPremium

    /// エラーを閉じる
    case dismissError
}

// MARK: - Premium ViewModel Protocol

/// プレミアム画面のViewModelプロトコル
@MainActor
public protocol PremiumViewModelProtocol: LoadableViewModelProtocol
    where State == PremiumViewState, Action == PremiumViewAction {

    /// 商品情報
    var products: [ProductInfo] { get }

    /// 現在のステータス
    var premiumStatus: PremiumStatus { get }
}

/// プレミアム画面の状態
public enum PremiumViewState: Equatable, Sendable {
    /// 初期状態
    case initial

    /// ローディング中
    case loading

    /// 商品読み込み完了
    case loaded

    /// 購入処理中
    case purchasing

    /// 復元処理中
    case restoring

    /// エラー
    case error(String)
}

/// プレミアム画面のアクション
public enum PremiumViewAction: Sendable {
    /// 商品を読み込み
    case load

    /// 購入を実行
    case purchase(String)

    /// 購入を復元
    case restore

    /// 画面を閉じる
    case dismiss

    /// エラーを閉じる
    case dismissError
}
