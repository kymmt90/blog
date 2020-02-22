<!-- Ruby のテストカバレッジを Travis CI から Code Climate へ POST する方法が変わっていた -->

Travis CI 上で Rubygems のテストを実行して、テストカバレッジの集計結果を Code Climate へ POST するときにエラーが発生していたので、解決方法をメモしておきます。

# エラー

```
/home/travis/.rvm/rubies/ruby-2.0.0-p598/bin/ruby -I"lib:test" -I"/home/travis/.rvm/gems/ruby-2.0.0-p598/gems/rake-10.5.0/lib" "/home/travis/.rvm/gems/ruby-2.0.0-p598/gems/rake-10.5.0/lib/rake/rake_test_loader.rb" "test/hatenablog/category_test.rb" "test/hatenablog/client_test.rb" "test/hatenablog/configuration_test.rb" "test/hatenablog/entry_test.rb" "test/hatenablog/feed_test.rb" "test/hatenablog/requester_test.rb"
W, [2016-11-20T13:49:38.926089 #13726]  WARN -- :       This usage of the Code Climate Test Reporter is now deprecated. Since version
      1.0, we now require you to run `SimpleCov` in your test/spec helper, and then
      run the provided `codeclimate-test-reporter` binary separately to report your
      results to Code Climate.
      More information here: https://github.com/codeclimate/ruby-test-reporter/blob/master/README.md
```

# 解決方法

エラーメッセージにすべて書いてあるのですが、Code Climate への結果の POST に使う ruby-test-reporter のメジャーバージョンアップで仕様が変わったため、エラーになるようです。

次の修正をすれば OK です。

- `Gemfile` の `test` グループに `simplecov` 追加

```ruby
group :test do
  require 'simplecov'
  require 'ruby-test-reporter', '~> 1.0.0'
end
```

- `test/test_helper.rb`（もしくは `spec/spec_helper.rb` など）の先頭から従来の test reporter のコードを削除して、次のコードを追加

```ruby
require 'simplecov'
SimpleCov.start
```

- `.travis.yml` に次のコードを追加

```yaml
after_success:
  - bundle exec codeclimate-test-reporter
```

## なにをやっているか

Travis CI は ruby-test-reporter を利用して Code Climate へ解析結果を POST しています。以前の ruby-test-reporter は SimpleCov を中で実行していたので、`CodeClimate::TestReporter.start` を実行すれば、テストカバレッジの集計 (SimpleCov) と結果の Code Climate への POST (reporter) までやってくれていました。

ところが、ruby-test-reporter v1.0 で SimpleCov と reporter が分離されました。テストが失敗したり、実行中にエラーが起きても、Code Climate にカバレッジなどを POST してしまい、master 以外のブランチでの開発などで問題になるためです((詳細は [この pull request](https://github.com/codeclimate/ruby-test-reporter/pull/121) に書かかれています。))。

以上の理由で SimpleCov と reporter が分離されたので、`test_helper.rb` での `SimpleCov.start` 実行と `.travis.yaml` に設定したテスト成功後の `codeclimate-test-reporter` 実行をそれぞれ設定し直しています。

# 参照

- [Travis CI Ruby Test Coverage](https://docs.codeclimate.com/v1.0/docs/travis-ci-ruby-test-coverage)
- [codeclimate/ruby-test-reporter: Uploads Ruby test coverage data to Code Climate](https://github.com/codeclimate/ruby-test-reporter)
