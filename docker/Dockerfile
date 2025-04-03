FROM ubuntu:24.04

# ビルド引数の設定（デフォルト値あり）
ARG FACTORIO_VERSION=2.0.43
ARG FACTORIO_SHA256="BDE6E167330C4439CE7DF3AC519EA445120258EF676F1F6AD31D0C2816D3AEE3"

# 環境変数の設定
ENV FACTORIO_PORT=34197 \
    FACTORIO_RCON_PORT=27015 \
    FACTORIO_VERSION=${FACTORIO_VERSION}

# 必要なパッケージのインストール
RUN apt-get update && \
    apt-get install -y wget tar xz-utils curl ca-certificates jq supervisor procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Factorioサーバーのダウンロードと展開
RUN mkdir -p /opt/factorio && \
    cd /opt/factorio && \
    wget -O factorio_headless.tar.xz https://factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64 && \
    if [ -n "${FACTORIO_SHA256}" ]; then \
        echo "SHA256ハッシュを検証しています..." && \
        echo "${FACTORIO_SHA256} factorio_headless.tar.xz" | sha256sum -c || exit 1; \
    else \
        echo "SHA256ハッシュが指定されていないため、ハッシュ検証をスキップします。"; \
    fi && \
    tar -xJf factorio_headless.tar.xz && \
    rm factorio_headless.tar.xz

# 権限設定
RUN useradd -r -m -d /opt/factorio -s /bin/bash factorio && \
    mkdir -p /opt/factorio/saves && \
    mkdir -p /opt/factorio/mods && \
    mkdir -p /opt/factorio/config && \
    mkdir -p /opt/factorio/scenarios && \
    mkdir -p /var/log/factorio && \
    chown -R factorio:factorio /opt/factorio && \
    chown -R factorio:factorio /var/log/factorio

# サーバー設定ファイルの作成
COPY common/server-settings.json /opt/factorio/config/server-settings.json
RUN chown factorio:factorio /opt/factorio/config/server-settings.json

# サーバー起動スクリプトの作成
COPY common/start-server.sh /opt/factorio/start-server.sh
RUN chmod +x /opt/factorio/start-server.sh && \
    chown factorio:factorio /opt/factorio/start-server.sh

# Supervisorの設定
COPY docker/supervisord.conf /etc/supervisor/conf.d/factorio.conf

# エントリーポイントスクリプトの設定
COPY common/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ボリュームの設定
VOLUME ["/opt/factorio/saves", "/opt/factorio/mods", "/opt/factorio/config", "/opt/factorio/scenarios"]

# ポートの公開
EXPOSE 34197/udp 27015/tcp

# エントリーポイントの設定
ENTRYPOINT ["/entrypoint.sh"]
