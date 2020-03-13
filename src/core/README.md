# cis-X run

**cis-X run** searches for activating regulatory variants in the tumor genome.

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

variants2matrix is a St. Jude tool that is available from [St. Jude Research]
(`variants2matrix.tar.gz`). It is expected to be in `PATH`, along with its
Perl library and Java class paths, e.g.,

```
$ V2M_HOME=$CIS_X_HOME/vendor/variants2matrix
$ wget http://ftp.stjude.org/pub/software/cis-x/variants2matrix.tar.gz
$ tar xf variants2matrix.tar.gz --directory $CIS_X_HOME/vendor
$ export PATH=$V2M_HOME/bin:$PATH
$ export PERL5LIB=$V2M_HOME/lib/perl:$PERL5LIB
$ export CLASSPATH=$V2M_HOME/lib/java/bambino-1.0.jar:$V2M_HOME/lib/java/indelxref-1.0.jar:$V2M_HOME/lib/java/picard.jar:$V2M_HOME/lib/java/samplenamelib-1.0.jar:$CLASSPATH
```

### References

Reference files are not included with the source due to their large sizes.

Internal references are placed in `$CIS_X_HOME/refs`. These files can be
downloaded from [St. Jude Research] (`cis-x-refs-*.tar.gz`). It includes a
blacklist of problematic polymorphism markers and two reference expression
matrices for T-ALL and NBL.

External references are expected to be in `$CIS_X_HOME/refs/external`. These
are not distributed with cis-X, but the `cis-X seed` command can download and
generate them. See [cis-X seed] for more details and a list of required
reference files.

[cis-X seed]: https://github.com/stjude/cis-x/tree/master/src/seed

## Usage

```
cis-X-run

USAGE:
    cis-X run -s <sample-id> -o <results-dir> -l <markers> -g <cnv-loh> -b <bam> -e <fpkm-matrix> -m <snv-indel> -v <sv> -c <cna> -d <disease> -a <cnv-loh-action> -w <min coverage in WGS> -r <min coverage in RNA-seq> -f <FPKM threshold for nominate cis-activated candidate> -u <user-annotation> -h <chr-string> -t <tad-info>

ARGS:
    -s <sample-id>       Sample ID
    -o <results-dir>     Output directory
    -l <markers>         Path to single nucleotide markers
    -g <cnv-loh>         Path to CNV/LOH regions
    -b <bam>             Path to a RNA-Seq BAM (index must be in same directory)
    -e <fpkm-matrix>     Path to gene expression table
    -m <snv-indel>       Path to somatic SNV/indels
    -v <sv>              Path to somatic SVs
    -c <cna>             Path to somatic CNVs
    -d <disease>         Disease name
    -a <cnv-loh-action>  Action of markers in CNV/LOH regions, either keep or drop (default=keep)
    -w <min coverage in WGS>          Minimal coverage in WGS to include a heterozygous marker (default=10)
    -r <min coverage in RNA-seq>      Minimal coverage in RNA-seq to include a heterozygous marker (default=10)
    -f <fpkm threshold for candidate> FPKM threshold for nominate cis-activated candidate (default=5)
    -u <user-annotation> User applied annotation file in BED format (default=NotSpecified)
    -h <chr-string>      if the RNA-seq BAM with 'chr' in name, TRUE|FALSE (default=TRUE)
    -t <tad-info>         Path to the TAD annotation file in BED format in hg19 (default=hESC)
```

## Inputs

Running cis-X requires quite a few inputs.

  * `sample-id`: The sample ID. This is primarily used as the prefix for the
    filenames of the results.

  * `results-dir`: The output directory. See "[Outputs](#outputs)" for the
    resulting files.

  * `markers`: A list of single nucleotide markers. This is a tab-delimited
    file with the following columns:

      * `Chr`: chromosome name for the marker
      * `Pos`: genomic start location for the marker
      * `Chr_Allele`: reference allele
      * `Alternative_Allele`: alternative allele
      * `reference_tumor_count`: reference allele count in the tumor genome
      * `alternative_tumor_count`: alternative allele count in the tumor genome
      * `reference_normal_count`: reference allele count in the matched normal genome
      * `alternative_normal_count`: alternative count in the matched normal genome

    This file can be generated with Bambino.

  * `cnv-loh`: CNV/LOH regions. It contains all the genomic regions carrying
    copy number variations (CNV) or loss of heterozygosity (LOH), which will be
    filtered out during analysis.

    This is a tab-delimited file in the bed format. It must have at least the
    following three columns:

      * `chrom`: chromosome name
      * `loc.start`: genomic start location
      * `loc.end`: genomic end location

    If no CNV/LOH are in the genome under analysis, a file with no rows (but
    including headers) can be provided.

    This file can be generated with CONSERTING.

  * `bam`: The RNA-Seq BAM file aligned to hg19 (GRCh37). The index file is
    expected to be in the same directory with the same name and extension
    `.bai`, e.g, `/path/to/SJ001_D1.bam` and `/path/to/SJ001_D1.bam.bai`.

    StrongArm or STAR can be used for RNA-Seq alignment.

  * `fpkm-matrix`: A gene expression table. This is a tab-delimited file
    containing gene level expressions for the tumor under analysis. The
    expressions are in FPKM (fragments per kilobase of transcript per million
    mapped reads).

      * `GeneID`: gene [Ensembl] ID
      * `GeneName`: gene symbol
      * `Type`: [transcript type](https://www.gencodegenes.org/gencode_biotypes.html)
      * `Status`: transcript status (must be `KNOWN`, `NOVEL`, or `PUTATIVE`)
      * `Chr`: chromosome name
      * `Start` genomic start location
      * `End`: genomic end location
      * [SampleID...]: FPKM for the given sample

    This file can can be generated with the output of HTseq-count
    preprocessed through `src/other/mergeData_geneName.pl`. The data must be
    able to match values in the given gene specific reference expression
    matrices (see [cis-X ref-exp]) generated from a larger cohort.

  * `snv-indel`: Somatic SNV/indels. This is a tab-delimited file containing
    somatic sequence mutations present in the genome under analysis. It includes
    both single nucleotide variants (SNV) and small insertion/deletions (indel).
    The file must have the following columns:

      * `chr`: chromosome name
      * `pos`: genomic start location
      * `ref`: reference allele genotype
      * `mutant`: mutant allele genotype
      * `type`: mutation type (either `snv` or `indel`)

    Note that the coordinate used for an indel is after the inserted sequence.

    If no SNV/indels are in the sample under analysis, a file with no rows
    (but including headers) can be provided.

    This file can can be created with Bambino and then preprocessed using the
    steps taken in "[The genetic basis of early T-cell precursor acute lymphoblastic leukaemia][22237106]".

  * `sv` Somatic SVs. This is a tab-delimited file containing somatic-acquired
    structural variants (SV) in the cancer genome. The file must have the
    following columns:

      * `chrA`: chromosome name of the left breakpoint
      * `posA`: genomic location of the left breakpoint
      * `ortA`: strand orientation of the left breakpoint
      * `chrB`: chromosome name of the right breakpoint
      * `posB`: genomic location of the right breakpoint
      * `ortB`: strand orientation of the right breakpoint

    Strand orientations are denoted with a `+` for a sense or coding strand
    and `-` for a antisense or non-coding strand.

    If no somatic SVs are in the sample under analysis, a file with no rows (but
    including headers) can be provided.

    This file can be generated by CREST.

  * `cna` Somatic CNV. This is a tab-delimited file containing the genomic
    regions with somatic-acquired copy number aberrations (CNA) in the cancer
    genome.

      * `chr`: chromosome name
      * `start`: genomic start location
      * `end`: genomic end location
      * `logR`: log2 ratio

    If no somatic CNVs are in the sample under analysis, a file with no rows
    (but including headers) can be provided.

    This file can be generating by CONSERTING.

  * `disease`: The disease name.

  * `cnv_loh_action`: The behavior when handling markers in CNV/LOH regions. Can
    be either `keep` or `drop`.

  * `min_coverage_wgs`: The minimum coverage in WGS to be included in the
    analysis.

  * `min_coverage_rna_seq`: The minimum coverage in RNA-seq to be included in
    the analysis.

  * `fpkm_threshold_candidate`: The FPKM threshold for the nomination of a
    cis-activated candidate.

  * `user-annotation`: Annotations for the candidate SNV/indels in BED format.

  * `chr-string`: Whether the names in the reference sequence dictionary are
    prefixed with "chr".

  * `tad-info`: TAD information defining the regulatory territory used in
    noncoding variant analysis.

[cis-X ref-exp]: https://github.com/stjude/cis-x/tree/master/src/ref-exp
[22237106]: https://www.ncbi.nlm.nih.gov/pubmed/22237106

## Outputs

Results are saved as tab-delimited files to `$RESULTS_DIR`.

  * `*.cisActivated.candidates.txt`: cis-activated candidates in the tumor
    genome under analysis.

      * `gene`: gene accession number ([RefSeq] ID)
      * `gsym`: gene symbol
      * `chrom`: chromosome name
      * `strand`: strand orientation
      * `start`: genomic start location
      * `end`: genomic end location
      * `cdsStartStat`: coding sequence (CDS) start status
      * `cdsEndStat`: coding sequence (CDS) end status
      * `markers`: number of heterozygous markers in this gene
      * `ase_markers`: number of heterozygous markers showing allelic specific expressions (ASE)
      * `average_ai_all`: average B-allele frequency (BAF) difference between RNA and DNA for all heterozygous markers
      * `average_ai_ase`: average BAF difference between RNA and DNA for ASE markers
      * `pval_all_markers`: p-value for each marker in the ASE test
      * `pval_ase_markers`: p-value for ASE markers in the ASE test
      * `ai_all_markers`: BAF difference between RNA and DNA for all heterozygrous markers
      * `ai_ase_markers`: BAF difference between RNA and DNA for ASE markers
      * `comb.pval`: combined p-value for the ASE test
      * `mean.delta`: average BAF difference between RNA and DNA for all markers
      * `rawp`: raw p-value for the ASE test
      * `Bonferroni`: adjusted p-value for the ASE test (single-step Bonferroni)
      * `ABH`: adjusted p-value for the ASE test (Benjamini-Hochberg)
      * `FPKM`: FPKM value
      * `loo.source`: which reference expression matrix was used in the outlier high expression (OHE) test
      * `loo.cohort.size`: number of cases in the reference expression matrix for this gene
      * `loo.pval`: p-value of the OHE test
      * `loo.rank`: rank of the case under analysis among the reference cases
      * `imprinting.status`: imprinting status of the gene
      * `candidate.group`: status of the gene, combining both ASE and outlier tests
      * `description`: status of the gene in COSMIC database

    Strand orientations are denoted with a `+` for a sense or coding strand
    and `-` for a antisense or non-coding strand.

    Coding sequence status is typically one of "none" (not specified), "unk"
    (unknown), "incmpl" (incomplete), or "cmpl" (complete).

  * `*.sv.candidates.txt`: Structural variant candidates predicted as the
    causal for the cis-activated genes in the regulatory territory.

      * `left.candidate.inTAD`: cis-activated candidate near the left breakpoint
      * `right.candidate.inTAD`: cis-activated candidate near the right breakpoint
      * `chrA`: chromosome name of the left breakpoint
      * `posA`: genomic location of the left breakpoint
      * `ortA`: strand orientation of the left breakpoint
      * `chrB`: chromosome name of the right breakpoint
      * `posB`: genomic location of the right breakpoint
      * `ortB`: strand orientation of the right breakpoint
      * `type`: type of translocation

  * `*.cna.candidates.txt`: Copy number aberrations predicted as the causal
    for the cis-activated genes in the regulatory territory.

      * `candidate.inTAD`: cis-activated candidate by the CNA
      * `chr`: chromosome name
      * `start`: genomic start position
      * `end`: genomic end location
      * `logR`: log ratio of the CNA

  * `*.snvindel.candidates.txt`: SNV/indel candidates predicted as functional
    and predicted transcription factors. The mutations are also annotated for
    known regulatory elements reported by the [NIH Roadmap Epigenomics Project]
    by collecting 111 cell lines.

      * `chrom`: chromosome name
      * `pos`: genomic start position
      * `ref`: reference allele genotype
      * `mut`: mutant allele genotype
      * `type`: mutation type (either `snv` or `indel`)
      * `target`: cis-activated candidate
      * `dist`: distance between the mutation and transcription start sites of the target gene
      * `tf`: transcription factors predicted to have the binding motif introduced by the mutation
      * `EpiRoadmap_enhancer`: enhancer regions that overlap with the mutation (from the [NIH Roadmap Epigenomics Project])
      * `EpiRoadmap_promoter`: promoter regions that overlap with the mutation (from the [NIH Roadmap Epigenomics Project])
      * `EpiRoadmap_dyadic`: dyadic regions that overlap with the mutation (from the [NIH Roadmap Epigenomics Project])
      * `User_Annot`: annotation from the user-provided BED file

  * `*.OHE.results.txt`: Raw results for outlier high expression test.

      * `Gene`: gene symbol
      * `fpkm.raw`: FPKM value
      * `size.bi`: number of cases in the bi-allelic reference cohort
      * `p.bi`: p-value in the outlier test using the bi-allelic reference cohort
      * `rank.bi`: rank of the expression level in the case under analysis compared to the bi-allelic reference cohort
      * `size.cohort`: number of cases in the entire reference cohort
      * `p.cohort`: p-value in the outlier test using the entire reference cohort
      * `rank.cohort`: rank of the expression level in the case under analysis compared to the entire reference cohort
      * `size.white`: number of cases in the whitelist reference cohort
      * `p.white`: p-value in the outlier test using the whitelist reference cohort
      * `rank.white`: rank of the expression level in the case under analysis compared to the whitelist reference cohort
      * `tscore.white`: t-score representing if the gene showed outlier expresssion using the whitelist reference cohort
      * `tscore.perc.white`: percentage of the t-score compared to the null distribution

  * `*.ase.gene.model.fdr.txt`: Raw results for gene level allelic specific
    expression test.

      * `gene`: gene accession number ([RefSeq] ID)
      * `gsym`: gene symbol
      * `chrom`: chromosome name
      * `strand`: strand orientation
      * `start`: genomic start location
      * `end`: genomic end location
      * `cdsStartStat`: coding sequence (CDS) start status
      * `cdsEndStat`: coding sequence (CDS) end status
      * `markers`: number of heterozygous markers in this gene
      * `ase_markers`: number of heterozygous markers showing allelic specific expressions (ASE)
      * `average_ai_all`: average B-allele frequency (BAF) difference between RNA and DNA for all heterozygous markers
      * `average_ai_ase`: average BAF difference between RNA and DNA for ASE markers
      * `pval_all_markers`: p-value for each marker in the ASE test
      * `pval_ase_markers`: p-value for ASE markers in the ASE test
      * `ai_all_markers`: BAF difference between RNA and DNA for all heterozygrous markers
      * `ai_ase_markers`: BAF difference between RNA and DNA for ASE markers
      * `comb.pval`: combined p-value for the ASE test
      * `mean.delta`: average BAF difference between RNA and DNA for all markers
      * `rawp`: raw p-value for the ASE test
      * `Bonferroni`: adjusted p-value for the ASE test (single-step Bonferroni)
      * `ABH`: adjusted p-value for the ASE test (Benjamini-Hochberg)

    Strand orientations are denoted with a `+` for a sense or coding strand
    and `-` for a antisense or non-coding strand.

    Coding sequence status is typically one of "none" (not specified), "unk"
    (unknown), "incmpl" (incomplete), or "cmpl" (complete).

  * `*.ase.combine.WGS.RNAseq.goodmarkers.binom.txt`: Raw results for single
    marker based allelic specific expression test.

      * `chrom`: chromosome name
      * `pos`: genomic start position
      * `ref`: reference allele genotype
      * `mut`: non-reference allele genotype
      * `cvg_wgs`: coverage of the marker from the whole genome sequence (WGS)
      * `mut_freq_wgs`: non-reference allele fraction in the WGS
      * `cvg_rna`: coverage of the marker from the RNA-seq
      * `mut_freq_rna`: non-reference allele fraction in the RNA-seq
      * `ref.1`: read count of the reference allele in the RNA-seq
      * `var`: read count of the non-reference allele in the RNA-seq
      * `pvalue`: p-value from the binomial test
      * `delta.abs`: absolute difference of the non-reference allele fraction between the WGS and RNA-seq

[Ensembl]: http://www.ensembl.org/
[NIH Roadmap Epigenomics Project]: https://egg2.wustl.edu/roadmap/web_portal/index.html
[RefSeq]: https://www.ncbi.nlm.nih.gov/refseq/
[St. Jude Research]: https://www.stjuderesearch.org/site/lab/zhang/cis-x
