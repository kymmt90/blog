<!-- Yokohama.rb Monthly Meetup #85 に参加した -->

2017-11-11（土）のYokohama.rb Monthly Meetup #85メモです。

[https://yokohamarb.doorkeeper.jp/events/65593:embed:cite]

## Rubyレシピブック

@igrepさんと、第10章の「Webプログラミング」の続きで次のレシピを読みました。

- 265: クッキーを処理する
- 266: セッションを使用する

[cgi](https://docs.ruby-lang.org/ja/2.4.0/library/cgi.html)と[Rack](https://github.com/rack/rack)を使う方法がそれぞれ説明されていましたが、`rackup` でWebサーバがシュッと立ち上がるというのもあってRackを使うのが圧倒的に楽な感じです。

## るびま移行

@miyohideさんから、[るびま](http://magazine.rubyist.net)をHikiからJekyllにリプレースするにあたって、URLの構成が変わるのでしばらくリダイレクトしたいといったような点について相談会がありました。AWSのS3に備わっているリダイレクト機能が使えるのではという解決案が出ていました。

- [S3 バケットによりホストされたウェブサイトへのリクエストを別のホストにリダイレクトする方法 - Amazon Simple Storage Service](http://docs.aws.amazon.com/ja_jp/AmazonS3/latest/user-guide/redirect-website-requests.html)

## OpenAPI

OpenAPI (Swagger) について、それ自体がどういうものかという点と、OpenAPIを使ったAPI開発の実際について紹介しました。説明に使ったのは次のあたりです。

- [EC新サービスにおけるスキーマファースト開発 / Schema First Development in the New EC Service // Speaker Deck](https://speakerdeck.com/kymmt90/schema-first-development-in-the-new-ec-service)
- [kymmt90/schema_conformist: An automatic JSON response validator for testing in Rails](https://github.com/kymmt90/schema_conformist)

その後、リクエストバリデーションやJSON Schemaの仕様完璧には使えない問題などについてなんやかんや話したりしました。

## Banken

自己紹介のときの雑談で[Pundit](https://github.com/elabs/pundit)を使っているという話が出た流れで、@hamaknさんからPunditと同種の認可ライブラリであるBankenの実例について紹介がありました。

[https://github.com/kyuden/banken:embed:cite]

Punditとの差別化ポイントとして、認可ポリシーを表現するクラス（PunditではPolicy, BankenではLoyaltyと呼ぶ）をモデルに対応づけるPunditとは異なり、コントローラと対応づける点があるそうです。そちらのほうが、アプリが複雑になるときに管理が楽になるようです。詳しくは次を読んでみてください。

- [The difference between Banken and Pundit · kyuden/banken Wiki](https://github.com/kyuden/banken/wiki/The-difference-between-Banken-and-Pundit)

----
<br>

次回は2017-12-09です。

[https://yokohamarb.doorkeeper.jp/events/66387:embed:cite]
