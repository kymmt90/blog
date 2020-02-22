<!-- Rails 4.1 以降のアプリを Heroku デプロイ時に Internal Server Error が発生したら -->

# 問題

Rails 4.1 以降のアプリを

```sh
$ git push heroku master
$ heroku open
```

で Heroku へのデプロイとアプリへのアクセスをおこなうと、Internal Server Error が発生し、以下のメッセージが表示されることがあります。

```
app error: Missing secret_key_base for ‘production’ environment, set this value in config/secrets.yml (RuntimeError)
```

「本番環境で `secret_key_base` が見つからないから、`config/secrets.yml` の中で値を設定しろ」と言っています。

# 原因

セッション使用時のクッキー改竄防止に利用する `secret_key_base` という変数があります。この変数は、Rails 4.0 までは `config/initializer/secret_token.rb` で設定されていました。

一方、Rails 4.1 からは、新しく導入された設定ファイル `config/secrets.yml` で `secret_key_base` の値を管理するようになっています。このファイルは Web API の secret key なんかを保存しておくのにもつかえます。また、デフォルトでは、本番環境用に以下の要領で環境変数による設定をしています。これでファイルに値を直書きせずにすんでいます。

```yaml
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

その用途から、本来はバージョン管理下に置かないものだと思いますが、Heroku ではこのファイルが必須となっています。

私の場合だと、GitHub が提供している [`Rails.gitignore`](https://github.com/github/gitignore/blob/master/Rails.gitignore) を `.gitignore` として使っていました。これには `config/secrets.yml` のパスが入ってしまっていました。よって、`config/secrets.yml` が Git の管理対象になっておらず、Heroku にデプロイしたときに、この `config/secrets.yml` は本番環境に配置されなくなっていました。結果として、`secret_key_base` が見つからず、エラーになったようです。

# 解決法

`config/secrets.yml` が `.gitignore` に入っている場合、`.gitignore` から外して、`git push heroku master` でアプリを Heroku にデプロイします。これで、Heroku 上の環境にも `config/secrets.yml` が配置されて、エラーは出なくなるはずです。
