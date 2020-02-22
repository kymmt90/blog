<!-- graphql-ruby + Railsで簡易なクエリとミューテーションが使えるGraphQL APIを実装する -->

[会社でGraphQLのハンズオンがあった](https://speakerdeck.com/kumak1/dekiru-graphql)のをきっかけに、最近はGraphQLのサーバ側実装をちょっと触っています。

[graphql-ruby](http://graphql-ruby.org)を使うと、RubyでGraphQL APIを実装することができます。今回はRailsでGraphQLの**クエリ**と**ミューテーション**を実装してみました。

# graphql-ruby使用時のRailsプロジェクトにおけるファイル／ディレクトリ構成

`rails generate graphql:install` すると、ジェネレータが `app` 配下に次のようなディレクトリ構成を作ります。

```
app/controllers
└── graphql_controller.rb
app/graphql
├── app_schema.rb
├── mutations
└── types
    ├── mutation_type.rb
    └── query_type.rb
```

また、ジェネレータは `config/routes` に次のルーティングを追加します。GraphQL APIへのあらゆるHTTPリクエストは次のエンドポイントへPOSTメソッドで送信することとなります。

```ruby
post "/graphql", to: "graphql#execute"
```

# 今回の前提条件

このエントリでは、RailsはAPIモードを使います。また、今回は次のようなデータ構成になっていることとします。

[f:id:kymmt90:20170726233709p:plain]

`User` の認証機構は作りません。実際はなんらかの認証があって、クエリ実行時に `context` というオブジェクトを通じて `current_user` を扱うことになります。

# 今回のゴール

今回は、次のようなクエリとミューテーションをAPIへリクエストできるようにします。

まず、クエリです。これはサーバ側のデータを取得するタイプのリクエストで、いまは引数 `email` で指定した `user` に関するデータを取得しようとしています。

```
{
  user(email: "foo@example.com") {
    email
    article {
      edges {
        node {
          title
          body
        }
      }
    }
  }
}
```

この場合、次のようなレスポンスが返ります。

```json
{
  "data": {
    "user": {
      "email": "foo@example.com",
      "article": {
        "edges": [
          {
            "node": {
              "title": "Title 1",
              "body": "this is the body"
            }
          },
          {
            "node": {
              "title": "Title 2",
              "body": "this is the body 2"
            }
          }
        ]
      }
    }
  }
}
```

次にミューテーションです。これはサーバ側のデータを変更します。

```
{
  createArticle(article: {user_email: "foo@example.com", title: "Another test", body: "This is another test"}) {
    article {
      title
      body
    }
  }
}
```

この場合、`article` が1件増えて、次のようなレスポンスが返ります。

```json
{
  "data": {
    "user": {
      "email": "foo@example.com",
      "article": {
        "edges": [
          {
            "node": {
              "title": "Title 1",
              "body": "this is the body"
            }
          },
          {
            "node": {
              "title": "Title 2",
              "body": "this is the body 2"
            }
          },
          {
            "node": {
              "title": "Another test",
              "body": "This is another test"
            }
          }
        ]
      }
    }
  }
}
```

# 実装手順

## 利用するデータの型を書く

リクエストやレスポンスに出てくるデータの型 `app/graphql/types` 配下の `user_type.rb` や `article_type.rb` にGraphQL APIで利用するデータの書きます。

```ruby
# app/graphql/types/user_type.rb
Types::UserType = GraphQL::ObjectType.defind do
  name 'User'

  field :email, !types.String
  connection :articles, Types::ArticleType.connection_type
end

# app/graphql/types/article_type.rb
Types::ArticleType = GraphQL::ObjectType.define do
  name 'Article'

  field :title, !types.String
  field :body, !types.String
  field :user, Types::UserType
end
```

`field` は型が持つ属性であり、名前とスカラー型（`types.String`, `types.Int`, `types.ID` など）を指定します。また `!` で非nullであることを指定します。

`Types::UserType` の `articles` は `connection` というヘルパを使っています。これは[Relay](https://facebook.github.io/relay/)由来の**connection**というページネーションを扱うための仕組みを使えるようにしてくれるものです。connectionによるページネーションの詳細については次のページを見てください。

- [Pagination | GraphQL](http://graphql.org/learn/pagination/)
- [Connection - Relay Docs](https://facebook.github.io/relay/docs/graphql-connections.html)

今回はクエリのルート階層に書くフィールドは `user` になりますが、これは `name 'Query'` を宣言している型に書きます。

```ruby
# app/graphql/types/query_type.rb
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :user do
    type Types::UserType
    argument :email, !types.String
    resolve ->(obj, args, ctx) {
      User.find_by(email: args['email'])
    }
  end
end
```

ここでは、`argument` にクエリで指定する引数を書いています。また、`resolve` に `user` クエリが投げられたときの `User` レコードの取得方法をラムダ式で書いています。

ここまでで、ゴールとしていたクエリをリクエストできるようになりました。

## ミューテーションと入力データの型を書く

次にミューテーションを書きます。まずは `name 'Mutation'` を宣言している型にフィールドとしてミューテーションを書いてきます。

```ruby
# app/graphql/types/mutation_type.rb
Types::MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  field :createArticle, Types::ArticleType do
    argument :article, Types::ArticleInputType

    resolve ->(o, args, c) {
      user = User.find_by!(email: args[:article][:user_email])
      user.articles.create!(title: args[:article][:title], body: args[:article][:body])
    }
  end
end
```

ここで2点ほどポイントがあります。

- `argument` の型が `Types::ArticleInputType` である
- `resolve` でレコードを作成している

`Types::ArticleInputType` は別途定義している次のような型です。

```ruby
# app/grpahql/types/article_input_type.rb
Types::ArticleInputType = GraphQL::InputObjectType.define do
  name 'ArticleInputType'

  argument :user_email, !types.String do
    description 'Email address of the user'
  end

  argument :title, !types.String do
    description 'Title of the article'
  end

  argument :body, types.String do
    description 'Body of the article'
  end
end
```

この型を引数とすることで、次のような `Types::ArticleInputType` 型の引数としてミューテーションに作成したい `article` のデータを渡すことができます。この方法だと型の再利用性が高まります。

```
createArticle(article: {user_email: "foo@example.com", title: "Another test", body: "This is another test"}) {
  # ...
}
```

`resolve` では、ミューテーションの実際の処理として、対象ユーザの関連レコード `article` を作成しています。

これでゴールとしていたミューテーションもリクエストできるようになりました。

## サンプルコード

素振り用に実装した上記コードを次の場所に置いています。

[https://github.com/kymmt90-sandbox/rails-graphql-sandbox/tree/a72520c1f7cb756b25b2f993ee3c2849e9d77abc:embed:cite]
