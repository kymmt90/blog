<!-- Emacs をアップデートしたあとは cask update を実行する -->

当たり前の話ですが一応メモ。

Emacs をいまさらながら 24.4 から 24.5 にアップデートしました。アップデートしたあとに Emacs を起動するとこんなエラーメッセージが出て init.el がちゃんと読み込めませんでした。

    File error: Cannot open load file, no such file or directory, auto-complete-config

エラーメッセージを見るに、拡張が見つかっていないので、`~/.emacs.d` 以下を見に行きました。すると、`~/.emacs.d/.cask` 以下はディレクトリ `24.4.1` しかないことに気づきました。バージョンごとに拡張を格納するディレクトリを分けてあるようです。

ということで、以下のコマンドでもう一度拡張をダウンロードしなおすと、正常に Emacs を起動できました。

```sh
$ cask update
```

以上です。
