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


# sanity check 
#             625K good quality N domains -> 495,202K rescued 
#           ../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_CATH-Max.tsv 

# original AF data (all entries with multiple Topology domains)
original="../data/AFDB-TED/tmp/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
# rescued-N-combined AF data (all entries with multiple Topology domains)
# combinedN="../data/AFDB-TED/inc_N/4_AF_CATHcombi_incN-ID_sortedTcombi-incN-sorted-multi.tsv"
combinedN="../data/AFDB-TED/tmp_rescuedN/3_remove_redundancy_and_sort-RESULT-ID_sortedTcombi-multi.tsv"
outfile="../data/AFDB-TED/inc_N/check_AF_CATHcombi_incN-ID_originalTcombi_combinedNTcombi.tsv" #
#awk -F"\t" -v OFS="\t" 'NR==FNR{data[$1]=$2;next;}!(data[$1]==$2){print $1,data[$1],$2}' $original $combinedN > $outfile
awk -F"\t" -v OFS="\t" 'NR==FNR{data[$1]=$2;next;}!(data[$1]){print $1,data[$1],$2}' $original $combinedN > $outfile
# 252,516 entries with multiple T combi were "rescued"
outfile2="../data/AFDB-TED/inc_N/check2_AF_CATHcombi_incN-ID_originalTcombi_combinedNTcombi.tsv"
awk -F"\t" -v OFS="\t" 'NR==FNR{data[$1]=$2;next;}(data[$1] && data[$1] != $2){print $1,data[$1],$2}' $original $combinedN > $outfile2
# 77,439 entries had altered domain combination (incresed number of domains) in their T combinations, when the rescued Ns were combined. 



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
novel_ESM="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv"
echo "start : search (ESM against AF)"
./5_compare_copairs_set.sh $outfile_AF $outfile_ESM $novel_ESM

#  awk -F"\t" '{print $1}' $novel_ESM | sort | uniq | wc -l  
# 11941 



#############################################################################
###### map H-level CATH array form ESM-only ################################# 
#############################################################################

# result dir 
mkdir ../data/ESM-only/HlevelCombi_mapped

# GH combination dataset 
input_GH_combi="../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi-multi.tsv"

# remove redundancy and sort
./3_remove_redundancy_and_sort.sh $input_GH_combi \
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

# extract novel MDPs, based on the novel copair set previously identified
# the novelty was examined by T level, and now the novel pairs are studied in the H level
input_novel_copairs="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv" # sort 
./3_remove_redundancy_and_sort_f3.sh $input_novel_copairs ../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_sortedCopairs.tsv

# mapping (to get novel MDPs with only H level )
awk -F'\t' -v OFS='\t' 'NR==FNR { data[$3]; next } ($4 in data)' \
../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_sortedCopairs.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_sortedTpair.tsv > \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv

# sanity check 
# awk -F"\t" '{print $1}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 5203 MDPs with novel co-occuring domains (novel combinations)

# awk -F"\t" '{print $2}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 4951 novel combinations

# awk -F"\t" '{print $3}' ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv | sort | uniq | wc -l 
# 5134 novel co-occuring pairs 

# prep for the TABLE (compiliation) generation  
./6_concatCATHpairs.sh ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_Hcombi_Hpair_Tpairs-sortedTpairs-NOVEL.tsv \
../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat.tsv  # 5203 



#############################################################################
###### compiliation table  ######
#############################################################################


# For the 3.2M ESM-only nonsingleton CRs; We made a table of 13 files
# '''
# $1  ID           Mgnify ID

# $2  isMDP        0 or 1      (1 if nDomain > 1, 0 if nDomain == 0)
#  $3    hasTpair    0 or 1      (1 if nTdomain >= 2, 0 if nTdomain <= 1)
#      hasGHpair   0 or 1      (1 if nGHdomain >= 2, 0 if nGHdomain <= 1)
#      isnovel     0 or 1      (1 if ID is in ../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv)

#   nDomain      Number of ";" in HrawComb + 1  "-"
#    nTdomain     Number of ";" in Tcombi + 1
# $   nGHdomain     Number of ";" in HCombi + 1
#    nNoveGHPair  Number of "&" in Concat_NovelGHpairs + 1   MGYP ~~~ a;b;c    a;b b;c a;c  1 

# $7  rawCombi                          Example: -;2.20.20.20;1.10.10.10;-;3.30.30.30  
#                                       File: ../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi.tsv

# $8  Tcombi (sorted, nonRedundant)      Example: 1.10.10;2.20.20;3.30.30
#                                       File: ../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv  
#                                       (if not present, "no_T_combi")

# $9  HCombi (sorted, nonRedundant)      Example: 1.10.10.10;2.20.20.20;3.30.30.30
#                                       File: ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv  
#                                       (if not present, "no_GH_combi")

# $10 Concat_NovelGHpairs                Example: 1.10.10.10;2.20.20.20&2.20.20.20;3.30.30.30
#                                       File: ../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat.tsv  
#                                       (if not present, "not_novel")
# '''

# mapping rawCombi, Tcombi, Hcombi, concatenated novel GH pairs 
rawCombi="../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi.tsv" 
rawCombi2="../data/ESM-only/tmp/1_concat_RESULT-ID_CATHcombi_rmHeader.tsv"
awk -F"\t" -v OFS='\t' 'NR>1' $rawCombi > $rawCombi2
Tcombi="../data/ESM-only/tmp/3_remove_redundancy_and_sort-RESULT_sortedTcombi.tsv"
GHcombi="../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-ID_sortedGHcombi.tsv"
Concat_NovelGHpairs="../data/ESM-only/HlevelCombi_mapped/1_extract-H_concat-RESULT-sorted-multi-ID_novelGHpairsConcat.tsv"
awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "no_Tcombi"}' "$Tcombi" "$rawCombi2" | \
awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "no_GHcombi"}' "$GHcombi" - | \
awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "not_novel_or_no_GHcombi"}' "$Concat_NovelGHpairs" - > \
../data/ESM-only/TABLE-ID_rawCombi_Tcombi_GHcombi_novelGHpairConcat.tsv

# count number of domains in rawCombi, Tcombi, GHcombi, and the number of pairs in concatenated novel GH pairs 
input="../data/ESM-only/TABLE-ID_rawCombi_Tcombi_GHcombi_novelGHpairConcat.tsv"
output="../data/ESM-only/compilation_table/TABLE-tmp1.tsv"
awk -F"\t" -v OFS='\t' '
{
    # Extract fields from the input file
    ID = $1
    rawCombi = $2
    Tcombi = $3
    GHcombi = $4
    Concat_NovelGHpairs = $5

    # Count the number of ";" in rawCombi, Tcombi, and GHCombi
    nDomain = split(rawCombi, temp1, ";")
    nTdomain = split(Tcombi, temp2, ";")
    nGHdomain = split(GHcombi, temp3, ";")

    # Count the number of "&" in Concat_NovelGHpairs
    nNovelGHPair = split(Concat_NovelGHpairs, temp4, "&")

    # Print the 9 fields
    print ID, nDomain, nTdomain, nGHdomain, nNovelGHPair, rawCombi, Tcombi, GHcombi, Concat_NovelGHpairs
}' "$input" > "$output"

# flag added (isNovel, isMDP, hasTpair, hasGHpair, isNovel)
input="../data/ESM-only/compilation_table/TABLE-tmp1.tsv"
novelIDs="../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv"
output="../data/ESM-only/compilation_table/TABLE-tmp2.tsv"
# Create a set of IDs from the novel file
awk '{novel[$1]=1} END {for (id in novel) print id}' "$novelIDs" > novel_ids_set.tsv
# Process the input file and add the 4 new fields
awk -F"\t" -v OFS='\t' '
BEGIN {
    # Load novel IDs into an array
    while ((getline < "../data/find-novel_ESMonlyGH-AFincN/incN_result-novel-copairs_ID_combi_copairs.tsv") > 0) {
        novel[$1] = 1
    }
}
{
    # Read input fields
    ID = $1
    nDomain = $2
    nTdomain = $3
    nGHdomain = $4
    nNovelGHPair = $5
    rawCombi = $6
    Tcombi = $7
    GHcombi = $8
    Concat_NovelGHpairs = $9

    # Calculate new fields
    isMDP = (nDomain > 1) ? 1 : 0
    hasTpair = (nTdomain >= 2) ? 1 : 0
    hasGHpair = (nGHdomain >= 2) ? 1 : 0
    isNovel = (ID in novel) ? 1 : 0

    # Print all fields including new ones
    print ID, isMDP, hasTpair, hasGHpair, isNovel, nDomain, nTdomain, nGHdomain, nNovelGHPair, rawCombi, Tcombi, GHcombi, Concat_NovelGHpairs 
}' "$input" > "$output"
# Clean up the temporary file
rm novel_ids_set.tsv
rm TABLE-tmp1.tsv
rm TABLE-tmp2.tsv

# add a header line 
header="ID\tisMDP\thasTpair\thasGHpair\tisNovel\tnDomain\tnTdomain\tnGHdomain\tnNovelGHPair\trawCombi\tTcombi\tGHcombi\tConcat_NovelGHpairs"
input="../data/ESM-only/compilation_table/TABLE-tmp2.tsv"
output="../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat.tsv"
 
# Add the header and append the content of the original file
{ echo -e "$header"; cat "$input"; } > "$output"

# compliated table
# "../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat.tsv"

# add nMember, nAllMember
# input table
table="../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat.tsv"   # total 3213408 

# dir
mkdir /fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata

#nMem 
foldseek_clu="/home/livinit/share/afesm5/cluster/afesm30_repseq_foldseek_clu.tsv"
tmp1="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_foldseek_clu_ID-mem.tsv"
awk -F"\t" 'NR==FNR{data[$1];next}($1 in data)' $table $foldseek_clu > $tmp1
tmp2="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_ID-Mem.tsv"    # ID - nMem 
awk -F"\t" -v OFS='\t' '{count[$1]++} END {for (key in count) print key, count[key]}' $tmp1 > $tmp2

# sanity check 
# nMem_data="/home/livinit/share/afesm5/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nMem_avgLddt_avgTmScore_nCovLe90.tsv"

#nAllMem
allmem_data="/home/livinit/share/afesm5/cluster/afesm30_repseq_foldseek_clu_nonsingleton-repId_allmemId_flag.tsv"
tmp3="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_foldseek_clu_nonsingleton-repId_allmemId_flag.tsv"
awk -F"\t" 'NR==FNR{data[$1];next}($1 in data)' $table $allmem_data > $tmp3
tmp4="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_ID-nAllMem.tsv"    # ID - nAllMem 
awk -F"\t" -v OFS='\t' '{count[$1]++} END {for (key in count) print key, count[key]}' $tmp3 > $tmp4

# adding nMem and nAllMem to the table 
table_result="../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem.tsv"  # 15 fields 

tmp2="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_ID-Mem.tsv"    # ID - nMem 
tmp4="/fast/yewon/0_Novel_MDP_Main/data/ESM-only/tmp_metadata/afesm30_onlyESMrepseq_ID-nAllMem.tsv"    # ID - nAllMem 

awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "no_nMem"}' "$tmp2" "$table" | \
awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "no_nAllMem"}' "$tmp4" - > $table_result

# result
# "../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem.tsv"  # 15 fields 
