<!-- WebAuthnによる認証機能を作りながら理解を深める -->

## 何をやったか

最近の仕事柄興味があったのと、WEB+DB PRESS Vol.114の特集2を読んだこともあって、理解を深めるためにWebAuthnでの公開鍵登録（今回はサインアップを兼ねる）、認証だけできる簡単なWebアプリを作りました。リポジトリのREADMEに様子のGIFアニメを貼っています((なぜかはてなブログにGIFを貼ろうとするとエラーになった))。今回はChrome 80とTouch IDで試しています:

[https://github.com/kymmt90/webauthn_app:title]

このボタンをクリックするとHerokuにデプロイできます。リポジトリのREADMEにも同じボタンを置いています:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/kymmt90/webauthn_app/tree/master)

デプロイ後に環境変数 `WEBAUTHN_ORIGIN` に `https://<Herokuアプリ名>.herokuapp.com` を追加してください。

## 理解できた点

WebAuthn自体の詳しい説明は、Web上のリソースを参照したほうがよいので、今回はとくに書いていません。

### 登場する各ロールの役割

WebAuthの認証フローを見ると用語が多いですが、概ね次のように理解しました。

- **Authenticator**
  - ユーザーエージェントからアクセスされる認証器
  - ハードウェアトークン（Yubikey、Titanなど）やデバイス埋め込みの認証機構（Touch IDなど）
- **Relying Party (RP)**
  - Authenticatorからもらった情報をもとに認証するサーバ
  - ブラウザから公開鍵と**attestation**（認証器自体の正当性証明）を受け取り、公開鍵をアカウントと紐付けて保存する
  - ブラウザから**assertion**（認証時の署名など）を受け取り、認証する

### 実装の感触

個人的にRailsだとさっと実装できるので、今回はRailsでやりました。[webauthn-ruby](https://github.com/cedarcode/webauthn-ruby)と[webauthn-json](https://github.com/github/webauthn-json)の組み合わせで問題なく実装できます((webauthn-rubyはデモアプリも公開していて、今回はそれを模倣している))。実装項目は次のような感じです。

#### サーバ

- クライアントがWebAuthn APIへ渡すためのオプションやチャレンジ値を返すAPIを追加する
  - 公開鍵登録時は `GET /webauthn/credential_creation_options`
    - `WebAuthn::Credential.options_for_create` を使う
  - 認証時は `GET /webauthn/credential_request_options`
    - `WebAuthn::Credential.options_for_get` を使う
- 送られてきたアカウント名、公開鍵、attestationから、アカウントを作成して公開鍵をそのアカウントに紐付けて保存するAPIを追加する
  - `POST /users`
    - `WebAuthn::Credential.from_create` / `WebAuthn::PublicKeyCredentialWithAttestation#verify` を使う
- 送られてきたアカウント名とassertionから、パスワードレス認証するAPIを追加する
  - `POST /session`
    - `WebAuthn::Credential.from_get` / `WebAuthn::PublicKeyCredentialWithAssertion#verify` を使う

#### クライアント

- サインアップ用フォーム
  - サーバからもらったオプションを `navigator.credentials.create()` に渡して認証器からattestationをもらいサーバへ送る
- ログイン用フォーム
  - サーバからもらったオプションを `navigator.credentials.get()` に渡して認証器からassertionをもらいサーバへ送る

RPサーバは署名、オリジン、チャレンジ値、認証回数の検証などプロトコルに規定されている検証を実行する必要がありますが、ライブラリである程度カバーできると思います。

### 認証体験

ふだんパスワードマネージャを使ってはいますが、やはりパスワードレスだと認証の体験がかなり簡単に感じました。これで多要素も満たせる（所持、生体）のも便利ですね。
