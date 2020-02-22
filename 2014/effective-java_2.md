# 数多くのコンストラクタパラメータに直面したときはビルダーを検討する

多くのフィールドを持ち、それに伴って多くのコンストラクタパラメータを持つクラスは、初期化のコードを書くときに煩雑であったり、可読性に難があることが多い。
このときに、ビルダーパターンを適用することの利点と欠点について述べられている。

**ビルダーパターン**は、ビルダーオブジェクトを使って、オブジェクトの構築を行う。
この項では、ビルダーオブジェクトによって初期化を行い、不変なオブジェクトを生成する。

## ビルダーパターンの利点

ビルダーパターンを使ったクラスを以下に示す。

```java
public class Person {
    private final String name;
	private final int age;
	private final int height;
	private final int weight;

    public static class Builder {
	    // name は必須、その他は任意
	    private final String name;
    	private int age = 20;
		private int height = 165;
		private int weight = 55;

        public Builder(String name) {
		    this.name = name;
		}

        public Builder age(int val) {
		    age = val;
			return this;
		}

		public Builder height(int val) {
		    height = val;
			return this;
		}

        public Builder weight(int val) {
		    weight = val;
			return this;
		}

        public Person build() {
		    return new Person(this);
		}
	}

    public Person(Builder builder) {
	    this.name = builder.name;
		this.age = builder.age;
		this.height = builder.height;
		this.weight = builder.weight;
	}
}
```

クラス `Builder` がビルダーの役割を果たす `Person` 内の static メンバークラスである。
クラス `Person` は、フィールドが final であることと、外部からフィールドに書き込みできるメソッドがないことから、不変であるといえる。
setter は自分自身を返すため、オブジェクト生成時に、以下のようにメソッドを次々とつなげて書くことができる。

```java
Person Taro = new Person.Builder("Taro").height(175)
								        .weight(65)
										.age(30)
										.build();
```

このコードを見ると、必須パラメータはビルダーのコンストラクタに渡しつつ、さらにオプションパラメータを自由に初期化できることがわかる。
さらに、各パラメータの名前と値がペアになって並んでいるため、読みやすい。

## ビルダーの欠点

ビルダーの欠点として、生成時のコストや、オプションパラメータが少ないときの冗長さが挙げられる。

## その他

* 各パラメータに対する不変式を満たすか検査し、不変式が破られれば `IllegalStateException` を投げるべき
* ビルダーは setter を複数使ってオブジェクトを初期化できるため、可変長パラメータを複数個持てる
* ビルダーを複数のオブジェクトの構築に使い回せる
    * ビルダーに何らかの情報を持たせておいて、オブジェクト構築ごとにその変化させるなどして利用できる
* ジェネリクスを用いたビルダーインタフェースと境界ワイルドカード型によって Abstract Factory パターンを実現できる

# まとめ

オプションパラメータを多く持つクラスの設計時には、ビルダーパターンを使うとうまくいくことがある。
ビルダーパターンにより、オブジェクト構築処理の読みやすさ、書きやすさが向上する。

# 参考文献

[asin:4621066056:detail]
