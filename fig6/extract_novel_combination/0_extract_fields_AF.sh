#!/bin/bash

# Usage:  
# ./0_extract_fields_AF 'path of input1' 'output path'

input1="$1"
output="$2"

# Fix the format
awk -F'\t' -v OFS='\t' '
{
    if ($8 == "foldseek,foldclass") {
        split($6, b, ",");
        print $1, $4, b[2], $7
    } else {
        print $1, $4, $6, $7
    }
}' "$input1" | awk '
{
    gsub(/_TED/, "\t")
    print
}' > "$output"

# original TED domain data from Nico:
# /home/livinit/share/afesm/y_new_domain_arr/afdb_consensus_domains_labelled.tsv 