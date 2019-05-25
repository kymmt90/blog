<!-- Active Recordでstring型属性を暗号化するためのRailsプラグインを作った -->

複数プロジェクトで、Active Recordのstring型を拡張して透過的に文字列を暗号化／復号できる型をattributes API（`ActiveRecord::Attributes`) を使って書く場面を目撃したり、自分でも書く機会があったので、Railsプラグインに切り出してみました。

[https://github.com/kymmt90/active_record-type-encrypted_string:embed:cite]

使い方は次のとおりです。

```ruby
# users.tokenはstring型
class User < ActiveRecord::Base
  attribute :token, :encrypted_string
end

# 環境変数かconfigで設定する
ENV['ENCRYPTED_STRING_PASSWORD'] = 'password'
ENV['ENCRYPTED_STRING_SALT'] = SecureRandom.random_bytes
# ActiveRecord::Type::EncryptedString.encryption_password = 'password'
# ActiveRecord::Type::EncryptedString.encryption_salt = SecureRandom.random_bytes

# DB内では暗号化されているがオブジェクト経由で取り出すと復号されている
user = User.create(token: 'token_to_encrypt')
ActiveRecord::Base.connection.select_value('SELECT token FROM users') #=> "eVZzbUlXME1xSlZ5ZWZPQnIvY..."
user.token #=> "token_to_encrypt"
```

内部的には [`ActiveSupport::MessageEncryptor`](https://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html) を使う、よくある実装になっています。gemにすることですぐに使えるようになって便利ですね。
