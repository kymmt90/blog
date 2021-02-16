<!-- 不安定なテストが存在することをSlackに通知するGitHub Actionsワークフロー -->

あるGitHubリポジトリのmaster（や最近はmain）ブランチで確率的に落ちるテストは間違いなく不安定なテスト((flaky testsともいう https://docs.gitlab.com/ee/development/testing_guide/flaky_tests.html))であるという考えのもと、不安定なテストを見つけたときに自動でSlackに通知するGitHub Actionsワークフローの書きかたについて説明する((業務で必要に駆られて作成しチームメンバーにレビューしてもらった))。

なお、この記事ではテスト自体の書きかたの良し悪しについては言及しない。

## 方法

- 不安定なテストを通知するジョブは、テストを実行するジョブの実行結果に依存する
- 現在のブランチがmaster、かつテストの終了ステータスが正常でないとき通知する
  - 今回はテストが1件でも失敗したなら、テストのコマンドは終了ステータスとして1を返すとする

これをYAMLに落とし込むとこうなる((本当はGitHub Enterprise Serverで作ったものをgithub.com風に書き換えた))。

```yaml
test:
  # リポジトリのテストを実行

flaky-test-notification:
  needs:
    - test
  runs-on: ubuntu-latest
  if: always()
  steps:
    - name: Notify flaky tests
      if: github.ref == 'refs/heads/master' && needs.test.result == 'failure'
      uses: tokorom/action-slack-incoming-webhook@main
      env:
        INCOMING_WEBHOOK_URL: {{ secrets.WEBHOOK_URL }}
      with:
        text: 'Flaky tests found: https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}'
```

まず、`test`ジョブの結果に依存するので`needs`に`test`を指定する。しかし、`needs`に指定した`test`ジョブはテストに失敗したとき終了ステータスが1なので失敗とみなされる。このとき[`needs`を持つジョブはデフォルトでスキップされてしまう](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idneeds)(("If a job fails, all jobs that need it are skipped unless the jobs use a conditional expression that causes the job to continue"))。この場合も`flaky-test-notification`は実行したいので、ステップ自体はつねに実行されるように`if: always()`を指定する。

通知用のステップで現在mainブランチかつテストが失敗しているか（すなわち不安定なテストが見つかったか）を[`github.ref`](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context)と[`needs.test.result`](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#needs-context)で判定する。判定がtrueならSlackへ通知する。GitHubフローで開発しているなら、masterブランチへはpull requestのマージでコミットが追加されるはずであり、それはpushと見なされるので、`flaky-test-notification`はpull requestマージ時に1回だけ実行される。

Slackへ通知する既存のActionはいくつか存在するので何かを使えばいいが、ここでは[tokorom/action-slack-incoming-webhook](https://github.com/tokorom/action-slack-incoming-webhook)を使わせていただく。といっても、リポジトリのActions用シークレット((リポジトリ配下の/settings/secrets/actionsから設定できる))にSlackのIncoming Webhook URLを登録しておき、送信するテキストを設定すれば終わり。ここでは[`github.repository`と`github.run_id`](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context)からGitHub Actionsの実行画面のURLを作成して、Slackからすぐに結果を確認しに行けるようにしている。

不安定なテストが見つかると次のようにSlackに通知が来る。

[f:id:kymmt90:20210216230146p:plain]

このあとは粛々とテストを直しましょう。
