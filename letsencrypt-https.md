<!-- Let's Encrypt で証明書取得 & Web サーバ HTTPS 化 -->

**[2016-07-10 更新](https://github.com/kymmt90/blog/commits/master/letsencrypt-https.md)**

[Let's Encrypt](https://letsencrypt.org) を使って取得した SSL/TLS サーバ証明書によって、Rails を動かしている自分の Web サーバを HTTPS 化しました。こんな鍵アイコンが出ていると HTTPS 化されたサーバと通信できています。

[f:id:kymmt90:20160429144216p:plain]

HTTPS は次のような利点があります。

- サーバ／クライアント間の通信を暗号化できる
- データの完全性（改竄されていないこと）を確認できる
- 中間者が介在せず、意図した Web サイトと通信していることの証明になる

次の流れで作業しました。

1. Let's Encrypt で SSL/TLS 認証局の証明書取得／更新処理自動化
2. nginx の設定ファイルに SSL/TLS の設定を追記
3. Rails の設定ファイルに SSL/TLS の設定を追記

なお、今回のミドルウェアの構成は nginx + Unicorn + Rails となっています。OS は CentOS 7 です。あと、以降は SSL/TLS を略して SSL と書きます。

# 1. Let's Encrypt で SSL 認証局の証明書を取得／更新処理自動化

## 概要

[Let's Encrypt](https://letsencrypt.org) は SSL のサーバ証明書を無料で取得できるサービスです。最近（2016 年 4 月）、サービスがベータ版から正式版に移行しました。

詳細については、日本語で Let's Encrypt の情報をまとめてくださっている次のページをご覧ください。

- [Let's Encrypt の概要 - Let's Encrypt 総合ポータル](https://letsencrypt.jp/about/)

## 利用方法

Let's Encrypt から提供されているクライアントツール `certbot-auto` を利用することで、サーバ証明書を取得したい Web サーバ上で証明書の取得・更新を自動で実行することができます。

また「Let's Encrypt 総合ポータル」を参照しますが、次のページにしたがって、Let's Encrypt クライアントツールのインストールと証明書の初回取得を実施しました。

- [Let's Encrypt の使い方 - Let's Encrypt 総合ポータル](https://letsencrypt.jp/usage/)

証明書の期限は 90 日間です。よって、定期的な証明書の更新が必要になります。これを手動でやるのはよろしくないので、自動化します。今回は、cron によって、証明書の自動更新を実行するシェルスクリプトを週一で実行します。

```sh
$ vi /etc/cron.weekly/renew_cert.sh
#!/bin/sh

LOGFILE=/var/log/letsencrypt/renew.log

echo "`date`: Update SSL/TLS cert by certbot" >>${LOGFILE}
/path/to/certbot/certbot-auto renew \
                              --pre-hook "systemctl stop nginx" \
                              --post-hook "systemctl start nginx" >>${LOGFILE} 2>&1
if [ $? -ne 0 ]; then
  echo Automated renewal failed >>${LOGFILE}
  exit 1
fi
$ chmod 744 ~/renew_cert.sh
```

`certbot-auto renew` が証明書を自動で更新するコマンドです。オプション `--pre-hook` と `--post-hook` は `certbot-auto renew` の実行前と後に実行するコマンドを指定しています。ここでは、`systemctl stop nginx` と `systemctl start nginx` をそれぞれ指定して、証明書の更新中に nginx を停止しています。

これで証明書の取得と自動更新処理の準備は完了です。

# 2. nginx の設定ファイルに SSL の設定を追記

まず、443 番ポートは開放しておいてください。

nginx を SSL の暗号化用サーバとして使うので、[Let’s EncryptとNginx : セキュアなWebデプロイメントの現状 | インフラ・ミドルウェア | POSTD](http://postd.cc/secure-web-deployment-with-lets-encrypt-and-nginx/) を参考にして、`/etc/nginx/nginx.conf` に SSL 用の設定を追記します。

```
# HTTP (80) の設定
server {
    listen 80;
    server_name <ドメイン名>;
    return 301 https://$host$request_uri;
}

# HTTPS (443) の設定
server {
    listen 443 ssl;
    # ...

    ssl_certificate /etc/letsencrypt/live/<ドメイン名>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<ドメイン名>/privkey.pem;
    ssl_session_cache shared:SSL:128m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_stapling on;
    ssl_stapling_verify on;
}
```

ポイントとしては、

- 80 番ポート（HTTP）へのリクエストは 443 番 (HTTPS) へ転送
- プロトコルは現在安全な TLSv1 以降だけを使うこと (`ssl_protocols`)
- 暗号化方式は明示的に指定 (`ssl_ciphers`)
- サーバ側が提示した暗号化方式を使うようにすること (`ssl_prefer_server_ciphers`)

あたりかと思います。

# 3. Rails アプリケーションの設定ファイルに SSL の設定を追記

Rails アプリケーション で SSL を利用するためには、設定ファイル `config/environments/production.rb` に `force_ssl = true` を書けば OK です。

```ruby
Rails.application.configure do
  # ...
  force_ssl = true
  # ...
end
```

簡単ですね。

# なぜか鍵アイコンが表示されないとき

普通はこれまでの作業で HTTPS 通信できるようになります。しかし、私の環境では、ブラウザのロケーションバーに表示されている URL が `https` になっているにもかかわらず、鍵アイコンは表示されない状態になっていました。

この現象の原因は、ページ内の要素をすべて HTTPS 経由でダウンロードしていなかったためでした。私の環境では、ページ中に表示する画像を `http` でダウンロードしていたため、完全に HTTPS 通信できておらず、鍵アイコンが表示されていませんでした。

これを解決するために、画像も HTTPS 経由でダウンロードするように修正しました。すると、次のように鍵アイコンが表示されました。次の画像は Chromium で見たときのものです。

[f:id:kymmt90:20160429143846p:plain]

鍵アイコンがなぜか出ないときは、ページ内要素をすべて HTTPS 経由で取得できているか、確認してみてください。

# おわりに

[Qualys SSL Server Test](https://www.ssllabs.com/ssltest/) という、Web サーバの SSL 設定状況をチェックしてくれるサービスでは、今回の設定は A+ となりました。A+ が最高ランクのようです。

[f:id:kymmt90:20160429143849p:plain]

今回は、Let's Encrypt で取得したサーバ証明書を使って、次の Web サイトを HTTPS 化しました。

- [kymmt.com](http://kymmt.com)

# 参考文献

- [Let's Encrypt 総合ポータル](https://letsencrypt.jp/)
- [Let’s EncryptとNginx : セキュアなWebデプロイメントの現状 | インフラ・ミドルウェア | POSTD](http://postd.cc/secure-web-deployment-with-lets-encrypt-and-nginx/)
- [httpsだからというだけで安全？調べたら怖くなってきたSSLの話!？ - Qiita](http://qiita.com/kuni-nakaji/items/5118b23bf2ea44fed96e)
- [nginx連載6回目: nginxの設定、その4 - TLS/SSLの設定 - インフラエンジニアway - Powered by HEARTBEATS](http://heartbeats.jp/hbblog/2012/06/nginx06.html)
