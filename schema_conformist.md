<!-- テスト時にAPIドキュメントのスキーマ定義からレスポンスのJSONを自動でバリデーションするgemを作った -->

あらかじめ書いた[JSON Hyper Schema](http://json-schema.org/latest/json-schema-hypermedia.html)/[OpenAPI 2.0](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md)のAPIドキュメントにおけるレスポンスのスキーマ定義をもとに、APIモードのRailsでHTTPリクエストを発行するテストを実行すると、自動でレスポンスのJSONをバリデーションしてくれる**SchemaConformist**というgemを作りました。

[https://github.com/kymmt90/schema_conformist:embed:cite]

といっても、次の記事でやっていることをgem (Rails plugin) として切り出して、JSON Hyper Schemaにも対応させたあと、いくつか設定できるようにしただけのものです。

- [RSpecのrequest specでCommitteeを使ってレスポンスJSONを自動的にバリデーションする - blog.kymmt.com](http://blog.kymmt.com/entry/auto-json-validation-with-committee)

## 使いかた

インストールは、Railsのプロジェクトで `Gemfile` に `gem 'schema_conformist'` を追加すれば終わりです。

あとは、テスト実行前に次のパスへAPIドキュメントを置いておきます。

- JSON Hyper Schemaを使うとき
  - `public/schema.json`
- OpenAPI 2.0を使うとき
  - `public/swagger.json`
  - OpenAPI 2.0を使うときは設定 `schema_conformist.driver` に `:open_api_2` を指定（後述します）

これで、Railsのintegration testやRSpecのrequest specでHTTPリクエストを発行したときに、APIドキュメントに書いたレスポンスのJSON Schemaにもとづいて、自動で実際のレスポンスのバリデーションが実行されるようになります。

テストを実行したときにどのような結果になるかについては、次のエントリをご覧ください。

- [Web APIのレスポンスJSONをCommittee + OpenAPIでバリデーションして仕様と実装の乖離を防ぐ - blog.kymmt.com](http://blog.kymmt.com/entry/use-committee-and-openapi-to-validate-response-jsons)

バリデーションNGのときは次のようなエラーが出ます。

```
  1) Users GET /users/:id レスポンスがAPI定義と一致する
     Failure/Error: assert_schema_conform

     Committee::InvalidResponse:
       Invalid response.

       #: failed schema #/properties//users/{userId}/properties/GET: "email" wasn't supplied.
```

### オプション

オプションはひとまず次のものを用意しました。[README](https://github.com/kymmt90/schema_conformist/blob/master/README.md)もご覧ください。

- `schema_conformist.driver`
  - JSON Hyper SchemaとOpenAPI 2.0どちらを使うか
    - `:hyper_schema` か `:open_api_2` を指定
  - デフォルトはJSON Hyper Schema（深い意味はないです…）
- `schema_conformist.ignored_api_paths`
  - バリデーションしないAPIパスの正規表現のリスト
  - デフォルトは空
- `schema_conformist.schema_path`
  - API定義のファイルパス
  - デフォルトは上述のとおり

`config/environments/test.rb` あたりに次のように書いておけばOKです。

```ruby
config.schema_conformist.driver = :open_api_2
config.schema_conformist.ignored_api_paths << %r(\A/private)
config.schema_conformist.schema_path = Rails.root.join('path', 'to', 'swagger.json')
```

## 余談

このgemを作った理由の一つとして、José Valim氏の "Crafting Rails 4 Applications" を一通り読んだ結果、Rails pluginを作りたくなったというのがあります。Rails内部の仕組みを細かく見ていったり、Rails pluginでRailsを拡張していったりする本です。今回もいくつか参考にしました。

[asin:1937785556:detail]

---

<br>

以上です。興味のあるかたはご活用ください。
