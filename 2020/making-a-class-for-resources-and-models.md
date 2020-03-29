<!-- リソースとActive Recordのモデルのあいだの差異を吸収するアダプタを作る -->

Web APIのリソースとバックエンドで扱うモデル（特にActive Recordのモデル）に歴史的な事情で差異があり、単純にモデルからリソースへと変換できないとき、それらの差異を吸収するクラスを作って対応することがあったのでメモを残しておきます。

---

## 問題

あるWeb APIに、親リソース((リソースは「APIが返すデータの構造」ぐらいの意味合いとする))`author`が1:Nで持つ子リソース`book`の一覧だけを返すエンドポイント`GET /books`を追加しようとしていた((これはあくまでも例))。追加するエンドポイントが返すリソースの例を示す:

```
{
  "books": [
    {
   	  "id": 1
   	  "author_id": 1,
   	  "title": "Bar",
   	  "publisher": "Baz, Inc.",
   	  "released_at": "2020-01-01"
    },
	// ...
  ]
}
```

なお、従来から、親リソース`GET /authors`を取得するときには`books`も取得はできていたとする。また、既存のAPIリソースはActive Model Serializer (AMS)で生成しているとする。

このエンドポイントで返すリソースが持つフィールド、リソースに対応するActive Record (AR)のモデルの属性、データベース上の対応するテーブルのカラムには、それぞれ微妙にズレが見られた。具体的には次のような問題があった:

1. ARのモデルが持っている属性の一部だけがリソースの属性となる
1. テーブルのカラム名とリソースのフィールド名／モデルの属性名が異なる
1. APIリソースのフィールド名とARモデルのリレーション名が被っている

まず、ARのモデルが持っている属性、すなわち対応するテーブルが持っているすべてのカラムのうち一部だけがリソースの属性となっていた。この場合、リソースを表すJSONに変換するときにフィルタする必要がある。

```ruby
create_table :books do |t|
  t.column :title, :string
  t.column :release_date, :date
  t.column :memo, :string # リソースには含めない
  # ...
end
```

また、テーブルのカラム名をよりわかりやすくするために、その後に作られたモデルやAMSのシリアライザでは改名された属性名を使っているケースがあった。

```ruby
class Book < ApplicationRecord
  alias_attribute :title, :name
end

class BookSerializer < ActiveModel::Serializer
  def released_at
    object.release_date
  end
end
```

さらに、特殊な事例だが、ARのモデルではリレーションとして定義されている名前が、AMSで生成されるリソースではスカラーな値として提供されているケースがあった。

```ruby
class Book < ApplicationRecord
  belongs_to :publisher
end

class Publisher < ApplicationRecord
  has_many :books
end

class BookSerializer < ActiveModel::Serializer
  attributes :publisher

  def publisher
    object.publisher.name
  end
end
```

後述するが、このケースでAMSを使わないようにする場合、リソース用に加工したフィールドの値を作る必要がある。しかし、今回はリレーションとしてそのフィールドと同名のメソッドが存在するので、メソッド名に気をつけないと、そのリレーションを使っている他のコードが壊れてしまってうまくいかない。

今回は、既存のコードをできるだけ変えずにこれらの問題に対処しながら、エンドポイント`GET /books`を追加したいとする。

## リソースとモデルの間の差異を吸収する層を導入する

問題を解決するために、リソースとモデルの間の差異を吸収する層を導入する。今回はAMSを使わず実現した((内部事情))。POROにActive Modelを組み合わせて使う。

次のようにリソースのフィールドとモデルの属性のマッピングを持たせたクラスを書く。リソースだけで使うメソッドはモデルに書く。

```ruby
class Book < ApplicationRecord
  # ...

  concerning :Api do
    def publisher_name
      publisher.name
    end
  end
end

class Book::ListResource
  include ActiveModel::Model

  attr_accesor :books

  ATTRS_AND_METHODS = {
    id: :id,
    author_id: :author_id,
	title: :title,
	publisher: :publisher_name,
	released_at: :release_date
  }

  def build
    books.map do |book|
      ATTRS_AND_METHODS.map { |attr, method|
	    [attr, book.send(method)]
      }.to_h
	end
  end
end
```

次のように使う。

```ruby
# コントローラ内での利用例
@books = Book::ListResource.new(
  books: Book.order(:id).limit(20)
)

# JBuiderのテンプレート
json.books @books
```

## 感想

- pros
  - 既存の実装に影響を与えず、コントローラからもシンプルにリソースを生成できた
- cons
  - `ATTRS_AND_METHODS`のようなマッピングを書かないといけない
  - 新しい層を導入するので設計意図をなんらかの手段で伝える必要がある
