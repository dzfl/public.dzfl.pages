#!/usr/bin/env bash
# validate.sh
# attachments/ 内の画像ファイルが命名規則に従っているか検証する
# 違反を全件収集してから exit 1 で停止する
# エラー内容は GitHub Actions のジョブサマリーにも書き込む
#
# 命名規則: {mdファイル名（日付なし）}-{name}.{ext}
# 例: slug-hero.png, slug-fig-01.webp

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

  if [ ${#md_files[@]} -eq 0 ]; then
    continue
  fi

  md_file="${md_files[0]}"
  slug="$(basename "$md_file" .md)"

  # attachments/ 内の画像ファイルを検証
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    if [[ "$filename" != "${slug}-"* ]]; then
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

# 違反があれば全件出力してジョブサマリーに書き込み停止
if [ ${#ERRORS[@]} -gt 0 ]; then
  msg="❌ 命名規則エラー: プレフィックスなし画像が検出されました（${#ERRORS[@]}件）"
  echo "$msg"
  echo ""

  # ジョブサマリーに書き込む
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "## ❌ 命名規則エラー" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "プレフィックスなし画像が **${#ERRORS[@]}件** 検出されました。" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "| # | ファイル | 対応MD | 期待するファイル名 |" >> "$GITHUB_STEP_SUMMARY"
    echo "|---|---|---|---|" >> "$GITHUB_STEP_SUMMARY"
  fi

  count=1
  for err in "${ERRORS[@]}"; do
    echo "$err"
    echo ""

    # ジョブサマリーにテーブル行を追加
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
      file=$(echo "$err" | grep 'ファイル:' | sed 's/.*ファイル: //')
      md=$(echo "$err"   | grep '対応MD:'   | sed 's/.*対応MD:   //')
      exp=$(echo "$err"  | grep '期待名:'   | sed 's/.*期待名:   //')
      echo "| $count | \`$file\` | \`$md\` | \`$exp\` |" >> "$GITHUB_STEP_SUMMARY"
    fi
    count=$((count + 1))
  done

  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "ファイルをリネームしてから再pushしてください。" >> "$GITHUB_STEP_SUMMARY"
  fi

  echo "修正してから再pushしてください。"
  exit 1
fi

echo "✅ 命名規則バリデーション: 問題なし"

# 正常時もサマリーに記録
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "## ✅ 命名規則バリデーション: 問題なし" >> "$GITHUB_STEP_SUMMARY"
fi
