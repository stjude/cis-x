#!/usr/bin/env bash

SAMPLE_ID=$1
ROOTDIR=$2
HIGH20=$3
CNVLOH=$4
RNABAM=$5
FPKM_MATRIX=$6
SNVINDEL_IN=$7
SV_IN=$8
CNA_IN=$9
DISEASE=${10}

CODE_DIR=$(dirname $0)

# Currently, all references are assumed to be merged in `$CODE_DIR/ref`. Since
# there are already static references there and mounting to that directory
# would shadow them, when running in a container, external references mounted
# at `/ref` are symlinked to `$CODE_DIR/ref`.
if [ -f /.dockerenv ] && [ -d /ref ]; then
    ln -s /ref/* $CODE_DIR/ref
fi

### set up directory for output
WORKDIR="$ROOTDIR/$SAMPLE_ID/working_space"
RESDIR="$ROOTDIR/$SAMPLE_ID"
mkdir -p $WORKDIR
cd $WORKDIR
pwd

### check for reference expression matrix data
BILIST=$CODE_DIR/ref/$DISEASE/exp.ref.bi.txt
WHITELIST=$CODE_DIR/ref/$DISEASE/exp.ref.white.txt
WHOLELIST=$CODE_DIR/ref/$DISEASE/exp.ref.entire.txt
if [ ! -f $BILIST ] || [ ! -f $WHITELIST ] || [ ! -f $WHOLELIST ]; then
    echo "Reference expression data missing for $DISEASE. Exiting."
    exit 1
fi
echo "Reference expression data checked."

### get heterozygous markers.
HET_OUT="$WORKDIR/$SAMPLE_ID.heterozygous.markers.txt"
SNV4_OUT="$WORKDIR/$SAMPLE_ID.snv4.txt";
BADLST=$CODE_DIR/ref/SuperBad.good.bad.new
perl $CODE_DIR/code/01.get.markder.pl $SAMPLE_ID $HIGH20 $CNVLOH $SNV4_OUT $HET_OUT $BADLST
echo "step1 completed."

### run matrix code
RNABAMLST="$WORKDIR/bam.lst"
MATRIX_OUT="$WORKDIR/matrix_combined_matrix_simple.tab"
echo $RNABAM > $RNABAMLST
for i in `seq 1 22`
do
    CHROM="chr$i"
    SNV4_CHR=snv4.seqchr.txt
    if [ -f $SNV4_CHR ]; then
        rm $SNV4_CHR
    fi
    if [ -f "commands.txt" ]; then
        rm commands.txt
    fi
    if [ -f "commands.sh" ]; then
        rm commands.sh
    fi
    perl $CODE_DIR/code/sepCHR.pl $SNV4_OUT $CHROM $SNV4_CHR
    LINE_TEMP=`wc -l $SNV4_CHR|sed -e 's/^ *//'|cut -d" " -f1`
    if [ $LINE_TEMP -gt 0 ]; then
        variants2matrix -now -bam-list $RNABAMLST -variant-file $SNV4_CHR -snv4 -flat -name $CHROM -step1 commands.txt
        cat commands.txt |sed 's/^\/bin\/env //' > commands.sh
        sh commands.sh 2>commands.err
        variants2matrix -now -bam-list $RNABAMLST -variant-file $SNV4_CHR -snv4 -flat -name $CHROM -step2 -clean
    fi
done
perl $CODE_DIR/code/mergeVariantOut.pl $WORKDIR $MATRIX_OUT
MATRIX_OUT_LINE=`wc -l $MATRIX_OUT|sed -e 's/^ *//'|cut -d" " -f1`
if [ $MATRIX_OUT_LINE -lt 2 ]; then
    echo "No output from variants2matrix. Exiting."
    exit 1
fi
echo "matrix code complete"

### calculate cis-activated gene candidates.
GENE_MODEL=$CODE_DIR/ref/hg19_refGene
IMPRINTING_GENES=$CODE_DIR/ref/ImprintGenes.txt

THRESH_AI=0.3
THRESH_PVALUE_ASE=0.05
THRESH_PVALUE_LOO=0.05
THRESH_FPKM=5
THRESH_LOO_Hi_Perc=0.1

WGS_RNA_COUNT="$WORKDIR/$SAMPLE_ID.combine.WGS.RNAseq.goodmarkers.txt"
ASE_RESULT_MARKER="$WORKDIR/$SAMPLE_ID.ase.combine.WGS.RNAseq.goodmarkers.binom.txt"
GENE_MODEL_Temp1="$WORKDIR/$SAMPLE_ID.combine.WGS.RNAseq.goodmarkers.binom.genemodel.summary.txt"
GENE_MODEL_Temp2="$WORKDIR/$SAMPLE_ID.combine.WGS.RNAseq.goodmarkers.binom.genemodel.summary.merged.txt"
ASE_RESULT_GENE="$WORKDIR/$SAMPLE_ID.ase.gene.model.fdr.txt"
OHE_RESULT="$WORKDIR/$SAMPLE_ID.OHE.results.txt"
CANDIDATES_RESULT="$WORKDIR/$SAMPLE_ID.cisActivated.candidates.txt"

perl $CODE_DIR/code/02.add.count.pl $SAMPLE_ID $HET_OUT $MATRIX_OUT $WGS_RNA_COUNT
Rscript $CODE_DIR/code/binom.R $WGS_RNA_COUNT $ASE_RESULT_MARKER
perl $CODE_DIR/code/07.gene.model.Oct2017.pl $SAMPLE_ID $ASE_RESULT_MARKER $GENE_MODEL $THRESH_AI $THRESH_PVALUE_ASE $GENE_MODEL_Temp1
perl $CODE_DIR/code/05.merge.pl $GENE_MODEL_Temp1 $GENE_MODEL_Temp2
Rscript $CODE_DIR/code/fdr.R $GENE_MODEL_Temp2 $ASE_RESULT_GENE
Rscript $CODE_DIR/code/exp.check.R $SAMPLE_ID $FPKM_MATRIX $BILIST $WHOLELIST $WHITELIST $OHE_RESULT
perl $CODE_DIR/code/ase.candidate.pl $THRESH_PVALUE_ASE $THRESH_AI $THRESH_FPKM $THRESH_PVALUE_LOO $SAMPLE_ID $CANDIDATES_RESULT $ASE_RESULT_GENE $OHE_RESULT $THRESH_LOO_Hi_Perc $IMPRINTING_GENES
echo "cis-candidates complete"

### screen for genomic variants.
SV_WIN=1000000
CNA_WIN=1000000
CNA_SIZE=5000000
SNVINDEL_WIN=200000
TF_FPKM_THRESH=3
TAD=$CODE_DIR/ref/hESC.combined.domain.hg19.bed
REFGENE=$CODE_DIR/ref/hg19_refGene.bed
REF_2BIT=$CODE_DIR/ref/GRCh37-lite.2bit
MOTIF=$CODE_DIR/ref/HOCOMOCOv10_HUMAN_mono_meme_format.meme
ROADMAP_ENH=$CODE_DIR/ref/roadmapData.enhancer.merged.111.bed
ROADMAP_PRO=$CODE_DIR/ref/roadmapData.promoter.merged.111.bed
ROADMAP_DYA=$CODE_DIR/ref/roadmapData.dyadic.merged.111.bed

SV_TEMP1="$WORKDIR/$SAMPLE_ID.sv.candidates.temp1.txt"
CNA_TEMP1="$WORKDIR/$SAMPLE_ID.cna.candidates.temp1.txt"
SNVINDEL_VAR="$WORKDIR/$SAMPLE_ID.snvindel.varlist.txt"
SNVINDEL_SEQLIST="$WORKDIR/$SAMPLE_ID.snvindel.seqlist.txt"
SNVINDEL_FA="$WORKDIR/$SAMPLE_ID.snvindel.fa"
FIMO_FA_IN="$WORKDIR/$SAMPLE_ID.snvindel.fimo.input.fa"
FIMO_OUT="$WORKDIR/fimo_out/fimo.txt"
FIMO_ACC2GSYM="$CODE_DIR/ref/HOCOMOCOv10_annotation_HUMAN_mono.tsv"

SV_CAN="$SAMPLE_ID.sv.candidates.txt"
CNA_CAN="$SAMPLE_ID.cna.candidates.txt"
SNVINDEL_CAN="$SAMPLE_ID.snvindel.candidates.txt"

perl $CODE_DIR/code/scan.sv.pl $SAMPLE_ID $CANDIDATES_RESULT $SV_IN $SV_TEMP1 $SV_WIN
perl $CODE_DIR/code/check.TAD.pl $SAMPLE_ID $TAD $REFGENE $SV_TEMP1 $SV_CAN
perl $CODE_DIR/code/scan.cnv.pl $SAMPLE_ID $CANDIDATES_RESULT $CNA_IN $CNA_TEMP1 $CNA_WIN $CNA_SIZE
perl $CODE_DIR/code/check.TAD.cnv.pl $SAMPLE_ID $TAD $REFGENE $CNA_TEMP1 $CNA_CAN
perl $CODE_DIR/code/snvindel.prep.pl $SAMPLE_ID $SNVINDEL_IN $CANDIDATES_RESULT $SV_CAN $CNA_CAN $TAD $SNVINDEL_VAR $SNVINDEL_SEQLIST $SNVINDEL_WIN
twoBitToFa -seqList=$SNVINDEL_SEQLIST $REF_2BIT $SNVINDEL_FA
perl $CODE_DIR/code/merge.fa.pl $SAMPLE_ID $SNVINDEL_VAR $SNVINDEL_FA $FIMO_FA_IN
fimo --verbosity 1 --thresh 1e-3 $MOTIF $FIMO_FA_IN
perl $CODE_DIR/code/snvindel.process.pl $SAMPLE_ID $FIMO_OUT $FIMO_ACC2GSYM $SNVINDEL_VAR $FPKM_MATRIX $TF_FPKM_THRESH $SNVINDEL_CAN $ROADMAP_ENH $ROADMAP_PRO $ROADMAP_DYA
echo "screening complete"

### copy results and clean up
cp $ASE_RESULT_GENE $RESDIR
cp $ASE_RESULT_MARKER $RESDIR
cp $OHE_RESULT $RESDIR
cp $CANDIDATES_RESULT $RESDIR
cp $SNVINDEL_CAN $RESDIR
cp $CNA_CAN $RESDIR
cp $SV_CAN $RESDIR
cd $RESDIR
#rm -rd $WORKDIR

