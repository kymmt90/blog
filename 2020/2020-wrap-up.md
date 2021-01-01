<!-- 2020年まとめ -->

2020年は特異な年だったというのもあり、個人的なことも含めて2020年にあったことをまとめた。

# 仕事

## リモートワーク

2020年1月15日に日本での新型コロナウイルス感染者が確認されたあと、国内ではかなり早い段階で所属企業を含むグループ全社でリモートワークが始まった。その開始をなぜかTwitterを通じて知り、「報道で知る」という感覚を初体験した。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">GMO、新型肺炎で国内4000人を在宅勤務に 27日から <a href="https://t.co/IR1tHOldNp">https://t.co/IR1tHOldNp</a></p>&mdash; 日本経済新聞 電子版 (@nikkei) <a href="https://twitter.com/nikkei/status/1221317092680458241?ref_src=twsrc%5Etfw">January 26, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

結局ペパボはリモートワークを原則とする勤務体制に変更された。会社関連の用事で渋谷に行ったのは3回だけだった((荷物の回収、感染拡大が落ち着いていた時期に久々にチームで顔合わせ、インフル予防接種))。

ずっと家にいるので、仕事用の机のまわりの設備を改善した。とはいえ、基本的にMacBook Pro1台だけで作業することにしているので、充電器と椅子とデスクライトを買った程度。

- 充電器: [AnkerのPowerPort I PD](https://www.ankerjapan.com/item/A2056.html)
- 椅子: [オカムラのBaron](https://www.okamura.co.jp/product/seating/baron/)
- デスクライト: [山田照明のZ80NB](http://www.zlight.net/product/LED/Z-80N/)

定額給付金はBaronに充てさせてもらった((14万円弱したので足は出ている))。会社の椅子がBaronだったのでそれに合わせた。シートタイプはクッションにした。

仕事の能率を上げる方法として古典的だがポモドーロテクニックを試していた。

[ポモドーロ・テクニックを2か月間やってみての感想 - kymmt](https://blog.kymmt.com/entry/the-pomodoro-technique)

いったん[原典](http://books.cccmh.co.jp/list/detail/2320/)のとおりに厳密にやっていて、新規に開発しているときなどはハマっている感じがしてよかった。調査業などとはどうしても相性が悪い感じがしている。最近はタスクリストの書き出しとポモドーロの計測だけという緩い運用になっていることが多い。

マンション自体の作りや立地の問題で、自分にとっていまの家はリモートワークに向いていないと感じている。そのわりに家賃がやたらと高く、来年で契約更新になるという事情もあるので、2021年の上期には引越したいと考えている。

## 業務

サービス基盤チーム所属という肩書きで、Eコマースプラットフォーム((https://shop-pro.jp / https://colorme-repeat.jp))のWebアプリケーションレイヤを全般的に改善するという役回りだった。所属しているチームの概要については[hrysdがスライドにまとめてくれている](https://speakerdeck.com/hrysd/upgrading-rails-application-is-hard)。

主にサービスにおける事業者側の玄関口にあたる認証／認可部分のセキュリティ向上や新しいアーキテクチャへの移行に取り組みつつ、Webアプリケーションの細かい改善をやっていた。また、コロナ禍でEコマースの需要が高まったことを背景に、一時的ではあるが久しぶりに新機能をチーム開発したりもした。

15年の歴史を持つサービスの認証／認可の設計改善についてはなかなか進めづらいものだが、今年はセキュリティ向上の作業に抱き合わせることで（？）よりよいアーキテクチャに移行していけそうに見えたので、理想とするアーキテクチャの案を上長や各ロールを担当するエンジニアと共有し、みんなで協力して今年やるべき分については開発を進められたのでよかった。しかし、この分野はとにかく気を使うので大変と感じる。OAuth 2.0の認可サーバの実装だけでも、ライブラリを入れるだけではなく[Security Best Current Practice](https://tools.ietf.org/html/draft-ietf-oauth-security-topics-16)をはじめとするRFCを読んだり情報収集したうえで、適切に実装するのが必須であるということを身を持って感じた。令和の時代に新規にWebアプリケーションを作るなら認証／認可は原則IDaaSに任せるのがいいのだろうなという気持ちになっている。

また、下期はWebアプリケーションを運用し続けると溜まる問題（省みられないエラー通知、古いライブラリのバージョンアップなど）の解決に発生しがちな属人性を減らして、チームや事業部レベルで解決できるように進めかたを考えて、まずはチームで実践したりしていた。ここは道半ばなので引き続き。

# アウトプット

## 記事

個人ブログの記事は14件。だいたい月末になにか書くことがないか考えて書くという感じで、テーマがバラバラだし内容も未来の自分向けが多い。そういえば年初はHaskellを勉強していたけど、すっかり触らなくなってしまった。

[2020-01-01から1年間の記事一覧 - kymmt](https://blog.kymmt.com/archive/2020)

会社のブログにWebアプリケーションのセッション管理に関する記事を書いた。会社の名前を借りてWebに情報発信させてもらえるということもあり、個人ブログよりはよっぽど読まれたようだった。

[SPA+SSR+APIで構成したWebアプリケーションのセッション管理 - ペパボテックブログ](https://tech.pepabo.com/2020/09/23/session-management-for-web-apps-using-spa-ssr-api/)

その他はQiitaにtipsレベルの記事を数本書いたぐらい。

## OSS

自分のOSSにもらったPRを対応したり、業務の関係上[doorkeeper-gem](https://github.com/doorkeeper-gem)のgemをよく読んだり使ったりしていたので、そのあたりで少しだけ貢献した。

- [Add formatted_content method to Entry by satoryu · Pull Request #21 · kymmt90/hatenablog](https://github.com/kymmt90/hatenablog/pull/21)
- [Bump committee to 4.0.0 by kajisha · Pull Request #18 · kymmt90/schema_conformist](https://github.com/kymmt90/schema_conformist/pull/18)
- [Doorkeeper 5.1.2 is missing from rubygems.org · Issue #1446 · doorkeeper-gem/doorkeeper](https://github.com/doorkeeper-gem/doorkeeper/issues/1446)
- [Avoid to use the config alias while supporting Doorkeeper 5.2 by kymmt90 · Pull Request #129 · doorkeeper-gem/doorkeeper-openid\_connect](https://github.com/doorkeeper-gem/doorkeeper-openid_connect/pull/129)

仕事の関係で小さいgemを作成した。

- [pepabo/action_dispatch-disable_x_xss_protection: Disables the X-XSS-Protection header which Action Dispatch sets by default](https://github.com/pepabo/action_dispatch-disable_x_xss_protection/)

総じてOSSをバリバリやる感じではなかった。

# その他

## 読書

79冊読んでいた((漫画を含む。再読した本が計算に入ってなさそうで、実際は80冊は超えていると思う))。

[Yamamoto Kōheiさんの読書記録](https://booklog.jp/users/kymmt90/stats?year=2020)

技術書はOAuth/OIDC関連の本が多め。[Auth屋さん](https://authya.booth.pm/)の本には助けられた。なんとなく量子コンピュータが気になって関連する本を数冊読んだが、手を動かさずに終わっている。

6月ぐらいにKindleでちくま新書のセールをやっていたときに畑違いの分野の本をここぞとばかりに買って読んでいた。また、Kindle Oasisを買って一般書の読書体験はかなり向上した。電子ペーパーのほうが圧倒的に紙に近く読みやすいし、片手でそれなりの画面サイズのデバイスを持って読み進められるのが個人的に体験がよく感じる。

## Emacs

Emacsを使うのをやめて、Visual Studio Codeだけで開発するようになった。また、これまで雑にメモを書いたり一時的に文字列を置きたいときはEmacsの`*scratch*`バッファを使っていたが、いまはSpotlightでTextEdit.appを立ち上げて用を済ませている。

Emacsとの出会いは大学に入った2008年4月((大学の演習室にあったのはLeopardの入ったMac Proで、演習の授業の初回でEmacsが導入された))で、本格的に使い始めたのは研究室に入ってまともにプログラミングをし始めた2011年〜2012年の間だと思う((研究室の支給PCはWindows 7が入っていたので、最初は雰囲気でxyzzyを使っていた。そのあとNTEmacsに移行した))。当時[『Emacs実践入門』](https://gihyo.jp/book/2017/978-4-7741-9235-2)の初版が出たころで、開発環境整備の重要性はこの本から教わったように思う。その後、時代は移り変わり、VS Code主流の世の中でも惰性でEmacsを使っていたが、リモートワーク下での開発作業でVS CodeのLive Shareを使いたい場面があり、そのために自分がボトルネックになるのはよくないので、いい機会と思って移行してしまった。この記事もVS Codeで書いている。

[Awesome Emacs Keymap](https://marketplace.visualstudio.com/items?itemName=tuttieee.emacs-mcx)を使っているので、まだ脱Emacsし切っているとはいえないが、手元のマシンからはEmacsをアンインストールした。

[Try to quit using Emacs for a time · kymmt90/dotfiles@85ca748](https://github.com/kymmt90/dotfiles/commit/85ca748da7bc0a9ff22a0bae7f3583c2f0ddb91a)

## 健康

通勤がなくなったので、朝の散歩と軽い自重トレーニングは毎日やっている。一念発起して、花粉症の治療のために6月ごろからシダキュアを服用しはじめた。月1回通院があるが散歩だと思って通っている。シダキュアはHabitifyで見る限り202日連続服用できていて挫折はしていない。

悪いできごととしては口腔外科系の病気になってしまったので、来年の医療費がどうなるか読めず不安感がある。また、生活環境が変わった影響か息抜きがうまくできておらず、そのわりに精神的に焦るだけで何もできていないという自覚があるので、来年は改善したい。

# 所感

総じて大変な年だった。まだまだやれていないことや知らないことだらけなので来年もがんばりたい。

---
