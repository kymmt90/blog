<!-- Effective Java 第 2 版：第 4 章 項目 20, 21 -->
# 項目 20: タグ付クラスよりクラス階層を選ぶ

後の章で出てくる enum をタグとして持たせたタグ付クラスはよくないという話。
わざわざこの悪い方法をとる人はあまりいなさそうな気もする。

以下のようなクラスを考える。

```java
class Figure {
    enum Shape { RECTANGLE, CIRCLE };
	final Shape shape;

    // for rectangle
    double length;
	double width;
    Figure(double length, double width) {
	    this.length = length;
		this.width = width;
	}

    // for circle
	double radius;
    Figure(double radius) {
	    this.radius = radius;
	}

    double area() {
	    switch (shape) {
		    RECTANGLE:
			    return length * width;
			CIRCLE:
			    return radius * radius * Math.PI;
		}
	}
}
```

このクラス `Figure` では、`Shape` の値によって、メソッドの振る舞いを制御している。
このタグ付クラスは、以下の点でよくない。

* 全てのフィールドを使うことがない
* フィールドの初期化を誤ると実行時に失敗する
* 新たなタグを追加するときは、そのコード自体を修正する必要がある

これらの問題を解決するために、クラス階層を導入する。
以下の手順で、タグ付クラスをクラス階層へと置き換える。

1. タグが振る舞いを制御していたメソッドを抽象メソッドにして、階層の親クラスに置く
2. その抽象メソッドをオーバーライドすることで、各子クラス特有の振る舞いをするメソッドをを書く

そうすると、以下のようなクラス群に変わる。

```java
class Figure {
    abstract double area();
}

class Rectangle extends Figure {
    double length, width;

    // コンストラクタ...

    @Override double area() {
	    return length * width;
	}
}

class Circle extends Figure {
    double radius;

    // コンストラクタ...

    @Override double area() {
	    return radius * radius * Math.PI;
	}
}
```

この方法の利点は以下の通りである。

* 各クラスに必要なデータだけが配置される
* 階層に型を追加できる柔軟性を持つ
* コンパイル時の型検査が可能であるため、実行時に失敗しない

# 項目 21: 戦略を表現するために関数オブジェクトを使用する

関数オブジェクトを使うと、いわゆる Strategy パターンを実装できるという話。

**関数オブジェクト**とは、他のオブジェクトを受け取り、何らかの操作するためのメソッドを一つだけ持つオブジェクトのことである。
例えば、以下のクラスは関数オブジェクトである。

```java
class StringLengthComparator {
    public int compare(String s1, String s2) {
	    return s1.length() - s2.length();
	}
}
```

この `StringLengthComparator` には、`compare` を通じて `String` が二つ渡される。
そして、その順序関係により、何らかの整数が返される。

この関数オブジェクトを用いると、Strategy パターンにおける戦略を表現することができる。
**戦略**とは、実行時に選択するアルゴリズムのことである。

* [Strategy パターン - Wikipedia](http://ja.wikipedia.org/wiki/Strategy_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3)

`StringLengthComparator` は、具体的なアルゴリズムを表現している具象戦略である。
これは stateless であるため、以下のようにシングルトンとして定義してもよい。
また、一度だけ利用されるときは、無名内部クラスとして宣言してもよい。

複数の具象戦略を扱うためには、インタフェースを用いる必要がある。
今回の場合だと、`StringLengthComparator` は `Comparator` インタフェースを実装するように定義する。
特に、`Comparator` はジェネリックなので、`Comparator<String>` を実装すればよい。

```java
class StringLengthComparator implements Comparator<String> {
    public int compare(String s1, String s2) {
	    return s1.length() - s2.length();
	}
}
```

そうすることで、以下のように具象戦略を渡せるようになる。

```java
// 文字列長を大小比較の戦略に用いてソート
Arrays.sort(array, new StringLengthComparator());
```

このような関数オブジェクトは、`public static final` なフィールドとして保持されて、用いられることが多い。

# 参考文献

[asin:4621066056:detail]
