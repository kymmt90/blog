<!-- Rails 5.1でRails pluginをセットアップする手順 -->

最近読んでいる "Crafting Rails 4 Applications" の中でRails pluginを開発する場面が多々あるので、手元でもRails 5を使ってRails pluginを書いてみています。

Rails 5だと、プラグインのセットアップ手順が本の記述やRails Guidesの記述と少し違っていたので書いておきます。

環境は次のとおりです。

- Ruby 2.4.1
- Rails 5.1.3
- Bundler 1.14.6

## プラグインの新規作成

```
$ rails plugin new my_plugin
      create
      create  README.md
      create  Rakefile
      create  my_plugin.gemspec
      create  MIT-LICENSE
      create  .gitignore
      create  Gemfile
      create  lib/my_plugin.rb
      create  lib/tasks/my_plugin_tasks.rake
      create  lib/my_plugin/version.rb
      create  bin/test
      create  test/test_helper.rb
      create  test/my_plugin_test.rb
      append  Rakefile
  vendor_app  test/dummy
```

## gemのインストール

```
$ cd my_plugin
$ bundle
You have one or more invalid gemspecs that need to be fixed.
The gemspec at /Users/kymmt/my_plugin/my_plugin.gemspec is not valid. Please fix this gemspec.
The validation error was '"FIXME" or "TODO" is not a description'
```

Rails pluginはgemの一種なのでプロジェクト中に `*.gemspec` ファイルを持ちます。plugin作成時はこの `gemspec` 中の次の項目に `TODO` の文字列が入っていて、これだと `gemspec` がinvalidと判定され先に進めないので、消すなりなんなりします。

```ruby
Gem::Specification.new do |s|
  # ...
  s.homepage    = "TODO" # TODOを消す
  s.summary     = "TODO: Summary of MyPlugin." # TODOを消す
  s.description = "TODO: Description of MyPlugin." # TODOを消す
  # ...
end
```

もう1回 `bundle` するとgemが入ります。

```
$ bundle
Fetching gem metadata from https://rubygems.org/..........
(snip)
Bundle complete! 2 Gemfile dependencies, 40 gems now installed.
Gems in the groups production and rmagick were not installed.
Use `bundle show [gemname]` to see where a bundled gem is installed.
```

## テストの実行

"Crafting Rails 4 Applications" には「`rake test` でテストを実行できる」という旨の記述がありますが、これをやると次のようになります。

```
$ rake test
/Users/kymmt/my_plugin/test/dummy/db/schema.rb doesn't exist yet. Run `rails db:migrate` to create it, then try again. If you do not intend to use a database, you should instead alter /Users/kymmt/my_plugin/test/dummy/config/application.rb to limit the frameworks that will be loaded.
/Users/kymmt/my_plugin/test/test_helper.rb:9:in `<top (required)>': uninitialized constant Rails::TestUnitReporter (NameError)
        from /Users/kymmt/my_plugin/test/my_plugin_test.rb:1:in `require'
        from /Users/kymmt/my_plugin/test/my_plugin_test.rb:1:in `<top (required)>'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:15:in `require'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:15:in `block in <main>'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:4:in `select'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:4:in `<main>'
rake aborted!
Command failed with status (1)

Tasks: TOP => test
(See full trace by running task with --trace)
```

テスト用ダミーアプリケーションのDBマイグレーションができていないので、ダミーアプリケーションのルートディレクトリまで降りてから、DBマイグレーションを実行します。

```
$ cd test/dummy
$ rake db:migrate
$ cat db/schema.rb
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 0) do

end
```

これで、もう1回テストを実行すると、今度は次のエラーになります。

```
$ cd ../../
$ rake test
/Users/kymmt/my_plugin/test/test_helper.rb:9:in `<top (required)>': uninitialized constant Rails::TestUnitReporter (NameError)
        from /Users/kymmt/my_plugin/test/my_plugin_test.rb:1:in `require'
        from /Users/kymmt/my_plugin/test/my_plugin_test.rb:1:in `<top (required)>'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:15:in `require'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:15:in `block in <main>'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:4:in `select'
        from /Users/kymmt/.rbenv/versions/2.4.1/lib/ruby/gems/2.4.0/gems/rake-12.0.0/lib/rake/rake_test_loader.rb:4:in `<main>'
rake aborted!
Command failed with status (1)

Tasks: TOP => test
(See full trace by running task with --trace)
```

これは `test/test_helper.rb` で `Rails::TestUnitReporter` を読み込んでないのが原因で、`test/test_helper.rb` に `require 'rails/test_unit/reporter'` を加えれば動くようになります(([rails plugin new 躓いたところ - Qiita](http://qiita.com/hikaruna/items/3cc8bb873e925f2c5dd3)))。

ですが、実は "[The Basics of Creating Rails Plugins — Ruby on Rails Guides](http://guides.rubyonrails.org/plugins.html)" の第2節に書いてあるとおり、テストを実行するには `bin/test` を実行するだけでOKです。これは `bin/test` の中で `rails/plugin/test` を `require` しており、その `rails/plugin/test` では `Rails::TestUnitReporter` が `require_relative` されているからです(([rails/test.rb at acea68de026ba657cb65c4dd0fc1f24ba67e1cf8 · rails/rails](https://github.com/rails/rails/blob/acea68de026ba657cb65c4dd0fc1f24ba67e1cf8/railties/lib/rails/plugin/test.rb)))。

```
$ bin/test
Run options: --seed 60803

# Running:

.

Finished in 0.002613s, 382.6843 runs/s, 382.6843 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

## 参考

[asin:1937785556:detail]
