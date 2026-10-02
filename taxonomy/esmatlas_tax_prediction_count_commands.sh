#!/usr/bin/env bash
# Fig. 2b: number of ESMatlas entries per rank group of the predicted taxonomy
# Plotted by 15_tax_plain_bar.ipynb
set -euo pipefail

# taxonomy prediction result of ESMatlas: entryId, taxId, taxRank, taxName
# LCA of the taxonomy_preparation step 5 alignment, recomputed with the UniRef90 taxIds of the cluster representatives (taxonomy_preparation, step 6)
TAX_ASSIGNED="/share/afesm6/14_uniref90_tax_substitution/esmatlas_union_uniref90WOBacArch_gtdb_taxAssigned_aln_lca.tsv"
# tax_rank_grouping.py outputs
GROUPING="/share/afesm6/coreness/grouping_w_merged_dmp_gtdb-taxId_taxName_taxRank_groupName.tsv"
# taxId -> superkingdom; NCBI Bacteria (2) and Archaea (2157) should not remain since they are replaced by GTDB
SUPERKINGDOM="/share/afesm6/coreness/grouping_w_merged_dmp_gtdb-taxId_taxName_superkingdomId_superkingdomName.tsv"
OUT_DIR="/share/afesm6/14_uniref90_tax_substitution"
mkdir -p "${OUT_DIR}"

# set the entries assigned to NCBI Bacteria or Archaea as unclassified
awk 'FNR==NR && ($3==2 || $3==2157) {id[$1]=$3; } FNR==NR {next} !($2 in id) {print $0; next;} {print $1"\t0\tno rank\tunclassified"}' "${SUPERKINGDOM}" "${TAX_ASSIGNED}" > "${OUT_DIR}/esmatlas_tax_wo_ncbi-entryId_taxId_taxRank_taxName.tsv"

# grouping
awk -F "\t" 'FNR==NR {id[$1]=$NF; next} {print $0"\t"id[$2]}' "${GROUPING}" "${OUT_DIR}/esmatlas_tax_wo_ncbi-entryId_taxId_taxRank_taxName.tsv" > "${OUT_DIR}/esmatlas_tax_wo_ncbi-entryId_taxId_taxRank_taxName_taxGroup.tsv"

# count the groups (taxId 0: not predicted)
awk -F "\t" '$2!=0 {id[$5]++; next;} {id["not predicted"]++;} END {for (key in id) print id[key]"\t"key}' "${OUT_DIR}/esmatlas_tax_wo_ncbi-entryId_taxId_taxRank_taxName_taxGroup.tsv" | sort -k1,1nr > "${OUT_DIR}/esmatlas_tax_wo_ncbi-count_taxGroup.tsv"
