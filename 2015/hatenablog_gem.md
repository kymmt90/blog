<!-- はてなブログ API 用の gem を書いた -->

# はじめに

はてなブログの AtomPub API 用の Ruby gem が意外にも存在しなかったので書きました。

- [kymmt90/hatenablog](https://github.com/kymmt90/hatenablog)
- [hatenablog | RubyGems.org | your community gem host](https://rubygems.org/gems/hatenablog/versions/0.2.0)

# 概要

Ruby スクリプトから、はてなブログのエントリ取得やブログへの投稿ができるようになります。

```ruby
require 'hatenablog'

# デフォルトでは 'conf.yml' から OAuth 設定を読み込む
Hatenablog::Client.create do |blog|
  # 最新 7 件のエントリの内容を出力する
  blog.entries.each do |entry|
    puts entry.content
  end

  # 新しいエントリを投稿する
  posted_entry = blog.post_entry('Entry Title',
                                 'This is entry contents', # Markdown 形式
								 ['Test', 'Programming'])  # カテゴリ

  # 既存エントリを更新する
  updated_entry = blog.update_entry(posted_entry.id,
                                    'Revised Entry Title',
							        posted_entry.content,
							        posted_entry.categories)

  # 既存エントリを削除する
  blog.delete_entry(updated_entry.id)
end
```

# 導入方法

## gem の導入

以下のコマンドで導入できます。

    $ gem install hatenablog

Bundler を使っているのであれば、Gemfile に `hatenablog` を追記してから、`bundle` コマンドを実行してください。

    $ vi Gemfile
    gem 'hatenablog'
	$ bundle

## OAuth の設定

はてなブログの API を叩くには、OAuth のコンシューマキーとアクセストークンを取得する必要があります。ここの手順は別のエントリ（[Ruby ではてな OAuth のアクセストークンを取得する](http://kymmt90.hatenablog.com/entry/hatena_oauth)）も参考にしてください。

まず、コンシューマキーを取得します。[はてなの開発者向けページ](http://developer.hatena.ne.jp/)からアプリケーション登録を実行し、コンシューマキーを取得してください。

次にアクセストークンを取得します。gem に同梱しているコマンド `get_access_token` を以下の通り実行してください。

    $ get_access_token <コンシューマキー> <コンシューマシークレット>

すると、以下のように URL が表示されます。この URL にアクセスして、PIN を取得し、以下の通り入力してください。

	Visit this website and get the PIN: https://www.hatena.com/oauth/authorize?oauth_token=XXXXXXXXXXXXXXXXXXXX
	Enter the PIN: <ここに PIN を入力する> [Enter]

これで、アクセストークンとアクセストークンシークレットを取得できます。

	Access token: <アクセストークン>
	Access token secret: <アクセストークンシークレット>

以上の手順で取得したキーとトークンを設定ファイルに記述します。デフォルトの設定ファイル名は `conf.yml` です。この名前にしておけば、スクリプト内で設定ファイル名を指定せずとも、設定を利用できます。設定ファイルの形式は以下の通りです。

```yml
consumer_key: <コンシューマキー>
consumer_secret: <コンシューマシークレット>
access_token: <アクセストークン>
access_token_secret: <アクセストークンシークレット>
user_id: <ユーザ ID>
blog_id: <はてなブログ ID>
```

はてなブログ ID はブログのドメイン部分です。例えば、このブログであれば `kymmt90.hatenablog.com` です。

# おわりに

はてなブログへのアクセスをサポートする hatenablog gem を書きました。

なんとか gem を公開できました。つまづいた部分もあったので、そちらのネタでエントリを書くかもしれません。
