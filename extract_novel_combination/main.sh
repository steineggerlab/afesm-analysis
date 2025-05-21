#!/bin/bash


##############################
###### MDPs from AFDB   ######
##############################

# directories 
mkdir ../data/AFDB-TED
mkdir ../data/AFDB-TED/given_data  # ted_domain_assignments.tsv 
mkdir ../data/AFDB-TED/tmp

# extract_fields_AF.sh
echo "AF_extracting fields"
./0_extract_fields_AF.sh ../data/AFDB-TED/given_data/ted_domain_assignments.tsv ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv

# counting MDP
# simple concatenation
echo "AF_counting MDPs"
./1_concatCATH.sh  ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat.tsv
grep ";" "../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat.tsv" > ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat-MDP.tsv
# wc -l ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level_concat-MDP.tsv

# extract H & T hit, and concatenate  
echo "AF_extract H & T hit, and concatenate"
awk -F'\t' '$5 == "T" || $5 == "H"' ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv > ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-HT.tsv
./1_concatCATH.sh  ../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-HT.tsv ../data/AFDB-TED/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv   #65077500 with 2 or more CATH domains 

# extract CAT (topology) level from the CATH code     ex) 1.1.1.1;1.1.2.2  -> 1.3.1;1.1.2 
echo "AF_extract T level" 
./2_remove_Hlevel.sh ../data/AFDB-TED/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/AFDB-TED/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv

# sort within combination, removing reduncant topologies within combination
echo "AF_remove_redundancy_and_sort"
./3_remove_redundancy_and_sort.sh ../data/AFDB-TED/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv # 143511353 proteins 

# get MDPs with a combination of multiple different domains (Topology level)
echo "AF_extracting  MDPs with a combination of multiple different domains"
grep ";" ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv > ../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv  # 51431676 proteins 

##################################################################
###### MDPs from AFDB - added : rescued by Foldseek Search  ######
##################################################################

# data dir 
mkdir ../data/AFDB-TED/inc_N

# foldseek search command

# resulting file 
# modified 
../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted.tsv

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

mkdir ../data/AFDB-TED/tmp_rescuedN

# concatenating the files 
cat \
../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_num_CATuniq-concat-sorted_modified.tsv \
../data/AFDB-TED/tmp/0_extract_fields_AF-RESULT-ID_plddt_CATH_level.tsv \
> ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv

# sort 
sort -t$'\t' -k1,1 -k2,2 \
../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv \
-o ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded-sorted.tsv

# extract H & T hit, and concatenate
echo "AF_extract H & T hit, and concatenate"
awk -F'\t' '$5 == "T" || $5 == "H"' ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded.tsv  > ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded-HT.tsv 
./1_concatCATH.sh ../data/AFDB-TED/tmp_rescuedN/0_extract_fields_AF-RESULT-ID_plddt_CATH_level-rescuedNadded-HT.tsv ../data/AFDB-TED/tmp_rescuedN/1_extract-HT_concat-RESULT-ID_rawCombi.tsv

# extract CAT (topology) level   ex) 1.1.1.1;1.1.2.2  -> 1.3.1;1.1.2 
echo "start : ./2_remove_Hlevel.sh"
./2_remove_Hlevel.sh ../data/AFDB-TED/tmp_rescuedN/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/AFDB-TED/tmp_rescuedN/2_remove_Hlevel-RESULT-ID_Tcombi.tsv 

# sort within combination, removing reduncant topologies within combination   1.3.1;1.1.2    1.1.2;1.3.1  #a,b,c  3 pairs  #a,c   ->
echo "start : ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh ../data/AFDB-TED/tmp_rescuedN/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv # 143511353 proteins 

# get MDPs with a combination of multiple different domains (Topology level)
echo "start : extracting  MDPs with a combination of multiple different domains "#
grep ";" ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi.tsv > ../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv  # 51,431,676 proteins   


################################
###### MDPs from ESM-only ######
################################

# working dir :  
mkdir ../data/ESM-only
mkdir ../data/ESM-only/given_data/
mkdir ../data/ESM-only/tmp/

# extract_fields_ESM.sh
echo "ESM_extracting fileds"
./0_extract_fields_ESM.sh ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv # 5114908 domains 

# simple concatenatenation (raw combination)
echo "ESM_simpel concat" 
./1_concatCATH.sh ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv ../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi.tsv
# wc -l ../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi.tsv

# extract H & T hit, and concatenate
echo "ESM_extract H & T hit, and concatenate"
awk -F'\t' '$5 == "T" || $5 == "H"' ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel.tsv > ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel-HT.tsv
./1_concatCATH.sh ../data/ESM-only/tmp/0_extract_fields_ESM-RESULT-ID_plddt_CATH_CATHlevel-HT.tsv ../data/ESM-only/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv # 1998888 proteins    476181 MDPs 

# extract CAT (topology) level 
echo "ESM-extract T level"
./2_remove_Hlevel.sh ../data/ESM-only/tmp/1_extract-HT_concat-RESULT-ID_rawCombi.tsv ../data/ESM-only/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv # 1998888 proteins    -ID_Tcombi.tsv

# sort within combination, removing reduncant topologies within combination
echo "ESM_sort and remove redundancy"
./3_remove_redundancy_and_sort.sh ../data/ESM-only/tmp/2_remove_Hlevel-RESULT-ID_Tcombi.tsv ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv # 1998888 proteins   _sortedTcombi.tsv

# get MDPs with a combination of multiple different domains 
echo "ESM_ extracting  MDPs with a combination of multiple different domains "
grep ";" ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv > ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv # 393793 proteins -ID_sortedTcombi-multi.tsv


##################################################################################
###### MDPs from ESM-only - only Globular & H(Homologous Superfamily) level ######
##################################################################################

# data dir 
mkdir ../data/ESM-only/tmp_onlyGH/

# extract Globular CATH hits 
echo "extract Globular CATH hits "
awk -F'\t' -v OFS='\t' '$9 == "G"' ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv > 
 ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo-G.tsv
./0_extract_fields_ESM.sh ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo-G.tsv \
../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv

# extract H level (full four level) CATH hits, and "concatenate"
echo "ESM_GH:  extract H level (full four level) CATH hits, and "concatenate""
awk -F'\t' '$5 == "H"' "$input1" ../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv > ../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level-H.tsv
./1_concatCATH.sh ../data/ESM-only/tmp_onlyGH/0_extract_fields_ESM-RESULT-ID_plddt_CATH_level.tsv ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_GHcombi.tsv

# sort within combination, removing reduncant topologies within combination
echo "ESM_GH: ./3_remove_redundancy_and_sort.sh"
./3_remove_redundancy_and_sort.sh  ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_GHcombi.tsv ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv # 1998888 proteins   _sortedTcombi.tsv

# get MDPs with a combination of multiple different domains 
echo "ESM_GH: extracting  MDPs with a combination of multiple different domains "
grep ";" ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv  > ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi-multi.tsv # 393793 proteins -ID_sortedTcombi-multi.tsv


#############################################################################
###### (T-level) search ESM-only combinations against AFDB counterpart ######
#############################################################################

# output dir
mkdir ../data/find-novel_ESMonlyGH-AFincN

# generate co-occuring pair set for ESM, AF respectively
infile_AF="../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
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

# only H level 
../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs_check.tsv
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv 

# prep for the TABLE (compiliation) generation  
./6_concatCATHpairs.sh ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat.tsv  # 5203 