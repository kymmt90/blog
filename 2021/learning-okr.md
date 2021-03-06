<!-- OKRについて調べていた -->

今年から会社で導入されているOKRについて、結局どうやっていけばうまく運用できるのかわかっていなかったので、入門書を読んで調べていた。

## OKRとは

[OKR - Wikipedia](https://en.wikipedia.org/wiki/OKR)

> a goal-setting framework for defining and tracking objectives and their outcomes.

特徴的なのは、それなりに背伸びした成果((『OKR』では「10分の5の自信度」という表現が出てくる))（ストレッチ・ゴール）を目標の達成度を測る尺度として利用するところ。

## 読んだ本

- [OKR（オーケーアール）｜日経の本 日経BP](https://www.nikkeibp.co.jp/atclpubmkt/book/18/P55640/)
- [Measure What Matters（メジャー・ホワット・マターズ） | 日経の本 日本経済新聞出版](https://nikkeibook.nikkeibp.co.jp/item-detail/32240)

1冊目の『OKR』はそれなりにレビューで評価が高く最初に読むにはよさそうだったので選んだ。2冊目の『Measure What Matters』は元IntelでシリコンバレーのGoogle含む各企業にOKRを広めた[John Doerr](https://en.wikipedia.org/wiki/John_Doerr)の著作。原典に近そうだったので選んだ。

## 読書メモ

### 『OKR』

第1部は、とあるスタートアップがOKRを導入してみて1回失敗し、そのあともう一度トライしてうまくいくみたいな話。海外ドラマを見ている気分になる。

第2部でOKRというフレームワークについて説明。OKR設定については主に次のような注意点がある。

- objectives (O)
  - 定性的かつ時間的に短距離走になる目標
    - 四半期がよさそう
  - チーム内で完結する目標
    - 達成できなかったときに他のチームのせいにできない
- key results (KR)
  - Oの抽象的な表現の具体的な意味を定義する
  - KRは一般的に三つ
  - 自信度は10分の5 (50%?)
  - まず測定対象を決めて、そのあとムーンショットといえる値かどうかを話し合う
  - ビジネス指標と品質指標を組み合わせて相補的なものとする
  - ポジティブな尺度（加算方式）にする

機能別部署（技術部など特定の専門職だけが属する部署）の目標は必ずしもプロダクト・チームのOKRにつながらないので、プロダクト・チームのメンバーが機能別部署から仕事を命じれられた場合に混乱が発生する。なので、そういうタスクはプロダクト・チームの目標に組み込むのがいい、という記述がある。

このあたりは自分の所属しているチームがそもそもプロダクト横断で開発者体験やセキュリティを向上させるという機能別部署に近いチームというのもあり、そういうチームでOKRを考えるのは、一工夫いる感じがした。

OKRを日常の一部にするために、週始めにチェックイン、週終わりにウィンセッションを実施するとよいという話があった。それぞれ次のようなもの。

- チェックイン
  - 目標に向けてやるべき優先事項(P1)3件を決める
    - OKRに繋がるか熟考する
    - 複数の手順を要する濃い仕事を選ぶ
  - 今後1か月のプロジェクトの予定を共有する
  - OKR自信度の状況を更新する
    - 下がっている場合、対策を考える
      - 自信度が下がるのは、自力で解決できない問題、技術的、スケジュール的、外部との折衝などにおける問題が出てきた時
    - 時間が進むにつれて上がる方がいいっぽい？
  - 健康・健全性指標を確認する
    - チーム自身の健康、コードベースの健全性、顧客との関係など守りたい要素の状況を確認する
- ウィンセッション
  - 作業中のコード、デモを見せあう
  - チーム横断でやると盛り上がってよい
    - 軽食を用意して実施するとよい、会社はそういうところに投資すべきとか書いてあってよい

「よくあるOKRの失敗例」はゴールが多すぎる、ストレッチ・ゴールになっていない、などアンチパターン集になっていて参考になる。

そのほか、毎週のチーム状況報告メールの書きかたにも言及されているが、これはそのままやりたくない感じがする。エッセンスだけ抜き出してNotionなどのプラットフォームの上でうまくできればいいのかもしれない。

### 『Measure What Matters』

こちらの本はOKRを用いた会社のケーススタディがたくさん載っている。フレームワークのコツについて簡潔に説明しているような本ではなかった。むしろおもしろかったのは、著者がIntel時代にOKRを生み出した[Andy Grove](https://en.wikipedia.org/wiki/Andrew_Grove)と出会ってからの体験についてなどで、そのあたりは興味深く読んだ。

## 実践

そもそも改めてOKRについて調べたのは、2021年上期に所属チームで雰囲気でOKRをやっていて、惨憺たる結果に終わったからだった。OKRは1回は失敗するものらしいが、そもそも方法論もよくわかっておらず、チェックインの頻度も推奨されるものよりずっと少なかったので、失敗の仕方も悪い感じがした。

前回は第一四半期と第二四半期をまとめて一つの期間とし、OKRの目標を決めていた。しかし、状況は色々と変わるので、今回は第三四半期に絞って目標を定めてみることにした。目標を決めるときは『OKR』の「OKR設定ミーティングを開催する」を参考にしてチームで時間を取らせてもらった((その節は稚拙な進行で失礼しました))。Oはなんとか決まったが、それを測る自信度10分の5のストレッチが効いたKRを決めるために、まず現状（例えば、どれぐらい最新でないバージョンのパッケージが残っているか、とか）を把握したうえで目標を実現するKRの値を決める必要がある。このあたりを決めないとOKRが始まらないが、現状把握もそれなりに大変なので、ここが踏ん張りどころだと思う。

これまではスクラムっぽいなにかで2週間に1回ふりかえりとKPTを実施し、計画と称してタスクの優先順位を決めて、カンバンを運用していた。しかし、そもそも顧客への機能の提供に主眼を置いたプロダクト・チームではないこともあって、チームに渡された期限の決まっているタスク以外の開発者体験の改善のようなタスクをどのように進めるかが曖昧になりがちだった。この点はOKRのチェックインでかなり解決できるのではないかと考えている。目標を慎重に決めておけば、毎週始めのチェックインで現状のKRの値やKR自体の自信度を更新し、それらをもとに目標を達成するために必要な優先事項を3件挙げて、それに必要なタスクの優先順位を上げればよいので、フォーカスが絞られる。これらが従来のタスクの優先順位決めに代わるものになる。

週末はウィンセッションとして各自の作業の成果((CLIでなにかが動く、とか調べ物をしたドキュメントを見せる、とかでいい))を見せたりできればいいのかなと考えている。

というような感じでやっていくと、やるべきことにフォーカスして物事を進められるような気がする。2021年第三四半期は、ためしに上に述べたような方法を使ってチームでOKRを運用してみようと勝手に考えている。
