#!/bin/bash

# Usage:  
# ./modify_given_domain.sh 'path of input1' 'output path'

input1="$1"
output="$2"


# Fix the format
awk -F'\t' -v OFS='\t' '
{
    print $1, $4, $6, $7  # Extract ID, plddt, CATH, and CATH_level(T, H, N, -)
}' "$input1" | awk '
{
    gsub(/_/, "\t")       # Replace underscores with tabs
    print
}' > "$output"
