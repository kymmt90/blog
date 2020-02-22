<!-- Maven に JDK 1.8 を認識させる -->
# 問題

Maven で `mvn package` などビルドコマンドを実行すると、以下のエラーが表示された。

    ...
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD FAILURE
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time: 1.357 s
    [INFO] Finished at: 2014-12-07T13:02:37+09:00
    [INFO] Final Memory: 5M/81M
    [INFO] ------------------------------------------------------------------------
    [ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.1:compile (default-compile) on project random-tweet-bot: Fatal error compiling: 1.8 ?͖????? VM ?o?[?W?????ł??B -> [Help 1]
    ...

このときの環境は以下の通り。

    $ mvn -version
    Apache Maven 3.2.3 (33f8c3e1027c3ddde99d3cdebad2656a31e8fdf4; 2014-08-12T05:58:10+09:00)
    Maven home: /usr/local/Cellar/maven/3.2.3/libexec
    Java version: 1.6.0_65, vendor: Apple Inc.
    Java home: /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home
    Default locale: ja_JP, platform encoding: SJIS
    OS name: "mac os x", version: "10.10.1", arch: "x86_64", family: "mac"

    $ java -version
    java version "1.8.0_20"
    Java(TM) SE Runtime Environment (build 1.8.0_20-b26)
    Java HotSpot(TM) 64-Bit Server VM (build 25.20-b23, mixed mode)

Maven の参照する Java のバージョンが 1.6 になっていておかしい。

# 原因

JDK のインストール時に OS X の `/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK` が更新されない。そのため、Maven などのコマンドが参照する環境変数 JAVA_HOME の指すディレクトリが 1.6 のものになっている。

# 解決法

`~/.bash_profile`, `~/.bashrc` などに以下の設定を書く。

    export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
    export PATH=$JAVA_HOME:$PATH

バージョンアップのときには、`-v` のあとの数字を変更してやるだけでよい。

# 参考文献

- [Can't get Maven to recognize Java 1.8 - Stack Overflow](http://stackoverflow.com/questions/24705877/cant-get-maven-to-recognize-java-1-8)
- [OSXでJavaのバージョンを切り替える - Qiita](http://qiita.com/ringo/items/db58b34dc02a941b297f)
