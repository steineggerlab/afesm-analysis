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


 