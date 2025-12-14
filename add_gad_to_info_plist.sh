#!/bin/bash
# Google AdMob App IDをInfo.plistに追加するスクリプト

PLIST_PATH="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

if [ -f "$PLIST_PATH" ]; then
    /usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string ca-app-pub-3940256099942544~1458002511" "$PLIST_PATH" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier ca-app-pub-3940256099942544~1458002511" "$PLIST_PATH"
    echo "✅ GADApplicationIdentifier added to Info.plist"
else
    echo "❌ Info.plist not found at $PLIST_PATH"
    exit 1
fi
