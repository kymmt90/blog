<!-- Yokohama.rb Monthly Meetup #82に参加した -->

2017-07-08（土）のYokohama.rb Monthly Meetup #82参加メモです。

[https://yokohamarb.doorkeeper.jp/events/60613:embed:cite]

# Rubyレシピブック

レシピ257から260まででした((258「LDAPで情報を得る」は飛ばしました))。259, 260についてメモ。

## 259: リモートホストが稼働していることを確認する

リモートホストが動いているかを確認するためにTCP接続を試みるメソッドについてのレシピです。

本文中では、TCPの7番ポートで受け付けるechoサービスに対して、TCPで接続を試みることでリモートホストが動いているかを確認しています。とはいえ、実際にやってみると、TCP7番を開けているサーバはほとんどなさそうでした。

コード例では `timeout` ライブラリによって導入される `Kernel#timeout` を使っています。このメソッドはRuby2.3からdeprecatedになっており、使うと次のメッセージが表示されます。実際には `Timeout#timeout` へのエイリアスになっているようです((ref: https://github.com/nahi/httpclient/issues/289))。

```
Object#timeout is deprecated, use Timeout.timeout instead.
```

メッセージのとおり、現在は明示的にモジュール関数 `Timeout.#timeout` を使うのが望ましいでしょう。

```ruby
Timeout.timeout do
  TCPSocket.open(host, service) do
    # pass
  end
end
```

## 260: 別プロセスのRubyオブジェクトにアクセスする

dRubyを使った分散オブジェクトの操作についてのレシピです。dRubyを実際に動かしてみたのは初めてだったのでおもしろかったです。次のようなことを話していました。

- リモートのオブジェクトに対して呼び出したメソッドはサーバ側で実行される
  - クライアント／サーバ間ではMarshalを使ってやり取りしているが、ブロック内のコード（要はProc）はMarshalでシリアライズできないので、クライアント側で実行される
- 2,3文字ぐらいの文字列を1000万要素ぐらい入れた配列をクライアントからサーバに送ろうとすると、なぜかクライアントが死ぬ…
- dRubyを使ってカードゲームのUNOを作ると楽しそう

# その他

以前書いた「DockerでRailsの開発環境を作る」ブログ記事を@miyohideさんが読んでいたということで、あらためて何をやったか紹介しました。

[http://blog.kymmt.com/entry/compose-and-rails-api-with-spring:embed:cite]

次のようなコメントをもらいました。

- たとえばDBへの接続のためにIPアドレスは必要？
  - `docker-compose.yml` でつけたサービス名をそのまま使える
- 本番環境はコンテナではない？
  - 今は開発環境だけ
    - エンジニアとデザイナの環境を統一して、うまく動かないときの原因切り分けを楽にしたかったのが最初のモチベーションのため
- ホストからコンテナへのファイルコピーが遅くなってくるのでrsyncを使っている
  - 現状そこをネックに感じるレベルには達してなかった
- コンテナが溜まってくるのはどうしてる？
  - コマンド実行は `--rm` をつけてやってもらう
  - こんな方法もあるそうです

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">docker system prune<br>で掃除できるのか。 <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a></p>&mdash; ゆーいち@雑魚豪鬼 (@u1tnk) <a href="https://twitter.com/u1tnk/status/883638198726873089">2017年7月8日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

また、@takeshyさんからDDD（ドメイン駆動設計）に基づいてRailsを使ったAPIサーバを作り直した事例について共有していただきました。

[http://qiita.com/takeshy/items/7fd1d0dfd3490a471b20:embed:cite]

次のようなお話が聞けました。

- ドメイン層は純粋なドメインロジックのコードだけになるのでわかりやすい
- リポジトリ層はActive Recordを使わずに生SQLを書くことが多い
- いかにimmutableな値オブジェクトに寄せるかがキモ
- ルートエンティティ経由でドメインロジックを呼び出す
- コントローラ層は `params` の処理ぐらいだけやってアプリケーション層に委譲
- アプリケーション層はコントローラ層のアクションと一対一対応している
- ドメインの処理を終わった時などにイベントを飛ばして、それを監視しているサブシステムが通知処理などを実行する
  - メインのドメインに通知処理などが入らない
  - ユーザ作成など、実行した処理がすべてイベントとして記録されるので、ログ活用やデバッグが楽になる

# 懇親会

次の結論に達した気がします。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">特定のパラダイム（言語、フレームワーク）一本足打法は危険なので知見を広めましょう、が今日のまとめだろうか？ <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a></p>&mdash; katsunori kawaguchi (@hamakn) <a href="https://twitter.com/hamakn/status/883684765664034816">2017年7月8日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

----
<br>

次回はまだ未定のようですが、普段どおりであれば8月の第2土曜日に開催されると思います。
