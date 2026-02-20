#!/usr/bin/env bash
# generate-structure.sh
# source/ のMDファイルを .gen/content/ にフラット展開してHugo用構造を生成する
#
# セクション判定:
#   source/blog/** → blog セクション（年月ディレクトリを除去してフラット展開）
#   それ以外       → source/ からの相対パス構造をそのまま維持
#
# フロントマターへの依存なし
# MDファイル名がそのまま公開URLのslugになる

set -euo pipefail

SOURCE_DIR="source"
CONTENT_OUT=".gen/content"

mkdir -p "$CONTENT_OUT"

# source/ を再帰走査してMDファイルを分類・コピー
while IFS= read -r -d '' md; do
  filename="$(basename "$md")"

  if [[ "$md" == "${SOURCE_DIR}/blog/"* ]]; then
    # blogセクション: 年月ディレクトリを除去してフラット展開
    dest="${CONTENT_OUT}/blog/${filename}"
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
