# cis-X refs

`cis-X-seed` is a utility script to download and generate a set of common
reference files used by cis-X.

## Quick Start

```
$ PLATFORM=linux.x86_64 # or "macOSX.x86_64"
$ UCSCGB_HOME=$(realpath ../tmp/vendor/ucscgb)
$ OUT_DIR=../tmp/refs
$ gem install nokogiri --no-ri --no-rdoc
$ mkdir -p $UCSCGB_HOME/bin
$ wget --directory-prefix $UCSCGB_HOME/bin \
    http://hgdownload.soe.ucsc.edu/admin/exe/$PLATFORM/faToTwoBit \
    http://hgdownload.soe.ucsc.edu/admin/exe/$PLATFORM/liftOver
$ chmod +x $UCSCGB_HOME/bin/*
$ export PATH=$(pwd)/bin:$UCSCGB_HOME/bin:$PATH
$ mkdir -p $OUT_DIR
$ cis-X-seed $OUT_DIR
```

## Usage

### Prerequisites

  * Ruby ^2.2.2
    * nokogiri ~1.8.3
  * [faToTwoBit]\*
  * [liftOver]\*

\* UCSC Genome Browser binaries are not versioned. The latest versions _should_ work.

[Ruby]: http://ruby-lang.org/
[nokogiri]: http://www.nokogiri.org/
[faToTwoBit]: https://genome.ucsc.edu/goldenpath/help/twoBit.html
[liftOver]: https://genome.ucsc.edu/cgi-bin/hgLiftOver

### Usage

```
$ cis-X-seed <out-dir> [tmp-dir]
```

## References

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
