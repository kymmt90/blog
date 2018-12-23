<!-- Stripe Sources APIにおける決済の抽象化 -->

この記事は[GMOペパボ Advent Calendar 2018](https://qiita.com/advent-calendar/2018/pepabo)の23日目の記事です。

GMOペパボのAdvent Calendarと言っておきながら、[Stripe](https://stripe.com/)が提供しているWeb APIの話をします。

Stripeの決済用Web APIでは、**source**という概念を通じて多様な決済方法を抽象化して表現しています。このsourceの概念がEC系Webサービス((https://colorme-repeat.jp/))を開発している人間としては興味深いものだったので紹介します。

## sourceとは

Stripe公式のリソースは次のあたりのものです。

[https://stripe.com/docs/sources:embed:cite]

[https://stripe.com/docs/api/sources:embed:cite]

sourceは多様な決済方法を取り扱うために導入されている概念です。sourceの状態がchargeable（課金可能）になると、買い手に対してcharge（課金）することができます。

もう少し詳しく説明すると、sourceは買い手が決済するために使う「モノ」を抽象化した概念であると言えます。その具象としては、クレジットカードやACH（銀行振込のようなもの）があります。1回きりの決済としてsourceに対して直接課金することもできますし、買い手に対して複数回課金するために買い手にsourceを関連付けておくこともできます。

Stripeのドキュメントとcurlがあれば、sourceを用いたWeb API経由での決済実行をすぐに体験できるので、興味がある人はぜひ触ってみてください（以下リンク先の"Try Now"）。

[https://stripe.com/docs#try-now:embed:cite]

たとえばクレジットカードであれば、JS経由でStripeへ直接カード情報を送信後にsourceのIDを得たあと、次のようにAPIを叩くと買い手へのsourceの関連付けと課金を実行できます。

```
$ curl https://api.stripe.com/v1/customers -u <key> -d email=<customer email> -d source=<source ID>
$ curl https://api.stripe.com/v1/charges -u <key> -d amount=100 -d currency=usd -d cutomer=<customer ID> -d source=<source ID>
```

## sourceを特徴づける四つの性質

Stripeはsourceに対して次のような四つの性質を定義しています。これらの性質を使ってさまざまなsourceを分類しています。

### pull/push

決済時の資金の移動方法です。

- pull
  - 買い手の同意を得たあとに売り手側が資金を引き落とせる
- push
  - 買い手側が明示的に資金を送る操作が必要
  - 送金後にsourceがchargeableになる

### flow

買い手が決済を承認するための行動フローです。これを通過するとsourceがchargeableになります。

- none
  - なにもしなくてもOK
- redirect
  - リダイレクト先の銀行のページなどに遷移して承認する
  - sourceがリダイレクト先URLを持つ
- code verification
  - 銀行口座など送金元口座の所有者であることを検証する
- receiver
  - 買い手が送金する
  - sourceに送金先情報を含む

### usage

sourceが何回使えるかを表します。

- reusable
  - 一度flowを通ったあとは追加でchargeできるsource
  - sourceをcustomerに関連付けて、customerに対して課金することで実現
- single_use
  - 決済するたびに買い手の明示的な同意が必要なsource
  - sourceに対して直接課金する

### synchronous/asynchronous

課金の結果がいつ得られるかを表します。

- synchronous
  - success/failureが即時わかる
- asynchronous
  - 結果が数日後にわかる
  - sourceの状態はpendingからsuccess/failureに遷移する

### 決済方法の分類

上述した性質を用いると、sourceの具象である決済方法は次のように分類できます。

- クレジットカード
  - pull/none/reusable/synchronous
  - 買い手に紐づけておけば、売り手が何度も課金できる
- ACH（銀行振込のようなもの）
  - push/receiver/reusable/asynchronous
  - 買い手の入金操作が必要、かつ数日かかる（らしい）

その他の決済方法についても、[Stripeのドキュメントで表がまとめてあります](https://stripe.com/docs/sources#supported-payment-methods)。

## sourceの利点

このあたりから私見が入ります。Stripeのsourceの利点は次のようなところだと思います。

- さまざまな決済方法を同じような扱いかたで扱えるようになる
- 決済ごとの特徴を決めるための性質を定義することで、新決済に対応しやすくなっている

一つ目については、[Stripeのドキュメント](https://stripe.com/docs/sources)を見るとわかるとおり、いろいろな決済方法について利用方法が説明されているのですが、どの決済方法でも概ねsource作成 → sourceへの課金 → Webhookによる結果の確認、という流れになっています。決済が複数あることで複雑化しそうな部分を適切な抽象化で吸収し、統一的なインタフェースとして提供できていることがわかります。

二つ目については、このsourceを用いた決済の抽象化方法を使うと、新しく導入する決済をsourceのインタフェースに載せやすくなります。例えば、Amazon Payや楽天Payのようないわゆる**ID決済**や日本でよく使われる((要出典))**後払い**について考えてみます。これらの決済をsourceの性質で分類すると、おおよそ次のようになると思います。

- ID決済
  - pull/redirect/reusable/synchronous な決済
  - 買い手と外部サービスIDを関連付け、外部サービスに遷移して認証し、あとで追加課金でき（ることが多い）、すぐに決済結果がわかる
- 後払い
  - push/receiver/single_use/asynchronous な決済
  - 買い手がコンビニなどから明示的に送金し、決済ごとに買い手の承認が必要で、与信に人手を介する場合は結果が出るのに時間がかかる

このように複数の性質を用いて特徴を決定することで、新しい具象に対しても、類似する性質の既存決済と同じフローに載せやすくなっています。

## まとめ

StripeのWeb APIにおいて多様な決済をうまく扱うための概念であるsourceについて紹介しました。今回はちょっと間に合わなかったのですが、このようなWeb APIをサーバサイドで実装する際にデータモデリングがどうなるかを考えると、なかなかおもしろいのではと思っています。

なお、id:takatoshionoさんに教えてもらったのがきっかけで、私はこのStripeのWeb APIについて知りました。ありがとうございました！
