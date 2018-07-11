# cis-X ref-exp

**cis-X ref-exp** generates reference expression matrices used for outlier
high expression (OHE) tests.

cis-X uses precalculated reference expression matrices for finding outlier
high expression (OHE) signals, which is disease specific. cis-X includes
references for pediatric T-ALL and AML, but user-defined references can be added
as well.

This command helps generate the biallelic expression cases as described
below (`exp.ref.bi.txt`).

## Usage

```
cis-X-ref-exp

USAGE:
    cis-X ref-exp <SUBCOMMAND> [args...]

SUBCOMMANDS:
    generate    Generate a biallelic reference expression matrix
    prepare     Create a batch script for preprocessing inputs
    preprocess  Runs allelic specific expression (ASE) tests on inputs
```

## Reference matrices

cis-X performs independent tests with three reference expression matrices per
disease:

  * `exp.ref.entire.txt`: the unfiltered cohort.
  * `exp.ref.bi.txt`: cases with a biallelic expression for a given gene.
  * `exp.ref.white.txt`: cases without known noncoding regulatory variants for
    a given gene.

Reference matrices are tab-delimited files, including a header.

  * `exp.ref.entire.txt`: gene_id, gene_name, type, status, chr, start, end, id...
  * `exp.ref.bi.txt`: gene_name, num_cases, id, fpkm
  * `exp.ref.white.txt`: gene_name, num_cases, id, fpkm

If there is no prior knowledge, it is valid to create a reference matrix with
no rows (but include the header). Note that having both empty biallelic
expression and whitelist matrices will result in higher false negative rates
for cis-activated candidates during analysis.

Each disease under `$CIS_X_HOME/refs/diseases/$DISEASE` must have these three
files. `$DISEASE` is the name given when running `cis-X run`. See the `TALL`
and `AML` reference matrices as references.

## Example

`cis-X ref-exp` will commonly be used in a three step process: prepare,
preprocess, and generate.

### `prepare`

The preparation stage creates a batch script from a list of inputs.

```
$ cis-X ref-exp prepare /path/to/config.txt /results
```

It requires a tab-delimited configuration file with four columns:

  * sample_id
  * markers: path to a list of single nucleotide markers
  * rna_bam: path to a RNA-Seq BAM file
  * cnv_loh: path to CNV/LOH regions

The resulting batch script is saved to
`$RESULTS_DIR/cis-X.refexp.step1.commands.sh`.

### `preprocess`

It is unlikely that the `preprocess` subcommand will be called manually, as
the resulting batch script from the `prepare` stage creates a list of
commands that calls it with inputs from the configuration file. This batch
can be submitted to a job runner or executed as a normal script.

```
$ bash /results/cis-X.refexp.step1.commands.sh
```

### `generate`

The final generation stage creates a biallelic expression matrix from the
preprocessed outputs.

```
$ cis-X ref-exp generate /path/to/config.txt /results /path/to/gene-exp-table.txt
```

To use this with cis-X, copy the output in `$RESULTS_DIR/refexp` to
`$CIS_X_HOME/refs/diseases/$DISEASE`, where `$DISEASE` is any name. Copy
`$GENE_EXP_TABLE` to the same disease directory as the unfiltered cohort,
named `exp.ref.entire.txt`
