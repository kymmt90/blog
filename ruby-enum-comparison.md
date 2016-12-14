<!-- Ruby (on Rails) で使える enumeration 実装を比較してみた  -->

こんにちは、GMO ペパボの人間です。これは [pepabo Advent Calendar 2016](http://qiita.com/advent-calendar/2016/pepabo) の 9 日目の記事です。

昨日は我らが CTL [けんちゃんくんさん](https://twitter.com/kenchan)の [「gemビルドしようとして `The validation error was 'yourgem-x.y.z contains itself (yourgem-x.y.z.gem), check your files list` と出たとき」](http://qiita.com/kenchan@github/items/ee7cf691232f597a2eb6) でした。

今日は Ruby, とくに Rails で使える enumeration 実装

- Enumerize
- `ActiveRecord::Enum`

の機能を比較してみました。

## 動機

私事ながら、仕事で Rails アプリケーションの開発をするようになって 1 か月経ちました。

コードを読んでいるといろいろと勉強になることが多いのですが、**Enumerize** という enumeration の gem が使われており、boolean を返す predicate（述語）メソッドや Active Record の scope を生成できるので便利〜という気持ちになっていました。

一方 Rails にも `enum` (`ActiveRecord::Enum`) があるのをなんとなく知っていたので、これらの違いが気になり、調べてみることにしました。

以下のコード例では `require 'enumerize'` しているものとします。また、`user` は `User` のインスタンスとします。

## Enumerize 概要

[The Ruby Toolbox の "ActiveRecord Enumeration" カテゴリでは 1 位](https://www.ruby-toolbox.com/categories/Active_Record_Enumerations)になっている gem です。

[https://github.com/brainspec/enumerize:embed:cite]

O/R マッパとは独立した gem なので、Active Record オブジェクトはもちろんのこと、プレーンな Ruby オブジェクトに対してもふつうに使えます。

次のようなコードで、クラスに enumeration を組み込めます。

```ruby
class User
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium]
end
```

## `ActiveRecord::Enum` 概要

**※名前が長いので以下 `enum` とします**

Rails 4.1 から入った機能です。名前空間が示すとおり、Active Record オブジェクトで使うのが前提となっています。

Active Record を継承したクラスへ次のように enumeration を組み込めます。

```ruby
class User < ActiveRecord::Base
  enum membership: [:free, :regular, :premium]
end
```

## 比較

上で例示した `User` のインスタンス `user` を使い、両者の主な機能について表にまとめてみました。

機能|Enumerize|`ActiveRecord::Enum`
-|-|-
値の更新|`user.membership = :member`|`user.member!`
文字列化|`user.membership.text`|`user.membership`
デフォルト値の設定|`default: :free`（lambda も渡せる）|DB のデフォルト値設定が別途必要
i18n 対応|デフォルトで対応|[`enum_help` が別途必要](https://github.com/zmbacker/enum_help)
predicate メソッド生成|`predicate: true` で生成|デフォルトで生成
scope 生成|`scope: true` で生成し、名前変更も可能|デフォルトで生成
prefix, suffix 生成|predicate だけ生成可能|predicate, 更新メソッドに生成可能（ただし Rails 5.0 から）
序数の取得|`user.membership.find_value(:free).value`|`user.membership[:free]`
複数値の保持|可能|不可能
テスト用のマッチャ|あり|なし

以下、かいつまんで見ていきます。

### 値の更新

`enum` は bang メソッドで更新できるのでちょっと短く書けて Ruby ぽいです。

```ruby
user.membership = :regular  # Enumerize
user.regular!               # enum
```

### デフォルト値の設定

Enumerize は enumeration の宣言部分でデフォルト値をオプションとして渡すことができます。

```ruby
class User
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium], default: :free
end
```

一方、`enum` ではマイグレーションの中でデフォルト値を設定する必要があります。

```ruby
class AddMembershipToUsers < ActiveRecord::Migration
  def change
    add_column :users, :memebership, :integer, default: 0
  end
end
```

### predicate, scope メソッドの生成

Enumerize は enumerize の宣言部分で predicate と Active Record の scope メソッドを生成するオプションを渡せます。scope は名前も変えられます。

```ruby
class User < ActiveRecord::Base
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium], predicates: true, scope: true
end
user.regular?  # predicate
user.with_membership(:premium)  # premium user だけ取得

# 自分で scope 名を指定できる
class User < ActiveRecord::Base
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium], scope: :having_membership
end
user.having_membership(:free)  # free user だけ取得
```

一方、`enum` は自動で predicate, scope の両メソッドを生成してくれています。ただし scope の名前は変えられません。そのぶんシンプルともいえます。

```ruby
class User < ActiveRecord::Base
  enum membership: [:free, :regular, :premium]
end
user.regular?  # predicate
user.premium  # premium user 取得
```

### プレフィックス／サフィックス生成

Enumerize は enumeration の宣言部分で predicate メソッド生成時に `prefix`, `suffix` オプションを渡すと、predicate メソッドのプレフィックス、サフィックスを生成できます。

```ruby
class User
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium], predicates: { prefix: true }
end
user.membership_free?

# 自分でプレフィックス名を指定できる
class User
  extend Enumerize
  enumerize :membership, in: [:free, :regular, :premium], predicates: { prefix: 'member' }
end
user.member_free?
```

`enum` にも Rails 5.0 からプレフィックス／サフィックス生成機能が入りました。`_prefix`, `_suffix` というアンダースコア付きのオプションを渡すと predicate, 更新メソッドの両方にプレフィックス／サフィックスを生成します。

```ruby
class User < ActiveRecord::Base
  enum membership: [:free, :regular, :premium], _prefix: true
end
user.membership_free!  # :free に更新

# 自分でプレフィックスを指定できる
class User < ActiveRecord::Base
  enum membership: [:free, :regular, :premium], _prefix: :member
end
user.member_premium?
```

### 複数値の保持

Enumerize は複数の値を保持できます。つまり、次のように、`multiple` オプションを渡すと、ある enumeration について複数状態を持てます。

```ruby
require 'active_support/core_ext/object/blank'  # << の中で blank? 使っているので必要

class User
  extend Enumerize
  enumerize :subscriptions, in: [:newspaper, :magazine, :podcast], multiple: true
end
user.subscriptions << :newspaper
user.subscriptions << :podcast
user.subscriptions  #=> #<Enumerize::Set {newspaper, podcast}>
```

### テスト用のマッチャ

Enumerize では [RSpec などのマッチャが使えます](https://github.com/brainspec/enumerize/blob/master/README.md#rspec)。

```ruby
describe User do
  it { is_expected.to enumerized(:membership) }
end
```

## まとめ

Enumerize のほうが `ActiveRecord::Enum` よりまだ機能は多いということがわかりました。とくに、Enumerize にはデフォルトの i18n 対応、デフォルト値設定や scope 名設定の柔軟さがあるのはよい点だと思います。独立した gem であることから、プレーン Ruby オブジェクトや Mongoid オブジェクトで使えるようになっているのもよいですね。

とはいえ、Rails 4.1 以降では、`ActiveRecord::Enum` で Rails の機能の一部として enumeraion の基本機能や predicate や scope の生成と言った機能が使えるようになっていることがわかりました。ですので、プロジェクトによっては、これぐらいのシンプルさで十分ということもあると思います。Rails 5.0 へのアップデートが必要になるものの、`_prefix`, `_suffix` も使えるようになっていることも知れたのでよかったです。

とくに結論はないですが、ご参考になればということで。興味を持った方は下記の公式ドキュメントをご参照ください。

- [enumerize/README.md at master · brainspec/enumerize](https://github.com/brainspec/enumerize/blob/master/README.md)
- [ActiveRecord::Enum](http://api.rubyonrails.org/classes/ActiveRecord/Enum.html)
