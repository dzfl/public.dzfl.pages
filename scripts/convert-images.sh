#!/usr/bin/env bash
# convert-images.sh
# attachments/ 内の画像をWebPに変換してEXIF削除・リサイズを行い
# .gen/static/ 以下の公開URLパスに配置する

set -euo pipefail

SOURCE_DIR="source"
STATIC_OUT=".gen/static"

# フロントマターからdateを抽出する関数
get_date() {
  local md_file="$1"
  grep -m1 '^date:' "$md_file" | sed 's/date:[[:space:]]*//' | tr -d '"' | tr -d "'"
}

# セクション判定
get_section() {
  local md_path="$1"
  if [[ "$md_path" == source/blog/* ]]; then
    echo "blog"
  elif [[ "$md_path" == source/docs/* ]]; then
    echo "docs"
  else
    echo "pages"
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
  section="$(get_section "$md_file")"

  # blogセクションのみdateを取得してslugに日付を付加
  if [ "$section" = "blog" ]; then
    date="$(get_date "$md_file")"
    if [ -z "$date" ]; then
      echo "❌ dateフロントマターが見つかりません: $md_file"
      exit 1
    fi
    slug="${date}-${filename_slug}"
  else
    slug="$filename_slug"
  fi

  # 出力先ディレクトリを決定・作成
  if [ "$section" = "pages" ]; then
    out_dir="${STATIC_OUT}/${slug}"
  else
    out_dir="${STATIC_OUT}/${section}/${slug}"
  fi

  echo "  出力先ディレクトリ: $out_dir"
  mkdir -p "$out_dir"

  # 画像を変換して配置
  while IFS= read -r -d '' img; do
    filename="$(basename "$img")"
    # ファイル名スラグプレフィックス（日付なし）を除去してnameを取得
    name="${filename#"${filename_slug}-"}"
    name_without_ext="${name%.*}"
    out_file="${out_dir}/${name_without_ext}.webp"

    echo "  変換: $img → $out_file"
    convert "$img" \
      -resize 1920x\> \
      -strip \
      -quality 85 \
      "$out_file" || {
        echo "❌ 変換失敗: $img"
        echo "  ImageMagickエラーを確認してください"
        exit 1
      }

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
