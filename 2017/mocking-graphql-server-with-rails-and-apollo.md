<!-- GraphQL APIをスキーマファースト開発するためのモックサーバをRailsとApolloで作る -->

[GMOペパボ Advent Calendar 2017](https://qiita.com/advent-calendar/2017/pepabo)の23日目の記事です。

今回はJavaScriptでGraphQLのサーバ／クライアントや関連ツールを提供している**Apollo**のツールセットでRailsプロジェクトでGraphQLのモックサーバを立ち上げるところまでを試してみます。

業務でRails製の（RESTishな）Web APIとVue.js製のSPAからなるアプリケーションを開発していて、[**スキーマファースト開発**](https://speakerdeck.com/kymmtchan/rails-developers-meetup-2017)を取り入れています。また、GraphQLで通信するAPIを実験的に導入しはじめていますが、こちらは明示的な開発フローを決めず導入しようとしているため、なかなかサクサクと開発が進まないのが現状です。そこで、GraphQLでも先にインタフェースだけを決めてから、モックサーバを使ってフロントエンドとバックエンドで並行開発していけばよいのでは、という発想になります。

しかし、そもそもGraphQLはサーバに対するクエリを書くためのスキーマありきの技術であり、それがRESTの文脈におけるAPIとは異なる点です。その点で、**スキーマ**ファースト開発と呼ぶと語弊があるかもしれません。ですが、ここでは「GraphQLの型やフィールドだけを書いて、実際にデータを問い合わせる部分（リゾルバ）を書かない」ことをスキーマファースト開発とひとまず呼びます。つまり、裏の実装を後回しにして、フロントエンド／バックエンドでインタフェースについて合意が取れればモックサーバを使って開発を進められる、という状態を目指します。

## 利用ツール

上述したとおり、Apolloのツールセットを使います。

[https://www.apollographql.com:embed:cite]

具体的には次のものを使います。

- [apollographql/apollo-server: GraphQL server for Express, Connect, Hapi, Koa and more](https://github.com/apollographql/apollo-server)
- [apollographql/graphql-tools: Build, mock, and stitch a GraphQL schema using the schema language](https://github.com/apollographql/graphql-tools)

ダミーデータを返してくれるサーバのことをスタブサーバと呼んだりもしますが、graphql-toolsが"Mocking"という言葉を使っているので、この記事ではモックサーバと呼ぶことにします。

## 最終構成

今回はRailsでgraphql-rubyを使っている状況を想定します。Railsプロジェクトにおける最終的な構成は次のとおりです（関係する部分だけ書いています）。

```
.
├── app
│    └── graphql
│         ├── app_schema.rb
│         ├── mutations
│         └── types
├── lib
│    └── tasks
│         └── graphql.rake
└── mock_app
     ├── index.js
     ├── mocks.js
     ├── package.json
     └── type_defs.js
```

詳細は次の通りです。

- `app` 配下にgraphql-rubyで書いたGraphQLスキーマを置く
- `lib` 配下にGraphQLスキーマをダンプするRakeタスクを置く
- `mock_app` 配下にモックサーバの実装を置く
  - `type_defs.js` はRakeタスクで生成する

## 想定する開発フロー

想定する開発フローは次の通りです。

1. graphql-rubyのDSLでGraphQLの型やフィールドを書く
1. 追加した型やフィールドのダミーデータを書く
    - モックサーバで使う
1. レビュー
1. モックサーバを立ち上げる
    - graphql-rubyでGraphQLスキーマをダンプしてApolloで使える形式にする
    - ExpressとApolloでGraphQLモックサーバを立ち上げる
1. フロントエンド／バックエンドが並行して開発する

それぞれ説明します。

### graphql-rubyのDSLでGraphQLの型やフィールドを書く

これはgraphql-rubyをふつうに使うときとほぼ同じになります。まだ裏の実装ができていないので `resolver` を書かない点が違いといえます。

```ruby
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :user do
    type Types::UserType
    argument :email, !types.String

    resolve ->(obj, args, ctx) {
	  # まだ裏の実装がないので書かない
	}
  end
end

Types::UserType = GraphQL::ObjectType.define do
  name 'User'

  field :email, !types.String
  connection :articles, Types::ArticleType.connection_type
end

Types::ArticleType = GraphQL::ObjectType.define do
  name 'Article'

  field :title, !types.String
  field :body, !types.String
end
```

このように開発に必要な型とフィールドだけを書いていきます。

## 追加した型やフィールドのダミーデータを書く

モックサーバとして動かすには、サーバになんらかのデータを返してもらう必要があります。Apolloのgraphql-toolsで作れるモックサーバは、フィールドの型に応じてある程度ランダムにデータを返してくれるようになっています。しかし、実際に返ってくるであろうものに近いデータを返したほうがフロントエンドの開発ではありがたいということもあるでしょう。また、ダミーデータを見ればフィールドの表現しているものの雰囲気がわかるという利点もあります。

Apolloのモックサーバが返す値を指定するために、次のようなオブジェクトを定義します。ここでは仮に `mocks.js` とします。

```javascript
// mock_app/mocks.js

module.exports = {
  User: () => ({
    email: 'kymmt90@example.com',
  }),
  Article: () => ({
    title: 'The Article',
	body: 'This is the article.',
  }),
};
```

GraphQLの型に対して、型のフィールドとダミーデータを持つオブジェクトを書き、それを返す関数を持たせているだけです。これを書いておくだけで、connectionなどを使ってクエリがネストしているときも、graphql-toolsのモックサーバがいい感じにダミーデータを返してくれるようになります。

## レビュー

上述した流れでスキーマとダミーデータだけ書けたら、チームでレビューするなりして合意をとります。

## モックサーバを立ち上げる

Apolloを使ってモックサーバを立ち上げます。

Expressとapollo-serverを使って、次のようなサーバを書きます。ここでは `mock_app/index.js` とします。

```javascript
// mock_app/index.js

const express = require('express');
const bodyParser = require('body-parser');
const { graphqlExpress } = require('apollo-server-express');
const { addMockFunctionsToSchema, makeExecutableSchema } = require('graphql-tools');

// モックサーバの作成
const typeDefs = require('./type_defs');
const schema = makeExecutableSchema({ typeDefs });
const mocks = require('./mocks')
addMockFunctionsToSchema({ schema, mocks });

// GraphQLエンドポイントを持つExpressサーバの立ち上げ
const app = express();
app.use('/graphql', bodyParser.json(), graphqlExpress({ schema }));
app.listen(3000, () => {
  console.log('GraphQL mock server is running!!1');
});
```

`mock_app/package.json` は次のような感じです。

```
{
  "name": "graphql-mock-server",
  "private": true,
  "version": "0.0.1",
  "description": "graphql-mock-server",
  "author": "kymmt90",
  "dependencies": {
    "apollo-server-express": "*",
    "graphql-tools": "*",
    "graphql": "*",
    "express": "*",
    "body-parser": "*"
  }
}
```

`server.js` に書いたように、GraphQLスキーマを `type_defs.js` から読み込みます。この `type_defs.js` を得るために、graphql-rubyで定義したスキーマをもとに、次のRakeタスクを書き、スキーマをダンプできるようにします。

```ruby
# lib/tasks/graphql.rake
namespace :graphql do
  namespace :schema do
    desc 'Dump GraphQL schema as a JavaScript file'
    task dump_as_js: :environment do
      schema = AppSchema.to_definition
      File.open(Rails.root.join('mock_app', 'type_defs.js'), 'w') do |f|
        f.puts("module.exports = `\n")
        f.puts(schema)
        f.puts('`')
      end
    end
  end
end
```

`bin/rails graphql:schema:dump_as_js` を実行すると次のようなファイルが得られます。`type_defs.js` では、GraphQLスキーマをJSの文字列として定義しています。

```
// mock_app/type_defs.js

module.exports = `
type Article {
  body: String!
  title: String!
}

# The connection type for Article.
type ArticleConnection {
  # A list of edges.
  edges: [ArticleEdge]

  # Information to aid in pagination.
  pageInfo: PageInfo!
}

# An edge in a connection.
type ArticleEdge {
  # A cursor for use in pagination.
  cursor: String!

  # The item at the end of the edge.
  node: Article
}

# Properties for creating an article by a specified user
input ArticleInputType {
  # Body of the article
  body: String

  # Title of the article
  title: String!

  # Email address of the user
  user_email: String!
}

type Mutation {
  # Create an article by the specified user
  createArticle(article: ArticleInputType): Article
}

pp# Information about pagination in a connection.
type PageInfo {
  # When paginating forwards, the cursor to continue.
  endCursor: String

  # When paginating forwards, are there more items?
  hasNextPage: Boolean!

  # When paginating backwards, are there more items?
  hasPreviousPage: Boolean!

  # When paginating backwards, the cursor to continue.
  startCursor: String
}

type Query {
  user(email: String!): User
}

type User {
  articles(
    # Returns the elements in the list that come after the specified global ID.
    after: String

    # Returns the elements in the list that come before the specified global ID.
    before: String

    # Returns the first _n_ elements from the list.
    first: Int

    # Returns the last _n_ elements from the list.
    last: Int
  ): ArticleConnection
  email: String!
}
`
```

ここまで来れば、あとは `index.js` をサーバとして起動すれば終わりです。

```
$ (cd mock_app && npm install && node start index)
GraphQL mock server is running!!1
```

次のように、サーバがGraphQLのクエリを受け取りつつ、自分で書いたダミーデータがサーバから返ってくるようになります。これでスタブサーバが手に入ったので、フロントエンドとバックエンドを並行開発していくことができます。

[f:id:kymmt90:20171223175753p:plain]

## まとめ

Railsでgraphql-rubyを使っている場合に、Apolloのツールセットを使ってGraphQLのモックサーバを作る方法について説明しました。Apolloが便利なので、わりと簡単にセットアップできました。

GraphQL APIの開発方法はまだ模索段階なので、2018年はこれを業務に取り入れてみて気になる点がないか確かめていきたいという気持ちです。

## 参考

- [Build a GraphQL server with Node.js | Apollo Server](https://www.apollographql.com/docs/apollo-server/)
- [Mocking | GraphQL Tools](https://www.apollographql.com/docs/graphql-tools/mocking.html)
- [Tracking Schema Changes with GraphQL-Ruby - Robert Mosolgo](http://rmosolgo.github.io/blog/2017/03/16/tracking-schema-changes-with-graphql-ruby/)
