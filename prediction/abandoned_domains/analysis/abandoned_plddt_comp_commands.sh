#!/usr/bin/env bash
# Supp. Fig. 9a: average pLDDT of the 2.3M low-quality (abandoned) domains, ESMFold vs AF2-ColabFold re-prediction
# Plotted by abandoned_plddt_comp.ipynb
set -euo pipefail

# abandoned domains from the novel fold identification workflow (Nico): domainId, ..., column 7: ESMFold domain pLDDT
gunzip -c /share/afesm6/23_abandoned_domains/allreps_lowqual_entries.gz > /share/afesm6/23_abandoned_domains/allreps_lowqual_domains

# AF2-ColabFold domain pLDDT of the re-predicted abandoned domains (Nico): domainId, pLDDT
COLABFOLD_PLDDT="/share/afesm6/40_nico_investigation/plddt_results_allset"

# domainId, ColabFold pLDDT, ESMFold pLDDT
awk 'FNR==NR {split($1, arr, "_"); entry=arr[1]"_"arr[2]; id[entry]=$2; next} {print $1"\t"id[$1]"\t"$7}' "${COLABFOLD_PLDDT}" /share/afesm6/23_abandoned_domains/allreps_lowqual_domains > /share/afesm6/40_nico_investigation/abandoned_domains-domainId_AFplddt_ESMplddt.tsv
