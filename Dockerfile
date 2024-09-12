FROM ubuntu:18.04
RUN apt-get update -y
RUN apt-get install wget nodejs -y
WORKDIR /opt/
RUN wget https://github.com/Groestlcoin/groestlcoin/releases/download/v27.0/groestlcoin-27.0-x86_64-linux-gnu.tar.gz
RUN tar zxvf groestlcoin-27.0-x86_64-linux-gnu.tar.gz
RUN mv groestlcoin-27.0/bin/groestlcoin* /usr/bin/
RUN wget -o /usr/bin/cli.js https://raw.githubusercontent.com/TheRetroMike/rmt-nomp/master/scripts/cli.js
#RUN rm groestlcoin-27.0-x86_64-linux-gnu.tar.gz
CMD /usr/bin/groestlcoind -daemon;tail -f /root/.groestlcoin/debug.log
