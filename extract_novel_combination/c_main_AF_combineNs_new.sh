#!/bin/bash

# data dir 
mkdir /fast/yewon/AFESM_MDP_Share/data/AFDB-TED/inc_N

# rescued Ns
awk -F'\t' -v OFS='\t' '{
    if ($1 ~ /_TED[0-9]+_v[0-9]+/) { 
        match($1, /_TED([0-9]+)_v([0-9]+)/, parts);
        if (parts[1] && parts[2]) {
            $1 = gensub(/_TED[0-9]+_v/, "_v", 1, $1) "\t" parts[1];
        }
    }
    print
}' ../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted.tsv | \
awk -F'\t' -v OFS='\t' '{print $1, $2, "-", $3, "H"}' > ../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted_modified.tsv


# working dir : /fast/yewon/0_Novel_MDP_Main/commands
# mkdir ../data/AFDB-TED
# mkdir ../data/AFDB-TED/given_data_by_Nico
# mkdir ../data/AFDB-TED/tmp

# original TED domain data from Nico
# mv /fast/yewon/FINAL_MDP/data/AFDB-TED/given_data/ted_domain_assignments.tsv ../data/AFDB-TED/given_data
# mv /fast/yewon/FINAL_MDP/data/AFDB-TED/tmp ../data/AFDB-TED/tmp

# extract_fields_AF.sh
# echo "start : ./0_extract_fields_AF.sh"
# ./0_extract_fields_AF.sh ../data/AFDB-TED/given_data/ted_domain_assignments.tsv ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv  
# echo "end : ./0_extract_fields_AF.sh"
# echo "\n"

mkdir ../data/AFDB-TED/tmp_rescuedN
# concatenating the files 
cat \
../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted_modified.tsv \
../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv \
> ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv

# # ex
# grep AF-A0A2Z4G890-F1-model_v4  ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv
# AF-A0A2Z4G890-F1-model_v4       01      88.5208 -       -
# AF-A0A2Z4G890-F1-model_v4       02      81.9224 2.40.128.190    T
# AF-A0A2Z4G890-F1-model_v4       03      82.1209 2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       04      90.0412 -       -
# AF-A0A2Z4G890-F1-model_v4       05      90.0344 2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       06      83.1807 2.60.40.760     H

# grep AF-A0A2Z4G890-F1-model_v4 ../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted_modified.tsv
# AF-A0A2Z4G890-F1-model_v4       04      -       2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       01      -       2.40.10.500     H

#  grep AF-A0A2Z4G890-F1-model_v4 ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv
# AF-A0A2Z4G890-F1-model_v4       04      -       2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       01      -       2.40.10.500     H
# AF-A0A2Z4G890-F1-model_v4       01      88.5208 -       -
# AF-A0A2Z4G890-F1-model_v4       02      81.9224 2.40.128.190    T
# AF-A0A2Z4G890-F1-model_v4       03      82.1209 2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       04      90.0412 -       -
# AF-A0A2Z4G890-F1-model_v4       05      90.0344 2.60.40.10      H
# AF-A0A2Z4G890-F1-model_v4       06      83.1807 2.60.40.760     H


# sort 
sort -t$'\t' -k1,1 -k2,2 \
../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv \
-o ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded-sorted.tsv

# extract H & T hit, and concatenate
echo "start : ./1_extract-HT_concat.sh"
./1_extract-HT_concat.sh ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv ../data/AFDB-TED/tmp_rescuedN/1_extract-HT_concat-RESULT-ID_rawCombi.tsv
echo "end : ./1_extract-HT_concat.sh"
echo "\n"

# extract CAT (topology) level   1.1.1.1;1.1.2  -> 1.3.1;1.1.2 
echo "start : ./2_remove_Hlevel.sh"
./2_remove_Hlevel.sh ../data/AFDB-TED/tmp_rescuedN/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/AFDB-TED/tmp_rescuedN/2_remove_Hlevel-RESULT-ID_Tcombi.tsv 
echo "end : ./2_remove_Hlevel.sh"
echo "\n"

# sort within combination, removing reduncant topologies within combination   1.3.1;1.1.2    1.1.2;1.3.1  #a,b,c  3 pairs  #a,c   ->
echo "start : ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh ../data/AFDB-TED/tmp_rescuedN/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv # 143511353 proteins 
echo "end : ./3_remove_redundancy_and_sort.sh"
echo "\n"

# get MDPs with a combination of multiple different domains (Topology level)
echo "start : extracting  MDPs with a combination of multiple different domains "#
grep ";" ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv > ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv  # 51,431,676 proteins  # total MDP will be larger 
echo "end : extracting  MDPs with a combination of multiple different domains "
echo "\n"

# srun -t 2-0 -c 64 -p compute -w super002 ./c_main_AF_combineNs_new.sh