#!/bin/bash

# output dir
mkdir ../data/find-novel_ESMonlyGH-AFwoN

# generate co-occuring pair set for ESM, AF respectively
infile_AF="../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
infile_ESM="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
outfile_AF="../data/find-novel_ESMonlyGH-AFwoN/4-copair-RESULT-AF-multi-ID_sortedTcombi_copair.tsv"
outfile_ESM="../data/find-novel_ESMonlyGH-AFwoN/4-copair-RESULT-ESM-multi-ID_sortedTcombi_copair.tsv"
echo "start : ESM copairs"
./4_gen_copairs.sh $infile_ESM $outfile_ESM
echo "start : AF copairs"
./4_gen_copairs.sh $infile_AF $outfile_AF

# find novel co-occuring pairs in ESM
novel_ESM="../data/find-novel_ESMonlyGH-AFwoN/woN_result-novel-copairs_ID_combi_copairs.tsv"
echo "start : search (ESM against AF)"
./5_compare_copairs_set.sh $outfile_AF $outfile_ESM $novel_ESM

#  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# 11941 