<!-- bookmeter_scraper 0.1.2 -->

bookmeter_scraper を 0.1.2 にアップデートしました。

[https://github.com/kymmt90/bookmeter_scraper:embed:cite]

# bookmeter_scraper とは

以下の記事を参照してください。

[http://kymmt90.hatenablog.com/entry/bookmeter_scraper:embed:cite]

# 追加機能

追加した機能は以下の二つです。

- ブロック内でログイン情報設定
-  取得できる情報に書籍とユーザの URI を追加

それぞれについて説明します。説明のサンプルコードでは、すでに `require 'bookmeter_scraper'` しているものとします。

## ブロック内でログイン情報設定

以下のように `Bookmeter.log_in` へ以下のようにブロックを渡すことで、ログイン処理を実行できます。

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in do |configuration|
  configuration.mail     = 'example@example.com'
  configuration.password = 'password'
end
bookmeter.logged_in?    # true
```

インスタンスメソッド版の `Bookmeter#log_in` でも、同じようにログイン可能です。

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
bookmeter.log_in do |configuration|
  configuration.mail     = 'example@example.com'
  configuration.password = 'password'
end
```

## 取得できる情報に書籍とユーザの URI を追加

書籍情報取得時に以下の情報を新たに取得できます。

- 読書メーター内の書籍ページの URI `uri`
- 書籍の表紙画像 URI `image_uri`

```ruby
# ログイン済みとする
books = bookmeter.reading_books
books[0].name        # "こころ (集英社文庫)"
books[0].uri         # "http://bookmeter.com/b/4087520099"
books[0].image_uri   # "http://ecx.images-amazon.com/images/I/51v9EsqegjL._SX230_.jpg"
```
また、お気に入り・お気に入られユーザ取得時に以下の情報を新たに取得できます。

- 読書メーター内のユーザページの URI `uri`

```ruby
# ログイン済みとする
followers = bookmeter.followers
followers[0].name   # "赤星琢哉"
followers[0].uri    # "http://bookmeter.com/u/1"
```

# 今後の展望

自分が使うために欲しい機能はおおかた実装してしまった感があります。

メンテナンス用にリファクタリング（必要であればテスト追加）、YARD 用コメント追加などはやっておきたいです。以下のようなサービスでメトリクスを測って、改善の参考にするのもよさそうだと考えています。

- [Coveralls](https://coveralls.io)
- [Code Climate](https://codeclimate.com)
