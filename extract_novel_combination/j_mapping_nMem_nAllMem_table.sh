#!/bin/bash

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



# 
# nassambly should be retrieved from : 
# original file 
# secondary file :  
# "/fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_all_CATH_pairs/ALL_copairs-ESM-updated-TED-incNs-repID_nAssemblies_nMem_nAllMem_repPlddt_avgPlddt_sortedCombi_novelPair.tsv"

# domain boundary should be also added 
# ../data/ESM-only/given_data/annotated_table_newclusters_provisional_nonewfoldsinfo.tsv

# MGYP000658185103

MGYP000419696103        1       1       1       1       3       3       3       1       3.40.1110.10;3.40.50.1000;3.40.640.10   3.40.1110;3.40.50;3.40.640      3.40.1110.10;3.40.50.1000;3.40.640.10   3.40.1110.10;3.40.640.10        4       89
MGYP000635553862        1       1       1       1       5       3       3       2       3.40.640.10;3.90.1150;-;2.70.150.10;3.40.1110.10        2.70.150;3.40.1110;3.40.640     2.70.150.10;3.40.1110.10;3.40.640.10    2.70.150.10;3.40.640.10&3.40.1110.10;3.40.640.10        2          1219
MGYP000658185103  #       1       1       1       1       5       4       3       1       -;3.40.640.10;3.40.1110.10;3.40.50.1000;1.20.58 1.20.58;3.40.1110;3.40.50;3.40.640      3.40.1110.10;3.40.50.1000;3.40.640.10   3.40.1110.10;3.40.640.10        6       508
MGYP000930297110        1       1       1       1       4       3       3       1       3.40.640.10;3.40.1110.10;-;3.30.479.30  3.30.479;3.40.1110;3.40.640     3.30.479.30;3.40.1110.10;3.40.640.10    3.40.1110.10;3.40.640.10        2       105
MGYP003338143772        1       1       1       1       3       3       3       1       3.40.640.10;3.40.50.1000;3.40.1110.10   3.40.1110;3.40.50;3.40.640      3.40.1110.10;3.40.50.1000;3.40.640.10   3.40.1110.10;3.40.640.10        5       41
~
~