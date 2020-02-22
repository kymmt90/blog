<!-- Web 上のリソースとその表現 -->

RSpec で request spec を書くとき、`get "/users/:id.json"` と書くかわりに `get "/users/:id"` と書くとエラーになりました。

```
ActionController::UnknownFormat:
  UsersController#show is missing a template for this request format and variant.
```

リソース `/users/:id` に対して拡張子で指定しないならば、HTTP リクエストのヘッダに `Accept: application/json` をつけて、クライアントが利用したいデータ形式を指示する必要があります。

そもそもなぜこういうふうになっているのかを整理しました。

# リソース

リソースとは Web 上に存在する情報そのものであり、URI (Uniform Resource Indicator) で指し示せます。たとえば次のようなリソースが考えられます。

- 人のプロフィール
  - URI 例：`http://example.com/users/john`
- ブログ記事
  - URI 例：`http://example.com/entries/2017/01/01`

わかりやすい URI でリソースを指定することで、どのような情報なのかが人間にとってわかりやすくなります。なお、ここでは、その情報がどのような見た目（表現）になっているかについては言及していません。

また、リソースに対して、HTTP のメソッド (GET, POST, PUT, PATCH, DELETE) を使うことで CRUD をはじめとする各種操作が実行できます。

# リソースの「表現」

「表現」という言葉はリソースがどのような形式のデータになって、サーバ／クライアント間で通信されるかを指しています。表現には次のようなものがあります。

- メディアタイプ
  - HTML, XML, JSON, JPEG, PDF など
- 言語
  - 日本語、英語、中国語など
- 文字エンコーディング
  - UTF-8, Shift_JIS など

## リソースは複数の「表現」をとれる

あるリソースは次のように複数の「表現」をとりえます。

- 人のプロフィールが HTML, JSON, PDF で表現できる
- ブログ記事が日本語、英語で表現できる

## リソース表現の指定方法

HTTP を介したサーバとのやりとりにおいて、リソースの表現をどう指定するかについては次のような方法があります。

- クエリ文字列
  - `GET http://example.com/users/john?format=json` で人のプロフィールの JSON 表現を得られる
- 拡張子
  - `GET http://example.com/entries/2017/01/01.en` でブログ記事の英語表現を得られる
- コンテントネゴシエーション
  - `GET http://example.com/users/john` のリクエストヘッダに `Accept: application/pdf` を利用するとプロフィールの PDF 表現を得られる
  - ほかには `Accept-Language` や `Accept-Charset` など

# リソースと表現を分離する利点

リソースと表現の関係を疎にして、リソースが複数の表現をとれるようにすると、さまざまなクライアントが求める形式のデータを統一された HTTP のインタフェースで提供できるようになります。また、拡張性の面でも利点があります。

# 参考資料

[asin:4774142042:detail]
