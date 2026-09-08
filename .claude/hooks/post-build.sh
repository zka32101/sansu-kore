#!/bin/bash
# Post-build Hook: ビルド完了後の自動エミュレータテスト

APP_NAME="${1:-}"
if [ -z "$APP_NAME" ]; then
  echo "⚠️  アプリ名が指定されていません"
  exit 0
fi

echo ""
echo "🧪 Post-build テスト開始: $APP_NAME"
echo "========================================="
/build-and-test "$APP_NAME" || echo "⚠️  テスト実行中にエラー"
echo "========================================="
echo ""
