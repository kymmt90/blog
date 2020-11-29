<!-- authorization code grantに沿ったDoorkeeperのコードリーディング -->

さまざまな都合により、OAuth 2のプロバイダになるための[Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper)というgemのコードを読むことがしばしばある生活を送っている。

似た名前のモジュールやクラスが多く、読むたびに混乱しているので、authorization code grantでアクセストークンを取得するときの登場するクラス／モジュールと流れをあらためて自分なりに整理した。基本的に自分用であって、網羅的ではない。

# 前提

2020-11-28現在での最新版である[Doorkeeper 5.5.0.rc1](https://github.com/doorkeeper-gem/doorkeeper/tree/v5.5.0.rc1)を読む。authorization code grantが正常に通るときのパスだけを見る。

RailsのAPIモードは無効とし、Doorkeeperの設定`resource_owner_authenticator`で渡すブロックでは特定のリソースオーナーの認証に常に成功しているとする。本来は認証を実際に実行し、失敗すれば再認証させるべき。

以降の文章では、Doorkeeperが提供する名前空間のうち`Doorkeeper`は`D`と省略する。

# Doorkeeper用エンドポイントの登録

DoorkeeperはRails Engineであり、ルーティングを拡張するための`use_doorkeeper`というメソッドが提供されている。このメソッドでルーティングを拡張するまでの流れは次のとおり。

## 主に登場するクラス／モジュール

|名前|概要
|---|---
|`D::Engine`|Rails EngineとしてRailtieのinitializerを設定する
|`D::Rails::AbstractRouter`|Doorkeeper用ルーティング拡張クラスのためのインタフェースを表す
|`D::Rails::Routes`|親アプリのルーティングにDoorkeeper用のエンドポイントを追加するメソッドを持つ

## ルーティングの設定フロー

- `D::Engine`が`"doorkeeper.routes"`としてinitializerを登録する
  - 親アプリの初期化時に`D::Rails::Routes.install!`を実行する
    - `ActionDispatch::Routing::Mapper`に`use_doorkeeper`をincludeすることでルーティングの設定で`use_doorkeeper`できるようにする
- Doorkeeper利用時に親アプリのconfig/routes.rbで`use_doorkeeper`する
  - `D::Rails::Routes#generate_routes!`を実行する
  - Railsの[`scope`](https://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-scope)を呼び出して、その中で `D::Rails::AbstractRouter#map_route`によってDoorkeeperのエンドポイントを定義する
    - `D::Rails::Routes`のprivateメソッドで個々のルーティングが定義されており、それらのメソッドを`send`で呼び出している

# authorization code grantの認可リクエスト

authorization code grantでは、あるクライアントとして認可リクエストを送り認可コードを得る必要がある。

## 主に登場するクラス／モジュール

`D::Request`と`D::OAuth`それぞれの配下に似たような名前のモジュールやクラスがあって混乱する。

### コントローラ関連

|名前|概要
|---|---
|`D::AuthorizationsController`|`/oauth/authorize`へのリクエストがルーティングされるコントローラ
|`D::Helpers::Controller`|Doorkeeperの設定をもとにした値などを取得するためのメソッドが集められたモジュール

### 認可リクエスト

|名前|概要
|---|---
|`D::OAuth::PreAuthorization`|認可リクエストのパラメータのラッパークラス。バリデーションを実行したりscope文字列をパースする
|`D::Validations`|`D::OAuth::PreAuthorization`や `D::OAuth::BaseRequest`でのバリデーションの仕組みを提供するモジュール
|`D::Models::AccessTokenMixin`|アクセストークンに関するロジックを提供するモジュール。ORマッパーへの依存を減らすために、アクセストークンのモデルからは切り離されている
|`D::OAuth::Hooks::Context`|認可前後のフック関数に渡すコンテキストを表すクラス
|`D::Server`|認可サーバとして必要なリクエスト、パラメータ、現在のリソースオーナーやクライアントへアクセスするためのメソッドを提供するクラス。コントローラをコンテキストとして渡して使う
|`D::Request`|`response_type`を渡して、対応する認可／トークンリクエストを処理するストラテジクラスを返すためのメソッドを提供するクラス
|`D::Request::Strategy`|リクエストをもとに認可するストラテジクラスの基底クラス。`#authorize`というメソッドを提供する
|`D::Request::Code`|`D::Request::Strategy`を継承するauthorization code grantのストラテジ。`#request`では`D::OAuth::CodeRequest`はインスタンスを返す。`D::Request::Strategy#authorize`を呼ぶと、そのインスタンスに`#authorize`を委譲する
|`D::OAuth::CodeRequest`|認可コードを`D::OAuth::Authorization::Code`のインスタンスとして生成して、認可エンドポイントのレスポンスを作成する
|`D::OAuth::Authorization::Code`|認可コードのラッパークラス。認可コードを発行しグラントを記録するテーブルへ保存する`#issue_token!`を提供する
|`D::OAuth::CodeResponse`|認可エンドポイントのレスポンスのラッパークラス。コールバックまたはネイティブアプリ向けの方法で認可コードをクライアントに渡すために必要なデータを提供する
|`D::GrantFlow`|`D::GrantFlow::Registry`にOAuthのグラントの種類とDoorkeeperのストラテジークラスの対応を登録するモジュール
|`D::GrantFlow::Flow`|`D::GrantFlow`で登録する対応を表すクラス

## 承諾画面の表示

`GET /oauth/authorize`を呼び出すときの流れ。

まず、リソースオーナーのデータを取得する。

- `D::AuthorizationsController#new`へルーティングする
- `before_action :authenticate_resource_owner!`を実行する
- `D::Helpers::Controller#current_resource_owner`を実行する
- 親アプリのconfig/initializers/doorkeeper.rbなどで`D.configure`で設定する `authenticate_resource_owner`のブロックを呼び出し、返り値を`@current_resource_owner`へ入れる

次に、認可エンドポイントへのリクエストを検証する。

- `D::AuthorizationsController#new`で`#pre_auth`を呼び出す
  - Doorkeeperの設定、認可リクエストのパラメータ、`@current_resource_owner`をもとに`D::OAuth::PreAuthorization`のインスタンスを作る
- `pre_auth#authorizable?`を実行する
  - `D::Validations#validate`を実行する
    - あらかじめ`D::OAuth::PreAuthorization`の序盤で定義している`validate :client_id, ...`などはこのモジュールのメソッドであり、バリデーションを登録している
    - 登録されたバリデーションを順番に実行する
      - バリデーションメソッドは`validate_#{属性名}`を`send`する
      - これらも`D::OAuth::PreAuthorization`にあらかじめ定義してある
      - それぞれのバリデーションはOAuth 2に基づいたもの

リクエストが妥当であれば、クライアントへ承諾画面を返す。

- `authorizable?`であれば`render_success`を実行する
  - `D::Helpers::Controller#skip_authorization`を実行する
    - 認可スコープの承諾画面を表示するか否かを決める
    - Doorkeeperの設定の`skip_authorization`のブロックを実行する
  - `#matching_token`を実行する
    - `D::Models::AccessTokenMixin#matching_token_for`ですでに対象のクライアントとリソースオーナーの組み合わせで作成済みのアクセストークンを探す
  - `#skip_authorization`か`#matching_token`のどちらかがtrueなら、すぐに`authorize_response`で作成する認可済みのレスポンスを返す
  - そうでなければ`:new`をレンダリングする
    - app/views/doorkeeper/authorizations/new.html.erbをレンダリングする
    - リクエストしているスコープを表示し、承諾もしくは拒否を求める画面

## 認可コードの発行

承諾画面で承諾をサブミットし、`POST /oauth/authorize`を呼び出すときの流れ。

認可コードを生成する。

- `D::AuthorizationsController#create`にルーティングする
- `#authorization_response`を呼び出す
  - `pre_auth`をもとに`D::OAuth::Hooks::Context`のインスタンスを作る
  - フック`before_successful_authorization`を実行する
  - `#strategy`を呼び出す
    - `#server`を呼び出す
      - `D::Helpers::Controller#server`を呼び出す
      - コントローラ自身をcontextとして渡してインスタンスを作る
    - `Server#authorization_request`を呼び出す
      - 引数に `pre_auth.response_type`を渡す。いまは`"code"`
      - `D::Request.authorization_strategy`から`"code"`に対応する認可strategyクラスを取得する
        - `D::GrantFlow`で各グラントのstrategyクラスなどは設定済み
        - Doorkeeperの設定にあるgrantから対応するものを`D::GrantFlow::Flow`として取り出す
        - `request_type_strategy`を呼び出して`D::Request::Code`を返す
        - `D::Request::Code`にserverを渡してストラテジーオブジェクトを作る
    - `strategy`として`D::Request::Code`のオブジェクトが得られた
  - `strategy`である`D::Request::Code#authorize`を実行する
    - `D::Request::Strategy#authorize`→`#request`→`D::OAuth::CodeRequest#authorize`と委譲される
    - `pre_auth`と`resource_owner`を引数に取って`D::OAuth::CodeRequest`のインスタンスを作る
    - `D::OAuth::CodeRequest#authorize`で`D::OAuth::Authorization::Code`のインスタンスを作り`#issue_token!`を呼び出す
      - 認可コードを生成して、既定のActive Recordモデルを通じてテーブルに保存する
    - `D::OAuth::CodeResponse`のインスタンスを`pre_auth`と`D::OAuth::Authorization::Code`のインスタンスを渡して作り、returnする

認可コードをコールバックURIに付与するかネイティブアプリ用画面のURIのパラメータとして返す。

- 認可コードを返すために`redirect_or_render authorization_response`する
  - `D::OAuth::CodeResponse`のインスタンスである`authorization_response`が`redirectable?`なら、そのURIへリダイレクトする
  - 認可コードのときは常にtrueなので、oobであればoob用のURIに、それ以外は設定済みのURIに、認可コードをパラメータとして付けてリダイレクトする
    - oobのとき`D::OAuth::Authorization::Code#oob_redirect`をもとにリダイレクトし、app/views/doorkeeper/authorizations/show.html.erbをレンダリングする

# トークンエンドポイント

## 主に登場するクラス／モジュール

認可エンドポイントで登場したものは省略。

|名前|概要
|---|---
|`D::TokensController`|`/oauth/token` へのリクエストがルーティングされるコントローラ
|`D::Request::AuthorizationCode`|`D::Request::Strategy`を継承するauthorization code grantのストラテジ。`#authorize`を提供する。`Strategy`での`#authorize`の`#request`への委譲時に`D::OAuth::AuthorizationCodeRequest`を生成する。そのときに`#grant`の呼び出しを通じて認可コードの検証を実行する
|`D::OAuth::BaseRequest`|トークンエンドポイントへのリクエストの基底クラス。`#authorize`でトークンレスポンスの生成と前後のフックの実行を提供する
|`D::OAuth::AuthorizationCodeRequest`|authorization code grantでのトークンエンドポイントへのリクエストを表すクラス。PKCEのchallengeの検証も担う。フック`D::BaseRequest#before_successful_response`をオーバーライドしてアクセストークンを作成している
|`D::Models::AccessGrantMixin`|アクセスグラントに関するロジックを提供するモジュール。ORマッパーへの依存を減らすために、アクセスグラントのモデルからは切り離されている
|`D::OAuth::TokenResponse`|トークンエンドポイントのレスポンスのラッパークラス。ステータスコードやレスポンスのJSONを取得できる

## アクセストークン取得の流れ

`POST /oauth/token`を呼び出して、アクセストークンを含むJSONをレスポンスとして得る。

- `D::TokensController#create`にルーティングする
- `#authorize_response`を呼び出す
    - 認可エンドポイントと同じ流れで`server`を取得し`D::Server#token_request`を呼び出す
      - 引数として`params[:grant_type]`を渡すが、ここでは`"authorization_code"`
      - `D::Request.token_strategy`であらかじめ登録済みのstrategyから`grant_type_strategy`として`D::Request::AuthorizationCode`を取得してreturnする
      - そのクラスのインスタンスを得る
    - `D::Request::AuthorizationCode#authorize`を呼び出す
      - `D::Request::Strategy#authorize`→`#request`→`D::OAuth::AuthorizationCodeRequest#authorize`→`D::OAuth::BaseRequest#authorize`と委譲される
      - `D::Request::AuthorizationCode#request`で`grant`呼び出し時に認可コードをもとに`oauth_access_grants`のレコードを探している
        - `D::Models::AccessGrantMixins.by_token`で実行している
      - `D::OAuth::BaseRequest`は`D::OAuth::Validations`をincludeしているので`D::OAuth::PreAuthorization`と同じく宣言済みのバリデーションを`valid?`で実行できる
      - `valid?`ならトークンレスポンスを返す
        - `D::OAuth::AuthorizationCodeRequest#before_successful_response`で認可コードをrevokeしてアクセストークンを生成する
        - `D::OAuth::TokenResponse`にアクセストークンを渡してインスタンスを作る
      - トークンレスポンスのオブジェクトをreturnする
- `D::TokensController#create`でトークンレスポンスから`#body`と`#status`でトークンレスポンスのJSONのステータスを取得してrenderする

---

# 所感

DoorkeeperはOAuthの各グラントに対応し、またORマッパー非依存になるような設計で作られていて、さまざまな要件のもとでOAuth 2サーバを作りたいという希望にかなうライブラリとなっている。そのぶん、やっていることが複雑であったりもするし、細かいカスタマイズを施したくなる場面もたびたびある。また、認可という場合によってはクリティカルな機能に関わるライブラリでもある。そういう点で、ただのブラックボックスとして扱うよりは、できるだけ内部を知っておいたほうがいいだろうと思う。どのライブラリにも言えることではあるが、アプリケーション開発の延長として、ライブラリの新バージョンリリース時などのタイミングでこまめにコードを読むことを継続していく。
