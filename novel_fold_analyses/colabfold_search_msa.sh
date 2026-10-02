#!/bin/bash
# MSA generation for the novel fold domains with colabfold_search (MMseqs2 15.6f452)
# usage: sbatch colabfold_search_msa.sh <fasta> <msa_dir>

#SBATCH --job-name=deep_msa
#SBATCH --nodelist=super004
#SBATCH --partition=compute
#SBATCH --time=7-0
#SBATCH --cpus-per-task=64
#SBATCH --output=/share/afesm6/50_novel_struct_dl/log_%j

  SEQ_FILE=$1
  MSA_DIR=$2
  # ColabFold environment with MMseqs2 15.6f452

  mkdir -p "$MSA_DIR"

  colabfold_search \
    --db1 /storage/databases/colabfold_db_all/uniref30_2202_db \
    --db3 /storage/databases/colabfold_db_all/colabfold_envdb_202108_db \
    --use-env 1 \
    --use-templates 0 \
    --filter 1 \
    -s 7 \
    --threads 64 \
    --db-load-mode 1 \
    "$SEQ_FILE" \
    /storage/databases/colabfold_db_all/ \
    "$MSA_DIR"
