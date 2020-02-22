<!-- wscatでAction Cableと通信する -->

Railsで`/cable`などのエンドポイントにAction CableをマウントするとWebSocketサーバとして利用できます。**wscat**を使ってAction CableによるWebSocket APIと対話的に通信するために、送信するデータの形式などを調べました。

## 準備

### wscat

[https://github.com/websockets/wscat:cite:embed]

npmでインストールできます。

```
$ npm install -g wscat
```

### Action Cable

この記事ではRails 5.1.6を使います。今回は、APIモードのRailsアプリケーションにAction Cableをマウントします（Action Cableサーバを独立に起動することも可能）。まず、適当にアプリを作ります。

```
$ rails new --api action-cable-sample
$ cd action-cable-sample
$ bin/rails g scaffold message body:string
$ bin/rails db:migrate
```

`config/application.rb`で`action_cable/engine`を読み込み、さらにマウントパスを指定します。`/cable`にマウントするのがRails wayの様子なのでそうします。

```ruby
# config/application.rb
require_relative 'boot'

require "rails"
# ...
require "action_cable/engine"
# ...

module ActionCableSample
  class Application < Rails::Application
    # ...
    config.api_only = true

    config.action_cable.mount_path = '/cable'
  end
end
```

また、デフォルトではCSRF対策で同じオリジンからしかWebSocket通信できないので、開発環境ではどのオリジンからでもWebSocket通信できるように設定します。

```ruby
# config/environments/development.rb
Rails.application.configure do
  # ...
  config.action_cable.disable_request_forgery_protection = true
end
```

あとはAction Cableのチャンネルを適当に作ります。

```
$ bin/rails g channel message
```

`MessageChannel`は次のように書いておきます。

```ruby
class MessageChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'message_channel'
  end

  def unsubscribed
  end
end
```

また、今回は`messages#create`が成功したときにWebSocket経由でメッセージをブロードキャストします。

```ruby
class MessagesController < ApplicationController
  # ...

  def create
    @message = Message.new(message_params)

    if @message.save
      ActionCable.server.broadcast 'message_channel', body: @message.body

      render json: @message, status: :created, location: @message
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end
end
```

## 実際に通信する

次のコマンドでWebSocketサーバへ接続します。HTTPでリクエストしてからWebSocketへアップグレードする処理などは自動でやってくれます。

```
$ wscat -c localhost:3000/cable

connected (press CTRL+C to quit)

< {"type":"welcome"}
>
```

Action Cableへ送信するデータには`subscribe`, `message`, `unsubscribe`の3種類があります。次の形式でデータを送信することでAction Cableとやりとりできます。

```
{"command":"subscribe","identifier":"{\"channel\":\"MessageChannel\"}"}
{"command":"message","identifier":"{\"channel\":\"MessageChannel\"","data":"\"action\":\"chat\"}"} # "chat"は例です
{"command":"unsubscribe","identifier":"{\"channel\":\"MessageChannel\"}"}
```

Action CableはフルスタックアプリでJSを書いて使うことを想定されているためか、このあたりの仕様はREADMEやRails Guidesを見てもとくにドキュメント化されていないようでした。仕様を把握するにはAction Cableのコードを読む必要があります。

- [rails/subscriptions.rb at v5.1.6 · rails/rails](https://github.com/rails/rails/blob/v5.1.6/actioncable/lib/action_cable/connection/subscriptions.rb)
- [rails/base.rb at v5.1.6 · rails/rails](https://github.com/rails/rails/blob/v5.1.6/actioncable/lib/action_cable/channel/base.rb)

[`ActionCable::Connection::Subscriptions#execute_command`](https://github.com/rails/rails/blob/0ae59ea828ed20141af0d4c9ed9130eb47ce55f3/actioncable/lib/action_cable/connection/subscriptions.rb#L13-L23)で受信したデータを解析し、`command`に指定された文字列`subscribe`, `message`, `unsubscribe`によって処理を分岐しています。`message`を送信したときは[`ActionCable::Channel::Base#perform_action`](https://github.com/rails/rails/blob/0ae59ea828ed20141af0d4c9ed9130eb47ce55f3/actioncable/lib/action_cable/channel/base.rb#L160-L171)に移り、受信データの`action`で指定された名前を持つチャンネルのメソッドを動的に呼び出しています。

また、キー`"identifier"`の値が文字列化されたJSONになっているのは、この文字列が`ActionCable::Connection::Subscriptions`の中で[`ActiveSupport::JSON.decode`](http://api.rubyonrails.org/v5.1.6/classes/ActiveSupport/JSON.html#method-c-decode)に渡るからです。

実際に上述した形式の`subscribe`のデータを送ると、チャンネルを購読できます。

```
> {"command":"subscribe","identifier":"{\"channel\":\"MessageChannel\"}"}
< {"identifier":"{\"channel\":\"MessageChannel\"}","type":"confirm_subscription"}
```

その後、コントローラのアクション内からブロードキャストするとメッセージを受信できます。

```
# curlで叩く
$ curl --request POST --url http://localhost:3000/messages --header 'content-type: application/json' --data '{"message":{"body":"test"}}'

# wscatでデータを受信する
< {"identifier":"{\"channel\":\"MessageChannel\"}","message":{"body":"test"}}
```

## 参考

- [ActionCable in Rails API – codequest – Medium](https://medium.com/codequest/actioncable-in-rails-api-f087b65c860d)
- [ActionCableをwebsocket APIとして使ってUnityと通信する - Qiita](https://qiita.com/wakaba260/items/b23721d5cfd73cd47ada)
