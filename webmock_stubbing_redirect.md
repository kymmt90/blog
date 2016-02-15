<!-- Webmock でリダイレクトが絡む HTTP 通信をスタブ化する -->

テストのために、リダイレクトが絡む HTTP 通信をスタブ化したい場合があります。

例えば、Web スクレイピングをするときに、[Mechanize](https://github.com/sparklemotion/mechanize) を使うと以下のようにログイン処理を書けます。HTTPS になっていないとかは気にしないでください。

```ruby
require 'mechanize'

def log_in(mail, password)
  agent = Mechanize.new
  next_page = nil
  agent.get('http://www.example.com/login') do |page|
    next_page = page.form_with(action: '/login') do |form|
      form.field_with(name: 'mail').value = mail
      form.field_with(name: 'password').value = password
    end.submit
  end
  next_page # -> ログイン後のページが入っている
end
```

この処理の裏での HTTP 通信に着目すると、以下のような実装になっていることがあります。

1. ログインフォームによって `http://www.example.com/login` へ POST して認証に成功する
2. 302 リダイレクトがレスポンスとして返ってくる
3. リダイレクト先であるログイン後のページを GET する
4. ログイン後のページがレスポンスとして返ってくる

この通信をスタブ化する方法を調べました。

<!-- more -->

# Webmock によるリダイレクトのスタブ化

[Webmock](https://github.com/bblimke/webmock) を使って、以下のようにコードを書くとできました。

```ruby
stub_request(:post, 'http://www.example.com/login')
  .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })
stub_request(:get, 'http://bookmeter.com/')
  .to_return(body: 'contents', headers: { 'Content-Type' => 'text/html' })
```

一つ目の `stub_request` では、例えばログインのために `http://www.example.com/login` に POST すると、ログインが成功したとして 302 リダイレクトが帰ってくるようにスタブを設定しています。このとき、`to_return` の引数で与えているように、レスポンスヘッダ内の `Location` を `'/'` とすることで、リダイレクト先が `http://www.example.com/` であることを示しています。

二つ目の `stub_request` では、リダイレクトされた先の `http://www.example.com/` を GET することで、正常なレスポンスが返ってくるようにスタブを設定しています。

以上のスタブの設定によって、

1. リクエスト：`/login` へ POST（ログイン処理） -> レスポンス：`/` へのリダイレクト
2. リクエスト：`/` へ GET -> レスポンス：`/` の内容（ログイン後のページ）

という流れをスタブ化することができます。

# 余談

302 が返ってきたときに GET で自動リダイレクトするのは、実は RFC に違反しているらしいです。

- [POST をリダイレクトすると GET になる件について調べた - 理系学生日記](http://kiririmode.hatenablog.jp/entry/20131202/p1)


> Note: RFC 1945 and RFC 2068 specify that the client is not allowed to change the method on the redirected request. However, most existing user agent implementations treat 302 as if it were a 303 response, performing a GET on the Location field-value regardless of the original request method. The status codes 303 and 307 have been added for servers that wish to make unambiguously clear which kind of reaction is expected of the client.

> 訳) RFC 1945 と RFC 2068 では、リダイレクト時のリクエストにおけるメソッドの変更は許されてないとしている。にも関わらず、ほとんどの既存ユーザエージェントの実装は、302 をあたかも 303 のようにみなし、元々のリクエストメソッドに関わらず Location ヘッダで示される値(URI)に GET リクエストをしかけている。303 や 307 は、クライアントに期待する振舞いがどちらかをサーバがはっきり示すために追加された。
