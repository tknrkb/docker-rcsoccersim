## Docker for Mac 用の RoboCup 2D Simulator 実行環境

### 準備

Homebrew (https://brew.sh/) が入っていない場合はインストールしておく。

Docker が入ってない場合は Homebrew (Cask) で Kitematic と共にインストールしておく。
~~~console
(host)$ brew cask install docker kitematic
~~~

始めに XQuartz と socat をインストールしておく。
XQuartz をインストールした後は，再起動しておいた方が良さそう。
~~~console
(host)$ brew cask install xquartz
(host)$ brew install socat
~~~

XQuartz を起動し，RoboCup Simulator のビューアアプリを XQuartz で表示できるように socat コマンドを実行しておく。
~~~console
(host)$ open -a XQuartz
(host)$ socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" &
~~~

チームバイナリを用意する.
~~~console
(host)$ cd teams
(host)$ wget -np -r https://archive.robocup.info/Soccer/Simulation/2D/binaries/RoboCup/2019/MainRound/ -A tar.gz
(host)$ for targz in archive.robocup.info/Soccer/Simulation/2D/binaries/RoboCup/2019/MainRound/*tar.gz; do tar zxvf $targz ; done
~~~

### 実行

$IMAGE_NAME: イメージ名

$CONTAINER_NAME: コンテナ名

$TEAM_DIR: チームバイナリ置場

$LOG_DIR: ログ出力先

#### STEP 0: docker build

イメージ作成
~~~console
(host)$ docker build -t $IMAGE_NAME .
~~~

#### STEP 1: docker run 

イメージを起動する際には logs と teams のボリュームを指定しておくこと。
logs ボリュームが指定されていないと rcssserver は起動できない。

rcsoccersim スクリプトが実行され、rcssserver と rcssmonitor が起動する
~~~console
(host)$ docker run --rm -d \
          --name $CONTAINER_NAME \
          -v $TEAM_DIR:/teams \
          -v $LOG_DIR:/logs \
          $IMAGE_NAME
~~~

soccerwindow2 を使う場合
~~~console
(host)$ docker run --rm -d \
          --name $CONTAINER_NAME \
          -v $TEAM_DIR:/teams \
          -v $LOG_DIR:/logs \
          -e RCSSMONITOR=soccerwindow2 \
          $IMAGE_NAME
~~~

#### STEP 2: run players.

2つのチームのバイナリを起動する。
~~~console
(host)$ docker exec -it $CONTAINER_NAME bash

(container)$ cd /teams/cyrus/
(container)$ ./startAll &

(container)$ cd /teams/helios/
(container)$ ./startAll &
~~~
### その他

soccerwindow2 のみ起動
```console
docker run --rm \
	$IMAGE_NAME \
	soccerwindow2
```

bash を起動
```console
docker run --rm \
    -v $TEAM_DIR:/teams \
    -v $LOG_DIR:/logs \
	-it \
	$IMAGE_NAME \
    bash
```

auto_mode と synch_mode で指定したチームの試合を自動実行

```console
docker run --rm \
    -v $TEAM_DIR:/teams \
    -v $LOG_DIR:/logs \
    $IMAGE_NAME \
    rcssserver \
    \
    server::game_log_dir=/logs \
	server::text_log_dir=/logs \
	server::game_log_compression=9 \
	server::text_log_compression=9 \
    \
    server::synch_mode=true \
    server::auto_mode=true \
    server::nr_extra_halfs=0 \
    server::penalty_shoot_outs=false \
    \
    server::team_l_start="/teams/helios/startAll" \
    server::team_r_start="/teams/cyrus/startAll2"
```

↑の設定を外部ファイルに出し include= を使って読みこんだバージョン
```console
docker run --rm \
    -v $TEAM_DIR:/teams \
    -v $LOG_DIR:/logs \
    $IMAGE_NAME \
    rcssserver \
    \
    include=/home/rcsoccersim/rcssserver.opt_log \
    include=/home/rcsoccersim/rcssserver.opt_auto \
    \
    server::team_l_start="/teams/helios/startAll" \
    server::team_r_start="/teams/cyrus/startAll2"
```

※ team_[lr]_start で指定するスクリプトは別のディレクトリから実行できなくてはならない.
スクリプトの最初の方に↓のコードを追加すれば良い
```
cd `dirname $0`
```
