#!/usr/bin/env bash
# Supp. Fig. 9e: structural similarity between the rescued domains (AF2-ColabFold) and their ESMatlas counterparts
# rescued: AF2-ColabFold domain pLDDT > 70 and ESMFold domain pLDDT < 70
# Plotted by plot_rescued_domain_alignment.py
set -euo pipefail

ABANDONED_DIR="/share/afesm6/23_abandoned_domains"
OUT_DIR="/share/afesm6/50_novel_struct_dl"
AFESM_DB="/fast/esmfold/databases/afesm"
# AF2-ColabFold models of the abandoned domains (prediction/abandoned_domains)
COLABFOLD_DB="/fast/esmfold/abandoned_preds/database/predicted_final_db"
TMP_DIR="/mnt/scratch/tmp"
mkdir -p "${OUT_DIR}/database" "${OUT_DIR}/alignment"

# abandoned domains (abandoned_plddt_comp_commands.sh): domainId, ..., column 4: domain boundaries (start-end, _-separated)
shuf "${ABANDONED_DIR}/allreps_lowqual_domains" > "${ABANDONED_DIR}/allreps_lowqual_domains_shuf"
# entryId, start,end,domainId[,start,end,domainId,...]
awk '{n=split($4,r,"_"); split($1,a,"_"); entry=a[1]; printf "%s\t", entry; for(i=1;i<=n;i++){split(r[i],p,"-"); printf "%s,%s,%s%s", p[1], p[2], $1, (i<n)?",":"\n"}}' "${ABANDONED_DIR}/allreps_lowqual_domains_shuf" > "${ABANDONED_DIR}/allreps_lowqual_domains_shuf.tsv"

# chop the abandoned domains out of their ESMatlas structures
# 19_makefile_s2e.sh: prediction/TED_novel_domains/ (calls 19_chop_domain_s2e.py)
foldseek createsubdb "${ABANDONED_DIR}/allreps_lowqual_domains_shuf.tsv" "${AFESM_DB}" "${OUT_DIR}/database/afesm_abandoned_db" --id-mode 1
./prediction/TED_novel_domains/19_makefile_s2e.sh "${OUT_DIR}/database/afesm_abandoned_db" "${TMP_DIR}/before/" "${OUT_DIR}/database/abandoned_domains_esmatlas" "${TMP_DIR}/" "${ABANDONED_DIR}/allreps_lowqual_domains_shuf.tsv"

# pair every ColabFold domain with its ESMatlas domain (self-hit alignment)
awk '{split($2,a,","); print a[3]"\t"(FNR-1)}' "${ABANDONED_DIR}/allreps_lowqual_domains_shuf.tsv" > "${OUT_DIR}/allreps_lowqual_domains-domain_index.tsv"
awk 'FNR==NR {id[$1]=$2; next} {N=split($2, arr, "_"); l=arr[1]"_"arr[2]; print $1"\t"id[l]}' "${OUT_DIR}/allreps_lowqual_domains-domain_index.tsv" "${COLABFOLD_DB}.lookup" > "${OUT_DIR}/alignment/esm_afdb_alignment.tsv"
awk '{print $1"\t"$2"\t0"}' "${OUT_DIR}/alignment/esm_afdb_alignment.tsv" > "${OUT_DIR}/tmp_prefilter.tsv"
foldseek tsv2db "${OUT_DIR}/tmp_prefilter.tsv" "${OUT_DIR}/alignment/esm_afdb_prefilter" --output-dbtype 7

# align: query ColabFold domain, target ESMatlas domain
foldseek structurealign "${COLABFOLD_DB}" "${OUT_DIR}/database/abandoned_domains_esmatlas" "${OUT_DIR}/alignment/esm_afdb_prefilter" "${OUT_DIR}/alignment/esm_afdb_aln" -a
foldseek convertalis "${COLABFOLD_DB}" "${OUT_DIR}/database/abandoned_domains_esmatlas" "${OUT_DIR}/alignment/esm_afdb_aln" "${OUT_DIR}/alignment/esm_afdb_aln_res" --format-output query,target,evalue,lddt,alntmscore,qtmscore

# AF2-ColabFold domain pLDDT -> /share/afesm6/50_novel_struct_dl/novel_domain-domainId_plddt.tsv
python3 prediction/abandoned_domains/analysis/abandoned_domain_colabfold_plddt.py

# rescued domains: domainId, ColabFold pLDDT, ESMFold pLDDT
awk 'FNR==NR && $7 < 70 {id[$1]=$7; next} FNR==NR {next} $1 in id && $2 > 70 {print $0"\t"id[$1]}' "${ABANDONED_DIR}/allreps_lowqual_domains" "${OUT_DIR}/novel_domain-domainId_plddt.tsv" > "${OUT_DIR}/rescued_domain-domainId_colabPlddt_esmPlddt.tsv"
# add lDDT, alnTM-score, qTM-score (0 if not aligned)
awk 'FNR==NR {N=split($1, arr, "_"); l=arr[1]"_"arr[2]; id[l]=$4"\t"$5"\t"$6; next} $1 in id {print $0"\t"id[$1]} !($1 in id) {print $0"\t0\t0\t0"}' "${OUT_DIR}/alignment/esm_afdb_aln_res" "${OUT_DIR}/rescued_domain-domainId_colabPlddt_esmPlddt.tsv" > "${OUT_DIR}/rescued_domain-domainId_colabPlddt_esmPlddt_lddt_alntmscore_qtmscore.tsv"
