<!-- Maven で依存 JAR ライブラリを `target/dependency` にコピー -->

# 問題

    $ mvn package

で、プロジェクトの `target` ディレクトリ直下に、プロジェクトの成果物として JAR ファイルが作成される。

このとき、例えばマニフェストに

    Class-Path: ./dependency/foo.jar ./dependency/bar.jar

のように指定する。そして、JARをコマンドラインからクラスパスを指定することなく実行するために、**依存する JAR ライブラリを `target/dependency` に置きたい**。

# 解決法

以下のコマンドを `pom.xml` と同じレベルのディレクトリで実行する。

    $ mvn dependency:copy-dependencies

このコマンドは、プロジェクトが依存するライブラリを `target/dependency` 直下にコピーする。

このコマンドはテスト実行時にのみ必要となるライブラリもコピーする。テスト実行時のみ利用するライブラリをコピー時に除くには、以下のコマンドを実行する。

    $ mvn dependency:copy-dependencies -DincludeScope=runtime

# 参考

- [java - Setting up a proper classpath when using maven - Stack Overflow](http://stackoverflow.com/questions/9385991/setting-up-a-proper-classpath-when-using-maven)

以下のリンク先のように、POM の中で設定する方法もあるらしい（節 1 参照）。こちらのほうが、ライブラリディレクトリ名の設定などもできるため、柔軟っぽい。

- [今まで知らなかった 5 つの事項: Apache Maven](http://www.ibm.com/developerworks/jp/java/library/j-5things13/index.html)
