#!/bin/bash
mkdir ../data/ESM-only/tmp_onlyGH/

# extract Globular CATH hits 
echo "start : ./0_extract_fields_ESM_onlyG.sh"
./0_extract_fields_ESM_onlyG.sh ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv \
../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv
echo "end : ./0_extract_fields_ESM_onlyG.sh"
echo "\n"

# extract H level (full four level) CATH hits, and "concatenate"
echo "start : ./1_extract-HT_concat.sh"
./1_extract-HT_concat_onlyH.sh ../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_GHcombi.tsv
echo "end : ./1_extract-HT_concat.sh"
echo "\n"

# sort within combination, removing reduncant topologies within combination
echo "start : ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh  ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_GHcombi.tsv ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv # 1998888 proteins   _sortedTcombi.tsv
echo "end : ./3_remove_redundancy_and_sort.sh"
echo "\n"

# get MDPs with a combination of multiple different domains 
echo "start : extracting  MDPs with a combination of multiple different domains "
grep ";" ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv  > ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi-multi.tsv # 393793 proteins -ID_sortedTcombi-multi.tsv
echo "end : extractig  MDPs with a combination of multiple different domains "
echo "\n"

# 141035-5493