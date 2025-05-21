#!/bin/bash

# output dir
mkdir ../data/check_rescuedN_div

# generate co-occuring pair set for ESM, AF respectively
# infile_AF="../data/AFDB-TED/inc_N/4_AF_CATHcombi_incN-ID_sortedTcombi-incN-sorted-multi.tsv"
infile_AF_original="../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
infile_AF_rescued="../data/AFDB-TED/inc_N/check2_AF_CATHcombi_incN-ID_originalTcombi_combinedNTcombi.tsv"

outfile_AF_original="../data/check_rescuedN_div/4-copair-RESULT-AF-prev-multi-ID_sortedTcombi_copair_check.tsv"
outfile_AF_rescued="../data/check_rescuedN_div/4-copair-RESULT-AF-new-multi-ID_sortedTcombi_copair_check.tsv"

./4_gen_copairs.sh $infile_AF_original $outfile_AF_original
./4_gen_copairs.sh $infile_AF_rescued $outfile_AF_rescued

# find novel co-occuring pairs in ESM
novel_rescued="../data/check_rescuedN_div/rescuedN_result-novel-copairs_ID_combi_copairs_check2-addedMDPs.tsv"
./5_compare_copairs_set.sh $outfile_AF_original $outfile_AF_rescued $novel_rescued

#  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# 11941 

#################
# generate co-occuring pair set for ESM, AF respectively
# infile_AF="../data/AFDB-TED/inc_N/4_AF_CATHcombi_incN-ID_sortedTcombi-incN-sorted-multi.tsv"
#infile_AF_original="../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
infile_AF_rescued="../data/AFDB-TED/inc_N/check2_AF_CATHcombi_incN-ID_originalTcombi_combinedNTcombi.tsv"

#outfile_AF_original="../data/check_rescuedN_div/4-copair-RESULT-AF-prev-multi-ID_sortedTcombi_copair_check.tsv"
outfile_AF_rescued="../data/check_rescuedN_div/4-copair-RESULT-AF-new-multi-ID_sortedTcombi_copair_check.tsv"

./4_gen_copairs.sh $infile_AF_original $outfile_AF_original
./4_gen_copairs.sh $infile_AF_rescued $outfile_AF_rescued

# find novel co-occuring pairs in ESM
novel_rescued="../data/check_rescuedN_div/rescuedN_result-novel-copairs_ID_combi_copairs_check-rescuedMDPs.tsv"
echo "start : search (ESM against AF)"
./5_compare_copairs_set.sh $outfile_AF_original $outfile_AF_rescued $novel_rescued

#  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# 11941 

 