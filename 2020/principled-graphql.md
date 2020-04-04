<!-- GraphQL開発のベストプラクティスをまとめた"Principled GraphQL"を読んだ -->

"Principled GraphQL"はApollo社が公開しているGraphQL開発のベストプラクティス集です。

[https://principledgraphql.com:embed:cite]

背景として、近年のアプリケーション開発では「データグラフ」が重要になってきているとしています。GraphQLを通じて、ある企業のすべてのアプリのデータとサービスとを統合してデータグラフとして提供することで、クライアントとしてのアプリケーションから効率よく簡単にサービスを使うことができるようになります。もはやGraphQLはクエリ言語というより、クライアントとサービス間の接続を担う包括的なソリューションなので、いろいろと考えるべきことも多く、GraphQL開発の統合環境を提供していて経験豊富なApolloがベストプラクティスをまとめた、というところのようです。

実際のところ最近GraphQLを触っていないのですが、ざっくり読んでみました。

---

## 構成

ドキュメントのフォーマットは["the Twelve-Factor App"](https://12factor.net/ja/)に影響を受けていて、各項目では守るべき原則を表す簡潔なタイトルとリード文に続いて、具体的な説明が載る構成。ただし"Principled GraphQL"は10箇条であり、次の3件にカテゴリ分けされている。

- Integrity Principles
- Agility Principles
- Operations Principles

## Integrity Principles

### One Graph

- 各チームでバラバラにグラフを作るのではなく、会社で一つの統合されたグラフを作る
- 利用者にとっては無駄や重複のないグラフとなって使い勝手が向上し、開発者にとってはスキルの共有や開発コストの削減になる

例えば、ある会社がジャンルの違う複数サービスを持っている場合は、それらの既存のREST APIなどをApolloプロダクトでデータグラフとして統合すべき、という意図と読める。

### Federated Implementation

- グラフの各部分の実装は複数チームでやる
- チームごとに各々のリリースサイクルで開発できる

[Apollo Federation](https://www.apollographql.com/docs/apollo-server/federation/introduction/)でバックエンドの違いは吸収できる。"One Graph"と表裏一体の関係にあるような原則。

### Track the Schema in a Registry

- schema registryで変更を追跡する
  - schema registryはソースコードにおけるバージョン管理システムにたとえられている
- VS Codeでの補完やスキーマバリデーションに利用できる
- single source of truthとして扱う

schema registryはApolloの場合[The schema registry](https://www.apollographql.com/docs/graph-manager/schema-registry/)のこと。知らなかったが便利そう。

## Agility Principles

### Abstract, Demand-Oriented Schema

- スキーマとサービス／クライアントを疎結合にして、実装を隠して柔軟に利用できる抽象層として扱う
- demand-orientedで開発する
  - 既存のグラフで機能開発しているアプリ開発者の開発者体験(DX)を高められるようなスキーマとする

インタフェースを設けることでバックエンドのアーキテクチャ変更も理論的には可能になるというのはソフトウェアエンジニアリングで頻出なので、もはや一般的な原則という感じもする。

### Use an Agile Approach to Schema Development

- 実際の要求に基づいてインクリメンタルにスキーマは開発していく
- 定期的なバージョニングより必要なときにリリースする
  - スキーマにバージョンをつけて半年ごとに公開するよりは、必要なときに頻繁にリリース
  - いつでも新規フィールドを追加する。フィールドの削除時は非推奨化→削除の順で進める
- schema registryを使って変更の影響をつねに確認できるようにしておくのも効果的

Apolloだと[`@deprecated`ディレクティブ](https://www.apollographql.com/docs/graphql-tools/schema-directives/)がある。

### Iteratively Improve Performance

- グラフ利用者がどのように使おうとしているかをAPI開発者は知るべき
- 実際に送られる形のクエリのパフォーマンス改善をすべき
- 本番ではパフォーマンスを継続的に監視する

GraphQLはエンドポイントが一つで従来のAPMが使いづらいので、パフォーマンス監視のために後述するtracerがあったほうがよさそう。

### Use Graph Metadata to Empower Developers

- 開発のプロセス全体を通してグラフを使うことを意識する
- ドキュメンテーション、補完、クエリのコスト計算、CIで変更の影響確認…
- アプリで使うクエリを運用チームにも共有して、性能的に問題ないか見てもらう
- 静的型付言語で型チェックに利用

型のついたスキーマを使うと補完が捗りそうというのは容易に想像がつく。GraphQLはクエリのコストを気にする必要があるので、そこへの対策もここで入ってくる。

## Operations Principles

### Access and Demand Control

- クライアントごとにグラフへのアクセス権限を管理する
  - access: どのオブジェクトやフィールドにアクセスできるか
  - demand: どのようにどの程度リソースにアクセスできるか
	- クエリのコストを測定して制御する必要がある
- demand controlのベストプラクティス
  - 認証済みの開発者が事前に登録したクエリだけを実行できるようにする
    - 内部アプリは緩和もOK
  - クエリのレビュー／承認フローを開発サイクルに組み込む
  - クエリコストの試算とユーザーごとアプリごとの利用可能コスト上限を決めておくことで、クエリの事前登録ができないときに対応する
  - もしものときのためにアプリ開発者は特定クエリの送信をとめられるようにしておく

GraphQL APIを公開するときはもちろん、内部的なAPIとして使うときも意図せずクエリのコストが高くなることはあるだろうと考えられるので、とにかく実行されるクエリの管理やコストの事前計測が大事そう。

### Structured Logging

- グラフに対する操作の構造化ログを取得し、グラフ利用状況を理解するためのツールとして扱う
  - 活用しやすいようにmachine readableな形式で取得する
- グラフ操作の記録をトレースという
  - [Analyzing performance \- Graph Manager \- Apollo GraphQL Docs](https://www.apollographql.com/docs/graph-manager/setup-analytics/#traces)で紹介されているようなアナリシスの機能
  - ビジネス情報（データがどのように使われているか）と技術的情報（どのバックエンドを使ったか、レイテンシ、キャッシュ利用の状況など）
- フィールド利用状況の調査、監視、監査データ収集、BI、API利用料計算などに使える
- traceは一か所に集めて、加工して監視システムに流すか、データウェアハウスにためておくとよい

### Separate the GraphQL Layer from the Service Layer

- GraphQLの層はサービスの層と分けるべき
- 各サービスにはデータグラフをシステムとして提供するためのロードバランスやAPIキー管理の機能を入れず、クライアントのリクエストに対応することに専念させる
- クエリの一部はエッジのキャッシュで返し、別の部分は他のサービスに問い合わせつつ、すべての操作をtraceで記録するということが可能になる
  - バックエンドのサービスはREST, gRPCなどさまざまな方式で存在しうる

REST APIにおけるAPI Gatewayのような役割。[Apollo Federation](https://www.apollographql.com/docs/apollo-server/federation/introduction/)におけるGatewayがここで述べられている層の役割の一部を担っている。

---

## 感想

スキーマの活用が便利というのはもちろんのこと、クエリのコストについてさまざまな方法で十分な注意を払うべきという主張がなされているのは興味深かったです。原則を示しつつ、Apolloがそれに対応するツールを用意しているところが強いなという印象でした。

興味があるかたは読んでみてください。
