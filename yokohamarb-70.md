<!-- Yokohama.rb Monthly Meetup #70 に参加した -->

2016-07-09（土）の Yokohama.rb Monthly Meetup #70 に参加しました。

[https://yokohamarb.doorkeeper.jp/events/45057:embed:cite]

参加者は 8 人。内容は次のような感じでした。

- レシピブック読書会
- どう書く
- [吉田飯店](http://tabelog.com/kanagawa/A1401/A140212/14006019/)で懇親会

# レシピブック読書会

今回はレシピ 234 から 237 まで読みました。

## レシピ 234

Ruby が `require`, `load` するときに参照するパスである **ロードパス** を制御するレシピです。ロードパスを設定するには、次の三つの方法

- 環境変数 `RUBYLIB`
- オプション `-I`
- グローバル変数 `$LOAD_PATH` (`$:`)

がありますが、一番下の `$LOAD_PATH` を使うことが多いという話でした。

パスの区切りは OS によって違う（Windows なら `;`, UNIX 系なら `:`）ので、定数になってるんじゃないかという話が出ました。実際のところ定数 `File::PATH_SEPARATOR` として存在していて、システムに応じて `;`, `:`, `,` のどれかが入っているようです。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">PATH環境変数の要素のセパレータ。 <a href="https://t.co/lAWAYm9mSB">https://t.co/lAWAYm9mSB</a> <a href="https://twitter.com/hashtag/yokohamarb?src=hash">#yokohamarb</a></p>&mdash; みよひで@大阪マラソン走ります (@miyohide) <a href="https://twitter.com/miyohide/status/751702262741737472">2016年7月9日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

どの OS で使われるのかわからなかった謎のカンマ `,` については、次のとおり [RISC OS](https://ja.wikipedia.org/wiki/RISC_OS) 用に存在していたものだそうです。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr"><a href="https://twitter.com/miyohide">@miyohide</a> 1.9以降では削除されてしまったけど、おそらくはRISC OS</p>&mdash; なかだ の (@n0kada) <a href="https://twitter.com/n0kada/status/751750520675545088">2016年7月9日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

## レシピ 235

`ruby` コマンドでスクリプトを実行するときに、バグになりそうな箇所などについて警告を出せます。すべての警告を出すには、次のようにオプションに `-w` または `-W2` を指定します。

```
$ ruby -w foo.rb
```

自前で警告を出したいときは、次のようにコードを書くと、オプションに `-w` または `-W2` を指定したときだけ警告が出せます。

```ruby
warn 'foobar' if $VERBOSE
```

これは、`-w` または `-W2` 指定を指定したとき、`$VERBOSE` が `true` になるからです。

なお、`stderr.puts` は `$VERBOSE` の値にかかわらず普通に出力されます。

また、`require` している外部 gem についての警告を抑止するための gem があるという話が出ました。

[https://github.com/graysonwright/warning_filter:embed:cite]

## レシピ 236

デバッグ関係のレシピです。

`ruby` コマンドで `-d` オプションをつけて実行すると、例外発生時に例外をすぐ表示します。また、マルチスレッド環境でどれかのスレッドが例外を投げると、メインスレッドに例外を投げ直してくれます。

処理系組み込みのデバッガもあります。次のコマンドで `debug` を `require` しつつスクリプトを実行すると、デバッガが起動します。

```
$ ruby -r debug foo.rb
```

実際には byebug を使うことが多いのではという話でした。

## レシピ 237

UNIX 系の OS 上で `/etc` 次の情報（ユーザ情報やグループ情報）を取得するためのレシピです。

`Etc.passwd` や `Etc.group` にブロックを渡すと、ユーザ情報やグループ情報を表す `Struct::Passwd` や `Struct::Group` を順に取得できます。

```ruby
Etc.passwd do |pw|
  p pw
end
```

この `Etc.passwd` や `Etc.group` へブロックを渡さずに実行すると、実行するたびに違う `Struct::Passwd` オブジェクトが順番に返ってきて、最後までいくと `nil` が返ってくるようになるという挙動に会場はざわ…ざわ…となってました。

```ruby
Etc.passwd   # 実行するたびに別の Struct::Passwd が返る
```

# 「どう書く」初挑戦

「[どう書く](https://yhpg.doorkeeper.jp)」というイベントの Yokohama.rb 版として、今回は @Nabetani さん作成の問題「Rails on Tiles」に挑戦しました。

- [Rails on Tiles yokohama.rb 2016.7.9 問題](http://nabetani.sakura.ne.jp/yokohamarb/2016.07.ront/)

40 分の挑戦時間で解けた人は 2 人でした。私は残念ながら時間内に解けず……

挑戦のあと、@Nabetani さんから解説の時間。

- [yokohama.rb#70 に出した問題の実装例(ruby) - Qiita](http://qiita.com/Nabetani/items/1234c313776b6588a9d8)

考えをコードへ無理なく落とし込めるようにしていきたいという感じです。Yokohama.rb 的には、こういうイベントではペアプログラミングをすることが多いそうなので、機会があれば参加してみたいですね。

 ----

次回 2016-08-06（土）の Yokohama.rb は以下リンクから申し込めます。

[https://yokohamarb.doorkeeper.jp/events/47082:embed:cite]
