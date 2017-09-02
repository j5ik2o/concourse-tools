# ステージング用 docker build タスク

- タスクで行うこと
    - `sbt test`
    - `sbt docker:stage outputVersion`で実行する
        - `sbt-release`でバージョンのバンプや`git commit/tag`は行わないで、Docker用のリソースと`target/tag`だけを生成する。
    - `concourse`上で`docker build/push`するために、`outputs`の`to-push`に`docker:stage`の結果と`target/tag`をコピーする
    - `production-version`の`VERSION`を`taget/tag`の内容で置き換えてコミットする。
