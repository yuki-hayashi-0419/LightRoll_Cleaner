#!/bin/bash
#
# App Store提出チェックリスト検証スクリプト
#
# このスクリプトは、APP_STORE_SUBMISSION_CHECKLIST.mdの品質と完全性を
# 自動で検証します。実際のApp Store提出前に実行してください。
#
# 使用方法:
#   ./scripts/validate_app_store_checklist.sh
#
# 戻り値:
#   0: 検証成功（すべてのチェックPASS）
#   1: 検証失敗（1つ以上のチェックFAIL）

set -euo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# カウンター
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# プロジェクトルート
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKLIST_PATH="${PROJECT_ROOT}/docs/CRITICAL/APP_STORE_SUBMISSION_CHECKLIST.md"

# ヘッダー出力
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}App Store提出チェックリスト検証${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# チェック1: ファイル存在確認
echo -e "${YELLOW}[Check 1/10]${NC} ドキュメント存在確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "$CHECKLIST_PATH" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - ファイルが存在します"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - ファイルが見つかりません: $CHECKLIST_PATH"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    exit 1
fi

# チェック2: ファイルサイズ確認
echo -e "${YELLOW}[Check 2/10]${NC} ファイルサイズ確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

FILE_SIZE=$(wc -c < "$CHECKLIST_PATH" | tr -d ' ')
if [ "$FILE_SIZE" -gt 1000 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - ファイルサイズ: ${FILE_SIZE} bytes (>1KB)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - ファイルが小さすぎます: ${FILE_SIZE} bytes"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック3: チェックボックス数確認
echo -e "${YELLOW}[Check 3/10]${NC} チェックボックス数確認（最低50個）..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

CHECKBOX_COUNT=$(grep -c "^- \[ \]" "$CHECKLIST_PATH" || true)
if [ "$CHECKBOX_COUNT" -ge 50 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - チェックボックス数: ${CHECKBOX_COUNT}個 (≥50)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - チェックボックスが不足: ${CHECKBOX_COUNT}個 (<50)"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック4: 必須セクション存在確認
echo -e "${YELLOW}[Check 4/10]${NC} 必須セクション存在確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

REQUIRED_SECTIONS=(
    "## 概要"
    "## 📋 提出前必須チェック項目"
    "### ✅ アプリビルド準備"
    "### ✅ App Store Connect設定"
    "### ✅ スクリーンショット要件"
    "### ✅ アプリ説明文（日本語）"
    "### ✅ プライバシーポリシー"
    "### ✅ 審査ガイドライン対応"
    "### ✅ テストフライト配信"
    "### ✅ 最終確認"
    "## 📊 提出手順"
    "## 🚨 よくあるリジェクト理由と対策"
)

SECTION_PASS=true
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "$section" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - セクションが見つかりません: $section"
        SECTION_PASS=false
    fi
done

if [ "$SECTION_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - すべての必須セクションが存在します"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック5: 重要キーワード存在確認
echo -e "${YELLOW}[Check 5/10]${NC} 重要キーワード存在確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

REQUIRED_KEYWORDS=(
    "Archive"
    "Distribution"
    "App Store Connect"
    "スクリーンショット"
    "In-App Purchase"
    "審査"
    "プライバシーポリシー"
    "1.0.0"
    "iOS 18.0"
)

KEYWORD_PASS=true
for keyword in "${REQUIRED_KEYWORDS[@]}"; do
    if ! grep -q "$keyword" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - キーワードが見つかりません: $keyword"
        KEYWORD_PASS=false
    fi
done

if [ "$KEYWORD_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - すべての重要キーワードが存在します"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック6: アプリ情報の一貫性
echo -e "${YELLOW}[Check 6/10]${NC} アプリ情報の一貫性確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

APP_NAME_COUNT=$(grep -c "LightRoll Cleaner" "$CHECKLIST_PATH" || true)
BUNDLE_ID_COUNT=$(grep -c "com.example.LightRoll-Cleaner" "$CHECKLIST_PATH" || true)

if [ "$APP_NAME_COUNT" -ge 5 ] && [ "$BUNDLE_ID_COUNT" -ge 3 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - アプリ名: ${APP_NAME_COUNT}箇所, バンドルID: ${BUNDLE_ID_COUNT}箇所"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - アプリ情報の記載が不足しています"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック7: In-App Purchase設定の完全性
echo -e "${YELLOW}[Check 7/10]${NC} In-App Purchase設定確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

IAP_PASS=true
IAP_PRODUCTS=(
    "com.example.LightRoll-Cleaner.premium.monthly"
    "com.example.LightRoll-Cleaner.premium.yearly"
    "com.example.LightRoll-Cleaner.premium.lifetime"
)

for product_id in "${IAP_PRODUCTS[@]}"; do
    if ! grep -q "$product_id" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - Product IDが見つかりません: $product_id"
        IAP_PASS=false
    fi
done

if [ "$IAP_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - In-App Purchase設定が完全です"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック8: スクリーンショット要件の網羅性
echo -e "${YELLOW}[Check 8/10]${NC} スクリーンショット要件確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

SCREENSHOT_PASS=true
SCREENSHOT_SIZES=(
    "6.9インチ"
    "6.7インチ"
    "6.5インチ"
    "5.5インチ"
)

for size in "${SCREENSHOT_SIZES[@]}"; do
    if ! grep -q "$size" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - スクリーンショットサイズが見つかりません: $size"
        SCREENSHOT_PASS=false
    fi
done

if [ "$SCREENSHOT_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - スクリーンショット要件が完全です"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック9: 審査ガイドライン対応確認
echo -e "${YELLOW}[Check 9/10]${NC} 審査ガイドライン対応確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

GUIDELINE_PASS=true
GUIDELINES=(
    "Guideline 2.1"
    "Guideline 2.3"
    "Guideline 3.1"
    "Guideline 4.0"
    "Guideline 5.1.1"
    "Guideline 5.1.2"
)

for guideline in "${GUIDELINES[@]}"; do
    if ! grep -q "$guideline" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - ガイドラインが見つかりません: $guideline"
        GUIDELINE_PASS=false
    fi
done

if [ "$GUIDELINE_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - 審査ガイドライン対応が完全です"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# チェック10: 提出手順の完全性
echo -e "${YELLOW}[Check 10/10]${NC} 提出手順の完全性確認..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

STEPS_PASS=true
SUBMISSION_STEPS=(
    "Step 1: Archive作成"
    "Step 2: Validation"
    "Step 3: Upload"
    "Step 4: App Store Connectで設定"
    "Step 5: 審査待ち"
    "Step 6: 承認後"
)

for step in "${SUBMISSION_STEPS[@]}"; do
    if ! grep -q "$step" "$CHECKLIST_PATH"; then
        echo -e "  ${RED}✗ FAIL${NC} - 提出手順が見つかりません: $step"
        STEPS_PASS=false
    fi
done

if [ "$STEPS_PASS" = true ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - 提出手順が完全です"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 結果サマリー
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}検証結果サマリー${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "総チェック数: ${TOTAL_CHECKS}"
echo -e "${GREEN}成功: ${PASSED_CHECKS}${NC}"
echo -e "${RED}失敗: ${FAILED_CHECKS}${NC}"
echo ""

if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "${GREEN}✓ すべてのチェックが成功しました！${NC}"
    echo -e "${GREEN}App Store提出チェックリストは品質基準を満たしています。${NC}"
    exit 0
else
    echo -e "${RED}✗ 検証に失敗しました。${NC}"
    echo -e "${RED}上記のエラーを修正してから再度実行してください。${NC}"
    exit 1
fi
