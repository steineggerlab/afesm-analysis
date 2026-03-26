#!/usr/bin/env bash
set -euo pipefail

# Randomly sample 10,000 AFESM entries from two sets:
# 1) singleton IDs
# 2) low-pLDDT representative structures
#
# This was used to prepare subsets for downstream novel domain identification.

# Resolve project root relative to this script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Input files
SINGLETON_ID_FILE="${ROOT_DIR}/data/afesm30_repseqp_foldseek_clu_singleton_ids"
LOWPLDDT_FILE="${ROOT_DIR}/data/afesm30_tlen70_plddtlt60-repid_picked_tlen2qlen_plddt.tsv"

# Output files
OUT_DIR="${ROOT_DIR}/results/random_samples"
mkdir -p "${OUT_DIR}"

SINGLETON_OUT="${OUT_DIR}/singletons_rand10k.tsv"
LOWPLDDT_OUT="${OUT_DIR}/lowplddt_rand10k-repid_picked_tlen2qlen_plddt.tsv"

# Sample 10,000 singleton entries containing MGYP
grep 'MGYP' "${SINGLETON_ID_FILE}" \
  | shuf -n 10000 \
  > "${SINGLETON_OUT}"

# Sample 10,000 low-pLDDT representative entries whose first column matches MGYP
awk '$1 ~ /MGYP/' "${LOWPLDDT_FILE}" \
  | shuf -n 10000 \
  > "${LOWPLDDT_OUT}"

echo "Wrote:"
echo "  ${SINGLETON_OUT}"
echo "  ${LOWPLDDT_OUT}"
