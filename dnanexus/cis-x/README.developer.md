# St. Jude cis-X (dev)

The main script runs a container with a pre-built cis-X image. The DNAnexus
applet only executes the `run` command.

## Build

```
$ docker build --tag cis-x ../..
$ mkdir -p resources/tmp
$ docker save cis-x | gzip > resources/tmp/cis-x-latest.tar.gz
$ dx build
```
