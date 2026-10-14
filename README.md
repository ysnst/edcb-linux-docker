# EDCB Linux Docker

Linux版EDCBをDockerで動かすための構成です。チューナーには、別途用意したMirakurunまたはmirakcを使います。

EDCB、BonDriver_LinuxMirakc、Multi2DecのB25Decoderをイメージ内でビルドし、EDCB Material WebUIを同梱します。WineやGUIデスクトップは使いません。

## 導入

LinuxホストにDockerとDocker Compose v2が必要です。先にMirakurunまたはmirakcを起動し、Mirakurun互換APIに接続できる状態にしてください。初期設定の接続先は `localhost:40772` です。

Composeは `network_mode: host` を使います。コンテナ内の `localhost` はLinuxホストを指します。Docker Desktopはこの手順の対象外です。

`Dockerfile` と `docker-compose.yml` があるディレクトリで実行します。

```sh
docker compose build
docker compose up -d
docker compose ps
docker compose logs edcb
```

初回起動時に、空の `./edcb-data` へ設定ファイルとWeb UIをコピーします。このディレクトリには、以後の設定、予約情報、EPGデータ、ログも保存されます。

ファイルがすでに入っている場合はコピーしません。`EpgTimerSrv.ini` がなくても既存ファイルは上書きせず、ログに警告を出します。イメージを更新しても、既存の設定やWeb UIは自動更新されません。

HTTPサーバーの設定は `edcb-data/EpgTimerSrv.ini` で確認してください。ポート5510で利用する場合のURLは次のとおりです。

- EDCB Web UI: `http://localhost:5510/`
- EDCB Material WebUI: `http://localhost:5510/EMWUI/`

別のPCから開く場合は、`localhost` をEDCBホストの名前またはIPアドレスに置き換えます。HTTPサーバーのアクセス許可も確認してください。

## チューナーと録画先の設定

### Mirakurun / mirakc

接続先は `edcb-data/BonDriver_LinuxMirakc.ini` で指定します。同じホストで動かしている場合は、初期設定のまま使えます。

```ini
[GLOBAL]
SERVER_HOST=localhost
SERVER_PORT=40772
```

別ホストに接続する場合は `SERVER_HOST` をそのホスト名またはIPアドレスに変更します。APIのポートを変えている場合は `SERVER_PORT` も合わせてください。

EDCB側では、利用するBonDriver、チューナー数、チャンネル設定を確認します。初期設定だけで、利用環境に合うチャンネル構成が揃うとは限りません。

イメージ内のライブラリは次の場所にあります。

| ライブラリ | コンテナ内のパス |
| --- | --- |
| BonDriver_LinuxMirakc | `/usr/local/lib/edcb/BonDriver_LinuxMirakc.so` |
| B25Decoder | `/usr/local/lib/edcb/B25Decoder.so` |

復号に関する設定は `edcb-data/BonCtrl.ini` で確認します。B-CAS / ACASやカードリーダーを使う場合は、ホスト側の構成とコンテナからのアクセスも確認してください。

### 録画フォルダ

ホスト側の録画先をComposeの `volumes` に指定し、EDCBにはコンテナ内のパスを設定します。たとえば、ホストの `/mnt/recordings` へ保存する場合は次のようにします。

```yaml
services:
  edcb:
    volumes:
      - ./edcb-data:/var/local/edcb
      - /mnt/recordings:/app/recorded
```

この場合、EDCBの録画フォルダは `/app/recorded` です。ホスト側の `/mnt/recordings` をEDCBに指定しても、同じ場所は参照できません。

既存のマウント先がある場合は、そのコンテナ内パスに合わせてください。ホスト側のディレクトリには、コンテナから書き込める権限が必要です。マウントしていない場所へ録画すると、コンテナの削除で録画ファイルを失うことがあります。

## 設定ファイル

ホストの `./edcb-data` は、コンテナ内の `/var/local/edcb` にマウントされます。

| パス | 用途 |
| --- | --- |
| `edcb-data/BonDriver_LinuxMirakc.ini` | Mirakurun / mirakcの接続先 |
| `edcb-data/EpgTimerSrv.ini` | HTTP・TCPサーバー、EPG取得などの設定 |
| `edcb-data/BonCtrl.ini` | 復号ライブラリ、チャンネルスキャンなどの設定 |
| `edcb-data/Setting/` | チャンネル、予約、Web UIなどの設定 |
| `edcb-data/HttpPublic/` | HTTPサーバーの公開ファイル |
| `edcb-data/HttpPublic/EMWUI/` | EDCB Material WebUI |

`templates/BonDriver_LinuxMirakc.ini` は初回起動用です。起動済みの環境で接続先を変更する場合は、`edcb-data` 側を編集してください。

Windows版EDCBやEDCB-Wineから設定を移す場合は、BonDriver、録画パス、Web UIの設定をLinux版に合わせて確認します。Windows版の設定や操作をそのまま使える構成ではありません。

## 更新

更新前に `edcb-data` をバックアップしてください。削除すると、予約情報やチャンネル設定も失われます。

ベースイメージを更新してビルドする場合は、次のコマンドを使います。

```sh
docker compose build --pull
docker compose up -d
```

EDCBなどの取得元にある変更を取り込む場合は、ビルドキャッシュを使わずに再取得します。

```sh
docker compose build --no-cache
docker compose up -d
```

どちらも `edcb-data` は保持します。新しいイメージの初期設定やWeb UIを使う場合は、既存ファイルとの差分を確認して更新してください。

## 困ったとき

まずコンテナの状態とログを確認します。

```sh
docker compose ps
docker compose logs edcb
```

### Web UIが開かない

`edcb-data/EpgTimerSrv.ini` のHTTPサーバー設定、ポート、アクセス許可を確認してください。別のPCから接続する場合は、URLのホスト名とホスト側のファイアウォールも確認します。

### Mirakurun / mirakcに接続できない

Mirakurun / mirakcが起動しているか、APIが待ち受けているかを確認します。接続先は `edcb-data/BonDriver_LinuxMirakc.ini` の `SERVER_HOST` と `SERVER_PORT` です。

### チャンネルが出ない、チューナー数が合わない

Mirakurun / mirakc側のチューナー定義と、EDCB側のBonDriver・チャンネル設定を確認してください。

### 録画できない、録画ファイルが見つからない

EDCBの録画フォルダが、Composeでマウントしたコンテナ内のパスを指しているか確認します。保存先ディレクトリの書き込み権限も確認してください。

### ビルドに失敗する

ビルドログで、ソースの取得、Debianパッケージの取得、コンパイルのどこで失敗したかを確認します。キャッシュを使わずにやり直す場合は `docker compose build --no-cache` を使います。

イメージ内にBonDriverとB25Decoderがあるかは、次のコマンドで確認できます。これはファイルの存在確認で、チューナー接続や録画のテストではありません。

```sh
docker compose run --rm --entrypoint sh edcb -c \
  "test -f /usr/local/lib/edcb/B25Decoder.so && test -f /usr/local/lib/edcb/BonDriver_LinuxMirakc.so"
```

## ビルド元

ビルド時に以下のソースを取得します。

| 用途 | 取得元 | ブランチ |
| --- | --- | --- |
| Linux版EDCB | [xtne6f/EDCB](https://github.com/xtne6f/EDCB) | `work-plus-s` |
| EDCB Material WebUI | [tsukumijima/EDCB_Material_WebUI](https://github.com/tsukumijima/EDCB_Material_WebUI) | 既定ブランチ |
| BonDriver | [matching/BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc) | 既定ブランチ |
| B25Decoder | [tsukumijima/Multi2Dec](https://github.com/tsukumijima/Multi2Dec) | 既定ブランチ |

取得先はDockerfileの `EDCB_REPO`、`BON_REPO`、`MULTI2DEC_REPO`、`EMWUI_REPO`、EDCBのブランチは `EDCB_BRANCH` で変更できます。Composeの `build.args` または `docker compose build --build-arg` で指定してください。

## ライセンス

このDocker構成はMIT Licenseです。[LICENSE](LICENSE)を参照してください。同梱する各プロジェクトとDebianパッケージには、それぞれのライセンスが適用されます。
