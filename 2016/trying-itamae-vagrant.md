<!-- Itamae + Vagrant でステージング環境を構築しようとしている -->

ここ数日、構成管理ツールの練習と自作の Rails アプリケーションを本番に近い環境で動かせるようにすることを兼ねて、[**Itamae**](http://itamae.kitchen) を使って Vagrant 上にステージング環境を作ろうとしています。

とりあえず、Rails で構築した自分の web サイトである [kymmt.com](https://kymmt.com/) を動かすべく、Vagrant で CentOS 7 の VM を作って環境構築をやっていて、現状は Itamae で次の項目を実行できるようになりました。

- rbenv で Ruby をインストール
- Bundler をインストール
- GitHub からアプリケーションのリポジトリをダウンロード
- nginx のインストールと設定
- PostgreSQL のインストールと設定

あまりキレイではないですが、試行錯誤しつつ作った現在の Itamae レシピは次のとおりです。

<script src="https://gist.github.com/kymmt90/9b7709cf57369aeae70d87f10524c1a1.js"></script>

# ハマった点

ここまでの作業でハマった点をメモしておきます。

## psql を使うときは実行ユーザを変える

コマンド `itamae ssh --vagrant` で Vagrant の VM に対してプロビジョニングするとき、プロビジョニングの実行ユーザは `root` です。一方、PostgreSQL の DB アクセス用コマンド `psql` は、`postgres` というユーザから実行するコマンドとなっています。

ユーザ `postgres` としてコマンドを実行するために、次のように `sudo` を使います。

```sh
$ sudo -u postgres -i sh -c '<実行したいコマンド>'
```

`sudo` にオプション `-u` をつけると、指定したユーザになることができます。オプション `-i` で `/etc/profile` や `.bash_profile` などを読み込み直します。

その後ろの `sh -c '<実行したいコマンド>'` が大事なところです。ここに `-u` で指定したユーザとして実行したいコマンドを書きます。例えば、

```sh
sh -c "psql -c \\"SELECT * FROM pg_user WHERE usename='#{node['kymmt']['dbuser']}'\\""
```

と書くことで、ユーザ `postgres` として、`psql` を叩いて DB 用のユーザ作成を実行しています。

## SELinux を無効にする

SELinux が有効なままだと、nginx 起動時に設定ファイルを読み込めないエラーが出たりします。

Itamae プラグインの [itamae-recipe-plugin-selinux](https://github.com/mizzy/itamae-plugin-recipe-selinux) で SELinux を無効にしました。

```ruby
include_recipe 'selinux::disabled'
```

## レシピ内で利用できるヘルパーメソッドを作る

今回、リソース内の `command` で`sudo` を任意ユーザで実行できるように、ヘルパーメソッドを定義しました。

```ruby
module ResourceHelper
  def sudo(user); "sudo -u #{user} -i"; end
end
```

これを Itamae のリソース内で使えるようにするためには、`Itamae::Resource::Base::EvalContext` にインクルードする必要があります。

```ruby
Itamae::Resource::Base::EvalContext.include(ResourceHelper)
```

この方法は次のエントリを参考にしました。

- [Cry for the Moon | Itamae でレシピとリソースに共通のヘルパメソッドを定義するテクニック](http://mozami.me/2016/07/17/itamae_hack.html)

# 今後の展望

まだ次のような TODO が残っているので、引き続きやっていきます。

- [Best Practice](https://github.com/itamae-kitchen/itamae/wiki/Best-Practice) として紹介されているディレクトリ構成にする
- Rails アプリケーションのデプロイを自動化する
- Let's Encrypt の設定を自動化できるか調査する

Let's Encrypt は `certbot-auto` でインストールすると、TUI で対話式になって自動化しにくいので、ACME プロトコルで証明書を取得できるレシピを作らないといけないのかどうかが気になってます……
