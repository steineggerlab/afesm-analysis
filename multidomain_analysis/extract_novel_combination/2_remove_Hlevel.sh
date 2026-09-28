#!/bin/bash

# Ensure the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input_file output_file"
    exit 1
fi

input_file=$1
output_file=$2

# Process the input file
awk '{gsub(/,/, "."); print}' "$input_file" | awk '
{
    # Print $1 (first field)
    printf "%s\t", $1;
    
    # Split $2 by ";" and process each part
    n = split($2, a, ";");
    for (i = 1; i <= n; ++i) {
        split(a[i], b, ".");
        printf "%s.%s.%s", b[1], b[2], b[3];
        if (i < n) printf ";";  # Add semicolon between parts
    }
    
    # Print newline after processing each line
    printf "\n";
}' > "$output_file"



 

#./2_remove_Hlevel.sh /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_ID_abundance_rank_CATHS35_CATHdomain_CATHname.tsv /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold-Superfam_abundance_rank_CATHS35_CATHdomain_CATHname.tsv


# /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold-Superfam_abundance_rank_CATHS35_CATHdomain_CATHname.tsv
# /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold_abundance_CATHS35_CATHdomain.tsv


#  awk -F'\t' -v OFS='\t' '{print $1, $3, $5, $6}'  /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold-Superfam_abundance_rank_CATHS35_CATHdomain_CATHname.tsv > /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold_abundance_CATHS35_CATHdomain.tsv


#  awk -F'\t' -v OFS='\t' '
# {
#     id = $1
#     sum1[id] += $2
#     sum2[id] += $3
#     sum3[id] += $4
# }
# END {
#     for (id in sum1) {
#         printf "%s\t%.7f\t%d\t%d\n", id, sum1[id], sum2[id], sum3[id]
#     }
# }
# ' | sort -k2,2nr | /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold_abundance_CATHS35_CATHdomain.tsv > /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_compare_w_AF/ESM-novel-H_Fold_abundance_CATHS35_CATHdomain_SUM.tsv

# 이 방식으로 fold - abundance in CATH 한 다음에, 거기에다가 fold 대응시켜야 한다 


# re

# ./2_remove_Hlevel.sh /fast/yewon/finalized_MDP_analysis/data/ESM-only/cath-superfamily-list.txt  /fast/yewon/finalized_MDP_analysis/data/ESM-only/cath-superfamily-list-FOLD.tsv

#  awk -F'\t' -v OFS='\t' 'NR >1 {print $1, $3, $4}'  /fast/yewon/finalized_MDP_analysis/data/ESM-only/cath-superfamily-list-FOLD.tsv > /fast/yewon/finalized_MDP_analysis/data/ESM-only/cath-superfamily-list-FOLD_S35_nDomains.tsv


