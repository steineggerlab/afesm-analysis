#!/usr/bin/env bash
# Fig. 2: metadata (Pfam, fragment, taxonomy, biome) distribution over the members of the non-singleton AFESM clusters after projection of labels
# The counts written here are hardcoded in plot_metadata_distribution_nonsingleton.py
set -euo pipefail

OUT_DIR="/share/afesm6/16_clu_plain_dist"
mkdir -p "${OUT_DIR}"

# non-singleton cluster ids (repId, nAllMem, nFrag)
NONSINGLETON="/share/afesm6/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nAllMem_nFrag.tsv"

# extract the non-singleton clusters from the annotations of all clusters (repId, memId, flag, annotation)
# taxonomy: taxonomy/taxonomy_preparation output
awk 'FNR==NR {id[$1]=1; next;} $1 in id {print $0}' "${NONSINGLETON}" /share/afesm6/15_n_genus/afesm30-repId_allmemId_flag_taxId.tsv > /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_taxId.tsv
# biome: biome/biome_analysis output
awk 'FNR==NR {id[$1]=1; next;} $1 in id {print $0}' "${NONSINGLETON}" /share/afesm5/annotation/afesm30-repId_allmemId_flag_memBiome.tsv > /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_memBiome.tsv
# pfam
awk 'FNR==NR {id[$1]=1; next;} $1 in id {print $0}' "${NONSINGLETON}" /share/afesm5/metadata/afesm30-repId_allMemId_flag_pfam.tsv > /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allMemId_flag_pfam.tsv

# annotated members of the non-singleton clusters
awk '$4!=0 {n++} END {print n"\t"FNR}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_taxId.tsv > "${OUT_DIR}/nonsingleton_tax"
awk '$4 {n++} END {print n"\t"FNR}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_memBiome.tsv > "${OUT_DIR}/nonsingleton_biome"
awk '{n+=$2; f+=$3;} END {print f"\t"n}' "${NONSINGLETON}" > "${OUT_DIR}/nonsingleton_frag"
awk '$4 {n++} END {print n"\t"FNR}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allMemId_flag_pfam.tsv > "${OUT_DIR}/nonsingleton_pfam"
awk 'substr($2, 1, 3)=="MGY" {m++} END {print m"\t"FNR}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_taxId.tsv > "${OUT_DIR}/nonsingleton_nEsm"

# metadata split by ESMatlas (MGYP) and AFDB members
# tax
awk '{mgyp=0} substr($2, 1, 4) =="MGYP" {mgyp=1;} mgyp==1 {M++}  mgyp==1 && $4!=0 {mtax++} mgyp==0 {A++} mgyp==0 && $4!=0 {atax++;} END {print mtax"\t"M"\t"atax"\t"A}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_taxId.tsv > "${OUT_DIR}/nonsingleton_tax-mgypTax_mgyp_afdbTax_afdb"
# frag
awk 'FNR==NR {id[$1]=1; next} !($2 in id) {next} substr($2, 1, 4)=="MGYP" {M++; next} {A++} END {print M, A}' /share/afesm/fragment_removal/afesm-fragments.ids /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_taxId.tsv > "${OUT_DIR}/nonsingleton_frag-mgyp_afdb"
# biome
awk '{mgyp=0} substr($2, 1, 4) =="MGYP" {mgyp=1;} mgyp==1 {M++}  mgyp==1 && $4 {mtax++} mgyp==0 {A++} mgyp==0 && $4 {atax++;} END {print mtax"\t"M"\t"atax"\t"A}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag_memBiome.tsv > "${OUT_DIR}/nonsingleton_biome-mgypBiome_mgyp_afdbBiome_afdb"
# pfam
awk '{mgyp=0} substr($2, 1, 4) =="MGYP" {mgyp=1;} mgyp==1 {M++}  mgyp==1 && $4 {mtax++} mgyp==0 {A++} mgyp==0 && $4 {atax++;} END {print mtax"\t"M"\t"atax"\t"A}' /share/afesm6/annotation/afesm30_repseq_foldseek_clu_nonsingleton-repId_allMemId_flag_pfam.tsv > "${OUT_DIR}/nonsingleton_pfam-mgypPfam_mgyp_afdbPfam_afdb"
