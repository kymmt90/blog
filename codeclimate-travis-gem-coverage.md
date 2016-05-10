<!-- Code Climate + Travis CI で gem のテストカバレッジを自動測定する -->

[Code Climate](https://codeclimate.com/) は Git リポジトリからソースコードを読み込んで、品質診断をやってくれる SaaS です。例えば、静的解析として

- 循環的複雑度（ソースコードの複雑さを表す尺度）
- ソースコード中の処理／構造の重複数（コードクローン）

などをソースコードごとに測定し、リポジトリに対してそれらのメトリクスを要約した GPA という値（1.0 - 4.0 で 4.0 が最もよい）を算出してくれます。ライブラリの README によく貼ってある次のようなバッジが、Code Climate によって算出された GPA の値です。

[![Code Climate](https://codeclimate.com/github/kymmt90/hatenablog/badges/gpa.svg)](https://codeclimate.com/github/kymmt90/hatenablog)

また、Ruby や PHP など一部の言語では、[Travis CI](http://travis-ci.org)（以下 Travis）と連携させて、テストを実行したときの C0 カバレッジ（命令網羅率）の値を測定できます。これも、次のようなバッジがあります。

[![Test Coverage](https://codeclimate.com/github/kymmt90/hatenablog/badges/coverage.svg)](https://codeclimate.com/github/kymmt90/hatenablog/coverage)

今回、Code Climate と Travis を連携させて、GitHub 上に置いている自分の Ruby gem のテストカバレッジを Code Climate から見られるようにしたのでメモっておきます。作業のおおまかな流れは次のとおりです。

1. Code Climate のトークンを Travis の設定ファイルに追記
2. テストコードに設定を追加
3. Travis 上でテスト実行して結果確認

以下、Code Climate 側のデフォルトブランチは master になっており、以下作業は リポジトリの master に対して実施するものとします。

# 1. Code Climate のトークンを Travis の設定ファイルに追記

リポジトリのルートディレクトリに置いているであろう Travis の設定ファイル `.travis.yml` に次の設定を書きます。`repo_token` に書くのは、Code Climate の Settings → Test Coverage → Ruby から確認できるトークン文字列です。

```yaml
addons:
  code_climate:
    repo_token: XXXX...
```

参考：[Using Code Climate with Travis CI - Travis CI](https://docs.travis-ci.com/user/code-climate/)

トークンは環境変数などを通して使ったほうがよいのかなという懸念がありましたが、ruby-test-reporter の issue での以下議論を見る限り、設定ファイル直書きでも問題ないようです。

- [Is CODECLIMATE_REPO_TOKEN a secret? · Issue #34 · codeclimate/ruby-test-reporter](https://github.com/codeclimate/ruby-test-reporter/issues/34)

トークンは、Code Climate がカバレッジデータをどのリポジトリと関連付けるか見分けるためだけに利用するものであるとのことです。

もし、公開リポジトリの設定ファイルにトークンを書くのはイヤ、暗号化したい！という場合は travis gem を使えばできるようです。次のページが参考になります。

- [Coderwall | Encrypt your Code Climate repo token for public](https://coderwall.com/p/5mtq6q/encrypt-your-code-climate-repo-token-for-public-repositories-on-travis-ci)

# 2. テストコードに設定を追加

Travis 上でテストが走ったときに、カバレッジデータを Code Climate へ POST するために、`codeclimate-test-reporter` という gem を利用します。

[https://github.com/codeclimate/ruby-test-reporter:embed:cite]

まず、`Gemfile` に

```ruby
gem 'codeclimate-test-reporter', group: :test, require: nil
```

を追記します。私は `*.gemspec` ではなく `Gemfile` に直接追記しました。

次に、`test/test_helper.rb` または `spec/spec_helper.rb` またはそれに類するものに、

```ruby
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
```

と書きます。ここが重要で、**このコードは `*_helper.rb` の一番最初に書く必要があります。また、この `*_helper.rb` は、各テストコードの 1 行目で、他の gem などに先んじて `require` してください**。そうしないと、テスト実行前にカバレッジが測定されたりして、正しいカバレッジの値を測定できません。

## Webmock を使っているときのエラーを回避する

[Webmock](https://github.com/bblimke/webmock) をテストコード内で使っているときは、以下の設定を `*_helper.rb` へ追加する必要があります。

```ruby
WebMock.disable_net_connect!(allow: 'codeclimate.com')
```

これはテスト実行時に外部（ここでは `codeclimate.com`）への実リクエストを許可する設定となっています。これがないと Travis 上で処理に失敗します。私は見事に踏みました。

# 3. Travis 上でテスト実行して結果確認

GitHub リポジトリにコミットを push するなり、Travis の更新ボタンを押すなりして、CI を実行します。無事にテストを実行してカバレッジが測定できれば、Code Climate へカバレッジデータが POST され、ブラウザ上やバッジを通じてテストカバレッジが見られるようになります。

[f:id:kymmt90:20160510220636p:plain]

行ごとにテストで通過しているかどうかも確認できます。便利ですね。

[f:id:kymmt90:20160510220640p:plain]

最後に [README](https://github.com/kymmt90/hatenablog/blob/master/README.md) にバッジを貼っておくと、それっぽい感じが出ますね。

[f:id:kymmt90:20160510220742p:plain]
