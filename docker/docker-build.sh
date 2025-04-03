#!/bin/bash
set -e

# Factorioサーバー用Dockerイメージビルドスクリプト

# 環境変数のデフォルト値を設定
: ${FACTORIO_VERSION:="2.0.43"}
: ${FACTORIO_SHA256:="BDE6E167330C4439CE7DF3AC519EA445120258EF676F1F6AD31D0C2816D3AEE3"}
: ${FACTORIO_IMAGE_TAG:="latest"}

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
  case $1 in
    --version=*)
      FACTORIO_VERSION="${1#*=}"
      shift
      ;;
    --sha256=*)
      FACTORIO_SHA256="${1#*=}"
      shift
      ;;
    --tag=*)
      FACTORIO_IMAGE_TAG="${1#*=}"
      shift
      ;;
    --help)
      echo "使用方法: $0 [オプション]"
      echo "オプション:"
      echo "  --version=VERSION   Factorioのバージョンを指定 (デフォルト: $FACTORIO_VERSION)"
      echo "  --sha256=HASH       ダウンロードファイルのSHA256ハッシュを指定"
      echo "  --tag=TAG           ビルドするイメージのタグを指定 (デフォルト: latest)"
      echo "  --help              このヘルプメッセージを表示"
      exit 0
      ;;
    *)
      echo "不明なオプション: $1"
      echo "ヘルプを表示するには: $0 --help"
      exit 1
      ;;
  esac
done

echo "Factorioサーバー用Dockerイメージのビルドを開始します..."
echo "Factorioバージョン: $FACTORIO_VERSION"
if [ -n "$FACTORIO_SHA256" ]; then
  echo "SHA256ハッシュ: $FACTORIO_SHA256"
else
  echo "SHA256ハッシュが指定されていません。ハッシュ検証はスキップされます。"
fi

# Dockerイメージのビルド
docker build \
  --build-arg FACTORIO_VERSION="$FACTORIO_VERSION" \
  --build-arg FACTORIO_SHA256="$FACTORIO_SHA256" \
  -t factorio-server:$FACTORIO_IMAGE_TAG \
  .

echo "Factorioサーバー用Dockerイメージのビルドが完了しました"
echo "イメージ名: factorio-server:$FACTORIO_IMAGE_TAG"
echo "Factorioバージョン: $FACTORIO_VERSION"

# 使用例の表示
echo ""
echo "使用例:"
echo "  # コンテナを起動（基本設定）"
echo "  docker run -d --name factorio-server -p 34197:34197/udp factorio-server:$FACTORIO_IMAGE_TAG"
echo ""
echo "  # コンテナを起動（ボリュームマウント）"
echo "  docker run -d --name factorio-server \\"
echo "    -p 34197:34197/udp \\"
echo "    -v /path/to/saves:/opt/factorio/saves \\"
echo "    -v /path/to/mods:/opt/factorio/mods \\"
echo "    -v /path/to/config:/opt/factorio/config \\"
echo "    -v /path/to/scenarios:/opt/factorio/scenarios \\"
echo "    factorio-server:$FACTORIO_IMAGE_TAG"
echo ""
echo "  # コンテナを起動（環境変数設定）"
echo "  docker run -d --name factorio-server \\"
echo "    -p 34197:34197/udp \\"
echo "    -e FACTORIO_SERVER_NAME=\"My Factorio Server\" \\"
echo "    -e FACTORIO_SERVER_DESCRIPTION=\"A Factorio Server running in Docker\" \\"
echo "    -e FACTORIO_MAX_PLAYERS=10 \\"
echo "    -e FACTORIO_PUBLIC_VISIBLE=false \\"
echo "    -e FACTORIO_LAN_VISIBLE=true \\"
echo "    factorio-server:$FACTORIO_IMAGE_TAG"
