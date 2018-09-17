<!-- このブログをHTTPS化した -->

[はてなブログで独自ドメインを当てているときもHTTPS化できるようにとっくになっていた](http://staff.hatenablog.com/entry/2018/06/13/160000)ので、このブログもHTTPS化しました。

## 手順

こちらの記事を全面的に参考にさせてもらいました。

[https://blog.jnito.com/entry/2018/07/16/084116:embed:cite]

まずはgemをインストールします。`config.yml` の準備もいい感じにやっておきます。

```
$ gem install hateblo_mixed_contents_finder
```

次に、mixed contentsが存在する記事を洗い出します。

```
$ hateblo_mixed_contents_finder validate_all
$ cat result.txt | cut -f 1 | sort -u > invalid_entries.txt # mixed contentsを含む記事のURLリストを出力する
```

ツールが `invalid_entries.txt` を参照してくれるので、再更新をかけます。

```
$ hateblo_mixed_contents_finder update_all
```

ふたたびmixed contentsがないかを確認します。

```
$ hateblo_mixed_contents_finder validate_all
$ cat result.txt | cut -f 1 | sort -u
http://blog.kymmt.com/entry/201601_read_booksq
http://blog.kymmt.com/entry/201602_read_books
http://blog.kymmt.com/entry/201603-read-books
```

ここまでやって、mixed contentsが残った記事のURLリストを出せたので、これらの記事については手作業でmixed contentsを取り除きました。具体的には、ベタ書きされたURLのプロトコルがHTTPだったので、次のように対応しました。

- `http` を `https` に置き換え
- Amazonの画像URLは `http://ecx.images-amazon.com` を `https://images-na.ssl-images-amazon.com` に置き換え

もう一度mixed contentsがないか確認たところ、そのような記事は見つかりませんでした。

```
$ hateblo_mixed_contents_finder validate_all
# ...
OK💚
```

最後に、はてなブログの設定画面からHTTPS配信を有効にしておしまいです。
