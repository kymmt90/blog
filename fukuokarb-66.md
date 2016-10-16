<!-- Fukuoka.rb #66 に参加した -->

現在、[会社](https://pepabo.com/)の研修で福岡に来ています。福岡には、地域 Ruby コミュニティとして Ruby コミッタの nagachika さんや弊社の udzura さんが主催されている Fukuoka.rb があります。今回、udzura さんに誘っていただき、10/12（水）に福岡・天神のグルーブノーツ社で開催された Fukuoka.rb #66 に参加してきました。

[http://fukuokarb.connpass.com/event/42072/:embed:cite]

弊社の研修メンバ 5 人が参加したので、会場がかつてない人口密度になりました。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">かつてない人口密度になっています <a href="https://twitter.com/hashtag/fukuokarb?src=hash">#fukuokarb</a></p>&mdash; nagachika (@nagachika) <a href="https://twitter.com/nagachika/status/786147074181959680">2016年10月12日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

LT として、morygonzalez さんから「Arel おじさんになって ActiveRecord のクエリを高速化しよう」というお話がありました。Arel は ActiveRecord のなかで様々な DB 用の SQL を生成するライブラリです。ActiveRecord で DB 操作を書いていると、Arel が無駄のあるクエリを生成することもあるらしく、Arel の性質をもとに、SELECT するカラムを絞るなどの方法で、できるだけ最適なクエリを生成するようにするのが大事ということでした。パフォーマンスに関わる部分は、できるだけ内部動作まで理解した対策が必要そうです。

その後、udzura さんの mruby gem ライブコーディングがありました。matsumotory さん作の [mruby-mrbgem-template](https://github.com/matsumoto-r/mruby-mrbgem-template) を使って gem のテンプレートを作成後、mruby や C で実装していくのを見ていました。mruby の C 拡張は Ruby の C 拡張よりとっつきやすいらしいので、試してみたいです。このあたりの記事が参考になりそう。

[http://qiita.com/ore_public/items/b9adf10dfbfae433853e:embed:cite]

発表を聞いたあとはもくもくしていました。僕は最近利用者の方から意見をもらうことが増えた Ruby gem [hatenablog](https://github.com/kymmt90/hatenablog) の修正をしていました。徐々にやっていきます。
