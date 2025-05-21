#!/bin/bash

# raw count table should be shared 

table="../data/TABLE-ID_isMDP_hasTpair_hasGHpair_isNovel_nDomain_nTdomain_nGHdomain_nNovelGHpair_rawCombi_Tcombi_GHcombi_NovelGHpairsConcat_nMem_nAllMem.tsv" 

# novel set 
grep -v "not_novel_or_no_GHcombi" $table > ..data/novel_MDPs_wGHpairs.tsv
grep ";" ../data/ESM-only/tmp_onlyGH/1_extract-H_concat-RESULT-sorted.tsv > ..data/ALL_ESM_MDPs_wGHpair.tsv
awk -F"\t" -v OFS="\t" 'NR==FNR{data[$1];next;} ($1 in data)' ..data/novel_MDPs_wGHpairs.tsv ..data/ALL_ESM_MDPs_wGHpair.tsv > novel_MDPs_wGHpair_2.tsv
  
# not novel set
cd ../data/ESM-only/tmp_onlyGH
grep ";" 1_extract-H_concat-RESULT-sorted.tsv > ..data/ALL_ESM_MDPs_wGHpair.tsv
grep -v "not_novel_or_no_GHcombi" $table > ..data/novel_MDPs_wGHpairs.tsv
awk -F"\t" 'NR==FNR{data[$1];next;} !($1 in data)' ..data/novel_MDPs_wGHpair_2.tsv ..data/ALL_ESM_MDPs_wGHpair.tsv > \
..data/not_novel_ESM_MDPs_wGHpair.tsv 

# count the occurence of CATH from the Novel / not Novel set 
file_novel="..data/novel_MDPs_wGHpair_2.tsv"  # should be replaced 
file_notNovel="..data/not_novel_ESM_MDPs_wGHpair.tsv"
awk -F"\t" -v OFS='\t' '{print $2}' $file_novel > ../data/temp_Novel.tsv
awk -F"\t" -v OFS='\t' '{print $2}' $file_notNovel > ../data/temp_notNovel.tsv

./count_novel_notNovel.sh temp_Novel.tsv temp_notNovel.tsv > ../data/CATHcount_Novel_notNovel.tsv

# statistical test for the over/underrepresentation   
Rscript chi-fisher_test.R ../data/CATHcount_Novel_notNovel.tsv ../data/CATH_cntA_cntB_testtype_pval_padjusted_direction.tsv

# sanity check with direction 
awk -F, -v groupA_size=5203 -v groupB_size=135832 'BEGIN {OFS=","} 
NR==1 {print $0,"log2FC"; next} 
{
    log2FC = log(($2 / groupA_size) / ($3 / groupB_size)) / log(2);
    print $0, log2FC;
}' ALL_results.csv > ALL_results_wlog2FC.csv

awk -F"," '{
    if (($7 >= 0 && $8 >= 0) || ($7 < 0 && $8 < 0)) 
        $9 = 1; 
    else 
        $9 = 0; 
    print $0;
}' OFS="," ALL_results_wlog2FC.csv > ALL_results_wlog2FC_isSameSign.csv


# Adding log2 fold change and -log10(p_adjusted) to the CSV data
./log2foldRatio_log10p-val.sh 5203 135832 CATH_cntA_cntB_testtype_pval_padjusted_direction.tsv > \
CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj.tsv

# curr table="CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj.tsv"  # 9 fields, tsv, $1=ID
# "Category","raw_count_A","raw_count_B","test_type","p_value","p_adjusted","direction","log2FC","-log10p-adj" 
# 1            2              3               4          5        6           7           8           9         

# desired : "Category","raw_count_A","raw_count_B","test_type","p_value","p_adjusted","direction","log2FC","-log10p-adj","nNovelPair","[mean_nDomain]","cath_name"

# nNovelPair
# ../data/components-novelMDP-GH-CATH_sumClu_sumNmem_sumNallMem_CATHname.tsv # refer to ../afesm-analysis/extract_novel_combination/x_fig_c_prep.sh 

# "meannDomain"
# CATH_count_meanDomain.tsv

# "cath_name"
# cath-names.tsv   # from cath-names.txt  pandas code in the 'volcano-FINAL.ipynb'

nNovelPair="../data/components-novelMDP-GH-CATH_sumClu_sumNmem_sumNallMem_CATHname.tsv"  
nDomain="../data/CATH_count_meanDomain.tsv"
cathname="../data/cath-names.tsv"
output1="../data/CATH_nNovelPair_meannDomain_cathname.tsv"

awk -F"\t" -v OFS='\t' '
  NR==FNR {  # For the first file (nNovelPair)
    nNovelPair[$1] = $2;
    next;
  }
  NR==FNR+1 {  # For the second file (meanDomain)
    meanDomain[$1] = $3;
    next;
  }
  NR==FNR+2 {  # For the third file (cathname)
    cathname[$1] = $3;
    next;
  }
  # Print header with new columns
  NR == 1 { 
    print $0, "nNovelPair", "[mean_nDomain]", "cath_name";
    next;
  }
  # For the rest of the records, print concatenated valsues
  {   
    print $0, nNovelPair[$1], meanDomain[$1], cathname[$1];
  }
' $nNovelPair $nDomain $cathname > $output1

# concatenate the log2FC and the -log10p-adj
curr_table="../data/CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj.tsv" 
awk -F"\t" -v OFS='\t' 'NR==FNR {data[$1];next;}($1 in data){print $0,data[$1]}' $output1 $curr_table > \
"../data/CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj_nNovelPair_meannDomain_cathname.tsv"   # 2906 entries 

# extract only the significant ones 
awk -F"\t" 'NR==1 || $6 < 0.05' ../data/CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj_nNovelPair_meannDomain_cathname.tsv > \
../data/CATH_cntA_cntB_testtype_pval_padjusted_direction_log2FC_-log10p-adj_nNovelPair_meannDomain_cathname-significant.tsv

