#!/usr/bin/env bash
#
# Copyright (c) 2019-2022 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

export CI_IMAGE_NAME_TAG="debian:bookworm"
export CONTAINER_NAME=ci_native_valgrind
export PACKAGES="valgrind clang llvm libclang-rt-dev python3-zmq libevent-dev bsdmainutils libboost-dev libdb5.3++-dev libminiupnpc-dev libnatpmp-dev libzmq3-dev libsqlite3-dev"
export NO_DEPENDS=1
export GOAL="install"
# Temporarily pin dwarf 4, until using Valgrind 3.20 or later
export GROESTLCOIN_CONFIG="--enable-zmq --with-incompatible-bdb --with-gui=no CC=clang CXX=clang++ CFLAGS='-gdwarf-4' CXXFLAGS='-gdwarf-4'"  # TODO enable GUI
