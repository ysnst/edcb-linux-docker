# EDCB Linux Docker

Linux版 EDCB を Docker 上で利用しやすくするための構成です。Linux ネイティブ版 EDCB、BonDriver_LinuxMirakc、Multi2Dec (B25Decoder) をコンテナ内でビルドし、EDCB Material WebUI を初期設定テンプレートに組み込みます。チューナーバックエンドには Mirakurun / mirakc を使います。

Windows版 EDCB を Wine で動かすのではなく、Linux ネイティブで動作する EDCB 環境を Docker で再現できるようにすることを目的としています。Wine やデスクトップ環境を含めず、Mirakurun / mirakc を前提にした軽量な構成にしています。EDCB-Wine と完全互換の環境ではありませんが、Linux ネイティブな代替構成・選択肢として使えることを目指しています。

## 特徴

- Linux ネイティブ版 EDCB を利用
- Docker による再現可能なビルド
- Mirakurun / mirakc に対応
- `BonDriver_LinuxMirakc` を自動ビルドして `/usr/local/lib/edcb/` に配置
- Multi2Dec の `B25Decoder.so` を自動ビルドして `/usr/local/lib/edcb/` に配置
- EDCB Material WebUI を初期設定テンプレートに組み込み
- 初回起動時だけ `edcb-data` に初期設定を自動展開
- 既存の `edcb-data` は上書きしない
- Wine、デスクトップ環境、VNC サーバーを含まない
- EDCB-Wine の Linux ネイティブな代替構成を目指した設計

## 対象ユーザー

- Linux 上で EDCB を動作させたい
- Docker で EDCB を運用したい
- Mirakurun / mirakc を既に利用している
- Wine を使用したくない
- Linux ネイティブ版 EDCB を利用したい
- EDCB-Wine から Linux ネイティブ構成への移行を検討している

## EDCB-Wine との違い

| 項目             | このリポジトリ                                 | EDCB-Wine                                          |
| ---------------- | ---------------------------------------------- | -------------------------------------------------- |
| EDCB             | Linux版 EDCB                                   | Windows版 EDCB                                     |
| Wine             | 使用しない                                     | 使用する                                           |
| チューナー連携   | Mirakurun / mirakc + BonDriver_LinuxMirakc     | Mirakurun / mirakc + Windows向け BonDriver         |
| GUI デスクトップ | 含めない                                       | Xfce / noVNC を含む                                |
| 主な用途         | Linux ネイティブ環境で EDCB を動かしたい人向け | Windows版 EDCB の操作感を Linux 上で使いたい人向け |

EDCB-Wine から移行できる可能性はありますが、完全互換ではありません。設定ファイル、BonDriver、録画パス、Web UI 周りは Linux版 EDCB の前提で確認してください。

## システム構成

```text
Browser / EpgTimerNW
        |
        | HTTP / TCP
        v
+-------------------------------+
| Docker container              |
|                               |
|  EpgTimerSrv                  |
|    |                          |
|    +-- BonDriver_LinuxMirakc  |
|    |        |                 |
|    |        v                 |
|    |   Mirakurun / mirakc API |
|    |                          |
|    +-- B25Decoder.so          |
|                               |
|  /var/local/edcb              |
+-------------------------------+
        |
        | host network
        v
Host Mirakurun / mirakc :40772
```

`docker-compose.yml` は `network_mode: host` を使います。Linux ホストでは、コンテナ内の `localhost:40772` がホスト側の Mirakurun / mirakc を指します。

## 動作環境

- Linux ホスト
- Docker
- Docker Compose v2
- Mirakurun または mirakc
- Mirakurun 互換 API が既定で `localhost:40772` から参照できること

Docker Desktop では host network の挙動が Linux ホストと異なる場合があります。この構成は Linux ホストでの利用を前提にしています。

## ディレクトリ構成

```text
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── templates/
│   └── BonDriver_LinuxMirakc.ini
├── README.md
└── edcb-data/        # 初回起動後に作成される設定・実行時データ
```

`edcb-data` には EDCB の設定、EPG データ、ログ、予約情報などが入ります。利用環境ごとのデータとして扱ってください。

## インストール

リポジトリを配置したディレクトリでビルドします。

```sh
docker compose build
```

ビルド時に、次のリポジトリからソースコードを取得します。Linux版 EDCB、BonDriver_LinuxMirakc、Multi2Dec はコンテナ内でビルドし、EDCB Material WebUI は初期設定テンプレートに配置します。

| 用途                                | 取得元                                                                                | 既定値                 |
| ----------------------------------- | ------------------------------------------------------------------------------------- | ---------------------- |
| Linux版 EDCB                        | [xtne6f/EDCB](https://github.com/xtne6f/EDCB)                                         | `work-plus-s` ブランチ |
| EDCB Material WebUI                 | [tsukumijima/EDCB_Material_WebUI](https://github.com/tsukumijima/EDCB_Material_WebUI) | 既定ブランチ           |
| Mirakurun / mirakc 連携用 BonDriver | [matching/BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc)   | 既定ブランチ           |
| B25Decoder                          | [tsukumijima/Multi2Dec](https://github.com/tsukumijima/Multi2Dec)                     | 既定ブランチ           |

ビルド対象の upstream やブランチを変えたい場合は、`docker-compose.yml` の `build.args`、または `docker compose build --build-arg` を使ってください。通常は変更不要です。

## 初回起動

コンテナを起動します。

```sh
docker compose up -d
```

`./edcb-data` が空の場合だけ、イメージ内の初期設定テンプレートをコピーします。`edcb-data` に既存ファイルがある場合はコピーしません。既存設定を守るため、`EpgTimerSrv.ini` が見つからない場合でも自動上書きは行わず、警告だけを出します。

起動状態を確認します。

```sh
docker compose ps
docker compose logs edcb
```

Web UI は EDCB の HTTP サーバーを使います。初期設定のままなら、ホストから次の URL にアクセスします。

```text
http://localhost:5510/
```

EDCB Material WebUI は次の URL から開けます。

```text
http://localhost:5510/EMWUI/
```

## Mirakurun / mirakc 設定

既定のテンプレートは `localhost:40772` の Mirakurun / mirakc に接続します。

```ini
[GLOBAL]
SERVER_HOST=localhost
SERVER_PORT=40772
```

接続先を変える場合は、初回起動後に作成される `edcb-data/BonDriver_LinuxMirakc.ini` を編集します。

```ini
[GLOBAL]
SERVER_HOST=<mirakurun-host>
SERVER_PORT=40772
```

ただし、`network_mode: host` を使う Linux ホストでは `localhost` のままでホスト側サービスへ接続できます。固定 IP を README やテンプレートに直接入れず、必要な環境だけ `edcb-data` 側で変更してください。

## BonDriver_LinuxMirakc

`BonDriver_LinuxMirakc.so` は Docker イメージ内の次のパスに配置します。

```text
/usr/local/lib/edcb/BonDriver_LinuxMirakc.so
```

EDCB 側の初期設定では、この BonDriver を使う前提です。Mirakurun / mirakc に登録しているチューナー数やチャンネル構成は、利用環境に合わせて EDCB 側で確認してください。

## B25Decoder

Multi2Dec の `B25Decoder.so` は次のパスに配置します。

```text
/usr/local/lib/edcb/B25Decoder.so
```

`BonCtrl.ini` では地上波、BS、CS などの復号処理に `B25Decoder.so` を使う設定になります。B-CAS / ACAS やカードリーダー周りは利用環境に依存するため、ホスト側の構成と Docker のデバイスアクセスを必要に応じて確認してください。

## 設定ファイル

主な設定ファイルは初回起動後に `edcb-data` 配下へ作成されます。

| パス                                  | 内容                                     |
| ------------------------------------- | ---------------------------------------- |
| `edcb-data/BonDriver_LinuxMirakc.ini` | Mirakurun / mirakc の接続先              |
| `edcb-data/EpgTimerSrv.ini`           | EpgTimerSrv の HTTP / TCP / EPG 取得設定 |
| `edcb-data/BonCtrl.ini`               | 復号ライブラリやチャンネルスキャンの設定 |
| `edcb-data/Setting/`                  | チャンネル、予約、Web UI などの設定      |
| `edcb-data/HttpPublic/`               | EDCB の HTTP 公開ファイル                |
| `edcb-data/HttpPublic/EMWUI/`         | EDCB Material WebUI                      |

`edcb-data` は実行時データです。テンプレートとして再配布せず、自分の環境で使う設定として扱ってください。

## 録画フォルダ

録画ファイルをコンテナ外へ保存する場合は、ホスト側のディレクトリをマウントします。

```yaml
services:
  edcb:
    volumes:
      - ./edcb-data:/var/local/edcb
      - /mnt/recordings:/recorded
```

その後、EDCB 側の録画フォルダ設定にコンテナ内のパスを指定します。

```text
/recorded
```

ホスト側の保存先は、Docker コンテナから書き込める権限にしてください。録画先をマウントしない場合、コンテナ内だけに保存される設定になり、コンテナの作り直しや設定変更時に扱いづらくなります。

## アップデート方法

通常の更新は、イメージを再ビルドしてコンテナを作り直します。

```sh
docker compose build --pull
docker compose up -d
```

`edcb-data` はホスト側に残るため、再ビルドしても既存設定は保持されます。upstream の EDCB、BonDriver_LinuxMirakc、Multi2Dec の変更を取り込む場合は、ビルドキャッシュを使わずに再ビルドします。

```sh
docker compose build --no-cache
docker compose up -d
```

設定変更前や大きな更新前には、`edcb-data` をバックアップしてください。

## 動作確認

必要な共有ライブラリがイメージに入っているか確認します。

```sh
docker compose run --rm --entrypoint sh edcb -c \
  "test -f /usr/local/lib/edcb/B25Decoder.so && test -f /usr/local/lib/edcb/BonDriver_LinuxMirakc.so"
```

起動後にログを確認します。

```sh
docker compose logs edcb
```

Mirakurun / mirakc に接続できない場合は、`edcb-data/BonDriver_LinuxMirakc.ini` の `SERVER_HOST` と `SERVER_PORT`、ホスト側の Mirakurun / mirakc の待ち受け状態を確認してください。

## FAQ

### Wine は必要ですか？

不要です。このリポジトリは Linux版 EDCB を使うため、Wine は使いません。

### EDCB-Wine の代替になりますか？

用途によっては代替になります。ただし Windows版 EDCB、Wine、noVNC、Xfce を前提にした操作や設定とは互換ではありません。Linux ネイティブ構成を使いたい場合の選択肢として考えてください。

### Mirakurun ではなく mirakc でも使えますか？

Mirakurun 互換 API を提供していれば利用できます。既定の接続先は `localhost:40772` です。

### `edcb-data` を削除するとどうなりますか？

次回起動時に初期テンプレートが再コピーされます。ただし、予約情報、EPG データ、チャンネル設定、録画関連の設定も消えます。削除前にバックアップしてください。

### 既存設定は上書きされますか？

上書きしません。`entrypoint.sh` は `edcb-data` が空のときだけ初期テンプレートをコピーします。

### 録画フォルダはどこに置けばよいですか？

ホスト側の永続化したいディレクトリを Docker Compose でマウントし、EDCB 側にはコンテナ内のパスを指定します。例では `/mnt/recordings` を `/recorded` としてマウントしています。

## トラブルシューティング

### `http://localhost:5510/` にアクセスできない

`docker compose ps` と `docker compose logs edcb` でコンテナが起動しているか確認してください。`EpgTimerSrv.ini` の HTTP サーバー設定を変更した場合は、ポートやアクセス許可も確認します。

### Mirakurun / mirakc に接続できない

ホスト側で Mirakurun / mirakc が起動しているか確認してください。Linux ホストで `network_mode: host` を使う場合は、通常 `SERVER_HOST=localhost` で接続できます。別ホストの Mirakurun / mirakc を使う場合は、`edcb-data/BonDriver_LinuxMirakc.ini` を編集します。

### チャンネルやチューナー数が合わない

Mirakurun / mirakc 側のチューナー定義と、EDCB 側の BonDriver / チャンネル設定を確認してください。初期設定のまま全環境で正しいチャンネル構成になるわけではありません。

### 録画ファイルが見つからない

EDCB 側の録画フォルダ設定が、Docker Compose でマウントしたコンテナ内パスを指しているか確認してください。ホスト側パスではなく、コンテナ内から見えるパスを指定します。

### ビルドが失敗する

upstream からの取得、Debian パッケージの取得、またはビルド依存関係で失敗している可能性があります。まず `docker compose build --no-cache` で再確認してください。ネットワーク障害や upstream の一時的な変更で失敗する場合もあります。

## ライセンス

このリポジトリ自体のライセンスは MIT License です。詳細は `LICENSE` を参照してください。

この Docker 構成は、ビルド時に複数の外部プロジェクトを取得して利用します。各プロジェクトのライセンスは、それぞれの upstream を確認してください。

- EDCB
- EDCB Material WebUI
- BonDriver_LinuxMirakc
- Multi2Dec
- Debian パッケージ群
