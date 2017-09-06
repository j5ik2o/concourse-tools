# concourse-tools

## 必要なもの

- Docker for Mac

## ローカルでの開発

ローカル開発環境は本番で重要な要素をすべて含みます。いわゆる箱庭環境です。動作するアプリケーションは以下です。

 - gitbucket(DBはH2)
 - docker-registry
 - docker-registry-web
 - concourse(web, worker, postgres)

### 準備

- Docker for Macの設定(Daemon) insecure registries: に `docker.for.mac.localhost:5000`を登録して、`Apply & Restart`してください。

#### ツールの起動

- 以下のコマンドを実行する。起動が完了するには少し時間がかかります。

```sh
local-middleware $ docker-compose up
```


#### gitbucket

- http://localhost:8081/ を開く
- root/rootでログインする
- System settings
  - Base URL = http://localhost:8081
  - SSH access
    - Enable SSH access to git repository を有効にする
    - SSH host = localhost
    - SSH port = 29418
- Account settings
  - SSH key
    - local-middleware/gitbucket.key.pubを登録する。
      - `$ cat gitbucket.key.pub | pbcopy`
  - .ssh/configに秘密鍵のエントリを追加する
  ```
  Host localhost
    HostName localhost
    TCPKeepAlive yes
    IdentitiesOnly yes
    IdentityFile /Users/xxxxx/Sources/concourse-tools/local-middleware/gitbucket.key
    AddKeysToAgent yes
  ```

#### Gitリポジトリの準備

- gitリポジトリをgitbucketに作成する
  - アプリケーション用
  - デプロイツール用
- GithubからローカルにクローンしたGitリポジトリの.git/configにリモートを追加する
  - アプリケーション用
    `git remote add local ssh://git@localhost:29418/org/application.git`
  - デプロイツール用
    `git remote add local ssh://git@localhost:29418/org/deploy-tools.git`
- gitbucketへのgit push

#### concourse

- `environment/local/credential.yml`を作成する
```
---
attempts: 1 # ジョブが失敗した時のリトライ回数(1はリトライなし)

# チャットワークへの通知設定(ローカルでは無効な値を設定する)
chatwork-notification-api-key: 1
chatwork-notification-room-id: 1

# git用の秘密鍵(local-middleware/gitbucket.keyを貼り付ける)
github-private-key: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
git-email: j5ik2o@gmail.com
git-name: j5ik2o

# ECRにDockerイメージをpushする際は設定する。ローカルでは不要です。
aws-access-key-id: ...
aws-secret-access-key: ...
```
- http://localhost:8080/ にアクセスする。
- Appleのアイコンをクリックして、flyをdeployディレクトリ直下にコピーする。
- concourseへログインする
  `$ ./fly -t deploy login -c http://localhost:8080`
- `environment/local/variable.yml`の値を前述のgitリポジトリのurlに書き換える。docker registry上のリポジトリは事前作成は不要。
- パイプラインをセットする
  `$ ./concourse-set-pipeline.sh -e local -c http://localhost:8080 -t concourse`
- http://localhost:8080/ にアクセスする。
- concourse/concourseでログインする

### concourseジョブの起動

- 左上のアイコンをクリックし、deployというパイプラインを有効にする
- すべてのリソースが正常であることを確認する(オレンジがあるとステータス異常)
- `create-application-build-cache-*`のジョブを選択し、(+)をクリックして実行する(30分ぐらいかかる)
- docker-registryにビルドキャッシュが作成されたら、`application-test-and-build-*`のジョブを実行できます。
  - stagingは本番リリースで行うバージョンのバンプ、`git tag`などは行いません。何度実行しても同じバージョンとしてテスト・ビルドします。
  - 本番の場合は、sbt release `with-defaults`が実行されます。

### docker-registry

- docker-registryのポート番号は5000
- docker-registry-webのポート番号は8082. http://localhost:8082

### sbtプロジェクトの前提条件

- `project/plugins.sbt`にbt-native-packagerとsbt-releaseを追加する
- docker buildできるように設定する
- `sbt release`のプロセスを設定する

**project/plugins.sbt

```scala
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "1.2.0")

addSbtPlugin("com.github.gseitz" % "sbt-release" % "1.0.6")
```

**build.sbt**

```scala
dockerBaseImage := "frolvlad/alpine-oraclejdk8:8.131.11-cleaned"

maintainer in Docker := "Junichi Kato <j5ik2o@gmail.com>"

packageName in Docker := "j5ik2o/message-board"

dockerExposedPorts in Docker := Seq(9000, 9443)

dockerUpdateLatest := true

enablePlugins(AshScriptPlugin)

bashScriptExtraDefines := List(
  """addJava "-Duser.dir=$(realpath "$(cd "${app_home}/.."; pwd -P)")""""
)
```

**release.sbt**

```scala
import sbtrelease._
import sbtrelease.ReleasePlugin.autoImport.ReleaseTransformations._

// concourseがdocker buildに参照するイメージバージョンをファイルに出力する
val outputVersion: (State) => State = { state: State =>
  val extracted = Project.extract(state)
  val v         = extracted get version
  val outDir    = (extracted get baseDirectory) / "target"
  IO.write(outDir / "tag", v.getBytes())
  state
}

commands += Command.command("outputVersion")(outputVersion)

releaseIgnoreUntrackedFiles := true

releaseCommitMessage := s"Setting version to ${if (releaseUseGlobalVersion.value) (version in ThisBuild).value
else version.value} / [ci skip]"

import ReleaseKeys._

releaseProcess := Seq[ReleaseStep](
  inquireVersions,
  runClean,
  // runTest,
  setReleaseVersion,
  commitReleaseVersion,
  ReleaseStep(action = { state: State =>
    val extracted = Project.extract(state)
    val git       = new Git(extracted get baseDirectory)
    val scalaV    = extracted get scalaBinaryVersion
    val v         = extracted get version
    val org       = extracted get organization
    val n         = extracted get name
    "git diff HEAD^" ! state.log
    state
  }),
  tagRelease,
  releaseStepCommand("docker:stage"), // concourseがdocker build & pushを行うのでここではステージのみ。
  ReleaseStep(action = outputVersion),
  setNextVersion,
  commitNextVersion,
  pushChanges
)
```

### 本番へのデプロイ

- デプロイツールを本番にデプロイする場合は、`environment/production`などを作ってください。
- ECRを利用する場合は、以下のように設定を書き換えてください。

```
- name: application-image-repo
  type: docker-image
  source:
    repository: ((application-image-repo-url))
#    insecure_registries: [ "docker.for.mac.localhost:5000" ]
      aws_access_key_id: ((aws-access-key-id))
      aws_secret_access_key: ((aws-secret-access-key))
```
