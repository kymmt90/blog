<!-- ISBN を例として不変クラスを作ってみる (2) -->
[前回](http://kymmt90.hatenablog.com/entry/immutable_class_1)に続いて、今回は実際に不変クラスを作ってみる。

# 不変クラスの条件

不変クラスの条件を復習しよう。条件は以下の通りだった。

1. すべてのフィールドの可視性を **private** にする
2. `final` をつけるなどして**すべてのフィールドを変更不可**にする
3. setter のような、**オブジェクトの状態を変更できるメソッドを持たない**
4. サブクラスで状態を変更されないように、**クラスの拡張を防ぐ**
5. 可変オブジェクトを持つ場合、**その不変クラスだけが変更できるようにする**

# ISBN クラスの機能

今回作る ISBN クラスに持たせたい機能は以下の通り。

- String で渡した ISBN からインスタンスを生成できる
- 接頭、グループ、出版社、書名、チェックディジットの各部分を取得できる
- ある String が ISBN として正当かどうか確かめられる（static メソッド）
- ある 10 桁 ISBN を 13 桁 ISBN に変換できる（static メソッド）

また、`Object.equals` と `Object.hashcode` をオーバーライドする必要がある。

# コードの説明

コードの全体はこちらに置いている。

- [Isbn.java](https://gist.github.com/kymmt90/a45ae122faeb78096b2c)

## フィールド

クラス `Isbn` には以下のインスタンスフィールドを持たせる。

```java
public class Isbn {
    private final String originalIsbn;
    private final String normalizedIsbn;

    private final String prefix;
    private final String group;
    private final String publisher;
    private final String bookName;
    private final String checkDigit;
}
```

`normalizeIsbn` は、ハイフンを含みうる ISBN 文字列 `originalIsbn` からハイフンを取り除いた文字列である。`equals` における比較などで利用する。

ここで、**条件 1, 2** から、フィールドはアクセス制御を `private` とし、`final` にする。また、**条件 3** から、フィールドに対する setter は持たせない。getter は必要に応じて持たせる。

## オブジェクト生成

次に、オブジェクト生成のためのメソッドを定義する。前回書いた通り、クラス拡張を防ぐために **条件 4** により、static ファクトリメソッド `Isbn#of` を定義し、その中で `private` なコンストラクタを用いる。

```java
public static Isbn of(String number) throws IllegalArgumentException {
    if (number == null) throw new NullPointerException();
    if (!isValid(number)) throw new IllegalArgumentException();

    if (removeHyphen(number).length() == OLD_LENGTH) {
        return new Isbn(toIsbn13(number));
    } else {
        return new Isbn(number);
    }
}

private Isbn(String originalIsbn) {
    assert null != originalIsbn;

    this.originalIsbn = originalIsbn;
	this.normalizedIsbn = removeHyphen(this.originalIsbn);

	String[] numbers = this.originalIsbn.split("-");
	if (numbers.length == 5) {
		this.prefix     = numbers[0];
		this.group      = numbers[1];
		this.publisher  = numbers[2];
		this.bookName   = numbers[3];
		this.checkDigit = numbers[4];
	} else {
		this.prefix     = "";
		this.group      = "";
		this.publisher  = "";
		this.bookName   = "";
		this.checkDigit = "";
	}
}
```

ここで、`Isbn#of` では、まず、`Isbn#isValid` で 渡された文字列 `number` が ISBN として妥当かを調べている。次に `number` から `removeHyphen` でハイフンを除いたとき、その数字列が 10 桁のときは、`Isbn#toIsbn13` で 13 桁 ISBN に変換している。

## `equals` と `hashCode`

最後に、決まりきったコードではあるが、`Object.equals` と `Object.hashCode` をオーバーライドする。

```java
@Override
public boolean equals(Object obj) {
    if (this == obj)
        return true;
    if (!(obj instanceof Isbn))
        return false;
    Isbn other = (Isbn)obj;
    return other.normalizedIsbn.equals(normalizedIsbn);
}

@Override
public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + normalizedIsbn.hashCode();
    return result;
}
```

今回は、ISBN からハイフンを取り除いた文字列 `normalizedIsbn` を `equals` の等価比較に用いる。また、`equals` が true なら `hashCode` の値が同じである必要がある。そのため、`hashCode` でも `normalizedIsbn` により、ハッシュ値を計算している。これらのメソッドのオーバーライド方法については、以下の記事も参照。

- [Effective Java 第 2 版：第 3 章 項目 8 - kymmt's note](http://kymmt90.hatenablog.com/entry/effective-java_8)
- [Effective Java 第 2 版：第 3 章 項目 9 - kymmt's note](http://kymmt90.hatenablog.com/entry/effective-java_9)

# さらなる発展

今回の内容以外にも、`Isbn#of` において、生成したインスタンスをキャッシュをすることもできるだろう。

キャッシュを実装する場合、不変クラスの**条件 5** の「可変オブジェクトを持つ場合、**その不変クラスだけが変更できるようにする**」を守り、外部からキャッシュを保存するコンテナにはアクセスできないようにする必要がある。

# 参考文献

[asin:4621066056:detail]
