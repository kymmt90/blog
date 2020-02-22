<!-- launchd で Homebrew を自動アップデート（Yosemite 編） -->

対応した内容をブログにメモしておくのを忘れていたので、いまさらながら書いておきます。

OS X で cron 的なことをするためには、launchd というものを使う必要があります。以前、パッケージマネージャ Homebrew のアップデートを自動で走らせたいと思い、launchd を使って、シェルスクリプトから `brew update`, `brew upgrade` を実行するようにしていました。

- [launchd で Homebrew を自動アップデート - kymmt's note](http://kymmt90.hatenablog.com/entry/launchd_brew)

しかし、OS X を Mavericks から Yosemite にアップグレードすると、この方法ではうまく動かなくなってしまいました。原因を調べたところ、**Yosemite では `/etc/launchd.conf` という lanunchd 設定ファイルが廃止されている（バグ？）**ことがわかりました。

以前の方法では、`/etc/launchd.conf` の中で、launchd が参照するシステムワイド環境変数中の `PATH` に Homebrew のコマンド `brew` が存在するパス `/usr/local/bin` を追加していました。そのため、`/etc/launchd.conf` が無効になると`brew` を実行できなくなります。

そこで、[前回記事](http://kymmt90.hatenablog.com/entry/launchd_brew)の内容（`/etc/launchd.conf` 以外）に加え、パスの設定も launchd のジョブとして実行することにしました。今回の環境は OS X Yosemite (10.10.2) です。

## パス設定用シェルスクリプトの作成

まず、システムワイド環境変数の `PATH` 設定用のシェルスクリプトを作成します。

```
$ vi launchd_path.sh
#!/bin/sh
launchctl setenv PATH /usr/local/bin:$PATH
```

## シェルスクリプト実行用 plist の作成

次に、上のシェルスクリプトを実行する launchd のジョブを plist という XML ファイルで記述します。

```xml
$ vi jp.kymmt90.launchd_path.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTDPLIST1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>jp.kymmt90.launchd_path.plist</string>
  <key>Program</key>
  <string>/path/to/brew_update/launchd_path.sh</string>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
```

ここで、`Program` の値には先ほど作成したシェルスクリプトのパスを指定します。また、`RunAtLoad` の値に `true` を指定することで、launchd への plist ロード時、つまり OS 起動時に指定したシェルスクリプトが実行されます。

## plist のロード

最後に、この plist を launchd にロードさせます。

```
$ launchctl load jp.kymmt90.launchd_path.plist
$ launchctl list | grep launchd_path
-	78	jp.kymmt90.launchd_path.plist
```

これで、launchd によって自動でシステムワイド環境変数 `PATH` に `/usr/local/bin` へのパスが追加されます。結果、launchd に Homebrew のアップデートを実行させることができます。

# 参考

- [Yosemiteアップデートでlaunchdが死亡した - retlet.net](http://retlet.net/log/2014/10/yosemite-launchd.html)

この記事で今回の問題の原因を把握しました。

- [Setting environment variables via launchd.conf no longer works in OS X Yosemite? - Stack Overflow](http://stackoverflow.com/questions/25385934/setting-environment-variables-via-launchd-conf-no-longer-works-in-os-x-yosemite)

AppleScript で

```
do shell script "launchctl setenv PATH /usr/local/bin:$PATH"
```

と書き、OS X のログイン項目にその AppleScript を指定することでも、パスの自動追加ができるようです。
