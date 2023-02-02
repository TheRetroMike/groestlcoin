UNIX BUILD NOTES
====================
Some notes on how to build Groestlcoin Core in Unix.

(For BSD specific instructions, see `build-*bsd.md` in this directory.)

Note
---------------------
Always use absolute paths to configure and compile Groestlcoin Core and the dependencies.
For example, when specifying the path of the dependency:

    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX

Here BDB_PREFIX must be an absolute path - it is defined using $(pwd) which ensures
the usage of the absolute path.

To Build
---------------------

```bash
./autogen.sh
./configure
make # use "-j N" for N parallel jobs
make install # optional
```

This will build groestlcoin-qt as well, if the dependencies are met.

See [dependencies.md](dependencies.md) for a complete overview.

Memory Requirements
--------------------

C++ compilers are memory-hungry. It is recommended to have at least 1.5 GB of
memory available when compiling Groestlcoin Core. On systems with less, gcc can be
tuned to conserve memory with additional CXXFLAGS:


    ./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768"

Alternatively, or in addition, debugging information can be skipped for compilation. The default compile flags are
`-g -O2`, and can be changed with:

    ./configure CXXFLAGS="-O2"

Finally, clang (often less resource hungry) can be used instead of gcc, which is used by default:

    ./configure CXX=clang++ CC=clang

## Linux Distribution Specific Instructions

### Ubuntu & Debian

#### Dependency Build Instructions

Build requirements:

    sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3

Now, you can either build from self-compiled [depends](/depends/README.md) or install the required dependencies:

    sudo apt-get install libevent-dev libboost-dev

SQLite is required for the descriptor wallet:

    sudo apt install libsqlite3-dev

To build Groestlcoin Core without wallet, see [*Disable-wallet mode*](#disable-wallet-mode)

Optional port mapping libraries (see: `--with-miniupnpc` and `--with-natpmp`):

    sudo apt install libminiupnpc-dev libnatpmp-dev

ZMQ dependencies (provides ZMQ API):

    sudo apt-get install libzmq3-dev

User-Space, Statically Defined Tracing (USDT) dependencies:

    sudo apt install systemtap-sdt-dev

GUI dependencies:

If you want to build groestlcoin-qt, make sure that the required packages for Qt development
are installed. Qt 5 is necessary to build the GUI.
To build without GUI pass `--without-gui`.

To build with Qt 5 you need the following:

    sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools

Additionally, to support Wayland protocol for modern desktop environments:

    sudo apt install qtwayland5

libqrencode (optional) can be installed with:

    sudo apt-get install libqrencode-dev

Once these are installed, they will be found by configure and a groestlcoin-qt executable will be
built by default.


### Fedora

#### Dependency Build Instructions

Build requirements:

    sudo dnf install gcc-c++ libtool make autoconf automake python3

Now, you can either build from self-compiled [depends](/depends/README.md) or install the required dependencies:

    sudo dnf install libevent-devel boost-devel

SQLite is required for the descriptor wallet:

    sudo dnf install sqlite-devel

Berkeley DB is required for the legacy wallet:

    sudo dnf install libdb libdb-cxx-devel


To build Groestlcoin Core without wallet, see [*Disable-wallet mode*](#disable-wallet-mode)

Optional port mapping libraries (see: `--with-miniupnpc` and `--with-natpmp`):

    sudo dnf install miniupnpc-devel libnatpmp-devel

ZMQ dependencies (provides ZMQ API):

    sudo dnf install zeromq-devel

User-Space, Statically Defined Tracing (USDT) dependencies:

    sudo dnf install systemtap

GUI dependencies:

If you want to build groestlcoin-qt, make sure that the required packages for Qt development
are installed. Qt 5 is necessary to build the GUI.
To build without GUI pass `--without-gui`.

To build with Qt 5 you need the following:

    sudo dnf install qt5-qttools-devel qt5-qtbase-devel

Additionally, to support Wayland protocol for modern desktop environments:

    sudo dnf install qt5-qtwayland

libqrencode (optional) can be installed with:

    sudo dnf install qrencode-devel

Once these are installed, they will be found by configure and a groestlcoin-qt executable will be
built by default.

Notes
-----
The release is built with GCC and then "strip groestlcoind" to strip the debug
symbols, which reduces the executable size by about 90%.

miniupnpc
---------

[miniupnpc](https://miniupnp.tuxfamily.org) may be used for UPnP port mapping.  It can be downloaded from [here](
https://miniupnp.tuxfamily.org/files/).  UPnP support is compiled in and
turned off by default.

libnatpmp
---------

[libnatpmp](https://miniupnp.tuxfamily.org/libnatpmp.html) may be used for NAT-PMP port mapping. It can be downloaded
from [here](https://miniupnp.tuxfamily.org/files/). NAT-PMP support is compiled in and
turned off by default.

Berkeley DB
-----------

The legacy wallet uses Berkeley DB. To ensure backwards compatibility it is
recommended to use Berkeley DB 5.3. If you have to build it yourself, and don't
want to use any other libraries built in depends, you can do:
```bash
make -C depends NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_UPNP=1 NO_ZMQ=1 NO_USDT=1
...
to: /path/to/groestlcoin/depends/x86_64-pc-linux-gnu
```
and configure using the following:
```bash
export BDB_PREFIX="/path/to/groestlcoin/depends/x86_64-pc-linux-gnu"

./configure \
    BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-5.3" \
    BDB_CFLAGS="-I${BDB_PREFIX}/include"
```

**Note**: You only need Berkeley DB if the legacy wallet is enabled (see [*Disable-wallet mode*](#disable-wallet-mode)).

Security
--------
To help make your Groestlcoin Core installation more secure by making certain attacks impossible to
exploit even if a vulnerability is found, binaries are hardened by default.
This can be disabled with:

Hardening Flags:

    ./configure --enable-hardening
    ./configure --disable-hardening


Hardening enables the following features:
* _Position Independent Executable_: Build position independent code to take advantage of Address Space Layout Randomization
    offered by some kernels. Attackers who can cause execution of code at an arbitrary memory
    location are thwarted if they don't know where anything useful is located.
    The stack and heap are randomly located by default, but this allows the code section to be
    randomly located as well.

    On an AMD64 processor where a library was not compiled with -fPIC, this will cause an error
    such as: "relocation R_X86_64_32 against `......' can not be used when making a shared object;"

    To test that you have built PIE executable, install scanelf, part of paxutils, and use:

        scanelf -e ./groestlcoin

    The output should contain:

     TYPE
    ET_DYN

* _Non-executable Stack_: If the stack is executable then trivial stack-based buffer overflow exploits are possible if
    vulnerable buffers are found. By default, Groestlcoin Core should be built with a non-executable stack,
    but if one of the libraries it uses asks for an executable stack or someone makes a mistake
    and uses a compiler extension which requires an executable stack, it will silently build an
    executable without the non-executable stack protection.

    To verify that the stack is non-executable after compiling use:
    `scanelf -e ./groestlcoin`

    The output should contain:
    STK/REL/PTL
    RW- R-- RW-

    The STK RW- means that the stack is readable and writeable but not executable.

Disable-wallet mode
--------------------
When the intention is to only run a P2P node, without a wallet, Groestlcoin Core can
be compiled in disable-wallet mode with:

    ./configure --disable-wallet

In this case there is no dependency on SQLite or Berkeley DB.

Mining is also possible in disable-wallet mode using the `getblocktemplate` RPC call.

Additional Configure Flags
--------------------------
A list of additional configure flags can be displayed with:

    ./configure --help


Setup and Build Example: Arch Linux
-----------------------------------
This example lists the steps necessary to setup and build a command line only distribution of the latest changes on Arch Linux:

    pacman --sync --needed autoconf automake boost gcc git libevent libtool make pkgconf python sqlite
    git clone https://github.com/groestlcoin/groestlcoin.git
    cd groestlcoin/
    ./autogen.sh
    ./configure
    ./src/groestlcoind

If you intend to work with legacy Berkeley DB wallets, see [Berkeley DB](#berkeley-db) section.
