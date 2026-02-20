#!/usr/bin/env bash
# convert-images.sh
# attachments/ 内の画像をWebPに変換してEXIF削除・リサイズを行い
# .gen/static/ 以下の公開URLパスに配置する
#
# 命名規則: {slug}_{name}.{ext}
# slugとnameの区切りは最初の _
# 例: 2026-02-04-my-travel-blog_hero.png → hero.webp
#
# セクション判定:
#   source/blog/** → blog セクション（slugがそのまま公開URL）
#   それ以外       → source/ からの相対パス構造をそのまま維持
#
# 変換方式:
#   拡張子に関わらずidentifyで実体フォーマットを判定して入力に明示する
#   出力はWEBP:プレフィックスでlibwebpをネイティブ使用（cwebpデリゲート不使用）

set -euo pipefail

SOURCE_DIR="source"
STATIC_OUT=".gen/static"

echo "  ImageMagick: $(convert --version | head -1)"

# 画像をWebPに変換する関数
convert_to_webp() {
  local input="$1"
  local output="$2"

  # 拡張子に関わらず実体フォーマットを判定して入力に明示する
  local format
  format="$(identify -format "%m" "$input" 2>/dev/null | head -1)"

  convert "${format}:${input}" \
    -resize 1920x\> \
    -strip \
    -quality 85 \
    "WEBP:${output}"
}

# attachments/ ディレクトリを全件探索
while IFS= read -r -d '' attachments_dir; do
  parent_dir="$(dirname "$attachments_dir")"

  # 画像ファイルを処理
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    name_no_ext="${filename%.*}"

    # 最初の _ でスラグとnameに分割
    slug="${name_no_ext%%_*}"
    name="${name_no_ext#*_}"

    # 出力先パスの決定
    if [[ "$parent_dir" == "${SOURCE_DIR}/blog"* ]]; then
      # blogセクション: slugがそのまま公開URL
      out_dir="${STATIC_OUT}/blog/${slug}"
    else
      # それ以外: source/ からの相対パス構造を維持
      rel_dir="${parent_dir#"${SOURCE_DIR}/"}"
      out_dir="${STATIC_OUT}/${rel_dir}/${slug}"
    fi

    mkdir -p "$out_dir"
    out_file="${out_dir}/${name}.webp"

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
