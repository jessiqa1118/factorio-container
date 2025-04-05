#!/bin/bash

# Factorio RCON Client インストールスクリプト

set -e

echo "Factorio RCON Client インストールを開始します..."

# 必要なディレクトリを作成
mkdir -p ~/bin ~/.config

# rcon-cliがインストールされているか確認
if ! command -v rcon &> /dev/null; then
    echo "rcon-cliがインストールされていません。インストールします..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y rcon-cli
    elif command -v yum &> /dev/null; then
        sudo yum install -y rcon-cli
    else
        echo "警告: パッケージマネージャが見つかりません。手動でrcon-cliをインストールしてください。"
        echo "例: https://github.com/gorcon/rcon-cli からダウンロードしてインストール"
    fi
fi

# スクリプトをコピー
echo "factorio-rconスクリプトを~/binにコピーしています..."
cp "$(dirname "$0")/factorio-rcon" ~/bin/
chmod +x ~/bin/factorio-rcon

# 設定ファイルが存在しない場合はコピー
if [ ! -f ~/.config/factorio-rcon.conf ]; then
    echo "設定ファイルのテンプレートを~/.configにコピーしています..."
    cp "$(dirname "$0")/factorio-rcon.conf.example" ~/.config/factorio-rcon.conf
    chmod 600 ~/.config/factorio-rcon.conf
    echo "設定ファイルを編集してください: ~/.config/factorio-rcon.conf"
else
    echo "設定ファイルは既に存在します: ~/.config/factorio-rcon.conf"
fi

# PATHに~/binが含まれているか確認
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo "PATHに~/binを追加しました。変更を適用するには、ターミナルを再起動するか、以下のコマンドを実行してください:"
    echo "source ~/.bashrc"
else
    echo "~/binは既にPATHに含まれています。"
fi

echo "インストールが完了しました！"
echo ""
echo "使用方法:"
echo "  factorio-rcon /help          # ヘルプの表示"
echo "  factorio-rcon /players       # プレイヤーリストの取得"
echo "  factorio-rcon /save          # ゲームの保存"
echo "  factorio-rcon /quit          # サーバーの停止"
echo ""
echo "注意: 設定ファイル~/.config/factorio-rcon.confを編集して、正しいホスト、ポート、パスワードを設定してください。"
