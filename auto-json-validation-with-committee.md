<!-- Web APIのレスポンスJSONをCommittee + OpenAPIでバリデーションして仕様と実装の乖離を防ぐ -->

APIドキュメントに書いた[JSON Schema](http://json-schema.org)と実際に実装したWeb APIのレスポンスJSONが一致するかバリデーションするための**Committee**というgemがあります。また、このCommitteeをRailsプロジェクト中のテストから使うための**Committee::Rails**というgemがあります。

- [interagent/committee: A collection of Rack middleware to support JSON Schema.](https://github.com/interagent/committee)
- [willnet/committee-rails: rails and committee are good friends](https://github.com/willnet/committee-rails)

CommitteeはAPIドキュメントの形式として[JSON Hyper Schema](http://json-schema.org/latest/json-schema-hypermedia.html)と[OpenAPI 2.0](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md)に対応しています。また、APIエンドポイントを叩いたときのレスポンスJSONがドキュメントで定義したJSON Schemaと一致したかを確認するアサーションメソッド `assert_schema_conform` を持っているので、このメソッドを使ってAPIドキュメントの実際の動作の乖離を未然に防ぐことができます。

今回はOpenAPI 2.0の形式で書いたAPIドキュメントを使って、Railsで作ったAPIのエンドポイントからのレスポンスをRspecのテストでバリデーションしてみます。

## 使用するライブラリのバージョン

ライブラリのバージョンは次のものとします。

- Commitee 2.0.0
- Commitee::Rails 0.2.0

## 例のAPI仕様

今回、次のようなAPIエンドポイントを持つ単純なアプリケーションを考えます。

- `GET /users/{userId}`

このエンドポイントはステータスコード200で `userId` のIDを持つユーザを返します。ここで、ユーザは次のような属性を持つデータとします。

|属性名|必須|
|--|--|
|`id`|○|
|`email`|○|
|`name`|○|
|`age`||

すなわち、レスポンスのJSONは次のような形となります。

```json
{
  "id": 1,
  "email": "foo@example.com",
  "name": "John Doe",
  "age": 25
}
```

## OpenAPIドキュメントの記述

上述した仕様に基づいて、次のようなOpenAPI 2.0形式のドキュメントを書きます。

```json
{
  "swagger": "2.0",
  "info": {
    "version": "1.0.0",
    "title": "Committee Rails Sample",
    "license": {
      "name": "MIT"
    }
  },
  "host": "example.com",
  "schemes": [
    "http"
  ],
  "consumes": [
    "application/json"
  ],
  "produces": [
    "application/json"
  ],
  "paths": {
    "/users/{userId}": {
      "get": {
        "summary": "get users",
        "operationId": "userShow",
        "tags": [
          "users"
        ],
        "parameters": [
          {
            "name": "userId",
            "in": "path",
            "description": "user ID",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "A user",
            "schema": {
              "$ref": "#/definitions/User"
            }
          }
        }
      }
    }
  },
  "definitions": {
    "User": {
      "required": [
        "id",
        "email",
        "name"
      ],
      "properties": {
        "id": {
          "type": "integer"
        },
        "email": {
          "type": "string"
        },
        "name": {
          "type": "string"
        },
        "age": {
          "type": "integer"
        }
      },
      "additionalProperties": false
    }
  }
}
```

ここでは次の点に注目してもらえればOKです。

- `GET /usres/{userId}` のレスポンスとして `definitions` 配下のデータ定義 `User` を使っている
- データ定義 `User` では `required` で必須パラメータを指定しつつ、`additionalProperties` に `false` を指定して記述したパラメータ以外が含まれることを禁じている

## Committee::RailsでOpenAPIを使う準備

Committee::RailsでOpenAPIを使うために、`Committee::Test::Methods#committee_schema` というメソッドをオーバーライドします。このメソッドはAPIドキュメントに書いたJSON Schemaで実際のJSONをバリデーションするときに、そのAPIドキュメントを読み込むメソッドです。Commitee::Railsでは `Commitee::Rails::Test::Methods#commitee_schema` でJSON Hyper Schemaのドライバを使うようにあらかじめオーバーライドしていますが、今回はOpenAPI 2.0のドライバを使いたいので、自前でオーバーライドし直します。

```ruby
# spec/support/committee_rails_openapi2.rb
module CommittteeRailsOpenapi2
  include Committee::Rails::Test::Methods

  def committee_schema
    @committee_schema ||=
      begin
        driver = Committee::Drivers::OpenAPI2.new
        schema_hash = JSON.parse(File.read(schema_path))
        driver.parse(schema_hash)
      end
  end

  def schema_path
    Rails.root.join('docs', 'swagger.json')
  end
end
```

ここでは、例としてRailsプロジェクトの `docs/swagger.json` に存在するOpenAPIドキュメントを読み込んでいます。

## テストの記述

ここまで来ると、上述の `commitee_schema` オーバーライドによって、APIエンドポイントが返すレスポンスがOpenAPIドキュメントに記述したJSON Schemaに一致するかどうかをRailsのテストで確認できるようになりました。テストは[Committee::RailsのREADME](https://github.com/willnet/committee-rails#usage)に書かれているものとまったく同じで、RSpecを使うと次のように書けます。

```ruby
# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users/:id' do
    let!(:user) { create(:user) }

    it 'レスポンスがAPI定義と一致する' do
      get "/users/#{user.id}"
      assert_schema_conform
    end
  end
end
```

もしレスポンス用テンプレートの記述を間違えて必須属性 `email` を含めなかった場合、次のようなエラーが出ます。

```
  1) Users GET /users/:id レスポンスがAPI定義と一致する
     Failure/Error: assert_schema_conform

     Committee::InvalidResponse:
       Invalid response.

       #: failed schema #/properties//users/{userId}/properties/GET: "email" wasn't supplied.
```

また、もしレスポンス用テンプレートの記述を間違えてOpenAPIドキュメントで定義していない属性 `phone` を含めた場合、次のようなエラーが出ます。

```
  1) Users GET /users/:id レスポンスがAPI定義と一致する
     Failure/Error: assert_schema_conform

     Committee::InvalidResponse:
       Invalid response.

       #: failed schema #/properties//users/{userId}/properties/GET: "phone" is not a permitted key.
```

さらに、 属性 `age` は必須としない定義にしているので、レスポンスに `age` を含めなくてもエラーにはなりません。

なお、注意点として、ライブラリの実装上、正常系（ステータスコード200〜300番台）のレスポンスだけテストでき、異常系（ステータスコード400〜500番台）についてはテストできません(([Committee::Rails::Test::Methods#assert_schema_conform](https://github.com/willnet/committee-rails/blob/32f9da847b22356a41f7eacf12948a953df2c6f7/lib/committee/rails/test/methods.rb#L55) と [Committee::ResponseValidator.validate?](https://github.com/interagent/committee/blob/c9941f7c42a7c5f5079ef8d5199512c7e1fc0eda/lib/committee/response_validator.rb#L12-L15) を参照))。

## まとめ

- Railsで作るWeb APIのレスポンスJSONがOpenAPIに定義したJSON Schemaと一致しているかをチェックするにはCommitteeとCommittee::Railsを使う
- OpenAPI 2.0の形式のドキュメントを読み込むように必要なメソッドをオーバーライドしておく必要がある
