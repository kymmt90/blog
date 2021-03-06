<!-- 『Everyday Rails - RSpec による Rails テスト入門』を読んだ  -->

「テストのないコードはレガシーコード」という名言((『レガシーコード改善ガイド』より))があります。自動化されたテストがあることで、コードの変更が正しいかどうかをすぐに判断できます。そして、すばやく正確にコードを改修できるようになります。

そんなテストを効率的に書くための Ruby 用テスティングフレームワークとして、[**RSpec**](http://rspec.info) があります。Ruby や Rails を触るなかで、RSpec については Web で散発的に知識の習得をしていました。そんな中で、体系的な知識を得ておいたほうが後々効率的だと思い、今回『Everyday Rails - RSpec による Rails テスト入門』を読みました。

この本は Leanpub で購入できる電子書籍となっています。

[https://leanpub.com/everydayrailsrspec-jp:embed:cite]

なお、私の持っていた事前知識は次のような感じです。

- Rails チュートリアル（4.0 版）をやっていたので、RSpec の構文はなんとなく理解している
- 自作 gem のテストをなんとなくの知識の RSpec で書いたことがある
  - [bookmeter_scraper/spec at master · kymmt90/bookmeter_scraper](https://github.com/kymmt90/bookmeter_scraper/tree/master/spec)

# どんな本か

Rails アプリ用の RSpec を使ったテスト（スペックと呼ばれる）を一通り書けるようになる本です。基本的には、既存の Rails アプリにスペックを追加していくという形式で進みます。

内容としては、

- セットアップや設定ファイルの書きかた
- 構文、モデル・コントローラ・フィーチャの各スペックの書きかた
- 保守性の高いスペックを書くためのベストプラクティス
- 周辺ツールの使いかた

など、基本的な使いかたについて網羅的に解説されています。また、最後には、テスト駆動開発のレッド・グリーン・リファクタリングという流れで、新機能開発をおこなう章があります。

最新版では、対象の RSpec のバージョンは 3.1 となっています。

作者の Sumner 氏が本書で使っているコードのリポジトリを公開してくださっています。

[https://github.com/everydayrails/rails-4-1-rspec-3-0:embed:cite]

このリポジトリを `git clone` して各章のブランチをチェックアウトし、写経しながら読み進めるのがよいかと思います。

# 読んで身についたこと

この本を読むことで身についたと私が感じたことがらは次のような感じでした。

## 1. コントローラに対するスペックの書きかた

コントローラのアクションやロール（管理者、一般ユーザの区分など）動作確認のスペックの書きかたについて、あらためて確認できました。

オープンソースの Rails アプリなどでは、コントローラは得てして薄いためにテストが書かれず、フィーチャスペックをもって代えられることが多いようです。しかし、本書では、

- コントローラはメソッドを持った立派なクラスであること
- フィーチャスペックより書くのが楽であるため

などの理由からテストしたほうがよいと述べられており、なるほどという感じでした。

## 2. 統合テストのためのフィーチャスペックの書きかた

- JavaScript を使っている機能のテスト
- Capybara と連携したブラウザでの操作の記述
- Selenium Webdriver と連携した自動ブラウザテスト

など、統合テストのための機能やツールを一通り確認できました。

ビュースペックは保守が大変であるため、代わりにフィーチャスペックでテストするのがよいらしいです。

## 3. ダミーデータの作成方法

ダミーデータを作成するための Factory Girl や Faker といったツールの使いかたについて確認できました。こういうツールの使いかたは、体系立てられた情報であらかじめ学んでおくと、その後の Web での調査もやりやすくなるのでよいですね。

特に、Factory Girl については、Rails チュートリアル（4.0 版）では出てこなかった、モデルのアソシエーションに対応した機能やファクトリの継承について紹介されており、勉強になりました。

# おわりに

この本の内容を頭に叩き込んでおけば、あとは自力での情報収集でキャッチアップしていけそうだと思いました。そもそも RSpec についてまとまっている日本語書籍というのはこれしかないと思いますし、RSpec を一通り身につけたい人にはぴったりだと思います。

本書には Minitest でテストを書くという日本版追加コンテンツ『Rspec ユーザのための Minitest チュートリアル』もあります。こちらは未読なので、引き続き読んでみるつもりです。
