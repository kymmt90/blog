<!-- Emacs のパッケージ管理に Cask を導入した -->
OS X の Emacs 環境に Cask を導入しました。

Cask によって、Emacs 環境が依存する elisp のリストをファイルに書き、そのファイルを読み込むことで、コマンドひとつで elisp のインストールやアップデートができるようになります。つまり、導入する elisp を `init.el` とは独立にリスト化できます。例えば、`auto-complete` をダウンロードするためには、`~/.emacs.d/Cask` というファイルに以下のように記述します。

```lisp
(source gnu)
(source melpa)
(depends-on "auto-complete")
```

最初の 2 行は探索するリポジトリの指定で、ELPA と MELPA から探索しています。3 行目で auto-compelete をダウンロードすることを指定しています。

導入手順をメモしておきます。今回の環境は以下の通りです。

- OS X Yosemite 10.10.2
- GNU Emacs 24.4.1
- Cask 0.7.2

## Cask のインストール

OS X では Homebrew を使うとすぐにインストールできます。

```
$ brew install cask
```

## `Cask` の記述

依存パッケージリストを `~/.emacs.d/Cask` に記述します。例えば、以下のような感じです。

<script src="https://gist.github.com/kymmt90/bdf586065a109886ff23.js"></script>

## パッケージのダウンロード

`Cask` を保存しているディレクトリ、今なら `~/.emacs/` で、以下のコマンドを実行すると、`Cask` に書いたパッケージをダウンロードしてくれます。

```
$ cask update
```

## `init.el` の設定

`init.el` に Cask を使うための設定を書きます。

```lisp
(require 'cask "~/.cask/cask.el")
(cask-initialize)
```

この設定により、Cask で導入した elisp を使える状態にする処理（ロードパスの設定など）が走ります。

ここで、Homebrew でインストールすると、ホームディレクトリ直下に `.cask/cask.el` が作成されないようです。とりあえず、手動でシンボリックリンクを作って対応しました。

```
$ mkdir .cask
$ ln -s /usr/local/share/emacs/site-lisp/cask.el ~/.cask/cask.el
```

## パッケージのアップデート

以上で Cask が導入できました。導入済みのパッケージをアップデートしたいときは `.emacs.d` で

```
$ cask update
```

を実行すればアップデートできます。

# 参考

- [package.elから Caskに切り替えました - Life is very short](http://d.hatena.ne.jp/syohex/20140424/1398310931)
- [emacs のパッケージ管理を cask に変更した - willnet.in](http://willnet.in/132)
