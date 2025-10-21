# テストベット

## 実装済みの内容

このコードは、全世界に分散した複数のコンピュータリソースで構成されるテストベットをAWSに構築します。

現在のコードで実装されるテストベットは、ひとつのデータセンター（シングルリージョン）に配置した複数のコンピュータにネットワークの遅延とエラー率を発生させることができます。

このコードを使って、テストベットに必要な設定と動作確認を行うことができます。また、テストベット利用者のチュートリアルとして利用できます。

## 必要となる追加の作業

### 固有ソフトウェアのセットアップ

テストベットに必要な追加作業は、以下の通りです。

* 各コンピュータで動作させるソフトウェアのセットアップ
* 動作ログを収集する仕組みのセットアップ

これらの設定は、**LinuxにCLIで設定できることが必須条件** です。

### テストベットの要件に応じたスケールアップ

設定が完了したテストベットを、複数のデータセンター（マルチリージョン）に配置し、実際のネットワークと同じ構成にし、日本から各国の平均的な遅延とエラー率を設定します。

## 使い方

下記のパラメータを環境変数に設定します。

| 環境変数名 | 概要 | デフォルト値 |
|-------------|------|---------------|
| `TF_VAR_pc_count` | 設置するPC台数。AWS上に展開する仮想PCの総数を指定します。 | `10` |
| `TF_VAR_network_latency_ms` | ネットワーク遅延（ミリ秒）。通信に発生する平均的な遅延時間を設定します。 | `100` |
| `TF_VAR_network_error_rate` | ネットワークエラー率（0〜1）。パケットロスなどの発生確率を指定します。 | `0.01` |
| `TF_VAR_affected_pc_ratio` | 遅延やエラーの影響を受けるPCの割合（0〜1）。全体のうち影響下に置かれるノードの比率を指定します。 | `0.2` |

下記のいずれかの方法で、AWSへの接続情報を設定します。

* IAMロールによる権限付与（推奨）
* 環境変数によるシークレットキーの設定

下記のコマンドで初期化を実行します。

```
terraform -install-autocomple
source ~/.bashrc
terraform init
```

下記のコマンドでリソース一式を作成します。

```
terraform apply
```

接続するインスタンスを指定します。

```
IP_IDX=0
```

ssh接続します。

```
eval $(terraform output -json ssh_private_cmds | jq -r '.['$IP_IDX']')
```

下記のコマンドでリソース一式を削除します。

```
terraform destroy
```

<details>
  <summary>実行例</summary>


100台のうち、70台がネットワーク遅延100ms、エラー率5%の環境

```
export TF_VAR_pc_count=100
export TF_VAR_network_latency_ms=100
export TF_VAR_network_error_rate=0.05
expott TF_VAR_affected_pc_ratio=0.7
terraform apply
```

```
$ IP_IDX=0
$ eval $(terraform output -json ssh_private_cmds | jq -r '.['$IP_IDX']')
The authenticity of host '35.77.36.31 (35.77.36.31)' can't be established.
ECDSA key fingerprint is SHA256:jW87T6xKxo8TsashCfiZNHDOKf7ltp6mVyBJFghtZyo.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '35.77.36.31' (ECDSA) to the list of known hosts.
   ,     #_
   ~\_  ####_        Amazon Linux 2
  ~~  \_#####\
  ~~     \###|       AL2 End of Life is 2026-06-30.
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /    A newer version of Amazon Linux is available!
      ~~._.   _/
         _/ _/       Amazon Linux 2023, GA and supported until 2028-03-15.
       _/m/'           https://aws.amazon.com/linux/amazon-linux-2023/

[ec2-user@ip-172-31-40-158 ~]$ 
```
</details>

## インターネット遅延とエラー率

下記は、公知情報から推測した各国の平均遅延とエラー率です。

| 国・地域         | 平均遅延（ms） | エラー率（推定） | 備考 |
|------------------|----------------------|--------------------------|------|
| 日本              | 30〜50               | < 0.1%                   | 非常に安定した通信環境 |
| 米国              | 70〜100              | < 0.5%                   | 地域差あり（東海岸 vs 西海岸） |
| ドイツ            | 40〜70               | < 0.5%                   | 欧州内では安定 |
| シンガポール      | 20〜40               | < 0.1%                   | アジアの通信ハブ |
| 韓国              | 20〜40               | < 0.1%                   | 高速・安定 |
| オーストラリア    | 150〜160             | < 1%                     | 地理的に遅延が大きい |
| インド            | 200〜210             | 1〜3%                    | 混雑やインフラの影響あり |
| ブラジル          | 120〜150             | 1〜3%                    | 地域によってばらつきあり |
| アルゼンチン      | 120〜140             | 1〜3%                    | 南米では比較的良好 |
| メキシコ          | 80〜100              | 1〜2%                    | 北米との接続は良好 |
| フランス          | 30〜50               | < 0.5%                   | 欧州内で安定 |
| イギリス          | 30〜50               | < 0.5%                   | 欧州内で安定 |
| 南アフリカ        | 180〜220             | 3〜5%                    | 通信インフラに課題あり |
| ベネズエラ        | 200〜250             | > 5%                     | 高いエラー率と遅延 |
| 香港              | 140〜150             | < 1%                     | 国際接続良好 |
| チリ              | 95〜100              | 1〜2%                    | 南米では良好な部類 |

> ※ パケットロス率は公開統計やISPのSLA、Speedtest Global Indexなどを参考にした推定値です。

エラー率の目安は、下記の通りです。

| 状況                 | パケットロス率の範囲 | 備考 |
|----------------------|----------------------|------|
| 通常時（健全な通信） | 0%〜0.1%             | ほぼ無視できるレベル |
| 軽微な障害           | 0.1%〜1%             | 一部のリアルタイムアプリに影響あり |
| 中程度の障害         | 1%〜3%               | 音声・映像・ゲームなどに支障が出る |
| 深刻な障害           | 3%以上               | 通信断や再接続が頻発、業務に支障 |

エラー率が一般的なアプリケーションに与える影響は下記の通りです。

| アプリケーション       | 許容パケットロス率 | 備考 |
|------------------------|--------------------|------|
| Webブラウジング・メール | < 1%               | TCP再送で補える |
| VoIP・ビデオ会議        | < 1%               | 音声・映像が途切れる可能性あり |
| オンラインゲーム        | 0%〜0.5%           | ラグや不公平なプレイに直結 |
| 動画ストリーミング      | < 5%               | 解像度低下や一時停止が発生 |
| 業務用アプリ（RDP等）   | 0.5%〜1%           | 操作遅延やファイル転送の遅延 |
| 医療・金融などの重要系 | ほぼ0%             | データの正確性が最重要 |


## ネットワークの遅延とエラーを設定

遅延とエラーを設定する方法は、下記の通りです。

下記のコマンドでネットワークの遅延を100ms、損失率10%に設定します。

```
sudo tc qdisc add dev eth0 root netem delay 100ms loss 10%
```

設定した内容は、下記のコマンドで確認できます。

```
sudo tc qdisc show
```

下記のコマンドで設定した遅延を解除します。

```
sudo tc qdisc del dev eth0 root netem
```

遅延を設定して解除したログです。

```
64 bytes from 8.8.8.8: icmp_seq=422 ttl=115 time=2.24 ms
64 bytes from 8.8.8.8: icmp_seq=423 ttl=115 time=2.26 ms
64 bytes from 8.8.8.8: icmp_seq=424 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=425 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=426 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=427 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=428 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=429 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=430 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=431 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=432 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=433 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=434 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=435 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=436 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=437 ttl=115 time=2.25 ms
64 bytes from 8.8.8.8: icmp_seq=438 ttl=115 time=2.36 ms
64 bytes from 8.8.8.8: icmp_seq=439 ttl=115 time=2.24 ms
64 bytes from 8.8.8.8: icmp_seq=440 ttl=115 time=2.25 ms
```

最後にエラー率が確認できます。

```
--- 8.8.8.8 ping statistics ---
80 packets transmitted, 76 received, 5% packet loss, time 79195ms
rtt min/avg/max/mdev = 2.252/53.633/102.520/49.979 ms
[ec2-user@ip-172-31-37-166 ~]$
```
## 実行例

```
[root@ip-172-31-37-166 ~]# sudo tc qdisc add dev eth0 root netem loss 20%
[root@ip-172-31-37-166 ~]# tc qdisc show
qdisc noqueue 0: dev lo root refcnt 2 
qdisc netem 8005: dev eth0 root refcnt 3 limit 1000 loss 20%
[root@ip-172-31-37-166 ~]# sudo tc qdisc del dev eth0 root netem
[root@ip-172-31-37-166 ~]# tc qdisc show
qdisc noqueue 0: dev lo root refcnt 2 
qdisc mq 0: dev eth0 root 
qdisc pfifo_fast 0: dev eth0 parent :2 bands 3 priomap 1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1
qdisc pfifo_fast 0: dev eth0 parent :1 bands 3 priomap 1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1
[root@ip-172-31-37-166 ~]# 
```

```
[ec2-user@ip-172-31-37-166 ~]$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=115 time=2.69 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=115 time=2.25 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=115 time=2.26 ms
... 中略（遅延とエラーを設定） ...
64 bytes from 8.8.8.8: icmp_seq=25 ttl=115 time=2.27 ms
64 bytes from 8.8.8.8: icmp_seq=26 ttl=115 time=2.26 ms
64 bytes from 8.8.8.8: icmp_seq=27 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=28 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=29 ttl=115 time=102 ms
... 中略 （遅延とエラーを解除）...
64 bytes from 8.8.8.8: icmp_seq=68 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=69 ttl=115 time=102 ms
64 bytes from 8.8.8.8: icmp_seq=70 ttl=115 time=2.25 ms
64 bytes from 8.8.8.8: icmp_seq=71 ttl=115 time=2.25 ms
64 bytes from 8.8.8.8: icmp_seq=72 ttl=115 time=2.35 ms
64 bytes from 8.8.8.8: icmp_seq=73 ttl=115 time=2.26 ms
64 bytes from 8.8.8.8: icmp_seq=74 ttl=115 time=2.28 ms
... 中略 （測定を矯正終了）...
64 bytes from 8.8.8.8: icmp_seq=79 ttl=115 time=2.27 ms
64 bytes from 8.8.8.8: icmp_seq=80 ttl=115 time=2.27 ms
^C
--- 8.8.8.8 ping statistics ---
80 packets transmitted, 76 received, 5% packet loss, time 79195ms
rtt min/avg/max/mdev = 2.252/53.633/102.520/49.979 ms
[ec2-user@ip-172-31-37-166 ~]$
```

## メモ

Amazon Linux2の場合、下記のパッケージが必要です。

```
yum install -y iproute-tc
```

以上
