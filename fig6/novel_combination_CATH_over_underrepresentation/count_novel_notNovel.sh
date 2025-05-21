#!/bin/bash

awk -F'[\t;]' '
BEGIN {
    OFS = "\t"
}
NR == FNR {
    for (i = 2; i <= NF; i++) {
        count1[$i]++
    }
    next
}
{
    for (i = 2; i <= NF; i++) {
        count2[$i]++
    }
}
END {
    for (val in count1) seen[val] = 1
    for (val in count2) seen[val] = 1

    for (val in seen) {
        c1 = (val in count1) ? count1[val] : 0
        c2 = (val in count2) ? count2[val] : 0
        print val, c1, c2
    }
}' "$1" "$2"
