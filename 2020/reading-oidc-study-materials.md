<!-- OpenID Connectについて知るときに読んだもの -->

OpenID Connect (OIDC)がどういうものか、どう使うのかについて知るために読んだものについてまとめておく。前提として、OAuth 2を利用したアプリケーションの開発経験はあるとします。

## OAuth 2

OIDCはOAuth 2を拡張した認可プロトコルとなっている。前提に書いたとおりOAuth 2を使ったアプリケーション（認可サーバ、クライアント両方）の開発に携わった経験はなんどかあったものの、念のため復習した。

### OAuth 2 in Action

OAuth 2をさらうために、網羅度が高そうな"[OAuth 2 in Action](https://www.manning.com/books/oauth-2-in-action)"を読んだ。邦訳は『[OAuth徹底入門 セキュアな認可システムを適用するための原則と実践](https://www.shoeisha.co.jp/book/detail/9784798159294)』。今回は気まぐれでなぜか洋書のほうを買ってしまった。

OAuth 2の各グラントタイプを、認可サーバ、クライアント、リソースサーバーそれぞれの役割と認可のフロー、それらを実現するコードで説明している。コードは基本的にJavaScriptで書かれていて、GitHubにもリポジトリ([oauthinaction/oauth-in-action-code](https://github.com/oauthinaction/oauth-in-action-code))がある。さらに、認可サーバ、クライアント、リソースサーバそれぞれについて、よくある脆弱性とその対策を説明している。

記述がよくも悪くも冗長なので、コードやシーケンス図を読んで、わからないところがあれば本文で補完していくような読みかたがいいかもしれない。

## OpenID Connect

### OAuth 2 in Action

上で紹介した"OAuth 2 in Action"の後半で、OIDCについて1章割いて説明している((Chapter 13. User Authentication with OAuth 2.0))。OAuthでは誰が認可したのかはクライアントからわかりえないので認証ではない、という話に始まり、他の章と同様に実装を交えてOIDCを説明している。

### OAuth、OAuth認証、OpenID Connectの違いを整理して理解できる本

もう少し理解を整理するためにAuth屋さんが頒布している次の本も読んだ。

[【電子版】OAuth、OAuth認証、OpenID Connectの違いを整理して理解できる本](https://authya.booth.pm/items/1550861)

この本のいいところは、いわゆる「OAuth認証」から始めて、OIDCがなぜ出てくるかまで次のような流れで説明しているところだと思う。

- OAuthでは、クライアントからはユーザを認証（つまり使っているのが誰なのか判断することが）できない
  - アクセストークンはクライアントから見るとopaqueだから情報がない
- プロフィールAPIがリソースサーバにあれば認証に近いことができる（これが「OAuth認証」）が、トークン置き換え攻撃やクライアントの脆弱性で乗っ取りが発生しうる
- Facebookなどdebug_token APIを導入して、「OAuth認証」をよりセキュアにしているサービスもある
- これらを踏まえて、OAuthを土台としつつセキュアな認証機能を標準化するのがOIDC

### RFCなど

IDトークンの検証方法は『OAuth、OAuth認証、OpenID Connectの違いを〜』にも書いてあるが、OIDCのRFCで説明しているのでそちらも確認した。

[Final: OpenID Connect Core 1.0 incorporating errata set 1 - 3.1.3.7.  ID Token Validation](https://openid-foundation-japan.github.io/openid-connect-core-1_0.ja.html#IDTokenValidation)

また、OAuth 2/OIDCの周辺技術に関して、いくつか文書を読んだ。

- [Bearer Token Usage (RFC6750)](https://openid-foundation-japan.github.io/rfc6750.ja.html)
- [JWT Current Best Practice (RFC8725)](https://tools.ietf.org/html/rfc8725)
- [OAuth Security Current Best Practice](https://tools.ietf.org/html/draft-ietf-oauth-security-topics-16)

OIDCではBearer TokenをプロフィールAPIを含むAPIへのアクセス時のトークン送信で使い、JWTをidentity providerからIDトークンとして取得するので、それぞれ注意点やベストプラクティスをあらためて把握するためにRFCを読んだ。"OAuth Security Current Best Practice"は"OAuth 2 in Action"の脆弱性に関する部分と少し被るが、こちらも生まれうる脆弱性とその対策について広く説明している。

OAuth 2/OIDCのRFCは長大なので、ひとまずライブラリの実装と標準の仕様を比較するときなどに読む方針にしている。

### OpenID Connectを実装したライブラリ

コードを読むと理解が深まりやすいので、なにか現実のライブラリを読むのはいいことだと思う。注意点は、あくまでもRFCなどが説明する仕様が正であって、実装はなんらかの差異や不足があると認識しておいたほうがよいこと。それも考慮してコードを読むとコントリビューションチャンスも生まれそう。

今回は[doorkeeper-openid_connect](https://github.com/doorkeeper-gem/doorkeeper-openid_connect)を使ってIDトークンの払い出しやDiscovery APIなど一通り実装し、relying partyとして認証サーバを叩いたりコードを読んで理解を深めた。

## 所感

はじめはなぜOIDCでIDトークンを検証したら認証したことになるのか理解しきれていなかったが、従来の「OAuth認証」で使うプロフィールAPIやdebug_token APIでやっていたようなことを、UserInfo APIと署名付きのIDトークンでやっていると考えると腑に落ちた。そういう意味では、『OAuth、OAuth認証、OpenID Connectの違いを〜』はそのあたりの観点を提供してくれたので大変助かった。とはいえ、それなりにいろいろ読んだものの、細かいパラメータや様々な拡張仕様など、わからないことはまだまだあるので、必要に応じて身につけていきたい。
