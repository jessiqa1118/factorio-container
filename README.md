# Factorioゲームサーバー用コンテナ

このリポジトリには、Factorioゲームサーバーをコンテナとして実行するために必要なファイルが含まれています。Ubuntu 24.04をベースにしており、Proxmox VEのLXCコンテナとして使用することを主な目的としていますが、Docker、K8s、OpenStack上でも汎用的に使用できます。

## ディレクトリ構造

```
.
├── README.md
├── common/                  # 共通ファイル
│   ├── entrypoint.sh       # コンテナのエントリーポイントスクリプト
│   ├── server-settings.json # Factorioサーバーの設定ファイル
│   └── start-server.sh     # Factorioサーバーの起動スクリプト
├── docker/                  # Docker版
│   ├── Dockerfile          # Dockerイメージのビルド定義
│   ├── docker-build.sh     # Dockerイメージをビルドするスクリプト
│   └── supervisord.conf    # Supervisorの設定ファイル
└── oci/                     # OCI/Buildah版
    ├── build.sh            # OCIコンテナイメージをビルドするスクリプト
    ├── container.yaml      # コンテナの基本構成定義
    ├── install_factorio.sh # Factorioサーバーのインストールスクリプト
    └── proxmox-lxc.conf    # Proxmox VE LXCコンテナの設定ファイル
```

## 前提条件

### OCI/Buildah版
- buildahがインストールされていること
- Factorioのヘッドレスサーバーをダウンロードするためのアクセス権

### Docker版
- Dockerがインストールされていること
- Factorioのヘッドレスサーバーをダウンロードするためのアクセス権

## ビルド環境の準備

ビルド手順は、OCIコンテナイメージをビルドするホストマシン（ビルド環境）で実行します。ビルド環境は以下のいずれかを使用できます：

1. 開発者のローカルマシン（Linux環境またはWindows+WSL）
2. CIサーバー（Jenkins、GitHub Actions、GitLab CIなど）
3. Proxmox VEホスト自体

### ビルド環境の要件

- Linux環境（Ubuntu、Debian、CentOSなど）またはWindows+WSL
- buildahがインストールされていること
- インターネット接続（Factorioサーバーのダウンロード用）
- 十分なディスク容量（最低2GB）

### Windows環境でのWSLセットアップ

Windows環境では、WSL（Windows Subsystem for Linux）を使用してビルドプロセスを実行できます：

1. WSLのインストール

   管理者権限でPowerShellを開き、以下のコマンドを実行します：
   ```powershell
   wsl --install
   ```
   
   または詳細なインストール手順は[Microsoftの公式ドキュメント](https://docs.microsoft.com/ja-jp/windows/wsl/install)を参照してください。

2. Ubuntu WSLディストリビューションのインストール

   Microsoft Storeから「Ubuntu」をインストールするか、以下のコマンドを実行します：
   ```powershell
   wsl --install -d Ubuntu
   ```

3. WSL内でbuildahをインストール

   WSLのUbuntuターミナルを開き、以下のコマンドを実行します：
   ```bash
   sudo apt update
   sudo apt install -y buildah
   ```

4. WSL内でビルドプロセスを実行

   WSLターミナルでリポジトリのディレクトリに移動し、ビルド手順を実行します。
   Windowsのパスは `/mnt/c/...` のように参照できます。

### Linux環境でのbuildahのインストール

Ubuntuの場合：
```bash
sudo apt update
sudo apt install -y buildah
```

CentOS/RHELの場合：
```bash
sudo yum install -y buildah
```

## OCI/Buildah版のビルドと使用方法

OCI/Buildah版を使用する場合は、以下の手順でビルドと実行を行います：

1. このリポジトリをクローンまたはダウンロード

   ```bash
   git clone https://your-repository-url.git
   cd factorio-container
   ```

2. スクリプトに実行権限を付与

   ```bash
   chmod +x oci/build.sh oci/install_factorio.sh common/entrypoint.sh
   ```

3. OCIコンテナイメージをビルド

   ociディレクトリに移動してビルドスクリプトを実行します：

   ```bash
   cd oci
   ```

   以下のいずれかの方法でビルドできます：

   ### 方法1: デフォルト設定でビルド

   ```bash
   ./build.sh
   ```

   デフォルトでは、Factorioバージョン2.0.43がインストールされ、SHA256ハッシュ検証が有効になっています。

   ### 方法2: コマンドライン引数でバージョンとハッシュを指定

   ```bash
   ./build.sh --version=1.1.91 --sha256=実際のSHA256ハッシュ値 --tag=1.1.91
   ```

   利用可能なオプション：
   - `--version=VERSION`: Factorioのバージョンを指定
   - `--sha256=HASH`: ダウンロードファイルのSHA256ハッシュを指定
   - `--tag=TAG`: ビルドするイメージのタグを指定（デフォルト: latest）
   - `--help`: ヘルプメッセージを表示

   ### 方法3: 環境変数を使用

   ```bash
   FACTORIO_VERSION=1.1.91 FACTORIO_SHA256=実際のSHA256ハッシュ値 FACTORIO_IMAGE_TAG=1.1.91 ./build.sh
   ```

   実際のSHA256ハッシュは[Factorioのダウンロードページ](https://factorio.com/download)で確認できます。

   ビルドが成功すると、指定したタグ（デフォルトは`latest`）でOCIイメージが作成されます。

## Docker版のビルドと使用方法

Docker版を使用する場合は、以下の手順でビルドと実行を行います：

1. このリポジトリをクローンまたはダウンロード

   ```bash
   git clone https://your-repository-url.git
   cd factorio-container
   ```

2. スクリプトに実行権限を付与

   ```bash
   chmod +x docker/docker-build.sh common/start-server.sh common/entrypoint.sh
   ```

3. Dockerイメージをビルド

   dockerディレクトリに移動してビルドスクリプトを実行します：

   ```bash
   cd docker
   ```

   以下のいずれかの方法でビルドできます：

   ### 方法1: デフォルト設定でビルド

   ```bash
   ./docker-build.sh
   ```

   デフォルトでは、Factorioバージョン2.0.43がインストールされ、SHA256ハッシュ検証が有効になっています。

   ### 方法2: コマンドライン引数でバージョンとハッシュを指定

   ```bash
   ./docker-build.sh --version=1.1.91 --sha256=実際のSHA256ハッシュ値 --tag=1.1.91
   ```

   利用可能なオプション：
   - `--version=VERSION`: Factorioのバージョンを指定
   - `--sha256=HASH`: ダウンロードファイルのSHA256ハッシュを指定
   - `--tag=TAG`: ビルドするイメージのタグを指定（デフォルト: latest）
   - `--help`: ヘルプメッセージを表示

   ### 方法3: 環境変数を使用

   ```bash
   FACTORIO_VERSION=1.1.91 FACTORIO_SHA256=実際のSHA256ハッシュ値 FACTORIO_IMAGE_TAG=1.1.91 ./docker-build.sh
   ```

4. Dockerコンテナを実行

   ### 基本的な実行方法

   ```bash
   docker run -d --name factorio-server -p 34197:34197/udp factorio-server:latest
   ```

   ### ボリュームマウントを使用した実行方法

   ```bash
   docker run -d --name factorio-server \
     -p 34197:34197/udp \
     -v /path/to/saves:/opt/factorio/saves \
     -v /path/to/mods:/opt/factorio/mods \
     -v /path/to/config:/opt/factorio/config \
     -v /path/to/scenarios:/opt/factorio/scenarios \
     factorio-server:latest
   ```

   ### 環境変数を使用した実行方法

   ```bash
   docker run -d --name factorio-server \
     -p 34197:34197/udp \
     -e FACTORIO_SERVER_NAME="My Factorio Server" \
     -e FACTORIO_SERVER_DESCRIPTION="A Factorio Server running in Docker" \
     -e FACTORIO_MAX_PLAYERS=10 \
     -e FACTORIO_PUBLIC_VISIBLE=false \
     -e FACTORIO_LAN_VISIBLE=true \
     factorio-server:latest
   ```

## Gitリポジトリでの使用

このリポジトリをGitで管理する場合、Factorioのバージョンとハッシュを固定値としてコミットしないことをお勧めします。代わりに、以下のいずれかの方法を使用してください：

1. ビルド時にコマンドライン引数または環境変数で指定する
2. ローカル環境専用の設定ファイル（例: `.env.local`）を作成し、`.gitignore`に追加する
3. CIパイプラインで自動的に最新バージョンを取得してビルドする

## Proxmox VEへのデプロイ

### 方法1: OCIイメージからLXCコンテナを作成

1. OCIイメージをビルド

   ```bash
   cd oci
   ./build.sh
   ```

2. ビルドしたOCIイメージをエクスポート

   ```bash
   podman save factorio-server:latest | gzip > factorio-server.tar.gz
   ```

3. イメージをProxmox VEホストに転送

   ```bash
   scp factorio-server.tar.gz root@proxmox-host:/var/lib/vz/template/cache/
   ```

4. Proxmox VEでLXCコンテナを作成

   Proxmox VEのWebインターフェースまたはCLIを使用して、新しいLXCコンテナを作成します。
   
   CLIの場合：
   ```bash
   pct create 100 /var/lib/vz/template/cache/factorio-server.tar.gz --rootfs local-lvm:10 --ostype ubuntu --hostname factorio-server
   ```

5. `proxmox-lxc.conf`の設定を適用

   作成したLXCコンテナの設定ファイルを編集して、`oci/proxmox-lxc.conf`の内容を適用します。
   
   ```bash
   # 既存の設定をバックアップ
   cp /etc/pve/lxc/100.conf /etc/pve/lxc/100.conf.bak
   
   # 新しい設定を適用（必要に応じてパスを調整）
   cat oci/proxmox-lxc.conf > /etc/pve/lxc/100.conf
   ```

### 方法2: Ubuntu 24.04テンプレートから新規作成

1. Proxmox VEでUbuntu 24.04のLXCテンプレートをダウンロード

   Proxmox VEのWebインターフェースで「ローカル」→「CTテンプレート」を選択し、Ubuntu 24.04のテンプレートをダウンロードします。

2. 新しいLXCコンテナを作成

   ダウンロードしたテンプレートを使用して新しいLXCコンテナを作成します。

3. `proxmox-lxc.conf`の設定を適用

   作成したLXCコンテナの設定ファイルを編集して、`oci/proxmox-lxc.conf`の内容を適用します。

4. コンテナを起動し、必要なファイルを転送

   ```bash
   pct start 100
   pct push 100 oci/install_factorio.sh /root/install_factorio.sh
   pct push 100 common/entrypoint.sh /root/entrypoint.sh
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
