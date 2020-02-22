<!-- Rails を使った EC アプリケーション開発について学べる本 "Take My Money" を読んだ -->

読みました。

[https://pragprog.com/book/nrwebpay/take-my-money:embed:cite]

# どんな本か

副題が "Accepting Payments on the Web" となっているように、決済 (payment) システムをもつ Web アプリケーションを作る方法について説明しています。『達人プログラマー』などでおなじみの The Pragmatic Bookshelf シリーズの本です。

チケット販売システムの開発を通して、次のような具体的な話題に触れています。基本的には Rails 5 を使ってロジックからビューまでを開発していきます((「クライアントサイド、サーバサイド両方 Rails 5 を使って開発しています」と書いていましたが、表現がよくないので修正しました))。

- 決済システムの実装
  - ショッピングカート
  - 外部決済サービスとの連携
  - サブスクリプション機能
  - エラーケースとその対策
- 管理画面の実装
  - 返金など注文の操作
  - 認証／認可
- その他実務上必要な項目
  - 監査用ログの保存
  - PCI DSS への準拠

# なぜ読んだか

この本の発売当時（2017-01 ぐらい）に社の Slack で紹介されていたのを見かけて、その存在を知りました。半年ぐらい前から [EC 系サービス](https://shop-pro.jp)の開発に携わっていて、その分野に関して一般的な知見をあらためて得たいなと思い、読むことにしました。

全体を読むのにかけた時間は 2 週間ぐらいです。pragprg.com のサポートページに置いてあるサンプルコードを見つつ、実際に動かしたりしながら読んでいました。

# どうだったか

おさえている話題の幅が広かったです。EC 系のアプリケーションに必要なデータのモデリングや Rails で開発するうえでの実装の工夫から各種定番の gem についてまで、ひととおり説明がありました。自分が携わっているサービスとの共通点／相違点を認識しながら、こういうやりかたもあるのかという発見や知識の整理ができました。

紹介されている外部決済サービスや gem の使いかたの説明は風化が速い部分になってしまうとは思いますが、データモデリングの部分などはそれなりに長く通用する有用な具体例を示してくれているように感じます。

個人的に有用だと思った点をまとめておきます。

## データのモデリング

### 商品在庫

この本では商品在庫をカウンタカラムで管理するのではなく、1 件ずつレコードを作るという方法がよいと述べていました。つまり、次のテーブル定義のような在庫用カウンタ `tickets_count` をもつものではなく、

```sql
# 採用しない例
create_table "tickets"　do |t|
  # ...
  t.integer "tickets_count"
  t.integer "price_cents", default: 0, null: false
end
```

在庫ごとにレコードを作り、`status` カラムに enum で `unsold`, `sold` といったデータを持たせる次のような定義を採用していました。

```ruby
# 採用する例
create_table "tickets" do |t|
  # ...
  t.integer "status"
  t.integer "price_cents", default: 0, null: false
end
```

これについては、開発当初はカウンタを持たせるのが簡単だが、だんだんと

- 在庫数
- カートに入っている商品数
- 売上数

…のようにカウンタの種類が増えていって管理がつらくなる、という理由があるようです。代わりに、在庫ごとにレコードを作るのが商品グループを操作するうえではより簡単な方法だと述べています。

### 返金

返金のモデリングについては、「返金のおかげでこの本を書こうと思ったぐらい返金はだるい」（意訳）と述べていることから、重要かつ工夫のいる部分であることがわかります。まず、この本で開発するアプリケーションでは、決済したときに次のようなテーブルのレコードを作成しています。

```ruby
create_table "payments" do |t|
  # ...
  t.integer "user_id"
  t.integer "price_cents", default: 0, null: false
  t.integer "status"
  t.string  "payment_method"
  t.json    "full_response"
end
```

返金のモデリングでは、次の 2 とおりの方法

- `payments` テーブルに返金額を保存するカラムを追加する方法
- 返金データとして `price_cents` が負の値の `payments` レコードを作成する方法

を選ぶ余地があります。

- これまでに作成したレコードは不変のものとしたい
- 決済処理時のペイメントゲートウェイからの JSON レスポンスを各レコードに保存しておきたい

と言った理由から、この本では返金データも 1 件の `payment` レコードとする方法をとっています。また、返金を表すレコードのために、返金の対象となった元の決済レコードへの参照用カラムを持たせています。

```ruby
change_table "payments" do |t|
  t.references :original_payment, index: true
end
```

これで、複数回の一部返金にも対応できるようになります。これは、ER 図を描くと自分自身へのループ参照で表現されるようなイメージです。

## 実装上の手法

### workflow による薄いコントローラ

コントローラにロジックを書かないために、**workflow** と称したクラスを `app/workflows` に切り出してロジックを分離する、という方法が紹介されています。

```ruby
# app/controllers/shopping_carts_controller.rb
class ShppingCartsController < ApplicationController
  def update
    # performance はある映画のある時間における上映
    workflow = AddsToCart.new(user: current_user, performance: performance, count: params[:ticket_count])
    workflow.run # workflow に実際のロジックを委譲する
    # ...
  end
end

# app/workflows/adds_to_cart.rb
class AddsToCart
  # initialize など...
  def run
    # 実際にカートへ商品を追加するロジックを書く
  end
end
```

調べてみると [Trailblazer の Operation](http://trailblazer.to/gems/operation/2.0/) も同じような発想に基づいているようです。

### 複数の決済方法

EC サービスを開発していると、決済方法は徐々に増えるものです。この本では、最初は Stripe だけを決済サービスとして利用していますが、途中で PayPal を追加します。このように決済方法が増えてきたときの対処として、上で説明した workflow を用いて解決しています。具体的には、抽象的な決済用 workflow を用意し、テンプレートメソッドでそれぞれの決済サービス用の workflow を実装しています。

```ruby
# app/workflows/purchases_cart.rb
class PurchasesCart
  # ...
  def run
    update_tichets
    create_payment
    purchase
    calculate_success
  end
end

# app/workflows/purchases_cart_via_stripe.rb
class PurchasesCartViaStripe < PurchasesCart
  def purchase
    # Stripe の Web API クライアントを使って決済
  end
end

# app/workflows/purchases_cart_via_pay_pal.rb
class PurchasesCartViaPayPal < PurchasesCart
  def purchase
    # PayPal の Web API クライアントを使って決済
  end
end
```

そして、これらの workflow を作成するファクトリはメソッド `create_workflow` に切り出していました。次のような感じで使います。

```ruby
class PaymentsController < ApplicationController
  # ...
  def create
    workflow = create_workflow(params[:payment_type]) # ビューからの payment_type で具象 workflow 作成
    workflow.run
    # ...
  end

  private

  def create_workflow(payment_type)
    case payment_type
    when "paypal"
      PurchasesCartViaPayPal.new( # 引数
      )
    else
      PurchasesCartViaStripe.new( # 引数
      )
    end
  end
end
```

## 定番の gem

アプリケーションを作るうえで必要になる定番の gem がいろいろと紹介されていました。次の gem は知らなかったので参考になりました。

- [money-rails](https://github.com/RubyMoney/money-rails)
  - 金額計算や通貨変換に関する API を提供する [money](https://github.com/Rubymoney/money) という gem を Rails へ統合する
- [Administrate](https://github.com/thoughtbot/administrate)
  - Thoughtbot 謹製の管理画面作成フレームワーク
  - 本の中では ActiveAdmin が使われているものの、こちらについても軽く言及があった
- [Pundit](https://github.com/elabs/pundit)
  - Policy クラスでコントローラアクションに認可機構をかけられる
- [PaperTrail](https://github.com/airblade/paper_trail)
  - ActiveRecord モデルのデータの変更を追跡してバージョン管理する
- [bundler-audit](https://github.com/rubysec/bundler-audit)
  - アプリケーションに導入している gem のうち `Gemfile.lock` に書いているバージョンのものに脆弱性が報告されているかチェックする

# おわりに

EC アプリケーションというドメインに絞って具体的な開発方法が説明されているニッチな本だと思いますが、個人的には参考になる部分がそれなりにあってよかったです。上に述べたような話が気になる人は読んでみてください。
