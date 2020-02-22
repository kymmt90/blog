<!-- GraphQL Subscriptionsをgraphql-rubyとAction Cableで作る -->

graphql-rubyでは、RailsのAction Cableに乗ることでGraphQL Subscriptionsを実装できます。

## GraphQL Subscriptionsとは

GraphQL Subscriptionsは、あらかじめ特定のGraphQLクエリを購読しておき、サーバ側でイベントが起きるたびにその形式のデータを受信できる仕組みです。用途としてはプッシュ通知などを想定しているようです。

2018年4月の段階ではまだworking draftですが、FacebookによるGraphQL SubscriptionsのRFCがあります。ここではアーキテクチャだけが示されており、具体的な実装方法については言及していません。

[https://github.com/facebook/graphql/blob/master/rfcs/Subscriptions.md:embed:cite]

Ruby/RailsまわりのGraphQL Subscriptionsの実装としては、graphql-rubyが提供しているものがあります。バックエンドとしては

- RailsのAction Cable
- Pub/Subメッセージングサービスの[Pusher](https://pusher.com)

をサポートしており、Pusherのほうは有料のpro版の機能となるので、最初はAction Cableを選択することになると思います。この記事でもAction Cableを使います。

## GraphQL Subscriptionsを実装する

Order（注文）が入ったときにクライアントへ通知するサーバをGraphQL Subscriptionsとして実装します。

この記事では次のgemを使います。

- rails 5.1.6
- graphql-ruby 1.7.14

次の手順で実装を進めます。

- 配信するデータを準備する
- Action Cableを準備する
- Subscription Typeを追加する
- GraphqlChannelを追加する
- データを配信する

### 配信するデータを準備する

事前にAPIモードでプロジェクトを作っておき、`bin/rails g scaffold order price:integer`を実行して、OrderをCRUDできる状態にしているものとします。また、`OrderType`を次のように定義しておきます。

```ruby
Types::OrderType = Graphql::ObjectType.define do
  name 'Order'
  field :price, !types.Int
end
```

### Action Cableを準備する

以前、Action CableでWebSocketのAPIを作って通信する方法について書いたので、こちらを見てください。Action Cable特有のメッセージ形式についても説明しています。

[http://blog.kymmt.com/entry/communicate-with-action-cable-by-wscat:embed:cite]

WebSocketの接続確立時に作られる`ApplicationCable::Connection`に、subscribeするユーザの認証処理を入れます。

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user || reject_unauthorized_connection
    end

    private

    def find_verified_user
      User.first
    end
  end
end
```

今回は`find_verified_user`で手を抜いて、必ず`User.first`が接続してきているような実装にしていますが、実際はここでなんらかの認証が走るようにします。

### Subscription Typeを追加する

スキーマ定義に`SubscriptionType`のフィールドを追加します。また、`GraphQL::Subscriptions::ActionCableSubscriptions`をスキーマ定義で`use`することで、スキーマでSubscriptionsを使えるようにします。

```ruby
AppSchema = GraphQL::Schema.define do
  subscription Types::SubscriptionType
  use GraphQL::Subscriptions::ActionCableSubscriptions
end
```

クライアントが受信するデータを表す`SubscriptionType`を書きます。

```ruby
Types::SubscriptionType = GraphQL::ObjectType.define do
  name 'Subscription'

  field :orderCreated do
    subscription_scope :current_user_id
    type Types::OrderType
  end
end
```

あとで述べる`GraphqlChannel`に対して購読メッセージを送ると、サーバ側でイベントが発生したときに、ここで定義した型でデータが配信されます。また、`subscription_scope :current_user_id`を指定することで、あとで説明する`trigger`利用時に`current_user`にだけデータを配信できます。

### GraphqlChannelを追加する

次に、GraphQL Subscriptionsを使うときにAction Cableのクライアントが購読する`GraphqlChannel`を定義します。graphql-rubyのAPIドキュメントにサンプル実装が載っています。

[Class: GraphQL::Subscriptions::ActionCableSubscriptions — Documentation for graphql (1.7.14)](http://www.rubydoc.info/gems/graphql/1.7.14/GraphQL/Subscriptions/ActionCableSubscriptions)

抜粋します。

```ruby
class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    query = data["query"]
    variables = ensure_hash(data["variables"])
    operation_name = data["operationName"]
    context = {
      current_user: current_user,
      # Make sure the channel is in the context
      channel: self,
    }

    result = MySchema.execute({
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    })

    payload = {
      result: result.subscription? ? nil : result.to_h,
      more: result.subscription?,
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.
    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each { |sid|
      CardsSchema.subscriptions.delete_subscription(sid)
    }
  end
end
```

これを使えばだいたい動きますが、なにをやっている実装なのかいろいろ気になるので、メソッドごとに見ていきます。

#### subscribed

`ApplicationCable::Channel`を継承すると、クライアントからこのチャンネルへsubscribeメッセージが送られたときに`subscribed`メソッドが実行されます。Rails Guidesの説明などでは、ここで`stream_from`を使ってストリームを自前で管理するように書いてありますが、graphql-rubyでは、このあと説明する`execute`実行時にgem側でストリームを管理するので、ここでストリームを管理する必要はありません。

また、`execute`/`unsubscribed`で使うために`@subscription_ids`を空配列として定義しています。

#### execute

クライアントからこのチャンネルへexecuteを実行するメッセージが送られたときに`execute`メソッドが実行されます。ここはgraphql-rubyを使っているときによく見る`GraphqlController#execute`の実装とよく似ています。

`GraphQL::Schema#execute`を実行しているので、subscribe後に普通のqueryやmutationのクエリを送ると、それが実行されて結果を返すことができます。一方、subscriptionクエリを送った場合は、`execute`すると次の場所でsubscription IDと対応するGraphQLクエリを登録し、`stream_from`でストリームを開きます。

[graphql-ruby/action_cable_subscriptions.rb at v1.7.14 · rmosolgo/graphql-ruby](https://github.com/rmosolgo/graphql-ruby/blob/9f74912f9b7ba8e898d188a03bf3e2737f4aa7dd/lib/graphql/subscriptions/action_cable_subscriptions.rb#L94-L106)

この`GraphQL::Subscriptions::ActionCableSubscription#write_subscription`はsubscriptionクエリを受信後に`GraphQL::Subscriptions::Instrumentation#after_query`で実行されます。

[graphql-ruby/instrumentation.rb at v1.7.14 · rmosolgo/graphql-ruby](https://github.com/rmosolgo/graphql-ruby/blob/9f74912f9b7ba8e898d188a03bf3e2737f4aa7dd/lib/graphql/subscriptions/instrumentation.rb#L31-L36)

この結果、`result.subscription?`が`true`になります。このときは、まだイベントが発生したわけではないので、`payload`として空の結果を返します。また、unsubscribed用にsubscription IDを`@subscription_ids`に入れておいて、最後にAction Cableの[ActionCable::Channel::Base#transmit](http://api.rubyonrails.org/v5.1.6/classes/ActionCable/Channel/Base.html#method-i-transmit)でクライアントへデータを送信します。

なお、例のコードは`payload`の`result`が`nil`ですが、本当は`{ data: nil }`が正しいです((https://github.com/rmosolgo/graphql-ruby/issues/1368))。

#### unsubscribed

クライアントからクエリへunsubscribeメッセージが送られたときに実行されます。execute時に登録されたsubscription IDに対応するsubscriptionを`delete_subscription`で削除しています。`delete_subscription`は次のコードです。

[graphql-ruby/action_cable_subscriptions.rb at v1.7.14 · rmosolgo/graphql-ruby](https://github.com/rmosolgo/graphql-ruby/blob/9f74912f9b7ba8e898d188a03bf3e2737f4aa7dd/lib/graphql/subscriptions/action_cable_subscriptions.rb#L120-L122)

登録したクエリを削除することで、`write_subscription`を実行したときにデータが配信されなくなります。

### データを配信する

subscriptionを登録したクライアントに対するデータの配信には[`GraphQL::Subscriptions#trigger`](http://www.rubydoc.info/gems/graphql/1.7.14/GraphQL/Subscriptions#trigger-instance_method)を使います。今回はわかりやすく`POST /orders`を叩いたときに、クライアントへデータを配信してみます。

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.new(price: params[:price])
    if @order.save
      AppSchema.subscriptions.trigger('orderCreated', {}, @order, scope: @order.user_id)
      render status: :created
    else
      # ...
    end
  end
end
```

`trigger`の詳しい説明は公式ガイドにあります。

[GraphQL - Triggers](http://graphql-ruby.org/subscriptions/triggers.html)

## 動作を確認する

WebSocket経由でサーバへメッセージを送信することで、購読とデータの受信ができるか確かめます。

### リクエスト手順

サーバへは次のGraphQLクエリを送ります。

```
subscription {
  orderCreated {
    price
  }
}
```

`bin/rails s`してサーバを立ち上げたあとに、`wscat -c localhost:3000/cable'`でWebSocketへ接続後、次の順番でデータを送ります。

- `{"command":"subscribe","identifier":"{\"channel\":\"GraphqlChannel\"}"}`
  - `GraphqlChannel`の購読
- `{"command":"message","identifier":"{\"channel\":\"GraphqlChannel\"}","data":"{\"action\":\"execute\",\"query\":\"subscription{orderCreated{price}}\"}"}`
  - `GraphqlChannel#execute`を実行して指定クエリを購読

このあと、適当なHTTPクライアントで`POST /orders`へ次のJSONを投げます。

```
{"order":{"price":1000}}
```

これで、`OrdersController#create`でtriggerが実行されて、subscriptionクエリで購読した構造のデータをwscatが次のように受信するのが見えるはずです。

```
< {"identifier":"{\"channel\":\"GraphqlChannel\",\"channelId\":\"16280cac9e0\"}","message":{"result":{"data":{"orderCreated":{"price":"1000"}}},"more":true}}
```

実際は、mutationでデータを変更したときにtriggerしたり、バックグラウンドジョブが実行完了したときにtriggerするとそれっぽくてよいと思います。

## クライアントについて

今回はサーバ側だけ作ったのでwscatで動くかどうか確認しました。アプリケーションを作るときは、Subscriptionsに対応したモジュールがApolloやRelayに存在するので、これらを使えばJSでSubscriptions対応のクライアントを作ることができます。

- [GraphQL - Apollo Subscriptions](http://graphql-ruby.org/javascript_client/apollo_subscriptions.html)
- [GraphQL - Relay Subscriptions](http://graphql-ruby.org/javascript_client/relay_subscriptions.html)
