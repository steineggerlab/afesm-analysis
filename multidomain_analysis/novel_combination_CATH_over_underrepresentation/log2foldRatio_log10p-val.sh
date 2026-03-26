#!/bin/bash

# Usage: ./code.sh <groupA_size> <groupB_size> <input_file>

groupA=$1
groupB=$2
input_file=$3

awk -v groupA_size="$groupA" -v groupB_size="$groupB" -F"\t" -v OFS="\t" '
BEGIN {
    print_header = 1
}

NR == 1 {
    # Identify column indices by name
    for (i = 1; i <= NF; i++) {
        header[i] = $i
        if ($i == "raw_count_A") colA = i
        if ($i == "raw_count_B") colB = i
        if ($i == "p_adjusted") colP = i
    }
    next
}

{
    countA = $colA + 1
    countB = $colB + 1

    # log2FC
    log2FC = log((countA * (groupB_size + 1)) / (countB * (groupA_size + 1))) / log(2)

    # -log10(p_adjusted), avoid log(0)
    padj = ($colP == 0) ? 1e-320 : $colP
    log10p = -log(padj) / log(10)

    # Output
    if (print_header) {
        print $0, "log2FC", "-log10p_adj"
        print_header = 0
    }

    print $0, log2FC, log10p
}
' "$input_file"
