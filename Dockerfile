FROM ubuntu:18.04
RUN apt-get update -y
RUN apt-get install wget nodejs build-essential -y
WORKDIR /opt/
RUN wget https://github.com/Groestlcoin/groestlcoin/releases/download/v27.0/groestlcoin-27.0-x86_64-linux-gnu.tar.gz
RUN tar zxvf groestlcoin-27.0-x86_64-linux-gnu.tar.gz
RUN mv groestlcoin-27.0/bin/groestlcoin* /usr/bin/
RUN wget https://raw.githubusercontent.com/TheRetroMike/rmt-nomp/master/scripts/blocknotify.c
RUN gcc blocknotify.c -o /usr/bin/blocknotify
CMD /usr/bin/groestlcoind -daemon;tail -f /root/.groestlcoin/debug.log
