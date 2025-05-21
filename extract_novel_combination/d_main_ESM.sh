#!/bin/bash

# working dir :  
mkdir ../data/ESM-only
mkdir ../data/ESM-only/given_data/
mkdir ../data/ESM-only/tmp/

# the original ESM-only data file from Nico
# mv /fast/yewon/FINAL_MDP/data/ESM-only/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv # 5114908 domains 
# mv ~~ 

# extract_fields_ESM.sh
echo "start : ./0_extract_fields_ESM.sh"
./0_extract_fields_ESM.sh ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv # 5114908 domains 
echo "end : ./0_extract_fields_ESM.sh"
echo "\n"

# just concatenate (raw combination)
./1_just_concat_ESM.sh ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv ../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi.tsv

# extract H & T hit, and concatenate
echo "start : ./1_extract-HT_concat.sh"
./1_extract-HT_concat.sh ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv ../data/ESM-only/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv # 1998888 proteins    476181 MDPs  
echo "end : ./1_extract-HT_concat.sh"
echo "\n"

# extract CAT (topology) level 
echo "start : ./2_remove_Hlevel.sh"
./2_remove_Hlevel.sh ../data/ESM-only/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/ESM-only/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv # 1998888 proteins    -ID_Tcombi.tsv
echo "end : ./2_remove_Hlevel.sh"
echo "\n"

# sort within combination, removing reduncant topologies within combination
echo "start : ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh ../data/ESM-only/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv # 1998888 proteins   _sortedTcombi.tsv
echo "end : ./3_remove_redundancy_and_sort.sh"
echo "\n"

# get MDPs with a combination of multiple different domains 
echo "start : extracting  MDPs with a combination of multiple different domains "
grep ";" ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv > ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv # 393793 proteins -ID_sortedTcombi-multi.tsv
echo "end : extractig  MDPs with a combination of multiple different domains "
echo "\n"