#!/usr/bin/env bash
# convert-images.sh【デバッグ版】
# set -e を外してconvertのエラー詳細を出力する

set -uo pipefail

SOURCE_DIR="source"
STATIC_OUT=".gen/static"

echo "  ImageMagick: $(convert --version | head -1)"

get_date() {
  local md_file="$1"
  grep -m1 '^date:' "$md_file" | sed 's/date:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

convert_to_webp() {
  local input="$1"
  local output="$2"

  echo "  --- file info ---"
  file "$input" 2>&1 || true
  echo "  --- identify ---"
  identify "$input" 2>&1 || true

  local format
  format="$(identify -format "%m" "$input" 2>/dev/null | head -1 || echo "UNKNOWN")"
  echo "  --- format: $format ---"

  echo "  --- convert実行 ---"
  convert "${format}:${input}" \
    -resize 1920x\> \
    -strip \
    -quality 85 \
    "WEBP:${output}" 2>&1
  local exit_code=$?
  echo "  --- exit: $exit_code ---"
  return $exit_code
}

while IFS= read -r -d '' attachments_dir; do
  parent_dir="$(dirname "$attachments_dir")"

  md_files=()
  while IFS= read -r -d '' md; do
    md_files+=("$md")
  done < <(find "$parent_dir" -maxdepth 1 -name "*.md" ! -name "_index.md" -print0)

  if [ ${#md_files[@]} -eq 0 ]; then
    continue
  fi

  md_file="${md_files[0]}"
  filename_slug="$(basename "$md_file" .md)"

  if [[ "$md_file" == "${SOURCE_DIR}/blog/"* ]]; then
    date="$(get_date "$md_file")"
    if [ -z "$date" ]; then
      echo "❌ dateフロントマターが見つかりません: $md_file"
      exit 1
    fi
    slug="${date}-${filename_slug}"
    out_dir="${STATIC_OUT}/blog/${slug}"
  else
    rel_dir="${parent_dir#"${SOURCE_DIR}/"}"
    slug="$filename_slug"
    out_dir="${STATIC_OUT}/${rel_dir}/${slug}"
  fi

  mkdir -p "$out_dir"

  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    name="${filename#"${filename_slug}-"}"
    name_without_ext="${name%.*}"
    out_file="${out_dir}/${name_without_ext}.webp"

    echo "  変換: $img → $out_file"
    convert_to_webp "$img" "$out_file" || {
      echo "❌ 変換失敗: $img"
      exit 1
    }

  done < <(find "$attachments_dir" -maxdepth 1 \
    \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) \
    -print0)

done < <(find "$SOURCE_DIR" -type d -name "attachments" -print0)

if [ -d "${SOURCE_DIR}/assets/site" ]; then
  mkdir -p "${STATIC_OUT}/assets/site"
  cp -r "${SOURCE_DIR}/assets/site/." "${STATIC_OUT}/assets/site/"
fi

echo "✅ 画像変換: 完了"
