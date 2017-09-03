# concourse-tools

## 必要なもの

- Docker for Mac

## ローカルでの開発

ローカル開発環境は本番で重要な要素をすべて含みます。いわゆる箱庭環境です。動作するアプリケーションは以下です。

 - docker-registry
 - concourse(web, worker, postgres)
 - gitbucket(DBはH2)
  
### 準備

- Docker for Macの設定(Daemon) insecure registries: に `docker.for.mac.localhost:5000`を登録して、`Apply & Restart`してください。


