<!-- アソシエーションのscopeを使いつつLIMITっぽいことをやる -->

細かすぎて伝わらないかもしれませんが、ハマったので共有します。

## 問題

ユーザーが免許を持つ次のようなモデルを考えます。`has_one :license`は免許更新を重ねてきたなかで最新の免許を取得したくて書いたと思ってください。

```ruby
class User < ApplicationRecord
  has_many :licenses
  has_one :license, -> { order(created_at: :desc).limit(1) }
end
```

「Userが2件のLicenseを持つ」というセットを3件作って、それぞれのUserの最新のLicenseが取りたいので、`license`をeager loadして`license`をそれぞれのUserに対して呼んでみると、次のような結果になります。

```ruby
User.includes(:license).map(&:license)
#=> [nil,
#    nil,
#    #<License:0x00007fb67bfbbbf0
#     id: 6,
#     code: "4934",
#     user_id: 3,
#     created_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00>]
```

それぞれのUserの最新のLicenseが取りたかったのですが、`nil`が入っており期待と違う結果になりました。このときにActive Recordが生成するクエリは次のような感じです。`licenses`テーブルの該当レコードをすべて取得したあとにLIMITしてしまうので、該当レコードすべての中の最新レコード1件しか取れていないようです。

```
SELECT "users".* FROM "users"
SELECT "licenses".* FROM "licenses" WHERE "licenses"."user_id" IN (?, ?, ?) ORDER BY "licenses"."created_at" DESC LIMIT ?  [["user_id", 1], ["user_id", 2], ["user_id", 3], ["LIMIT", 1]]
```

一方、次のように`licenses`（複数形）を`includes`すると取得結果は正しくなりますが、ORDER BY DESCを使うクエリとそうではないクエリに分かれてしまい、N+1問題が発生してしまいます。

```ruby
User.includes(:licenses).map(&:license)
#=> [#<License:0x00007fb680000288
#     id: 2,
#     code: "326",
#     user_id: 1,
#     created_at: Sun, 29 Apr 2018 11:14:59 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:14:59 UTC +00:00>,
#    #<License:0x00007fb67bfe7c28
#     id: 4,
#     code: "8028",
#     user_id: 2,
#     created_at: Sun, 29 Apr 2018 11:15:24 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:15:24 UTC +00:00>,
#    #<License:0x00007fb67bfdf4d8
#     id: 6,
#     code: "4934",
#     user_id: 3,
#     created_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00>]
```

```
SELECT "users".* FROM "users"
SELECT "licenses".* FROM "licenses" WHERE "licenses"."user_id" IN (?, ?, ?)  [["user_id", 1], ["user_id", 2], ["user_id", 3]]
SELECT  "licenses".* FROM "licenses" WHERE "licenses"."user_id" = ? ORDER BY "licenses"."created_at" DESC LIMIT ?  [["user_id", 1], ["LIMIT", 1]]
SELECT  "licenses".* FROM "licenses" WHERE "licenses"."user_id" = ? ORDER BY "licenses"."created_at" DESC LIMIT ?  [["user_id", 2], ["LIMIT", 1]]
SELECT  "licenses".* FROM "licenses" WHERE "licenses"."user_id" = ? ORDER BY "licenses"."created_at" DESC LIMIT ?  [["user_id", 3], ["LIMIT", 1]]
```

## ある解決策

`licenses`のscopeでソートしつつ、インスタンスメソッド化した`User#license`のなかで`ActiveRecord::Associations::CollectionProxy#take`すると、期待どおり動くようです。

```ruby
class User < ApplicationRecord
  has_many :licenses, -> { order(created_at: :desc) }

  def license
    licenses.take
  end
end
```

License取得時は`licenses`（複数形）をeager loadします。

```ruby
User.includes(:licenses).map(&:license)
#=> [#<License:0x00007fb680000288
#     id: 2,
#     code: "326",
#     user_id: 1,
#     created_at: Sun, 29 Apr 2018 11:14:59 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:14:59 UTC +00:00>,
#    #<License:0x00007fb67bfe7c28
#     id: 4,
#     code: "8028",
#     user_id: 2,
#     created_at: Sun, 29 Apr 2018 11:15:24 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:15:24 UTC +00:00>,
#    #<License:0x00007fb67bfdf4d8
#     id: 6,
#     code: "4934",
#     user_id: 3,
#     created_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00,
#     updated_at: Sun, 29 Apr 2018 11:15:26 UTC +00:00>]
```

`licenses`に対してORDER BY DESCするクエリを1回だけ発行して、Ruby側では取得済みレコードに対して`take`でデータを取るので、N+1問題を回避できています。

```
SELECT "users".* FROM "users"
SELECT "licenses".* FROM "licenses" WHERE "licenses"."user_id" IN (?, ?, ?) ORDER BY "licenses"."created_at" DESC  [["user_id", 1], ["user_id", 2], ["user_id", 3]]
```
