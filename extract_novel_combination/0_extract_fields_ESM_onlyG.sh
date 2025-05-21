#!/bin/bash

# Usage:  
# ./0_extract_fields_ESM_onlyG.sh 'path of input1' 'output path'

input1="$1"
output="$2"

# Extract Globular Entries
awk -F'\t' -v OFS='\t' '$9 == "G" {
    print $1, $4, $6, $7  # Extract ID, plddt, CATH, and CATH_level (T, H, N, -)
}' "$input1" | awk '
{
    gsub(/_/, "\t")       # Replace underscores with tabs
    print
}' > "$output"

