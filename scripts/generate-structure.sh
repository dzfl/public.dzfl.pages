#!/usr/bin/env bash
# generate-structure.sh
# source/ のMDファイルを .gen/content/ にフラット展開してHugo用構造を生成する
#
# セクション判定:
#   source/blog/** → 日付平坦化（dateフロントマター + ファイル名でファイル名生成）
#   それ以外       → source/ からの相対パス構造をそのまま維持

set -euo pipefail

SOURCE_DIR="source"
CONTENT_OUT=".gen/content"

mkdir -p "$CONTENT_OUT"

# フロントマターからdateを抽出する関数
get_date() {
  local md_file="$1"
  grep -m1 '^date:' "$md_file" | sed 's/date:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

# source/ を再帰走査してMDファイルを分類・コピー
while IFS= read -r -d '' md; do
  filename="$(basename "$md")"

  if [[ "$md" == "${SOURCE_DIR}/blog/"* ]]; then
    # blogセクション: dateフロントマターから日付を取得してファイル名を組み立て・フラット展開
    date="$(get_date "$md")"
    if [ -z "$date" ]; then
      echo "❌ dateフロントマターが見つかりません: $md"
      exit 1
    fi
    slug="$(basename "$md" .md)"
    dest="${CONTENT_OUT}/blog/${date}-${slug}.md"
    mkdir -p "${CONTENT_OUT}/blog"

  else
    # それ以外: source/ からの相対パス構造をそのまま維持
    rel_path="${md#"${SOURCE_DIR}/"}"
    dest="${CONTENT_OUT}/${rel_path}"
    mkdir -p "$(dirname "$dest")"
  fi

  cp "$md" "$dest"
  echo "  コピー: $md → $dest"

done < <(find "$SOURCE_DIR" -name "*.md" \
  ! -path "*/attachments/*" \
  -print0)

echo "✅ Hugo用構造生成: 完了"
