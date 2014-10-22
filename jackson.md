<!-- Java 向け JSON ライブラリ Jackson の Databind でデータを読み込む -->
使ってみる機会があったのでメモ。

# はじめに

Jackson は Java 向けの JSON 処理用のライブラリである。

* [FasterXML/jackson](https://github.com/FasterXML/jackson)

ランダムアクセスで JSON からデータを読みたい。今回は、Jackson にある Databind というモジュールを使う。

# データの読み込み

## 外部ファイルの読み込み

以下のような JSON ファイル `test.json` からデータを読み込む。

```javascript
// test.json
{
	"member": [
		{
			"name": "John",
			"age": 22
		},
		{
			"name": "Paul",
			"age": 21
		},
		{
			"name": "George",
			"age": 19
		},
		{
			"name": "Ringo",
			"age": 22
		}
	],
	"album": [
		{
			"name": "Rubber Soul",
			"year": 1965,
			"month": "December",
			"day": 3
		},
		{
			"name": "Revolver",
			"year": 1966,
			"month": "August",
			"day": 5
		}
	]
}
```

まず、`ObjectMapper` を生成する。

```java
ObjectMapper mapper = new ObjectMapper();
```

そして、`ObjectMapper.readTree` によって、JSON ファイルのデータを木構造データとしたときの根ノードを、`JsonNode` 型のオブジェクトとして読み込む。

```java
JsonNode root = mapper.readTree(new File("test.json"));
```

## 特定の値の取得

`JsonNode.get` を使うと、木構造上の指定したキーに対応するノードを取得できる。
根ノード `root` から、`get` を使ってたどっていくような感じ。

値を取得したいキーに対応するノードで `JsonNode.asText` や `JsonNode.asInt` を使うと、そのノードの値を `int` や `String` に変換して取得できる。

```java
// member -> 0 個目の要素 -> name
String member_name = root.get("member").get(0).get("name").asText();
System.out.println(member_name);

// member -> 3 個目の要素 -> age
int age = root.get("member").get(3).get("age").asInt();
System.out.println(age);
```

実行結果：

    John
	22

## 配列

`JsonNode` は `Iterable<JsonNode>` を実装している。
よって、今回のデータでいう `member` や `album` の中のように、配列になっていれば、拡張 for ループで使える。

```java
for (JsonNode n : root.get("album")) {
    String album_name = n.get("name").asText();
    int year = n.get("year").asInt();
    String month = n.get("month").asText();
    int day = n.get("year").asInt();
    System.out.println(album_name + ": " + day + " " + month + " " + year);
}
```

実行結果：

    Rubber Soul: 1965 December 1965
    Revolver: 1966 August 1966

# コード

<script src="https://gist.github.com/kymmt90/bd23b5ef460ccf628453.js"></script>

# 参考文献

* [FasterXML/jackson-databind](https://github.com/FasterXML/jackson-databind)

JSON, POJO 間の変換、木構造データでの読み書き、mapper の設定やアノテーションの使い方が説明されている。
