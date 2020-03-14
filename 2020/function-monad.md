<!-- 関数をFunctor/Applicative/Monadにする -->

[『プログラミングHaskell 第2版』](https://www.lambdanote.com/collections/haskell)の12章「モナドなど」の演習((12.5「練習問題」の2, 3, 6))で型 `(a ->)` をFunctor（関手）、Applicative、Monadにするという問題があり、少しわかりにくかったので、いまの自分自身の理解をまとめました。

## 型(a ->)とは

部分適用された関数の型を`(a ->)`（もしくは`->`を2引数関数とみて`((->) a)`）と表現する((一般的にはrを使って(r ->)と書くが、ここでは本の記法にしたがって(a ->)とする。参考:["Functors, Applicative Functors and Monoids"](http://learnyouahaskell.com/functors-applicative-functors-and-monoids#functors-redux)))。この型の意味は「`a`を部分適用済みの関数」である。部分適用するのは、ある型をFunctorにするには型コンストラクタが持つ型変数が1つでなければならないことによる。

実際のインスタンス宣言は[Control.Monad](https://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Monad.html)に存在する。

## Functorにする

「型変数を持つならモナドになるか試してみるのが自然な流れ」と書いてあるので、`(a ->)`もMonadにしていく。

まずFunctorにする。Functorにするには`fmap`を定義する必要がある。演習問題のヒントに書いてあるとおり、`(a ->)`に対する`fmap`の型がどうなるかを考える。Functor型クラスにおける`fmap`の型は次のとおり。なお、`a`という変数は`(a ->)`で使われているので、これ以降新たに現れる型変数は`b`から始める。

```haskell
fmap :: (b -> c) -> f b -> f c
```

まず第2引数`f b`から考える。今回`(a ->)`をFunctorにするので、ある構造を表す`f`が`(a ->)`に該当する。つまり、`f`は「引数として取る型の値を返す部分適用済みの関数であること」を表す。つまり`f b`と書くと`a -> b`となる。ここから`(a ->)`に対して`fmap`の型を次のように表現できる:

```haskell
fmap :: (b -> c) -> (a -> b) -> (a -> c)
```

この`fmap`の型をよく見ると、関数合成そのものになっている。よって、`(a ->)`は次のようにFunctorとできる。

```haskell
instance Functor ((->) a) where
  fmap = (.)
```

## Applicativeにする

続いて、`(a ->)`をApplicativeにするには`pure`と`<*>`を定義する。Applicative型クラスにおける`pure`と`<*>`の型は次のとおり。

```haskell
pure :: a -> f a
(<*>) :: f (a -> b) -> f a -> f b
```

まず`pure`から考える。型`b`を持つある値を`(a ->)`の文脈に持ち込むと考えると、型`b`の値を受け取り、つねにその値を返す関数`(a -> b)`を返せばよい。

```haskell
pure :: b -> (a -> b)
```

これは`b -> a -> b`と見なせるので[`const`](https://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html#v:const)と同じである。

次に`<*>`も型から考える。これまでどおり`f`を部分適用済みの関数`(a ->)`と見なすと、

- `f b`は`a -> b`
- `f c`は`a -> c`
- `f (b -> c)`は`a -> b -> c`

となる。よって

```haskell
(<*>) :: (a -> b -> c) -> (a -> b) -> (a -> c)
```

となる。

結果の型が`a -> c`という関数なので、ある引数`f`と`g`に関して、`f <*> g`は型`a`の1引数関数と考えればよい。また、関数`a -> b -> c`と関数`a -> b`に型`a`の値を適用すると、関数`b -> c`と型`b`の値になる。型`c`を返す関数を作る必要があるので、後者の`b`の値を関数`b -> c`に適用すればよい。これらを合わせて、次のように`(a ->)`をApplicativeにすることができる。

```haskell
instance Applicative ((->) a) where
  pure = const
  f <*> g = \a -> f a (g a)
```

ここでは`g a`が型`b`の値、`f a`が関数`b -> c`である。

関数がApplicativeだと、二つの関数をそれぞれ適用して結果を足すコードを逐次的に書けたりする。

```haskell
f = fmap (+) (+ 5) <*> (* 100) -- 5足した値と100かけた値の合計
f 30 -- 3035
```

また、`pure`と`<*>`はそれぞれ[SKIコンビネータ](https://ja.wikipedia.org/wiki/SKI%E3%82%B3%E3%83%B3%E3%83%93%E3%83%8D%E3%83%BC%E3%82%BF%E8%A8%88%E7%AE%97)におけるKとSにあたる((12.5「練習問題」の3より))。

## Monadにする

最後に、`(a ->)`をMonadにする。Monadにするには`return`と`>>=`を定義する必要があるが、`return`は`pure`と同じなので`>>=`だけ考える。

型から考えると、Monad型クラスで`>>=`の型は次のように定義されている。

```haskell
(>>=) :: m b -> (b -> m c) -> m c
```

`m`を部分適用済みの関数`(a ->)`と見なすと、

- `m b`は`a -> b`
- `b -> m c`は`b -> a -> c`
- `m c`は`a -> c`

となる。よって

```haskell
(>>=) :: (a -> b) -> (b -> a -> c) -> (a -> c)
```

となる。

Applicativeと同様に結果の型が`a -> c`という関数なので、`(a -> b) >>= (b -> a -> c)`は型`a`の1引数関数と考えればよい。Applicativeのときと同じように考えると、次のように`(a ->)`をMonadにすることができる。

```haskell
instance Monad ((->) a) where
  return = pure
  f >>= g = \a -> g (f a) a
```

ここでは`f a`が型`b`の値、`g`が関数`b -> a -> c`である。

関数がMonadだと、Applicativeで実現した「二つの関数をそれぞれ適用して結果を足すコード」を次のようにdo記法で書ける。入力した数値（この例だと`30`）を環境として持ちながら計算していると見なせる(([Haskell 状態系モナド 超入門 \- Qiita](https://qiita.com/7shi/items/2e9bff5d88302de1a9e9#%E9%96%A2%E6%95%B0%E3%83%A2%E3%83%8A%E3%83%89)))。

```haskell
f = do
  g <- (+ 5)
  h <- (* 100)
  return $ g + h

f 30 -- 3035
```
