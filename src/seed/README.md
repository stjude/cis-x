# cis-X seed

`cis-X seed` downloads and generates a set of common reference files required
by cis-X.

## Prerequisites

  * [Ruby] ^2.2.2
    * [nokogiri] ~1.8.3
  * [faToTwoBit]\*
  * [liftOver]\*

\* UCSC Genome Browser binaries are not versioned. The latest versions
_should_ work.

[Ruby]: http://ruby-lang.org/
[nokogiri]: http://www.nokogiri.org/
[faToTwoBit]: https://genome.ucsc.edu/goldenpath/help/twoBit.html
[liftOver]: https://genome.ucsc.edu/cgi-bin/hgLiftOver

## Usage

```
$ cis-X seed <out-dir> [tmp-dir]
```

## References

The following files are created by `cis-X seed`. They are all required to run
cis-X.

  * `GRCh37-lite.2bit`: Converted from [`GRCh37-lite.fa`] to 2bit using
    [faToTwoBit].

  * `hESC.combined.domain.hg19.bed`: Extracted from Hi-C's "[Human ES Cell (H1) topological domains]"
    and preprocessed from hg18 to hg19 using [liftOver].

  * `hg19_refGene`: Downloaded from the [UCSC Table Browser] (assembly: Feb.
    2009 (GRCH37/hg19), track: NCBI RefSeq, table: UCSC RefSeq (refGene)).

  * `hg19_refGene.bed`: Converted from `hg19_refGene` using
    `bin/hg19_ref_gene_to_bed`.

  * `HOCOMOCOv10_HUMAN_mono_meme_format.meme`: Downloaded from [HOCOMOCO v10]
    (Matrices in other formats > MEME).

  * `HOCOMOCOv10_annotation_HUMAN_mono.tsv`: Downloaded from [HOCOMOCO v10]
    (Complete model annotation)

  * `ImprintGenes.txt`: Copied from Geneimprint [Human Imprinted Genes] as a
    tab-delimited file.

  * `roadmapData.dyadic.merged.111.bed`: Downloaded from the [NIH Roadmap Epigenomics Project]
    (Delineation of DNaseI-accessible regulatory regions > Dyadic). All files
    are merged with two extra columns: cell line name and tissue of origin.

  * `roadmapData.enhancer.merged.111.bed`: Downloaded from the [NIH Roadmap Epigenomics Project]
    (Delineation of DNaseI-accessible regulatory regions > Enhancer). All files
    are merged with two extra columns: cell line name and tissue of origin.

  * `roadmapData.promoter.merged.111.bed`: Downloaded from the [NIH Roadmap Epigenomics Project]
    (Delineation of DNaseI-accessible regulatory regions > Promoter). All files
    are merged with two extra columns: cell line name and tissue of origin.

[`GRCh37-lite.fa`]: http://genome.wustl.edu/pub/reference/GRCh37-lite/
[Human ES Cell (H1) topological domains]: http://chromosome.sdsc.edu/mouse/hi-c/download.html
[UCSC Table Browser]: http://genome.ucsc.edu/cgi-bin/hgTables
[HOCOMOCO v10]: http://hocomoco11.autosome.ru/downloads_v10
[Human Imprinted Genes]: http://www.geneimprint.com/site/genes-by-species.Homo+sapiens
[NIH Roadmap Epigenomics Project]: https://egg2.wustl.edu/roadmap/web_portal/index.html

## Example

`cis-X seed` will commonly be used to seed the `$CIS_X_HOME/refs/external`
directory.

```
$ cis-X seed $CIS_X_HOME/refs/external
```
