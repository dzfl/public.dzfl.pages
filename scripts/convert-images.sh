#!/usr/bin/env bash
# convert-images.sh
# attachments/ 内の画像をWebPに変換してEXIF削除・リサイズを行い
# .gen/static/ 以下の公開URLパスに配置する
#
# セクション判定:
#   source/blog/** → 日付平坦化（dateフロントマター + ファイル名でslug生成）
#   それ以外       → source/ からの相対パス構造をそのまま維持
#
# 変換方式:
#   PNG/JPG → ImageMagick でリサイズ・EXIF削除 → cwebp で WebP変換
#   WebP    → cwebp で直接処理（メタデータ削除・リサイズ）

set -euo pipefail

SOURCE_DIR="source"
STATIC_OUT=".gen/static"

# ツールバージョンをログに出力
echo "  ImageMagick: $(convert --version | head -1)"
echo "  cwebp: $(cwebp -version 2>&1 | head -1)"

# フロントマターからdateを抽出する関数
get_date() {
  local md_file="$1"
  grep -m1 '^date:' "$md_file" | sed 's/date:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

# 画像の幅を取得する関数
get_width() {
  local input="$1"
  identify -format "%w" "$input" 2>/dev/null || echo "0"
}

# 画像をWebPに変換する関数
convert_to_webp() {
  local input="$1"
  local output="$2"
  local ext="${input##*.}"

  if [[ "${ext,,}" == "webp" ]]; then
    # WebP: cwebpで直接処理（メタデータ削除）
    # リサイズが必要な場合のみ -resize を付与
    local width
    width="$(get_width "$input")"
    if [ "$width" -gt 1920 ] 2>/dev/null; then
      cwebp -quiet -q 85 -metadata none -resize 1920 0 "$input" -o "$output"
    else
      cwebp -quiet -q 85 -metadata none "$input" -o "$output"
    fi
  else
    # PNG/JPG: ImageMagickでリサイズ・EXIF削除 → cwebpでWebP変換
    local tmp_png
    tmp_png="$(mktemp /tmp/convert_XXXXXX.png)"
    convert "$input" -resize 1920x\> -strip "$tmp_png"
    cwebp -quiet -q 85 -metadata none "$tmp_png" -o "$output"
    rm -f "$tmp_png"
  fi
}

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
  filename_slug="$(basename "$md_file" .md)"

  # 出力先パスの決定
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

  # 画像を変換して配置
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    name="${filename#"${filename_slug}-"}"
    name_without_ext="${name%.*}"
    out_file="${out_dir}/${name_without_ext}.webp"

    echo "  変換: $img → $out_file"
    convert_to_webp "$img" "$out_file"

  done < <(find "$attachments_dir" -maxdepth 1 \
    \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) \
    -print0)

done < <(find "$SOURCE_DIR" -type d -name "attachments" -print0)

# source/assets/site/ はそのままコピー（変換なし）
if [ -d "${SOURCE_DIR}/assets/site" ]; then
  mkdir -p "${STATIC_OUT}/assets/site"
  cp -r "${SOURCE_DIR}/assets/site/." "${STATIC_OUT}/assets/site/"
  echo "  コピー: source/assets/site/ → ${STATIC_OUT}/assets/site/"
fi

echo "✅ 画像変換: 完了"
