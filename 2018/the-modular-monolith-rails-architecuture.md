<!-- "The Modular Monolith: Rails Architecture"を読んだ -->

**Modular Monolith**というアーキテクチャをRailsアプリケーションへ適用する記事を読みました。

[https://medium.com/@dan_manges/the-modular-monolith-rails-architecture-fb1023826fc4:embed:cite]

モノリスアーキテクチャとマイクロサービスアーキテクチャの中間に位置する、一つのモノリシックなアプリケーション内でドメインごとにモジュールに分解しつつ運用するためのアーキテクチャを、Railsでどのように実装するか、という内容です。

## Modular Monolithとは

記事から引用します。

> Rather than extracting microservices, we decided to first focus on making our app modular. Our goal was to identify good architectural boundaries before we extracted code out into independent services. This would set us up to be able to migrate to microservices in the future, by having the code structured in a way to make a smooth transition.

- モノリスから複数のマイクロサービスを抽出するより、まずアプリ内をモジュラーにしていく
- 独立したサービスとして抽出する前にアーキテクチャ上のよい境界を見つける。スムーズに移行しやすいようにコードを構成しておく

というものです。Railsで実現するための具体的な方法として次の項目が挙げられています。

- `app` ディレクトリを持たず、コードはすべて `gems` か `engines` の下に置く
- `gems` の下に置くコードははRailsに依存しないRubyのコードとなる
  - すべてステートレスであり、ストレージを使わない
  - Active Supportだけは使う
- `engines` の下に置くコードはRailsに依存するRubyのコードとなる
  - mountable engineにする
  - Active Recordによってデータを永続化する
  - Action PackによってAPIやWebインタフェースを公開する

## なぜModular Monolithを使うのか

`rails new` してRailsアプリケーションをふつうに作っていくとモノリスアーキテクチャになります。ユーザー管理、商品管理、決済など、さまざまなドメインの機能をまとめて `app` 配下などで管理しています。一方、ドメインごとにサービスを切り出して別のアプリケーションとして運用し、サービス間はWeb APIなどを通じて連携するマイクロサービスアーキテクチャも存在します。

Martin Fowler氏は、[MonolithFirst](https://martinfowler.com/bliki/MonolithFirst.html)という記事で、最終的にマイクロサービスにアーキテクチャを移行したいとしても、最初はモノリスから始めるのがよいと述べています。Monolith Firstではアプリケーションを成長させながらドメインの境界を見つけていき、またその必要があるならば、徐々にマイクロサービスとして切り出していきます。

Railsであれば、小〜中規模なアプリケーションならモノリスのままRailsの利点を活かしていくのがよいでしょう。成長して大きくなってきたアプリケーションは、モジュール間の依存が複雑になって変更時の影響範囲が読めなくなってきたりします。こういう場合は、まずモノリスの中をドメインごとにモジュールとして分解していくのが効果的といえ、今回読んだ記事ではModular Monolithを使うのがよいと述べています。

## RailsにおけるModular Monolithアーキテクチャの実現

ここからは、記事で説明されているModular Monolithアーキテクチャを実現するための実装方法について、かいつまんで説明します。

### コードを `gems` か `engines` に配置

前述したように、コードをすべて `gems` と `engines` の下に置きます。すべてgemとして構成するので、それぞれのディレクトリにはgemspecが存在します。Gemfileでは次のようにしてロードします。

```ruby
Dir.glob(File.expand_path("../engines/*", __FILE__)).each do |path|
  gem File.basename(path), :path => path
end

Dir.glob(File.expand_path("../gems/*", __FILE__)).each do |path|
  gem File.basename(path), :path => path
end
```

やっていることは、`engines` と `gems` 配下のディレクトリについて `gem` メソッドで読み込むgemを指定しています。同一リポジトリ内にgemが存在するので `path` オプションを使っています。これを見るとわかるように、実質monorepoとなっています。記事では、プロダクトのコアとなるコードとgemのコードを同時に更新できるので、後方互換性が問題とならず便利であることを利点として挙げています。

### モジュール構成のスタート地点

記事では、`Admin`, `API`, `Domain` というモジュールから始めたと述べています。`Admin` と `API` が `Domain` にそれぞれ依存する形です。ここから、`Domain` モジュールを分解していくのがよいだろうと述べています。

### 境界の遵守

Railsでgemをロードすると、あるクラスは他のクラスに自由にアクセスできてしまいます。これを防ぐために、Railsエンジンのテスト実行時にそのエンジン自体と依存先だけをロードできるようにGemfileの記述を工夫しています。テストはRailsエンジンのディレクトリで実行します。

```ruby
if ENV["ENGINE"].nil?
  if Dir.pwd.split("/")[-2] == "engines"
    ENV["ENGINE"] = Dir.pwd.split("/").last
  end
end

Dir.glob(File.expand_path("../engines/*", __FILE__)).each do |path|
  engine = File.basename(path)
  gem engine, :path => "engines/#{engine}", :require => (ENV["ENGINE"].nil? || ENV["ENGINE"] == engine)
end
```

`ENGINE` 環境変数が設定されていなければ、Railsエンジン名を `ENGINE` 環境変数に保存しておきます。そして、`engines` 配下のディレクトリ名をトラバースしながら、`ENGINE` 環境変数を見て該当のRailsエンジンだけを `require` しています。この方法によって、あるモジュールが依存先として指定していないモジュールのクラスを使ってしまっているときはテストでエラーにできます。

元記事では、このロード方法をさらに発展させて、変更したgemとRailsエンジンだけテストが実行されるようにしていました。

### 循環依存の検出

Bundlerのおかげでモジュールの循環依存が検出できるという話です。

ある二つのモジュール間に循環依存があると、それらのモジュールは強く結合しており、実質一つのモジュールになっているといえます。Modular MonolithアーキテクチャでgemやRailsエンジンといったモジュールに分解することで、モジュール間に循環依存があると、それらのモジュールのロード時にBundlerがエラーとして検出してくれるようになります。

### 疎結合化のためのObserverパターン

Modular Monolithでは、モジュール間の依存方向に気をつける必要があることがわかってきました。モジュール間の依存方向を制御したいときにはObserverパターンが使えます。

```ruby
# driving_scoreエンジンにある定期ジョブ
score = ScoringService.generate_score(user)
if score.eligible?
  QuoteService.generate_quotes(user)
end
```

上のコードは `quoting` （見積）エンジンの持つ `QuoteService` へ依存が発生しています。`driving_score` エンジンから `quoting` エンジンへの依存を作りたくない場合、次のようにすれば、モジュール間の依存を解消して疎結合にできます。

```ruby
# driving_scoreエンジンにある定期ジョブ
score = ScoringService.generate_score(user)
if score.eligible?
  DRIVING_SCORE_PUB_SUB.publish(:eligible_score, :user_id => user_id)
end

# quotingエンジンにあるイベントsubscribe用コード
DRIVING_SCORE_PUB_SUB.subscribe(:eligible_score) do |user_id|
  QuoteService.generate_quotes(user_id)
end
```

`driving_score` エンジンでは `eligible_score` というイベントだけを発行し、だれがそのイベントを購読しているかに関心はありません。つまり、`driving_score` エンジンから `quoting` エンジンへの依存をなくすことに成功しています。

実際には、pub/subの実現にはKafkaやメッセージキュー用のミドルウェアなどが必要になります。私見としては、このあたりはRailsだと[Whisper](https://github.com/krisleech/wisper)が使えそうだと思いました。

## 感想

独立したアプリケーションの機能をmountable engineに切り出すと便利というのはこれまでも言われていたことですが((https://speakerdeck.com/kami/mountable-engine-for-small-team など))、`app` 配下を廃してすべてのコードを `gems` と `engines` 配下に置くという割り切りや、マイクロサービスを意識して徐々にドメイン境界を見つけて切り出すという点が独特だと思いました。

また、書籍[『マイクロサービスアーキテクチャ』](https://www.oreilly.co.jp/books/9784873117607/)では、モノリシックなアプリケーション内にモジュールを作ることは「実世界ではプロセス境界内でのモジュール分離の約束が守られてことはほとんどありません」((『マイクロサービスアーキテクチャ』p.12（原文ママ）))と述べられています。この問題に対しては、Modular Monolithの設計方針であるgem／Railsエンジンへの分離やBundlerによる依存関係管理を用いた境界の遵守が、解決策の候補になるのではないかと思いました。

興味があれば元記事も読んでみてください。
