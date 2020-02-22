<!-- graphql-rubyでGraphQL APIを作るときにテストをどう書いていくか -->

こういうのはどうかという最近の考えを書いておきます。とはいっても、だいたいは[graphql-rubyのドキュメント](http://graphql-ruby.org/schema/testing.html)に書いてあります。Rails + graphql-ruby + RSpecが前提です。

## 各フィールドのテスト

フィールドから正しく値を取得できるか、つまりRailsのモデルとgraphql-rubyとの連携が正しいかという点をテストします。次のようにスキーマのオブジェクトから型情報を取得して、`resolve`を実行します。

```ruby
# たとえば spec/graphql/types/user_type_spec.rb に書く
user_type = MySchema.types['User']
user = FactoryBot.create(:user, name: 'Foo')
expect(user_type.fields['name'].resolve(user, nil, nil)).to eq 'Foo' # nameフィールドが正しい値を取得できるかのテスト
```

## resolverの処理を切り出す

`resolve`を明示的に指定していて、さらに少し複雑な場合があると思います。

```ruby
Types::ArticleType = GraphQL::ObjectType.define do
  # ...
  field :something do
    type !types.String
    resolve ->(article, args, ctx) {
      # ref: https://github.com/Shopify/graphql-batch/blob/master/examples/association_loader.rb
      Loaders::AssociationLoader.for(Article, :comments).load(article).then do |comments|
        # articleとcommentsからなにかを生成する処理
      end
    }
  end
end
```

この場合、resolverの処理をクラスとして外に出し、そのクラスをテストすると見通しが少しよくなります。

これに関連して、graphql-rubyのドキュメントにおける["Testing"](http://graphql-ruby.org/schema/testing.html)のページの"Don't test the schema"という節を見ると、だいたい次のようなことが書いてあります。

- スキーマはテストしない
- フィールドのテストはresolverの処理を切り出して`app/models`配下に単機能のクラスとして置く
  - `#new`と`#value`だけ持つクラス
  - `#new`でフィールドが属する型に対応するオブジェクトを受け取る
  - `#value`でresolverの中にもともとベタ書きされていた処理を実行する
- GraphQLのスキーマとフィールド内の処理が疎になって便利

これは`app/models`配下にGraphQLだけで使いそうなクラスが混ざる点が気になるので、`app/models`配下には置かず`app/graphql/types/<型名>_fields`配下にフィールドごとにresolverを切り出します。

```
app
└ graphql
  └ types
    └ <型名>_fields
      └ <フィールド名>.rb
```

`<型名>_fields`配下のクラスは上述したgraphql-rubyのドキュメントにおけるものと同じような、`#value`だけをメソッドとして持つ単機能のクラスです。

ちょっと適当な例ですが、このようなクラスを使うとフィールドの定義は次のようになります。

```ruby
Types::ArticleType = GraphQL::ObjectType.define do
  # ...
  field :something do
    type !types.String
    resolve ->(article, args, ctx) {
      Loaders::AssociationLoader.for(Article, :comments).load(article).then do |comments|
        Types::ArticleFields::Something.new(article, comments).value
      end
    }
  end
end
```

## request specになにを書くか

request specでテストを書くと、スキーマが大きく／深くなるにしたがって、テスト中のクエリが大きくなり、さらに複数の種類を持つようになります。すると、必要な事前処理や期待値の準備が大変になり、メンテしづらくなります。

基本的には、request specにはGraphQL APIへのリクエストを受けるコントローラ内でのエラーケースに関するテストを書く、ぐらいがいいかと思います。たとえば認可されていないアクセスに対して401 Not Authorizedを返す処理をコントローラレベルでやっている場合、そのレスポンスをテストする、などです。
