# `toString` を常にオーバーライドする

`Object.toString` をオーバーライドしておくと、クラスが使いやすくなるという話。

`toString` はオブジェクトを表現する文字列を返すメソッドである。
`toString` がオーバーライドされているクラスのオブジェクトを `println` のような文字列出力で使うと、自動的に `toString` が呼ばれる。

`toString` の詳細は以下を参照。

* [Object (Java Platform SE 8 )](http://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#toString--)

上記リンク先を読めばわかるように、デフォルトの `toString` による文字列は `{クラス名}@{ハッシュ値の 16 進数表現}` であり、人間には理解しにくい。
そこで、本項では、`toString` をオーバーライドし、有益な情報を出力できるようにすべきと主張している。

## 表示させるべき情報

**`toString` は、オブジェクトに含まれる有益な情報を全て表示できるようにするべきである。**
例えば、以下のようなクラスを考える。

```java
public class Circle {
    public double x;
	public double y;
	public double radius;

    public Circle(double x, double y, double radius) {
	    //...
	}

    // ...
}
```

このとき、円の中心の座標と半径の両方の情報を返すように `toString` をオーバーライドすべきである。
どれが欠けても完全ではない。

```java
@Override public String toString() {
    return "[Circle: x = " + x + ", y = " + y + ", radius = "+ radius + "]";
}
```

これで、以下のように使える。

```java
Circle c = new Circle(0, 0, 1);    // 原点中心の単位円
System.out.println(c);    // [Circle: x = 0.0, y = 0.0, radius = 1.0] と表示
```

## その他

* Javadoc などを用いて、`toString` によって返される文字列の形式に関する方針をしっかり書くべき
    * 形式を規定するしないに関わらず
* `toString` による文字列に含まれる全ての情報へのアクセサを提供すべき
    * ユーザへの文字列パースの強要を避ける

# 参考文献

[asin:4621066056:detail]
