#!/bin/bash

# working dir : /fast/yewon/0_Novel_MDP_Main/commands
mkdir ../data/AFDB-TED
mkdir ../data/AFDB-TED/given_data_by_Nico
# mkdir ../data/AFDB-TED/tmp

# original TED domain data from Nico
# mv /fast/yewon/FINAL_MDP/data/AFDB-TED/given_data/ted_domain_assignments.tsv ../data/AFDB-TED/given_data
# mv /fast/yewon/FINAL_MDP/data/AFDB-TED/tmp ../data/AFDB-TED/tmp


# extract_fields_AF.sh
echo "start : ./0_extract_fields_AF.sh"
./0_extract_fields_AF.sh ../data/AFDB-TED/given_data/ted_domain_assignments.tsv ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv
echo "end : ./0_extract_fields_AF.sh"
echo "\n"

# just concat 
./1_just_concat_ESM.sh  ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat.tsv

grep ";" "../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat.tsv" > ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat-MDP.tsv
wc -l ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat-MDP.tsv

# extract H & T hit, and concatenate
echo "start : ./1_extract-HT_concat.sh"
./1_extract-HT_concat.sh ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv ../data/AFDB-TED/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv   #65077500 with 2 or more CATH domains 
echo "end : ./1_extract-HT_concat.sh"
echo "\n"

# extract CAT (topology) level 
echo "start : ./2_remove_Hlevel.sh"
./2_remove_Hlevel.sh ../data/AFDB-TED/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/AFDB-TED/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv
echo "end : ./2_remove_Hlevel.sh"
echo "\n"

# sort within combination, removing reduncant topologies within combination
echo "start : ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh ../data/AFDB-TED/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv # 143511353 proteins 
echo "end : ./3_remove_redundancy_and_sort.sh"
echo "\n"

# get MDPs with a combination of multiple different domains (Topology level)
echo "start : extracting  MDPs with a combination of multiple different domains "#
grep ";" ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv > ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv  # 51431676 proteins 
echo "end : extracting  MDPs with a combination of multiple different domains "
echo "\n"