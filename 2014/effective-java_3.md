# private のコンストラクタか enum 型でシングルトン特性を強制する

Java でシングルトンを実装するときは、

* static ファクトリーメソッド（項目 1 参照）
* 列挙型 (`enum`)

のどちらかを使うのがよい。

一方、`public static` フィールドにインスタンスを保持するのは避けた方がよい。
以下のコードを考える。

```java
public class Singleton {
    public static final Singleton SINGLETON = new Singleton();
	private Singleton() { ... }
    ...
}
```

ここで、Java のセキュリティマネージャによって特権を得た状態で `AccessibleObject.setAccessible` メソッドを使うと、リフレクトしたオブジェクトの `private` メソッドを呼び出せるようになる。
つまり、`private` なはずのコンストラクタを呼び出せてしまい、シングルトン特性が破られる。
その点で、この方法でのシングルトンの実現は好ましくないといえる。

## static ファクトリーメソッドによる方法

static ファクトリーメソッドで以下のようにシングルトンを実現できる。

```java
public class Singleton {
    private static final Singleton SINGLETON = new Singleton();
	private Singleton() { ... }
	public static getInstance() { return SINGLETON; }
	...
}
```
この方法では、`getInstance` は常に同じ `SINGLETON` の参照を返すため、新たにインスタンスが生成される心配はない。
他の長所として以下の事項がある。

* インスタンス生成の実装が隠蔽されているので、例えば 3 個までインスタンス生成可能にするような変更が簡単にできる
* ジェネリックシングルトンが実現できる

`Serializable` にするためには、すべてのフィールドを `transient` にして、`readResolve` が `SINGLETON` を返すようにオーバーライドしておく。
そうしないと、ディシリアライズ時に複数インスタンスが生成される。

## 列挙型 (`enum`) による方法

要素を一つだけ持つ `enum` を使うと、以下のように簡潔にシングルトンを実現できる。

```java
public enum Singleton {
    SINGLETON;    // 型 Singleton の不変オブジェクト
    public void doSomething() { ... }    // メソッドも定義可能
	...
}
```

このシングルトンは `Singleton.SINGLETON.doSomething()` のように使える。
`enum` は、Java の言語仕様上、シリアライズやリフレクションといった方法によるオブジェクト生成に対して特別な措置がとられている。
そのため、シングルトンを実装するのに向いている。

# 参考文献

[asin:4621066056:detail]
