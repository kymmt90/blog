<!-- 値の妥当性をチェックする日時表現パーサを作る -->

『[Haskell入門](https://gihyo.jp/book/2017/978-4-7741-9237-6)』に日時表現(`"YYYY/MM/DD hh:mm:ss"`)のパーサを[Attoparsec](https://hackage.haskell.org/package/attoparsec)で作る節((7.5「高速なパーサ ─ attoparsec」))があり、

> このままでは9999/99/99 99:99:99のような入力ができてしまいますが、月の入力範囲を1～12に制限するといった制約をかけることも、これまで説明した範囲で簡単に実現できます

という記述があったので、値の入力範囲に制限があるバージョンを書いてみた。具体的には[`guard`](https://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Monad.html#g:6)を使う((5.3.3「Alternative型クラスとしてのMaybe」で説明されているので一応「これまで説明した範囲」ではある))。

```haskell
{-# LANGUAGE OverloadedStrings #-}

import qualified Data.Text as T
import Control.Monad
import Data.Attoparsec.Text hiding (take)

data YMD = YMD Int Int Int deriving Show
data HMS = HMS Int Int Int deriving Show

countRead :: Read a => Int -> Parser Char -> Parser a
countRead i = fmap read . count i

year :: Parser Int
year = countRead 4 digit

month :: Parser Int
month = do
  month <- countRead 2 digit
  guard $ 1 <= month && month <= 12
  return month

day :: Parser Int
day = do
  day <- countRead 2 digit
  guard $ 1 <= day && day <= 31
  return day

hour :: Parser Int
hour = do
  hour <- countRead 2 digit
  guard $ 0 <= hour && hour <= 23
  return hour

minute :: Parser Int
minute = do
  minute <- countRead 2 digit
  guard $ 0 <= minute && minute <= 59
  return minute

second :: Parser Int
second = do
  second <- countRead 2 digit
  guard $ 0 <= second && second <= 59
  return second

ymdParser :: Parser YMD
ymdParser = YMD <$> year <* char '/' <*> month <* char '/' <*> day

hmsParser :: Parser HMS
hmsParser = HMS <$> hour <* char ':' <*> minute <* char ':' <*> second

dateTimeParser :: Parser (YMD, HMS)
dateTimeParser = (,) <$> ymdParser <* char ' ' <*> hmsParser
```

各パーサ関数で[Control.Monad](https://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Monad.html)の`guard`に年、月、日、時、分、秒それぞれが満たすべき条件式を渡す。パースした結果得られた整数が`guard`に渡した条件を満たさないとき、結果が`empty`になる。

[`Parser`は`Alternative`のインスタンス](https://hackage.haskell.org/package/attoparsec-0.13.2.3/docs/src/Data.Attoparsec.Internal.Types.html#line-204)であり、`empty`を返した時点で`fail "empty"`が実行される。この時点でパースが中止される。

それぞれの関数を組み合わせることでApplicativeスタイルでパーサを表現できている。

上のコードを読み込んだ状態で次のコードを実行する:

```haskell
main :: IO ()
main = do
  print $ parse dateTimeParser "2020/03/01 12:34:56" `feed` ""
  print $ parse dateTimeParser "2020/03/32 12:34:56" `feed` ""
```

このとき結果は次のとおりで、invalidな値を渡すとパースに失敗する:

```
Done "" (YMD 2020 3 1,HMS 12 34 56)
Fail " 12:34:56" [] "Failed reading: empty"
```
