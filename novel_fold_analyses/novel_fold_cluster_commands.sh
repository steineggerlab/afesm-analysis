#!/usr/bin/env bash
# Supp. Fig. 10: the clusters where the 45 novel folds are found
# a: cluster metadata, plotted by plot_novel_fold_cluster_metadata.py
# b: taxonomic LCA of the clusters (taxonomy report, visualized with Pavian)
set -euo pipefail

TAX_DIR="/share/afesm6/49_tax_of_novel"
OUT_DIR="/share/afesm6/50_novel_struct_dl"
AFESM_DB="/fast/esmfold/databases/afesm"
mkdir -p "${TAX_DIR}/database" "${OUT_DIR}"

# novel folds (domainId: <repId>_<domain>) from the novel fold identification workflow
# novel_from_bins: 33 from the AF2-ColabFold re-predicted domains, novel_from_pipeline: 12 from the ESMFold models
awk '{split($1, arr, "_"); print arr[1]}' "${TAX_DIR}/novel_from_bins" > "${TAX_DIR}/novel_from_bins-ids"
awk '{split($1, arr, "_"); print arr[1]}' "${TAX_DIR}/novel_from_pipeline" > "${TAX_DIR}/novel_from_pipeline-ids"
cat "${TAX_DIR}/novel_from_bins-ids" "${TAX_DIR}/novel_from_pipeline-ids" > "${OUT_DIR}/novel_domain_ids"

# a: metadata of the novel fold clusters
# 39_share_db/2-...: metadata of all the AFESM clusters (afesm.foldseek.com data)
awk 'FNR==NR {id[$1]=1; next} $1 in id {print $0}' "${OUT_DIR}/novel_domain_ids" /share/afesm6/39_share_db/2-repID_isOnlyESM_nMem_nAllMem_repPlddt_avgPlddt_avgAllPlddt_repLen_avgLen_avgAllLen_LCAtaxID_nBiome_LCBID.tsv > "${OUT_DIR}/novel_domain_ids-repID_isOnlyESM_nMem_nAllMem_repPlddt_avgPlddt_avgAllPlddt_repLen_avgLen_avgAllLen_LCAtaxID_nBiome_LCBID.tsv"

# b: taxonomic LCA of the novel fold clusters
# LCA of all the cluster members: taxonomy/taxonomy_lca
awk 'FNR==NR {id[$1]=1; next} $2 in id {print $0}' "${OUT_DIR}/novel_domain_ids" "${AFESM_DB}.lookup" > "${TAX_DIR}/database/novel_domain_lca.lookup"
mmseqs createsubdb "${TAX_DIR}/database/novel_domain_lca.lookup" /share/afesm6/15_n_genus/tax_lca/afesm30_allMem_lca_blacklist "${TAX_DIR}/database/novel_domain_lca"
mmseqs taxonomyreport "${AFESM_DB}" "${TAX_DIR}/database/novel_domain_lca" "${TAX_DIR}/database/novel_domain_lca_report"
