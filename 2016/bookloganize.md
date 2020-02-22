<!-- 読書メーター→ブクログ移行用スクリプトを書いた -->

読書メーターからブクログへ宗旨替えすることにしたので、データを移行したい気持ちになりました。

幸い、ブクログには CSV データによる読書データのインポート機能が備わっていたことと、私が以前読書メーターのスクレイピング gem である [bookmeter_scraper](https://github.com/kymmt90/bookmeter_scraper) を作っていたことから、ブクログへの移行用にスクリプト booklognize を書きました。

[https://github.com/kymmt90/bookloganize:embed:cite]

このスクリプトで移行できるのは次のデータです。

- 自分が登録した本
- 読書ステータス
  - 読んだ
  - いま読んでる
  - 積読
  - 読みたい
- 読了日（既読本のみ）

読書メーターで複数回読了日を記録している書籍（再読本）については、最後に読んだ日を読了日とします。

# 移行方法

次の流れで進めます。

1. bookloganize でブクログへのインポート用 CSV を作成
2. ブクログへインポート

## bookloganize でブクログへのインポート用 CSV を作成

bookloganize で読書メーターからデータを取得し、ブクログへのインポート用 CSV を作成します。bookloganize はただの Ruby スクリプトなので、ダウンロードすれば使えます。`thor` と `bookmeter_scraper` が必要なので、適宜インストールします。また、bookloganize は結果を標準出力に出力します。詳細は README を参照してください。

- [bookloganize/README.md at master · kymmt90/bookloganize](https://github.com/kymmt90/bookloganize/blob/master/README.md)

また、ブクログへインポートする CSV の文字コードは Shift_JIS とする必要があります。だいたい次のようなコマンドで所望の CSV が作成できると思います。

```
$ git clone https://github.com/kymmt90/bookloganize.git
$ gem install thor bookmeter_scraper
$ ruby bookloganize.rb csv <読書メーターのメールアドレス> <読書メーターのパスワード> | iconv -f utf-8 -t sjis >books.csv
```

CSV は次ページの「ブクログ形式」にしたがったものとなっています。

- [まとめて登録 (CSV)](http://booklog.jp/input/file)

        CSVファイルは、以下の項目順で1アイテムにつき1行として作成してください。
        サービスID, アイテムID, 13桁ISBN, カテゴリ, 評価, 読書状況, レビュー, タグ, 読書メモ(非公開), 登録日時, 読了日

## ブクログへインポート

次のページから、CSV を使ってブクログへ読書データをインポートできます。

- [まとめて登録 (CSV)](http://booklog.jp/input/file)

なお、読書メーターのオリジナル本機能による本を登録している場合、そのデータはブクログへ移行できません。
