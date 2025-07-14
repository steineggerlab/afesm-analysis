#!/bin/bash
#SBATCH --job-name=colab_prediction
#SBATCH --nodelist=devbox001
#SBATCH --partition=gpu
#SBATCH --time=0
#SBATCH --gres=gpu:1
#SBATCH --output="Preds/log_pred_batch00"

# Colabfold batch
# MSA_DIR="19_pred_novel_domains/colabfold/esm_novel_msa"
MSA_DIR=$1
# PRED_DIR="19_pred_novel_domains/colabfold/pred_result"
PRED_DIR=$2
COLABFOLD_PATH="/home/livinit/localcolabfold/colabfold-conda/bin"
#NUM_RECYCLES=20

$COLABFOLD_PATH/colabfold_batch $MSA_DIR $PRED_DIR