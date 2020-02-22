<!-- IRB の評価値出力を抑える -->

小ネタです。

# 問題

要素の多い Hash などの中身を確認するために、IRB (`irb`) を使って、その Hash の中身を表示したいときがあります。

このとき、例えば `Mechanize::AGENT_ALIASES` を表示するために、コマンドを

```ruby
irb(main):002:0> pp Mechanize::AGENT_ALIASES
```

のように実行すると、コマンドによる出力と、IRB 自体が表示するコマンドの評価値の出力（ここでは最後の `=>` 以降）の両方が表示されます。

```bash
irb(main):002:0> pp Mechanize::AGENT_ALIASES
{"Mechanize"=>
  "Mechanize/2.7.4 Ruby/2.3.0p0 (http://github.com/sparklemotion/mechanize/)",
 "Linux Firefox"=>
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
 ...
 "Android"=>
  "Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2$26.76 Safari/537.36"}
=> {"Mechanize"=>"Mechanize/2.7.4 Ruby/2.3.0p0 (http://github.com/sparklemotion/mechanize/)","Linux Firefox"=>"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0", ..., "Android"=>"Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.76 Safari/537.36"}
```

コンソールがテキストを右端で折り返すようになっていると、IRB の評価値である改行なしの大量のテキストでコンソールが埋まり、読みにくいです。

# 解決法

実行したい処理の末尾に `; nil` をつけ足します。

```ruby
pp Mechanize::AGENT_ALIASES; nil
```

すると、IRB によるコマンド自体の評価値が `nil` になるので、以下の最終行のように、IRB による評価値の出力が `nil` になり、`pp` の出力だけ表示されます。よって、表示が見やすくなります。

```bash
irb(main):003:0> pp Mechanize::AGENT_ALIASES; nil
{"Mechanize"=>
  "Mechanize/2.7.4 Ruby/2.3.0p0 (http://github.com/sparklemotion/mechanize/)",
 "Linux Firefox"=>
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0",
 ...
 "Android"=>
  "Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.76 Safari/537.36"}
=> nil
```

# 参考

- [ruby - How to suppress Rails console/irb outputs - Stack Overflow](http://stackoverflow.com/questions/4678732/how-to-suppress-rails-console-irb-outputs)
