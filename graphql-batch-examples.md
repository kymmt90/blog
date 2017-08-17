<!-- GraphQL::Batchのサンプルコードを読む & 使ってみる -->

単純にGraphQLクエリを投げると、サーバサイドでの関連を含むレコード取得時にN+1問題が発生することがあります。こういうケースでは、複数のデータ取得リクエストをひとまとめにして、単一のリクエストとしてDBからデータを取得する**batching**が推奨されています(([GraphQL Best Practices | GraphQL](http://graphql.org/learn/best-practices/#server-side-batching-caching)))。

GraphQLにおけるbatchingを[graphql gem](https://github.com/rmosolgo/graphql-ruby)を使ってやるための**GraphQL::Batch**というgemがあります。[先日リポジトリにサンプルコードが追加されて使いかたを把握しやすくなった](https://github.com/Shopify/graphql-batch/pull/64)ので、サンプルコードを読みながら使ってみます。

[https://github.com/Shopify/graphql-batch:embed:cite]

# GraphQL::Batchの概要

GraphQL::Batchでは、**Loader**というデータを取得するためのクラスを作って使うことが想定されています。これは、Facebookが開発している[DataLoader](https://github.com/facebook/dataloader)での考えかたが元となっています。Loaderがbatchingでデータを取得するときは、`load` 関数でレコードのキーを複数受け取り、複数レコードを解決するpromiseを返します((https://github.com/facebook/dataloader#batching))。

## 利用例

コードを読む前にGraphQL::Batchの利用例を示します。

### 前提

本エントリではRailsでGraphQL::Batchを使うこととします((GraphQL::BatchはActive Recordに依存しているわけではありません))。

次のようなモデルが存在するRailsアプリケーションを考えます。DBテーブルもこれにしたがった構成であるとします。

```ruby
class User < ApplicationRecord
  has_many :customers
end

class Customer < ApplicationRecord
  belongs_to :user
  has_many :orders
  has_many :deliverers, through: :orders
end

class Deliverer < ApplicationRecord
  has_many :orders
  has_many :customers, through: :orders
end

class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :deliverer
end
```

このとき、次のようなGraphQLのスキーマを `app/graphql/types` 配下などに定義するとします。

```ruby
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :user do
    type Types::UserType
    argument :email, !types.String
    resolve ->(obj, args, ctx) {
      User.find_by!(email: args['email'])
    }
  end
end

Types::UserType = GraphQL::ObjectType.define do
  name 'User'

  field :email, !types.String
  connection :customers, Types::CustomerType.connection_type
end

Types::CustomerType = GraphQL::ObjectType.define do
  name 'Customer'

  field :name, !types.String
  connection :orders, Types::OrderType.connection_type
  connection :deliverers, Types::DelivererType.connection_type
end

Types::DelivererType = GraphQL::ObjectType.define do
  name 'Deliverer'

  field :name, !types.String
  connection :orders, Types::OrderType.connection_type
  connection :customers, Types::CustomerType.connection_type
end

Types::OrderType = GraphQL::ObjectType.define do
  name 'Order'

  field :price, !types.Int
  field :customer, !Types::CustomerType
  field :deliverer, !Types::DelivererType
end
```

ここで、次のようなクエリをサーバへ投げてみます（DBにはいい感じにデータが保存されているとします）。

```
{
  user(email: "foo@example.com") {
    customers(first: 2) {
      edges {
        node {
          orders {
            edges {
              node {
                deliverer {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}
```

すると、次のように `Customer` のレコードごとに `Order` を、`Order` のレコードごとに `Deliverer` を取得するSQLを発行してしまうN+1問題が発生します。

```
User Load (1.6ms)  SELECT  "users".* FROM "users" WHERE "users"."email" = ? LIMIT ?  [["email", "foo@example.com"], ["LIMIT", 1]]
Customer Load (1.7ms)  SELECT  "customers".* FROM "customers" WHERE "customers"."user_id" = ? LIMIT ?  [["user_id", 1], ["LIMIT", 2]]
Order Load (3.3ms)  SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = ?  [["customer_id", 1]]
Deliverer Load (1.8ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.5ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.4ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (2.1ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (2.6ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (2.9ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.8ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.9ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.6ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.8ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Order Load (2.1ms)  SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" = ?  [["customer_id", 2]]
Deliverer Load (1.5ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.4ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.5ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.6ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (2.2ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.7ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.6ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (1.4ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
Deliverer Load (1.5ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 1], ["LIMIT", 1]]
Deliverer Load (2.6ms)  SELECT  "deliverers".* FROM "deliverers" WHERE "deliverers"."id" = ? LIMIT ?  [["id", 2], ["LIMIT", 1]]
```

### GraphQL::Batchの利用

上述したN+1問題を解消するためにGraphQL::Batchを使います。具体的には次のことをやります。

- [サンプル](https://github.com/Shopify/graphql-batch/tree/058213b78775c791135bf7db784b7d10007d5ade/examples)を参考にLoaderを定義する
- スキーマ定義の `resolve` 内で使う

まず、サンプルを参考にして、Loaderを `app/graphql/loaders` 配下などに定義しておきます。そして、定義したLoaderを使って次のようにスキーマを定義し直します。変更部分だけ抜粋します。

```ruby
Types::UserType = GraphQL::ObjectType.define do
  # ...
  connection :customers, Types::CustomerType.connection_type do
    resolve ->(user, args, ctx) {
      Loaders::AssociationLoader.for(User, :customers).load(user)
    }
  end
end

Types::CustomerType = GraphQL::ObjectType.define do
  # ...
  connection :orders, Types::OrderType.connection_type do
    resolve ->(customer, args, ctx) {
      Loaders::AssociationLoader.for(Customer, :orders).load(customer)
    }
  end
  connection :deliverers, Types::DelivererType.connection_type do
    resolve ->(customer, args, ctx) {
      Loaders::AssociationLoader.for(Customer, :deliverers).load(customer)
    }
  end
end

Types::DelivererType = GraphQL::ObjectType.define do
  # ...
  connection :orders, Types::OrderType.connection_type do
    resolve ->(deliverer, args, ctx) {
      Loaders::AssociationLoader.for(Deliverer, :orders).load(deliverer)
    }
  end
  connection :customers, Types::CustomerType.connection_type do
    resolve ->(deliverer, args, ctx) {
      Loaders::AssociationLoader.for(Deliverer, :customers).load(deliverer)
    }
  end
end

Types::OrderType = GraphQL::ObjectType.define do
  # ...
  field :customer, !Types::CustomerType do
    resolve ->(order, args, ctx) {
      Loaders::RecordLoader.for(Customer).load(order.customer_id)
    }
  end
  field :deliverer, !Types::DelivererType  do
    resolve ->(order, args, ctx) {
      Loaders::RecordLoader.for(Deliverer).load(order.deliverer_id)
    }
  end
end
```

この状態で先ほどと同じクエリを送信すると、`Order`, `Deliverer` に対するSQLがまとめて発行されるようになり、N+1問題を防いでいることがログを見るとわかります。

```
User Load (1.6ms)  SELECT  "users".* FROM "users" WHERE "users"."email" = ? LIMIT ?  [["email", "foo@example.com"], ["LIMIT", 1]]
Customer Load (1.5ms)  SELECT "customers".* FROM "customers" WHERE "customers"."user_id" = 1
Order Load (2.2ms)  SELECT "orders".* FROM "orders" WHERE "orders"."customer_id" IN (1, 2, 3, 4)
Deliverer Load (1.5ms)  SELECT "deliverers".* FROM "deliverers" WHERE "deliverers"."id" IN (1, 2)
```

それでは、このLoaderが何をやっているかを見ていきます。

# Loaderサンプルコードリーディング

次の場所にある `RecordLoader` と `AssociationLoader` のコードを読んで何をやっているか見ていきます。

- [graphql-batch/examples at 058213b78775c791135bf7db784b7d10007d5ade · Shopify/graphql-batch](https://github.com/Shopify/graphql-batch/tree/058213b78775c791135bf7db784b7d10007d5ade/examples)

なお、Loaderを作るには [`GraphQL::Batch::Loader`](https://github.com/Shopify/graphql-batch/blob/master/lib/graphql/batch/loader.rb) を継承する必要があります。

## `RecordLoader`

コードはこちら。

- [graphql-batch/record_loader.rb at 058213b78775c791135bf7db784b7d10007d5ade · Shopify/graphql-batch](https://github.com/Shopify/graphql-batch/blob/058213b78775c791135bf7db784b7d10007d5ade/examples/record_loader.rb)

`belongs_to` のように関連先が1件のときに使うLoaderです。上述した例では `Order` で利用しています。

`Graphql::Batch::Loader` はファクトリメソッド `for` から `initialize` を使っており、この `initialize` を必要に応じてオーバーライドしていきます。ここでは `model` で関連先モデルのクラス名を渡せるようになっています。`column` はデフォルトでは主キー（Active Recordのデフォルトではサロゲートキー `id`）ですが、オプションで別のキーも渡せるようになっています。また、特定レコードだけ絞り込むために `where` を渡せるようになっています。

```ruby
def initialize(model, column: model.primary_key, where: nil)
  @model = model
  @column = column.to_s
  @column_type = model.type_for_attribute(@column)
  @where = where
end
```

`load` へはバッチで取得してほしいレコードのキーを渡します。ここでは `@column_type` の表す型にキャストしてから親クラス `GraphQL::Batch::Loader` の `load` に引数を渡しています。これは、任意の主キーを適切な型に変換する処理と思われます。

```ruby
def load(key)
  super(@column_type.cast(key))
end
```

`perform` へは、バッチで渡ってくる `keys` をもとに、一気にレコードをロード、つまり**batching**する処理を書きます。このときに、プライベートメソッド `query` で、`initialize` で渡された絞り込み条件と `perform` の引数 `keys` をもとに、必要な関連先レコードだけロードしています。その後、`fulfill` することで、promiseを解決状態に遷移させつつ、ロードしたレコードを渡しています。`GraphQL::Batch::Loader#fulfill` の定義は次を参照してください。

- [graphql-batch/loader.rb at bdc21a02716adb594ea3e92c9337e55a31771adf · Shopify/graphql-batch](https://github.com/Shopify/graphql-batch/blob/bdc21a02716adb594ea3e92c9337e55a31771adf/lib/graphql/batch/loader.rb#L75)

また、対応するレコードが存在しない `keys` 中のキーのpromiseも解決状態とするために、最後の行で `fulfill` できていない `keys` の要素に対して、レコードが存在しなかったという意味合いで `nil` を渡して `fulfill` しています。

```ruby
def perform(keys)
  query(keys).each do |record|
    value = @column_type.cast(record.public_send(@column))
    fulfill(value, record)
  end
  keys.each { |key| fulfill(key, nil) unless fulfilled?(key) }
end

private

def query(keys)
  scope = @model
  scope = scope.where(@where) if @where
  scope.where(@column => keys)
end
```

## `AssociationLoader`

コードはこちら。

- [graphql-batch/association_loader.rb at 058213b78775c791135bf7db784b7d10007d5ade · Shopify/graphql-batch](https://github.com/Shopify/graphql-batch/blob/058213b78775c791135bf7db784b7d10007d5ade/examples/association_loader.rb)

`has_many` のように関連先が複数件あるときに使うLoaderです。上述した例では `User`, `Customer`, `Deliverer` で利用しています。

`initialize` では関連元モデルのクラス名 `model` と、モデル内で `has_many` に指定する関連先名 `association_name` を渡しています。最後の行の `validate` では、`model` が本当に `association_name` で指定される関連を持っているのかをチェックしています。

```ruby
def initialize(model, association_name)
  @model = model
  @association_name = association_name
  validate
end

private

def validate
  unless @model.reflect_on_association(@association_name)
    raise ArgumentError, "No association #{@association_name} on #{@model}"
  end
end
```

`perform` では、バッチで渡ってくる関連元レコード群に対する関連先を `preload_association` 内の `ActiveRecord::Associations::Preloader#preload` で一気にpreloadしています。このメソッドは `:nodoc:` なRailsの内部APIですが、ここでは利便性をとって使われているようです。その後、`RecordLoader` と同じように、ロードした各レコードに対して `fulfill` することで、promiseを解決状態にしつつ、eager loadしたレコードを渡しています。

```ruby
def perform(records)
  preload_association(records)
  records.each { |record| fulfill(record, read_association(record)) }
end

private

def preload_association(records)
  ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
end

def read_association(record)
  record.public_send(@association_name)
end
```

順番が前後しますが、`load` へはバッチで関連先を取得してほしい関連元レコードを渡します。ここで、すでに関連先レコードを `perform` でロード済みであれば、batchingの対象とすることなく、そのレコードを持つ解決済みpromiseをすぐに返しています。

```ruby
def load(record)
  raise TypeError, "#{@model} loader can't load association for #{record.class}" unless record.is_a?(@model)
  return Promise.resolve(read_association(record)) if association_loaded?(record)
  super
end

private

def association_loaded?(record)
  record.association(@association_name).loaded?
end
```

# おわりに

サンプルコードを試しつつ読みながらGraphQL::Batchをどう使うか調べました。具体的には次のようにすればひとまず使えそうです。

- [サンプル](https://github.com/Shopify/graphql-batch/tree/058213b78775c791135bf7db784b7d10007d5ade/examples)を参考にLoaderを定義する
- スキーマ定義の `resolve` 内で使う

私が試しに書き散らしたコードは次の場所に置いています。

[https://github.com/kymmt90-sandbox/rails-graphql-batch:embed:cite]
