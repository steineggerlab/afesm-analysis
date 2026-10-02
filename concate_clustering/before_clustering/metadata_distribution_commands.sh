#!/usr/bin/env bash
# Fig. 1a: metadata (Pfam, fragment, taxonomy, biome) distribution over AFDB, ESMatlas and AFESM before clustering
# The counts written here are hardcoded in plot_metadata_distribution_afesm.py
set -euo pipefail

AFESM_LOOKUP="/fast/esmfold/databases/afesm.lookup"   # AFESM (AFDB + ESMatlas) entry list
OUT_DIR="/share/afesm6/12_plain_distributions"
mkdir -p "${OUT_DIR}"

# pfam
# total annotated entries and their ratio
awk 'FNR==NR {id[$1]=1; next} $2 in id {anno++} {n++} END {print anno"\t"anno/n*100}' /share/afesm/metadata/j_afesm-entryId_pfam.tsv "${AFESM_LOOKUP}" > "${OUT_DIR}/pfam"
# annotated entries split by ESMatlas (MGYP) and AFDB
awk 'FNR==NR {id[$2]=1; next} !($1 in id) {next} {mgyp=0;} substr($1, 1, 4)=="MGYP" {mgyp=1;} mgyp==1 && !($1 in m) {m[$1]=1; M++} mgyp==0 && !($1 in a) {a[$1]=1; A++} END {print M"\t"A}' "${AFESM_LOOKUP}" /share/afesm/metadata/j_afesm-entryId_pfam.tsv > "${OUT_DIR}/pfam_mgyp_afdb"

# biome (ESMatlas only), excluding root and root:Mixed
awk 'FNR==NR && ($4!="root" && $4!="root:Mixed") {id[$1]=1; next;}  FNR==NR {next} substr($2, 1, 3) !="MGY" {next} {n++} $2 in id {anno++} END {print anno"\t"n"\t"anno*100/n}' /fast/new_2024_LCA_rmMixed/LCA_mgy_clusters_repBiomes/mgy_clusters_LCA-repBiomes.tsv "${AFESM_LOOKUP}" > "${OUT_DIR}/biome"

# frag
awk 'FNR==NR {id[$1]=1; next} {n++} $2 in id {f++} END {print f"\t"n}' /share/afesm/fragment_removal/afesm-fragments.ids "${AFESM_LOOKUP}" > "${OUT_DIR}/frag"
# frag of ESMatlas
awk 'FNR==NR {id[$1]=1; next} substr($2, 1, 4)!="MGYP" {next} {n++} $2 in id {f++} END {print f"\t"n}' /share/afesm/fragment_removal/afesm-fragments.ids "${AFESM_LOOKUP}" > "${OUT_DIR}/frag_esm"

# tax
# afesm-entryId_taxId.tsv: taxonomy/taxonomy_preparation output (taxId 0 = unannotated)
awk '{n++} $2 != 0 {t++} END {print t"\t"n}' /share/afesm6/15_n_genus/afesm-entryId_taxId.tsv > "${OUT_DIR}/tax"
awk 'substr($1, 1, 2)=="MG" {a=0; mn++;} substr($1, 1, 2)=="AF" {a=1; an++;} $2==0 {next;} a==0 {mt++; next} {at++;} END {print at"\t"an"\t"mt"\t"mn}' /share/afesm6/15_n_genus/afesm-entryId_taxId.tsv > "${OUT_DIR}/tax-afdbtax_nafdb_esmtax_nesm"
