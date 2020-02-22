<!-- テキストの校正用に textlint を導入してみた -->

textlint は Markdown のようなテキスト向けの
[lint](https://ja.wikipedia.org/wiki/Lint)
ツールです。テキストを静的解析し、あらかじめ決められたルールによって、テキスト上のミスや読みにくい点などを指摘してくれます。textlint は azu 氏によって JavaScript で開発されています。

[https://textlint.github.io:embed:cite]

特徴としては、lint 用のルールがプラガブルであること、つまり静的解析時に使うルールを自由に追加できることがあります。日本語のルールはもちろんありますし、作成すれば、それ以外の言語のルールも使えます。内部的には Markdown をパースして AST に変換し、AST 上を走査しながら、ルールが AST の構造にマッチするかチェックしているようです。

ブログを書くときなどに有用そうだと思い、今回 textlint を導入してみました。

# 導入方法

azu 氏の以下ブログエントリを参照して導入しました。

- [textlintで日本語の文章をチェックする | Web Scratch](http://efcl.info/2015/09/10/introduce-textlint/)
- [ルールプリセットを使ってお手軽にtextlint入門 | Web Scratch](http://efcl.info/2015/12/30/textlint-preset/)

私自身の作業をメモしておきます。

## textlint とルールのインストール

textlint とルールは npm からインストールできます。今回は次のルールを導入しました。

- [textlint-rule-preset-japanese](https://github.com/azu/textlint-rule-preset-japanese)
  - 技術系日本語文書用のルール集
- [azu/textlint-rule-prh: textlint rule for prh.](https://github.com/azu/textlint-rule-prh)
  - 表記ゆれチェック用ツール [proofread-helper](https://github.com/vvakame/prh) (prh) を textlint から扱えるようにしたルール
  - 表記ゆれ例：「通り」と「とおり」や「クエリ」と「クエリー」など

次のコマンドで textlint とルールをインストールできます。ここではグローバルインストールしています。

```
npm i -g textlint textlint-preset-japanese textlint-prh
```

## prh の表記ゆれ辞書の作成

prh は YAML 形式の表記ゆれ辞書を使って、表記ゆれチェックをおこないます。今回は [prh に同梱されている](https://github.com/vvakame/prh/tree/master/misc)

- [techbooster.yml](https://github.com/vvakame/prh/blob/master/misc/techbooster.yml)
- [WEB+DB_PRESS.yml](https://github.com/vvakame/prh/blob/master/misc/WEB%2BDB_PRESS.yml)

を多少修正して使うことにしました。

## textlint の設定ファイル `.textlintrc` の作成

最後に、textlint の設定ファイル `.textlintrc` を作成し、次のような内容とします。中身は JSON です。

```json
{
    "rules": {
        "preset-japanese": true,
        "prh": {
            "rulePaths": [
                "./prh_basic_rules.yml",
                "./WEB+DB_PRESS.yml"
            ]
        }
    }
}
```

使うルールであれば `"preset-japanese"` のように値を `true` とすれば OK です。使うルールの設定をさらに書くときは、`"prh"` 配下の `"rulePaths"` のようにネストして書けば OK です。ここでは、prh が使う表記ゆれ辞書へのパスを `"rulePath"` の値に配列として指定しています。

辞書と設定ファイルを textlint を利用するディレクトリに置いておけば、textlint 実行時にそれらが読み込まれます。

# 使用例

Markdown で残しているこのブログのエントリから、今回は次のエントリに上記設定を施した textlint を適用してみます。

[http://blog.kymmt.com/entry/everyday_rails:embed:cite]

CLI から次のコマンドを実行します。

```
$ textlint everyday_rails.md
```

すると、次のようにチェック結果が表示されます。

[f:id:kymmt90:20160628204059p:plain]

さらに、`--format pretty-error` をつけて実行します。

```
$ textlint --format pretty-error
```

すると、次のようにテキスト中の指摘されている部分を詳しく見ることができます。

[f:id:kymmt90:20160628214546p:plain]

緑色のチェックがついている項目は自動で修正可能です。自動で修正するには `--fix` オプションつきで textlint を実行します。

```
$ textlint --fix everyday_rails.md
```

自動で修正されたテキストの diff の一部を次に示します。便利ですね。

[f:id:kymmt90:20160628204102p:plain]

# おわりに

今回作成した表記ゆれ辞書と設定ファイルを以下からリンクしておきます。

- [Add textlint settings · kymmt90/blog@87e6c61](https://github.com/kymmt90/blog/commit/87e6c61c7587da07acf32b0206d36706d11bc8a5)

textlint で静的解析によって校正することで、効率よく文章のミス修正や読みやすさの改善が図れそうです。まだ誤爆っぽい指摘もあるので、今後ルールや辞書を適宜調整しつつ使ってみたいと思います。

また、引き続き、textlint を Emacs の flycheck に組み込んでみたいところです。
