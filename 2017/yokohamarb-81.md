<!-- Yokohama.rb Monthly Meetup #81に参加した -->

2017-06-10（土）のYokohama.rb Monthly Meetup #81参加メモです。

[https://yokohamarb.doorkeeper.jp/events/60612:embed:cite]

3月の#78も参加していたのにメモを書いていなかったので、久しぶり感あります。

# Rubyレシピブック

レシピ254から256まで。HTTP, SMTP, FTPというプロトコル3連発でした。

## 254: HTTPクライアントをつくる

HTTPクライアントを一からつくるというわけではなく、[open-uri](https://docs.ruby-lang.org/ja/latest/library/open=2duri.html), [net/http](https://docs.ruby-lang.org/ja/latest/library/net=2fhttp.html), [httpclient](https://github.com/nahi/httpclient)を使ってみるというレシピでした。rest-clientというクライアントライブラリがあるという話も聞けました。

[https://github.com/rest-client/rest-client:embed:cite]

あとはlibcurlラッパのtyphoeusとかがありますね。

[https://github.com/typhoeus/typhoeus:embed:cite]

## 255: メールを送信する

[net/stmp](https://docs.ruby-lang.org/ja/latest/library/net=2fsmtp.html)を使って、素のRubyスクリプトでメールを送るというレシピでした。ふだんはAction Mailerばかりなので新鮮。

今回はメールの受信テストに[MailCatcher](https://mailcatcher.me)を使っていましたが、Railsのときは[letter_opener](https://github.com/ryanb/letter_opener)を使ったり、Action Mailerにもプレビューがあるという話をしていました。

- [RailsのAction Mailer Previewsについて | 日々雑記](http://y-yagi.tumblr.com/post/88746017105/rails%E3%81%AEaction-mailer-previews%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6)

## 256: FTPでファイルを送受信する

Ruby, [net/ftp](https://docs.ruby-lang.org/ja/latest/library/net=2fftp.html)というライブラリも標準添付されています。@igrepさんに[Pure-FTPd](https://www.pureftpd.org/project/pure-ftpd)というFTPサーバを立ててデモしてもらいました。

バイナリファイル、テキストファイルの送受信がプロトコルとして存在していて、そのまま `Net::FTP#getbinaryfile` のように対応するメソッドが存在しています。`get` という名前ですが、返り値はなくローカルにファイルを保存するという仕様。

# その他

Rubocopを導入するとき、とっかかりのルールはどうしたらよさそうかという話をしたところ、onkcopの設定を参考にしてみるとよさそうというお話を聞いたので、それを眺めたりしていました。

[https://github.com/onk/onkcop:embed:cite]

あとはこのエントリをもくもく書いたり。

[http://blog.kymmt.com/entry/compose-and-rails-api-with-spring:embed:cite]

----
<br>

次回は2017-07-08（土）です。

[https://yokohamarb.doorkeeper.jp/events/60613:embed:cite]
