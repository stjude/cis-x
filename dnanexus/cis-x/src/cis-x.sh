#!/usr/bin/env bash

main() {
    set -x

    DATA_DIR=$HOME/data
    REFS_DIR=$HOME/refs
    RESULTS_DIR=$HOME/results

    mkdir $DATA_DIR $REFS_DIR $RESULTS_DIR

    dx download --output $DATA_DIR/wgs.markers.txt "$markers"
    dx download --output $DATA_DIR/wgs.cnvloh.txt "$cnv_loh"
    dx download --output $DATA_DIR/RNAseq.bam "$bam"
    dx download --output $DATA_DIR/RNAseq.bam.bai "$bai"
    dx download --output $DATA_DIR/RNAseq_all_fpkm.txt "$fpkm_matrix"
    dx download --output $DATA_DIR/mut.txt "$snv_indel"
    dx download --output $DATA_DIR/sv.txt "$sv"
    dx download --output $DATA_DIR/cna.txt "$cna"

    dx download --recursive --output $REFS_DIR 'St. Jude Reference Data:/pipeline/cis-X/*'

    dx-docker run \
        --volume $DATA_DIR:/data \
        --volume $REFS_DIR:/app/refs/external \
        --volume $RESULTS_DIR:/results \
        cis-x \
        run \
        $sample_id \
        /results \
        /data/wgs.markers.txt \
        /data/wgs.cnvloh.txt \
        /data/RNAseq.bam \
        /data/RNAseq_all_fpkm.txt \
        /data/mut.txt \
        /data/sv.txt \
        /data/cna.txt \
        $disease \
        $cnv_loh_action \
        $min_coverage_wgs \
        $min_coverage_rna_seq \
        $fpkm_threshold_candidate

    cis_activated_candidates=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.cisActivated.candidates.txt)
    sv_candidates=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.sv.candidates.txt)
    cna_candidates=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.cna.candidates.txt)
    snv_indel_candidates=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.snvindel.candidates.txt)
    ohe_results=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.OHE.results.txt)
    ase_gene_results=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.ase.gene.model.fdr.txt)
    ase_marker_results=$(dx upload --brief $RESULTS_DIR/$sample_id/$sample_id.ase.combine.WGS.RNAseq.goodmarkers.binom.txt)

    dx-jobutil-add-output --class file cis_activated_candidates "$cis_activated_candidates"
    dx-jobutil-add-output --class file sv_candidates "$sv_candidates"
    dx-jobutil-add-output --class file cna_candidates "$cna_candidates"
    dx-jobutil-add-output --class file snv_indel_candidates "$snv_indel_candidates"
    dx-jobutil-add-output --class file ohe_results "$ohe_results"
    dx-jobutil-add-output --class file ase_gene_results "$ase_gene_results"
    dx-jobutil-add-output --class file ase_marker_results "$ase_marker_results"
}
