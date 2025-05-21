

#  625K good quality N domains -> 495,202K rescued 
# ../data/AFDB-TED/625K_N_good_quality/TED-N-CATHmatch-id_CATH-Max.tsv 

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