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

#### STEP 0: docker build
~~~console
(host)$ docker build -t rcsoccersim .
~~~

#### STEP 1: docker run

rcsoccersim コンテナを起動する際には logs と teams のボリュームを指定しておくこと。logs ボリュームが指定されていないと rcssserver は起動できない。
~~~console
(host)$ docker run --rm -d --name rcsoccersim \
          -v $PWD/teams:/home/rcsoccersim/teams \
          -v $PWD/logs:/home/rcsoccersim/logs \
          rcsoccersim
~~~

#### STEP 2: open soccerwindow2 && run players.

soccerwindow2 か rcssmonitor を起動する。
2つのチームのバイナリを起動する。
~~~console
(host)$ docker exec -it rcsoccersim bash
(container)$ soccerwindow2 &

(container)$ cd /home/rcsoccersim/teams/cyrus/
(container)$ ./startAll &

(container)$ cd /home/rcsoccersim/teams/helios/
(container)$ ./startAll &
~~~
