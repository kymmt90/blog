<!-- Effective Java 第 2 版：第 4 章 項目 22 -->
# 項目 22: 非 static のメンバークラスより static のメンバークラスを選ぶ

4 種のネストしたクラスの説明が述べられている。

ネストしたクラス (nested class) とは、あるクラスの中で定義されているクラスのことである。
ネストしたクラスは以下の 4 種類からなる。

* static メンバークラス
* 非 static メンバークラス
* 無名クラス
* ローカルクラス

……ばっちり内容が被っている記事を見つけたので、各クラスの説明は以下のリンクの紹介に代える。

* [【改訂版】Eclipseではじめるプログラミング（17）：あなたの知らない、4つのマニアックなJava文法 (1/3) - ＠IT](http://www.atmarkit.co.jp/ait/articles/1007/27/news103.html)

先ほど紹介したクラスの種類とは以下のように対応する。

* static メンバークラス <--> static のネストしたクラス
* 非 static メンバークラス <--> メンバ・クラス
* 無名クラス <--> 無名内部クラス
* ローカルクラス <--> ローカル内部クラス

なぜ「非 static のメンバークラスより static のメンバークラスを選ぶ」なのかだけ書いておく。
このプラクティスは、メンバークラスを使うときに、そのクラスがエンクロージングクラスへアクセスする必要がないときに有効である。
なぜなら、非 static のメンバークラスは、エンクロージングクラスのインスタンスと一対一に関連づけられ、エンクロージングクラスへの参照を裏で持ち、これはリソースの浪費となる可能性がある。

# 参考文献

[asin:4621066056:detail]