FROM ubuntu:20.04
RUN apt-get update -y
RUN apt-get install wget build-essential -y
WORKDIR /opt/
RUN wget https://github.com/Groestlcoin/groestlcoin/releases/download/v28.0/groestlcoin-28.0-x86_64-linux-gnu.tar.gz
RUN tar zxvf groestlcoin-28.0-x86_64-linux-gnu.tar.gz
RUN mv groestlcoin-28.0/bin/groestlcoin* /usr/bin/
RUN wget https://raw.githubusercontent.com/TheRetroMike/rmt-nomp/master/scripts/blocknotify.c
RUN gcc blocknotify.c -o /usr/bin/blocknotify
CMD /usr/bin/groestlcoind -printtoconsole
