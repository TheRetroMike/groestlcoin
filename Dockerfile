FROM ubuntu:20.04
RUN apt-get update -y
RUN apt-get install unzip wget build-essential libssl-dev libdb++-dev libboost-all-dev libminiupnpc-dev libqrencode-dev libevent-dev obfs4proxy libcurl4-openssl-dev -y
WORKDIR /opt/
RUN wget https://github.com/Groestlcoin/groestlcoin/releases/download/v27.0/groestlcoin-27.0-x86_64-linux-gnu.tar.gz
RUN tar zxvf groestlcoin-27.0-x86_64-linux-gnu.tar.gz
COPY groestlcoin-27.0/bin/groestlcoind /groestlcoind
COPY groestlcoin-27.0/bin/groestlcoin-cli /groestlcoin-cli
RUN rm groestlcoin-27.0-x86_64-linux-gnu.tar.gz
CMD ./groestlcoind -daemon;tail -f /root/.groestlcoin/debug.log
