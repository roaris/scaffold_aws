# scaffold_aws

RailsアプリをAWSにデプロイする練習

## scaffoldでアプリ作成
```
$ rails new scaffold_aws
$ cd scaffold_aws
$ rails g scaffold tweet title:string content:text
```

## VPCの作成
Virtual Private Cloud

ユーザー独自の空間、それぐらいの認識

![vpc設定](/images/vpc.png)

名前タグは設定しておいた方が管理画面で分かりやすい

CIDRは前から何ビットまでがネットワーク部かを示すもの 例えば`10.0.0.0/16`だったら、`10.0`がネットワーク部、`0.0`がホスト部になる ホスト部に割り当てられたIPアドレスの数がネットワーク内で使用可能なIPアドレスの数になる

IPv4は32ビット、IPv6が128ビット

IPv6の例: `3002:0bd6:0000:0000:0000:ee00:0033:6778`

テナンシーは、VPCを作るときにハードウェアを占有するかの設定 共有テナンシーと占有テナンシーがあり、共有テナンシーは1台のホストを複数のAWSアカウントで共有する 占有テナンシーは1台のホストを1つのAWSアカウントで占有する 占有テナンシーの方がお金がかかるが、セキュリティ面を考慮して、他のアカウントと同居したくない時に使う デフォルトでは共有テナンシーが選択される

## サブネットの作成
VPCを細分化したもの この中にRDSやEC2を配置する

![subnet設定](/images/subnet.png)

`10.0.0.0/16`のVPCで、`10.0.1`が先頭に来る256個のIPアドレスをグループ化したことになる

アベイラビリティゾーンは、AWSの各リージョン(東京やシドニー)に存在するデータセンターの場所 東京リージョンだとap-northeast-1aとap-northeast-1cとap-northeast-1dから選ぶことができる

`10.0.0.0/16`のVPCで、`10.1.1.0/24`のサブネットを作ろうとすると、VPCのホスト部にサブネットが入っていないので、エラーになる

![subnetエラー](/images/invalid_subnet.png)

## インターネットゲートウェイの作成
VPCが外部とやり取りするためのもの

![internet_gateway設定](/images/internet_gateway.png)

作成しただけではVPCと紐づけられていない(Detached)

![VPC割り当て](/images/vpc_attach.png)

## ルートテーブルの作成
ルーティング(トラフィックの経路選択)のために必要、それぐらいの認識

![route_table設定](/images/route_table.png)

この後にルートの編集を行う

![route編集](/images/route_config.png)

`0.0.0.0/0`は全ての宛先を意味するもの([参考](https://www.wdic.org/w/WDIC/0.0.0.0))で、全ての宛先に対して、インターネットゲートウェイを通るようにする、という設定をしている

サブネットとも紐付ける必要がある

![サブネットとの紐付け](/images/subnet_associate.png)

## セキュリティグループの作成
この通信は許可するとか、この通信は拒否するといった設定

インバウンドルールは、どんな通信が入ってくるのを許可するのか、アウトバウンドルールはどんな通信が出ていくのを許可するのか、の設定

タイプは、このタイプの通信が来たら受け入れるというもの(HTTPSとかSSHとか)

プロトコルとポート範囲はタイプを選択すると、大体自動的に設定される

ソースはどんなIPアドレスであれば通信を許可するかで、`0.0.0.0/0`を選択すると、リソースタイプはAnywhere-IPv4に自動的に設定される

アウトバウンドルールはデフォルトで、タイプはすべてのトラフィック、送信先は`0.0.0.0/0`に設定されている

![security_group設定](/images/security_group.png)

説明は必須で、日本語は使えない

同様に、全ての送信元からのSSH接続を許可する`test_ssh`、全ての送信元からの全てのトラフィックを許可する`test_production`を作成する

`test_http`はサービスの利用者がEC2にアクセスするためのもので、`test_ssh`は開発者がEC2にアクセスするためのもので、`test_production`はEC2とRDSに設定して、この間の通信のみ許可するものらしい(ここ良く分からない)

## RDSの作成
Relational Database Service

エンジンのタイプはアプリケーションで使うのものを選択する

![RDS設定1](/images/rds1.png)

![RDS設定2](/images/rds2.png)

![RDS設定3](/images/rds3.png)

サブネットグループは、サブネットをまとめたものぐらいの認識

アベイラビリティゾーンが別のサブネットが2つないと、RDSを作成することができなかった

![RDS作成エラー](/images/rds_error.png)

というわけで、ap-northeast-1cのサブネットを追加

![サブネット追加](/images/add_subnet.png)

これでRDSを作成できるようになった

![RDS詳細](/images/rds_detail.png)

マルチAZは、異なるアベイラビリティゾーンにRDSを配置し、問題が発生したときに、切り替えを行う仕組み 無料利用枠だと使用できない

## EC2の作成
Elastic Compute Cloud

この中にWebサーバーやアプリケーションサーバーを配置する

AMI(Amazon マシンイメージ)はAmazon Linux 2 AMIを選択する

インスタンスタイプ(CPUのスペックなどをプランにしたもの)は無料枠のt2.microを選択

![EC2設定1](/images/ec2_1.png)

色々あるが、ネットワーク、サブネット、自動割り当てパブリックIP以外はそのまま

自動割り当てパブリックIPは、パブリックIPを作成するインスタンスに自動で割り当てるかの設定で、これを有効にするとインスタンスを停止したタイミングでIPアドレスが変わったりするので、今回は無効に設定

![EC2設定2](/images/ec2_2.png)

そのまま

![EC2設定3](/images/ec2_3.png)

分かりやすいようにタグをつけておく

![EC2設定4](/images/ec2_4.png)

サービス利用者がアクセスするための`test_http`、開発者がSSH接続するための`test_ssh`、RDSと接続するための`test_production`を設定する

![keypair](/images/keypair.png)

SSH接続する時に必要

## Elastic IPの作成
EC2の設定で、自動割り当てパブリックIPを無しに設定しているので、このままだとサービスにアクセスすることができない

デフォルトの設定で作成

その後、EC2と紐づける

![EC2への紐付け](/images/elastic_ip_1.png)

![EC2詳細](/images/elastic_ip_2.png)

(パブリックIPv4アドレスに注目)

## EC2へSSH接続
EC2を作成したときにダウンロードしたキーペアを.sshに移動する

```
$  mv ~/Downloads/test.pem ~/.ssh
```

作成したEC2からSSH接続の方法が見れる

![SSH](/images/ssh.png)

.sshに移動し、書かれているコマンドを実行する

```
$ cd ~/.ssh
$ ssh -i "test.pem" ec2-user@13.113.171.196
```

初めての接続だけど大丈夫？と聞かれるのでyesで進む

すると、test.pemのパーミッションがオープンすぎるという警告が出て、接続できない

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for 'test.pem' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "test.pem": bad permissions
ec2-user@13.113.171.196: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

なので、以下のコマンドを実行して、自分だけ読み取り可能にする

```
$ chmod 400 test.pem
```

これで接続できるようになる


