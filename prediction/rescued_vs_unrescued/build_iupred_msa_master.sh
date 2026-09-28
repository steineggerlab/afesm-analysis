#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

range_file="${1:-$repo_root/all_2000_domain_ranges.tsv}"
iupred_file="${2:-$repo_root/iupred_results.tsv}"
msa_file="${3:-$repo_root/data/domain_to_msa_depth.tsv}"
output_file="${4:-$repo_root/iupred_msa_master.tsv}"

summary_file="${output_file%.tsv}.qc_summary.tsv"
missing_file="${output_file%.tsv}.qc_missing.tsv"
duplicates_file="${output_file%.tsv}.qc_duplicates.tsv"

awk \
  -v qc_summary="$summary_file" \
  -v qc_missing="$missing_file" \
  -v qc_duplicates="$duplicates_file" \
  -f "$repo_root/scripts/build_iupred_msa_master.awk" \
  "$range_file" \
  "$iupred_file" \
  "$msa_file" \
  > "$output_file"

printf 'Wrote %s\n' "$output_file"
printf 'Wrote %s\n' "$summary_file"
printf 'Wrote %s\n' "$missing_file"
printf 'Wrote %s\n' "$duplicates_file"
