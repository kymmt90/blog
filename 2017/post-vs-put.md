<!-- 冪等な処理の API エンドポイントでは PUT を使うとよさそう -->

# 結論

- star や like を付与するような、冪等性を持つアクションのための API エンドポイントでも POST はよく使われる
- が、HTTP メソッドの意図を考慮すると、冪等な処理の API エンドポイントにアクセスするときの HTTP メソッドは、POST より PUT がよりよさそう

# 何をやったか

Twitter の like や GitHub の star を付与するようなアクションを、API エンドポイントとしてどのように表現すればよいのかというのを考えていました。

データを編集する操作なので POST, PUT, PATCH のいずれかで、さらに新規に like を表すリソースを作ると考えると、POST か PUT かなと思いました。この二つのどちらがよさそうか、既存 Web サービスの公開 API を見ながら調べてみました。

# 調査結果

## POST

Twitter や Instagram の like は POST でした。

- [POST favorites/create — Twitter Developers](https://dev.twitter.com/rest/reference/post/favorites/create)
- [Instagram Developer Documentation](https://www.instagram.com/developer/endpoints/likes/)

Twitter だと、リソース `favorites/create` を POST で作成するエンドポイントとなっています。

```
POST https://api.twitter.com/1.1/favorites/create.json
```

データを編集するための HTTP メソッドには POST はよく使われます。今回のような操作でも POST が使われている場合が多いようです。ただ、POST は送信したデータを指定 URI に従属させることを意図しています((『Web API: The Good Parts』2.3.2 節参照))。たとえば

```
POST /v1/users
```

で `users` の配下に新しくユーザのリソースを作成するようなパターンです。

なので、Twitter の API のように、直接リソース `favorite/create` を URI で指定するのは、POST の本来の意図とは若干異なってくるのかなと感じました。

## PUT

GitHub API v3 の star は PUT でした。

リポジトリに対する star では、PUT で `user` が持つ `starred/:owner/:repo` というリソースを作成するエンドポイントとなっています。

- [Starring | GitHub Developer Guide](https://developer.github.com/v3/activity/starring/#star-a-repository)

```
PUT /user/starred/:owner/:repo
```

また、Gist に対する star では、PUT で `star` を作成するエンドポイントとなっています。

- [Gists | GitHub Developer Guide](https://developer.github.com/v3/gists/#star-a-gist)

```
PUT /gists/:id/star
```

PUT を使う場合の要件として

- 冪等性を担保すべき((http://stackoverflow.com/questions/630453/put-vs-post-in-rest))
- URI でリソースを直接指定すべき((『Web API: The Good Parts』2.3.3 節参照))

があります。

よって、次の理由

- 一般に star や like は一度付与したら何度付与しても増えたりしない（冪等な処理である）
- リソース （`:repo` や `star`） を URI 内で直接に指定している

から、今回のようなエンドポイントでは POST よりも適しているのかなと思いました。

# 参考資料

[asin:4873116864:detail]

次の Qiita 記事がかなり参考になりました。

[http://qiita.com/suin/items/d17bdfc8dba086d36115:embed:cite]
