//
//  ScreenshotMode.swift
//  LightRoll_CleanerFeature
//
//  App Store提出用スクリーンショット撮影モード
//  起動引数 -SCREENSHOT_MODE でダミーデータを表示
//  シミュレーターでCoreMLが動かない問題を回避
//

#if DEBUG

import SwiftUI

// MARK: - ScreenshotMode

/// スクリーンショットモードの判定と設定
public enum ScreenshotMode {

    /// スクリーンショットモードが有効かどうか
    /// 起動引数に -SCREENSHOT_MODE が含まれている場合に有効
    public static var isEnabled: Bool {
        CommandLine.arguments.contains("-SCREENSHOT_MODE")
    }
}

// MARK: - ScreenshotModeData

/// スクリーンショットモード用のダミーデータ
public enum ScreenshotModeData {

    // MARK: - ダミーグループ

    /// スキャン結果として表示するダミーグループ一覧
    public static var groups: [PhotoGroup] {
        [
            // 類似写真グループ1: 旅行写真（5枚）
            PhotoGroup(
                type: .similar,
                photoIds: (0..<5).map { "ss-similar-a-\($0)" },
                fileSizes: [3_200_000, 3_100_000, 3_400_000, 2_900_000, 3_000_000],
                bestShotIndex: 2,
                similarityScore: 0.94
            ),
            // 類似写真グループ2: 風景写真（4枚）
            PhotoGroup(
                type: .similar,
                photoIds: (0..<4).map { "ss-similar-b-\($0)" },
                fileSizes: [4_500_000, 4_200_000, 4_800_000, 4_100_000],
                bestShotIndex: 0,
                similarityScore: 0.89
            ),
            // 類似写真グループ3: 料理写真（3枚）
            PhotoGroup(
                type: .similar,
                photoIds: (0..<3).map { "ss-similar-c-\($0)" },
                fileSizes: [2_800_000, 2_600_000, 2_900_000],
                bestShotIndex: 1,
                similarityScore: 0.91
            ),
            // スクリーンショット（12枚）
            PhotoGroup(
                type: .screenshot,
                photoIds: (0..<12).map { "ss-screenshot-\($0)" },
                fileSizes: Array(repeating: 950_000, count: 12)
            ),
            // ブレ写真（6枚）
            PhotoGroup(
                type: .blurry,
                photoIds: (0..<6).map { "ss-blurry-\($0)" },
                fileSizes: [3_500_000, 2_800_000, 3_200_000, 2_600_000, 3_100_000, 2_900_000]
            ),
            // 自撮りグループ（4枚）
            PhotoGroup(
                type: .selfie,
                photoIds: (0..<4).map { "ss-selfie-\($0)" },
                fileSizes: [2_500_000, 2_300_000, 2_700_000, 2_400_000],
                bestShotIndex: 2
            ),
            // 重複写真（3枚）
            PhotoGroup(
                type: .duplicate,
                photoIds: (0..<3).map { "ss-duplicate-\($0)" },
                fileSizes: [4_000_000, 4_000_000, 4_000_000],
                bestShotIndex: 0,
                similarityScore: 1.0
            ),
        ]
    }

    /// スキャン結果のダミーデータ
    public static var scanResult: ScanResult {
        let allGroups = groups
        let totalPhotos = allGroups.reduce(0) { $0 + $1.count }
        let potentialSavings = allGroups.reduce(0) { $0 + $1.reclaimableSize }

        return ScanResult(
            totalPhotosScanned: 2_847,
            groupsFound: allGroups.count,
            potentialSavings: potentialSavings,
            duration: 12.5,
            groupBreakdown: GroupBreakdown(
                similarGroups: 3,
                selfieGroups: 1,
                screenshotCount: 12,
                blurryCount: 6,
                largeVideoCount: 0
            )
        )
    }

    /// ストレージ情報のダミーデータ
    public static var storageInfo: StorageInfo {
        StorageInfo(
            totalCapacity: 256_000_000_000,   // 256GB
            availableCapacity: 42_000_000_000, // 42GB空き
            photosUsedCapacity: 68_500_000_000, // 68.5GB写真使用
            reclaimableCapacity: groups.reduce(0) { $0 + $1.reclaimableSize }
        )
    }

    /// ストレージ統計のダミーデータ
    public static var storageStatistics: StorageStatistics {
        // PhotoGroup配列から生成するイニシャライザを使用
        StorageStatistics(
            storageInfo: storageInfo,
            groups: groups,
            scannedPhotoCount: 2_847
        )
    }

    /// ダミー写真データ（グループ詳細表示用）
    public static func photos(for photoIds: [String]) -> [Photo] {
        photoIds.enumerated().map { index, id in
            let isVideo = id.contains("video")
            let isScreenshot = id.contains("screenshot")

            return Photo(
                id: id,
                localIdentifier: id,
                creationDate: Date().addingTimeInterval(TimeInterval(-3600 * (index + 1))),
                modificationDate: Date().addingTimeInterval(TimeInterval(-3600 * (index + 1))),
                mediaType: isVideo ? .video : .image,
                mediaSubtypes: isScreenshot ? MediaSubtypes(rawValue: MediaSubtypes.screenshot.rawValue) : [],
                pixelWidth: isScreenshot ? 1179 : 4032,
                pixelHeight: isScreenshot ? 2556 : 3024,
                duration: isVideo ? 45.0 : 0,
                fileSize: Int64(1_500_000 + (index * 300_000)),
                isFavorite: index == 0
            )
        }
    }
}

// MARK: - ScreenshotModePhotoProvider

/// スクリーンショットモード用の写真プロバイダー
/// PHAssetを使わずダミーデータを返す
public struct ScreenshotModePhotoProvider: PhotoProvider {
    public init() {}

    public func photos(for ids: [String]) async -> [Photo] {
        ScreenshotModeData.photos(for: ids)
    }
}

// MARK: - ScreenshotModeThumbnail

/// スクリーンショットモード用のサムネイル表示コンポーネント
/// PHAssetの代わりにSF SymbolsとColorでプレースホルダー画像を生成
public struct ScreenshotModeThumbnail: View {

    let photo: Photo
    let isSelected: Bool
    let showBadge: Bool

    public init(
        photo: Photo,
        isSelected: Bool = false,
        showBadge: Bool = false
    ) {
        self.photo = photo
        self.isSelected = isSelected
        self.showBadge = showBadge
    }

    /// 写真IDに基づく色の生成（一貫した色を返す）
    private var photoColor: Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .teal, .indigo, .mint, .cyan, .brown
        ]
        let hash = abs(photo.id.hashValue)
        return colors[hash % colors.count]
    }

    /// 写真IDに基づくSF Symbol
    private var photoIcon: String {
        if photo.id.contains("screenshot") {
            return "rectangle.on.rectangle"
        } else if photo.id.contains("selfie") {
            return "person.crop.circle"
        } else if photo.id.contains("blurry") {
            return "camera.metering.unknown"
        } else if photo.id.contains("duplicate") {
            return "doc.on.doc"
        } else if photo.id.contains("video") {
            return "video.fill"
        } else {
            // 類似写真用のバリエーション
            let icons = [
                "mountain.2.fill", "leaf.fill", "cup.and.saucer.fill",
                "building.2.fill", "sun.max.fill", "cloud.fill",
                "star.fill", "heart.fill", "camera.fill", "photo.fill"
            ]
            let hash = abs(photo.id.hashValue)
            return icons[hash % icons.count]
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                LinearGradient(
                    colors: [
                        photoColor.opacity(0.6),
                        photoColor.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // アイコン
                Image(systemName: photoIcon)
                    .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.35))
                    .foregroundStyle(.white.opacity(0.8))

                // ベストショットバッジ
                if showBadge {
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                            }
                            .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                // 選択状態
                if isSelected {
                    ZStack {
                        Color.blue.opacity(0.2)

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(4)
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

// MARK: - ScreenshotModeContentView

/// スクリーンショットモード時のメインビュー
/// 通常のContentViewの代わりに使用し、ダミーデータでUI全体を表示
@MainActor
public struct ScreenshotModeContentView: View {

    @State private var settingsService = SettingsService()
    @State private var selectedTab: ScreenshotTab = .home

    enum ScreenshotTab: Hashable {
        case home
        case groupList
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScreenshotHomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(ScreenshotTab.home)

            NavigationStack {
                ScreenshotGroupListView()
            }
            .tabItem {
                Label("グループ", systemImage: "rectangle.stack.fill")
            }
            .tag(ScreenshotTab.groupList)
        }
        .environment(settingsService)
    }
}

// MARK: - ScreenshotHomeView

/// スクリーンショットモード用のホーム画面
/// スキャン完了状態をシミュレート
@MainActor
struct ScreenshotHomeView: View {

    private let scanResult = ScreenshotModeData.scanResult
    private let statistics = ScreenshotModeData.storageStatistics

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.surfaceCard.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LRSpacing.lg) {
                    // ストレージ概要カード
                    StorageOverviewCard(
                        statistics: statistics,
                        displayStyle: .full,
                        onScanTap: nil,
                        onGroupTap: nil
                    )

                    // スキャン結果セクション
                    scanResultSection

                    // グループサマリーセクション
                    groupSummarySection

                    Spacer()
                        .frame(height: LRSpacing.xxl)
                }
                .padding(.horizontal, LRSpacing.md)
                .padding(.top, LRSpacing.sm)
            }
        }
        .navigationTitle(NSLocalizedString(
            "home.title",
            value: "ホーム",
            comment: "Home screen title"
        ))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            #endif
        }
    }

    /// スキャン結果セクション
    private var scanResultSection: some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(NSLocalizedString(
                    "home.scanResult.title",
                    value: "スキャン完了",
                    comment: "Scan result title"
                ))
                .font(.headline)
            }
            .padding(.horizontal, LRSpacing.xs)

            VStack(spacing: LRSpacing.sm) {
                ResultRow(
                    icon: "photo.stack",
                    label: NSLocalizedString("home.scanResult.photosScanned", value: "スキャン済み", comment: ""),
                    value: "\(scanResult.totalPhotosScanned)枚"
                )
                ResultRow(
                    icon: "rectangle.stack",
                    label: NSLocalizedString("home.scanResult.groupsFound", value: "グループ検出", comment: ""),
                    value: "\(scanResult.groupsFound)件"
                )
                ResultRow(
                    icon: "arrow.down.circle",
                    label: NSLocalizedString("home.scanResult.potentialSavings", value: "削減可能", comment: ""),
                    value: scanResult.formattedPotentialSavings
                )
                ResultRow(
                    icon: "clock",
                    label: NSLocalizedString("home.scanResult.duration", value: "所要時間", comment: ""),
                    value: scanResult.formattedDuration
                )
            }
            .padding(.vertical, LRSpacing.xs)
        }
        .padding(LRSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG))
    }

    /// グループサマリーセクション
    private var groupSummarySection: some View {
        VStack(alignment: .leading, spacing: LRSpacing.sm) {
            Text(NSLocalizedString(
                "home.quickActions.title",
                value: "クイックアクション",
                comment: "Quick actions section title"
            ))
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, LRSpacing.xs)

            // グループタイプ別のサマリーカード
            let groupedByType = Dictionary(grouping: ScreenshotModeData.groups) { $0.type }
            ForEach(Array(groupedByType.keys).sorted(), id: \.self) { type in
                if let typeGroups = groupedByType[type] {
                    HStack(spacing: LRSpacing.md) {
                        Image(systemName: type.icon)
                            .font(.title3)
                            .foregroundStyle(Color.LightRoll.primary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            let photoCount = typeGroups.reduce(0) { $0 + $1.count }
                            Text("\(typeGroups.count)グループ / \(photoCount)枚")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        let reclaimable = typeGroups.reduce(0) { $0 + $1.reclaimableSize }
                        Text(ByteCountFormatter.string(fromByteCount: reclaimable, countStyle: .file))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.LightRoll.success)
                    }
                    .padding(LRSpacing.sm)
                    .background(Color.LightRoll.surfaceCard.opacity(0.5), in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusMD))
                }
            }
        }
        .padding(LRSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LRLayout.cornerRadiusLG))
    }
}

// MARK: - ScreenshotGroupListView

/// スクリーンショットモード用のグループリスト画面
@MainActor
struct ScreenshotGroupListView: View {

    private let groups = ScreenshotModeData.groups
    @State private var selectedGroup: PhotoGroup?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.surfaceCard.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // サマリーヘッダー
                summaryHeader

                // グループリスト
                ScrollView {
                    LazyVStack(spacing: LRSpacing.md) {
                        ForEach(groups) { group in
                            screenshotGroupCard(for: group)
                        }
                    }
                    .padding(.horizontal, LRSpacing.md)
                    .padding(.vertical, LRSpacing.sm)
                }
            }
        }
        .navigationTitle(NSLocalizedString(
            "groupList.title",
            value: "グループ一覧",
            comment: "Group list title"
        ))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationDestination(item: $selectedGroup) { group in
            ScreenshotGroupDetailView(group: group)
        }
    }

    /// サマリーヘッダー
    private var summaryHeader: some View {
        HStack(spacing: LRSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("groupList.summary.groups", value: "グループ数", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(groups.count)")
                    .font(.headline)
            }

            Divider().frame(height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("groupList.summary.photos", value: "写真数", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(groups.totalPhotoCount)")
                    .font(.headline)
            }

            Divider().frame(height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("groupList.summary.reclaimable", value: "削減可能", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(groups.formattedTotalReclaimableSize)
                    .font(.headline)
                    .foregroundStyle(Color.LightRoll.success)
            }

            Spacer()
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThinMaterial)
    }

    /// グループカード（プレースホルダーサムネイル付き）
    private func screenshotGroupCard(for group: PhotoGroup) -> some View {
        Button {
            selectedGroup = group
        } label: {
            VStack(alignment: .leading, spacing: LRSpacing.md) {
                // ヘッダー
                HStack(spacing: LRSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.LightRoll.primary.opacity(0.2))
                            .frame(width: LRLayout.iconSizeXL, height: LRLayout.iconSizeXL)

                        Image(systemName: group.type.icon)
                            .font(.system(size: LRLayout.iconSizeMD))
                            .foregroundStyle(Color.LightRoll.primary)
                    }

                    Text(group.displayName)
                        .font(Font.LightRoll.headline)
                        .foregroundStyle(Color.LightRoll.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: LRLayout.iconSizeSM, weight: .semibold))
                        .foregroundStyle(Color.LightRoll.textTertiary)
                }

                // サムネイルプレビュー（プレースホルダー3枚）
                HStack(spacing: LRSpacing.gridSpacing) {
                    let previewPhotos = ScreenshotModeData.photos(for: Array(group.photoIds.prefix(3)))
                    ForEach(previewPhotos) { photo in
                        ScreenshotModeThumbnail(
                            photo: photo,
                            showBadge: group.bestShotId == photo.id
                        )
                        .frame(width: LRLayout.thumbnailSizeMD, height: LRLayout.thumbnailSizeMD)
                    }

                    if previewPhotos.count < 3 {
                        ForEach(0..<(3 - previewPhotos.count), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.LightRoll.surfaceCard)
                                .frame(width: LRLayout.thumbnailSizeMD, height: LRLayout.thumbnailSizeMD)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(Color.LightRoll.textTertiary)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // フッター
                HStack(spacing: LRSpacing.lg) {
                    HStack(spacing: LRSpacing.xs) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: LRLayout.iconSizeSM))
                            .foregroundStyle(Color.LightRoll.textSecondary)
                        Text("\(group.count)枚")
                            .font(Font.LightRoll.callout)
                            .foregroundStyle(Color.LightRoll.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: LRSpacing.xs) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: LRLayout.iconSizeSM))
                            .foregroundStyle(Color.LightRoll.success)
                        Text(group.formattedReclaimableSize)
                            .font(Font.LightRoll.smallNumber)
                            .foregroundStyle(Color.LightRoll.success)
                    }
                }
            }
            .padding(LRSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: LRLayout.cornerRadiusLG, style: .regular)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ScreenshotGroupDetailView

/// スクリーンショットモード用のグループ詳細画面
@MainActor
struct ScreenshotGroupDetailView: View {

    let group: PhotoGroup
    @State private var selectedPhotoIds: Set<String> = []

    private var photos: [Photo] {
        ScreenshotModeData.photos(for: group.photoIds)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.LightRoll.background,
                    Color.LightRoll.surfaceCard.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // サマリーヘッダー
                summaryHeader

                // 写真グリッド（プレースホルダー）
                ScrollView {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: LRSpacing.gridSpacing),
                            count: 3
                        ),
                        spacing: LRSpacing.gridSpacing
                    ) {
                        ForEach(photos) { photo in
                            ScreenshotModeThumbnail(
                                photo: photo,
                                isSelected: selectedPhotoIds.contains(photo.id),
                                showBadge: group.bestShotId == photo.id
                            )
                            .aspectRatio(1.0, contentMode: .fit)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedPhotoIds.contains(photo.id) {
                                        selectedPhotoIds.remove(photo.id)
                                    } else {
                                        selectedPhotoIds.insert(photo.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(LRSpacing.md)
                }

                // フローティングアクションバー
                if !selectedPhotoIds.isEmpty {
                    actionBar
                }
            }
        }
        .navigationTitle(group.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    /// サマリーヘッダー
    private var summaryHeader: some View {
        HStack(spacing: LRSpacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: group.type.icon)
                    .font(.title2)
                    .foregroundStyle(Color.LightRoll.primary)
                Text(group.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("groupDetail.summary.photos", value: "写真数", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(group.count)")
                    .font(.headline)
            }

            Divider().frame(height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("groupDetail.summary.reclaimable", value: "削減可能", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(group.formattedReclaimableSize)
                    .font(.headline)
                    .foregroundStyle(Color.LightRoll.success)
            }

            Spacer()
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThinMaterial)
    }

    /// アクションバー
    private var actionBar: some View {
        HStack(spacing: LRSpacing.lg) {
            Text("\(selectedPhotoIds.count)枚選択中")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                selectedPhotoIds.removeAll()
            } label: {
                Text("全解除")
                    .font(.subheadline)
            }

            Button(role: .destructive) {
                // スクリーンショットモードでは実際の削除は行わない
            } label: {
                HStack(spacing: LRSpacing.xs) {
                    Image(systemName: "trash")
                    Text("削除")
                }
            }
        }
        .padding(.horizontal, LRSpacing.lg)
        .padding(.vertical, LRSpacing.md)
        .background(.ultraThickMaterial)
    }
}

#endif
