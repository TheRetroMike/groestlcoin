#!/usr/bin/env bash
#
# Copyright (c) 2018-2022 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C.UTF-8

set -ex

if [ "$CI_OS_NAME" == "macos" ]; then
  top -l 1 -s 0 | awk ' /PhysMem/ {print}'
  echo "Number of CPUs: $(sysctl -n hw.logicalcpu)"
else
  free -m -h
  echo "Number of CPUs \(nproc\):" \$\(nproc\)
  lscpu | grep Endian
fi
echo "Free disk space:"
df -h

if [ "$RUN_FUZZ_TESTS" = "true" ]; then
  export DIR_FUZZ_IN=${DIR_QA_ASSETS}/fuzz_seed_corpus/
  if [ ! -d "$DIR_FUZZ_IN" ]; then
    git clone --depth=1 https://github.com/bitcoin-core/qa-assets "${DIR_QA_ASSETS}"
  fi
elif [ "$RUN_UNIT_TESTS" = "true" ] || [ "$RUN_UNIT_TESTS_SEQUENTIAL" = "true" ]; then
  export DIR_UNIT_TEST_DATA=${DIR_QA_ASSETS}/unit_test_data/
  if [ ! -d "$DIR_UNIT_TEST_DATA" ]; then
    mkdir -p "$DIR_UNIT_TEST_DATA"
    curl --location --fail https://github.com/bitcoin-core/qa-assets/raw/main/unit_test_data/script_assets_test.json -o "${DIR_UNIT_TEST_DATA}/script_assets_test.json"
  fi
fi

mkdir -p "${BASE_SCRATCH_DIR}/sanitizer-output/"

if [ "$USE_BUSY_BOX" = "true" ]; then
  echo "Setup to use BusyBox utils"
  # tar excluded for now because it requires passing in the exact archive type in ./depends (fixed in later BusyBox version)
  # ar excluded for now because it does not recognize the -q option in ./depends (unknown if fixed)
  for util in $(busybox --list | grep -v "^ar$" | grep -v "^tar$" ); do ln -s "$(command -v busybox)" "${BINS_SCRATCH_DIR}/$util"; done
  # Print BusyBox version
  patch --help
fi

# Make sure default datadir does not exist and is never read by creating a dummy file
if [ "$CI_OS_NAME" == "macos" ]; then
  echo > "${HOME}/Library/Application Support/Bitcoin"
else
  echo > "${HOME}/.bitcoin"
fi

if [ -z "$NO_DEPENDS" ]; then
  if [[ $CI_IMAGE_NAME_TAG == *centos* ]]; then
    # CentOS has problems building the depends if the config shell is not explicitly set
    # (i.e. for libevent a Makefile with an empty SHELL variable is generated, leading to
    #  an error as the first command is executed)
    SHELL_OPTS="LC_ALL=en_US.UTF-8 CONFIG_SHELL=/bin/dash"
  else
    SHELL_OPTS="CONFIG_SHELL="
  fi
  bash -c "$SHELL_OPTS make $MAKEJOBS -C depends HOST=$HOST $DEP_OPTS LOG=1"
fi
if [ "$DOWNLOAD_PREVIOUS_RELEASES" = "true" ]; then
  test/get_previous_releases.py -b -t "$PREVIOUS_RELEASES_DIR"
fi

BITCOIN_CONFIG_ALL="--enable-suppress-external-warnings --disable-dependency-tracking"
if [ -z "$NO_DEPENDS" ]; then
  BITCOIN_CONFIG_ALL="${BITCOIN_CONFIG_ALL} CONFIG_SITE=$DEPENDS_DIR/$HOST/share/config.site"
fi
if [ -z "$NO_WERROR" ]; then
  BITCOIN_CONFIG_ALL="${BITCOIN_CONFIG_ALL} --enable-werror"
fi

ccache --zero-stats --max-size="${CCACHE_SIZE}"
PRINT_CCACHE_STATISTICS="ccache --version | head -n 1 && ccache --show-stats"

if [ -n "$ANDROID_TOOLS_URL" ]; then
  make distclean || true
  ./autogen.sh
  bash -c "./configure $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG" || ( (cat config.log) && false)
  make "${MAKEJOBS}" && cd src/qt && ANDROID_HOME=${ANDROID_HOME} ANDROID_NDK_HOME=${ANDROID_NDK_HOME} make apk
  bash -c "${PRINT_CCACHE_STATISTICS}"
  exit 0
fi

BITCOIN_CONFIG_ALL="${BITCOIN_CONFIG_ALL} --enable-external-signer --prefix=$BASE_OUTDIR"

if [ -n "$CONFIG_SHELL" ]; then
  "$CONFIG_SHELL" -c "./autogen.sh"
else
  ./autogen.sh
fi

mkdir -p "${BASE_BUILD_DIR}"
cd "${BASE_BUILD_DIR}"

bash -c "${BASE_ROOT_DIR}/configure --cache-file=config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG" || ( (cat config.log) && false)

make distdir VERSION="$HOST"

cd "${BASE_BUILD_DIR}/bitcoin-$HOST"

bash -c "./configure --cache-file=../config.cache $BITCOIN_CONFIG_ALL $BITCOIN_CONFIG" || ( (cat config.log) && false)

set -o errtrace
trap 'bash -c "cat ${BASE_SCRATCH_DIR}/sanitizer-output/* 2> /dev/null"' ERR

if [[ ${USE_MEMORY_SANITIZER} == "true" ]]; then
  # MemorySanitizer (MSAN) does not support tracking memory initialization done by
  # using the Linux getrandom syscall. Avoid using getrandom by undefining
  # HAVE_SYS_GETRANDOM. See https://github.com/google/sanitizers/issues/852 for
  # details.
  grep -v HAVE_SYS_GETRANDOM src/config/bitcoin-config.h > src/config/bitcoin-config.h.tmp && mv src/config/bitcoin-config.h.tmp src/config/bitcoin-config.h
fi

if [[ "${RUN_TIDY}" == "true" ]]; then
  MAYBE_BEAR="bear --config src/.bear-tidy-config"
  MAYBE_TOKEN="--"
fi

bash -c "${MAYBE_BEAR} ${MAYBE_TOKEN} make $MAKEJOBS $GOAL" || ( echo "Build failure. Verbose build follows." && make "$GOAL" V=1 ; false )

bash -c "${PRINT_CCACHE_STATISTICS}"
du -sh "${DEPENDS_DIR}"/*/
du -sh "${PREVIOUS_RELEASES_DIR}"

if [[ $HOST = *-mingw32 ]]; then
  # Generate all binaries, so that they can be wrapped
  make "$MAKEJOBS" -C src/secp256k1 VERBOSE=1
  #make "$MAKEJOBS" -C src minisketch/test.exe VERBOSE=1
  "${BASE_ROOT_DIR}/ci/test/wrap-wine.sh"
fi

if [ -n "$QEMU_USER_CMD" ]; then
  # Generate all binaries, so that they can be wrapped
  make "$MAKEJOBS" -C src/secp256k1 VERBOSE=1
  #make "$MAKEJOBS" -C src minisketch/test VERBOSE=1
  "${BASE_ROOT_DIR}/ci/test/wrap-qemu.sh"
fi

if [ "$RUN_SECURITY_TESTS" = "true" ]; then
  make test-security-check
fi
