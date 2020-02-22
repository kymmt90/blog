<!-- OpenAPI 3ドキュメントも使えるSchemaConformist 0.3.0をリリースした -->

[https://rubygems.org/gems/schema_conformist/versions/0.3.0:embed:cite]

これまでのバージョンの差分は[OpenAPI 3](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md)ドキュメントが使えるようになった点です。OpenAPI 3に対応した[Committee](https://github.com/interagent/committee) v3の機能を使うことで、integration test/request spec実行中にOpenAPI 3ドキュメント中のスキーマに基づいたJSONレスポンスのバリデーションを自動実行できるようになりました。

OpenAPI 3についてはRubyKaigi 2019での@ota42yさんの発表資料や、WEB+DB PRESS Vol.108の特集1が参考になります。

[https://speakerdeck.com/ota42y/how-to-use-openapi3-for-api-developer-rubykaigi-2019:embed:cite]

[https://gihyo.jp/magazine/wdpress/archive/2019/vol108:embed:cite]

以上の対応に伴って、Committeeの機能を利用して自動でドキュメントフォーマットが判別できるようになったので、オプション `driver` の指定は不要になりました。また、オプション `schema_path` については必須とすることにしました。これは、`schema_path` を指定しなかったときにデフォルトで入るパス（`public/swagger.json` など）がとくに一般的なものではないことと、`driver` をオプションとして渡さなくなったことによります。

他には、`ignored_api_paths` は正規表現だけでなくふつうのStringも渡せるようにしました。渡された文字列と前方一致するパスを検索して、そのパスで表されるエンドポイントについてはテスト実行時にバリデーションをスキップします。

もし仮に使っている人がいれば、なにかおかしいところがあったら教えてください。
