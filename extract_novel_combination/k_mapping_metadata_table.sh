#!/bin/bash

# input table
table="../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem.tsv"  # 15 fields 

# output table 
table_w_metadata="../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem_avgPlddt_avgTMscore_nAssembly_isFrag.tsv"

# added 
    # repPlddt  (won't be used)   
    # avgPlddt          /home/livinit/share/afesm5/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nMem_avgLddt_avgTmScore_nCovLe90.tsv # $4
    # avgTMscore          /home/livinit/share/afesm5/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nMem_avgLddt_avgTmScore_nCovLe90.tsv # $5
    # nAssembly   (should be checked) /fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_all_CATH_pairs/ALL_copairs-ESM-updated-TED-incNs-repID_nAssemblies_nMem_nAllMem_repPlddt_avgPlddt_sortedCombi_novelPair.tsv # $2
    # is_frag  : (should it be added?)
    # nDomain : already in the table ($6)
    # nAllDomains :  (should it be added?)
    # LCAbiome (if there's no, write "no_biome")
    # LCAtaxonomy (if there's no, write "no_taxonomy")
 
# table_w_metadata
metadata_jingi="/home/livinit/share/afesm5/metadata/afesm30_repseq_foldseek_clu_nonsingleton-repId_nMem_avgLddt_avgTmScore_nCovLe90.tsv"
metadata_prev="/fast/yewon/finalized_MDP_analysis/data/ESM-only/tmp_all_CATH_pairs/ALL_copairs-ESM-updated-TED-incNs-repID_nAssemblies_nMem_nAllMem_repPlddt_avgPlddt_sortedCombi_novelPair.tsv"

awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$4"\t"$5;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "avgPlddt_avbTMscore"}' "$metadata_jingi" "$table" | \
awk -F"\t" -v OFS='\t' 'NR==FNR{data[$1]=$2;next;}($1 in data){print $0, data[$1]}!($1 in data){print $0, "nAssembly"}' "$metadata_prev" - > $table_w_metadata # should be fixed (for now, the nassmbly file covers only novel MDPs)

#result 
# "../data/ESM-only/compilation_table/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem_avgPlddt_avgTMscore_nAssembly_isFrag.tsv"
 