# cis-X run

**cis-X run** is a command to search for activating regulatory variants in the
*tumor genome.

## Prerequisites

  * [Perl] ^5.10.1
    * [Data::Compare] ~1.25
  * [R] ^3.1.0
    * [multtest] ~2.36.0
  * [Java SE Runtime Environment] ~1.8.0_66
  * [MEME Suite] =4.9.0
  * [twoBitToFa]\*
  * [variants2matrix] (See below.)

\* The UCSC Genome Browser pre-compiled binaries are not versioned, but the
latest version _should_ work.

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

External references are expected to be in `$CIS_X_HOME/refs/external`. These
are not distributed with cis-X, but the `cis-X seed` command can download and
generate them. See cis-X-seed for more details and a list of required
reference files.

## Usage

```
$ cis-X-run <sample-id> <results-dir> <markers> <cnv-loh> <bam> <fpkm-matrix> <snv-indel> <sv> <cna> <disease>
```
