<!-- dx-header -->
# St. Jude cis-X

Search for activating regulatory variants in the tumor genome
<!-- /dx-header -->

## Introduction

@TODO

cis-Var is designed to search for activating regulatory variants in the tumor
genome, which usually cause cis-activating of the target genes. The key step
is to locate the cis-activated genes in a given genome, with the ASE (Allelic
Specific/Imbalanced Expression) and OHE (Outlier High Expression) signal.
From there, cis-Var will start to search for any variants sitting in the same
TAD (Topologically Associated Domains) with the candidates, including
structural variant (SV), copy number aberration (CNA) and SNV/Indels. cis-Var
will give SV and CNA higher priority to SNV/Indel by design. A transcription
factor binding motif analysis is included with the FIMO function in MEME and
the motif from HOCOMOCO database (v10). See the manuscript for more details
regarding the logic behind (url to be added).

cis-Var relies on pre-calculated "reference expression matrix" for
calculating the OHE signal, which is disease specific. We currently have the
reference built for pediatric T-ALL and AML. More to be added.

Only for hg19 at this moment.

## Inputs

@TODO

## Outputs

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
