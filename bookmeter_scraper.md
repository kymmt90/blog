<!-- 読書メータースクレイピング用の gem を書いた -->

[読書メーター](http://bookmeter.com)は読書記録をつけたり本のレビューを書いたりできる SNS 風味の Web サービスです。

今回、読書メーターの情報をスクレイピングして Ruby で扱えるようにするための gem を書きました。現状 v0.1.1 です。

- [kymmt90/bookmeter_scraper: A scraping library for Bookmeter (読書メーター)](https://github.com/kymmt90/bookmeter_scraper)
- [bookmeter_scraper | RubyGems.org | your community gem host](https://rubygems.org/gems/bookmeter_scraper)

# 概要

Ruby で読書メーターのデータを取得できます。

```ruby
# デフォルトでは 'config.yml' からメールアドレスとパスワードを読み込む
bookmeter = BookmeterScraper::Bookmeter.log_in
# bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'your_password') でも OK

books = bookmeter.read_books    # ログインユーザの「読んだ本」取得
books[0].name          # 書名
books[0].author        # 著者
books[0].read_dates    # 読了日の配列（初読了日と再読日）

# 2016年3月に「読んだ本」に限定して取得可能
bookmeter.read_books(2016, 3)

# それぞれログインユーザの「読んでる本」「積読本」「読みたい本」を取得
bookmeter.reading_books
bookmeter.tsundoku
bookmeter.wish_list
```

上記以外にも、ユーザプロフィールなどを取得できます。使いかたの詳細については以下を読んでください。

- [bookmeter_scraper/README.ja.md at master · kymmt90/bookmeter_scraper](https://github.com/kymmt90/bookmeter_scraper/blob/master/README.ja.md)

# 書いた動機

長いことサービスを使っていると、いろいろとログがたまってきます。すると、例えば、ローカルにデータをエクスポートしたり、過去の各月にどんな本を読んでいたかの調査など、過去の読書に関するデータを自動で処理したくなってきます。

こういうときに Web API が用意されていて、それを通じて各種データのやりとりができるとよいと思うのですが、残念ながら読書メーターには Web API が存在しません。そのため、読書メーターのデータを取得しようとすると、スクレイピングが必要です。しかし、スクレイピングで細かいデータを取ろうとすると、XPath などを使って、HTML から必要な部分をがんばって抽出する必要があり、若干面倒です。

というわけで、スクレイピング周りの処理は隠蔽しつつ、再利用可能にするために、簡単なメソッド呼び出しで読書メーターから情報を取得できるような gem を書きました。

# 導入方法

## gem の導入

以下のコマンドで導入できます。

```sh
$ gem install bookmeter_scraper
```

Bundler を使っているのであれば、Gemfile に `bookmeeter_scraper` を追記してから、`bundle` を実行してください。

## ログイン情報の入力

ログイン情報の入力方法は 2 通りあります。

1. `Bookmeter.log_in`, `Bookmeter#log_in` に引数として渡す
2. `config.yml` に記述する

### 1. 引数として渡す

以下のように `Bookmeter.log_in` へメールアドレスとパスワードを引数として渡すことで、ログインできます。

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'password')
bookmeter.logged_in?    # true
```

`Bookmeter#log_in` でもログイン可能です。

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
bookmeter.log_in('example@example.com', 'password')
```

### 2. `config.yml` へ記述しておく

まず、以下のように YAML ファイル `config.yml` を記述し、実行する Ruby スクリプトと同じディレクトリに置きます。

```yml
mail: example@example.com
password: your_password
```

次に、引数なしで `Bookmeter.log_in` または `Bookmeter#log_in` を呼ぶと、`config.yml` からログイン情報を読みとり、ログインできます。

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in
bookmeter.logged_in?    # true
```

# 注意

**過度なスクレイピングはサービスに負担をかけるので**、常識の範囲内での実行をお願いします。読書メーターのサーバーへ故意に著しい負荷をかける行為は、利用規約の第 9 条で禁止されています。

- [利用規約 - 読書メーター](http://bookmeter.com/terms.php)

# おわりに

[読書メーターのスクレイピングに rubyXL, parallel が便利だった - Qiita](http://qiita.com/HiroshiTakagi/items/eecedae016e9e211fe5a) のように、これまでの読書記録が残る読書メーターのデータを処理したいというニーズはあるようです。この gem でも、そのニーズに若干は応えられるかと思います。

また気が向いたら拡張していきたいと思います。
