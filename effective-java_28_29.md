<!-- Effective Java 第 2 版：第 5 章 項目 28, 29 -->
ジェネリックスの章、最後の 2 項目。ワイルドカードを使った API と、マップのキーのパラメータ化について。

# 項目 28: API の柔軟性向上のために境界ワイルドカードを使用する

## `extends` を用いた境界ワイルドカード

スタックを考える。`pushAll` は以下の API を考える。

```java
public void pushAll(Iterable<E> src);
```

`Number` は `Integer` のスーパークラスである。よって、`Number` でパラメータ化されたスタックに、`Integer` でパラメータ化されたオブジェクトを格納することは自然に思える。しかし、実際は以下のようなコードはエラーになる。

```java
Stack<Number> stack = new Stack<>();
Iterable<Integer> iterable = ...;
stack.pushAll(iterable);    // エラー
```

ここで**境界ワイルドカード**を使う。この境界ワイルドカードを使って、以下のようにコードを書き換えると、上記のコードは動く。

```java
public void pushAll(Iterable<? extends E> src);
```

`? extends E` は `E` のサブクラスであるなんらかの型を表す。こうすることで、`Number` のサブクラスである `Integer`, `Double` などでパラメータ化されているオブジェクトが、引数として渡せるようになる。

## `super` を用いた境界ワイルドカード

スタックに対する格納メソッドである `popAll` を考える。

```java
public void popAll(Collection<E> dest);
```

このコードだと、さきほどの `Number` と `Integer` の話と同様の理由で、以下のコードが動かない。

```java
Stack<Integer> stack = Stack<>();
Collection<Number> numbers = ...;
stack.popAll(numbers);
```

このとき、境界ワイルドカードを用いて、以下のように書き換えることで、上記のコードが動くようになる。

```java
public void popAll(Collection<? super E> dest);
```

`? super E` は `E` のスーパークラスであるなんらかの型を表す。こうすることで、`Number` のサブクラスである `Integer`, `Double` などでパラメータ化されているオブジェクトを、引数のオブジェクトへ格納できるようになる。

## PECS

メソッドに `T` を与えるための引数は、型パラメータを `extends` とする。逆に、メソッドから `T` をもらうための引数は、型パラメータを `super` とする。これを表す略語として **PECS** (producer-extends, consumer-super) がある。PECS にのっとることで、API が柔軟に使えるようになる。

項目 27 の `max` の API は、PECS により、以下のように書き換えられる。

```java
public static <T extends Comparable<? super T>> T max(List<? extends T> list);
```

`max` 自体の引数の型が `List<? extends T>` であることは、この**与える**引数から最大値を求める、ということから、PECS により理解できる。

それより少しわかりにくいのは `Comparable` の型パラメータである。これは `super` を使っているため、`T` を**与えられる**ということになる。`Comparable<T>` は `T` と比較可能なことを表すインターフェースである。つまり、`Comparable<T>` は、`T` を受け取って、`compareTo` によって、自分自身と比較するオブジェクトということになる。これは、`popAll` における `Collection<T>` と役割としては一緒である（`Collection` は `T` を受け取って自分自身に格納している）。よって、`Comparable<T>` は consumer といえ、PECS により `Comparable<? super T>` と書き換えられる。

## その他

* 型パラメータがメソッド宣言中に一度しか現れないなら `?` で置き換える
    * 型パラメータが `?` のコンテナーには（`null` 意外の）要素を入れられないので、その対応は必要

# 項目 29: 型安全な異種コンテナーを検討する

ジェネリックな `Class` 型をキーとすることで、複数の型を扱うマップを作れる。

```java
Map<Class<?>, Object> map = new HashMap<Class<?>, Object>>();
```

マップのキーにワイルドカード `?` が用いられている。これによって、異なる型のクラスリテラルをキーとして値を格納、取り出しできる。クラスリテラルとは、`String.class` や `Integer.class` などで得られる `Class<T>` 型オブジェクトのことである。

また、値に `Object` 型が用いられている。こちらは型パラメーターで表せないので、すべてのクラスの先祖である `Object` にすることで、どのような型のオブジェクトも入れられるようにしている。

このコンテナーに対する API は以下のように実装できる。

```java
public <T> void myPut(Class<T> type, T instance) {
    if (type == null) {
	    throw new NullPointerException("Type is null");
	}
    map.put(type, type.cast(instance));
}
public <T> T myGet(Class<T> type) {
    return type.cast(map.get(type));
}
```

上記のメソッドで使われている `Class.cast` は、引数にとった値が `Class` の表す型と一致するなら、`Object` から `Class` の表す型のオブジェクトへキャストする。そうでなければ、`ClassCastException` を投げる。

実際の使い方は以下の通り。

```java
myPut(Integer.class, 1);    // キー Class<Integer>, 値 int (Integer)
myPut(String.class, "test");    // キー Class<String>, 値 String
int i = myGet(Integer.class);
String s = myGet(String.class);
```

## 制約


1. 原型をキーにすると型安全性が崩れる
    * コンパイル時に無検査警告が出る
2. 具象化不可能型（`List<String>` など）をキーに使えない
    * `List<String>.class` は文法エラー
	* `List<Integer>` と `List<String>` は同じ `Class` オブジェクトを持つので、今回のケースではうまくいかない

# 参考文献

[asin:4621066056:detail]
