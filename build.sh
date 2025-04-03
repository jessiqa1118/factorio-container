#!/bin/bash
set -e

# Factorioサーバー用OCIコンテナイメージビルドスクリプト
# buildahを使用してDockerなしでOCIイメージを構築

echo "Factorioサーバー用OCIコンテナイメージのビルドを開始します..."

# ビルド環境の準備
CONTAINER=$(buildah from ubuntu:24.04)
MOUNT=$(buildah mount $CONTAINER)

# ビルドコンテキストをマウントポイントにコピー
echo "ビルドファイルをコンテナにコピーしています..."
cp install_factorio.sh $MOUNT/
cp entrypoint.sh $MOUNT/

# スクリプトに実行権限を付与
buildah run $CONTAINER chmod +x /install_factorio.sh
buildah run $CONTAINER chmod +x /entrypoint.sh

# 必要なパッケージのインストールとFactorioサーバーのセットアップ
echo "Factorioサーバーをインストールしています..."
buildah run $CONTAINER /install_factorio.sh

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
buildah commit $CONTAINER factorio-server:latest

# クリーンアップ
buildah umount $CONTAINER
buildah rm $CONTAINER

echo "Factorioサーバー用OCIコンテナイメージのビルドが完了しました"
echo "イメージ名: factorio-server:latest"
