# cis-X

**cis-X** searches for activating regulatory variants in the tumor genome.

## Prerequisites

  * [Perl] ^5.10.1
    * [Data::Compare] ~1.25
  * [R] ^3.1.0
    * [multtest] ~2.36.0
  * [Java SE Runtime Environment] ~1.8.0_66
  * [MEME Suite] =4.9.0
  * [twoBitToFa] (The UCSC Genome Browser does not version their pre-compiled
    binaries, but the latest version _should_ work.)
  * [variants2matrix] (See below.)

[Perl]: https://www.perl.org/
[Data::Compare]: https://metacpan.org/pod/Data::Compare
[R]: https://www.r-project.org/
[multtest]: https://www.bioconductor.org/packages/release/bioc/html/multtest.html
[Java SE Runtime Environment]: http://www.oracle.com/technetwork/java/javase/overview/index.html
[MEME Suite]: http://meme-suite.org/
[twoBitToFa]: https://genome.ucsc.edu/goldenpath/help/twoBit.html
[variants2matrix]: #variants2matrix

### variants2matrix

variants2matrix is (maybe) included with cis-X in the `vendor` directory. It
is expected to be in `PATH`, along with its Perl library and Java class
paths.

```
V2M_HOME=$(pwd)/vendor/variants2matrix
export PATH=$V2M_HOME/bin:$PATH
export PERL5LIB=$V2M_HOME/lib/perl
export CLASSPATH=$V2M_HOME/lib/java/bambino-1.0.jar:$V2M_HOME/lib/java/indelxref-1.0.jar:$V2M_HOME/lib/java/picard.jar:$V2M_HOME/lib/java/samplenamelib-1.0.jar
```

### References

See cis-X-seed for a list of required reference files.

## Demo

### Docker

cis-X has a `Dockerfile` to create a [Docker] image, which sets up and
installs all the required dependencies. To use this image, [install
Docker](https://docs.docker.com/install) for your platform.

cis-X requires at least 4 GiB of RAM. This resource can be increased for the
desktop version of Docker by going to Docker preferences > Advanced > Memory.

In the cis-X project directory, build the Docker image.

```
$ docker build --tag cis-x .
```

The next example runs the newly created cis-X image with the demo data and
references. It assumes the demo was extracted to a `tmp` directory in the
project directory. The `source` directives in the `mount` option can be any
absolute path on the local filesystem, but note that the arguments to cis-X
are relative to the container's target.

```
$ docker run \
    --mount type=bind,source=$(pwd)/tmp/demo/data,target=/data,readonly \
    --mount type=bind,source=$(pwd)/tmp/demo/ref,target=/refs,readonly \
    --mount type=bind,source=$(pwd)/tmp,target=/results \
    cis-x \
    run \
    SJALL018373_D1 \
    /results \
    /data/SJALL018373_D1.test.wgs.markers.txt \
    /data/SJALL018373_D1.test.wgs.cnvloh.txt \
    /data/SJALL018373_D1.test.RNAseq.bam \
    /data/SJALL018373_D1.test.RNASEQ_all_fpkm.txt \
    /data/SJALL018373_D1.test.mut.txt \
    /data/SJALL018373_D1.test.sv.txt \
    /data/SJALL018373_D1.test.cna.txt \
    TALL
```

[Docker]: https://www.docker.com/
