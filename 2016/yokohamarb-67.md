<!-- Yokohama.rb Monthly Meetup #67 -->

4/16（土）の Yokohama.rb Monthly Meetup #67 に参加しました。

[https://yokohamarb.doorkeeper.jp/events/39315:embed:cite]

『Ruby レシピブック第 3 版』の読書会はレシピ 225 から 229 まで。「日付と時刻」の章が終わりました。おめでとうございます！次の章は「システムとプロセス」です。

[https://twitter.com/igrep/status/721268563860787200:embed]

メモっときます。

<hr>

## 225: 年度を求める

`Date#<<`, `Date#>>` 子は月単位でずらした日付を得られます。

```ruby
date = Date.new(2016, 4, 16)
date << 3    # 2016-01-16
```

これを使って、日付から年度を求められるという話です。

なお、現場では今年のプリキュアが何作品目かを調べる用途が見出されていました。

## 229: コマンドにした Ruby スクリプトを一時的にオプション付きで実行する

ふつうの UNIX 環境であれば、Ruby スクリプト（例えば `foo.rb`）の先頭に次の 1 行

```ruby
#!/usr/bin/env ruby
```

を書いて `chmod +x` しておけばコマンドとして実行できます。

```sh
$ ./foo.rb
```

このコマンドを Ruby 用のオプション付きで実行するには、環境変数 `RUBYOPT` にオプションを設定すれば OK です。

```sh
$ env RUBYOPT=-d foo.rb    # デバッグフラグ ON で Ruby スクリプトをコマンドとして実行
```

<hr>

後半は、switch_point を使った DB 負荷分散の話や stateful_enum, 雑誌への記事執筆の裏話など、いろいろ聞いてました。

懇親会は話題がなぜかレガシー技術についての話に収束。あとは、なんかいろいろと話聞きに行こうかなと思ったり。

次回の Yokohama.rb は以下のリンクから申し込めます。

[https://yokohamarb.doorkeeper.jp/events/41051:embed:cite]
