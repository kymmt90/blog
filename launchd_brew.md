<!-- launchd で Homebrew を自動アップデート -->
Homebrew を使っていて、たまに `brew doctor` すると、以下のメッセージが表示される。

    Warning: Your Homebrew is outdated.
    You haven't updated for at least 24 hours, this is a long time in brew land!

そう言われても、毎日手動でアップデートするのも面倒なので、自動でアップデートすることにした。

ジョブの自動実行といえば cron だと思っていた。
しかし、OS X では普通 **launchd** を使うらしい。
crontab で設定を書くのではなく、XML ファイルに書くという。

そこで、launchd で Homebrew を自動アップデートするように設定してみる。
設定は以下の手順で進める。

1. 自動実行するスクリプトを作成
2. launchd の plist ファイルを作成
3. システムワイド環境変数にパスを設定
4. plist ファイルをジョブとして登録

環境は OS X Mavericks (10.9.5) である。

# 1. 自動実行するスクリプトを作成

    $ vi brew_update.sh

`brew_update.sh` は以下の通り。
実行結果はログに書き出す。

```sh
#!/bin/sh

log_name=log/`date "+%Y%m%d"`.log

brew doctor >> ${log_name} 2>&1
if [ $? -ne 0 ]; then
	brew update >> ${log_name} 2>&1
	brew upgrade >> ${log_name} 2>&1
fi
```

    $ chmod 744 brew_update.sh
    $ mkdir log

# 2. launchd の plist ファイルを作成

plist (property list) ファイルは、実行したいジョブの設定を書く XML ファイルである。
今回は `~/Library/LaunchAgents/` に置く。

    $ vi ~/Library/LaunchAgents/jp.kymmt90.brew_update.plist

`jp.kymmt90.brew_update.plist `は以下の通り。
毎日 22:00 に実行する。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTDPLIST1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>jp.kymmt90.brew_update.plist</string>
        <key>Program</key>
        <string>/path/to/brew_update.sh</string>
        <key>WorkingDirectory</key>
        <string>/path/to/brew_update</string>
        <key>StartCalendarInterval</key>
        <dict>
            <key>Hour</key>
            <integer>22</integer>
            <key>Minute</key>
            <integer>00</integer>
        </dict>
    </dict>
</plist>
```

# 3. システムワイド環境変数にパスを設定

launchd はシステムワイド環境変数を利用している。
`brew` がある `/usr/local/bin` は、デフォルトのシステムワイド環境変数の `PATH` に設定されていないようである。
そこで、システムワイド環境変数にパスを設定する。

    $ launchctl setenv PATH /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
	$ launchctl getenv PATH
	/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

しかし、この方法では、OS の再起動時に設定が消えてしまう。
設定を永続化するために、`/etc` 直下に設定ファイル `launchd.conf` を置く。

    $ sudo vi /etc/launchd.conf

内容は以下の通り。

    setenv PATH /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# 4. plist ファイルをジョブとして登録

以下のコマンドでジョブを登録する。

    $ launchctl load jp.kymmt90.brew_update.plist
	$ launchctl list | grep brew_update
    -	0	jp.kymmt90.brew_update.plist

これで、plist ファイルで設定した通りの時間に、設定したプログラムが実行される。

# その他

launchd では、マシンがスリープ状態のときに、ジョブが設定された時間になると、スリープ復帰時にジョブが実行される。

# 参考文献

* [LaunchDaemons (launchctl, launchd.plist) の使い方 - maruko2 Note.](http://www.maruko2.com/mw/LaunchDaemons_\(launchctl,_launchd.plist\)_%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9#launchd.plist_.E3.83.95.E3.82.A1.E3.82.A4.E3.83.AB.E3.82.92.E7.BD.AE.E3.81.8F.E3.83.87.E3.82.A3.E3.83.AC.E3.82.AF.E3.83.88.E3.83.AA)
* [Daemons and Services Programming Guide: Creating Launch Daemons and Agents](https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpsystemstartup/chapters/CreatingLaunchdJobs.html#//apple_ref/doc/uid/TP40001762-104142)
* [Daemons and Services Programming Guide: Scheduling Timed Jobs](https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpsystemstartup/chapters/ScheduledJobs.html)
* [cron - launchd(8)の使い方 - Qiita](http://qiita.com/archinwater/items/4c2e9174e4898a197de6)
* [システムワイドなロケール設定 ～ Mac OS X (その2) - 彷徨えるフジワラ](http://d.hatena.ne.jp/flying-foozy/20140204/1391520123)
