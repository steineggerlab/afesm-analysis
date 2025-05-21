#!/bin/bash

# output dir
mkdir ../data/find-novel_ESMonlyGH-AFincN

# generate co-occuring pair set for ESM, AF respectively
# infile_AF="../data/AFDB-TED/inc_N/4_AF_CATHcombi_incN-ID_sortedTcombi-incN-sorted-multi.tsv"
infile_AF="../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
# infile_AF="../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"

infile_ESM="../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"

outfile_AF="../data/find-novel_ESMonlyGH-AFincN/4-copair-RESULT-AF-multi-ID_sortedTcombi_copair_check.tsv"
outfile_ESM="../data/find-novel_ESMonlyGH-AFincN/4-copair-RESULT-ESM-multi-ID_sortedTcombi_copair_check.tsv"
echo "start : ESM copairs"
./4_gen_copairs.sh $infile_ESM $outfile_ESM
echo "start : AF copairs"
./4_gen_copairs.sh $infile_AF $outfile_AF

# find novel co-occuring pairs in ESM
novel_ESM="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs_check.tsv"
echo "start : search (ESM against AF)"
./5_compare_copairs_set.sh $outfile_AF $outfile_ESM $novel_ESM

#  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# 11941 


# prep for the TABLE (compiliation) generation
 ./1_concat_cath_v2.sh ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat_check.tsv

infile="../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv"
awk -F'\t' -v OFS='\t' '{print $1, $3}' $infile > \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-NOVEL-multi-ID_Hpairs_check.tsv

# ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-NOVEL-multi-ID_Hpairs.tsv # 5203 




# #!/bin/bash

# # output dir
# mkdir ../data/find-novel_ESMonlyGH-AFincN

# # generate co-occuring pair set for ESM, AF respectively
# infile_AF="../data/AFDB-TED/inc_N/4_AF_CATHcombi_incN-ID_sortedTcombi-incN-sorted-multi.tsv"
# infile_ESM="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
# outfile_AF="../data/find-novel_ESMonlyGH-AFincN/4-copair-RESULT-AF-multi-ID_sortedTcombi_copair.tsv"
# outfile_ESM="../data/find-novel_ESMonlyGH-AFincN/4-copair-RESULT-ESM-multi-ID_sortedTcombi_copair.tsv"
# echo "start : ESM copairs"
# ./4_gen_copairs.sh $infile_ESM $outfile_ESM
# echo "start : AF copairs"
# ./4_gen_copairs.sh $infile_AF $outfile_AF

# # find novel co-occuring pairs in ESM
# novel_ESM="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv"
# echo "start : search (ESM against AF)"
# ./5_compare_copairs_set.sh $outfile_AF $outfile_ESM $novel_ESM

# #  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# # 11941 


# # prep for the TABLE (compiliation) generation
#  ./1_concat_cath_v2.sh ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv \
# ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat.tsv

# infile="../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv"
# awk -F'\t' -v OFS='\t' '{print $1, $3}' $infile > \
# ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-NOVEL-multi-ID_Hpairs.tsv
