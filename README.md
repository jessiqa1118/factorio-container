# Factorioゲームサーバー用OCIコンテナ

このリポジトリには、FactorioゲームサーバーをOCIコンテナとして実行するために必要なファイルが含まれています。Ubuntu 24.04をベースにしており、Proxmox VEのLXCコンテナとして使用することを主な目的としていますが、K8sやOpenStack上でも汎用的に使用できます。

## ファイル構成

- `container.yaml` - コンテナの基本構成定義
- `install_factorio.sh` - Factorioサーバーのインストールスクリプト
- `entrypoint.sh` - コンテナのエントリーポイントスクリプト
- `build.sh` - OCIコンテナイメージをビルドするスクリプト
- `proxmox-lxc.conf` - Proxmox VE LXCコンテナの設定ファイル

## 前提条件

- buildahがインストールされていること
- Factorioのヘッドレスサーバーをダウンロードするためのアクセス権

## ビルド手順

1. 最新のFactorioバージョンとSHA256ハッシュを確認

   Factorioの公式サイトから最新のヘッドレスサーバーバージョンとSHA256ハッシュを確認し、`install_factorio.sh`の以下の部分を更新します：

   ```bash
   FACTORIO_VERSION="1.1.91"
   FACTORIO_SHA256="c0c0c9c1a9a7e7a1c3a4f7c0a9a19e4c3a6f7c0a9a19e4c3a6f7c0a9a19e4c3a"
   ```

   実際のSHA256ハッシュは[Factorioのダウンロードページ](https://factorio.com/download)で確認できます。

2. スクリプトに実行権限を付与

   ```bash
   chmod +x build.sh install_factorio.sh entrypoint.sh
   ```

3. OCIコンテナイメージをビルド

   ```bash
   ./build.sh
   ```

   ビルドが成功すると、`factorio-server:latest`というOCIイメージが作成されます。

## Proxmox VEへのデプロイ

### 方法1: OCIイメージからLXCコンテナを作成

1. ビルドしたOCIイメージをエクスポート

   ```bash
   podman save factorio-server:latest | gzip > factorio-server.tar.gz
   ```

2. イメージをProxmox VEホストに転送

   ```bash
   scp factorio-server.tar.gz root@proxmox-host:/var/lib/vz/template/cache/
   ```

3. Proxmox VEでLXCコンテナを作成

   Proxmox VEのWebインターフェースまたはCLIを使用して、新しいLXCコンテナを作成します。
   
   CLIの場合：
   ```bash
   pct create 100 /var/lib/vz/template/cache/factorio-server.tar.gz --rootfs local-lvm:10 --ostype ubuntu --hostname factorio-server
   ```

4. `proxmox-lxc.conf`の設定を適用

   作成したLXCコンテナの設定ファイルを編集して、`proxmox-lxc.conf`の内容を適用します。
   
   ```bash
   # 既存の設定をバックアップ
   cp /etc/pve/lxc/100.conf /etc/pve/lxc/100.conf.bak
   
   # 新しい設定を適用（必要に応じてパスを調整）
   cat proxmox-lxc.conf > /etc/pve/lxc/100.conf
   ```

### 方法2: Ubuntu 24.04テンプレートから新規作成

1. Proxmox VEでUbuntu 24.04のLXCテンプレートをダウンロード

   Proxmox VEのWebインターフェースで「ローカル」→「CTテンプレート」を選択し、Ubuntu 24.04のテンプレートをダウンロードします。

2. 新しいLXCコンテナを作成

   ダウンロードしたテンプレートを使用して新しいLXCコンテナを作成します。

3. `proxmox-lxc.conf`の設定を適用

   作成したLXCコンテナの設定ファイルを編集して、`proxmox-lxc.conf`の内容を適用します。

4. コンテナを起動し、必要なファイルを転送

   ```bash
   pct start 100
   pct push 100 install_factorio.sh /root/install_factorio.sh
   pct push 100 entrypoint.sh /root/entrypoint.sh
   ```

5. コンテナ内でFactorioサーバーをインストール

   ```bash
   pct exec 100 -- chmod +x /root/install_factorio.sh /root/entrypoint.sh
   pct exec 100 -- /root/install_factorio.sh
   ```

6. エントリーポイントスクリプトを適切な場所に配置

   ```bash
   pct exec 100 -- mv /root/entrypoint.sh /entrypoint.sh
   ```

7. コンテナの自動起動設定

   ```bash
   pct exec 100 -- systemctl enable supervisor
   ```

## 環境変数

コンテナは以下の環境変数を使用して設定できます：

- `FACTORIO_PORT`: ゲームサーバーのUDPポート（デフォルト: 34197）
- `FACTORIO_RCON_PORT`: RCONポート（デフォルト: 27015）
- `FACTORIO_RCON_PASSWORD`: RCONパスワード
- `FACTORIO_USERNAME`: Factorioアカウントのユーザー名
- `FACTORIO_TOKEN`: Factorioアカウントのトークン
- `FACTORIO_SERVER_NAME`: サーバー名
- `FACTORIO_SERVER_DESCRIPTION`: サーバーの説明
- `FACTORIO_SERVER_GAME_PASSWORD`: ゲームパスワード
- `FACTORIO_MAX_PLAYERS`: 最大プレイヤー数
- `FACTORIO_PUBLIC_VISIBLE`: パブリック可視性（true/false）
- `FACTORIO_LAN_VISIBLE`: LAN可視性（true/false）
- `FACTORIO_AUTOSAVE_INTERVAL`: 自動保存間隔（分）
- `FACTORIO_AUTOSAVE_SLOTS`: 自動保存スロット数
- `FACTORIO_AUTO_PAUSE`: プレイヤーがいない場合に自動一時停止（true/false）

## データの永続化

以下のディレクトリをホストにマウントすることで、データを永続化できます：

- `/opt/factorio/saves`: セーブデータ
- `/opt/factorio/mods`: MOD
- `/opt/factorio/config`: 設定ファイル
- `/opt/factorio/scenarios`: シナリオ

## 注意事項

- Factorioサーバーを公開する場合は、適切なファイアウォール設定を行ってください。
- RCONパスワードを設定する場合は、強力なパスワードを使用してください。
- Factorioの公式サイトから最新のヘッドレスサーバーバージョンとSHA256ハッシュを確認することをお勧めします。
