<!-- Ruby でメソッド呼び出しのフック処理を実行する -->

# 問題

Ruby でなんらかのメソッドを呼び出しにともなって、特定の処理を実行したい場合、つまり、**メソッド呼び出しのフック処理を実行したい**状況を考えます。

# 解決法

**エイリアスチェイニング**という方法で実現します。エイリアスチェイニングについては、『Effective Ruby』の項目 33 「エイリアスチェイニングで書き換えたメソッドを呼び出そう」を参照しました。

例えば、`Array#at` を呼び出すたびに、その引数と返却値を標準出力にログ出力するようにしたいとします。

```ruby
arr = [1, 2, 3]
arr.at(0)
# calling at
# returned -> 1
```

これを実現するには、`Array#at` に新たに処理を差し込む必要があります。このために、以下のステップを踏む必要があります。

1. `alias_method` によって処理を変更したいメソッドの退避用エイリアスを作成
2. `define_method` によって元のメソッドの処理を変更する

この処理を実行するメソッド `log_method` を持つモジュール `LogMethod` を定義します。

```ruby
module LogMethod
  def log_method(method)
    # 引数 method にログ出力処理を差し込む
  end
end
```

この `log_method` の中身について説明します。

## 1. `alias_method` によって処理を変更したいメソッドのエイリアスを作成

あるメソッドを、`alias_method` によって別の名前 `orig` に退避します。ここでは `method` にメソッド名が入っているとします。

```ruby
orig = "#{method}_without_logging".to_sym         # 退避用メソッド名作成
if instance_methods.include?(orig)
  raise NameError, "#{orig} isn't a unique name"  # すでにあるメソッド名前が被っていれば例外をあげる
end
alias_method orig, method                         # method で示されるメソッドを orig (= "#{method}_without_logging") でも示せるようにする
```

## 2. `define_method` によって元のメソッドの処理を変更する

元のメソッドの処理を `define_method` によって書き換えます。

```ruby
define_method(method) do |*args, &block|
    $stdout.puts "calling '#{method}'"        # 元のメソッドの前に差し込む処理（メソッド名表示）
    result = send(orig, *args, &block)        # orig, つまり元のメソッドを引数とブロックを伴って呼び出し
    $stdout.puts "returned -> #{result.to_s}" # 元のメソッドの後に差し込む処理（返却値表示）
    result                                    # 元のメソッドの返却値
end
```

以上の処理を持つメソッド `log_method` を持つモジュール `LogMethod` を任意のクラスで `extend` し、`log_method` にログ表示処理を差し込みたいメソッド名をシンボルで指定することで、そのメソッド実行時にログが表示されるようになります。ここでは `Array` を `LogMethod` で `extend` し、`Array#at` にログ表示処理を差し込みます。

``` ruby
Array.extend LogMethod
Array.log_method(:at)
[2, 3, 4].at(1)
# 以下の内容が標準出力に表示される
# calling at
# returned -> 3
```

# 複数のメソッドに対して外からフック処理を設定

上述した `log_method` をちょっと改変して、メソッド `hook_method(hook, *methods)` を以下のように書くと、複数メソッドに対して一括で外からフック処理を設定できます。引数 `hook` が差し込む処理、`*methods` がメソッド名シンボルです（可変長引数）。ここでは、元のメソッドを呼び出したあとに、`hook` を呼び出しています。

```ruby
module HookMethod
  def hook_method(hook, *methods)
    methods.each do |method|
      orig = "#{method}_without_logging".to_sym
	  if instance_methods.include? orig
        raise NameError, "#{orig} isn't a unique name"
      end

      alias_method orig, method

      define_method(method) do |*args, &block|
        result = send(orig, *args, &block)
        send(hook) # フックメソッド呼び出し
        result
      end
    end
  end
end
```

これを使うと、複数のメソッドに対して、以下のように外からフックさせるメソッドを指定できます。

``` ruby
def print_message
  puts 'hook message'
end
Array.extend HookMethod
# Array#first, Array#at の呼び出し後に print_message を実行する
Array.hook_method(:print_message, :first, :at)
puts [1, 2, 3].first
puts [2, 3, 4].at(1)
# 以下の内容が標準出力に表示される
# hook message
# 1
# hook message
# 3
```

ここでは、`send(hook)` としているため、引数をとらないメソッドしかフックとして指定できませんが、やりようによっては引数をとるメソッドも指定できると思います。

# 参考

項目 33 「エイリアスチェイニングで書き換えたメソッドを呼び出そう」を参考にしました。

[asin:4798139823:detail]

最後に示した `hook_method` を含むコードの全体は以下の通りです。

<script src="https://gist.github.com/kymmt90/bcad30ff36f1f13a8637.js"></script>
