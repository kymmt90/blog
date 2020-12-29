<!-- Railsエンジンのappディレクトリ配下のクラスを親アプリでオーバーライドする -->

# やりたいこと

Railsエンジンのappディレクトリ配下に存在するクラス（モデルやコントローラ）のメソッドをオーバーライドしたい。

# 結論

[RailsガイドのRailsエンジンについての記事](https://guides.rubyonrails.org/engines.html#overriding-models-and-controllers)に全部書いてある。Railsエンジンのapp配下のオーバーライドは、[`to_prepare`](https://guides.rubyonrails.org/configuring.html#initialization-events)を使って、親アプリの初期化が終わったあとに実行する。オーバーライドするクラスは`class_eval`でリオープンする。

```ruby
# config/application.rb
module TestApp
  class Application < Rails::Application
    # ...

    # アプリの初期化が終わったときに呼ばれるフック
    config.to_prepare do
      # もしZeitwerkなら`require_dependency`が非推奨なので`load`を使う
      require_dependency Rails.root.join('lib/monkey_patch/foo_bar_engine.rb')
    end
  end
end
```

```ruby
# lib/monkey_patch/foo_bar_engine.rb
module MonkeyPatch
  module FooBarEngine
    def do_something
      # 上書きする
    end
  end
end

FooBarEngine::FooBarsController.class_eval do
  prepend ::MonkeyPatch::FooBarEngine
end
```

# 詳細

Railsガイドを読めば問題は解決するのだが、思いつく他の方法で試してみて、なぜだめだったかを見てみる。

## オーバーライドに失敗する例: その1

親アプリ側のディレクトリに次のようなコードを書くと、このアクションに対応するエンドポイントにリクエストを送るとき、`AbstractController::ActionNotFound`のエラーになる。

```ruby
# app/controllers/foo_bar_engine/foo_bars_controller.rb
module MonkeyPatch
  module FooBarEngine
    def do_something
      # 上書きする
    end
  end
end

module FooBarEngine
  class FooBarsController
    prepend ::MonkeyPatch::FooBarEngine
  end
end
```

開発環境では、定数参照時に`const_missing`になるとActive Supportが`autoload_paths`からパスの規約などに基づいて定数を探す。`autoload_paths`は例えば次のように確認できる:

```
[1] pry(main)> puts ActiveSupport::Dependencies.autoload_paths
/usr/src/app/app/assets
/usr/src/app/app/controllers
/usr/src/app/app/controllers/concerns
/usr/src/app/app/helpers
/usr/src/app/app/jobs
/usr/src/app/app/mailers
/usr/src/app/app/models
/usr/src/app/app/models/concerns
/usr/local/bundle/gems/letter_opener_web-1.4.0/app/assets
/usr/local/bundle/gems/letter_opener_web-1.4.0/app/controllers
/usr/local/bundle/gems/letter_opener_web-1.4.0/app/models
/usr/local/bundle/gems/devise-4.7.3/app/controllers
/usr/local/bundle/gems/devise-4.7.3/app/helpers
/usr/local/bundle/gems/devise-4.7.3/app/mailers
/usr/src/app/spec/mailers/previews
=> nil
```

ここではletter_opener_webやdeviseなどのRailsエンジンのapp配下も`autoload_paths`の後ろのほうに入っている。

`FooBarsController`を読み込んでいないとき、アクション実行時に`FooBarEngine::FooBarsController`という定数を解決することになる。`autoload_paths`に従うとRailsエンジンより先に親アプリの定義を見てしまい、中身がほぼ空のコントローラのアクションを呼び出してしまって`AbstractController::ActionNotFound`になる。

## オーバーライドに失敗する例: その2

config/application.rbの末尾で`class_eval`でオーバーライド対象のクラスをリオープンしてオーバーライド用のモジュールを`prepend`すると、`uninitialized constant FooBarEngine::FooBarsController (NameError)`のエラーになる。

```ruby
# config/application.rb
module TestApp
  class Application < Rails::Application
    # ...

    # これがないとlibにパスが通らない
    config.eager_load_paths << "#{Rails.root}/lib"
  end
end

require_dependency 'lib/monkey_path/foo_bar_engine.rb'
```

```ruby
# lib/monkey_path/foo_bar_engine.rb
module MonkeyPatch
  module FooBarEngine
    def do_something
      # オーバーライドする
    end
  end
end

FooBarEngine::FooBarsController.class_eval # この定数が見つからない
  prepend ::MonkeyPatch::FooBarEngine
end
```

これは、config/environment.rbでconfig/application.rbを読み込んだ時点ではアプリの初期化が終わっておらず、オートロードの準備もできていないので、Railsエンジン配下の定数を探索できないのが理由。

## オーバーライドに成功する例

結論に書いたとおり、`config.prepare_to`フックでオーバーライドする。`prepare_to`はアプリの初期化が終わった時点で呼び出されるので、オートロードも可能であり、Railsエンジン配下の定数を探索することもできる。
