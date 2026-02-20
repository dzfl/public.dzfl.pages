#!/usr/bin/env bash
# validate.sh
# attachments/ 内の画像ファイルが命名規則に従っているか検証する
# 違反を全件収集してから exit 1 で停止する

set -euo pipefail

SOURCE_DIR="source"
ERRORS=()

# attachments/ ディレクトリを全件探索
while IFS= read -r -d '' attachments_dir; do
  parent_dir="$(dirname "$attachments_dir")"

  # 同階層のMDファイルを取得（_index.md は除外）
  md_files=()
  while IFS= read -r -d '' md; do
    md_files+=("$md")
  done < <(find "$parent_dir" -maxdepth 1 -name "*.md" ! -name "_index.md" -print0)

  # MDファイルが存在しない場合はスキップ
  if [ ${#md_files[@]} -eq 0 ]; then
    continue
  fi

  # slugを取得（MDファイル名から拡張子を除いたもの）
  md_file="${md_files[0]}"
  slug="$(basename "$md_file" .md)"

  # attachments/ 内の画像ファイルを検証
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    if [[ "$filename" != "${slug}-"* ]]; then
      # 拡張子を除いたnameを推定（元のファイル名をそのまま使う）
      ext="${filename##*.}"
      name_without_ext="${filename%.*}"
      expected="${slug}-${name_without_ext}.${ext}"
      ERRORS+=("$(printf '[%d]\n  ファイル: %s\n  対応MD:   %s\n  期待名:   %s' \
        "$((${#ERRORS[@]} + 1))" "$img" "$md_file" "$expected")")
    fi
  done < <(find "$attachments_dir" -maxdepth 1 \
    \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) \
    -print0)

done < <(find "$SOURCE_DIR" -type d -name "attachments" -print0)

# 違反があれば全件出力して停止
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "❌ 命名規則エラー: プレフィックスなし画像が検出されました（${#ERRORS[@]}件）"
  echo ""
  for err in "${ERRORS[@]}"; do
    echo "$err"
    echo ""
  done
  echo "修正してから再pushしてください。"
  exit 1
fi

echo "✅ 命名規則バリデーション: 問題なし"
