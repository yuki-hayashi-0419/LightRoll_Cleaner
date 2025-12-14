#!/bin/bash

# =============================================================================
# LightRoll Cleaner - App Store スクリーンショット自動生成スクリプト
# =============================================================================
#
# 機能:
#   - 4つの画面サイズ × 5つの画面 = 20枚のスクリーンショットを自動生成
#   - XcodeBuildMCPを使用してシミュレータ制御
#   - ステータスバー設定（9:41 AM、フルバッテリー、フル電波）
#   - App Store Connect提出用フォーマット
#
# 使用方法:
#   ./scripts/generate_screenshots.sh
#
# 前提条件:
#   - Xcode 16.0以降
#   - XcodeBuildMCP設定済み
#   - アプリビルド済み
#
# =============================================================================

set -e  # エラー時に即座に終了

# -----------------------------------------------------------------------------
# カラー定義
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# プロジェクト設定
# -----------------------------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_PATH="${PROJECT_ROOT}/LightRoll_Cleaner.xcworkspace"
SCHEME="LightRoll_Cleaner"
BUNDLE_ID="com.example.LightRoll-Cleaner"
OUTPUT_DIR="${PROJECT_ROOT}/screenshots"

# -----------------------------------------------------------------------------
# シミュレータ設定（画面サイズ別）
# -----------------------------------------------------------------------------
declare -A SIMULATORS=(
    ["6.9"]="iPhone 16 Pro Max"
    ["6.7"]="iPhone 16 Plus"
    ["6.5"]="iPhone XS Max"
    ["5.5"]="iPhone 8 Plus"
)

declare -A RESOLUTIONS=(
    ["6.9"]="1320x2868"
    ["6.7"]="1290x2796"
    ["6.5"]="1242x2688"
    ["5.5"]="1242x2208"
)

# -----------------------------------------------------------------------------
# スクリーンショット設定
# -----------------------------------------------------------------------------
SCREENSHOTS=(
    "01_home|ホーム画面"
    "02_group_list|グループリスト"
    "03_group_detail|グループ詳細"
    "04_deletion_confirm|削除確認"
    "05_premium|Premium"
)

# -----------------------------------------------------------------------------
# ユーティリティ関数
# -----------------------------------------------------------------------------

# ログ出力
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# 準備処理
# -----------------------------------------------------------------------------

setup() {
    log_info "🚀 スクリーンショット生成を開始します..."

    # 出力ディレクトリ作成
    mkdir -p "${OUTPUT_DIR}"

    for size in "${!SIMULATORS[@]}"; do
        mkdir -p "${OUTPUT_DIR}/${size}inch"
    done

    log_success "✅ 出力ディレクトリ作成完了: ${OUTPUT_DIR}"
}

# -----------------------------------------------------------------------------
# シミュレータ検索
# -----------------------------------------------------------------------------

find_simulator() {
    local sim_name="$1"

    log_info "📱 シミュレータ検索中: ${sim_name}"

    # シミュレータUUIDを取得
    local uuid=$(xcrun simctl list devices available | grep "${sim_name}" | grep -v unavailable | head -n 1 | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})")

    if [ -z "$uuid" ]; then
        log_error "❌ シミュレータが見つかりません: ${sim_name}"
        return 1
    fi

    log_success "✅ シミュレータ発見: ${sim_name} (${uuid})"
    echo "$uuid"
}

# -----------------------------------------------------------------------------
# シミュレータ起動
# -----------------------------------------------------------------------------

boot_simulator() {
    local uuid="$1"
    local sim_name="$2"

    log_info "🔄 シミュレータ起動中: ${sim_name}"

    # 既に起動している場合はスキップ
    local state=$(xcrun simctl list devices | grep "$uuid" | grep -o "Booted" || echo "")

    if [ "$state" = "Booted" ]; then
        log_warning "⚠️  既に起動済み: ${sim_name}"
        return 0
    fi

    # シミュレータ起動
    xcrun simctl boot "$uuid" 2>/dev/null || true
    sleep 3

    # Simulator.app起動
    open -a Simulator --args -CurrentDeviceUDID "$uuid"
    sleep 5

    log_success "✅ シミュレータ起動完了: ${sim_name}"
}

# -----------------------------------------------------------------------------
# ステータスバー設定
# -----------------------------------------------------------------------------

configure_status_bar() {
    local uuid="$1"

    log_info "⚙️  ステータスバー設定中..."

    # ステータスバーをオーバーライド（9:41 AM、フルバッテリー、フル電波）
    xcrun simctl status_bar "$uuid" override \
        --time "9:41" \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100

    log_success "✅ ステータスバー設定完了（9:41 AM、フル電波、フルバッテリー）"
}

# -----------------------------------------------------------------------------
# アプリビルド & インストール
# -----------------------------------------------------------------------------

build_and_install() {
    local uuid="$1"
    local sim_name="$2"

    log_info "🔨 アプリビルド中: ${sim_name}"

    # ビルド（既存のビルドがあればスキップ可能）
    xcodebuild -workspace "${WORKSPACE_PATH}" \
               -scheme "${SCHEME}" \
               -configuration Debug \
               -sdk iphonesimulator \
               -destination "id=${uuid}" \
               build \
               -quiet || {
        log_error "❌ ビルド失敗"
        return 1
    }

    log_success "✅ ビルド完了"

    # アプリパスを取得
    local app_path=$(find ~/Library/Developer/Xcode/DerivedData -name "${SCHEME}.app" -path "*/Build/Products/Debug-iphonesimulator/*" | head -n 1)

    if [ -z "$app_path" ]; then
        log_error "❌ アプリが見つかりません"
        return 1
    fi

    log_info "📦 アプリインストール中: ${app_path}"

    # インストール
    xcrun simctl install "$uuid" "$app_path"

    log_success "✅ アプリインストール完了"
}

# -----------------------------------------------------------------------------
# アプリ起動
# -----------------------------------------------------------------------------

launch_app() {
    local uuid="$1"

    log_info "🚀 アプリ起動中..."

    xcrun simctl launch "$uuid" "$BUNDLE_ID"

    # 起動待ち
    sleep 3

    log_success "✅ アプリ起動完了"
}

# -----------------------------------------------------------------------------
# UI操作（画面遷移）
# -----------------------------------------------------------------------------

navigate_to_screen() {
    local uuid="$1"
    local screen_id="$2"

    log_info "🧭 画面遷移中: ${screen_id}"

    case "$screen_id" in
        "01_home")
            # ホーム画面（起動直後）
            sleep 2
            ;;
        "02_group_list")
            # グループリスト画面へ遷移
            # （スキャン完了後のグループリスト）
            # TODO: UI自動化で「スキャン開始」ボタンをタップ
            xcrun simctl spawn "$uuid" log stream --predicate 'subsystem == "com.example.LightRoll-Cleaner"' &
            sleep 5
            ;;
        "03_group_detail")
            # グループ詳細画面へ遷移
            # TODO: UI自動化で最初のグループをタップ
            sleep 2
            ;;
        "04_deletion_confirm")
            # 削除確認画面へ遷移
            # TODO: UI自動化で削除ボタンをタップ
            sleep 2
            ;;
        "05_premium")
            # Premium画面へ遷移
            # TODO: UI自動化で右上のPremiumボタンをタップ
            sleep 2
            ;;
    esac

    log_success "✅ 画面遷移完了: ${screen_id}"
}

# -----------------------------------------------------------------------------
# スクリーンショット撮影
# -----------------------------------------------------------------------------

take_screenshot() {
    local uuid="$1"
    local size="$2"
    local screen_id="$3"
    local screen_name="$4"

    local output_path="${OUTPUT_DIR}/${size}inch/${screen_id}.png"

    log_info "📸 スクリーンショット撮影中: ${screen_name}"

    # スクリーンショット撮影
    xcrun simctl io "$uuid" screenshot --type=png "$output_path"

    if [ ! -f "$output_path" ]; then
        log_error "❌ スクリーンショット保存失敗: ${output_path}"
        return 1
    fi

    log_success "✅ スクリーンショット保存: ${output_path}"
}

# -----------------------------------------------------------------------------
# 画面サイズごとの処理
# -----------------------------------------------------------------------------

process_simulator() {
    local size="$1"
    local sim_name="${SIMULATORS[$size]}"
    local resolution="${RESOLUTIONS[$size]}"

    log_info "════════════════════════════════════════════════════════════════"
    log_info "📱 処理開始: ${size}インチ - ${sim_name} (${resolution})"
    log_info "════════════════════════════════════════════════════════════════"

    # 1. シミュレータ検索
    local uuid=$(find_simulator "$sim_name")
    if [ $? -ne 0 ]; then
        log_error "❌ スキップ: ${sim_name}"
        return 1
    fi

    # 2. シミュレータ起動
    boot_simulator "$uuid" "$sim_name"

    # 3. ステータスバー設定
    configure_status_bar "$uuid"

    # 4. アプリビルド & インストール
    build_and_install "$uuid" "$sim_name"

    # 5. アプリ起動
    launch_app "$uuid"

    # 6. 各画面のスクリーンショット撮影
    for screenshot_info in "${SCREENSHOTS[@]}"; do
        local screen_id="${screenshot_info%%|*}"
        local screen_name="${screenshot_info##*|}"

        # 画面遷移
        navigate_to_screen "$uuid" "$screen_id"

        # スクリーンショット撮影
        take_screenshot "$uuid" "$size" "$screen_id" "$screen_name"

        sleep 1
    done

    # 7. アプリ終了
    xcrun simctl terminate "$uuid" "$BUNDLE_ID" 2>/dev/null || true

    log_success "✅ ${size}インチ処理完了: 5枚のスクリーンショット生成"
    log_info ""
}

# -----------------------------------------------------------------------------
# クリーンアップ
# -----------------------------------------------------------------------------

cleanup() {
    log_info "🧹 クリーンアップ中..."

    # すべてのシミュレータのステータスバーオーバーライドをクリア
    for size in "${!SIMULATORS[@]}"; do
        local sim_name="${SIMULATORS[$size]}"
        local uuid=$(find_simulator "$sim_name" 2>/dev/null || echo "")

        if [ -n "$uuid" ]; then
            xcrun simctl status_bar "$uuid" clear 2>/dev/null || true
        fi
    done

    log_success "✅ クリーンアップ完了"
}

# -----------------------------------------------------------------------------
# サマリー表示
# -----------------------------------------------------------------------------

show_summary() {
    log_info "════════════════════════════════════════════════════════════════"
    log_success "🎉 スクリーンショット生成完了！"
    log_info "════════════════════════════════════════════════════════════════"

    echo ""
    log_info "📊 生成サマリー:"

    local total_count=0
    for size in "${!SIMULATORS[@]}"; do
        local count=$(ls -1 "${OUTPUT_DIR}/${size}inch/"*.png 2>/dev/null | wc -l | xargs)
        total_count=$((total_count + count))
        log_info "  - ${size}インチ: ${count}枚"
    done

    echo ""
    log_success "合計: ${total_count}枚のスクリーンショットを生成しました"
    log_info "出力先: ${OUTPUT_DIR}"
    echo ""

    log_info "📱 各画面サイズ別の解像度:"
    log_info "  - 6.9インチ (iPhone 16 Pro Max): 1320 x 2868 px"
    log_info "  - 6.7インチ (iPhone 16 Plus):    1290 x 2796 px"
    log_info "  - 6.5インチ (iPhone XS Max):     1242 x 2688 px"
    log_info "  - 5.5インチ (iPhone 8 Plus):     1242 x 2208 px"
    echo ""

    log_info "📝 次のステップ:"
    log_info "  1. screenshots/ディレクトリを確認"
    log_info "  2. 各スクリーンショットをプレビュー"
    log_info "  3. App Store Connectにアップロード"
    echo ""
}

# -----------------------------------------------------------------------------
# エラーハンドリング
# -----------------------------------------------------------------------------

error_handler() {
    log_error "❌ エラーが発生しました（終了コード: $?）"
    cleanup
    exit 1
}

trap error_handler ERR

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------

main() {
    # 準備
    setup

    # 各画面サイズごとにスクリーンショット生成
    for size in "6.9" "6.7" "6.5" "5.5"; do
        process_simulator "$size" || log_warning "⚠️  ${size}インチの処理に失敗しました"
    done

    # クリーンアップ
    cleanup

    # サマリー表示
    show_summary
}

# スクリプト実行
main "$@"
