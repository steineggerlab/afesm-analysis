#!/bin/bash

 

# CATH name 부터 붙이기; 
# 피겨 c, d, e 만들기 

 
awk '{gsub(/ /, "_"); print}' ../data/CATH_metadat/cath-names.txt | \
awk '{gsub(/____/, "\t"); print}' | \
awk -F"\t" -v OFS='\t' '{$3 = substr($3, 2); print}' > ../data/CATH_metadat/cath-names_modified.txt   # 새로 다운받아서 가공하기? 

awk -F"\t" -v OFS='\t' '$3=="" {print $1, $2, "no_name"}' ../data/CATH_metadat/cath-names_modified.txt  > ../data/CATH_metadat/cath-names_modified2.txt  # 해결하기 

#
awk -F'\t' -v OFS='\t'  '
    NR == FNR {
        # Read the first file and store field3 with field1 as the key
        mapping[$1] = $3
        next
    }
    {
        # Split field3 of the second file by semicolons
        n = split($3, keys, ";")
        values = ""
        # Loop over each key to build the corresponding values string
        for (i = 1; i <= n; i++) {
            key = keys[i]
            if (values != "")
                values = values " & "
            values = values mapping[key]
        }
        # Print the original line with the new mapped values appended
        print $1 "\t" $3 "\t" values
    }
' ../data/CATH_metadat/cath-names_modified.txt \
    ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv  \
  > ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-NOVEL-multi-ID_Hpairs_CATHpair.tsv






 