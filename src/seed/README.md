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

The following files are created by `cis-X seed`.

  * `GRCh37-lite.2bit`
  * `hESC.combined.domain.hg19.bed`
  * `hg19_refGene`
  * `hg19_refGene.bed`
  * `HOCOMOCOv10_HUMAN_mono_meme_format.meme`
  * `HOCOMOCOv10_annotation_HUMAN_mono.tsv`
  * `ImprintGenes.txt`
  * `roadmapData.dyadic.merged.111.bed`
  * `roadmapData.enhancer.merged.111.bed`
  * `roadmapData.promoter.merged.111.bed`
