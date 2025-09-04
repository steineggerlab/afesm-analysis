#!/bin/bash

# SEQ_FILE="23_abandoned_domains/tmp/entryIds_allreps_lowqual.fasta"
SEQ_FILE=$1
# MSA_DIR="23_abandoned_domains/colabfold/esm_novel_msa"
MSA_DIR=$2
COLABFOLD_PATH="/home/livinit/localcolabfold/colabfold-conda/bin"

$COLABFOLD_PATH/colabfold_search --db1 /storage/databases/colabfold_db_all/uniref30_2202_db \
--db3 /storage/databases/colabfold_db_all/colabfold_envdb_202108_db \
--use-env 1 --use-templates 0 --filter 1 -s 7 --threads 64 --db-load-mode 1 \
$SEQ_FILE /storage/databases/colabfold_db_all/ $MSA_DIR