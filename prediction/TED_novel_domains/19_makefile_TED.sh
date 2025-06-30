#!/bin/bash -e

# Check if five arguments are passed
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <BASE_PATH> <FASTA_PATH> <OUTPUT_PATH> <TMP_PATH> <DOMAIN_FILE>"
    exit 1
fi

BASE_PATH=$1
FASTA_PATH=$2
OUTPUT_PATH=$3
TMP_PATH=$4
DOMAIN_FILE=$5

# Assuming 'foldseek' is the command you want to execute
FOLDSEEK="/home/livinit/foldseek_from_web/foldseek/bin/foldseek"

# Function to measure and print time
measure_time() {
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo "Time taken: ${duration} seconds"
}

# Ensure directories exist or create them
mkdir -p "${FASTA_PATH}"
mkdir -p "${TMP_PATH}"
# mkdir -p "${OUTPUT_PATH}"

if true; then
# Convert PDB database to FASTA format
echo "Start run convert2fasta for PDB"
start_time=$(date +%s)
${FOLDSEEK} convert2fasta "${BASE_PATH}" "${FASTA_PATH}.fasta"
echo "Done run convert2fasta for PDB"
measure_time
fi

if true; then
# Convert 3Di sequence database to FASTA format
echo "Start run convert2fasta for 3DiSeq"
start_time=$(date +%s)
${FOLDSEEK} lndb "${BASE_PATH}_h" "${BASE_PATH}_ss_h" # soft link 
${FOLDSEEK} convert2fasta "${BASE_PATH}_ss" "${FASTA_PATH}_ss.fasta"
echo "Done run convert2fasta for 3DiSeq"
measure_time
fi

if true; then
# Handling of c_alpha database
echo "Start run convert2fasta for C_alpha"
start_time=$(date +%s)
${FOLDSEEK} compressca "${BASE_PATH}" "${TMP_PATH}_ca_f64" --coord-store-mode 3
${FOLDSEEK} lndb "${BASE_PATH}_h" "${TMP_PATH}_ca_f64_h"
${FOLDSEEK} convert2fasta "${TMP_PATH}_ca_f64" "${FASTA_PATH}_ca.fasta"
${FOLDSEEK} rmdb "${TMP_PATH}_ca_f64"
${FOLDSEEK} rmdb "${TMP_PATH}_ca_f64_h"
echo "Done run convert2fasta for C_alpha"
measure_time
fi

# Process retained files
echo "Start cutting"
start_time=$(date +%s)
echo "python3 ./jupyter/19_chop_domain_TED.py \"${FASTA_PATH}\" \"${DOMAIN_FILE}\" \"${TMP_PATH}\""
python3 ./jupyter/19_chop_domain_TED.py "${FASTA_PATH}" "${DOMAIN_FILE}" "${TMP_PATH}"
echo "Done cutting"
measure_time

# Convert TSV to database format
echo "Start converting tsv to db"
start_time=$(date +%s)
${FOLDSEEK} tsv2db "${TMP_PATH}.tsv" "${OUTPUT_PATH}" --output-dbtype 0
${FOLDSEEK} tsv2db "${TMP_PATH}_ss.tsv" "${OUTPUT_PATH}_ss" --output-dbtype 0
${FOLDSEEK} tsv2db "${TMP_PATH}_h.tsv" "${OUTPUT_PATH}_h" --output-dbtype 12
${FOLDSEEK} tsv2db "${TMP_PATH}_ca.tsv" "${OUTPUT_PATH}_ca" --output-dbtype 12
echo "Done converting tsv to db"
measure_time

# Compress and handle CA database
echo "Start compressing ca db"
start_time=$(date +%s)
${FOLDSEEK} compressca "${OUTPUT_PATH}" "${OUTPUT_PATH}_ca2" --coord-store-mode 2 --threads 1
${FOLDSEEK} rmdb "${OUTPUT_PATH}_ca"
${FOLDSEEK} mvdb "${OUTPUT_PATH}_ca2" "${OUTPUT_PATH}_ca"
echo "Done compressing ca db"
measure_time





# srun -t 10-0 -c 64 -p compute -w hulk ./makefile.sh input_subdb/afdb50_seq_625K TED_beforeCut/TED_beforeCut TED_afterCut/TED_afterCut temp/TED_CUT TED_n_hits_625k_only_boundaries_modified.tsv


# Add option to save C-alpha as float16
# foldseek structureto3didescriptor input_subdb/afdb50_seq_625K input_subdb/afdb50_seq_625K_ca

# yewon1@hulk:/big/yewon/cut_TED_600K_domains$ mkdir CreateDB_for_ca
# srun -t 10-0 -c 64 -p compute -w hulk foldseek createdb TED_beforeCut/TED_beforeCut.fasta CreateDB_for_ca/afdb50_seq_625K

# srun -t 10-0 -c 128 -p compute -w super001 ./makefile_temp.sh /fast/databases/foldseek/webserver/afdb50_seq /mnt/scratch/yewon1/cut_TED_600K_domains/TED_beforeCut /mnt/scratch/yewon1/cut_TED_600K_domains/TED_afterCut /mnt/scratch/yewon1/cut_TED_600K_domains/TED_temp_CUT /mnt/scratch/yewon1/TED_n_hits_625k_only_boundaries_modified.tsv

# done!
# yewon1@super001:/mnt/scratch/yewon1/cut_TED_600K_domains$ cp TED_beforeCut_ca.fasta /fast/yewon/cut_TED_600K_domains/


# cutting & converting 

# srun -t 10-0 -c 64 -p compute -w hulk ./makefile.sh input_subdb/afdb50_seq_625K TED_beforeCut/TED_beforeCut TED_afterCut/TED_afterCut temp/TED_CUT TED_n_hits_625k_only_boundaries_modified.tsv

# srun -t 10-0 -c 64 -p compute -w hulk awk -f extract_lines.awk /fast/yewon/cut_TED_600K_domains/TED_beforeCut_ca.fasta ids_desired.txt > TED_beforeCut/TED_beforeCut_ca_extracted.fasta


# mv TED_beforeCut_ca_extracted.fasta TED_beforeCut_ca.fasta


# srun -t 10-0 -c 64 -p compute -w hulk ./makefile.sh input_subdb/afdb50_seq_625K TED_beforeCut/TED_beforeCut TED_afterCut/TED_afterCut temp/TED_CUT TED_n_hits_625k_only_boundaries_modified-uniprotID-range-domainID.tsv

# cp TED_afterCut_h TED_afterCut_ca_h 



# foldseek search /big/yewon/cut_TED_600K_domains/TED_afterCut/TED_afterCut_ca (target : CATH foldseek db ) aln tmp --alignment-type 1 --exhaustive-search 1

# /big/yewon/cut_TED_600K_domains/TED_afterCut 


#  srun -t 10-0 -c 64 -p compute -w hulk cp /big/yewon/cut_TED_600K_domains/TED_afterCut/TED_afterCut_ca* query_TED_domains

#  srun -t 10-0 -c 64 -p compute -w hulk cp /big/yewon/cut_TED_600K_domains/*tar.gz query_TED_domains



#  srun -t 10-0 -c 64 -p compute -w super002 cp -r /fast/yewon/temp_store .

#   srun -t 10-0 -c 64 -p compute -w super002 tar -xvf cath_s95_foldseek_database.tar

#    srun -t 10-0 -c 64 -p compute -w super002 cp /fast/yewon/temp_store/ TED_afterCut .
 


# srun -t 10-0 -c 128 -p compute -w super002 foldseek search /mnt/scratch/yewon1/query_TED_domains/TED_afterCut /mnt/scratch/yewon1/cath_s95_foldseek_database/cath_s95_fs_db aln tmp --alignment-type 1 --exhaustive-search 1

#  /mnt/scratch/yewon1/target_CATH_db/cath_s95_foldseek_database



# srun -t 10-0 -c 128 -p compute -w super002 foldseek createtsv /mnt/scratch/yewon1/query_TED_domains/TED_afterCut /mnt/scratch/yewon1/cath_s95_foldseek_database/cath_s95_fs_db aln_tmscore aln_tmscore.tsv





# 최종 
# srun -t 10-0 -c 128 -p compute -w super002 awk -F'\t' -v 'OFS='\t' '{print $1, $2, $3, $4, $5, (2*$5 - ($3/100)), $6, $7, $8, $9, $10, $11}' aln_tmscore.tsv > aln_tmscore_modified.tsv
# srun -t 10-0 -c 128 -p compute -w super002 awk -F'\t' -v OFS='\t' '$6 >= 0.5' aln_tmscore_modified.tsv > aln_tmscore_modified_filtered_f5.tsv

# # 0.4M entries are rescued!


# srun -t 10-0 -c 128 -p compute -w super002 awk -v OFS='\t' '
#     NR==FNR { data[$1]=$3; next; } 
#     { 
#         if ($2 in data) {          # If the value in the second column of input2.tsv exists as a key in the "data" array.
#             print $1"\t"data[$2]"\t"$6; # Print the first column from input2.tsv, the corresponding value from input1.tsv, and the sixth column from input2.tsv.
#         }
#     }
# ' cath-b-newest-all.txt aln_tmscore_modified_filtered_f5.tsv | awk -F'_' -v OFS='\t' '{print $4"_"$6}' > match-id-CATH-tmscore.tsv


# cp /mnt/scratch/yewon1/match-id-CATH-Ttmscore.tsv 


# cp aln_tmscore.tsv /fast/yewon/finalized_MDP_analysis/data/AFDB-TED 
