<!-- 『WEB+DB PRESS Vol.108』でスキーマ駆動Web API開発についての特集記事を執筆しました -->

このたび、2018年12月22日に発売された『WEB+DB PRESS Vol.108』の特集1「効率急上昇！スキーマ駆動Web API開発」の企画と執筆に携わりました。id:june29さん、id:ackintoshさん両名との共著です。

[asin:4297103249:detail]

Web APIの仕様を表現するフォーマット（**スキーマ**）を用いたWeb API開発について、基礎的なところから紹介しています。本号はこの特集の他にもPostgreSQLやZOZOのシステムリプレイスなど、非常に興味深い内容が盛りだくさんなので、ご興味のある方はぜひ手にとっていただければと思います。

以上、宣伝でした。

---

以下、裏話的なことを書きます。

## なぜ書いたのか

そもそも現在業務として携わっているWebサービスの開発でOpenAPI（いわゆるSwagger）を利用しています。ある程度わかっている人にOpenAPIについて知ってもらうにはWeb上にある次のようなリソースが役立ちます。

- [RubyKaigi 2017 でどんな発表をしたか - onk.ninja](https://blog.onk.ninja/2017/09/21/my_talk_of_rubykaigi_2017)
  - id:onkさんの記事。個人的にはこの話題の原典だと思っている
- [REST APIのためのコード生成入門](https://gumroad.com/l/swagger_codegen_beginner_jp)
  - id:ackintoshさんが翻訳に参加

一方、新しくチームに入った人やそこまでWeb API開発に詳しくない人に対して、OpenAPIについて「読んどいて！」と言える文献があると、自分自身はもちろん、同じ境遇の他の人にも便利なものになるのではと感じていました。そして、REST APIのスキーマに関して最も有力な選択肢はOpenAPIなので、その説明を含めた文献があるとよさそうだと考えました。

また、これは執筆を始めたあとの話ですが、june29さんと「2018年時点でのWeb API開発のスナップショットみたいな記事だね」という話をして、それを意識して書くようにもしていました。

そういうわけで無事に企画が通り、今回寄稿することになったので、社内外で今後OpenAPIについて知ってもらいたいときは積極的にこの特集を勧めていこうと思っています。

## 補足

今回、OpenAPIに関しては最新版であるバージョン3を前提として、記法や活用方法を解説しました。OpenAPI 3がリリースされたのは2018年6月とまだ新しく、各種ツールのサポートも、Swagger公式やOpenAPI Generator以外の場合は特にですが、まちまちというのが現状です。そういう現状もあって、3章のサーバサイド開発のレスポンスバリデーションに関する部分は、仕組みの解説としてライブラリを使わない素朴な実装方法について書きました。

ここに関しては、今後いろいろなツールでOpenAPI 3がサポートされていくだろうと思うので、とくに主戦場であるRuby/Railsまわりなどは私としても情報発信は継続していきます。また、特集内のコラムで紹介したCommitteeに関しては、@ota42yさんが中心となって対応を進めていただいているので、私自身も試しつつ貢献できる部分はしていきたいと思っています。

<blockquote class="twitter-tweet" data-cards="hidden" data-lang="ja"><p lang="ja" dir="ltr">committeeのOpenAPI3対応したalpha版がそろそろ出ます。(ただしまだ一部機能のみサポート)  &quot; alpha release by ota42y · Pull Request #166 · interagent/committee <a href="https://t.co/A84l0LO3Js">https://t.co/A84l0LO3Js</a></p>&mdash; おおた@10/5にサーバレス本 (@ota42y) <a href="https://twitter.com/ota42y/status/1075283492026470401?ref_src=twsrc%5Etfw">2018年12月19日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

また、スキーマの活用という点で、Protocol Buffersからのサーバ／クライアント生成が特徴的なgRPCをなぜ取り上げていないのか、という点は指摘としてあるかなと思います。ここに関しては、今回の執筆陣がgRPCに関する知見をそれほど持っておらず書かなかったというのが正直なところです。最近は[gRPC-Web](https://github.com/grpc/grpc-web)などブラウザからgRPCのサービスをコールできる技術も出てきているようなので、詳しい知見を持つ方々にぜひ執筆してほしいという気持ちです…！

## おわりに

よろしくお願いします！

<blockquote class="twitter-tweet" data-partner="tweetdeck"><p lang="ja" dir="ltr">でかい (@ 書泉ブックタワー - <a href="https://twitter.com/shosen_bt?ref_src=twsrc%5Etfw">@shosen_bt</a> in 千代田区, 東京都) <a href="https://t.co/KNmDGyfqFJ">https://t.co/KNmDGyfqFJ</a> <a href="https://t.co/ZVfUkJJOfZ">pic.twitter.com/ZVfUkJJOfZ</a></p>&mdash; kymmt90 (@kymmt90) <a href="https://twitter.com/kymmt90/status/1077062421657911296?ref_src=twsrc%5Etfw">December 24, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
