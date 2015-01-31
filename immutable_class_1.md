<!-- ISBN を例として不変クラスを作ってみる (1) -->
Effective Java で説かれているのが、不変クラスの重要性だ。以前、読書メモを以下の記事に書いた。

- [Effective Java 第 2 版：第 4 章 項目 15 - kymmt's note](http://kymmt90.hatenablog.com/entry/effective-java_15)

不変クラスとは、インスタンス生成後は保持データの変更ができないクラスのことだ。例えば、Java の String や基本データクラスは不変クラスだ。ある String のインスタンスが持つ文字列を変更することはできない。

不変クラスは主に以下の点で便利だ。

- 単純で扱いやすい
- マップやセットなど、他のオブジェクトで利用しやすい
- スレッドセーフである

あるクラスを不変クラスとするためには、いくつかの条件がある。それを説明するために、ISBN を例として Java で不変クラスを作ってみる。本記事では、

- ISBN
- 不変クラスの条件

について説明する。

## ISBN とは

ISBN は書籍を識別するための番号だ。本の裏のコレである。

<p><span itemscope itemtype="http://schema.org/Photograph"><img src="http://cdn-ak.f.st-hatena.com/images/fotolife/k/kymmt90/20150125/20150125113423.jpg" alt="f:id:kymmt90:20150125113423j:plain" title="f:id:kymmt90:20150125113423j:plain" class="hatena-fotolife" itemprop="image"></span></p>

詳しくは Wikipedia を参照してほしい。

- [ISBN - Wikipedia](http://ja.wikipedia.org/wiki/ISBN)

今回は現行規格である 13 桁 ISBN を保持するクラスを作る。ISBN クラスには以下のメソッドを実装する。

- String で渡した ISBN からインスタンスを生成するメソッド
- 接頭、グループ、出版社、書名、チェックディジットの各部分を取得するメソッド
- ある String が ISBN として正当かどうか確かめるメソッド
- ある 10 桁 ISBN を 13 桁 ISBN に変換するメソッド

ISBN 自体はただの数字の羅列であり、状態を持たない。よって、クラスとして実現するのであれば、不変クラスとすべきだろう。

## 不変クラスの条件

ISBN を不変クラスとして作っていくために、不変クラスの条件について説明する。条件は以下の通り。

1. setter のような、**オブジェクトの状態を変更できるメソッドを持たない**
2. サブクラスで状態を変更されないように、**クラスの拡張を防ぐ**
3. すべてのフィールドの可視性を **private** にする
4. `final` をつけるなどして**すべてのフィールドを変更不可**にする
5. 可変オブジェクトを持つ場合、**その不変クラスだけが変更できるようにする**

各項目とも、外部からの変更を防ぐことを目的としたものである。項目 2 と 5 について、注意点を説明する。

### 2. クラス拡張禁止について

クラスの拡張を防ぐ方法として、Java であれば、以下のように `final` を利用できる。

```java
public final class Isbn {
//...
```

これ以外にも、コンストラクタを private にする方法がある。コンストラクタが private だと、そのクラスを継承したとき、その子クラスから親クラスのコンストラクタを呼び出せないため、拡張できない。

しかし、そのままだと、その不変クラスを生成できない。そこで、以下のような **static ファクトリメソッド**を定義する。

```java
public class Isbn {
    // static ファクトリメソッド（単純な例）
    public static Isbn of(String arg) { return new Isbn(arg); }
    // private なコンストラクタ
    private Isbn(String arg) {
        //...
    }
}
```

これで、`Isbn.of("978-4-***-*****-*")` のようにすることでインスタンスを生成できる。static ファクトリメソッドのほうが柔軟性は高いので、今回はこの方法をとる。static ファクトリメソッドの詳細は以下の記事を参照してほしい。

- [Effective Java 第 2 版：第 2 章 オブジェクトの生成と消滅 項目 1 - kymmt's note](http://kymmt90.hatenablog.com/entry/effective-java_1)

### 5. 可変オブジェクトについて

可変オブジェクトを外部から変更されないようにするためには、**防御的なコピー**が必要となる。

ISBN とは異なるが、例えば `Person` クラスを名前、誕生日をフィールドに持つ不変クラスとしたいときを考える。誕生日には**可変クラス** `Date` を利用する。このとき、コンストラクタや getter を以下のように実装してはいけない。

```java
public final class Person {
    private final String name;
    private final Date birthday;

    // ダメなコンストラクタ
    public Person(String name, Date birthday) {
        this.name = name;
     	this.birthday = birthday;
	}

    // ダメな getter
	public Date birthday() { return birthday; }
}
```

なぜなら、このクラスを利用するクライアントから、以下のように `date` を（`Date.setMonth` は非推奨メソッドながら）操作できてしまい、`Person` が不変クラスとして成り立たなくなってしまうからである。

```java
DateFormat format = new SimpleDateFormat("yyyy/MM/dd");
Date date = format.parse("1940/10/09");
Person john = new Person("John Lennon", date);

// Wed Oct 09 00:00:00 JST 1940
System.out.println(john.birthday());

// 外部から john の内部を操作
date.setMonth(0);

// Tue Jan 09 00:00:00 JST 1940
System.out.println(john.birthday());
```

これを防ぐために、以下のように防御的にコピーするのが重要である。

```java
public final class Person {
    public Person(String name, Date birthday) {
        this.name = name;
        // 防御的コピー
     	this.birthday = new Date(birthday.getTime());
    }

    public Date birthday() {
	    // 防御的コピー
		return new Date(birthday.getTime());
	}
}
```

これで、`Person` の内部と外部で `Date` インスタンスが別々のものとなり、外部から `birthday` を操作できなくなるため、不変クラスといえることになる。

とはいえ、今回の ISBN では可変オブジェクトを持たせない予定なので、この条件については気にしないことにする。

## 次回

不変クラスの条件を守った ISBN のクラスを作ってみる。

- [ISBN を例として不変クラスを作ってみる (1) - kymmt's note](http://kymmt90.hatenablog.com/entry/immutable_class_1)

## 参考文献

[asin:4621066056:detail]
