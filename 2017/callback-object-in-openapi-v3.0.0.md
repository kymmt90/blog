<!-- OpenAPI v3.0.0のCallback Objectについて調べた -->

2017年7月末リリースのOpenAPI v3.0.0に入った**Callback Object**という仕様がパッと見だとどう使うかわかりにくかったので、調べてみました。

Callback Objectの仕様は次のリンク先のとおりです。

[OpenAPI-Specification/3.0.0.md at master · OAI/OpenAPI-Specification](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#callback-object)

Callack Objectについて簡単に述べると、「OpenAPIドキュメントで記述しているエンドポイントに対してリクエストしたあと、こちらが指定したエンドポイントに対してリクエスト先がwebhookなどでコールバックするような場合についての仕様が記述できるもの」、です。

まだわかりにくいので、OpenAPI公式のリポジトリに置いてある次のサンプルを見てみます。

- [OpenAPI-Specification/callback-example.yaml at ccf01692e5a522514e0394db5b10f22d17f36bfa · OAI/OpenAPI-Specification](https://github.com/OAI/OpenAPI-Specification/blob/ccf01692e5a522514e0394db5b10f22d17f36bfa/examples/v3.0/callback-example.yaml)

まず、このYAML中のキー `post` 配下を見てみると次のようになっています（抜粋）。

```yaml
post:
  description: subscribes a client to receive out-of-band data
  parameters:
    - name: callbackUrl
      in: query
      required: true
      description: # ...
      schema:
        type: string
        format: uri
        example: https://tonys-server.com
  responses:
    '201':
      description: subscription successfully created
      content:
        application/json:
          schema:
            description: subscription information
            required:
              - subscriptionId
            properties:
              subscriptionId:
                description: this unique identifier allows management of the subscription
                type: string
                example: 2531329f-fb09-4ef7-887e-84e648214436
```

ここでは、

- `/streams` というエンドポイントに対して `callbackUrl` というパラメータとともにPOSTリクエストを投げることができる
- リクエストが成功すると `subscription`（購読）リソースが作成される

というエンドポイント仕様が記述されていることがわかります。

`parameters`, `responses` のさらに下の `callbacks` 配下にある記述が、今回着目するCallbacks Objectです（抜粋）。

```yaml
callbacks:
  onData:
    '{$request.query.callbackUrl}/data':
      post:
        requestBody:
          description: subscription payload
          content:
            application/json:
              schema:
                properties:
                  timestamp:
                    type: string
                    format: date-time
                  userData:
                    type: string
        responses:
          '202':
            description: # ...
          '204':
            description: # ...
```

これは、このAPIを提供している側（仕様書内では**API provider**と呼ばれています）はクライアント側が指定した `'{$request.query.callbackUrl}/data'` というURLに対して `requestBody` の内容でPOSTリクエストするようになるという記述です。

ここで、`$request.query.callbackUrl` のようなデータの指定方法は仕様書の [`Key Expression` の項](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#key-expression)に書いてあるURL, HtTPメソッド、HTTPリクエストのデータ、HTTPレスポンスの `Location` ヘッダが取得できる「実行時式」(runtime expression) です。

`responses` には返すべきステータスコードなどが記述できます。ここでいうエンドポイント `'{$request.query.callbackUrl}/data'` を持つホストは `responses` に書いた記述を満たすようにレスポンスを返す必要があります。

以上のようにして、Callback Objectを使うことで、あるエンドポイントに付随したAPI provider側からのコールバックについての仕様も記述できるようになります。
