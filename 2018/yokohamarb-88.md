<!-- Yokohama.rb Monthly Meetup #88 に参加した -->

2018-02-17（月）のYokohama.rb Monthly Meetup #88 参加メモです。

[https://yokohamarb.doorkeeper.jp/events/69127:embed:cite]

## Rubyレシピブック

気づいたら第11章「オブジェクトとメタプログラミング」に入っていました。

- 273: オブジェクトが同じか調べる
- 274: オブジェクトを複製する
- 275: オブジェクトのクラスを調べる
- 276: オブジェクトを文字列に変換する
- 277: オブジェクトを数値に変換する

とくに盛り上がったのは274, 277あたりでしょうか。274では`Object#dup`や`Object#clone`といったメソッドがshallow copyであるという話が紹介されていて、`deep_copy`のようなものはあったっけというところから、Active Supportの`deep_dup`の実装を見ていました。ArrayやHashに対しては再帰的に`deep_dup`を呼んでコピーしています。

[rails/deep_dup.rb at v5.1.5 · rails/rails](https://github.com/rails/rails/blob/v5.1.5/activesupport/lib/active_support/core_ext/object/deep_dup.rb)

277では`to_i`が数値として有効でない文字列や`nil`を0に変換するのに対して、[`Kernel.#Integer`](https://docs.ruby-lang.org/ja/latest/method/Kernel/m/Integer.html)は数値として有効でないデータに対しては例外を投げるという厳密なメソッドなので、後者を使うほうが安全な場面は結構あるのではという話をしていました。

## Slack

Yokohama.rbのSlack workspaceができました。@hamaknさんに[Slackin](https://github.com/rauchg/slackin)をセットアップしていただきました。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">できた？ <a href="https://t.co/zJbLU3ExVn">https://t.co/zJbLU3ExVn</a> <a href="https://twitter.com/hashtag/yokohamarb?src=hash&amp;ref_src=twsrc%5Etfw">#yokohamarb</a></p>&mdash; kawag_hamakn (@hamakn) <a href="https://twitter.com/hamakn/status/964805052337553408?ref_src=twsrc%5Etfw">2018年2月17日</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">slackinの作り方2018年版書いた、必要なのがslack legacy api tokenな点に注意... / slackinの作り方 2018 (to heroku) <a href="https://t.co/jpnasYPTxw">https://t.co/jpnasYPTxw</a> <a href="https://twitter.com/hashtag/yokohamarb?src=hash&amp;ref_src=twsrc%5Etfw">#yokohamarb</a></p>&mdash; kawag_hamakn (@hamakn) <a href="https://twitter.com/hamakn/status/964807884520415233?ref_src=twsrc%5Etfw">2018年2月17日</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

----
<br>

次回は2018-03-17です。

[https://yokohamarb.doorkeeper.jp/events/70949:embed:cite]
