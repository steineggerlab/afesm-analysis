#!/bin/bash

# result dir 
mkdir ../data/ESM-only/HlevelCombi_mapped

# H level combination dataset already made
input_H_combi="../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT.tsv"

# remove redundancy and sort
./3_remove_redundancy_and_sort.sh ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT.tsv \
 ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-sorted.tsv

# sort the H combinations 
./3_remove_redundancy_and_sort.sh ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-sorted.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted.tsv

# get MDPs with a combination of multiple different domains (H level)
grep ";" ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted.tsv > \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi.tsv

# ./process_copairs
./4_gen_copairs.sh ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi_Hpairs.tsv

# get T pair from H pair 
awk -F"\t" -v OFS="\t" '{
    split($3, arr, ";");       # Split the third column on `;` into arr
    for (i in arr) {
        split(arr[i], subarr, "."); # Split each segment on `.`
        subarr[4] = "";            # Remove the fourth part
        arr[i] = subarr[1];        # Start rebuilding
        for (j = 2; j <= length(subarr); j++) {
            if (subarr[j] != "") {
                arr[i] = arr[i] "." subarr[j];
            }
        }
    }
    output = arr[1];
    for (k = 2; k <= length(arr); k++) {
        output = output ";" arr[k];
    }
    $4 = output;                  # Assign the modified result to the fourth column
    print $0;                     # Print the modified line
}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi_Hpairs.tsv > \
 ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs.tsv

# sort the file one more time  
./3_remove_redundancy_and_sort_f4.sh "../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs.tsv" \
 "../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_sortedTpair.tsv"

# now, we'll extract novel MDPs, based on the novel copair set previously identified
# the novelty was examined by T level, and now the novel pairs are studied in the H level
input_novel_copairs="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv" # sort 
./3_remove_redundancy_and_sort_f3.sh $input_novel_copairs ../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_sortedCopairs.tsv

# mapping 
awk -F'\t' -v OFS='\t' 'NR==FNR { data[$3]; next } ($4 in data)' \
../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_sortedCopairs.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_sortedTpair.tsv > \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv

# awk -F"\t" '{print $1}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 5203 MDPs with novel co-occuring domains (novel combinations)

# awk -F"\t" '{print $2}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 4951 novel combinations

# awk -F"\t" '{print $3}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 5134 novel co-occuring pairs 