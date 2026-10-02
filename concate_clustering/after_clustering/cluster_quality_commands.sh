#!/usr/bin/env bash
# Fig. 2a: structural similarity within the non-singleton AFESM clusters
# average member-to-representative lDDT and TM-score per cluster; plotted by plot_cluster_quality.py
set -euo pipefail

OUT_DIR="/share/afesm6/01_cluster_quality"
mkdir -p "${OUT_DIR}"

# member-to-representative alignments of the foldseek clusters (column 5: lDDT, column 6: TM-score)
# TODO: the command generating this alignment file is not in the log
ALN_RES="/share/afesm5/alignment/afesm30_repseq_foldseek_clu_aln_res"

# keep the non-singleton clusters only
awk 'FNR==NR {id[$1]=1; next;} $1 in id {print $0}' /share/afesm6/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_lca.tsv "${ALN_RES}" > "${OUT_DIR}/afesm30_repseq_foldseek_clu_nonsingleton_aln_res"

# average lDDT and TM-score per cluster
# MGYP000712449342 has lddt value as NAN, so it is counted as 1
awk '{n[$1]++} $5!="-NAN" {lddt[$1]+=$5; tm[$1]+=$6;} $5=="-NAN" {lddt[$1]+=1; tm[$1]+=$6;} END {for (key in n) print key"\t"lddt[key]/n[key]"\t"tm[key]/n[key]}' "${OUT_DIR}/afesm30_repseq_foldseek_clu_nonsingleton_aln_res" > "${OUT_DIR}/afesm30_repseq_foldseek_clu_nonsingleton-repId_avgLddt_avgTmscore.tsv"
