<!-- "Quickstart: Compose and Rails"を読みながらDocker ComposeでRails+MySQLの環境を作る -->

次の記事などでDockerを使ってRailsの開発環境を構築しているのを見て、自分でもやっておこうと思ったので、やってみました。

[http://dev.classmethod.jp/server-side/ruby-on-rails-on-docker/:embed:cite]

公式ドキュメントの"Quickstart: Compose and Rails"を読みながらやります。

[https://docs.docker.com/compose/rails/:embed:cite]

# 前提

まったく同じ手順でやるだけというのもなんなので、一度おなじ手順でやったあとに、次のような変更を加えてやってみました。

- Rubyのバージョンを2.3.3から2.4.1にする
- Railsのバージョンを5.0.0.1から5.1.1にする
- PostgreSQLのかわりにMySQLを使う

以降の記述でとくに言及していないファイルや手順は["Quickstart: Compose and Rails"](https://docs.docker.com/compose/rails/)での説明とおなじことをやっています。

DockerとDocker Composeは次のバージョンを使います。

- Docker
  - 17.03.1-ce
- Docker Compose
  - 1.11.2

# 作業

## Dockerfile

Railsの環境を含むイメージを作るために`Dockerfile`を書きます。

```
FROM ruby:2.4.1

RUN apt-get update -qq && apt-get install -y build-essential libmysqlclient-dev nodejs

RUN mkdir /myapp
WORKDIR /myapp

ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock

RUN bundle install

ADD . /myapp
```

Ruby 2.4.1の公式イメージがあるので、タグ`2.4.1`を指定します。Rubyのイメージの大元はDebianのイメージなので、`apt-get`で必要なパッケージをインストールしていきます。

RubyのMySQLクライアントである`mysql2`というgemが`libmysqlclient-dev`というライブラリに依存するので、このライブラリをインストールしておきます。

## Gemfile

さきほどの`Dockerfile`でイメージへコピーしていた`Gemfile`は、Railsの5.1.1を使うことから次のような内容とします。

```ruby
source 'https://rubygems.org'
gem 'rails', '5.1.1'
```

## docker-compose.yml

複数のコンテナをDocker Composeで立ち上げるためにComposeファイル`docker-compose.yml`を書きます。

```yaml
version: '3'
services:
  db:
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
  web:
    build: .
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/myapp
    ports:
      - "3000:3000"
    depends_on:
      - db
```

2017年5月現在、Composeファイルはバージョン3が最新版かつ推奨((https://docs.docker.com/compose/compose-file/compose-versioning/))なので、`version: 3`を指定しておけばよさそうです。

MySQLを使うとき、環境変数に`MYSQL_ROOT_PASSWORD`, `MYSQL_ALLOW_EMPTY_PASSWORD`, `MYSQL_RANDOM_ROOT_PASSWORD`のどれかを指定する必要があります。詳しくは[MySQL公式イメージのページ](https://hub.docker.com/_/mysql/)にある"Environment Variables"の節を参照してください。今回は`MYSQL_ROOT_PASSWORD`でrootパスワードを指定しておきます。

## イメージのビルド

手順どおりやればOKです。イメージビルド後にRailsプロジェクトを作成するときMySQLを使う設定ファイルを生成するために、オプション`--database`を指定しておきます。

```
$ docker-compose run web rails new . --force --database=mysql --skip-bundle
```

## データベースへの接続設定

`config/database.yml`の`password`に`docker-compose.yml`で環境変数に指定したパスワードを書いておきます。実際はパスワードも環境変数などの間接的な方法で管理することになるでしょう。`host`は`docker-compose.yml`内で指定したDB用コンテナの名前`db`を指定します。

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: db

development:
  <<: *default
  database: myapp_development

test:
  <<: *default
  database: myapp_test
```

はじめはDBがないので作る必要があります。Rails 5では`rails`コマンドでタスクを実行できます。

```
$ docker-compose run web bin/rails db:create
```

## コンテナの起動

最後に次のコマンドで`web`, `db`のコンテナを立ち上げて、ブラウザで`localhost:3000`にアクセスすればRailsのデフォルトページが見られます。

```
$ docker-compose up
```
