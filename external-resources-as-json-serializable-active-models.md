<!-- 外部サービスのリソースをJSONシリアライザブルなActive Modelとして表現する -->

RailsでWeb APIを作っていて、外部のサービスからリソースを取得し、DBには保存しないもののレスポンスに含めてクライアントに返したい、ということがありました。このとき次のモジュールが役立ったので紹介します。

- [`ActiveModel::Model`](https://railsguides.jp/active_model_basics.html#model%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB)
- [`ActiveModel::Attributes`](https://api.rubyonrails.org/classes/ActiveModel/Attributes.html)
- [`ActiveModel::Serializers::JSON`](https://railsguides.jp/active_model_basics.html#activemodel-serializers-json)

## モジュールの説明

`ActiveModel::Model` はActive Recordとも互換性のあるインタフェースでRails上のモデルとして扱える機能がいろいろ入るモジュールです。`ActiveModel::Attributes` は[Attributes API](https://y-yagi.tumblr.com/post/140725723370/rails-5%E3%81%AEactive-record-attributes-api%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6)を提供するモジュールです。最後の `ActiveModel::Serializers::JSON` は有名な[ActiveModelSerializers](https://github.com/rails-api/active_model_serializers) gemと名前は似ているのですが別物の、[rails/rails](https://github.com/rails/rails)の `activemodel` gem内に含まれるモジュールです。

## 実現方法

POROに `ActiveModel::Serializers::JSON` をincludeして `render :json` に渡すと、Attributes APIの `attribute` で定義した属性からなるJSONをシリアライズできるようになります。これを利用して、次のようなクラスを作りました。

まず、外部サービスから得られるリソースを表すクラスを作り、上述したモジュールをincludeします。

```ruby
class ExternalServiceResource
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON
end
```

次に、`ExternalServiceResource` をもとに具体的なリソースを表すクラスを作ります。ここでは外部ブログサービスから記事リソースを取得しているとします。

```ruby
class Article < ExternalServiceResource
  attribute :title, :string
  attribute :content, :string
  attribute :status, :integer
  attribute :created_at, :datetime

  DRAFT = 0
  PUBLIC = 1
  DELETED = 2

  def unavailable?
    status.in?([DRAFT, DELETED])
  end
end

class Blog
  # ...

  def articles
    raw_response = client.articles
    raw_articles = JSON.parse(raw_response)['articles']

    raw_articles
      .map { |raw_article| Article.new(raw_article) } # 生JSONをモデルオブジェクトへ変換
      .reject(&:unavailable?)
  end

  private

  def client
    # 外部サービスのWeb APIを叩いてJSONを返すクライアント
  end
end
```

これらを使うと、外部サービスのリソースも含んだJSONを返すエンドポイント自体は、シンプルに実装できます。

```ruby
class ArticlesController < ActionController::API
  # articles#index で外部ブログ記事のうちpublicなものを取得できる
  def index
    render json: { articles: blog.articles }
  end

  private

  def blog
    # Blogのインスタンスを返す
  end
end
```

## pros/cons

この方法の利点は、サードパーティgemの[ActiveModelSerializers](https://github.com/rails-api/active_model_serializers)を使うのに比べると、Railsのモジュールだけで実現できてシンプルというところや、モデルとして外部リソースを表現できるので、そのリソースに関するロジックをモデルに置くことができるという点が挙げられます。

逆に、欠点として、自前実装になるのでうまくやらないと負債になりそうな点や、リソースの構造がネストするときに、Attributes APIでは [`ActiveModel::Type.register`](https://api.rubyonrails.org/classes/ActiveModel/Type.html#method-c-register) を使って自前の型を定義していくと実装がやや面倒という点です。ただし、ネストしているリソースについて型を定義せず、次のように型を指定せずに属性を定義することもできるにはできます。

```ruby
# Article#author に入れるためのモデル
class Author < ExternalServiceResource
  attribute :name
  # ...
end

class Article < ExternalServiceResource
  attribute :title, :string
  attribute :content, :string
  attribute :status, :integer
  attribute :created_at, :datetime

  # Authorのオブジェクトを入れるつもりだが、型指定はとくになし
  attribute :author

  # ...
end
```
