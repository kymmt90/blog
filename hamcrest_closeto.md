<!-- 単体テスト時に Hamcrest の Matcher#closeTo で誤差あり浮動小数点数の等値比較 -->
# 状況

JUnit + Hamcrest で単体テストを書いている。

# 問題

たとえば、単体テストとして、浮動小数点数を返すメソッドを用いて等値比較をしたいとする。ここで、あるテスト対象オブジェクト `sut` のメソッド `getDoubleValueWithError()` は 1.0 を返すが、**誤差を含みうるとする**。

こういうとき、Hamcrest のマッチャ `Matchers#is` を使って以下のようにアサーションを書いてみる。このとき、**返り値の浮動小数点数に誤差が含まれていると、単体テストが失敗してしまう。**

```java
// getDoubleValueWithError が 1.0000000001 を返したりすると失敗する
assertThat(sut.getADoubleValueWithError(), is(1.0));
```

# 解決法

マッチャとして、**Hamcrest の [`Matchers#closeTo(double operand, double error)`](http://hamcrest.org/JavaHamcrest/javadoc/1.3/org/hamcrest/Matchers.html#closeTo%28double,%20double%29) を使う**。第一引数 `operand` は期待する浮動小数点数値、第二引数 `error` は誤差である。以下のように `closeTo(1.0, 0.0001)` とすると、等値比較する値が 1.0 ± 0.0001 に収まっていれば、単体テストは成功となる。

```java
assertThat(sut.getADoubleValueWithError(), is(closeTo(1.0, 0.0001)));
```
