<!-- RFC 5988 "Web Linking" を読んだ -->

JSON を返す API サーバでページネーションを実装したいと思っていて、前／後ページや最初／最後のページなどといった他のリソースとの関係を表すメタ情報をどこに格納すべきかなと考えていました。解決方法として少なくとも次の二つがありそうです。

- JSON の中（レスポンスのボディ）にメタ情報も入れる
- レスポンスヘッダにメタ情報を入れる

レスポンスヘッダに当該メタ情報を入れる後者の方法について提案している文書としては、[RFC 5988 "Web Linking"](https://tools.ietf.org/html/rfc5988) があります。この方法は大きなサイズのコレクションをページネーションで返す API のレスポンスを設計するときにも使えるという話を見つけたので、メタ情報はボディよりヘッダに入れたほうが場所としては適切だろうと思い、ページネーションを実装する前に、この RFC を読んでみました。

RFC 5988 の要点をハイパーざっくりまとめておきます。

---

### イントロ

- なにをやるのか
  - 特定の形式や応用例に縛られない型付きリンクの表現を定義する
- なぜやるのか
  - リソース間の関係とその型を示す方法は HTML と Atom で別々に定義しているけど一般化できる
  - HTTP ヘッダでリンクを定義する方法が RFC 2068 で定義されてたけど RFC 2616 で削除されてしまった
  - 放っておくと各アプリケーション特有のやり方が生まれちゃってつらそうなので、この RFC ではそれを解決するよ

### リンクとは

- リンクは「IRI((https://www.ietf.org/rfc/rfc3987.txt)) で識別されるリソース間の型付き接続」として定義する
  - 基本的に IRI は URI と読み替えて OK
- リンクは次の要素からなる
  - 一つのコンテキスト IRI
  - 一つのリンク関連型 (link relation type)
  - 一つのターゲット IRI
  - 任意個数のターゲット属性
- `<コンテキスト IRI> は <リンク関連型> のリソースを <ターゲット IRI> で持ち、そのリソースは <ターゲット属性> を持つ` という文章として見ることができる
- どんな型のリンクもどの IRI から何本出ていてもいいし、順番も気にしない
- ターゲット属性は key-value ペア

### リンク関連型

- リンク関連型はリンクの意味を決める
  - `copyright` という関連型のリンクは、ターゲット IRI が指すリソースはコンテキスト IRI へ適用する著作権規定の文章であることを示している
- リンク関連型はターゲットリソースが特定の属性を持つことも示す
  - `service` というリンクは、「サービスの説明」のようにリソースが何か定義されたプロトコルの一部であることを示している
- メディアタイプではないので、リンクの参照先の表現形式は問わない
- 他のリンク関連型の存在や出現数に依存して意味を付け加わるような関連型は望ましくない
  - `alternate` と `stylesheet` は歴史的事情により例外

### 関連型の種類

- 登録関連型 (Registered Relation Types)
  - IANA レジストリに登録済みの再利用できる関連型
  - 名前は reg-rel-type rule にしたがう
    - `reg-rel-type = LOALPHA *( LOALPHA | DIGIT | "." | "-" )` と定義されている
    - つまり ASCII 小文字 `"a".."z"` 1 文字の後に任意個数の ASCII 小文字、数字、`"."`, `"-"` が続く形式
- 拡張関連型 (Extension Relation Types)
  - 関連型を一意に識別できる URI を使うこともできる
  - URIは関連型を定義しているものを指し示す必要があるけど、サーバに負荷がかかるのでクライアントは勝手にそのリソースへアクセスすべきではない

レジストリに最初に登録された関連は該当 RFC 6.2.2 節に載っている。

- https://tools.ietf.org/html/rfc5988#section-6.2.2

現在のレジストリ登録済み関連は IANA のページに載っている。結構増えてますね。

- [Link Relations](https://www.iana.org/assignments/link-relations/link-relations.xhtml)

### Link ヘッダフィールド

- エンティティのヘッダ上で 1 本以上のリンクを表現する
- HTML の `<LINK>` 要素とか Atom の `atom:link` 要素と等価
- ターゲット IRI
  - ブラケットで囲む
  - 相対パスならパーサはパス解決する必要がある
- コンテキスト IRI
  - デフォルトではリクエストされているリソース自体がコンテキスト IRI が指すリソース
  - 404 で該当リソースが存在しないときは `anonymous` になる
- 関連型
  - `rel` パラメータで関連型の値を指定する
  - `rev` は `rel` の逆向きになっている関連であり、歴史的事情で存在しているが、もう使わない
- ターゲット属性
  - `hreflang` は参照先の言語のヒント
  - `media` は参照先のメディアスタイル（画面表示、読み上げ、etc.）のヒント
  - `title`, `title*` は参照先リソースのタイトルで、`title*` は別の文字セットを使うことができる
  - `type` は参照先のメディアタイプのヒント

例を示す。

"chapter2" が現在のリソースの前に位置していることを示すリンク。

```
Link: <http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"
```

ルートリソース ("/") が拡張関連型 `http://example.net/foo` でこのリソースと関連していることを示すリンク。

```
Link: </>; rel="http://example.net/foo"
```

`title*` 属性でドイツ語で「前の章」、「次の章」というタイトルを指定しているリンク。

```
Link: </TheBook/chapter2>; rel="previous"; title*=UTF-8'de'letztes%20Kapitel,
      </TheBook/chapter4>; rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel
```

複数のリンクも持てる。

```
Link: <http://example.org/>; rel="start http://example.net/relation/other"
```

---

結局、ページネーションでは、[Link Relations](https://www.iana.org/assignments/link-relations/link-relations.xhtml) あたりに載っているリンク関連型から、`first`, `last`, `next`, `previous` を使ってリンク先を示すようなメタ情報をヘッダに入れておけば十分そうです。

## 参考資料

- [RFC 5988 - Web Linking](https://tools.ietf.org/html/rfc5988)
- [WikiHub APIのページネーションの実装 - Programming](https://programming.wikihub.io/@r7kamura/20160510164824)
