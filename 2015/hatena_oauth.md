<!-- Ruby ではてな OAuth のアクセストークンを取得する -->

# はじめに

はてなのサービスの API を自作のアプリケーションなどから叩くためには、OAuth というプロトコルを通じて、そのアプリケーションに適切な認可を与える必要があります。

最近 Ruby を触り始め、Ruby ではてなブログの API を叩きたくなりました。そこで、OAuth における**アクセストークン**を取得する必要がありました。今回はその方法を説明します。

# OAuth 概要

OAuth は、自作アプリケーションなどからユーザの情報を参照／操作できる権限を Web サービスが与える（**認可**）ために使われるプロトコルです。以下のページに、利点や OAuth 1.0a のプロトコルの具体的な手順が非常にわかりやすくまとまっています。詳細はこちらを参考にしてください。

- [OAuthプロトコルの中身をざっくり解説してみるよ - ( ꒪⌓꒪) ゆるよろ日記](http://yuroyoro.hatenablog.com/entry/20100506/1273137673)

世間で利用されている OAuth のバージョンは 1.0a か 2.0 です。OAuth 2.0 は 1.0a と比較して手順か簡単になっているようで、Facebook など、2.0 に対応しているサービスも存在します。一方、はてなが対応しているのは 1.0a のみです。ですので、**今回は OAuth 1.0a を前提として話を進めます**。

# はてな OAuth のアクセストークン取得

今回は Ruby の CLI プログラムで、はてな OAuth のアクセストークンを得ます。

## Gem のインストール

Ruby で OAuth を利用するための Gem が存在します。

- [oauth-xx/oauth-ruby](https://github.com/oauth-xx/oauth-ruby)

これを利用するために、以下のコマンドを実行します。

    $ gem install oauth

## コンシューマキーの取得

はてなの開発者向けページから作成するアプリケーションのためにアプリケーション登録を実施し、コンシューマキー (consumer key, consumer secret) を得ます。コンシューマキーは BASE64 エンコードされた文字列です。アプリケーション登録の詳細は以下のドキュメントを参考にしてください。

- [Consumer key を取得して OAuth 開発をはじめよう - Hatena Developer Center](http://developer.hatena.ne.jp/ja/documents/auth/apis/oauth/consumer)

登録したアプリケーションの情報確認ページからコンシューマキーが確認できます。

## Ruby からのアクセストークンの取得

アクセストークンを得るために、まずは以下のコードのようにコンシューマのオブジェクトを作成します。

```ruby
SITE_URI          = 'https://www.hatena.com'
REQUEST_TOKEN_URI = '/oauth/initiate?scope=read_public%2Cread_private%2Cwrite_public%2Cwrite_private'
ACCESS_TOKEN_URI  = '/oauth/token'

consumer = OAuth::Consumer.new(consumer_key,
                               consumer_secret,
                               site: SITE_URI,
                               request_token_url: REQUEST_TOKEN_URI,
                               access_token_url: ACCESS_TOKEN_URI
                               oauth_callback: 'oob')
```

`OAuth::Consumer.new` の引数を説明していきます。

`consumer_key` と `consumer_secret` は、はてなの登録アプリケーション情報確認ページから確認できる consumer key と consumer secret の文字列です。

`site` はリクエストを投げる先の URI を指定します。

`request_token_url` はリクエストトークンの送信先 URI を指定します。ここで **URI クエリパラメータ `scope` に認可してもらう操作の種類を指定している**ことに注意してください。今回は、`read_public%2Cread_private%2Cwrite_public%2Cwrite_private`となっており、公開／非公開すべてのコンテンツに対して読み込み／書き込みを認可してもらうように設定しています。ちなみに、`%2C` はカンマをパーセントエンコーディングした表現です。scope については以下のページを参考にしてください。

- [はてな OAuth scope (許可操作) 一覧 - Hatena Developer Center](http://developer.hatena.ne.jp/ja/documents/auth/apis/oauth/scopes)

`access_token_url` はアクセストークンを取得する際にリクエストを送る URI を指定します。

`oauth_callback` は、後ほど説明するリクエストトークン取得時に、ブラウザからアプリケーションに対する認可するボタン押下後に遷移するページの URI （一般にはアプリケーションのページ）を指定します。遷移時は URI クエリパラメータに `oauth_verifier` というデータが付与されます。

ところが、今回は `oob` という文字列が指定されています。これは、"out-of-band" の略で、ここでは OAuth の標準プロトコルから外れることを表すようです。どういうことかというと、今回は Web アプリケーションではなく、デスクトップアプリケーションからのアクセストークン取得なので、ユーザ認可後 `oauth_verifier` を表示する画面に遷移する、ということを表します。ユーザは、手間になりますが `oauth_verifier` をデスクトップアプリケーションに入力することでアプリケーションを認可します。詳細は後述します。

次に、以下のコードのように認可用 URI を取得します。

```ruby
request_token = consumer.get_request_token
puts "Visit this website and get the PIN: #{request_token.authorize_url}"
```

必要な情報を設定した `consumer` から以上のように request_token オブジェクトを取得することができます。`request_token.authorize_url` で取得できる URI の Web ページにアクセスすると以下のようなページが表示されます。

[f:id:kymmt90:20150922131415p:plain]

ここで「許可する」を押下すると、以下のような文字列が表示されます。これが verifier です。`oauth_callbak` に `oob` を設定したのでこうなります。

[f:id:kymmt90:20150922131422p:plain]

この verifier をなんらかの形でアプリケーションに入力します。いま、`oauth_verifier` に verifier を保存したとして、以下のコードのようにアクセストークンを取得します。

```ruby
consumer.options.delete(:oauth_callback)
access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)
puts "Access token: #{access_token.token}"
puts "Access token secret: #{access_token.secret}"
```

最初の行で、`consumer` の持つオプションから `oauth_callback` を削除しています。これはなぜかというと、はてなの仕様だと思いますが、アクセストークンリクエストのヘッダに `oauth_callback` が含まれたままだと、`parameter_rejected` というエラーメッセージが返り、アクセストークン取得に失敗するためです。

2 行目では与えたパラメータを元にアクセストークン取得を実行しています。3, 4 行目では、結果として得られたアクセストークンオブジェクトが持つ token と secret を標準出力に表示しています。

# おわりに

以上の方法で、CLI プログラムから、はてな OAuth のアクセストークンを取得することができました。このアクセストークンを利用すれば、認可された操作の範囲内で、はてなの各種サービスの API を叩くことができます。

以下がはてな OAuth のアクセストークンを取得するための最小限のコードです。エラー処理などは入っていません。

<script src="https://gist.github.com/kymmt90/4372f65087e93a284b5b.js"></script>

# 参考資料

- [OAuthプロトコルの中身をざっくり解説してみるよ - ( ꒪⌓꒪) ゆるよろ日記](http://yuroyoro.hatenablog.com/entry/20100506/1273137673)

OAuth の概要、プロトコルの手順などがわかりやすくまとめられています。

- [Documentation for oauth-xx/oauth-ruby (master)](http://www.rubydoc.info/github/oauth-xx/oauth-ruby/master/index)

OAuth Gem の API リファレンスです。

- [JavaではてなAPIのOAuth](http://www.takaiwa.net/2013/09/javaapioauth.html)

リクエストトークン URI にクエリパラメータとして scope を指定している部分を参考にしました。
