#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: ./script.sh inputfile.txt outfile.txt"
    exit 1
fi

# Assign input and output file arguments
inputfile="$1"
outfile="$2"

# Run the AWK script and direct output to the specified outfile
awk '
BEGIN {
    FS = "\t"  # Set the input field separator to tab
    OFS = "\t" # Set the output field separator to tab
}

{
    split($2, list, ";");
    n = length(list);

    # Generate all possible co-occurring pairs of the list elements
    for (i = 1; i < n; i++) {
        for (j = i + 1; j <= n; j++) {
            pair = list[i] ";" list[j];
            print $1, $2, pair;
        }
    }
}
' "$inputfile" > "$outfile"

# srun -t 10-0 -c 98 -p compute -w hulk ./process_copairs.sh ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT_multi_temp.tsv ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT_multi_temp_copairs.tsv