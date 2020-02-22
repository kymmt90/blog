# `clone` を注意してオーバーライドする

`Object.clone` は適切にオーバーライドしないと問題が起こるという話。

`clone` はあるオブジェクトのコピーを返すメソッドである。

* [Object (Java Platform SE 8 )](http://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#clone--)

例えば、GoF のデザインパターンの一つ、"Prototype" パターンで利用されている。

* [Prototype パターン - Wikipedia](http://ja.wikipedia.org/wiki/Prototype_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3)

**`clone` のオーバーライド方法には注意が必要である。**
というのは、`Object.clone` は、デフォルトではオブジェクトのコピーを返さず、`CloneNotSupportedException` を投げるからである。
インタフェース `Cloneable` を実装したクラスから `Object.clone` を呼ぶことで、そのオブジェクトをフィールドごとにコピーしたオブジェクトを返すようになる。

## `clone` に対する一般契約

`clone` に対する契約は以下の通り。
しかし、必須の契約ではない。

* `x.clone() != x` は `true` である
* `x.clone().getClass() == x.getClass()` は `true` である
* `x.clone().equals(x) == true` である
* コピー生成時にコンストラクタは呼び出されない

## `clone` の望ましい処理

`final` ではないクラスで `clone` をオーバーライドするとき、**フィールドが基本データ型もしくは不変オブジェクトならば `super.clone` を返せばよい**。
それなら、最終的には `Object.clone()` が呼び出され、求めるクラスのコピーが得られる。
例えば、以下のようになる。

```java
public class Circle implements Cloneable {
    private double x;
	private double y;
	private double radius;

    @Override public Circle clone() {
        try {
	        return (Circle) super.clone();
	    } catch (CloneNotSupportedException cnse) {
	        throw new AssertionError();  // 起き得ない
	    }
    }

    //...
}
```

ここで、返り値型が `Object` ではなく `Circle` でよいのは、共変戻り値型であることによる。
つまり、オーバーライドされたメソッドにおいて、戻り値型のサブクラスを使えるからである。

さて、問題は**フィールドに配列や参照型などの可変オブジェクトが存在するとき**である。
この場合に `super.clone()` を返すだけだと、オリジナルのオブジェクトとコピーの間で可変オブジェクトを共有してしまう。
その結果、一方で変更があると、もう片方にその影響が及んでしまう。

このときは、**それらのオブジェクトに対して再帰的に `clone` を呼び出す**。
例えば、以下のようになる。

```java
public class MyQueue implements Cloneable {
    private Object[] queue;
	private int size;

    public MyQueue(int size) {
	    this.size = size;
		queue = new Object[size];
	}

    @Override public MyQueue clone() {
        try {
     	    MyQueue result = (MyQueue) super.clone();
     		result.queue = queue.clone();    // 再帰的に clone
     		return result;
     	} catch (CloneNotSupportedException e) {
     	    throw new AssertionError();
     	}
    }

    //...
}
```

ちなみに、もし可変オブジェクトが `final` だと、上のような代入ができず、`clone` の処理がうまく書けない。
この場合は `final` を外す必要があるかもしれない。

最後に、継承されるように設計したクラスについては、そのクライアントに `clone` をオーバーライドするか否かの選択肢を残すため、`Object` と同様に、`protected clone()` をオーバーライドしておく。

```java
@Override protected Foo clone() throw CloneNotSupportedException {
    //...
}
```

## `clone` の代替案

`clone` よりよい方法として、以下のようなコピーコンストラクタか static ファクトリーメソッドによるコピーファクトリーがある。

* `public Foo(Foo foo)`
* `public static Foo newInstance(Foo foo)`

# 参考文献

[asin:4621066056:detail]
