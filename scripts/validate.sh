#!/usr/bin/env bash
# validate.sh
# attachments/ 内の画像ファイルが命名規則に従っているか検証する
# 違反を全件収集してから exit 1 で停止する
# エラー内容は GitHub Actions のジョブサマリーにも書き込む
#
# 命名規則: {slug}_{name}.{ext}
# slugとnameの区切りは最初の _ （スラグ・name共にハイフンを含んでよい）
# 例: 2026-02-04-my-travel-blog_hero.png
#     2026-02-04-my-travel-blog_fig-01.png
#
# 検証方法:
#   画像ファイル名の最初の _ より前の部分をスラグとして抽出し
#   同階層に {slug}.md が存在するかを確認する

set -euo pipefail

SOURCE_DIR="source"
ERRORS=()

# attachments/ ディレクトリを全件探索
while IFS= read -r -d '' attachments_dir; do
  parent_dir="$(dirname "$attachments_dir")"

  # attachments/ 内の画像ファイルを検証
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    name_no_ext="${filename%.*}"

    # 最初の _ でスラグとnameに分割
    if [[ "$name_no_ext" != *_* ]]; then
      # _ が存在しない → 命名規則違反
      expected_md="${parent_dir}/$(echo "$name_no_ext" | cut -d- -f1-4).md"
      ERRORS+=("$(printf '[%d]\n  ファイル: %s\n  問題:     アンダースコア区切りがありません\n  期待形式: {slug}_{name}.{ext}（例: 2026-02-04-slug_hero.png）' \
        "$((${#ERRORS[@]} + 1))" "$img")")
      continue
    fi

    # スラグ部分を抽出（最初の _ より前）
    slug="${name_no_ext%%_*}"

    # 対応するMDファイルが同階層に存在するか確認
    md_file="${parent_dir}/${slug}.md"
    if [ ! -f "$md_file" ]; then
      # 同階層のMDを列挙してエラーメッセージに含める
      existing_mds=()
      while IFS= read -r -d '' md; do
        existing_mds+=("$(basename "$md")")
      done < <(find "$parent_dir" -maxdepth 1 -name "*.md" ! -name "_index.md" -print0)
      existing_list="${existing_mds[*]:-なし}"

      ERRORS+=("$(printf '[%d]\n  ファイル: %s\n  スラグ:   %s\n  期待MD:   %s\n  実在MD:   %s' \
        "$((${#ERRORS[@]} + 1))" "$img" "$slug" "$md_file" "$existing_list")")
    fi

  done < <(find "$attachments_dir" -maxdepth 1 \
    \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) \
    -print0)

done < <(find "$SOURCE_DIR" -type d -name "attachments" -print0)

# 違反があれば全件出力してジョブサマリーに書き込み停止
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "❌ 命名規則エラー: 違反画像が検出されました（${#ERRORS[@]}件）"
  echo ""

  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "## ❌ 命名規則エラー" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "違反画像が **${#ERRORS[@]}件** 検出されました。" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
  fi

  count=1
  for err in "${ERRORS[@]}"; do
    echo "$err"
    echo ""

    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
      file=$(echo "$err" | grep 'ファイル:' | sed 's/.*ファイル: //')
      echo "**[$count]** \`$file\`" >> "$GITHUB_STEP_SUMMARY"
      echo '```' >> "$GITHUB_STEP_SUMMARY"
      echo "$err" >> "$GITHUB_STEP_SUMMARY"
      echo '```' >> "$GITHUB_STEP_SUMMARY"
      echo "" >> "$GITHUB_STEP_SUMMARY"
    fi
    count=$((count + 1))
  done

  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "ファイルをリネームしてから再pushしてください。" >> "$GITHUB_STEP_SUMMARY"
  fi

  echo "修正してから再pushしてください。"
  exit 1
fi

echo "✅ 命名規則バリデーション: 問題なし"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "## ✅ 命名規則バリデーション: 問題なし" >> "$GITHUB_STEP_SUMMARY"
fi
