import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color Palette
/// LightRoll アプリケーションのデザインシステム - カラーパレット定義
/// ダークモード/ライトモード両対応
public extension Color {
    /// LightRoll アプリ専用のカラーパレット
    struct LightRoll {
        // MARK: - Primary Colors
        /// メインブランドカラー（青）
        public static let primary = Color("Primary", bundle: .module)
        /// セカンダリブランドカラー（紫）
        public static let secondary = Color("Secondary", bundle: .module)
        /// アクセントカラー（オレンジ）
        public static let accent = Color("Accent", bundle: .module)

        // MARK: - Background Colors
        /// メイン背景色
        public static let background = Color("Background", bundle: .module)
        /// カード表面の背景色
        public static let surfaceCard = Color("SurfaceCard", bundle: .module)
        /// オーバーレイ表面の背景色
        public static let surfaceOverlay = Color("SurfaceOverlay", bundle: .module)

        // MARK: - Text Colors
        /// 主要テキストカラー
        public static let textPrimary = Color("TextPrimary", bundle: .module)
        /// 補助テキストカラー
        public static let textSecondary = Color("TextSecondary", bundle: .module)
        /// 第三テキストカラー（プレースホルダー等）
        public static let textTertiary = Color("TextTertiary", bundle: .module)

        // MARK: - Semantic Colors
        /// 成功状態を示す色（緑）
        public static let success = Color("Success", bundle: .module)
        /// 警告状態を示す色（オレンジ）
        public static let warning = Color("Warning", bundle: .module)
        /// エラー状態を示す色（赤）
        public static let error = Color("Error", bundle: .module)
        /// 情報を示す色（青）
        public static let info = Color("Info", bundle: .module)

        // MARK: - Storage Indicator Colors
        /// ストレージ使用中を示す色
        public static let storageUsed = Color("StorageUsed", bundle: .module)
        /// ストレージ空き容量を示す色
        public static let storageFree = Color("StorageFree", bundle: .module)
        /// 写真ストレージを示す色
        public static let storagePhotos = Color("StoragePhotos", bundle: .module)
    }
}

// MARK: - Color Scheme Helper
/// カラースキームに関するヘルパー
#if canImport(UIKit)
public extension Color.LightRoll {
    /// 現在のカラースキームに基づいて適切な色を返す（iOS専用）
    /// - Parameters:
    ///   - light: ライトモード時の色
    ///   - dark: ダークモード時の色
    /// - Returns: 適切な色
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
#endif
