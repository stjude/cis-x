# Changelog

## [1.3.0] - 2019-03-28

### Added

  * core: Known oncogenes in the [COSMIC Cancer Gene Census] are used to
    reevaluate cis-activated candidates.

[COSMIC Cancer Gene Census]: https://cancer.sanger.ac.uk/census

### Changed

  * core: Increased default transcription factor FPKM value to 10 for
    screening.

  * core: The motif for MYB (MYBL1 and MYBL2) are similar and treated as the
    same gene.

  * core: SNV/indel candidates are sorted by FPKM value.

## [1.2.0] - 2019-01-08

### Added

  * core: Added argument to set the FPKM threshold for the nomination of
    a cis-activated candidate.

## [1.1.0] - 2018-12-17

### Added

  * core: Added argument to handle markers in CNV/LOH regions. This can either
    be `keep` or `drop`.

  * core: Added arguments to set the threshold for the minimal coverage in WGS
    and RNA-seq when selecting heterozygous markers.

### Fixed

  * seed: Update download location for `GRCh37-lite.fa.gz`.

## 1.0.0 - 2018-07-23

  * Initial release

[1.3.0]: https://github.com/stjude/cis-x/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/stjude/cis-x/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/stjude/cis-x/compare/v1.0.0...v1.1.0
