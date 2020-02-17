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

More details and examples on running cis-X can be found in the [user guide].

[HOCOMOCO]: http://hocomoco11.autosome.ru/
[user guide]: https://www.stjuderesearch.org/site/docs/zhang/cis-x-instructions-20200210.pdf

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
$ docker image build --tag cis-x .
```

#### Run

The Docker image uses `bin/cis-X` as its entrypoint, giving access to all of its
commands.

The image assumes two working directories: `/data` for inputs and `/results`
for outputs. `/data` can be read-only, whereas `/results` needs write access.
External references (see [cis-X seed][seed]) also need to be mounted to
`/app/refs/external`. For example, mounting to these directories requires three
flags:

```
--mount type=bind,source=$HOME/research/data,target=/data,readonly \
--mount type=bind,source=/tmp/references,target=/app/refs/external,readonly \
--mount type=bind,source=$(pwd)/cis-x-out,target=/results \
```

The source directives can point to any absolute path that can be accessed
locally. They do not need to match their target directory. Also note that the
results directory must exist before running the command.

##### Examples

###### cis-X seed

A basic example is running [cis-X seed][seed], which downloads and preprocesses
required reference files to a directory. To run this locally, the `seed`
subcommand is used, passing the destination directory of the resulting files.

```
$ cis-X seed /tmp/refs/external
```

To run this in a container using the Docker image, pass the subcommand and arguments
as the command the container runs.

```
$ docker container run cis-x seed /tmp/refs/external
```

This, however, writes files to the container, rather than the host. To write
files to the host from the container, mount the host destination directory to
the container, e.g., `$(pwd)/refs/external` to `/app/refs/external`. The
argument passed to the command must match the target directory.

```
$ docker container run \
    --mount type=bind,source=$(pwd)/refs/external,target=/app/refs/external \
    cis-x \
    seed \
    /app/refs/external
```

###### cis-X run

The following template is the entire command to execute the `run` command,
with variables showing what needs to be set.

```
$ docker container run \
    --mount type=bind,source=$DATA_DIR,target=/data,readonly \
    --mount type=bind,source=$REFS_DIR,target=/app/refs/external,readonly \
    --mount type=bind,source=$RESULT_DIR,target=/results \
    cis-x \
    run \
    -s $SAMPLE_ID \
    -o /results \
    -l /data/$MARKERS \
    -g /data/$CNV_LOH_REGIONS \
    -b /data/$BAM \
    -e /data/$GENE_EXPRESSION_TABLE \
    -m /data/$SOMATIC_SNV_INDEL \
    -v /data/$SOMATIC_SV \
    -c /data/$SOMATIC_CNV \
    -d $DISEASE \
    -a $CNV_LOH_ACTION \
    -w $MIN_COV_WGS \
    -r $MIN_COV_RNA_SEQ \
    -f $FPKM_THRESHOLD_CANDIDATE
```

Note that pathname arguments are relative to the container's target. For
example, mounting `$HOME/research` and with an input located at
`$HOME/research/sample-001/markers.txt`, the corresponding argument is
`/data/sample-001/markers.txt`.

See the [Docker reference for `run`][docker-run] for more options.

[docker-run]: https://docs.docker.com/engine/reference/run/

## Demo

The next example runs cis-X with [demo data] (`cis-X-demo.tar.gz`).

Set up the project home directory with the demo data. The following commands
assume the demo is extracted to a `tmp` directory in the root of the project.

```
$ git clone https://github.com/stjude/cis-x.git
$ cd cis-x
$ docker image build --tag cis-x .
$ mkdir tmp
$ wget --directory-prefix tmp http://ftp.stjude.org/pub/software/cis-x/cis-X-demo.tar.gz
$ tar xf tmp/cis-X-demo.tar.gz --directory tmp
```

Then run cis-X.

```
$ docker container run \
    --mount type=bind,source=$(pwd)/tmp/demo/data,target=/data,readonly \
    --mount type=bind,source=$(pwd)/tmp/demo/ref,target=/app/refs/external,readonly \
    --mount type=bind,source=$(pwd)/tmp,target=/results \
    cis-x \
    run \
    -s SJALL018373_D1 \
    -o /results \
    -l /data/SJALL018373_D1.test.wgs.markers.txt \
    -g /data/SJALL018373_D1.test.wgs.cnvloh.txt \
    -b /data/SJALL018373_D1.test.RNAseq.bam \
    -e /data/SJALL018373_D1.test.RNASEQ_all_fpkm.txt \
    -m /data/SJALL018373_D1.test.mut.txt \
    -v /data/SJALL018373_D1.test.sv.txt \
    -c /data/SJALL018373_D1.test.cna.txt \
    -d TALL \
    -a drop \
    -w 10 \
    -r 10 \
    -f 5
```

[demo data]: https://www.stjuderesearch.org/site/lab/zhang/cis-x

[ref-exp]: https://github.com/stjude/cis-x/tree/master/src/ref-exp
[run]: https://github.com/stjude/cis-x/tree/master/src/core
[seed]: https://github.com/stjude/cis-x/tree/master/src/seed
