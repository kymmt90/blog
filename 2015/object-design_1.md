<!-- 『オブジェクトデザイン』読書メモ：第 1 章「設計概念」 -->

以下のスライドなどを読んだのがきっかけで、Wirfs-Brock の『[asin:4798109037:title]』を読んでいます。

- [オブジェクト指向の設計と実装の学び方のコツ](http://www.slideshare.net/masuda220/ss-14263541)

ブログにメモを書きながら、とりあえず第 6 章の内容までは読み解きます。今回は第 1 章についてメモ。

# 1 設計概念

- この本で利用する設計の概念、用語について説明
  - **ロール**
  - **コラボレーション**
  - **ロールステレオタイプ**
  - など

## 1.1 オブジェクト機構

- アプリケーションの構成
  - **アプリケーション**は**オブジェクト**から構成
  - オブジェクトは 1 個以上の**ロール**を実装
  - オブジェクトは**契約**に基づいてメッセージを送信しあい、相互に作用（**コラボレーション**）

- **ロール**
  - 関連する**責務**の集合のこと

- **責務**
  - タスクを実行する義務
  - 情報を知っている義務

## 1.2 ロール

- ロール
  - **単体のオブジェクトが実現する機能のこと**
  - オブジェクトの責務を遂行することで実現
  - 実現方法は交換可能

## 1.3 オブジェクトのロールステレオタイプ

- ロールを意図的に単純化したもの
  - **情報保持役**
  - **構造化役**
  - **サービス提供役**
  - **調整役**
  - **制御役**
  - **インターフェース役**
- あるオブジェクトは複数のロールステレオタイプを保持可

## 1.4 ロール、責務、コラボレーション

- **地域** (neighborhood)
  - ある特定の機能を果たすオブジェクトの集合、サブシステム
  - オブジェクト群は地域内でコラボレート

- オブジェクトはロールの集合を具体化したもの

## 1.5 オブジェクトの契約

### 1.5.1 使用条件保証と事後結果保証

- 使用条件保証 = 事前条件
- 事後結果保証 = 事後条件
- オブジェクトは、条件を満たす要求に対してのみ、正しくレスポンスする義務あり

## 1.6 ドメインオブジェクト

- ドメインオブジェクト
  - 問題領域のモノを表現するオブジェクト
  - 開発はドメインオブジェクトから始まり、追ってドメインオブジェクト間の相互作用を設計
    - その過程で、制御役などのアプリケーション固有のオブジェクトが登場

## 1.7 アプリケーション固有のオブジェクト

- アプリケーション固有のオブジェクト
  - アプリケーションを動作させるために必要なオブジェクト
    - 制御
    - データ変換、処理……
    - 外部インタフェースとの接続

- ドメインオブジェクトと対をなす
- **ドメインオブジェクト、アプリケーション固有オブジェクトの両方を結び付ける視点が設計者には必要**

## 1.8 インターフェース

- オブジェクトは公開インターフェースを実装
    - 利用条件も明記
    - 期待されるサービスとその利用条件のみを公開（情報隠蔽）

## 1.9 クラス

### 1.9.1 2 つのロール

- クラスは以下の二つのロールを担当
  - インスタンスを生み出す工場としてのロール
  - オブジェクトとしてのロール（クラスメソッドにより実現？）

## 1.10 コンポジション

- **継承と比較して非常に柔軟**
- 実行中に動的に委譲する部品を変更可能

## 1.11 継承

- **コンポジションと比較すると静的**
- コンパイル時にオブジェクト間の関係が決定

## 1.12 オブジェクトの組織

- オブジェクト間の連携（連合）がより高いレベルの概念を構成
- 連合自体も特定の責務を保持

## 1.13 コンポーネント

- 多数のサービスをまとめ、その実装を隠蔽しインターフェースのみ外部に公開
- 再利用を実現

## 1.14 パターン

- GoF
- パターンを使うことで以下の利点あり
  - 技術的コミュニケーションにおける語彙として利用可能
  - あらゆるドメインに対して適用可能
  - 利用されているパターンを見ることで、新たな開発者がシステムの構成を判断可能

## 1.14.1 ある特定の問題に対する Double Dispatch パターンの適用

- パターンを使うことで、コラボレーションの方法についての説明が不要
  - より高い抽象度での議論（パターンの適合性、パターン採用の動機、そのトレードオフなど）が可能

## 1.15 フレームワークス社

（「フレームワークス社」？）

- フレームワークの利点
  - 設計／コーディングの削減による効率向上
  - ドメイン知識を内包
  - フレームワークのアプローチに合わせることにより一貫性を保持
  - アプリケーションが完成させられるかどうかを予測可能

- フレームワークの欠点
  - 学習曲線が急勾配
  - 特定のアプローチのみ対応可能
  - 性能を犠牲にした柔軟性

- フレームワークに合うように設計し、コードを書く必要がある

## 1.16 アーキテクチャ

- アーキテクチャ = アプリケーションの構造と各コンポーネントの振る舞い
- アーキテクチャのある記述方法はアーキテクチャのある一面のみ表現

## 1.17 アーキテクチャスタイル

- パターン
  - 複数オブジェクト間で責務を分配する方法

- アーキテクチャスタイル
  - コンポーネント相互作用、制御の方法

### 1.17.1 集中型制御スタイル

- 集中制御オブジェクトと複数の情報保持役オブジェクトから構成
- 情報保持役に逐次問い合わせながら処理を実行
- ロジックがあるオブジェクトに集中

### 1.17.2 分散型制御スタイル

- 各オブジェクトは最低限の情報しか持たず、外部依存性が現象
- ロジックが各オブジェクトに分散

### 1.17.3 委譲型制御スタイル

- 集中型と分散型のハイブリッド
- 各調整役が他の調整役とコラボレートすることで全体の処理を実現

### 1.17.4 相互作用の考察：レイヤアーキテクチャの例

- レイヤ内のオブジェクトは別のレイヤのどのオブジェクトとコラボレートするべきか考慮不要

### 1.17.5 レイヤにオブジェクトを配置する

- ロールステレオタイプをレイヤアーキテクチャの各レイヤに配置
- 上から下のレイヤへとメッセージが送信され、その結果は下から上へと送信
- イベント通知型の処理の場合、下から上にメッセージ送信

## 1.18 設計記述

- UML は言語
  - 各シンボルにはしっかりと定義された意味が存在
  - ゆえに誰が読んでも解釈が一意に定まり精密

- CRC カードなど、よりインフォーマルなものもあり、場合に応じて利用

# 参考文献

[asin:4798109037:detail]
