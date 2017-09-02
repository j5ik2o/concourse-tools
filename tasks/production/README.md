# 本番用 docker build タスク

- タスクで行うこと
    - `$HOME/.ssh/config`を設定
    - `$HOME/.gitconfig`を設定
    - gitのsymbolic-refをHEADに設定(sbt-releaseのために)
    - `[ci skip]`から最新のコミットを取得する(sbt-releaseのために)
    - `sbt-release`を`with-defaults`で実行する
        - `with-defaults`は標準入力からバージョンなどの質問を受け付けない非対話モード。詳細は以下
    - `concourse`上で`docker build/push`するために、`outputs`の`to-push`に`docker:stage`の結果と`target/tag`をコピーする
    - `production-version`の`VERSION`を`taget/tag`の内容で置き換えてコミットする。

- `sbt-release`で行うこと
    - `sbt clean`
    - `sbt test`
    - `version.sbt`をリリースバージョンに切り替え
    - リリースバージョンのコミットを作成
    - `README.md`の更新
    - リリースバージョンのタグ作成
    - `sbt docker:stage`(`concourse`が`docker build/push`を行うため、sbtでは`docker build`はしない)
    - リリースバージョンを `target/tag` に出力
    - `version.sbt`を開発バージョンに切り替え
    - 開発バージョンのコミットを作成
    - コミットとタグをリモートにプッシュ
