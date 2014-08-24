# `Comparable` の実装を検討する

インタフェース `Comparable` を実装するといいことがあるという話。

`Comparable` は以下のようなインタフェース。
```java
public interface Comparable<T> {
    int compareTo(T t);
}
```

Javadoc は以下のリンクから。

* [Comparable (Java Platform SE 8 )](http://docs.oracle.com/javase/8/docs/api/java/lang/Comparable.html)

`Comparable` は比較メソッド `compareTo` を持つ。
`compareTo` は自身と引数のオブジェクトを比較して、その結果を整数値として返す。
**このインタフェースを実装しているクラスは、自然な順序を持つといえ、ソート（例：`Arrays.sort`）などのアルゴリズムを適用できる。**
よって、値クラスを作るのであれば、`Comparable` を実装すべきである。

このインタフェースは `Object` クラスとは関係ないが、次の節で示すような契約を持つ。

## `compareTo` が従うべき契約

`sgn` は引数の正、ゼロ、負に応じて、1, 0, -1 を返す関数とする。
このとき、`compareTo` は以下の契約を守らなければならない。

1. すべての `x`, `y` に対して `sgn(x.compareTo(y)) == -sgn(x.compareTo(y))`
2. `sgn(x.compareTo(y)) > 0` かつ `sgn(y.compareTo(z)) > 0` ならば `sgn(x.compareTo(z)) > 0`
3. すべての `z` に対して `sgn(x.compareTo(y)) == 0` ならば `sgn(x.compareTo(z)) == sgn(y.compareTo(z))`

ここで、3 番目の条件は必須ではない。
例えば、`BigDecimal` において

* `BigDecimal(1.00) != BigDecimal(1.0)`

だが、

* `compareTo(BigDecimal(1.00), BigDecimal(1.0)) == 0`

である。
ただし、この条件を破る `compareTo` を実装するならば、ドキュメントなどで明確に述べるべきである。

## `Comparable.compareTo` のレシピ

クラスに `Comparable` を実装して `compareTo` をオーバーライドする方法は以下の通り。

* 各フィールドに対してを再帰的に `compareTo` を呼び出す
* フィールドの比較は、最も意味のあるフィールドから始める
* 基本データ型は比較演算子 (`<`, `>`) で比較する。ただし、浮動小数点数は `Double.compare` や `Float.compare` で比較する

フィールドが `Comparable` を実装してないなどの状況に対しては、`Comparator` を使えばよい。

`compareTo` において、引数の型はジェネリクスによりパラメータ化されている。
よって、`Object.equals` のときのような型チェックは必要ない。

## 参考文献

[asin:4621066056:detail]
