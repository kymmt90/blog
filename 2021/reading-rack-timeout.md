<!-- Rack::Timeoutによるリクエストタイムアウトの仕組み -->

# はじめに

Rackミドルウェアの一つである[Rack::Timeout](https://github.com/sharpstone/rack-timeout)を使うと、Rackアプリがリクエストを受け取ってから一定時間が経過すると、アプリのどの場所でコードが実行されていても、その場所からRack::Timeoutの例外``RequestTimeoutException``が発生する。

サンプルコードと、タイムアウト時のスタックトレースは次のようになる。

```ruby
# config.ru
require 'rack-timeout'
require_relative './app'

use Rack::Timeout, service_timeout: 5
run App
```

```ruby
# app.rb
require 'sinatra/base'

class App < Sinatra::Base
  get '/timeout' do
    sleep 6
    'Time out'
  end
end
```

```
[2021-04-12 20:20:17] INFO  WEBrick::HTTPServer#start: pid=1362 port=9292
source=rack-timeout id=287a1d6a-d9b2-47b1-8d03-27094d707e9d timeout=5000ms state=ready at=info
source=rack-timeout id=287a1d6a-d9b2-47b1-8d03-27094d707e9d timeout=5000ms service=5006ms state=timed_out at=error
2021-04-12 20:20:44 - Rack::Timeout::RequestTimeoutException - Request ran for longer than 5000ms :
	/Users/kymmt90/path/to/app/app.rb:5:in `sleep'
	/Users/kymmt90/path/to/app/app.rb:5:in `block in <class:App>'
	/Users/kymmt90/path/to/app/vendor/bundle/ruby/3.0.0/gems/sinatra-2.1.0/lib/sinatra/base.rb:1675:in `call'
(snip)
source=rack-timeout id=287a1d6a-d9b2-47b1-8d03-27094d707e9d timeout=5000ms service=5013ms state=completed at=info
::1 - - [12/Apr/2021:20:20:44 +0900] "GET /timeout HTTP/1.1" 500 30 5.0176
```

sleepしているapp.rbの13行目からRack::Attackの例外`Rack::Timeout::RequestTimeoutException`が発生している。この仕組みが気になったので調べた。

# 先に結論

Rack::Timeoutでタイムアウトするとき、次のように動作する。

- 渡したブロックを一定時間後に実行できるスケジューラを作る
- Rack::Timeoutの`#call`メソッドを呼ぶとき
  - リクエストをハンドリングするスレッドで[`Thread#raise`](https://docs.ruby-lang.org/ja/3.0.0/method/Thread/i/raise.html)して`Rack::Timeout::RequestTimeoutException`を発生させるブロックをスケジューラに渡す
  - 先のRackアプリに対して`#call`を実行し、タイムアウトの時間が経過すると渡したブロックを実行する

こうして、一定時間以内にRackアプリがレスポンスを返せばそのレスポンスを返し、そうでなければスケジューラに渡したブロックがアプリのスレッドの外から例外を発生させている。

# Rack::Timeoutの概要

## 目的

[Rack::TimeoutのREADME](https://github.com/sharpstone/rack-timeout#readme)には、その目的がこう書いてある:

> Rack::Timeout is not a solution to the problem of long-running requests, it's a debug and remediation tool.

あくまでもタイムアウトをきっかけとしてアプリケーションを改善するために使っていこうというもの。

## 設定方法

[Rack::Runtime](https://github.com/rack/rack/blob/master/lib/rack/runtime.rb)がRackミドルウェアとして入っているRackアプリなら、`rack-timeout`をGemfileに追加するだけでRack::Timeoutの機能が追加される。そうでないときやRackミドルウェアスタックのどこにミドルウェアを入れたいかを制御したいなら自前で設定を書く必要がある。

## 設定項目の意味

Rack::Timeoutはさまざまな設定項目を持つ。それぞれの効果をあらためて確認した。

### Service Timeout

Rackアプリの実行時間のタイムアウト。

### Wait Timeout

リクエストがWebサーバのキューに入ってからRackアプリが処理し始めるまでの時間のタイムアウト。

たとえばHeroku Routerは30秒でタイムアウトするので、リクエストのキューに入って30秒たってからRackアプリが処理し始めるのは意味をなさない。そういうリクエストをRackアプリの手前で落として`Rack::Timeout::RequestExpiryError`をraiseする。

30秒のタイムアウトのとき、Rackアプリの前段で時間がかかって、Rackアプリの処理が始まるまでに20秒使ったら、service timeoutが実質10秒になってしまう。これを無効にするのが `service_past_wait`。

`X-Request-Start`を使ってリクエスト開始時間をUNIXエポックで取得しているので、このヘッダがなかったらwait timeoutは発生しない。

### Wait Overtime

wait timeoutで`X-Request-Start`を使っていることもあって、ボディが大きなPOSTリクエスト（ファイルアップロードとか）で受信しはじめから受信終わりまでに時間がかかると、受信完了前にwait timeout扱いになることがある。これを防ぐために、wait timeoutに下駄を履かせる((ベストな解決策はS3などオブジェクトストレージへのダイレクトアップロード))。

### Term on timeout

たとえば1を設定すると、あるリクエストでタイムアウトしたらWebサーバにSIGTERMを送る。また、たとえば5を設定すると、5件のリクエストがタイムアウトするまでSIGTERMしない。

この機能はPumaなどWebサーバがマルチワーカーなときに使わないと、masterプロセスが終了してしまう。

# コードの概要

この記事ではRack::Timeout [v0.6.0](https://github.com/sharpstone/rack-timeout/tree/v0.6.0)を読む。コメントが豊富に書かれており、読みやすい。

[lib/rack/timeout/core.rb](https://github.com/sharpstone/rack-timeout/blob/v0.6.0/lib/rack/timeout/core.rb)にRackミドルウェアとしての`Rack::Timeout#call`が存在する。

```ruby
module Rack
  class Timeout

  # ...

    RT = self # shorthand reference
    def call(env)
      # ...
    end
```

スケジューラ`Rack::Timeout::Scheduler::Timeout`（以下`RT::Scheduler::Timeout`）はタイムアウト処理を実現するにあたっての肝となるクラスである。`Rack::Timeout`の`#call`では、次のように次のミドルウェアまたはRackアプリに対しての`#call`を`RT::Scheduler::Timeout#timeout`に渡すブロックで包むことでタイムアウト処理を実現している。これにより、一定時間以上でタイムアウトするRackアプリが完成する。

```ruby
      timeout = RT::Scheduler::Timeout.new do |app_thread|
        # タイムアウトしたときの処理を設定する
      end

      # 一定時間経過したとき上で渡したブロックを実行するために、#timeoutに@app.callを実行するブロックを渡す
      response = timeout.timeout(info.timeout) do
        begin
          @app.call(env)
        rescue RequestTimeoutException => e
          raise RequestTimeoutError.new(env), e.message, e.backtrace
        ensure
          register_state_change.call :completed
        end
      end
```

[lib/rack/timeout/support/scheduler.rb](https://github.com/sharpstone/rack-timeout/blob/v0.6.0/lib/rack/timeout/support/scheduler.rb)にある`RT::Scheduler::Timeout#timeout`は次のとおり。本質は`@scheduler.run_in`の部分で`#run_in`は渡した秒数が経つとブロックを実行する。つまり、タイムアウト用のブロックを実行する。ここで得ている`Thread.current`はRackアプリへのリクエストハンドリングを行っているスレッドとなるので、スタックトレース上はRackアプリ内で`RequestTimeoutException`が発生する形となる。

```ruby
  def timeout(secs, &block)
    return block.call if secs.nil? || secs.zero?
    thr = Thread.current
    job = @scheduler.run_in(secs) { @on_timeout.call thr }
    return block.call
  ensure
    job.cancel! if job
  end
```

`#run_in`は次のとおり。`fsecs`はmonotonic clock((現実の時刻は閏年などで補正されたり巻き戻ったりすることがあるが、monotonic clockは単調増加する))から得られる時刻。スケジューラに渡せるイベントの一種として`RunEvent`があり、これは渡された秒数経過後に1回処理を実行するというもの。

```ruby
  def run_in(secs, &block)
    schedule RunEvent.new(fsecs + secs, block)
  end
```

`#schedule`にイベントを渡すことで、Rack::Timeoutは新たなスレッドで無限ループしながら、実行が必要なイベントを随時実行する。

```ruby
  def schedule(event)
    @mx_events.synchronize { @events << event }
    runner.run # 無限ループしながら実行が必要なイベントを実行するまで待つ#run_loop!を別スレッドで実行する
    return event
  end
```

[`#run_loop!`](https://github.com/sharpstone/rack-timeout/blob/v0.6.0/lib/rack/timeout/support/scheduler.rb#L77-L103)は詳細は割愛するが、コメントが丁寧なのでやっていること自体は把握しやすい。現在実行すべきイベントを取り出して実行する、の繰り返しになっている。
