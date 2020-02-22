<!-- dry-containerとdry-auto_injectでDI -->

[dry-rb](dry-rb.org)ファミリーの[dry-container](http://dry-rb.org/gems/dry-container/)と[dry-auto_inject](http://dry-rb.org/gems/dry-auto_inject/)を使うと、<abbr title="Plain Old Ruby Object">PORO</abbr>の組み合わせで<abbr title="Dependency Injection">DI</abbr>が実現できます。

DIについてハイパーざっくり理解を得るには次の記事を読めばよいです。

[https://qiita.com/ritukiii/items/de30b2d944109521298f:embed:cite]

上の記事の中の[DIコンテナを適用したコード](https://qiita.com/ritukiii/items/de30b2d944109521298f#そこでようやくdiコンテナ)をdry-containerとdry-auto_injectを使って書き直してみました。

```ruby
require 'dry-auto_inject'
require 'logger'

class FileLogger
  def initialize(filename)
    @logger = Logger.new(filename)
  end
end

class TwitterManager
  def initialize(logger)
    @logger = logger
  end
end

class DatabaseUserAuthenticator; end

class SampleContainer
  extend Dry::Container::Mixin

  register 'file_logger' do
    FileLogger.new('example.log')
  end

  register 'twitter_manager' do
    TwitterManager.new(FileLogger.new('twitter.log'))
  end

  register 'database_authenticator' do
    DatabaseUserAuthenticator.new
  end
end

Import = Dry::AutoInject(SampleContainer)

class Sample
  include Import['file_logger', 'twitter_manager']
end
```

これで、`Sample` に `SampleContainer` で登録されているインスタンスを注入できました。次のようにメソッド形式の呼び出しでインスタンスが取得できます。

```ruby
sample = Sample.new
pp sample.file_logger
pp sample.twitter_manager
pp sample.database_authenticator
```

`pp` で中身を確認するとインスタンスが取得できていることがわかります。また、`database_authenticator` は `Sample` に注入しなかったので取得できずエラーになります。

```
#<FileLogger:0x00007f84780cb3c8
 @logger=
  #<Logger:0x00007f84780cb378
   @default_formatter=
    #<Logger::Formatter:0x00007f84780cb328 @datetime_format=nil>,
   @formatter=nil,
   @level=0,
   @logdev=
    #<Logger::LogDevice:0x00007f84780cb2d8
     @dev=#<File:example.log>,
     @filename="example.log",
     @mon_count=0,
     @mon_mutex=#<Thread::Mutex:0x00007f84780cb1c0>,
     @mon_owner=nil,
     @shift_age=0,
     @shift_period_suffix="%Y%m%d",
     @shift_size=1048576>,
   @progname=nil>>
#<TwitterManager:0x00007f84780cab08
 @logger=
  #<FileLogger:0x00007f84780cadd8
   @logger=
    #<Logger:0x00007f84780cadb0
     @default_formatter=
      #<Logger::Formatter:0x00007f84780cad60 @datetime_format=nil>,
     @formatter=nil,
     @level=0,
     @logdev=
      #<Logger::LogDevice:0x00007f84780cad10
       @dev=#<File:twitter.log>,
       @filename="twitter.log",
       @mon_count=0,
       @mon_mutex=#<Thread::Mutex:0x00007f84780cacc0>,
       @mon_owner=nil,
       @shift_age=0,
       @shift_period_suffix="%Y%m%d",
       @shift_size=1048576>,
     @progname=nil>>>
Traceback (most recent call last):
container.rb:43:in `<main>': undefined method `database_authenticator' for #<Sample:0x00007fd8149da578> (NoMethodError)
```

また、別のインスタンスに差し替えることもできます。テストのときはモックに差し替える、というような用途で便利です。

```ruby
sample = Sample.new(file_logger: Logger.new(STDOUT))
pp sample.file_logger
```

```
#<Logger:0x00007f84788cfdd0
 @default_formatter=
  #<Logger::Formatter:0x00007f84788cfce0 @datetime_format=nil>,
 @formatter=nil,
 @level=0,
 @logdev=
  #<Logger::LogDevice:0x00007f84788cfbc8
   @dev=#<IO:<STDOUT>>,
   @filename=nil,
   @mon_count=0,
   @mon_mutex=#<Thread::Mutex:0x00007f84788cf010>,
   @mon_owner=nil,
   @shift_age=nil,
   @shift_period_suffix=nil,
   @shift_size=nil>,
 @progname=nil>
```
