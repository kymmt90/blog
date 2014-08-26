亀の歩みで読み進めている Effective Java は第 4 章へ入った。
第 4 章は「クラスとインフェース」。
この章では、Java でクラスやインタフェースの機能を適切に使うための方法が説明されている。

今回は 項目 13, 14 をメモ。

# 項目 13: クラスとメンバーへのアクセス可能性を最小限にする

言わずと知れたアクセス修飾子 (`public`, `protected`, `private`) の適切な使いどころについて、説明されている。

アクセス修飾子の機能は以下の通り。

* `public`
    * どこからでもアクセス可能
* `protected`
    * サブクラス、同一パッケージ内からアクセス可能
* パッケージプライベート（アクセス修飾子を付けない）
    * 同一パッケージ内からアクセス可能
* `private`
    * そのメンバーが宣言されたクラス内からアクセス可能

クライアントが利用するメソッド (API) は、もちろん `public` を指定する。
そして、**その他のメンバーは極力 `private` を指定するべきである。**

## `private` にする理由

できる限り外からメンバーにアクセスできないようにする理由として、**情報隠蔽**の考え方が挙げられる。
モジュール（例：クラス）の中のメンバを隠蔽することで、他のモジュールがそのメンバに依存した機能、処理を持つことがなくなる。
したがって、各モジュールを分離し、個別の開発や再利用が容易になる。
これが情報隠蔽の利点である。

## パッケージプライベートの使いどころ

パッケージプライベートは、外部に公開する必要のないトップレベルのクラスやインタフェースに適用するとよい。
パッケージ外部に公開されないので、クライアントの知らないところで自由に変更、追加、削除できる。
パッケージプライベートクラスが一つのクラスにのみ使用されているなら、`private` のネストされたクラスにするのもよい方法である。

## `public static final`

**`public static final` の配列フィールドを持たせることは、ほとんどの場合で誤りである。**
これは、配列が
```java
public static final Object[] array = { ... }
```
のように `final` であったとしても、配列 `array` の各要素は変更可能であることによる。
このコードはセキュリティホールになり得る。
この事態を防ぐために、配列を `private` にしておいて、

* `Collection.unmodifiableList` などで `public` な不変リストを持たせる
* `clone` により得られるコピーオブジェクトを返す `public` なメソッドを持たせる

などの方法がある。

# 項目 14: `public` のクラスでは、`public` のフィールドではなく、アクセッサーメソッドを使う

アクセッサーとは、フィールドへアクセスするためのメソッドであり、要は getter と setter のことである。
情報隠蔽の観点から、`public` クラスのフィールドは `public` 公開してはならない。
代わりに、以下のように、アクセッサーを持つべきである。
```java
public class Circle {
    private double x;
	private double y;
	private double radius;

    public Circle(double x, double y, double radius) {
	    this.x = x;
		this.y = y;
		this.radius = radius;
	}

    // getter
    public double getX() {
	    return x;
	}
    public double getY() {
	    return y;
	}
	public double getRadius() {
	    return radius;
	}

    // setter
	public void setX(double x) {
	    this.x = x;
	}
	public void setY(double y) {
	    this.y = y;
	}
	public double setRadius(double radius) {
	    this.radius = radius;
	}
}
```

パッケージプライベート、`private` のネストされたクラスに関しては、`public` でフィールドを公開しても問題ない。
これは、公開範囲がパッケージ内、エンクロージングクラス内に制限されているためである。

また、不変フィールド（`final` の基本データ型、`String`など）は、`public` 公開しても害は少ない。

# 参考文献

[asin:4621066056:detail]
