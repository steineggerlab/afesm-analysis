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
echo "python3 ./jupyter/19_chop_domain_TED_s2e.py \"${FASTA_PATH}\" \"${DOMAIN_FILE}\" \"${TMP_PATH}\""
python3 ./jupyter/19_chop_domain_TED_s2e.py "${FASTA_PATH}" "${DOMAIN_FILE}" "${TMP_PATH}"
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

