### Verify Binaries

#### Usage:

This script attempts to download the signature file `SHA256SUMS.asc` from https://github.com/Groestlcoin/groestlcoin/releases.

It first checks if the signature passes, and then downloads the files specified in the file, and checks if the hashes of these files match those that are specified in the signature file.

The script returns 0 if everything passes the checks. It returns 1 if either the signature check or the hash check doesn't pass. If an error occurs the return value is 2.


```sh
./verify.py groestlcoin-core-2.17.2
./verify.py groestlcoin-core-2.18.2
./verify.py groestlcoin-core-2.19.1
```

If you only want to download the binaries of certain platform, add the corresponding suffix, e.g.:

```sh
./verify.py groestlcoin-core-2.17.2-osx
./verify.py 2.18.2-linux
./verify.py groestlcoin-core-2.19.1-win64
```

If you do not want to keep the downloaded binaries, specify anything as the second parameter.

```sh
./verify.py groestlcoin-core-2.18.2 delete
```
