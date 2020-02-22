<!-- Rails+MySQLなAPIサーバの開発環境をDocker Composeで作る -->

先日、"Quickstart: Compose and Rails"の手順にしたがいながら、Docker ComposeでRails+MySQLがとりあえず動くような環境を作りました。

[http://blog.kymmt.com/entry/compose-and-rails:cite:embed]

今回は、RailsのAPIサーバの開発環境を**もうちょっといい感じ**にDocker Composeで作ってみます。DBにはMySQL 5.7を使います。

# ディレクトリ構成

コマンド `rails new sample_app --api --db=mysql` でRailsのプロジェクトツリーを作り、ルートに `Dockerfile` と `docker-compose.yml` を置きます。

```
.
├── Gemfile
├── Gemfile.lock
├── app
│   └── ...
├── config
│   ├── database.yml
│   └── ...
├── db
│   ├── migrate
│   │   └── ...
│   ├── seeds.rb
│   └── ...
├── Dockerfile
├── docker-compose.yml
└── ...
```

# イメージの作成

最終的に立ち上げたいDockerコンテナは次のふたつです。

- `app`
  - APIモードのRailsの実行環境
- `db`
  - MySQL 5.7の実行環境

このうち、`db` は既存のMySQL公式イメージを使ってコンテナを立ち上げます。`app` は次の `Dockerfile` を書いてイメージを作ります。

```
FROM ruby:2.4.1-onbuild
```

ここでは、Ruby 2.4.1の公式イメージ(([Railsの公式イメージは存在しますが](https://hub.docker.com/_/rails/)、今では非推奨となっています))、特に `ruby:2.4.1-onbuild` というイメージを使います。

Rubyの公式イメージは `buildpack-deps` というイメージをもとにしています。この `buildpack-deps` はRubyやPythonのライブラリのインストールに必要となりやすいライブラリをあらかじめインストールする便利なイメージです。

- [library/buildpack-deps - Docker Hub](https://hub.docker.com/_/buildpack-deps/)

MySQLをRubyから利用するために、本来は `libmysql-dev` というライブラリをインストールする必要があります。しかし、このライブラリは `buildpack-deps` があらかじめインストールしているので、今回の `Dockerfile` には明示的に書かないでも大丈夫です。

このあと、本来はホストに存在するRailsアプリケーションのプロジェクトツリーを `app` イメージ内にコピーする必要がありますが、この処理を `Dockerfile` に書いていません。これは、`app` のもととなるイメージに `ruby:2.4.1-onbuild` を使っているからです。このイメージの `Dockerfile` はおおむね次のようになっており、処理が `ONBUILD` で記述されています。`ruby:2.4.1-onbuild` では `Gemfile` のコピーやBundlerでの依存gemインストール、プロジェクトツリーのコピーといった定型作業を `ONBUILD` で指定してあります。`ONBUILD` を持つイメージをもとに作った新たなイメージからコンテナをビルドしたあとに、`ONBUILD` で指定した処理が実行されるようになっています。

```
FROM ruby:2.4

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# このイメージをもとにしたイメージからコンテナをビルドしたあとに実行する
ONBUILD COPY Gemfile /usr/src/app/
ONBUILD COPY Gemfile.lock /usr/src/app/
ONBUILD RUN bundle install
ONBUILD COPY . /usr/src/app
```

ちなみに、もし `buildpack-deps` で入るもの以外のライブラリをインストールしたい場合は、今回書いた`Dockerfile` に次のように追記する必要があります。

```
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    nodejs \
 && rm -rf /var/lib/apt/lists/*
```

ここでは、Debianの公式パッケージのビルドに必要な `build-essential` をインストールしています。さらに `&&` でつないでインストールしたいパッケージの名前（たとえば `nodejs`）を指定します。このあと、さらに `rm -rf var/lib/apt/lists/*` を実行していますが、これはベストプラクティスとされている方法であり、APTのキャッシュを削除することでイメージのサイズを削減しています。

- [Best practices for writing Dockerfiles | Docker Documentation](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run)

# Composeファイルの作成

`app` と `db` をコンテナとして起動するためにComposeファイルを作ります。

```yaml
version: '3'
services:
  db:
    image: mysql:5.7
    volumes:
      - mysql_data:/var/lib/mysql
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ports:
      - "3306:3306"
  app:
    build: .
    command: bin/rails s -b "0.0.0.0"
    volumes:
      - .:/usr/src/app
    ports:
      - "3000:3000"
    depends_on:
      - db
volumes:
  mysql_data:
```

ファイルの末尾で `volumes` を指定し、Docker Engineがサポートする名前付きボリュームとして `mysql_data` を作成しています。ボリュームというのはコンテナ間で共有できるデータを保存する仕組みです。ボリュームはコンテナとは独立して作成するため、たとえそのボリュームを使う `db` コンテナが破棄されてもデータはホストに残ります。

今回のComposeファイルでは、名前付きボリュームとして `mysql_data` を作成し、`db` の設定にある `volumes` で `mysql_data` を `db` の `/var/lib/mysql` ディレクトリにマウントする形で利用しています。

`app` では `depends_on` という設定項目に `db` を指定しています。これによって、依存先のサービスをコンテナとして立ち上げてから、本サービスを立ち上げるようになります。

# Railsのデータベース設定

Railsの `config/database.yml` で、開発／テスト環境のDBを次のとおり設定します。

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password:
  host: db

development:
  <<: *default
  database: sample_app_development

test:
  <<: *default
  database: sample_app_test
```

`docker-compose.yml` で `app` の依存先として `db` を指定し、`host: db` と指定することで、コンテナ `db` へ接続することができます。

# コンテナの立ち上げ

次の要領で `app` と `db` の各コンテナを立ち上げます。

1. APIサーバで使うDBをセットアップ（DBの作成、テーブルの作成、初期データの投入など）する
2. Docker Composeでコンテナ群を立ち上げる

コンテナ群を立ち上げる前にDBをセットアップしておかないと、APIサーバにリクエストがあったときにエラーが発生します。

次のコマンドでDBをセットアップします。

```
$ docker-compose run --rm app bin/rails db:setup
```

このコマンドによって、次のように処理が進みます。

- `app` が依存する `db` のコンテナを先にイメージから立ち上げる
- `app` のコンテナを `Dockerfile` から立ち上げる
- `app` のなかのワーキングディレクトリ `/usr/src/app` で `bin/rails db:setup` を実行し、DBのセットアップを実行する

これでAPIサーバを動かせるようになりました。最後に次のコマンドを叩き、`app` と `db` のコンテナを立ち上げると、RailsとMySQLが動きだします。

```
$ docker-compose up
```

`curl http://localhost:3000/users/1` のようなリクエスト送信で疎通が取れます。また、ホストの `Dockerfile` を置いているディレクトリをコンテナ内の該当ディレクトリにマウントしているので、ホストでコードを編集すると直にコンテナ内に反映されます。

開発中に `Gemfile` を更新したときは次のコマンドでイメージをビルドし直します。

```
$ docker-compose build app
```

RSpecのテストは次の要領で実行できます。

```
$ docker-compose run --rm app bin/rspec
```
