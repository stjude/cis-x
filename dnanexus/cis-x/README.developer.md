# St. Jude cis-X (dev)

The main script runs a container with a pre-built cis-X image. The DNAnexus
applet only executes the `run` command.

## Build

```
$ docker build --tag cis-x ../..
$ dx-docker add-to-applet cis-x .
$ dx build
```

Note dx-docker exports the image in the ACI format, which requires
[docker2aci] to be installed.

[docker2aci]: https://github.com/appc/docker2aci
