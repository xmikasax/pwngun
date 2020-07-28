# pwngun
Docker environment for pwning
[![Build Status](https://travis-ci.com/xmikasax/pwngun.svg?branch=master)](https://travis-ci.com/xmikasax/pwngun)

* `spl` - put sploit template script in currect directory
* `libc-identify $LIBC_PATH` - find libc by hash
* `libc-find $FUNC $ADDR` - find libc by function address
* `libc-download $NAME` - download libc to current directory
* `newa $NAME` - create or attach to tmux session

---

Where to get it

* `docker pull fl3x3dd/pwngun:latest`
* `docker pull fl3x3dd/pwngun:2.23`
* `docker pull fl3x3dd/pwngun:2.27`
* `docker pull fl3x3dd/pwngun:2.29`
* `docker pull fl3x3dd/pwngun:2.30`
* `docker pull fl3x3dd/pwngun:2.31`
