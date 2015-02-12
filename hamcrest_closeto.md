<!-- 単体テスト時に Hamcrest の Matcher#closeTo で誤差あり浮動小数点数の等値比較 -->
# 状況

JUnit + Hamcrest で単体テストを書いている。

# 問題

たとえば、単体テストとして、浮動小数点を返すメソッドに対して等値比較をしたい。ここで、あるテスト対象オブジェクト `sut` のメソッド `getADoubleValueWithError()` は 1.0 を返すが、**誤差を含みうるとする**。

こういうとき、Hamcrest のマッチャ `Matchers#is` を使って以下のようにアサーションを書いてみる。このとき、**返り値の浮動小数点に誤差が含まれていると、単体テストが失敗してしまう。**


```java
// getADoubleValueWithError が 1.0000000001 を返したりすると失敗する
assertThat(sut.getADoubleValueWithError(), is(1.0));
```

# 解決法

マッチャとして、**Hamcrest の `Matchers#closeTo(double operand, double error)`** を使う。第一引数 `operand` は期待する浮動小数点値、第二引数 `error` は誤差である。以下のように `closeTo(1.0, 0.0001)` と使うとき、等値比較する値が 1.0 ± 0.0001 に収まっていれば、単体テストは成功となる。

```java
// getADoubleValueWithError が 1.0000000001 や 0.9999999999 を返すなら成功する
assertThat(sut.getADoubleValueWithError(), is(closeTo(1.0, 0.0001)));
```

# 参考文献

- [Matchers (Hamcrest)](http://hamcrest.org/JavaHamcrest/javadoc/1.3/org/hamcrest/Matchers.html#closeTo%28double,%20double%29)
