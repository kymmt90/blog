<!-- Yokohama.rb Monthly Meetup #76 に参加した -->

2017-01-14（土）の Yokohama.rb Monthly Meetup #76 に参加したので、メモを書きます。1 週間たってしまった。

[https://yokohamarb.doorkeeper.jp/events/54173:embed:cite]

# Ruby レシピブック

今回はレシピ 244 から 247 まで読みました。システム寄りの話題が中心です。

## レシピ 244

[スレッド](https://docs.ruby-lang.org/ja/2.4.0/class/Thread.html)、[ファイバ](https://docs.ruby-lang.org/ja/2.4.0/class/Fiber.html)の扱いかたについてです。

スレッドを使うときに気をつけるべき点は次のようなところでしょう。

- あるスレッドが別のスレッドの変数を操作しないように、`Thread#fork` の引数としてスレッド固有のローカル変数を渡す
- メインスレッドが勝手に終了するのを防ぐため `Thread#join` でスレッドが終了するのを待つ

ファイバは軽量スレッドのようなものです。スレッドは自動で他スレッドに制御が移りますが、ファイバが持つコードを実行するには `Fiber#resume` を実行し、制御を呼び出し元に戻すには `Fiber#yield` を実行する必要があります。`Enumerable#each` など内部イテレータをジェネレータのような外部イテレータに変換するコードとともに紹介されていました。

ちなみに、Ruby 1.9 以降では組み込みの [`Enumerator`](https://docs.ruby-lang.org/ja/2.4.0/class/Enumerator.html) をジェネレータとして使うことができます。

```ruby
sentence =<<EOF
lorem ipsum
hoge fuga fizz bazz
EOF
enumerator = sentence.each_line  # Enumerator を返す
loop { p enumerator.next }
# => "lorem ipsum\n"
# => "hoge fuga fizz bazz\n"

```

また、レシピのサンプルコードで [`Object#__send__`](https://docs.ruby-lang.org/ja/latest/method/Object/i/__send__.html) というメソッドが使われていました。これは、`send` という名前が一般的で再定義されやすいことから定義された `Object#send` の別名ということです。

## レシピ 245

プロセスのフォークについてです。

レシピ内では [`fork`](https://docs.ruby-lang.org/ja/2.4.0/method/Kernel/m/fork.html) して [`exec`](https://docs.ruby-lang.org/ja/2.4.0/method/Kernel/m/exec.html) するサンプルコードが紹介されていました。この用途なら [`Kernel.#spawn`](https://docs.ruby-lang.org/ja/2.4.0/method/Kernel/m/spawn.html) でもよいという話がありました。子プロセスの終了を待つなら [`Process.waitpid2`](https://docs.ruby-lang.org/ja/2.4.0/method/Process/m/waitpid.html) を使う必要があります。

```ruby
pid = spawn('job')
exitpid, status = *Process.waitpid2(pid)  # 'job' が終了するまで待つ
```

## レシピ 246

プロセスがシグナルを受けたときの動作を設定するシグナルハンドラについてです。

有名な `SIGINT` などの他に `SIGUSR1`, `SIGUSR2` というはシグナルがあって、これはユーザ定義用のものだそうです（参照：[シグナル (ソフトウェア) - Wikipedia](https://ja.wikipedia.org/wiki/%E3%82%B7%E3%82%B0%E3%83%8A%E3%83%AB_(%E3%82%BD%E3%83%95%E3%83%88%E3%82%A6%E3%82%A7%E3%82%A2)）。

Pry など REPL 上で `Singal.trap(:USR1) { puts 'USR1' }` などとして、`kill` で `SIGUSR1` を送ると、シグナルハンドラが動作していることが確かめられます。

## レシピ 247

プロセスをデーモン化する方法についてです。

注意点として、デーモンの場合、必ず [`Kernel.#exit!`](https://docs.ruby-lang.org/ja/2.4.0/method/Kernel/m/exit=21.html) で終了するようにします。`exit!` は `ensure` 節など後処理も飛ばしてプロセスを終了します。これを使わないと stdio ライブラリのバッファが 2 回フラッシュされてしまうなどの問題が起きるそうです。

そもそもなぜデーモンなのか？ nohup ではだめなのか？という話に展開して、次のページを皆で見ていました。

- [技術/UNIX/なぜnohupをバックグランドジョブとして起動するのが定番なのか？(擬似端末, Pseudo Terminal, SIGHUP他) - Glamenv-Septzen.net](https://www.glamenv-septzen.net/view/854)

# もくもく

後半はもくもく会でした。僕は [swagger-docs](https://github.com/richhollis/swagger-docs) や [Swagger UI](http://swagger.io/swagger-ui/) を使って、Rails で作った API のドキュメント化を試していました。

# 懇親会

miyohide さん誕生日おめでとうございました。

----

次回は 2017-02-18（土）です。次のリンクから申し込めます。

[https://yokohamarb.doorkeeper.jp/events/55216:embed:cite]
