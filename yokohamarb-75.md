<!-- Yokohama.rb Monthly Meetup #75 に参加した -->

2016-12-10（土）の Yokohama.rb Monthly Meetup #75 に参加しました。

[https://yokohamarb.doorkeeper.jp/events/52661:embed:cite]

次の流れでした。

- 前半は Ruby レシピブック読書会
- 後半は LT

今回は、参加者の @Nabetani さんがすでにメモを書いてくださっています。被らない範囲で僕もメモしておきます。

[http://qiita.com/Nabetani/items/1345fa4ac99f75e2e78b:embed:cite]

# レシピブック

今回はレシピ 240 から 243 まで読みました。おもにシステム寄りの Ruby プログラミングについてでした。

## レシピ 240

システムのダイナミックリンクライブラリを Ruby から呼ぶためのレシピです。

システムライブラリを呼ぶためのライブラリとして dl が紹介されていますが、これは Ruby 2.0 以降では deprecated になっており、2.2 以降では削除されています。かわりに [fiddle](https://docs.ruby-lang.org/ja/latest/library/fiddle.html) を使うとよさそうです。

また、macOS 環境では libc の代わりに libSystem.B.dylib を使う必要があります。

[http://stackoverflow.com/questions/6240639/where-is-the-standard-c-library-on-mac-os-x:embed:cite]

たとえば、次のような感じで標準 C ライブラリの関数としておなじみの `strlen` が呼べます。

```ruby
require 'fiddle/import'
module LibSystem
  extend Fiddle::Importer
  dlload 'libSystem.B.dylib'
  extern 'int strlen(char*)'
end
p LibSystem.strlen('abc')  #=> 3
```

## レシピ 242

Ruby 付属のベンチマークライブラリである [`benchmark`](https://docs.ruby-lang.org/ja/latest/library/benchmark.html) についてです。

@igrep さんからベンチマークにより便利な `benchmark-ips` を紹介してもらいました。与えたブロックの 1 秒あたりの繰り返し回数 (iteration per second: **ips**) を測定する gem です。評価値が大きいほど評価がよいので、直感的という話などをしていました。

[https://github.com/evanphx/benchmark-ips:embed:cite]

軽く使いたいなら [`Benchmark#measure`](https://docs.ruby-lang.org/ja/latest/class/Benchmark.html#M_MEASURE) を使っておくと楽そうです。次のように書けます。

```ruby
require 'benchmark'
puts Benchmark.measure { 'a' * 1_000_000 }
```

## レシピ 243

シェルのコマンドを Ruby から起動するためのレシピです。

@Nabetani さんも書いておられますが、`Kernel.#open` の引数に `|` （パイプ）をつけて `| df -k` のように文字列を渡すと、[`IO.popen`](https://docs.ruby-lang.org/ja/latest/method/IO/s/popen.html) と同じ動きになることにびっくりしました。つまり、任意のコマンドを実行できるということです。この仕様については、次のドキュメントの最初にも

> ファイル名 file が `|' で始まる時には続く文字列をコマンドとして起動し、 コマンドの標準入出力に対してパイプラインを生成します

と明記してあります。

- [module function Kernel.#open (Ruby 2.3.0)](https://docs.ruby-lang.org/ja/latest/method/Kernel/m/open.html)

さらに、これは macOS でも Windows でも実行できることを、前回に引き続き @igrep さんに Windows 環境で実験してもらいました！

`File.open` にはこのような仕様がないので、ファイル操作にはこちらを使っておいたほうが、万一のコマンドインジェクションは防げるので安心ということだそうです。

# LT

LT 一本目は、先月と話がかなり被るのですが、僕が 10 月に受けていた GMO ペパボの第二新卒向け研修「ペパボカレッジ」について、[社のテックブログに書いたエントリ](http://tech.pepabo.com/2016/12/08/pepabo-college-1st/)をもとにご紹介しました。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">ペパボさんよく人を育ててるんだなぁ <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a></p>&mdash; Yuji Yamamoto: 山本悠滋 (@igrep) <a href="https://twitter.com/igrep/status/807536957311983616">2016年12月10日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-cards="hidden" data-lang="ja"><p lang="ja" dir="ltr">あらためてペパカレについて紹介しました <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a> <a href="https://t.co/tiXsFpI7Ry">https://t.co/tiXsFpI7Ry</a></p>&mdash; ky (@kymmt90) <a href="https://twitter.com/kymmt90/status/807537471130988544">2016年12月10日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">ペパボさんが第二新卒を大事に教育してる <a href="https://t.co/XtGcyDp0VQ">https://t.co/XtGcyDp0VQ</a></p>&mdash; ゆーいち@ヒョーバル (@u1tnk) <a href="https://twitter.com/u1tnk/status/807538750196592640">2016年12月10日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

LT 二本目は、@ryonext さんから、先日の Re:Invent で発表された AWS のサービス群について紹介がありました。AWS は VPS から人工知能まで幅広いですね……。

# 懇親会

もう 12 月なので、忘年会と銘打たれていた気がします。来年もよろしくお願いします！！１

----

次回は 2017-01-14（土）です。次のリンクから申し込めます。ぜひぜひ。

[https://yokohamarb.doorkeeper.jp/events/54173:embed:cite]
