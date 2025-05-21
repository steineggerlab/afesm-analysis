#!/bin/bash

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
 

# nassambly should be retrieved from : 
# original file 
# secondary file :  
# "/fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_all_CATH_pairs/ALL_copairs-ESM-updated-TED-incNs-repID_nAssemblies_nMem_nAllMem_repPlddt_avgPlddt_sortedCombi_novelPair.tsv"
# MGYP000001210011        22      3       6       87.6    77.6 

 