<!-- Jackson で JSON データを POJO に格納  -->
前回に続いて。

Jackson を使うと、JSON から [POJO](http://ja.wikipedia.org/wiki/Plain_Old_Java_Object) へデータを格納できる。

# 基本

以下のような Book という POJO を考える。著者が一人しか設定できないなど、いろいろ問題があるが、例なので気にしないでほしい。

```java
public final class Book {
    private String title;
    private String author;
	private String year;

    public Book() {}

    public String getTitle() { return title; }
	public void setTitle(String title) { this.title = title; }
	public String getAuthor() { return author; }
	public void setAuthor(String author) { this.author = author; }
	public String getYear() { return year; }
	public void setYear(String year) { this.year = year; }
}
```

一方、以下のような内容の JSON ファイル `books.json` を考える。ここで、

- なにもしないコンストラクタを用意する
- POJO のフィールド名と JSON のキー名を一致させる
- POJO に getter/setter を用意するか、フィールドを `public` にする

ことに注意。

```javascript
[
    {
	    "title":"Harry Potter and the Philosopher's Stone",
		"author":"J.K. Rowling",
		"year":"1997"
	}
]
```

このとき、以下のコードで、JSON ファイルから読み込んだデータが `Book` に格納される。

```java
ObjectMapper mapper = new ObjectMapper();
Book book = mapper.readValue(new File("books.json"), Book.class)
book.getTitle();    // Harry Potter and the Philosopher's Stone
book.getAuthor();    // J.K. Rowling
book.getYear();    // 1997
```

# JSON のキー名と POJO のフィールド名が不一致のとき

`Book` のフィールド名 `year` を `firstEditionYear` に変え、getter/setter もそれにしたがって変えるとする。このとき、POJO と JSON で持つ値の名前が一致しない。

このような場合、`JsonProperty` アノテーションを使えばよい。以下に例を示す。

```java
public final class Book {
    private String title;
    private String author;

    @JsonProperty("year")
	private String firstEditionYear;    // <- 名前が JSON でのキー名と一致しないが、アノテーションで year に対応することを明示

    public Book() {}

    public String getTitle() { return title; }
	public void setTitle(String title) { this.title = title; }
	public String getAuthor() { return author; }
	public void setAuthor(String author) { this.author = author; }

    // 以下も名前が JSON のキー名と一致しないが、アノテーションで year に対応することを明示
	@JsonProperty("year")
	public String getFirstEditionYear() { return firstEditionYear; }
	public void setFirstEditionYear(String year) { this.firstEditionYear = firstEditionYear; }
}
```

これで、前の例と同じように JSON データを POJO へ格納できる。

# 不変オブジェクトへデータを格納するとき

これまでの POJO は setter を持っていた。つまり、不変でない。しかし、[Effective Java 第 15 項にあったように](http://kymmt90.hatenablog.com/entry/effective-java_15)、不変なオブジェクトには多くの利点がある。そのため、JSON から読み込んだデータを不変オブジェクトに格納したい。

まず、不変オブジェクトにするために setter を削除する。さらに、JSON から読み込んだデータによって、オブジェクト生成時にのみ値を設定できるように、`JsonCreator` アノテーションを付け、引数に `JsonProperty` を付けたコンストラクタを定義する。

不変な `Book` は以下のようになる。

```java
public final class Book {
    private String title;
    private String author;
	private String year;

    @JsonCreator
    public Book(@JsonProperty("title") String title,
	            @JsonProperty("author") String author,
				@JsonProperty("year") String year) {
	    this.title = title;
		this.author = author;
		this.year = year;
	}

    public String getTitle() { return title; }
	public String getAuthor() { return author; }
	public String getYear() { return year; }
}
```

これで、JSON からデータを読み込んで、不変なオブジェクトを生成することができる。

# コレクションに格納するとき

`books.json` が、以下のように複数の本のデータを持っているとする。

```javascript
[
    {
	    "title":"Harry Potter and the Philosopher's Stone",
		"author":"J.K. Rowling",
		"year":"1997"
	},
    {
	    "title":"Effective Java",
		"author":"Joshua Bloch",
		"year":"2008"
	},
	{
	    "title":"Effective C++",
		"author":"Scott Meyers",
		"year":"2005"
	}
]
```

これらのデータを Java のコレクション、例えば `List<Book>` に格納したいときは以下のようにする。`TypeReference<List<Book>>` のインスタンスを渡すことで、[イレイジャ](http://kymmt90.hatenablog.com/entry/effective-java_24_25)により消されるジェネリックス型情報を `ObjectMapper` に教えている。

```java
ObjectMapper mapper = new ObjectMapper();
List<Book> books = mapper.readValue(new File("books.json"), new TypeReference<List<Book>>() {});
```

`books` には JSON から読み込んだ複数データが格納されている。

```java
books.at(0).getTitle();    // Harry Potter and the Philosopher's Stone
books.at(0).getAuthor();    // J.K. Rowling
books.at(0).getYear();    // 1997
Book ecpp = books.at(2);
ecpp.getTitle();    // Effective C++
ecpp.getAuthor();    // Scott Meyers
ecpp.getYear();    // 2005
```

# まとめ

- Jackson によって JSON ファイルから POJO へデータを格納できる
- Jackson のアノテーションを利用することで以下のことができる
    - JSON のキー名に対応する POJO のフィールドを指定
    - 利用するコンストラクタの指定
- POJO のコレクションにも格納できる

# コード

Java 8 で動作。

<script src="https://gist.github.com/kymmt90/decf11dc917aacc920da.js"></script>

# 参考文献

- [FasterXML/jackson-databind](https://github.com/FasterXML/jackson-databind)
- [Java Jackson- Json Data Binding](http://www.studytrails.com/java/json/java-jackson-Data-Binding.jsp)
