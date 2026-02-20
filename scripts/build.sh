#!/usr/bin/env bash
# build.sh
# Hugo をビルドする

set -euo pipefail

HUGO_DIR="hugo"
PUBLIC_OUT=".gen/public"

# 出力ディレクトリをクリーン
rm -rf "$PUBLIC_OUT"

# hugo/ ディレクトリに移動してビルド実行
cd "$HUGO_DIR"
hugo --minify

echo "✅ Hugo ビルド: 完了"
