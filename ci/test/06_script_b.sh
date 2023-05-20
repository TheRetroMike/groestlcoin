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
  echo "Number of CPUs (nproc): $(nproc)"
  lscpu | grep Endian
fi
echo "Free disk space:"
df -h

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
  echo > "${HOME}/Library/Application Support/Groestlcoin"
else
  echo > "${HOME}/.groestlcoin"
fi

if [ -z "$NO_DEPENDS" ]; then
  if [[ $CI_IMAGE_NAME_TAG == *centos* ]]; then
    SHELL_OPTS="CONFIG_SHELL=/bin/dash"
  else
    SHELL_OPTS="CONFIG_SHELL="
  fi
  bash -c "$SHELL_OPTS make $MAKEJOBS -C depends HOST=$HOST $DEP_OPTS LOG=1"
fi
if [ "$DOWNLOAD_PREVIOUS_RELEASES" = "true" ]; then
  test/get_previous_releases.py -b -t "$PREVIOUS_RELEASES_DIR"
fi

GROESTLCOIN_CONFIG_ALL="--enable-suppress-external-warnings --disable-dependency-tracking"
if [ -z "$NO_DEPENDS" ]; then
  GROESTLCOIN_CONFIG_ALL="${GROESTLCOIN_CONFIG_ALL} CONFIG_SITE=$DEPENDS_DIR/$HOST/share/config.site"
fi
if [ -z "$NO_WERROR" ]; then
  GROESTLCOIN_CONFIG_ALL="${GROESTLCOIN_CONFIG_ALL} --enable-werror"
fi

ccache --zero-stats --max-size="${CCACHE_SIZE}"
PRINT_CCACHE_STATISTICS="ccache --version | head -n 1 && ccache --show-stats"

if [ -n "$ANDROID_TOOLS_URL" ]; then
  make distclean || true
  ./autogen.sh
  bash -c "./configure $GROESTLCOIN_CONFIG_ALL $GROESTLCOIN_CONFIG" || ( (cat config.log) && false)
  make "${MAKEJOBS}" && cd src/qt && ANDROID_HOME=${ANDROID_HOME} ANDROID_NDK_HOME=${ANDROID_NDK_HOME} make apk
  bash -c "${PRINT_CCACHE_STATISTICS}"
  exit 0
fi

GROESTLCOIN_CONFIG_ALL="${GROESTLCOIN_CONFIG_ALL} --enable-external-signer --prefix=$BASE_OUTDIR"

if [ -n "$CONFIG_SHELL" ]; then
  "$CONFIG_SHELL" -c "./autogen.sh"
else
  ./autogen.sh
fi

mkdir -p "${BASE_BUILD_DIR}"
cd "${BASE_BUILD_DIR}"

bash -c "${BASE_ROOT_DIR}/configure --cache-file=config.cache $GROESTLCOIN_CONFIG_ALL $GROESTLCOIN_CONFIG" || ( (cat config.log) && false)

make distdir VERSION="$HOST"

cd "${BASE_BUILD_DIR}/groestlcoin-$HOST"

bash -c "./configure --cache-file=../config.cache $GROESTLCOIN_CONFIG_ALL $GROESTLCOIN_CONFIG" || ( (cat config.log) && false)

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
