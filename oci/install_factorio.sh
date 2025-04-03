#!/bin/bash
set -e

# Factorioサーバーインストールスクリプト
# Ubuntu 24.04ベースのOCIコンテナ用

# 必要なパッケージのインストール
apt-get update
apt-get install -y wget tar xz-utils curl ca-certificates jq supervisor procps

# Factorioサーバーのバージョン設定
# 環境変数から読み取り、設定されていない場合はデフォルト値を使用
: ${FACTORIO_VERSION:="2.0.43"}
: ${FACTORIO_SHA256:="BDE6E167330C4439CE7DF3AC519EA445120258EF676F1F6AD31D0C2816D3AEE3"}

# バージョンとハッシュの情報を表示
echo "Factorioバージョン: $FACTORIO_VERSION"
if [ -n "$FACTORIO_SHA256" ]; then
  echo "SHA256ハッシュ: $FACTORIO_SHA256"
else
  echo "SHA256ハッシュが指定されていません。ハッシュ検証をスキップします。"
fi

# Factorioサーバーのダウンロードと展開
mkdir -p /opt/factorio
cd /opt/factorio
wget -O factorio_headless.tar.xz https://factorio.com/get-download/$FACTORIO_VERSION/headless/linux64

# SHA256ハッシュが指定されている場合のみ検証を実行
if [ -n "$FACTORIO_SHA256" ]; then
  echo "ダウンロードしたファイルのハッシュを検証しています..."
  echo "$FACTORIO_SHA256 factorio_headless.tar.xz" | sha256sum -c || exit 1
else
  echo "SHA256ハッシュが指定されていないため、ハッシュ検証をスキップします。"
fi
tar -xJf factorio_headless.tar.xz
rm factorio_headless.tar.xz

# 権限設定
useradd -r -m -d /opt/factorio -s /bin/bash factorio
chown -R factorio:factorio /opt/factorio

# データディレクトリの作成
mkdir -p /opt/factorio/saves
mkdir -p /opt/factorio/mods
mkdir -p /opt/factorio/config
mkdir -p /opt/factorio/scenarios

# サーバー設定ファイルの作成
cat > /opt/factorio/config/server-settings.json << 'EOF'
{
  "name": "Factorio Server",
  "description": "Factorio Game Server",
  "tags": ["game", "factorio"],
  "max_players": 0,
  "visibility": {
    "public": false,
    "lan": true
  },
  "username": "",
  "password": "",
  "token": "",
  "game_password": "",
  "require_user_verification": true,
  "max_upload_in_kilobytes_per_second": 0,
  "max_upload_slots": 5,
  "minimum_latency_in_ticks": 0,
  "ignore_player_limit_for_returning_players": false,
  "allow_commands": "admins-only",
  "autosave_interval": 10,
  "autosave_slots": 5,
  "afk_autokick_interval": 0,
  "auto_pause": true,
  "only_admins_can_pause_the_game": true,
  "autosave_only_on_server": true,
  "non_blocking_saving": false,
  "minimum_segment_size": 25,
  "minimum_segment_size_peer_count": 20,
  "maximum_segment_size": 100,
  "maximum_segment_size_peer_count": 10
}
EOF

# サーバー起動スクリプトの作成
cat > /opt/factorio/start-server.sh << 'EOF'
#!/bin/bash
cd /opt/factorio
./bin/x64/factorio --start-server-load-latest --server-settings ./config/server-settings.json "$@"
EOF

chmod +x /opt/factorio/start-server.sh
chown factorio:factorio /opt/factorio/start-server.sh

# Supervisorの設定
cat > /etc/supervisor/conf.d/factorio.conf << 'EOF'
[program:factorio]
command=/opt/factorio/start-server.sh
user=factorio
directory=/opt/factorio
autostart=true
autorestart=true
stdout_logfile=/var/log/factorio/stdout.log
stderr_logfile=/var/log/factorio/stderr.log
EOF

# ログディレクトリの作成
mkdir -p /var/log/factorio
chown -R factorio:factorio /var/log/factorio

# クリーンアップ
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Factorioサーバーのインストールが完了しました"
