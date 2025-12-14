#!/bin/bash
# スクリーンショット検証スクリプト
# M10-T02: スクリーンショット作成タスクの自動検証

set -e  # エラー時に即座に終了

# ========================================
# 設定
# ========================================

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOTS_DIR="$PROJECT_ROOT/screenshots"
GENERATE_SCRIPT="$PROJECT_ROOT/scripts/generate_screenshots.sh"

# 色コード
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# カウンター
total_checks=0
passed_checks=0
failed_checks=0

# ========================================
# ヘルパー関数
# ========================================

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

print_check() {
    total_checks=$((total_checks + 1))
    echo -e "${BLUE}[Check $total_checks/$1]${NC} $2"
}

print_pass() {
    passed_checks=$((passed_checks + 1))
    echo -e "  ${GREEN}✓ PASS${NC} - $1"
}

print_fail() {
    failed_checks=$((failed_checks + 1))
    echo -e "  ${RED}❌ FAIL${NC} - $1"
}

print_warn() {
    echo -e "  ${YELLOW}⚠ WARN${NC} - $1"
}

# ========================================
# テストケース関数
# ========================================

# TC-01: スクリプト実行可能性確認
test_script_executable() {
    print_check 4 "スクリプト実行可能性確認..."

    # スクリプトファイルの存在確認
    if [ -f "$GENERATE_SCRIPT" ]; then
        print_pass "generate_screenshots.sh が存在します"
    else
        print_fail "generate_screenshots.sh が見つかりません: $GENERATE_SCRIPT"
        return 1
    fi

    # 実行権限の確認
    if [ -x "$GENERATE_SCRIPT" ]; then
        print_pass "実行権限があります"
    else
        print_fail "実行権限がありません（chmod +x が必要）"
        return 1
    fi
}

# TC-02: 全スクリーンショットファイル生成確認
test_all_files_generated() {
    print_check 4 "ファイル生成確認..."

    # screenshots/ ディレクトリの存在確認
    if [ -d "$SCREENSHOTS_DIR" ]; then
        print_pass "screenshots/ ディレクトリが存在します"
    else
        print_fail "screenshots/ ディレクトリが見つかりません"
        return 1
    fi

    # デバイスごとのファイル数確認
    local devices=("6.9inch" "6.7inch" "6.5inch" "5.5inch")
    local expected_count=5

    for device in "${devices[@]}"; do
        local count=$(find "$SCREENSHOTS_DIR" -name "${device}_*.png" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -eq "$expected_count" ]; then
            print_pass "$device: ${count}枚"
        else
            print_fail "$device: ${count}枚（期待値: ${expected_count}枚）"
            return 1
        fi
    done

    # 合計ファイル数確認
    local total_count=$(find "$SCREENSHOTS_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    local expected_total=$((expected_count * ${#devices[@]}))

    if [ "$total_count" -eq "$expected_total" ]; then
        print_pass "合計${total_count}枚"
    else
        print_fail "合計${total_count}枚（期待値: ${expected_total}枚）"
        return 1
    fi
}

# TC-03: 画像解像度正確性確認
test_image_resolution() {
    print_check 4 "画像解像度確認..."

    # デバイスごとの期待解像度
    declare -A expected_resolutions
    expected_resolutions["6.9inch"]="1320x2868"
    expected_resolutions["6.7inch"]="1290x2796"
    expected_resolutions["6.5inch"]="1242x2688"
    expected_resolutions["5.5inch"]="1242x2208"

    local all_passed=true

    for device in "${!expected_resolutions[@]}"; do
        local expected="${expected_resolutions[$device]}"
        local expected_width=$(echo "$expected" | cut -d'x' -f1)
        local expected_height=$(echo "$expected" | cut -d'x' -f2)

        # デバイスごとのファイルをチェック
        for file in "$SCREENSHOTS_DIR/${device}_"*.png; do
            if [ ! -f "$file" ]; then
                continue
            fi

            local filename=$(basename "$file")

            # sips コマンドで解像度取得
            local width=$(sips -g pixelWidth "$file" 2>/dev/null | tail -1 | awk '{print $2}')
            local height=$(sips -g pixelHeight "$file" 2>/dev/null | tail -1 | awk '{print $2}')

            if [ "$width" -eq "$expected_width" ] && [ "$height" -eq "$expected_height" ]; then
                print_pass "$filename: ${width}x${height}"
            else
                print_fail "$filename: ${width}x${height} (期待値: ${expected})"
                all_passed=false
            fi
        done
    done

    if [ "$all_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# TC-04: ファイル形式妥当性確認
test_file_format() {
    print_check 4 "ファイル形式確認..."

    local all_passed=true
    local min_size=102400  # 100KB
    local max_size=10485760  # 10MB

    for file in "$SCREENSHOTS_DIR"/*.png; do
        if [ ! -f "$file" ]; then
            continue
        fi

        local filename=$(basename "$file")

        # ファイル形式確認
        local file_type=$(file "$file" | grep -o "PNG image data")
        if [ -z "$file_type" ]; then
            print_fail "$filename - PNG形式ではありません"
            all_passed=false
            continue
        fi

        # ファイルサイズ確認（macOS/Linux互換）
        local size
        if [[ "$OSTYPE" == "darwin"* ]]; then
            size=$(stat -f%z "$file" 2>/dev/null)
        else
            size=$(stat -c%s "$file" 2>/dev/null)
        fi

        if [ "$size" -lt "$min_size" ]; then
            print_fail "$filename - ファイルサイズが小さすぎます (${size} bytes < 100KB)"
            all_passed=false
        elif [ "$size" -gt "$max_size" ]; then
            print_fail "$filename - ファイルサイズが大きすぎます (${size} bytes > 10MB)"
            all_passed=false
        fi
    done

    if [ "$all_passed" = true ]; then
        print_pass "全ファイルがPNG形式です"
        print_pass "ファイルサイズが適切です（100KB〜10MB）"
        return 0
    else
        return 1
    fi
}

# ========================================
# メイン実行
# ========================================

main() {
    print_header "スクリーンショット検証"

    # TC-01: スクリプト実行可能性確認
    if test_script_executable; then
        echo ""
    else
        echo ""
        echo -e "${RED}スクリプト実行可能性の検証に失敗しました${NC}"
        exit 1
    fi

    # screenshots/ ディレクトリが存在しない場合は警告
    if [ ! -d "$SCREENSHOTS_DIR" ]; then
        echo ""
        print_warn "screenshots/ ディレクトリが存在しません"
        print_warn "まず generate_screenshots.sh を実行してください"
        echo ""
        echo "実行方法:"
        echo "  ./scripts/generate_screenshots.sh"
        echo ""
        exit 1
    fi

    # TC-02: 全ファイル生成確認
    if test_all_files_generated; then
        echo ""
    else
        echo ""
        echo -e "${RED}ファイル生成確認に失敗しました${NC}"
        exit 1
    fi

    # TC-03: 画像解像度確認
    if test_image_resolution; then
        echo ""
    else
        echo ""
        echo -e "${RED}画像解像度確認に失敗しました${NC}"
        exit 1
    fi

    # TC-04: ファイル形式確認
    if test_file_format; then
        echo ""
    else
        echo ""
        echo -e "${RED}ファイル形式確認に失敗しました${NC}"
        exit 1
    fi

    # 結果サマリー
    print_header "検証結果サマリー"
    echo "総チェック数: $total_checks"
    echo -e "成功: ${GREEN}$passed_checks${NC}"
    echo -e "失敗: ${RED}$failed_checks${NC}"
    echo ""

    if [ "$failed_checks" -eq 0 ]; then
        echo -e "${GREEN}✓ すべてのチェックが成功しました！${NC}"
        echo "スクリーンショットはApp Store Connect要件を満たしています。"
        echo ""
        echo "次のステップ:"
        echo "  1. open screenshots/ でスクリーンショットを目視確認"
        echo "  2. App Store Connectにアップロード"
        echo ""
        exit 0
    else
        echo -e "${RED}✗ 検証に失敗しました${NC}"
        echo ""
        echo "対処方法:"
        echo "  1. エラーメッセージを確認"
        echo "  2. generate_screenshots.sh を再実行"
        echo "  3. 必要に応じて手動でスクリーンショットを修正"
        echo ""
        exit 1
    fi
}

# スクリプト実行
main
