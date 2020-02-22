<!-- Springが動くRails+MySQLなAPIサーバの開発環境をDocker Composeで作る -->

このあいだ、Rails+MySQLという構成のアプリケーション開発環境をDocker Composeで構築できるようにしました。

[http://blog.kymmt.com/entry/compose-and-rails-api:cite:embed]

いろいろと理解が深まるにつれて、何点かクリアしたい問題が見えてきました。

- `Dockerfile` で使うイメージ
  - `ruby:2.4.1-onbuild` は `RUN bundle config frozen 1` しているので、あとから `Gemfile` を更新して `bundle install` できない
- `bundle install` に時間がかかる
  - `Gemfile` にgemを追加するたびに、すべてのgemのインストールが走る
- `rails`, `rake` コマンドの立ち上がりが遅い
  - アプリケーションプリローダSpringのサーバが立ち上がっていないため

今回はこれらの問題をクリアして、**さらにいい感じ**の開発環境を作ります。

## `Dockerfile` で使うイメージ

前回作った `Dockerfile` では `ruby:2.4.1-onbuild` というイメージを使っていました。このイメージは `ONBUILD` 命令を使っており、このイメージを使った `Dockerfile` をビルドすることで `ONBUILD` に指定されたコマンドが自動で実行されるようになっています。Rubyの場合だと、`Gemfile` のイメージ内へのコピーや `bundle install` の実行のような決まりきったコマンドが `ONBUILD` として指定されているので、`Dockerfile` の作成を省力化できます。`ruby:2.4.1-onbuild` の `Dockerfile` は次のものです。

- [ruby/Dockerfile at 752c5f7cf44870ceae77134b346d20093053c370 · docker-library/ruby](https://github.com/docker-library/ruby/blob/752c5f7cf44870ceae77134b346d20093053c370/2.4/onbuild/Dockerfile)

しかし、この `ruby:2.4.1-onbuild` では、`RUN bundle config --global frozen 1` というコマンドを実行するようになっています。これは、イメージ内の `Gemfile` を変更して `bundle install` できないようにするものです(([Bundler: bundle config](http://bundler.io/v1.15/man/bundle-config.1.html#LIST-OF-AVAILABLE-KEYS)))。

デプロイするような用途であればこれでもよいですが、今回は**開発環境**がほしいので、`Gemfile` は必要なときに都度変更してgemをインストールできるようにしたいです。また、`onbuild` タグがついたイメージは非推奨となっているようでした(([library/ruby - Docker Hub](https://hub.docker.com/_/ruby/)))。

そこで、`ruby:2.4.1-onbuild` イメージを使うのはやめて、`ruby:2.4.1` イメージをベースに自分でもろもろの作業をやる `Dockerfile` になるように書き直しました。

```
FROM ruby:2.4.1

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile \
     Gemfile.lock \
     $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=4
RUN bundle install
```

（※後述の［追記］も参照してください）

これで、コンテナ内の `Gemfile` をあとから編集しても、`bundle install` が実行できます。

## `bundle install` に時間がかかる

現在、`bundle install` で入るgemの保存先はコンテナ内になっています。この場合、`Gemfile` にgemを追加してインストールしたいときはイメージを作り直す必要がありますが、これだとすべてのgemのインストールが走ってしまいます。

これを回避するために、gemの保存先をDocker Volumeに変更します。`docker-compose.yml` でgem保存用のVolumeを作り、APIサーバを動かすコンテナにマウントします。

```yaml
version: '3'
services:
  # dbの設定...

  app:
    build: .
    command: bin/rails s -p 3000 -b "0.0.0.0"
    depends_on:
      - db
    ports:
      - "3000:3000"
    stdin_open: true
    tty: true
    volumes:
      - .:/usr/src/app
      - bundle_cache:/usr/local/bundle
volumes:
  bundle_cache:
```

`bundle_cache` がgem保存用のVolumeです。マウント先が `/usr/local/bundle` になっているのは、ベースイメージとしている `ruby:2.4.1` が `GEM_HOME` を `/usr/local/bundle` としているからです。

https://github.com/docker-library/ruby/blob/752c5f7cf44870ceae77134b346d20093053c370/2.4/Dockerfile#L63

これで、gemをVolumeへ保存できるようになりました。コンテナが終了したあともVolumeにgemが残ります。`Gemfile` にgemを追加して `bundle install` したいときは、次のようにコンテナを起動すればOKです。

```
$ docker-compose run app --rm bundle install
```

### ［2017-06-11 追記］`bundle install` する場所について

`bundle install` を `Dockerfile` に書くと、イメージのビルド時にインストールされたgemがイメージに入ります。この時点ではgemを保存するVolumeが設定されていないのですが、`docker-compose` コマンド経由でコンテナを起動すると、Volumeがgem保存先にマウントされます。このVolumeが上述の説明で使っている**名前付きボリューム**だと、マウント先に存在するファイルはVolumeへコピーされます(([Manage data in containers | Docker Documentation](https://docs.docker.com/engine/tutorials/dockervolumes/)))。

しかし、コンテナ起動前後でgemの保存の仕組みが変わるのはわかりにくいです。`Dockerfile` 内に `bundle install` を書くのではなく `docker-compose run --rm app bundle install` のように明示的にVolumeへgemをインストールする、という方法のほうがわかりやすそうです。

## `rails`, `rake` コマンドの立ち上がりが遅い

RailsにはデフォルトでSpringというアプリケーションプリローダが入っています。Springを起動させておくと、`rails`, `rake` のようなコマンドの実行を高速化できます。現在、Springのことを考慮していないので、APIサーバとは別にSpring用のコンテナを立ち上げるようにします。

実際の作業内容では、この記事が参考になりました。ほとんどこの記事のとおりやっています。

[http://tech.degica.com/ja/2016/06/14/dockerized-rails-development/:cite:embed]

```yaml
version: '3'
services:
  # dbの設定...

  app: &app_base
    build: .
    command: bin/rails s -p 3000 -b "0.0.0.0"
    depends_on:
      - db
    ports:
      - "3000:3000"
    stdin_open: true
    tty: true
    volumes:
      - .:/usr/src/app
      - bundle_cache:/usr/local/bundle
  spring:
    <<: *app_base
    command: bin/spring server
    ports: []
volumes:
  bundle_cache:
```

`bin` 配下にある `rails` や `rake` のようなbinstubにSpringの処理を差し込み、叩くコマンドを省略できるようにする機能があるので、それを実行しておきます。

```
$ docker-compose exec spring bundle exec spring binstub --all
* bin/rake: spring inserted
* bin/rails: spring inserted
```

`docker-compose up` で `app` と `spring` のコンテナを立ち上げたあと、実行中の `spring` コンテナ内でSpringを通じたコマンドの実行ができます。

```
$ docker-compose exec spring bin/rails console
```

### ［参考］`spring` コマンド実行時にエラーが出る場合

もし `.bundle/config` 内で `BUNDLE_DISABLE_SHARED_GEMS: 1` という設定がある場合は削除する必要があります。この設定があると、Springを通じたコマンド実行時にうまくgemの場所を解決ができず次のエラーが出てしまいます。

```
Could not find rake-12.0.0 in any of the sources
Run `bundle install` to install missing gems.
```

あんまりないと思いますが、以前に `bundle install --path vendor/bundle` したときに自動で `BUNDLE_DISABLE_SHARED_GEMS` が設定に入っていてハマりました…

## 結果

`Dockerfile` は次のようになりました。

```
FROM ruby:2.4.1

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile \
     Gemfile.lock \
     $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=4
RUN bundle install
```

`docker-compose.yml` は次のとおりです。

```yaml
version: '3'
services:
  db:
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    image: mysql:5.7
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
  app: &app_base
    build: .
    command: bin/rails s -p 3000 -b "0.0.0.0"
    depends_on:
      - db
    ports:
      - "3000:3000"
    stdin_open: true
    tty: true
    volumes:
      - .:/usr/src/app
      - bundle_cache:/usr/local/bundle
  spring:
    <<: *app_base
    command: bin/spring server
    ports: []
volumes:
  bundle_cache:
  mysql_data:
```
