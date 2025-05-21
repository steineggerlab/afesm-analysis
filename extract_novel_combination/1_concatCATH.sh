#!/bin/bash

# Usage: ./script.sh input_file output_file

 
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
awk -F'\t' -v OFS='\t' '
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
' "$input1" | uniq > "$output"

# Check if the output file was created successfully
if [ ! -f "$output" ]; then
    echo "Output file not created!"
    exit 1
fi

echo "Processing complete. Output saved to $output."

# cd /fast/yewon/finalized_MDP_analysis/commands
# ./1_just_concat_ESM.sh ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv > ../data/ESM-only/tmp/ALL-MDPs-list.tsv
# grep "#" ../data/ESM-only/tmp/ALL-ESM-list.tsv > ../data/ESM-only/tmp/ALL-ESM-MDPs-list.tsv