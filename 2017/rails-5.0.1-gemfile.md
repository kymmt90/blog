<!-- Rails 5.0.1 で rails new するとできる Gemfile の git_source ブロックの意味 -->

Rails 5.0.1 で `rails new` したときに作成される `Gemfile` の先頭に次のブロックが挿入されるようになっていました。

```ruby
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
```

# これの意味

`Gemfile` の中で `:github` オプションをつけた gem について、HTTPS 経由で GitHub から取得します。

`git_source` は [Bundler で定義されているメソッド](https://github.com/bundler/bundler/blob/9f414c55be8b749f46a0470277f14572c5246c03/lib/bundler/dsl.rb#L153) で、引数のオプション（ここでは `:github`）が付いた gem の取得先 URL をブロック内で指定できます。

# やる理由

Bundler が持つ `:github` オプションは Git プロトコルで通信するのでセキュアでなく、さらに Bundler 1.13 以降は `:github` オプションを使っていると警告が出ます。[公式ドキュメント](http://bundler.io/man/gemfile.5.html#GITHUB)でも `:github` オプションを使うのを避けるよう明記してあります。

このコードを入れておくと、HTTPS 経由で GitHub から gem を取得できるので警告が出ずにすみます。ちなみにデフォルトの `Gemfile` では `web-console` が `:github` オプションを使っていますね。Bundler 2.0 ではこの点が対策されるようで、それまでの対処ということです。

入ったプルリクはこちらです。

[https://github.com/rails/rails/pull/27092:embed:cite]

# 参考資料

- [bundler 1.13.0でGemfileに`:github`... | 日々雑記](http://y-yagi.tumblr.com/post/150244664010/bundler-1130%E3%81%A7gemfile%E3%81%AB-github)
- [ruby on rails - Meaning of new block "git_source(:github)" in Gemfile - Stack Overflow](http://stackoverflow.com/questions/41454333/meaning-of-new-block-git-sourcegithub-in-gemfile)
