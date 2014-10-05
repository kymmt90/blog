<!-- Effective Java 第 2 版：第 5 章 項目 26, 27 -->

今回は、ジェネリックな型やメソッドを作るという、ジェネリックスの章の中でも重要な部分。

# 項目 26: ジェネリック型を使用する

自分でジェネリック型を書くときの方法についての話。

## 基本

まず、クラス宣言に型パラメータを追加する。このとき、型名はなんでもよいのだが、`E` とするのが一般的。

```java
public class Stack<E> {
    // ...
}
```

## ジェネリック配列の回避

既存の型をジェネリック化するときは、配列を使っている部分で問題が発生する。例えば、Java では、配列の定義をそのままジェネリック化した `E[] elements = new E[10];` のような書き方はできない。

このときは、以下の方法のどちらかをとれば、コンパイルエラーは避けられる。
一つ目は、`Object` の配列を生成して `E[]` でキャストする方法。

```java
E[] elements = (E[]) new Object[10];
```

二つ目は、`elements` を `Object[]` に変え、要素を取り出すときに `E` でキャストする方法。

```java
Object[] elements = new E[10];
E e = (E) elements[0];
```

これらは、どちらも無検査キャストなので、警告が出る。
型安全だとわかっているときは `@SuppressWarning` する。

そもそも、こういう配列の使いかたをするより、リストなどを使ったほうがよいというのが項目 25 の話だった。コレクションは言語機能でないので、リストやマップも内部では配列を使っているということ、また、現実的な制約から、以上のような無検査キャストと `@SuppressWarning` による方法がとられることもあるということらしい。

# 項目 27: ジェネリックメソッドを使用する

自分でジェネリックメソッドを書くときの方法についての話。

## 基本

型パラメーターはメソッドの修飾子と戻り値型の間に書く。

```java
public <E> Set<E> union(Set<E> s1, Set<E> s2) {
    // s1 と s2 の和集合を求める...
}
```

ジェネリックメソッドでは、メソッドの引数の型を調べて、型パラメータの値を決めてくれる（型推論）。よって、以下のように、メソッド自体に型パラメータを指定することなく使える。

```java
Set<Integer> s1 = new HashSet<Integer>(Arrays.asList(1, 2, 3));
Set<Integer> s2 = new HashSet<Integer>(Arrays.asList(3, 4, 5));
Set<Integer> result = union(s1, s2);    // result: (1, 2, 3, 4, 5)
```

## ジェネリック static ファクトリーメソッド

```java
Map<String, List<String>> anagrams = new HashMap<String, List<String>>();
```

このような宣言は長い。これには、ジェネリック化した static ファクトリーメソッドを作ることで対応できる。

```java
public static <K, V> HashMap<K, V> newHashMap() {
    return new HashMap<K, V>();
}
```

とはいえ、Java 7 以降はダイヤモンド演算子を使えばよい。

```java
Map<String, List<String>> anagrams = new HashMap<>();
```

## ジェネリックシングルトンファクトリー

ジェネリックシングルトンファクトリーは `Collections.emptyList` や `Collections.reverseOrder` などの、ジェネリック化された型のシングルトンオブジェクトを返すメソッドのことである。

```java
// String でパラメータ化された空リスト（シングルトン）が返る
List<String> empty_list = Collections.emptyList();

List<Integer>> list = Arrays.asList(1, 0, 5, 2, 4)
// Integer でパラメータ化された Comparator （シングルトン）で逆順にソート
Arrays.sort(a, Collections.reverseOrder());
```

これを実現するには、以下の方法をとる。
今回は、恒等関数（引数をそのまま返す関数）をシングルトンファクトリーで得る場合を考える。
まず、`Object` でパラメータ化されたシングルトンを宣言する。

```java
// 引数を 1 個とる関数オブジェクト
public interface UnaryFunction<T> {
    T apply(T arg);
}

private static UnaryFunction<Object> IDENTITY_FUNCTION
    = new UnaryFunction<Object>() {
        public Object apply(Object arg) { return arg; }
	};
```

次に、ジェネリック化した static ファクトリーメソッドによって、先ほどのシングルトンを型パラメータを用いてキャストし、返す。このキャストは無検査キャストだが、`@SuppressWarning` する。

```java
@SuppressWarning("unchecked")
public static <T> UnaryFunction<T> identityFunction() {
    return (UnaryFunction<T>) IDENTITY_FUNCTION;
}
```

`identityFunction` は、以下のようにジェネリックシングルトンファクトリーとして使える。

```java
UnaryFunction<String> sameString = identityFunction();
String result = sameString("Foo");    // result は "Foo"
```

## 再帰型境界

以下のような型パラメータの書きかたは、再帰型境界と呼ばれる。

```java
public static <T extends Comparable<T>> T max(List<T> list) {
    // 型 T の list の中の最大要素を返す
}
```

`<T extends Comparable<T>>` は、自分の型と比較可能な型 `T` と読める。

# 参考文献

[asin:4621066056:detail]
