#!/usr/bin/env bash
#
# Copyright (c) 2019-2021 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

export CONTAINER_NAME=ci_macos_cross
export DOCKER_NAME_TAG=ubuntu:20.04  # Check that Focal can cross-compile to macos
export HOST=x86_64-apple-darwin
export PACKAGES="cmake libz-dev libtinfo5 python3-setuptools xorriso"
export XCODE_VERSION=12.1
export XCODE_BUILD_ID=12A7403
export GOAL="deploy"
export GROESTLCOIN_CONFIG="--with-gui --enable-reduce-exports"
