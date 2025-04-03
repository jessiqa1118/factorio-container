#!/bin/bash
set -e

# Factorioサーバーコンテナエントリーポイント

# シンボリックリンクを作成（Factorioが期待するパス構造を維持）
mkdir -p /opt/factorio/factorio/saves
rm -rf /opt/factorio/factorio/saves
ln -sf /opt/factorio/saves /opt/factorio/factorio/saves

# 初回起動時にセーブファイルを作成
if [ ! -f /opt/factorio/saves/save.zip ] && [ ! -f /opt/factorio/factorio/saves/save.zip ]; then
    echo "新しいセーブファイルを作成します..."
    cd /opt/factorio
    ./factorio/bin/x64/factorio --create /opt/factorio/saves/save.zip
fi

# 環境変数のデフォルト値設定
: ${FACTORIO_PORT:=34197}
: ${FACTORIO_RCON_PORT:=27015}
: ${FACTORIO_RCON_PASSWORD:=""}
: ${FACTORIO_USERNAME:=""}
: ${FACTORIO_TOKEN:=""}
: ${FACTORIO_SERVER_NAME:="Factorio Server"}
: ${FACTORIO_SERVER_DESCRIPTION:="Factorio Game Server"}
: ${FACTORIO_SERVER_GAME_PASSWORD:=""}
: ${FACTORIO_MAX_PLAYERS:=0}
: ${FACTORIO_PUBLIC_VISIBLE:=false}
: ${FACTORIO_LAN_VISIBLE:=true}
: ${FACTORIO_AUTOSAVE_INTERVAL:=10}
: ${FACTORIO_AUTOSAVE_SLOTS:=5}
: ${FACTORIO_AUTO_PAUSE:=true}

# サーバー設定ファイルの更新
CONFIG_FILE="/opt/factorio/config/server-settings.json"

# jqを使用して設定ファイルを更新
jq ".name = \"$FACTORIO_SERVER_NAME\" | \
    .description = \"$FACTORIO_SERVER_DESCRIPTION\" | \
    .max_players = $FACTORIO_MAX_PLAYERS | \
    .visibility.public = $FACTORIO_PUBLIC_VISIBLE | \
    .visibility.lan = $FACTORIO_LAN_VISIBLE | \
    .username = \"$FACTORIO_USERNAME\" | \
    .token = \"$FACTORIO_TOKEN\" | \
    .game_password = \"$FACTORIO_SERVER_GAME_PASSWORD\" | \
    .autosave_interval = $FACTORIO_AUTOSAVE_INTERVAL | \
    .autosave_slots = $FACTORIO_AUTOSAVE_SLOTS | \
    .auto_pause = $FACTORIO_AUTO_PAUSE" \
    $CONFIG_FILE > /tmp/server-settings.json && \
    mv /tmp/server-settings.json $CONFIG_FILE

# RCONパスワードが設定されている場合、RCON設定を有効化
if [ -n "$FACTORIO_RCON_PASSWORD" ]; then
    echo "RCONを有効化しています..."
    cat > /opt/factorio/config/rconpw << EOF
$FACTORIO_RCON_PASSWORD
EOF
    chmod 600 /opt/factorio/config/rconpw
    chown factorio:factorio /opt/factorio/config/rconpw
fi

# 所有権の確認
chown -R factorio:factorio /opt/factorio

# Supervisorを使用してサービスを起動
echo "Factorioサーバーを起動しています..."
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
