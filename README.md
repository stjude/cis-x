# cis-X

**cis-X** searches for activating regulatory variants in the tumor genome.

Activating regular variants usually cause the cis-activation of target genes.
To find cis-activated genes, allelic specific/imbalance expressions (ASE) and
outlier high expression (OHE) signals are used. Variants in the same
topologically associated domains with the candidates can then be searched,
including structural variants (SV), copy number aberrations (CNA), and single
nucleotide variations (SNV) and insertion/deletions (indel).

A transcription factor binding analysis is also done, using motifs from
[HOCOMOCO] v10 models.

cis-X currently only works with hg19 (GRCh37).

[HOCOMOCO]: http://hocomoco11.autosome.ru/

## Installation

Installation is simply unpacking the source to a working directory and adding
`$CIS_X_HOME/bin` to `PATH`.

### Prerequisites

See [cis-X run][run] and [cis-X seed][seed] for the required tools and
references.

## Usage

```
cis-X

USAGE:
    cis-X <SUBCOMMAND> [args...]

SUBCOMMANDS:
    ref-exp  Generate reference expression matrices
    run      Search for activating regulatory variants in the tumor genome
    seed     Download and generate a set of common references
```

For more details on how to run each command, see its respective README:
[ref-exp], [run], and [seed].

### Docker

cis-X has a `Dockerfile` to create a [Docker] image, which sets up and
installs all the required dependencies (sans references). To use this image,
[install Docker](https://docs.docker.com/install) for your platform.

For typical inputs, cis-X requires at least 4 GiB of RAM. This resource can
be increased for the desktop version of Docker by going to Docker preferences
\> Advanced \> Memory.

[Docker]: https://www.docker.com/

#### Build

In the cis-X project directory, build the Docker image.

```
$ docker build --tag cis-x .
```

#### Run

The Docker image uses `bin/cis-X` as its entrypoint, giving access to all of its
commands.

The image assumes two working directories: `/data` for inputs and `/results`
for outputs. `/data` can be read-only, whereas `/results` needs write access.
External references also need to be mounted to `/app/refs/external`. For
example, mounting to these directories requires three flags:

```
--mount type=bind,source=$HOME/research/data,target=/data,readonly \
--mount type=bind,source=/tmp/references,target=/app/refs/external,readonly \
--mount type=bind,source=$(pwd)/cis-x-out,target=/results \
```

The source directives can point to any absolute path that can be accessed
locally. They do not need to match their target directory. Also note that the
results directory must exist before running the command.

The following template is the entire command to execute the `run` command,
with variables showing what needs to be set.

```
$ docker run \
    --mount type=bind,source=$DATA_DIR,target=/data,readonly \
    --mount type=bind,source=$REFS_DIR,target=/app/refs/external,readonly \
    --mount type=bind,source=$RESULT_DIR,target=/results \
    cis-x \
    run \
    $SAMPLE_ID \
    /results \
    /data/$MARKERS \
    /data/$CNV_LOH_REGIONS \
    /data/$BAM \
    /data/$GENE_EXPRESSION_TABLE \
    /data/$SOMATIC_SNV_INDEL \
    /data/$SOMATIC_SV \
    /data/$SOMATIC_CNV \
    $DISEASE \
    $CNV_LOH_ACTION \
    $MIN_COV_WGS \
    $MIN_COV_RNA_SEQ
```

Note that pathname arguments are relative to the container's target. For
example, mounting `$HOME/research` and with an input located at
`$HOME/research/sample-001/markers.txt`, the corresponding argument is
`/data/sample-001/markers.txt`.

See the [Docker reference for `run`][docker-run] for more options.

[docker-run]: https://docs.docker.com/engine/reference/run/

## Demo

The next example runs cis-X with [demo data] (`cis-X-demo.tar.gz`). It
assumes the demo is extracted to a `tmp` directory in the root of the
project.

```
$ docker run \
    --mount type=bind,source=$(pwd)/tmp/demo/data,target=/data,readonly \
    --mount type=bind,source=$(pwd)/tmp/demo/ref,target=/app/refs/external,readonly \
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
    TALL \
    drop \
    10 \
    10
```

[demo data]: https://www.stjuderesearch.org/site/lab/zhang/cis-x

[ref-exp]: https://github.com/stjude/cis-x/tree/master/src/ref-exp
[run]: https://github.com/stjude/cis-x/tree/master/src/core
[seed]: https://github.com/stjude/cis-x/tree/master/src/seed
