<!-- Yokohama.rb Monthly Meetup #74 に参加した -->

2016-11-12（土）の Yokohama.rb Monthly Meetup #74 に参加しました。

[https://yokohamarb.doorkeeper.jp/events/52660:embed:cite]

- 前半は Ruby レシピブック読書会
- 後半は LT

という 7 月以来の流れでした。

# レシピブック

今回はいつもより 30 分短かったこともあって、レシピ 238, 239 だけ読みました。

## レシピ 238

- OS の `/etc` 配下のデータにアクセスできる [etc ライブラリ](https://docs.ruby-lang.org/ja/latest/library/etc.html)
  - [`Etc#getpwnam`](https://docs.ruby-lang.org/ja/latest/method/Etc/m/getpwnam.html)
- 組み込みライブラリの [`Process`](https://docs.ruby-lang.org/ja/latest/class/Process.html) モジュール
  - [`Process#euid`](https://docs.ruby-lang.org/ja/latest/method/Process/m/euid=3d.html), [`Process::UID#change_privilege`](https://docs.ruby-lang.org/ja/latest/method/Process=3a=3aUID/m/change_privilege.html) など

のふたつを使って、プログラムの処理途中に実行ユーザの権限やグループ権限を切り替えたりする方法についてのレシピです。Docker や Foreman のグループを処理途中で使いたいときなどに便利ではという話でした。

スーパーユーザから一般ユーザへとプロセス実行権限を一時的に切り替えるために、**実効 UID** というものを `Process#euid=` を使って書き換えています。一方で、**実 UID**というまた別の ID もあるようで、それらの違いがよくわからなかったので、質問してみました。その場で調査した結果（Wikipedia の[ユーザ識別子](https://ja.wikipedia.org/wiki/ユーザー識別子)）、次の違いがあるとわかりました。

- 実効 UID, 実効 GID（グループ ID）
  - ファイルの作成やアクセスに影響する ID
  - たとえばあるファイルを開く権限があるかチェックするときに使う
- 実 UID, 実 GID
  - シグナル送信に影響する ID
  - たとえば `kill` でプロセス終了できる権限があるかチェックするときに使う

もはや Ruby とはあまり関係ないですが、勉強になりました。

## レシピ 239

Windows レジストリにアクセスするためのライブラリ `win32/registry` についてのレシピです。メモ帳 (notepad.exe) 終了時のウィンドウ位置取得を例にした、レジストリの操作方法についてでした。

Windows ユーザが会場にいないので、完全に読むだけになるかと思いきや、@igrep さんがあらかじめ準備してあった自宅の Windows 環境にリモート接続しレシピを実演してくれました。ありがとうございます！

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">あ、今日のレシピブックはレシピ239まで進みました！次回もWindowsの準備がいるな。。。 <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a></p>&mdash; Yuji Yamamoto: 山本悠滋 (@igrep) <a href="https://twitter.com/igrep/status/797381895914799104">2016年11月12日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

# LT

LT 一本目は、@hamakn さんからリクエストがあったこともあり、僕が先月受けていた[GMO ペパボの第二新卒向け研修](http://pb-recruit.jugem.jp/?eid=31)についてかんたんにご紹介しました。

LT 二本目は、@hamakn さんから Rails の `accepts_nested_attributes_for` の `limit` オプションでハマった話や、DB 設計の悩みについてなどでした。DB 周りの知識大事という話に収束していきました。

# 懇親会

いつも使っている吉田飯店というお店の名前が「吉田**大**飯店」に変わってました…

いかにエンジニアとして満足できる仕事をして成仏するか、みたいな人生観的な話と昨今のゲームの話が展開されていました。

----

次回 2016-12-10（土）の Yokohama.rb は以下リンクから申し込めます。読書会に参加するもよし、もくもくするもよし、他の方と技術トークするもよしで初心者から上級者までフィットするコミュニティだと思いますのでぜひぜひ。

[https://yokohamarb.doorkeeper.jp/events/52661:embed:cite]
