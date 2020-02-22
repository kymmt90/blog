<!-- hatenablog gem 0.4.0 をリリースした -->

Rubygem の hatenablog 0.4.0 をリリースしました。今回追加したのは Basic 認証ではてなブログの API を使えるようにする機能です。

[https://github.com/kymmt90/hatenablog/pull/2:embed:cite]

PR ありがとうございます！

# Basic 認証による利用方法

はてな API で Basic 認証による操作認可を得るには、API キーが必要です。API キーは

```
http://blog.hatena.ne.jp/<はてなユーザ ID>/<はてなブログ ID>/config/detail
```

から確認できます。次の画面の「API キー」の下に書いてあります。

[f:id:kymmt90:20161009151759p:plain]

Basic 認証を使うには、`config.yml` に次の項目を書いてください。

```yaml
auth_type: basic
api_key: <API キー>
user_id: <はてなユーザ ID>
blog_id: <はてなブログ ID>
```

これで Basic 認証ではてなブログ API にアクセスできるようになります。
