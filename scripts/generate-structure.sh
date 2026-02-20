#!/usr/bin/env bash
# generate-structure.sh
# source/ のMDファイルを .gen/content/ にフラット展開してHugo用構造を生成する

set -euo pipefail

SOURCE_DIR="source"
CONTENT_OUT=".gen/content"

mkdir -p "$CONTENT_OUT"
mkdir -p "${CONTENT_OUT}/blog"
mkdir -p "${CONTENT_OUT}/docs"

# source/ を再帰走査してMDファイルを分類・コピー
while IFS= read -r -d '' md; do
  filename="$(basename "$md")"
  rel_path="${md#"${SOURCE_DIR}/"}"

  if [[ "$md" == source/blog/* ]]; then
    # blog: 年月ディレクトリを除去してフラット展開
    dest="${CONTENT_OUT}/blog/${filename}"
  elif [[ "$md" == source/docs/* ]]; then
    # docs: フラット展開
    dest="${CONTENT_OUT}/docs/${filename}"
  else
    # source/ 直下（_index.md・固定ページ）
    dest="${CONTENT_OUT}/${filename}"
  fi

  cp "$md" "$dest"
  echo "  コピー: $md → $dest"

done < <(find "$SOURCE_DIR" -name "*.md" \
  ! -path "*/attachments/*" \
  -print0)

echo "✅ Hugo用構造生成: 完了"
