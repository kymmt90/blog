<!-- Railsの内部やPluginによる拡張方法について学べる本 "Crafting Rails 4 Applications" を読んだ -->

読みました、というよりは夏の終わりぐらいから何度か読んでいました。

[asin:1937785556:detail]

## どのような本か

Rails中上級者向けとよく言われている本です。Railsの内部構造を知りたかったり、Rails Plugin/Rails Engineを開発したいという人が読むと勉強になる内容です。著者はRailsのコントリビュータでありDeviseなどの開発で有名なPlatformatecの、というよりは、現在はElixirやPhoenixの開発で有名なといったほうがよさそうなJosé Valim氏です。

Railsの内部構造、Rails Plugin/Rails Engineの開発について書かれていると説明しましたが、具体的な例を挙げると次のような内容が含まれています。

- 内部構造
  - Railsのレンダリングの仕組みを追う
  - Active Modelを構成するモジュールの構造を追う
- Rails Plugin
  - コントローラで使う`render`に`:pdf`オプションを追加する
  - ビューテンプレートをファイルではなくDBから読み込めるようにする
  - ERBやHamlのようなテンプレートハンドラを新しく追加する
- Rails Engine
  - Server Sent Eventsでストリーム通信できるようなRails Engineを作る
  - MongoDBに`ActiveSupport::Notifications`で得られるイベントを保存するMoutable and Isolated Engineを作る

## どう役立つか

上にも書いたとおり、Rails Plugin/Rails Engineを作りたい人にとっては、例となるコードを通じてどうやればいいのかがわかるので便利だと思います。

本の題名のとおり、Rails 4（具体的にはv4.0.0）のコードを対象としています。なので、Rails 5のコードと照らし合わせながら読もうとすると、もちろん実装はRails 4から変わっており、サンプルコードなどはそのまま動かないものもあります（それはそれで勉強になりますが）。そういうわけで、Railsの内部については現在のものが直接わかるということにはならないのですが、Railsが実装されるうえで生まれたアイデアを学ぶというスタンスで読むと、Railsを使うときの周辺知識や文脈が補強されるのでよいのではと思います。

個人的には、この本でのRails PluginやRailtiesについての説明を参考にしながら[SchemaConformist](https://github.com/kymmt90/schema_conformist)というRails Pluginを書けたので便利でした。

## 参考資料

この本を読み解くのには次の記事に集められた資料が役立ちました。

[https://techracho.bpsinc.jp/morimorihoge/2014_03_29/16247:embed:cite]

<br>

-----

<br>

おおざっぱには上述したような本です。残りは読書メモを貼っておきます。

- Rails Plugin
  - Rails用に特化したgemのこと
  - `rails new plugin`でスケルトンのプロジェクトを生成できる
  - Railsアプリケーションを動かしてテストするために、プロジェクト内にデフォルトで`test/dummy`という最小限のRailsプロジェクトが一式できる
- Railsのレンダリングスタック
  - [`AbstractController::Rendering#render`](http://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render)は引数とオプションを正規化してから、オプションをもとにレンダリングする
  - [`AbstractController::Rendering#render_to_string`](http://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render_to_string)は`response_body`にレンダリング結果を入れずにそのまま文字列として返す
    - [`AbstractController::Rendering::render_to_body`](http://api.rubyonrails.org/classes/AbstractController/Rendering.html#method-i-render_to_body)を通じて`render`とレンダリングスタックの仕組みを共有している
- Active Model
  - Active Model準拠のAPIを持つクラスを作ると、コントローラやビューでRails Wayに乗って扱えるようになるので便利
    - [`ActiveModel::Model`](http://api.rubyonrails.org/classes/ActiveModel/Model.html)を`include`すればよい
    - [`ActiveModel::Lint::Tests`](http://api.rubyonrails.org/classes/ActiveModel/Lint/Tests.html)でActive Model準拠かどうかをチェックできる
- Action View
  - ビューは`form_for`や`link_to`などのヘルパーメソッドを持つビューコンテキストオブジェクト内で実行される
  - テンプレートを探す (lookup) ための情報を持つlookup contextをコントローラとビューで共有している
  - `ActinoView::Resolver#find_template`をオーバーライドすると、ファイルシステム以外からテンプレートを読み出せる
  - [`ActionController::Metal`](http://api.rubyonrails.org/classes/ActionController/Metal.html)
    - HTTPのことを知らない`AbstractController`とHTTPのことを全部知っている`ActionController::Base`の間の軽量なコントローラ
    - Rackアプリケーションとして動作し、HTTPを扱える最小限の機能を持つ
  - テンプレートハンドラ
    - テンプレートハンドラは内部API`ActionView::Template.register_template_handler`で登録
    - テンプレートハンドラは「レンダリング後の文字列を返すRubyコード」の文字列表現を返すようにすればよい
- [`Rails::Railtie`](http://api.rubyonrails.org/classes/Rails/Railtie.html)
  - Railsの初期化とデフォルト設定にフックできる
  - 利用例
    - アプリ初期化時にタスクを実行したい
    - プラグインで設定値を変えたい
    - プラグインでRakeタスクを入れたい
    - Rails consoleかrunner実行時にプラグインでコードを実行したい
    - プラグインの設定値を追加したい
- Moutable and Isolated Engines
  - `rails plugin new foo --mootable`でスケルトンを生成するRails Engine
  - 名前空間が独立なので、本体のアプリケーションのコンポーネントをオーバーライドしない
- Rack middlewares
  - 使いたいコントローラの中で`use FooControllerMiddleware`とできる
- Rakeタスクで`:environment`を指定している意味
  - Rakeタスク実行前にRailsの初期化処理するために、`config/environment.rb`を実行したい
    - 初期化を必要とするRakeタスクは多数存在（例：`rake db:migrate`）
  - これを指定することでアプリケーションを初期化することができる
  - DBへのアクセスやアプリケーション内のクラスを利用するときは`:environment`が必要
- 1ファイルからなるRailsアプリケーション
  - `config.ru`で`Rails::Application`の子クラスを設定して`initialize!`して`run Rails.application`したものを`rackup`する
