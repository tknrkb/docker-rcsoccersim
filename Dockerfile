FROM ubuntu:16.04
MAINTAINER Yasuo Miyoshi <miyoshi@is.kochi-u.ac.jp>

ENV TZ Asia/Tokyo
ENV DISPLAY host.docker.internal:0
ENV DEBIAN_FRONTEND nointeractive
ENV DEBCONF_NOWARNINGS yes
ENV RCSS_CONF_DIR /home/rcsoccersim/.rcssserver
ENV LOG_DIR /logs
ENV TEAM_DIR /teams
USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    tzdata \
  && rm -rf /var/lib/apt/lists/* \
  && echo "${TZ}" > /etc/timezone \
  && rm /etc/localtime \
  && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
	wget \
    git \
    make \
    automake \
    bison \
    flex \
    libtool \
    libfl-dev \
    libqt4-dev \
    libboost-all-dev \
    libfontconfig-dev \
    libaudio-dev \
    libxt-dev \
    libsm-dev \
    libice-dev \
    libxi-dev \
    libxrender-dev \
    libxext-dev \
    libx11-dev \
    libglib2.0-dev \
    g++

WORKDIR /root
RUN git clone https://github.com/rcsoccersim/rcssserver.git
RUN git clone https://github.com/rcsoccersim/rcssmonitor.git

WORKDIR /root/rcssserver
RUN autoreconf -i && ./configure && make && make install && ldconfig
RUN sed 's+^$SERV &+$SERV include=/home/rcsoccersim/rcssserver.opt_log \&+' /usr/local/bin/rcsoccersim > /usr/local/bin/rcsoccersim.with_opt \
    && chmod +x /usr/local/bin/rcsoccersim.with_opt

WORKDIR /root/rcssmonitor
RUN autoreconf -i && ./configure && make && make install && ldconfig

RUN mkdir -p /root/src
WORKDIR /root/src
RUN wget https://osdn.net/dl/rctools/librcsc-4.1.0.tar.gz
RUN tar zxf librcsc-4.1.0.tar.gz
WORKDIR /root/src/librcsc-4.1.0
RUN ./configure && make && make install && ldconfig
WORKDIR /root/src
RUN wget https://osdn.net/dl/rctools/agent2d-3.1.1.tar.gz
RUN tar zxf agent2d-3.1.1.tar.gz
WORKDIR /root/src/agent2d-3.1.1
RUN ./configure && make && make install
WORKDIR /root/src
RUN wget https://osdn.net/dl/rctools/soccerwindow2-5.1.1.tar.gz
RUN tar zxf soccerwindow2-5.1.1.tar.gz
WORKDIR /root/src/soccerwindow2-5.1.1
RUN ./configure && make && make install

RUN useradd -d /home/rcsoccersim -m -s /bin/bash rcsoccersim \
  && echo "rcsoccersim:rcsoccersim" | chpasswd

RUN mkdir -p $TEAM_DIR $LOG_DIR \
    && chown -R rcsoccersim:rcsoccersim $TEAM_DIR \
    && chown -R rcsoccersim:rcsoccersim $LOG_DIR 

USER rcsoccersim
WORKDIR /home/rcsoccersim
RUN mkdir -p $RCSS_CONF_DIR

# rcssserver option
RUN echo \
        server::game_log_dir=$LOG_DIR \
        server::text_log_dir=$LOG_DIR \
        server::game_log_compression=9 \
		    server::text_log_compression=9 \
    > rcssserver.opt_log \
    && echo \
       server::auto_mode=true \
       server::synch_mode=true \
       server::nr_extra_halfs=0 \
       server::penalty_shoot_outs=false \
   > rcssserver.opt_auto

VOLUME $TEAM_DIR
VOLUME $LOG_DIR

WORKDIR $TEAM_DIR

CMD /usr/local/bin/rcsoccersim.with_opt
