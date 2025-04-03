#!/bin/bash
set -e

# Factorioサーバー用OCIコンテナイメージビルドスクリプト
# buildahを使用してDockerなしでOCIイメージを構築

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

echo "Factorioサーバー用OCIコンテナイメージのビルドを開始します..."
echo "Factorioバージョン: $FACTORIO_VERSION"
if [ -n "$FACTORIO_SHA256" ]; then
  echo "SHA256ハッシュ: $FACTORIO_SHA256"
else
  echo "SHA256ハッシュが指定されていません。ハッシュ検証はスキップされます。"
fi

# ビルド環境の準備
CONTAINER=$(buildah from ubuntu:24.04)
MOUNT=$(buildah mount $CONTAINER)

# ビルドコンテキストをマウントポイントにコピー
echo "ビルドファイルをコンテナにコピーしています..."
cp install_factorio.sh $MOUNT/
cp ../common/entrypoint.sh $MOUNT/

# スクリプトに実行権限を付与
buildah run $CONTAINER chmod +x /install_factorio.sh
buildah run $CONTAINER chmod +x /entrypoint.sh

# 必要なパッケージのインストールとFactorioサーバーのセットアップ
echo "Factorioサーバーをインストールしています..."
buildah run --env FACTORIO_VERSION="$FACTORIO_VERSION" --env FACTORIO_SHA256="$FACTORIO_SHA256" $CONTAINER /install_factorio.sh

# インストールスクリプトの削除（セキュリティのため）
buildah run $CONTAINER rm /install_factorio.sh

# コンテナの設定
echo "コンテナの設定を行っています..."
buildah config --author "Factorio Server Builder" $CONTAINER
buildah config --label name="factorio-server" $CONTAINER
buildah config --label version="1.0" $CONTAINER
buildah config --label description="Factorio Game Server Container" $CONTAINER

# エントリーポイントの設定
buildah config --entrypoint '["/entrypoint.sh"]' $CONTAINER

# ポートの設定
buildah config --port 34197/udp $CONTAINER  # Factorioゲームポート
buildah config --port 27015/tcp $CONTAINER  # RCON（リモートコンソール）ポート

# ボリュームの設定
buildah config --volume /opt/factorio/saves $CONTAINER
buildah config --volume /opt/factorio/mods $CONTAINER
buildah config --volume /opt/factorio/config $CONTAINER
buildah config --volume /opt/factorio/scenarios $CONTAINER

# 環境変数の設定
buildah config --env FACTORIO_PORT=34197 $CONTAINER
buildah config --env FACTORIO_RCON_PORT=27015 $CONTAINER

# イメージのコミット
echo "OCIイメージをコミットしています..."
buildah commit $CONTAINER factorio-server:$FACTORIO_IMAGE_TAG

# クリーンアップ
buildah umount $CONTAINER
buildah rm $CONTAINER

echo "Factorioサーバー用OCIコンテナイメージのビルドが完了しました"
echo "イメージ名: factorio-server:$FACTORIO_IMAGE_TAG"
echo "Factorioバージョン: $FACTORIO_VERSION"
