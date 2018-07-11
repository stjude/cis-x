# cis-X run

**cis-X run** is a command to search for activating regulatory variants in the
tumor genome.

## Prerequisites

  * [Perl] ^5.10.1
    * [Data::Compare] ~1.25
  * [R] ^3.1.0
    * [multtest] ~2.36.0
  * [Java SE Runtime Environment] ~1.8.0_66
  * [MEME Suite] =4.9.0
  * [twoBitToFa]\*
  * [variants2matrix] (See below.)

\* UCSC Genome Browser binaries are not versioned. The latest versions
_should_ work.

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
generate them. See [cis-X seed] for more details and a list of required
reference files.

[cis-X seed]: https://github.com/stjude/cis-x/tree/master/src/seed

## Usage

```
cis-X-run

USAGE:
    cis-X run <sample-id> <results-dir> <markers> <cnv-loh> <bam> <fpkm-matrix> <snv-indel> <sv> <cna> <disease>

ARGS:
    <sample-id>    Sample ID
    <results-dir>  Output directory
    <markers>      Path to single nucleotide markers
    <cnv-loh>      Path to CNV/LOH regions
    <bam>          Path to a RNA-Seq BAM (index must be in same directory)
    <fpkm-matrix>  Path to gene expression table
    <snv-indel>    Path to somatic SNV/indels
    <sv>           Path to somatic SVs
    <cna>          Path to somatic CNVs
    <disease>      Disease name
```

## Inputs

Running cis-X requires quite a few inputs.

  * `sample-id`: The sample ID.

  * `results-dir`: The output directory. See "[Outputs](#outputs)" for the
    resulting files.

  * `markers`: A list of single nucleotide markers. This is a tab-delimited
    file with the following columns:

      * `Chr`: the chromosome location for the marker
      * `Pos`: the genomic position for the marker
      * `Chr_Allele`: the reference allele
      * `Alternative_Allele`: the alternative allele
      * `reference_tumor_count`: the reference allele count in the tumor genome
      * `alternative_tumor_count`: the alterative allele count in the tumor genome
      * `reference_normal_count`: the reference allele count in the matched normal genome
      * `alternative_normal_count`: the alternative count in the matched normal genome

    This file can be generated with Bambino.

  * `cnv-loh`: CNV/LOH regions. It contains all the genomic regions carrying
    copy number variations (CNV) or loss of heterozygosity (LOH), which will be
    filtered out during analysis.

    This is a tab-delimited file in the bed format. It must have at least the
    following three columns:

      * `chrom`
      * `loc.start`
      * `loc.end`

    If no CNV/LOH are in the genome under analysis, a file with no rows (but
    including headers) can be provided.

    This file can be generated with CONSERTING.

  * `bam`: The RNA-Seq BAM file aligned to hg19 (GRCh37). The index file is
    expected to be in the same directory with the same name and extension
    `.bai`, e.g, `/path/to/SJ001_D1.bam` and `/path/to/SJ001_D1.bam.bai`.

    StrongArm or STAR can be used for RNA-Seq alignment.

  * `fpkm-matrix`: A gene expression table. This is a tab-delimited file
    containing gene level expressions for the tumor under analysis. The
    expression are in FPKM (fragments per kilobase of transcript per million
    mapped reads).

    This FPKM matrix can be generated with the output of HTseq-count and
    preprocessed through `src/other/mergeData_geneName.pl`. The data must be
    able to match values in the given gene specific reference expression
    matrices (see [cis-X ref-exp]) generated from a larger cohort.

  * `snv-indel`: Somatic SNV/indels. This is a tab-delimited file containing
    somatic sequence mutations present in the genome under analysis. It includes
    both single nucleotide variants (SNV) and small insertion/deletions (indel).
    The file must have the following columns:

      * `chr`
      * `pos`
      * `ref allele`
      * `mutant allele`
      * `mutation type`: must be `snv` or `index`

    Note that the coordinate used for an indel is after the inserted sequence.

    If no SNV/indels are in the sample under analysis, a file with no rows
    (but including headers) can be provided.

    This file can can be created with Bambino and then preprocessed using the
    steps taken in "[The genetic basis of early T-cell precursor acute lymphoblastic leukaemia][22237106]".

  * `sv` Somatic SVs. This is a tab-delimited file containing somatic-acquired
    structural variants (SV) in the cancer genome. The file must have the
    following columns:

      * `chrA`: the chromosome of the left breakpoint
      * `posA`: the genomic location of the left breakpoint
      * `ortA`: the strand orientation of the left breakpoint
      * `chrB`: the chromosome of the right breakpoint
      * `posB`: the genomic location of the right breakpoint
      * `ortB`: the strange orientation of the right breakpoint

    If no somatic SVs are in the sample under analysis, a file with no rows (but
    including headers) can be provided.

    This file can be generated by CREST.

  * `cna` Somatic CNV. This is a tab-delimited file containing the genomic
    regions with somatic-acquired copy number aberrations (CNA) in the cancer
    genome.

      * `chr`
      * `start`
      * `end`
      * `log2Ratio`

    If no somatic CNVs are in the sample under analysis, a file with no rows
    (but including headers) can be provided.

    This file can be generating by CONSERTING.

  * `disease`: The disease name.

[cis-X ref-exp]: https://github.com/stjude/cis-x/tree/master/src/ref-exp
[22237106]: https://www.ncbi.nlm.nih.gov/pubmed/22237106

## Outputs

Results are saved to `$RESULTS_DIR`, which include the following files.

  * `*.cisActivated.candidates.txt`: cis-activated candidates in the tumor
    genome under analysis.

  * `*.sv.candidates.txt`: Structural variant candidates predicted as the
    causal for the cis-activated genes in the regulatory territory.

  * `*.cna.candidates.txt`: Copy number aberrations predicted as the causal
    for the cis-activated genes in the regulatory territory.

  * `*.snvindel.candidates.txt`: SNV/indel candidates predicted as functional
    and predicted transcription factors. The mutations are also annotated for
    known regulatory elements reported by the Epigonomic Roadmap project by
    collecting 111 cell lines.

  * `*.OHE.results.txt`: Raw results for outlier high expression test.

  * `*.ase.gene.model.fdr.txt`: Raw results for gene level allelic specific
    expression test.

  * `*.ase.combine.WGS.RNAseq.goodmarkers.binom.txt`: Raw results for single
    marker based allelic specific expression test.
