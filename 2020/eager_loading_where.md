<!-- 意図せず関連先のカラムでwhereしつつeager loadしたらクエリのパフォーマンスが極端に悪化した事例 -->

## 問題

15個ぐらいのさまざまなクエリパラメータを検索条件として受け付けることができる一覧取得API（「Item取得API」とする）があった。

そのAPIで取得するItemは複数の関連を持っていた。また、関連先の取得時にN+1問題の対策が不十分だったので、取得するデータで必要な関連先を漏れなく`includes`でeager loadした結果、ほとんどのケースでパフォーマンスが改善していた。

しかし、あるクエリパラメータ（**`q`**とする）を使うときだけ極端にAPIのパフォーマンスが悪化するという現象が見られた。

## 先に結論

よく言われていることですが、関連先の取得方法が複雑になりそうなら、`preload`/`eager_load`で読み込み方法を明示的に指定して、意図したクエリを作るようにしましょう。

## 原因

元々のコードは次のようなイメージ((出てくるモデルや関連はすべて仮のもの)):

```ruby
# ItemsController
def index
  relation = current_user.items

  # クエリパラメータに基づくたくさんのwhere ...
  if params[:q]
    relation = relation.where(genre: { q: params[:q] })
  end
  # さらに続く...

  # 関連先を漏れなくincludes
  relation = relation.includes(
    :genre,
    :sub_items,
    user: :store,
    category: {
      user: :store,
      :sub_items
    }
  )

  # JSONにしてrenderして終わり
end
```

`q`は関連先テーブルのカラムをWHEREの条件として用いるときのパラメータ。そのパラメータをAPIに渡して`where`で絞り込みをかけるときだけ、関連先テーブルのカラムでWHEREすることになる。

このとき、`Item`取得と同時に関連先のテーブルの情報で絞り込みをかける必要があるので、`includes`はLEFT JOINを発行する`eager_load`の挙動となる。すると、`includes`は指定したすべての関連先を（たとえ他の関連先テーブルのカラムでWHEREするわけではなくても）LEFT JOINで読み込むことになる((https://github.com/rails/rails/blob/7b5cc5a5dfcf38522be0a4b5daa97c5b2ba26c20/activerecord/lib/active_record/relation/finder_methods.rb#L379))((ちなみに他のクエリパラメータだけ使うときは、関連元テーブルitemsのカラムでWHEREしており、関連先テーブルは複数のクエリで取得するpreloadの挙動になっていた))。

関連先のテーブルすべてをLEFT JOINすると、テーブルの構造が原因で本来取りたいデータセットの行数の3乗程度の数のデータを取得しようとして、DB側でメモリを使い尽くして((数十万〜の行数を一発で取ろうとしていた))エラーになっていた。

## もう少し詳しい経緯

### 同じ関連先を複数回includesの引数としていた

モデル`Item`の関連先どうしも関連を持っていた。たとえば、`Item`が持つ`sub_items`や`category`について、それらどうしや`user`へ関連を持つイメージ。これにより、`includes`の引数に同じ関連先が複数回出てくることがあった:

```ruby
relation.includes(
  :genre,
  :sub_items, # 1回目
  user: :store, # 1回目
  category: {
    :sub_items # 2回目
    user: :store, # 2回目
  }
)
```

例えば`user`と`store`は関連元`Item`のメソッドで`user.store.foo?`のようにアクセスされるのに加えて、`Category#bar`でも`user.store.bar?`のようにアクセスされていた。このとき、たとえば`category`のネストした関連先指定を省くと、`Category#bar`の呼び出しが複数回あるときに都度クエリが発行されてしまうので、上のように書かざるをえない((必ずItemの関連から引くようにするなどより大きい範囲でコードを改善をするのがベターだが、いまはそれができないという仮定))。

### 同じテーブルが複数回LEFT JOINされていた

上記のように関連先を指定していて`eager_load`を使うとき、`includes`への指定の仕方が2通りあることから、`sub_items`は2通りの結合条件でLEFT JOINされる。細かい点は説明しないが、テーブルの構成的に、このように2回LEFT JOINすると本来取りたい行数の2乗の数データが取得されてしまっていた((いわゆるproductとproduct variantとoptionのような構成でproductとproduct variantそれぞれにoptionをLEFT JOINしたのに近い cf. https://shopify.dev/docs/admin-api/rest/reference/products/product-variant))。実際の事例ではもう少し込み入った感じになっていて、実際に取りたい行数の3乗程度の行数を取得しようとしていた。

## 解決法

解決法は簡単で、問題となったクエリパラメータを使うテーブル以外の関連先テーブルはつねに`preload`を明示的に指定するだけ。`q`での絞り込み用のカラムを持つ関連先テーブルは`includes`のままにする。

```ruby
def index
  relation = current_user.items

  # ...
  if params['q']
    relation = relation.where(genre: { q: params['q'] })
  end
  # ...

  # whereで使わない関連先を漏れなくpreload
  relation = relation.preload(
    :sub_items,
    user: :store,
    category: {
      user: :store,
      :sub_items
    }
  )

  # whereで使われるかもしれないのでincludes
  relation = relation.includes(:genre)

  # JSONにしてrenderして終わり
end
```

問題のパラメータを指定しなければ`preload`で読み込んでくれるし、必要なときは`eager_load`になる。

今回は、テストの規模ではそこまで遅くなることに気付けなかったのと、問題のパラメータ指定時のクエリを見ていなかったのが敗因。単純なケースなら`includes`のほうが考えることが少なくて便利だが、関連先の取得方法が複雑になってきたら横着せずに`preload`や（今回は使わなかったが）`eager_load`で関連先の読み込み方法を明示的に指定したほうがよい。
