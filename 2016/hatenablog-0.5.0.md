<!-- hatenablog gem 0.5.0 をリリースした -->

Rubygem の hatenablog 0.5.0 をリリースしました。

[https://github.com/kymmt90/hatenablog/blob/master/README.md:embed:cite]

# アップデート

`Hatenablog::Client.new` にブロックを渡すことで認証情報を設定できるようにしました。

```ruby
client = Hatenablog::Client.new do |config|
  config.consumer_key        = '<consumer key>'
  config.consumer_secret     = '<consumer secret>'
  config.access_token        = '<access token>'
  config.access_token_secret = '<access token secret>'
  config.user_id             = '<user name>'
  config.blog_id             = '<user_name>.hatenablog.com'
end
```

従来どおり YAML ファイル経由での設定もできます。

全エントリを取得するメソッド `Hatenablog::Client#all_entries` を追加しました。

```ruby
entries = client.all_entries
```

あと、gem に直接関係ないですが、README が不足気味だったので[増量しました](https://github.com/kymmt90/hatenablog/commit/693c89e6e4d48c776dc01bfdf42b3b657c997944#diff-04c6e90faac2675aa89e2176d2eec7d8)。
