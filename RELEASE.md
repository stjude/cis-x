# Release

  * [ ] Update `CHANGELOG.md` with version and publication date.
  * [ ] Update version in `dnanexus/cis-x/dxapp.json`.
  * [ ] Stage changes: `git add dnanexus/cis-x/dxapp.json CHANGELOG.md`
  * [ ] Create git commit: `git commit -m "Bump version to $VERSION"`
  * [ ] Create git tag: `git tag -m "" -a v$VERSION`
  * [ ] Push release: `git push --follow-tags`

## DNAnexus

  * [ ] Build Docker image: `docker image build --tag cis-x .`
  * [ ] Save Docker image: `docker image save cis-x | gzip > dnanexus/cis-x/resources/tmp/cis-x-latest.tar.gz`
  * [ ] Check security context: `dx whoami`
  * [ ] Build DNAnexus applet: `dx build --destination cis-x:/cis-x-$VERSION dnanexus/cis-x`
  * [ ] Verify expected results:

    ```
    dx run cis-x:/cis-x-$VERSION \
      --input sample_id=SJALL018373_D1 \
      --input markers=cis-x:/data/SJALL018373_D1.test.wgs.markers.txt \
      --input cnv_loh=cis-x:/data/SJALL018373_D1.test.wgs.cnvloh.txt \
      --input bam=cis-x:/data/SJALL018373_D1.test.RNAseq.bam \
      --input bai=cis-x:/data/SJALL018373_D1.test.RNAseq.bam.bai \
      --input fpkm_matrix=cis-x:/data/SJALL018373_D1.test.RNASEQ_all_fpkm.txt \
      --input snv_indel=cis-x:/data/SJALL018373_D1.test.mut.txt \
      --input sv=cis-x:/data/SJALL018373_D1.test.sv.txt \
      --input cna=cis-x:/data/SJALL018373_D1.test.cna.txt \
      --input disease=TALL \
      --input cnv_loh_action=drop \
      --input min_coverage_wgs=10 \
      --input min_coverage_rna_seq=10 \
      --destination cis-x:/results/$VERSION
    ```

  * [ ] Publish DNAnexus app: `dx build --app --publish dnanexus/cis-x`
  * [ ] Build St. Jude Cloud production workflow.
