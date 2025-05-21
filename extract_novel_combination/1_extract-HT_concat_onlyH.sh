#!/bin/bash

# Usage: ./script.sh input_file output_file

# ID_DomainNo_Consensus_Chopping_DomainLen_DomainSeg_pLDDT_SSE_nHelices_nStrands_nHel+Stran_nTurns_CATH_method_G

# Fix the format
# ID num plddt cath T/H

input1="$1"
output="$2"

# Check if input file exists
if [ ! -f "$input1" ]; then
    echo "Input file not found!"
    exit 1
fi

# Filter records and process the filtered records in a single pipeline
awk -F'\t' '$5 == "H"' "$input1" | awk -F'\t' -v OFS='\t' '
{
    # If the key (1st field) is not in the order array, add it
    if (!($1 in order)) {
        order[cnt++] = $1
    }

    # Concatenate the 4th field values for each unique key in the cath array
    if ($1 in cath) {
        cath[$1] = cath[$1] ";" $4
    } else {
        cath[$1] = $4
    }
}

END {
    # Print each key along with the concatenated values from the cath array
    for (i = 0; i < cnt; ++i) {
        key = order[i]
        print key, cath[key]
    }
}
' | uniq > "$output"

# Check if the output file was created successfully
if [ ! -f "$output" ]; then
    echo "Output file not created!"
    exit 1
fi

echo "Processing complete. Output saved to $output."
