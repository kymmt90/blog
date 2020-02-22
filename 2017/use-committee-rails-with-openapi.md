<!-- RSpecのrequest specでCommitteeを使ってレスポンスJSONを自動的にバリデーションする -->

この記事の続きのようなものです。

[http://blog.kymmt.com/entry/use-committee-and-openapi-to-validate-response-jsons:embed:cite]

## やりたいこと

Rails + RSpecでWeb APIのrequest specを書くときに、[Committee](https://github.com/interagent/committee)（と[Committee::Rails](https://github.com/willnet/committee-rails)）の `assert_schema_conform` を使って、レスポンスのJSONがOpenAPIドキュメントで定義したレスポンスのJSON Schemaと一致するかどうか**自動で**チェックできるようにします。つまり、次のようにrequest specを書いたら自動でJSONのバリデーションが走ります。

```ruby
describe 'User', type: :request do
  describe 'GET /users/:id' do
    it 'returns 200 OK' do
      get "/users/:id" # GETリクエスト発行後にJSONのバリデーションを自動で実行
    end
  end
end
```

## 前提

[前述した記事](http://blog.kymmt.com/entry/use-committee-and-openapi-to-validate-response-jsons)の内容を実施しているものとします。

使うソフトウェアのバージョンは次のとおりです。

- Rails 5.1.4
- Committee 2.0.0
- Committee::Rails 0.2.0

## 結論

先に結論を書いておくと、次のことをやればできます。

- `ActionDispatch::Integration::Session#process` を実行したあとにCommitteeの `assert_schema_conform` を実行する

やりかたは後述の「HTTPリクエスト発行後に `assert_schema_conform` を実行する」を見てください。

## request spec内でのHTTPリクエスト発行メソッドの正体を調べる

request specで `get`, `post` などのHTTPリクエストメソッドを発行したときに `assert_schema_conform` を実行したいので、まずはこれらのHTTPリクエスト発行メソッドの正体を調べます。

結論としては、これらのメソッドの実体は、RailsのAction Dispatch（以下AD, `AD` とします）における `AD::Integration::Session` という結合テスト時のHTTP通信セッション管理用クラスが持つメソッド `#process` です。このメソッドは次のようにHTTPメソッド、パス、パラメータなどHTTPリクエストを発行するのに必要なデータを受け取って、実際にリクエストを発行します。

```ruby
# see: https://github.com/rails/rails/blob/d79e102bfaefc0dce843a73a48456831bd7848b7/actionpack/lib/action_dispatch/testing/integration.rb#L204
def process(method, path, params: nil, headers: nil, env: nil, xhr: false, as: nil)
  # ...
end
```

`AD::Integration::Session#process` はモジュール `AD::integration::RequestHelpers` で定義されている `get`, `post` などのヘルパーメソッドから呼び出されています。`get` の例を引用します。

```ruby
# see: https://github.com/rails/rails/blob/d79e102bfaefc0dce843a73a48456831bd7848b7/actionpack/lib/action_dispatch/testing/integration.rb#L17-L19
module ActionDispatch
  module Integration #:nodoc:
    module RequestHelpers
      # Performs a GET request with the given parameters. See ActionDispatch::Integration::Session#process
      # for more details.
      def get(path, **args)
        process(:get, path, **args)
      end
      # ...
```

モジュール `AD::integration::RequestHelpers` はクラス `AD::Integration::Session` で `include` されています。

モジュール `AD::Integration::Runner` は結合テストを実行するために `AD::Integration::Session` を使ってHTTP通信のセッションを開きます。そして、`get`, `post` などのメソッド呼び出しを `AD::Integration::Session` へ委譲するメソッドを動的に定義しています。`AD::Integration::Session` は `AD::Integration::RequestHelper` を `include` しているので、委譲されてきたメソッド呼び出しを処理することができます。

```ruby
# see: https://github.com/rails/rails/blob/d79e102bfaefc0dce843a73a48456831bd7848b7/actionpack/lib/action_dispatch/testing/integration.rb#L343-L354
module ActionDispatch
  module Integration
    # ...
    module Runner
      %w(get post patch put head delete cookies assigns follow_redirect!).each do |method|
        define_method(method) do |*args|
          # reset the html_document variable, except for cookies/assigns calls
          unless method == "cookies" || method == "assigns"
            @html_document = nil
          end

          # 注：integraion_session が Session のインスタンス
          integration_session.__send__(method, *args).tap do
            copy_session_variables!
          end
        end
      end
    # ...
```

[rspec-rails](https://github.com/rspec/rspec-rails)では、[モジュール `RSpec::Rails::RequestExampleGroup` でモジュール `AD::Integration::Runner` を `include` しています](https://github.com/rspec/rspec-rails/blob/e8054a1cd03044f725030fe8315952cf3799a395/lib/rspec/rails/example/request_example_group.rb#L8)。また、rspec-railsはrequest specのときに[モジュール `RSpec::Rails::RequestExampleGroup` を `include` します](https://github.com/rspec/rspec-rails/blob/2fb410b2670fdaf22f6bd2d0b8d67f9d1b78334d/lib/rspec/rails/configuration.rb#L47)。これにより、request specでは `get`, `post` などが使えるようになっています。

## HTTPリクエスト発行後に `assert_schema_conform` を実行する

ここまで把握したら、あとは `Session#process` を実行したあとに `assert_schema_conform` を差し込めばよさそうです。他にいいやりかたがあるかもしれませんが、今回は次のようにしました。

```ruby
# spec/support/assert_schema_conform_available.rb
# CommitteeRailsOpenapi2 は前回記事参照
module AssertSchemaConformAvailable
  include CommitteeRailsOpenapi2

  def process(*args)
    super *args
    assert_schema_conform
  end
end

class ActionDispatch::Integration::Session
  prepend AssertSchemaConformAvailable
end
```

まず、`#process` を定義したモジュール `AssertSchemaConformAvailable` を作り、継承チェーンの上位に `process` があるとして、そのメソッドを呼んだあとに `assert_schema_conform` を単純に差し込んでいます。そして、このモジュールを `AD::Integration::Session` に `prepend` することで、このモジュールが継承チェーンにおいて `AD::Integration::Session` の下位に入り、request specから `get` や `post` を呼んだときに `AssertSchemaConformAvailable#process` を呼べるようにしています。

あとは `spec/rails_helper.rb` でこのファイルを `require` しておけば、普通にrequest specを書くだけで、OpenAPIドキュメントに基づいて自動でレスポンスJSONをバリデーションできるようになります。

## その他

- OpenAPIドキュメントに書いていないパスがあれば `AssertSchemaConformAvailable#process` の中で除外しておく
- OpenAPIドキュメントをファイル分割して書いて必要なときに結合する運用のときは、request spec実行前後でドキュメントを自動作成／削除すると便利そう

## 参考

この記事での試みはこちらに影響されております。

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">assert_schema_conform、毎回書くの面倒なのでもう get とか post とかで自動的に呼んじゃうともっと便利です。(多分 example 増やすよりテスト速度的にもお得</p>&mdash; Takafumi ONAKA (@onk) <a href="https://twitter.com/onk/status/912328830609629187?ref_src=twsrc%5Etfw">2017年9月25日</a></blockquote> <script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
