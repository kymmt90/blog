<!-- Yokohama.rb Monthly Meetup #69 に参加した -->

6/11（日）の Yokohama.rb Monthly Meetup #69 に参加しました。3 回目ぐらいです。

[https://yokohamarb.doorkeeper.jp/events/45055:embed:cite]

今回は初参加の方が 4 人ほどいて、そのなかにはプログラミング始めたての学生の方もいました。行動力！

内容は次のような感じでした。

- レシピブック読書会
- 発表
- 懇親会

# レシピブック読書会

今回はレシピ 230 から 233 まで読みました。以下メモ。

## レシピ 231

`OptionParser#on` で設定できるオプション値の挙動が若干ややこしめでした。
Ruby 2.3.1 で確かめてみたところ、次のような感じでした。

### 省略不可のオプション

- `on('-f', '--format=FMT', ...)`（本に書いてあるパターン）
  - `./foo.rb --format=FMT`, `./foo.rb --format FMT` とすると `FMT` がオプション引数として認識される
  - `./foo.rb -f FMT` とすると `FMT` がオプション引数として認識される

- `on('-f FMT', '--format=FMT', ...)`, `on('-f FMT', '--format FMT', ...)`
  - `on('-f', '--format=FMT')` と同じ

### 省略可のオプション

- `on('-u', '--user=[NAME]', ...)`（本に書いてあるパターン）
  - `./foo.rb --user=NAME` とすると `NAME` がオプション引数として認識される
  - `./foo.rb -u NAME` とするとオプション引数が認識されない
  - `./foo.rb -uNAME` とすると `NAME` がオプション引数として認識される

- `on('-u [NAME]', '--user=[NAME]', ...)`
  - 次のエラーが発生する

```
foo.rb:*:in `<main>': =[NAME]: incompatible argument styles (ArgumentError)
OptionParser::Switch::PlacedArgument, OptionParser::Switch::OptionalArgument
```

- `on('-u', '--user [NAME]', ...)`, `on('-u [NAME]', '--user [NAME]', ...)`
  - `./foo.rb --user=NAME`, `./foo.rb -u NAME`, `./foo.rb --user NAME` すべてで `NAME` がオプション引数が認識される

## レシピ 233

コードのテストを `if __FILE__ == $0` 内に書くという利用法があります。次のような感じ。

```ruby
# foo.rb
class Foo
  def foo(a, b)
    a + b
  end

  if __FILE__ == $0
    require 'minitest/autorun'
    class TestFoo < Minitest::Unit::TestCase
      def test_foo
        assert_equal 6, Foo.new.foo(2, 3)    # テスト結果は NG となる
      end
    end
  end
end
```

これで、別ファイルから `require_relative 'foo'` などとすれば `Foo` が使えますし、`foo.rb` 自体を実行すれば `if` 内の `foo` のテストを実行できます。

# 発表

今回は競馬のデータ解析の話と、個人で作っておられる Rails アプリのコードを読むという企画でした。

競馬のデータは [JRA-VAN](http://jra-van.jp) というところで取得できるそうです（.NET 環境からしかデータが取得できないそうですが）。競馬データ解析でうまくビジネスするためには、実力があるのに人気がない馬を見つけることが求められるそうです。

Rails アプリのコードを読む企画では、AngularJS + Rails (API 用) という構成のアプリについてコードを読んでいきつつ、有識者の方々からコメントが出ていました。以下メモ。

- 順番：Gemfile, config/routes.rb -> app/* -> db/schema.rb
- routes.rb での `only` / `except` の使いわけ
- ABC サイズ（RuboCop でチェックできる）を下げるにはメソッド切り分けがよい
  - 参考：[Abc Metric](http://c2.com/cgi/wiki?AbcMetric)
- `try` より `NoMethodError` を投げてくれる `try!` を使ったほうがよい
  - 参考：[try と try! の使い分け - Qiita](http://qiita.com/kuboon/items/8e4812bbb55c31c235bf)

私も Rails をちょこちょこ触っているので、かなり勉強になりました。

 ----

その後は懇親会で吉田飯店へ。今回は参加者が 10 人以上と多く、懇親会もかなり盛り上がっていました。

他の方から、「gem のコードは Web 上に結構あるが、Rails を使ったコードはあまりないので参考にするのが難しい」というお話を伺いました。そういうこともあって、今回のようなコードを読む企画はよいのだろうなあと思いました。

次回の Yokohama.rb は以下リンクから申し込めます。

[https://yokohamarb.doorkeeper.jp/events/45057:embed:cite]
