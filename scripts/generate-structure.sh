#!/usr/bin/env bash
# generate-structure.sh
# source/ のMDファイルを .gen/content/ にフラット展開してHugo用構造を生成する
#
# blogセクション: MDのdateフロントマターから日付を取得してファイル名を組み立てる
# 例: slug.md (date: 2026-01-27) → .gen/content/blog/2026-01-27-slug.md

set -euo pipefail

SOURCE_DIR="source"
CONTENT_OUT=".gen/content"

mkdir -p "$CONTENT_OUT"
mkdir -p "${CONTENT_OUT}/blog"
mkdir -p "${CONTENT_OUT}/docs"

# フロントマターからdateを抽出する関数
get_date() {
  local md_file="$1"
  grep -m1 '^date:' "$md_file" | sed 's/date:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

# source/ を再帰走査してMDファイルを分類・コピー
while IFS= read -r -d '' md; do
  filename="$(basename "$md")"

  if [[ "$md" == source/blog/* ]]; then
    # blogセクション: dateフロントマターから日付を取得してファイル名を組み立てる
    date="$(get_date "$md")"
    if [ -z "$date" ]; then
      echo "❌ dateフロントマターが見つかりません: $md"
      exit 1
    fi
    slug="$(basename "$md" .md)"
    dest="${CONTENT_OUT}/blog/${date}-${slug}.md"

  elif [[ "$md" == source/docs/* ]]; then
    # docsセクション: フラット展開
    dest="${CONTENT_OUT}/docs/${filename}"

  else
    # source/ 直下（_index.md・固定ページ）: そのままコピー
    dest="${CONTENT_OUT}/${filename}"
  fi

  cp "$md" "$dest"
  echo "  コピー: $md → $dest"

done < <(find "$SOURCE_DIR" -name "*.md" \
  ! -path "*/attachments/*" \
  -print0)

echo "✅ Hugo用構造生成: 完了"
