[![Build Status](https://travis-ci.org/madworx/docker-minix.svg?branch=master)](https://travis-ci.org/madworx/docker-minix)

# docker-minix

QEMU-based Docker image for Minix 3, based on the official CD-ROM ISO image installation from the Minix website.

Available at Docker hub as [madworx/minix](https://hub.docker.com/r/madworx/minix/).

## Usage

```
# Run a specific command in MINIX:
$ docker run --rm -it madworx/minix uname -a
Minix 192.168.76.9 3.3.0 Minix 3.3.0 (GENERIC) i386

# Start in background, connect via ssh:
$ docker run --rm -d --name minix madworx/minix
$ docker exec -it minix ssh localhost
For post-installation usage tips such as installing binary
packages, please see:
http://wiki.minix3.org/UsersGuide/PostInstallation

For more information on how to use MINIX 3, see the wiki:
http://wiki.minix3.org

We'd like your feedback: http://minix3.org/community/

#
```

## Source

Everything is hosted on [github](https://github.com/madworx/docker-debian-archive).
