<!-- はてなブログライターを作った -->

はてなブログに CLI で投稿できる**はてなブログライター** (0.1.0) を Ruby で作ってみました。

- [kymmt90/hatenablog-writer](https://github.com/kymmt90/hatenablog-writer)

# 概要

ローカルの Markdown ファイルの内容をはてなブログへ投稿します。

    $ vi foo.md
    タイトル 1
                        # 2 行目は空白にする
    ここが内容です。

    $ vi bar.md
    タイトル 2

    **Markdown** で書けます。

    $ hw foo.md bar.md   # はてなブログへ二つのエントリを投稿

# その他

[hatenablog gem](https://github.com/kymmt90/hatenablog)を使っているので、OAuth の設定などは以下のリンクを参考にしてください。

- [Ruby ではてな OAuth のアクセストークンを取得する](http://kymmt90.hatenablog.com/entry/hatena_oauth)

現状、このツールはローカルの Markdown ファイルの 2 行目に処理の都合からエントリ ID を書き込むようになっています。これは筋が悪い気がするので、代替案を検討中です。
